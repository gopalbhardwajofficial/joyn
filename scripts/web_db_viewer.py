#!/usr/bin/env python3
"""
JOYN ERP - Live Web Database Viewer (phpMyAdmin-style)
Runs locally on your Mac:
  python3 scripts/web_db_viewer.py
Then open http://localhost:5050 in your browser!
"""

import http.server
import socketserver
import json
import urllib.parse
import webbrowser
import paramiko
import sys
import threading

PORT = 5050

SSH_HOST = '45.199.139.28'
SSH_PORT = 22
SSH_USER = 'joynonli1'
SSH_PASS = 'Gopalstar@147'

DB_HOST = '10.169.0.20'
DB_USER = 'joynonli1_joynuser'
DB_PASS = 'Joynapp@147'
DB_NAME = 'joynonli1_joyn'

def query_db_json(sql):
    ssh = paramiko.SSHClient()
    ssh.set_missing_host_key_policy(paramiko.AutoAddPolicy())
    ssh.connect(SSH_HOST, port=SSH_PORT, username=SSH_USER, password=SSH_PASS, timeout=10)

    # Wrap in JSON aggregation for clean structured output
    wrapped = f"SELECT json_agg(t) FROM ({sql}) t;"
    remote_cmd = (
        f'PGPASSWORD="{DB_PASS}" psql -h {DB_HOST} -U {DB_USER} -d {DB_NAME} -t -A -c "{wrapped}"'
    )
    stdin, stdout, stderr = ssh.exec_command(remote_cmd)
    raw = stdout.read().decode().strip()
    ssh.close()
    if not raw or raw == 'null':
        return []
    try:
        return json.loads(raw)
    except Exception as e:
        return [{"error": str(e), "raw": raw}]

HTML_PAGE = """<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <title>JOYN ERP - Live PostgreSQL Viewer</title>
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <link href="https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600;700&display=swap" rel="stylesheet">
  <style>
    * { box-sizing: border-box; margin: 0; padding: 0; }
    body { font-family: 'Inter', sans-serif; background: #0f172a; color: #f8fafc; display: flex; height: 100vh; overflow: hidden; }
    #sidebar { width: 280px; background: #1e293b; border-right: 1px solid #334155; display: flex; flex-direction: column; }
    .sidebar-header { padding: 20px; border-bottom: 1px solid #334155; display: flex; align-items: center; gap: 10px; }
    .sidebar-header h2 { font-size: 16px; font-weight: 700; color: #60a5fa; }
    .badge-pg { background: #3b82f6; color: #fff; font-size: 10px; padding: 2px 6px; border-radius: 4px; font-weight: 600; }
    .table-list { overflow-y: auto; flex: 1; padding: 12px 8px; }
    .table-item { display: flex; justify-content: space-between; align-items: center; padding: 10px 14px; border-radius: 8px; cursor: pointer; font-size: 13px; color: #cbd5e1; margin-bottom: 4px; transition: all 0.15s; }
    .table-item:hover { background: #334155; color: #fff; }
    .table-item.active { background: #2563eb; color: #fff; font-weight: 600; }
    .row-count { font-size: 11px; background: rgba(0,0,0,0.25); padding: 2px 7px; border-radius: 12px; }
    #main { flex: 1; display: flex; flex-direction: column; overflow: hidden; }
    .topbar { padding: 16px 24px; background: #1e293b; border-bottom: 1px solid #334155; display: flex; justify-content: space-between; align-items: center; }
    .table-title { font-size: 18px; font-weight: 700; color: #fff; }
    .actions { display: flex; gap: 10px; }
    .btn { background: #3b82f6; color: #fff; border: none; padding: 8px 14px; border-radius: 6px; font-size: 13px; font-weight: 500; cursor: pointer; transition: background 0.2s; }
    .btn:hover { background: #2563eb; }
    .btn-secondary { background: #334155; color: #e2e8f0; }
    .btn-secondary:hover { background: #475569; }
    .content { flex: 1; overflow: auto; padding: 20px; }
    .table-container { background: #1e293b; border: 1px solid #334155; border-radius: 8px; overflow: auto; max-height: calc(100vh - 150px); }
    table { width: 100%; border-collapse: collapse; font-size: 12px; text-align: left; }
    th { background: #0f172a; padding: 12px 14px; position: sticky; top: 0; color: #94a3b8; font-weight: 600; text-transform: uppercase; font-size: 11px; border-bottom: 1px solid #334155; white-space: nowrap; }
    td { padding: 12px 14px; border-bottom: 1px solid #334155; color: #e2e8f0; max-width: 300px; overflow: hidden; text-overflow: ellipsis; white-space: nowrap; }
    tr:hover td { background: #334155; }
    .empty-msg { text-align: center; padding: 40px; color: #94a3b8; font-size: 14px; }
    .spinner { display: inline-block; width: 16px; height: 16px; border: 2px solid rgba(255,255,255,0.3); border-radius: 50%; border-top-color: #fff; animation: spin 0.8s linear infinite; }
    @keyframes spin { to { transform: rotate(360deg); } }
  </style>
</head>
<body>
  <div id="sidebar">
    <div class="sidebar-header">
      <h2>🐘 JOYN DB</h2>
      <span class="badge-pg">PostgreSQL 16</span>
    </div>
    <div class="table-list" id="tableList">
      <div class="empty-msg">Loading tables...</div>
    </div>
  </div>

  <div id="main">
    <div class="topbar">
      <div>
        <div class="table-title" id="currentTableName">Select a Table</div>
        <div style="font-size: 12px; color: #94a3b8; margin-top: 4px;" id="currentTableSubtitle">Live Connected to MilesWeb VPS (joynonli1_joyn)</div>
      </div>
      <div class="actions">
        <button class="btn btn-secondary" onclick="refreshCurrentTable()">↻ Refresh</button>
      </div>
    </div>
    <div class="content">
      <div class="table-container" id="tableContainer">
        <div class="empty-msg">👈 Left sidebar se kisi bhi table par click karke live records dekhein.</div>
      </div>
    </div>
  </div>

  <script>
    let activeTable = '';

    async function loadTables() {
      try {
        const res = await fetch('/api/tables');
        const tables = await res.json();
        const listEl = document.getElementById('tableList');
        listEl.innerHTML = '';

        tables.forEach(t => {
          const item = document.createElement('div');
          item.className = 'table-item' + (t.table_name === activeTable ? ' active' : '');
          item.onclick = () => selectTable(t.table_name);
          item.innerHTML = `
            <span>📋 ${t.table_name}</span>
            <span class="row-count">${t.count}</span>
          `;
          listEl.appendChild(item);
        });

        if (!activeTable && tables.length > 0) {
          selectTable('sales_orders');
        }
      } catch (e) {
        document.getElementById('tableList').innerHTML = '<div class="empty-msg">Failed to load tables.</div>';
      }
    }

    async function selectTable(name) {
      activeTable = name;
      document.getElementById('currentTableName').textContent = '📋 ' + name;
      document.querySelectorAll('.table-item').forEach(el => {
        el.classList.toggle('active', el.textContent.includes(name));
      });

      const container = document.getElementById('tableContainer');
      container.innerHTML = '<div class="empty-msg"><span class="spinner"></span> Loading records...</div>';

      try {
        const res = await fetch('/api/data?table=' + encodeURIComponent(name));
        const rows = await res.json();

        if (!rows || rows.length === 0) {
          container.innerHTML = '<div class="empty-msg">Ye table abhi empty hai (No records found).</div>';
          return;
        }

        const cols = Object.keys(rows[0]);
        let html = '<table><thead><tr>';
        cols.forEach(c => html += `<th>${c}</th>`);
        html += '</tr></thead><tbody>';

        rows.forEach(r => {
          html += '<tr>';
          cols.forEach(c => {
            let val = r[c];
            if (val === null || val === undefined) val = '<span style="color:#64748b; font-style:italic;">null</span>';
            else if (typeof val === 'object') val = JSON.stringify(val);
            html += `<td title="${String(val).replace(/"/g, '&quot;')}">${val}</td>`;
          });
          html += '</tr>';
        });

        html += '</tbody></table>';
        container.innerHTML = html;
      } catch (err) {
        container.innerHTML = '<div class="empty-msg">Error loading records: ' + err.message + '</div>';
      }
    }

    function refreshCurrentTable() {
      if (activeTable) {
        selectTable(activeTable);
        loadTables();
      }
    }

    loadTables();
  </script>
</body>
</html>
"""

