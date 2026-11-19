import { FastifyInstance } from 'fastify';
import {
  getTeamMembersHandler,
  createTeamMemberHandler,
  updateTeamMemberHandler,
  toggleMemberStatusHandler,
  deleteTeamMemberHandler,
  getActivityLogsHandler
} from '../controllers/team.controller.js';
import { verifyBusinessAccess } from '../middleware/rbac.middleware.js';

export async function teamRoutes(fastify: FastifyInstance) {
  fastify.addHook('onRequest', async (req, reply) => {
    try {
      await req.jwtVerify();
    } catch (err) {
      return reply.status(401).send({ success: false, message: 'Unauthorized access.' });
    }
  });

  // Team member management requires access_admin
  fastify.get('/', {
    preHandler: async (req, reply) => {
      const access = await verifyBusinessAccess(req, reply, 'access_admin');
      if (!access) return reply;
    }
  }, getTeamMembersHandler);

  fastify.post('/', {
    preHandler: async (req, reply) => {
      const access = await verifyBusinessAccess(req, reply, 'access_admin');
      if (!access) return reply;
    }
  }, createTeamMemberHandler);

  fastify.put('/:id', {
    preHandler: async (req, reply) => {
      const access = await verifyBusinessAccess(req, reply, 'access_admin');
      if (!access) return reply;
    }
  }, updateTeamMemberHandler);

  fastify.patch('/:id/toggle-status', {
    preHandler: async (req, reply) => {
      const access = await verifyBusinessAccess(req, reply, 'access_admin');
      if (!access) return reply;
    }
  }, toggleMemberStatusHandler);

  fastify.put('/:id/toggle-status', {
    preHandler: async (req, reply) => {
      const access = await verifyBusinessAccess(req, reply, 'access_admin');
      if (!access) return reply;
    }
  }, toggleMemberStatusHandler);

  fastify.patch('/:id/status', {
    preHandler: async (req, reply) => {
      const access = await verifyBusinessAccess(req, reply, 'access_admin');
      if (!access) return reply;
    }
  }, toggleMemberStatusHandler);

  fastify.put('/:id/status', {
    preHandler: async (req, reply) => {
      const access = await verifyBusinessAccess(req, reply, 'access_admin');
      if (!access) return reply;
    }
  }, toggleMemberStatusHandler);

  fastify.delete('/:id', {
    preHandler: async (req, reply) => {
      const access = await verifyBusinessAccess(req, reply, 'access_admin');
      if (!access) return reply;
    }
  }, deleteTeamMemberHandler);

  // Activity logs can be viewed by admin or member themselves
  fastify.get('/:memberId/activity-logs', {
    preHandler: async (req, reply) => {
      const access = await verifyBusinessAccess(req, reply);
      if (!access) return reply;
    }
  }, getActivityLogsHandler);

  fastify.get('/activity-logs', {
    preHandler: async (req, reply) => {
      const access = await verifyBusinessAccess(req, reply, 'access_admin');
      if (!access) return reply;
    }
  }, getActivityLogsHandler);
}
