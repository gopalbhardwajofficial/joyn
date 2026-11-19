import { FastifyRequest, FastifyReply } from 'fastify';
import { getDbPool } from '../db/connection.js';

// Helper to determine active business ID
async function resolveBusinessId(req: FastifyRequest): Promise<string | null> {
  const verifiedId = (req as any).businessAccess?.businessId;
  if (verifiedId) return verifiedId;

  const user = (req as any).user;
  const pool = getDbPool();
  let bizId = (req.headers['x-business-id'] as string) || (req.query as any)?.businessId;

  if (!bizId && user?.userId) {
    const res = await pool.query(
      'SELECT id FROM business_profile WHERE owner_id = $1 ORDER BY created_at ASC LIMIT 1',
      [user.userId]
    );
    if (res.rows.length > 0) bizId = res.rows[0].id;
  }
  return bizId || null;
}

// =====================================================================
// 1. DAY BOOK HANDLER
// =====================================================================
export async function getDayBookHandler(req: FastifyRequest, reply: FastifyReply) {
  try {
    const pool = getDbPool();
    const businessId = await resolveBusinessId(req);
    if (!businessId) {
      return reply.status(400).send({ success: false, message: 'Business ID is required.' });
    }

    const { date } = req.query as { date?: string };
    const targetDate = date || new Date().toISOString().slice(0, 10);

    // 1. Fetch Sales on target date
    const salesRes = await pool.query(
      `SELECT so.id, so.invoice_no, so.total_amount, so.created_at, COALESCE(so.customer_name, p.name) as party_name
       FROM sales_orders so
       LEFT JOIN parties p ON so.party_id = p.id
       WHERE so.business_id = $1 AND (so.date = $2 OR so.created_at::date = $2::date)
       ORDER BY so.created_at ASC`,
      [businessId, targetDate]
    );

    // 2. Fetch Purchases on target date
    const purchasesRes = await pool.query(
      `SELECT po.id, po.order_no, po.total_amount, po.created_at, COALESCE(po.party_name, p.name) as party_name
       FROM purchase_orders po
       LEFT JOIN parties p ON po.party_id = p.id
       WHERE po.business_id = $1 AND (po.date = $2 OR po.created_at::date = $2::date)
       ORDER BY po.created_at ASC`,
      [businessId, targetDate]
    );

    // 3. Fetch Payments on target date
    const paymentsRes = await pool.query(
      `SELECT pay.id, pay.receipt_no, pay.received_amount, pay.is_payment_out, pay.payment_type, pay.created_at, COALESCE(pay.party_name, p.name) as party_name
       FROM payments pay
       LEFT JOIN parties p ON pay.party_id = p.id
       WHERE pay.business_id = $1 AND (pay.date = $2 OR pay.created_at::date = $2::date)
       ORDER BY pay.created_at ASC`,
      [businessId, targetDate]
    );

    // 4. Fetch Expenses on target date
    const expensesRes = await pool.query(
      `SELECT id, expense_category, amount, payment_mode, notes, created_at
       FROM expenses
       WHERE business_id = $1 AND (expense_date = $2 OR expense_date::date = $2::date)
       ORDER BY created_at ASC`,
      [businessId, targetDate]
    );

    let totalSales = 0;
    let totalPurchases = 0;
    let totalExpenses = 0;
    let totalMoneyIn = 0;
    let totalMoneyOut = 0;

    const timeline: any[] = [];

    // Process Sales
    for (const s of salesRes.rows) {
      const amt = parseFloat(s.total_amount) || 0;
      totalSales += amt;
      totalMoneyIn += amt;
      timeline.push({
        id: s.id,
        type: 'Sale',
        title: `Sale Invoice #${s.invoice_no || 'INV'}`,
        subtitle: s.party_name ? `Customer: ${s.party_name}` : 'Cash Sale',
        partyName: s.party_name || 'Cash Customer',
        amount: amt,
        isPositive: true,
        timestamp: s.created_at
      });
    }

    // Process Purchases
    for (const p of purchasesRes.rows) {
      const amt = parseFloat(p.total_amount) || 0;
      totalPurchases += amt;
      totalMoneyOut += amt;
      timeline.push({
        id: p.id,
        type: 'Purchase',
        title: `Purchase #${p.order_no || 'PO'}`,
        subtitle: p.party_name ? `Vendor: ${p.party_name}` : 'Direct Purchase',
        partyName: p.party_name || 'Cash Vendor',
        amount: amt,
        isPositive: false,
        timestamp: p.created_at
      });
    }

    // Process Payments
    for (const pay of paymentsRes.rows) {
      const amt = parseFloat(pay.received_amount) || 0;
      const isPayOut = pay.is_payment_out === 1 || pay.is_payment_out === true;
      if (!isPayOut) {
        totalMoneyIn += amt;
      } else {
        totalMoneyOut += amt;
      }
      timeline.push({
        id: pay.id,
        type: isPayOut ? 'PaymentOut' : 'PaymentIn',
        title: isPayOut ? `Payment Out (${pay.payment_type || 'Cash'})` : `Payment In (${pay.payment_type || 'Cash'})`,
        subtitle: pay.party_name ? `Party: ${pay.party_name}` : `Receipt #${pay.receipt_no}`,
        partyName: pay.party_name || 'Party',
        amount: amt,
        isPositive: !isPayOut,
        timestamp: pay.created_at
      });
    }

    // Process Expenses
    for (const exp of expensesRes.rows) {
      const amt = parseFloat(exp.amount) || 0;
      totalExpenses += amt;
      totalMoneyOut += amt;
      timeline.push({
        id: exp.id,
        type: 'Expense',
        title: `Expense: ${exp.expense_category}`,
        subtitle: exp.notes ? exp.notes : `Paid via ${exp.payment_mode || 'CASH'}`,
        partyName: exp.expense_category,
        amount: amt,
        isPositive: false,
        timestamp: exp.created_at
      });
    }

    // Sort timeline chronologically descending
    timeline.sort((a, b) => new Date(b.timestamp).getTime() - new Date(a.timestamp).getTime());

    return reply.send({
      success: true,
      date: targetDate,
      summary: {
        totalSales: parseFloat(totalSales.toFixed(2)),
        totalPurchases: parseFloat(totalPurchases.toFixed(2)),
        totalExpenses: parseFloat(totalExpenses.toFixed(2)),
        totalMoneyIn: parseFloat(totalMoneyIn.toFixed(2)),
        totalMoneyOut: parseFloat(totalMoneyOut.toFixed(2)),
        netCashFlow: parseFloat((totalMoneyIn - totalMoneyOut).toFixed(2))
      },
      transactions: timeline
    });
  } catch (error: any) {
    return reply.status(500).send({ success: false, message: error?.message || 'Failed to fetch Day Book.' });
  }
}

// =====================================================================
// 2. PROFIT & LOSS HANDLER
// =====================================================================
export async function getProfitAndLossHandler(req: FastifyRequest, reply: FastifyReply) {
  try {
    const pool = getDbPool();
    const businessId = await resolveBusinessId(req);
    if (!businessId) {
      return reply.status(400).send({ success: false, message: 'Business ID is required.' });
    }

    const { startDate, endDate } = req.query as { startDate?: string; endDate?: string };
    const now = new Date();
    const start = startDate ? new Date(startDate) : new Date(now.getFullYear(), now.getMonth(), 1);
    const end = endDate ? new Date(endDate) : new Date(now.getFullYear(), now.getMonth() + 1, 0, 23, 59, 59);

    // Gross Sales
    const salesRes = await pool.query(
      `SELECT COALESCE(SUM(total_amount), 0) as total FROM sales_orders
       WHERE business_id = $1 AND created_at >= $2 AND created_at <= $3`,
      [businessId, start.toISOString(), end.toISOString()]
    );
    const grossSales = parseFloat(salesRes.rows[0].total) || 0;

    // Gross Purchases
    const purchasesRes = await pool.query(
      `SELECT COALESCE(SUM(total_amount), 0) as total FROM purchase_orders
       WHERE business_id = $1 AND created_at >= $2 AND created_at <= $3`,
      [businessId, start.toISOString(), end.toISOString()]
    );
    const grossPurchases = parseFloat(purchasesRes.rows[0].total) || 0;

    // Direct and Indirect Expenses with Category Breakdown
    const expRes = await pool.query(
      `SELECT COALESCE(category, 'General Expense') as category,
              COALESCE(expense_type, 'Indirect') as expense_type,
              COALESCE(SUM(amount), 0) as total
       FROM expenses
       WHERE business_id = $1 AND created_at >= $2 AND created_at <= $3
       GROUP BY category, expense_type`,
      [businessId, start.toISOString(), end.toISOString()]
    );

    let directExpenses = 0;
    let indirectExpenses = 0;
    const expenseBreakdown: { category: string; amount: number; isDirect: boolean }[] = [];

    for (const r of expRes.rows) {
      const amt = parseFloat(r.total) || 0;
      const cat = r.category || 'General';
      const isDirect = r.expense_type === 'Direct' || ['Packaging', 'Freight', 'Manufacturing', 'Raw Materials'].includes(cat);
      if (isDirect) {
        directExpenses += amt;
      } else {
        indirectExpenses += amt;
      }
      expenseBreakdown.push({ category: cat, amount: amt, isDirect });
    }

    // Closing Stock Valuation
    const stockRes = await pool.query(
      `SELECT COALESCE(SUM(stock * purchase_price), 0) as total FROM items WHERE business_id = $1`,
      [businessId]
    );
    const closingStock = parseFloat(stockRes.rows[0].total) || 0;
    const openingStock = 0.0;

    // Cost of Goods Sold (COGS)
    let cogs = openingStock + grossPurchases + directExpenses - closingStock;
    if (cogs < 0) cogs = grossPurchases * 0.7; // Standard fallback estimate

    const grossProfit = parseFloat((grossSales - cogs).toFixed(2));
    const netProfit = parseFloat((grossProfit - indirectExpenses).toFixed(2));
    const grossMarginPct = grossSales > 0 ? parseFloat(((grossProfit / grossSales) * 100).toFixed(1)) : 0.0;
    const netMarginPct = grossSales > 0 ? parseFloat(((netProfit / grossSales) * 100).toFixed(1)) : 0.0;

    const rows = [
      { type: 'sectionHeader', label: '1. Revenue from Operations' },
      { type: 'item', label: 'Gross Sales / Turnover (+)', amount: grossSales, isPositive: true },
      { type: 'item', label: 'Fixed Assets Sales (+)', amount: 0.0, isPositive: true },
      { type: 'item', label: 'Sales Returns & Credit Notes (-)', amount: 0.0, isPositive: false },
      { type: 'item', label: 'Net Operating Revenue', amount: grossSales, isPositive: true },

      { type: 'sectionHeader', label: '2. Cost of Goods Sold (COGS)' },
      { type: 'item', label: 'Opening Stock (-)', amount: openingStock, isPositive: false },
      { type: 'item', label: 'Gross Purchases (-)', amount: grossPurchases, isPositive: false },
      { type: 'item', label: 'Direct Operations / Freight (-)', amount: directExpenses, isPositive: false },
      { type: 'item', label: 'Less: Closing Stock (+)', amount: closingStock, isPositive: true },
      { type: 'item', label: 'Total Cost of Goods Sold (COGS)', amount: parseFloat(cogs.toFixed(2)), isPositive: false },

      { type: 'highlight', label: `Gross Profit (${grossMarginPct}% Margin)`, amount: grossProfit, isPositive: grossProfit >= 0 },

      { type: 'sectionHeader', label: '3. Operating & Administrative Expenses' },
      ...(expenseBreakdown.filter(e => !e.isDirect).length > 0
        ? expenseBreakdown.filter(e => !e.isDirect).map(e => ({
            type: 'item',
            label: `${e.category} (-)`,
            amount: parseFloat(e.amount.toFixed(2)),
            isPositive: false
          }))
        : [{ type: 'item', label: 'Administrative & General Expenses', amount: indirectExpenses, isPositive: false }]
      ),
      { type: 'item', label: 'Total Operating Expenses', amount: indirectExpenses, isPositive: false },

      { type: 'sectionHeader', label: '4. EBITDA & Operating Profit' },
      { type: 'item', label: 'Operating Profit (EBITDA)', amount: parseFloat((grossProfit - indirectExpenses).toFixed(2)), isPositive: (grossProfit - indirectExpenses) >= 0 },

      { type: 'highlight', label: `Net Profit / (Loss) (${netMarginPct}% Margin)`, amount: netProfit, isPositive: netProfit >= 0 }
    ];

    return reply.send({
      success: true,
      startDate: start.toISOString(),
      endDate: end.toISOString(),
      grossProfit,
      netProfit,
      grossMarginPct,
      netMarginPct,
      grossSales,
      grossPurchases,
      cogs: parseFloat(cogs.toFixed(2)),
      directExpenses,
      indirectExpenses,
      closingStock,
      expenseBreakdown,
      rows
    });
  } catch (error: any) {
    return reply.status(500).send({ success: false, message: error?.message || 'Failed to compute P&L.' });
  }
}

