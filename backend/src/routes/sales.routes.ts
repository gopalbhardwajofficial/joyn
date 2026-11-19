import { FastifyInstance } from 'fastify';
import {
  getSalesOrdersHandler,
  getSaleOrderByIdHandler,
  createSaleOrderHandler
} from '../controllers/sales.controller.js';
import {
  getSalesInvoicePdfHandler,
  getWhatsAppShareLinkHandler
} from '../controllers/shares.controller.js';
import { verifyBusinessAccess } from '../middleware/rbac.middleware.js';

export async function salesRoutes(fastify: FastifyInstance) {
  fastify.addHook('onRequest', async (req, reply) => {
    try {
      await req.jwtVerify();
    } catch (err) {
      return reply.status(401).send({ success: false, message: 'Unauthorized access.' });
    }
  });

  fastify.addHook('preHandler', async (req, reply) => {
    const access = await verifyBusinessAccess(req, reply, 'access_sales');
    if (!access) return reply;
  });

  fastify.get('/orders', getSalesOrdersHandler);
  fastify.get('/orders/:id', getSaleOrderByIdHandler);
  fastify.get('/orders/:id/pdf', getSalesInvoicePdfHandler);
  fastify.get('/orders/:id/whatsapp-share', getWhatsAppShareLinkHandler);
  fastify.post('/orders', createSaleOrderHandler);
}
