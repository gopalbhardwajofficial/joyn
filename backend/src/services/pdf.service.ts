import PDFDocument from 'pdfkit';
import QRCode from 'qrcode';

export interface InvoicePdfData {
  business: {
    businessName: string;
    ownerName?: string;
    gstNumber?: string;
    address?: string;
    phone1?: string;
    email?: string;
    state?: string;
    bankName?: string;
    accountNumber?: string;
    ifscCode?: string;
    branchName?: string;
    upiId?: string;
    invoiceTheme?: string;
    invoiceColorHex?: string;
    invoiceTerms?: string;
    showUpiQr?: boolean;
    logoUrl?: string;
    signatureUrl?: string;
  };
  order: {
    invoiceNo: number | string;
    date: string;
    customerName: string;
    customerPhone?: string;
    customerAddress?: string;
    paymentMode?: string;
    totalAmount: number;
    receivedAmount: number;
    stateOfSupply?: string;
    description?: string;
    termsAndConditions?: string;
    items: Array<{
      itemName?: string;
      name?: string;
      qty: number;
      unitPrice?: number;
      price?: number;
      taxRate?: number;
      total: number;
    }>;
  };
}

function parseImageBuffer(str?: string): Buffer | null {
  if (!str) return null;
  try {
    if (str.startsWith('data:image')) {
      const commaIdx = str.indexOf(',');
      if (commaIdx !== -1) {
        return Buffer.from(str.substring(commaIdx + 1), 'base64');
      }
    } else if (/^[A-Za-z0-9+/=]+$/.test(str.trim()) && str.length > 80) {
      return Buffer.from(str.trim(), 'base64');
    }
  } catch (_) {}
  return null;
}