// =====================================================================
// 3. BALANCE SHEET HANDLER
// =====================================================================
export async function getBalanceSheetHandler(req: FastifyRequest, reply: FastifyReply) {
  try {
    const pool = getDbPool();
    const businessId = await resolveBusinessId(req);
    if (!businessId) {
      return reply.status(400).send({ success: false, message: 'Business ID is required.' });
    }

    const { asOfDate } = req.query as { asOfDate?: string };
    const targetAsOf = asOfDate || new Date().toISOString().slice(0, 10);

    // 1. Debtors (Accounts Receivable) from Parties
    const debtorsRes = await pool.query(
      `SELECT COALESCE(SUM(opening_balance), 0) as total FROM parties WHERE business_id = $1 AND opening_balance > 0`,
      [businessId]
    );
    const debtors = parseFloat(debtorsRes.rows[0].total) || 0;

    // 2. Creditors (Accounts Payable) from Parties
    const creditorsRes = await pool.query(
      `SELECT COALESCE(SUM(ABS(opening_balance)), 0) as total FROM parties WHERE business_id = $1 AND opening_balance < 0`,
      [businessId]
    );
    const creditors = parseFloat(creditorsRes.rows[0].total) || 0;

    // 3. Stock in hand (Inventory asset)
    const stockRes = await pool.query(
      `SELECT COALESCE(SUM(stock * purchase_price), 0) as total FROM items WHERE business_id = $1`,
      [businessId]
    );
    const stockValuation = parseFloat(stockRes.rows[0].total) || 0;

    // 4. Net Cash / Bank Position
    const payInRes = await pool.query(
      `SELECT COALESCE(SUM(received_amount), 0) as total FROM payments WHERE business_id = $1 AND (is_payment_out = 0 OR is_payment_out IS NULL)`,
      [businessId]
    );
    const payOutRes = await pool.query(
      `SELECT COALESCE(SUM(received_amount), 0) as total FROM payments WHERE business_id = $1 AND is_payment_out = 1`,
      [businessId]
    );
    const expRes = await pool.query(
      `SELECT COALESCE(SUM(amount), 0) as total FROM expenses WHERE business_id = $1`,
      [businessId]
    );
    const salesRes = await pool.query(
      `SELECT COALESCE(SUM(total_amount), 0) as total FROM sales_orders WHERE business_id = $1`,
      [businessId]
    );
    const purchRes = await pool.query(
      `SELECT COALESCE(SUM(total_amount), 0) as total FROM purchase_orders WHERE business_id = $1`,
      [businessId]
    );

    const totalMoneyIn = parseFloat(payInRes.rows[0].total) + parseFloat(salesRes.rows[0].total);
    const totalMoneyOut = parseFloat(payOutRes.rows[0].total) + parseFloat(purchRes.rows[0].total) + parseFloat(expRes.rows[0].total);
    const cashInHand = Math.max(0, totalMoneyIn - totalMoneyOut);

    // Total Assets
    const totalCurrentAssets = parseFloat((cashInHand + debtors + stockValuation).toFixed(2));
    const fixedAssets = 0.00;
    const totalAssets = parseFloat((totalCurrentAssets + fixedAssets).toFixed(2));

    // Total Liabilities
    const totalLiabilities = parseFloat(creditors.toFixed(2));

    // Net Profit (Retained Earnings)
    const netProfit = Math.max(0, parseFloat((totalAssets - totalLiabilities).toFixed(2)));
    const ownersEquity = 0.00;
    const totalEquity = netProfit;

    const liabilityCards = [
      {
        rows: [
          { label: "Owner's Equity", amount: ownersEquity, style: 'normal' },
          {
            label: 'Reserves & Surplus',
            amount: totalEquity,
            style: 'normal',
            expandable: true,
            children: [{ label: 'Net Profit', amount: netProfit }]
          },
          { label: 'Equity/Capital', amount: totalEquity, style: 'subtotal' }
        ]
      },
      {
        rows: [
          {
            label: 'Current Liabilities',
            amount: totalLiabilities,
            style: 'normal',
            expandable: true,
            children: [{ label: 'Sundry Creditors (Vendors)', amount: creditors }]
          },
          { label: 'Total Liabilities', amount: totalLiabilities, style: 'subtotal' }
        ]
      }
    ];

    const assetCards = [
      {
        rows: [
          {
            label: 'Current Assets',
            amount: totalCurrentAssets,
            style: 'normal',
            expandable: true,
            children: [
              { label: 'Cash & Bank Balance', amount: cashInHand },
              { label: 'Sundry Debtors (Customers)', amount: debtors },
              { label: 'Closing Stock in Hand', amount: stockValuation }
            ]
          },
          { label: 'Fixed Assets', amount: fixedAssets, style: 'normal' },
          { label: 'Total Assets', amount: totalAssets, style: 'subtotal' }
        ]
      }
    ];

    const bsResponse = {
      asOfDate: targetAsOf,
      assets: {
        currentAssets: {
          cashInHand,
          bankAccounts: 0.00,
          sundryDebtors: debtors,
          stockInHand: stockValuation,
          totalCurrentAssets
        },
        fixedAssets,
        otherAssets: 0.00,
        totalAssets
      },
      liabilitiesAndEquity: {
        currentLiabilities: {
          sundryCreditors: creditors,
          dutiesAndTaxes: 0.00,
          otherCurrentLiabilities: 0.00,
          totalCurrentLiabilities: creditors
        },
        longTermLiabilities: 0.00,
        equity: {
          ownersEquity: 0.00,
          reservesAndSurplus: totalEquity,
          netProfit: totalEquity,
          totalEquity
        },
        totalLiabilitiesAndEquity: totalAssets
      }
    };

    return reply.send({
      success: true,
      totalAssets,
      totalLiabilities: totalAssets, // In double-entry balance sheet: Total Liabilities & Equity equals Total Assets
      actualLiabilities: totalLiabilities,
      totalEquity,
      cashInHand,
      debtors,
      stockValuation,
      creditors,
      liabilityCards,
      assetCards,
      balanceSheet: bsResponse
    });
  } catch (error: any) {
    return reply.status(500).send({ success: false, message: error?.message || 'Failed to compute Balance Sheet.' });
  }
}

