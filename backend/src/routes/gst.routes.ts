import { FastifyInstance } from 'fastify';
import {
  getGstr1Handler,
  getGstr2Handler,
  getGstr3bHandler,
  getHsnSummaryHandler,
  getGstr9Handler,
  lookupGstinHandler
} from '../controllers/gst.controller.js';
import { verifyBusinessAccess } from '../middleware/rbac.middleware.js';

export async function gstRoutes(fastify: FastifyInstance) {
  // Guard endpoints with JWT authentication
  fastify.addHook('onRequest', async (req, reply) => {
    try {
      await req.jwtVerify();
    } catch (err) {
      reply.status(401).send({ success: false, message: 'Unauthorized access. Token invalid or expired.' });
    }
  });

  // GSTR Returns & Analytics require access_reports
  fastify.addHook('preHandler', async (req, reply) => {
    const access = await verifyBusinessAccess(req, reply, 'access_reports');
    if (!access) return reply;
  });

  // GSTR Returns & Analytics
  fastify.get('/gstr-1', getGstr1Handler);
  fastify.get('/gstr-2', getGstr2Handler);
  fastify.get('/gstr-3b', getGstr3bHandler);
  fastify.get('/gstr-9', getGstr9Handler);
  fastify.get('/lookup/:gstin', lookupGstinHandler);
  fastify.get('/hsn-summary', getHsnSummaryHandler);
}

