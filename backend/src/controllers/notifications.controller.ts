import { FastifyRequest, FastifyReply } from 'fastify';
import { getDbPool } from '../db/connection.js';

function toValidUuidOrNull(val: any): string | null {
  if (typeof val !== 'string' || !val) return null;
  const uuidRegex = /^[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i;
  return uuidRegex.test(val) ? val : null;
}

// 1. Register FCM Device Token
export async function registerDeviceTokenHandler(req: FastifyRequest, reply: FastifyReply) {
  try {
    const user = (req as any).user;
    const { token, deviceType } = (req.body as any) || {};

    if (!token) {
      return reply.status(400).send({ success: false, message: 'FCM device token is required.' });
    }

    const pool = getDbPool();
    await pool.query(
      `UPDATE users SET fcm_device_token = $1, updated_at = CURRENT_TIMESTAMP WHERE id = $2`,
      [token, user.userId]
    );

    return reply.send({
      success: true,
      message: 'FCM device token registered successfully.',
      deviceType: deviceType || 'android'
    });
  } catch (error: any) {
    console.error('Register Token Error:', error);
    return reply.status(500).send({ success: false, message: error?.message || 'Failed to register device token.' });
  }
}

// 2. List In-App Notifications for Active Business
export async function listNotificationsHandler(req: FastifyRequest, reply: FastifyReply) {
  try {
    const activeBusinessId = (req as any).businessAccess?.businessId || (req.headers['x-business-id'] as string) || (req.query as any)?.businessId;
    const { limit = 50, type } = (req.query as any) || {};

    if (!activeBusinessId) {
      return reply.status(400).send({ success: false, message: 'x-business-id header is required.' });
    }

    const pool = getDbPool();

    // Query notifications
    let query = `
      SELECT * FROM notifications 
      WHERE business_id = $1 
      ${type ? 'AND type = $2' : ''}
      ORDER BY created_at DESC 
      LIMIT ${parseInt(limit) || 50}
    `;
    const params = type ? [activeBusinessId, type] : [activeBusinessId];
    const res = await pool.query(query, params);

    // Unread count
    const unreadRes = await pool.query(
      `SELECT COUNT(*)::int as unread_count FROM notifications WHERE business_id = $1 AND is_read = false`,
      [activeBusinessId]
    );
    const unreadCount = unreadRes.rows[0]?.unread_count || 0;

    return reply.send({
      success: true,
      unreadCount,
      notifications: res.rows.map((n: any) => ({
        id: n.id,
        businessId: n.business_id,
        title: n.title,
        body: n.body,
        type: n.type,
        data: n.data || {},
        isRead: n.is_read,
        createdAt: n.created_at
      }))
    });
  } catch (error: any) {
    console.error('List Notifications Error:', error);
    return reply.status(500).send({ success: false, message: error?.message || 'Failed to list notifications.' });
  }
}

// 3. Mark Notification as Read
export async function markNotificationReadHandler(req: FastifyRequest, reply: FastifyReply) {
  try {
    const { id } = req.params as { id: string };
    if (!id || !id.trim()) {
      return reply.status(400).send({ success: false, message: 'Valid notification ID required.' });
    }

    const pool = getDbPool();
    const res = await pool.query(
      `UPDATE notifications SET is_read = true WHERE id::text = $1 RETURNING *`,
      [id.trim()]
    );

    return reply.send({
      success: true,
      message: 'Notification marked as read.',
      notification: res.rows[0] || null
    });
  } catch (error: any) {
    return reply.status(500).send({ success: false, message: error?.message || 'Failed to mark as read.' });
  }
}

// 4. Mark All Notifications as Read
export async function markAllNotificationsReadHandler(req: FastifyRequest, reply: FastifyReply) {
  try {
    const pool = getDbPool();
    const user = (req as any).user;
    let activeBusinessId = (req as any).businessAccess?.businessId || (req.headers['x-business-id'] as string) || (req.body as any)?.businessId;

    if (!activeBusinessId && user?.userId) {
      const bizRes = await pool.query(
        'SELECT id FROM business_profile WHERE owner_id = $1 ORDER BY created_at ASC LIMIT 1',
        [user.userId]
      );
      if (bizRes.rows.length > 0) activeBusinessId = bizRes.rows[0].id;
    }

    if (activeBusinessId) {
      await pool.query(
        `UPDATE notifications SET is_read = true WHERE business_id = $1 AND is_read = false`,
        [activeBusinessId]
      );
    }
    if (user?.userId) {
      await pool.query(
        `UPDATE notifications SET is_read = true WHERE user_id = $1 AND is_read = false`,
        [user.userId]
      );
    }

    return reply.send({
      success: true,
      message: 'All notifications marked as read.'
    });
  } catch (error: any) {
    return reply.status(500).send({ success: false, message: error?.message || 'Failed to mark all as read.' });
  }
}

// 5. Delete Notification
export async function deleteNotificationHandler(req: FastifyRequest, reply: FastifyReply) {
  try {
    const { id } = req.params as { id: string };
    const validId = toValidUuidOrNull(id);
    const activeBusinessId = (req as any).businessAccess?.businessId || (req.headers['x-business-id'] as string);

    if (!validId) {
      return reply.status(400).send({ success: false, message: 'Valid notification ID required.' });
    }

    const pool = getDbPool();
    await pool.query(
      `DELETE FROM notifications WHERE id = $1 ${activeBusinessId ? 'AND business_id = $2' : ''}`,
      activeBusinessId ? [validId, activeBusinessId] : [validId]
    );

    return reply.send({
      success: true,
      message: 'Notification deleted successfully.'
    });
  } catch (error: any) {
    return reply.status(500).send({ success: false, message: error?.message || 'Failed to delete notification.' });
  }
}

// 6. Check & Generate Low Stock Alerts Automatically
export async function checkLowStockAlertsHandler(req: FastifyRequest, reply: FastifyReply) {
  try {
    const activeBusinessId = (req as any).businessAccess?.businessId || (req.headers['x-business-id'] as string) || (req.body as any)?.businessId;
    if (!activeBusinessId) {
      return reply.status(400).send({ success: false, message: 'x-business-id header is required.' });
    }

    const pool = getDbPool();

    // Find items where stock <= min_stock_alert
    const itemsRes = await pool.query(
      `SELECT id, name, stock, min_stock_alert, unit 
       FROM items 
       WHERE business_id = $1 AND stock <= min_stock_alert
       ORDER BY stock ASC`,
      [activeBusinessId]
    );

    let createdAlerts = 0;
    const alertedItems: any[] = [];

    for (const item of itemsRes.rows) {
      // Check if low stock notification already exists in last 24h for this item
      const existingRes = await pool.query(
        `SELECT id FROM notifications 
         WHERE business_id = $1 AND type = 'LOW_STOCK_ALERT' 
           AND (data->>'itemId') = $2 
           AND created_at > (CURRENT_TIMESTAMP - INTERVAL '24 hours')
         LIMIT 1`,
        [activeBusinessId, item.id]
      );

      if (existingRes.rows.length === 0) {
        await pool.query(
          `INSERT INTO notifications (business_id, title, body, type, data, is_read)
           VALUES ($1, $2, $3, 'LOW_STOCK_ALERT', $4, false)`,
          [
            activeBusinessId,
            `⚠️ Low Stock Alert: ${item.name}`,
            `Only ${item.stock} ${item.unit || 'units'} left! Restock threshold is ${item.min_stock_alert}.`,
            JSON.stringify({ itemId: item.id, itemName: item.name, stock: item.stock, minStockAlert: item.min_stock_alert })
          ]
        );
        createdAlerts++;
      }
      alertedItems.push({
        id: item.id,
        name: item.name,
        stock: item.stock,
        minStockAlert: item.min_stock_alert,
        unit: item.unit
      });
    }

    return reply.send({
      success: true,
      message: `Low stock scan complete. ${createdAlerts} new alerts created.`,
      lowStockCount: itemsRes.rows.length,
      createdAlerts,
      items: alertedItems
    });
  } catch (error: any) {
    console.error('Check Low Stock Error:', error);
    return reply.status(500).send({ success: false, message: error?.message || 'Failed to check low stock.' });
  }
}

// 7. Send Broadcast / Custom In-App Notification
export async function createNotificationHandler(req: FastifyRequest, reply: FastifyReply) {
  try {
    const user = (req as any).user;
    const activeBusinessId = (req as any).businessAccess?.businessId || (req.headers['x-business-id'] as string) || (req.body as any)?.businessId;
    const { title, body, type = 'SYSTEM', data = {} } = (req.body as any) || {};

    if (!title || !body) {
      return reply.status(400).send({ success: false, message: 'Title and body are required.' });
    }
    if (!activeBusinessId) {
      return reply.status(400).send({ success: false, message: 'x-business-id is required.' });
    }

    const pool = getDbPool();
    const res = await pool.query(
      `INSERT INTO notifications (business_id, user_id, title, body, type, data, is_read)
       VALUES ($1, $2, $3, $4, $5, $6, false)
       RETURNING *`,
      [activeBusinessId, user.userId, title, body, type, JSON.stringify(data)]
    );

    return reply.status(201).send({
      success: true,
      message: 'Notification created successfully.',
      notification: res.rows[0]
    });
  } catch (error: any) {
    return reply.status(500).send({ success: false, message: error?.message || 'Failed to create notification.' });
  }
}

