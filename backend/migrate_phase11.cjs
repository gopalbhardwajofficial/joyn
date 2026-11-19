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

async function runPhase11Migration() {
  console.log("================================================================================");
  console.log("🚀 STARTING PHASE 11 DATABASE MIGRATION (QUOTATIONS, CREDIT & DEBIT NOTES)");
  console.log("================================================================================");

  const client = await pool.connect();
  try {
    await client.query('BEGIN');

    // 1. Create quotations / estimates table
    console.log("1. Creating quotations table...");
    await client.query(`
      CREATE TABLE IF NOT EXISTS quotations (
        id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
        business_id UUID NOT NULL REFERENCES business_profile(id) ON DELETE CASCADE,
        quotation_no INT NOT NULL,
        date DATE NOT NULL,
        expiry_date DATE,
        party_id UUID REFERENCES parties(id) ON DELETE SET NULL,
        customer_name VARCHAR(150),
        customer_phone VARCHAR(25),
        items_json JSONB NOT NULL DEFAULT '[]',
        total_amount NUMERIC(12, 2) NOT NULL DEFAULT 0.00,
        status VARCHAR(30) DEFAULT 'OPEN',
        converted_invoice_id UUID REFERENCES sales_orders(id) ON DELETE SET NULL,
        notes TEXT,
        created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
      );

      CREATE INDEX IF NOT EXISTS idx_quotations_biz_no ON quotations(business_id, quotation_no);
      CREATE INDEX IF NOT EXISTS idx_quotations_biz_date ON quotations(business_id, date DESC);
      CREATE INDEX IF NOT EXISTS idx_quotations_status ON quotations(business_id, status);
    `);

    // 2. Create credit_notes (Sales Return) table
    console.log("2. Creating credit_notes (Sales Return) table...");
    await client.query(`
      CREATE TABLE IF NOT EXISTS credit_notes (
        id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
        business_id UUID NOT NULL REFERENCES business_profile(id) ON DELETE CASCADE,
        note_no INT NOT NULL,
        date DATE NOT NULL,
        party_id UUID REFERENCES parties(id) ON DELETE SET NULL,
        customer_name VARCHAR(150),
        original_invoice_no INT,
        items_json JSONB NOT NULL DEFAULT '[]',
        return_amount NUMERIC(12, 2) NOT NULL DEFAULT 0.00,
        reason TEXT,
        refund_mode VARCHAR(30) DEFAULT 'CREDIT',
        created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
      );

      CREATE INDEX IF NOT EXISTS idx_credit_notes_biz_no ON credit_notes(business_id, note_no);
      CREATE INDEX IF NOT EXISTS idx_credit_notes_biz_date ON credit_notes(business_id, date DESC);
    `);

    // 3. Create debit_notes (Purchase Return) table
    console.log("3. Creating debit_notes (Purchase Return) table...");
    await client.query(`
      CREATE TABLE IF NOT EXISTS debit_notes (
        id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
        business_id UUID NOT NULL REFERENCES business_profile(id) ON DELETE CASCADE,
        note_no INT NOT NULL,
        date DATE NOT NULL,
        party_id UUID REFERENCES parties(id) ON DELETE SET NULL,
        supplier_name VARCHAR(150),
        original_order_no INT,
        items_json JSONB NOT NULL DEFAULT '[]',
        return_amount NUMERIC(12, 2) NOT NULL DEFAULT 0.00,
        reason TEXT,
        created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
      );

      CREATE INDEX IF NOT EXISTS idx_debit_notes_biz_no ON debit_notes(business_id, note_no);
      CREATE INDEX IF NOT EXISTS idx_debit_notes_biz_date ON debit_notes(business_id, date DESC);
    `);

    await client.query('COMMIT');
    console.log("✅ Phase 11 Database Migration Completed Successfully!");
  } catch (err) {
    await client.query('ROLLBACK');
    console.error("❌ Phase 11 Migration Failed:", err);
    process.exit(1);
  } finally {
    client.release();
    await pool.end();
  }
}

runPhase11Migration();