// =====================================================================
// 4. CASH FLOW HANDLER
// =====================================================================
export async function getCashFlowHandler(req: FastifyRequest, reply: FastifyReply) {
  try {
    const pool = getDbPool();
    const businessId = await resolveBusinessId(req);
    if (!businessId) {
      return reply.status(400).send({ success: false, message: 'Business ID is required.' });
    }

    const { startDate, endDate } = req.query as { startDate?: string; endDate?: string };
    const now = new Date();
    const start = startDate ? new Date(startDate) : new Date(now.getFullYear(), now.getMonth(), 1);
    const end = endDate ? new Date(endDate) : new Date(now.getFullYear(), now.getMonth() + 1, 0, 23, 59, 59);

    // Payments In
    const payInRes = await pool.query(
      `SELECT COALESCE(SUM(received_amount), 0) as total FROM payments
       WHERE business_id = $1 AND (is_payment_out = 0 OR is_payment_out IS NULL) AND created_at >= $2 AND created_at <= $3`,
      [businessId, start.toISOString(), end.toISOString()]
    );
    const paymentsIn = parseFloat(payInRes.rows[0].total) || 0;

    // Payments Out
    const payOutRes = await pool.query(
      `SELECT COALESCE(SUM(received_amount), 0) as total FROM payments
       WHERE business_id = $1 AND is_payment_out = 1 AND created_at >= $2 AND created_at <= $3`,
      [businessId, start.toISOString(), end.toISOString()]
    );
    const paymentsOut = parseFloat(payOutRes.rows[0].total) || 0;

    // Expenses Outflow
    const expRes = await pool.query(
      `SELECT COALESCE(SUM(amount), 0) as total FROM expenses
       WHERE business_id = $1 AND created_at >= $2 AND created_at <= $3`,
      [businessId, start.toISOString(), end.toISOString()]
    );
    const expensesOut = parseFloat(expRes.rows[0].total) || 0;

    // Cash Sales
    const salesRes = await pool.query(
      `SELECT COALESCE(SUM(total_amount), 0) as total FROM sales_orders
       WHERE business_id = $1 AND created_at >= $2 AND created_at <= $3`,
      [businessId, start.toISOString(), end.toISOString()]
    );
    const cashSales = parseFloat(salesRes.rows[0].total) || 0;

    // Cash Purchases
    const purchRes = await pool.query(
      `SELECT COALESCE(SUM(total_amount), 0) as total FROM purchase_orders
       WHERE business_id = $1 AND created_at >= $2 AND created_at <= $3`,
      [businessId, start.toISOString(), end.toISOString()]
    );
    const cashPurchases = parseFloat(purchRes.rows[0].total) || 0;

    const totalInflow = parseFloat((paymentsIn + cashSales).toFixed(2));
    const totalOutflow = parseFloat((paymentsOut + cashPurchases + expensesOut).toFixed(2));
    const netCashFlow = parseFloat((totalInflow - totalOutflow).toFixed(2));

    const summary = {
      openingCash: 0.00,
      moneyIn: totalInflow,
      moneyOut: totalOutflow,
      closingCash: netCashFlow,
      netCashFlow
    };

    return reply.send({
      success: true,
      startDate: start.toISOString(),
      endDate: end.toISOString(),
      summary,
      moneyIn: totalInflow,
      moneyOut: totalOutflow,
      closingCash: netCashFlow,
      inflow: {
        paymentsIn,
        cashSales,
        totalInflow
      },
      outflow: {
        paymentsOut,
        cashPurchases,
        expenses: expensesOut,
        totalOutflow
      },
      netCashFlow
    });
  } catch (error: any) {
    return reply.status(500).send({ success: false, message: error?.message || 'Failed to compute Cash Flow.' });
  }
}

// =====================================================================
// 5. BILL-WISE PROFIT HANDLER
// =====================================================================
export async function getBillWiseProfitHandler(req: FastifyRequest, reply: FastifyReply) {
  try {
    const pool = getDbPool();
    const businessId = await resolveBusinessId(req);
    if (!businessId) {
      return reply.status(400).send({ success: false, message: 'Business ID is required.' });
    }

    const { startDate, endDate } = req.query as { startDate?: string; endDate?: string };
    const now = new Date();
    const start = startDate ? new Date(startDate) : new Date(now.getFullYear(), now.getMonth(), 1);
    const end = endDate ? new Date(endDate) : new Date(now.getFullYear(), now.getMonth() + 1, 0, 23, 59, 59);

    const invoicesRes = await pool.query(
      `SELECT so.id, so.invoice_no, so.total_amount, so.items_json, so.created_at, p.name as party_name
       FROM sales_orders so
       LEFT JOIN parties p ON so.party_id = p.id
       WHERE so.business_id = $1 AND so.created_at >= $2 AND so.created_at <= $3
       ORDER BY so.created_at DESC`,
      [businessId, start.toISOString(), end.toISOString()]
    );

    let totalRevenue = 0;
    let totalCost = 0;
    const bills = [];

    for (const inv of invoicesRes.rows) {
      const saleAmount = parseFloat(inv.total_amount) || 0;
      let estCost = 0;

      // Calculate cost from items_json if available
      let itemsList: any[] = [];
      try {
        itemsList = typeof inv.items_json === 'string' ? JSON.parse(inv.items_json) : (inv.items_json || []);
      } catch (e) {
        itemsList = [];
      }

      for (const item of itemsList) {
        const qty = parseFloat(item.quantity || item.qty || 1);
        const purchaseRate = parseFloat(item.purchase_price || item.purchasePrice || (item.rate ? item.rate * 0.7 : 0));
        estCost += qty * purchaseRate;
      }

      if (estCost === 0) estCost = saleAmount * 0.7; // 30% default profit margin fallback

      const profit = parseFloat((saleAmount - estCost).toFixed(2));
      const marginPct = saleAmount > 0 ? parseFloat(((profit / saleAmount) * 100).toFixed(1)) : 0;

      totalRevenue += saleAmount;
      totalCost += estCost;

      bills.push({
        id: inv.id,
        invoiceNo: inv.invoice_no || 'INV',
        partyName: inv.party_name || 'Cash Customer',
        date: inv.created_at,
        saleAmount,
        costAmount: parseFloat(estCost.toFixed(2)),
        profit,
        marginPercentage: marginPct
      });
    }

    const totalProfit = parseFloat((totalRevenue - totalCost).toFixed(2));
    const averageMargin = totalRevenue > 0 ? parseFloat(((totalProfit / totalRevenue) * 100).toFixed(1)) : 0;

    const summary = {
      totalSaleAmount: parseFloat(totalRevenue.toFixed(2)),
      totalCostAmount: parseFloat(totalCost.toFixed(2)),
      totalProfitLoss: totalProfit,
      averageMarginPercentage: averageMargin
    };

    return reply.send({
      success: true,
      totalRevenue: parseFloat(totalRevenue.toFixed(2)),
      totalCost: parseFloat(totalCost.toFixed(2)),
      totalProfit,
      averageMargin,
      summary,
      invoices: bills,
      bills
    });
  } catch (error: any) {
    return reply.status(500).send({ success: false, message: error?.message || 'Failed to compute Bill-Wise Profit.' });
  }
}

// =====================================================================
// 6. PARTY STATEMENT & RUNNING LEDGER HANDLER
// =====================================================================
export async function getPartyStatementHandler(req: FastifyRequest, reply: FastifyReply) {
  try {
    const { partyId } = req.params as { partyId: string };
    const pool = getDbPool();
    const businessId = await resolveBusinessId(req);
    if (!businessId) {
      return reply.status(400).send({ success: false, message: 'Business ID is required.' });
    }

    // Party Information
    const partyRes = await pool.query(
      `SELECT id, name, contact_number, party_type, opening_balance FROM parties WHERE id = $1 AND business_id = $2`,
      [partyId, businessId]
    );

    if (partyRes.rows.length === 0) {
      return reply.status(404).send({ success: false, message: 'Party not found.' });
    }

    const party = partyRes.rows[0];
    const initialOpeningBalance = parseFloat(party.opening_balance) || 0;

    // Fetch all party transactions
    // 1. Sales (Debit)
    const salesRes = await pool.query(
      `SELECT id, invoice_no, total_amount, created_at FROM sales_orders WHERE party_id = $1 ORDER BY created_at ASC`,
      [partyId]
    );

    // 2. Payments In (Credit)
    const payInRes = await pool.query(
      `SELECT id, receipt_no, received_amount, payment_type, created_at FROM payments WHERE party_id = $1 AND (is_payment_out = 0 OR is_payment_out IS NULL) ORDER BY created_at ASC`,
      [partyId]
    );

    // 3. Purchases (Credit)
    const purchRes = await pool.query(
      `SELECT id, order_no, total_amount, created_at FROM purchase_orders WHERE party_id = $1 ORDER BY created_at ASC`,
      [partyId]
    );

    // 4. Payments Out (Debit)
    const payOutRes = await pool.query(
      `SELECT id, receipt_no, received_amount, payment_type, created_at FROM payments WHERE party_id = $1 AND is_payment_out = 1 ORDER BY created_at ASC`,
      [partyId]
    );

    const ledger: any[] = [];
    let runningBalance = initialOpeningBalance;

    // Add Opening Balance entry
    ledger.push({
      id: 'opening',
      date: party.created_at || new Date().toISOString(),
      type: 'Opening Balance',
      debit: initialOpeningBalance > 0 ? initialOpeningBalance : 0,
      credit: initialOpeningBalance < 0 ? Math.abs(initialOpeningBalance) : 0,
      balance: runningBalance
    });

    let totalSale = 0;
    let totalPayment = 0;

    // Add Sales
    for (const s of salesRes.rows) {
      const amt = parseFloat(s.total_amount) || 0;
      totalSale += amt;
      runningBalance += amt;
      ledger.push({
        id: s.id,
        date: s.created_at,
        type: 'Sale',
        voucherNo: s.invoice_no,
        debit: amt,
        credit: 0,
        balance: runningBalance
      });
    }

    // Add Payments In
    for (const p of payInRes.rows) {
      const amt = parseFloat(p.received_amount) || 0;
      totalPayment += amt;
      runningBalance -= amt;
      ledger.push({
        id: p.id,
        date: p.created_at,
        type: 'Payment In',
        voucherNo: p.receipt_no,
        debit: 0,
        credit: amt,
        balance: runningBalance
      });
    }

    // Add Purchases
    for (const pu of purchRes.rows) {
      const amt = parseFloat(pu.total_amount) || 0;
      runningBalance -= amt;
      ledger.push({
        id: pu.id,
        date: pu.created_at,
        type: 'Purchase',
        voucherNo: pu.order_no,
        debit: 0,
        credit: amt,
        balance: runningBalance
      });
    }

    // Add Payments Out
    for (const po of payOutRes.rows) {
      const amt = parseFloat(po.received_amount) || 0;
      runningBalance += amt;
      ledger.push({
        id: po.id,
        date: po.created_at,
        type: 'Payment Out',
        voucherNo: po.receipt_no,
        debit: amt,
        credit: 0,
        balance: runningBalance
      });
    }

    // Sort ledger by date
    ledger.sort((a, b) => new Date(a.date).getTime() - new Date(b.date).getTime());

    return reply.send({
      success: true,
      party: {
        id: party.id,
        name: party.name,
        phone: party.contact_number || '',
        type: party.party_type,
        openingBalance: initialOpeningBalance,
        closingBalance: parseFloat(runningBalance.toFixed(2))
      },
      totalSale: parseFloat(totalSale.toFixed(2)),
      totalPayment: parseFloat(totalPayment.toFixed(2)),
      closingBalance: parseFloat(runningBalance.toFixed(2)),
      ledger
    });
  } catch (error: any) {
    return reply.status(500).send({ success: false, message: error?.message || 'Failed to fetch party statement.' });
  }
}

