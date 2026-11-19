import { FastifyRequest, FastifyReply } from 'fastify';
import { getDbPool } from '../db/connection.js';

function toValidUuidOrNull(val: any): string | null {
  if (typeof val !== 'string' || !val) return null;
  const uuidRegex = /^[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i;
  return uuidRegex.test(val) ? val : null;
}

function parseItems(itemsJson: any): any[] {
  if (!itemsJson) return [];
  if (Array.isArray(itemsJson)) return itemsJson;
  if (typeof itemsJson === 'string') {
    try {
      const parsed = JSON.parse(itemsJson);
      return Array.isArray(parsed) ? parsed : [];
    } catch {
      return [];
    }
  }
  return [];
}

// ============================================================================
// 1. QUOTATIONS / ESTIMATES ENGINE
// ============================================================================

export async function listQuotationsHandler(req: FastifyRequest, reply: FastifyReply) {
  try {
    const activeBusinessId = (req as any).businessAccess?.businessId || (req.headers['x-business-id'] as string) || (req.query as any)?.businessId;
    if (!activeBusinessId) {
      return reply.status(400).send({ success: false, message: 'x-business-id is required.' });
    }

    const { status, limit = 100 } = (req.query as any) || {};
    const pool = getDbPool();

    let query = `
      SELECT q.*, p.name as party_name_db, p.contact_number as party_phone_db
      FROM quotations q
      LEFT JOIN parties p ON q.party_id = p.id
      WHERE q.business_id = $1
    `;
    const params: any[] = [activeBusinessId];

    if (status) {
      params.push(status);
      query += ` AND q.status = $${params.length}`;
    }

    query += ` ORDER BY q.date DESC, q.quotation_no DESC LIMIT ${parseInt(limit) || 100}`;

    const res = await pool.query(query, params);
    const totalAmount = res.rows.reduce((sum: number, r: any) => sum + parseFloat(r.total_amount || 0), 0);

    return reply.send({
      success: true,
      count: res.rows.length,
      totalAmount: parseFloat(totalAmount.toFixed(2)),
      quotations: res.rows.map((r: any) => ({
        id: r.id,
        quotationNo: r.quotation_no,
        date: r.date,
        expiryDate: r.expiry_date,
        partyId: r.party_id,
        customerName: r.customer_name || r.party_name_db || 'Customer',
        customerPhone: r.customer_phone || r.party_phone_db || '',
        items: parseItems(r.items_json),
        totalAmount: parseFloat(r.total_amount || 0),
        status: r.status,
        convertedInvoiceId: r.converted_invoice_id,
        notes: r.notes || '',
        createdAt: r.created_at
      }))
    });
  } catch (error: any) {
    console.error('List Quotations Error:', error);
    return reply.status(500).send({ success: false, message: error?.message || 'Failed to list quotations.' });
  }
}

export async function createQuotationHandler(req: FastifyRequest, reply: FastifyReply) {
  try {
    const activeBusinessId = (req as any).businessAccess?.businessId || (req.headers['x-business-id'] as string) || (req.body as any)?.businessId;
    if (!activeBusinessId) {
      return reply.status(400).send({ success: false, message: 'x-business-id is required.' });
    }

    const {
      date,
      expiryDate,
      partyId,
      customerName,
      partyName,
      customerPhone,
      partyPhone,
      items = [],
      totalAmount,
      subtotal,
      taxAmount,
      discountAmount,
      notes = ''
    } = (req.body as any) || {};

    const pool = getDbPool();

    // Auto-generate next quotation_no
    const maxRes = await pool.query(
      `SELECT COALESCE(MAX(quotation_no), 0) + 1 as next_no FROM quotations WHERE business_id = $1`,
      [activeBusinessId]
    );
    const quotationNo = maxRes.rows[0].next_no;

    const dateVal = date || new Date().toISOString().split('T')[0];
    const validPartyId = toValidUuidOrNull(partyId);
    const computedTotal = totalAmount != null ? parseFloat(totalAmount) : (parseFloat(subtotal || 0) + parseFloat(taxAmount || 0) - parseFloat(discountAmount || 0));
    const numTotal = isNaN(computedTotal) ? 0 : computedTotal;

    const res = await pool.query(
      `INSERT INTO quotations (
        business_id, quotation_no, date, expiry_date, party_id, customer_name, customer_phone, items_json, total_amount, status, notes
      ) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, 'OPEN', $10)
      RETURNING *`,
      [
        activeBusinessId,
        quotationNo,
        dateVal,
        expiryDate || null,
        validPartyId,
        customerName || partyName || 'Customer',
        customerPhone || partyPhone || '',
        JSON.stringify(items),
        numTotal,
        notes
      ]
    );

    return reply.status(201).send({
      success: true,
      message: `Quotation QT-${quotationNo} created successfully.`,
      quotation: res.rows[0]
    });
  } catch (error: any) {
    console.error('Create Quotation Error:', error);
    return reply.status(500).send({ success: false, message: error?.message || 'Failed to create quotation.' });
  }
}

export async function getQuotationByIdHandler(req: FastifyRequest, reply: FastifyReply) {
  try {
    const { id } = req.params as { id: string };
    const validId = toValidUuidOrNull(id);
    const activeBusinessId = (req as any).businessAccess?.businessId || (req.headers['x-business-id'] as string);

    if (!validId) {
      return reply.status(400).send({ success: false, message: 'Valid quotation ID is required.' });
    }

    if (!activeBusinessId) {
      return reply.status(400).send({ success: false, message: 'x-business-id is required.' });
    }

    const pool = getDbPool();
    const res = await pool.query(
      `SELECT * FROM quotations WHERE id = $1 AND business_id = $2 LIMIT 1`,
      [validId, activeBusinessId]
    );

    if (res.rows.length === 0) {
      return reply.status(404).send({ success: false, message: 'Quotation not found.' });
    }

    const q = res.rows[0];
    return reply.send({
      success: true,
      quotation: {
        id: q.id,
        quotationNo: q.quotation_no,
        date: q.date,
        expiryDate: q.expiry_date,
        partyId: q.party_id,
        customerName: q.customer_name,
        customerPhone: q.customer_phone,
        items: parseItems(q.items_json),
        totalAmount: parseFloat(q.total_amount || 0),
        status: q.status,
        convertedInvoiceId: q.converted_invoice_id,
        notes: q.notes,
        createdAt: q.created_at
      }
    });
  } catch (error: any) {
    return reply.status(500).send({ success: false, message: error?.message || 'Failed to fetch quotation.' });
  }
}

export async function updateQuotationStatusHandler(req: FastifyRequest, reply: FastifyReply) {
  try {
    const { id } = req.params as { id: string };
    const { status } = (req.body as any) || {};
    const validId = toValidUuidOrNull(id);
    const activeBusinessId = (req as any).businessAccess?.businessId || (req.headers['x-business-id'] as string);

    if (!validId || !status) {
      return reply.status(400).send({ success: false, message: 'Valid quotation ID and status required.' });
    }

    if (!activeBusinessId) {
      return reply.status(400).send({ success: false, message: 'x-business-id is required.' });
    }

    const pool = getDbPool();
    const res = await pool.query(
      `UPDATE quotations SET status = $1 WHERE id = $2 AND business_id = $3 RETURNING *`,
      [status.toUpperCase(), validId, activeBusinessId]
    );

    if (res.rows.length === 0) {
      return reply.status(404).send({ success: false, message: 'Quotation not found.' });
    }

    return reply.send({
      success: true,
      message: `Quotation status updated to ${status}.`,
      quotation: res.rows[0]
    });
  } catch (error: any) {
    return reply.status(500).send({ success: false, message: error?.message || 'Failed to update status.' });
  }
}

// 1-Tap Convert Quotation to Tax Invoice (Atomically assigns invoice_no, deducts stock, creates sales_orders)
export async function convertQuotationToInvoiceHandler(req: FastifyRequest, reply: FastifyReply) {
  const pool = getDbPool();
  const client = await pool.connect();
  try {
    const { id } = req.params as { id: string };
    const validId = toValidUuidOrNull(id);
    const activeBusinessId = (req as any).businessAccess?.businessId || (req.headers['x-business-id'] as string) || (req.body as any)?.businessId;

    if (!validId || !activeBusinessId) {
      return reply.status(400).send({ success: false, message: 'Valid quotation ID and business ID required.' });
    }

    await client.query('BEGIN');

    // 1. Fetch Quotation
    const qRes = await client.query(
      `SELECT * FROM quotations WHERE id = $1 AND business_id = $2 FOR UPDATE`,
      [validId, activeBusinessId]
    );
    if (qRes.rows.length === 0) {
      await client.query('ROLLBACK');
      return reply.status(404).send({ success: false, message: 'Quotation not found.' });
    }
    const q = qRes.rows[0];

    if (q.status === 'CONVERTED') {
      await client.query('ROLLBACK');
      return reply.status(400).send({
        success: false,
        message: 'This quotation has already been converted to an invoice.',
        convertedInvoiceId: q.converted_invoice_id
      });
    }

    // 2. Generate Next Invoice No
    const maxInvRes = await client.query(
      `SELECT COALESCE(MAX(invoice_no), 0) + 1 as next_no FROM sales_orders WHERE business_id = $1`,
      [activeBusinessId]
    );
    const nextInvoiceNo = maxInvRes.rows[0].next_no;
    const items = parseItems(q.items_json);

    // 3. Insert into sales_orders
    const invRes = await client.query(
      `INSERT INTO sales_orders (
        business_id, invoice_no, date, payment_mode, party_id, customer_name, customer_phone,
        items_json, total_amount, received_amount, payment_type, description
      ) VALUES ($1, $2, CURRENT_DATE, 'Cash', $3, $4, $5, $6, $7, 0, 'Cash', $8)
      RETURNING *`,
      [
        activeBusinessId,
        nextInvoiceNo,
        q.party_id,
        q.customer_name,
        q.customer_phone,
        JSON.stringify(items),
        q.total_amount,
        `Converted from Quotation QT-${q.quotation_no}`
      ]
    );
    const newInvoice = invRes.rows[0];

    // 4. Atomically Deduct Stock from items
    for (const itm of items) {
      const itmId = toValidUuidOrNull(itm.itemId || itm.id);
      const qty = parseFloat(itm.quantity || itm.qty || 0);
      if (itmId && qty > 0) {
        await client.query(
          `UPDATE items SET stock = stock - $1, updated_at = CURRENT_TIMESTAMP WHERE id = $2 AND business_id = $3`,
          [qty, itmId, activeBusinessId]
        );
      }
    }

    // 5. Update Quotation status to CONVERTED
    await client.query(
      `UPDATE quotations SET status = 'CONVERTED', converted_invoice_id = $1 WHERE id = $2`,
      [newInvoice.id, validId]
    );

    await client.query('COMMIT');

    return reply.send({
      success: true,
      message: `Quotation QT-${q.quotation_no} successfully converted to Tax Invoice INV-${nextInvoiceNo}!`,
      invoiceId: newInvoice.id,
      invoiceNo: nextInvoiceNo,
      invoice: newInvoice,
      quotationId: validId
    });
  } catch (error: any) {
    await client.query('ROLLBACK');
    console.error('Convert Quotation Error:', error);
    return reply.status(500).send({ success: false, message: error?.message || 'Failed to convert quotation to invoice.' });
  } finally {
    client.release();
  }
}

// ============================================================================
// 2. CREDIT NOTES (SALES RETURN) ENGINE
// ============================================================================

export async function listCreditNotesHandler(req: FastifyRequest, reply: FastifyReply) {
  try {
    const activeBusinessId = (req as any).businessAccess?.businessId || (req.headers['x-business-id'] as string) || (req.query as any)?.businessId;
    if (!activeBusinessId) {
      return reply.status(400).send({ success: false, message: 'x-business-id is required.' });
    }

    const { limit = 100 } = (req.query as any) || {};
    const pool = getDbPool();

    const res = await pool.query(
      `SELECT cn.*, p.name as party_name_db, p.contact_number as party_phone_db
       FROM credit_notes cn
       LEFT JOIN parties p ON cn.party_id = p.id
       WHERE cn.business_id = $1
       ORDER BY cn.date DESC, cn.note_no DESC
       LIMIT ${parseInt(limit) || 100}`,
      [activeBusinessId]
    );

    const totalReturnAmount = res.rows.reduce((sum: number, r: any) => sum + parseFloat(r.return_amount || 0), 0);

    return reply.send({
      success: true,
      count: res.rows.length,
      totalReturnAmount: parseFloat(totalReturnAmount.toFixed(2)),
      creditNotes: res.rows.map((r: any) => ({
        id: r.id,
        noteNo: r.note_no,
        date: r.date,
        partyId: r.party_id,
        customerName: r.customer_name || r.party_name_db || 'Customer',
        originalInvoiceNo: r.original_invoice_no,
        items: parseItems(r.items_json),
        returnAmount: parseFloat(r.return_amount || 0),
        reason: r.reason || '',
        refundMode: r.refund_mode,
        createdAt: r.created_at
      }))
    });
  } catch (error: any) {
    console.error('List Credit Notes Error:', error);
    return reply.status(500).send({ success: false, message: error?.message || 'Failed to list credit notes.' });
  }
}

export async function createCreditNoteHandler(req: FastifyRequest, reply: FastifyReply) {
  const pool = getDbPool();
  const client = await pool.connect();
  try {
    const activeBusinessId = (req as any).businessAccess?.businessId || (req.headers['x-business-id'] as string) || (req.body as any)?.businessId;
    if (!activeBusinessId) {
      return reply.status(400).send({ success: false, message: 'x-business-id is required.' });
    }

    const {
      date,
      partyId,
      customerName,
      partyName,
      originalInvoiceNo,
      invoiceNo,
      items = [],
      returnAmount,
      totalAmount,
      reason = '',
      refundMode = 'CREDIT'
    } = (req.body as any) || {};

    await client.query('BEGIN');

    // Auto-increment note_no
    const maxRes = await client.query(
      `SELECT COALESCE(MAX(note_no), 0) + 1 as next_no FROM credit_notes WHERE business_id = $1`,
      [activeBusinessId]
    );
    const noteNo = maxRes.rows[0].next_no;
    const numAmount = parseFloat(returnAmount ?? totalAmount ?? 0);
    const validPartyId = toValidUuidOrNull(partyId);
    const dateVal = date || new Date().toISOString().split('T')[0];
    const parsedInvNo = originalInvoiceNo ? parseInt(originalInvoiceNo) : (invoiceNo ? parseInt(invoiceNo) : null);
    const safeInvNo = (parsedInvNo !== null && !isNaN(parsedInvNo)) ? parsedInvNo : null;

    // 1. Insert Credit Note
    const res = await client.query(
      `INSERT INTO credit_notes (
        business_id, note_no, date, party_id, customer_name, original_invoice_no, items_json, return_amount, reason, refund_mode
      ) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10)
      RETURNING *`,
      [
        activeBusinessId,
        noteNo,
        dateVal,
        validPartyId,
        customerName || partyName || 'Customer',
        safeInvNo,
        JSON.stringify(items),
        numAmount,
        reason,
        refundMode
      ]
    );
    const newNote = res.rows[0];

    // 2. RESTORE / ADD Stock back to items
    for (const itm of items) {
      const itmId = toValidUuidOrNull(itm.itemId || itm.id);
      const qty = parseFloat(itm.quantity || itm.qty || 0);
      if (itmId && qty > 0) {
        await client.query(
          `UPDATE items SET stock = stock + $1, updated_at = CURRENT_TIMESTAMP WHERE id = $2 AND business_id = $3`,
          [qty, itmId, activeBusinessId]
        );
      }
    }

    // 3. If refundMode is CREDIT and customer exists, credit customer balance (reduce amount they owe)
    if (validPartyId && refundMode === 'CREDIT' && numAmount > 0) {
      await client.query(
        `UPDATE parties 
         SET opening_balance = GREATEST(0, opening_balance - $1), updated_at = CURRENT_TIMESTAMP 
         WHERE id = $2 AND business_id = $3`,
        [numAmount, validPartyId, activeBusinessId]
      );
    }

    await client.query('COMMIT');

    return reply.status(201).send({
      success: true,
      message: `Credit Note CN-${noteNo} (Sales Return) recorded. Inventory restored and ledger credited.`,
      creditNote: newNote,
      noteNo: noteNo,
      noteId: newNote.id
    });
  } catch (error: any) {
    await client.query('ROLLBACK');
    console.error('Create Credit Note Error:', error);
    return reply.status(500).send({ success: false, message: error?.message || 'Failed to record credit note.' });
  } finally {
    client.release();
  }
}

// ============================================================================
// 3. DEBIT NOTES (PURCHASE RETURN) ENGINE
// ============================================================================

export async function listDebitNotesHandler(req: FastifyRequest, reply: FastifyReply) {
  try {
    const activeBusinessId = (req as any).businessAccess?.businessId || (req.headers['x-business-id'] as string) || (req.query as any)?.businessId;
    if (!activeBusinessId) {
      return reply.status(400).send({ success: false, message: 'x-business-id is required.' });
    }

    const { limit = 100 } = (req.query as any) || {};
    const pool = getDbPool();

    const res = await pool.query(
      `SELECT dn.*, p.name as supplier_name_db
       FROM debit_notes dn
       LEFT JOIN parties p ON dn.party_id = p.id
       WHERE dn.business_id = $1
       ORDER BY dn.date DESC, dn.note_no DESC
       LIMIT ${parseInt(limit) || 100}`,
      [activeBusinessId]
    );

    const totalReturnAmount = res.rows.reduce((sum: number, r: any) => sum + parseFloat(r.return_amount || 0), 0);

    return reply.send({
      success: true,
      count: res.rows.length,
      totalReturnAmount: parseFloat(totalReturnAmount.toFixed(2)),
      debitNotes: res.rows.map((r: any) => ({
        id: r.id,
        noteNo: r.note_no,
        date: r.date,
        partyId: r.party_id,
        supplierName: r.supplier_name || r.supplier_name_db || 'Supplier',
        originalOrderNo: r.original_order_no,
        items: parseItems(r.items_json),
        returnAmount: parseFloat(r.return_amount || 0),
        reason: r.reason || '',
        createdAt: r.created_at
      }))
    });
  } catch (error: any) {
    console.error('List Debit Notes Error:', error);
    return reply.status(500).send({ success: false, message: error?.message || 'Failed to list debit notes.' });
  }
}

export async function createDebitNoteHandler(req: FastifyRequest, reply: FastifyReply) {
  const pool = getDbPool();
  const client = await pool.connect();
  try {
    const activeBusinessId = (req as any).businessAccess?.businessId || (req.headers['x-business-id'] as string) || (req.body as any)?.businessId;
    if (!activeBusinessId) {
      return reply.status(400).send({ success: false, message: 'x-business-id is required.' });
    }

    const {
      date,
      partyId,
      supplierName,
      partyName,
      originalOrderNo,
      purchaseNo,
      invoiceNo,
      items = [],
      returnAmount,
      totalAmount,
      reason = ''
    } = (req.body as any) || {};

    await client.query('BEGIN');

    // Auto-increment note_no
    const maxRes = await client.query(
      `SELECT COALESCE(MAX(note_no), 0) + 1 as next_no FROM debit_notes WHERE business_id = $1`,
      [activeBusinessId]
    );
    const noteNo = maxRes.rows[0].next_no;
    const numAmount = parseFloat(returnAmount ?? totalAmount ?? 0);
    const validPartyId = toValidUuidOrNull(partyId);
    const dateVal = date || new Date().toISOString().split('T')[0];
    const parsedOrderNo = originalOrderNo ? parseInt(originalOrderNo) : (purchaseNo ? parseInt(purchaseNo) : (invoiceNo ? parseInt(invoiceNo) : null));
    const safeOrderNo = (parsedOrderNo !== null && !isNaN(parsedOrderNo)) ? parsedOrderNo : null;

    // 1. Insert Debit Note
    const res = await client.query(
      `INSERT INTO debit_notes (
        business_id, note_no, date, party_id, supplier_name, original_order_no, items_json, return_amount, reason
      ) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9)
      RETURNING *`,
      [
        activeBusinessId,
        noteNo,
        dateVal,
        validPartyId,
        supplierName || partyName || 'Supplier',
        safeOrderNo,
        JSON.stringify(items),
        numAmount,
        reason
      ]
    );
    const newNote = res.rows[0];

    // 2. DEDUCT Stock from items (as items sent back to supplier)
    for (const itm of items) {
      const itmId = toValidUuidOrNull(itm.itemId || itm.id);
      const qty = parseFloat(itm.quantity || itm.qty || 0);
      if (itmId && qty > 0) {
        await client.query(
          `UPDATE items SET stock = GREATEST(0, stock - $1), updated_at = CURRENT_TIMESTAMP WHERE id = $2 AND business_id = $3`,
          [qty, itmId, activeBusinessId]
        );
      }
    }

    // 3. If supplier exists, decrease payable balance
    if (validPartyId && numAmount > 0) {
      await client.query(
        `UPDATE parties 
         SET opening_balance = GREATEST(0, opening_balance - $1), updated_at = CURRENT_TIMESTAMP 
         WHERE id = $2 AND business_id = $3`,
        [numAmount, validPartyId, activeBusinessId]
      );
    }

    await client.query('COMMIT');

    return reply.status(201).send({
      success: true,
      message: `Debit Note DN-${noteNo} (Purchase Return) recorded. Defective inventory deducted and supplier balance debited.`,
      debitNote: newNote,
      noteNo: noteNo,
      noteId: newNote.id
    });
  } catch (error: any) {
    await client.query('ROLLBACK');
    console.error('Create Debit Note Error:', error);
    return reply.status(500).send({ success: false, message: error?.message || 'Failed to record debit note.' });
  } finally {
    client.release();
  }
}
