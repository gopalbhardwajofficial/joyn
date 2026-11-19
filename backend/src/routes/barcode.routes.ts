import { FastifyInstance } from 'fastify';
import {
  searchBarcodeHandler,
  generateBarcodeHandler
} from '../controllers/barcode.controller.js';
import { verifyBusinessAccess } from '../middleware/rbac.middleware.js';

export async function barcodeRoutes(fastify: FastifyInstance) {
  fastify.addHook('onRequest', async (req, reply) => {
    try {
      await req.jwtVerify();
    } catch (err) {
      return reply.status(401).send({ success: false, message: 'Unauthorized access.' });
    }
  });

  fastify.get('/search', {
    preHandler: async (req, reply) => {
      const access = await verifyBusinessAccess(req, reply);
      if (!access) return reply;
      if (!access.isOwner && !access.permissions.accessInventory && !access.permissions.accessSales && !access.permissions.accessPurchase) {
        return reply.status(403).send({ success: false, message: 'Permission denied. You do not have access to search barcodes.' });
      }
    }
  }, searchBarcodeHandler);

  fastify.post('/generate', {
    preHandler: async (req, reply) => {
      const access = await verifyBusinessAccess(req, reply, 'access_inventory');
      if (!access) return reply;
    }
  }, generateBarcodeHandler);

  fastify.get('/generate', {
    preHandler: async (req, reply) => {
      const access = await verifyBusinessAccess(req, reply, 'access_inventory');
      if (!access) return reply;
    }
  }, generateBarcodeHandler);
}
