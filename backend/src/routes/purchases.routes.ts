import { FastifyInstance } from 'fastify';
import {
  getPurchaseOrdersHandler,
  getPurchaseOrderByIdHandler,
  createPurchaseOrderHandler
} from '../controllers/purchases.controller.js';
import { verifyBusinessAccess } from '../middleware/rbac.middleware.js';

export async function purchasesRoutes(fastify: FastifyInstance) {
  fastify.addHook('onRequest', async (req, reply) => {
    try {
      await req.jwtVerify();
    } catch (err) {
      return reply.status(401).send({ success: false, message: 'Unauthorized access.' });
    }
  });

  fastify.addHook('preHandler', async (req, reply) => {
    const access = await verifyBusinessAccess(req, reply, 'access_purchase');
    if (!access) return reply;
  });

  fastify.get('/orders', getPurchaseOrdersHandler);
  fastify.get('/orders/:id', getPurchaseOrderByIdHandler);
  fastify.post('/orders', createPurchaseOrderHandler);
}
