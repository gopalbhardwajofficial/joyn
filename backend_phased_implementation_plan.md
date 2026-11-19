# 🚀 JOYN Backend — Online-First Architecture & Phased Implementation Plan

---

## 📌 Architectural Correction & Connection Strategy

### **Online-First (Cloud Primary) with Intelligent Offline Queue & Cache**
1. **Primary Mode**: **Online-First**. The app requires internet connectivity for real-time cloud operations, live stock validation, multi-user concurrency, and immediate server-side invoice generation.
2. **Local Cache (Read Layer)**: All fetched server data (Items, Parties, Invoices, Settings) is saved in local SQLite (`joyn_database.db`) and `SharedPreferences`. If internet is slow or temporarily offline, reading and viewing data operates instantly from cache.
3. **Pending Write Queue (Write Fallback)**: If a user creates or edits a record (Customer, Item, Sale Invoice, Payment) while offline or on poor network:
   - Record is saved to SQLite `pending_write_queue` with a temporary local ID.
   - UI updates instantly in optimistic mode.
   - As soon as connectivity restores, `SyncQueueManager` flushes the queue to the backend server via `POST /api/v1/sync/batch-process`, replacing local IDs with permanent server UUIDs.

---

## 🗺️ Phase-by-Phase Modular Implementation Matrix

```
+-------------------------------------------------------------------------------------------------------------------+
|                                     JOYN BACKEND MODULAR PHASE BREAKDOWN                                           |
+-------------------------------------------------------------------------------------------------------------------+
| PHASE 1: Authentication, Server Setup & Tenant Management                                                         |
| ├── App Features: Login Screen, 2Factor OTP Dialog, Splash, Onboarding, Company Creation/Selection                |
| └── Backend APIs: POST /auth/send-otp, POST /auth/verify-otp, POST /business/create, GET /business/list            |
+-------------------------------------------------------------------------------------------------------------------+
                                         |
                                         v
+-------------------------------------------------------------------------------------------------------------------+
| PHASE 2: Master Catalog (Inventory Items & Parties CRM)                                                            |
| ├── App Features: Items List, Add/Edit Item, Categories/Locations, Parties List, Add Party, Party Detail           |
| └── Backend APIs: GET/POST/PUT/DELETE /items, GET/POST/PUT/DELETE /parties                                        |
+-------------------------------------------------------------------------------------------------------------------+
                                         |
                                         v
+-------------------------------------------------------------------------------------------------------------------+
| PHASE 3: Transactions Engine (Sales Invoices, Purchase Orders & Payments)                                         |
| ├── App Features: Add Sale Order, Sale Orders List, Add Purchase Order, Payment In/Out                            |
| └── Backend APIs: POST /sales, POST /purchases, POST /payments, Sequential Invoice Generator, Atomic Stock Deduct  |
+-------------------------------------------------------------------------------------------------------------------+
                                         |
                                         v
+-------------------------------------------------------------------------------------------------------------------+
| PHASE 4: Barcodes, Server-Side PDF Rendering & WhatsApp Integration                                                |
| ├── App Features: Barcode Label Screen, Barcode Scanner, Invoice Preview, Share Invoice                            |
| └── Backend APIs: GET /barcode/search, POST /invoice/render-pdf (BullMQ Worker), WhatsApp Link Generator          |
+-------------------------------------------------------------------------------------------------------------------+
                                         |
                                         v
+-------------------------------------------------------------------------------------------------------------------+
| PHASE 5: Team Management, Roles & RBAC Security Middleware                                                         |
| ├── App Features: Roles List, Create Role, Add Staff Member, Staff List, Staff Detail, Activity Audit Log          |
| └── Backend APIs: GET/POST /roles, GET/POST /team-members, RBAC Security Guard Middleware, GET /activity-logs    |
+-------------------------------------------------------------------------------------------------------------------+
                                         |
                                         v
+-------------------------------------------------------------------------------------------------------------------+
| PHASE 6: Real-Time Reports, Financial Statements & Firebase FCM Alerts                                             |
| ├── App Features: Daybook, Profit & Loss, Balance Sheet, Cashflow, GST Reports (GSTR-1, GSTR-3B)                   |
| └── Backend APIs: GET /reports/daybook, GET /reports/profit-loss, GET /reports/gst, Firebase FCM Notifications     |
+-------------------------------------------------------------------------------------------------------------------+
                                         |
                                         v
+-------------------------------------------------------------------------------------------------------------------+
| PHASE 7: Offline Queue Sync Engine & System Hardening                                                              |
| ├── App Features: Background Sync Queue Manager (Flutter `ConnectivityWatcher`)                                    |
| └── Backend APIs: POST /sync/batch-process (Idempotent Transaction Queue Processor)                                |
+-------------------------------------------------------------------------------------------------------------------+
```

