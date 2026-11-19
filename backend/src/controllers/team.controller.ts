import { FastifyRequest, FastifyReply } from 'fastify';
import { getDbPool } from '../db/connection.js';
import { send2FactorOtp } from '../services/sms.service.js';

export async function getTeamMembersHandler(req: FastifyRequest, reply: FastifyReply) {
  try {
    const user = (req as any).user;
    const pool = getDbPool();
    const { businessId } = req.query as { businessId?: string };
    let activeBusinessId = (req.headers['x-business-id'] as string) || businessId;

    if (!activeBusinessId && user?.userId) {
      const bizRes = await pool.query(
        'SELECT id FROM business_profile WHERE owner_id = $1 ORDER BY created_at ASC LIMIT 1',
        [user.userId]
      );
      if (bizRes.rows.length > 0) activeBusinessId = bizRes.rows[0].id;
    }

    if (!activeBusinessId) {
      return reply.send({ success: true, teamMembers: [] });
    }

    const query = `
      SELECT tm.*, COALESCE(r.name, 'Staff') as role_name,
             COALESCE(r.access_sales, 1) as access_sales,
             COALESCE(r.access_purchase, 1) as access_purchase,
             COALESCE(r.access_inventory, 1) as access_inventory,
             COALESCE(r.access_reports, 0) as access_reports,
             COALESCE(r.access_admin, 0) as access_admin,
             COALESCE(r.access_party_details, 1) as access_party_details
      FROM team_members tm
      LEFT JOIN roles r ON tm.role_id = r.id
      WHERE tm.business_id = $1
      ORDER BY tm.created_at DESC
    `;

    const res = await pool.query(query, [activeBusinessId]);

    return reply.send({
      success: true,
      teamMembers: res.rows.map((m: any) => ({
        id: m.id,
        name: m.name,
        phone: m.phone,
        email: m.email || '',
        roleId: m.role_id || '',
        roleName: m.role_name || 'Staff',
        isActive: m.is_active === 1 || m.is_active === true,
        photoPath: m.photo_url || '',
        lastLoginTime: m.last_login_at,
        createdAt: m.created_at,
        permissions: {
          accessSales: m.access_sales === 1 || m.access_sales === true,
          accessPurchase: m.access_purchase === 1 || m.access_purchase === true,
          accessInventory: m.access_inventory === 1 || m.access_inventory === true,
          accessReports: m.access_reports === 1 || m.access_reports === true,
          accessAdmin: m.access_admin === 1 || m.access_admin === true,
          accessPartyDetails: m.access_party_details === 1 || m.access_party_details === true
        }
      }))
    });
  } catch (error: any) {
    return reply.status(500).send({ success: false, message: error?.message || 'Failed to fetch team members.' });
  }
}

const isValidUUID = (str: any) => typeof str === 'string' && /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i.test(str);

