# 🚀 JOYN Enterprise Backend & Database Master Implementation Specification

---

## 📌 Executive Architecture Summary

**JOYN** is a high-speed, enterprise-grade **Offline-First Multi-Tenant ERP, Billing, Inventory, Accounting & POS Ecosystem** designed for mobile and web.

The mobile app relies on a local **SQLite (`sqflite`)** database for zero-latency offline operation. The cloud backend on **MilesWeb Server** at `api.joynonline.in` acts as the single source of truth, managing **multi-tenant data synchronization, 2Factor.in SMS OTP authentication, double-entry financial accounting, BullMQ background queues, and FCM push notifications**.

---

## 1. Environment & Server Infrastructure Specs

- **Server IP**: `45.199.139.28`
- **Domain**: `api.joynonline.in`
- **SSL Certificate**: Let's Encrypt TLS 1.3 (HTTPS)
- **2Factor.in API Key**: `1eed4550-986f-11f1-9cb1-0200cd936042`
- **Reverse Proxy**: LiteSpeed / Nginx
- **API Runtime**: Node.js 20 LTS (TypeScript + Fastify) running via PM2 Cluster Mode
- **Primary Database**: MySQL 8.0 / PostgreSQL 16 (Multi-Tenant Row Level Security)
- **Cache & Message Broker**: Redis 7 + BullMQ Queue Engine

---

## 2. Deep-Dive Feature Mapping (Frontend -> Backend Database)

```
+-------------------------------------------------------------------------------------------------------------------+
|                                          JOYN FLUTTER MOBILE APP                                                  |
|                                     (Local SQLite Engine `joyn_database.db`)                                      |
+--------------------+---------------------+----------------------+---------------------+-------------------+
                     |                     |                      |                     |                   |
                     v                     v                      v                     v                   v
            +----------------+   +-------------------+  +-------------------+ +-------------------+ +------------------+
            |  Auth Module   |   | Business Profile  |  | Inventory Items   | | Parties / Ledger  | | Billing & Sales  |
            | (2Factor SMS)  |   | (Logo/Sign/Cards) |  | (SKU, Stock, Tax) | | (Customer/Vendor)| | (Invoices, POs) |
            +-------+--------+   +---------+---------+  +---------+---------+ +---------+---------+ +--------+---------+
                    |                      |                      |                     |                  |
                    +----------------------+----------------------+---------------------+------------------+
                                                                  |
                                                           REST HTTPS / WSS
                                                        (JWT RSA-256 Tokens)
                                                                  |
                                                                  v
+-------------------------------------------------------------------------------------------------------------------+
|                                      MILESWEB BACKEND API GATEWAY                                                 |
|                                       (Node.js Fastify + TypeScript)                                              |
|                                                                                                                   |
|  +--------------------------+  +--------------------------+  +--------------------------+  +-------------------+  |
|  | Multi-Tenant RBAC Guard  |  | Delta Sync Engine        |  | Accounting Calculation   |  | Rate Limiter      |  |
|  | (business_id isolation)  |  | (LWW & Append Ledgers)   |  | (GST, CGST/SGST/IGST)    |  | (DDoS Protection) |  |
|  +--------------+-----------+  +------------+-------------+  +------------+-------------+  +---------+---------+  |
|                 |                           |                             |                        |              |
|                 v                           v                             v                        v              |
|  +-------------------------------------------------------------------------------------------------------------+  |
|  |                                  BullMQ Distributed Async Task Queue                                        |  |
|  |           [sms-otp-queue]    [pdf-invoice-queue]    [fcm-notification-queue]    [sync-queue]                 |  |
|  +--------------+---------------------------+-----------------------------+------------------------+-----------+  |
|                 |                           |                             |                        |              |
|                 v                           v                             v                        v              |
|      +---------------------+     +--------------------+       +---------------------+     +--------------------+  |
|      | Redis 7 Cache Server|     | MySQL 8.0 / Postgres|       | Firebase FCM Push   |     | 2Factor.in SMS API |  |
|      | (Sessions & Queues) |     | (ACID Database)    |       | & Crashlytics Logs  |     | (DLT OTP Gateway)  |  |
|      +---------------------+     +--------------------+       +---------------------+     +--------------------+  |
+-------------------------------------------------------------------------------------------------------------------+
```

