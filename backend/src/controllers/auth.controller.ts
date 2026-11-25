import { FastifyRequest, FastifyReply } from 'fastify';
import { send2FactorOtp, verify2FactorOtp } from '../services/sms.service.js';
import { deleteCache } from '../redis/client.js';
import { getDbPool } from '../db/connection.js';

export async function sendOtpHandler(req: FastifyRequest, reply: FastifyReply) {
  try {
    const { phoneNumber } = req.body as { phoneNumber?: string };
    if (!phoneNumber) {
      return reply.status(400).send({ success: false, message: 'Phone number is required.' });
    }

    const result = await send2FactorOtp(phoneNumber);
    return reply.send(result);
  } catch (error: any) {
    return reply.status(400).send({ success: false, message: error?.message || 'Failed to send OTP.' });
  }
}

export async function verifyOtpHandler(req: FastifyRequest, reply: FastifyReply) {
  try {
    const { phoneNumber, otp } = req.body as { phoneNumber?: string; otp?: string };
    if (!phoneNumber || !otp) {
      return reply.status(400).send({ success: false, message: 'Phone number and OTP are required.' });
    }

    const isValid = await verify2FactorOtp(phoneNumber, otp);
    if (!isValid) {
      return reply.status(401).send({ success: false, message: 'Invalid or expired OTP.' });
    }

    const cleanPhone = phoneNumber.replace(/\D/g, '').slice(-10);
    const pool = getDbPool();

    // 1. Fetch or Insert User in PostgreSQL
    let userResult = await pool.query('SELECT * FROM users WHERE phone_number = $1', [cleanPhone]);
    let user;

    if (userResult.rows.length === 0) {
      const newUserRes = await pool.query(
        `INSERT INTO users (phone_number, full_name) VALUES ($1, $2) RETURNING *`,
        [cleanPhone, 'User ' + cleanPhone.slice(-4)]
      );
      user = newUserRes.rows[0];
    } else {
      user = userResult.rows[0];
    }

    // 2. Delete used OTP
    await deleteCache(`otp:${cleanPhone}`);

    // 3. Auto-link team_members with this user_id if invited previously
    await pool.query(
      `UPDATE team_members
       SET user_id = $1, is_active = 1
       WHERE (phone = $2 OR phone = $3 OR RIGHT(phone, 10) = $2) AND user_id IS NULL`,
      [user.id, cleanPhone, `+91${cleanPhone}`]
    );

    // 4. Issue Asymmetric RSA / JWT Token
    const tokenPayload = { userId: user.id, phone: user.phone_number };
    const accessToken = (req.server as any).jwt.sign(tokenPayload, { expiresIn: '15d' });

    // 5. Fetch Owned Businesses
    const ownedRes = await pool.query(
      `SELECT b.*, 'Owner' as user_role, true as is_owner
       FROM business_profile b 
       WHERE b.owner_id = $1 
       ORDER BY b.created_at DESC`,
      [user.id]
    );

    // 6. Fetch Active Member Businesses
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
      [user.id, cleanPhone, `+91${cleanPhone}`]
    );

    const ownedIds = new Set(ownedRes.rows.map((r: any) => r.id));
    const allRows = [
      ...ownedRes.rows,
      ...memberRes.rows.filter((r: any) => !ownedIds.has(r.id))
    ];

    return reply.send({
      success: true,
      message: 'Authentication successful',
      accessToken,
      user: {
        id: user.id,
        phoneNumber: user.phone_number,
        fullName: user.full_name,
        email: user.email,
        createdAt: user.created_at
      },
      hasCreatedBusiness: allRows.length > 0,
      businesses: allRows.map((b: any) => ({
        id: b.id,
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
        }
      }))
    });
  } catch (error: any) {
    console.error('Verify OTP Error:', error);
    return reply.status(500).send({ success: false, message: error?.message || 'Verification failed.' });
  }
}

export async function googleAuthHandler(req: FastifyRequest, reply: FastifyReply) {
  try {
    const { email, displayName, photoUrl, idToken } = req.body as {
      email?: string;
      displayName?: string;
      photoUrl?: string;
      idToken?: string;
    };

    if (!email) {
      return reply.status(400).send({ success: false, message: 'Google account email is required.' });
    }

    const pool = getDbPool();
    const cleanEmail = email.trim().toLowerCase();

    // 1. Fetch or Insert User in PostgreSQL
    let userResult = await pool.query('SELECT * FROM users WHERE email = $1', [cleanEmail]);
    let user;

    if (userResult.rows.length === 0) {
      try {
        await pool.query("UPDATE users SET phone_number = NULL WHERE phone_number = ''");
      } catch (_) {}

      const newUserRes = await pool.query(
        `INSERT INTO users (email, full_name, phone_number) VALUES ($1, $2, $3) RETURNING *`,
        [cleanEmail, displayName || 'Google User', null]
      );
      user = newUserRes.rows[0];
    } else {
      user = userResult.rows[0];
    }

    // 2. Issue JWT Token
    const tokenPayload = { userId: user.id, email: user.email, phone: user.phone_number || '' };
    const accessToken = (req.server as any).jwt.sign(tokenPayload, { expiresIn: '15d' });

    // Auto-link team_members with this user_id if invited previously
    await pool.query(
      `UPDATE team_members
       SET user_id = $1
       WHERE LOWER(email) = $2 AND user_id IS NULL`,
      [user.id, cleanEmail]
    );

    // 3. Fetch Owned Businesses
    const ownedRes = await pool.query(
      `SELECT b.*, 'Owner' as user_role, true as is_owner
       FROM business_profile b 
       WHERE b.owner_id = $1 
       ORDER BY b.created_at DESC`,
      [user.id]
    );

    // 4. Fetch Active Member Businesses
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
       WHERE (tm.user_id = $1 OR tm.email = $2) AND tm.is_active = 1
       ORDER BY tm.created_at DESC`,
      [user.id, cleanEmail]
    );

    const ownedIds = new Set(ownedRes.rows.map((r: any) => r.id));
    const allRows = [
      ...ownedRes.rows,
      ...memberRes.rows.filter((r: any) => !ownedIds.has(r.id))
    ];

    return reply.send({
      success: true,
      message: 'Google authentication successful',
      accessToken,
      user: {
        id: user.id,
        phoneNumber: user.phone_number || '',
        fullName: user.full_name,
        email: user.email,
        createdAt: user.created_at
      },
      hasCreatedBusiness: allRows.length > 0,
      businesses: allRows.map((b: any) => ({
        id: b.id,
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
        permissions: b.is_owner
          ? {
              accessSales: true,
              accessPurchase: true,
              accessInventory: true,
              accessReports: true,
              accessAdmin: true,
              accessPartyDetails: true
            }
          : {
              accessSales: b.access_sales === 1,
              accessPurchase: b.access_purchase === 1,
              accessInventory: b.access_inventory === 1,
              accessReports: b.access_reports === 1,
              accessAdmin: b.access_admin === 1,
              accessPartyDetails: b.access_party_details === 1
            }
      }))
    });
  } catch (error: any) {
    console.error('Google Auth Error:', error);
    return reply.status(500).send({ success: false, message: error?.message || 'Google authentication failed.' });
  }
}
