import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/joyn_colors.dart';
import '../../../core/theme/joyn_typography.dart';
import '../../orders/models/sales_models.dart';
import '../../orders/data/sales_repository.dart';
import 'add_new_party_screen.dart';
import 'sale_form_screen.dart';
import 'payment_in_screen.dart';

// =====================================================================
// PREMIUM DESIGN SYSTEM — Diamond Edition
// =====================================================================
class _Premium {
  static List<BoxShadow> cardShadow = [
    BoxShadow(color: Colors.black.withValues(alpha: 0.018), blurRadius: 2, offset: const Offset(0, 1)),
    BoxShadow(color: Colors.black.withValues(alpha: 0.026), blurRadius: 6, offset: const Offset(0, 2)),
    BoxShadow(color: Colors.black.withValues(alpha: 0.030), blurRadius: 14, offset: const Offset(0, 6)),
  ];

  static List<BoxShadow> heroShadow = [
    BoxShadow(color: Colors.black.withValues(alpha: 0.09), blurRadius: 5, offset: const Offset(0, 2)),
    BoxShadow(color: Colors.black.withValues(alpha: 0.10), blurRadius: 18, offset: const Offset(0, 8)),
  ];

  static List<BoxShadow> softShadow = [
    BoxShadow(color: Colors.black.withValues(alpha: 0.025), blurRadius: 3, offset: const Offset(0, 1)),
    BoxShadow(color: Colors.black.withValues(alpha: 0.035), blurRadius: 12, offset: const Offset(0, 4)),
  ];

  static List<BoxShadow> hairlineShadow = [
    BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 6, offset: const Offset(0, 2)),
  ];

  static List<BoxShadow> chipShadow(Color color) => [
    BoxShadow(color: color.withValues(alpha: 0.18), blurRadius: 5, offset: const Offset(0, 2)),
    BoxShadow(color: color.withValues(alpha: 0.22), blurRadius: 12, offset: const Offset(0, 5)),
  ];

  static List<BoxShadow> softGlow(Color color) => [
    BoxShadow(color: color.withValues(alpha: 0.24), blurRadius: 12, spreadRadius: 1, offset: const Offset(0, 4)),
    BoxShadow(color: color.withValues(alpha: 0.14), blurRadius: 26, offset: const Offset(0, 10)),
  ];

  static LinearGradient gradient(Color color) => LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color.lerp(color, Colors.white, 0.08) ?? color,
      color,
      Color.lerp(color, Colors.black, 0.22) ?? color,
    ],
    stops: const [0.0, 0.5, 1.0],
  );

  static LinearGradient deepGradient(Color color) => LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [color, Color.lerp(color, Colors.black, 0.32) ?? color],
  );

  static LinearGradient softGradient(Color color) => LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [color.withValues(alpha: 0.12), color.withValues(alpha: 0.04)],
  );

  static LinearGradient surfaceGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Colors.white, Color.lerp(Colors.white, JoynColors.background, 0.55) ?? Colors.white],
  );

  static LinearGradient topHighlight = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Colors.white.withValues(alpha: 0.18), Colors.transparent],
  );

  static Border hairline({double width = 1.0, double alpha = 1}) =>
      Border.all(color: JoynColors.border.withValues(alpha: alpha), width: width);
}

// =====================================================================
// ACTIVITY — merged Sales + Purchases timeline
// =====================================================================
enum _ActivityKind { sale, purchase }
enum _ActivityFilter { all, sales, purchases }

class _ActivityEntry {
  const _ActivityEntry({
    required this.kind,
    required this.id,
    required this.refNo,
    required this.date,
    required this.total,
    required this.balanceDue,
    this.sale,
    this.purchase,
  });

  final _ActivityKind kind;
  final String id;
  final String refNo;
  final String date;
  final double total;
  final double balanceDue;
  final SaleOrderModel? sale;
  final PurchaseOrderModel? purchase;

  bool get isSale => kind == _ActivityKind.sale;
  bool get isPaid => balanceDue <= 0.01;
}

DateTime _parseActivityDate(String s) {
  final iso = DateTime.tryParse(s);
  if (iso != null) return iso;
  final parts = s.split(RegExp(r'[/\-.]'));
  if (parts.length == 3) {
    final a = int.tryParse(parts[0]);
    final b = int.tryParse(parts[1]);
    final c = int.tryParse(parts[2]);
    if (a != null && b != null && c != null) {
      if (a > 31) return DateTime(a, b, c);
      return DateTime(c, b, a);
    }
  }
  return DateTime(1970);
}

// =====================================================================
// PRESSABLE
// =====================================================================
class _Pressable extends StatefulWidget {
  const _Pressable({
    required this.child,
    required this.onTap,
    this.scale = 0.97,
    this.borderRadius = 18,
  });
  final Widget child;
  final VoidCallback onTap;
  final double scale;
  final double borderRadius;

