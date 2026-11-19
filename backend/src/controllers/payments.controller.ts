import { FastifyRequest, FastifyReply } from 'fastify';
import { getDbPool } from '../db/connection.js';

export async function getPaymentsHandler(req: FastifyRequest, reply: FastifyReply) {
  try {
    const { businessId, partyId } = req.query as { businessId?: string; partyId?: string };
    const user = (req as any).user;
    const pool = getDbPool();

    let activeBusinessId = (req.headers['x-business-id'] as string) || businessId;
    if (!activeBusinessId && user?.userId) {
      const bizRes = await pool.query(
        'SELECT id FROM business_profile WHERE owner_id = $1 ORDER BY created_at ASC LIMIT 1',
        [user.userId]
      );
      if (bizRes.rows.length > 0) activeBusinessId = bizRes.rows[0].id;
    }

    if (!activeBusinessId) {
      return reply.send({ success: true, payments: [] });
    }

    let query = `SELECT * FROM payments WHERE business_id = $1`;
    const params: any[] = [activeBusinessId];

    if (partyId) {
      params.push(partyId);
      query += ` AND party_id = $${params.length}`;
    }

    query += ` ORDER BY receipt_no DESC, created_at DESC LIMIT 200`;

    const res = await pool.query(query, params);

    return reply.send({
      success: true,
      payments: res.rows.map((row: any) => ({
        id: row.id,
        businessId: row.business_id,
        receiptNo: row.receipt_no,
        date: row.date ? new Date(row.date).toISOString().split('T')[0] : '',
        partyId: row.party_id || '',
        partyName: row.party_name || '',
        partyPhone: row.party_phone || '',
        receivedAmount: parseFloat(row.received_amount || 0),
        paymentType: row.payment_type || 'Cash',
        isPaymentOut: row.is_payment_out === 1,
        createdAt: row.created_at
      }))
    });
  } catch (error: any) {
    return reply.status(500).send({ success: false, message: error?.message || 'Failed to fetch payments.' });
  }
}

export async function createPaymentHandler(req: FastifyRequest, reply: FastifyReply) {
  const pool = getDbPool();
  const client = await pool.connect();

  try {
    const user = (req as any).user;
    const {
      id,
      businessId,
      date,
      partyId,
      partyName,
      partyPhone,
      receivedAmount,
      paymentType,
      isPaymentOut
    } = req.body as any;

    let activeBusinessId = businessId || (req.headers['x-business-id'] as string);
    if (!activeBusinessId && user?.userId) {
      const bizRes = await client.query(
        'SELECT id FROM business_profile WHERE owner_id = $1 ORDER BY created_at ASC LIMIT 1',
        [user.userId]
      );
      if (bizRes.rows.length > 0) activeBusinessId = bizRes.rows[0].id;
    }

    if (!activeBusinessId) {
      client.release();
      return reply.status(400).send({ success: false, message: 'Active business ID required to record payment.' });
    }

    // Start ACID Transaction
    await client.query('BEGIN');

    // 1. Get next sequential receipt number
    const maxRecRes = await client.query(
      `SELECT COALESCE(MAX(receipt_no), 500) AS max_rec FROM payments WHERE business_id = $1`,
      [activeBusinessId]
    );
    const nextReceiptNo = parseInt(maxRecRes.rows[0].max_rec, 10) + 1;

    const parsedAmount = parseFloat(receivedAmount || 0);
    const paymentDate = date ? new Date(date) : new Date();
    const isOutFlag = isPaymentOut === true || isPaymentOut === 1 ? 1 : 0;

function toValidUuidOrNull(val: any): string | null {
  if (typeof val !== 'string' || !val) return null;
  const uuidRegex = /^[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i;
  return uuidRegex.test(val) ? val : null;
}

    const validId = toValidUuidOrNull(id);
    const validPartyId = toValidUuidOrNull(partyId);

    // 2. Insert into payments
    const insertRes = await client.query(
      `INSERT INTO payments (
        id, business_id, receipt_no, date, party_id, party_name, party_phone,
        received_amount, payment_type, is_payment_out
      ) VALUES (
        COALESCE($1, gen_random_uuid()), $2, $3, $4, $5, $6, $7, $8, $9, $10
      ) RETURNING *`,
      [
        validId,
        activeBusinessId,
        nextReceiptNo,
        paymentDate,
        validPartyId,
        partyName || 'Party',
        partyPhone || '',
        parsedAmount,
        paymentType || 'Cash',
        isOutFlag
      ]
    );

    const createdPayment = insertRes.rows[0];

    // 3. Adjust party opening balance in parties table
    if (validPartyId) {
      // Payment In reduces amount to receive; Payment Out reduces amount to pay
      await client.query(
        `UPDATE parties SET opening_balance = opening_balance - $1 WHERE id = $2 AND business_id = $3`,
        [parsedAmount, validPartyId, activeBusinessId]
      );
    }

    // 4. Audit Log
    let logMemberId = null;
    let logMemberName = null;
    try {
      const cleanPhone = (user.phone || '').replace(/\D/g, '').slice(-10);
      const mRes = await client.query(
        `SELECT id, name FROM team_members 
         WHERE business_id = $1 AND (user_id = $2 OR (phone IS NOT NULL AND RIGHT(phone, 10) = $3))
         LIMIT 1`,
        [activeBusinessId, user.userId, cleanPhone]
      );
      if (mRes.rows.length > 0) {
        logMemberId = mRes.rows[0].id;
        logMemberName = mRes.rows[0].name;
      }
    } catch (_) {}

    await client.query(
      `INSERT INTO activity_logs (business_id, user_id, user_name, module, action, details, member_id, member_name, activity_type, title, subtitle, amount)
       VALUES ($1, $2, $3, 'Payments', 'CREATE', $4, $5, $6, 'custAddedModified', $7, $8, $9)`,
      [
        activeBusinessId,
        user.userId,
        user.phone || 'User',
        `Payment ${isOutFlag === 1 ? 'Out' : 'In'} #${nextReceiptNo} recorded: ₹${parsedAmount.toFixed(2)} (${paymentType || 'Cash'})`,
        logMemberId,
        logMemberName,
        `Payment ${isOutFlag === 1 ? 'Out' : 'In'}`,
        `Receipt #${nextReceiptNo} - ${partyName || 'Walk-in'} (${paymentType || 'Cash'})`,
        parsedAmount
      ]
    );

    await client.query('COMMIT');
    client.release();

    return reply.status(201).send({
      success: true,
      message: 'Payment recorded successfully',
      payment: {
        id: createdPayment.id,
        businessId: createdPayment.business_id,
        receiptNo: createdPayment.receipt_no,
        date: createdPayment.date ? new Date(createdPayment.date).toISOString().split('T')[0] : '',
        partyId: createdPayment.party_id,
        partyName: createdPayment.party_name,
        partyPhone: createdPayment.party_phone,
        receivedAmount: parseFloat(createdPayment.received_amount),
        paymentType: createdPayment.payment_type,
        isPaymentOut: createdPayment.is_payment_out === 1,
        createdAt: createdPayment.created_at
      }
    });
  } catch (error: any) {
    await client.query('ROLLBACK');
    client.release();
    console.error('Create Payment Error:', error);
    return reply.status(500).send({ success: false, message: error?.message || 'Failed to record payment.' });
  }
}
