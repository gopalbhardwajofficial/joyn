import { FastifyInstance } from 'fastify';
import {
  getRolesHandler,
  createRoleHandler,
  updateRoleHandler,
  deleteRoleHandler
} from '../controllers/roles.controller.js';
import { verifyBusinessAccess } from '../middleware/rbac.middleware.js';

export async function rolesRoutes(fastify: FastifyInstance) {
  fastify.addHook('onRequest', async (req, reply) => {
    try {
      await req.jwtVerify();
    } catch (err) {
      return reply.status(401).send({ success: false, message: 'Unauthorized access.' });
    }
  });

  fastify.addHook('preHandler', async (req, reply) => {
    // Only business owner or admin can manage roles
    const access = await verifyBusinessAccess(req, reply, 'access_admin');
    if (!access) return reply;
  });

  fastify.get('/', getRolesHandler);
  fastify.post('/', createRoleHandler);
  fastify.put('/:id', updateRoleHandler);
  fastify.delete('/:id', deleteRoleHandler);
}