export async function generateInvoicePdf(data: InvoicePdfData): Promise<Buffer> {
  const { business, order } = data;
  const theme = business.invoiceTheme || 'classic_blue';

  if (theme === 'thermal_pos') {
    return generateThermalPosPdf(data);
  }

  return new Promise(async (resolve, reject) => {
    try {
      const doc = new PDFDocument({ margin: 40, size: 'A4' });
      const buffers: Buffer[] = [];

      doc.on('data', buffers.push.bind(buffers));
      doc.on('end', () => resolve(Buffer.concat(buffers)));

      const primaryColor = business.invoiceColorHex || (theme === 'emerald_elegance' ? '#059669' : theme === 'modern_minimal' ? '#0F172A' : '#4338CA');
      const darkColor = '#1E293B';
      const grayColor = '#64748B';
      const lightBg = theme === 'emerald_elegance' ? '#F0FDF4' : theme === 'modern_minimal' ? '#F8FAFC' : '#EEF2FF';

      // ── 1. HEADER SECTION
      doc.rect(40, 40, 515, 80).fill(lightBg);

      // Render Business Logo if available
      let textStartX = 55;
      const logoBuffer = parseImageBuffer(business.logoUrl);
      if (logoBuffer) {
        try {
          doc.image(logoBuffer, 50, 48, { width: 45, height: 45, fit: [45, 45] });
          textStartX = 105;
        } catch (_) {}
      }

      doc.fillColor(primaryColor).fontSize(18).font('Helvetica-Bold')
        .text(business.businessName || 'Tax Invoice', textStartX, 50, { width: 280, ellipsis: true });

      doc.fillColor(grayColor).fontSize(8.5).font('Helvetica')
        .text(`GSTIN: ${business.gstNumber || 'Not Registered'}`, textStartX, 73)
        .text(`Phone: ${business.phone1 || ''} | Email: ${business.email || ''}`, textStartX, 85, { width: 280, ellipsis: true })
        .text(business.address || '', textStartX, 97, { width: 280, ellipsis: true });

      // Right Header Details
      doc.fillColor(primaryColor).fontSize(16).font('Helvetica-Bold')
        .text('TAX INVOICE', 380, 50, { align: 'right' });

      doc.fillColor(darkColor).fontSize(9).font('Helvetica-Bold')
        .text(`Invoice No: INV-${order.invoiceNo}`, 380, 72, { align: 'right' });

      doc.font('Helvetica').fillColor(grayColor)
        .text(`Date: ${order.date}`, 380, 85, { align: 'right' })
        .text(`Payment: ${order.paymentMode || 'Cash'}`, 380, 97, { align: 'right' });

      // ── 2. BILL TO & SUPPLY INFO
      doc.rect(40, 130, 515, 55).fill('#F8FAFC');

      doc.fillColor(primaryColor).fontSize(9.5).font('Helvetica-Bold')
        .text('BILL TO:', 55, 138);

      doc.fillColor(darkColor).fontSize(11).font('Helvetica-Bold')
        .text(order.customerName || 'Cash Customer', 55, 151, { width: 300, ellipsis: true });

      doc.fillColor(grayColor).fontSize(8.5).font('Helvetica')
        .text(`Phone: ${order.customerPhone || 'N/A'} ${order.customerAddress ? '| ' + order.customerAddress : ''}`, 55, 165, { width: 300, ellipsis: true });

      if (order.stateOfSupply) {
        doc.fillColor(darkColor).fontSize(8.5).font('Helvetica-Bold')
          .text(`Place of Supply:`, 380, 142, { align: 'right' });
        doc.fillColor(grayColor).fontSize(8.5).font('Helvetica')
          .text(order.stateOfSupply, 380, 156, { align: 'right' });
      }

      // ── 3. LINE ITEMS TABLE HEADER
      let y = 195;
      doc.rect(40, y, 515, 24).fill(primaryColor);

      doc.fillColor('#FFFFFF').fontSize(8.5).font('Helvetica-Bold');
      doc.text('#', 50, y + 7, { width: 25 });
      doc.text('Item Description', 80, y + 7, { width: 220 });
      doc.text('Qty', 305, y + 7, { width: 45, align: 'right' });
      doc.text('Rate (₹)', 360, y + 7, { width: 60, align: 'right' });
      doc.text('Tax %', 430, y + 7, { width: 40, align: 'right' });
      doc.text('Total (₹)', 480, y + 7, { width: 65, align: 'right' });

      // Table Rows
      y += 28;
      doc.font('Helvetica').fontSize(8.5);

      let subtotal = 0;
      const items = Array.isArray(order.items) ? order.items : [];

      items.forEach((item, index) => {
        const itemName = item.itemName || item.name || `Item ${index + 1}`;
        const qty = item.qty || 1;
        const rate = item.unitPrice || item.price || 0;
        const taxRate = item.taxRate || 0;
        const total = item.total || qty * rate;
        subtotal += total;

        const rowBg = index % 2 === 0 ? '#FFFFFF' : '#F8FAFC';
        doc.rect(40, y - 4, 515, 20).fill(rowBg);

        doc.fillColor(darkColor);
        doc.text((index + 1).toString(), 50, y, { width: 25 });
        doc.text(itemName, 80, y, { width: 220, ellipsis: true });
        doc.text(qty.toString(), 305, y, { width: 45, align: 'right' });
        doc.text(rate.toFixed(2), 360, y, { width: 60, align: 'right' });
        doc.text(`${taxRate}%`, 430, y, { width: 40, align: 'right' });
        doc.text(total.toFixed(2), 480, y, { width: 65, align: 'right' });

        y += 22;
      });

      doc.rect(40, y, 515, 1).fill('#CBD5E1');
      y += 12;

      // ── 4. PAYMENT & BANK DETAILS (LEFT) + SUMMARY CARD (RIGHT)
      const balanceDue = Math.max(0, order.totalAmount - order.receivedAmount);
      const leftColY = y;

      // Dynamic NPCI UPI QR Code
      if (business.showUpiQr !== false) {
        try {
          const upiVpa = business.upiId || (business.phone1 ? `${business.phone1.replace(/\D/g, '').slice(-10)}@upi` : '8130820030@upi');
          const upiPayAmount = balanceDue > 0 ? balanceDue.toFixed(2) : order.totalAmount.toFixed(2);
          const upiString = `upi://pay?pa=${upiVpa}&pn=${encodeURIComponent(business.businessName || 'Merchant')}&am=${upiPayAmount}&cu=INR&tn=Invoice_${order.invoiceNo}`;
          const qrBuffer = await QRCode.toBuffer(upiString, { width: 85, margin: 1 });
          doc.image(qrBuffer, 45, leftColY, { width: 80 });

          doc.fillColor(primaryColor).fontSize(7.5).font('Helvetica-Bold')
            .text('Scan to Pay via UPI', 40, leftColY + 84, { width: 90, align: 'center' });
          doc.fillColor(grayColor).fontSize(6.5).font('Helvetica')
            .text(upiVpa, 40, leftColY + 94, { width: 90, align: 'center', ellipsis: true });
        } catch (_) {}
      }

      // Bank Details Card (Adjacent to UPI QR)
      const bankX = (business.showUpiQr !== false) ? 140 : 45;
      const bankWidth = (business.showUpiQr !== false) ? 175 : 270;
      if (business.bankName || business.accountNumber || business.upiId) {
        doc.rect(bankX, leftColY, bankWidth, 95).fill('#F8FAFC');
        doc.fillColor(primaryColor).fontSize(8.5).font('Helvetica-Bold')
          .text('BANK & PAYMENT DETAILS', bankX + 8, leftColY + 8);

        doc.fillColor(grayColor).fontSize(7.5).font('Helvetica');
        let by = leftColY + 24;
        if (business.bankName) {
          doc.text(`Bank: ${business.bankName}`, bankX + 8, by);
          by += 13;
        }
        if (business.accountNumber) {
          doc.text(`A/c No: ${business.accountNumber}`, bankX + 8, by);
          by += 13;
        }
        if (business.ifscCode) {
          doc.text(`IFSC: ${business.ifscCode}`, bankX + 8, by);
          by += 13;
        }
        if (business.branchName) {
          doc.text(`Branch: ${business.branchName}`, bankX + 8, by);
          by += 13;
        }
        if (business.upiId) {
          doc.text(`UPI ID: ${business.upiId}`, bankX + 8, by);
        }
      }

      // Right Side Totals Card
      const totalsX = 330;
      doc.rect(totalsX, leftColY, 225, 95).fill('#F8FAFC');

      doc.fillColor(grayColor).fontSize(8.5).font('Helvetica')
        .text('Subtotal:', totalsX + 15, leftColY + 10)
        .text(`₹${subtotal.toFixed(2)}`, 450, leftColY + 10, { align: 'right' });

      doc.fillColor(primaryColor).fontSize(12).font('Helvetica-Bold')
        .text('Grand Total:', totalsX + 15, leftColY + 28)
        .text(`₹${order.totalAmount.toFixed(2)}`, 450, leftColY + 28, { align: 'right' });

      doc.fillColor('#059669').fontSize(8.5).font('Helvetica-Bold')
        .text('Received Amount:', totalsX + 15, leftColY + 52)
        .text(`₹${order.receivedAmount.toFixed(2)}`, 450, leftColY + 52, { align: 'right' });

      doc.fillColor(balanceDue > 0 ? '#DC2626' : '#059669').fontSize(9.5).font('Helvetica-Bold')
        .text('Balance Due:', totalsX + 15, leftColY + 72)
        .text(`₹${balanceDue.toFixed(2)}`, 450, leftColY + 72, { align: 'right' });

      y = leftColY + 110;

      // ── 5. TERMS & CONDITIONS & SIGNATURE
      const terms = order.termsAndConditions || business.invoiceTerms;
      if (terms) {
        doc.fillColor(darkColor).fontSize(8).font('Helvetica-Bold').text('Terms & Conditions:', 40, y);
        doc.fillColor(grayColor).fontSize(7.5).font('Helvetica').text(terms, 40, y + 12, { width: 310 });
      }

      // Authorized Signatory & Signature Image
      doc.fillColor(darkColor).fontSize(8.5).font('Helvetica-Bold')
        .text(`For ${business.businessName}`, 380, y, { align: 'right' });

      const sigBuffer = parseImageBuffer(business.signatureUrl);
      if (sigBuffer) {
        try {
          doc.image(sigBuffer, 440, y + 14, { width: 80, height: 32, fit: [80, 32] });
        } catch (_) {}
      }

      doc.rect(390, y + 50, 160, 1).fill('#CBD5E1');
      doc.fillColor(grayColor).fontSize(7.5).font('Helvetica')
        .text('Authorized Signatory', 380, y + 55, { align: 'right' });

      // Footer
      doc.fillColor('#94A3B8').fontSize(7.5).font('Helvetica')
        .text('Generated seamlessly via JOYN Business OS • Tax compliant invoice', 40, 770, { align: 'center', width: 515 });

      doc.end();
    } catch (err) {
      reject(err);
    }
  });
}

