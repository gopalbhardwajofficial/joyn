import { FastifyInstance } from 'fastify';
import {
  listQuotationsHandler,
  createQuotationHandler,
  getQuotationByIdHandler,
  updateQuotationStatusHandler,
  convertQuotationToInvoiceHandler,
  listCreditNotesHandler,
  createCreditNoteHandler,
  listDebitNotesHandler,
  createDebitNoteHandler
} from '../controllers/estimates_returns.controller.js';
import { verifyBusinessAccess } from '../middleware/rbac.middleware.js';

export async function quotationsRoutes(fastify: FastifyInstance) {
  fastify.addHook('onRequest', async (req, reply) => {
    try {
      await req.jwtVerify();
    } catch (err) {
      reply.status(401).send({ success: false, message: 'Unauthorized access. Token invalid or expired.' });
    }
  });

  fastify.addHook('preHandler', async (req, reply) => {
    const access = await verifyBusinessAccess(req, reply, 'access_sales');
    if (!access) return reply;
  });

  fastify.get('/', listQuotationsHandler);
  fastify.post('/', createQuotationHandler);
  fastify.get('/:id', getQuotationByIdHandler);
  fastify.put('/:id/status', updateQuotationStatusHandler);
  fastify.patch('/:id/status', updateQuotationStatusHandler);
  fastify.post('/:id/convert-to-invoice', convertQuotationToInvoiceHandler);
}

export async function creditNotesRoutes(fastify: FastifyInstance) {
  fastify.addHook('onRequest', async (req, reply) => {
    try {
      await req.jwtVerify();
    } catch (err) {
      reply.status(401).send({ success: false, message: 'Unauthorized access. Token invalid or expired.' });
    }
  });

  fastify.addHook('preHandler', async (req, reply) => {
    const access = await verifyBusinessAccess(req, reply, 'access_sales');
    if (!access) return reply;
  });

  fastify.get('/', listCreditNotesHandler);
  fastify.post('/', createCreditNoteHandler);
}

export async function debitNotesRoutes(fastify: FastifyInstance) {
  fastify.addHook('onRequest', async (req, reply) => {
    try {
      await req.jwtVerify();
    } catch (err) {
      reply.status(401).send({ success: false, message: 'Unauthorized access. Token invalid or expired.' });
    }
  });

  fastify.addHook('preHandler', async (req, reply) => {
    const access = await verifyBusinessAccess(req, reply, 'access_purchase');
    if (!access) return reply;
  });

  fastify.get('/', listDebitNotesHandler);
  fastify.post('/', createDebitNoteHandler);
}
