import pg from 'pg';
import { config } from '../config/index.js';

const { Pool } = pg;
let pool: pg.Pool | null = null;

export function getDbPool(): pg.Pool {
  if (!pool) {
    pool = new Pool({
      host: config.db.host,
      port: config.db.port,
      user: config.db.user,
      password: config.db.password,
      database: config.db.database,
      max: 20,
      idleTimeoutMillis: 30000,
      connectionTimeoutMillis: 5000,
    });

    pool.on('error', (err) => {
      console.error('Unexpected PostgreSQL Pool Error:', err);
    });
  }
  return pool;
}

export async function testDbConnection(): Promise<boolean> {
  try {
    const p = getDbPool();
    const res = await p.query('SELECT current_database(), now();');
    console.log(`✅ Connected to PostgreSQL 16 DB [${res.rows[0].current_database}] at ${res.rows[0].now}`);
    return true;
  } catch (error: any) {
    console.warn('⚠️ PostgreSQL DB connection status:', error?.message || error);
    return false;
  }
}
