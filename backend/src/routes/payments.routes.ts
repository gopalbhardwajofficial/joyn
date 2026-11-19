import { FastifyInstance } from 'fastify';
import {
  getPaymentsHandler,
  createPaymentHandler
} from '../controllers/payments.controller.js';
import { verifyBusinessAccess } from '../middleware/rbac.middleware.js';

export async function paymentsRoutes(fastify: FastifyInstance) {
  fastify.addHook('onRequest', async (req, reply) => {
    try {
      await req.jwtVerify();
    } catch (err) {
      return reply.status(401).send({ success: false, message: 'Unauthorized access.' });
    }
  });

  fastify.get('/', {
    preHandler: async (req, reply) => {
      const access = await verifyBusinessAccess(req, reply);
      if (!access) return reply;
      if (!access.isOwner && !access.permissions.accessSales && !access.permissions.accessPurchase) {
        return reply.status(403).send({ success: false, message: 'Permission denied. You do not have access to payments.' });
      }
    }
  }, getPaymentsHandler);

  fastify.post('/', {
    preHandler: async (req, reply) => {
      const isOut = (req.body as any)?.isPaymentOut === true || (req.body as any)?.isPaymentOut === 1;
      const required = isOut ? 'access_purchase' : 'access_sales';
      const access = await verifyBusinessAccess(req, reply, required);
      if (!access) return reply;
    }
  }, createPaymentHandler);
}