  @override
  State<_Pressable> createState() => _PressableState();
}

class _PressableState extends State<_Pressable> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      onTap: () {
        HapticFeedback.selectionClick();
        widget.onTap();
      },
      child: AnimatedScale(
        scale: _pressed ? widget.scale : 1.0,
        duration: const Duration(milliseconds: 130),
        curve: Curves.easeOut,
        child: widget.child,
      ),
    );
  }
}

// =====================================================================
// STAGGERED ENTRANCE
// =====================================================================
class _StaggeredItem extends StatefulWidget {
  const _StaggeredItem({required this.index, required this.child});
  final int index;
  final Widget child;

  @override
  State<_StaggeredItem> createState() => _StaggeredItemState();
}

class _StaggeredItemState extends State<_StaggeredItem>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 440),
  );

  late final Animation<double> _fade =
  CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic);

  late final Animation<Offset> _slide = Tween<Offset>(
    begin: const Offset(0, 0.08),
    end: Offset.zero,
  ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));

  @override
  void initState() {
    super.initState();
    final delay = Duration(milliseconds: (widget.index * 55).clamp(0, 600));
    Future.delayed(delay, () {
      if (mounted) _ctrl.forward();
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
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

// =====================================================================
// PULSING DOT
// =====================================================================
class _PulsingDot extends StatefulWidget {
  const _PulsingDot({required this.color, this.size = 8});
  final Color color;
  final double size;

  @override
  State<_PulsingDot> createState() => _PulsingDotState();
}

class _PulsingDotState extends State<_PulsingDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1600),
  )..repeat();

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.size * 2.6,
      height: widget.size * 2.6,
      child: AnimatedBuilder(
        animation: _ctrl,
        builder: (context, _) {
          final t = _ctrl.value;
          return Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: widget.size + (widget.size * 1.6 * t),
                height: widget.size + (widget.size * 1.6 * t),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: widget.color.withValues(alpha: (1 - t) * 0.35),
                ),
              ),
              Container(
                width: widget.size,
                height: widget.size,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: widget.color,
                  boxShadow: [
                    BoxShadow(
                      color: widget.color.withValues(alpha: 0.55),
                      blurRadius: 8,
                      spreadRadius: 0.5,
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

// =====================================================================
// FLOATING AVATAR
// =====================================================================
class _FloatingAvatar extends StatefulWidget {
  const _FloatingAvatar({required this.child, this.delayMs = 0});
  final Widget child;
  final int delayMs;

  @override
  State<_FloatingAvatar> createState() => _FloatingAvatarState();
}

class _FloatingAvatarState extends State<_FloatingAvatar>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2400),
  );

  @override
  void initState() {
    super.initState();
    Future.delayed(Duration(milliseconds: widget.delayMs), () {
      if (mounted) _ctrl.repeat(reverse: true);
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, child) {
        final offset = Curves.easeInOut.transform(_ctrl.value) * 1.5 - 0.75;
        return Transform.translate(offset: Offset(0, offset), child: child);
      },
      child: widget.child,
    );
  }
}

// =====================================================================
// MAIN SCREEN
// =====================================================================
class PartyDetailScreen extends StatefulWidget {
  const PartyDetailScreen({super.key, required this.party});

  final PartyModel party;

  @override
  State<PartyDetailScreen> createState() => _PartyDetailScreenState();
}

class _PartyDetailScreenState extends State<PartyDetailScreen> {
  final SalesRepository _salesRepository = SalesRepository();

  late PartyModel _party = widget.party;
  List<SaleOrderModel> _sales = [];
  List<PurchaseOrderModel> _purchases = [];
  bool _isLoading = true;
  double _balance = 0;
  bool _isReceivable = true;
  _ActivityFilter _filter = _ActivityFilter.all;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    try {
      final results = await Future.wait([
        _salesRepository.getSaleOrdersForParty(_party.id, _party.name),
        _salesRepository.getPurchaseOrdersForParty(_party.id, _party.name),
        _salesRepository.getPartyBalance(_party.id),
      ]);

      if (!mounted) return;

      final sales = results[0] as List<SaleOrderModel>;
      final purchases = results[1] as List<PurchaseOrderModel>;
      final info = results[2] as Map<String, dynamic>;

      setState(() {
        _sales = sales;
        _purchases = purchases;
        _balance = info['balance'] as double;
        _isReceivable = info['isReceivable'] as bool;
        _isLoading = false;
      });
    } catch (e, st) {
      debugPrint('❌❌❌ _loadData ERROR: $e');
      debugPrint('$st');
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  // Total stats (sirf sales)
  double get _totalSales => _sales.fold(0.0, (sum, s) => sum + s.totalAmount);
  double get _totalPaid =>
      _sales.fold(0.0, (sum, s) => sum + (s.totalAmount - s.balanceDue));
  double get _totalDue => _sales.fold(0.0, (sum, s) => sum + s.balanceDue);

  // -------- Merged activity timeline --------
  List<_ActivityEntry> get _allActivities {
    final list = <_ActivityEntry>[
      ..._sales.map((s) => _ActivityEntry(
        kind: _ActivityKind.sale,
        id: s.id,
        refNo: s.invoiceNo.toString(),
        date: s.date,
        total: s.totalAmount,
        balanceDue: s.balanceDue,
        sale: s,
      )),
      ..._purchases.map((p) => _ActivityEntry(
        kind: _ActivityKind.purchase,
        id: p.id,
        refNo: p.orderNo.toString(),
        date: p.date,
        total: p.totalAmount,
        balanceDue: p.totalAmount,
        purchase: p,
      )),
    ];
    list.sort((a, b) =>
        _parseActivityDate(b.date).compareTo(_parseActivityDate(a.date)));
    return list;
  }

  List<_ActivityEntry> get _visibleActivities {
    switch (_filter) {
      case _ActivityFilter.sales:
        return _allActivities.where((e) => e.isSale).toList();
      case _ActivityFilter.purchases:
        return _allActivities.where((e) => !e.isSale).toList();
      case _ActivityFilter.all:
        return _allActivities;
    }
  }

  Future<void> _openEdit() async {
    HapticFeedback.lightImpact();
    final updatedData = await Navigator.of(context).push<Map<String, dynamic>>(
      MaterialPageRoute(builder: (_) => AddNewPartyScreen(existingParty: _party)),
    );
    if (updatedData == null || !mounted) return;

    setState(() {
      _party = _party.copyWith(
        name: (updatedData['name'] as String?)?.trim().isNotEmpty == true
            ? updatedData['name']
            : null,
        category: updatedData['category'] as String?,
        contactNumber: updatedData['contactNumber'] as String?,
        email: updatedData['email'] as String?,
        address: updatedData['billingAddress'] as String?,
        city: updatedData['city'] as String?,
        partyType: updatedData['partyType'] as String?,
        priorityLevel: updatedData['priorityLevel'] as String?,
        photoPath: updatedData['photoPath'] as String?,
        avatarIndex: updatedData['avatarIndex'] as int?,
      );
    });
    _loadData();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Party updated'),
          backgroundColor: JoynColors.primary,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
      );
    }
  }

  Future<void> _openTakePayment() async {
    HapticFeedback.lightImpact();
    final saved = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => PaymentInScreen(party: _party)),
    );
    if (saved == true) _loadData();
  }

  Future<void> _openAddSale() async {
    HapticFeedback.lightImpact();
    final saved = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => SaleFormScreen(party: _party)),
    );
    if (saved == true) _loadData();
  }

  void _sendReminder() {
    HapticFeedback.lightImpact();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Send Reminder — wire this to SMS/WhatsApp share'),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    );
  }

  void _sendStatement() {
    HapticFeedback.lightImpact();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Send Statement — wire this to PDF export'),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    );
  }

  // -----------------------------------------------------------------
  // BUILD
  // -----------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: JoynColors.background,
      appBar: AppBar(
        backgroundColor: JoynColors.background,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: Padding(
          padding: const EdgeInsets.only(left: 8),
          child: _Pressable(
            onTap: () => context.pop(_party),
            scale: 0.9,
            borderRadius: 22,
            child: Container(
              margin: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                border: Border.all(
                    color: JoynColors.border.withValues(alpha: 0.7), width: 1),
                boxShadow: _Premium.hairlineShadow,
              ),
              child: const Icon(Icons.arrow_back_rounded,
                  size: 18, color: Colors.black87),
            ),
          ),
        ),
        centerTitle: true,
        title: Text(
          'Party Details',
          style: JoynTypography.titleMedium.copyWith(
              fontSize: 18, fontWeight: FontWeight.w800, letterSpacing: -0.3),
        ),
        actions: [
          _Pressable(
            onTap: _openEdit,
            scale: 0.9,
            borderRadius: 22,
            child: Container(
              margin: const EdgeInsets.symmetric(vertical: 6),
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                border: Border.all(
                    color: JoynColors.border.withValues(alpha: 0.7), width: 1),
                boxShadow: _Premium.hairlineShadow,
              ),
              child: const Icon(Icons.edit_outlined,
                  size: 17, color: Colors.black87),
            ),
          ),
          const SizedBox(width: 6),
          _Pressable(
            onTap: _showMoreMenu,
            scale: 0.9,
            borderRadius: 22,
            child: Container(
              margin: const EdgeInsets.fromLTRB(0, 6, 12, 6),
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                border: Border.all(
                    color: JoynColors.border.withValues(alpha: 0.7), width: 1),
                boxShadow: _Premium.hairlineShadow,
              ),
              child: const Icon(Icons.more_horiz_rounded,
                  size: 18, color: Colors.black87),
            ),
          ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: _isLoading
            ? const Center(
            child: CircularProgressIndicator(color: JoynColors.primary))
            : RefreshIndicator(
          onRefresh: _loadData,
          color: JoynColors.primary,
          backgroundColor: Colors.white,
          strokeWidth: 2.6,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(
                parent: BouncingScrollPhysics()),
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            children: [
              _StaggeredItem(
                  index: 0, child: _buildHeroHeaderCard()),
              const SizedBox(height: 16),

              if (_sales.isNotEmpty) ...[
                _StaggeredItem(index: 1, child: _buildStatsRow()),
                const SizedBox(height: 20),
              ],

              _StaggeredItem(
                index: 2,
                child: _buildSectionHeader(
                    'Recent Activity', Icons.receipt_long_outlined),
              ),
              const SizedBox(height: 10),

              if (_allActivities.isNotEmpty)
                _StaggeredItem(index: 2, child: _buildFilterChips()),

              const SizedBox(height: 12),

              if (_allActivities.isEmpty)
                _StaggeredItem(index: 3, child: _buildEmptySales())
              else if (_visibleActivities.isEmpty)
                _StaggeredItem(index: 3, child: _buildFilterEmpty())
              else
                ..._visibleActivities.asMap().entries.map((entry) =>
                    _StaggeredItem(
                      index: entry.key + 3,
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: _buildActivityCard(entry.value),
                      ),
                    )),
            ],
          ),
        ),
      ),
      bottomNavigationBar: _buildFrostedActionBar(),
    );
  }

  // -----------------------------------------------------------------
  // MORE MENU
  // -----------------------------------------------------------------
  void _showMoreMenu() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4.5,
                margin: const EdgeInsets.only(top: 14, bottom: 12),
                decoration: BoxDecoration(
                    color: JoynColors.border,
                    borderRadius: BorderRadius.circular(3)),
              ),
              _buildMenuTile(
                icon: Icons.point_of_sale_rounded,
                color: JoynColors.primary,
                label: 'Add Sale',
                subtitle: 'Create a new invoice',
                onTap: () {
                  Navigator.pop(context);
                  _openAddSale();
                },
              ),
              _buildMenuTile(
                icon: Icons.call_received_rounded,
                color: JoynColors.success,
                label: 'Take Payment',
                subtitle: 'Receive against balance',
                onTap: () {
                  Navigator.pop(context);
                  _openTakePayment();
                },
              ),
              _buildMenuTile(
                icon: Icons.notifications_active_outlined,
                color: const Color(0xFFF59E0B),
                label: 'Send Reminder',
                subtitle: 'Nudge via SMS / WhatsApp',
                onTap: () {
                  Navigator.pop(context);
                  _sendReminder();
                },
              ),
              _buildMenuTile(
                icon: Icons.description_outlined,
                color: JoynColors.primary,
                label: 'Send Statement',
                subtitle: 'Export ledger as PDF',
                onTap: () {
                  Navigator.pop(context);
                  _sendStatement();
                },
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMenuTile({
    required IconData icon,
    required Color color,
    required String label,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return _Pressable(
      onTap: onTap,
      scale: 0.98,
      borderRadius: 16,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 3),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                gradient: _Premium.softGradient(color),
                borderRadius: BorderRadius.circular(12),
                border:
                Border.all(color: color.withValues(alpha: 0.15), width: 1),
              ),
              child: Icon(icon, size: 18, color: color),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style: JoynTypography.bodyLarge.copyWith(
                          fontSize: 14.5, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 2),
                  Text(subtitle,
                      style: JoynTypography.caption.copyWith(
                          fontSize: 11.5, color: JoynColors.secondaryText)),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded,
                size: 20,
                color: JoynColors.secondaryText.withValues(alpha: 0.5)),
          ],
        ),
      ),
    );
  }

  // -----------------------------------------------------------------
  // FILTER CHIPS
  // -----------------------------------------------------------------
  Widget _buildFilterChips() {
    return Row(
      children: [
        _buildFilterChip('All', _ActivityFilter.all, _allActivities.length,
            JoynColors.primary),
        const SizedBox(width: 8),
        _buildFilterChip('Sales', _ActivityFilter.sales,
            _allActivities.where((e) => e.isSale).length, JoynColors.primary),
        const SizedBox(width: 8),
        _buildFilterChip('Purchases', _ActivityFilter.purchases,
            _allActivities.where((e) => !e.isSale).length,
            const Color(0xFF7C3AED)),
      ],
    );
  }

  Widget _buildFilterChip(
      String label, _ActivityFilter value, int count, Color color) {
    final selected = _filter == value;
    return _Pressable(
      onTap: () {
        HapticFeedback.selectionClick();
        setState(() => _filter = value);
      },
      scale: 0.95,
      borderRadius: 20,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          gradient: selected ? _Premium.gradient(color) : null,
          color: selected ? null : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected
                ? color.withValues(alpha: 0.4)
                : JoynColors.border.withValues(alpha: 0.8),
            width: 1,
          ),
          boxShadow:
          selected ? _Premium.softGlow(color) : _Premium.hairlineShadow,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: JoynTypography.caption.copyWith(
                fontSize: 11.5,
                fontWeight: FontWeight.w800,
                color: selected ? Colors.white : Colors.black87,
              ),
            ),
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
              decoration: BoxDecoration(
                color: selected
                    ? Colors.white.withValues(alpha: 0.25)
                    : color.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '$count',
                style: JoynTypography.caption.copyWith(
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  color: selected ? Colors.white : color,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterEmpty() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 32),
      alignment: Alignment.center,
      child: Text(
        'No ${_filter == _ActivityFilter.sales ? 'sales' : 'purchases'} yet',
        style: JoynTypography.subtitle
            .copyWith(fontSize: 12.5, color: JoynColors.secondaryText),
      ),
    );
  }

  // -----------------------------------------------------------------
  // HERO HEADER (compact)
  // -----------------------------------------------------------------
  Widget _buildHeroHeaderCard() {
    final balanceColor = _isReceivable ? JoynColors.success : JoynColors.error;
    final balanceLabel = _isReceivable ? 'Receivable' : 'Payable';
    final balanceIcon =
    _isReceivable ? Icons.call_received_rounded : Icons.call_made_rounded;

    return Container(
      decoration: BoxDecoration(
        gradient: _Premium.deepGradient(JoynColors.primary),
        borderRadius: BorderRadius.circular(20),
        boxShadow: _Premium.heroShadow,
      ),
      child: Stack(
        children: [
          Positioned(
            top: -30,
            right: -24,
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    Colors.white.withValues(alpha: 0.18),
                    Colors.white.withValues(alpha: 0.0),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            top: 0,
            height: 32,
            child: Container(
              decoration: BoxDecoration(
                gradient: _Premium.topHighlight,
                borderRadius:
                const BorderRadius.vertical(top: Radius.circular(20)),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
            child: Column(
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _FloatingAvatar(child: _buildHeroAvatar()),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  _party.name,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: JoynTypography.titleMedium.copyWith(
                                    fontSize: 16.5,
                                    fontWeight: FontWeight.w900,
                                    color: Colors.white,
                                    letterSpacing: -0.3,
                                    height: 1.1,
                                  ),
                                ),
                              ),
                              if (_party.priorityLevel == 'high')
                                Padding(
                                  padding: const EdgeInsets.only(left: 6),
                                  child: _PulsingDot(
                                      color: Colors.white, size: 5),
                                ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Wrap(
                            spacing: 6,
                            runSpacing: 6,
                            children: [
                              _buildHeroPill(
                                  Icons.badge_outlined,
                                  _party.displayPartyCode),
                              if (_party.category.isNotEmpty)
                                _buildHeroPill(
                                    Icons.local_offer_outlined,
                                    _party.category),
                              if (_party.contactNumber.isNotEmpty)
                                _buildHeroPill(
                                    Icons.phone_outlined,
                                    _party.contactNumber),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 14),

                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                        color: Colors.white.withValues(alpha: 0.18),
                        width: 1),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.18),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Icon(balanceIcon,
                                      size: 10, color: Colors.white),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  balanceLabel.toUpperCase(),
                                  style: JoynTypography.caption.copyWith(
                                      fontSize: 9.5,
                                      fontWeight: FontWeight.w800,
                                      color: Colors.white.withValues(alpha: 0.85),
                                      letterSpacing: 0.9),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            FittedBox(
                              fit: BoxFit.scaleDown,
                              alignment: Alignment.centerLeft,
                              child: Text(
                                '₹${_balance.toStringAsFixed(2)}',
                                maxLines: 1,
                                style: JoynTypography.titleMedium.copyWith(
                                  fontSize: 24,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.white,
                                  letterSpacing: -0.6,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 9, vertical: 7),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.10),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.receipt_long_rounded,
                                size: 11, color: Colors.white),
                            const SizedBox(width: 5),
                            Text(
                              '${_allActivities.length}',
                              style: JoynTypography.caption.copyWith(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white.withValues(alpha: 0.9)),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 8),
                Divider(
                    height: 1, color: Colors.white.withValues(alpha: 0.16)),
                const SizedBox(height: 6),

                Row(
                  children: [
                    Expanded(
                      child: _buildHeroAction(
                        icon: Icons.notifications_active_outlined,
                        label: 'Reminder',
                        onTap: _sendReminder,
                      ),
                    ),
                    Container(
                        width: 1,
                        height: 22,
                        color: Colors.white.withValues(alpha: 0.20)),
                    Expanded(
                      child: _buildHeroAction(
                        icon: Icons.description_outlined,
                        label: 'Statement',
                        onTap: _sendStatement,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeroAvatar() {
    if (_party.photoPath.isNotEmpty && File(_party.photoPath).existsSync()) {
      return Container(
        width: 52,
        height: 52,
        padding: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            colors: [
              Colors.white.withValues(alpha: 0.9),
              Colors.white.withValues(alpha: 0.5),
            ],
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.18),
              blurRadius: 14,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipOval(
          child: Image.file(File(_party.photoPath), fit: BoxFit.cover),
        ),
      );
    }

    return Container(
      width: 52,
      height: 52,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.18),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      alignment: Alignment.center,
      child: Text(
        _party.name.isNotEmpty ? _party.name[0].toUpperCase() : '?',
        style: JoynTypography.titleMedium.copyWith(
          fontSize: 21,
          fontWeight: FontWeight.w900,
          color: JoynColors.primary,
        ),
      ),
    );
  }

  Widget _buildHeroPill(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
            color: Colors.white.withValues(alpha: 0.18), width: 0.8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 9, color: Colors.white),
          const SizedBox(width: 4),
          Text(
            text,
            style: JoynTypography.caption.copyWith(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: Colors.white,
                height: 1.0),
          ),
        ],
      ),
    );
  }

  Widget _buildHeroAction({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return _Pressable(
      onTap: onTap,
      scale: 0.96,
      borderRadius: 12,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 12, color: Colors.white),
            const SizedBox(width: 6),
            Text(
              label,
              style: JoynTypography.bodyMedium.copyWith(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                  color: Colors.white),
            ),
          ],
        ),
      ),
    );
  }

  // -----------------------------------------------------------------
  // STATS ROW
  // -----------------------------------------------------------------
  Widget _buildStatsRow() {
    return Row(
      children: [
        Expanded(
          child: _buildStatTile(
            label: 'Total',
            value: '₹${_totalSales.toStringAsFixed(0)}',
            icon: Icons.receipt_long_rounded,
            color: JoynColors.primary,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildStatTile(
            label: 'Paid',
            value: '₹${_totalPaid.toStringAsFixed(0)}',
            icon: Icons.check_circle_outline_rounded,
            color: JoynColors.success,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildStatTile(
            label: 'Due',
            value: '₹${_totalDue.toStringAsFixed(0)}',
            icon: Icons.error_outline_rounded,
            color: _totalDue > 0
                ? JoynColors.error
                : JoynColors.secondaryText,
          ),
        ),
      ],
    );
  }

  Widget _buildStatTile({
    required String label,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        gradient: _Premium.surfaceGradient,
        borderRadius: BorderRadius.circular(14),
        border: _Premium.hairline(width: 1.0, alpha: 0.85),
        boxShadow: _Premium.softShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              gradient: _Premium.softGradient(color),
              borderRadius: BorderRadius.circular(7),
              border:
              Border.all(color: color.withValues(alpha: 0.15), width: 0.8),
            ),
            child: Icon(icon, size: 11, color: color),
          ),
          const SizedBox(height: 6),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              maxLines: 1,
              style: JoynTypography.bodyLarge.copyWith(
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                  color: Colors.black87,
                  letterSpacing: -0.3),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label.toUpperCase(),
            style: JoynTypography.caption.copyWith(
                fontSize: 8.5,
                fontWeight: FontWeight.w800,
                color: JoynColors.secondaryText,
                letterSpacing: 0.5),
          ),
        ],
      ),
    );
  }

  // -----------------------------------------------------------------
  // SECTION HEADER
  // -----------------------------------------------------------------
  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Container(
          width: 3,
          height: 22,
          margin: const EdgeInsets.only(right: 10),
          decoration: BoxDecoration(
            gradient: _Premium.gradient(JoynColors.primary),
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            gradient: _Premium.softGradient(JoynColors.primary),
            borderRadius: BorderRadius.circular(9),
          ),
          child: Icon(icon, size: 14, color: JoynColors.primary),
        ),
        const SizedBox(width: 10),
        Text(
          title,
          style: JoynTypography.bodyLarge.copyWith(
              fontWeight: FontWeight.w800,
              fontSize: 16,
              letterSpacing: -0.2,
              color: Colors.black87),
        ),
        const SizedBox(width: 10),
        if (_allActivities.isNotEmpty)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2.5),
            decoration: BoxDecoration(
              color: JoynColors.primary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '${_allActivities.length}',
              style: JoynTypography.caption.copyWith(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  color: JoynColors.primary),
            ),
          ),
      ],
    );
  }

  // -----------------------------------------------------------------
  // ACTIVITY CARD (compact)
  // -----------------------------------------------------------------
  Widget _buildActivityCard(_ActivityEntry e) {
    final isSale = e.isSale;
    final kindColor = isSale ? JoynColors.primary : const Color(0xFF7C3AED);
    final kindLabel = isSale ? 'SALE' : 'PURCHASE';
    final kindIcon =
    isSale ? Icons.point_of_sale_rounded : Icons.shopping_bag_rounded;

    final statusColor = e.isPaid ? JoynColors.success : JoynColors.error;
    final statusLabel = e.isPaid ? 'PAID' : 'DUE';
    final payProgress = e.total > 0
        ? ((e.total - e.balanceDue) / e.total).clamp(0.0, 1.0)
        : 0.0;

    return Container(
      decoration: BoxDecoration(
        gradient: _Premium.surfaceGradient,
        borderRadius: BorderRadius.circular(16),
        border: _Premium.hairline(width: 1.0, alpha: 0.85),
        boxShadow: _Premium.cardShadow,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          children: [
            Positioned(
              left: 0,
              top: 0,
              bottom: 0,
              width: 3,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      kindColor.withValues(alpha: 0.9),
                      kindColor.withValues(alpha: 0.35),
                    ],
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(13, 11, 12, 11),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          gradient: _Premium.softGradient(kindColor),
                          borderRadius: BorderRadius.circular(9),
                          border: Border.all(
                              color: kindColor.withValues(alpha: 0.20),
                              width: 1),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(kindIcon, size: 10, color: kindColor),
                            const SizedBox(width: 4),
                            Text(
                              '#${e.refNo}',
                              style: JoynTypography.caption.copyWith(
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w800,
                                  color: kindColor,
                                  letterSpacing: 0.2),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 4),
                        decoration: BoxDecoration(
                          color: kindColor.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(7),
                        ),
                        child: Text(
                          kindLabel,
                          style: JoynTypography.caption.copyWith(
                              fontSize: 8.5,
                              fontWeight: FontWeight.w900,
                              color: kindColor,
                              letterSpacing: 0.6),
                        ),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          gradient: _Premium.softGradient(statusColor),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                              color: statusColor.withValues(alpha: 0.28),
                              width: 1),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 5,
                              height: 5,
                              decoration: BoxDecoration(
                                  color: statusColor,
                                  shape: BoxShape.circle),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              statusLabel,
                              style: JoynTypography.caption.copyWith(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w900,
                                  color: statusColor,
                                  letterSpacing: 0.5),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 8),

                  Row(
                    children: [
                      Icon(Icons.calendar_today_outlined,
                          size: 10,
                          color: JoynColors.secondaryText
                              .withValues(alpha: 0.75)),
                      const SizedBox(width: 5),
                      Text(
                        e.date,
                        style: JoynTypography.caption.copyWith(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: JoynColors.secondaryText),
                      ),
                    ],
                  ),

                  const SizedBox(height: 10),

                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'TOTAL',
                              style: JoynTypography.caption.copyWith(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w800,
                                  color: JoynColors.secondaryText,
                                  letterSpacing: 0.5),
                            ),
                            const SizedBox(height: 2),
                            FittedBox(
                              fit: BoxFit.scaleDown,
                              alignment: Alignment.centerLeft,
                              child: Text(
                                '₹${e.total.toStringAsFixed(2)}',
                                maxLines: 1,
                                style: JoynTypography.bodyLarge.copyWith(
                                    fontSize: 14.5,
                                    fontWeight: FontWeight.w900,
                                    color: Colors.black87,
                                    letterSpacing: -0.3),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                          width: 1,
                          height: 28,
                          color: JoynColors.border.withValues(alpha: 0.6)),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              e.isPaid ? 'SETTLED' : 'DUE',
                              style: JoynTypography.caption.copyWith(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w800,
                                  color: statusColor,
                                  letterSpacing: 0.5),
                            ),
                            const SizedBox(height: 2),
                            FittedBox(
                              fit: BoxFit.scaleDown,
                              alignment: Alignment.centerRight,
                              child: Text(
                                '₹${e.balanceDue.toStringAsFixed(2)}',
                                maxLines: 1,
                                style: JoynTypography.bodyLarge.copyWith(
                                    fontSize: 14.5,
                                    fontWeight: FontWeight.w900,
                                    color: statusColor,
                                    letterSpacing: -0.3),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 10),

                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: Container(
                      height: 4,
                      decoration: BoxDecoration(
                        color: JoynColors.chipBackground,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: FractionallySizedBox(
                        alignment: Alignment.centerLeft,
                        widthFactor: payProgress,
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: _Premium.gradient(statusColor),
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 10),
                  Divider(
                      height: 1,
                      color: JoynColors.border.withValues(alpha: 0.5)),

                  Row(
                    children: [
                      const Spacer(),
                      _buildSaleActionIcon(Icons.print_outlined, () {}),
                      const SizedBox(width: 4),
                      _buildSaleActionIcon(Icons.ios_share_rounded, () {}),
                      const SizedBox(width: 4),
                      _buildSaleActionIcon(Icons.arrow_forward_ios_rounded,
                              () {}),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSaleActionIcon(IconData icon, VoidCallback onTap) {
    return _Pressable(
      onTap: onTap,
      scale: 0.86,
      borderRadius: 10,
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: JoynColors.chipBackground,
          borderRadius: BorderRadius.circular(9),
          border: Border.all(
              color: JoynColors.border.withValues(alpha: 0.5), width: 1),
        ),
        child: Icon(icon, size: 13, color: JoynColors.secondaryText),
      ),
    );
  }

  // -----------------------------------------------------------------
  // EMPTY
  // -----------------------------------------------------------------
  Widget _buildEmptySales() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 40),
      decoration: BoxDecoration(
        gradient: _Premium.surfaceGradient,
        borderRadius: BorderRadius.circular(18),
        border: _Premium.hairline(width: 1.0, alpha: 0.7),
        boxShadow: _Premium.softShadow,
      ),
      child: Column(
        children: [
          SizedBox(
            width: 96,
            height: 96,
            child: Stack(
              alignment: Alignment.center,
              children: [
                _PulsingDot(color: JoynColors.primary, size: 28),
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    gradient: _Premium.softGradient(JoynColors.primary),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                        color: JoynColors.primary.withValues(alpha: 0.15),
                        width: 1),
                  ),
                  child: Icon(Icons.receipt_long_outlined,
                      size: 28,
                      color: JoynColors.primary.withValues(alpha: 0.75)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          Text('No activity yet',
              style: JoynTypography.bodyLarge.copyWith(
                  fontWeight: FontWeight.w800, fontSize: 15)),
          const SizedBox(height: 6),
          Text('Tap "Add Sale" below to create your first bill',
              textAlign: TextAlign.center,
              style: JoynTypography.subtitle.copyWith(
                  fontSize: 12.5, color: JoynColors.secondaryText)),
        ],
      ),
    );
  }

  // -----------------------------------------------------------------
  // FROSTED ACTION BAR — shine hataya, cleaner flat gradient buttons
  // -----------------------------------------------------------------
  Widget _buildFrostedActionBar() {
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Container(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.72),
            border: Border(
              top: BorderSide(
                  color: JoynColors.border.withValues(alpha: 0.6), width: 1),
            ),
          ),
          child: SafeArea(
            top: false,
            child: Row(
              children: [
                Expanded(
                  flex: 3,
                  child: _buildBottomButton(
                    label: 'Take Payment',
                    icon: Icons.call_received_rounded,
                    color: JoynColors.success,
                    onTap: _openTakePayment,
                    outlined: true,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 4,
                  child: _buildBottomButton(
                    label: 'Add Sale',
                    icon: Icons.point_of_sale_rounded,
                    color: JoynColors.primary,
                    onTap: _openAddSale,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ✅ Shine sweep hata diya; solid gradient + subtle icon chip, "Take Payment"
  // ab outlined/secondary style mein taaki "Add Sale" primary action clearly
  // stand out kare.
  Widget _buildBottomButton({
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
    bool outlined = false,
  }) {
    return _Pressable(
      onTap: onTap,
      scale: 0.97,
      borderRadius: 16,
      child: Container(
        height: 52,
        decoration: BoxDecoration(
          gradient: outlined ? null : _Premium.gradient(color),
          color: outlined ? Colors.white : null,
          borderRadius: BorderRadius.circular(16),
          border: outlined
              ? Border.all(color: color.withValues(alpha: 0.35), width: 1.4)
              : null,
          boxShadow: outlined ? _Premium.softShadow : _Premium.chipShadow(color),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(5),
              decoration: BoxDecoration(
                color: outlined
                    ? color.withValues(alpha: 0.10)
                    : Colors.white.withValues(alpha: 0.22),
                borderRadius: BorderRadius.circular(9),
              ),
              child: Icon(icon,
                  color: outlined ? color : Colors.white, size: 13),
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: JoynTypography.bodyMedium.copyWith(
                    fontWeight: FontWeight.w800,
                    color: outlined ? color : Colors.white,
                    fontSize: 13,
                    letterSpacing: 0.2),
              ),
            ),
          ],
        ),
      ),
    );
  }
}