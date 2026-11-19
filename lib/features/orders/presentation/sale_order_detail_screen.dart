// lib/features/orders/presentation/sale_order_detail_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/joyn_colors.dart';
import '../../../core/theme/joyn_typography.dart';
import '../models/sales_models.dart';
import '../data/sales_repository.dart';
import 'add_sale_order_screen.dart';
import 'package:share_plus/share_plus.dart';
import '../../../core/services/api_service.dart';
// ⚠️ Adjust this import path to wherever InvoicePreviewScreen actually lives in your project.
import 'package:joyn/features/invoice/presentation/InvoicePreviewScreen.dart';
import '../../business_profile/data/business_profile_repository.dart';
import '../../../core/services/local_storage_service.dart';

class _P {
  static const double rMd = 14;
  static const double rLg = 18;

  static List<BoxShadow> soft = [
    BoxShadow(
        color: Colors.black.withValues(alpha: 0.04),
        blurRadius: 16,
        offset: const Offset(0, 4)),
    BoxShadow(
        color: Colors.black.withValues(alpha: 0.02),
        blurRadius: 4,
        offset: const Offset(0, 1)),
  ];
  static List<BoxShadow> glow(Color color, double opacity) => [
    BoxShadow(
        color: color.withValues(alpha: opacity),
        blurRadius: 24,
        spreadRadius: -4,
        offset: const Offset(0, 8)),
  ];

  static LinearGradient get primaryGrad => LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color.lerp(JoynColors.primary, Colors.white, 0.20) ??
          JoynColors.primary,
      JoynColors.primary,
      Color.lerp(JoynColors.primary, Colors.black, 0.22) ??
          JoynColors.primary,
    ],
    stops: const [0.0, 0.5, 1.0],
  );
  static LinearGradient get heroGrad => LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color.lerp(JoynColors.primary, Colors.white, 0.05) ??
          JoynColors.primary,
      Color.lerp(JoynColors.primary, Colors.black, 0.15) ??
          JoynColors.primary,
    ],
  );
  static Color get infoSoft => JoynColors.primary.withValues(alpha: 0.08);
  static Color get successSoft => JoynColors.success.withValues(alpha: 0.10);
  static Color get errorSoft => JoynColors.error.withValues(alpha: 0.10);
  static Color get warningSoft =>
      const Color(0xFFF59E0B).withValues(alpha: 0.10);
  static const Color warningColor = Color(0xFFF59E0B);
}

class _HeroWavePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.06)
      ..style = PaintingStyle.fill;
    final path = Path();
    path.moveTo(0, size.height * 0.6);
    path.quadraticBezierTo(size.width * 0.25, size.height * 0.35,
        size.width * 0.5, size.height * 0.55);
    path.quadraticBezierTo(size.width * 0.75, size.height * 0.75,
        size.width, size.height * 0.4);
    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _AnimatedEntry extends StatefulWidget {
  final Widget child;
  final int delayMs;
  const _AnimatedEntry({required this.child, this.delayMs = 0});

  @override
  State<_AnimatedEntry> createState() => _AnimatedEntryState();
}

class _AnimatedEntryState extends State<_AnimatedEntry>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fade;
  late Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 480));
    _fade = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    _slide = Tween<Offset>(begin: const Offset(0, 0.05), end: Offset.zero)
        .animate(
        CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
    Future.delayed(Duration(milliseconds: widget.delayMs), () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fade,
      child: SlideTransition(position: _slide, child: widget.child),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  const _SectionCard({required this.child, this.padding});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: padding ?? const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(_P.rLg),
        boxShadow: _P.soft,
        border: Border.all(color: JoynColors.border.withValues(alpha: 0.4)),
      ),
      child: child,
    );
  }
}

// ==================== Main Screen ====================
class SaleOrderDetailScreen extends StatefulWidget {
  final SaleOrderModel order;
  final VoidCallback? onChanged; // ✅ callback for list refresh

  const SaleOrderDetailScreen({
    super.key,
    required this.order,
    this.onChanged,
  });

  @override
  State<SaleOrderDetailScreen> createState() => _SaleOrderDetailScreenState();
}

class _SaleOrderDetailScreenState extends State<SaleOrderDetailScreen> {
  final SalesRepository _salesRepository = SalesRepository();
  late SaleOrderModel _order;
  List<OrderItemModel> _items = [];

