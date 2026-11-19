import { FastifyInstance } from 'fastify';
import {
  getDayBookHandler,
  getProfitAndLossHandler,
  getBalanceSheetHandler,
  getCashFlowHandler,
  getBillWiseProfitHandler,
  getPartyStatementHandler,
  getAllPartiesReportHandler,
  getGstSummaryHandler,
  getExpensesHandler,
  createExpenseHandler,
  getExecutiveAnalyticsHandler,
  getItemAnalyticsHandler,
  getPartyAnalyticsHandler,
  getInventoryHealthHandler,
  getAllTransactionsHandler
} from '../controllers/reports.controller.js';
import { verifyBusinessAccess } from '../middleware/rbac.middleware.js';

export async function reportsRoutes(fastify: FastifyInstance) {
  fastify.addHook('onRequest', async (req, reply) => {
    try {
      await req.jwtVerify();
    } catch (err) {
      return reply.status(401).send({ success: false, message: 'Unauthorized access.' });
    }
  });

  fastify.addHook('preHandler', async (req, reply) => {
    const access = await verifyBusinessAccess(req, reply, 'access_reports');
    if (!access) return reply;
  });

  // Executive Analytics & KPIs
  fastify.get('/analytics/overview', getExecutiveAnalyticsHandler);
  fastify.get('/analytics/items', getItemAnalyticsHandler);
  fastify.get('/analytics/parties', getPartyAnalyticsHandler);
  fastify.get('/analytics/inventory', getInventoryHealthHandler);

  // Financial & Operational Statements
  fastify.get('/daybook', getDayBookHandler);
  fastify.get('/profit-loss', getProfitAndLossHandler);
  fastify.get('/balance-sheet', getBalanceSheetHandler);
  fastify.get('/cashflow', getCashFlowHandler);
  fastify.get('/bill-wise-profit', getBillWiseProfitHandler);
  fastify.get('/party-statement/:partyId', getPartyStatementHandler);
  fastify.get('/parties', getAllPartiesReportHandler);
  fastify.get('/all-transactions', getAllTransactionsHandler);
  fastify.get('/gst/summary', getGstSummaryHandler);
  fastify.get('/expenses', getExpensesHandler);
  fastify.post('/expenses', createExpenseHandler);
}