// =====================================================================
// 7. ALL PARTIES REPORT HANDLER
// =====================================================================
export async function getAllPartiesReportHandler(req: FastifyRequest, reply: FastifyReply) {
  try {
    const pool = getDbPool();
    const businessId = await resolveBusinessId(req);
    if (!businessId) {
      return reply.status(400).send({ success: false, message: 'Business ID is required.' });
    }

    const res = await pool.query(
      `SELECT id, name, contact_number, party_type, opening_balance, credit_limit, created_at
       FROM parties
       WHERE business_id = $1
       ORDER BY name ASC`,
      [businessId]
    );

    let totalReceivables = 0;
    let totalPayables = 0;

    const parties = res.rows.map((row: any) => {
      const bal = parseFloat(row.opening_balance) || 0;
      if (bal > 0) totalReceivables += bal;
      else if (bal < 0) totalPayables += Math.abs(bal);

      return {
        id: row.id,
        name: row.name,
        phone: row.contact_number || '',
        partyType: row.party_type || 'Customer',
        balance: bal,
        creditLimit: parseFloat(row.credit_limit) || 0
      };
    });

    return reply.send({
      success: true,
      totalParties: parties.length,
      totalReceivables: parseFloat(totalReceivables.toFixed(2)),
      totalPayables: parseFloat(totalPayables.toFixed(2)),
      netBalance: parseFloat((totalReceivables - totalPayables).toFixed(2)),
      parties
    });
  } catch (error: any) {
    return reply.status(500).send({ success: false, message: error?.message || 'Failed to fetch parties report.' });
  }
}

// =====================================================================
// 8. GST SUMMARY REPORT HANDLER (GSTR-1 & 3B)
// =====================================================================
export async function getGstSummaryHandler(req: FastifyRequest, reply: FastifyReply) {
  try {
    const pool = getDbPool();
    const businessId = await resolveBusinessId(req);
    if (!businessId) {
      return reply.status(400).send({ success: false, message: 'Business ID is required.' });
    }

    const { startDate, endDate } = req.query as { startDate?: string; endDate?: string };
    const now = new Date();
    const start = startDate ? new Date(startDate) : new Date(now.getFullYear(), now.getMonth(), 1);
    const end = endDate ? new Date(endDate) : new Date(now.getFullYear(), now.getMonth() + 1, 0, 23, 59, 59);

    const salesRes = await pool.query(
      `SELECT so.id, so.total_amount, so.items_json, so.is_one_time_customer
       FROM sales_orders so
       WHERE so.business_id = $1 AND so.created_at >= $2 AND so.created_at <= $3`,
      [businessId, start.toISOString(), end.toISOString()]
    );

    let b2bTotal = 0;
    let b2cTotal = 0;
    let totalTax = 0;

    for (const s of salesRes.rows) {
      const amt = parseFloat(s.total_amount) || 0;
      let itemsList: any[] = [];
      try {
        itemsList = typeof s.items_json === 'string' ? JSON.parse(s.items_json) : (s.items_json || []);
      } catch (e) {
        itemsList = [];
      }

      let orderTax = 0;
      for (const item of itemsList) {
        const taxPct = parseFloat(item.taxRatePercent || item.tax_rate_percent || 0);
        const itemTotal = (parseFloat(item.quantity || 1)) * (parseFloat(item.rate || item.sellingPrice || 0));
        orderTax += (itemTotal * taxPct) / 100;
      }

      totalTax += orderTax;

      if (s.is_one_time_customer === 1) {
        b2cTotal += amt;
      } else {
        b2bTotal += amt;
      }
    }

    const taxableSales = Math.max(0, b2bTotal + b2cTotal - totalTax);
    const gstSummary = {
      b2bSales: parseFloat(b2bTotal.toFixed(2)),
      b2cSales: parseFloat(b2cTotal.toFixed(2)),
      totalTaxableSales: parseFloat(taxableSales.toFixed(2)),
      totalTaxCollected: parseFloat(totalTax.toFixed(2)),
      cgst: parseFloat((totalTax / 2).toFixed(2)),
      sgst: parseFloat((totalTax / 2).toFixed(2)),
      igst: 0.0
    };

    return reply.send({
      success: true,
      ...gstSummary,
      gstSummary
    });
  } catch (error: any) {
    return reply.status(500).send({ success: false, message: error?.message || 'Failed to fetch GST summary.' });
  }
}

// =====================================================================
// 9. EXPENSES CRUD HANDLERS
// =====================================================================
export async function getExpensesHandler(req: FastifyRequest, reply: FastifyReply) {
  try {
    const pool = getDbPool();
    const businessId = await resolveBusinessId(req);
    if (!businessId) {
      return reply.status(400).send({ success: false, message: 'Business ID is required.' });
    }

    const res = await pool.query(
      `SELECT * FROM expenses WHERE business_id = $1 ORDER BY expense_date DESC, created_at DESC LIMIT 200`,
      [businessId]
    );

    return reply.send({
      success: true,
      expenses: res.rows.map((row: any) => ({
        id: row.id,
        category: row.expense_category,
        type: row.expense_type,
        amount: parseFloat(row.amount),
        paymentMode: row.payment_mode,
        notes: row.notes || '',
        date: row.expense_date,
        createdAt: row.created_at
      }))
    });
  } catch (error: any) {
    return reply.status(500).send({ success: false, message: error?.message || 'Failed to fetch expenses.' });
  }
}

export async function createExpenseHandler(req: FastifyRequest, reply: FastifyReply) {
  try {
    const pool = getDbPool();
    const businessId = await resolveBusinessId(req);
    if (!businessId) {
      return reply.status(400).send({ success: false, message: 'Business ID is required.' });
    }

    const body = (req.body as any) || {};
    const category = body.category || body.expenseCategory;
    const type = body.type || body.expenseType || 'Indirect';
    const amount = body.amount;
    const paymentMode = body.paymentMode || body.payment_mode || 'CASH';
    const notes = body.notes || '';
    const date = body.date || body.expenseDate;

    if (!category || !category.toString().trim()) {
      return reply.status(400).send({ success: false, message: 'Expense category is required.' });
    }
    const parsedAmount = parseFloat(amount);
    if (isNaN(parsedAmount) || parsedAmount <= 0) {
      return reply.status(400).send({ success: false, message: 'Valid expense amount is required.' });
    }

    const targetDate = date || new Date().toISOString().slice(0, 10);

    const res = await pool.query(
      `INSERT INTO expenses (business_id, expense_category, expense_type, amount, payment_mode, notes, expense_date)
       VALUES ($1, $2, $3, $4, $5, $6, $7)
       RETURNING *`,
      [businessId, category.trim(), type, parsedAmount, paymentMode, notes.trim(), targetDate]
    );

    const row = res.rows[0];

    return reply.status(201).send({
      success: true,
      message: 'Expense recorded successfully.',
      expense: {
        id: row.id,
        category: row.expense_category,
        type: row.expense_type,
        amount: parseFloat(row.amount),
        paymentMode: row.payment_mode,
        notes: row.notes,
        date: row.expense_date,
        createdAt: row.created_at
      }
    });
  } catch (error: any) {
    return reply.status(500).send({ success: false, message: error?.message || 'Failed to create expense.' });
  }
}

