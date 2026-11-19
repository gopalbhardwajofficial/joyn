import { FastifyRequest, FastifyReply } from 'fastify';
import { getDbPool } from '../db/connection.js';

export async function searchBarcodeHandler(req: FastifyRequest, reply: FastifyReply) {
  try {
    const { code, q } = req.query as { code?: string; q?: string };
    const queryTerm = (code || q || '').trim();

    if (!queryTerm) {
      return reply.status(400).send({ success: false, message: 'Barcode or search term is required.' });
    }

    const user = (req as any).user;
    const activeBusinessId = (req.headers['x-business-id'] as string) || (req.query as any)?.businessId;

    if (!activeBusinessId) {
      return reply.status(400).send({ success: false, message: 'Active business ID required.' });
    }

    const pool = getDbPool();

    // 1. Try exact barcode match first
    let res = await pool.query(
      `SELECT * FROM items WHERE business_id = $1 AND (barcode = $2 OR sku = $2) LIMIT 1`,
      [activeBusinessId, queryTerm]
    );

    // 2. If not found, try partial name search
    if (res.rows.length === 0) {
      res = await pool.query(
        `SELECT * FROM items WHERE business_id = $1 AND LOWER(name) LIKE LOWER($2) LIMIT 5`,
        [activeBusinessId, `%${queryTerm}%`]
      );
    }

    if (res.rows.length === 0) {
      return reply.status(404).send({ success: false, message: 'No item found with this barcode.' });
    }

    const row = res.rows[0];
    return reply.send({
      success: true,
      item: {
        id: row.id,
        businessId: row.business_id,
        name: row.name,
        sku: row.sku || '',
        barcode: row.barcode || '',
        unit: row.unit || 'pcs',
        category: row.category || 'General',
        purchasePrice: parseFloat(row.purchase_price || 0),
        sellingPrice: parseFloat(row.selling_price || 0),
        salePriceTaxMode: row.sale_price_tax_mode || 'withoutTax',
        purchasePriceTaxMode: row.purchase_price_tax_mode || 'withoutTax',
        taxRatePercent: parseFloat(row.tax_rate_percent || 0),
        stock: parseInt(row.stock || 0, 10),
        minStockAlert: parseInt(row.min_stock_alert || 5, 10),
        createdAt: row.created_at
      },
      matches: res.rows.map((r) => ({
        id: r.id,
        name: r.name,
        barcode: r.barcode,
        sellingPrice: parseFloat(r.selling_price || 0),
        stock: parseInt(r.stock || 0, 10)
      }))
    });
  } catch (error: any) {
    return reply.status(500).send({ success: false, message: error?.message || 'Barcode search failed.' });
  }
}

export async function generateBarcodeHandler(req: FastifyRequest, reply: FastifyReply) {
  try {
    const activeBusinessId = (req.headers['x-business-id'] as string) || (req.body as any)?.businessId;
    const pool = getDbPool();

    let uniqueBarcode = '';
    let isUnique = false;
    let attempts = 0;

    // Standard EAN-13 generator (890 prefix for India)
    while (!isUnique && attempts < 10) {
      attempts++;
      const random9 = Math.floor(100000000 + Math.random() * 900000000).toString();
      const code12 = '890' + random9;

      // Calculate EAN-13 checksum digit
      let sum = 0;
      for (let i = 0; i < 12; i++) {
        const digit = parseInt(code12[i], 10);
        sum += i % 2 === 0 ? digit : digit * 3;
      }
      const checkDigit = (10 - (sum % 10)) % 10;
      uniqueBarcode = code12 + checkDigit.toString();

      const exists = await pool.query(
        `SELECT id FROM items WHERE barcode = $1 ${activeBusinessId ? 'AND business_id = $2' : ''} LIMIT 1`,
        activeBusinessId ? [uniqueBarcode, activeBusinessId] : [uniqueBarcode]
      );

      if (exists.rows.length === 0) {
        isUnique = true;
      }
    }

    return reply.send({
      success: true,
      barcode: uniqueBarcode,
      type: 'EAN-13',
      format: 'standard'
    });
  } catch (error: any) {
    return reply.status(500).send({ success: false, message: error?.message || 'Failed to generate barcode.' });
  }
}
