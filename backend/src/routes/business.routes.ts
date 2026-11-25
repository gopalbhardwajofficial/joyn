import { FastifyInstance } from 'fastify';
import { 
  createBusinessHandler, 
  getMyBusinessesHandler,
  getBusinessProfileHandler,
  updateBusinessBrandingHandler,
  uploadBusinessLogoHandler,
  uploadBusinessSignatureHandler,
  deleteBusinessHandler,
  getInvoiceThemesHandler
} from '../controllers/business.controller.js';
import { verifyBusinessAccess } from '../middleware/rbac.middleware.js';

export async function businessRoutes(fastify: FastifyInstance) {
  // Guard endpoints with JWT authentication
  fastify.addHook('onRequest', async (req, reply) => {
    try {
      await req.jwtVerify();
    } catch (err) {
      reply.status(401).send({ success: false, message: 'Unauthorized access. Token invalid or expired.' });
    }
  });

  fastify.post('/', createBusinessHandler);
  fastify.put('/', createBusinessHandler);
  fastify.put('/:id', createBusinessHandler);
  fastify.delete('/:id', deleteBusinessHandler);
  fastify.get('/my-businesses', getMyBusinessesHandler);

  // Phase 8: Business Profile Branding & Invoice Theme Endpoints
  fastify.get('/profile', {
    preHandler: async (req, reply) => {
      const access = await verifyBusinessAccess(req, reply);
      if (!access) return reply;
    }
  }, getBusinessProfileHandler);

  fastify.put('/profile', {
    preHandler: async (req, reply) => {
      const access = await verifyBusinessAccess(req, reply, 'access_admin');
      if (!access) return reply;
    }
  }, updateBusinessBrandingHandler);

  fastify.put('/branding', {
    preHandler: async (req, reply) => {
      const access = await verifyBusinessAccess(req, reply, 'access_admin');
      if (!access) return reply;
    }
  }, updateBusinessBrandingHandler);

  fastify.post('/upload-logo', {
    preHandler: async (req, reply) => {
      const access = await verifyBusinessAccess(req, reply, 'access_admin');
      if (!access) return reply;
    }
  }, uploadBusinessLogoHandler);

  fastify.post('/upload-signature', {
    preHandler: async (req, reply) => {
      const access = await verifyBusinessAccess(req, reply, 'access_admin');
      if (!access) return reply;
    }
  }, uploadBusinessSignatureHandler);

  fastify.get('/invoice-themes', getInvoiceThemesHandler);
}
