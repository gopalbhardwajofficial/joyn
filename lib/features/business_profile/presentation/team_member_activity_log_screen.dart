import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/joyn_colors.dart';
import '../../../core/theme/joyn_typography.dart';
import '../models/activity_log_model.dart';
import '../../team_management/models/team_member_model.dart';

// =====================================================================
// PREMIUM DESIGN SYSTEM — Diamond Edition
// =====================================================================
class _P {
  static List<BoxShadow> cardShadow = [
    BoxShadow(color: Colors.black.withValues(alpha: 0.020), blurRadius: 2, offset: const Offset(0, 1)),
    BoxShadow(color: Colors.black.withValues(alpha: 0.030), blurRadius: 8, offset: const Offset(0, 3)),
    BoxShadow(color: Colors.black.withValues(alpha: 0.035), blurRadius: 20, offset: const Offset(0, 8)),
    BoxShadow(color: Colors.black.withValues(alpha: 0.025), blurRadius: 40, offset: const Offset(0, 16)),
  ];

  static List<BoxShadow> heroShadow = [
    BoxShadow(color: Colors.black.withValues(alpha: 0.10), blurRadius: 6, offset: const Offset(0, 2)),
    BoxShadow(color: Colors.black.withValues(alpha: 0.12), blurRadius: 22, offset: const Offset(0, 10)),
    BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 44, offset: const Offset(0, 20)),
  ];

  static List<BoxShadow> softShadow = [
    BoxShadow(color: Colors.black.withValues(alpha: 0.025), blurRadius: 3, offset: const Offset(0, 1)),
    BoxShadow(color: Colors.black.withValues(alpha: 0.035), blurRadius: 12, offset: const Offset(0, 4)),
  ];

  static List<BoxShadow> hairlineShadow = [
    BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 6, offset: const Offset(0, 2)),
  ];

  static List<BoxShadow> chipShadow(Color color) => [
    BoxShadow(color: color.withValues(alpha: 0.20), blurRadius: 6, offset: const Offset(0, 2)),
    BoxShadow(color: color.withValues(alpha: 0.28), blurRadius: 16, offset: const Offset(0, 7)),
    BoxShadow(color: color.withValues(alpha: 0.15), blurRadius: 30, offset: const Offset(0, 14)),
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
    colors: [color.withValues(alpha: 0.14), color.withValues(alpha: 0.04)],
  );

  static LinearGradient surfaceGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Colors.white, Color.lerp(Colors.white, JoynColors.background, 0.6) ?? Colors.white],
  );

  static LinearGradient topHighlight = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Colors.white.withValues(alpha: 0.22), Colors.transparent],
  );

  static LinearGradient shineSweep = LinearGradient(
    begin: Alignment(-1.0, -1.0),
    end: Alignment(0.5, 0.5),
    colors: [
      Colors.white.withValues(alpha: 0.0),
      Colors.white.withValues(alpha: 0.32),
      Colors.white.withValues(alpha: 0.0),
    ],
    stops: const [0.35, 0.5, 0.65],
  );

  static Border hairline({double w = 1.0, double a = 1}) =>
      Border.all(color: JoynColors.border.withValues(alpha: a), width: w);
}

// =====================================================================
// PRESSABLE
// =====================================================================
class _Pressable extends StatefulWidget {
  const _Pressable({
    required this.child,
    required this.onTap,
    this.scale = 0.97,
  });
  final Widget child;
  final VoidCallback onTap;
  final double scale;

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
// MAIN SCREEN
// =====================================================================
class TeamMemberActivityLogScreen extends StatefulWidget {
  final TeamMemberModel member;

  const TeamMemberActivityLogScreen({super.key, required this.member});

