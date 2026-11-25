import { toDeterministicUuid } from '../utils/common.utils.js';
import { FastifyRequest, FastifyReply } from 'fastify';
import { getDbPool } from '../db/connection.js';

export async function getItemsHandler(req: FastifyRequest, reply: FastifyReply) {
  try {
    const businessId = (req.headers['x-business-id'] as string) || (req.query as any)?.businessId;
    const pool = getDbPool();

    const query = businessId
      ? `SELECT * FROM items WHERE business_id = $1 ORDER BY created_at DESC`
      : `SELECT * FROM items ORDER BY created_at DESC LIMIT 100`;
    const params = businessId ? [businessId] : [];

    const res = await pool.query(query, params);

    return reply.send({
      success: true,
      items: res.rows.map((i: any) => ({
        id: i.id,
        businessId: i.business_id,
        name: i.name,
        sku: i.sku || '',
        barcode: i.barcode || '',
        barcodeMode: i.barcode_mode || 'same',
        unit: i.unit || 'Pcs',
        category: i.category || 'General',
        hsnSac: i.hsn_sac || '',
        location: i.location || '',
        photoPath: i.photo_url || '',
        purchasePrice: parseFloat(i.purchase_price || 0),
        sellingPrice: parseFloat(i.selling_price || 0),
        salePriceTaxMode: i.sale_price_tax_mode || 'withoutTax',
        purchasePriceTaxMode: i.purchase_price_tax_mode || 'withoutTax',
        discountOnSalePrice: parseFloat(i.discount_on_sale_price || 0),
        discountType: i.discount_type || 'percentage',
        taxRateLabel: i.tax_rate_label || 'None',
        taxRatePercent: parseFloat(i.tax_rate_percent || 0),
        stock: parseInt(i.stock || 0, 10),
        minStockAlert: parseInt(i.min_stock_alert || 5, 10),
        itemNumber: i.item_number,
        itemCode: i.item_code || (i.item_number ? `ITM-${i.item_number}` : null),
        createdAt: i.created_at
      }))
    });
  } catch (error: any) {
    return reply.status(500).send({ success: false, message: error?.message || 'Failed to fetch items.' });
  }
}

export async function getItemByIdHandler(req: FastifyRequest, reply: FastifyReply) {
  try {
    const { id } = req.params as { id: string };
    const businessId = (req.headers['x-business-id'] as string) || (req.query as any)?.businessId;
    const pool = getDbPool();

    const query = businessId
      ? `SELECT * FROM items WHERE id = $1 AND business_id = $2 LIMIT 1`
      : `SELECT * FROM items WHERE id = $1 LIMIT 1`;
    const params = businessId ? [id, businessId] : [id];

    const res = await pool.query(query, params);
    if (res.rows.length === 0) {
      return reply.status(404).send({ success: false, message: 'Item not found.' });
    }

    const i = res.rows[0];
    return reply.send({
      success: true,
      item: {
        id: i.id,
        businessId: i.business_id,
        name: i.name,
        sku: i.sku || '',
        barcode: i.barcode || '',
        barcodeMode: i.barcode_mode || 'same',
        unit: i.unit || 'Pcs',
        category: i.category || 'General',
        hsnSac: i.hsn_sac || '',
        location: i.location || '',
        photoPath: i.photo_url || '',
        purchasePrice: parseFloat(i.purchase_price || 0),
        sellingPrice: parseFloat(i.selling_price || 0),
        salePriceTaxMode: i.sale_price_tax_mode || 'withoutTax',
        purchasePriceTaxMode: i.purchase_price_tax_mode || 'withoutTax',
        discountOnSalePrice: parseFloat(i.discount_on_sale_price || 0),
        discountType: i.discount_type || 'percentage',
        taxRateLabel: i.tax_rate_label || 'None',
        taxRatePercent: parseFloat(i.tax_rate_percent || 0),
        stock: parseInt(i.stock || 0, 10),
        minStockAlert: parseInt(i.min_stock_alert || 5, 10),
        itemNumber: i.item_number,
        itemCode: i.item_code || (i.item_number ? `ITM-${i.item_number}` : null),
        createdAt: i.created_at
      }
    });
  } catch (error: any) {
    return reply.status(500).send({ success: false, message: error?.message || 'Failed to fetch item.' });
  }
}

