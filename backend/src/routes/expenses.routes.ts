import { FastifyInstance } from 'fastify';
import {
  listExpensesHandler,
  createExpenseHandler,
  deleteExpenseHandler,
  getExpenseSummaryHandler
} from '../controllers/expenses.controller.js';
import { verifyBusinessAccess } from '../middleware/rbac.middleware.js';

export async function expensesRoutes(fastify: FastifyInstance) {
  // Guard endpoints with JWT authentication
  fastify.addHook('onRequest', async (req, reply) => {
    try {
      await req.jwtVerify();
    } catch (err) {
      reply.status(401).send({ success: false, message: 'Unauthorized access. Token invalid or expired.' });
    }
  });

  // Expenses management requires access_reports
  fastify.addHook('preHandler', async (req, reply) => {
    const access = await verifyBusinessAccess(req, reply, 'access_reports');
    if (!access) return reply;
  });

  fastify.get('/', listExpensesHandler);
  fastify.post('/', createExpenseHandler);
  fastify.delete('/:id', deleteExpenseHandler);
  fastify.get('/summary', getExpenseSummaryHandler);
}