export async function createTeamMemberHandler(req: FastifyRequest, reply: FastifyReply) {
  try {
    const pool = getDbPool();
    const user = (req as any).user;
    const body = req.body as any;
    let activeBusinessId = (req.headers['x-business-id'] as string) || body.businessId;

    if (!activeBusinessId && user?.userId) {
      const bizRes = await pool.query(
        'SELECT id FROM business_profile WHERE owner_id = $1 ORDER BY created_at ASC LIMIT 1',
        [user.userId]
      );
      if (bizRes.rows.length > 0) activeBusinessId = bizRes.rows[0].id;
    }

    if (!activeBusinessId) {
      return reply.status(400).send({ success: false, message: 'Active business ID required.' });
    }

    const { name, phone, email = '', roleId = null, roleName = '', photoPath = '' } = body;

    if (!name || !name.trim()) {
      return reply.status(400).send({ success: false, message: 'Member name is required.' });
    }
    if (!phone || !phone.trim()) {
      return reply.status(400).send({ success: false, message: 'Phone number is required.' });
    }

    const cleanPhone = phone.replace(/\D/g, '').slice(-10);

    // 1. Resolve Role ID safely to a valid PostgreSQL UUID
    let resolvedRoleId: string | null = null;
    let finalRoleName = roleName || 'Staff';

    if (roleId && isValidUUID(roleId)) {
      const rCheck = await pool.query('SELECT id, name FROM roles WHERE id = $1', [roleId]);
      if (rCheck.rows.length > 0) {
        resolvedRoleId = rCheck.rows[0].id;
        finalRoleName = rCheck.rows[0].name;
      }
    }

    if (!resolvedRoleId) {
      // Try resolving by role name or role slug (e.g. 'role_admin' -> 'Admin', 'role_cashier' -> 'Cashier')
      const targetName = (roleName || (typeof roleId === 'string' ? roleId.replace(/^role_/, '') : '')).toLowerCase();
      if (targetName) {
        const rMatch = await pool.query(
          `SELECT id, name FROM roles WHERE business_id = $1 AND LOWER(name) LIKE $2 ORDER BY created_at ASC LIMIT 1`,
          [activeBusinessId, `%${targetName}%`]
        );
        if (rMatch.rows.length > 0) {
          resolvedRoleId = rMatch.rows[0].id;
          finalRoleName = rMatch.rows[0].name;
        }
      }
    }

    if (!resolvedRoleId) {
      // Pick any existing role for this business
      const anyRole = await pool.query(
        `SELECT id, name FROM roles WHERE business_id = $1 ORDER BY created_at ASC LIMIT 1`,
        [activeBusinessId]
      );
      if (anyRole.rows.length > 0) {
        resolvedRoleId = anyRole.rows[0].id;
        finalRoleName = anyRole.rows[0].name;
      } else {
        // Auto-seed Admin role if none exists
        const newRole = await pool.query(
          `INSERT INTO roles (business_id, name, access_sales, access_purchase, access_inventory, access_reports, access_admin, access_party_details)
           VALUES ($1, 'Admin', 1, 1, 1, 1, 1, 1) RETURNING id, name`,
          [activeBusinessId]
        );
        resolvedRoleId = newRole.rows[0].id;
        finalRoleName = newRole.rows[0].name;
      }
    }

    // 2. Check if a registered user exists with this phone
    let linkedUserId = null;
    const userRes = await pool.query(
      'SELECT id FROM users WHERE phone_number = $1 OR RIGHT(phone_number, 10) = $1 LIMIT 1',
      [cleanPhone]
    );
    if (userRes.rows.length > 0) {
      linkedUserId = userRes.rows[0].id;
    }

    // 3. Check if member already exists in this business
    const existing = await pool.query(
      `SELECT id FROM team_members WHERE business_id = $1 AND (phone = $2 OR RIGHT(phone, 10) = $2)`,
      [activeBusinessId, cleanPhone]
    );

    let m;
    if (existing.rows.length > 0) {
      // Update existing record
      const updateRes = await pool.query(
        `UPDATE team_members
         SET name = $1, role_id = $2, user_id = COALESCE($3, user_id), is_active = 1, email = $4, photo_url = COALESCE($5, photo_url)
         WHERE id = $6
         RETURNING *`,
        [name.trim(), resolvedRoleId, linkedUserId, email.trim(), photoPath, existing.rows[0].id]
      );
      m = updateRes.rows[0];
    } else {
      // Insert new member
      const memberUuid = body.id && isValidUUID(body.id) ? body.id : undefined;
      const insertQuery = memberUuid
        ? `INSERT INTO team_members (id, business_id, user_id, name, phone, email, role_id, photo_url, is_active)
           VALUES ($1, $2, $3, $4, $5, $6, $7, $8, 1) RETURNING *`
        : `INSERT INTO team_members (business_id, user_id, name, phone, email, role_id, photo_url, is_active)
           VALUES ($1, $2, $3, $4, $5, $6, $7, 1) RETURNING *`;
      const insertParams = memberUuid
        ? [memberUuid, activeBusinessId, linkedUserId, name.trim(), cleanPhone, email.trim(), resolvedRoleId, photoPath]
        : [activeBusinessId, linkedUserId, name.trim(), cleanPhone, email.trim(), resolvedRoleId, photoPath];

      const insertRes = await pool.query(insertQuery, insertParams);
      m = insertRes.rows[0];
    }

    // Log admin activity (tagged as team_management so it does not pollute business performance metrics)
    await pool.query(
      `INSERT INTO activity_logs (business_id, user_id, member_id, member_name, activity_type, title, subtitle)
       VALUES ($1, $2, $3, $4, 'team_management', $5, $6)`,
      [activeBusinessId, user?.userId || null, m.id, m.name, 'Team Member Joined', `${m.name} assigned as ${finalRoleName}`]
    );

    // Fetch business name for invitation message
    let bizName = 'JOYN Business';
    try {
      const bRes = await pool.query('SELECT business_name FROM business_profile WHERE id = $1', [activeBusinessId]);
      if (bRes.rows.length > 0 && bRes.rows[0].business_name) {
        bizName = bRes.rows[0].business_name;
      }
    } catch (_) {}

    const inviteMessage = `${bizName} has invited you to join the app as a team member for the ${finalRoleName} role. Please accept and download the app here: https://api.joynonline.in/download`;

    // Trigger SMS to Indian mobile number
    try {
      if (cleanPhone && cleanPhone.length === 10) {
        send2FactorOtp(cleanPhone).catch((err) => {
          console.warn('Invite SMS dispatch warning:', err?.message || err);
        });
      }
    } catch (_) {}

    return reply.status(201).send({
      success: true,
      message: 'Team member added successfully.',
      inviteMessage,
      teamMember: {
        id: m.id,
        name: m.name,
        phone: m.phone,
        email: m.email,
        roleId: m.role_id,
        roleName: finalRoleName,
        isActive: m.is_active === 1 || m.is_active === true,
        photoPath: m.photo_url,
        createdAt: m.created_at
      }
    });
  } catch (error: any) {
    console.error('Create Team Member Error:', error);
    return reply.status(500).send({ success: false, message: error?.message || 'Failed to create team member.' });
  }
}

