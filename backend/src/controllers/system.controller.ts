import { FastifyRequest, FastifyReply } from 'fastify';
import { getDbPool } from '../db/connection.js';

export async function getSystemHealthHandler(req: FastifyRequest, reply: FastifyReply) {
  const startTime = Date.now();
  const pool = getDbPool();
  let dbStatus = 'DISCONNECTED';
  let latencyMs = 0;

  try {
    const dbCheck = await pool.query('SELECT NOW() as server_time');
    latencyMs = Date.now() - startTime;
    dbStatus = dbCheck.rows.length > 0 ? 'CONNECTED' : 'DEGRADED';
  } catch (err) {
    dbStatus = 'ERROR';
  }

  const mem = process.memoryUsage();
  const uptimeSec = Math.floor(process.uptime());

  const days = Math.floor(uptimeSec / 86400);
  const hours = Math.floor((uptimeSec % 86400) / 3600);
  const minutes = Math.floor((uptimeSec % 3600) / 60);
  const seconds = uptimeSec % 60;
  const formattedUptime = `${days}d ${hours}h ${minutes}m ${seconds}s`;

  return reply.send({
    status: dbStatus === 'CONNECTED' ? 'HEALTHY' : 'DEGRADED',
    service: 'JOYN ERP & Billing API',
    version: '1.0.0-phase12',
    timestamp: new Date().toISOString(),
    database: {
      status: dbStatus,
      latencyMs: `${latencyMs}ms`,
      totalClients: pool.totalCount,
      idleClients: pool.idleCount,
      waitingClients: pool.waitingCount
    },
    system: {
      platform: process.platform,
      nodeVersion: process.version,
      uptimeSeconds: uptimeSec,
      formattedUptime,
      memory: {
        rssMb: (mem.rss / 1024 / 1024).toFixed(2),
        heapUsedMb: (mem.heapUsed / 1024 / 1024).toFixed(2),
        heapTotalMb: (mem.heapTotal / 1024 / 1024).toFixed(2)
      }
    }
  });
}

export async function getSystemTelemetryHandler(req: FastifyRequest, reply: FastifyReply) {
  const pool = getDbPool();
  try {
    const [bizCount, itemsCount, salesCount, backupsCount] = await Promise.all([
      pool.query('SELECT COUNT(*) as count FROM business_profile'),
      pool.query('SELECT COUNT(*) as count FROM items WHERE is_deleted = 0'),
      pool.query('SELECT COUNT(*) as count FROM sales_orders WHERE is_deleted = 0'),
      pool.query('SELECT COUNT(*) as count FROM cloud_backups')
    ]);

    return reply.send({
      success: true,
      telemetry: {
        totalBusinesses: parseInt(bizCount.rows[0]?.count || 0),
        activeCatalogItems: parseInt(itemsCount.rows[0]?.count || 0),
        totalInvoices: parseInt(salesCount.rows[0]?.count || 0),
        storedCloudBackups: parseInt(backupsCount.rows[0]?.count || 0),
        timestamp: new Date().toISOString()
      }
    });
  } catch (error: any) {
    return reply.status(500).send({ success: false, message: error?.message || 'Failed to fetch telemetry.' });
  }
}