// =====================================================================
// 10. EXECUTIVE ANALYTICS & KPI DASHBOARD HANDLER
// =====================================================================
export async function getExecutiveAnalyticsHandler(req: FastifyRequest, reply: FastifyReply) {
  try {
    const pool = getDbPool();
    const businessId = await resolveBusinessId(req);
    if (!businessId) {
      return reply.status(400).send({ success: false, message: 'Business ID is required.' });
    }

    const {
      startDate,
      endDate,
      partyId,
      category,
      paymentMode
    } = req.query as {
      startDate?: string;
      endDate?: string;
      partyId?: string;
      category?: string;
      paymentMode?: string;
    };

    const now = new Date();
    const start = startDate ? new Date(startDate) : new Date(now.getFullYear(), now.getMonth(), 1);
    const end = endDate ? new Date(endDate) : new Date(now.getFullYear(), now.getMonth() + 1, 0, 23, 59, 59);

    const startIso = start.toISOString().slice(0, 10);
    const endIso = end.toISOString().slice(0, 10);

    // Compute previous period equivalent duration
    const durationMs = end.getTime() - start.getTime();
    const prevEnd = new Date(start.getTime() - 1000);
    const prevStart = new Date(prevEnd.getTime() - durationMs);
    const prevStartIso = prevStart.toISOString().slice(0, 10);
    const prevEndIso = prevEnd.toISOString().slice(0, 10);

    // 1. Fetch Sales Orders in Current Period
    let salesQuery = `
      SELECT so.id, so.invoice_no, so.date, so.payment_mode, so.payment_type,
             so.party_id, so.customer_name, so.customer_phone,
             so.items_json, so.total_amount, so.received_amount, so.created_at
      FROM sales_orders so
      WHERE so.business_id = $1 AND (so.date >= $2 AND so.date <= $3)
    `;
    const salesParams: any[] = [businessId, startIso, endIso];

    if (partyId) {
      salesParams.push(partyId);
      salesQuery += ` AND so.party_id = $${salesParams.length}`;
    }
    if (paymentMode) {
      salesParams.push(paymentMode);
      salesQuery += ` AND (LOWER(so.payment_mode) = LOWER($${salesParams.length}) OR LOWER(so.payment_type) = LOWER($${salesParams.length}))`;
    }
    salesQuery += ` ORDER BY so.date ASC, so.created_at ASC`;

    const salesRes = await pool.query(salesQuery, salesParams);

    // 2. Fetch Sales in Previous Period for Growth Calculation
    const prevSalesRes = await pool.query(
      `SELECT COALESCE(SUM(total_amount), 0.0) as prev_sales
       FROM sales_orders
       WHERE business_id = $1 AND (date >= $2 AND date <= $3)`,
      [businessId, prevStartIso, prevEndIso]
    );
    const prevPeriodSales = parseFloat(prevSalesRes.rows[0]?.prev_sales || 0);

    // 3. Fetch Purchases in Period
    const purchasesRes = await pool.query(
      `SELECT po.id, po.order_no, po.date, po.party_name, po.party_id, po.total_amount, po.created_at
       FROM purchase_orders po
       WHERE po.business_id = $1 AND (po.date >= $2 AND po.date <= $3)
       ORDER BY po.date ASC`,
      [businessId, startIso, endIso]
    );

    // 4. Fetch Expenses in Period
    const expensesRes = await pool.query(
      `SELECT id, expense_category, expense_type, amount, payment_mode, expense_date
       FROM expenses
       WHERE business_id = $1 AND (expense_date >= $2 AND expense_date <= $3)`,
      [businessId, startIso, endIso]
    );

    // 5. Fetch Catalog Items & Inventory
    const itemsRes = await pool.query(
      `SELECT id, name, sku, barcode, unit, category, purchase_price, selling_price, stock, min_stock_alert, item_number, item_code
       FROM items
       WHERE business_id = $1`,
      [businessId]
    );

    // 6. Fetch Parties (Customers & Suppliers)
    const partiesRes = await pool.query(
      `SELECT id, name, contact_number, party_type, opening_balance, balance_type, party_number, party_code
       FROM parties
       WHERE business_id = $1`,
      [businessId]
    );

    // 7. Fetch All-Time Open Balances for Receivables & Payables
    const allSalesDebtRes = await pool.query(
      `SELECT COALESCE(SUM(total_amount - received_amount), 0.0) as total_unpaid_sales
       FROM sales_orders
       WHERE business_id = $1 AND (total_amount > received_amount)`,
      [businessId]
    );
    const allPurchasesPayableRes = await pool.query(
      `SELECT COALESCE(SUM(total_amount), 0.0) as total_po_payables
       FROM purchase_orders
       WHERE business_id = $1`,
      [businessId]
    );

    // Build Fast Lookups
    const itemMap = new Map<string, any>();
    const itemNameMap = new Map<string, any>();
    for (const itm of itemsRes.rows) {
      if (itm.id) itemMap.set(itm.id, itm);
      if (itm.name) itemNameMap.set(itm.name.toLowerCase().trim(), itm);
    }

    const partyMap = new Map<string, any>();
    for (const p of partiesRes.rows) {
      if (p.id) partyMap.set(p.id, p);
    }

    // Process Sales Aggregations
    let grossSales = 0.0;
    let netSalesRealized = 0.0;
    let creditSales = 0.0;
    let totalGrossProfit = 0.0;
    const itemSalesAgg = new Map<string, { id: string; itemCode: string; name: string; unit: string; qtySold: number; totalRevenue: number; grossProfit: number }>();
    const customerSalesAgg = new Map<string, { partyId: string; partyCode: string; name: string; partyType: string; contactNumber: string; totalVolume: number; orderCount: number; balanceDue: number }>();

    const paymentModes: Record<string, number> = {
      Cash: 0.0,
      'UPI / Online': 0.0,
      Bank: 0.0,
      Credit: 0.0
    };

    const creditAging: Record<string, number> = {
      '0 - 15 Days': 0.0,
      '16 - 30 Days': 0.0,
      '31 - 60 Days': 0.0,
      '60+ Days': 0.0
    };

    let cashInHand = 0.0;
    let bankBalance = 0.0;

    for (const s of salesRes.rows) {
      const tot = parseFloat(s.total_amount) || 0.0;
      const rec = parseFloat(s.received_amount) || 0.0;
      const due = Math.max(0, tot - rec);
      const pMode = (s.payment_mode || 'Cash').trim();
      const pType = (s.payment_type || 'Cash').trim();

      grossSales += tot;
      netSalesRealized += rec;
      creditSales += due;

      // Cash & Bank
      if (pMode.toLowerCase() === 'cash' || pType.toLowerCase() === 'cash') {
        cashInHand += rec;
      } else if (pType.toLowerCase().includes('upi') || pType.toLowerCase().includes('online')) {
        bankBalance += rec;
      } else if (pType.toLowerCase().includes('bank') || pType.toLowerCase().includes('cheque')) {
        bankBalance += rec;
      }

      // Payment Modes Breakdown
      if (pMode.toLowerCase() === 'credit' && due > 0) {
        paymentModes['Credit'] += due;
        if (rec > 0) paymentModes['Cash'] += rec;
      } else if (pType.toLowerCase().includes('upi') || pType.toLowerCase().includes('online')) {
        paymentModes['UPI / Online'] += tot;
      } else if (pType.toLowerCase().includes('bank') || pType.toLowerCase().includes('cheque')) {
        paymentModes['Bank'] += tot;
      } else {
        paymentModes['Cash'] += tot;
      }

      // Credit Aging
      if (due > 0) {
        const saleDate = new Date(s.date || s.created_at);
        const ageDays = Math.floor((now.getTime() - saleDate.getTime()) / (1000 * 60 * 60 * 24));
        if (ageDays <= 15) creditAging['0 - 15 Days'] += due;
        else if (ageDays <= 30) creditAging['16 - 30 Days'] += due;
        else if (ageDays <= 60) creditAging['31 - 60 Days'] += due;
        else creditAging['60+ Days'] += due;
      }

      // Items parsing
      let itemsList: any[] = [];
      try {
        itemsList = typeof s.items_json === 'string' ? JSON.parse(s.items_json) : (s.items_json || []);
      } catch (e) {
        itemsList = [];
      }

      for (const item of itemsList) {
        const id = item.id || item.itemId || '';
        const name = (item.name || item.itemName || 'Unknown').trim();
        const qty = parseFloat(item.quantity || item.qty || 1);
        const rate = parseFloat(item.rate || item.sellingPrice || 0);
        const itemTot = parseFloat(item.total || item.amount || (qty * rate));

        const dbItem = itemMap.get(id) || itemNameMap.get(name.toLowerCase());
        const purchasePrice = parseFloat(dbItem?.purchase_price || 0);
        const profit = (rate - purchasePrice) * qty;
        totalGrossProfit += profit > 0 ? profit : (itemTot * 0.15); // Fallback 15%

        const key = id || name.toLowerCase();
        let agg = itemSalesAgg.get(key);
        if (!agg) {
          agg = {
            id: id,
            itemCode: dbItem?.item_code || '',
            name: name,
            unit: dbItem?.unit || item.unit || 'Pcs',
            qtySold: 0,
            totalRevenue: 0,
            grossProfit: 0
          };
          itemSalesAgg.set(key, agg);
        }
        agg.qtySold += qty;
        agg.totalRevenue += itemTot;
        agg.grossProfit += profit;
      }

      // Customer Sales
      const partyId = s.party_id || '';
      const cName = (s.customer_name || 'Walk-in Customer').trim();
      const pKey = partyId || cName.toLowerCase();
      const dbParty = partyMap.get(partyId);

      let pAgg = customerSalesAgg.get(pKey);
      if (!pAgg) {
        pAgg = {
          partyId: partyId,
          partyCode: dbParty?.party_code || '',
          name: cName,
          partyType: dbParty?.party_type || 'customer',
          contactNumber: dbParty?.contact_number || s.customer_phone || '',
          totalVolume: 0,
          orderCount: 0,
          balanceDue: 0
        };
        customerSalesAgg.set(pKey, pAgg);
      }
      pAgg.totalVolume += tot;
      pAgg.orderCount += 1;
      pAgg.balanceDue += due;
    }

    // Process Supplier Aggregations
    const supplierSalesAgg = new Map<string, { partyId: string; partyCode: string; name: string; partyType: string; contactNumber: string; totalVolume: number; orderCount: number; balanceDue: number }>();
    for (const po of purchasesRes.rows) {
      const tot = parseFloat(po.total_amount) || 0;
      const sName = (po.party_name || 'Supplier').trim();
      const sKey = po.party_id || sName.toLowerCase();
      const dbParty = partyMap.get(po.party_id);

      let sAgg = supplierSalesAgg.get(sKey);
      if (!sAgg) {
        sAgg = {
          partyId: po.party_id || '',
          partyCode: dbParty?.party_code || '',
          name: sName,
          partyType: 'supplier',
          contactNumber: dbParty?.contact_number || '',
          totalVolume: 0,
          orderCount: 0,
          balanceDue: 0
        };
        supplierSalesAgg.set(sKey, sAgg);
      }
      sAgg.totalVolume += tot;
      sAgg.orderCount += 1;
    }

    // Process Expenses
    let totalExpenses = 0.0;
    for (const exp of expensesRes.rows) {
      const amt = parseFloat(exp.amount) || 0.0;
      totalExpenses += amt;
    }
    cashInHand = Math.max(0, cashInHand - totalExpenses);

    // Total Receivables & Payables (including Opening Balances)
    let totalReceivables = parseFloat(allSalesDebtRes.rows[0]?.total_unpaid_sales || 0);
    let totalPayables = parseFloat(allPurchasesPayableRes.rows[0]?.total_po_payables || 0);

    for (const p of partiesRes.rows) {
      const opBal = parseFloat(p.opening_balance) || 0.0;
      if (p.balance_type === 'toReceive' && opBal > 0) totalReceivables += opBal;
      else if (p.balance_type === 'toPay' && opBal > 0) totalPayables += opBal;
    }

    // Margins & KPIs
    const invoicesCount = salesRes.rows.length;
    const aov = invoicesCount > 0 ? parseFloat((grossSales / invoicesCount).toFixed(2)) : 0.0;
    const salesGrowthPercent = prevPeriodSales > 0
      ? parseFloat((((grossSales - prevPeriodSales) / prevPeriodSales) * 100).toFixed(1))
      : (grossSales > 0 ? 100.0 : 0.0);

    const grossProfit = parseFloat(totalGrossProfit.toFixed(2));
    const grossMarginPercent = grossSales > 0 ? parseFloat(((grossProfit / grossSales) * 100).toFixed(1)) : 0.0;
    const netProfit = parseFloat((grossProfit - totalExpenses).toFixed(2));
    const netMarginPercent = grossSales > 0 ? parseFloat(((netProfit / grossSales) * 100).toFixed(1)) : 0.0;

    // Inventory Valuation & Health
    let totalStockValuationCost = 0.0;
    let potentialStockValuationSale = 0.0;
    let outOfStockCount = 0;
    let lowStockCount = 0;
    const outOfStockItems: any[] = [];
    const lowStockItems: any[] = [];
    const deadStockItems: any[] = [];

    const soldKeys = new Set(itemSalesAgg.keys());

    for (const itm of itemsRes.rows) {
      const stk = parseInt(itm.stock) || 0;
      const pPrice = parseFloat(itm.purchase_price) || 0;
      const sPrice = parseFloat(itm.selling_price) || 0;
      const minAlert = parseInt(itm.min_stock_alert) || 5;

      if (stk > 0) {
        totalStockValuationCost += (stk * pPrice);
        potentialStockValuationSale += (stk * sPrice);
      }

      const itmObj = {
        id: itm.id,
        itemCode: itm.item_code || '',
        name: itm.name,
        currentStock: stk,
        unit: itm.unit || 'Pcs',
        minAlert: minAlert,
        purchasePrice: pPrice,
        sellingPrice: sPrice,
        isOutOfStock: stk <= 0
      };

      if (stk <= 0) {
        outOfStockCount++;
        outOfStockItems.push(itmObj);
      } else if (stk <= minAlert) {
        lowStockCount++;
        lowStockItems.push(itmObj);
      }

      // Dead Stock: active stock > 0 but had 0 sales in period
      const hasSold = soldKeys.has(itm.id) || soldKeys.has(itm.name.toLowerCase().trim());
      if (!hasSold && stk > 0) {
        deadStockItems.push({
          id: itm.id,
          itemCode: itm.item_code || '',
          name: itm.name,
          unit: itm.unit || 'Pcs',
          currentStock: stk,
          purchasePrice: pPrice,
          lockedCapital: parseFloat((stk * pPrice).toFixed(2)),
          daysWithoutSale: Math.floor((end.getTime() - start.getTime()) / (1000 * 60 * 60 * 24))
        });
      }
    }

    deadStockItems.sort((a, b) => b.lockedCapital - a.lockedCapital);

    // Sorted Star Items
    const mostSellingItems = Array.from(itemSalesAgg.values())
      .sort((a, b) => b.qtySold - a.qtySold)
      .map(item => ({
        ...item,
        totalRevenue: parseFloat(item.totalRevenue.toFixed(2)),
        grossProfit: parseFloat(item.grossProfit.toFixed(2)),
        percentageShare: grossSales > 0 ? parseFloat(((item.totalRevenue / grossSales) * 100).toFixed(1)) : 0.0
      }));

    const topCustomers = Array.from(customerSalesAgg.values())
      .sort((a, b) => b.totalVolume - a.totalVolume)
      .map(c => ({
        ...c,
        totalVolume: parseFloat(c.totalVolume.toFixed(2)),
        balanceDue: parseFloat(c.balanceDue.toFixed(2))
      }));

    const topSuppliers = Array.from(supplierSalesAgg.values())
      .sort((a, b) => b.totalVolume - a.totalVolume)
      .map(s => ({
        ...s,
        totalVolume: parseFloat(s.totalVolume.toFixed(2))
      }));

    // Compute Daily/Monthly Trend Points for Spline Chart
    const daysCount = Math.floor((end.getTime() - start.getTime()) / (1000 * 60 * 60 * 24)) + 1;
    const trendPoints: any[] = [];
    const trendMap = new Map<string, { sales: number; purchases: number; expenses: number }>();

    const monthsShort = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];

    if (daysCount <= 31) {
      for (let i = 0; i < daysCount; i++) {
        const d = new Date(start.getTime() + (i * 24 * 60 * 60 * 1000));
        const key = d.toISOString().slice(0, 10);
        trendMap.set(key, { sales: 0, purchases: 0, expenses: 0 });
      }

      for (const s of salesRes.rows) {
        const key = new Date(s.date || s.created_at).toISOString().slice(0, 10);
        const pt = trendMap.get(key);
        if (pt) pt.sales += parseFloat(s.total_amount) || 0;
      }

      for (const po of purchasesRes.rows) {
        const key = new Date(po.date || po.created_at).toISOString().slice(0, 10);
        const pt = trendMap.get(key);
        if (pt) pt.purchases += parseFloat(po.total_amount) || 0;
      }

      for (const exp of expensesRes.rows) {
        const key = new Date(exp.expense_date).toISOString().slice(0, 10);
        const pt = trendMap.get(key);
        if (pt) pt.expenses += parseFloat(exp.amount) || 0;
      }

      for (const [key, val] of trendMap.entries()) {
        const d = new Date(key);
        trendPoints.push({
          date: key,
          dayLabel: `${d.getDate()} ${monthsShort[d.getMonth()]}`,
          sales: parseFloat(val.sales.toFixed(2)),
          purchases: parseFloat(val.purchases.toFixed(2)),
          expenses: parseFloat(val.expenses.toFixed(2))
        });
      }
    } else {
      let cursor = new Date(start.getFullYear(), start.getMonth(), 1);
      const endMonth = new Date(end.getFullYear(), end.getMonth(), 1);

      while (cursor <= endMonth) {
        const key = `${cursor.getFullYear()}-${String(cursor.getMonth() + 1).padStart(2, '0')}`;
        trendMap.set(key, { sales: 0, purchases: 0, expenses: 0 });
        cursor = new Date(cursor.getFullYear(), cursor.getMonth() + 1, 1);
      }

      for (const s of salesRes.rows) {
        const d = new Date(s.date || s.created_at);
        const key = `${d.getFullYear()}-${String(d.getMonth() + 1).padStart(2, '0')}`;
        const pt = trendMap.get(key);
        if (pt) pt.sales += parseFloat(s.total_amount) || 0;
      }

      for (const po of purchasesRes.rows) {
        const d = new Date(po.date || po.created_at);
        const key = `${d.getFullYear()}-${String(d.getMonth() + 1).padStart(2, '0')}`;
        const pt = trendMap.get(key);
        if (pt) pt.purchases += parseFloat(po.total_amount) || 0;
      }

      for (const exp of expensesRes.rows) {
        const d = new Date(exp.expense_date);
        const key = `${d.getFullYear()}-${String(d.getMonth() + 1).padStart(2, '0')}`;
        const pt = trendMap.get(key);
        if (pt) pt.expenses += parseFloat(exp.amount) || 0;
      }

      for (const [key, val] of trendMap.entries()) {
        const monthNum = parseInt(key.split('-')[1]) - 1;
        trendPoints.push({
          date: key,
          dayLabel: monthsShort[monthNum],
          sales: parseFloat(val.sales.toFixed(2)),
          purchases: parseFloat(val.purchases.toFixed(2)),
          expenses: parseFloat(val.expenses.toFixed(2))
        });
      }
    }

    return reply.send({
      success: true,
      timeframe: {
        startDate: startIso,
        endDate: endIso,
        daysCount: daysCount
      },
      kpis: {
        // Pillar 1: Sales & Revenue Velocity
        grossSales: parseFloat(grossSales.toFixed(2)),
        netSalesRealized: parseFloat(netSalesRealized.toFixed(2)),
        creditSales: parseFloat(creditSales.toFixed(2)),
        invoicesCount: invoicesCount,
        aov: aov,
        salesGrowthPercent: salesGrowthPercent,
        prevPeriodSales: parseFloat(prevPeriodSales.toFixed(2)),

        // Pillar 2: Working Capital & Liquidity
        youllGet: parseFloat(totalReceivables.toFixed(2)),
        youllGive: parseFloat(totalPayables.toFixed(2)),
        cashInHand: parseFloat(cashInHand.toFixed(2)),
        bankBalance: parseFloat(bankBalance.toFixed(2)),
        netWorkingCapital: parseFloat((totalReceivables - totalPayables).toFixed(2)),

        // Pillar 3: Profitability & Margins
        grossProfit: grossProfit,
        grossMarginPercent: grossMarginPercent,
        totalExpenses: parseFloat(totalExpenses.toFixed(2)),
        netProfit: netProfit,
        netMarginPercent: netMarginPercent,

        // Pillar 4: Inventory Assets & Stock Health
        totalStockValuationCost: parseFloat(totalStockValuationCost.toFixed(2)),
        potentialStockValuationSale: parseFloat(potentialStockValuationSale.toFixed(2)),
        totalItemsCount: itemsRes.rows.length,
        outOfStockCount: outOfStockCount,
        lowStockCount: lowStockCount,

        // Lists & Rankings
        mostSellingItems: mostSellingItems.slice(0, 10),
        leastSellingItems: deadStockItems.slice(0, 10),
        outOfStockItems: outOfStockItems.slice(0, 10),
        lowStockItems: lowStockItems.slice(0, 10),
        topCustomers: topCustomers.slice(0, 10),
        topSuppliers: topSuppliers.slice(0, 10),

        // Breakdowns & Trends
        paymentModeBreakdown: {
          Cash: parseFloat((paymentModes['Cash'] || 0).toFixed(2)),
          'UPI / Online': parseFloat((paymentModes['UPI / Online'] || 0).toFixed(2)),
          Bank: parseFloat((paymentModes['Bank'] || 0).toFixed(2)),
          Credit: parseFloat((paymentModes['Credit'] || 0).toFixed(2))
        },
        creditAging: {
          '0 - 15 Days': parseFloat((creditAging['0 - 15 Days'] || 0).toFixed(2)),
          '16 - 30 Days': parseFloat((creditAging['16 - 30 Days'] || 0).toFixed(2)),
          '31 - 60 Days': parseFloat((creditAging['31 - 60 Days'] || 0).toFixed(2)),
          '60+ Days': parseFloat((creditAging['60+ Days'] || 0).toFixed(2))
        },
        trendPoints: trendPoints
      }
    });
  } catch (error: any) {
    return reply.status(500).send({ success: false, message: error?.message || 'Failed to compute executive analytics.' });
  }
}

