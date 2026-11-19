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

async function runPhase10Migration() {
  console.log("================================================================================");
  console.log("🚀 STARTING PHASE 10 DATABASE MIGRATION (GST FILING & EXPENSES ENGINE)");
  console.log("================================================================================");

  const client = await pool.connect();
  try {
    await client.query('BEGIN');

    // 1. Ensure expenses table
    console.log("1. Creating expenses table if not exists...");
    await client.query(`
      CREATE TABLE IF NOT EXISTS expenses (
        id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
        business_id UUID NOT NULL REFERENCES business_profile(id) ON DELETE CASCADE,
        expense_category VARCHAR(100) NOT NULL,
        expense_type VARCHAR(20) DEFAULT 'Indirect',
        amount NUMERIC(12, 2) NOT NULL,
        payment_mode VARCHAR(30) DEFAULT 'CASH',
        notes TEXT,
        expense_date DATE DEFAULT CURRENT_DATE,
        created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
      );

      CREATE INDEX IF NOT EXISTS idx_expenses_biz_date ON expenses(business_id, expense_date DESC);
    `);

    // 2. Ensure parties gst_number
    console.log("2. Ensuring parties.gst_number column...");
    await client.query(`
      ALTER TABLE parties ADD COLUMN IF NOT EXISTS gst_number VARCHAR(25);
      CREATE INDEX IF NOT EXISTS idx_parties_gst ON parties(business_id, gst_number);
    `);

    // 3. Ensure sales & purchase order date performance indexes
    console.log("3. Ensuring performance indexes on sales and purchase orders...");
    await client.query(`
      CREATE INDEX IF NOT EXISTS idx_sales_biz_date ON sales_orders(business_id, date DESC);
      CREATE INDEX IF NOT EXISTS idx_purchases_biz_date ON purchase_orders(business_id, date DESC);
    `);

    await client.query('COMMIT');
    console.log("✅ Phase 10 Database Migration Completed Successfully!");
  } catch (err) {
    await client.query('ROLLBACK');
    console.error("❌ Phase 10 Migration Failed:", err);
    process.exit(1);
  } finally {
    client.release();
    await pool.end();
  }
}

runPhase10Migration();

