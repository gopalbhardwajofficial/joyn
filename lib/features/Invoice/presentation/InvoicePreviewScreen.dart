// -----------------------------------------------------------------------
// InvoicePreviewScreen
//
// Shows the just-saved invoice as a swipeable, theme-able preview
// (Tally / Landscape 1 / Landscape 2 / GST / Modern Elite / Double Divine),
// with a working Print button (renders to PDF) and Share button (renders
// to PNG and opens the native share sheet) — matching the reference app's
// "Preview" screen.
//
// REQUIRED PACKAGES (add to pubspec.yaml if not already present):
//   screenshot: ^3.0.0
//   share_plus: ^10.0.0
//   printing: ^5.13.0
//   pdf: ^3.11.0
//
// USAGE (e.g. from AddSaleOrderScreen after a successful save):
//
//   Navigator.of(context).push(MaterialPageRoute(
//     builder: (_) => InvoicePreviewScreen(
//       data: InvoicePreviewData(
//         invoiceNo: _invoiceNo,
//         date: _formattedDate,
//         customerName: _isOneTimeCustomer ? 'One Time Customer' : _customerController.text.trim(),
//         customerPhone: _isOneTimeCustomer ? '' : _phoneController.text.trim(),
//         items: List<OrderItemModel>.from(_items),
//         totalAmount: double.tryParse(_totalAmountController.text.trim()) ?? 0,
//         businessName: 'Your Business Name',   // pull from Business Profile
//         businessPhone: '9958761582',
//         businessEmail: 'you@example.com',
//       ),
//     ),
//   ));
// -----------------------------------------------------------------------

import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:screenshot/screenshot.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/theme/joyn_colors.dart';
import '../../../core/theme/joyn_typography.dart';
import '../../orders/models/order_item_model.dart';

// ============================================================
// DATA MODEL — everything the preview needs, decoupled from
// whichever screen (Sale / Purchase Order / etc.) is calling it.
// ============================================================

class InvoicePreviewData {
  const InvoicePreviewData({
    required this.invoiceNo,
    required this.date,
    required this.customerName,
    required this.customerPhone,
    required this.items,
    required this.totalAmount,
    this.receivedAmount = 0,
    this.businessName = 'Your Business',
    this.businessPhone = '',
    this.businessEmail = '',
    this.title = 'Tax Invoice',
  });

  final int invoiceNo;
  final String date;
  final String customerName;
  final String customerPhone;
  final List<OrderItemModel> items;
  final double totalAmount;
  final double receivedAmount;
  final String businessName;
  final String businessPhone;
  final String businessEmail;
  final String title;

  double get balanceDue => (totalAmount - receivedAmount).clamp(0, double.infinity);
}

// ============================================================
// THEME REGISTRY
// ============================================================

enum _ThemeId { tally, landscape1, landscape2, gst1, modernElite, doubleDivine }

class _InvoiceTheme {
  const _InvoiceTheme(this.id, this.name, this.accents);
  final _ThemeId id;
  final String name;
  final List<Color> accents;
}

const List<_InvoiceTheme> _kThemes = [
  _InvoiceTheme(_ThemeId.tally, 'Tally Theme', [Colors.black87]),
  _InvoiceTheme(_ThemeId.landscape1, 'Landscape Theme 1', [Colors.black87]),
  _InvoiceTheme(_ThemeId.landscape2, 'Landscape Theme 2', [Colors.black87]),
  _InvoiceTheme(_ThemeId.gst1, 'GST Theme 1', [
    Color(0xFF7C3AED), Color(0xFF2563EB), Color(0xFF9CA3AF),
    Color(0xFF4B5563), Color(0xFFB5A642), Color(0xFF4682B4),
  ]),
  _InvoiceTheme(_ThemeId.modernElite, 'Modern Elite', [
    Color(0xFFC7C9F5), Color(0xFF7FB3D5), Color(0xFF9CA3AF),
    Color(0xFF6B7280), Color(0xFFC9C08F), Color(0xFF9FB8DA),
  ]),
  _InvoiceTheme(_ThemeId.doubleDivine, 'Double Divine', [
    Color(0xFFC0202B), Color(0xFF2563EB), Color(0xFFDB6A1E),
    Color(0xFF1F8A5A), Color(0xFF3B4B8C),
  ]),
];

