# 🛠️ JOYN Backend — Complete Step-by-Step Implementation & Execution Plan

---

## 📌 Executive Summary

This document provides the **exact roadmap, required access/credentials, server stack details, and phase-by-phase execution plan** to build and deploy the **JOYN Backend API Server & Database** on **MilesWeb Cloud Hosting**.

---

## 🔑 1. What Credentials & Access We Need From You

To set up, configure, and connect the live server and services, please provide the following details:

### A. MilesWeb Hosting Details
- [ ] **MilesWeb Access Type**: Is it **Cloud VPS / Linux Server (SSH)** or **cPanel Web Hosting**?
- [ ] **Server IP Address** (e.g., `123.45.67.89`)
- [ ] **SSH Username & Password / SSH Private Key** (or cPanel login credentials)
- [ ] **Domain Name** (e.g., `joynapp.in` or `api.joynapp.in`) & DNS Provider access (Cloudflare / GoDaddy / MilesWeb DNS) to point the API subdomain.

### B. Third-Party Service Keys
- [ ] **2Factor.in API Key**: For sending SMS OTPs to Indian mobile numbers.
- [ ] **Firebase Project Access / Service Account JSON**: For Firebase Cloud Messaging (FCM) push notifications and Crashlytics telemetry.

---

## 🏗️ 2. Recommended Technology Stack for MilesWeb Server

To achieve **sub-100ms response time**, **zero errors**, and **flawless scalability**:

| Layer | Recommended Choice | Rationale |
| :--- | :--- | :--- |
| **Backend Framework** | **Node.js (TypeScript + Fastify)** | 3x faster than standard Express, built-in schema validation, 100% type-safe matching Flutter models. |
| **Primary Database** | **PostgreSQL 16** | Strict ACID compliance for financial ledgers, GST calculations, multi-tenancy, and JSONB invoice storage. |
| **In-Memory Cache** | **Redis 7** | Sub-millisecond OTP verification, session token caching, rate-limiting, and async queue management (BullMQ). |
| **Reverse Proxy** | **Nginx** | Handles SSL (HTTPS), gzip/brotli compression, rate limiting (DDoS protection), and static file serving. |
| **Process Manager** | **PM2 Cluster Mode** | Zero-downtime reloads, auto-restart on crash, full CPU core utilization. |

---

## 📅 3. Phase-by-Phase Execution Plan

```
+-----------------------------------------------------------------------------------+
| PHASE 1: Local Backend Project Architecture & Development Setup                    |
| - Initialize Node.js TypeScript + Fastify repo                                   |
| - Setup Prisma / Drizzle ORM & PostgreSQL Schema Migrations                        |
| - Setup Redis Caching & Queue Client                                              |
+-----------------------------------------------------------------------------------+
                                         |
                                         v
+-----------------------------------------------------------------------------------+
| PHASE 2: Auth System & 2Factor.in SMS Integration                                 |
| - Build POST /auth/send-otp (2Factor.in DLT SMS)                                  |
| - Build POST /auth/verify-otp (Redis validation & Asymmetric RSA-256 JWT)         |
| - Build Refresh Token & Logout Handlers                                           |
+-----------------------------------------------------------------------------------+
                                         |
                                         v
+-----------------------------------------------------------------------------------+
| PHASE 3: Core Enterprise APIs (CRUD & Financial Accounting Logic)                 |
| - Business Profile & Custom Cards API (Logo, Signature upload)                    |
| - Items & Inventory Stock Mutation API (Atomic stock deduct)                      |
| - Parties / Ledger CRM API (Opening Balance, Running Ledger Statements)           |
| - Sales Invoices & Purchase Orders API (Auto-increment invoice numbers)           |
| - Team Management & RBAC Permissions Middleware                                   |
+-----------------------------------------------------------------------------------+
                                         |
                                         v
+-----------------------------------------------------------------------------------+
| PHASE 4: Offline Delta Sync Engine                                                |
| - Build POST /sync/push (Batch process SQLite offline transactions)               |
| - Build GET /sync/pull (Fetch server deltas using vector timestamps)              |
| - Implement Conflict Resolution (Last-Write-Wins vs Financial Append Logs)        |
+-----------------------------------------------------------------------------------+
                                         |
                                         v
+-----------------------------------------------------------------------------------+
| PHASE 5: MilesWeb Cloud Server Setup & Production Deployment                      |
| - Install & configure Nginx, SSL TLS 1.3 (Let's Encrypt), PostgreSQL 16, Redis 7 |
| - Deploy Node.js Fastify code via PM2 cluster mode                                |
| - Configure UFW Firewall & Security Guards                                        |
+-----------------------------------------------------------------------------------+
                                         |
                                         v
+-----------------------------------------------------------------------------------+
| PHASE 6: Flutter App Integration & Final E2E Testing                              |
| - Connect Flutter HTTP client to https://api.joynapp.in                           |
| - Conduct load testing (K6 benchmark: 10,000 req/sec)                             |
| - Verify offline-to-cloud sync & FCM Push Notifications                           |
+-----------------------------------------------------------------------------------+
```

---

## 🚀 4. Immediate Next Steps

1. **Step 1**: Confirm if your MilesWeb hosting is a **VPS / Cloud Server** or **cPanel**.
2. **Step 2**: Share the MilesWeb SSH / Server IP details & 2Factor.in API key.
3. **Step 3**: We will initialize the backend project repository, build the database migration scripts, and set up the local API development server!