// =====================================================================
// 11. ITEM ANALYTICS HANDLER (ALL ITEMS VELOCITY & DEAD STOCK)
// =====================================================================
export async function getItemAnalyticsHandler(req: FastifyRequest, reply: FastifyReply) {
  try {
    const pool = getDbPool();
    const businessId = await resolveBusinessId(req);
    if (!businessId) {
      return reply.status(400).send({ success: false, message: 'Business ID is required.' });
    }

    const {
      startDate,
      endDate,
      category,
      search,
      type = 'all' // all, top, dead
    } = req.query as {
      startDate?: string;
      endDate?: string;
      category?: string;
      search?: string;
      type?: string;
    };

    const now = new Date();
    const startIso = (startDate ? new Date(startDate) : new Date(now.getFullYear(), now.getMonth(), 1)).toISOString().slice(0, 10);
    const endIso = (endDate ? new Date(endDate) : new Date(now.getFullYear(), now.getMonth() + 1, 0, 23, 59, 59)).toISOString().slice(0, 10);

    const itemsRes = await pool.query(
      `SELECT id, name, sku, barcode, unit, category, purchase_price, selling_price, stock, item_code
       FROM items
       WHERE business_id = $1`,
      [businessId]
    );

    const salesRes = await pool.query(
      `SELECT items_json, total_amount, date, created_at
       FROM sales_orders
       WHERE business_id = $1 AND (date >= $2 AND date <= $3)`,
      [businessId, startIso, endIso]
    );

    const itemMap = new Map<string, any>();
    for (const itm of itemsRes.rows) {
      itemMap.set(itm.id, itm);
    }

    const salesAgg = new Map<string, { qty: number; revenue: number; profit: number }>();
    let totalGrossSales = 0.0;

    for (const s of salesRes.rows) {
      totalGrossSales += parseFloat(s.total_amount) || 0;
      let list: any[] = [];
      try {
        list = typeof s.items_json === 'string' ? JSON.parse(s.items_json) : (s.items_json || []);
      } catch (e) {
        list = [];
      }

      for (const item of list) {
        const id = item.id || item.itemId || '';
        const name = (item.name || item.itemName || '').trim().toLowerCase();
        const key = id || name;
        const qty = parseFloat(item.quantity || item.qty || 1);
        const rate = parseFloat(item.rate || item.sellingPrice || 0);
        const tot = parseFloat(item.total || item.amount || (qty * rate));

        const dbItem = itemMap.get(id);
        const pPrice = parseFloat(dbItem?.purchase_price || 0);
        const prof = (rate - pPrice) * qty;

        const cur = salesAgg.get(key) || { qty: 0, revenue: 0, profit: 0 };
        cur.qty += qty;
        cur.revenue += tot;
        cur.profit += prof;
        salesAgg.set(key, cur);
      }
    }

    const q = (search || '').toLowerCase().trim();
    const resultItems: any[] = [];

    for (const itm of itemsRes.rows) {
      if (category && category !== 'ALL' && itm.category !== category) continue;
      if (q && !itm.name.toLowerCase().includes(q) && !(itm.item_code || '').toLowerCase().includes(q)) continue;

      const sold = salesAgg.get(itm.id) || salesAgg.get(itm.name.toLowerCase().trim()) || { qty: 0, revenue: 0, profit: 0 };
      const stk = parseInt(itm.stock) || 0;
      const pPrice = parseFloat(itm.purchase_price) || 0;
      const sPrice = parseFloat(itm.selling_price) || 0;

      const itemRecord = {
        id: itm.id,
        itemCode: itm.item_code || '',
        name: itm.name,
        category: itm.category || 'General',
        unit: itm.unit || 'Pcs',
        currentStock: stk,
        purchasePrice: pPrice,
        sellingPrice: sPrice,
        qtySold: sold.qty,
        totalRevenue: parseFloat(sold.revenue.toFixed(2)),
        grossProfit: parseFloat(sold.profit.toFixed(2)),
        percentageShare: totalGrossSales > 0 ? parseFloat(((sold.revenue / totalGrossSales) * 100).toFixed(1)) : 0.0,
        lockedCapital: parseFloat((stk * pPrice).toFixed(2)),
        isDeadStock: sold.qty === 0 && stk > 0
      };

      if (type === 'top' && sold.qty === 0) continue;
      if (type === 'dead' && !itemRecord.isDeadStock) continue;

      resultItems.push(itemRecord);
    }

    if (type === 'dead') {
      resultItems.sort((a, b) => b.lockedCapital - a.lockedCapital);
    } else {
      resultItems.sort((a, b) => b.qtySold - a.qtySold);
    }

    return reply.send({
      success: true,
      totalItems: resultItems.length,
      totalGrossSales: parseFloat(totalGrossSales.toFixed(2)),
      items: resultItems
    });
  } catch (error: any) {
    return reply.status(500).send({ success: false, message: error?.message || 'Failed to fetch item analytics.' });
  }
}

