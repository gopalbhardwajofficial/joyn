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

async function runPhase9Migration() {
  console.log("================================================================================");
  console.log("🚀 STARTING PHASE 9 DATABASE MIGRATION (NOTIFICATIONS & PAYMENT REMINDERS)");
  console.log("================================================================================");

  const client = await pool.connect();
  try {
    await client.query('BEGIN');

    // 1. Create notifications table
    console.log("1. Creating notifications table...");
    await client.query(`
      CREATE TABLE IF NOT EXISTS notifications (
        id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
        business_id UUID NOT NULL REFERENCES business_profile(id) ON DELETE CASCADE,
        user_id UUID REFERENCES users(id) ON DELETE SET NULL,
        title VARCHAR(200) NOT NULL,
        body TEXT NOT NULL,
        type VARCHAR(50) NOT NULL DEFAULT 'SYSTEM',
        data JSONB DEFAULT '{}',
        is_read BOOLEAN DEFAULT FALSE,
        created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
      );

      CREATE INDEX IF NOT EXISTS idx_notifications_biz ON notifications(business_id, created_at DESC);
      CREATE INDEX IF NOT EXISTS idx_notifications_read ON notifications(business_id, is_read);
    `);

    // 2. Create payment_reminders table
    console.log("2. Creating payment_reminders table...");
    await client.query(`
      CREATE TABLE IF NOT EXISTS payment_reminders (
        id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
        business_id UUID NOT NULL REFERENCES business_profile(id) ON DELETE CASCADE,
        party_id UUID REFERENCES parties(id) ON DELETE SET NULL,
        party_name VARCHAR(150) NOT NULL,
        party_phone VARCHAR(25),
        amount_due NUMERIC(12, 2) NOT NULL,
        reminder_type VARCHAR(30) DEFAULT 'MANUAL',
        channel VARCHAR(30) DEFAULT 'WHATSAPP',
        message_text TEXT,
        payment_link TEXT,
        status VARCHAR(30) DEFAULT 'SENT',
        created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
      );

      CREATE INDEX IF NOT EXISTS idx_reminders_biz ON payment_reminders(business_id, created_at DESC);
      CREATE INDEX IF NOT EXISTS idx_reminders_party ON payment_reminders(party_id);
    `);

    // 3. Ensure fcm_device_token in users
    console.log("3. Ensuring fcm_device_token in users table...");
    await client.query(`
      ALTER TABLE users ADD COLUMN IF NOT EXISTS fcm_device_token TEXT;
    `);

    await client.query('COMMIT');
    console.log("✅ Phase 9 Database Migration Completed Successfully!");
  } catch (err) {
    await client.query('ROLLBACK');
    console.error("❌ Migration Failed:", err);
    process.exit(1);
  } finally {
    client.release();
    await pool.end();
  }
}

runPhase9Migration();

