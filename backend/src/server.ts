import Fastify from 'fastify';
import cors from '@fastify/cors';
import jwt from '@fastify/jwt';
import { config } from './config/index.js';
import { authRoutes } from './routes/auth.routes.js';
import { businessRoutes } from './routes/business.routes.js';
import { itemsRoutes } from './routes/items.routes.js';
import { partiesRoutes } from './routes/parties.routes.js';
import { salesRoutes } from './routes/sales.routes.js';
import { purchasesRoutes } from './routes/purchases.routes.js';
import { paymentsRoutes } from './routes/payments.routes.js';
import { barcodeRoutes } from './routes/barcode.routes.js';
import { rolesRoutes } from './routes/roles.routes.js';
import { teamRoutes } from './routes/team.routes.js';
import { reportsRoutes } from './routes/reports.routes.js';
import { syncRoutes } from './routes/sync.routes.js';
import { backupRoutes } from './routes/backup.routes.js';
import { notificationsRoutes } from './routes/notifications.routes.js';
import { remindersRoutes } from './routes/reminders.routes.js';
import { gstRoutes } from './routes/gst.routes.js';
import { expensesRoutes } from './routes/expenses.routes.js';
import {
  quotationsRoutes,
  creditNotesRoutes,
  debitNotesRoutes
} from './routes/estimates_returns.routes.js';
import {
  getPublicInvoiceHtmlHandler,
  getPublicInvoicePdfStreamHandler
} from './controllers/shares.controller.js';
import {
  getSystemHealthHandler,
  getSystemTelemetryHandler
} from './controllers/system.controller.js';
import { rateLimitMiddleware } from './middleware/rate_limit.middleware.js';
import { startBackupCronScheduler } from './services/backup_cron.service.js';
import { testDbConnection } from './db/connection.js';

const fastify = Fastify({ logger: true });

async function startServer() {
  try {
    // 1. Register CORS & JWT Plugins
    await fastify.register(cors, { origin: '*' });
    await fastify.register(jwt, { secret: config.jwtSecret });

    // 2. Production Security Hardening & Rate Limiting (Phase 12)
    fastify.addHook('onRequest', rateLimitMiddleware);
    fastify.addHook('onSend', async (req, reply) => {
      reply.header('X-Content-Type-Options', 'nosniff');
      reply.header('X-Frame-Options', 'DENY');
      reply.header('X-XSS-Protection', '1; mode=block');
      reply.header('Strict-Transport-Security', 'max-age=31536000; includeSubDomains');
      reply.header('X-Download-Options', 'noopen');
      reply.header('Referrer-Policy', 'strict-origin-when-cross-origin');
    });

    // 3. System Health & Telemetry Routes (Phase 12)
    fastify.get('/health', getSystemHealthHandler);
    fastify.get('/api/v1/health', getSystemHealthHandler);
    fastify.get('/api/v1/system/status', getSystemHealthHandler);
    fastify.get('/api/v1/system/telemetry', getSystemTelemetryHandler);

    // 4. Register Phase 1 to Phase 12 Routes
    await fastify.register(authRoutes, { prefix: '/api/v1/auth' });
    await fastify.register(businessRoutes, { prefix: '/api/v1/business' });
    await fastify.register(itemsRoutes, { prefix: '/api/v1/items' });
    await fastify.register(partiesRoutes, { prefix: '/api/v1/parties' });
    await fastify.register(salesRoutes, { prefix: '/api/v1/sales' });
    await fastify.register(purchasesRoutes, { prefix: '/api/v1/purchases' });
    await fastify.register(purchasesRoutes, { prefix: '/api/v1/purchase' });
    await fastify.register(paymentsRoutes, { prefix: '/api/v1/payments' });
    await fastify.register(barcodeRoutes, { prefix: '/api/v1/barcode' });
    await fastify.register(rolesRoutes, { prefix: '/api/v1/roles' });
    await fastify.register(teamRoutes, { prefix: '/api/v1/team-members' });
    await fastify.register(teamRoutes, { prefix: '/api/v1/team' });
    await fastify.register(reportsRoutes, { prefix: '/api/v1/reports' });
    await fastify.register(syncRoutes, { prefix: '/api/v1/sync' });
    await fastify.register(backupRoutes, { prefix: '/api/v1/backup' });
    await fastify.register(backupRoutes, { prefix: '/api/v1/backups' });
    await fastify.register(notificationsRoutes, { prefix: '/api/v1/notifications' });
    await fastify.register(remindersRoutes, { prefix: '/api/v1/reminders' });
    await fastify.register(gstRoutes, { prefix: '/api/v1/reports/gst' });
    await fastify.register(gstRoutes, { prefix: '/api/v1/gst' });
    await fastify.register(expensesRoutes, { prefix: '/api/v1/expenses' });
    await fastify.register(quotationsRoutes, { prefix: '/api/v1/quotations' });
    await fastify.register(quotationsRoutes, { prefix: '/api/v1/estimates' });
    await fastify.register(creditNotesRoutes, { prefix: '/api/v1/credit-notes' });
    await fastify.register(debitNotesRoutes, { prefix: '/api/v1/debit-notes' });

    // 4. Public Unauthenticated Document Share Routes
    fastify.get('/public/invoices/:token', getPublicInvoiceHtmlHandler);
    fastify.get('/public/invoices/:token/pdf', getPublicInvoicePdfStreamHandler);

    // 5. Test DB Connection asynchronously
    testDbConnection().catch(() => {});

    // 6. Listen on Host & Port
    await fastify.listen({ port: config.port, host: config.host });
    startBackupCronScheduler();
    console.log(`\n🚀 JOYN Backend API Server running at http://${config.host}:${config.port}`);
    console.log(`📌 Phase 1 & 2 Endpoints Live:`);
    console.log(`   - Auth, Business, Items, Parties`);
    console.log(`📌 Phase 3 Endpoints Live:`);
    console.log(`   - POST/GET /api/v1/sales/orders (Sales Invoicing & Stock Deduction)`);
    console.log(`   - POST/GET /api/v1/purchases/orders (Purchase Orders & Stock Addition)`);
    console.log(`   - POST/GET /api/v1/payments (Payments Ledger)`);
    console.log(`📌 Phase 4 Endpoints Live:`);
    console.log(`   - GET /api/v1/barcode/search & POST /api/v1/barcode/generate`);
    console.log(`   - GET /api/v1/sales/orders/:id/pdf (GST Tax Invoice PDF Generator)`);
    console.log(`   - GET /api/v1/sales/orders/:id/whatsapp-share (WhatsApp Message & Deep Link)`);
    console.log(`   - GET /public/invoices/:token (Public Online Customer Invoice Portal)\n`);
  } catch (err) {
    fastify.log.error(err);
    process.exit(1);
  }
}

startServer();