  @override
  State<TeamMemberActivityLogScreen> createState() =>
      _TeamMemberActivityLogScreenState();
}

class _TeamMemberActivityLogScreenState
    extends State<TeamMemberActivityLogScreen> {
  ActivityTimePeriod _selectedPeriod = ActivityTimePeriod.day1;
  DateTimeRange? _customRange;

  List<ActivityLogEntry> get _dummyEntries => [
    ActivityLogEntry(
      id: '1',
      type: ActivityType.itemPurchased,
      title: 'Item Purchased',
      subtitle: 'Purchase Order #PO-1234',
      amount: 5000,
      timestamp: DateTime.now().subtract(const Duration(hours: 2)),
    ),
    ActivityLogEntry(
      id: '2',
      type: ActivityType.itemSold,
      title: 'Item Sold',
      subtitle: 'Sale Invoice #2',
      amount: 10020,
      timestamp: DateTime.now().subtract(const Duration(hours: 5)),
    ),
    ActivityLogEntry(
      id: '3',
      type: ActivityType.itemAddedModified,
      title: 'Item Added / Modified',
      subtitle: 'Sugar 1kg — stock updated',
      timestamp: DateTime.now().subtract(const Duration(days: 1)),
    ),
    ActivityLogEntry(
      id: '4',
      type: ActivityType.custAddedModified,
      title: 'Customer Added / Modified',
      subtitle: 'Ramesh Traders — details updated',
      timestamp: DateTime.now().subtract(const Duration(days: 2)),
    ),
  ];

  Future<void> _selectPeriod() async {
    final result = await showModalBottomSheet<ActivityTimePeriod>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => SafeArea(
        child: Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 42,
                height: 5,
                margin: const EdgeInsets.only(top: 14, bottom: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFFD1D5DB),
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 4),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Select Time Period',
                        style: JoynTypography.titleMedium.copyWith(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.2),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Choose a range to filter activity',
                        style: JoynTypography.caption.copyWith(
                            fontSize: 11.5,
                            color: JoynColors.secondaryText),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              for (final period in ActivityTimePeriod.values
                  .where((p) => p != ActivityTimePeriod.custom))
                _Pressable(
                  scale: 0.98,
                  onTap: () => Navigator.pop(context, period),
                  child: Container(
                    margin:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 14),
                    decoration: BoxDecoration(
                      gradient: _selectedPeriod == period
                          ? _P.softGradient(JoynColors.primary)
                          : null,
                      color: _selectedPeriod == period ? null : Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: _selectedPeriod == period
                            ? JoynColors.primary.withValues(alpha: 0.5)
                            : JoynColors.border.withValues(alpha: 0.7),
                        width: 1.2,
                      ),
                      boxShadow: _selectedPeriod == period
                          ? _P.softGlow(JoynColors.primary)
                          : _P.hairlineShadow,
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(7),
                          decoration: BoxDecoration(
                            gradient: _P.softGradient(JoynColors.primary),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                                color: JoynColors.primary
                                    .withValues(alpha: 0.18),
                                width: 1),
                          ),
                          child: const Icon(Icons.calendar_today_rounded,
                              size: 14, color: JoynColors.primary),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            period.label,
                            style: JoynTypography.bodyLarge.copyWith(
                              fontSize: 15,
                              fontWeight: _selectedPeriod == period
                                  ? FontWeight.w700
                                  : FontWeight.w600,
                              color: JoynColors.primary,
                            ),
                          ),
                        ),
                        if (_selectedPeriod == period)
                          const Icon(Icons.check_circle_rounded,
                              size: 20, color: JoynColors.primary),
                      ],
                    ),
                  ),
                ),
              const SizedBox(height: 14),
            ],
          ),
        ),
      ),
    );

    if (result != null) {
      setState(() => _selectedPeriod = result);
    }
  }

  Future<void> _selectCustomDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: _customRange,
    );
    if (picked != null) {
      setState(() {
        _customRange = picked;
        _selectedPeriod = ActivityTimePeriod.custom;
      });
    }
  }

  String get _rangeLabel {
    if (_selectedPeriod == ActivityTimePeriod.custom && _customRange != null) {
      final start = _customRange!.start;
      final end = _customRange!.end;
      return '${start.day}/${start.month}/${start.year} - ${end.day}/${end.month}/${end.year}';
    }
    return _selectedPeriod.label;
  }

  IconData _iconFor(ActivityType type) {
    switch (type) {
      case ActivityType.itemPurchased:
        return Icons.shopping_bag_outlined;
      case ActivityType.itemSold:
        return Icons.shopping_cart_outlined;
      case ActivityType.itemAddedModified:
        return Icons.inventory_2_outlined;
      case ActivityType.custAddedModified:
        return Icons.people_outline_rounded;
    }
  }

  Color _colorFor(ActivityType type) {
    switch (type) {
      case ActivityType.itemPurchased:
        return const Color(0xFF0284C7);
      case ActivityType.itemSold:
        return JoynColors.success;
      case ActivityType.itemAddedModified:
        return const Color(0xFFB45309);
      case ActivityType.custAddedModified:
        return const Color(0xFF7C3AED);
    }
  }

  @override
  Widget build(BuildContext context) {
    final entries = _dummyEntries;
    final totalPurchased = entries
        .where((e) => e.type == ActivityType.itemPurchased)
        .fold<double>(0, (sum, e) => sum + (e.amount ?? 0));
    final totalSold = entries
        .where((e) => e.type == ActivityType.itemSold)
        .fold<double>(0, (sum, e) => sum + (e.amount ?? 0));

    return Scaffold(
      backgroundColor: JoynColors.background,
      appBar: AppBar(
        backgroundColor: JoynColors.background,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: Padding(
          padding: const EdgeInsets.only(left: 8),
          child: _Pressable(
            onTap: () => context.pop(),
            scale: 0.9,
            child: Container(
              margin: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                border: Border.all(
                    color: JoynColors.border.withValues(alpha: 0.7), width: 1),
                boxShadow: _P.hairlineShadow,
              ),
              child: const Icon(Icons.arrow_back_rounded,
                  size: 18, color: Colors.black87),
            ),
          ),
        ),
        centerTitle: true,
        title: Text(
          'Activity Log',
          style: JoynTypography.titleMedium.copyWith(
              fontSize: 18, fontWeight: FontWeight.w800, letterSpacing: -0.3),
        ),
      ),
      body: SafeArea(
        top: false,
        child: ListView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
          children: [
            _StaggeredItem(index: 0, child: _buildMemberHeroCard()),
            const SizedBox(height: 20),

            _StaggeredItem(index: 1, child: _buildSectionLabel('Time Period')),
            const SizedBox(height: 12),
            _StaggeredItem(index: 2, child: _buildPeriodSelector()),
            const SizedBox(height: 24),

            _StaggeredItem(index: 3, child: _buildSectionLabel('Summary')),
            const SizedBox(height: 12),
            _StaggeredItem(
              index: 4,
              child: Row(
                children: [
                  Expanded(
                    child: _buildSummaryTile(
                      icon: Icons.shopping_bag_outlined,
                      label: 'Item Purchased',
                      value: '₹${totalPurchased.toStringAsFixed(0)}',
                      color: const Color(0xFF0284C7),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildSummaryTile(
                      icon: Icons.shopping_cart_outlined,
                      label: 'Item Sold',
                      value: '₹${totalSold.toStringAsFixed(0)}',
                      color: JoynColors.success,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            _StaggeredItem(
                index: 5,
                child: _buildSectionLabel('Items / Customer / Order')),
            const SizedBox(height: 12),

            if (entries.isEmpty)
              _StaggeredItem(index: 6, child: _buildEmptyState())
            else
              ...entries.asMap().entries.map((entry) => _StaggeredItem(
                index: entry.key + 6,
                child: Padding(
                  padding: EdgeInsets.only(
                      bottom: entry.key == entries.length - 1 ? 0 : 10),
                  child: _buildActivityCardItem(entry.value),
                ),
              )),
          ],
        ),
      ),
    );
  }

  // =================================================================
  // MEMBER HERO CARD
  // =================================================================
  Widget _buildMemberHeroCard() {
    return Container(
      decoration: BoxDecoration(
        gradient: _P.deepGradient(JoynColors.primary),
        borderRadius: BorderRadius.circular(24),
        boxShadow: _P.heroShadow,
      ),
      child: Stack(
        children: [
          // radial glow top-right
          Positioned(
            top: -40,
            right: -30,
            child: Container(
              width: 160,
              height: 160,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    Colors.white.withValues(alpha: 0.20),
                    Colors.white.withValues(alpha: 0.0),
                  ],
                ),
              ),
            ),
          ),
          // bottom left glow
          Positioned(
            bottom: -50,
            left: -30,
            child: Container(
              width: 140,
              height: 140,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    Colors.white.withValues(alpha: 0.10),
                    Colors.white.withValues(alpha: 0.0),
                  ],
                ),
              ),
            ),
          ),
          // top highlight
          Positioned(
            left: 0,
            right: 0,
            top: 0,
            height: 40,
            child: Container(
              decoration: BoxDecoration(
                gradient: _P.topHighlight,
                borderRadius:
                const BorderRadius.vertical(top: Radius.circular(24)),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
            child: Row(
              children: [
                // avatar with ring
                Container(
                  width: 62,
                  height: 62,
                  padding: const EdgeInsets.all(2.5),
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
                        color: Colors.black.withValues(alpha: 0.20),
                        blurRadius: 20,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Container(
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white,
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      widget.member.name.isNotEmpty
                          ? widget.member.name[0].toUpperCase()
                          : '?',
                      style: JoynTypography.titleMedium.copyWith(
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                        color: JoynColors.primary,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.member.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: JoynTypography.titleMedium.copyWith(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          letterSpacing: -0.3,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: [
                          _buildHeroPill(
                              Icons.badge_outlined, widget.member.roleName),
                          _buildHeroPill(
                              Icons.timeline_rounded, _rangeLabel),
                        ],
                      ),
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

  Widget _buildHeroPill(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
            color: Colors.white.withValues(alpha: 0.18), width: 0.8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 10, color: Colors.white),
          const SizedBox(width: 4),
          Text(
            text,
            style: JoynTypography.caption.copyWith(
                fontSize: 10.5,
                fontWeight: FontWeight.w700,
                color: Colors.white,
                height: 1.0),
          ),
        ],
      ),
    );
  }

  // =================================================================
  // SECTION LABEL
  // =================================================================
  Widget _buildSectionLabel(String title) {
    return Row(
      children: [
        Container(
          width: 3,
          height: 14,
          margin: const EdgeInsets.only(right: 9),
          decoration: BoxDecoration(
            gradient: _P.gradient(JoynColors.primary),
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        Text(
          title.toUpperCase(),
          style: JoynTypography.caption.copyWith(
            fontSize: 11.5,
            fontWeight: FontWeight.w800,
            color: JoynColors.secondaryText,
            letterSpacing: 0.8,
          ),
        ),
      ],
    );
  }

  // =================================================================
  // PERIOD SELECTOR
  // =================================================================
  Widget _buildPeriodSelector() {
    return Row(
      children: [
        Expanded(
          child: _Pressable(
            scale: 0.98,
            onTap: _selectPeriod,
            child: Container(
              height: 56,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                gradient: _P.surfaceGradient,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                    color: JoynColors.border.withValues(alpha: 0.8),
                    width: 1.2),
                boxShadow: _P.softShadow,
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(7),
                    decoration: BoxDecoration(
                      gradient: _P.softGradient(JoynColors.primary),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                          color: JoynColors.primary.withValues(alpha: 0.15),
                          width: 1),
                    ),
                    child: const Icon(Icons.schedule_rounded,
                        size: 15, color: JoynColors.primary),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _rangeLabel,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: JoynTypography.bodyLarge.copyWith(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w700,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                  const Icon(Icons.keyboard_arrow_down_rounded,
                      size: 20, color: JoynColors.secondaryText),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        _Pressable(
          scale: 0.94,
          onTap: _selectCustomDateRange,
          child: Container(
            height: 56,
            width: 56,
            decoration: BoxDecoration(
              gradient: _P.gradient(JoynColors.primary),
              borderRadius: BorderRadius.circular(16),
              boxShadow: _P.chipShadow(JoynColors.primary),
            ),
            child: Stack(
              children: [
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: _P.shineSweep,
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
                const Center(
                  child: Icon(Icons.date_range_outlined,
                      size: 20, color: Colors.white),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // =================================================================
  // SUMMARY TILE
  // =================================================================
  Widget _buildSummaryTile({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: _P.surfaceGradient,
        borderRadius: BorderRadius.circular(18),
        // border: _P.hairline(width: 1.0, alpha: 0.85),
        boxShadow: _P.softShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              gradient: _P.softGradient(color),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                  color: color.withValues(alpha: 0.15), width: 1),
            ),
            child: Icon(icon, size: 18, color: color),
          ),
          const SizedBox(height: 12),
          Text(
            label.toUpperCase(),
            style: JoynTypography.caption.copyWith(
              fontSize: 10,
              color: JoynColors.secondaryText,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.6,
            ),
          ),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              maxLines: 1,
              style: JoynTypography.bodyLarge.copyWith(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.3),
            ),
          ),
        ],
      ),
    );
  }

  // =================================================================
  // ACTIVITY CARD ITEM (single)
  // =================================================================
  Widget _buildActivityCardItem(ActivityLogEntry entry) {
    final color = _colorFor(entry.type);

    return Container(
      decoration: BoxDecoration(
        gradient: _P.surfaceGradient,
        borderRadius: BorderRadius.circular(18),
        // border: _P.hairline(width: 1.0, alpha: 0.85),
        boxShadow: _P.cardShadow,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: Stack(
          children: [
            // Left accent stripe
            Positioned(
              left: 0,
              top: 0,
              bottom: 0,
              width: 4,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      color.withValues(alpha: 0.9),
                      color.withValues(alpha: 0.35),
                    ],
                  ),
                ),
              ),
            ),
            // top highlight
            Positioned(
              left: 0,
              right: 0,
              top: 0,
              height: 30,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.white.withValues(alpha: 0.6),
                      Colors.white.withValues(alpha: 0.0),
                    ],
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 14, 14),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      gradient: _P.softGradient(color),
                      borderRadius: BorderRadius.circular(13),
                      border: Border.all(
                          color: color.withValues(alpha: 0.18), width: 1),
                    ),
                    child: Icon(_iconFor(entry.type), size: 18, color: color),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                entry.title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: JoynTypography.bodyMedium.copyWith(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 14,
                                    color: Colors.black87),
                              ),
                            ),
                            if (entry.amount != null)
                              Padding(
                                padding: const EdgeInsets.only(left: 8),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    gradient: _P.softGradient(color),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                        color:
                                        color.withValues(alpha: 0.20),
                                        width: 1),
                                  ),
                                  child: Text(
                                    '₹${entry.amount!.toStringAsFixed(0)}',
                                    style: JoynTypography.bodyLarge.copyWith(
                                        fontWeight: FontWeight.w900,
                                        fontSize: 12.5,
                                        color: color),
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          entry.subtitle,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: JoynTypography.caption.copyWith(
                              fontSize: 12,
                              color: JoynColors.secondaryText),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Icon(Icons.access_time_rounded,
                                size: 10,
                                color: JoynColors.secondaryText
                                    .withValues(alpha: 0.65)),
                            const SizedBox(width: 4),
                            Text(
                              '${entry.timestamp.day}/${entry.timestamp.month}/${entry.timestamp.year} • ${entry.timestamp.hour.toString().padLeft(2, '0')}:${entry.timestamp.minute.toString().padLeft(2, '0')}',
                              style: JoynTypography.caption.copyWith(
                                  fontSize: 10.5,
                                  color: JoynColors.secondaryText
                                      .withValues(alpha: 0.65)),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // =================================================================
  // EMPTY STATE
  // =================================================================
  Widget _buildEmptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 44),
      decoration: BoxDecoration(
        gradient: _P.surfaceGradient,
        borderRadius: BorderRadius.circular(20),
        // border: _P.hairline(width: 1.0, alpha: 0.7),
        boxShadow: _P.softShadow,
      ),
      child: Column(
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              gradient: _P.softGradient(JoynColors.primary),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(
                  color: JoynColors.primary.withValues(alpha: 0.15),
                  width: 1),
            ),
            child: Icon(Icons.receipt_long_outlined,
                size: 32,
                color: JoynColors.primary.withValues(alpha: 0.75)),
          ),
          const SizedBox(height: 18),
          Text(
            'No Activity Found',
            style: JoynTypography.titleMedium.copyWith(
                fontSize: 16, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 6),
          Text(
            'No transactions recorded for this period.',
            style: JoynTypography.subtitle.copyWith(fontSize: 13),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}