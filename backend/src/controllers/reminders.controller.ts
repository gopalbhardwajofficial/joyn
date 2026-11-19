import { FastifyRequest, FastifyReply } from 'fastify';
import { getDbPool } from '../db/connection.js';

function toValidUuidOrNull(val: any): string | null {
  if (typeof val !== 'string' || !val) return null;
  const uuidRegex = /^[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i;
  return uuidRegex.test(val) ? val : null;
}

// 1. Get Overdue Debtors (Parties with Outstanding Balance to Receive)
export async function getOverdueDebtorsHandler(req: FastifyRequest, reply: FastifyReply) {
  try {
    const activeBusinessId = (req as any).businessAccess?.businessId || (req.headers['x-business-id'] as string) || (req.query as any)?.businessId;
    if (!activeBusinessId) {
      return reply.status(400).send({ success: false, message: 'x-business-id is required.' });
    }

    const pool = getDbPool();

    const res = await pool.query(
      `SELECT p.id, p.name, p.category, p.contact_number, p.email, p.city,
              p.opening_balance as balance_due, p.credit_limit, p.updated_at,
              (SELECT MAX(pr.created_at) FROM payment_reminders pr WHERE pr.party_id = p.id) as last_reminder_sent
       FROM parties p
       WHERE p.business_id = $1 
         AND p.balance_type = 'toReceive' 
         AND p.opening_balance > 0
       ORDER BY p.opening_balance DESC`,
      [activeBusinessId]
    );

    const totalOverdue = res.rows.reduce((sum: number, r: any) => sum + parseFloat(r.balance_due || 0), 0);

    return reply.send({
      success: true,
      count: res.rows.length,
      totalOverdueAmount: totalOverdue,
      debtors: res.rows.map((r: any) => ({
        id: r.id,
        name: r.name,
        category: r.category || 'Customer',
        contactNumber: r.contact_number || '',
        email: r.email || '',
        city: r.city || '',
        balanceDue: parseFloat(r.balance_due || 0),
        creditLimit: parseFloat(r.credit_limit || 0),
        lastReminderSent: r.last_reminder_sent,
        updatedAt: r.updated_at
      }))
    });
  } catch (error: any) {
    console.error('Get Overdue Debtors Error:', error);
    return reply.status(500).send({ success: false, message: error?.message || 'Failed to fetch overdue debtors.' });
  }
}

// 2. Send Payment Reminder (Generates WhatsApp text, UPI deep link, logs reminder & notification)
export async function sendPaymentReminderHandler(req: FastifyRequest, reply: FastifyReply) {
  try {
    const activeBusinessId = (req as any).businessAccess?.businessId || (req.headers['x-business-id'] as string) || (req.body as any)?.businessId;
    const { partyId, channel = 'WHATSAPP', customNote = '' } = (req.body as any) || {};

    const validPartyId = toValidUuidOrNull(partyId);
    if (!validPartyId || !activeBusinessId) {
      return reply.status(400).send({ success: false, message: 'Valid partyId and activeBusinessId required.' });
    }

    const pool = getDbPool();

    // Fetch Party
    const partyRes = await pool.query(
      `SELECT * FROM parties WHERE id = $1 AND business_id = $2 LIMIT 1`,
      [validPartyId, activeBusinessId]
    );
    if (partyRes.rows.length === 0) {
      return reply.status(404).send({ success: false, message: 'Party not found.' });
    }
    const party = partyRes.rows[0];

    // Fetch Business Profile (for Name, UPI ID, Bank details)
    const bizRes = await pool.query(
      `SELECT business_name, phone1, upi_id, bank_name, account_number, ifsc_code FROM business_profile WHERE id = $1 LIMIT 1`,
      [activeBusinessId]
    );
    const biz = bizRes.rows[0] || {};

    const balanceDue = parseFloat(party.opening_balance || 0);
    const upiVpa = biz.upi_id || (biz.phone1 ? `${biz.phone1.replace(/\D/g, '').slice(-10)}@upi` : '');
    const upiString = upiVpa
      ? `upi://pay?pa=${upiVpa}&pn=${encodeURIComponent(biz.business_name || 'Store')}&am=${balanceDue.toFixed(2)}&cu=INR&tn=Due_Payment_${encodeURIComponent(party.name)}`
      : '';

    // Pre-formatted professional WhatsApp reminder text
    const messageText = 
`*PAYMENT REMINDER from ${biz.business_name || 'Our Store'}*
━━━━━━━━━━━━━━━━━━━━
Dear *${party.name}*,

This is a gentle reminder that a pending balance of *₹${balanceDue.toFixed(2)}* is due on your account.
${customNote ? `\n📝 *Note:* ${customNote}` : ''}
${upiString ? `\n💳 *Pay Instantly via UPI (GPay/PhonePe/Paytm):*\n${upiString}\n\nUPI ID: \`${upiVpa}\`` : ''}
${biz.bank_name ? `\n🏦 *Bank Transfer Details:*\nBank: ${biz.bank_name}\nA/c No: ${biz.account_number || 'N/A'}\nIFSC: ${biz.ifsc_code || 'N/A'}` : ''}

Kindly settle the dues at your earliest convenience. If already transferred, kindly share the payment receipt.
Thank you for your business!`;

    const cleanPhone = (party.contact_number || '').replace(/\D/g, '');
    const phoneParam = cleanPhone.length >= 10 ? (cleanPhone.startsWith('91') ? cleanPhone : '91' + cleanPhone.slice(-10)) : '';
    const whatsappUrl = `https://wa.me/${phoneParam}?text=${encodeURIComponent(messageText)}`;

    // 1. Insert into payment_reminders log
    const reminderRes = await pool.query(
      `INSERT INTO payment_reminders (
        business_id, party_id, party_name, party_phone, amount_due, reminder_type, channel, message_text, payment_link, status
      ) VALUES ($1, $2, $3, $4, $5, 'MANUAL', $6, $7, $8, 'SENT')
      RETURNING *`,
      [
        activeBusinessId,
        party.id,
        party.name,
        party.contact_number || '',
        balanceDue,
        channel,
        messageText,
        upiString
      ]
    );

    // 2. Insert into in-app notifications
    await pool.query(
      `INSERT INTO notifications (business_id, title, body, type, data, is_read)
       VALUES ($1, $2, $3, 'PAYMENT_REMINDER', $4, false)`,
      [
        activeBusinessId,
        `Payment Reminder Dispatched: ${party.name}`,
        `Sent reminder for ₹${balanceDue.toFixed(2)} via ${channel}.`,
        JSON.stringify({ partyId: party.id, partyName: party.name, amountDue: balanceDue, reminderId: reminderRes.rows[0].id })
      ]
    );

    return reply.send({
      success: true,
      message: 'Payment reminder prepared and logged successfully.',
      reminder: reminderRes.rows[0],
      messageText,
      whatsappUrl,
      paymentLink: upiString
    });
  } catch (error: any) {
    console.error('Send Reminder Error:', error);
    return reply.status(500).send({ success: false, message: error?.message || 'Failed to dispatch payment reminder.' });
  }
}

