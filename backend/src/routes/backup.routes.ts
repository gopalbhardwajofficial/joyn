import { FastifyInstance } from 'fastify';
import {
  createBackupHandler,
  listBackupsHandler,
  getBackupByIdHandler,
  restoreBackupHandler,
  deleteBackupHandler,
  downloadBackupHandler,
  getBackupSettingsHandler,
  updateBackupSettingsHandler,
  triggerManualCronBackupHandler
} from '../controllers/backup.controller.js';
import { verifyBusinessAccess } from '../middleware/rbac.middleware.js';

export async function backupRoutes(fastify: FastifyInstance) {
  fastify.addHook('onRequest', async (req, reply) => {
    try {
      await req.jwtVerify();
    } catch (err) {
      return reply.status(401).send({ success: false, message: 'Unauthorized access.' });
    }
  });

  fastify.addHook('preHandler', async (req, reply) => {
    const access = await verifyBusinessAccess(req, reply, 'access_admin');
    if (!access) return reply;
  });

  fastify.post('/create', createBackupHandler);
  fastify.post('/', createBackupHandler);

  fastify.get('/list', listBackupsHandler);
  fastify.get('/', listBackupsHandler);

  fastify.get('/settings', getBackupSettingsHandler);
  fastify.put('/settings', updateBackupSettingsHandler);
  fastify.post('/trigger-cron', triggerManualCronBackupHandler);

  fastify.get('/:id', getBackupByIdHandler);
  fastify.get('/:id/download', downloadBackupHandler);

  fastify.post('/restore/:id', restoreBackupHandler);

  fastify.delete('/:id', deleteBackupHandler);
}
