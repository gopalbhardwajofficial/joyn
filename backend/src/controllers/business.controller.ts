import { FastifyRequest, FastifyReply } from 'fastify';
import { getDbPool } from '../db/connection.js';

export async function createBusinessHandler(req: FastifyRequest, reply: FastifyReply) {
  try {
    const user = (req as any).user;
    const body = (req.body as any) || {};
    const params = (req.params as any) || {};
    const {
      id,
      businessId,
      businessName,
      ownerName,
      gstNumber,
      businessType,
      businessCategory,
      phone1,
      email,
      address,
      state,
      status
    } = body;

    const targetId = params.id || id || businessId;
    const pool = getDbPool();

    // Auto-migrate status column if needed
    try {
      await pool.query("ALTER TABLE business_profile ADD COLUMN IF NOT EXISTS status VARCHAR(20) DEFAULT 'active'");
    } catch (_) {}

    // 1. If targetId exists, UPDATE the existing business instead of inserting a duplicate!
    if (targetId) {
      const existing = await pool.query(
        "SELECT id FROM business_profile WHERE id = $1 AND owner_id = $2",
        [targetId, user.userId]
      );
      if (existing.rows.length > 0) {
        const updateRes = await pool.query(
          `UPDATE business_profile SET
            business_name = COALESCE($1, business_name),
            owner_name = COALESCE($2, owner_name),
            gst_number = COALESCE($3, gst_number),
            business_type = COALESCE($4, business_type),
            business_category = COALESCE($5, business_category),
            phone1 = COALESCE($6, phone1),
            email = COALESCE($7, email),
            address = COALESCE($8, address),
            state = COALESCE($9, state),
            status = COALESCE($10, status),
            updated_at = CURRENT_TIMESTAMP
           WHERE id = $11
           RETURNING *`,
          [
            businessName !== undefined ? businessName : null,
            ownerName !== undefined ? ownerName : null,
            gstNumber !== undefined ? gstNumber : null,
            businessType !== undefined ? businessType : null,
            businessCategory !== undefined ? businessCategory : null,
            phone1 !== undefined ? phone1 : null,
            email !== undefined ? email : null,
            address !== undefined ? address : null,
            state !== undefined ? state : null,
            status !== undefined ? status : null,
            targetId
          ]
        );
        const b = updateRes.rows[0];
        return reply.send({
          success: true,
          message: 'Business Profile updated successfully',
          business: {
            id: b.id,
            ownerId: b.owner_id,
            businessName: b.business_name,
            ownerName: b.owner_name,
            gstNumber: b.gst_number,
            businessType: b.business_type,
            businessCategory: b.business_category,
            phone1: b.phone1,
            email: b.email,
            address: b.address,
            state: b.state,
            status: b.status || 'active',
            createdAt: b.created_at,
            updatedAt: b.updated_at
          }
        });
      }
    }

    if (!businessName) {
      return reply.status(400).send({ success: false, message: 'Business Name is required.' });
    }

    // Insert new business into PostgreSQL
    const res = await pool.query(
      `INSERT INTO business_profile (
        owner_id, business_name, owner_name, gst_number, business_type, 
        business_category, phone1, email, address, state, status
      ) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11)
      RETURNING *`,
      [
        user.userId,
        businessName,
        ownerName || '',
        gstNumber || '',
        businessType || 'Retailer',
        businessCategory || 'General Store',
        phone1 || user.phone,
        email || '',
        address || '',
        state || 'Delhi',
        status || 'active'
      ]
    );

    const b = res.rows[0];

    // Create default Admin role for this business
    await pool.query(
      `INSERT INTO roles (business_id, name, access_sales, access_purchase, access_inventory, access_reports, access_admin, access_party_details)
       VALUES ($1, $2, 1, 1, 1, 1, 1, 1)`,
      [b.id, 'Admin']
    );

    return reply.status(201).send({
      success: true,
      message: 'Business Profile created successfully',
      business: {
        id: b.id,
        ownerId: b.owner_id,
        businessName: b.business_name,
        ownerName: b.owner_name,
        gstNumber: b.gst_number,
        businessType: b.business_type,
        businessCategory: b.business_category,
        phone1: b.phone1,
        email: b.email,
        address: b.address,
        state: b.state,
        createdAt: b.created_at
      }
    });
  } catch (error: any) {
    console.error('Create Business Error:', error);
    return reply.status(500).send({ success: false, message: error?.message || 'Failed to create business.' });
  }
}