export async function updateTeamMemberHandler(req: FastifyRequest, reply: FastifyReply) {
  try {
    const { id } = req.params as { id: string };
    const pool = getDbPool();
    const body = req.body as any;
    const { name, phone, email, roleId, roleName, photoPath, isActive } = body;

    let findRes;
    if (isValidUUID(id)) {
      findRes = await pool.query('SELECT * FROM team_members WHERE id = $1', [id]);
    } else {
      const cleanPhone = (phone || id).replace(/\D/g, '').slice(-10);
      findRes = await pool.query('SELECT * FROM team_members WHERE phone = $1 OR RIGHT(phone, 10) = $1 LIMIT 1', [cleanPhone]);
    }

    if (findRes.rows.length === 0) {
      return reply.status(404).send({ success: false, message: 'Team member not found.' });
    }
    const currentMember = findRes.rows[0];
    const realId = currentMember.id;
    const cleanPhone = phone ? phone.replace(/\D/g, '').slice(-10) : currentMember.phone;

    let resolvedRoleId = currentMember.role_id;
    if (roleId && isValidUUID(roleId)) {
      resolvedRoleId = roleId;
    } else if (roleName || (typeof roleId === 'string' && !isValidUUID(roleId))) {
      const targetName = (roleName || roleId.replace(/^role_/, '')).toLowerCase();
      const rMatch = await pool.query(
        `SELECT id FROM roles WHERE business_id = $1 AND LOWER(name) LIKE $2 ORDER BY created_at ASC LIMIT 1`,
        [currentMember.business_id, `%${targetName}%`]
      );
      if (rMatch.rows.length > 0) resolvedRoleId = rMatch.rows[0].id;
    }

    const updateRes = await pool.query(
      `UPDATE team_members
       SET name = COALESCE($1, name),
           phone = COALESCE($2, phone),
           email = COALESCE($3, email),
           role_id = COALESCE($4, role_id),
           photo_url = COALESCE($5, photo_url),
           is_active = COALESCE($6, is_active)
       WHERE id = $7
       RETURNING *`,
      [
        name ? name.trim() : null,
        cleanPhone,
        email !== undefined ? email.trim() : null,
        resolvedRoleId,
        photoPath !== undefined ? photoPath : null,
        isActive !== undefined ? (isActive ? 1 : 0) : null,
        realId
      ]
    );

    const m = updateRes.rows[0];
    let finalRoleName = 'Staff';
    if (m.role_id) {
      const roleRes = await pool.query('SELECT name FROM roles WHERE id = $1 LIMIT 1', [m.role_id]);
      if (roleRes.rows.length > 0) finalRoleName = roleRes.rows[0].name;
    }

    return reply.send({
      success: true,
      message: 'Team member updated successfully.',
      teamMember: {
        id: m.id,
        name: m.name,
        phone: m.phone,
        email: m.email,
        roleId: m.role_id,
        roleName: finalRoleName,
        isActive: m.is_active === 1 || m.is_active === true,
        photoPath: m.photo_url,
        createdAt: m.created_at
      }
    });
  } catch (error: any) {
    return reply.status(500).send({ success: false, message: error?.message || 'Failed to update team member.' });
  }
}

