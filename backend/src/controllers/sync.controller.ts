import { FastifyRequest, FastifyReply } from 'fastify';
import { getDbPool } from '../db/connection.js';
import { getIstDateString, toDeterministicUuid, toValidUuidOrNull } from '../utils/common.utils.js';

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

export async function pushSyncHandler(req: FastifyRequest, reply: FastifyReply) {
  const pool = getDbPool();
  const user = (req as any).user;
  const body = req.body as any || {};

  let activeBusinessId = (req.headers['x-business-id'] as string) || body.businessId;
  if (!activeBusinessId && user?.userId) {
    const bizRes = await pool.query(
      'SELECT id FROM business_profile WHERE owner_id = $1 ORDER BY created_at ASC LIMIT 1',
      [user.userId]
    );
    if (bizRes.rows.length > 0) activeBusinessId = bizRes.rows[0].id;
  }

  if (!activeBusinessId) {
    return reply.status(400).send({ success: false, message: 'Active business ID required for sync.' });
  }

  const mutations = body.mutations || body;
  const items = Array.isArray(mutations.items) ? mutations.items : [];
  const parties = Array.isArray(mutations.parties) ? mutations.parties : [];
  const salesOrders = Array.isArray(mutations.salesOrders) ? mutations.salesOrders : [];
  const purchaseOrders = Array.isArray(mutations.purchaseOrders) ? mutations.purchaseOrders : [];
  const payments = Array.isArray(mutations.payments) ? mutations.payments : [];
  const expenses = Array.isArray(mutations.expenses) ? mutations.expenses : [];

  const client = await pool.connect();
  const stats = {
    items: 0,
    parties: 0,
    salesOrders: 0,
    purchaseOrders: 0,
    payments: 0,
    expenses: 0
  };

  try {
    await client.query('BEGIN');

    // 1. SYNC ITEMS (Last-Write-Wins based on updated_at)
    for (const item of items) {
      if (!item.id || !item.name) continue;
      const isDeleted = item.isDeleted === 1 || item.isDeleted === true ? 1 : 0;
      const updatedAt = item.updatedAt ? new Date(item.updatedAt) : new Date();

      const itemNum = item.itemNumber || item.item_number || null;
      const itemCode = item.itemCode || item.item_code || null;

      await client.query(
        `INSERT INTO items (
          id, business_id, name, sku, barcode, barcode_mode, unit, category, hsn_sac, location,
          purchase_price, selling_price, sale_price_tax_mode, purchase_price_tax_mode,
          discount_on_sale_price, discount_type, tax_rate_label, tax_rate_percent, stock, min_stock_alert,
          item_number, item_code, is_deleted, updated_at, server_version
        ) VALUES (
          $1, $2, $3, $4, $5, $6, $7, $8, $9, $10,
          $11, $12, $13, $14, $15, $16, $17, $18, $19, $20,
          $21, $22, $23, $24, 1
        )
        ON CONFLICT (id) DO UPDATE SET
          name = EXCLUDED.name,
          sku = EXCLUDED.sku,
          barcode = EXCLUDED.barcode,
          unit = EXCLUDED.unit,
          category = EXCLUDED.category,
          hsn_sac = EXCLUDED.hsn_sac,
          location = EXCLUDED.location,
          purchase_price = EXCLUDED.purchase_price,
          selling_price = EXCLUDED.selling_price,
          stock = EXCLUDED.stock,
          min_stock_alert = EXCLUDED.min_stock_alert,
          item_number = COALESCE(EXCLUDED.item_number, items.item_number),
          item_code = COALESCE(EXCLUDED.item_code, items.item_code),
          is_deleted = EXCLUDED.is_deleted,
          updated_at = EXCLUDED.updated_at,
          server_version = items.server_version + 1
        WHERE items.updated_at <= EXCLUDED.updated_at`,
        [
          toDeterministicUuid(item.id),
          activeBusinessId,
          item.name,
          item.sku || '',
          item.barcode || '',
          item.barcodeMode || 'same',
          item.unit || 'Pcs',
          item.category || 'General',
          item.hsnSac || '',
          item.location || '',
          parseFloat(item.purchasePrice || 0),
          parseFloat(item.sellingPrice || item.salePrice || 0),
          item.salePriceTaxMode || 'withoutTax',
          item.purchasePriceTaxMode || 'withoutTax',
          parseFloat(item.discountOnSalePrice || 0),
          item.discountType || 'percentage',
          item.taxRateLabel || 'None',
          parseFloat(item.taxRatePercent || 0),
          parseInt(item.stock || item.qty || 0, 10),
          parseInt(item.minStockAlert || 5, 10),
          itemNum,
          itemCode,
          isDeleted,
          updatedAt
        ]
      );
      stats.items++;
    }

    // 2. SYNC PARTIES (Last-Write-Wins)
    for (const party of parties) {
      if (!party.id || !party.name) continue;
      const isDeleted = party.isDeleted === 1 || party.isDeleted === true ? 1 : 0;
      const updatedAt = party.updatedAt ? new Date(party.updatedAt) : new Date();
      const partyNum = party.partyNumber || party.party_number || null;
      const partyCode = party.partyCode || party.party_code || null;

      await client.query(
        `INSERT INTO parties (
          id, business_id, name, category, contact_number, email, address,
          opening_balance, balance_type, credit_limit, city, party_type, priority_level,
          party_number, party_code, is_deleted, updated_at, server_version
        ) VALUES (
          $1, $2, $3, $4, $5, $6, $7,
          $8, $9, $10, $11, $12, $13,
          $14, $15, $16, $17, 1
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
          priority_level = EXCLUDED.priority_level,
          party_number = COALESCE(EXCLUDED.party_number, parties.party_number),
          party_code = COALESCE(EXCLUDED.party_code, parties.party_code),
          is_deleted = EXCLUDED.is_deleted,
          updated_at = EXCLUDED.updated_at,
          server_version = parties.server_version + 1
        WHERE parties.updated_at <= EXCLUDED.updated_at`,
        [
          toDeterministicUuid(party.id),
          activeBusinessId,
          party.name,
          party.category || 'General',
          party.contactNumber || party.phone || '',
          party.email || '',
          party.address || '',
          parseFloat(party.openingBalance || 0),
          party.balanceType || 'toReceive',
          parseFloat(party.creditLimit || 0),
          party.city || '',
          party.partyType || 'customer',
          party.priorityLevel || 'medium',
          partyNum,
          partyCode,
          isDeleted,
          updatedAt
        ]
      );
      stats.parties++;
    }

    // 3. SYNC SALES ORDERS (Append-Only Accounting Log + Stock Deduction)
    for (const order of salesOrders) {
      if (!order.id) continue;
      const orderId = toDeterministicUuid(order.id);
      const isDeleted = order.isDeleted === 1 || order.isDeleted === true ? 1 : 0;
      const updatedAt = order.updatedAt ? new Date(order.updatedAt) : new Date();

      // Check if order already exists on server
      const existing = await client.query('SELECT id, is_deleted FROM sales_orders WHERE id = $1', [orderId]);

      if (existing.rows.length === 0) {
        // New order -> Insert and deduct stock atomically
        const itemsList = Array.isArray(order.items) ? order.items : [];
        let invNo = parseSequentialNumber(order.invoiceNo, 0);
        if (invNo <= 0) {
          const maxInvRes = await client.query(
            `SELECT COALESCE(MAX(invoice_no), 1000) AS max_inv FROM sales_orders WHERE business_id = $1`,
            [activeBusinessId]
          );
          invNo = parseInt(maxInvRes.rows[0].max_inv, 10) + 1;
        }

        await client.query(
          `INSERT INTO sales_orders (
            id, business_id, invoice_no, date, payment_mode, is_one_time_customer,
            party_id, customer_name, customer_phone, items_json, total_amount,
            received_amount, payment_type, state_of_supply, description, terms_and_conditions,
            is_deleted, updated_at, server_version
          ) VALUES (
            $1, $2, $3, $4, $5, $6,
            $7, $8, $9, $10, $11,
            $12, $13, $14, $15, $16,
            $17, $18, 1
          )`,
          [
            orderId,
            activeBusinessId,
            invNo,
            getIstDateString(order.date),
            order.paymentMode || 'Cash',
            order.isOneTimeCustomer ? 1 : 0,
            toValidUuidOrNull(order.partyId),
            order.customerName || '',
            order.customerPhone || '',
            JSON.stringify(itemsList),
            parseFloat(order.totalAmount || 0),
            parseFloat(order.receivedAmount || 0),
            order.paymentType || 'Cash',
            order.stateOfSupply || '',
            order.description || '',
            order.termsAndConditions || '',
            isDeleted,
            updatedAt
          ]
        );

        // Deduct inventory stock
        for (const it of itemsList) {
          const itId = it.itemId || it.id;
          const qty = parseInt(it.quantity || it.qty || 1, 10);
          if (itId) {
            await client.query(
              `UPDATE items SET stock = stock - $1, updated_at = CURRENT_TIMESTAMP WHERE id = $2 AND business_id = $3`,
              [qty, toDeterministicUuid(itId), activeBusinessId]
            );
          }
        }
        stats.salesOrders++;
      } else if (isDeleted && existing.rows[0].is_deleted === 0) {
        // Marking deleted -> Soft delete order
        await client.query('UPDATE sales_orders SET is_deleted = 1, updated_at = $1 WHERE id = $2', [updatedAt, order.id]);
        stats.salesOrders++;
      }
    }

    // 4. SYNC PURCHASE ORDERS
    for (const po of purchaseOrders) {
      if (!po.id) continue;
      const poId = toDeterministicUuid(po.id);
      const isDeleted = po.isDeleted === 1 || po.isDeleted === true ? 1 : 0;
      const updatedAt = po.updatedAt ? new Date(po.updatedAt) : new Date();

      const existingPo = await client.query('SELECT id FROM purchase_orders WHERE id = $1', [poId]);
      if (existingPo.rows.length === 0) {
        const itemsList = Array.isArray(po.items) ? po.items : [];
        let ordNo = parseSequentialNumber(po.orderNo, 0);
        if (ordNo <= 0) {
          const maxOrderRes = await client.query(
            `SELECT COALESCE(MAX(order_no), 2000) AS max_ord FROM purchase_orders WHERE business_id = $1`,
            [activeBusinessId]
          );
          ordNo = parseInt(maxOrderRes.rows[0].max_ord, 10) + 1;
        }

        await client.query(
          `INSERT INTO purchase_orders (
            id, business_id, order_no, date, due_date, party_name, items_json, total_amount,
            is_deleted, updated_at, server_version
          ) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, 1)`,
          [
            poId,
            activeBusinessId,
            ordNo,
            getIstDateString(po.date),
            po.dueDate ? getIstDateString(po.dueDate) : '',
            po.partyName || '',
            JSON.stringify(itemsList),
            parseFloat(po.totalAmount || 0),
            isDeleted,
            updatedAt
          ]
        );

        // Increment inventory stock
        for (const it of itemsList) {
          const itId = it.itemId || it.id;
          const qty = parseInt(it.quantity || it.qty || 1, 10);
          if (itId) {
            await client.query(
              `UPDATE items SET stock = stock + $1, updated_at = CURRENT_TIMESTAMP WHERE id = $2 AND business_id = $3`,
              [qty, toDeterministicUuid(itId), activeBusinessId]
            );
          }
        }
        stats.purchaseOrders++;
      }
    }

    // 5. SYNC PAYMENTS
    for (const pay of payments) {
      if (!pay.id) continue;
      const payId = toDeterministicUuid(pay.id);
      const isDeleted = pay.isDeleted === 1 || pay.isDeleted === true ? 1 : 0;
      const updatedAt = pay.updatedAt ? new Date(pay.updatedAt) : new Date();

      let recNo = parseSequentialNumber(pay.receiptNo, 0);
      if (recNo <= 0) {
        const maxRecRes = await client.query(
          `SELECT COALESCE(MAX(receipt_no), 500) AS max_rec FROM payments WHERE business_id = $1`,
          [activeBusinessId]
        );
        recNo = parseInt(maxRecRes.rows[0].max_rec, 10) + 1;
      }

      await client.query(
        `INSERT INTO payments (
          id, business_id, receipt_no, date, party_id, party_name, party_phone,
          received_amount, payment_type, is_payment_out, is_deleted, updated_at, server_version
        ) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, 1)
        ON CONFLICT (id) DO UPDATE SET
          received_amount = EXCLUDED.received_amount,
          payment_type = EXCLUDED.payment_type,
          is_deleted = EXCLUDED.is_deleted,
          updated_at = EXCLUDED.updated_at,
          server_version = payments.server_version + 1
        WHERE payments.updated_at <= EXCLUDED.updated_at`,
        [
          payId,
          activeBusinessId,
          recNo,
          getIstDateString(pay.date || pay.paymentDate),
          toValidUuidOrNull(pay.partyId),
          pay.partyName || '',
          pay.partyPhone || '',
          parseFloat(pay.receivedAmount || pay.amount || 0),
          pay.paymentType || pay.paymentMode || 'Cash',
          pay.isPaymentOut ? 1 : 0,
          isDeleted,
          updatedAt
        ]
      );
      stats.payments++;
    }

    // 6. SYNC EXPENSES
    for (const exp of expenses) {
      if (!exp.id && !exp.amount) continue;
      const expId = toDeterministicUuid(exp.id || Date.now());
      const updatedAt = exp.updatedAt ? new Date(exp.updatedAt) : new Date();
      await client.query(
        `INSERT INTO expenses (
          id, business_id, expense_category, expense_type, amount, payment_mode, notes, expense_date, is_deleted, updated_at, server_version
        ) VALUES (
          COALESCE($1, gen_random_uuid()), $2, $3, $4, $5, $6, $7, $8, $9, $10, 1
        )
        ON CONFLICT (id) DO UPDATE SET
          expense_category = EXCLUDED.expense_category,
          amount = EXCLUDED.amount,
          notes = EXCLUDED.notes,
          is_deleted = EXCLUDED.is_deleted,
          updated_at = EXCLUDED.updated_at,
          server_version = expenses.server_version + 1
        WHERE expenses.updated_at <= EXCLUDED.updated_at`,
        [
          expId,
          activeBusinessId,
          exp.category || exp.expenseCategory || 'General',
          exp.expenseType || 'Indirect',
          parseFloat(exp.amount || 0),
          exp.paymentMode || 'Cash',
          exp.notes || '',
          getIstDateString(exp.expenseDate || exp.date),
          exp.isDeleted ? 1 : 0,
          updatedAt
        ]
      );
      stats.expenses++;
    }

    await client.query('COMMIT');

    return reply.send({
      success: true,
      message: 'Delta sync pushed successfully.',
      stats,
      processed: stats,
      serverSyncTimestamp: new Date().toISOString()
    });
  } catch (error: any) {
    await client.query('ROLLBACK');
    console.error('Push Sync Error:', error);
    return reply.status(500).send({ success: false, message: error?.message || 'Sync push failed.' });
  } finally {
    client.release();
  }
}

