# 🚀 JOYN Backend & Database Architecture — Comprehensive Technical Specification Roadmap

---

## 📋 Executive Overview

**JOYN** is a high-performance **Offline-First Multi-Tenant ERP, Billing, Inventory & POS Platform** designed for mobile and web. The frontend (Flutter) operates with an offline-first **SQLite (`sqflite`)** database, enabling zero-latency offline operations.

This document outlines the **complete production-grade backend ecosystem**, including cloud server deployment on **MilesWeb Cloud**, high-concurrency **Node.js (TypeScript + Fastify)** REST API engine, **PostgreSQL 16** multi-tenant transactional database schema, **Redis 7** caching layer, **2Factor.in** SMS OTP gateway, and **Firebase** (FCM Push Notifications & Crashlytics).

---

## 1. High-Level Architecture Diagram

```
                                  +-------------------------------------------------+
                                  |            JOYN Mobile Flutter App              |
                                  |   (Offline-First Local SQLite Database Engine)  |
                                  +------------------------+------------------------+
                                                           |
                                                   HTTPS / TLS 1.3
                                                (JWT Bearer Tokens)
                                                           |
                                                           v
+-------------------------------------------------------------------------------------------------------------------+
|                                            MilesWeb Cloud VPS Server                                              |
|                                                                                                                   |
|  +-------------------------------------------------------------------------------------------------------------+  |
|  |                                  Nginx Reverse Proxy & Load Balancer                                        |  |
|  |                        (Rate Limiting, SSL Termination, Static Asset Serving)                               |  |
|  +-------------------------------------------------------+-----------------------------------------------------+  |
|                                                          |                                                        |
|                                                          v                                                        |
|  +-------------------------------------------------------------------------------------------------------------+  |
|  |                                Node.js (TypeScript + Fastify) Server Cluster                               |  |
|  |                 - Authentication & Token Management Service                                                 |  |
|  |                 - Offline Delta Sync & Conflict Resolution Engine                                           |  |
|  |                 - Multi-Tenant Row-Level Security Middleware                                                |  |
|  |                 - Double-Entry Accounting & Ledger Computation Engine                                       |  |
|  |                 - Automated PDF Invoice & Receipt Generation Worker                                         |  |
|  +-------------+-----------------------------------------+----------------------------------------+------------+  |
|                |                                         |                                        |               |
|                v                                         v                                        v               |
|  +---------------------------+             +---------------------------+            +--------------------------+  |
|  |    PostgreSQL 16 DB       |             |       Redis 7 Cache       |            |    Local File Storage    |  |
|  | (ACID Multi-Tenant Store) |             | (OTP, Sessions, BullMQ)   |            |  (Logos, Signs, PDFs)    |  |
|  +---------------------------+             +---------------------------+            +--------------------------+  |
+-------------------------------------------------------------------------------------------------------------------+
       |                                                   |                                           |
       v                                                   v                                           v
+------------------+                              +-------------------+                       +---------------------+
| 2Factor.in API   |                              | Firebase (FCM)    |                       | WhatsApp Business   |
| (DLT SMS Gateway)|                              | (Push Notifications)|                     | (Direct PDF Share)  |
+------------------+                              +-------------------+                       +---------------------+
```

---

## 2. Infrastructure & Hosting Configuration

### 2.1 MilesWeb Cloud Server Environment
- **Operating System**: Ubuntu 22.04 LTS x86_64
- **Web Server / Reverse Proxy**: **Nginx** (Configured with HTTP/2, HTTP/3, Brotli Compression, SSL TLS 1.3)
- **Process Manager**: **PM2** Cluster Mode (spawns 1 instance per CPU core for max CPU utilization)
- **Runtime Environment**: Node.js v20 LTS + TypeScript v5

```nginx
# /etc/nginx/sites-available/joyn-api.conf
upstream joyn_backend {
    server 127.0.0.1:3000 max_fails=3 fail_timeout=30s;
    server 127.0.0.1:3001 max_fails=3 fail_timeout=30s;
    keepalive 64;
}

server {
    listen 443 ssl http2;
    server_name api.joynapp.in;

    ssl_certificate /etc/letsencrypt/live/api.joynapp.in/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/api.joynapp.in/privkey.pem;
    ssl_protocols TLSv1.2 TLSv1.3;

    # Limit Rate: 100 requests / minute per IP
    limit_req zone=api_limit burst=20 nodelay;

    location /api/v1/ {
        proxy_pass http://joyn_backend;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
```

---

## 3. Comprehensive Database Schema (PostgreSQL 16)

PostgreSQL provides **strict ACID compliance** for financial accounting, double-entry integrity, and JSONB document support.

