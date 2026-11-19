-- PostgreSQL 16 DDL Migration Schema for JOYN Multi-Tenant System
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- 1. USERS TABLE
CREATE TABLE IF NOT EXISTS users (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    phone_number VARCHAR(15) UNIQUE NOT NULL,
    full_name VARCHAR(100),
    email VARCHAR(150),
    fcm_device_token TEXT,
    is_verified BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_users_phone ON users(phone_number);

-- 2. BUSINESS PROFILE (TENANTS) TABLE
CREATE TABLE IF NOT EXISTS business_profile (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    owner_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
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
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_business_owner ON business_profile(owner_id);

-- 3. ROLES TABLE
CREATE TABLE IF NOT EXISTS roles (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    business_id UUID NOT NULL REFERENCES business_profile(id) ON DELETE CASCADE,
    name VARCHAR(50) NOT NULL,
    access_sales INT DEFAULT 0,
    access_purchase INT DEFAULT 0,
    access_inventory INT DEFAULT 0,
    access_reports INT DEFAULT 0,
    access_admin INT DEFAULT 0,
    access_party_details INT DEFAULT 0,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_roles_business ON roles(business_id);

-- 4. TEAM MEMBERS TABLE
CREATE TABLE IF NOT EXISTS team_members (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    business_id UUID NOT NULL REFERENCES business_profile(id) ON DELETE CASCADE,
    user_id UUID REFERENCES users(id) ON DELETE SET NULL,
    name VARCHAR(100) NOT NULL,
    phone VARCHAR(15),
    email VARCHAR(150),
    role_id UUID REFERENCES roles(id) ON DELETE SET NULL,
    is_active INT DEFAULT 1,
    photo_url TEXT,
    last_login_at TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_team_members_business ON team_members(business_id);

-- 5. CATEGORIES TABLE
CREATE TABLE IF NOT EXISTS categories (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    business_id UUID NOT NULL REFERENCES business_profile(id) ON DELETE CASCADE,
    name VARCHAR(100) NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_categories_business ON categories(business_id);

-- 6. LOCATIONS TABLE
CREATE TABLE IF NOT EXISTS locations (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    business_id UUID NOT NULL REFERENCES business_profile(id) ON DELETE CASCADE,
    name VARCHAR(100) NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_locations_business ON locations(business_id);

-- 7. PARTIES (CUSTOMERS & SUPPLIERS) TABLE
CREATE TABLE IF NOT EXISTS parties (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    business_id UUID NOT NULL REFERENCES business_profile(id) ON DELETE CASCADE,
    name VARCHAR(150) NOT NULL,
    category VARCHAR(50),
    contact_number VARCHAR(15),
    email VARCHAR(150),
    address TEXT,
    city VARCHAR(50) DEFAULT '',
    opening_balance NUMERIC(12, 2) DEFAULT 0.00,
    balance_type VARCHAR(20) DEFAULT 'toReceive',
    credit_limit NUMERIC(12, 2),
    party_type VARCHAR(20) DEFAULT 'customer',
    priority_level VARCHAR(20) DEFAULT 'medium',
    avatar_index INT DEFAULT 0,
    photo_url TEXT,
    party_number INT,
    party_code VARCHAR(50),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_parties_tenant ON parties(business_id, party_type);

-- 8. INVENTORY ITEMS TABLE
CREATE TABLE IF NOT EXISTS items (
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
    photo_url TEXT,
    purchase_price NUMERIC(12, 2) DEFAULT 0.00,
    selling_price NUMERIC(12, 2) DEFAULT 0.00,
    sale_price_tax_mode VARCHAR(20) DEFAULT 'withoutTax',
    purchase_price_tax_mode VARCHAR(20) DEFAULT 'withoutTax',
    discount_on_sale_price NUMERIC(8, 2) DEFAULT 0.00,
    discount_type VARCHAR(20) DEFAULT 'percentage',
    tax_rate_label VARCHAR(50) DEFAULT 'None',
    tax_rate_percent NUMERIC(5, 2) DEFAULT 0.00,
    stock INT DEFAULT 0,
    min_stock_alert INT DEFAULT 5,
    item_number INT,
    item_code VARCHAR(50),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_items_tenant ON items(business_id, barcode);

-- 9. SALES ORDERS TABLE
CREATE TABLE IF NOT EXISTS sales_orders (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    business_id UUID NOT NULL REFERENCES business_profile(id) ON DELETE CASCADE,
    invoice_no INT NOT NULL,
    date DATE NOT NULL,
    payment_mode VARCHAR(30) DEFAULT 'Cash',
    is_one_time_customer INT DEFAULT 0,
    party_id UUID REFERENCES parties(id) ON DELETE SET NULL,
    customer_name VARCHAR(150),
    customer_phone VARCHAR(15),
    items_json JSONB NOT NULL,
    total_amount NUMERIC(12, 2) NOT NULL DEFAULT 0.00,
    received_amount NUMERIC(12, 2) DEFAULT 0.00,
    payment_type VARCHAR(30) DEFAULT 'Cash',
    state_of_supply VARCHAR(50) DEFAULT '',
    description TEXT,
    terms_and_conditions TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_sales_tenant ON sales_orders(business_id, date DESC);

-- 10. PURCHASE ORDERS TABLE
CREATE TABLE IF NOT EXISTS purchase_orders (
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

CREATE INDEX IF NOT EXISTS idx_purchase_tenant ON purchase_orders(business_id, date DESC);

-- 11. PAYMENTS TABLE
CREATE TABLE IF NOT EXISTS payments (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    business_id UUID NOT NULL REFERENCES business_profile(id) ON DELETE CASCADE,
    receipt_no INT NOT NULL,
    date DATE NOT NULL,
    party_id UUID REFERENCES parties(id) ON DELETE SET NULL,
    party_name VARCHAR(150),
    party_phone VARCHAR(15),
    received_amount NUMERIC(12, 2) NOT NULL,
    payment_type VARCHAR(30) DEFAULT 'Cash',
    is_payment_out INT DEFAULT 0,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_payments_tenant ON payments(business_id, party_id);

-- 12. ACTIVITY LOGS TABLE
CREATE TABLE IF NOT EXISTS activity_logs (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    business_id UUID NOT NULL REFERENCES business_profile(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    user_name VARCHAR(100) NOT NULL,
    module VARCHAR(50) NOT NULL,
    action VARCHAR(50) NOT NULL,
    details TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_logs_tenant ON activity_logs(business_id, created_at DESC);

-- 13. EXPENSES TABLE (PHASE 6)
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