// ============================================================
// SCREEN
// ============================================================

class InvoicePreviewScreen extends StatefulWidget {
  const InvoicePreviewScreen({super.key, required this.data});

  final InvoicePreviewData data;

  @override
  State<InvoicePreviewScreen> createState() => _InvoicePreviewScreenState();
}

class _InvoicePreviewScreenState extends State<InvoicePreviewScreen> {
  final _pageController = PageController();
  final _screenshotController = ScreenshotController();

  int _themeIndex = 0;
  int _accentIndex = 0;
  bool _isSharing = false;
  bool _isPrinting = false;

  _InvoiceTheme get _theme => _kThemes[_themeIndex];
  Color get _accent => _theme.accents[_accentIndex.clamp(0, _theme.accents.length - 1)];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _goTo(int index) {
    if (index < 0 || index >= _kThemes.length) return;
    HapticFeedback.selectionClick();
    setState(() {
      _themeIndex = index;
      _accentIndex = 0;
    });
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
    );
  }

  // ============================================================
  // CAPTURE / SHARE / PRINT — this is the part that makes the
  // buttons in the screenshots actually work, instead of being
  // decorative.
  // ============================================================

  Future<Uint8List> _captureCurrentThemeAsPng() async {
    final bytes = await _screenshotController.capture(pixelRatio: 3);
    if (bytes == null) {
      throw Exception('Could not render invoice for export');
    }
    return bytes;
  }

  Future<void> _share() async {
    if (_isSharing) return;
    setState(() => _isSharing = true);
    try {
      final bytes = await _captureCurrentThemeAsPng();
      await Share.shareXFiles(
        [
          XFile.fromData(
            bytes,
            name: 'invoice_${widget.data.invoiceNo}.png',
            mimeType: 'image/png',
          ),
        ],
        text: '${widget.data.title} #${widget.data.invoiceNo}',
      );
    } catch (e) {
      _showError('Could not share invoice: $e');
    } finally {
      if (mounted) setState(() => _isSharing = false);
    }
  }

  Future<void> _print() async {
    if (_isPrinting) return;
    setState(() => _isPrinting = true);
    try {
      final bytes = await _captureCurrentThemeAsPng();
      final image = pw.MemoryImage(bytes);
      final doc = pw.Document();
      doc.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(16),
          build: (context) => pw.Center(child: pw.Image(image)),
        ),
      );
      await Printing.layoutPdf(
        onLayout: (_) => doc.save(),
        name: 'invoice_${widget.data.invoiceNo}.pdf',
      );
    } catch (e) {
      _showError('Could not print invoice: $e');
    } finally {
      if (mounted) setState(() => _isPrinting = false);
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: JoynColors.error,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    );
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: JoynColors.background,
      appBar: AppBar(
        backgroundColor: JoynColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text('Preview', style: JoynTypography.titleMedium.copyWith(fontWeight: FontWeight.w800)),
        centerTitle: false,
        actions: [
          TextButton.icon(
            onPressed: _isPrinting ? null : _print,
            icon: _isPrinting
                ? const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
                : const Icon(Icons.print_outlined, size: 20, color: JoynColors.primary),
            label: Text('Print', style: JoynTypography.bodyMedium.copyWith(color: JoynColors.primary)),
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined, color: JoynColors.secondaryText),
            onPressed: () {},
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                _theme.name,
                style: JoynTypography.titleMedium.copyWith(fontSize: 20, fontWeight: FontWeight.w800),
              ),
            ),
          ),
          if (_theme.accents.length > 1)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
              child: SizedBox(
                height: 36,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: _theme.accents.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 10),
                  itemBuilder: (context, i) {
                    final isSelected = i == _accentIndex;
                    return InkWell(
                      onTap: () {
                        HapticFeedback.selectionClick();
                        setState(() => _accentIndex = i);
                      },
                      customBorder: const CircleBorder(),
                      child: Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: _theme.accents[i],
                          shape: BoxShape.circle,
                          border: isSelected ? Border.all(color: JoynColors.primary, width: 2) : null,
                        ),
                        child: isSelected ? const Icon(Icons.check_rounded, color: Colors.white, size: 16) : null,
                      ),
                    );
                  },
                ),
              ),
            ),
          const SizedBox(height: 10),
          Expanded(
            child: Stack(
              alignment: Alignment.center,
              children: [
                PageView.builder(
                  controller: _pageController,
                  itemCount: _kThemes.length,
                  onPageChanged: (i) => setState(() {
                    _themeIndex = i;
                    _accentIndex = 0;
                  }),
                  itemBuilder: (context, index) {
                    final theme = _kThemes[index];
                    final isCurrent = index == _themeIndex;
                    final body = _InvoiceBody(
                      themeId: theme.id,
                      accent: isCurrent ? _accent : theme.accents.first,
                      data: widget.data,
                    );

                    // Only the currently-active page is wrapped in the
                    // Screenshot capture boundary — that's what gets
                    // exported when Print / Share is tapped.
                    return SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                      child: isCurrent
                          ? Screenshot(controller: _screenshotController, child: body)
                          : body,
                    );
                  },
                ),
                Positioned(
                  left: 4,
                  child: _NavArrow(icon: Icons.chevron_left_rounded, onTap: () => _goTo(_themeIndex - 1)),
                ),
                Positioned(
                  right: 4,
                  child: _NavArrow(icon: Icons.chevron_right_rounded, onTap: () => _goTo(_themeIndex + 1)),
                ),
              ],
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 14),
              child: Column(
                children: [
                  GestureDetector(
                    onTap: _isSharing ? null : _share,
                    child: Container(
                      width: 58,
                      height: 58,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF5A623),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.2),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: _isSharing
                          ? const Padding(
                        padding: EdgeInsets.all(16),
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      )
                          : const Icon(Icons.ios_share_rounded, color: Colors.white),
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text(
                      'Save & close',
                      style: JoynTypography.bodyMedium.copyWith(color: JoynColors.secondaryText),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _NavArrow extends StatelessWidget {
  const _NavArrow({required this.icon, required this.onTap});
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      customBorder: const CircleBorder(),
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.35), shape: BoxShape.circle),
        child: Icon(icon, color: Colors.white),
      ),
    );
  }
}