// =====================================================================
// 12. PARTY ANALYTICS HANDLER (CUSTOMERS, SUPPLIERS & AGING)
// =====================================================================
export async function getPartyAnalyticsHandler(req: FastifyRequest, reply: FastifyReply) {
  try {
    const pool = getDbPool();
    const businessId = await resolveBusinessId(req);
    if (!businessId) {
      return reply.status(400).send({ success: false, message: 'Business ID is required.' });
    }

    const {
      startDate,
      endDate,
      type = 'customer',
      search
    } = req.query as {
      startDate?: string;
      endDate?: string;
      type?: string;
      search?: string;
    };

    const now = new Date();
    const startIso = (startDate ? new Date(startDate) : new Date(now.getFullYear(), now.getMonth(), 1)).toISOString().slice(0, 10);
    const endIso = (endDate ? new Date(endDate) : new Date(now.getFullYear(), now.getMonth() + 1, 0, 23, 59, 59)).toISOString().slice(0, 10);

    const partiesRes = await pool.query(
      `SELECT id, name, contact_number, party_type, opening_balance, balance_type, party_number, party_code
       FROM parties
       WHERE business_id = $1`,
      [businessId]
    );

    const q = (search || '').toLowerCase().trim();
    const partyResults: any[] = [];

    if (type === 'supplier') {
      const poRes = await pool.query(
        `SELECT party_id, party_name, total_amount
         FROM purchase_orders
         WHERE business_id = $1 AND (date >= $2 AND date <= $3)`,
        [businessId, startIso, endIso]
      );

      const supplierMap = new Map<string, { volume: number; orders: number }>();
      for (const po of poRes.rows) {
        const key = po.party_id || (po.party_name || '').toLowerCase().trim();
        const cur = supplierMap.get(key) || { volume: 0, orders: 0 };
        cur.volume += parseFloat(po.total_amount) || 0;
        cur.orders += 1;
        supplierMap.set(key, cur);
      }

      for (const p of partiesRes.rows) {
        if (p.party_type !== 'supplier') continue;
        if (q && !p.name.toLowerCase().includes(q) && !(p.party_code || '').toLowerCase().includes(q)) continue;

        const stat = supplierMap.get(p.id) || supplierMap.get(p.name.toLowerCase().trim()) || { volume: 0, orders: 0 };
        partyResults.push({
          partyId: p.id,
          partyCode: p.party_code || '',
          name: p.name,
          partyType: 'supplier',
          contactNumber: p.contact_number || '',
          totalVolume: parseFloat(stat.volume.toFixed(2)),
          orderCount: stat.orders,
          balanceDue: p.balance_type === 'toPay' ? parseFloat(p.opening_balance || 0) : 0
        });
      }
      partyResults.sort((a, b) => b.totalVolume - a.totalVolume);
    } else {
      // Customer
      const salesRes = await pool.query(
        `SELECT party_id, customer_name, total_amount, received_amount, date, created_at
         FROM sales_orders
         WHERE business_id = $1 AND (date >= $2 AND date <= $3)`,
        [businessId, startIso, endIso]
      );

      const customerMap = new Map<string, { volume: number; orders: number; due: number }>();
      for (const s of salesRes.rows) {
        const key = s.party_id || (s.customer_name || '').toLowerCase().trim();
        const tot = parseFloat(s.total_amount) || 0;
        const rec = parseFloat(s.received_amount) || 0;
        const cur = customerMap.get(key) || { volume: 0, orders: 0, due: 0 };
        cur.volume += tot;
        cur.orders += 1;
        cur.due += Math.max(0, tot - rec);
        customerMap.set(key, cur);
      }

      for (const p of partiesRes.rows) {
        if (p.party_type === 'supplier') continue;
        if (q && !p.name.toLowerCase().includes(q) && !(p.party_code || '').toLowerCase().includes(q)) continue;

        const stat = customerMap.get(p.id) || customerMap.get(p.name.toLowerCase().trim()) || { volume: 0, orders: 0, due: 0 };
        const opDue = p.balance_type === 'toReceive' ? parseFloat(p.opening_balance || 0) : 0;

        partyResults.push({
          partyId: p.id,
          partyCode: p.party_code || '',
          name: p.name,
          partyType: p.party_type || 'customer',
          contactNumber: p.contact_number || '',
          totalVolume: parseFloat(stat.volume.toFixed(2)),
          orderCount: stat.orders,
          balanceDue: parseFloat((stat.due + opDue).toFixed(2))
        });
      }
      partyResults.sort((a, b) => b.totalVolume - a.totalVolume);
    }

    return reply.send({
      success: true,
      totalParties: partyResults.length,
      parties: partyResults
    });
  } catch (error: any) {
    return reply.status(500).send({ success: false, message: error?.message || 'Failed to fetch party analytics.' });
  }
}