export async function pullSyncHandler(req: FastifyRequest, reply: FastifyReply) {
  try {
    const pool = getDbPool();
    const user = (req as any).user;
    const { since } = req.query as { since?: string };

    let activeBusinessId = (req.headers['x-business-id'] as string) || (req.query as any)?.businessId;
    if (!activeBusinessId && user?.userId) {
      const bizRes = await pool.query(
        'SELECT id FROM business_profile WHERE owner_id = $1 ORDER BY created_at ASC LIMIT 1',
        [user.userId]
      );
      if (bizRes.rows.length > 0) activeBusinessId = bizRes.rows[0].id;
    }

    if (!activeBusinessId) {
      return reply.status(400).send({ success: false, message: 'Active business ID required for sync pull.' });
    }

    // Default since date: 30 days ago if not provided
    const sinceDate = since ? new Date(since) : new Date(Date.now() - 30 * 24 * 60 * 60 * 1000);

    // Fetch updated/created records
    const [itemsRes, partiesRes, salesRes, purchasesRes, paymentsRes, expensesRes] = await Promise.all([
      pool.query(
        `SELECT * FROM items WHERE business_id = $1 AND (updated_at >= $2 OR created_at >= $2) ORDER BY updated_at ASC`,
        [activeBusinessId, sinceDate]
      ),
      pool.query(
        `SELECT * FROM parties WHERE business_id = $1 AND (updated_at >= $2 OR created_at >= $2) ORDER BY updated_at ASC`,
        [activeBusinessId, sinceDate]
      ),
      pool.query(
        `SELECT * FROM sales_orders WHERE business_id = $1 AND (updated_at >= $2 OR created_at >= $2) ORDER BY updated_at ASC`,
        [activeBusinessId, sinceDate]
      ),
      pool.query(
        `SELECT * FROM purchase_orders WHERE business_id = $1 AND (updated_at >= $2 OR created_at >= $2) ORDER BY updated_at ASC`,
        [activeBusinessId, sinceDate]
      ),
      pool.query(
        `SELECT * FROM payments WHERE business_id = $1 AND (updated_at >= $2 OR created_at >= $2) ORDER BY updated_at ASC`,
        [activeBusinessId, sinceDate]
      ),
      pool.query(
        `SELECT * FROM expenses WHERE business_id = $1 AND (updated_at >= $2 OR created_at >= $2) ORDER BY updated_at ASC`,
        [activeBusinessId, sinceDate]
      )
    ]);

    return reply.send({
      success: true,
      serverTimestamp: new Date().toISOString(),
      delta: {
        items: itemsRes.rows.map((i: any) => ({
          id: i.id,
          name: i.name,
          sku: i.sku || '',
          barcode: i.barcode || '',
          unit: i.unit || 'Pcs',
          category: i.category || 'General',
          purchasePrice: parseFloat(i.purchase_price || 0),
          sellingPrice: parseFloat(i.selling_price || 0),
          stock: parseInt(i.stock || 0, 10),
          minStockAlert: parseInt(i.min_stock_alert || 5, 10),
          itemNumber: i.item_number,
          itemCode: i.item_code || (i.item_number ? `ITM-${i.item_number}` : null),
          isDeleted: i.is_deleted === 1,
          updatedAt: i.updated_at,
          serverVersion: parseInt(i.server_version || 1, 10)
        })),
        parties: partiesRes.rows.map((p: any) => ({
          id: p.id,
          name: p.name,
          category: p.category || 'General',
          contactNumber: p.contact_number || '',
          email: p.email || '',
          address: p.address || '',
          openingBalance: parseFloat(p.opening_balance || 0),
          balanceType: p.balance_type || 'toReceive',
          creditLimit: parseFloat(p.credit_limit || 0),
          city: p.city || '',
          partyType: p.party_type || 'customer',
          partyNumber: p.party_number,
          partyCode: p.party_code || (p.party_number ? `PRT-${p.party_number}` : null),
          isDeleted: p.is_deleted === 1,
          updatedAt: p.updated_at,
          serverVersion: parseInt(p.server_version || 1, 10)
        })),
        salesOrders: salesRes.rows.map((s: any) => ({
          id: s.id,
          invoiceNo: s.invoice_no,
          date: getIstDateString(s.date),
          paymentMode: s.payment_mode,
          partyId: s.party_id,
          customerName: s.customer_name,
          items: typeof s.items_json === 'string' ? JSON.parse(s.items_json) : s.items_json,
          totalAmount: parseFloat(s.total_amount || 0),
          receivedAmount: parseFloat(s.received_amount || 0),
          paymentType: s.payment_type,
          isDeleted: s.is_deleted === 1,
          updatedAt: s.updated_at,
          serverVersion: parseInt(s.server_version || 1, 10)
        })),
        purchaseOrders: purchasesRes.rows.map((po: any) => ({
          id: po.id,
          orderNo: po.order_no,
          date: getIstDateString(po.date),
          partyName: po.party_name,
          items: typeof po.items_json === 'string' ? JSON.parse(po.items_json) : po.items_json,
          totalAmount: parseFloat(po.total_amount || 0),
          isDeleted: po.is_deleted === 1,
          updatedAt: po.updated_at,
          serverVersion: parseInt(po.server_version || 1, 10)
        })),
        payments: paymentsRes.rows.map((pay: any) => ({
          id: pay.id,
          receiptNo: pay.receipt_no,
          date: getIstDateString(pay.date),
          partyId: pay.party_id,
          partyName: pay.party_name,
          receivedAmount: parseFloat(pay.received_amount || 0),
          paymentType: pay.payment_type,
          isPaymentOut: pay.is_payment_out === 1,
          isDeleted: pay.is_deleted === 1,
          updatedAt: pay.updated_at,
          serverVersion: parseInt(pay.server_version || 1, 10)
        })),
        expenses: expensesRes.rows.map((e: any) => ({
          id: e.id,
          category: e.expense_category,
          amount: parseFloat(e.amount || 0),
          expenseDate: getIstDateString(e.expense_date),
          paymentMode: e.payment_mode,
          notes: e.notes || '',
          isDeleted: e.is_deleted === 1,
          updatedAt: e.updated_at,
          serverVersion: parseInt(e.server_version || 1, 10)
        }))
      }
    });
  } catch (error: any) {
    console.error('Pull Sync Error:', error);
    return reply.status(500).send({ success: false, message: error?.message || 'Sync pull failed.' });
  }
}
