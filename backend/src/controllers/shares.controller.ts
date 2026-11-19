import { FastifyRequest, FastifyReply } from 'fastify';
import crypto from 'crypto';
import QRCode from 'qrcode';
import { getDbPool } from '../db/connection.js';
import { generateInvoicePdf } from '../services/pdf.service.js';

function toValidUuidOrNull(val: any): string | null {
  if (typeof val !== 'string' || !val) return null;
  const uuidRegex = /^[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i;
  return uuidRegex.test(val) ? val : null;
}

// 1. Download Sales Invoice PDF (Authenticated)
export async function getSalesInvoicePdfHandler(req: FastifyRequest, reply: FastifyReply) {
  try {
    const { id } = req.params as { id: string };
    const validId = toValidUuidOrNull(id);
    const activeBusinessId = (req.headers['x-business-id'] as string) || (req.query as any)?.businessId;

    const pool = getDbPool();

    // Fetch order
    let orderRes = await pool.query(
      `SELECT * FROM sales_orders WHERE (id = $1 OR invoice_no::text = $2) ${activeBusinessId ? 'AND business_id = $3' : ''} LIMIT 1`,
      activeBusinessId ? [validId || '00000000-0000-0000-0000-000000000000', id, activeBusinessId] : [validId || '00000000-0000-0000-0000-000000000000', id]
    );

    if (orderRes.rows.length === 0 && validId) {
      orderRes = await pool.query('SELECT * FROM sales_orders WHERE id = $1 LIMIT 1', [validId]);
    }

    if (orderRes.rows.length === 0) {
      return reply.status(404).send({ success: false, message: 'Sales invoice not found.' });
    }

    const orderRow = orderRes.rows[0];

    // Fetch business profile
    const bizRes = await pool.query('SELECT * FROM business_profile WHERE id = $1 LIMIT 1', [orderRow.business_id]);
    let bizRow = bizRes.rows[0];
    if (!bizRow) {
      const fallbackBiz = await pool.query('SELECT * FROM business_profile ORDER BY created_at ASC LIMIT 1');
      bizRow = fallbackBiz.rows[0] || {};
    }

    const pdfBuffer = await generateInvoicePdf({
      business: {
        businessName: bizRow.business_name || 'JOYN Merchant',
        ownerName: bizRow.owner_name || '',
        gstNumber: bizRow.gst_number || '',
        address: bizRow.address || '',
        phone1: bizRow.phone1 || '',
        email: bizRow.email || '',
        state: bizRow.state || '',
        bankName: bizRow.bank_name || '',
        accountNumber: bizRow.account_number || '',
        ifscCode: bizRow.ifsc_code || '',
        branchName: bizRow.branch_name || '',
        upiId: bizRow.upi_id || '',
        invoiceTheme: orderRow.invoice_theme || bizRow.invoice_theme || 'classic_blue',
        invoiceColorHex: bizRow.invoice_color_hex || '#4338CA',
        invoiceTerms: bizRow.invoice_terms || '',
        showUpiQr: bizRow.show_upi_qr ?? true,
        logoUrl: bizRow.logo_url || '',
        signatureUrl: bizRow.signature_url || ''
      },
      order: {
        invoiceNo: orderRow.invoice_no,
        date: orderRow.date ? new Date(orderRow.date).toLocaleDateString('en-IN') : '',
        customerName: orderRow.customer_name || 'Customer',
        customerPhone: orderRow.customer_phone || '',
        paymentMode: orderRow.payment_mode || 'Cash',
        totalAmount: parseFloat(orderRow.total_amount || 0),
        receivedAmount: parseFloat(orderRow.received_amount || 0),
        stateOfSupply: orderRow.state_of_supply || '',
        termsAndConditions: orderRow.terms_and_conditions || bizRow.invoice_terms || '',
        items: typeof orderRow.items_json === 'string' ? JSON.parse(orderRow.items_json) : orderRow.items_json
      }
    });

    return reply
      .header('Content-Type', 'application/pdf')
      .header('Content-Disposition', `inline; filename="invoice_INV-${orderRow.invoice_no}.pdf"`)
      .send(pdfBuffer);
  } catch (error: any) {
    console.error('Invoice PDF Generation Error:', error);
    return reply.status(500).send({ success: false, message: error?.message || 'Failed to generate PDF.' });
  }
}

// 2. Generate WhatsApp Share Link with Public View Token
export async function getWhatsAppShareLinkHandler(req: FastifyRequest, reply: FastifyReply) {
  try {
    const { id } = req.params as { id: string };
    const validId = toValidUuidOrNull(id);
    const activeBusinessId = (req.headers['x-business-id'] as string) || (req.query as any)?.businessId;

    const pool = getDbPool();

    let orderRes = await pool.query(
      `SELECT * FROM sales_orders WHERE (id = $1 OR invoice_no::text = $2) ${activeBusinessId ? 'AND business_id = $3' : ''} LIMIT 1`,
      activeBusinessId ? [validId || '00000000-0000-0000-0000-000000000000', id, activeBusinessId] : [validId || '00000000-0000-0000-0000-000000000000', id]
    );

    if (orderRes.rows.length === 0 && validId) {
      orderRes = await pool.query('SELECT * FROM sales_orders WHERE id = $1 LIMIT 1', [validId]);
    }

    if (orderRes.rows.length === 0) {
      return reply.status(404).send({ success: false, message: 'Sales invoice not found.' });
    }

    const orderRow = orderRes.rows[0];

    // Fetch business profile
    const bizRes = await pool.query('SELECT * FROM business_profile WHERE id = $1 LIMIT 1', [orderRow.business_id]);
    let bizRow = bizRes.rows[0];
    if (!bizRow) {
      const fallbackBiz = await pool.query('SELECT * FROM business_profile ORDER BY created_at ASC LIMIT 1');
      bizRow = fallbackBiz.rows[0] || {};
    }

    // Check or create public share token
    let shareToken = '';
    const shareRes = await pool.query(
      `SELECT share_token FROM public_shares WHERE entity_type = 'SALE_INVOICE' AND entity_id = $1 LIMIT 1`,
      [orderRow.id]
    );

    if (shareRes.rows.length > 0) {
      shareToken = shareRes.rows[0].share_token;
    } else {
      shareToken = 'inv_' + crypto.randomBytes(16).toString('hex');
      await pool.query(
        `INSERT INTO public_shares (business_id, entity_type, entity_id, share_token)
         VALUES ($1, 'SALE_INVOICE', $2, $3)`,
        [orderRow.business_id, orderRow.id, shareToken]
      );
    }

    const publicUrl = `https://api.joynonline.in/public/invoices/${shareToken}`;
    const total = parseFloat(orderRow.total_amount || 0);
    const received = parseFloat(orderRow.received_amount || 0);
    const balanceDue = Math.max(0, total - received);

    // Pre-formatted professional WhatsApp message
    const rawMessage = 
`*TAX INVOICE from ${bizRow.business_name || 'Our Store'}*
━━━━━━━━━━━━━━━━━━━━
📄 *Invoice No:* INV-${orderRow.invoice_no}
📅 *Date:* ${orderRow.date ? new Date(orderRow.date).toLocaleDateString('en-IN') : ''}
💰 *Total Amount:* ₹${total.toFixed(2)}
💵 *Received:* ₹${received.toFixed(2)}
${balanceDue > 0 ? `⚠️ *Balance Due:* ₹${balanceDue.toFixed(2)}` : '✅ *Payment:* Fully Paid'}
━━━━━━━━━━━━━━━━━━━━
📥 *View & Download Invoice PDF:*
${publicUrl}

Thank you for your business!`;

    const cleanPhone = (orderRow.customer_phone || '').replace(/\D/g, '');
    const phoneParam = cleanPhone.length >= 10 ? (cleanPhone.startsWith('91') ? cleanPhone : '91' + cleanPhone.slice(-10)) : '';
    const whatsappUrl = `https://wa.me/${phoneParam}?text=${encodeURIComponent(rawMessage)}`;

    return reply.send({
      success: true,
      shareToken,
      publicUrl,
      whatsappText: rawMessage,
      whatsappUrl
    });
  } catch (error: any) {
    return reply.status(500).send({ success: false, message: error?.message || 'Failed to generate share link.' });
  }
}

// 3. Public Invoice Web View (Unauthenticated)
export async function getPublicInvoiceHtmlHandler(req: FastifyRequest, reply: FastifyReply) {
  try {
    const { token } = req.params as { token: string };
    const pool = getDbPool();

    // Find share record
    const shareRes = await pool.query(
      `SELECT * FROM public_shares WHERE share_token = $1 LIMIT 1`,
      [token]
    );

    if (shareRes.rows.length === 0) {
      return reply.status(404).type('text/html').send(`
        <div style="font-family:sans-serif;text-align:center;padding:50px;">
          <h2>Invoice Not Found or Link Expired</h2>
          <p>Please contact the merchant for an updated link.</p>
        </div>
      `);
    }

    const share = shareRes.rows[0];

    // Increment views count
    await pool.query('UPDATE public_shares SET views_count = views_count + 1 WHERE id = $1', [share.id]);

    // Fetch order & business
    const orderRes = await pool.query('SELECT * FROM sales_orders WHERE id = $1 LIMIT 1', [share.entity_id]);
    if (orderRes.rows.length === 0) {
      return reply.status(404).type('text/html').send('<h2>Invoice data not found.</h2>');
    }
    const order = orderRes.rows[0];

    const bizRes = await pool.query('SELECT * FROM business_profile WHERE id = $1 LIMIT 1', [share.business_id]);
    let biz = bizRes.rows[0];
    if (!biz) {
      const fallbackBiz = await pool.query('SELECT * FROM business_profile ORDER BY created_at ASC LIMIT 1');
      biz = fallbackBiz.rows[0] || {};
    }

    const items = typeof order.items_json === 'string' ? JSON.parse(order.items_json) : (order.items_json || []);
    const total = parseFloat(order.total_amount || 0);
    const received = parseFloat(order.received_amount || 0);
    const balance = Math.max(0, total - received);
    const primaryColor = biz.invoice_color_hex || '#4338CA';

    // Generate dynamic UPI Payment String & QR code
    let upiQrDataUri = '';
    const upiVpa = biz.upi_id || (biz.phone1 ? `${biz.phone1.replace(/\D/g, '').slice(-10)}@upi` : '');
    const upiPayAmount = balance > 0 ? balance.toFixed(2) : total.toFixed(2);
    const upiString = upiVpa ? `upi://pay?pa=${upiVpa}&pn=${encodeURIComponent(biz.business_name || 'Store')}&am=${upiPayAmount}&cu=INR&tn=Invoice_${order.invoice_no}` : '';
    if (upiString && biz.show_upi_qr !== false) {
      try {
        upiQrDataUri = await QRCode.toDataURL(upiString, { width: 140, margin: 1 });
      } catch (_) {}
    }

    const html = `<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Invoice INV-${order.invoice_no} | ${biz.business_name || 'JOYN'}</title>
  <style>
    * { box-sizing: border-box; margin:0; padding:0; }
    body { font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, Helvetica, Arial, sans-serif; background: #0F172A; color: #1E293B; padding: 20px 12px; }
    .card { max-width: 650px; margin: 0 auto; background: #FFFFFF; border-radius: 18px; box-shadow: 0 20px 40px rgba(0,0,0,0.3); overflow: hidden; }
    .header { background: linear-gradient(135deg, ${primaryColor}, #1E293B); color: #FFF; padding: 24px; display: flex; align-items: center; gap: 16px; }
    .header-logo { width: 56px; height: 56px; border-radius: 12px; object-fit: contain; background: #FFF; padding: 4px; }
    .header-info h1 { font-size: 20px; font-weight: 800; margin-bottom: 4px; }
    .header-info p { font-size: 12.5px; opacity: 0.9; }
    .meta { display: flex; justify-content: space-between; padding: 18px 24px; background: #F8FAFC; border-bottom: 1px solid #E2E8F0; }
    .meta-box h4 { font-size: 11px; text-transform: uppercase; color: #64748B; margin-bottom: 4px; }
    .meta-box p { font-size: 13.5px; font-weight: 700; color: #0F172A; }
    .content { padding: 24px; }
    table { width: 100%; border-collapse: collapse; margin: 16px 0; }
    th { text-align: left; padding: 10px 8px; font-size: 12px; color: #64748B; border-bottom: 2px solid #E2E8F0; }
    td { padding: 12px 8px; font-size: 13.5px; border-bottom: 1px solid #F1F5F9; }
    .totals { margin-top: 18px; background: #F8FAFC; padding: 18px; border-radius: 12px; }
    .tot-row { display: flex; justify-content: space-between; margin-bottom: 8px; font-size: 13.5px; }
    .tot-row.grand { font-size: 18px; font-weight: 800; color: ${primaryColor}; border-top: 1px solid #E2E8F0; padding-top: 10px; margin-top: 8px; }
    
    /* Payment & UPI Box */
    .payment-box { margin-top: 20px; padding: 16px; border-radius: 12px; background: #F0FDF4; border: 1px solid #BBF7D0; display: flex; flex-direction: column; align-items: center; text-align: center; }
    .upi-btn { display: inline-block; width: 100%; max-width: 380px; text-align: center; background: #059669; color: #FFF; text-decoration: none; padding: 14px 20px; border-radius: 12px; font-weight: 700; font-size: 14px; margin-top: 10px; box-shadow: 0 4px 12px rgba(5,150,105,0.25); }
    .upi-btn:hover { background: #047857; }
    
    .bank-card { margin-top: 16px; padding: 14px 18px; background: #F8FAFC; border-radius: 12px; border: 1px solid #E2E8F0; font-size: 12.5px; }
    .bank-card h4 { font-size: 12px; font-weight: 700; color: ${primaryColor}; margin-bottom: 6px; text-transform: uppercase; }
    .bank-card p { margin-bottom: 3px; color: #475569; }

    .btn-pdf { display: block; width: 100%; text-align: center; background: ${primaryColor}; color: #FFF; text-decoration: none; padding: 15px; border-radius: 12px; font-weight: 700; font-size: 14.5px; margin-top: 20px; box-shadow: 0 4px 12px rgba(67,56,202,0.25); }
    .btn-pdf:hover { opacity: 0.92; }
    .terms { margin-top: 18px; padding-top: 14px; border-top: 1px solid #E2E8F0; font-size: 11.5px; color: #64748B; }
    .footer { text-align: center; padding: 18px; font-size: 11.5px; color: #94A3B8; }
  </style>
</head>
<body>
  <div class="card">
    <div class="header">
      ${biz.logo_url ? `<img src="${biz.logo_url}" alt="Logo" class="header-logo" />` : ''}
      <div class="header-info">
        <h1>${biz.business_name || 'Tax Invoice'}</h1>
        <p>GSTIN: ${biz.gst_number || 'Unregistered'} | Phone: ${biz.phone1 || ''}</p>
      </div>
    </div>
    <div class="meta">
      <div class="meta-box">
        <h4>Invoice No</h4>
        <p>INV-${order.invoice_no}</p>
      </div>
      <div class="meta-box">
        <h4>Date</h4>
        <p>${order.date ? new Date(order.date).toLocaleDateString('en-IN') : ''}</p>
      </div>
      <div class="meta-box">
        <h4>Customer</h4>
        <p>${order.customer_name || 'Cash Customer'}</p>
      </div>
    </div>
    <div class="content">
      <table>
        <thead>
          <tr>
            <th>Item</th>
            <th style="text-align:right;">Qty</th>
            <th style="text-align:right;">Rate</th>
            <th style="text-align:right;">Total</th>
          </tr>
        </thead>
        <tbody>
          ${items.map((it: any) => `
            <tr>
              <td><strong>${it.itemName || it.name || 'Item'}</strong></td>
              <td style="text-align:right;">${it.qty || 1}</td>
              <td style="text-align:right;">₹${parseFloat(it.unitPrice || it.price || 0).toFixed(2)}</td>
              <td style="text-align:right;">₹${parseFloat(it.total || 0).toFixed(2)}</td>
            </tr>
          `).join('')}
        </tbody>
      </table>

      <div class="totals">
        <div class="tot-row">
          <span>Subtotal</span>
          <span>₹${total.toFixed(2)}</span>
        </div>
        <div class="tot-row grand">
          <span>Grand Total</span>
          <span>₹${total.toFixed(2)}</span>
        </div>
        <div class="tot-row" style="color: #059669; font-weight: 600; margin-top: 8px;">
          <span>Received Amount</span>
          <span>₹${received.toFixed(2)}</span>
        </div>
        <div class="tot-row" style="color: ${balance > 0 ? '#DC2626' : '#059669'}; font-weight: 700;">
          <span>Balance Due</span>
          <span>₹${balance.toFixed(2)}</span>
        </div>
      </div>

      ${(upiString && balance > 0) ? `
        <div class="payment-box">
          <h4 style="color:#065F46; font-size:13px; font-weight:700; margin-bottom:8px;">Instant UPI Payment</h4>
          ${upiQrDataUri ? `<img src="${upiQrDataUri}" alt="UPI QR" style="width:120px;height:120px;border-radius:8px;border:1px solid #A7F3D0;background:#FFF;padding:4px;margin-bottom:8px;" />` : ''}
          <a href="${upiString}" class="upi-btn">
            ⚡ Pay ₹${upiPayAmount} via UPI (GPay / PhonePe / Paytm)
          </a>
          <span style="font-size:11px;color:#047857;margin-top:6px;">UPI ID: ${upiVpa}</span>
        </div>
      ` : ''}

      ${(biz.bank_name || biz.account_number) ? `
        <div class="bank-card">
          <h4>Bank Account Details</h4>
          ${biz.bank_name ? `<p><strong>Bank:</strong> ${biz.bank_name}</p>` : ''}
          ${biz.account_number ? `<p><strong>A/c Number:</strong> ${biz.account_number}</p>` : ''}
          ${biz.ifsc_code ? `<p><strong>IFSC Code:</strong> ${biz.ifsc_code}</p>` : ''}
          ${biz.branch_name ? `<p><strong>Branch:</strong> ${biz.branch_name}</p>` : ''}
        </div>
      ` : ''}

      ${biz.invoice_terms ? `
        <div class="terms">
          <strong>Terms & Conditions:</strong>
          <p style="white-space:pre-line; margin-top:4px;">${biz.invoice_terms}</p>
        </div>
      ` : ''}

      <a href="/public/invoices/${token}/pdf" class="btn-pdf">
        📄 Download Official GST Tax Invoice PDF
      </a>
    </div>
    <div class="footer">
      Powered seamlessly by JOYN Business OS
    </div>
  </div>
</body>
</html>`;

    return reply.type('text/html').send(html);
  } catch (error: any) {
    return reply.status(500).type('text/html').send(`<h2>Error rendering invoice: ${error.message}</h2>`);
  }
}

// 4. Public Invoice PDF Stream (Unauthenticated)
export async function getPublicInvoicePdfStreamHandler(req: FastifyRequest, reply: FastifyReply) {
  try {
    const { token } = req.params as { token: string };
    const pool = getDbPool();

    const shareRes = await pool.query(`SELECT * FROM public_shares WHERE share_token = $1 LIMIT 1`, [token]);
    if (shareRes.rows.length === 0) {
      return reply.status(404).send({ success: false, message: 'Invoice not found.' });
    }

    const share = shareRes.rows[0];
    const orderRes = await pool.query('SELECT * FROM sales_orders WHERE id = $1 LIMIT 1', [share.entity_id]);
    if (orderRes.rows.length === 0) {
      return reply.status(404).send({ success: false, message: 'Order data not found.' });
    }
    const orderRow = orderRes.rows[0];

    const bizRes = await pool.query('SELECT * FROM business_profile WHERE id = $1 LIMIT 1', [share.business_id]);
    const bizRow = bizRes.rows[0] || {};

    const pdfBuffer = await generateInvoicePdf({
      business: {
        businessName: bizRow.business_name || 'JOYN Merchant',
        ownerName: bizRow.owner_name || '',
        gstNumber: bizRow.gst_number || '',
        address: bizRow.address || '',
        phone1: bizRow.phone1 || '',
        email: bizRow.email || '',
        state: bizRow.state || '',
        bankName: bizRow.bank_name || '',
        accountNumber: bizRow.account_number || '',
        ifscCode: bizRow.ifsc_code || '',
        branchName: bizRow.branch_name || '',
        upiId: bizRow.upi_id || '',
        invoiceTheme: orderRow.invoice_theme || bizRow.invoice_theme || 'classic_blue',
        invoiceColorHex: bizRow.invoice_color_hex || '#4338CA',
        invoiceTerms: bizRow.invoice_terms || '',
        showUpiQr: bizRow.show_upi_qr ?? true,
        logoUrl: bizRow.logo_url || '',
        signatureUrl: bizRow.signature_url || ''
      },
      order: {
        invoiceNo: orderRow.invoice_no,
        date: orderRow.date ? new Date(orderRow.date).toLocaleDateString('en-IN') : '',
        customerName: orderRow.customer_name || 'Customer',
        customerPhone: orderRow.customer_phone || '',
        paymentMode: orderRow.payment_mode || 'Cash',
        totalAmount: parseFloat(orderRow.total_amount || 0),
        receivedAmount: parseFloat(orderRow.received_amount || 0),
        stateOfSupply: orderRow.state_of_supply || '',
        termsAndConditions: orderRow.terms_and_conditions || bizRow.invoice_terms || '',
        items: typeof orderRow.items_json === 'string' ? JSON.parse(orderRow.items_json) : orderRow.items_json
      }
    });

    return reply
      .header('Content-Type', 'application/pdf')
      .header('Content-Disposition', `inline; filename="invoice_INV-${orderRow.invoice_no}.pdf"`)
      .send(pdfBuffer);
  } catch (error: any) {
    return reply.status(500).send({ success: false, message: error?.message || 'Failed to stream PDF.' });
  }
}