export async function getMyBusinessesHandler(req: FastifyRequest, reply: FastifyReply) {
  try {
    const user = (req as any).user;
    const pool = getDbPool();

    // 1. Owned businesses
    const ownedRes = await pool.query(
      `SELECT b.*, 'Owner' as user_role, true as is_owner
       FROM business_profile b 
       WHERE b.owner_id = $1 
       ORDER BY b.created_at DESC`,
      [user.userId]
    );

    // 2. Member businesses (where user is added as active staff)
    const cleanPhone = (user.phone || '').replace(/\D/g, '').slice(-10);
    if (cleanPhone) {
      await pool.query(
        `UPDATE team_members SET user_id = $1 WHERE (phone = $2 OR phone = $3 OR RIGHT(phone, 10) = $2) AND user_id IS NULL`,
        [user.userId, cleanPhone, `+91${cleanPhone}`]
      );
    }

    const memberRes = await pool.query(
      `SELECT b.*, tm.name as member_name, COALESCE(r.name, 'Staff') as user_role, false as is_owner,
              COALESCE(r.access_sales, 1) as access_sales,
              COALESCE(r.access_purchase, 1) as access_purchase,
              COALESCE(r.access_inventory, 1) as access_inventory,
              COALESCE(r.access_reports, 0) as access_reports,
              COALESCE(r.access_admin, 0) as access_admin,
              COALESCE(r.access_party_details, 1) as access_party_details
       FROM team_members tm
       JOIN business_profile b ON tm.business_id = b.id
       LEFT JOIN roles r ON tm.role_id = r.id
       WHERE (tm.user_id = $1 OR tm.phone = $2 OR tm.phone = $3 OR RIGHT(tm.phone, 10) = $2) AND tm.is_active = 1
       ORDER BY tm.created_at DESC`,
      [user.userId, cleanPhone, `+91${cleanPhone}`]
    );

    const ownedIds = new Set(ownedRes.rows.map((r: any) => r.id));
    const allRows = [
      ...ownedRes.rows,
      ...memberRes.rows.filter((r: any) => !ownedIds.has(r.id))
    ];

    return reply.send({
      success: true,
      businesses: allRows.map((b: any) => ({
        id: b.id,
        ownerId: b.owner_id,
        businessName: b.business_name,
        ownerName: b.owner_name,
        gstNumber: b.gst_number,
        businessType: b.business_type,
        businessCategory: b.business_category,
        phone1: b.phone1,
        email: b.email,
        address: b.address,
        state: b.state,
        userRole: b.user_role || (b.is_owner ? 'Owner' : 'Staff'),
        isOwner: b.is_owner === true,
        permissions: b.is_owner ? {
          accessSales: true,
          accessPurchase: true,
          accessInventory: true,
          accessReports: true,
          accessAdmin: true,
          accessPartyDetails: true
        } : {
          accessSales: b.access_sales === 1 || b.access_sales === true,
          accessPurchase: b.access_purchase === 1 || b.access_purchase === true,
          accessInventory: b.access_inventory === 1 || b.access_inventory === true,
          accessReports: b.access_reports === 1 || b.access_reports === true,
          accessAdmin: b.access_admin === 1 || b.access_admin === true,
          accessPartyDetails: b.access_party_details === 1 || b.access_party_details === true
        },
        createdAt: b.created_at,
        logoUrl: b.logo_url,
        signatureUrl: b.signature_url,
        bankName: b.bank_name,
        accountNumber: b.account_number,
        ifscCode: b.ifsc_code,
        branchName: b.branch_name,
        upiId: b.upi_id,
        invoiceTheme: b.invoice_theme || 'classic_blue',
        invoiceColorHex: b.invoice_color_hex || '#4338CA',
        invoiceTerms: b.invoice_terms,
        showUpiQr: b.show_upi_qr ?? true
      }))
    });
  } catch (error: any) {
    return reply.status(500).send({ success: false, message: error?.message || 'Failed to fetch businesses.' });
  }
}

// ============================================================================
// PHASE 8: BUSINESS BRANDING, BANKING & INVOICE CUSTOMIZATION CONTROLLERS
// ============================================================================

