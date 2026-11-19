// lib/features/orders/presentation/widgets/order_list_widgets.dart

import 'package:flutter/material.dart';
import '../../../../core/theme/joyn_colors.dart';
import '../../../../core/theme/joyn_typography.dart';

// ==================== Shared UI tokens ====================
class OrderUi {
  static const double rMd = 14;
  static const Color textDark = Color(0xFF3B3B4F);
  static const Color textMuted = Color(0xFFA3A3BD);

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
}

const List<String> _kMonths = [
  'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
  'Jul', 'Aug', 'Sept', 'Oct', 'Nov', 'Dec'
];

/// DateTime -> "19 Sept, 26"
String formatOrderDateTime(DateTime d) =>
    '${d.day.toString().padLeft(2, '0')} ${_kMonths[d.month - 1]}, '
        '${(d.year % 100).toString().padLeft(2, '0')}';

/// "19/09/2026" -> "19 Sept, 26"
String formatOrderDate(String raw) {
  try {
    final p = raw.split('/');
    if (p.length == 3) {
      return formatOrderDateTime(
          DateTime(int.parse(p[2]), int.parse(p[1]), int.parse(p[0])));
    }
  } catch (_) {}
  return raw;
}

// ==================== Animated Entry ====================
class AnimatedEntry extends StatefulWidget {
  final Widget child;
  final int delayMs;
  const AnimatedEntry({super.key, required this.child, this.delayMs = 0});

  @override
  State<AnimatedEntry> createState() => _AnimatedEntryState();
}

class _AnimatedEntryState extends State<AnimatedEntry>
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

// ==================== Compact Header ====================
// SliverToBoxAdapter ke andar rakha jata hai, isliye list ke saath scroll hota hai.
class OrderListHeader extends StatelessWidget {
  final String title;
  final String subtitle;
  final VoidCallback? onBack;
  final VoidCallback onSort;
  final VoidCallback onFilterSettings;
  final bool filterActive;

  const OrderListHeader({
    super.key,
    required this.title,
    required this.subtitle,
    this.onBack,
    required this.onSort,
    required this.onFilterSettings,
    this.filterActive = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: OrderUi.heroGrad,
        boxShadow: OrderUi.glow(JoynColors.primary, 0.25),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: EdgeInsets.fromLTRB(onBack != null ? 8 : 20, onBack != null ? 4 : 14, 16, 14),
          child: Row(
            children: [
              if (onBack != null)
                IconButton(
                  onPressed: onBack,
                  icon: const Icon(Icons.arrow_back_rounded,
                      color: Colors.white, size: 22),
                ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 19,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 1),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.75),
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              _HeaderIconBtn(icon: Icons.swap_vert_rounded, onTap: onSort),
              const SizedBox(width: 8),
              _HeaderIconBtn(
                icon: Icons.tune_rounded,
                onTap: onFilterSettings,
                showDot: filterActive,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HeaderIconBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final bool showDot;
  const _HeaderIconBtn(
      {required this.icon, required this.onTap, this.showDot = false});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.15),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
        ),
        child: Stack(
          children: [
            Icon(icon, color: Colors.white, size: 18),
            if (showDot)
              Positioned(
                top: 0,
                right: 0,
                child: Container(
                  width: 7,
                  height: 7,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFB4AB),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 1),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ==================== Empty State ====================
class OrderEmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  const OrderEmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 88,
            height: 88,
            decoration: BoxDecoration(
              color: JoynColors.primary.withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 40, color: JoynColors.primary),
          ),
          const SizedBox(height: 18),
          Text(
            title,
            style: JoynTypography.titleMedium
                .copyWith(fontSize: 18, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 6),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              subtitle,
              textAlign: TextAlign.center,
              style: JoynTypography.subtitle.copyWith(fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}

// ==================== Order Card (Vyapar style) ====================
class OrderListCard extends StatelessWidget {
  final String title;
  final String badge;
  final Color badgeColor;
  final String number; // e.g. "#3"
  final String date; // already formatted
  final double total;
  final double balance;
  final VoidCallback onTap;
  final VoidCallback onPrint;
  final VoidCallback onShare;
  final VoidCallback onView;
  final VoidCallback onDelete;

  const OrderListCard({
    super.key,
    required this.title,
    required this.badge,
    required this.badgeColor,
    required this.number,
    required this.date,
    required this.total,
    required this.balance,
    required this.onTap,
    required this.onPrint,
    required this.onShare,
    required this.onView,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 8,
              offset: const Offset(0, 2)),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 6, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ---- Top: name + chip | #no + date ----
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: JoynTypography.bodyLarge.copyWith(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: OrderUi.textDark,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 5),
                            decoration: BoxDecoration(
                              color: badgeColor.withValues(alpha: 0.16),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              badge,
                              style: JoynTypography.caption.copyWith(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w600,
                                color: badgeColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(top: 2, right: 10),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(number,
                              style: JoynTypography.caption.copyWith(
                                  fontSize: 13, color: OrderUi.textMuted)),
                          const SizedBox(height: 6),
                          Text(date,
                              style: JoynTypography.caption.copyWith(
                                  fontSize: 13, color: OrderUi.textMuted)),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                // ---- Bottom: Total | Balance | actions ----
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(child: _amount('Total', total)),
                    Expanded(child: _amount('Balance', balance)),
                    _ActionIcon(icon: Icons.print_outlined, onTap: onPrint),
                    _ActionIcon(icon: Icons.shortcut_rounded, onTap: onShare),
                    _buildMenu(),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _amount(String label, double value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: JoynTypography.caption
                .copyWith(fontSize: 13, color: OrderUi.textMuted)),
        const SizedBox(height: 2),
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Text(
            '₹ ${value.toStringAsFixed(2)}',
            style: JoynTypography.bodyLarge.copyWith(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: OrderUi.textDark,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMenu() {
    return PopupMenuButton<String>(
      padding: EdgeInsets.zero,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      icon: const Icon(Icons.more_vert_rounded,
          color: OrderUi.textMuted, size: 22),
      onSelected: (v) {
        if (v == 'view') onView();
        if (v == 'delete') onDelete();
      },
      itemBuilder: (_) => [
        const PopupMenuItem(
          value: 'view',
          child: Row(children: [
            Icon(Icons.visibility_outlined, size: 18),
            SizedBox(width: 10),
            Text('View Details'),
          ]),
        ),
        PopupMenuItem(
          value: 'delete',
          child: Row(children: [
            Icon(Icons.delete_outline_rounded,
                size: 18, color: JoynColors.error),
            const SizedBox(width: 10),
            Text('Delete', style: TextStyle(color: JoynColors.error)),
          ]),
        ),
      ],
    );
  }
}

class _ActionIcon extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _ActionIcon({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkResponse(
      onTap: onTap,
      radius: 22,
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Icon(icon, size: 24, color: OrderUi.textMuted),
      ),
    );
  }
}