export async function toggleMemberStatusHandler(req: FastifyRequest, reply: FastifyReply) {
  try {
    const { id } = req.params as { id: string };
    const body = (req.body as any) || {};
    const user = (req as any).user;
    const pool = getDbPool();

    let currentRes;
    if (isValidUUID(id)) {
      currentRes = await pool.query(`SELECT id, is_active, business_id, name FROM team_members WHERE id = $1`, [id]);
    } else {
      const cleanPhone = id.replace(/\D/g, '').slice(-10);
      currentRes = await pool.query(`SELECT id, is_active, business_id, name FROM team_members WHERE phone = $1 OR RIGHT(phone, 10) = $1 LIMIT 1`, [cleanPhone]);
    }

    if (currentRes.rows.length === 0) {
      return reply.status(404).send({ success: false, message: 'Team member not found.' });
    }
    const realId = currentRes.rows[0].id;
    const currentActive = currentRes.rows[0].is_active === 1 || currentRes.rows[0].is_active === true;
    let targetActive: boolean;
    if (body.isActive !== undefined) {
      targetActive = body.isActive === true || body.isActive === 1 || body.isActive === '1' || body.isActive === 'true';
    } else if (body.is_active !== undefined) {
      targetActive = body.is_active === true || body.is_active === 1 || body.is_active === '1' || body.is_active === 'true';
    } else {
      targetActive = !currentActive;
    }

    const updateRes = await pool.query(
      `UPDATE team_members SET is_active = $1 WHERE id = $2 RETURNING *`,
      [targetActive ? 1 : 0, realId]
    );

    const m = updateRes.rows[0];

    // Log status toggle
    await pool.query(
      `INSERT INTO activity_logs (business_id, user_id, member_id, member_name, activity_type, title, subtitle)
       VALUES ($1, $2, $3, $4, 'custAddedModified', $5, $6)`,
      [
        m.business_id,
        user?.userId || null,
        m.id,
        m.name,
        targetActive ? 'Member Activated' : 'Member Deactivated',
        `Access status changed to ${targetActive ? 'Active' : 'Disabled'}`
      ]
    );

    return reply.send({
      success: true,
      message: `Team member ${targetActive ? 'activated' : 'deactivated'} successfully.`,
      isActive: targetActive,
      teamMember: {
        id: m.id,
        name: m.name,
        phone: m.phone,
        email: m.email,
        roleId: m.role_id,
        isActive: targetActive,
        photoPath: m.photo_url,
        createdAt: m.created_at
      }
    });
  } catch (error: any) {
    return reply.status(500).send({ success: false, message: error?.message || 'Failed to toggle status.' });
  }
}

