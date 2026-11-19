import { FastifyInstance } from 'fastify';
import {
  registerDeviceTokenHandler,
  listNotificationsHandler,
  markNotificationReadHandler,
  markAllNotificationsReadHandler,
  deleteNotificationHandler,
  checkLowStockAlertsHandler,
  createNotificationHandler
} from '../controllers/notifications.controller.js';
import { verifyBusinessAccess } from '../middleware/rbac.middleware.js';

export async function notificationsRoutes(fastify: FastifyInstance) {
  // Guard endpoints with JWT authentication
  fastify.addHook('onRequest', async (req, reply) => {
    try {
      await req.jwtVerify();
    } catch (err) {
      reply.status(401).send({ success: false, message: 'Unauthorized access. Token invalid or expired.' });
    }
  });

  // Token management (User-level)
  fastify.post('/register-token', registerDeviceTokenHandler);

  // In-app notifications (Business-scoped, requires active membership)
  fastify.get('/', {
    preHandler: async (req, reply) => {
      const access = await verifyBusinessAccess(req, reply);
      if (!access) return reply;
    }
  }, listNotificationsHandler);

  fastify.put('/:id/read', {
    preHandler: async (req, reply) => {
      const access = await verifyBusinessAccess(req, reply);
      if (!access) return reply;
    }
  }, markNotificationReadHandler);

  fastify.put('/read-all', {
    preHandler: async (req, reply) => {
      const access = await verifyBusinessAccess(req, reply);
      if (!access) return reply;
    }
  }, markAllNotificationsReadHandler);

  fastify.delete('/:id', {
    preHandler: async (req, reply) => {
      const access = await verifyBusinessAccess(req, reply);
      if (!access) return reply;
    }
  }, deleteNotificationHandler);

  // Automation & broadcast
  fastify.post('/check-low-stock', {
    preHandler: async (req, reply) => {
      const access = await verifyBusinessAccess(req, reply, 'access_inventory');
      if (!access) return reply;
    }
  }, checkLowStockAlertsHandler);

  fastify.post('/send', {
    preHandler: async (req, reply) => {
      const access = await verifyBusinessAccess(req, reply, 'access_admin');
      if (!access) return reply;
    }
  }, createNotificationHandler);
}