```sql
-- Enable UUID extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- ==================================================================
-- 1. USERS TABLE
-- ==================================================================
CREATE TABLE users (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    phone_number VARCHAR(15) UNIQUE NOT NULL,
    full_name VARCHAR(100),
    email VARCHAR(150),
    fcm_device_token TEXT,
    is_verified BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_users_phone ON users(phone_number);

-- ==================================================================
-- 2. BUSINESS PROFILE TABLE (TENANTS)
-- ==================================================================
CREATE TABLE business_profile (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    owner_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    business_name VARCHAR(150) NOT NULL,
    owner_name VARCHAR(100),
    gst_number VARCHAR(20),
    business_type VARCHAR(50),      -- Retailer, Wholesaler, Manufacturer, Service
    business_category VARCHAR(100),  -- Electronics, Apparel, Grocery, etc.
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
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_business_owner ON business_profile(owner_id);

-- ==================================================================
-- 3. ROLES & PERMISSIONS TABLE (RBAC)
-- ==================================================================
CREATE TABLE roles (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    business_id UUID NOT NULL REFERENCES business_profile(id) ON DELETE CASCADE,
    name VARCHAR(50) NOT NULL,
    access_sales BOOLEAN DEFAULT FALSE,
    access_purchase BOOLEAN DEFAULT FALSE,
    access_inventory BOOLEAN DEFAULT FALSE,
    access_reports BOOLEAN DEFAULT FALSE,
    access_admin BOOLEAN DEFAULT FALSE,
    access_party_details BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_roles_business ON roles(business_id);

-- ==================================================================
-- 4. TEAM MEMBERS TABLE
-- ==================================================================
CREATE TABLE team_members (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    business_id UUID NOT NULL REFERENCES business_profile(id) ON DELETE CASCADE,
    user_id UUID REFERENCES users(id) ON DELETE SET NULL,
    name VARCHAR(100) NOT NULL,
    phone VARCHAR(15),
    email VARCHAR(150),
    role_id UUID REFERENCES roles(id) ON DELETE SET NULL,
    is_active BOOLEAN DEFAULT TRUE,
    photo_url TEXT,
    last_login_at TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_team_members_business ON team_members(business_id);

-- ==================================================================
-- 5. PARTIES (CUSTOMERS & SUPPLIERS) TABLE
-- ==================================================================
CREATE TABLE parties (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    business_id UUID NOT NULL REFERENCES business_profile(id) ON DELETE CASCADE,
    name VARCHAR(150) NOT NULL,
    category VARCHAR(50),
    contact_number VARCHAR(15),
    email VARCHAR(150),
    address TEXT,
    city VARCHAR(50) DEFAULT '',
    opening_balance NUMERIC(12, 2) DEFAULT 0.00,
    balance_type VARCHAR(20) DEFAULT 'toReceive', -- toReceive / toPay
    credit_limit NUMERIC(12, 2),
    party_type VARCHAR(20) DEFAULT 'customer',    -- customer / supplier
    priority_level VARCHAR(20) DEFAULT 'medium',
    avatar_index INT DEFAULT 0,
    photo_url TEXT DEFAULT '',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_parties_tenant ON parties(business_id, party_type);

-- ==================================================================
-- 6. INVENTORY ITEMS TABLE
-- ==================================================================
CREATE TABLE items (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    business_id UUID NOT NULL REFERENCES business_profile(id) ON DELETE CASCADE,
    name VARCHAR(200) NOT NULL,
    sku VARCHAR(100),
    barcode VARCHAR(100),
    barcode_mode VARCHAR(20) DEFAULT 'same',
    unit VARCHAR(20) DEFAULT 'Pcs',
    category VARCHAR(100),
    hsn_sac VARCHAR(20),
    location VARCHAR(100),
    photo_url TEXT DEFAULT '',
    purchase_price NUMERIC(12, 2) DEFAULT 0.00,
    selling_price NUMERIC(12, 2) DEFAULT 0.00,
    sale_price_tax_mode VARCHAR(20) DEFAULT 'withoutTax', -- withTax / withoutTax
    purchase_price_tax_mode VARCHAR(20) DEFAULT 'withoutTax',
    discount_on_sale_price NUMERIC(8, 2) DEFAULT 0.00,
    discount_type VARCHAR(20) DEFAULT 'percentage',       -- percentage / amount
    tax_rate_label VARCHAR(50) DEFAULT 'None',
    tax_rate_percent NUMERIC(5, 2) DEFAULT 0.00,
    stock INT DEFAULT 0,
    min_stock_alert INT DEFAULT 5,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_items_tenant ON items(business_id, barcode);

-- ==================================================================
-- 7. SALES ORDERS / INVOICES TABLE
-- ==================================================================
CREATE TABLE sales_orders (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    business_id UUID NOT NULL REFERENCES business_profile(id) ON DELETE CASCADE,
    invoice_no INT NOT NULL,
    date DATE NOT NULL,
    payment_mode VARCHAR(30) DEFAULT 'Cash', -- Cash, UPI, NetBanking, Cheque
    is_one_time_customer BOOLEAN DEFAULT FALSE,
    party_id UUID REFERENCES parties(id) ON DELETE SET NULL,
    customer_name VARCHAR(150),
    customer_phone VARCHAR(15),
    items_json JSONB NOT NULL, -- Detailed JSON array of snapshot items
    total_amount NUMERIC(12, 2) NOT NULL DEFAULT 0.00,
    received_amount NUMERIC(12, 2) DEFAULT 0.00,
    payment_type VARCHAR(30) DEFAULT 'Cash',
    state_of_supply VARCHAR(50) DEFAULT '',
    description TEXT DEFAULT '',
    terms_and_conditions TEXT DEFAULT '',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_sales_tenant_date ON sales_orders(business_id, date DESC);

-- ==================================================================
-- 8. PURCHASE ORDERS TABLE
-- ==================================================================
CREATE TABLE purchase_orders (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    business_id UUID NOT NULL REFERENCES business_profile(id) ON DELETE CASCADE,
    order_no INT NOT NULL,
    date DATE NOT NULL,
    due_date DATE,
    party_name VARCHAR(150),
    party_id UUID REFERENCES parties(id) ON DELETE SET NULL,
    items_json JSONB NOT NULL,
    total_amount NUMERIC(12, 2) DEFAULT 0.00,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_purchase_tenant ON purchase_orders(business_id, date DESC);

-- ==================================================================
-- 9. PAYMENTS IN / OUT TABLE
-- ==================================================================
CREATE TABLE payments (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    business_id UUID NOT NULL REFERENCES business_profile(id) ON DELETE CASCADE,
    receipt_no INT NOT NULL,
    date DATE NOT NULL,
    party_id UUID REFERENCES parties(id) ON DELETE SET NULL,
    party_name VARCHAR(150),
    party_phone VARCHAR(15),
    received_amount NUMERIC(12, 2) NOT NULL,
    payment_type VARCHAR(30) DEFAULT 'Cash',
    is_payment_out BOOLEAN DEFAULT FALSE, -- FALSE = Payment In, TRUE = Payment Out
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_payments_tenant ON payments(business_id, party_id);
```