// ============================================================
// INVOICE BODY — picks the right layout for the active theme.
// Keeping this separate from the screen means Screenshot only
// ever wraps the printable content, not the app bar/buttons.
// ============================================================

class _InvoiceBody extends StatelessWidget {
  const _InvoiceBody({required this.themeId, required this.accent, required this.data});

  final _ThemeId themeId;
  final Color accent;
  final InvoicePreviewData data;

  @override
  Widget build(BuildContext context) {
    switch (themeId) {
      case _ThemeId.tally:
        return _SimpleInvoiceCard(data: data, showLogoBox: true);
      case _ThemeId.landscape1:
      case _ThemeId.landscape2:
        return _SimpleInvoiceCard(data: data, showLogoBox: true, compact: true);
      case _ThemeId.gst1:
        return _GstInvoiceCard(data: data, accent: accent);
      case _ThemeId.modernElite:
        return _ModernEliteCard(data: data, accent: accent);
      case _ThemeId.doubleDivine:
        return _DoubleDivineCard(data: data, accent: accent);
    }
  }
}

// ============================================================
// SHARED ITEMS TABLE
// ============================================================

class _ItemsTable extends StatelessWidget {
  const _ItemsTable({required this.items, required this.total, this.headerColor});

  final List<OrderItemModel> items;
  final double total;
  final Color? headerColor;

