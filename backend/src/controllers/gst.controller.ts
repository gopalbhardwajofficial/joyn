import { FastifyRequest, FastifyReply } from 'fastify';
import { getDbPool } from '../db/connection.js';

function toValidUuidOrNull(val: any): string | null {
  if (typeof val !== 'string' || !val) return null;
  const uuidRegex = /^[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i;
  return uuidRegex.test(val) ? val : null;
}

function parseItems(itemsJson: any): any[] {
  if (!itemsJson) return [];
  if (Array.isArray(itemsJson)) return itemsJson;
  if (typeof itemsJson === 'string') {
    try {
      const parsed = JSON.parse(itemsJson);
      return Array.isArray(parsed) ? parsed : [];
    } catch {
      return [];
    }
  }
  return [];
}

function getDateRange(query: any): { start: Date; end: Date } {
  const now = new Date();
  const start = query?.startDate
    ? new Date(query.startDate)
    : new Date(now.getFullYear(), now.getMonth(), 1);
  const end = query?.endDate
    ? new Date(query.endDate + 'T23:59:59.999Z')
    : new Date(now.getFullYear(), now.getMonth() + 1, 0, 23, 59, 59, 999);
  return { start, end };
}

// ============================================================================
// 1. GSTR-1 OUTWARD SUPPLIES RETURN ENGINE
// ============================================================================
export async function getGstr1Handler(req: FastifyRequest, reply: FastifyReply) {
  try {
    const activeBusinessId = (req as any).businessAccess?.businessId || (req.headers['x-business-id'] as string) || (req.query as any)?.businessId;
    if (!activeBusinessId) {
      return reply.status(400).send({ success: false, message: 'x-business-id is required.' });
    }

    const { start, end } = getDateRange(req.query);
    const pool = getDbPool();

    // 1. Fetch Business Profile for State & GSTIN
    const bizRes = await pool.query(
      `SELECT state, gst_number, business_name FROM business_profile WHERE id = $1 LIMIT 1`,
      [activeBusinessId]
    );
    const biz = bizRes.rows[0] || {};
    const bizState = (biz.state || 'Delhi').trim().toLowerCase();

    // 2. Fetch Sales Orders for Date Range with Party Details
    const salesRes = await pool.query(
      `SELECT so.id, so.invoice_no, so.date, so.party_id, so.customer_name, so.customer_phone,
              so.items_json, so.total_amount, so.received_amount, so.payment_type,
              so.state_of_supply, so.is_one_time_customer, so.created_at,
              p.gst_number as party_gst, p.city as party_city, p.address as party_address
       FROM sales_orders so
       LEFT JOIN parties p ON so.party_id = p.id
       WHERE so.business_id = $1 
         AND so.date >= $2 AND so.date <= $3
       ORDER BY so.date DESC, so.invoice_no DESC`,
      [activeBusinessId, start.toISOString().split('T')[0], end.toISOString().split('T')[0]]
    );

    let totalTaxableValue = 0;
    let totalCgst = 0;
    let totalSgst = 0;
    let totalIgst = 0;
    let totalInvoiceValue = 0;

    const b2bInvoices: any[] = [];
    const b2cLargeInvoices: any[] = [];
    let b2cSmallCount = 0;
    let b2cSmallTaxable = 0;
    let b2cSmallCgst = 0;
    let b2cSmallSgst = 0;
    let b2cSmallIgst = 0;
    let b2cSmallTotal = 0;

    const hsnMap: { [key: string]: any } = {};
    const rateMap: { [key: string]: any } = {
      '0': { rate: 0, taxableValue: 0, cgst: 0, sgst: 0, igst: 0 },
      '5': { rate: 5, taxableValue: 0, cgst: 0, sgst: 0, igst: 0 },
      '12': { rate: 12, taxableValue: 0, cgst: 0, sgst: 0, igst: 0 },
      '18': { rate: 18, taxableValue: 0, cgst: 0, sgst: 0, igst: 0 },
      '28': { rate: 28, taxableValue: 0, cgst: 0, sgst: 0, igst: 0 }
    };

    for (const order of salesRes.rows) {
      const orderTotal = parseFloat(order.total_amount || 0);
      totalInvoiceValue += orderTotal;

      const items = parseItems(order.items_json);
      const isInterState = order.state_of_supply
        ? order.state_of_supply.trim().toLowerCase() !== bizState
        : false;

      let orderTaxable = 0;
      let orderCgst = 0;
      let orderSgst = 0;
      let orderIgst = 0;

      for (const itm of items) {
        const qty = parseFloat(itm.quantity || itm.qty || 1);
        const rate = parseFloat(itm.rate || itm.sellingPrice || itm.price || 0);
        const taxRate = parseFloat(itm.taxRatePercent || itm.tax_rate_percent || 0);
        const discount = parseFloat(itm.discount || 0);
        const lineItemRaw = (qty * rate) - discount;
        const lineTaxable = itm.salePriceTaxMode === 'withTax'
          ? (lineItemRaw / (1 + (taxRate / 100)))
          : lineItemRaw;

        const lineTax = (lineTaxable * taxRate) / 100;
        let lineCgst = 0;
        let lineSgst = 0;
        let lineIgst = 0;

        if (isInterState) {
          lineIgst = lineTax;
        } else {
          lineCgst = lineTax / 2;
          lineSgst = lineTax / 2;
        }

        orderTaxable += lineTaxable;
        orderCgst += lineCgst;
        orderSgst += lineSgst;
        orderIgst += lineIgst;

        // Aggregate HSN
        const hsnCode = (itm.hsnSac || itm.hsn_sac || itm.hsnCode || 'N/A').toString().trim() || 'N/A';
        if (!hsnMap[hsnCode]) {
          hsnMap[hsnCode] = {
            hsnCode,
            description: itm.name || 'Goods',
            unit: itm.unit || 'PCS',
            totalQuantity: 0,
            taxableValue: 0,
            taxRatePercent: taxRate,
            cgst: 0,
            sgst: 0,
            igst: 0,
            totalValue: 0
          };
        }
        hsnMap[hsnCode].totalQuantity += qty;
        hsnMap[hsnCode].taxableValue += lineTaxable;
        hsnMap[hsnCode].cgst += lineCgst;
        hsnMap[hsnCode].sgst += lineSgst;
        hsnMap[hsnCode].igst += lineIgst;
        hsnMap[hsnCode].totalValue += (lineTaxable + lineTax);

        // Aggregate Rate slab
        const rateKey = taxRate.toString();
        if (!rateMap[rateKey]) {
          rateMap[rateKey] = { rate: taxRate, taxableValue: 0, cgst: 0, sgst: 0, igst: 0 };
        }
        rateMap[rateKey].taxableValue += lineTaxable;
        rateMap[rateKey].cgst += lineCgst;
        rateMap[rateKey].sgst += lineSgst;
        rateMap[rateKey].igst += lineIgst;
      }

      totalTaxableValue += orderTaxable;
      totalCgst += orderCgst;
      totalSgst += orderSgst;
      totalIgst += orderIgst;

      const hasGstin = Boolean(order.party_gst && order.party_gst.length >= 10);
      const isOneTime = Boolean(order.is_one_time_customer);

      if (hasGstin && !isOneTime) {
        // Section 4: B2B Invoice
        b2bInvoices.push({
          id: order.id,
          invoiceNo: order.invoice_no,
          date: order.date,
          customerName: order.customer_name || 'Registered Customer',
          customerGstin: order.party_gst,
          stateOfSupply: order.state_of_supply || biz.state || 'Local',
          taxableValue: parseFloat(orderTaxable.toFixed(2)),
          cgst: parseFloat(orderCgst.toFixed(2)),
          sgst: parseFloat(orderSgst.toFixed(2)),
          igst: parseFloat(orderIgst.toFixed(2)),
          totalAmount: orderTotal
        });
      } else if (isInterState && orderTotal > 250000) {
        // Section 5: B2C Large
        b2cLargeInvoices.push({
          id: order.id,
          invoiceNo: order.invoice_no,
          date: order.date,
          customerName: order.customer_name || 'Unregistered Buyer',
          stateOfSupply: order.state_of_supply || 'Interstate',
          taxableValue: parseFloat(orderTaxable.toFixed(2)),
          igst: parseFloat(orderIgst.toFixed(2)),
          totalAmount: orderTotal
        });
      } else {
        // Section 7: B2C Small
        b2cSmallCount++;
        b2cSmallTaxable += orderTaxable;
        b2cSmallCgst += orderCgst;
        b2cSmallSgst += orderSgst;
        b2cSmallIgst += orderIgst;
        b2cSmallTotal += orderTotal;
      }
    }

    const hsnSummaryList = Object.values(hsnMap).map((h: any) => ({
      hsnCode: h.hsnCode,
      description: h.description,
      unit: h.unit,
      totalQuantity: parseFloat(h.totalQuantity.toFixed(2)),
      taxableValue: parseFloat(h.taxableValue.toFixed(2)),
      taxRatePercent: h.taxRatePercent,
      cgst: parseFloat(h.cgst.toFixed(2)),
      sgst: parseFloat(h.sgst.toFixed(2)),
      igst: parseFloat(h.igst.toFixed(2)),
      totalValue: parseFloat(h.totalValue.toFixed(2))
    })).sort((a, b) => b.taxableValue - a.taxableValue);

    const rateWiseList = Object.values(rateMap).map((r: any) => ({
      rate: r.rate,
      taxableValue: parseFloat(r.taxableValue.toFixed(2)),
      cgst: parseFloat(r.cgst.toFixed(2)),
      sgst: parseFloat(r.sgst.toFixed(2)),
      igst: parseFloat(r.igst.toFixed(2)),
      totalTax: parseFloat((r.cgst + r.sgst + r.igst).toFixed(2))
    })).filter((r: any) => r.taxableValue > 0 || [5, 12, 18, 28].includes(r.rate));

    return reply.send({
      success: true,
      reportType: 'GSTR-1',
      businessName: biz.business_name || '',
      businessGstin: biz.gst_number || '',
      dateRange: { start: start.toISOString().split('T')[0], end: end.toISOString().split('T')[0] },
      summary: {
        totalInvoices: salesRes.rows.length,
        totalTaxableValue: parseFloat(totalTaxableValue.toFixed(2)),
        totalCgst: parseFloat(totalCgst.toFixed(2)),
        totalSgst: parseFloat(totalSgst.toFixed(2)),
        totalIgst: parseFloat(totalIgst.toFixed(2)),
        totalTaxLiability: parseFloat((totalCgst + totalSgst + totalIgst).toFixed(2)),
        totalInvoiceValue: parseFloat(totalInvoiceValue.toFixed(2))
      },
      b2bSummary: {
        count: b2bInvoices.length,
        invoices: b2bInvoices
      },
      b2cLargeSummary: {
        count: b2cLargeInvoices.length,
        invoices: b2cLargeInvoices
      },
      b2cSmallSummary: {
        count: b2cSmallCount,
        taxableValue: parseFloat(b2cSmallTaxable.toFixed(2)),
        cgst: parseFloat(b2cSmallCgst.toFixed(2)),
        sgst: parseFloat(b2cSmallSgst.toFixed(2)),
        igst: parseFloat(b2cSmallIgst.toFixed(2)),
        totalAmount: parseFloat(b2cSmallTotal.toFixed(2))
      },
      hsnSummary: hsnSummaryList,
      rateWiseBreakup: rateWiseList
    });
  } catch (error: any) {
    console.error('GSTR-1 Error:', error);
    return reply.status(500).send({ success: false, message: error?.message || 'Failed to generate GSTR-1.' });
  }
}

// ============================================================================
// 2. GSTR-2 INWARD SUPPLIES (PURCHASES ITC) RETURN ENGINE
// ============================================================================
export async function getGstr2Handler(req: FastifyRequest, reply: FastifyReply) {
  try {
    const activeBusinessId = (req as any).businessAccess?.businessId || (req.headers['x-business-id'] as string) || (req.query as any)?.businessId;
    if (!activeBusinessId) {
      return reply.status(400).send({ success: false, message: 'x-business-id is required.' });
    }

    const { start, end } = getDateRange(req.query);
    const pool = getDbPool();

    const bizRes = await pool.query(
      `SELECT state, gst_number, business_name FROM business_profile WHERE id = $1 LIMIT 1`,
      [activeBusinessId]
    );
    const biz = bizRes.rows[0] || {};
    const bizState = (biz.state || 'Delhi').trim().toLowerCase();

    // Query Purchases
    const purchasesRes = await pool.query(
      `SELECT po.id, po.order_no, po.date, po.party_name, po.party_id, po.items_json, po.total_amount,
              p.gst_number as supplier_gst, p.city as supplier_city
       FROM purchase_orders po
       LEFT JOIN parties p ON po.party_id = p.id
       WHERE po.business_id = $1 
         AND po.date >= $2 AND po.date <= $3
       ORDER BY po.date DESC, po.order_no DESC`,
      [activeBusinessId, start.toISOString().split('T')[0], end.toISOString().split('T')[0]]
    );

    let totalPurchaseAmount = 0;
    let totalTaxablePurchase = 0;
    let itcCgst = 0;
    let itcSgst = 0;
    let itcIgst = 0;

    const purchaseInvoices: any[] = [];

    for (const po of purchasesRes.rows) {
      const orderTotal = parseFloat(po.total_amount || 0);
      totalPurchaseAmount += orderTotal;

      const items = parseItems(po.items_json);
      let orderTaxable = 0;
      let orderCgst = 0;
      let orderSgst = 0;
      let orderIgst = 0;

      for (const itm of items) {
        const qty = parseFloat(itm.quantity || itm.qty || 1);
        const price = parseFloat(itm.purchasePrice || itm.rate || itm.price || 0);
        const taxRate = parseFloat(itm.taxRatePercent || itm.tax_rate_percent || 0);
        const lineItemRaw = qty * price;
        const lineTaxable = itm.purchasePriceTaxMode === 'withTax'
          ? (lineItemRaw / (1 + (taxRate / 100)))
          : lineItemRaw;

        const lineTax = (lineTaxable * taxRate) / 100;
        const isInterState = po.supplier_city && !po.supplier_city.toLowerCase().includes(bizState);

        orderTaxable += lineTaxable;
        if (isInterState) {
          orderIgst += lineTax;
        } else {
          orderCgst += lineTax / 2;
          orderSgst += lineTax / 2;
        }
      }

      totalTaxablePurchase += orderTaxable;
      itcCgst += orderCgst;
      itcSgst += orderSgst;
      itcIgst += orderIgst;

      purchaseInvoices.push({
        id: po.id,
        orderNo: po.order_no,
        date: po.date,
        supplierName: po.party_name || 'Vendor',
        supplierGstin: po.supplier_gst || 'Unregistered',
        taxableValue: parseFloat(orderTaxable.toFixed(2)),
        itcCgst: parseFloat(orderCgst.toFixed(2)),
        itcSgst: parseFloat(orderSgst.toFixed(2)),
        itcIgst: parseFloat(orderIgst.toFixed(2)),
        totalItc: parseFloat((orderCgst + orderSgst + orderIgst).toFixed(2)),
        totalAmount: orderTotal
      });
    }

    const totalEligibleItc = itcCgst + itcSgst + itcIgst;

    return reply.send({
      success: true,
      reportType: 'GSTR-2',
      businessName: biz.business_name || '',
      businessGstin: biz.gst_number || '',
      dateRange: { start: start.toISOString().split('T')[0], end: end.toISOString().split('T')[0] },
      summary: {
        totalPurchaseOrders: purchasesRes.rows.length,
        totalPurchaseAmount: parseFloat(totalPurchaseAmount.toFixed(2)),
        totalTaxablePurchase: parseFloat(totalTaxablePurchase.toFixed(2)),
        eligibleItcCgst: parseFloat(itcCgst.toFixed(2)),
        eligibleItcSgst: parseFloat(itcSgst.toFixed(2)),
        eligibleItcIgst: parseFloat(itcIgst.toFixed(2)),
        totalEligibleItc: parseFloat(totalEligibleItc.toFixed(2))
      },
      inwardSupplies: purchaseInvoices
    });
  } catch (error: any) {
    console.error('GSTR-2 Error:', error);
    return reply.status(500).send({ success: false, message: error?.message || 'Failed to generate GSTR-2.' });
  }
}

// ============================================================================
// 3. GSTR-3B MONTHLY SUMMARY RETURN ENGINE
// ============================================================================
export async function getGstr3bHandler(req: FastifyRequest, reply: FastifyReply) {
  try {
    const activeBusinessId = (req as any).businessAccess?.businessId || (req.headers['x-business-id'] as string) || (req.query as any)?.businessId;
    if (!activeBusinessId) {
      return reply.status(400).send({ success: false, message: 'x-business-id is required.' });
    }

    const { start, end } = getDateRange(req.query);
    const pool = getDbPool();

    // 1. Fetch Sales (Outward Supplies Tax Liability)
    const salesRes = await pool.query(
      `SELECT total_amount, items_json, state_of_supply FROM sales_orders 
       WHERE business_id = $1 AND date >= $2 AND date <= $3`,
      [activeBusinessId, start.toISOString().split('T')[0], end.toISOString().split('T')[0]]
    );

    let outwardTaxable = 0;
    let outwardCgst = 0;
    let outwardSgst = 0;
    let outwardIgst = 0;

    for (const s of salesRes.rows) {
      const items = parseItems(s.items_json);
      for (const itm of items) {
        const qty = parseFloat(itm.quantity || itm.qty || 1);
        const rate = parseFloat(itm.rate || itm.sellingPrice || itm.price || 0);
        const taxRate = parseFloat(itm.taxRatePercent || itm.tax_rate_percent || 0);
        const raw = qty * rate;
        const lineTaxable = itm.salePriceTaxMode === 'withTax' ? (raw / (1 + (taxRate / 100))) : raw;
        const lineTax = (lineTaxable * taxRate) / 100;

        outwardTaxable += lineTaxable;
        outwardCgst += lineTax / 2;
        outwardSgst += lineTax / 2;
      }
    }

    // 2. Fetch Purchases (Eligible Input Tax Credit - ITC)
    const purchaseRes = await pool.query(
      `SELECT total_amount, items_json FROM purchase_orders 
       WHERE business_id = $1 AND date >= $2 AND date <= $3`,
      [activeBusinessId, start.toISOString().split('T')[0], end.toISOString().split('T')[0]]
    );

    let inwardTaxable = 0;
    let itcCgst = 0;
    let itcSgst = 0;
    let itcIgst = 0;

    for (const p of purchaseRes.rows) {
      const items = parseItems(p.items_json);
      for (const itm of items) {
        const qty = parseFloat(itm.quantity || itm.qty || 1);
        const price = parseFloat(itm.purchasePrice || itm.rate || itm.price || 0);
        const taxRate = parseFloat(itm.taxRatePercent || itm.tax_rate_percent || 0);
        const raw = qty * price;
        const lineTaxable = itm.purchasePriceTaxMode === 'withTax' ? (raw / (1 + (taxRate / 100))) : raw;
        const lineTax = (lineTaxable * taxRate) / 100;

        inwardTaxable += lineTaxable;
        itcCgst += lineTax / 2;
        itcSgst += lineTax / 2;
      }
    }

    // 3. Net Tax Payable Calculation
    const totalOutwardTax = outwardCgst + outwardSgst + outwardIgst;
    const totalItc = itcCgst + itcSgst + itcIgst;

    const netCgstPayable = Math.max(0, outwardCgst - itcCgst);
    const netSgstPayable = Math.max(0, outwardSgst - itcSgst);
    const netIgstPayable = Math.max(0, outwardIgst - itcIgst);
    const netTaxPayable = netCgstPayable + netSgstPayable + netIgstPayable;

    const excessItcCarriedForward = Math.max(0, totalItc - totalOutwardTax);

    return reply.send({
      success: true,
      reportType: 'GSTR-3B',
      dateRange: { start: start.toISOString().split('T')[0], end: end.toISOString().split('T')[0] },
      outwardSupplies: {
        taxableTurnover: parseFloat(outwardTaxable.toFixed(2)),
        cgst: parseFloat(outwardCgst.toFixed(2)),
        sgst: parseFloat(outwardSgst.toFixed(2)),
        igst: parseFloat(outwardIgst.toFixed(2)),
        totalTaxLiability: parseFloat(totalOutwardTax.toFixed(2))
      },
      eligibleItc: {
        taxablePurchases: parseFloat(inwardTaxable.toFixed(2)),
        itcCgst: parseFloat(itcCgst.toFixed(2)),
        itcSgst: parseFloat(itcSgst.toFixed(2)),
        itcIgst: parseFloat(itcIgst.toFixed(2)),
        totalEligibleItc: parseFloat(totalItc.toFixed(2))
      },
      netTaxLiability: {
        cgstPayable: parseFloat(netCgstPayable.toFixed(2)),
        sgstPayable: parseFloat(netSgstPayable.toFixed(2)),
        igstPayable: parseFloat(netIgstPayable.toFixed(2)),
        totalNetPayable: parseFloat(netTaxPayable.toFixed(2)),
        excessItcCarriedForward: parseFloat(excessItcCarriedForward.toFixed(2)),
        status: netTaxPayable > 0 ? 'TAX_PAYABLE' : 'ITC_CREDIT_AVAILABLE'
      }
    });
  } catch (error: any) {
    console.error('GSTR-3B Error:', error);
    return reply.status(500).send({ success: false, message: error?.message || 'Failed to generate GSTR-3B.' });
  }
}

// ============================================================================
// 4. HSN-WISE SALES & TAX BREAKDOWN ENGINE
// ============================================================================
export async function getHsnSummaryHandler(req: FastifyRequest, reply: FastifyReply) {
  try {
    const activeBusinessId = (req as any).businessAccess?.businessId || (req.headers['x-business-id'] as string) || (req.query as any)?.businessId;
    if (!activeBusinessId) {
      return reply.status(400).send({ success: false, message: 'x-business-id is required.' });
    }

    const { start, end } = getDateRange(req.query);
    const startStr = start.toISOString().split('T')[0];
    const endStr = end.toISOString().split('T')[0];
    const pool = getDbPool();

    // 1. Fetch Business Profile for State & GSTIN (Inter-state IGST determination)
    const bizRes = await pool.query(
      `SELECT state, gst_number, business_name FROM business_profile WHERE id = $1 LIMIT 1`,
      [activeBusinessId]
    );
    const biz = bizRes.rows[0] || {};
    const bizState = (biz.state || '').trim().toLowerCase();

    // 2. Fetch Inventory Items to auto-resolve HSN Code & Unit if not persisted in line item
    const itemsRes = await pool.query(
      `SELECT LOWER(TRIM(name)) as item_name, hsn_sac, unit FROM items WHERE business_id = $1`,
      [activeBusinessId]
    );
    const dbItemHsn = new Map<string, { hsn: string; unit: string }>();
    for (const itm of itemsRes.rows) {
      if (itm.item_name) {
        dbItemHsn.set(itm.item_name, {
          hsn: (itm.hsn_sac || '').trim(),
          unit: (itm.unit || '').trim()
        });
      }
    }

    // 3. Fetch sales orders with state_of_supply within date range
    const salesRes = await pool.query(
      `SELECT items_json, state_of_supply, date, created_at FROM sales_orders 
       WHERE business_id = $1 
         AND ((date >= $2 AND date <= $3) OR (date IS NULL AND created_at >= $2::date AND created_at <= ($3 || ' 23:59:59')::timestamp))`,
      [activeBusinessId, startStr, endStr]
    );

    const hsnMap: { [key: string]: any } = {};

    for (const s of salesRes.rows) {
      const items = parseItems(s.items_json);
      const isInterState = s.state_of_supply && bizState
        ? s.state_of_supply.trim().toLowerCase() !== bizState
        : false;

      for (const itm of items) {
        let rawHsn = (itm.hsnSac || itm.hsn_sac || itm.hsnCode || '').toString().trim();
        const itemName = (itm.name || itm.itemName || itm.description || 'Sample Item').toString().trim();

        // Auto-resolve HSN from registered inventory items if missing in invoice
        if (!rawHsn || rawHsn.toUpperCase() === 'NA' || rawHsn.toUpperCase() === 'N/A') {
          const inv = dbItemHsn.get(itemName.toLowerCase());
          if (inv && inv.hsn) {
            rawHsn = inv.hsn;
          }
        }

        const hsn = (!rawHsn || rawHsn.toUpperCase() === 'NA' || rawHsn.toUpperCase() === 'N/A') ? 'NA' : rawHsn;
        const key = `${hsn}_${itemName.toLowerCase()}`;

        const qty = parseFloat(itm.quantity || itm.qty || 1);
        const rate = parseFloat(itm.rate || itm.sellingPrice || itm.unitPrice || itm.price || 0);
        const taxRate = parseFloat(itm.taxRatePercent || itm.tax_rate_percent || itm.taxRate || 0);
        const discount = parseFloat(itm.discount || itm.discountAmount || 0);
        const isWithTax = itm.salePriceTaxMode === 'withTax' || itm.taxInclusive === 1 || itm.taxInclusive === true;

        const lineRaw = (qty * rate) - discount;
        const lineTaxable = isWithTax
          ? (lineRaw / (1 + (taxRate / 100)))
          : lineRaw;
        const lineTax = (lineTaxable * taxRate) / 100;

        let lineCgst = 0;
        let lineSgst = 0;
        let lineIgst = 0;

        if (isInterState) {
          lineIgst = lineTax;
        } else {
          lineCgst = lineTax / 2;
          lineSgst = lineTax / 2;
        }

        const lineCess = parseFloat(itm.cess || 0);
        const lineAddCess = parseFloat(itm.additionalCess || itm.additional_cess || 0);
        const lineFloodCess = parseFloat(itm.floodCess || itm.flood_cess || 0);
        const lineOtherTaxes = parseFloat(itm.otherTaxes || itm.other_taxes || 0);
        const lineTotal = lineTaxable + lineTax + lineCess + lineAddCess + lineFloodCess + lineOtherTaxes;

        if (!hsnMap[key]) {
          let itemUnit = itm.unit || '';
          if (!itemUnit) {
            const inv = dbItemHsn.get(itemName.toLowerCase());
            if (inv && inv.unit) itemUnit = inv.unit;
          }
          hsnMap[key] = {
            hsnCode: hsn,
            description: itemName,
            unit: itemUnit,
            totalQuantity: 0,
            taxableValue: 0,
            taxRatePercent: taxRate,
            cgst: 0,
            sgst: 0,
            igst: 0,
            cess: 0,
            additionalCess: 0,
            floodCess: 0,
            otherTaxes: 0,
            totalValue: 0
          };
        }

        hsnMap[key].totalQuantity += qty;
        hsnMap[key].taxableValue += lineTaxable;
        hsnMap[key].cgst += lineCgst;
        hsnMap[key].sgst += lineSgst;
        hsnMap[key].igst += lineIgst;
        hsnMap[key].cess += lineCess;
        hsnMap[key].additionalCess += lineAddCess;
        hsnMap[key].floodCess += lineFloodCess;
        hsnMap[key].otherTaxes += lineOtherTaxes;
        hsnMap[key].totalValue += lineTotal;
      }
    }

    const result = Object.values(hsnMap).map((h: any) => ({
      hsnCode: h.hsnCode,
      description: h.description,
      unit: h.unit,
      totalQuantity: parseFloat(h.totalQuantity.toFixed(2)),
      taxableValue: parseFloat(h.taxableValue.toFixed(2)),
      taxRatePercent: h.taxRatePercent,
      cgst: parseFloat(h.cgst.toFixed(2)),
      sgst: parseFloat(h.sgst.toFixed(2)),
      igst: parseFloat(h.igst.toFixed(2)),
      cess: parseFloat(h.cess.toFixed(2)),
      additionalCess: parseFloat(h.additionalCess.toFixed(2)),
      floodCess: parseFloat(h.floodCess.toFixed(2)),
      otherTaxes: parseFloat(h.otherTaxes.toFixed(2)),
      totalValue: parseFloat(h.totalValue.toFixed(2))
    })).sort((a, b) => b.taxableValue - a.taxableValue);

    const totalQuantity = result.reduce((sum, i) => sum + i.totalQuantity, 0);
    const totalTaxable = result.reduce((sum, i) => sum + i.taxableValue, 0);
    const totalTurnover = result.reduce((sum, i) => sum + i.totalValue, 0);
    const totalCgst = result.reduce((sum, i) => sum + i.cgst, 0);
    const totalSgst = result.reduce((sum, i) => sum + i.sgst, 0);
    const totalIgst = result.reduce((sum, i) => sum + i.igst, 0);
    const totalCess = result.reduce((sum, i) => sum + i.cess, 0);
    const totalAddCess = result.reduce((sum, i) => sum + i.additionalCess, 0);
    const totalFloodCess = result.reduce((sum, i) => sum + i.floodCess, 0);
    const totalOtherTaxes = result.reduce((sum, i) => sum + i.otherTaxes, 0);

    return reply.send({
      success: true,
      count: result.length,
      dateRange: { start: startStr, end: endStr },
      summary: {
        totalHsnCodes: result.length,
        totalQuantity: parseFloat(totalQuantity.toFixed(2)),
        totalValue: parseFloat(totalTurnover.toFixed(2)),
        totalTaxableValue: parseFloat(totalTaxable.toFixed(2)),
        totalCgst: parseFloat(totalCgst.toFixed(2)),
        totalSgst: parseFloat(totalSgst.toFixed(2)),
        totalIgst: parseFloat(totalIgst.toFixed(2)),
        totalCess: parseFloat(totalCess.toFixed(2)),
        totalAdditionalCess: parseFloat(totalAddCess.toFixed(2)),
        totalFloodCess: parseFloat(totalFloodCess.toFixed(2)),
        totalOtherTaxes: parseFloat(totalOtherTaxes.toFixed(2)),
      },
      hsnSummary: result
    });
  } catch (error: any) {
    return reply.status(500).send({ success: false, message: error?.message || 'Failed to fetch HSN summary.' });
  }
}

// ============================================================================
// 5. GSTR-9 ANNUAL RETURN ENGINE
// ============================================================================
export async function getGstr9Handler(req: FastifyRequest, reply: FastifyReply) {
  try {
    const activeBusinessId = (req as any).businessAccess?.businessId || (req.headers['x-business-id'] as string) || (req.query as any)?.businessId;
    if (!activeBusinessId) {
      return reply.status(400).send({ success: false, message: 'x-business-id is required.' });
    }

    const { start, end } = getDateRange(req.query);
    const pool = getDbPool();

    // 1. Fetch Business Profile
    const bizRes = await pool.query(
      `SELECT state, gst_number, business_name FROM business_profile WHERE id = $1 LIMIT 1`,
      [activeBusinessId]
    );
    const biz = bizRes.rows[0] || {};
    const bizState = (biz.state || 'Delhi').trim().toLowerCase();

    // 2. Fetch all sales within financial year / date range
    const salesRes = await pool.query(
      `SELECT so.id, so.invoice_no, so.date, so.party_id, so.customer_name, so.items_json,
              so.total_amount, so.state_of_supply, p.gst_number as party_gst
       FROM sales_orders so
       LEFT JOIN parties p ON so.party_id = p.id
       WHERE so.business_id = $1 AND so.date >= $2 AND so.date <= $3
       ORDER BY so.date ASC`,
      [activeBusinessId, start.toISOString().split('T')[0], end.toISOString().split('T')[0]]
    );

    let b2bTaxable = 0;
    let b2bCgst = 0;
    let b2bSgst = 0;
    let b2bIgst = 0;

    let b2cTaxable = 0;
    let b2cCgst = 0;
    let b2cSgst = 0;
    let b2cIgst = 0;

    let totalTurnover = 0;

    for (const s of salesRes.rows) {
      const orderTotal = parseFloat(s.total_amount || 0);
      totalTurnover += orderTotal;
      const isB2b = !!(s.party_gst && s.party_gst.trim().length >= 15);
      const isInterState = s.state_of_supply
        ? s.state_of_supply.trim().toLowerCase() !== bizState
        : false;

      const items = parseItems(s.items_json);
      for (const itm of items) {
        const qty = parseFloat(itm.quantity || itm.qty || 1);
        const rate = parseFloat(itm.rate || itm.sellingPrice || itm.price || 0);
        const taxRate = parseFloat(itm.taxRatePercent || itm.tax_rate_percent || 0);
        const raw = qty * rate;
        const lineTaxable = itm.salePriceTaxMode === 'withTax'
          ? (raw / (1 + (taxRate / 100)))
          : raw;
        const lineTax = (lineTaxable * taxRate) / 100;

        if (isB2b) {
          b2bTaxable += lineTaxable;
          if (isInterState) {
            b2bIgst += lineTax;
          } else {
            b2bCgst += lineTax / 2;
            b2bSgst += lineTax / 2;
          }
        } else {
          b2cTaxable += lineTaxable;
          if (isInterState) {
            b2cIgst += lineTax;
          } else {
            b2cCgst += lineTax / 2;
            b2cSgst += lineTax / 2;
          }
        }
      }
    }

    // 3. Fetch all purchases (ITC) within financial year / date range
    const purchRes = await pool.query(
      `SELECT po.id, po.order_no, po.date, po.items_json, po.total_amount, p.gst_number as supplier_gst
       FROM purchase_orders po
       LEFT JOIN parties p ON po.party_id = p.id
       WHERE po.business_id = $1 AND po.date >= $2 AND po.date <= $3
       ORDER BY po.date ASC`,
      [activeBusinessId, start.toISOString().split('T')[0], end.toISOString().split('T')[0]]
    );

    let itcTaxable = 0;
    let itcCgst = 0;
    let itcSgst = 0;
    let itcIgst = 0;
    let totalPurchases = 0;

    for (const p of purchRes.rows) {
      const orderTotal = parseFloat(p.total_amount || 0);
      totalPurchases += orderTotal;

      const items = parseItems(p.items_json);
      for (const itm of items) {
        const qty = parseFloat(itm.quantity || itm.qty || 1);
        const price = parseFloat(itm.purchasePrice || itm.rate || itm.price || 0);
        const taxRate = parseFloat(itm.taxRatePercent || itm.tax_rate_percent || 0);
        const raw = qty * price;
        const lineTaxable = itm.purchasePriceTaxMode === 'withTax'
          ? (raw / (1 + (taxRate / 100)))
          : raw;
        const lineTax = (lineTaxable * taxRate) / 100;

        itcTaxable += lineTaxable;
        itcCgst += lineTax / 2;
        itcSgst += lineTax / 2;
      }
    }

    const totalOutwardTax = (b2bCgst + b2cCgst) + (b2bSgst + b2cSgst) + (b2bIgst + b2cIgst);
    const totalEligibleItc = itcCgst + itcSgst + itcIgst;
    const netPayable = Math.max(0, totalOutwardTax - totalEligibleItc);
    const excessItc = Math.max(0, totalEligibleItc - totalOutwardTax);

    const yearLabel = `FY ${start.getFullYear()}-${(start.getFullYear() + 1).toString().slice(-2)}`;

    return reply.send({
      success: true,
      reportType: 'GSTR-9',
      financialYear: yearLabel,
      businessName: biz.business_name || '',
      businessGstin: biz.gst_number || '',
      dateRange: {
        start: start.toISOString().split('T')[0],
        end: end.toISOString().split('T')[0]
      },
      outwardSupplies: {
        b2bTaxableTurnover: parseFloat(b2bTaxable.toFixed(2)),
        b2bCgst: parseFloat(b2bCgst.toFixed(2)),
        b2bSgst: parseFloat(b2bSgst.toFixed(2)),
        b2bIgst: parseFloat(b2bIgst.toFixed(2)),
        b2cTaxableTurnover: parseFloat(b2cTaxable.toFixed(2)),
        b2cCgst: parseFloat(b2cCgst.toFixed(2)),
        b2cSgst: parseFloat(b2cSgst.toFixed(2)),
        b2cIgst: parseFloat(b2cIgst.toFixed(2)),
        totalTaxableTurnover: parseFloat((b2bTaxable + b2cTaxable).toFixed(2)),
        totalGrossTurnover: parseFloat(totalTurnover.toFixed(2)),
        totalOutwardCgst: parseFloat((b2bCgst + b2cCgst).toFixed(2)),
        totalOutwardSgst: parseFloat((b2bSgst + b2cSgst).toFixed(2)),
        totalOutwardIgst: parseFloat((b2bIgst + b2cIgst).toFixed(2)),
        totalOutwardTaxLiability: parseFloat(totalOutwardTax.toFixed(2))
      },
      inputTaxCredit: {
        totalTaxablePurchases: parseFloat(itcTaxable.toFixed(2)),
        totalPurchasesGross: parseFloat(totalPurchases.toFixed(2)),
        itcCgst: parseFloat(itcCgst.toFixed(2)),
        itcSgst: parseFloat(itcSgst.toFixed(2)),
        itcIgst: parseFloat(itcIgst.toFixed(2)),
        totalEligibleItcAvailed: parseFloat(totalEligibleItc.toFixed(2))
      },
      taxComputation: {
        totalTaxPayable: parseFloat(totalOutwardTax.toFixed(2)),
        totalItcUtilized: parseFloat(Math.min(totalOutwardTax, totalEligibleItc).toFixed(2)),
        netTaxPayableCash: parseFloat(netPayable.toFixed(2)),
        excessItcCarriedForward: parseFloat(excessItc.toFixed(2))
      }
    });
  } catch (error: any) {
    console.error('GSTR-9 Error:', error);
    return reply.status(500).send({ success: false, message: error?.message || 'Failed to generate GSTR-9 Annual Return.' });
  }
}


export async function lookupGstinHandler(req: FastifyRequest, reply: FastifyReply) {
  try {
    const { gstin } = req.params as { gstin: string };
    const cleanGstin = (gstin || '').trim().toUpperCase();

    if (cleanGstin.length !== 15) {
      return reply.status(400).send({ success: false, message: 'Invalid 15-digit GSTIN.' });
    }

    const stateCode = cleanGstin.substring(0, 2);
    const pan = cleanGstin.substring(2, 12);

    const stateMap: Record<string, string> = {
      '01': 'Jammu and Kashmir',
      '02': 'Himachal Pradesh',
      '03': 'Punjab',
      '04': 'Chandigarh',
      '05': 'Uttarakhand',
      '06': 'Haryana',
      '07': 'Delhi',
      '08': 'Rajasthan',
      '09': 'Uttar Pradesh',
      '10': 'Bihar',
      '11': 'Sikkim',
      '12': 'Arunachal Pradesh',
      '13': 'Nagaland',
      '14': 'Manipur',
      '15': 'Mizoram',
      '16': 'Tripura',
      '17': 'Meghalaya',
      '18': 'Assam',
      '19': 'West Bengal',
      '20': 'Jharkhand',
      '21': 'Odisha',
      '22': 'Chhattisgarh',
      '23': 'Madhya Pradesh',
      '24': 'Gujarat',
      '26': 'Dadra and Nagar Haveli and Daman and Diu',
      '27': 'Maharashtra',
      '29': 'Karnataka',
      '30': 'Goa',
      '31': 'Lakshadweep',
      '32': 'Kerala',
      '33': 'Tamil Nadu',
      '34': 'Puducherry',
      '35': 'Andaman and Nicobar Islands',
      '36': 'Telangana',
      '37': 'Andhra Pradesh',
      '38': 'Ladakh'
    };

    const stateName = stateMap[stateCode] || 'Delhi';
    const pool = getDbPool();

    const partyMatch = await pool.query(
      `SELECT name, address, city, state FROM parties WHERE UPPER(gst_number) = $1 LIMIT 1`,
      [cleanGstin]
    );

    let legalName = '';
    let address = '';
    let city = '';
    let pincode = '';

    if (partyMatch.rows.length > 0) {
      const p = partyMatch.rows[0];
      legalName = p.name || '';
      address = p.address || '';
      city = p.city || '';
    } else {
      const bizMatch = await pool.query(
        `SELECT business_name, address, city, state, pincode FROM business_profile WHERE UPPER(gst_number) = $1 LIMIT 1`,
        [cleanGstin]
      );
      if (bizMatch.rows.length > 0) {
        const b = bizMatch.rows[0];
        legalName = b.business_name || '';
        address = b.address || '';
        city = b.city || '';
        pincode = b.pincode || '';
      }
    }

    return reply.send({
      success: true,
      gstin: cleanGstin,
      legalName,
      tradeName: legalName,
      address,
      city,
      state: stateName,
      stateCode,
      pincode,
      pan
    });
  } catch (error: any) {
    return reply.status(500).send({ success: false, message: error?.message || 'Failed to lookup GSTIN.' });
  }
}
