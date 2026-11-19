import { FastifyInstance } from 'fastify';
import {
  getOverdueDebtorsHandler,
  sendPaymentReminderHandler,
  listRemindersHistoryHandler,
  triggerBatchAutomatedRemindersHandler
} from '../controllers/reminders.controller.js';
import { verifyBusinessAccess } from '../middleware/rbac.middleware.js';

export async function remindersRoutes(fastify: FastifyInstance) {
  // Guard endpoints with JWT authentication
  fastify.addHook('onRequest', async (req, reply) => {
    try {
      await req.jwtVerify();
    } catch (err) {
      reply.status(401).send({ success: false, message: 'Unauthorized access. Token invalid or expired.' });
    }
  });

  // Reminders require access_sales
  fastify.addHook('preHandler', async (req, reply) => {
    const access = await verifyBusinessAccess(req, reply, 'access_sales');
    if (!access) return reply;
  });

  // Debtors with pending dues
  fastify.get('/overdue', getOverdueDebtorsHandler);

  // Send single payment reminder (WhatsApp text, UPI link, DB log & notification)
  fastify.post('/send', sendPaymentReminderHandler);

  // Audit history of dispatched reminders
  fastify.get('/history', listRemindersHistoryHandler);

  // Automated batch dispatch
  fastify.post('/auto-dispatch', triggerBatchAutomatedRemindersHandler);
}