---

## 4. Authentication & 2Factor.in SMS Gateway Integration

### 4.1 OTP Dispatch Engine
When a user inputs their mobile number, the API backend dispatches an OTP request via **2Factor.in API**:

```typescript
// src/services/sms.service.ts
import axios from 'axios';
import Redis from 'ioredis';

const redis = new Redis(process.env.REDIS_URL!);
const TWO_FACTOR_API_KEY = process.env.TWO_FACTOR_API_KEY!;

export async function sendOtp(phoneNumber: string): Promise<string> {
    // 1. Rate Limiting Check (Max 3 OTP requests per 10 minutes)
    const rateKey = `rate:otp:${phoneNumber}`;
    const attempts = await redis.incr(rateKey);
    if (attempts === 1) await redis.expire(rateKey, 600);
    if (attempts > 3) throw new Error("OTP limit exceeded. Try again in 10 minutes.");

    // 2. Generate 6-digit OTP
    const otp = Math.floor(100000 + Math.random() * 900000).toString();
    
    // 3. Store in Redis (TTL: 5 Minutes)
    await redis.set(`otp:${phoneNumber}`, otp, 'EX', 300);

    // 4. Dispatch via 2Factor.in DLT SMS Endpoint
    const url = `https://2factor.in/API/V1/${TWO_FACTOR_API_KEY}/SMS/${phoneNumber}/${otp}/AUTOGEN`;
    await axios.get(url);

    return "OTP dispatched successfully";
}
```

### 4.2 JWT Token Generation
Upon successful verification, the server returns an **Asymmetric RSA-256 signed JWT**:
- **Access Token**: Expiration 15 Days (`sub`, `userId`, `businessId`, `role`)
- **Refresh Token**: Expiration 90 Days (stored securely in Mobile Secure Storage)

---

## 5. Offline-First Synchronization Engine (Delta Sync)

To keep mobile app SQLite data perfectly in sync with cloud PostgreSQL:

### Sync Strategy: **Delta Sync + Vector Timestamps**
1. **Push Sync (`POST /api/v1/sync/push`)**: Mobile app sends un-synced local records with local `uuid` and `updatedAt` timestamps.
2. **Conflict Resolution**:
   - **Financial Invoices & Payments**: Insert-Only Append Log (No overwrite conflicts allowed).
   - **Items & Master Data**: **Last-Write-Wins (LWW)** based on UTC timestamp comparison.
3. **Pull Sync (`GET /api/v1/sync/pull?lastSyncTimestamp=...`)**: Returns all records updated on the server since the last sync time.

```typescript
// src/controllers/sync.controller.ts
export async function handleSyncPush(req: FastifyRequest, reply: FastifyReply) {
    const { businessId } = req.user;
    const { items, parties, salesOrders, lastSyncTime } = req.body;

    const client = await pgPool.connect();
    try {
        await client.query('BEGIN');

        // 1. Upsert Items
        for (const item of items) {
            await client.query(`
                INSERT INTO items (id, business_id, name, selling_price, purchase_price, stock, updated_at)
                VALUES ($1, $2, $3, $4, $5, $6, $7)
                ON CONFLICT (id) DO UPDATE SET
                    name = EXCLUDED.name,
                    selling_price = EXCLUDED.selling_price,
                    stock = EXCLUDED.stock,
                    updated_at = EXCLUDED.updated_at
                WHERE items.updated_at < EXCLUDED.updated_at
            `, [item.id, businessId, item.name, item.sellingPrice, item.purchasePrice, item.stock, item.updatedAt]);
        }

        // 2. Commit Transaction
        await client.query('COMMIT');
        return reply.send({ success: true, serverTimestamp: new Date().toISOString() });
    } catch (err) {
        await client.query('ROLLBACK');
        return reply.status(500).send({ error: "Sync failed" });
    } finally {
        client.release();
    }
}
```

---

## 6. Complete REST API Specifications Matrix

| Endpoint | Method | Security | Description |
| :--- | :--- | :--- | :--- |
| `/api/v1/auth/send-otp` | `POST` | Public | Send 6-digit SMS OTP via 2Factor.in |
| `/api/v1/auth/verify-otp` | `POST` | Public | Verify OTP & return JWT Tokens |
| `/api/v1/business/profile` | `GET / PUT` | JWT Auth | Fetch & Update Business details (Logo, GST) |
| `/api/v1/items` | `GET / POST / PUT` | JWT + RBAC | Manage Inventory items & SKU details |
| `/api/v1/parties` | `GET / POST / PUT` | JWT + RBAC | Manage Customers & Suppliers ledgers |
| `/api/v1/sales/orders` | `GET / POST` | JWT + RBAC | Create & Fetch Sales Invoices / Orders |
| `/api/v1/purchase/orders` | `GET / POST` | JWT + RBAC | Create & Fetch Purchase Orders |
| `/api/v1/reports/daybook` | `GET` | JWT + Admin | Real-time Daybook summary |
| `/api/v1/reports/profit-loss`| `GET` | JWT + Admin | P&L Statement breakdown |
| `/api/v1/reports/gst` | `GET` | JWT + Admin | GSTR-1 & GSTR-3B tax export payload |
| `/api/v1/sync/push` | `POST` | JWT Auth | Push local SQLite batch updates to server |
| `/api/v1/sync/pull` | `GET` | JWT Auth | Fetch server delta changes since timestamp |

---

## 7. Security, Performance & Maintenance Standards

1. **Sub-100ms Response Time Target**:
   - Redis caching for static lookups (tax rates, business preferences).
   - Indexed foreign keys on `(business_id, date, created_at)`.
2. **Row-Level Security (RLS)**:
   - Tenant isolation enforced in every database query: `WHERE business_id = $tenantId`.
3. **Data Backup & Disaster Recovery**:
   - Automated hourly PostgreSQL `pg_dump` backups saved to MilesWeb backup storage.
   - Point-In-Time-Recovery (PITR) enabled.

---

## 8. Sprint Implementation Schedule

```
Phase 1: Setup & Foundations (Days 1–4)
  ├── Provision MilesWeb VPS (Nginx, Node.js 20 LTS, PostgreSQL 16, Redis 7)
  ├── Configure SSL TLS 1.3 & Nginx Reverse Proxy
  └── Execute PostgreSQL Database DDL Migrations

Phase 2: Auth & Core Services (Days 5–8)
  ├── Implement 2Factor.in SMS OTP integration
  ├── Build JWT Token Authority & Refresh handlers
  └── Create Business Profile & Multi-Tenant Middleware

Phase 3: Inventory, Parties & Billing Engine (Days 9–14)
  ├── Build Items, SKU, and Stock Mutation endpoints
  ├── Implement Sales & Purchase Order transaction APIs
  └── Develop Offline Delta Sync Engine (Push/Pull)

Phase 4: Analytics, PDF & Launch (Days 15–20)
  ├── Build Reports Engine (Daybook, P&L, GST)
  ├── Integrate Firebase FCM Notifications & Crashlytics
  └── Perform Load Testing (K6 / JMeter for 10,000 req/sec) & Final Launch
```