  @override
  void initState() {
    super.initState();
    _order = widget.order;
    _parseItems();
  }

  void _parseItems() {
    try {
      _items =
          _order.items.map((map) => OrderItemModel.fromJson(map)).toList();
    } catch (e) {
      debugPrint('Error parsing items: $e');
    }
  }

  // ==================== CALCULATIONS ====================
  double get _subtotal => _items.fold(0.0, (s, i) => s + i.subtotal);

  double get _totalDiscount =>
      _items.fold(0.0, (s, i) => s + i.discountAmount);

  double get _totalTax => _items.fold(0.0, (s, i) => s + i.taxAmount);

  int get _totalQty => _items.fold(0, (s, i) => s + i.qty);

  double get _totalAmount => _items.fold(0.0, (s, i) => s + i.total);

  double get _receivedAmount => _order.receivedAmount;

  double get _balanceDue {
    final due = _totalAmount - _receivedAmount;
    return due < 0 ? 0 : due;
  }

  bool get _isPaid => _balanceDue <= 0;
  bool get _isCredit => _order.paymentMode.toLowerCase() == 'credit';

  String get _effectiveTaxRate {
    if (_subtotal <= 0 || _totalTax <= 0) return '0';
    return ((_totalTax / _subtotal) * 100).toStringAsFixed(2);
  }

  // ==================== ACTIONS ====================
  Future<void> _deleteOrder() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Text('Delete Sale?',
            style: JoynTypography.titleMedium
                .copyWith(fontSize: 17, fontWeight: FontWeight.w700)),
        content: Text(
          'Delete Invoice #${_order.invoiceNo} for ${_order.customerName}?',
          style: JoynTypography.bodyMedium.copyWith(
              fontSize: 13.5, color: JoynColors.secondaryText),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Delete',
                style: TextStyle(
                    color: JoynColors.error, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _salesRepository.deleteSaleOrder(_order.id);
      if (!mounted) return;

      widget.onChanged?.call();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Sale deleted successfully!'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: JoynColors.error,
          margin: const EdgeInsets.all(16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
      );
      Navigator.of(context).pop(true);
    }
  }