// 1. Get Detailed Business Profile & Branding
export async function getBusinessProfileHandler(req: FastifyRequest, reply: FastifyReply) {
  try {
    const user = (req as any).user;
    const accessContext = (req as any).businessAccess;
    const businessId = accessContext?.businessId || (req.headers['x-business-id'] as string) || (req.query as any)?.businessId;
    const pool = getDbPool();

    let res;
    if (businessId) {
      const cleanPhone = (user.phone || '').replace(/\D/g, '').slice(-10);
      res = await pool.query(
        `SELECT b.* FROM business_profile b
         WHERE b.id = $1 AND (
           b.owner_id = $2 OR
           EXISTS (SELECT 1 FROM team_members tm WHERE tm.business_id = b.id AND (tm.user_id = $2 OR tm.phone = $3 OR tm.phone = $4 OR RIGHT(tm.phone, 10) = $3) AND tm.is_active = 1)
         )
         LIMIT 1`,
        [businessId, user.userId, cleanPhone, `+91${cleanPhone}`]
      );
    } else {
      res = await pool.query('SELECT * FROM business_profile WHERE owner_id = $1 ORDER BY created_at DESC LIMIT 1', [user.userId]);
    }

    if (res.rows.length === 0) {
      return reply.status(404).send({ success: false, message: 'Business profile not found or access denied.' });
    }

    const b = res.rows[0];
    return reply.send({
      success: true,
      business: {
        id: b.id,
        ownerId: b.owner_id,
        businessName: b.business_name,
        ownerName: b.owner_name,
        gstNumber: b.gst_number,
        businessType: b.business_type,
        businessCategory: b.business_category,
        phone1: b.phone1,
        phone2: b.phone2,
        email: b.email,
        website: b.website,
        address: b.address,
        city: b.city,
        state: b.state,
        pincode: b.pincode,
        country: b.country,
        description: b.description,
        booksStartDate: b.books_start_date,
        // Branding & Banking
        logoUrl: b.logo_url || null,
        signatureUrl: b.signature_url || null,
        bankName: b.bank_name || '',
        accountNumber: b.account_number || '',
        ifscCode: b.ifsc_code || '',
        branchName: b.branch_name || '',
        upiId: b.upi_id || '',
        invoiceTheme: b.invoice_theme || 'classic_blue',
        invoiceColorHex: b.invoice_color_hex || '#4338CA',
        invoiceTerms: b.invoice_terms || '1. Goods once sold will not be taken back or exchanged.\n2. Payment due within 15 days of invoice date.\n3. Subject to local jurisdiction.',
        showUpiQr: b.show_upi_qr ?? true,
        createdAt: b.created_at,
        updatedAt: b.updated_at
      }
    });
  } catch (error: any) {
    console.error('Get Business Profile Error:', error);
    return reply.status(500).send({ success: false, message: error?.message || 'Failed to fetch business profile.' });
  }
}

// 2. Update Business Branding, Bank Details & Invoice Settings
export async function updateBusinessBrandingHandler(req: FastifyRequest, reply: FastifyReply) {
  try {
    const user = (req as any).user;
    const accessContext = (req as any).businessAccess;
    const businessId = accessContext?.businessId || (req.headers['x-business-id'] as string) || (req.body as any)?.businessId;
    const pool = getDbPool();

    // Verify business exists and user is owner OR has access_admin
    let checkRes;
    if (businessId) {
      const cleanPhone = (user.phone || '').replace(/\D/g, '').slice(-10);
      checkRes = await pool.query(
        `SELECT b.* FROM business_profile b
         WHERE b.id = $1 AND (
           b.owner_id = $2 OR
           EXISTS (
             SELECT 1 FROM team_members tm
             JOIN roles r ON tm.role_id = r.id
             WHERE tm.business_id = b.id AND (tm.user_id = $2 OR tm.phone = $3 OR tm.phone = $4 OR RIGHT(tm.phone, 10) = $3)
               AND tm.is_active = 1 AND (r.access_admin = 1 OR r.access_admin = true)
           )
         )
         LIMIT 1`,
        [businessId, user.userId, cleanPhone, `+91${cleanPhone}`]
      );
    } else {
      checkRes = await pool.query('SELECT * FROM business_profile WHERE owner_id = $1 ORDER BY created_at DESC LIMIT 1', [user.userId]);
    }

    if (checkRes.rows.length === 0) {
      return reply.status(403).send({ success: false, message: 'Business not found or admin access required.' });
    }

    const currentBiz = checkRes.rows[0];
    const bId = currentBiz.id;
    const body = (req.body as any) || {};

    const updated = await pool.query(
      `UPDATE business_profile SET
        business_name = COALESCE($1, business_name),
        owner_name = COALESCE($2, owner_name),
        gst_number = COALESCE($3, gst_number),
        phone1 = COALESCE($4, phone1),
        email = COALESCE($5, email),
        address = COALESCE($6, address),
        state = COALESCE($7, state),
        city = COALESCE($8, city),
        pincode = COALESCE($9, pincode),
        bank_name = COALESCE($10, bank_name),
        account_number = COALESCE($11, account_number),
        ifsc_code = COALESCE($12, ifsc_code),
        branch_name = COALESCE($13, branch_name),
        upi_id = COALESCE($14, upi_id),
        invoice_theme = COALESCE($15, invoice_theme),
        invoice_color_hex = COALESCE($16, invoice_color_hex),
        invoice_terms = COALESCE($17, invoice_terms),
        show_upi_qr = COALESCE($18, show_upi_qr),
        logo_url = COALESCE($19, logo_url),
        signature_url = COALESCE($20, signature_url)
      WHERE id = $21
      RETURNING *`,
      [
        body.businessName ?? null,
        body.ownerName ?? null,
        body.gstNumber ?? null,
        body.phone1 ?? null,
        body.email ?? null,
        body.address ?? null,
        body.state ?? null,
        body.city ?? null,
        body.pincode ?? null,
        body.bankName ?? null,
        body.accountNumber ?? null,
        body.ifscCode ?? null,
        body.branchName ?? null,
        body.upiId ?? null,
        body.invoiceTheme ?? null,
        body.invoiceColorHex ?? null,
        body.invoiceTerms ?? null,
        body.showUpiQr !== undefined ? body.showUpiQr : null,
        body.logoUrl ?? null,
        body.signatureUrl ?? null,
        bId
      ]
    );

    const b = updated.rows[0];
    return reply.send({
      success: true,
      message: 'Business branding and invoice settings updated successfully',
      business: {
        id: b.id,
        businessName: b.business_name,
        bankName: b.bank_name,
        accountNumber: b.account_number,
        ifscCode: b.ifsc_code,
        branchName: b.branch_name,
        upiId: b.upi_id,
        invoiceTheme: b.invoice_theme,
        invoiceColorHex: b.invoice_color_hex,
        invoiceTerms: b.invoice_terms,
        showUpiQr: b.show_upi_qr,
        logoUrl: b.logo_url,
        signatureUrl: b.signature_url
      }
    });
  } catch (error: any) {
    console.error('Update Branding Error:', error);
    return reply.status(500).send({ success: false, message: error?.message || 'Failed to update business branding.' });
  }
}

