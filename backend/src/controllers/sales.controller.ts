import { FastifyRequest, FastifyReply } from 'fastify';
import { getDbPool } from '../db/connection.js';
import { getIstDateString, toDeterministicUuid, toValidUuidOrNull } from '../utils/common.utils.js';

export async function getSalesOrdersHandler(req: FastifyRequest, reply: FastifyReply) {
  try {
    const { businessId, partyId, startDate, endDate } = req.query as {
      businessId?: string;
      partyId?: string;
      startDate?: string;
      endDate?: string;
    };
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
      return reply.send({ success: true, orders: [] });
    }

    let query = `SELECT * FROM sales_orders WHERE business_id = $1`;
    const params: any[] = [activeBusinessId];

    if (partyId) {
      params.push(partyId);
      query += ` AND party_id = $${params.length}`;
    }

    if (startDate) {
      params.push(startDate);
      query += ` AND date >= $${params.length}`;
    }

    if (endDate) {
      params.push(endDate);
      query += ` AND date <= $${params.length}`;
    }

    query += ` ORDER BY invoice_no DESC, created_at DESC LIMIT 200`;

    const res = await pool.query(query, params);

    return reply.send({
      success: true,
      orders: res.rows.map((row: any) => ({
        id: row.id,
        businessId: row.business_id,
        invoiceNo: row.invoice_no,
        date: getIstDateString(row.date),
        paymentMode: row.payment_mode || 'Cash',
        isOneTimeCustomer: row.is_one_time_customer === 1,
        partyId: row.party_id || '',
        customerName: row.customer_name || '',
        customerPhone: row.customer_phone || '',
        items: typeof row.items_json === 'string' ? JSON.parse(row.items_json) : row.items_json,
        totalAmount: parseFloat(row.total_amount || 0),
        receivedAmount: parseFloat(row.received_amount || 0),
        paymentType: row.payment_type || 'Cash',
        stateOfSupply: row.state_of_supply || '',
        description: row.description || '',
        termsAndConditions: row.terms_and_conditions || '',
        createdAt: row.created_at
      }))
    });
  } catch (error: any) {
    return reply.status(500).send({ success: false, message: error?.message || 'Failed to fetch sales orders.' });
  }
}

export async function getSaleOrderByIdHandler(req: FastifyRequest, reply: FastifyReply) {
  try {
    const { id } = req.params as { id: string };
    const pool = getDbPool();

    const res = await pool.query('SELECT * FROM sales_orders WHERE id = $1 LIMIT 1', [id]);
    if (res.rows.length === 0) {
      return reply.status(404).send({ success: false, message: 'Sale order not found.' });
    }

    const row = res.rows[0];
    return reply.send({
      success: true,
      order: {
        id: row.id,
        businessId: row.business_id,
        invoiceNo: row.invoice_no,
        date: getIstDateString(row.date),
        paymentMode: row.payment_mode || 'Cash',
        isOneTimeCustomer: row.is_one_time_customer === 1,
        partyId: row.party_id || '',
        customerName: row.customer_name || '',
        customerPhone: row.customer_phone || '',
        items: typeof row.items_json === 'string' ? JSON.parse(row.items_json) : row.items_json,
        totalAmount: parseFloat(row.total_amount || 0),
        receivedAmount: parseFloat(row.received_amount || 0),
        paymentType: row.payment_type || 'Cash',
        stateOfSupply: row.state_of_supply || '',
        description: row.description || '',
        termsAndConditions: row.terms_and_conditions || '',
        createdAt: row.created_at
      }
    });
  } catch (error: any) {
    return reply.status(500).send({ success: false, message: error?.message || 'Failed to fetch sale order.' });
  }
}

