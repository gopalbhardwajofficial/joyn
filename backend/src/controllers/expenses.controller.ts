import { FastifyRequest, FastifyReply } from 'fastify';
import { getDbPool } from '../db/connection.js';

function toValidUuidOrNull(val: any): string | null {
  if (typeof val !== 'string' || !val) return null;
  const uuidRegex = /^[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i;
  return uuidRegex.test(val) ? val : null;
}

// 1. List Expenses with filtering
export async function listExpensesHandler(req: FastifyRequest, reply: FastifyReply) {
  try {
    const activeBusinessId = (req as any).businessAccess?.businessId || (req.headers['x-business-id'] as string) || (req.query as any)?.businessId;
    if (!activeBusinessId) {
      return reply.status(400).send({ success: false, message: 'x-business-id is required.' });
    }

    const { category, startDate, endDate, limit = 100 } = (req.query as any) || {};
    const pool = getDbPool();

    let query = `
      SELECT id, expense_category, expense_type, amount, payment_mode, notes, expense_date, created_at
      FROM expenses
      WHERE business_id = $1
    `;
    const params: any[] = [activeBusinessId];

    if (category) {
      params.push(category);
      query += ` AND expense_category = $${params.length}`;
    }
    if (startDate) {
      params.push(startDate);
      query += ` AND expense_date >= $${params.length}`;
    }
    if (endDate) {
      params.push(endDate);
      query += ` AND expense_date <= $${params.length}`;
    }

    query += ` ORDER BY expense_date DESC, created_at DESC LIMIT ${parseInt(limit) || 100}`;

    const res = await pool.query(query, params);
    const totalAmount = res.rows.reduce((sum: number, r: any) => sum + parseFloat(r.amount || 0), 0);

    return reply.send({
      success: true,
      count: res.rows.length,
      totalAmount: parseFloat(totalAmount.toFixed(2)),
      expenses: res.rows.map((r: any) => ({
        id: r.id,
        category: r.expense_category,
        type: r.expense_type,
        amount: parseFloat(r.amount || 0),
        paymentMode: r.payment_mode,
        notes: r.notes || '',
        expenseDate: r.expense_date,
        createdAt: r.created_at
      }))
    });
  } catch (error: any) {
    console.error('List Expenses Error:', error);
    return reply.status(500).send({ success: false, message: error?.message || 'Failed to list expenses.' });
  }
}

// 2. Create Expense
export async function createExpenseHandler(req: FastifyRequest, reply: FastifyReply) {
  try {
    const activeBusinessId = (req as any).businessAccess?.businessId || (req.headers['x-business-id'] as string) || (req.body as any)?.businessId;
    if (!activeBusinessId) {
      return reply.status(400).send({ success: false, message: 'x-business-id is required.' });
    }

    const {
      category,
      expenseCategory,
      type = 'Indirect',
      expenseType,
      amount,
      paymentMode = 'CASH',
      notes = '',
      expenseDate
    } = (req.body as any) || {};

    const cat = category || expenseCategory || 'General Expense';
    const expType = expenseType || type || 'Indirect';
    const numAmount = parseFloat(amount || 0);

    if (numAmount <= 0) {
      return reply.status(400).send({ success: false, message: 'Valid expense amount > 0 is required.' });
    }

    const pool = getDbPool();
    const dateVal = expenseDate || new Date().toISOString().split('T')[0];

    const res = await pool.query(
      `INSERT INTO expenses (business_id, expense_category, expense_type, amount, payment_mode, notes, expense_date)
       VALUES ($1, $2, $3, $4, $5, $6, $7)
       RETURNING *`,
      [activeBusinessId, cat, expType, numAmount, paymentMode, notes, dateVal]
    );

    return reply.status(201).send({
      success: true,
      message: 'Expense recorded successfully.',
      expense: res.rows[0]
    });
  } catch (error: any) {
    console.error('Create Expense Error:', error);
    return reply.status(500).send({ success: false, message: error?.message || 'Failed to create expense.' });
  }
}

// 3. Delete Expense
export async function deleteExpenseHandler(req: FastifyRequest, reply: FastifyReply) {
  try {
    const { id } = req.params as { id: string };
    const validId = toValidUuidOrNull(id);
    const activeBusinessId = (req as any).businessAccess?.businessId || (req.headers['x-business-id'] as string);

    if (!validId) {
      return reply.status(400).send({ success: false, message: 'Valid expense ID is required.' });
    }

    if (!activeBusinessId) {
      return reply.status(400).send({ success: false, message: 'x-business-id is required.' });
    }

    const pool = getDbPool();
    await pool.query(
      `DELETE FROM expenses WHERE id = $1 AND business_id = $2`,
      [validId, activeBusinessId]
    );

    return reply.send({
      success: true,
      message: 'Expense deleted successfully.'
    });
  } catch (error: any) {
    return reply.status(500).send({ success: false, message: error?.message || 'Failed to delete expense.' });
  }
}

// 4. Expense Summary & Category Breakdown
export async function getExpenseSummaryHandler(req: FastifyRequest, reply: FastifyReply) {
  try {
    const activeBusinessId = (req as any).businessAccess?.businessId || (req.headers['x-business-id'] as string) || (req.query as any)?.businessId;
    if (!activeBusinessId) {
      return reply.status(400).send({ success: false, message: 'x-business-id is required.' });
    }

    const pool = getDbPool();
    const res = await pool.query(
      `SELECT expense_category, expense_type, SUM(amount) as total_amount, COUNT(*) as count
       FROM expenses
       WHERE business_id = $1
       GROUP BY expense_category, expense_type
       ORDER BY total_amount DESC`,
      [activeBusinessId]
    );

    const grandTotal = res.rows.reduce((sum: number, r: any) => sum + parseFloat(r.total_amount || 0), 0);

    return reply.send({
      success: true,
      grandTotal: parseFloat(grandTotal.toFixed(2)),
      categories: res.rows.map((r: any) => ({
        category: r.expense_category,
        type: r.expense_type,
        count: parseInt(r.count),
        totalAmount: parseFloat(r.total_amount || 0)
      }))
    });
  } catch (error: any) {
    return reply.status(500).send({ success: false, message: error?.message || 'Failed to fetch expense summary.' });
  }
}