export async function deleteTeamMemberHandler(req: FastifyRequest, reply: FastifyReply) {
  try {
    const { id } = req.params as { id: string };
    const user = (req as any).user;
    const pool = getDbPool();

    let delRes;
    if (isValidUUID(id)) {
      delRes = await pool.query('DELETE FROM team_members WHERE id = $1 RETURNING id, name, business_id', [id]);
    } else {
      const cleanPhone = id.replace(/\D/g, '').slice(-10);
      delRes = await pool.query('DELETE FROM team_members WHERE phone = $1 OR RIGHT(phone, 10) = $1 RETURNING id, name, business_id', [cleanPhone]);
    }

    if (delRes.rows.length === 0) {
      return reply.status(404).send({ success: false, message: 'Team member not found.' });
    }

    const m = delRes.rows[0];
    await pool.query(
      `INSERT INTO activity_logs (business_id, user_id, member_name, activity_type, title, subtitle)
       VALUES ($1, $2, $3, 'custAddedModified', 'Team Member Removed', $4)`,
      [m.business_id, user?.userId || null, m.name, `${m.name} was removed from the business.`]
    );

    return reply.send({ success: true, message: 'Team member deleted successfully.' });
  } catch (error: any) {
    return reply.status(500).send({ success: false, message: error?.message || 'Failed to delete team member.' });
  }
}

