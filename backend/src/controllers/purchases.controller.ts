import { FastifyRequest, FastifyReply } from 'fastify';
import { getDbPool } from '../db/connection.js';
import { getIstDateString, toDeterministicUuid, toValidUuidOrNull } from '../utils/common.utils.js';

export async function getPurchaseOrdersHandler(req: FastifyRequest, reply: FastifyReply) {
  try {
    const { businessId } = req.query as { businessId?: string };
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

    const res = await pool.query(
      `SELECT * FROM purchase_orders WHERE business_id = $1 ORDER BY order_no DESC, created_at DESC LIMIT 200`,
      [activeBusinessId]
    );

    return reply.send({
      success: true,
      orders: res.rows.map((row: any) => ({
        id: row.id,
        businessId: row.business_id,
        orderNo: row.order_no,
        date: getIstDateString(row.date),
        dueDate: row.due_date ? getIstDateString(row.due_date) : '',
        partyName: row.party_name || '',
        partyId: row.party_id || '',
        items: typeof row.items_json === 'string' ? JSON.parse(row.items_json) : row.items_json,
        totalAmount: parseFloat(row.total_amount || 0),
        createdAt: row.created_at
      }))
    });
  } catch (error: any) {
    return reply.status(500).send({ success: false, message: error?.message || 'Failed to fetch purchase orders.' });
  }
}

export async function getPurchaseOrderByIdHandler(req: FastifyRequest, reply: FastifyReply) {
  try {
    const { id } = req.params as { id: string };
    const pool = getDbPool();

    const res = await pool.query('SELECT * FROM purchase_orders WHERE id = $1 LIMIT 1', [id]);
    if (res.rows.length === 0) {
      return reply.status(404).send({ success: false, message: 'Purchase order not found.' });
    }

    const row = res.rows[0];
    return reply.send({
      success: true,
      order: {
        id: row.id,
        businessId: row.business_id,
        orderNo: row.order_no,
        date: getIstDateString(row.date),
        dueDate: row.due_date ? getIstDateString(row.due_date) : '',
        partyName: row.party_name || '',
        partyId: row.party_id || '',
        items: typeof row.items_json === 'string' ? JSON.parse(row.items_json) : row.items_json,
        totalAmount: parseFloat(row.total_amount || 0),
        createdAt: row.created_at
      }
    });
  } catch (error: any) {
    return reply.status(500).send({ success: false, message: error?.message || 'Failed to fetch purchase order.' });
  }
}

export async function createPurchaseOrderHandler(req: FastifyRequest, reply: FastifyReply) {
  const pool = getDbPool();
  const client = await pool.connect();

  try {
    const user = (req as any).user;
    const {
      id,
      businessId,
      date,
      dueDate,
      partyName,
      partyId,
      items,
      totalAmount
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
      return reply.status(400).send({ success: false, message: 'Active business ID required to create purchase order.' });
    }

    // Start ACID Transaction
    await client.query('BEGIN');

    // 1. Get next sequential order number for this business
    const maxOrderRes = await client.query(
      `SELECT COALESCE(MAX(order_no), 2000) AS max_ord FROM purchase_orders WHERE business_id = $1`,
      [activeBusinessId]
    );
    const nextOrderNo = parseInt(maxOrderRes.rows[0].max_ord, 10) + 1;

    const parsedItems = Array.isArray(items) ? items : (typeof items === 'string' ? JSON.parse(items) : []);
    const parsedTotal = parseFloat(totalAmount || 0);
    const orderDate = getIstDateString(date);
    const orderDueDate = dueDate ? getIstDateString(dueDate) : null;

    const validId = toValidUuidOrNull(id);
    const validPartyId = toValidUuidOrNull(partyId);

    // 2. Insert into purchase_orders
    const insertRes = await client.query(
      `INSERT INTO purchase_orders (
        id, business_id, order_no, date, due_date, party_name, party_id, items_json, total_amount
      ) VALUES (
        COALESCE($1, gen_random_uuid()), $2, $3, $4, $5, $6, $7, $8, $9
      ) RETURNING *`,
      [
        validId,
        activeBusinessId,
        nextOrderNo,
        orderDate,
        orderDueDate,
        partyName || 'Vendor',
        validPartyId,
        JSON.stringify(parsedItems),
        parsedTotal
      ]
    );

    const createdOrder = insertRes.rows[0];

    // 3. Atomically increment inventory stock for each line item
    for (const item of parsedItems) {
      const qty = parseInt(item.qty || 1, 10);
      const itemId = item.id;
      const itemName = item.itemName || item.name;
      const validItemId = toValidUuidOrNull(itemId);

      if (validItemId) {
        await client.query(
          `UPDATE items SET stock = stock + $1 WHERE id = $2 AND business_id = $3`,
          [qty, validItemId, activeBusinessId]
        );
      } else if (itemName) {
        await client.query(
          `UPDATE items SET stock = stock + $1 WHERE LOWER(name) = LOWER($2) AND business_id = $3`,
          [qty, itemName, activeBusinessId]
        );
      }
    }

    // 4. Ledger integrity: party opening_balance represents initial balance and is preserved without mutation.

    // 5. Activity log
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

    const targetParty = partyName || 'Vendor';
    await client.query(
      `INSERT INTO activity_logs (business_id, user_id, user_name, module, action, details, member_id, member_name, activity_type, title, subtitle, amount)
       VALUES ($1, $2, $3, 'Purchases', 'CREATE', $4, $5, $6, 'itemPurchased', 'Item Purchased', $7, $8)`,
      [
        activeBusinessId,
        user.userId,
        user.phone || 'User',
        `Purchase Order #${nextOrderNo} created for total ₹${parsedTotal.toFixed(2)}`,
        logMemberId,
        logMemberName,
        `PO #${nextOrderNo} - ${targetParty}`,
        parsedTotal
      ]
    );

    await client.query('COMMIT');
    client.release();

    return reply.status(201).send({
      success: true,
      message: 'Purchase order created successfully',
      order: {
        id: createdOrder.id,
        businessId: createdOrder.business_id,
        orderNo: createdOrder.order_no,
        date: getIstDateString(createdOrder.date),
        totalAmount: parseFloat(createdOrder.total_amount),
        partyName: createdOrder.party_name,
        partyId: createdOrder.party_id,
        items: parsedItems,
        createdAt: createdOrder.created_at
      }
    });
  } catch (error: any) {
    await client.query('ROLLBACK');
    client.release();
    console.error('Create Purchase Order Error:', error);
    return reply.status(500).send({ success: false, message: error?.message || 'Failed to create purchase order.' });
  }
}
