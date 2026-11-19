const pg = require('pg');
require('dotenv').config();

const pool = new pg.Pool({
  host: process.env.DB_HOST || '10.169.0.20',
  port: parseInt(process.env.DB_PORT || '5432'),
  user: process.env.DB_USER || 'joynonli1_joynuser',
  password: process.env.DB_PASSWORD || 'Joynapp@147',
  database: process.env.DB_NAME || 'joynonli1_joyn',
  max: 5,
  idleTimeoutMillis: 10000,
});

async function runPhase12Migration() {
  console.log("================================================================================");
  console.log("🚀 STARTING PHASE 12 DATABASE MIGRATION (AUTOMATED BACKUPS & SECURITY SETTINGS)");
  console.log("================================================================================");

  const client = await pool.connect();
  try {
    await client.query('BEGIN');

    // 1. Ensure cloud_backups table exists with backup_type
    console.log("1. Ensuring cloud_backups table with enterprise columns...");
    await client.query(`
      CREATE TABLE IF NOT EXISTS cloud_backups (
        id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
        business_id UUID NOT NULL REFERENCES business_profile(id) ON DELETE CASCADE,
        backup_name VARCHAR(255) NOT NULL,
        backup_type VARCHAR(50) DEFAULT 'MANUAL',
        file_size_bytes BIGINT DEFAULT 0,
        record_count INT DEFAULT 0,
        storage_path VARCHAR(255) DEFAULT 'postgres:cloud_backups.backup_data',
        backup_data JSONB NOT NULL,
        device_name VARCHAR(100) DEFAULT 'JOYN Cloud',
        created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
      );

      ALTER TABLE cloud_backups ADD COLUMN IF NOT EXISTS backup_type VARCHAR(50) DEFAULT 'MANUAL';
      CREATE INDEX IF NOT EXISTS idx_cloud_backups_biz_created ON cloud_backups(business_id, created_at DESC);
      CREATE INDEX IF NOT EXISTS idx_cloud_backups_type ON cloud_backups(business_id, backup_type);
    `);

    // 2. Create backup_settings table for automated scheduling
    console.log("2. Creating backup_settings table for automated nightly cron...");
    await client.query(`
      CREATE TABLE IF NOT EXISTS backup_settings (
        business_id UUID PRIMARY KEY REFERENCES business_profile(id) ON DELETE CASCADE,
        auto_backup_enabled BOOLEAN DEFAULT true,
        frequency VARCHAR(20) DEFAULT 'DAILY',
        retention_days INT DEFAULT 30,
        last_auto_backup_at TIMESTAMP WITH TIME ZONE,
        updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
      );
    `);

    await client.query('COMMIT');
    console.log("✅ Phase 12 Database Migration Completed Successfully!");
  } catch (error) {
    await client.query('ROLLBACK');
    console.error("❌ Phase 12 Migration Failed:", error);
    process.exit(1);
  } finally {
    client.release();
    await pool.end();
  }
}

runPhase12Migration();

