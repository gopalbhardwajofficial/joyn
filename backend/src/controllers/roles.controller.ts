import { FastifyRequest, FastifyReply } from 'fastify';
import { getDbPool } from '../db/connection.js';

const DEFAULT_ROLES = [
  {
    name: 'Admin / Manager',
    access_sales: 1,
    access_purchase: 1,
    access_inventory: 1,
    access_reports: 1,
    access_admin: 1,
    access_party_details: 1
  },
  {
    name: 'Salesperson / Biller',
    access_sales: 1,
    access_purchase: 0,
    access_inventory: 0,
    access_reports: 0,
    access_admin: 0,
    access_party_details: 1
  },
  {
    name: 'Accountant',
    access_sales: 1,
    access_purchase: 1,
    access_inventory: 0,
    access_reports: 1,
    access_admin: 0,
    access_party_details: 1
  },
  {
    name: 'Stock Keeper',
    access_sales: 0,
    access_purchase: 1,
    access_inventory: 1,
    access_reports: 0,
    access_admin: 0,
    access_party_details: 0
  }
];

export async function getRolesHandler(req: FastifyRequest, reply: FastifyReply) {
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
      return reply.send({ success: true, roles: [] });
    }

    // 1. Check existing roles
    let res = await pool.query(
      `SELECT * FROM roles WHERE business_id = $1 ORDER BY created_at ASC`,
      [activeBusinessId]
    );

    // 2. Ensure all standard default roles exist
    const existingNames = new Set(res.rows.map((r: any) => r.name.toLowerCase()));
    let newlyAdded = false;
    for (const def of DEFAULT_ROLES) {
      if (!existingNames.has(def.name.toLowerCase())) {
        await pool.query(
          `INSERT INTO roles (business_id, name, access_sales, access_purchase, access_inventory, access_reports, access_admin, access_party_details)
           VALUES ($1, $2, $3, $4, $5, $6, $7, $8)`,
          [
            activeBusinessId,
            def.name,
            def.access_sales,
            def.access_purchase,
            def.access_inventory,
            def.access_reports,
            def.access_admin,
            def.access_party_details
          ]
        );
        newlyAdded = true;
      }
    }

    if (newlyAdded) {
      res = await pool.query(
        `SELECT * FROM roles WHERE business_id = $1 ORDER BY created_at ASC`,
        [activeBusinessId]
      );
    }

    return reply.send({
      success: true,
      roles: res.rows.map((r: any) => ({
        id: r.id,
        name: r.name,
        accessSales: r.access_sales === 1 || r.access_sales === true,
        accessPurchase: r.access_purchase === 1 || r.access_purchase === true,
        accessInventory: r.access_inventory === 1 || r.access_inventory === true,
        accessReports: r.access_reports === 1 || r.access_reports === true,
        accessAdmin: r.access_admin === 1 || r.access_admin === true,
        accessPartyDetails: r.access_party_details === 1 || r.access_party_details === true,
        createdAt: r.created_at
      }))
    });
  } catch (error: any) {
    return reply.status(500).send({ success: false, message: error?.message || 'Failed to fetch roles.' });
  }
}

export async function createRoleHandler(req: FastifyRequest, reply: FastifyReply) {
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

    const {
      name,
      accessSales = false,
      accessPurchase = false,
      accessInventory = false,
      accessReports = false,
      accessAdmin = false,
      accessPartyDetails = false
    } = body;

    if (!name || !name.trim()) {
      return reply.status(400).send({ success: false, message: 'Role name is required.' });
    }

    const insertRes = await pool.query(
      `INSERT INTO roles (business_id, name, access_sales, access_purchase, access_inventory, access_reports, access_admin, access_party_details)
       VALUES ($1, $2, $3, $4, $5, $6, $7, $8)
       RETURNING *`,
      [
        activeBusinessId,
        name.trim(),
        accessSales ? 1 : 0,
        accessPurchase ? 1 : 0,
        accessInventory ? 1 : 0,
        accessReports ? 1 : 0,
        accessAdmin ? 1 : 0,
        accessPartyDetails ? 1 : 0
      ]
    );

    const r = insertRes.rows[0];
    return reply.status(201).send({
      success: true,
      message: 'Role created successfully.',
      role: {
        id: r.id,
        name: r.name,
        accessSales: r.access_sales === 1 || r.access_sales === true,
        accessPurchase: r.access_purchase === 1 || r.access_purchase === true,
        accessInventory: r.access_inventory === 1 || r.access_inventory === true,
        accessReports: r.access_reports === 1 || r.access_reports === true,
        accessAdmin: r.access_admin === 1 || r.access_admin === true,
        accessPartyDetails: r.access_party_details === 1 || r.access_party_details === true,
        createdAt: r.created_at
      }
    });
  } catch (error: any) {
    return reply.status(500).send({ success: false, message: error?.message || 'Failed to create role.' });
  }
}

