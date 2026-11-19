import { FastifyInstance } from 'fastify';
import { pushSyncHandler, pullSyncHandler } from '../controllers/sync.controller.js';
import { verifyBusinessAccess } from '../middleware/rbac.middleware.js';

export async function syncRoutes(fastify: FastifyInstance) {
  fastify.addHook('onRequest', async (req, reply) => {
    try {
      await req.jwtVerify();
    } catch (err) {
      return reply.status(401).send({ success: false, message: 'Unauthorized access.' });
    }
  });

  // Push Sync: mutations batch uploaded from mobile client
  fastify.post('/push', {
    preHandler: async (req, reply) => {
      const access = await verifyBusinessAccess(req, reply);
      if (!access) return reply;
    }
  }, pushSyncHandler);

  // Pull Sync: incremental delta fetched by mobile client since timestamp
  fastify.get('/pull', {
    preHandler: async (req, reply) => {
      const access = await verifyBusinessAccess(req, reply);
      if (!access) return reply;
    }
  }, pullSyncHandler);
}