class DBViewerHandler(http.server.BaseHTTPRequestHandler):
    def do_GET(self):
        parsed = urllib.parse.urlparse(self.path)
        path = parsed.path
        query = urllib.parse.parse_qs(parsed.query)

        if path == '/' or path == '/index.html':
            self.send_response(200)
            self.send_header('Content-Type', 'text/html; charset=utf-8')
            self.end_headers()
            self.wfile.write(HTML_PAGE.encode('utf-8'))
            return

        if path == '/api/tables':
            sql = """
            SELECT table_name, 
                   (xpath('/row/cnt/text()', xml_count))[1]::text::int as count
            FROM (
              SELECT table_name, 
                     query_to_xml(format('select count(*) as cnt from %I', table_name), false, true, '') as xml_count
              FROM information_schema.tables 
              WHERE table_schema = 'public'
            ) t
            ORDER BY table_name;
            """
            data = query_db_json(sql)
            self.send_response(200)
            self.send_header('Content-Type', 'application/json')
            self.end_headers()
            self.wfile.write(json.dumps(data).encode('utf-8'))
            return

        if path == '/api/data':
            table = query.get('table', [''])[0]
            if not table:
                self.send_response(400)
                self.end_headers()
                return

            sql = f'SELECT * FROM "{table}" ORDER BY 1 DESC LIMIT 100;'
            data = query_db_json(sql)
            self.send_response(200)
            self.send_header('Content-Type', 'application/json')
            self.end_headers()
            self.wfile.write(json.dumps(data).encode('utf-8'))
            return

        self.send_response(404)
        self.end_headers()

    def log_message(self, format, *args):
        pass

def start_server():
    socketserver.TCPServer.allow_reuse_address = True
    with socketserver.TCPServer(("", PORT), DBViewerHandler) as httpd:
        print(f"🚀 Live Web Database Viewer running at: http://localhost:{PORT}")
        print("Press Ctrl+C to stop.")
        httpd.serve_forever()

if __name__ == '__main__':
    print("=" * 80)
    print("🐘 JOYN ERP - LIVE WEB DATABASE VIEWER (PHPMYADMIN ALTERNATIVE)")
    print("=" * 80)
    webbrowser.open(f'http://localhost:{PORT}')
    start_server()