// 3. List Payment Reminders Audit History
export async function listRemindersHistoryHandler(req: FastifyRequest, reply: FastifyReply) {
  try {
    const activeBusinessId = (req as any).businessAccess?.businessId || (req.headers['x-business-id'] as string) || (req.query as any)?.businessId;
    const { limit = 50 } = (req.query as any) || {};

    if (!activeBusinessId) {
      return reply.status(400).send({ success: false, message: 'x-business-id is required.' });
    }

    const pool = getDbPool();
    const res = await pool.query(
      `SELECT * FROM payment_reminders WHERE business_id = $1 ORDER BY created_at DESC LIMIT ${parseInt(limit) || 50}`,
      [activeBusinessId]
    );

    return reply.send({
      success: true,
      count: res.rows.length,
      history: res.rows.map((r: any) => ({
        id: r.id,
        partyId: r.party_id,
        partyName: r.party_name,
        partyPhone: r.party_phone,
        amountDue: parseFloat(r.amount_due || 0),
        reminderType: r.reminder_type,
        channel: r.channel,
        status: r.status,
        createdAt: r.created_at
      }))
    });
  } catch (error: any) {
    return reply.status(500).send({ success: false, message: error?.message || 'Failed to fetch reminder history.' });
  }
}

// 4. Batch Automated Payment Reminders Dispatch
export async function triggerBatchAutomatedRemindersHandler(req: FastifyRequest, reply: FastifyReply) {
  try {
    const activeBusinessId = (req as any).businessAccess?.businessId || (req.headers['x-business-id'] as string) || (req.body as any)?.businessId;
    if (!activeBusinessId) {
      return reply.status(400).send({ success: false, message: 'x-business-id is required.' });
    }

    const pool = getDbPool();

    // Find all customers with overdue balance
    const debtors = await pool.query(
      `SELECT id, name, contact_number, opening_balance as balance_due 
       FROM parties 
       WHERE business_id = $1 AND balance_type = 'toReceive' AND opening_balance > 0`,
      [activeBusinessId]
    );

    let dispatchedCount = 0;
    let totalRemindedAmount = 0;

    for (const d of debtors.rows) {
      const balance = parseFloat(d.balance_due || 0);
      totalRemindedAmount += balance;

      await pool.query(
        `INSERT INTO payment_reminders (
          business_id, party_id, party_name, party_phone, amount_due, reminder_type, channel, status
        ) VALUES ($1, $2, $3, $4, $5, 'AUTOMATED', 'WHATSAPP', 'QUEUED')`,
        [activeBusinessId, d.id, d.name, d.contact_number || '', balance]
      );
      dispatchedCount++;
    }

    // Insert summary notification
    if (dispatchedCount > 0) {
      await pool.query(
        `INSERT INTO notifications (business_id, title, body, type, data, is_read)
         VALUES ($1, $2, $3, 'PAYMENT_REMINDER', $4, false)`,
        [
          activeBusinessId,
          `Automated Payment Reminders Processed`,
          `Queued ${dispatchedCount} reminders for total ₹${totalRemindedAmount.toFixed(2)}.`,
          JSON.stringify({ dispatchedCount, totalRemindedAmount })
        ]
      );
    }

    return reply.send({
      success: true,
      message: `Successfully processed automated reminders for ${dispatchedCount} debtors.`,
      dispatchedCount,
      totalRemindedAmount
    });
  } catch (error: any) {
    return reply.status(500).send({ success: false, message: error?.message || 'Failed to process automated reminders.' });
  }
}