export async function createItemHandler(req: FastifyRequest, reply: FastifyReply) {
  try {
    const {
      businessId,
      name,
      sku,
      barcode,
      unit,
      category,
      hsnSac,
      location,
      purchasePrice,
      sellingPrice,
      salePriceTaxMode,
      purchasePriceTaxMode,
      discountOnSalePrice,
      discountType,
      taxRateLabel,
      taxRatePercent,
      stock,
      minStockAlert
    } = req.body as any;

    const activeBiz = businessId || (req.headers['x-business-id'] as string);
    if (!name || !activeBiz) {
      return reply.status(400).send({ success: false, message: 'Item name and businessId are required.' });
    }

    const pool = getDbPool();
    const body = req.body as any || {};
    const explicitId = body.id ? toDeterministicUuid(body.id) : null;

    // Check if item already exists by ID or by exact name for this business
    let existingQuery = 'SELECT * FROM items WHERE business_id = $1 AND (LOWER(TRIM(name)) = LOWER(TRIM($2))';
    const checkParams: any[] = [activeBiz, name.trim()];
    if (explicitId) {
      existingQuery += ' OR id = $3';
      checkParams.push(explicitId);
    }
    existingQuery += ') ORDER BY created_at ASC LIMIT 1';

    const existingRes = await pool.query(existingQuery, checkParams);
    if (existingRes.rows.length > 0) {
      // UPDATE existing item and preserve existing item_number and item_code!
      const targetId = existingRes.rows[0].id;
      const updateRes = await pool.query(
        `UPDATE items SET
          name = $1,
          sku = COALESCE($2, sku),
          barcode = COALESCE($3, barcode),
          unit = COALESCE($4, unit),
          category = COALESCE($5, category),
          hsn_sac = COALESCE($6, hsn_sac),
          location = COALESCE($7, location),
          purchase_price = COALESCE($8, purchase_price),
          selling_price = COALESCE($9, selling_price),
          sale_price_tax_mode = COALESCE($10, sale_price_tax_mode),
          purchase_price_tax_mode = COALESCE($11, purchase_price_tax_mode),
          discount_on_sale_price = COALESCE($12, discount_on_sale_price),
          discount_type = COALESCE($13, discount_type),
          tax_rate_label = COALESCE($14, tax_rate_label),
          tax_rate_percent = COALESCE($15, tax_rate_percent),
          stock = COALESCE($16, stock),
          min_stock_alert = COALESCE($17, min_stock_alert),
          updated_at = CURRENT_TIMESTAMP
        WHERE id = $18 AND business_id = $19
        RETURNING *`,
        [
          name,
          sku || null,
          barcode || null,
          unit || null,
          category || null,
          hsnSac || null,
          location || null,
          purchasePrice !== undefined ? purchasePrice : null,
          sellingPrice !== undefined ? sellingPrice : null,
          salePriceTaxMode || null,
          purchasePriceTaxMode || null,
          discountOnSalePrice !== undefined ? discountOnSalePrice : null,
          discountType || null,
          taxRateLabel || null,
          taxRatePercent !== undefined ? taxRatePercent : null,
          stock !== undefined ? stock : null,
          minStockAlert !== undefined ? minStockAlert : null,
          targetId,
          activeBiz
        ]
      );
      const updated = updateRes.rows[0];
      return reply.send({
        success: true,
        message: 'Item updated successfully.',
        item: {
          id: updated.id,
          name: updated.name,
          sku: updated.sku,
          barcode: updated.barcode,
          sellingPrice: parseFloat(updated.selling_price || 0),
          purchasePrice: parseFloat(updated.purchase_price || 0),
          stock: updated.stock,
          unit: updated.unit,
          category: updated.category,
          itemNumber: updated.item_number,
          itemCode: updated.item_code,
          createdAt: updated.created_at
        }
      });
    }

    const numRes = await pool.query(
      `SELECT COALESCE(MAX(item_number), 1000) + 1 AS next_num FROM items WHERE business_id = $1`,
      [activeBiz]
    );
    const assignedNum = parseInt(body.itemNumber || body.item_number || numRes.rows[0].next_num, 10);
    const assignedCode = body.itemCode || body.item_code || `ITM-${assignedNum}`;

    const res = await pool.query(
      `INSERT INTO items (
        id, business_id, name, sku, barcode, unit, category, hsn_sac, location,
        purchase_price, selling_price, sale_price_tax_mode, purchase_price_tax_mode,
        discount_on_sale_price, discount_type, tax_rate_label, tax_rate_percent,
        stock, min_stock_alert, item_number, item_code
      ) VALUES (COALESCE($1, gen_random_uuid()), $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13, $14, $15, $16, $17, $18, $19, $20, $21)
      RETURNING *`,
      [
        explicitId,
        activeBiz,
        name,
        sku || '',
        barcode || '',
        unit || 'Pcs',
        category || 'General',
        hsnSac || '',
        location || '',
        purchasePrice || 0,
        sellingPrice || 0,
        salePriceTaxMode || 'withoutTax',
        purchasePriceTaxMode || 'withoutTax',
        discountOnSalePrice || 0,
        discountType || 'percentage',
        taxRateLabel || 'None',
        taxRatePercent || 0,
        stock || 0,
        minStockAlert || 5,
        assignedNum,
        assignedCode
      ]
    );

    const i = res.rows[0];

    return reply.status(201).send({
      success: true,
      message: 'Item created successfully',
      item: {
        id: i.id,
        businessId: i.business_id,
        name: i.name,
        sku: i.sku,
        barcode: i.barcode,
        unit: i.unit,
        category: i.category,
        purchasePrice: parseFloat(i.purchase_price),
        sellingPrice: parseFloat(i.selling_price),
        stock: parseInt(i.stock, 10),
        itemNumber: i.item_number,
        itemCode: i.item_code,
        createdAt: i.created_at
      }
    });
  } catch (error: any) {
    return reply.status(500).send({ success: false, message: error?.message || 'Failed to create item.' });
  }
}

