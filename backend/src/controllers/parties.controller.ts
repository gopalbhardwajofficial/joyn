import { FastifyRequest, FastifyReply } from 'fastify';
import { getDbPool } from '../db/connection.js';
import { toDeterministicUuid } from '../utils/common.utils.js';

export async function getPartiesHandler(req: FastifyRequest, reply: FastifyReply) {
  try {
    const { businessId, partyType } = req.query as { businessId?: string; partyType?: string };
    const pool = getDbPool();
    const user = (req as any).user;

    let activeBiz = businessId || (req.headers['x-business-id'] as string);
    if (!activeBiz && user?.userId) {
      const bizRes = await pool.query(
        'SELECT id FROM business_profile WHERE owner_id = $1 ORDER BY created_at ASC LIMIT 1',
        [user.userId]
      );
      if (bizRes.rows.length > 0) activeBiz = bizRes.rows[0].id;
    }

    let query = `SELECT * FROM parties WHERE 1=1`;
    const params: any[] = [];

    if (activeBiz) {
      params.push(activeBiz);
      query += ` AND business_id = $${params.length}`;
    }
    if (partyType && partyType.toLowerCase() !== 'all') {
      const pLower = partyType.toLowerCase().trim();
      if (pLower === 'customer' || pLower === 'customers') {
        query += ` AND (LOWER(party_type) = 'customer' OR LOWER(party_type) = 'both')`;
      } else if (pLower === 'supplier' || pLower === 'suppliers') {
        query += ` AND (LOWER(party_type) = 'supplier' OR LOWER(party_type) = 'both')`;
      } else {
        params.push(pLower);
        query += ` AND LOWER(party_type) = $${params.length}`;
      }
    }
    query += ` ORDER BY created_at DESC`;

    const res = await pool.query(query, params);

    const mapped = res.rows.map((p: any) => ({
      id: p.id,
      businessId: p.business_id,
      name: p.name,
      category: p.category || 'General',
      contactNumber: p.contact_number || '',
      email: p.email || '',
      address: p.address || '',
      city: p.city || '',
      openingBalance: parseFloat(p.opening_balance || 0),
      balanceType: p.balance_type || 'toReceive',
      creditLimit: p.credit_limit ? parseFloat(p.credit_limit) : null,
      partyType: p.party_type || 'customer',
      priorityLevel: p.priority_level || 'medium',
      avatarIndex: p.avatar_index || 0,
      photoPath: p.photo_url || '',
      partyNumber: p.party_number,
      partyCode: p.party_code || (p.party_number ? `PRT-${p.party_number}` : null),
      createdAt: p.created_at
    }));

    return reply.send({
      success: true,
      parties: mapped,
      data: mapped
    });
  } catch (error: any) {
    return reply.status(500).send({ success: false, message: error?.message || 'Failed to fetch parties.' });
  }
}

export async function createPartyHandler(req: FastifyRequest, reply: FastifyReply) {
  try {
    const {
      businessId,
      name,
      category,
      contactNumber,
      phone,
      email,
      address,
      city,
      openingBalance,
      balanceType,
      creditLimit,
      partyType,
      priorityLevel,
      avatarIndex
    } = req.body as any;

    const pool = getDbPool();
    const user = (req as any).user;
    let activeBiz = businessId || (req.headers['x-business-id'] as string);
    if (!activeBiz && user?.userId) {
      const bizRes = await pool.query(
        'SELECT id FROM business_profile WHERE owner_id = $1 ORDER BY created_at ASC LIMIT 1',
        [user.userId]
      );
      if (bizRes.rows.length > 0) activeBiz = bizRes.rows[0].id;
    }

    if (!name || !activeBiz) {
      return reply.status(400).send({ success: false, message: 'Party name and businessId are required.' });
    }

    const body = req.body as any || {};
    const effectiveType = (partyType || body.type || 'customer').toString().toLowerCase();

    const numRes = await pool.query(
      `SELECT COALESCE(MAX(party_number), 1000) + 1 AS next_num FROM parties WHERE business_id = $1`,
      [activeBiz]
    );
    const assignedNum = parseInt(body.partyNumber || body.party_number || numRes.rows[0].next_num, 10);
    const assignedCode = body.partyCode || body.party_code || `PRT-${assignedNum}`;
    const explicitId = body.id ? toDeterministicUuid(body.id) : null;

    const res = await pool.query(
      `INSERT INTO parties (
        id, business_id, name, category, contact_number, email, address, city,
        opening_balance, balance_type, credit_limit, party_type, priority_level, avatar_index,
        party_number, party_code
      ) VALUES (COALESCE($1, gen_random_uuid()), $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13, $14, $15, $16)
      RETURNING *`,
      [
        explicitId,
        activeBiz,
        name,
        category || 'General',
        contactNumber || phone || '',
        email || '',
        address || '',
        city || '',
        openingBalance || 0,
        balanceType || 'toReceive',
        creditLimit || null,
        effectiveType,
        priorityLevel || 'medium',
        avatarIndex || 0,
        assignedNum,
        assignedCode
      ]
    );

    const p = res.rows[0];
    const returnParty = {
      id: p.id,
      businessId: p.business_id,
      name: p.name,
      contactNumber: p.contact_number,
      openingBalance: parseFloat(p.opening_balance || 0),
      balanceType: p.balance_type,
      partyType: p.party_type,
      partyNumber: p.party_number,
      partyCode: p.party_code,
      createdAt: p.created_at
    };

    return reply.status(201).send({
      success: true,
      message: 'Party created successfully',
      party: returnParty,
      data: returnParty
    });
  } catch (error: any) {
    return reply.status(500).send({ success: false, message: error?.message || 'Failed to create party.' });
  }
}

export async function updatePartyHandler(req: FastifyRequest, reply: FastifyReply) {
  try {
    const { id } = req.params as { id: string };
    const updates = req.body as any;
    const pool = getDbPool();

    const res = await pool.query(
      `UPDATE parties SET 
        name = COALESCE($1, name),
        contact_number = COALESCE($2, contact_number),
        opening_balance = COALESCE($3, opening_balance),
        updated_at = CURRENT_TIMESTAMP
       WHERE id = $4 RETURNING *`,
      [updates.name, updates.contactNumber, updates.openingBalance, id]
    );

    if (res.rows.length === 0) {
      return reply.status(404).send({ success: false, message: 'Party not found' });
    }

    return reply.send({ success: true, message: 'Party updated successfully', party: res.rows[0] });
  } catch (error: any) {
    return reply.status(500).send({ success: false, message: error?.message || 'Failed to update party.' });
  }
}

export async function deletePartyHandler(req: FastifyRequest, reply: FastifyReply) {
  try {
    const { id } = req.params as { id: string };
    const pool = getDbPool();

    await pool.query(`DELETE FROM parties WHERE id = $1`, [id]);
    return reply.send({ success: true, message: 'Party deleted successfully' });
  } catch (error: any) {
    return reply.status(500).send({ success: false, message: error?.message || 'Failed to delete party.' });
  }
}
