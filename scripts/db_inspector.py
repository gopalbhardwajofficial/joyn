#!/usr/bin/env python3
"""
JOYN ERP - Live PostgreSQL Database Quick Inspector
Run from your Mac terminal:
  python3 scripts/db_inspector.py
"""

import paramiko
import sys

HOST = '45.199.139.28'
PORT = 22
SSH_USER = 'joynonli1'
SSH_PASS = 'Gopalstar@147'

DB_HOST = '10.169.0.20'
DB_USER = 'joynonli1_joynuser'
DB_PASS = 'Joynapp@147'
DB_NAME = 'joynonli1_joyn'

def run_query(sql):
    ssh = paramiko.SSHClient()
    ssh.set_missing_host_key_policy(paramiko.AutoAddPolicy())
    ssh.connect(HOST, port=PORT, username=SSH_USER, password=SSH_PASS)

    remote_cmd = (
        f'PGPASSWORD="{DB_PASS}" psql -h {DB_HOST} -U {DB_USER} -d {DB_NAME} -c "{sql}"'
    )
    stdin, stdout, stderr = ssh.exec_command(remote_cmd)
    out = stdout.read().decode()
    err = stderr.read().decode()
    ssh.close()
    if err and not out:
        return f"Error: {err}"
    return out

def main():
    table = sys.argv[1] if len(sys.argv) > 1 else None

    print("=" * 80)
    print("🐘 JOYN ERP - LIVE POSTGRESQL DATABASE INSPECTOR")
    print("=" * 80)

    if not table:
        print("\n📊 1. LIVE RECORD COUNTS ACROSS ALL MODULES:\n")
        stats_query = """
        SELECT 'business_profile' as table_name, count(*) as total_rows FROM business_profile
        UNION ALL SELECT 'items', count(*) FROM items
        UNION ALL SELECT 'parties', count(*) FROM parties
        UNION ALL SELECT 'sales_orders', count(*) FROM sales_orders
        UNION ALL SELECT 'purchase_orders', count(*) FROM purchase_orders
        UNION ALL SELECT 'payments', count(*) FROM payments
        UNION ALL SELECT 'expenses', count(*) FROM expenses
        UNION ALL SELECT 'quotations', count(*) FROM quotations
        UNION ALL SELECT 'credit_notes', count(*) FROM credit_notes
        UNION ALL SELECT 'debit_notes', count(*) FROM debit_notes
        UNION ALL SELECT 'team_members', count(*) FROM team_members
        UNION ALL SELECT 'cloud_backups', count(*) FROM cloud_backups;
        """
        print(run_query(stats_query))

        print("\n💡 TIP: To inspect a specific table, run:")
        print("  python3 scripts/db_inspector.py sales_orders")
        print("  python3 scripts/db_inspector.py items")
        print("  python3 scripts/db_inspector.py parties")
        print("  python3 scripts/db_inspector.py business_profile")
    else:
        print(f"\n📋 LATEST 5 RECORDS IN TABLE: {table}\n")
        inspect_query = f"SELECT * FROM {table} ORDER BY created_at DESC LIMIT 5;"
        print(run_query(inspect_query))

    print("=" * 80)

if __name__ == '__main__':
    main()

