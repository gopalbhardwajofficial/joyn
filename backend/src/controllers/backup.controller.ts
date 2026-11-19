import { FastifyRequest, FastifyReply } from 'fastify';
import { getDbPool } from '../db/connection.js';
import { performAutoBackupForBusiness } from '../services/backup_cron.service.js';

function toValidUuidOrNull(val: any): string | null {
  if (typeof val !== 'string' || !val) return null;
  const uuidRegex = /^[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i;
  return uuidRegex.test(val) ? val : null;
}

function parseSequentialNumber(val: any, fallback: number = 0): number {
  if (typeof val === 'number' && !isNaN(val)) return Math.floor(val);
  if (typeof val === 'string') {
    const digitsOnly = val.replace(/\D/g, '');
    if (digitsOnly.length > 0) {
      const parsed = parseInt(digitsOnly, 10);
      if (!isNaN(parsed) && parsed > 0) return parsed;
    }
  }
  return fallback;
}

export async function createBackupHandler(req: FastifyRequest, reply: FastifyReply) {
  const pool = getDbPool();
  const user = (req as any).user;
  const body = (req.body as any) || {};

  let activeBusinessId = (req as any).businessAccess?.businessId || (req.headers['x-business-id'] as string) || body.businessId;
  if (!activeBusinessId && user?.userId) {
    const bizRes = await pool.query(
      'SELECT id FROM business_profile WHERE owner_id = $1 ORDER BY created_at ASC LIMIT 1',
      [user.userId]
    );
    if (bizRes.rows.length > 0) activeBusinessId = bizRes.rows[0].id;
  }

  if (!activeBusinessId) {
    return reply.status(400).send({ success: false, message: 'Active business ID required for backup.' });
  }

  try {
    // Ensure tables exist on first run
    await pool.query(`
      CREATE TABLE IF NOT EXISTS cloud_backups (
        id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
        business_id UUID NOT NULL REFERENCES business_profile(id) ON DELETE CASCADE,
        backup_name VARCHAR(255) NOT NULL,
        backup_type VARCHAR(50) DEFAULT 'MANUAL',
        file_size_bytes BIGINT DEFAULT 0,
        record_count INT DEFAULT 0,
        storage_path VARCHAR(255) DEFAULT 'postgres:cloud_backups.backup_data',
        backup_data JSONB NOT NULL,
        device_name VARCHAR(100) DEFAULT 'JOYN Mobile App',
        created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
      );
      CREATE TABLE IF NOT EXISTS backup_settings (
        business_id UUID PRIMARY KEY REFERENCES business_profile(id) ON DELETE CASCADE,
        auto_backup_enabled BOOLEAN DEFAULT true,
        frequency VARCHAR(20) DEFAULT 'DAILY',
        retention_days INT DEFAULT 30,
        last_auto_backup_at TIMESTAMP WITH TIME ZONE,
        updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
      );
    `).catch(() => {});

    let backupData = body.data || null;

    // If client didn't supply local DB dump, assemble complete cloud snapshot
    if (!backupData) {
      const [
        bizRes,
        itemsRes,
        partiesRes,
        salesRes,
        purchasesRes,
        paymentsRes,
        expensesRes,
        teamRes,
        quotationsRes,
        creditNotesRes,
        debitNotesRes,
        remindersRes
      ] = await Promise.all([
        pool.query('SELECT * FROM business_profile WHERE id = $1', [activeBusinessId]).catch(() => ({ rows: [] })),
        pool.query('SELECT * FROM items WHERE business_id = $1 ORDER BY created_at ASC', [activeBusinessId]).catch(() => ({ rows: [] })),
        pool.query('SELECT * FROM parties WHERE business_id = $1 ORDER BY created_at ASC', [activeBusinessId]).catch(() => ({ rows: [] })),
        pool.query('SELECT * FROM sales_orders WHERE business_id = $1 ORDER BY created_at ASC', [activeBusinessId]).catch(() => ({ rows: [] })),
        pool.query('SELECT * FROM purchase_orders WHERE business_id = $1 ORDER BY created_at ASC', [activeBusinessId]).catch(() => ({ rows: [] })),
        pool.query('SELECT * FROM payments WHERE business_id = $1 ORDER BY created_at ASC', [activeBusinessId]).catch(() => ({ rows: [] })),
        pool.query('SELECT * FROM expenses WHERE business_id = $1 ORDER BY created_at ASC', [activeBusinessId]).catch(() => ({ rows: [] })),
        pool.query('SELECT tm.*, r.name as role_name FROM team_members tm LEFT JOIN roles r ON tm.role_id = r.id WHERE tm.business_id = $1', [activeBusinessId]).catch(() => ({ rows: [] })),
        pool.query('SELECT * FROM quotations WHERE business_id = $1 ORDER BY created_at ASC', [activeBusinessId]).catch(() => ({ rows: [] })),
        pool.query('SELECT * FROM credit_notes WHERE business_id = $1 ORDER BY created_at ASC', [activeBusinessId]).catch(() => ({ rows: [] })),
        pool.query('SELECT * FROM debit_notes WHERE business_id = $1 ORDER BY created_at ASC', [activeBusinessId]).catch(() => ({ rows: [] })),
        pool.query('SELECT * FROM payment_reminders WHERE business_id = $1 ORDER BY created_at ASC', [activeBusinessId]).catch(() => ({ rows: [] }))
      ]);

      backupData = {
        version: '2.0',
        phase: 12,
        exportedAt: new Date().toISOString(),
        business: bizRes.rows[0] || null,
        items: itemsRes.rows,
        parties: partiesRes.rows,
        salesOrders: salesRes.rows,
        purchaseOrders: purchasesRes.rows,
        payments: paymentsRes.rows,
        expenses: expensesRes.rows,
        teamMembers: teamRes.rows,
        quotations: quotationsRes.rows,
        creditNotes: creditNotesRes.rows,
        debitNotes: debitNotesRes.rows,
        paymentReminders: remindersRes.rows
      };
    }

    const jsonString = JSON.stringify(backupData);
    const fileSizeBytes = Buffer.byteLength(jsonString, 'utf8');

    const recordCount =
      (Array.isArray(backupData.items) ? backupData.items.length : 0) +
      (Array.isArray(backupData.parties) ? backupData.parties.length : 0) +
      (Array.isArray(backupData.salesOrders) ? backupData.salesOrders.length : 0) +
      (Array.isArray(backupData.purchaseOrders) ? backupData.purchaseOrders.length : 0) +
      (Array.isArray(backupData.payments) ? backupData.payments.length : 0) +
      (Array.isArray(backupData.expenses) ? backupData.expenses.length : 0) +
      (Array.isArray(backupData.quotations) ? backupData.quotations.length : 0) +
      (Array.isArray(backupData.creditNotes) ? backupData.creditNotes.length : 0) +
      (Array.isArray(backupData.debitNotes) ? backupData.debitNotes.length : 0);

    const now = new Date();
    const backupName = body.backupName || `Cloud Backup - ${now.toISOString().split('T')[0]} ${now.toLocaleTimeString('en-IN', { hour12: false })}`;
    const deviceName = body.deviceName || 'JOYN Mobile App';
    const backupType = body.backupType || 'MANUAL';

    const insertRes = await pool.query(
      `INSERT INTO cloud_backups (
        business_id, backup_name, backup_type, file_size_bytes, record_count, storage_path, backup_data, device_name
      ) VALUES ($1, $2, $3, $4, $5, $6, $7, $8)
      RETURNING id, business_id, backup_name, backup_type, file_size_bytes, record_count, device_name, created_at`,
      [
        activeBusinessId,
        backupName,
        backupType,
        fileSizeBytes,
        recordCount,
        'postgres:cloud_backups.backup_data',
        jsonString,
        deviceName
      ]
    );

    return reply.status(201).send({
      success: true,
      message: 'Cloud backup created successfully',
      backup: insertRes.rows[0]
    });
  } catch (error: any) {
    console.error('Create Backup Error:', error);
    return reply.status(500).send({
      success: false,
      message: error?.message || 'Failed to create cloud backup.'
    });
  }
}

export async function listBackupsHandler(req: FastifyRequest, reply: FastifyReply) {
  const pool = getDbPool();
  const user = (req as any).user;

  let activeBusinessId = (req as any).businessAccess?.businessId || (req.headers['x-business-id'] as string) || (req.query as any)?.businessId;
  if (!activeBusinessId && user?.userId) {
    const bizRes = await pool.query(
      'SELECT id FROM business_profile WHERE owner_id = $1 ORDER BY created_at ASC LIMIT 1',
      [user.userId]
    );
    if (bizRes.rows.length > 0) activeBusinessId = bizRes.rows[0].id;
  }

  if (!activeBusinessId) {
    return reply.status(400).send({ success: false, message: 'Active business ID required.' });
  }

  try {
    const result = await pool.query(
      `SELECT id, business_id, backup_name, backup_type, file_size_bytes, record_count, device_name, created_at
       FROM cloud_backups
       WHERE business_id = $1
       ORDER BY created_at DESC`,
      [activeBusinessId]
    );

    return reply.send({
      success: true,
      backups: result.rows
    });
  } catch (error: any) {
    console.error('List Backups Error:', error);
    return reply.status(500).send({
      success: false,
      message: error?.message || 'Failed to list cloud backups.'
    });
  }
}

export async function getBackupByIdHandler(req: FastifyRequest, reply: FastifyReply) {
  const pool = getDbPool();
  const user = (req as any).user;
  const { id } = req.params as { id: string };

  let activeBusinessId = (req as any).businessAccess?.businessId || (req.headers['x-business-id'] as string) || (req.query as any)?.businessId;
  if (!activeBusinessId && user?.userId) {
    const bizRes = await pool.query(
      'SELECT id FROM business_profile WHERE owner_id = $1 ORDER BY created_at ASC LIMIT 1',
      [user.userId]
    );
    if (bizRes.rows.length > 0) activeBusinessId = bizRes.rows[0].id;
  }

  try {
    const result = await pool.query(
      `SELECT id, business_id, backup_name, file_size_bytes, record_count, device_name, backup_data, created_at
       FROM cloud_backups
       WHERE id = $1 AND business_id = $2`,
      [id, activeBusinessId]
    );

    if (result.rows.length === 0) {
      return reply.status(404).send({ success: false, message: 'Backup not found or unauthorized.' });
    }

    const row = result.rows[0];
    const parsedData = typeof row.backup_data === 'string' ? JSON.parse(row.backup_data) : row.backup_data;

    return reply.send({
      success: true,
      backup: {
        id: row.id,
        businessId: row.business_id,
        backupName: row.backup_name,
        fileSizeBytes: row.file_size_bytes,
        recordCount: row.record_count,
        deviceName: row.device_name,
        createdAt: row.created_at,
        data: parsedData
      }
    });
  } catch (error: any) {
    console.error('Get Backup Error:', error);
    return reply.status(500).send({
      success: false,
      message: error?.message || 'Failed to retrieve backup details.'
    });
  }
}

export async function restoreBackupHandler(req: FastifyRequest, reply: FastifyReply) {
  const pool = getDbPool();
  const user = (req as any).user;
  const { id } = req.params as { id: string };

  let activeBusinessId = (req as any).businessAccess?.businessId || (req.headers['x-business-id'] as string) || (req.body as any)?.businessId;
  if (!activeBusinessId && user?.userId) {
    const bizRes = await pool.query(
      'SELECT id FROM business_profile WHERE owner_id = $1 ORDER BY created_at ASC LIMIT 1',
      [user.userId]
    );
    if (bizRes.rows.length > 0) activeBusinessId = bizRes.rows[0].id;
  }

  if (!activeBusinessId) {
    return reply.status(400).send({ success: false, message: 'Active business ID required.' });
  }

  const client = await pool.connect();
  try {
    const backupRes = await client.query(
      'SELECT backup_data FROM cloud_backups WHERE id = $1 AND business_id = $2',
      [id, activeBusinessId]
    );

    if (backupRes.rows.length === 0) {
      client.release();
      return reply.status(404).send({ success: false, message: 'Backup not found or unauthorized.' });
    }

    const rawData = backupRes.rows[0].backup_data;
    const backupData = typeof rawData === 'string' ? JSON.parse(rawData) : rawData;

    await client.query('BEGIN');

    const restoredStats = {
      items: 0,
      parties: 0,
      salesOrders: 0,
      purchaseOrders: 0,
      payments: 0,
      expenses: 0
    };

    // Restore Items
    if (Array.isArray(backupData.items)) {
      for (const item of backupData.items) {
        if (!item.id || !item.name) continue;
        await client.query(
          `INSERT INTO items (
            id, business_id, name, sku, barcode, barcode_mode, unit, category, hsn_sac, location,
            purchase_price, selling_price, sale_price_tax_mode, purchase_price_tax_mode,
            discount_on_sale_price, discount_type, tax_rate_label, tax_rate_percent, stock, min_stock_alert,
            is_deleted, updated_at, server_version
          ) VALUES (
            $1, $2, $3, $4, $5, $6, $7, $8, $9, $10,
            $11, $12, $13, $14, $15, $16, $17, $18, $19, $20,
            $21, $22, $23
          )
          ON CONFLICT (id) DO UPDATE SET
            name = EXCLUDED.name,
            sku = EXCLUDED.sku,
            barcode = EXCLUDED.barcode,
            unit = EXCLUDED.unit,
            category = EXCLUDED.category,
            purchase_price = EXCLUDED.purchase_price,
            selling_price = EXCLUDED.selling_price,
            stock = EXCLUDED.stock,
            min_stock_alert = EXCLUDED.min_stock_alert,
            is_deleted = EXCLUDED.is_deleted,
            updated_at = EXCLUDED.updated_at,
            server_version = EXCLUDED.server_version`,
          [
            item.id,
            activeBusinessId,
            item.name,
            item.sku || '',
            item.barcode || '',
            item.barcode_mode || 'auto',
            item.unit || 'Pcs',
            item.category || 'General',
            item.hsn_sac || '',
            item.location || '',
            item.purchase_price || 0,
            item.selling_price || 0,
            item.sale_price_tax_mode || 'exclusive',
            item.purchase_price_tax_mode || 'exclusive',
            item.discount_on_sale_price || 0,
            item.discount_type || 'percentage',
            item.tax_rate_label || 'None',
            item.tax_rate_percent || 0,
            item.stock || 0,
            item.min_stock_alert || 5,
            item.is_deleted || 0,
            item.updated_at || new Date(),
            item.server_version || 1
          ]
        );
        restoredStats.items++;
      }
    }

    // Restore Parties
    if (Array.isArray(backupData.parties)) {
      for (const p of backupData.parties) {
        if (!p.id || !p.name) continue;
        await client.query(
          `INSERT INTO parties (
            id, business_id, name, category, contact_number, email, address,
            opening_balance, balance_type, credit_limit, city, party_type,
            is_deleted, updated_at, server_version
          ) VALUES (
            $1, $2, $3, $4, $5, $6, $7,
            $8, $9, $10, $11, $12,
            $13, $14, $15
          )
          ON CONFLICT (id) DO UPDATE SET
            name = EXCLUDED.name,
            category = EXCLUDED.category,
            contact_number = EXCLUDED.contact_number,
            email = EXCLUDED.email,
            address = EXCLUDED.address,
            opening_balance = EXCLUDED.opening_balance,
            balance_type = EXCLUDED.balance_type,
            credit_limit = EXCLUDED.credit_limit,
            city = EXCLUDED.city,
            party_type = EXCLUDED.party_type,
            is_deleted = EXCLUDED.is_deleted,
            updated_at = EXCLUDED.updated_at,
            server_version = EXCLUDED.server_version`,
          [
            p.id,
            activeBusinessId,
            p.name,
            p.category || 'General',
            p.contact_number || '',
            p.email || '',
            p.address || '',
            p.opening_balance || 0,
            p.balance_type || 'toReceive',
            p.credit_limit || 0,
            p.city || '',
            p.party_type || 'customer',
            p.is_deleted || 0,
            p.updated_at || new Date(),
            p.server_version || 1
          ]
        );
        restoredStats.parties++;
      }
    }

    // Restore Sales Orders
    if (Array.isArray(backupData.salesOrders)) {
      for (const s of backupData.salesOrders) {
        if (!s.id || !s.invoice_no) continue;
        await client.query(
          `INSERT INTO sales_orders (
            id, business_id, invoice_no, date, payment_mode, party_id, customer_name,
            items_json, total_amount, received_amount, payment_type, is_deleted, updated_at, server_version
          ) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13, $14)
          ON CONFLICT (id) DO UPDATE SET
            total_amount = EXCLUDED.total_amount,
            received_amount = EXCLUDED.received_amount,
            items_json = EXCLUDED.items_json,
            is_deleted = EXCLUDED.is_deleted,
            updated_at = EXCLUDED.updated_at,
            server_version = EXCLUDED.server_version`,
          [
            s.id,
            activeBusinessId,
            parseSequentialNumber(s.invoice_no, 1001),
            s.date || new Date().toISOString(),
            s.payment_mode || 'Cash',
            toValidUuidOrNull(s.party_id),
            s.customer_name || 'Walk-in Customer',
            typeof s.items_json === 'string' ? s.items_json : JSON.stringify(s.items_json || []),
            s.total_amount || 0,
            s.received_amount || 0,
            s.payment_type || 'Full Payment',
            s.is_deleted || 0,
            s.updated_at || new Date(),
            s.server_version || 1
          ]
        );
        restoredStats.salesOrders++;
      }
    }

    // Restore Purchase Orders
    if (Array.isArray(backupData.purchaseOrders)) {
      for (const po of backupData.purchaseOrders) {
        if (!po.id || !po.order_no) continue;
        await client.query(
          `INSERT INTO purchase_orders (
            id, business_id, order_no, date, party_name, items_json, total_amount,
            is_deleted, updated_at, server_version
          ) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10)
          ON CONFLICT (id) DO UPDATE SET
            total_amount = EXCLUDED.total_amount,
            items_json = EXCLUDED.items_json,
            is_deleted = EXCLUDED.is_deleted,
            updated_at = EXCLUDED.updated_at,
            server_version = EXCLUDED.server_version`,
          [
            po.id,
            activeBusinessId,
            parseSequentialNumber(po.order_no, 2001),
            po.date || new Date().toISOString(),
            po.party_name || 'Vendor',
            typeof po.items_json === 'string' ? po.items_json : JSON.stringify(po.items_json || []),
            po.total_amount || 0,
            po.is_deleted || 0,
            po.updated_at || new Date(),
            po.server_version || 1
          ]
        );
        restoredStats.purchaseOrders++;
      }
    }

    // Restore Payments
    if (Array.isArray(backupData.payments)) {
      for (const pay of backupData.payments) {
        if (!pay.id || !pay.receipt_no) continue;
        await client.query(
          `INSERT INTO payments (
            id, business_id, receipt_no, date, party_id, party_name, received_amount,
            payment_type, is_payment_out, is_deleted, updated_at, server_version
          ) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12)
          ON CONFLICT (id) DO UPDATE SET
            received_amount = EXCLUDED.received_amount,
            is_deleted = EXCLUDED.is_deleted,
            updated_at = EXCLUDED.updated_at,
            server_version = EXCLUDED.server_version`,
          [
            pay.id,
            activeBusinessId,
            parseSequentialNumber(pay.receipt_no, 501),
            pay.date || new Date().toISOString(),
            toValidUuidOrNull(pay.party_id),
            pay.party_name || '',
            pay.received_amount || 0,
            pay.payment_type || 'Cash',
            pay.is_payment_out || 0,
            pay.is_deleted || 0,
            pay.updated_at || new Date(),
            pay.server_version || 1
          ]
        );
        restoredStats.payments++;
      }
    }

    // Restore Expenses
    if (Array.isArray(backupData.expenses)) {
      for (const e of backupData.expenses) {
        if (!e.id || !e.expense_category) continue;
        await client.query(
          `INSERT INTO expenses (
            id, business_id, expense_category, amount, expense_date, payment_mode, notes,
            is_deleted, updated_at, server_version
          ) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10)
          ON CONFLICT (id) DO UPDATE SET
            amount = EXCLUDED.amount,
            is_deleted = EXCLUDED.is_deleted,
            updated_at = EXCLUDED.updated_at,
            server_version = EXCLUDED.server_version`,
          [
            e.id,
            activeBusinessId,
            e.expense_category,
            e.amount || 0,
            e.expense_date || new Date().toISOString().split('T')[0],
            e.payment_mode || 'Cash',
            e.notes || '',
            e.is_deleted || 0,
            e.updated_at || new Date(),
            e.server_version || 1
          ]
        );
        restoredStats.expenses++;
      }
    }

    await client.query('COMMIT');
    client.release();

    return reply.send({
      success: true,
      message: 'Cloud backup restored successfully',
      restoredStats
    });
  } catch (error: any) {
    await client.query('ROLLBACK');
    client.release();
    console.error('Restore Backup Error:', error);
    return reply.status(500).send({
      success: false,
      message: error?.message || 'Failed to restore cloud backup.'
    });
  }
}

export async function deleteBackupHandler(req: FastifyRequest, reply: FastifyReply) {
  const pool = getDbPool();
  const user = (req as any).user;
  const { id } = req.params as { id: string };

  let activeBusinessId = (req as any).businessAccess?.businessId || (req.headers['x-business-id'] as string) || (req.query as any)?.businessId;
  if (!activeBusinessId && user?.userId) {
    const bizRes = await pool.query(
      'SELECT id FROM business_profile WHERE owner_id = $1 ORDER BY created_at ASC LIMIT 1',
      [user.userId]
    );
    if (bizRes.rows.length > 0) activeBusinessId = bizRes.rows[0].id;
  }

  try {
    const result = await pool.query(
      'DELETE FROM cloud_backups WHERE id = $1 AND business_id = $2 RETURNING id',
      [id, activeBusinessId]
    );

    if (result.rows.length === 0) {
      return reply.status(404).send({ success: false, message: 'Backup not found or unauthorized.' });
    }

    return reply.send({
      success: true,
      message: 'Cloud backup deleted successfully'
    });
  } catch (error: any) {
    console.error('Delete Backup Error:', error);
    return reply.status(500).send({
      success: false,
      message: error?.message || 'Failed to delete backup.'
    });
  }
}

export async function downloadBackupHandler(req: FastifyRequest, reply: FastifyReply) {
  const pool = getDbPool();
  const { id } = req.params as { id: string };
  const activeBusinessId = (req as any).businessAccess?.businessId || (req.headers['x-business-id'] as string) || (req.query as any)?.businessId;

  if (!activeBusinessId) {
    return reply.status(400).send({ success: false, message: 'x-business-id is required.' });
  }

  try {
    const res = await pool.query(
      `SELECT backup_name, backup_data, created_at FROM cloud_backups WHERE id = $1 AND business_id = $2`,
      [id, activeBusinessId]
    );

    if (res.rows.length === 0) {
      return reply.status(404).send({ success: false, message: 'Backup not found.' });
    }

    const row = res.rows[0];
    const cleanName = (row.backup_name || 'backup').replace(/[^a-zA-Z0-9_-]/g, '_');
    const safeData = typeof row.backup_data === 'string' ? row.backup_data : JSON.stringify(row.backup_data, null, 2);

    reply.header('Content-Type', 'application/json');
    reply.header('Content-Disposition', `attachment; filename="joyn_backup_${cleanName}.json"`);
    return reply.send(safeData);
  } catch (error: any) {
    return reply.status(500).send({ success: false, message: error?.message || 'Download failed.' });
  }
}

export async function getBackupSettingsHandler(req: FastifyRequest, reply: FastifyReply) {
  const pool = getDbPool();
  const activeBusinessId = (req as any).businessAccess?.businessId || (req.headers['x-business-id'] as string) || (req.query as any)?.businessId;

  if (!activeBusinessId) {
    return reply.status(400).send({ success: false, message: 'x-business-id is required.' });
  }

  try {
    const res = await pool.query(
      `SELECT * FROM backup_settings WHERE business_id = $1`,
      [activeBusinessId]
    );

    if (res.rows.length === 0) {
      return reply.send({
        success: true,
        settings: {
          businessId: activeBusinessId,
          autoBackupEnabled: true,
          frequency: 'DAILY',
          retentionDays: 30,
          lastAutoBackupAt: null
        }
      });
    }

    const row = res.rows[0];
    return reply.send({
      success: true,
      settings: {
        businessId: row.business_id,
        autoBackupEnabled: row.auto_backup_enabled ?? true,
        frequency: row.frequency || 'DAILY',
        retentionDays: row.retention_days || 30,
        lastAutoBackupAt: row.last_auto_backup_at
      }
    });
  } catch (error: any) {
    return reply.status(500).send({ success: false, message: error?.message || 'Failed to fetch settings.' });
  }
}

export async function updateBackupSettingsHandler(req: FastifyRequest, reply: FastifyReply) {
  const pool = getDbPool();
  const activeBusinessId = (req as any).businessAccess?.businessId || (req.headers['x-business-id'] as string) || (req.body as any)?.businessId;
  const { autoBackupEnabled = true, frequency = 'DAILY', retentionDays = 30 } = (req.body as any) || {};

  if (!activeBusinessId) {
    return reply.status(400).send({ success: false, message: 'x-business-id is required.' });
  }

  try {
    const res = await pool.query(
      `INSERT INTO backup_settings (business_id, auto_backup_enabled, frequency, retention_days, updated_at)
       VALUES ($1, $2, $3, $4, CURRENT_TIMESTAMP)
       ON CONFLICT (business_id) DO UPDATE SET
         auto_backup_enabled = EXCLUDED.auto_backup_enabled,
         frequency = EXCLUDED.frequency,
         retention_days = EXCLUDED.retention_days,
         updated_at = CURRENT_TIMESTAMP
       RETURNING *`,
      [activeBusinessId, autoBackupEnabled, frequency.toUpperCase(), retentionDays]
    );

    return reply.send({
      success: true,
      message: 'Backup settings updated successfully.',
      settings: {
        businessId: res.rows[0].business_id,
        autoBackupEnabled: res.rows[0].auto_backup_enabled,
        frequency: res.rows[0].frequency,
        retentionDays: res.rows[0].retention_days,
        lastAutoBackupAt: res.rows[0].last_auto_backup_at
      }
    });
  } catch (error: any) {
    return reply.status(500).send({ success: false, message: error?.message || 'Failed to update settings.' });
  }
}

export async function triggerManualCronBackupHandler(req: FastifyRequest, reply: FastifyReply) {
  const activeBusinessId = (req as any).businessAccess?.businessId || (req.headers['x-business-id'] as string) || (req.body as any)?.businessId;

  if (!activeBusinessId) {
    return reply.status(400).send({ success: false, message: 'x-business-id is required.' });
  }

  try {
    const backup = await performAutoBackupForBusiness(activeBusinessId);
    return reply.send({
      success: true,
      message: 'Automated cloud backup triggered and completed successfully.',
      backup
    });
  } catch (error: any) {
    return reply.status(500).send({ success: false, message: error?.message || 'Cron backup execution failed.' });
  }
}