// 3. Upload Logo (Accepts Base64 / Data URI / Direct URL)
export async function uploadBusinessLogoHandler(req: FastifyRequest, reply: FastifyReply) {
  try {
    const user = (req as any).user;
    const accessContext = (req as any).businessAccess;
    const businessId = accessContext?.businessId || (req.headers['x-business-id'] as string) || (req.body as any)?.businessId;
    const { logo, logoUrl, imageBase64 } = (req.body as any) || {};

    const logoData = logo || logoUrl || imageBase64;
    if (!logoData) {
      return reply.status(400).send({ success: false, message: 'Logo data (base64 or URL) is required.' });
    }

    const pool = getDbPool();
    let bizRes;
    if (businessId) {
      const cleanPhone = (user.phone || '').replace(/\D/g, '').slice(-10);
      bizRes = await pool.query(
        `SELECT b.id FROM business_profile b
         WHERE b.id = $1 AND (
           b.owner_id = $2 OR
           EXISTS (
             SELECT 1 FROM team_members tm
             JOIN roles r ON tm.role_id = r.id
             WHERE tm.business_id = b.id AND (tm.user_id = $2 OR tm.phone = $3 OR tm.phone = $4 OR RIGHT(tm.phone, 10) = $3)
               AND tm.is_active = 1 AND (r.access_admin = 1 OR r.access_admin = true)
           )
         )
         LIMIT 1`,
        [businessId, user.userId, cleanPhone, `+91${cleanPhone}`]
      );
    } else {
      bizRes = await pool.query('SELECT id FROM business_profile WHERE owner_id = $1 ORDER BY created_at DESC LIMIT 1', [user.userId]);
    }

    if (bizRes.rows.length === 0) {
      return reply.status(403).send({ success: false, message: 'Business not found or admin access required.' });
    }

    const bId = bizRes.rows[0].id;
    await pool.query('UPDATE business_profile SET logo_url = $1 WHERE id = $2', [logoData, bId]);

    return reply.send({
      success: true,
      message: 'Logo uploaded and linked successfully.',
      logoUrl: logoData
    });
  } catch (error: any) {
    console.error('Upload Logo Error:', error);
    return reply.status(500).send({ success: false, message: error?.message || 'Failed to upload logo.' });
  }
}

