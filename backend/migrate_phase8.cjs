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

async function runPhase8Migration() {
  console.log("================================================================================");
  console.log("🚀 STARTING PHASE 8 DATABASE MIGRATION (INVOICE BRANDING & UPI QR)");
  console.log("================================================================================");

  const client = await pool.connect();
  try {
    await client.query('BEGIN');

    // 1. Add branding, banking & theme columns to business_profile
    console.log("1. Adding branding, banking, and invoice theme columns to business_profile...");
    await client.query(`
      ALTER TABLE business_profile ADD COLUMN IF NOT EXISTS logo_url TEXT;
      ALTER TABLE business_profile ADD COLUMN IF NOT EXISTS signature_url TEXT;
      ALTER TABLE business_profile ADD COLUMN IF NOT EXISTS bank_name VARCHAR(100);
      ALTER TABLE business_profile ADD COLUMN IF NOT EXISTS account_number VARCHAR(50);
      ALTER TABLE business_profile ADD COLUMN IF NOT EXISTS ifsc_code VARCHAR(25);
      ALTER TABLE business_profile ADD COLUMN IF NOT EXISTS branch_name VARCHAR(100);
      ALTER TABLE business_profile ADD COLUMN IF NOT EXISTS upi_id VARCHAR(100);
      ALTER TABLE business_profile ADD COLUMN IF NOT EXISTS invoice_theme VARCHAR(50) DEFAULT 'classic_blue';
      ALTER TABLE business_profile ADD COLUMN IF NOT EXISTS invoice_color_hex VARCHAR(20) DEFAULT '#4338CA';
      ALTER TABLE business_profile ADD COLUMN IF NOT EXISTS invoice_terms TEXT DEFAULT '1. Goods once sold will not be taken back or exchanged.\\n2. Payment due within 15 days of invoice date.\\n3. Subject to local jurisdiction.';
      ALTER TABLE business_profile ADD COLUMN IF NOT EXISTS show_upi_qr BOOLEAN DEFAULT TRUE;
    `);

    // 2. Add invoice_theme & payment_qr tracking to sales_orders if desired
    console.log("2. Adding theme override and upi_qr to sales_orders...");
    await client.query(`
      ALTER TABLE sales_orders ADD COLUMN IF NOT EXISTS invoice_theme VARCHAR(50);
      ALTER TABLE sales_orders ADD COLUMN IF NOT EXISTS upi_payment_string TEXT;
    `);

    await client.query('COMMIT');
    console.log("✅ Phase 8 Database Migration Completed Successfully!");
  } catch (err) {
    await client.query('ROLLBACK');
    console.error("❌ Migration Failed:", err);
    process.exit(1);
  } finally {
    client.release();
    await pool.end();
  }
}

runPhase8Migration();