// ── 6. THERMAL POS 80MM RECEIPT RENDERER
async function generateThermalPosPdf(data: InvoicePdfData): Promise<Buffer> {
  const { business, order } = data;
  return new Promise(async (resolve, reject) => {
    try {
      // 80mm thermal paper is approximately 226 points wide
      const doc = new PDFDocument({ margin: 10, size: [226, 650] });
      const buffers: Buffer[] = [];

      doc.on('data', buffers.push.bind(buffers));
      doc.on('end', () => resolve(Buffer.concat(buffers)));

      let y = 15;

      // Business Header
      doc.fillColor('#000000').fontSize(12).font('Helvetica-Bold')
        .text(business.businessName || 'TAX INVOICE', 10, y, { align: 'center', width: 206 });
      y += 16;

      doc.fontSize(7.5).font('Helvetica')
        .text(business.address || '', 10, y, { align: 'center', width: 206 });
      y += 10;
      doc.text(`Phone: ${business.phone1 || ''} | GSTIN: ${business.gstNumber || 'N/A'}`, 10, y, { align: 'center', width: 206 });
      y += 14;

      doc.text('------------------------------------------------------------', 10, y, { align: 'center' });
      y += 10;

      // Invoice & Customer Info
      doc.fontSize(8).font('Helvetica-Bold')
        .text(`Inv: INV-${order.invoiceNo}`, 10, y)
        .text(`Date: ${order.date}`, 120, y, { align: 'right' });
      y += 12;
      doc.font('Helvetica').fontSize(7.5)
        .text(`Customer: ${order.customerName || 'Cash'}`, 10, y);
      y += 12;

      doc.text('------------------------------------------------------------', 10, y, { align: 'center' });
      y += 10;

      // Items Header
      doc.fontSize(7.5).font('Helvetica-Bold');
      doc.text('Item', 10, y, { width: 100 });
      doc.text('Qty', 110, y, { width: 25, align: 'right' });
      doc.text('Rate', 138, y, { width: 35, align: 'right' });
      doc.text('Total', 175, y, { width: 40, align: 'right' });
      y += 12;

      // Items Rows
      doc.font('Helvetica').fontSize(7.5);
      const items = Array.isArray(order.items) ? order.items : [];
      items.forEach((item, idx) => {
        const name = item.itemName || item.name || `Item ${idx + 1}`;
        const qty = item.qty || 1;
        const rate = item.unitPrice || item.price || 0;
        const total = item.total || qty * rate;

        doc.text(name, 10, y, { width: 100, ellipsis: true });
        doc.text(qty.toString(), 110, y, { width: 25, align: 'right' });
        doc.text(rate.toFixed(0), 138, y, { width: 35, align: 'right' });
        doc.text(total.toFixed(2), 175, y, { width: 40, align: 'right' });
        y += 11;
      });

      y += 4;
      doc.text('------------------------------------------------------------', 10, y, { align: 'center' });
      y += 10;

      // Totals
      const balanceDue = Math.max(0, order.totalAmount - order.receivedAmount);
      doc.fontSize(8).font('Helvetica-Bold')
        .text('Total Amount:', 10, y)
        .text(`₹${order.totalAmount.toFixed(2)}`, 130, y, { align: 'right', width: 85 });
      y += 13;

      doc.font('Helvetica').fontSize(7.5)
        .text('Received Amount:', 10, y)
        .text(`₹${order.receivedAmount.toFixed(2)}`, 130, y, { align: 'right', width: 85 });
      y += 12;

      doc.font('Helvetica-Bold')
        .text('Balance Due:', 10, y)
        .text(`₹${balanceDue.toFixed(2)}`, 130, y, { align: 'right', width: 85 });
      y += 15;

      // Dynamic UPI QR Code
      if (business.showUpiQr !== false) {
        try {
          const upiVpa = business.upiId || (business.phone1 ? `${business.phone1.replace(/\D/g, '').slice(-10)}@upi` : '8130820030@upi');
          const upiPayAmount = balanceDue > 0 ? balanceDue.toFixed(2) : order.totalAmount.toFixed(2);
          const upiString = `upi://pay?pa=${upiVpa}&pn=${encodeURIComponent(business.businessName || 'Store')}&am=${upiPayAmount}&cu=INR&tn=Invoice_${order.invoiceNo}`;
          const qrBuffer = await QRCode.toBuffer(upiString, { width: 80, margin: 1 });
          doc.image(qrBuffer, 73, y, { width: 80 });
          y += 84;
          doc.fontSize(7).font('Helvetica-Bold').text('Scan to Pay via UPI', 10, y, { align: 'center', width: 206 });
          y += 12;
        } catch (_) {}
      }

      // Footer
      doc.font('Helvetica').fontSize(7.5)
        .text('Thank You! Visit Again.', 10, y, { align: 'center', width: 206 });
      y += 10;
      doc.fontSize(6).text('Powered by JOYN POS', 10, y, { align: 'center', width: 206 });

      doc.end();
    } catch (err) {
      reject(err);
    }
  });
}
