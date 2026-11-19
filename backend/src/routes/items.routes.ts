import { FastifyInstance } from 'fastify';
import {
  getItemsHandler,
  getItemByIdHandler,
  createItemHandler,
  updateItemHandler,
  deleteItemHandler
} from '../controllers/items.controller.js';
import { verifyBusinessAccess } from '../middleware/rbac.middleware.js';

export async function itemsRoutes(fastify: FastifyInstance) {
  fastify.addHook('onRequest', async (req, reply) => {
    try {
      await req.jwtVerify();
    } catch (err) {
      return reply.status(401).send({ success: false, message: 'Unauthorized access.' });
    }
  });

  // Reading items is allowed if user has inventory, sales, or purchase permissions
  fastify.get('/', {
    preHandler: async (req, reply) => {
      const access = await verifyBusinessAccess(req, reply);
      if (!access) return reply;
      if (!access.isOwner && !access.permissions.accessInventory && !access.permissions.accessSales && !access.permissions.accessPurchase) {
        return reply.status(403).send({ success: false, message: 'Permission denied. You do not have access to view items.' });
      }
    }
  }, getItemsHandler);

  fastify.get('/:id', {
    preHandler: async (req, reply) => {
      const access = await verifyBusinessAccess(req, reply);
      if (!access) return reply;
      if (!access.isOwner && !access.permissions.accessInventory && !access.permissions.accessSales && !access.permissions.accessPurchase) {
        return reply.status(403).send({ success: false, message: 'Permission denied. You do not have access to view items.' });
      }
    }
  }, getItemByIdHandler);

  // Creating/updating/deleting items requires access_inventory
  fastify.post('/', {
    preHandler: async (req, reply) => {
      const access = await verifyBusinessAccess(req, reply, 'access_inventory');
      if (!access) return reply;
    }
  }, createItemHandler);

  fastify.put('/:id', {
    preHandler: async (req, reply) => {
      const access = await verifyBusinessAccess(req, reply, 'access_inventory');
      if (!access) return reply;
    }
  }, updateItemHandler);

  fastify.delete('/:id', {
    preHandler: async (req, reply) => {
      const access = await verifyBusinessAccess(req, reply, 'access_inventory');
      if (!access) return reply;
    }
  }, deleteItemHandler);
}