export async function updateItemHandler(req: FastifyRequest, reply: FastifyReply) {
  try {
    const { id } = req.params as { id: string };
    const updates = req.body as any;
    const pool = getDbPool();

    const res = await pool.query(
      `UPDATE items SET 
        name = COALESCE($1, name),
        selling_price = COALESCE($2, selling_price),
        purchase_price = COALESCE($3, purchase_price),
        stock = COALESCE($4, stock),
        updated_at = CURRENT_TIMESTAMP
       WHERE id = $5 RETURNING *`,
      [updates.name, updates.sellingPrice, updates.purchasePrice, updates.stock, id]
    );

    if (res.rows.length === 0) {
      return reply.status(404).send({ success: false, message: 'Item not found' });
    }

    return reply.send({ success: true, message: 'Item updated successfully', item: res.rows[0] });
  } catch (error: any) {
    return reply.status(500).send({ success: false, message: error?.message || 'Failed to update item.' });
  }
}

export async function deleteItemHandler(req: FastifyRequest, reply: FastifyReply) {
  try {
    const { id } = req.params as { id: string };
    const pool = getDbPool();

    await pool.query(`DELETE FROM items WHERE id = $1`, [id]);
    return reply.send({ success: true, message: 'Item deleted successfully' });
  } catch (error: any) {
    return reply.status(500).send({ success: false, message: error?.message || 'Failed to delete item.' });
  }
}
