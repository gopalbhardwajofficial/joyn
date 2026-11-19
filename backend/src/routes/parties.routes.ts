import { FastifyInstance } from 'fastify';
import {
  getPartiesHandler,
  createPartyHandler,
  updatePartyHandler,
  deletePartyHandler
} from '../controllers/parties.controller.js';
import { verifyBusinessAccess } from '../middleware/rbac.middleware.js';

export async function partiesRoutes(fastify: FastifyInstance) {
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
      if (!access.isOwner && !access.permissions.accessPartyDetails && !access.permissions.accessSales && !access.permissions.accessPurchase) {
        return reply.status(403).send({ success: false, message: 'Permission denied. You do not have access to view parties.' });
      }
    }
  }, getPartiesHandler);

  fastify.post('/', {
    preHandler: async (req, reply) => {
      const access = await verifyBusinessAccess(req, reply, 'access_party_details');
      if (!access) return reply;
    }
  }, createPartyHandler);

  fastify.put('/:id', {
    preHandler: async (req, reply) => {
      const access = await verifyBusinessAccess(req, reply, 'access_party_details');
      if (!access) return reply;
    }
  }, updatePartyHandler);

  fastify.delete('/:id', {
    preHandler: async (req, reply) => {
      const access = await verifyBusinessAccess(req, reply, 'access_party_details');
      if (!access) return reply;
    }
  }, deletePartyHandler);
}