---

## 🗄️ Database Schema & Table Mapping

```sql
-- 1. USERS TABLE
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

-- 2. BUSINESS PROFILE TABLE (TENANTS)
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

-- 3. ROLES TABLE
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

-- 5. PARTIES TABLE
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

-- 6. ITEMS TABLE
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

-- 7. SALES ORDERS TABLE
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

-- 9. PAYMENTS TABLE
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

-- 10. ACTIVITY LOGS TABLE
CREATE TABLE activity_logs (
    id VARCHAR(36) PRIMARY KEY,
    business_id VARCHAR(36) NOT NULL,
    user_id VARCHAR(36) NOT NULL,
    user_name VARCHAR(100) NOT NULL,
    module VARCHAR(50) NOT NULL,   -- Sales, Inventory, Parties, Settings
    action VARCHAR(50) NOT NULL,   -- CREATE, UPDATE, DELETE, LOGIN
    details TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (business_id) REFERENCES business_profile(id) ON DELETE CASCADE
);
```

---

## ⚙️ Detailed Phase Technical Execution

### **PHASE 1: Authentication, Server Setup & Tenant Management**
- **Goal**: User signs in via 2Factor.in SMS OTP, gets JWT Tokens, creates/selects Business.
- **APIs to Build**:
  - `POST /api/v1/auth/send-otp` (2Factor.in SMS Integration + Redis 5-min TTL)
  - `POST /api/v1/auth/verify-otp` (Validates OTP, creates/fetches User, issues RSA-256 JWT)
  - `POST /api/v1/business` (Creates business profile & default Admin role)
  - `GET /api/v1/business/my-businesses` (Lists all businesses owned by or assigned to user)

---

### **PHASE 2: Master Catalog (Items & Parties)**
- **Goal**: Real-time CRUD for Items (with Stock Alert) & Parties (Customers/Vendors).
- **APIs to Build**:
  - `GET /api/v1/items` & `POST /api/v1/items` & `PUT /api/v1/items/:id`
  - `GET /api/v1/parties` & `POST /api/v1/parties` & `PUT /api/v1/parties/:id`
  - `GET /api/v1/categories` & `GET /api/v1/locations`

---

### **PHASE 3: Transactions Engine (Sales, Purchases & Payments)**
- **Goal**: Generate Invoices, Purchase Orders, and Payment Receipts with atomic invoice numbers and atomic stock updates.
- **APIs to Build**:
  - `POST /api/v1/sales/orders` (Auto-increments `invoice_no`, decrements `items.stock`)
  - `POST /api/v1/purchase/orders` (Auto-increments `order_no`, increments `items.stock`)
  - `POST /api/v1/payments` (Auto-increments `receipt_no`, updates party balance)

---

### **PHASE 4: Barcodes, Server-Side PDF Rendering & WhatsApp**
- **Goal**: Render high-res PDF invoices server-side using **BullMQ (`pdf-invoice-queue`)** and generate WhatsApp share links.
- **APIs to Build**:
  - `GET /api/v1/barcode/search?code=...`
  - `POST /api/v1/invoices/:id/pdf` (Asynchronously renders PDF invoice)
  - `GET /api/v1/invoices/:id/whatsapp-link`

---

### **PHASE 5: Team Management & RBAC Security Middleware**
- **Goal**: Owner creates Roles & adds Staff Members with specific permissions.
- **APIs to Build**:
  - `GET /api/v1/roles` & `POST /api/v1/roles`
  - `GET /api/v1/team-members` & `POST /api/v1/team-members`
  - Middleware: `authorizeRole(['accessSales', 'accessAdmin'])`

---

### **PHASE 6: Reports & Analytics Engine + Firebase FCM**
- **Goal**: High-speed analytics queries (Daybook, P&L, Balance Sheet, GST) and real-time push alerts.
- **APIs to Build**:
  - `GET /api/v1/reports/daybook?date=...`
  - `GET /api/v1/reports/profit-loss?startDate=...&endDate=...`
  - `GET /api/v1/reports/gst?month=...`
  - Firebase FCM Alert Dispatcher for Low Stock & Payment In.

---

### **PHASE 7: Offline Queue Batch Processor**
- **Goal**: Process offline queued writes seamlessly when network restores.
- **APIs to Build**:
  - `POST /api/v1/sync/batch-process`
  - Idempotent payload handling to avoid duplicate invoice creations.