  @override
  Widget build(BuildContext context) {
    final headerTextColor = headerColor != null ? Colors.white : Colors.black87;

    TableRow header() => TableRow(
      decoration: BoxDecoration(color: headerColor ?? Colors.grey.shade200),
      children: [
        _cell('#', bold: true, color: headerTextColor),
        _cell('Item Name', bold: true, color: headerTextColor),
        _cell('HSN/SAC', bold: true, color: headerTextColor),
        _cell('Qty', bold: true, color: headerTextColor),
        _cell('Price/Unit', bold: true, color: headerTextColor),
        _cell('Amount', bold: true, color: headerTextColor),
      ],
    );

    return Table(
      border: TableBorder.all(color: Colors.grey.shade300, width: 0.6),
      columnWidths: const {0: FixedColumnWidth(24)},
      children: [
        header(),
        if (items.isEmpty)
          TableRow(children: [
            _cell(''), _cell('—'), _cell(''), _cell(''), _cell(''), _cell(''),
          ])
        else
          ...items.asMap().entries.map(
                (e) => TableRow(children: [
              _cell('${e.key + 1}'),
              _cell(e.value.itemName),
              _cell(e.value.category),
              _cell('${e.value.qty}'),
              _cell(e.value.price.toStringAsFixed(2)),
              _cell(e.value.amount.toStringAsFixed(2)),
            ]),
          ),
        TableRow(children: [
          _cell(''), _cell(''), _cell(''), _cell(''),
          _cell('Total', bold: true),
          _cell('₹${total.toStringAsFixed(2)}', bold: true),
        ]),
      ],
    );
  }

  Widget _cell(String text, {bool bold = false, Color? color}) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
    child: Text(
      text,
      style: TextStyle(fontSize: 10.5, fontWeight: bold ? FontWeight.w800 : FontWeight.w500, color: color),
    ),
  );
}

// ============================================================
// THEME: Tally / Landscape 1 / Landscape 2
// ============================================================

class _SimpleInvoiceCard extends StatelessWidget {
  const _SimpleInvoiceCard({required this.data, this.showLogoBox = false, this.compact = false});