---

## 3. Database Schema Mapping (MySQL 8.0 / PostgreSQL 16)

```sql
-- 1. USERS & AUTHENTICATION TABLE
CREATE TABLE users (
    id VARCHAR(36) PRIMARY KEY,
    phone_number VARCHAR(15) UNIQUE NOT NULL,
    full_name VARCHAR(100),
    email VARCHAR(150),
    fcm_device_token TEXT,
    is_verified BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);

-- 2. BUSINESS PROFILE (TENANTS) TABLE
CREATE TABLE business_profile (
    id VARCHAR(36) PRIMARY KEY,
    owner_id VARCHAR(36) NOT NULL,
    business_name VARCHAR(150) NOT NULL,
    owner_name VARCHAR(100),
    gst_number VARCHAR(20),
    business_type VARCHAR(50),
    business_category VARCHAR(100),
    phone1 VARCHAR(15),
    phone2 VARCHAR(15),
    email VARCHAR(150),
    website VARCHAR(200),
    address TEXT,
    city VARCHAR(50),
    state VARCHAR(50),
    pincode VARCHAR(10),
    country VARCHAR(50) DEFAULT 'India',
    description TEXT,
    books_start_date DATE,
    logo_url TEXT,
    signature_url TEXT,
    show_gst_on_card BOOLEAN DEFAULT FALSE,
    show_business_type_on_card BOOLEAN DEFAULT FALSE,
    show_category_on_card BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (owner_id) REFERENCES users(id) ON DELETE CASCADE
);

-- 3. ROLES & PERMISSIONS (RBAC) TABLE
CREATE TABLE roles (
    id VARCHAR(36) PRIMARY KEY,
    business_id VARCHAR(36) NOT NULL,
    name VARCHAR(50) NOT NULL,
    access_sales INT DEFAULT 0,
    access_purchase INT DEFAULT 0,
    access_inventory INT DEFAULT 0,
    access_reports INT DEFAULT 0,
    access_admin INT DEFAULT 0,
    access_party_details INT DEFAULT 0,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (business_id) REFERENCES business_profile(id) ON DELETE CASCADE
);

-- 4. TEAM MEMBERS TABLE
CREATE TABLE team_members (
    id VARCHAR(36) PRIMARY KEY,
    business_id VARCHAR(36) NOT NULL,
    user_id VARCHAR(36),
    name VARCHAR(100) NOT NULL,
    phone VARCHAR(15),
    email VARCHAR(150),
    role_id VARCHAR(36),
    is_active INT DEFAULT 1,
    photo_url TEXT,
    last_login_at TIMESTAMP NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (business_id) REFERENCES business_profile(id) ON DELETE CASCADE,
    FOREIGN KEY (role_id) REFERENCES roles(id) ON DELETE SET NULL
);

-- 5. PARTIES (CUSTOMERS & SUPPLIERS) TABLE
CREATE TABLE parties (
    id VARCHAR(36) PRIMARY KEY,
    business_id VARCHAR(36) NOT NULL,
    name VARCHAR(150) NOT NULL,
    category VARCHAR(50),
    contact_number VARCHAR(15),
    email VARCHAR(150),
    address TEXT,
    city VARCHAR(50) DEFAULT '',
    opening_balance DECIMAL(12, 2) DEFAULT 0.00,
    balance_type VARCHAR(20) DEFAULT 'toReceive',
    credit_limit DECIMAL(12, 2),
    party_type VARCHAR(20) DEFAULT 'customer',
    priority_level VARCHAR(20) DEFAULT 'medium',
    avatar_index INT DEFAULT 0,
    photo_url TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (business_id) REFERENCES business_profile(id) ON DELETE CASCADE
);

-- 6. INVENTORY ITEMS TABLE
CREATE TABLE items (
    id VARCHAR(36) PRIMARY KEY,
    business_id VARCHAR(36) NOT NULL,
    name VARCHAR(200) NOT NULL,
    sku VARCHAR(100),
    barcode VARCHAR(100),
    barcode_mode VARCHAR(20) DEFAULT 'same',
    unit VARCHAR(20) DEFAULT 'Pcs',
    category VARCHAR(100),
    hsn_sac VARCHAR(20),
    location VARCHAR(100),
    photo_url TEXT,
    purchase_price DECIMAL(12, 2) DEFAULT 0.00,
    selling_price DECIMAL(12, 2) DEFAULT 0.00,
    sale_price_tax_mode VARCHAR(20) DEFAULT 'withoutTax',
    purchase_price_tax_mode VARCHAR(20) DEFAULT 'withoutTax',
    discount_on_sale_price DECIMAL(8, 2) DEFAULT 0.00,
    discount_type VARCHAR(20) DEFAULT 'percentage',
    tax_rate_label VARCHAR(50) DEFAULT 'None',
    tax_rate_percent DECIMAL(5, 2) DEFAULT 0.00,
    stock INT DEFAULT 0,
    min_stock_alert INT DEFAULT 5,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (business_id) REFERENCES business_profile(id) ON DELETE CASCADE
);

-- 7. SALES ORDERS / INVOICES TABLE
CREATE TABLE sales_orders (
    id VARCHAR(36) PRIMARY KEY,
    business_id VARCHAR(36) NOT NULL,
    invoice_no INT NOT NULL,
    date DATE NOT NULL,
    payment_mode VARCHAR(30) DEFAULT 'Cash',
    is_one_time_customer INT DEFAULT 0,
    party_id VARCHAR(36),
    customer_name VARCHAR(150),
    customer_phone VARCHAR(15),
    items_json JSON NOT NULL,
    total_amount DECIMAL(12, 2) NOT NULL DEFAULT 0.00,
    received_amount DECIMAL(12, 2) DEFAULT 0.00,
    payment_type VARCHAR(30) DEFAULT 'Cash',
    state_of_supply VARCHAR(50) DEFAULT '',
    description TEXT,
    terms_and_conditions TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (business_id) REFERENCES business_profile(id) ON DELETE CASCADE,
    FOREIGN KEY (party_id) REFERENCES parties(id) ON DELETE SET NULL
);

-- 8. PURCHASE ORDERS TABLE
CREATE TABLE purchase_orders (
    id VARCHAR(36) PRIMARY KEY,
    business_id VARCHAR(36) NOT NULL,
    order_no INT NOT NULL,
    date DATE NOT NULL,
    due_date DATE,
    party_name VARCHAR(150),
    party_id VARCHAR(36),
    items_json JSON NOT NULL,
    total_amount DECIMAL(12, 2) DEFAULT 0.00,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (business_id) REFERENCES business_profile(id) ON DELETE CASCADE
);

-- 9. PAYMENTS IN / OUT TABLE
CREATE TABLE payments (
    id VARCHAR(36) PRIMARY KEY,
    business_id VARCHAR(36) NOT NULL,
    receipt_no INT NOT NULL,
    date DATE NOT NULL,
    party_id VARCHAR(36),
    party_name VARCHAR(150),
    party_phone VARCHAR(15),
    received_amount DECIMAL(12, 2) NOT NULL,
    payment_type VARCHAR(30) DEFAULT 'Cash',
    is_payment_out INT DEFAULT 0,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (business_id) REFERENCES business_profile(id) ON DELETE CASCADE
);
```