  Future<void> _editOrder() async {
    HapticFeedback.lightImpact();

    final result = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => AddSaleOrderScreen(existingOrder: _order),
      ),
    );

    if (result != null && mounted) {
      final orders = await _salesRepository.getSaleOrders();
      final updated = orders.firstWhere(
            (o) => o.id == _order.id,
        orElse: () => _order,
      );
      setState(() {
        _order = updated;
        _parseItems();
      });

      widget.onChanged?.call();

      if (mounted) {
        HapticFeedback.mediumImpact();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Updated successfully!'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: JoynColors.success,
            margin: const EdgeInsets.all(16),
            shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
        );
      }
    }
  }

  void _shareOrder() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: JoynColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.share_rounded, color: JoynColors.primary, size: 22),
                ),
                const SizedBox(width: 12),
                Text(
                  'Share Invoice #${_order.invoiceNo}',
                  style: JoynTypography.titleMedium.copyWith(fontWeight: FontWeight.w800),
                ),
              ],
            ),
            const SizedBox(height: 18),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: const Color(0xFF25D366).withValues(alpha: 0.15), shape: BoxShape.circle),
                child: const Icon(Icons.chat_rounded, color: Color(0xFF25D366), size: 20),
              ),
              title: const Text('Share Link on WhatsApp / SMS', style: TextStyle(fontWeight: FontWeight.w700)),
              subtitle: const Text('Includes public bill link and amount breakdown'),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              tileColor: const Color(0xFFF8FAFC),
              onTap: () async {
                Navigator.pop(ctx);
                try {
                  final res = await ApiService.getWhatsAppShareLink(_order.invoiceNo.toString());
                  if (res['success'] == true && res['whatsappText'] != null) {
                    Share.share(res['whatsappText'], subject: 'Tax Invoice INV-${_order.invoiceNo}');
                  } else {
                    Share.share('Tax Invoice INV-${_order.invoiceNo}\nTotal: ₹${_order.totalAmount}');
                  }
                } catch (_) {
                  Share.share('Tax Invoice INV-${_order.invoiceNo}\nTotal: ₹${_order.totalAmount}');
                }
              },
            ),
            const SizedBox(height: 10),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: JoynColors.primary.withValues(alpha: 0.1), shape: BoxShape.circle),
                child: const Icon(Icons.picture_as_pdf_rounded, color: JoynColors.primary, size: 20),
              ),
              title: const Text('View Full PDF & Print', style: TextStyle(fontWeight: FontWeight.w700)),
              subtitle: const Text('Preview layout, custom templates & direct printing'),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              tileColor: const Color(0xFFF8FAFC),
              onTap: () async {
                Navigator.pop(ctx);
                final profile = await BusinessProfileRepository().getBusinessProfile();

                String custPhone = _order.customerPhone;
                String custAddress = '';
                if (!_order.isOneTimeCustomer && _order.partyId.isNotEmpty) {
                  try {
                    final party = await _salesRepository.getPartyById(_order.partyId);
                    if (party != null) {
                      if (custPhone.isEmpty && party.contactNumber.isNotEmpty) {
                        custPhone = party.contactNumber;
                      }
                      custAddress = [
                        if (party.address.isNotEmpty) party.address,
                        if (party.city.isNotEmpty) party.city,
                      ].join(', ');
                    }
                  } catch (_) {}
                }

                final bizAddr = [
                  if (profile?.address.isNotEmpty == true) profile!.address,
                  if (profile?.city.isNotEmpty == true) profile!.city,
                  if (profile?.state.isNotEmpty == true) profile!.state,
                  if (profile?.pincode.isNotEmpty == true) profile!.pincode,
                ].join(', ');

                final resolvedBusinessName = (profile?.businessName.isNotEmpty == true && profile!.businessName != 'My Business')
                    ? profile!.businessName
                    : (LocalStorageService().businessName.isNotEmpty
                        ? LocalStorageService().businessName
                        : 'JOYN Enterprise');

                if (!mounted) return;
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => InvoicePreviewScreen(
                      data: InvoicePreviewData(
                        invoiceNo: _order.invoiceNo,
                        date: _order.date,
                        customerName: _order.isOneTimeCustomer
                            ? 'One Time Customer'
                            : (_order.customerName.isNotEmpty ? _order.customerName : 'Customer'),
                        customerPhone: _order.isOneTimeCustomer ? '' : custPhone,
                        customerAddress: custAddress,
                        items: _items,
                        totalAmount: _totalAmount,
                        receivedAmount: _receivedAmount,
                        businessName: resolvedBusinessName,
                        businessPhone: profile?.phone1 ?? LocalStorageService().phoneNumber,
                        businessEmail: profile?.email ?? LocalStorageService().email,
                        businessAddress: bizAddr,
                        businessGstin: profile?.gstNumber ?? '',
                        stateOfSupply: _order.stateOfSupply,
                        paymentMode: _order.paymentType,
                        termsAndConditions: _order.termsAndConditions,
                        logoPath: profile?.logoPath,
                        logoUrl: profile?.logoUrl,
                        bankName: profile?.bankName ?? '',
                        accountNumber: profile?.accountNumber ?? '',
                        ifscCode: profile?.ifscCode ?? '',
                        upiId: profile?.upiId ?? '',
                        title: 'Tax Invoice',
                      ),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: JoynColors.background,
      // ✅ Poori screen ab ek hi scroll view mein — header bhi scroll ke saath jayega
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildHeroHeader(),
                  const SizedBox(height: 12),
                  _AnimatedEntry(
                      delayMs: 0, child: _buildCustomerSection()),
                  const SizedBox(height: 12),
                  _AnimatedEntry(delayMs: 60, child: _buildItemsSection()),
                  const SizedBox(height: 12),
                  _AnimatedEntry(
                      delayMs: 120, child: _buildSummarySection()),
                  const SizedBox(height: 12),
                  _AnimatedEntry(
                      delayMs: 180, child: _buildPaymentSection()),
                  if (_order.description.isNotEmpty ||
                      _order.termsAndConditions.isNotEmpty ||
                      _order.stateOfSupply.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    _AnimatedEntry(
                        delayMs: 240, child: _buildAdditionalSection()),
                  ],
                  const SizedBox(height: 12),
                  _AnimatedEntry(
                      delayMs: 300, child: _buildMetaSection()),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
          _buildBottomBar(),
        ],
      ),
    );
  }

  // ==================== Hero Header (chota / compact) ====================
  Widget _buildHeroHeader() {
    return Container(
      decoration: BoxDecoration(
        gradient: _P.heroGrad,
        boxShadow: _P.glow(JoynColors.primary, 0.25),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
      ),
      child: Stack(
        children: [
          Positioned.fill(child: CustomPaint(painter: _HeroWavePainter())),
          SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 14),
              child: Column(
                children: [
                  Row(
                    children: [
                      InkWell(
                        borderRadius: BorderRadius.circular(18),
                        onTap: () => Navigator.of(context).pop(true),
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.15),
                            shape: BoxShape.circle,
                            border: Border.all(
                                color: Colors.white.withValues(alpha: 0.2)),
                          ),
                          child: const Icon(Icons.arrow_back,
                              color: Colors.white, size: 16),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Sale Details',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 17,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: -0.3,
                                )),
                            const SizedBox(height: 1),
                            Text(
                              'Invoice #${_order.invoiceNo}  •  ${_order.date}',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.75),
                                fontSize: 11.5,
                                fontWeight: FontWeight.w600,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      _buildHeaderIconBtn(
                        icon: Icons.share_rounded,
                        onTap: _shareOrder,
                      ),
                      const SizedBox(width: 6),
                      _buildHeaderIconBtn(
                        icon: Icons.edit_outlined,
                        onTap: _editOrder,
                      ),
                      const SizedBox(width: 6),
                      _buildHeaderIconBtn(
                        icon: Icons.delete_outline_rounded,
                        onTap: _deleteOrder,
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _buildHeroStat(
                          icon: Icons.currency_rupee_rounded,
                          label: 'Total',
                          value: '₹${_totalAmount.toStringAsFixed(0)}',
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildHeroStat(
                          icon: Icons.payments_outlined,
                          label: 'Received',
                          value: '₹${_receivedAmount.toStringAsFixed(0)}',
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildHeroStat(
                          icon: _isPaid
                              ? Icons.check_circle_outline
                              : Icons.warning_amber_rounded,
                          label: _isPaid ? 'Paid' : 'Due',
                          value: '₹${_balanceDue.toStringAsFixed(0)}',
                          danger: !_isPaid,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                            color: Colors.white.withValues(alpha: 0.2)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _isCredit
                                ? Icons.account_balance_wallet_outlined
                                : Icons.payments_outlined,
                            color: Colors.white,
                            size: 12,
                          ),
                          const SizedBox(width: 5),
                          Text(
                            '${_order.paymentMode}  •  ${_order.paymentType}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
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

  Widget _buildHeaderIconBtn({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.15),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
        ),
        child: Icon(icon, color: Colors.white, size: 15),
      ),
    );
  }

  Widget _buildHeroStat({
    required IconData icon,
    required String label,
    required String value,
    bool danger = false,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon,
                  size: 11, color: Colors.white.withValues(alpha: 0.85)),
              const SizedBox(width: 4),
              Text(label,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.75),
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  )),
            ],
          ),
          const SizedBox(height: 3),
          Text(value,
              style: TextStyle(
                color: danger ? const Color(0xFFFFB4AB) : Colors.white,
                fontSize: 13.5,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.2,
              )),
        ],
      ),
    );
  }

  // ==================== Sections ====================
  Widget _buildCustomerSection() {
    return _SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeader(
            icon: Icons.person_outline_rounded,
            title: 'Customer Details',
          ),
          const SizedBox(height: 16),
          _detailRow('Customer Name',
              _order.customerName.isEmpty ? '—' : _order.customerName),
          if (_order.customerPhone.isNotEmpty)
            _detailRow('Phone Number', _order.customerPhone),
          if (_order.partyId.isNotEmpty)
            _detailRow('Party ID', _order.partyId),
        ],
      ),
    );
  }

  Widget _buildItemsSection() {
    return _SectionCard(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                colors: [
                  JoynColors.primary.withValues(alpha: 0.14),
                  JoynColors.primary.withValues(alpha: 0.04),
                ],
              ),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(_P.rLg),
                topRight: Radius.circular(_P.rLg),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    gradient: _P.primaryGrad,
                    shape: BoxShape.circle,
                    boxShadow: _P.glow(JoynColors.primary, 0.35),
                  ),
                  child: const Icon(Icons.check_rounded,
                      size: 14, color: Colors.white),
                ),
                const SizedBox(width: 10),
                Text('Billed Items',
                    style: JoynTypography.bodyMedium.copyWith(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: JoynColors.primary,
                        letterSpacing: 0.1)),
                const SizedBox(width: 8),
                Container(
                  padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.9),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                        color: JoynColors.primary.withValues(alpha: 0.15)),
                  ),
                  child: Text('$_totalQty',
                      style: JoynTypography.caption.copyWith(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: JoynColors.primary)),
                ),
                const Spacer(),
                Text('${_items.length} items',
                    style: JoynTypography.caption.copyWith(
                        fontSize: 11.5,
                        color: JoynColors.secondaryText,
                        fontWeight: FontWeight.w600)),
              ],
            ),
          ),
          if (_items.isEmpty)
            Padding(
              padding: const EdgeInsets.all(24),
              child: Center(
                child: Text('No items',
                    style: JoynTypography.bodyMedium
                        .copyWith(color: JoynColors.secondaryText)),
              ),
            )
          else
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                children: _items
                    .asMap()
                    .entries
                    .map((e) => _buildDetailItemCard(e.value, e.key))
                    .toList(),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildDetailItemCard(OrderItemModel item, int index) {
    final subtotal = item.unitPrice * item.qty;
    final discountPercent = subtotal > 0
        ? ((item.discountAmount / subtotal) * 100).toStringAsFixed(1)
        : '0';
    final afterDiscount = subtotal - item.discountAmount;
    final finalTotal = afterDiscount + item.taxAmount;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: JoynColors.chipBackground,
        borderRadius: BorderRadius.circular(_P.rMd),
        border: Border.all(color: JoynColors.border.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding:
                const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  gradient: _P.primaryGrad,
                  borderRadius: BorderRadius.circular(6),
                  boxShadow: _P.glow(JoynColors.primary, 0.25),
                ),
                child: Text('#${index + 1}',
                    style: JoynTypography.caption.copyWith(
                        fontSize: 11,
                        color: Colors.white,
                        fontWeight: FontWeight.w800)),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(item.itemName,
                    style: JoynTypography.bodyLarge.copyWith(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.2,
                        color: JoynColors.primary)),
              ),
              Container(
                padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: _P.successSoft,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                      color: JoynColors.success.withValues(alpha: 0.2)),
                ),
                child: Text('₹${finalTotal.toStringAsFixed(2)}',
                    style: JoynTypography.bodyMedium.copyWith(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: JoynColors.success)),
              ),
            ],
          ),
          if (item.category.isNotEmpty) ...[
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: _P.infoSoft,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(item.category,
                  style: JoynTypography.caption.copyWith(
                      fontSize: 10.5,
                      color: JoynColors.primary,
                      fontWeight: FontWeight.w700)),
            ),
          ],
          const SizedBox(height: 12),
          _itemDetailRow(
            'Quantity',
            '${item.qty} ${item.unit.isNotEmpty ? item.unit : ''}',
          ),
          _itemDetailRow(
            'Unit Price',
            '₹${item.unitPrice.toStringAsFixed(2)}',
          ),
          _itemDetailRow(
            'Subtotal (${item.qty} × ₹${item.unitPrice.toStringAsFixed(2)})',
            '₹${subtotal.toStringAsFixed(2)}',
            valueColor: JoynColors.primary,
          ),
          if (item.discountAmount > 0) ...[
            _itemDetailRow(
              'Discount ($discountPercent%)',
              '-₹${item.discountAmount.toStringAsFixed(2)}',
              valueColor: JoynColors.error,
            ),
            _itemDetailRow(
              'After Discount',
              '₹${afterDiscount.toStringAsFixed(2)}',
              valueColor: JoynColors.secondaryText,
            ),
          ],
          if (item.taxAmount > 0)
            _itemDetailRow(
              'Tax @${item.taxRate.toStringAsFixed(2)}%',
              '+₹${item.taxAmount.toStringAsFixed(2)}',
              valueColor: _P.warningColor,
            ),
          Container(
            height: 1,
            margin: const EdgeInsets.symmetric(vertical: 8),
            color: JoynColors.border.withValues(alpha: 0.4),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Item Total',
                  style: JoynTypography.bodyMedium.copyWith(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w800,
                      color: JoynColors.primary)),
              Text('₹${finalTotal.toStringAsFixed(2)}',
                  style: JoynTypography.bodyMedium.copyWith(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: JoynColors.primary)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummarySection() {
    final afterDiscount = _subtotal - _totalDiscount;

    return _SectionCard(
      child: Column(
        children: [
          _sectionHeader(
            icon: Icons.summarize_outlined,
            title: 'Summary',
          ),
          const SizedBox(height: 16),
          _summaryRow('Subtotal', _subtotal),
          if (_totalDiscount > 0)
            _summaryRow('Total Discount', -_totalDiscount,
                color: JoynColors.error),
          if (_totalDiscount > 0)
            _summaryRow('After Discount', afterDiscount,
                color: JoynColors.secondaryText),
          if (_totalTax > 0)
            _summaryRow(
              'Total Tax (${_effectiveTaxRate}%)',
              _totalTax,
              color: _P.warningColor,
            ),
          Container(
            height: 1,
            margin: const EdgeInsets.symmetric(vertical: 12),
            color: JoynColors.border.withValues(alpha: 0.4),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Total Amount',
                  style: JoynTypography.bodyLarge.copyWith(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: JoynColors.primary)),
              Text('₹${_totalAmount.toStringAsFixed(2)}',
                  style: JoynTypography.bodyLarge.copyWith(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: JoynColors.primary)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentSection() {
    final dueColor = _isPaid ? JoynColors.success : JoynColors.error;

    return _SectionCard(
      child: Column(
        children: [
          _sectionHeader(
            icon: Icons.receipt_long_outlined,
            title: 'Payment Summary',
          ),
          const SizedBox(height: 16),
          _detailRow(
            'Payment Mode',
            _order.paymentMode,
            valueColor: _isCredit ? JoynColors.error : JoynColors.success,
          ),
          if (_order.paymentType.isNotEmpty)
            _detailRow('Payment Type', _order.paymentType),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: JoynColors.chipBackground,
              borderRadius: BorderRadius.circular(_P.rMd),
            ),
            child: Column(
              children: [
                _detailRow('Total Amount',
                    '₹${_totalAmount.toStringAsFixed(2)}'),
                const SizedBox(height: 6),
                _detailRow('Received Amount',
                    '₹${_receivedAmount.toStringAsFixed(2)}',
                    valueColor: JoynColors.success),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  dueColor.withValues(alpha: 0.10),
                  dueColor.withValues(alpha: 0.05),
                ],
              ),
              borderRadius: BorderRadius.circular(_P.rMd),
              border: Border.all(color: dueColor.withValues(alpha: 0.25)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: dueColor,
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: _P.glow(dueColor, 0.35),
                  ),
                  child: Icon(
                      _isPaid ? Icons.check_circle : Icons.trending_up,
                      color: Colors.white,
                      size: 16),
                ),
                const SizedBox(width: 12),
                Text('Balance Due',
                    style: JoynTypography.bodyMedium.copyWith(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: dueColor,
                        letterSpacing: 0.1)),
                const Spacer(),
                Text('₹${_balanceDue.toStringAsFixed(2)}',
                    style: JoynTypography.bodyLarge.copyWith(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: dueColor)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAdditionalSection() {
    return _SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeader(
            icon: Icons.tune_rounded,
            title: 'Additional Details',
          ),
          const SizedBox(height: 16),
          if (_order.stateOfSupply.isNotEmpty)
            _detailRow('State of Supply', _order.stateOfSupply),
          if (_order.description.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text('Description / Note',
                style: JoynTypography.caption.copyWith(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: JoynColors.secondaryText,
                    letterSpacing: 0.2)),
            const SizedBox(height: 6),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: JoynColors.chipBackground,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(_order.description,
                  style: JoynTypography.bodyMedium.copyWith(
                      fontSize: 13.5, height: 1.5)),
            ),
          ],
          if (_order.termsAndConditions.isNotEmpty) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.gavel_rounded,
                    size: 14, color: JoynColors.secondaryText),
                const SizedBox(width: 6),
                Text('Terms & Conditions',
                    style: JoynTypography.caption.copyWith(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: JoynColors.secondaryText,
                        letterSpacing: 0.2)),
              ],
            ),
            const SizedBox(height: 6),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: JoynColors.chipBackground,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(_order.termsAndConditions,
                  style: JoynTypography.bodyMedium.copyWith(
                      fontSize: 12.5, height: 1.5)),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMetaSection() {
    return _SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeader(
            icon: Icons.info_outline,
            title: 'Metadata',
          ),
          const SizedBox(height: 16),
          _detailRow('Order ID', _order.id),
          _detailRow('Invoice No.', '#${_order.invoiceNo}'),
          _detailRow('Created', _formatDateTime(_order.createdAt)),
          _detailRow('One-time Customer',
              _order.isOneTimeCustomer ? 'Yes' : 'No'),
        ],
      ),
    );
  }

  // ==================== Row Helpers ====================
  Widget _sectionHeader({
    required IconData icon,
    required String title,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: _P.infoSoft,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 14, color: JoynColors.primary),
        ),
        const SizedBox(width: 8),
        Text(title,
            style: JoynTypography.bodyLarge.copyWith(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.2,
                color: JoynColors.primary)),
      ],
    );
  }

  Widget _detailRow(String label, String value, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130,
            child: Text(label,
                style: JoynTypography.bodyMedium.copyWith(
                    fontSize: 13,
                    color: JoynColors.secondaryText,
                    fontWeight: FontWeight.w600)),
          ),
          Expanded(
            child: Text(value,
                textAlign: TextAlign.right,
                style: JoynTypography.bodyMedium.copyWith(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                    color: valueColor ?? Colors.black87)),
          ),
        ],
      ),
    );
  }

  Widget _itemDetailRow(String label, String value,
      {Color? valueColor, bool bold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Flexible(
            child: Text(label,
                style: JoynTypography.caption.copyWith(
                    fontSize: 12,
                    color: JoynColors.secondaryText,
                    fontWeight: FontWeight.w600)),
          ),
          const SizedBox(width: 8),
          Text(value,
              style: JoynTypography.caption.copyWith(
                  fontSize: 12.5,
                  fontWeight: bold ? FontWeight.w800 : FontWeight.w700,
                  color: valueColor ?? Colors.black87)),
        ],
      ),
    );
  }

  Widget _summaryRow(String label, double value, {Color? color}) {
    final isNegative = value < 0;
    final display = isNegative
        ? '-₹${value.abs().toStringAsFixed(2)}'
        : '₹${value.toStringAsFixed(2)}';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: JoynTypography.bodyMedium.copyWith(
                  fontSize: 13.5,
                  color: JoynColors.secondaryText,
                  fontWeight: FontWeight.w600)),
          Text(display,
              style: JoynTypography.bodyMedium.copyWith(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w800,
                  color: color ?? Colors.black87)),
        ],
      ),
    );
  }

  String _formatDateTime(DateTime dt) {
    final d = dt.day.toString().padLeft(2, '0');
    final m = dt.month.toString().padLeft(2, '0');
    final y = dt.year;
    final h = dt.hour.toString().padLeft(2, '0');
    final min = dt.minute.toString().padLeft(2, '0');
    return '$d/$m/$y • $h:$min';
  }

  Widget _buildBottomBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 24,
              offset: const Offset(0, -8)),
        ],
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Expanded(
              child: SizedBox(
                height: 52,
                child: OutlinedButton.icon(
                  onPressed: _deleteOrder,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: JoynColors.error,
                    side: BorderSide(
                        color: JoynColors.error.withValues(alpha: 0.3),
                        width: 1.5),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(_P.rMd)),
                  ),
                  icon: const Icon(Icons.delete_outline_rounded, size: 18),
                  label: Text('Delete',
                      style: JoynTypography.caption.copyWith(
                          fontSize: 14,
                          color: JoynColors.error,
                          fontWeight: FontWeight.w700)),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 2,
              child: Container(
                height: 52,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(_P.rMd),
                  boxShadow: _P.glow(JoynColors.primary, 0.35),
                ),
                child: ElevatedButton.icon(
                  onPressed: _shareOrder,
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.zero,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(_P.rMd)),
                    elevation: 0,
                    backgroundColor: Colors.transparent,
                  ),
                  icon: const Icon(Icons.share_rounded,
                      color: Colors.white, size: 18),
                  label: Text('Share Invoice',
                      style: JoynTypography.bodyMedium.copyWith(
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          fontSize: 15,
                          letterSpacing: 0.2)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}