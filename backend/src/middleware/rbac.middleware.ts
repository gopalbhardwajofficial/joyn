import { FastifyRequest, FastifyReply } from 'fastify';
import { getDbPool } from '../db/connection.js';

export type RequiredPermission =
  | 'access_sales'
  | 'access_purchase'
  | 'access_inventory'
  | 'access_reports'
  | 'access_admin'
  | 'access_party_details';

export interface BusinessAccessContext {
  businessId: string;
  isOwner: boolean;
  userRole: string;
  permissions: {
    accessSales: boolean;
    accessPurchase: boolean;
    accessInventory: boolean;
    accessReports: boolean;
    accessAdmin: boolean;
    accessPartyDetails: boolean;
  };
}

/**
 * Checks if the authenticated user has access to the business specified in x-business-id,
 * verifies they are active, and checks specific module permissions.
 */
export async function verifyBusinessAccess(
  req: FastifyRequest,
  reply: FastifyReply,
  requiredPermission?: RequiredPermission
): Promise<BusinessAccessContext | null> {
  const user = (req as any).user;
  if (!user || !user.userId) {
    reply.status(401).send({ success: false, message: 'Unauthorized. User session missing.' });
    return null;
  }

  const pool = getDbPool();
  let activeBusinessId = (req.headers['x-business-id'] as string) || (req.query as any)?.businessId;

  // If no businessId provided in header or query, resolve fallback to user's first owned or member business
  if (!activeBusinessId) {
    const cleanPhone = (user.phone || '').replace(/\D/g, '').slice(-10);
    const fallbackRes = await pool.query(
      `SELECT b.id FROM business_profile b WHERE b.owner_id = $1
       UNION
       SELECT tm.business_id as id FROM team_members tm WHERE (tm.user_id = $1 OR tm.phone = $2 OR tm.phone = $3 OR RIGHT(tm.phone, 10) = $2) AND tm.is_active = 1
       LIMIT 1`,
      [user.userId, cleanPhone, `+91${cleanPhone}`]
    );

    if (fallbackRes.rows.length > 0) {
      activeBusinessId = fallbackRes.rows[0].id;
    }
  }

  if (!activeBusinessId) {
    reply.status(400).send({ success: false, message: 'Active business ID required.' });
    return null;
  }

  // 1. Check if user is the business owner
  const ownerRes = await pool.query(
    'SELECT id, business_name FROM business_profile WHERE id = $1 AND owner_id = $2 LIMIT 1',
    [activeBusinessId, user.userId]
  );

  if (ownerRes.rows.length > 0) {
    const context: BusinessAccessContext = {
      businessId: activeBusinessId,
      isOwner: true,
      userRole: 'Owner',
      permissions: {
        accessSales: true,
        accessPurchase: true,
        accessInventory: true,
        accessReports: true,
        accessAdmin: true,
        accessPartyDetails: true,
      },
    };
    (req as any).businessAccess = context;
    return context;
  }

  // 2. Check if user is a registered team member
  const cleanPhone = (user.phone || '').replace(/\D/g, '').slice(-10);
  const memberRes = await pool.query(
    `SELECT tm.*, COALESCE(r.name, 'Staff') as role_name,
            COALESCE(r.access_sales, 1) as access_sales,
            COALESCE(r.access_purchase, 1) as access_purchase,
            COALESCE(r.access_inventory, 1) as access_inventory,
            COALESCE(r.access_reports, 0) as access_reports,
            COALESCE(r.access_admin, 0) as access_admin,
            COALESCE(r.access_party_details, 1) as access_party_details
     FROM team_members tm
     LEFT JOIN roles r ON tm.role_id = r.id
     WHERE tm.business_id = $1 AND (tm.user_id = $2 OR tm.phone = $3 OR tm.phone = $4 OR RIGHT(tm.phone, 10) = $3)
     LIMIT 1`,
    [activeBusinessId, user.userId, cleanPhone, `+91${cleanPhone}`]
  );

  if (memberRes.rows.length === 0) {
    reply.status(403).send({
      success: false,
      message: 'Access denied. You are not a member of this business.',
    });
    return null;
  }

  const member = memberRes.rows[0];

  // 3. Check if team member is active
  if (member.is_active !== 1 && member.is_active !== true) {
    reply.status(403).send({
      success: false,
      message: 'Your access to this business has been deactivated by the owner.',
    });
    return null;
  }

  // 4. Check specific module permission
  if (requiredPermission) {
    const hasPermission = member[requiredPermission] === 1 || member[requiredPermission] === true;
    if (!hasPermission) {
      const readableModule = requiredPermission.replace('access_', '').toUpperCase();
      reply.status(403).send({
        success: false,
        message: `Permission denied. Your role does not have access to ${readableModule}.`,
      });
      return null;
    }
  }

  const context: BusinessAccessContext = {
    businessId: activeBusinessId,
    isOwner: false,
    userRole: member.role_name || 'Staff',
    permissions: {
      accessSales: member.access_sales === 1 || member.access_sales === true,
      accessPurchase: member.access_purchase === 1 || member.access_purchase === true,
      accessInventory: member.access_inventory === 1 || member.access_inventory === true,
      accessReports: member.access_reports === 1 || member.access_reports === true,
      accessAdmin: member.access_admin === 1 || member.access_admin === true,
      accessPartyDetails: member.access_party_details === 1 || member.access_party_details === true,
    },
  };

  (req as any).businessAccess = context;
  return context;
}