---

## 4. BullMQ Async Queue Architecture & Redis 7

To ensure zero API bottlenecks, heavy tasks are offloaded to **BullMQ worker threads**:

```
[ HTTP API Requests ]
        |
        v
+-------------------+      +-------------------+      +-------------------+      +-------------------+
|  sms-otp-queue    |      | pdf-invoice-queue |      | fcm-notify-queue  |      | sync-recon-queue  |
+---------+---------+      +---------+---------+      +---------+---------+      +---------+---------+
          |                          |                          |                          |
          v                          v                          v                          v
[2Factor SMS Worker]       [Puppeteer PDF Worker]      [Firebase FCM Worker]       [Ledger Sync Worker]
```

### Queue Definitions:
1. **`sms-otp-queue`**: Dispatches 2Factor.in SMS calls with automatic 3x exponential backoff retry logic.
2. **`pdf-invoice-queue`**: Render professional PDF invoices from HTML templates for WhatsApp sharing & instant download.
3. **`fcm-notify-queue`**: Sends real-time alerts when stock drops below `min_stock_alert` or when a payment receipt is generated.
4. **`sync-recon-queue`**: Batch reconciles offline transaction logs submitted by mobile Flutter devices.

---

## 5. Offline-First Synchronization Engine (Delta Sync)