  final InvoicePreviewData data;
  final bool showLogoBox;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(child: Text(data.title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15))),
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (showLogoBox)
                Container(
                  width: 56,
                  height: 40,
                  color: Colors.grey.shade400,
                  alignment: Alignment.center,
                  child: const Text('LOGO', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(data.businessName, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                    Text('Phone: ${data.businessPhone}   Email: ${data.businessEmail}', style: const TextStyle(fontSize: 10)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Bill To:', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700)),
                    Text(data.customerName, style: const TextStyle(fontSize: 11)),
                    Text('Contact No: ${data.customerPhone}', style: const TextStyle(fontSize: 10)),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('Invoice No: ${data.invoiceNo}', style: const TextStyle(fontSize: 10)),
                  Text('Date: ${data.date}', style: const TextStyle(fontSize: 10)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),
          _ItemsTable(items: data.items, total: data.totalAmount),
          const SizedBox(height: 10),
          Align(
            alignment: Alignment.centerRight,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text('Total: ₹${data.totalAmount.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.w700)),
                Text('Received: ₹${data.receivedAmount.toStringAsFixed(2)}', style: const TextStyle(fontSize: 11)),
                Text(
                  'Balance: ₹${data.balanceDue.toStringAsFixed(2)}',
                  style: const TextStyle(fontSize: 11, color: Colors.green, fontWeight: FontWeight.w700),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// THEME: GST Theme 1
// ============================================================

class _GstInvoiceCard extends StatelessWidget {
  const _GstInvoiceCard({required this.data, required this.accent});
  final InvoicePreviewData data;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: accent.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(6)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(data.businessName, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13)),
                    Text('Phone no.: ${data.businessPhone}', style: const TextStyle(fontSize: 10)),
                    Text('Email: ${data.businessEmail}', style: const TextStyle(fontSize: 10)),
                  ],
                ),
              ),
              const Text('LOGO', style: TextStyle(fontSize: 10, color: Colors.grey)),
            ],
          ),
          const SizedBox(height: 10),
          Text(data.title, style: TextStyle(color: accent, fontWeight: FontWeight.w800, fontSize: 15)),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Bill To', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700)),
                  Text(data.customerName, style: const TextStyle(fontSize: 11)),
                  Text('Contact No.: ${data.customerPhone}', style: const TextStyle(fontSize: 10)),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Text('Invoice Details', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700)),
                  Text('Invoice No.: ${data.invoiceNo}', style: const TextStyle(fontSize: 10)),
                  Text('Date: ${data.date}', style: const TextStyle(fontSize: 10)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),
          _ItemsTable(items: data.items, total: data.totalAmount, headerColor: accent),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Expanded(
                child: Text('Invoice Amount In Words', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700)),
              ),
              Container(
                padding: const EdgeInsets.all(8),
                color: accent.withValues(alpha: 0.12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text('Total  ₹${data.totalAmount.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 11)),
                    Text('Received  ₹${data.receivedAmount.toStringAsFixed(2)}', style: const TextStyle(fontSize: 10)),
                    Text('Balance  ₹${data.balanceDue.toStringAsFixed(2)}', style: const TextStyle(fontSize: 10)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ============================================================
// THEME: Modern Elite
// ============================================================

class _ModernEliteCard extends StatelessWidget {
  const _ModernEliteCard({required this.data, required this.accent});
  final InvoicePreviewData data;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(data.businessName, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                  Text(data.businessPhone, style: const TextStyle(fontSize: 10, color: Colors.grey)),
                ],
              ),
              const Text('GENERATED ON\nJoyn', textAlign: TextAlign.right, style: TextStyle(fontSize: 8, color: Colors.grey)),
            ],
          ),
          const SizedBox(height: 14),
          Center(child: Text(data.title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15))),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Bill To:', style: TextStyle(fontSize: 10, color: Colors.grey)),
                  Text(data.customerName, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
                  Text(data.customerPhone, style: const TextStyle(fontSize: 10)),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('Invoice No: ${data.invoiceNo}', style: const TextStyle(fontSize: 10)),
                  Text('Date: ${data.date}', style: const TextStyle(fontSize: 10)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade300), borderRadius: BorderRadius.circular(10)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Pricing / Breakup', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12, color: accent)),
                const SizedBox(height: 8),
                _kv('Total Amount', '₹${data.totalAmount.toStringAsFixed(2)}', bold: true, color: accent),
                _kv('Received Amount', '₹${data.receivedAmount.toStringAsFixed(2)}'),
                _kv('Transaction Balance', '₹${data.balanceDue.toStringAsFixed(2)}'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _kv(String k, String v, {bool bold = false, Color? color}) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 2),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(k, style: const TextStyle(fontSize: 11, color: Colors.grey)),
        Text(v, style: TextStyle(fontSize: 11, fontWeight: bold ? FontWeight.w800 : FontWeight.w500, color: color)),
      ],
    ),
  );
}

// ============================================================
// THEME: Double Divine
// ============================================================

class _DoubleDivineCard extends StatelessWidget {
  const _DoubleDivineCard({required this.data, required this.accent});
  final InvoicePreviewData data;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            color: accent,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(data.businessName, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13)),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(data.businessPhone, style: const TextStyle(color: Colors.white, fontSize: 9)),
                    Text(data.businessEmail, style: const TextStyle(color: Colors.white, fontSize: 9)),
                  ],
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(data.title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Bill To', style: TextStyle(fontSize: 10, color: accent, fontWeight: FontWeight.w700)),
                        Text(data.customerName, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
                        Text('Contact No.: ${data.customerPhone}', style: const TextStyle(fontSize: 10)),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text('Invoice No.: ${data.invoiceNo}', style: const TextStyle(fontSize: 10)),
                        Text('Date: ${data.date}', style: const TextStyle(fontSize: 10)),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                _ItemsTable(items: data.items, total: data.totalAmount, headerColor: accent),
                const SizedBox(height: 10),
                Align(
                  alignment: Alignment.centerRight,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text('Total: ₹${data.totalAmount.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.w700)),
                      Text('Received: ₹${data.receivedAmount.toStringAsFixed(2)}', style: const TextStyle(fontSize: 11)),
                      Text('Balance: ₹${data.balanceDue.toStringAsFixed(2)}', style: const TextStyle(fontSize: 11)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}