export async function updateRoleHandler(req: FastifyRequest, reply: FastifyReply) {
  try {
    const { id } = req.params as { id: string };
    const pool = getDbPool();
    const body = req.body as any;

    const {
      name,
      accessSales,
      accessPurchase,
      accessInventory,
      accessReports,
      accessAdmin,
      accessPartyDetails
    } = body;

    const updateRes = await pool.query(
      `UPDATE roles
       SET name = COALESCE($1, name),
           access_sales = COALESCE($2, access_sales),
           access_purchase = COALESCE($3, access_purchase),
           access_inventory = COALESCE($4, access_inventory),
           access_reports = COALESCE($5, access_reports),
           access_admin = COALESCE($6, access_admin),
           access_party_details = COALESCE($7, access_party_details)
       WHERE id = $8
       RETURNING *`,
      [
        name ? name.trim() : null,
        accessSales !== undefined ? (accessSales ? 1 : 0) : null,
        accessPurchase !== undefined ? (accessPurchase ? 1 : 0) : null,
        accessInventory !== undefined ? (accessInventory ? 1 : 0) : null,
        accessReports !== undefined ? (accessReports ? 1 : 0) : null,
        accessAdmin !== undefined ? (accessAdmin ? 1 : 0) : null,
        accessPartyDetails !== undefined ? (accessPartyDetails ? 1 : 0) : null,
        id
      ]
    );

    if (updateRes.rows.length === 0) {
      return reply.status(404).send({ success: false, message: 'Role not found.' });
    }

    const r = updateRes.rows[0];
    return reply.send({
      success: true,
      message: 'Role updated successfully.',
      role: {
        id: r.id,
        name: r.name,
        accessSales: r.access_sales === 1 || r.access_sales === true,
        accessPurchase: r.access_purchase === 1 || r.access_purchase === true,
        accessInventory: r.access_inventory === 1 || r.access_inventory === true,
        accessReports: r.access_reports === 1 || r.access_reports === true,
        accessAdmin: r.access_admin === 1 || r.access_admin === true,
        accessPartyDetails: r.access_party_details === 1 || r.access_party_details === true,
        createdAt: r.created_at
      }
    });
  } catch (error: any) {
    return reply.status(500).send({ success: false, message: error?.message || 'Failed to update role.' });
  }
}

export async function deleteRoleHandler(req: FastifyRequest, reply: FastifyReply) {
  try {
    const { id } = req.params as { id: string };
    const pool = getDbPool();

    // Check if any team member is using this role
    const countRes = await pool.query('SELECT COUNT(*) FROM team_members WHERE role_id = $1', [id]);
    if (parseInt(countRes.rows[0].count, 10) > 0) {
      return reply.status(400).send({
        success: false,
        message: 'Cannot delete role because it is currently assigned to team members.'
      });
    }

    const delRes = await pool.query('DELETE FROM roles WHERE id = $1 RETURNING id', [id]);
    if (delRes.rows.length === 0) {
      return reply.status(404).send({ success: false, message: 'Role not found.' });
    }

    return reply.send({ success: true, message: 'Role deleted successfully.' });
  } catch (error: any) {
    return reply.status(500).send({ success: false, message: error?.message || 'Failed to delete role.' });
  }
}
