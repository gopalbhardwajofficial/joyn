import { getDbPool } from '../db/connection.js';

export async function performAutoBackupForBusiness(businessId: string): Promise<any> {
  const pool = getDbPool();

  // 1. Gather all tenant entities across all 11 phases
  const [
    bizRes,
    itemsRes,
    partiesRes,
    salesRes,
    purchasesRes,
    paymentsRes,
    expensesRes,
    teamRes,
    quotationsRes,
    creditNotesRes,
    debitNotesRes,
    remindersRes
  ] = await Promise.all([
    pool.query('SELECT * FROM business_profile WHERE id = $1', [businessId]).catch(() => ({ rows: [] })),
    pool.query('SELECT * FROM items WHERE business_id = $1 ORDER BY created_at ASC', [businessId]).catch(() => ({ rows: [] })),
    pool.query('SELECT * FROM parties WHERE business_id = $1 ORDER BY created_at ASC', [businessId]).catch(() => ({ rows: [] })),
    pool.query('SELECT * FROM sales_orders WHERE business_id = $1 ORDER BY created_at ASC', [businessId]).catch(() => ({ rows: [] })),
    pool.query('SELECT * FROM purchase_orders WHERE business_id = $1 ORDER BY created_at ASC', [businessId]).catch(() => ({ rows: [] })),
    pool.query('SELECT * FROM payments WHERE business_id = $1 ORDER BY created_at ASC', [businessId]).catch(() => ({ rows: [] })),
    pool.query('SELECT * FROM expenses WHERE business_id = $1 ORDER BY created_at ASC', [businessId]).catch(() => ({ rows: [] })),
    pool.query('SELECT tm.*, r.name as role_name FROM team_members tm LEFT JOIN roles r ON tm.role_id = r.id WHERE tm.business_id = $1', [businessId]).catch(() => ({ rows: [] })),
    pool.query('SELECT * FROM quotations WHERE business_id = $1 ORDER BY created_at ASC', [businessId]).catch(() => ({ rows: [] })),
    pool.query('SELECT * FROM credit_notes WHERE business_id = $1 ORDER BY created_at ASC', [businessId]).catch(() => ({ rows: [] })),
    pool.query('SELECT * FROM debit_notes WHERE business_id = $1 ORDER BY created_at ASC', [businessId]).catch(() => ({ rows: [] })),
    pool.query('SELECT * FROM payment_reminders WHERE business_id = $1 ORDER BY created_at ASC', [businessId]).catch(() => ({ rows: [] }))
  ]);

  const backupData = {
    version: '2.0',
    phase: 12,
    exportedAt: new Date().toISOString(),
    business: bizRes.rows[0] || null,
    items: itemsRes.rows,
    parties: partiesRes.rows,
    salesOrders: salesRes.rows,
    purchaseOrders: purchasesRes.rows,
    payments: paymentsRes.rows,
    expenses: expensesRes.rows,
    teamMembers: teamRes.rows,
    quotations: quotationsRes.rows,
    creditNotes: creditNotesRes.rows,
    debitNotes: debitNotesRes.rows,
    paymentReminders: remindersRes.rows
  };

  const jsonString = JSON.stringify(backupData);
  const fileSizeBytes = Buffer.byteLength(jsonString, 'utf8');

  const recordCount =
    backupData.items.length +
    backupData.parties.length +
    backupData.salesOrders.length +
    backupData.purchaseOrders.length +
    backupData.payments.length +
    backupData.expenses.length +
    backupData.quotations.length +
    backupData.creditNotes.length +
    backupData.debitNotes.length;

  const now = new Date();
  const dateStr = now.toISOString().split('T')[0];
  const timeStr = now.toLocaleTimeString('en-IN', { hour12: false });
  const backupName = `Automated Cloud Backup - ${dateStr} ${timeStr}`;

  // Insert into cloud_backups
  const insertRes = await pool.query(
    `INSERT INTO cloud_backups (
      business_id, backup_name, backup_type, file_size_bytes, record_count, storage_path, backup_data, device_name
    ) VALUES ($1, $2, 'AUTOMATED', $3, $4, $5, $6, 'JOYN Nightly Cron')
    RETURNING id, business_id, backup_name, backup_type, file_size_bytes, record_count, created_at`,
    [
      businessId,
      backupName,
      fileSizeBytes,
      recordCount,
      'postgres:cloud_backups.backup_data',
      jsonString
    ]
  );

  // Update backup_settings last_auto_backup_at
  await pool.query(
    `INSERT INTO backup_settings (business_id, auto_backup_enabled, last_auto_backup_at, updated_at)
     VALUES ($1, true, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)
     ON CONFLICT (business_id) DO UPDATE SET
       last_auto_backup_at = CURRENT_TIMESTAMP,
       updated_at = CURRENT_TIMESTAMP`,
    [businessId]
  );

  // Clean up old automated backups older than 30 days
  await pool.query(
    `DELETE FROM cloud_backups 
     WHERE business_id = $1 
       AND backup_type = 'AUTOMATED' 
       AND created_at < NOW() - INTERVAL '30 days'`,
    [businessId]
  );

  return insertRes.rows[0];
}

export async function runNightlyBackupCronJob(): Promise<{ processed: number; succeeded: number; failed: number }> {
  console.log('[CRON] Starting Nightly Cloud Backup Job...');
  const pool = getDbPool();
  let succeeded = 0;
  let failed = 0;

  try {
    // Select all businesses where auto backup is not explicitly disabled
    const bizRes = await pool.query(`
      SELECT bp.id, bp.name 
      FROM business_profile bp
      LEFT JOIN backup_settings bs ON bp.id = bs.business_id
      WHERE bs.auto_backup_enabled IS NULL OR bs.auto_backup_enabled = true
    `);

    for (const biz of bizRes.rows) {
      try {
        await performAutoBackupForBusiness(biz.id);
        succeeded++;
      } catch (err) {
        console.error(`[CRON] Backup failed for business ${biz.id} (${biz.name}):`, err);
        failed++;
      }
    }

    console.log(`[CRON] Nightly Cloud Backup Job Completed: ${succeeded} succeeded, ${failed} failed.`);
    return { processed: bizRes.rows.length, succeeded, failed };
  } catch (err) {
    console.error('[CRON] Global Nightly Backup Error:', err);
    return { processed: 0, succeeded: 0, failed: 1 };
  }
}

// Background Cron Scheduler (Runs every 24 hours at 2:00 AM UTC / interval)
let cronInterval: NodeJS.Timeout | null = null;

export function startBackupCronScheduler() {
  if (cronInterval) return;

  console.log('⏰ Starting Automated Backup Cron Scheduler (Interval: 24h)...');
  // Check once per hour
  cronInterval = setInterval(async () => {
    const currentHour = new Date().getUTCHours();
    // Run at 20:00 UTC (~01:30 AM IST)
    if (currentHour === 20) {
      await runNightlyBackupCronJob();
    }
  }, 1000 * 60 * 60);
}