export async function getActivityLogsHandler(req: FastifyRequest, reply: FastifyReply) {
  try {
    const { memberId } = req.params as { memberId?: string };
    const { period = '1month', startDate, endDate } = req.query as {
      period?: string;
      startDate?: string;
      endDate?: string;
    };
    const user = (req as any).user;
    const pool = getDbPool();
    let activeBusinessId = (req.headers['x-business-id'] as string) || (req.query as any)?.businessId;

    if (!activeBusinessId && user?.userId) {
      const bizRes = await pool.query(
        'SELECT id FROM business_profile WHERE owner_id = $1 ORDER BY created_at ASC LIMIT 1',
        [user.userId]
      );
      if (bizRes.rows.length > 0) activeBusinessId = bizRes.rows[0].id;
    }

    let memberUserId: string | null = null;
    let memberPhone: string | null = null;
    let memberName: string | null = null;

    if (memberId && memberId !== 'all') {
      let tmRes;
      if (isValidUUID(memberId)) {
        tmRes = await pool.query('SELECT id, business_id, user_id, phone, name FROM team_members WHERE id = $1', [memberId]);
      } else {
        const cleanPhone = memberId.replace(/\D/g, '').slice(-10);
        tmRes = await pool.query('SELECT id, business_id, user_id, phone, name FROM team_members WHERE id = $1 OR phone = $1 OR RIGHT(phone, 10) = $2 LIMIT 1', [memberId, cleanPhone]);
      }

      if (tmRes.rows.length === 0) {
        // Specified member not found or has 0 activity -> strictly return 0 logs, never fallback to whole business!
        return reply.send({ success: true, logs: [] });
      }

      const tm = tmRes.rows[0];
      if (!activeBusinessId) activeBusinessId = tm.business_id;
      memberUserId = tm.user_id;
      memberPhone = tm.phone ? tm.phone.replace(/\D/g, '').slice(-10) : null;
      memberName = tm.name;

      // Auto-link user_id if null
      if (!memberUserId && memberPhone) {
        const uRes = await pool.query(
          'SELECT id FROM users WHERE phone_number = $1 OR RIGHT(phone_number, 10) = $1 LIMIT 1',
          [memberPhone]
        );
        if (uRes.rows.length > 0) {
          memberUserId = uRes.rows[0].id;
          await pool.query('UPDATE team_members SET user_id = $1 WHERE id = $2', [memberUserId, tm.id]);
        }
      }
    }

    let query = `SELECT * FROM activity_logs WHERE 1=1`;
    const params: any[] = [];

    if (activeBusinessId) {
      params.push(activeBusinessId);
      query += ` AND business_id = $${params.length}`;
    }

    if (memberId && memberId !== 'all') {
      const filterConditions: string[] = [];
      if (isValidUUID(memberId)) {
        params.push(memberId);
        filterConditions.push(`member_id = $${params.length}`);
      }
      if (memberUserId) {
        params.push(memberUserId);
        filterConditions.push(`user_id = $${params.length}`);
      }
      if (memberPhone) {
        params.push(`%${memberPhone}`);
        filterConditions.push(`user_name LIKE $${params.length}`);
      }
      if (memberName) {
        params.push(memberName);
        filterConditions.push(`member_name = $${params.length}`);
      }

      if (filterConditions.length > 0) {
        query += ` AND (${filterConditions.join(' OR ')})`;
      } else {
        query += ` AND 1=0`; // Guard: never return all business logs when filtering by member
      }

      // Performance records of a member should only include real business actions (sales, purchases, items, etc.),
      // NOT administrative setup events (e.g. "Team Member Joined", "Team Member Updated", "Member Activated").
      query += ` AND (title IS NULL OR title NOT IN ('Team Member Joined', 'Team Member Updated', 'Team Member Deleted', 'Member Activated', 'Member Deactivated', 'Role Created', 'Role Updated'))`;
      query += ` AND (activity_type IS NULL OR activity_type NOT IN ('team_management', 'profile_update', 'admin', 'auth'))`;
      query += ` AND (details IS NULL OR details NOT ILIKE '%assigned as%')`;
      query += ` AND (subtitle IS NULL OR subtitle NOT ILIKE '%assigned as%')`;
    }

    // Date period filtering
    const now = new Date();
    if (startDate && endDate) {
      params.push(startDate, endDate);
      query += ` AND created_at >= $${params.length - 1} AND created_at <= $${params.length}`;
    } else if (period === '1day') {
      const d1 = new Date(now.getTime() - 24 * 60 * 60 * 1000);
      params.push(d1.toISOString());
      query += ` AND created_at >= $${params.length}`;
    } else if (period === '1week') {
      const d7 = new Date(now.getTime() - 7 * 24 * 60 * 60 * 1000);
      params.push(d7.toISOString());
      query += ` AND created_at >= $${params.length}`;
    } else if (period === '1month') {
      const d30 = new Date(now.getTime() - 30 * 24 * 60 * 60 * 1000);
      params.push(d30.toISOString());
      query += ` AND created_at >= $${params.length}`;
    } else if (period === '3months') {
      const d90 = new Date(now.getTime() - 90 * 24 * 60 * 60 * 1000);
      params.push(d90.toISOString());
      query += ` AND created_at >= $${params.length}`;
    } else if (period === '6months') {
      const d180 = new Date(now.getTime() - 180 * 24 * 60 * 60 * 1000);
      params.push(d180.toISOString());
      query += ` AND created_at >= $${params.length}`;
    }

    query += ` ORDER BY created_at DESC LIMIT 200`;

    const res = await pool.query(query, params);

    const logs = res.rows.map((row: any) => {
      let actType = row.activity_type;
      const mod = (row.module || '').toLowerCase();
      const det = (row.details || '').toLowerCase();
      const tit = (row.title || '').toLowerCase();

      if (!actType) {
        if (mod.includes('purchase') || det.includes('purchase order') || tit.includes('purchase')) {
          actType = 'itemPurchased';
        } else if (mod.includes('sale') || det.includes('invoice') || tit.includes('sold') || tit.includes('sale')) {
          actType = 'itemSold';
        } else if (mod.includes('item') || det.includes('item') || det.includes('stock')) {
          actType = 'itemAddedModified';
        } else {
          actType = 'custAddedModified';
        }
      }

      // Title determination
      let title = row.title;
      if (!title) {
        if (actType === 'itemSold') title = 'Item Sold';
        else if (actType === 'itemPurchased') title = 'Item Purchased';
        else if (actType === 'itemAddedModified') title = 'Item Added / Modified';
        else title = row.action ? `Customer / ${row.action}` : 'Activity';
      }

      // Amount parsing
      let amount: number | null = null;
      if (row.amount !== null && row.amount !== undefined && !isNaN(parseFloat(row.amount))) {
        amount = parseFloat(row.amount);
      } else if (row.details) {
        const amtMatch = row.details.match(/₹\s*([0-9]+(?:\.[0-9]+)?)/);
        if (amtMatch) {
          amount = parseFloat(amtMatch[1]);
        }
      }

      // Clean Subtitle
      let subtitle = row.subtitle || row.details || '';
      if (!subtitle && amount) {
        subtitle = `Amount: ₹${amount.toFixed(2)}`;
      }

      return {
        id: row.id,
        type: actType,
        title,
        subtitle,
        amount,
        timestamp: row.created_at
      };
    });

    return reply.send({
      success: true,
      logs
    });
  } catch (error: any) {
    return reply.status(500).send({ success: false, message: error?.message || 'Failed to fetch activity logs.' });
  }
}