```typescript
// Fastify Sync Controller Example
export async function pushSyncHandler(req: FastifyRequest, reply: FastifyReply) {
    const { businessId } = req.user;
    const { items, parties, salesOrders, lastSyncTimestamp } = req.body;

    const connection = await dbPool.getConnection();
    try {
        await connection.beginTransaction();

        // 1. Upsert Items with Last-Write-Wins (LWW) conflict check
        for (const item of items) {
            await connection.query(`
                INSERT INTO items (id, business_id, name, selling_price, purchase_price, stock, updated_at)
                VALUES (?, ?, ?, ?, ?, ?, ?)
                ON DUPLICATE KEY UPDATE
                    name = IF(VALUES(updated_at) >= updated_at, VALUES(name), name),
                    selling_price = IF(VALUES(updated_at) >= updated_at, VALUES(selling_price), selling_price),
                    stock = IF(VALUES(updated_at) >= updated_at, VALUES(stock), stock),
                    updated_at = IF(VALUES(updated_at) >= updated_at, VALUES(updated_at), updated_at)
            `, [item.id, businessId, item.name, item.sellingPrice, item.purchasePrice, item.stock, item.updatedAt]);
        }

        // 2. Insert Sales Orders (Append-Only Accounting Log)
        for (const order of salesOrders) {
            await connection.query(`
                INSERT IGNORE INTO sales_orders (id, business_id, invoice_no, date, party_id, items_json, total_amount)
                VALUES (?, ?, ?, ?, ?, ?, ?)
            `, [order.id, businessId, order.invoiceNo, order.date, order.partyId, JSON.stringify(order.items), order.totalAmount]);

            // Atomic Stock Deduction
            for (const orderItem of order.items) {
                await connection.query(`
                    UPDATE items SET stock = stock - ? 
                    WHERE id = ? AND business_id = ? AND stock >= ?
                `, [orderItem.qty, orderItem.itemId, businessId, orderItem.qty]);
            }
        }

        await connection.commit();
        return reply.send({ success: true, serverTimestamp: new Date().toISOString() });
    } catch (err) {
        await connection.rollback();
        return reply.status(500).send({ error: "Sync transaction failed" });
    } finally {
        connection.release();
    }
}
```

---

## 6. Complete Implementation Roadmap (20-Day Timeline)

```
Days 1–4: Core Server & Database Setup
  ├── Configure Node.js 20 LTS + Fastify + TypeScript codebase
  ├── Execute MySQL 8.0 / PostgreSQL 16 schema migrations
  └── Setup Redis 7 & BullMQ queue worker engine

Days 5–8: Authentication & Multi-Tenancy Middleware
  ├── Build 2Factor.in SMS OTP dispatch & verification API
  ├── Implement Asymmetric RSA-256 JWT Token Authority
  └── Create Business Profile creation & Row Level Security guards

Days 9–14: Core ERP APIs & Stock Engine
  ├── Develop Items SKU, Barcode, & Stock Deduction endpoints
  ├── Develop Sales Invoices, Purchase Orders, & Payments APIs
  └── Implement Offline Delta Sync Engine (Push/Pull)

Days 15–20: Analytics, FCM Notifications & Hardening
  ├── Build Reports Engine (Daybook, P&L, GST Export)
  ├── Integrate Firebase FCM Push Alerts & WhatsApp PDF Renderer
  └── Perform Load Testing (10,000 req/sec) & Final Live Launch
```