// =====================================================================
// 13. INVENTORY HEALTH & REORDER RECOMMENDATIONS HANDLER
// =====================================================================
export async function getInventoryHealthHandler(req: FastifyRequest, reply: FastifyReply) {
  try {
    const pool = getDbPool();
    const businessId = await resolveBusinessId(req);
    if (!businessId) {
      return reply.status(400).send({ success: false, message: 'Business ID is required.' });
    }

    const itemsRes = await pool.query(
      `SELECT id, name, sku, barcode, unit, category, purchase_price, selling_price, stock, min_stock_alert, item_code
       FROM items
       WHERE business_id = $1
       ORDER BY stock ASC`,
      [businessId]
    );

    let totalStockValuationCost = 0.0;
    let potentialStockValuationSale = 0.0;
    const outOfStockItems: any[] = [];
    const lowStockItems: any[] = [];
    const healthyItems: any[] = [];

    for (const itm of itemsRes.rows) {
      const stk = parseInt(itm.stock) || 0;
      const pPrice = parseFloat(itm.purchase_price) || 0;
      const sPrice = parseFloat(itm.selling_price) || 0;
      const minAlert = parseInt(itm.min_stock_alert) || 5;

      if (stk > 0) {
        totalStockValuationCost += (stk * pPrice);
        potentialStockValuationSale += (stk * sPrice);
      }

      const record = {
        id: itm.id,
        itemCode: itm.item_code || '',
        name: itm.name,
        category: itm.category || 'General',
        unit: itm.unit || 'Pcs',
        currentStock: stk,
        minAlert: minAlert,
        purchasePrice: pPrice,
        sellingPrice: sPrice,
        isOutOfStock: stk <= 0,
        reorderDeficit: Math.max(0, minAlert - stk)
      };

      if (stk <= 0) {
        outOfStockItems.push(record);
      } else if (stk <= minAlert) {
        lowStockItems.push(record);
      } else {
        healthyItems.push(record);
      }
    }

    return reply.send({
      success: true,
      summary: {
        totalItemsCount: itemsRes.rows.length,
        totalStockValuationCost: parseFloat(totalStockValuationCost.toFixed(2)),
        potentialStockValuationSale: parseFloat(potentialStockValuationSale.toFixed(2)),
        potentialProfitMargin: parseFloat((potentialStockValuationSale - totalStockValuationCost).toFixed(2)),
        outOfStockCount: outOfStockItems.length,
        lowStockCount: lowStockItems.length,
        healthyStockCount: healthyItems.length
      },
      outOfStockItems,
      lowStockItems
    });
  } catch (error: any) {
    return reply.status(500).send({ success: false, message: error?.message || 'Failed to fetch inventory health.' });
  }
}

// =====================================================================
// 14. ALL TRANSACTIONS ENGINE (Unified Sales, Purchases, Payments, Expenses)
// =====================================================================
export async function getAllTransactionsHandler(req: FastifyRequest, reply: FastifyReply) {
  try {
    const pool = getDbPool();
    const businessId = await resolveBusinessId(req);
    if (!businessId) {
      return reply.status(400).send({ success: false, message: 'Business ID is required.' });
    }

    const { startDate, endDate, partyId, txnType } = req.query as {
      startDate?: string;
      endDate?: string;
      partyId?: string;
      txnType?: string;
    };

    const now = new Date();
    const start = startDate ? new Date(startDate) : new Date(now.getFullYear(), now.getMonth(), 1);
    const end = endDate ? new Date(endDate + 'T23:59:59.999Z') : new Date(now.getFullYear(), now.getMonth() + 1, 0, 23, 59, 59, 999);
    const startStr = start.toISOString().split('T')[0];
    const endStr = end.toISOString().split('T')[0];

    const transactions: any[] = [];

    // 1. Fetch Sales Orders
    if (!txnType || txnType === 'All Transactions' || txnType.toLowerCase() === 'sale') {
      let salesQuery = `SELECT id, invoice_no, date, created_at, customer_name, total_amount, received_amount, party_id 
                        FROM sales_orders 
                        WHERE business_id = $1 
                          AND ((date >= $2 AND date <= $3) OR (date IS NULL AND created_at >= $2::date AND created_at <= ($3 || ' 23:59:59')::timestamp))`;
      const salesParams: any[] = [businessId, startStr, endStr];
      if (partyId) {
        salesParams.push(partyId);
        salesQuery += ` AND party_id = $${salesParams.length}`;
      }
      salesQuery += ` ORDER BY date DESC, invoice_no DESC`;

      const salesRes = await pool.query(salesQuery, salesParams);
      for (const s of salesRes.rows) {
        const tot = parseFloat(s.total_amount || 0);
        const rec = parseFloat(s.received_amount || 0);
        transactions.push({
          id: s.id,
          partyName: s.customer_name || 'Cash Customer',
          date: s.date ? new Date(s.date).toISOString().split('T')[0] : (s.created_at ? new Date(s.created_at).toISOString().split('T')[0] : startStr),
          type: 'Sale',
          txnNumber: s.invoice_no,
          total: tot,
          balance: Math.max(0, tot - rec),
          partyId: s.party_id
        });
      }
    }

    // 2. Fetch Purchase Orders
    if (!txnType || txnType === 'All Transactions' || txnType.toLowerCase() === 'purchase') {
      let poQuery = `SELECT id, order_no, date, created_at, party_name, total_amount, party_id 
                     FROM purchase_orders 
                     WHERE business_id = $1 
                       AND ((date >= $2 AND date <= $3) OR (date IS NULL AND created_at >= $2::date AND created_at <= ($3 || ' 23:59:59')::timestamp))`;
      const poParams: any[] = [businessId, startStr, endStr];
      if (partyId) {
        poParams.push(partyId);
        poQuery += ` AND party_id = $${poParams.length}`;
      }
      poQuery += ` ORDER BY date DESC, order_no DESC`;

      const poRes = await pool.query(poQuery, poParams);
      for (const p of poRes.rows) {
        const tot = parseFloat(p.total_amount || 0);
        transactions.push({
          id: p.id,
          partyName: p.party_name || 'Supplier',
          date: p.date ? new Date(p.date).toISOString().split('T')[0] : (p.created_at ? new Date(p.created_at).toISOString().split('T')[0] : startStr),
          type: 'Purchase',
          txnNumber: p.order_no,
          total: tot,
          balance: 0,
          partyId: p.party_id
        });
      }
    }

    // 3. Fetch Payments (Payment-In and Payment-Out)
    if (!txnType || txnType === 'All Transactions' || txnType.toLowerCase().includes('payment')) {
      let payQuery = `SELECT id, receipt_no, date, created_at, party_name, received_amount, is_payment_out, party_id 
                      FROM payments 
                      WHERE business_id = $1 
                        AND ((date >= $2 AND date <= $3) OR (date IS NULL AND created_at >= $2::date AND created_at <= ($3 || ' 23:59:59')::timestamp))`;
      const payParams: any[] = [businessId, startStr, endStr];
      if (partyId) {
        payParams.push(partyId);
        payQuery += ` AND party_id = $${payParams.length}`;
      }
      payQuery += ` ORDER BY receipt_no DESC`;

      const payRes = await pool.query(payQuery, payParams);
      for (const pay of payRes.rows) {
        const isOut = pay.is_payment_out === 1;
        const pType = isOut ? 'Payment-Out' : 'Payment-In';
        if (txnType && txnType !== 'All Transactions' && txnType !== pType) continue;

        const amt = parseFloat(pay.received_amount || 0);
        transactions.push({
          id: pay.id,
          partyName: pay.party_name || (isOut ? 'Supplier' : 'Customer'),
          date: pay.date ? new Date(pay.date).toISOString().split('T')[0] : (pay.created_at ? new Date(pay.created_at).toISOString().split('T')[0] : startStr),
          type: pType,
          txnNumber: pay.receipt_no,
          total: amt,
          balance: 0,
          partyId: pay.party_id
        });
      }
    }

    // Sort descending by date
    transactions.sort((a, b) => b.date.localeCompare(a.date));

    const totalVolume = transactions.reduce((s, t) => s + t.total, 0);
    const totalBalance = transactions.reduce((s, t) => s + t.balance, 0);

    return reply.send({
      success: true,
      count: transactions.length,
      dateRange: { start: startStr, end: endStr },
      summary: {
        totalTransactions: transactions.length,
        totalAmount: parseFloat(totalVolume.toFixed(2)),
        totalBalanceDue: parseFloat(totalBalance.toFixed(2))
      },
      transactions
    });
  } catch (error: any) {
    return reply.status(500).send({ success: false, message: error?.message || 'Failed to fetch all transactions.' });
  }
}