export async function createSaleOrderHandler(req: FastifyRequest, reply: FastifyReply) {
  const pool = getDbPool();
  const client = await pool.connect();

  try {
    const user = (req as any).user;
    const {
      id,
      businessId,
      date,
      paymentMode,
      isOneTimeCustomer,
      partyId,
      customerName,
      customerPhone,
      items,
      totalAmount,
      receivedAmount,
      paymentType,
      stateOfSupply,
      description,
      termsAndConditions
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
      return reply.status(400).send({ success: false, message: 'Active business ID required to create sales invoice.' });
    }

    // Start ACID Transaction
    await client.query('BEGIN');

    const body = req.body as any || {};
    let nextInvoiceNo: number;
    if (body.invoiceNo && parseInt(body.invoiceNo, 10) > 0) {
      nextInvoiceNo = parseInt(body.invoiceNo, 10);
    } else if (body.invoice_no && parseInt(body.invoice_no, 10) > 0) {
      nextInvoiceNo = parseInt(body.invoice_no, 10);
    } else {
      const maxInvRes = await client.query(
        `SELECT COALESCE(MAX(invoice_no), 1000) AS max_inv FROM sales_orders WHERE business_id = $1`,
        [activeBusinessId]
      );
      nextInvoiceNo = parseInt(maxInvRes.rows[0].max_inv, 10) + 1;
    }

    const parsedItems = Array.isArray(items) ? items : (typeof items === 'string' ? JSON.parse(items) : []);
    const parsedTotal = parseFloat(totalAmount || 0);
    const parsedReceived = parseFloat(receivedAmount || 0);
    const saleDate = getIstDateString(date);

    const validId = id ? toDeterministicUuid(id) : null;
    const validPartyId = toValidUuidOrNull(partyId);

    let finalCustomerName = (customerName && customerName.trim().length > 0) ? customerName.trim() : 'Customer';
    let finalCustomerPhone = (customerPhone && customerPhone.trim().length > 0) ? customerPhone.trim() : '';

    if ((!finalCustomerPhone || finalCustomerName === 'Customer') && validPartyId) {
      const partyRes = await client.query('SELECT name, contact_number FROM parties WHERE id = $1 LIMIT 1', [validPartyId]);
      if (partyRes.rows.length > 0) {
        if (!finalCustomerPhone && partyRes.rows[0].contact_number) {
          finalCustomerPhone = partyRes.rows[0].contact_number;
        }
        if (finalCustomerName === 'Customer' && partyRes.rows[0].name) {
          finalCustomerName = partyRes.rows[0].name;
        }
      }
    }

    // 2. Insert into sales_orders
    const insertRes = await client.query(
      `INSERT INTO sales_orders (
        id, business_id, invoice_no, date, payment_mode, is_one_time_customer,
        party_id, customer_name, customer_phone, items_json, total_amount,
        received_amount, payment_type, state_of_supply, description, terms_and_conditions
      ) VALUES (
        COALESCE($1, gen_random_uuid()), $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13, $14, $15, $16
      ) RETURNING *`,
      [
        validId,
        activeBusinessId,
        nextInvoiceNo,
        saleDate,
        paymentMode || 'Cash',
        isOneTimeCustomer ? 1 : 0,
        validPartyId,
        finalCustomerName,
        finalCustomerPhone,
        JSON.stringify(parsedItems),
        parsedTotal,
        parsedReceived,
        paymentType || 'Cash',
        stateOfSupply || '',
        description || '',
        termsAndConditions || ''
      ]
    );

    const createdOrder = insertRes.rows[0];

    // 3. Atomically deduct inventory stock for each line item
    for (const item of parsedItems) {
      const qty = parseInt(item.qty || 1, 10);
      const itemId = item.id;
      const itemName = item.itemName || item.name;
      const validItemId = toValidUuidOrNull(itemId);

      if (validItemId) {
        await client.query(
          `UPDATE items SET stock = stock - $1 WHERE id = $2 AND business_id = $3`,
          [qty, validItemId, activeBusinessId]
        );
      } else if (itemName) {
        await client.query(
          `UPDATE items SET stock = stock - $1 WHERE LOWER(name) = LOWER($2) AND business_id = $3`,
          [qty, itemName, activeBusinessId]
        );
      }
    }

    // 4. Ledger integrity: party opening_balance represents initial balance and is preserved without mutation.
    // Dynamic net balance is computed from opening_balance + sales - purchases - payments.

    // 5. Audit Log Entry
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

    const targetCustomer = isOneTimeCustomer ? 'One-time Customer' : (customerName || 'Customer');
    await client.query(
      `INSERT INTO activity_logs (business_id, user_id, user_name, module, action, details, member_id, member_name, activity_type, title, subtitle, amount)
       VALUES ($1, $2, $3, 'Sales', 'CREATE', $4, $5, $6, 'itemSold', 'Item Sold', $7, $8)`,
      [
        activeBusinessId,
        user.userId,
        user.phone || 'User',
        `Invoice #${nextInvoiceNo} created for total ₹${parsedTotal.toFixed(2)}`,
        logMemberId,
        logMemberName,
        `Invoice #${nextInvoiceNo} - ${targetCustomer}`,
        parsedTotal
      ]
    );

    await client.query('COMMIT');
    client.release();

    return reply.status(201).send({
      success: true,
      message: 'Sales invoice created successfully',
      order: {
        id: createdOrder.id,
        businessId: createdOrder.business_id,
        invoiceNo: createdOrder.invoice_no,
        date: getIstDateString(createdOrder.date),
        totalAmount: parseFloat(createdOrder.total_amount),
        receivedAmount: parseFloat(createdOrder.received_amount),
        customerName: createdOrder.customer_name,
        customerPhone: createdOrder.customer_phone,
        items: parsedItems,
        createdAt: createdOrder.created_at
      }
    });
  } catch (error: any) {
    await client.query('ROLLBACK');
    client.release();
    console.error('Create Sale Order Error:', error);
    return reply.status(500).send({ success: false, message: error?.message || 'Failed to create sales invoice.' });
  }
}