// 4. Upload Digital Signature (Accepts Base64 / Data URI / Direct URL)
export async function uploadBusinessSignatureHandler(req: FastifyRequest, reply: FastifyReply) {
  try {
    const user = (req as any).user;
    const accessContext = (req as any).businessAccess;
    const businessId = accessContext?.businessId || (req.headers['x-business-id'] as string) || (req.body as any)?.businessId;
    const { signature, signatureUrl, imageBase64 } = (req.body as any) || {};

    const signatureData = signature || signatureUrl || imageBase64;
    if (!signatureData) {
      return reply.status(400).send({ success: false, message: 'Signature data (base64 or URL) is required.' });
    }

    const pool = getDbPool();
    let bizRes;
    if (businessId) {
      const cleanPhone = (user.phone || '').replace(/\D/g, '').slice(-10);
      bizRes = await pool.query(
        `SELECT b.id FROM business_profile b
         WHERE b.id = $1 AND (
           b.owner_id = $2 OR
           EXISTS (
             SELECT 1 FROM team_members tm
             JOIN roles r ON tm.role_id = r.id
             WHERE tm.business_id = b.id AND (tm.user_id = $2 OR tm.phone = $3 OR tm.phone = $4 OR RIGHT(tm.phone, 10) = $3)
               AND tm.is_active = 1 AND (r.access_admin = 1 OR r.access_admin = true)
           )
         )
         LIMIT 1`,
        [businessId, user.userId, cleanPhone, `+91${cleanPhone}`]
      );
    } else {
      bizRes = await pool.query('SELECT id FROM business_profile WHERE owner_id = $1 ORDER BY created_at DESC LIMIT 1', [user.userId]);
    }

    if (bizRes.rows.length === 0) {
      return reply.status(403).send({ success: false, message: 'Business not found or admin access required.' });
    }

    const bId = bizRes.rows[0].id;
    await pool.query('UPDATE business_profile SET signature_url = $1 WHERE id = $2', [signatureData, bId]);

    return reply.send({
      success: true,
      message: 'Digital signature uploaded and linked successfully.',
      signatureUrl: signatureData
    });
  } catch (error: any) {
    console.error('Upload Signature Error:', error);
    return reply.status(500).send({ success: false, message: error?.message || 'Failed to upload signature.' });
  }
}

// 5. Get Available Invoice Themes & Color Presets
export async function getInvoiceThemesHandler(req: FastifyRequest, reply: FastifyReply) {
  return reply.send({
    success: true,
    themes: [
      {
        id: 'classic_blue',
        name: 'Classic Corporate GST',
        description: 'Standard professional business layout with clear tax breakdown, itemized grid, and UPI QR code.',
        defaultColor: '#4338CA',
        recommendedFor: 'Wholesale, Manufacturing, B2B'
      },
      {
        id: 'modern_minimal',
        name: 'Modern Clean Minimal',
        description: 'Ultra-clean layout with sleek typography, subtle horizontal lines, and compact header.',
        defaultColor: '#0F172A',
        recommendedFor: 'Services, Freelancers, Tech, Boutiques'
      },
      {
        id: 'emerald_elegance',
        name: 'Emerald Elegance',
        description: 'Sophisticated dark emerald theme with bordered containers, badge styling, and payment callouts.',
        defaultColor: '#059669',
        recommendedFor: 'Retail, Pharmacy, Grocery, General Store'
      },
      {
        id: 'thermal_pos',
        name: 'Thermal POS (80mm / 3-inch)',
        description: 'Compact receipt roll format optimized for thermal counter printers and fast POS checkout.',
        defaultColor: '#000000',
        recommendedFor: 'Fast Food, Supermarket, Counter Retail'
      }
    ],
    colorPresets: [
      { name: 'Indigo Corporate', hex: '#4338CA' },
      { name: 'Sky Tech', hex: '#0284C7' },
      { name: 'Emerald Nature', hex: '#059669' },
      { name: 'Crimson Bold', hex: '#E11D48' },
      { name: 'Amber Warmth', hex: '#D97706' },
      { name: 'Slate Executive', hex: '#1E293B' },
      { name: 'Classic Black', hex: '#000000' }
    ]
  });
}


export async function deleteBusinessHandler(req: FastifyRequest, reply: FastifyReply) {
  try {
    const user = (req as any).user;
    const { id } = req.params as { id: string };
    const pool = getDbPool();

    const check = await pool.query("SELECT id FROM business_profile WHERE id = $1 AND owner_id = $2", [id, user.userId]);
    if (check.rows.length === 0) {
      return reply.status(403).send({ success: false, message: 'Business not found or access denied.' });
    }

    await pool.query("DELETE FROM business_profile WHERE id = $1", [id]);
    return reply.send({ success: true, message: 'Business deleted successfully.' });
  } catch (error: any) {
    console.error("Delete Business Error:", error);
    return reply.status(500).send({ success: false, message: error?.message || 'Failed to delete business.' });
  }
}
