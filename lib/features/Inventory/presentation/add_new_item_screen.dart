import 'dart:io';
import 'dart:math';
import 'dart:ui' as ui;

import 'package:barcode_widget/barcode_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../../core/constants/tax_rates.dart';
import '../../../core/theme/joyn_colors.dart';
import '../../../core/theme/joyn_typography.dart';
import '../../../core/widgets/joyn_button.dart';
import '../../orders/data/sales_repository.dart';
import '../../orders/models/sales_models.dart';
import 'scan_code_screen.dart';
import '../../business_profile/presentation/widgets/image_crop_dialog.dart';

enum PricingTab { buying, selling }
enum TaxMode { inclusive, exclusive }
enum TaxVisibility { withTax, withoutTax }
enum BarcodeTab { barcode, qrCode }
enum BarcodeQtyMode { same, different }

class _AccentColors {
  static const addRed = Color(0xFFC0202B);
  static const addRedDark = Color(0xFF8E1620);
  static const toggleGreen = Color(0xFF16A34A);
  static const toggleBlue = Color(0xFF2563EB);
  static const togglePurple = Color(0xFF7C3AED);
}

// =====================================================================
// PREMIUM DESIGN SYSTEM — Diamond
// =====================================================================
class _Premium {
  static List<BoxShadow> cardShadow = [
    BoxShadow(color: Colors.black.withValues(alpha: 0.020), blurRadius: 2, offset: const Offset(0, 1)),
    BoxShadow(color: Colors.black.withValues(alpha: 0.030), blurRadius: 8, offset: const Offset(0, 3)),
    BoxShadow(color: Colors.black.withValues(alpha: 0.035), blurRadius: 20, offset: const Offset(0, 8)),
    BoxShadow(color: Colors.black.withValues(alpha: 0.025), blurRadius: 40, offset: const Offset(0, 16)),
  ];

  static List<BoxShadow> fieldShadow = [
    BoxShadow(color: Colors.black.withValues(alpha: 0.025), blurRadius: 3, offset: const Offset(0, 1)),
    BoxShadow(color: Colors.black.withValues(alpha: 0.030), blurRadius: 12, offset: const Offset(0, 4)),
  ];

  static List<BoxShadow> hairlineShadow = [
    BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 6, offset: const Offset(0, 2)),
  ];

  static List<BoxShadow> chipShadow(Color color) => [
    BoxShadow(color: color.withValues(alpha: 0.20), blurRadius: 6, offset: const Offset(0, 2)),
    BoxShadow(color: color.withValues(alpha: 0.28), blurRadius: 16, offset: const Offset(0, 7)),
    BoxShadow(color: color.withValues(alpha: 0.15), blurRadius: 30, offset: const Offset(0, 14)),
  ];

  static List<BoxShadow> floatingShadow(Color color) => [
    BoxShadow(color: color.withValues(alpha: 0.25), blurRadius: 8, offset: const Offset(0, 3)),
    BoxShadow(color: color.withValues(alpha: 0.35), blurRadius: 22, offset: const Offset(0, 10)),
    BoxShadow(color: color.withValues(alpha: 0.18), blurRadius: 40, offset: const Offset(0, 18)),
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

  static LinearGradient shineSweep = LinearGradient(
    begin: Alignment(-1.0, -1.0),
    end: Alignment(0.5, 0.5),
    colors: [
      Colors.white.withValues(alpha: 0.0),
      Colors.white.withValues(alpha: 0.28),
      Colors.white.withValues(alpha: 0.0),
    ],
    stops: const [0.35, 0.5, 0.65],
  );

  static Border hairline({double width = 1.0, double alpha = 1}) =>
      Border.all(color: JoynColors.border.withValues(alpha: alpha), width: width);
}

// =====================================================================
// PRESSABLE
// =====================================================================
class _Pressable extends StatefulWidget {
  const _Pressable({
    required this.child,
    required this.onTap,
    this.scale = 0.97,
    this.borderRadius = 16,
    this.onLongPress,
  });

  final Widget child;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;
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
      onLongPress: widget.onLongPress,
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
// ANIMATED REVEAL
// =====================================================================
class _AnimatedReveal extends StatelessWidget {
  const _AnimatedReveal({
    required this.show,
    required this.child,
    this.duration = const Duration(milliseconds: 320),
    this.slideOffset = 0.06,
  });

  final bool show;
  final Widget child;
  final Duration duration;
  final double slideOffset;

  @override
  Widget build(BuildContext context) {
    return AnimatedSize(
      duration: duration,
      curve: Curves.easeOutCubic,
      alignment: Alignment.topCenter,
      child: AnimatedSwitcher(
        duration: duration,
        switchInCurve: Curves.easeOutCubic,
        switchOutCurve: Curves.easeIn,
        layoutBuilder: (currentChild, previousChildren) {
          return Stack(
            alignment: Alignment.topCenter,
            children: [
              ...previousChildren,
              if (currentChild != null) currentChild,
            ],
          );
        },
        transitionBuilder: (child, animation) {
          return FadeTransition(
            opacity: animation,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: Offset(0, slideOffset),
                end: Offset.zero,
              ).animate(CurvedAnimation(
                parent: animation,
                curve: Curves.easeOutCubic,
              )),
              child: child,
            ),
          );
        },
        child: show
            ? Container(key: const ValueKey('show'), child: child)
            : const SizedBox.shrink(key: ValueKey('hide')),
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
    duration: const Duration(milliseconds: 460),
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
    final delay = Duration(milliseconds: (widget.index * 60).clamp(0, 500));
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
// GRADIENT BUTTON
// =====================================================================
class _GradientButton extends StatelessWidget {
  const _GradientButton({
    required this.onPressed,
    required this.icon,
    required this.label,
    required this.color,
    this.compact = false,
  });

  final VoidCallback onPressed;
  final IconData icon;
  final String label;
  final Color color;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return _Pressable(
      onTap: onPressed,
      scale: 0.96,
      borderRadius: 14,
      child: Container(
        decoration: BoxDecoration(
          gradient: _Premium.gradient(color),
          borderRadius: BorderRadius.circular(14),
          boxShadow: _Premium.floatingShadow(color),
        ),
        child: Stack(
          children: [
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: _Premium.shineSweep,
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
            Positioned(
              left: 0,
              right: 0,
              top: 0,
              height: 20,
              child: Container(
                decoration: BoxDecoration(
                  gradient: _Premium.topHighlight,
                  borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(14)),
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.symmetric(vertical: compact ? 12 : 13),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.22),
                      borderRadius: BorderRadius.circular(7),
                    ),
                    child: Icon(icon, size: 13, color: Colors.white),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    label,
                    style: JoynTypography.buttonText.copyWith(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.2,
                      color: Colors.white,
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
}

// =====================================================================
// FOCUS-AWARE FIELD
// =====================================================================
class _FocusField extends StatefulWidget {
  const _FocusField({
    required this.child,
    this.height = 54,
    this.borderRadius = 16,
  });
  final Widget child;
  final double height;
  final double borderRadius;

  @override
  State<_FocusField> createState() => _FocusFieldState();
}

class _FocusFieldState extends State<_FocusField> {
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    return Focus(
      onFocusChange: (f) => setState(() => _focused = f),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height: widget.height,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(widget.borderRadius),
          border: Border.all(
            color: _focused
                ? JoynColors.primary.withValues(alpha: 0.55)
                : JoynColors.border.withValues(alpha: 0.85),
            width: _focused ? 1.5 : 1.2,
          ),
          boxShadow: _focused
              ? [
            BoxShadow(
                color: JoynColors.primary.withValues(alpha: 0.14),
                blurRadius: 16,
                offset: const Offset(0, 5)),
            ..._Premium.fieldShadow,
          ]
              : _Premium.fieldShadow,
        ),
        child: widget.child,
      ),
    );
  }
}

// =====================================================================
// HERO SUMMARY CARD — live preview
// =====================================================================
class _HeroSummaryCard extends StatelessWidget {
  const _HeroSummaryCard({
    required this.itemName,
    required this.category,
    required this.price,
    required this.isSelling,
    required this.hasPhoto,
    required this.photoPath,
    required this.completionPercent,
  });

  final String itemName;
  final String? category;
  final double price;
  final bool isSelling;
  final bool hasPhoto;
  final String? photoPath;
  final double completionPercent;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 22),
      decoration: BoxDecoration(
        gradient: _Premium.deepGradient(JoynColors.primary),
        borderRadius: BorderRadius.circular(24),
        boxShadow: _Premium.floatingShadow(JoynColors.primary),
      ),
      child: Stack(
        children: [
          Positioned(
            top: -50,
            right: -40,
            child: Container(
              width: 180,
              height: 180,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(colors: [
                  Colors.white.withValues(alpha: 0.22),
                  Colors.white.withValues(alpha: 0.0),
                ]),
              ),
            ),
          ),
          Positioned(
            bottom: -60,
            left: -40,
            child: Container(
              width: 160,
              height: 160,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(colors: [
                  Colors.white.withValues(alpha: 0.12),
                  Colors.white.withValues(alpha: 0.0),
                ]),
              ),
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            top: 0,
            height: 40,
            child: Container(
              decoration: BoxDecoration(
                gradient: _Premium.topHighlight,
                borderRadius:
                const BorderRadius.vertical(top: Radius.circular(24)),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 9, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.16),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                            color: Colors.white.withValues(alpha: 0.20),
                            width: 0.8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.auto_awesome_rounded,
                              size: 10, color: Colors.white),
                          const SizedBox(width: 5),
                          Text('LIVE PREVIEW',
                              style: JoynTypography.caption.copyWith(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.white,
                                  letterSpacing: 1.2)),
                        ],
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 9, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.14),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.trending_up_rounded,
                              size: 11, color: Colors.white),
                          const SizedBox(width: 4),
                          Text('${completionPercent.toStringAsFixed(0)}%',
                              style: JoynTypography.caption.copyWith(
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.white)),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.16),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                            color: Colors.white.withValues(alpha: 0.22),
                            width: 1),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: hasPhoto && photoPath != null
                          ? Image.file(File(photoPath!), fit: BoxFit.cover)
                          : Icon(
                        Icons.inventory_2_outlined,
                        size: 28,
                        color: Colors.white.withValues(alpha: 0.85),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            itemName.isEmpty ? 'Untitled Item' : itemName,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: JoynTypography.titleMedium.copyWith(
                                fontSize: 17,
                                fontWeight: FontWeight.w900,
                                color: Colors.white,
                                letterSpacing: -0.3,
                                height: 1.15),
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              if (category != null && category!.isNotEmpty)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 9, vertical: 3),
                                  decoration: BoxDecoration(
                                    color:
                                    Colors.white.withValues(alpha: 0.14),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(category!,
                                      style: JoynTypography.caption.copyWith(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w800,
                                          color: Colors.white)),
                                ),
                              if (category != null &&
                                  category!.isNotEmpty &&
                                  price > 0)
                                const SizedBox(width: 6),
                              if (price > 0)
                                Row(
                                  children: [
                                    Icon(Icons.currency_rupee_rounded,
                                        size: 11,
                                        color: Colors.white
                                            .withValues(alpha: 0.85)),
                                    Text(price.toStringAsFixed(0),
                                        style: JoynTypography.caption.copyWith(
                                            fontSize: 12.5,
                                            fontWeight: FontWeight.w900,
                                            color: Colors.white,
                                            letterSpacing: -0.2)),
                                    const SizedBox(width: 3),
                                    Text(isSelling ? 'selling' : 'buying',
                                        style: JoynTypography.caption.copyWith(
                                            fontSize: 9.5,
                                            fontWeight: FontWeight.w700,
                                            color: Colors.white
                                                .withValues(alpha: 0.7))),
                                  ],
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: Stack(
                    children: [
                      Container(
                        height: 6,
                        color: Colors.white.withValues(alpha: 0.18),
                      ),
                      FractionallySizedBox(
                        widthFactor: completionPercent / 100,
                        child: Container(
                          height: 6,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Colors.white.withValues(alpha: 0.9),
                                Colors.white.withValues(alpha: 0.65),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(6),
                            boxShadow: [
                              BoxShadow(
                                  color: Colors.white.withValues(alpha: 0.4),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2)),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Text('Fill all fields to complete this item',
                    style: JoynTypography.caption.copyWith(
                        fontSize: 10.5,
                        color: Colors.white.withValues(alpha: 0.75),
                        fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// =====================================================================
// SUCCESS OVERLAY
// =====================================================================
class _SuccessOverlay extends StatelessWidget {
  const _SuccessOverlay({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: 1),
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeOutBack,
        builder: (context, value, child) {
          return Transform.scale(
            scale: value,
            child: Opacity(opacity: value.clamp(0, 1), child: child),
          );
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 22),
          decoration: BoxDecoration(
            gradient: _Premium.gradient(JoynColors.success),
            borderRadius: BorderRadius.circular(22),
            boxShadow: _Premium.floatingShadow(JoynColors.success),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.24),
                  border: Border.all(
                      color: Colors.white.withValues(alpha: 0.3),
                      width: 1.5),
                ),
                child: const Icon(Icons.check_rounded,
                    size: 34, color: Colors.white),
              ),
              const SizedBox(height: 14),
              Text(message,
                  style: JoynTypography.bodyLarge.copyWith(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: Colors.white)),
            ],
          ),
        ),
      ),
    );
  }
}

// =====================================================================
// FROSTED BAR
// =====================================================================
class _FrostedBar extends StatelessWidget {
  const _FrostedBar({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Container(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 14),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.78),
            border: Border(
              top: BorderSide(
                  color: JoynColors.border.withValues(alpha: 0.55),
                  width: 1),
            ),
          ),
          child: SafeArea(top: false, child: child),
        ),
      ),
    );
  }
}

// =====================================================================
// CORNER ACCENTS — decorative brackets
// =====================================================================
class _CornerAccents extends StatelessWidget {
  const _CornerAccents({
    required this.color,
    this.size = 14,
    this.thickness = 2.4,
    this.radius = 8,
  });
  final Color color;
  final double size;
  final double thickness;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned(top: 0, left: 0, child: _buildCorner(Alignment.topLeft)),
        Positioned(top: 0, right: 0, child: _buildCorner(Alignment.topRight)),
        Positioned(
            bottom: 0, left: 0, child: _buildCorner(Alignment.bottomLeft)),
        Positioned(
            bottom: 0, right: 0, child: _buildCorner(Alignment.bottomRight)),
      ],
    );
  }

  Widget _buildCorner(Alignment alignment) {
    final isTop = alignment == Alignment.topLeft ||
        alignment == Alignment.topRight;
    final isLeft = alignment == Alignment.topLeft ||
        alignment == Alignment.bottomLeft;
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _CornerPainter(
          color: color,
          isTop: isTop,
          isLeft: isLeft,
          thickness: thickness,
          radius: radius,
        ),
      ),
    );
  }
}

class _CornerPainter extends CustomPainter {
  _CornerPainter({
    required this.color,
    required this.isTop,
    required this.isLeft,
    required this.thickness,
    required this.radius,
  });
  final Color color;
  final bool isTop;
  final bool isLeft;
  final double thickness;
  final double radius;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = thickness
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final path = Path();
    if (isTop && isLeft) {
      path.moveTo(0, size.height);
      path.lineTo(0, radius);
      path.arcToPoint(Offset(radius, 0), radius: Radius.circular(radius));
      path.lineTo(size.width, 0);
    } else if (isTop && !isLeft) {
      path.moveTo(0, 0);
      path.lineTo(size.width - radius, 0);
      path.arcToPoint(Offset(size.width, radius),
          radius: Radius.circular(radius));
      path.lineTo(size.width, size.height);
    } else if (!isTop && isLeft) {
      path.moveTo(0, 0);
      path.lineTo(0, size.height - radius);
      path.arcToPoint(Offset(radius, size.height),
          radius: Radius.circular(radius));
      path.lineTo(size.width, size.height);
    } else {
      path.moveTo(size.width, 0);
      path.lineTo(size.width, size.height - radius);
      path.arcToPoint(Offset(size.width - radius, size.height),
          radius: Radius.circular(radius));
      path.lineTo(0, size.height);
    }
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _CornerPainter oldDelegate) => false;
}

// =====================================================================
// MAIN SCREEN
// =====================================================================
class AddNewItemScreen extends StatefulWidget {
  const AddNewItemScreen({super.key, this.existingItem});

  final InventoryItemModel? existingItem;

  @override
  State<AddNewItemScreen> createState() => _AddNewItemScreenState();
}

class _AddNewItemScreenState extends State<AddNewItemScreen> {
  final _salesRepository = SalesRepository();

  final _skuController = TextEditingController();
  final _itemNameController = TextEditingController();
  final _qtyController = TextEditingController();
  final _hsnSacController = TextEditingController();

  String _selectedUnit = 'Select Unit';
  String? _selectedCategory;
  String _selectedLocation = 'Select Location';

  bool _primaryUnitOnly = true;
  String _selectedSecondaryUnit = 'Select Unit';
  final _secondaryConversionController = TextEditingController();

  final List<String> _units = [
    'Select Unit', 'Pcs', 'Kg', 'Gram', 'Litre', 'ml',
    'Box', 'Dozen', 'Meter', 'Bag', 'Packet', 'Other',
  ];

  List<String> _categories = [];
  List<String> _locations = [];

  PricingTab _pricingTab = PricingTab.selling;
  final _buyingPriceController = TextEditingController();
  TaxVisibility _buyingTaxVisibility = TaxVisibility.withoutTax;
  TaxMode _buyingTaxMode = TaxMode.exclusive;
  TaxRateOption _buyingTaxRate = kTaxRateOptions.first;

  final _sellingPriceController = TextEditingController();
  TaxVisibility _sellingTaxVisibility = TaxVisibility.withoutTax;
  TaxMode _sellingTaxMode = TaxMode.exclusive;
  TaxRateOption _sellingTaxRate = kTaxRateOptions.first;

  BarcodeTab _barcodeTab = BarcodeTab.barcode;
  BarcodeQtyMode _barcodeQtyMode = BarcodeQtyMode.same;

  final _barcodeController = TextEditingController();
  final _qrValueController = TextEditingController();

  final List<String> _generatedCodes = [];
  final PageController _codePageController = PageController();
  int _currentCodePage = 0;

  String? _photoPath;
  static const double _standardPhotoSize = 180;
  bool _isSaving = false;

  bool _showSuccessOverlay = false;
  String _successMessage = '';

  bool get _isEditMode => widget.existingItem != null;

  @override
  void initState() {
    super.initState();
    _buyingPriceController.addListener(_onPriceChanged);
    _sellingPriceController.addListener(_onPriceChanged);
    _qtyController.addListener(_onQtyChanged);
    _itemNameController.addListener(_onPriceChanged);

    _loadCategoriesAndLocations();
  }

  Future<void> _loadCategoriesAndLocations() async {
    try {
      final cats = await _salesRepository.getCategories();
      final locs = await _salesRepository.getLocations();
      if (!mounted) return;

      _categories = cats.isNotEmpty
          ? cats
          : ['Grocery', 'Electronics', 'Garments', 'Stationery', 'Other'];
      _locations = locs.isNotEmpty
          ? locs
          : [
        'Select Location',
        'Rack A1',
        'Rack A2',
        'Warehouse 1',
        'Store Front'
      ];

      if (_isEditMode) {
        await _prefillFromExistingItem();
      }

      if (mounted) setState(() {});
    } catch (e) {
      debugPrint('Error loading categories/locations: $e');
      if (!mounted) return;
      setState(() {
        _categories = [
          'Grocery',
          'Electronics',
          'Garments',
          'Stationery',
          'Other'
        ];
        _locations = [
          'Select Location',
          'Rack A1',
          'Rack A2',
          'Warehouse 1',
          'Store Front'
        ];
      });
      if (_isEditMode) {
        await _prefillFromExistingItem();
        if (mounted) setState(() {});
      }
    }
  }

  Future<void> _prefillFromExistingItem() async {
    final item = widget.existingItem;
    if (item == null) return;

    _itemNameController.text = item.name;
    _qtyController.text = item.qty.toString();
    _hsnSacController.text = item.hsnSac;
    _buyingPriceController.text = item.purchasePrice.toString();
    _sellingPriceController.text = item.sellingPrice.toString();
    _barcodeController.text = item.barcode;
    _selectedUnit = item.unit;
    _photoPath = item.photoPath.isNotEmpty ? item.photoPath : null;

    if (item.category.isNotEmpty && !_categories.contains(item.category)) {
      await _salesRepository.insertCategory(item.category);
      _categories.add(item.category);
    }
    _selectedCategory = item.category.isNotEmpty ? item.category : null;

    if (item.location.isNotEmpty && !_locations.contains(item.location)) {
      await _salesRepository.insertLocation(item.location);
      _locations.add(item.location);
    }
    _selectedLocation =
    item.location.isNotEmpty ? item.location : 'Select Location';

    _buyingTaxMode = item.purchasePriceTaxMode == PriceTaxMode.withTax
        ? TaxMode.inclusive
        : TaxMode.exclusive;
    _sellingTaxMode = item.salePriceTaxMode == PriceTaxMode.withTax
        ? TaxMode.inclusive
        : TaxMode.exclusive;

    for (final rate in kTaxRateOptions) {
      if (rate.rate == item.taxRatePercent) {
        _buyingTaxRate = rate;
        _sellingTaxRate = rate;
        break;
      }
    }
  }

  void _onPriceChanged() {
    if (mounted) setState(() {});
  }

  void _onQtyChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _itemNameController.removeListener(_onPriceChanged);
    _itemNameController.dispose();
    _qtyController.removeListener(_onQtyChanged);
    _skuController.dispose();
    _qtyController.dispose();
    _hsnSacController.dispose();
    _secondaryConversionController.dispose();
    _buyingPriceController.removeListener(_onPriceChanged);
    _sellingPriceController.removeListener(_onPriceChanged);
    _buyingPriceController.dispose();
    _sellingPriceController.dispose();
    _barcodeController.dispose();
    _qrValueController.dispose();
    _codePageController.dispose();
    super.dispose();
  }

  // ---------------- HELPERS ----------------

  double get _completionPercent {
    int filled = 0;
    int total = 6;

    if (_itemNameController.text.trim().isNotEmpty) filled++;
    if (_qtyController.text.trim().isNotEmpty) filled++;
    if (_selectedCategory != null && _selectedCategory!.isNotEmpty) filled++;
    if (_selectedUnit != 'Select Unit') filled++;
    if (_buyingPriceController.text.trim().isNotEmpty ||
        _sellingPriceController.text.trim().isNotEmpty) filled++;
    if (_photoPath != null) filled++;

    return (filled / total) * 100;
  }

  double get _currentDisplayPrice {
    final isSelling = _pricingTab == PricingTab.selling;
    final controller =
    isSelling ? _sellingPriceController : _buyingPriceController;
    return double.tryParse(controller.text.trim()) ?? 0;
  }

  // ---------------- LOGIC ----------------

  void _ensureGeneratedCodesLength(int count) {
    final target = count.clamp(0, 500);
    if (_generatedCodes.length < target) {
      while (_generatedCodes.length < target) {
        _generatedCodes.add(_generateCode());
      }
    } else if (_generatedCodes.length > target) {
      _generatedCodes.removeRange(target, _generatedCodes.length);
    }
    if (_currentCodePage >= _generatedCodes.length) {
      _currentCodePage =
      _generatedCodes.isEmpty ? 0 : _generatedCodes.length - 1;
    }
  }

  void _regenerateAllCodes() {
    HapticFeedback.lightImpact();
    setState(() {
      for (var i = 0; i < _generatedCodes.length; i++) {
        _generatedCodes[i] = _generateCode();
      }
    });
  }

  void _regenerateCodeAt(int index) {
    if (index < 0 || index >= _generatedCodes.length) return;
    HapticFeedback.selectionClick();
    setState(() => _generatedCodes[index] = _generateCode());
  }

  void _copyToClipboard(String value, String label) {
    if (value.isEmpty) return;
    HapticFeedback.lightImpact();
    Clipboard.setData(ClipboardData(text: value));
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_rounded,
                color: Colors.white, size: 18),
            const SizedBox(width: 10),
            Text('$label copied'),
          ],
        ),
        duration: const Duration(seconds: 2),
        backgroundColor: JoynColors.primary,
        behavior: SnackBarBehavior.floating,
        elevation: 6,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14)),
      ),
    );
  }

  String _generateCode() {
    final rand = Random();
    return List.generate(6, (_) => rand.nextInt(10)).join();
  }

  void _regenerateCode() {
    HapticFeedback.lightImpact();
    setState(() {
      final code = _generateCode();
      if (_barcodeTab == BarcodeTab.barcode) {
        _barcodeController.text = code;
      } else {
        _qrValueController.text = code;
      }
    });
  }

  Future<void> _openScanner() async {
    final result = await Navigator.of(context).push<String>(
      MaterialPageRoute(builder: (_) => const ScanCodeScreen()),
    );
    if (result != null && result.isNotEmpty) {
      setState(() {
        if (_barcodeTab == BarcodeTab.barcode) {
          _barcodeController.text = result;
        } else {
          _qrValueController.text = result;
        }
      });
    }
  }

  Future<void> _createLocation() async {
    final controller = TextEditingController();
    final focusNode = FocusNode();

    try {
      final result = await showDialog<String>(
        context: context,
        useRootNavigator: false,
        builder: (dialogContext) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (focusNode.canRequestFocus) focusNode.requestFocus();
          });
          return AlertDialog(
            backgroundColor: JoynColors.background,
            elevation: 12,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(22)),
            title: Text('New Location',
                style: JoynTypography.titleMedium
                    .copyWith(fontSize: 18, fontWeight: FontWeight.w800)),
            content: TextField(
              controller: controller,
              focusNode: focusNode,
              autofocus: false,
              decoration: InputDecoration(
                hintText: 'Enter Warehouse location name',
                filled: true,
                fillColor: JoynColors.chipBackground,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
                contentPadding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () =>
                    Navigator.of(dialogContext).pop(controller.text.trim()),
                style:
                TextButton.styleFrom(foregroundColor: _AccentColors.addRed),
                child: const Text('Add',
                    style: TextStyle(fontWeight: FontWeight.w800)),
              ),
            ],
          );
        },
      );

      if (!mounted) return;

      if (result != null && result.isNotEmpty) {
        await _salesRepository.insertLocation(result);
        if (!mounted) return;
        setState(() {
          if (!_locations.contains(result)) _locations.add(result);
          _selectedLocation = result;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Location "$result" added'),
            backgroundColor: JoynColors.primary,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 1),
            margin: const EdgeInsets.all(16),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14)),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not add location: $e'),
          backgroundColor: JoynColors.error,
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(16),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14)),
        ),
      );
    } finally {
      controller.dispose();
      focusNode.dispose();
    }
  }

  Future<void> _confirmDeleteLocation(String location) async {
    final confirmed = await showDialog<bool>(
      context: context,
      useRootNavigator: false,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: JoynColors.background,
        elevation: 12,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        title: Text('Delete Location?',
            style: JoynTypography.titleMedium
                .copyWith(fontSize: 17, fontWeight: FontWeight.w800)),
        content: Text('Remove "$location" from your locations list?',
            style: JoynTypography.bodyMedium
                .copyWith(fontSize: 13.5, color: JoynColors.secondaryText)),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text('Delete',
                style: TextStyle(
                    color: JoynColors.error, fontWeight: FontWeight.w800)),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      await _salesRepository.deleteLocation(location);
      if (!mounted) return;
      setState(() {
        _locations.remove(location);
        if (_selectedLocation == location) _selectedLocation = 'Select Location';
      });
    }
  }

  Future<void> _createCategory() async {
    final controller = TextEditingController();
    final focusNode = FocusNode();

    try {
      final result = await showDialog<String>(
        context: context,
        useRootNavigator: false,
        builder: (dialogContext) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (focusNode.canRequestFocus) focusNode.requestFocus();
          });
          return AlertDialog(
            backgroundColor: JoynColors.background,
            elevation: 12,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(22)),
            title: Text('New Category',
                style: JoynTypography.titleMedium
                    .copyWith(fontSize: 18, fontWeight: FontWeight.w800)),
            content: TextField(
              controller: controller,
              focusNode: focusNode,
              autofocus: false,
              decoration: InputDecoration(
                hintText: 'Enter category name',
                filled: true,
                fillColor: JoynColors.chipBackground,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
                contentPadding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () =>
                    Navigator.of(dialogContext).pop(controller.text.trim()),
                style:
                TextButton.styleFrom(foregroundColor: _AccentColors.addRed),
                child: const Text('Add',
                    style: TextStyle(fontWeight: FontWeight.w800)),
              ),
            ],
          );
        },
      );

      if (!mounted) return;

      if (result != null && result.isNotEmpty) {
        await _salesRepository.insertCategory(result);
        if (!mounted) return;
        setState(() {
          if (!_categories.contains(result)) _categories.add(result);
          _selectedCategory = result;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Category "$result" added'),
            backgroundColor: JoynColors.primary,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 1),
            margin: const EdgeInsets.all(16),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14)),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not add category: $e'),
          backgroundColor: JoynColors.error,
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(16),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14)),
        ),
      );
    } finally {
      controller.dispose();
      focusNode.dispose();
    }
  }

  Future<void> _confirmDeleteCategory(String category) async {
    final confirmed = await showDialog<bool>(
      context: context,
      useRootNavigator: false,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: JoynColors.background,
        elevation: 12,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        title: Text('Delete Category?',
            style: JoynTypography.titleMedium
                .copyWith(fontSize: 17, fontWeight: FontWeight.w800)),
        content: Text('Remove "$category" from your categories list?',
            style: JoynTypography.bodyMedium
                .copyWith(fontSize: 13.5, color: JoynColors.secondaryText)),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text('Delete',
                style: TextStyle(
                    color: JoynColors.error, fontWeight: FontWeight.w800)),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      await _salesRepository.deleteCategory(category);
      if (!mounted) return;
      setState(() {
        _categories.remove(category);
        if (_selectedCategory == category) _selectedCategory = null;
      });
    }
  }

  Future<void> _openCategoryPicker() async {
    await showModalBottomSheet<void>(
      context: context,
      useRootNavigator: false,
      backgroundColor: JoynColors.background,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (sheetContext, setSheetState) {
            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 40,
                      height: 4.5,
                      margin: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                          color: JoynColors.border,
                          borderRadius: BorderRadius.circular(3)),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(7),
                                decoration: BoxDecoration(
                                  gradient: _Premium.softGradient(
                                      JoynColors.primary),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Icon(Icons.category_outlined,
                                    size: 15, color: JoynColors.primary),
                              ),
                              const SizedBox(width: 10),
                              Text('Item Category',
                                  style: JoynTypography.titleMedium.copyWith(
                                      fontSize: 17,
                                      fontWeight: FontWeight.w800)),
                            ],
                          ),
                          _Pressable(
                            onTap: () {
                              Navigator.pop(sheetContext);
                              Future.delayed(
                                  const Duration(milliseconds: 200), () {
                                if (mounted) _createCategory();
                              });
                            },
                            scale: 0.94,
                            borderRadius: 20,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 11, vertical: 7),
                              decoration: BoxDecoration(
                                gradient: _Premium.softGradient(
                                    _AccentColors.addRed),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                    color: _AccentColors.addRed
                                        .withValues(alpha: 0.20),
                                    width: 1),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.add_circle_outline_rounded,
                                      size: 14, color: _AccentColors.addRed),
                                  const SizedBox(width: 4),
                                  Text('Add New',
                                      style:
                                      JoynTypography.bodyMedium.copyWith(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w800,
                                          color: _AccentColors.addRed)),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Text('Long-press a category to delete it',
                          style: JoynTypography.caption.copyWith(
                              fontSize: 11.5,
                              color: JoynColors.secondaryText)),
                    ),
                    const SizedBox(height: 8),
                    if (_categories.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 32),
                        child: Text('No categories yet',
                            style: JoynTypography.subtitle
                                .copyWith(fontSize: 13.5)),
                      )
                    else
                      ConstrainedBox(
                        constraints: BoxConstraints(
                            maxHeight:
                            MediaQuery.of(context).size.height * 0.5),
                        child: ListView.builder(
                          shrinkWrap: true,
                          itemCount: _categories.length,
                          itemBuilder: (context, index) {
                            final category = _categories[index];
                            final isSelected = _selectedCategory == category;
                            return _Pressable(
                              onTap: () {
                                setState(() => _selectedCategory = category);
                                Navigator.pop(sheetContext);
                              },
                              onLongPress: () async {
                                await _confirmDeleteCategory(category);
                                setSheetState(() {});
                              },
                              scale: 0.98,
                              borderRadius: 14,
                              child: Container(
                                margin: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 3),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 12),
                                decoration: BoxDecoration(
                                  gradient: isSelected
                                      ? _Premium.softGradient(
                                      JoynColors.primary)
                                      : null,
                                  borderRadius: BorderRadius.circular(14),
                                  border: isSelected
                                      ? Border.all(
                                      color: JoynColors.primary
                                          .withValues(alpha: 0.22),
                                      width: 1.2)
                                      : Border.all(
                                      color: JoynColors.border
                                          .withValues(alpha: 0.5),
                                      width: 1),
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 34,
                                      height: 34,
                                      alignment: Alignment.center,
                                      decoration: BoxDecoration(
                                        gradient: isSelected
                                            ? _Premium.gradient(
                                            JoynColors.primary)
                                            : _Premium.softGradient(
                                            JoynColors.primary),
                                        borderRadius:
                                        BorderRadius.circular(10),
                                      ),
                                      child: Icon(
                                        Icons.local_offer_outlined,
                                        size: 15,
                                        color: isSelected
                                            ? Colors.white
                                            : JoynColors.primary,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        category,
                                        style: JoynTypography.bodyLarge
                                            .copyWith(
                                            fontSize: 15,
                                            fontWeight: isSelected
                                                ? FontWeight.w800
                                                : FontWeight.w500,
                                            color: isSelected
                                                ? JoynColors.primary
                                                : Colors.black87),
                                      ),
                                    ),
                                    if (isSelected)
                                      Container(
                                        padding: const EdgeInsets.all(4),
                                        decoration: BoxDecoration(
                                          gradient: _Premium.gradient(
                                              JoynColors.primary),
                                          shape: BoxShape.circle,
                                          boxShadow: [
                                            BoxShadow(
                                                color: JoynColors.primary
                                                    .withValues(alpha: 0.32),
                                                blurRadius: 8,
                                                offset: const Offset(0, 2)),
                                          ],
                                        ),
                                        child: const Icon(Icons.check_rounded,
                                            size: 12, color: Colors.white),
                                      ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
    if (mounted) setState(() {});
  }

  Future<void> _openLocationPicker() async {
    await showModalBottomSheet<void>(
      context: context,
      useRootNavigator: false,
      backgroundColor: JoynColors.background,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (sheetContext, setSheetState) {
            final selectable =
            _locations.where((l) => l != 'Select Location').toList();
            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 40,
                      height: 4.5,
                      margin: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                          color: JoynColors.border,
                          borderRadius: BorderRadius.circular(3)),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(7),
                                decoration: BoxDecoration(
                                  gradient: _Premium.softGradient(
                                      JoynColors.primary),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Icon(Icons.place_outlined,
                                    size: 15, color: JoynColors.primary),
                              ),
                              const SizedBox(width: 10),
                              Text('Item Location',
                                  style: JoynTypography.titleMedium.copyWith(
                                      fontSize: 17,
                                      fontWeight: FontWeight.w800)),
                            ],
                          ),
                          _Pressable(
                            onTap: () {
                              Navigator.pop(sheetContext);
                              Future.delayed(
                                  const Duration(milliseconds: 200), () {
                                if (mounted) _createLocation();
                              });
                            },
                            scale: 0.94,
                            borderRadius: 20,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 11, vertical: 7),
                              decoration: BoxDecoration(
                                gradient: _Premium.softGradient(
                                    _AccentColors.addRed),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                    color: _AccentColors.addRed
                                        .withValues(alpha: 0.20),
                                    width: 1),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.add_circle_outline_rounded,
                                      size: 14, color: _AccentColors.addRed),
                                  const SizedBox(width: 4),
                                  Text('Add New',
                                      style:
                                      JoynTypography.bodyMedium.copyWith(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w800,
                                          color: _AccentColors.addRed)),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Text('Long-press a location to delete it',
                          style: JoynTypography.caption.copyWith(
                              fontSize: 11.5,
                              color: JoynColors.secondaryText)),
                    ),
                    const SizedBox(height: 8),
                    if (selectable.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 32),
                        child: Text('No locations yet',
                            style: JoynTypography.subtitle
                                .copyWith(fontSize: 13.5)),
                      )
                    else
                      ConstrainedBox(
                        constraints: BoxConstraints(
                            maxHeight:
                            MediaQuery.of(context).size.height * 0.5),
                        child: ListView.builder(
                          shrinkWrap: true,
                          itemCount: selectable.length,
                          itemBuilder: (context, index) {
                            final location = selectable[index];
                            final isSelected = _selectedLocation == location;
                            return _Pressable(
                              onTap: () {
                                setState(() => _selectedLocation = location);
                                Navigator.pop(sheetContext);
                              },
                              onLongPress: () async {
                                await _confirmDeleteLocation(location);
                                setSheetState(() {});
                              },
                              scale: 0.98,
                              borderRadius: 14,
                              child: Container(
                                margin: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 3),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 12),
                                decoration: BoxDecoration(
                                  gradient: isSelected
                                      ? _Premium.softGradient(
                                      JoynColors.primary)
                                      : null,
                                  borderRadius: BorderRadius.circular(14),
                                  border: isSelected
                                      ? Border.all(
                                      color: JoynColors.primary
                                          .withValues(alpha: 0.22),
                                      width: 1.2)
                                      : Border.all(
                                      color: JoynColors.border
                                          .withValues(alpha: 0.5),
                                      width: 1),
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 34,
                                      height: 34,
                                      alignment: Alignment.center,
                                      decoration: BoxDecoration(
                                        gradient: isSelected
                                            ? _Premium.gradient(
                                            JoynColors.primary)
                                            : _Premium.softGradient(
                                            JoynColors.primary),
                                        borderRadius:
                                        BorderRadius.circular(10),
                                      ),
                                      child: Icon(
                                        Icons.warehouse_outlined,
                                        size: 15,
                                        color: isSelected
                                            ? Colors.white
                                            : JoynColors.primary,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        location,
                                        style: JoynTypography.bodyLarge
                                            .copyWith(
                                            fontSize: 15,
                                            fontWeight: isSelected
                                                ? FontWeight.w800
                                                : FontWeight.w500,
                                            color: isSelected
                                                ? JoynColors.primary
                                                : Colors.black87),
                                      ),
                                    ),
                                    if (isSelected)
                                      Container(
                                        padding: const EdgeInsets.all(4),
                                        decoration: BoxDecoration(
                                          gradient: _Premium.gradient(
                                              JoynColors.primary),
                                          shape: BoxShape.circle,
                                          boxShadow: [
                                            BoxShadow(
                                                color: JoynColors.primary
                                                    .withValues(alpha: 0.32),
                                                blurRadius: 8,
                                                offset: const Offset(0, 2)),
                                          ],
                                        ),
                                        child: const Icon(Icons.check_rounded,
                                            size: 12, color: Colors.white),
                                      ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
    if (mounted) setState(() {});
  }

  Future<void> _pickAndCropPhoto(ImageSource source) async {
    try {
      final picker = ImagePicker();
      final image = await picker.pickImage(
          source: source, imageQuality: 90, maxWidth: 1600, maxHeight: 1600);
      if (image == null || !mounted) return;

      final String? croppedPath = await showDialog<String>(
        context: context,
        useRootNavigator: false,
        builder: (context) => ImageCropDialog(
            imagePath: image.path, title: 'Crop & Adjust Item Photo'),
      );
      if (croppedPath != null && mounted) {
        setState(() => _photoPath = croppedPath);
      }
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(source == ImageSource.camera
              ? 'Unable to open camera.'
              : 'Unable to open gallery.'),
          backgroundColor: JoynColors.error,
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(16),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14)),
        ),
      );
    }
  }

  Future<void> _openPhotoSourceSheet() async {
    await showModalBottomSheet<void>(
      context: context,
      useRootNavigator: false,
      backgroundColor: JoynColors.background,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4.5,
                  margin: const EdgeInsets.only(bottom: 8),
                  decoration: BoxDecoration(
                      color: JoynColors.border,
                      borderRadius: BorderRadius.circular(3)),
                ),
                Padding(
                  padding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(7),
                        decoration: BoxDecoration(
                          gradient:
                          _Premium.softGradient(JoynColors.primary),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.add_photo_alternate_outlined,
                            size: 15, color: JoynColors.primary),
                      ),
                      const SizedBox(width: 10),
                      Text('Add Item Photo',
                          style: JoynTypography.titleMedium.copyWith(
                              fontSize: 16, fontWeight: FontWeight.w800)),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                        'Photo will be cropped to a standard square size',
                        style: JoynTypography.caption.copyWith(
                            fontSize: 11.5,
                            color: JoynColors.secondaryText)),
                  ),
                ),
                const SizedBox(height: 6),
                _buildSheetTile(
                  icon: Icons.photo_camera_outlined,
                  label: 'Take Photo',
                  onTap: () {
                    Navigator.pop(sheetContext);
                    _pickAndCropPhoto(ImageSource.camera);
                  },
                ),
                _buildSheetTile(
                  icon: Icons.photo_library_outlined,
                  label: 'Choose from Gallery',
                  onTap: () {
                    Navigator.pop(sheetContext);
                    _pickAndCropPhoto(ImageSource.gallery);
                  },
                ),
                if (_photoPath != null) ...[
                  _buildSheetTile(
                    icon: Icons.crop_rounded,
                    label: 'Re-crop Current Photo',
                    onTap: () async {
                      Navigator.pop(sheetContext);
                      final path = _photoPath;
                      if (path == null || !mounted) return;
                      final croppedPath = await showDialog<String>(
                        context: context,
                        useRootNavigator: false,
                        builder: (context) => ImageCropDialog(
                            imagePath: path,
                            title: 'Crop & Adjust Item Photo'),
                      );
                      if (croppedPath != null && mounted) {
                        setState(() => _photoPath = croppedPath);
                      }
                    },
                  ),
                  _buildSheetTile(
                    icon: Icons.delete_outline_rounded,
                    label: 'Remove Photo',
                    isDestructive: true,
                    onTap: () {
                      Navigator.pop(sheetContext);
                      setState(() => _photoPath = null);
                    },
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSheetTile({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    final color = isDestructive ? JoynColors.error : _AccentColors.addRed;
    return _Pressable(
      onTap: onTap,
      scale: 0.98,
      borderRadius: 14,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                gradient: _Premium.softGradient(color),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color: color.withValues(alpha: 0.15), width: 1),
              ),
              child: Icon(icon, color: color, size: 19),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                label,
                style: JoynTypography.bodyLarge.copyWith(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: isDestructive ? JoynColors.error : JoynColors.primary,
                ),
              ),
            ),
            Icon(Icons.chevron_right_rounded,
                size: 18,
                color: JoynColors.secondaryText.withValues(alpha: 0.5)),
          ],
        ),
      ),
    );
  }

  ({double base, double taxAmount, double finalPrice}) _calculateTax({
    required double price,
    required TaxMode mode,
    required double ratePercent,
  }) {
    if (mode == TaxMode.inclusive) {
      final base = price / (1 + (ratePercent / 100));
      final taxAmount = price - base;
      return (base: base, taxAmount: taxAmount, finalPrice: price);
    } else {
      final taxAmount = price * (ratePercent / 100);
      final finalPrice = price + taxAmount;
      return (base: price, taxAmount: taxAmount, finalPrice: finalPrice);
    }
  }

  Future<void> _saveToDatabase() async {
    if (_itemNameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Item Name is required'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: JoynColors.error,
          margin: const EdgeInsets.all(16),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14)),
        ),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final item = InventoryItemModel(
        id: widget.existingItem?.id ??
            DateTime.now().millisecondsSinceEpoch.toString(),
        name: _itemNameController.text.trim(),
        qty: int.tryParse(_qtyController.text.trim()) ?? 0,
        barcode: _barcodeController.text.trim(),
        unit: _selectedUnit == 'Select Unit' ? 'Pcs' : _selectedUnit,
        category: _selectedCategory ?? '',
        hsnSac: _hsnSacController.text.trim(),
        location:
        _selectedLocation == 'Select Location' ? '' : _selectedLocation,
        barcodeMode:
        _barcodeQtyMode == BarcodeQtyMode.different ? 'separate' : 'same',
        purchasePrice: double.tryParse(_buyingPriceController.text.trim()) ?? 0,
        sellingPrice:
        double.tryParse(_sellingPriceController.text.trim()) ?? 0,
        purchasePriceTaxMode: _buyingTaxMode == TaxMode.inclusive
            ? PriceTaxMode.withTax
            : PriceTaxMode.withoutTax,
        salePriceTaxMode: _sellingTaxMode == TaxMode.inclusive
            ? PriceTaxMode.withTax
            : PriceTaxMode.withoutTax,
        taxRateLabel: _sellingTaxRate.label,
        taxRatePercent: _sellingTaxRate.rate,
        stock: int.tryParse(_qtyController.text.trim()) ?? 0,
        photoPath: _photoPath ?? '',
        createdAt: widget.existingItem?.createdAt ?? DateTime.now(),
      );

      debugPrint('Saving item: ${item.toDb()}');
      debugPrint('Is Edit Mode: $_isEditMode');

      if (_isEditMode) {
        await _salesRepository.updateItem(item);
        debugPrint('Item updated successfully');
      } else {
        await _salesRepository.insertItem(item);
        debugPrint('Item inserted successfully');
      }

      final savedItems = await _salesRepository.getItems();
      debugPrint('Total items after save: ${savedItems.length}');

      if (!mounted) return;

      HapticFeedback.mediumImpact();

      // Show success overlay
      setState(() {
        _showSuccessOverlay = true;
        _successMessage = _isEditMode ? 'Item Updated!' : 'Item Saved!';
      });

      await Future.delayed(const Duration(milliseconds: 900));

      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      debugPrint('Error saving item: $e');
      if (!mounted) return;
      setState(() => _isSaving = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to save item: $e'),
          backgroundColor: JoynColors.error,
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(16),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14)),
        ),
      );
    }
  }

  // =====================================================================
  // BUILD
  // =====================================================================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: JoynColors.background,
      extendBodyBehindAppBar: false,
      appBar: AppBar(
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: JoynColors.background,
        leading: Padding(
          padding: const EdgeInsets.only(left: 8),
          child: _Pressable(
            onTap: () => Navigator.of(context).pop(),
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
          _isEditMode ? 'Edit Item' : 'Add New Item',
          style: JoynTypography.titleMedium.copyWith(
              fontSize: 18, fontWeight: FontWeight.w800, letterSpacing: -0.3),
        ),
        actions: [
          if (_isEditMode)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Container(
                padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                margin: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  gradient: _Premium.softGradient(JoynColors.primary),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                      color: JoynColors.primary.withValues(alpha: 0.20),
                      width: 1),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.edit_rounded,
                        size: 11, color: JoynColors.primary),
                    const SizedBox(width: 4),
                    Text('Editing',
                        style: JoynTypography.caption.copyWith(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w800,
                            color: JoynColors.primary,
                            letterSpacing: 0.3)),
                  ],
                ),
              ),
            ),
        ],
      ),
      body: Stack(
        children: [
          SafeArea(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 100),
              children: [
                // HERO SUMMARY CARD
                _StaggeredItem(
                  index: 0,
                  child: _HeroSummaryCard(
                    itemName: _itemNameController.text,
                    category: _selectedCategory,
                    price: _currentDisplayPrice,
                    isSelling: _pricingTab == PricingTab.selling,
                    hasPhoto: _photoPath != null,
                    photoPath: _photoPath,
                    completionPercent: _completionPercent,
                  ),
                ),

                // SECTION 1
                _StaggeredItem(
                  index: 1,
                  child: _buildSectionHeader(
                      1, 'Item Details', Icons.inventory_2_outlined),
                ),
                const SizedBox(height: 16),
                _StaggeredItem(index: 2, child: _buildItemDetailsCard()),
                const SizedBox(height: 30),

                // SECTION 2
                _StaggeredItem(
                  index: 3,
                  child:
                  _buildSectionHeader(2, 'Pricing', Icons.sell_outlined),
                ),
                const SizedBox(height: 16),
                _StaggeredItem(index: 4, child: _buildPricingCard()),
                const SizedBox(height: 30),

                // SECTION 3
                _StaggeredItem(
                  index: 5,
                  child: _buildSectionHeader(
                      3, 'Barcode', Icons.qr_code_2_rounded),
                ),
                const SizedBox(height: 16),
                _StaggeredItem(index: 6, child: _buildBarcodeCard()),
                const SizedBox(height: 30),

                // SECTION 4
                _StaggeredItem(
                  index: 7,
                  child:
                  _buildSectionHeader(4, 'Photo', Icons.image_outlined),
                ),
                const SizedBox(height: 16),
                _StaggeredItem(index: 8, child: _buildPhotoPicker()),
              ],
            ),
          ),

          // FROSTED SAVE BAR
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: _FrostedBar(
              child: _Pressable(
                onTap: () {
                  if (_isSaving) return;
                  HapticFeedback.mediumImpact();
                  _saveToDatabase();
                },
                scale: 0.97,
                borderRadius: 18,
                child: Container(
                  height: 56,
                  decoration: BoxDecoration(
                    gradient: _Premium.gradient(JoynColors.primary),
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: _Premium.floatingShadow(JoynColors.primary),
                  ),
                  child: Stack(
                    children: [
                      Positioned.fill(
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: _Premium.shineSweep,
                            borderRadius: BorderRadius.circular(18),
                          ),
                        ),
                      ),
                      Positioned(
                        left: 0,
                        right: 0,
                        top: 0,
                        height: 24,
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: _Premium.topHighlight,
                            borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(18)),
                          ),
                        ),
                      ),
                      Center(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            if (_isSaving)
                              const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.4,
                                  valueColor: AlwaysStoppedAnimation(
                                      Colors.white),
                                ),
                              )
                            else
                              Container(
                                padding: const EdgeInsets.all(5),
                                decoration: BoxDecoration(
                                  color:
                                  Colors.white.withValues(alpha: 0.24),
                                  borderRadius: BorderRadius.circular(9),
                                  border: Border.all(
                                      color: Colors.white
                                          .withValues(alpha: 0.18),
                                      width: 0.6),
                                ),
                                child: Icon(
                                    _isEditMode
                                        ? Icons.check_circle_outline_rounded
                                        : Icons.save_outlined,
                                    color: Colors.white,
                                    size: 15),
                              ),
                            const SizedBox(width: 10),
                            Text(
                              _isSaving
                                  ? 'Saving...'
                                  : (_isEditMode
                                  ? 'Update Item'
                                  : 'Save Item'),
                              style: JoynTypography.buttonText.copyWith(
                                fontSize: 15.5,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                                letterSpacing: 0.3,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // SUCCESS OVERLAY
          if (_showSuccessOverlay)
            Positioned.fill(
              child: Container(
                color: Colors.black.withValues(alpha: 0.35),
                child: _SuccessOverlay(message: _successMessage),
              ),
            ),
        ],
      ),
    );
  }

  // =====================================================================
  // SECTION HEADER
  // =====================================================================
  Widget _buildSectionHeader(int number, String title, IconData icon) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 32,
              height: 32,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                gradient: _Premium.gradient(Colors.black87),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                      color: Colors.black.withValues(alpha: 0.28),
                      blurRadius: 10,
                      offset: const Offset(0, 4)),
                  BoxShadow(
                      color: Colors.black.withValues(alpha: 0.12),
                      blurRadius: 2,
                      offset: const Offset(0, 1)),
                ],
              ),
              child: Text('$number',
                  style: JoynTypography.caption.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      fontSize: 13.5)),
            ),
            const SizedBox(width: 11),
            Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                gradient: _Premium.softGradient(JoynColors.primary),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                    color: JoynColors.primary.withValues(alpha: 0.12),
                    width: 1),
              ),
              child: Icon(icon, size: 14, color: JoynColors.primary),
            ),
            const SizedBox(width: 9),
            Expanded(
              child: Text(title,
                  style: JoynTypography.bodyLarge.copyWith(
                      fontWeight: FontWeight.w800,
                      fontSize: 16.5,
                      letterSpacing: -0.28,
                      color: Colors.black87)),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          height: 1.5,
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [
              JoynColors.primary.withValues(alpha: 0.42),
              JoynColors.primary.withValues(alpha: 0.10),
              JoynColors.primary.withValues(alpha: 0.0),
            ]),
          ),
        ),
      ],
    );
  }

  // =====================================================================
  // ITEM DETAILS CARD
  // =====================================================================
  Widget _buildItemDetailsCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: _Premium.surfaceGradient,
        borderRadius: BorderRadius.circular(22),
        border: _Premium.hairline(width: 1.0, alpha: 0.85),
        boxShadow: _Premium.cardShadow,
      ),
      child: Column(
        children: [
          _buildFormField(
              label: 'Item Name *',
              hintText: 'Enter item name',
              controller: _itemNameController,
              icon: Icons.inventory_2_outlined),
          const SizedBox(height: 12),
          _buildFormField(
              label: 'SKU',
              controller: _skuController,
              hintText: 'Enter SKU',
              icon: Icons.tag_rounded),
          const SizedBox(height: 12),
          _buildQtyUnitRow(),
          const SizedBox(height: 12),
          _buildSecondaryUnitSection(),
          const SizedBox(height: 14),
          _buildCategoryPickerField(),
          const SizedBox(height: 14),
          _buildFormField(
              label: 'HSN / SAC Code',
              hintText: 'Enter HSN or SAC code',
              controller: _hsnSacController,
              icon: Icons.receipt_long_outlined),
          const SizedBox(height: 14),
          _buildLocationField(),
        ],
      ),
    );
  }

  // ============ QTY + UNIT ROW ============
  Widget _buildQtyUnitRow() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: _buildCompactTextField(
            label: 'Qty',
            hintText: '0',
            controller: _qtyController,
            keyboardType: TextInputType.number,
            icon: Icons.numbers_rounded,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _buildCompactUnitDropdown(
            label: 'Unit',
            value: _selectedUnit,
            icon: Icons.straighten_rounded,
            onChanged: (val) {
              setState(() => _selectedUnit = val ?? _selectedUnit);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildCompactTextField({
    required String label,
    required String hintText,
    required TextEditingController controller,
    TextInputType keyboardType = TextInputType.text,
    IconData? icon,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: JoynTypography.bodyMedium.copyWith(
                fontSize: 11.5,
                fontWeight: FontWeight.w700,
                color: JoynColors.secondaryText,
                letterSpacing: 0.1)),
        const SizedBox(height: 5),
        _FocusField(
          height: 44,
          borderRadius: 12,
          child: Row(
            children: [
              if (icon != null) ...[
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    gradient: _Premium.softGradient(JoynColors.primary),
                    borderRadius: BorderRadius.circular(7),
                  ),
                  child: Icon(icon, size: 11, color: JoynColors.primary),
                ),
                const SizedBox(width: 7),
              ],
              Expanded(
                child: TextField(
                  controller: controller,
                  keyboardType: keyboardType,
                  style: JoynTypography.bodyLarge.copyWith(
                      fontSize: 13.5, fontWeight: FontWeight.w600),
                  decoration: InputDecoration(
                    hintText: hintText,
                    hintStyle: JoynTypography.bodyLarge.copyWith(
                        color: JoynColors.secondaryText.withValues(alpha: 0.5),
                        fontSize: 13,
                        fontWeight: FontWeight.w500),
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCompactUnitDropdown({
    required String label,
    required String value,
    required IconData icon,
    required ValueChanged<String?> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: JoynTypography.bodyMedium.copyWith(
                fontSize: 11.5,
                fontWeight: FontWeight.w700,
                color: JoynColors.secondaryText,
                letterSpacing: 0.1)),
        const SizedBox(height: 5),
        Container(
          height: 44,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
                color: JoynColors.border.withValues(alpha: 0.85),
                width: 1.2),
            boxShadow: _Premium.fieldShadow,
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  gradient: _Premium.softGradient(JoynColors.primary),
                  borderRadius: BorderRadius.circular(7),
                ),
                child: Icon(icon, size: 11, color: JoynColors.primary),
              ),
              const SizedBox(width: 7),
              Expanded(
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: value,
                    isExpanded: true,
                    isDense: true,
                    itemHeight: null,
                    icon: const Icon(Icons.keyboard_arrow_down_rounded,
                        color: JoynColors.primary, size: 18),
                    style: JoynTypography.bodyLarge.copyWith(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: Colors.black87),
                    borderRadius: BorderRadius.circular(12),
                    onChanged: onChanged,
                    selectedItemBuilder: (context) => _units
                        .map((u) => Align(
                      alignment: Alignment.centerLeft,
                      child: Text(u,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          softWrap: false,
                          style: JoynTypography.bodyLarge.copyWith(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: Colors.black87)),
                    ))
                        .toList(),
                    items: _units
                        .map((u) => DropdownMenuItem(
                      value: u,
                      child: Text(u,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          softWrap: false),
                    ))
                        .toList(),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ============ SECONDARY UNIT ============
  Widget _buildSecondaryUnitSection() {
    final isEnabled = !_primaryUnitOnly;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 240),
      curve: Curves.easeOutCubic,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            _AccentColors.togglePurple
                .withValues(alpha: isEnabled ? 0.08 : 0.04),
            _AccentColors.togglePurple
                .withValues(alpha: isEnabled ? 0.03 : 0.015),
          ],
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
            color: _AccentColors.togglePurple
                .withValues(alpha: isEnabled ? 0.22 : 0.10),
            width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(5),
                decoration: BoxDecoration(
                  gradient:
                  _Premium.softGradient(_AccentColors.togglePurple),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.layers_outlined,
                    size: 12, color: _AccentColors.togglePurple),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Secondary Unit',
                        style: JoynTypography.bodyMedium.copyWith(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w800,
                            color: Colors.black87)),
                    Text(
                      isEnabled
                          ? 'Track item in a second unit too'
                          : 'Only primary unit will be used',
                      style: JoynTypography.caption.copyWith(
                          fontSize: 10.5,
                          color: JoynColors.secondaryText),
                    ),
                  ],
                ),
              ),
              Transform.scale(
                scale: 0.72,
                child: Switch.adaptive(
                  value: isEnabled,
                  onChanged: (v) => setState(() => _primaryUnitOnly = !v),
                  activeTrackColor: _AccentColors.togglePurple,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
            ],
          ),
          _AnimatedReveal(
            show: isEnabled,
            child: Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: _buildCompactUnitDropdown(
                      label: 'Unit',
                      value: _selectedSecondaryUnit,
                      icon: Icons.straighten_rounded,
                      onChanged: (val) {
                        setState(() => _selectedSecondaryUnit =
                            val ?? _selectedSecondaryUnit);
                      },
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildCompactTextField(
                      label: 'Conversion',
                      hintText: '1 $_selectedUnit = ?',
                      controller: _secondaryConversionController,
                      keyboardType: const TextInputType.numberWithOptions(
                          decimal: true),
                      icon: Icons.swap_horiz_rounded,
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

  Widget _buildCategoryPickerField() {
    final hasValue = _selectedCategory != null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Item Category',
            style: JoynTypography.bodyMedium.copyWith(
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
                color: JoynColors.secondaryText,
                letterSpacing: 0.1)),
        const SizedBox(height: 6),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _Pressable(
                onTap: _openCategoryPicker,
                scale: 0.98,
                borderRadius: 16,
                child: Container(
                  height: 54,
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: hasValue
                          ? JoynColors.primary.withValues(alpha: 0.35)
                          : JoynColors.border.withValues(alpha: 0.85),
                      width: hasValue ? 1.4 : 1.2,
                    ),
                    boxShadow: hasValue
                        ? [
                      BoxShadow(
                          color: JoynColors.primary
                              .withValues(alpha: 0.10),
                          blurRadius: 12,
                          offset: const Offset(0, 4)),
                      ..._Premium.fieldShadow,
                    ]
                        : _Premium.fieldShadow,
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          gradient:
                          _Premium.softGradient(JoynColors.primary),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.category_outlined,
                            size: 15, color: JoynColors.primary),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          _selectedCategory ?? 'Select Category',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: JoynTypography.bodyLarge.copyWith(
                            fontSize: 14.5,
                            fontWeight: hasValue
                                ? FontWeight.w700
                                : FontWeight.w500,
                            color: hasValue
                                ? Colors.black87
                                : JoynColors.secondaryText
                                .withValues(alpha: 0.6),
                          ),
                        ),
                      ),
                      const Icon(Icons.keyboard_arrow_down_rounded,
                          color: JoynColors.primary, size: 20),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            _buildInlineAddButton(onTap: _createCategory),
          ],
        ),
      ],
    );
  }

  Widget _buildLocationField() {
    final hasValue = _selectedLocation != 'Select Location';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Location',
            style: JoynTypography.bodyMedium.copyWith(
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
                color: JoynColors.secondaryText,
                letterSpacing: 0.1)),
        const SizedBox(height: 6),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _Pressable(
                onTap: _openLocationPicker,
                scale: 0.98,
                borderRadius: 16,
                child: Container(
                  height: 54,
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: hasValue
                          ? JoynColors.primary.withValues(alpha: 0.35)
                          : JoynColors.border.withValues(alpha: 0.85),
                      width: hasValue ? 1.4 : 1.2,
                    ),
                    boxShadow: hasValue
                        ? [
                      BoxShadow(
                          color: JoynColors.primary
                              .withValues(alpha: 0.10),
                          blurRadius: 12,
                          offset: const Offset(0, 4)),
                      ..._Premium.fieldShadow,
                    ]
                        : _Premium.fieldShadow,
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          gradient:
                          _Premium.softGradient(JoynColors.primary),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.place_outlined,
                            size: 15, color: JoynColors.primary),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          _selectedLocation,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: JoynTypography.bodyLarge.copyWith(
                            fontSize: 14.5,
                            fontWeight: hasValue
                                ? FontWeight.w700
                                : FontWeight.w500,
                            color: hasValue
                                ? Colors.black87
                                : JoynColors.secondaryText
                                .withValues(alpha: 0.6),
                          ),
                        ),
                      ),
                      const Icon(Icons.keyboard_arrow_down_rounded,
                          color: JoynColors.primary, size: 20),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            _buildInlineAddButton(onTap: _createLocation),
          ],
        ),
      ],
    );
  }

  Widget _buildInlineAddButton({required VoidCallback onTap}) {
    return _Pressable(
      onTap: onTap,
      scale: 0.94,
      borderRadius: 16,
      child: Container(
        height: 54,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          gradient: _Premium.gradient(_AccentColors.addRed),
          borderRadius: BorderRadius.circular(16),
          boxShadow: _Premium.chipShadow(_AccentColors.addRed),
        ),
        child: Stack(
          children: [
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: _Premium.topHighlight,
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
            Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(3),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.22),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Icon(Icons.add_rounded,
                        color: Colors.white, size: 14),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Add',
                    style: JoynTypography.bodyMedium.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 13.5,
                        letterSpacing: 0.2),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // =====================================================================
  // PRICING CARD
  // =====================================================================
  Widget _buildPricingCard() {
    final isSelling = _pricingTab == PricingTab.selling;
    final priceController =
    isSelling ? _sellingPriceController : _buyingPriceController;
    final taxVisibility =
    isSelling ? _sellingTaxVisibility : _buyingTaxVisibility;
    final taxMode = isSelling ? _sellingTaxMode : _buyingTaxMode;
    final taxRate = isSelling ? _sellingTaxRate : _buyingTaxRate;
    final hasTax = taxVisibility == TaxVisibility.withTax;
    final enteredPrice = double.tryParse(priceController.text.trim()) ?? 0;
    final taxResult = hasTax && enteredPrice > 0
        ? _calculateTax(
        price: enteredPrice, mode: taxMode, ratePercent: taxRate.rate)
        : null;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: _Premium.surfaceGradient,
        borderRadius: BorderRadius.circular(22),
        border: _Premium.hairline(width: 1.0, alpha: 0.85),
        boxShadow: _Premium.cardShadow,
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: JoynColors.chipBackground,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                Expanded(
                  child: _buildPricingTab(
                    label: 'Buying',
                    icon: Icons.arrow_downward_rounded,
                    isSelected: !isSelling,
                    color: JoynColors.primary,
                    onTap: () =>
                        setState(() => _pricingTab = PricingTab.buying),
                  ),
                ),
                Expanded(
                  child: _buildPricingTab(
                    label: 'Selling',
                    icon: Icons.arrow_upward_rounded,
                    isSelected: isSelling,
                    color: JoynColors.primary,
                    onTap: () =>
                        setState(() => _pricingTab = PricingTab.selling),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          _FocusField(
            height: 56,
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    gradient: _Premium.softGradient(JoynColors.primary),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.currency_rupee_rounded,
                      size: 15, color: JoynColors.primary),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    controller: priceController,
                    keyboardType: const TextInputType.numberWithOptions(
                        decimal: true),
                    style: JoynTypography.bodyLarge.copyWith(
                        fontSize: 15.5, fontWeight: FontWeight.w700),
                    decoration: InputDecoration(
                      hintText: isSelling
                          ? 'Selling Price (Per Unit)'
                          : 'Buying Price (Per Unit)',
                      hintStyle: JoynTypography.bodyLarge.copyWith(
                          color: JoynColors.secondaryText
                              .withValues(alpha: 0.55),
                          fontSize: 14,
                          fontWeight: FontWeight.w500),
                      border: InputBorder.none,
                      isDense: true,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          _buildToggleRow(
            title: hasTax ? 'With Tax' : 'Without Tax',
            subtitle: hasTax
                ? 'Tax will be applied to this price'
                : 'No tax will be applied',
            value: hasTax,
            color: _AccentColors.toggleGreen,
            onChanged: (withTax) {
              setState(() {
                final newVisibility = withTax
                    ? TaxVisibility.withTax
                    : TaxVisibility.withoutTax;
                if (isSelling) {
                  _sellingTaxVisibility = newVisibility;
                } else {
                  _buyingTaxVisibility = newVisibility;
                }
              });
            },
          ),

          _AnimatedReveal(
            show: hasTax,
            child: Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Column(
                children: [
                  _buildToggleRow(
                    title: taxMode == TaxMode.inclusive
                        ? 'Inclusive of Tax'
                        : 'Exclusive of Tax',
                    subtitle: taxMode == TaxMode.inclusive
                        ? 'Entered price already includes tax'
                        : 'Tax will be added on top',
                    value: taxMode == TaxMode.inclusive,
                    color: _AccentColors.toggleGreen,
                    compact: true,
                    onChanged: (isInclusive) {
                      setState(() {
                        final newMode = isInclusive
                            ? TaxMode.inclusive
                            : TaxMode.exclusive;
                        if (isSelling) {
                          _sellingTaxMode = newMode;
                        } else {
                          _buyingTaxMode = newMode;
                        }
                      });
                    },
                  ),
                  const SizedBox(height: 14),

                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text('Tax Rate',
                        style: JoynTypography.caption.copyWith(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: JoynColors.secondaryText,
                            letterSpacing: 0.1)),
                  ),
                  const SizedBox(height: 6),

                  Container(
                    height: 52,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                          color: JoynColors.border.withValues(alpha: 0.85),
                          width: 1.2),
                      boxShadow: _Premium.fieldShadow,
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<TaxRateOption>(
                        value: taxRate,
                        isExpanded: true,
                        isDense: true,
                        itemHeight: null,
                        icon: const Icon(
                            Icons.keyboard_arrow_down_rounded,
                            color: JoynColors.primary,
                            size: 20),
                        style: JoynTypography.bodyLarge.copyWith(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: Colors.black87),
                        borderRadius: BorderRadius.circular(14),
                        onChanged: (val) {
                          if (val == null) return;
                          setState(() {
                            if (isSelling) {
                              _sellingTaxRate = val;
                            } else {
                              _buyingTaxRate = val;
                            }
                          });
                        },
                        selectedItemBuilder: (context) {
                          return kTaxRateOptions
                              .map((t) => Align(
                            alignment: Alignment.centerLeft,
                            child: Text(t.label,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                softWrap: false,
                                style: JoynTypography.bodyLarge
                                    .copyWith(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700)),
                          ))
                              .toList();
                        },
                        items: kTaxRateOptions.map((t) {
                          return DropdownMenuItem<TaxRateOption>(
                            value: t,
                            child: Row(
                              mainAxisAlignment:
                              MainAxisAlignment.spaceBetween,
                              children: [
                                Text(t.label,
                                    style: JoynTypography.bodyLarge
                                        .copyWith(fontSize: 14)),
                                Text('${t.rate}%',
                                    style: JoynTypography.caption.copyWith(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w700,
                                        color: JoynColors.secondaryText)),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ),

                  if (taxResult != null) ...[
                    const SizedBox(height: 14),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 14),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            JoynColors.primary.withValues(alpha: 0.06),
                            JoynColors.primary.withValues(alpha: 0.02),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                            color: JoynColors.primary
                                .withValues(alpha: 0.12),
                            width: 1),
                      ),
                      child: Column(
                        children: [
                          _buildTaxRow('Base Price', taxResult.base),
                          const SizedBox(height: 8),
                          _buildTaxRow(
                              '${taxMode == TaxMode.inclusive ? 'Tax Included' : 'Tax Added'} (${taxRate.rate}%)',
                              taxResult.taxAmount),
                          const SizedBox(height: 10),
                          Container(
                              height: 1,
                              color: JoynColors.primary
                                  .withValues(alpha: 0.15)),
                          const SizedBox(height: 10),
                          _buildTaxRow('Final Price', taxResult.finalPrice,
                              emphasize: true),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildToggleRow({
    required String title,
    required String subtitle,
    required bool value,
    required Color color,
    required ValueChanged<bool> onChanged,
    bool compact = false,
  }) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
      padding:
      EdgeInsets.symmetric(horizontal: 12, vertical: compact ? 8 : 10),
      decoration: BoxDecoration(
        gradient: value ? _Premium.softGradient(color) : null,
        color: value ? null : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: value
              ? color.withValues(alpha: 0.35)
              : JoynColors.border.withValues(alpha: 0.6),
          width: value ? 1.3 : 1.1,
        ),
        boxShadow: value
            ? [
          BoxShadow(
              color: color.withValues(alpha: 0.08),
              blurRadius: 10,
              offset: const Offset(0, 3)),
        ]
            : null,
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AnimatedDefaultTextStyle(
                  duration: const Duration(milliseconds: 200),
                  style: JoynTypography.bodyMedium.copyWith(
                      fontSize: compact ? 12.5 : 13,
                      fontWeight: FontWeight.w700,
                      color: value ? color : Colors.black87),
                  child: Text(title),
                ),
                const SizedBox(height: 2),
                Text(subtitle,
                    style: JoynTypography.caption.copyWith(
                        fontSize: 11,
                        color: JoynColors.secondaryText.withValues(
                            alpha: value ? 0.85 : 0.65))),
              ],
            ),
          ),
          Transform.scale(
            scale: 0.72,
            child: Switch.adaptive(
              value: value,
              onChanged: onChanged,
              activeTrackColor: color,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTaxRow(String label, double value, {bool emphasize = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: JoynTypography.bodyMedium.copyWith(
                fontSize: emphasize ? 13.5 : 12.5,
                fontWeight: emphasize ? FontWeight.w800 : FontWeight.w500,
                color:
                emphasize ? JoynColors.primary : JoynColors.secondaryText)),
        Text('₹${value.toStringAsFixed(2)}',
            style: JoynTypography.bodyMedium.copyWith(
                fontSize: emphasize ? 15.5 : 12.5,
                fontWeight: emphasize ? FontWeight.w900 : FontWeight.w600,
                color: emphasize ? _AccentColors.addRed : JoynColors.primary)),
      ],
    );
  }

  Widget _buildPricingTab({
    required String label,
    required IconData icon,
    required bool isSelected,
    required Color color,
    required VoidCallback onTap,
  }) {
    return _Pressable(
      onTap: onTap,
      scale: 0.96,
      borderRadius: 13,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
        height: 46,
        decoration: BoxDecoration(
          gradient: isSelected ? _Premium.gradient(color) : null,
          color: isSelected ? null : Colors.transparent,
          borderRadius: BorderRadius.circular(13),
          boxShadow: isSelected ? _Premium.chipShadow(color) : null,
        ),
        child: Stack(
          children: [
            if (isSelected)
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: _Premium.topHighlight,
                    borderRadius: BorderRadius.circular(13),
                  ),
                ),
              ),
            Center(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon,
                      size: 15,
                      color:
                      isSelected ? Colors.white : JoynColors.secondaryText),
                  const SizedBox(width: 6),
                  Text(label,
                      style: JoynTypography.bodyMedium.copyWith(
                          fontSize: 14,
                          fontWeight:
                          isSelected ? FontWeight.w800 : FontWeight.w600,
                          color: isSelected
                              ? Colors.white
                              : JoynColors.secondaryText)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // =====================================================================
  // BARCODE CARD
  // =====================================================================
  Widget _buildBarcodeCard() {
    final isQr = _barcodeTab == BarcodeTab.qrCode;
    final controller = isQr ? _qrValueController : _barcodeController;
    final isDifferentMode = _barcodeQtyMode == BarcodeQtyMode.different;
    final qty = int.tryParse(_qtyController.text.trim()) ?? 0;

    if (isDifferentMode) {
      _ensureGeneratedCodesLength(qty);
    }

    final hasValue = controller.text.trim().isNotEmpty;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: _Premium.surfaceGradient,
        borderRadius: BorderRadius.circular(22),
        border: _Premium.hairline(width: 1.0, alpha: 0.85),
        boxShadow: _Premium.cardShadow,
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _buildOutlinedTab(
                  label: 'Barcode',
                  icon: Icons.view_week_rounded,
                  isSelected: !isQr,
                  onTap: () =>
                      setState(() => _barcodeTab = BarcodeTab.barcode),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildOutlinedTab(
                  label: 'QR Code',
                  icon: Icons.qr_code_rounded,
                  isSelected: isQr,
                  onTap: () =>
                      setState(() => _barcodeTab = BarcodeTab.qrCode),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          _buildToggleRow(
            title: isDifferentMode
                ? 'Different Barcode for each Qty'
                : 'Same Barcode for all Qty',
            subtitle: isDifferentMode
                ? 'A unique code will be generated per unit'
                : 'One code will be used for the whole quantity',
            value: isDifferentMode,
            color: _AccentColors.toggleBlue,
            onChanged: (isDifferent) {
              setState(() => _barcodeQtyMode = isDifferent
                  ? BarcodeQtyMode.different
                  : BarcodeQtyMode.same);
            },
          ),
          const SizedBox(height: 14),
          Container(
              height: 1,
              color: JoynColors.border.withValues(alpha: 0.6)),
          const SizedBox(height: 14),

          AnimatedSwitcher(
            duration: const Duration(milliseconds: 340),
            switchInCurve: Curves.easeOutCubic,
            switchOutCurve: Curves.easeIn,
            layoutBuilder: (currentChild, previousChildren) {
              return Stack(
                alignment: Alignment.topCenter,
                children: [
                  ...previousChildren,
                  if (currentChild != null) currentChild,
                ],
              );
            },
            transitionBuilder: (child, animation) {
              return FadeTransition(
                opacity: animation,
                child: SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0, 0.04),
                    end: Offset.zero,
                  ).animate(CurvedAnimation(
                    parent: animation,
                    curve: Curves.easeOutCubic,
                  )),
                  child: child,
                ),
              );
            },
            child: isDifferentMode
                ? KeyedSubtree(
              key: const ValueKey('different'),
              child: _buildQtyCodeCarousel(isQr, qty),
            )
                : KeyedSubtree(
              key: const ValueKey('same'),
              child: _buildSameCodeContent(
                  isQr, controller, hasValue),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSameCodeContent(
      bool isQr, TextEditingController controller, bool hasValue) {
    return Column(
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: Text(
              isQr ? 'QR Code Value' : 'Barcode',
              style: JoynTypography.caption.copyWith(
                  fontSize: 12,
                  color: JoynColors.secondaryText,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.1)),
        ),
        const SizedBox(height: 6),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _FocusField(
                height: 52,
                borderRadius: 14,
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(5),
                      decoration: BoxDecoration(
                        gradient:
                        _Premium.softGradient(JoynColors.primary),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(Icons.qr_code_rounded,
                          size: 14, color: JoynColors.primary),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: controller,
                        style: JoynTypography.bodyLarge.copyWith(
                            fontSize: 14.5, fontWeight: FontWeight.w700),
                        onChanged: (_) => setState(() {}),
                        decoration: InputDecoration(
                          hintText: isQr ? 'QR Code Value' : 'Barcode',
                          hintStyle: JoynTypography.bodyLarge.copyWith(
                              color: JoynColors.secondaryText
                                  .withValues(alpha: 0.55),
                              fontSize: 14,
                              fontWeight: FontWeight.w500),
                          border: InputBorder.none,
                          isDense: true,
                        ),
                      ),
                    ),
                    if (hasValue)
                      _Pressable(
                        onTap: () => setState(() => controller.clear()),
                        scale: 0.88,
                        borderRadius: 20,
                        child: Container(
                          width: 20,
                          height: 20,
                          decoration: const BoxDecoration(
                              color: JoynColors.secondaryText,
                              shape: BoxShape.circle),
                          child: const Icon(Icons.close_rounded,
                              size: 12, color: Colors.white),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 8),
            _Pressable(
              onTap: _openScanner,
              scale: 0.92,
              borderRadius: 14,
              child: Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  gradient: _Premium.gradient(JoynColors.primary),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: _Premium.chipShadow(JoynColors.primary),
                ),
                child: const Icon(Icons.qr_code_scanner_rounded,
                    color: Colors.white, size: 22),
              ),
            ),
            const SizedBox(width: 8),
            _Pressable(
              onTap: _regenerateCode,
              scale: 0.92,
              borderRadius: 14,
              child: Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                      color: JoynColors.primary.withValues(alpha: 0.5),
                      width: 1.4),
                  boxShadow: _Premium.fieldShadow,
                ),
                child: const Icon(Icons.refresh_rounded,
                    color: JoynColors.primary, size: 22),
              ),
            ),
          ],
        ),
        if (hasValue) ...[
          const SizedBox(height: 18),
          Container(
              height: 1, color: JoynColors.border.withValues(alpha: 0.6)),
          const SizedBox(height: 16),
          Center(
            child: Container(
              width: double.infinity,
              padding:
              const EdgeInsets.symmetric(vertical: 22, horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                    color: JoynColors.border.withValues(alpha: 0.8),
                    width: 1.2),
                boxShadow: _Premium.fieldShadow,
              ),
              child: isQr
                  ? QrImageView(
                  data: controller.text,
                  size: 170,
                  backgroundColor: Colors.white)
                  : Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  BarcodeWidget(
                    barcode: Barcode.code128(),
                    data: controller.text,
                    width: double.infinity,
                    height: 90,
                    drawText: false,
                    color: JoynColors.primary,
                  ),
                  const SizedBox(height: 10),
                  Text(controller.text,
                      style: JoynTypography.bodyMedium.copyWith(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.4)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _Pressable(
                  onTap: () => _copyToClipboard(controller.text.trim(),
                      isQr ? 'QR value' : 'Barcode'),
                  scale: 0.96,
                  borderRadius: 14,
                  child: Container(
                    height: 52,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                          color: JoynColors.border.withValues(alpha: 0.85),
                          width: 1.3),
                      boxShadow: _Premium.fieldShadow,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.copy_rounded,
                            size: 15, color: JoynColors.primary),
                        const SizedBox(width: 7),
                        Text('Copy',
                            style: JoynTypography.bodyMedium.copyWith(
                                fontWeight: FontWeight.w800,
                                color: JoynColors.primary,
                                fontSize: 13.5)),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _GradientButton(
                  onPressed: () {},
                  icon: Icons.print_rounded,
                  label: 'Print Label',
                  color: JoynColors.primary,
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildQtyCodeCarousel(bool isQr, int qty) {
    if (qty <= 0) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 30, horizontal: 16),
        decoration: BoxDecoration(
          gradient: _Premium.softGradient(JoynColors.primary),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
              color: JoynColors.primary.withValues(alpha: 0.12), width: 1),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                gradient: _Premium.softGradient(JoynColors.primary),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.info_outline_rounded,
                  size: 20, color: JoynColors.primary),
            ),
            const SizedBox(height: 10),
            Text('Enter a Qty above to generate a code for each unit',
                style: JoynTypography.subtitle.copyWith(fontSize: 13),
                textAlign: TextAlign.center),
          ],
        ),
      );
    }

    final total = _generatedCodes.length;
    final safePage = _currentCodePage.clamp(0, total - 1);
    final currentCode = _generatedCodes[safePage];

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              padding:
              const EdgeInsets.symmetric(horizontal: 11, vertical: 5.5),
              decoration: BoxDecoration(
                gradient: _Premium.softGradient(JoynColors.primary),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                    color: JoynColors.primary.withValues(alpha: 0.20),
                    width: 1),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.tag_rounded,
                      size: 12, color: JoynColors.primary),
                  const SizedBox(width: 5),
                  Text('Serial No. ${safePage + 1} of $total',
                      style: JoynTypography.bodyMedium.copyWith(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w800,
                          color: JoynColors.primary)),
                ],
              ),
            ),
            _Pressable(
              onTap: _regenerateAllCodes,
              scale: 0.92,
              borderRadius: 10,
              child: Container(
                padding:
                const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                      color: JoynColors.primary.withValues(alpha: 0.3),
                      width: 1.1),
                  boxShadow: _Premium.hairlineShadow,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.refresh_rounded,
                        size: 13, color: JoynColors.primary),
                    const SizedBox(width: 4),
                    Text('Regenerate All',
                        style: JoynTypography.caption.copyWith(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: JoynColors.primary)),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text('Swipe to see each unit\'s code',
            style: JoynTypography.caption.copyWith(
                fontSize: 11, color: JoynColors.secondaryText)),
        const SizedBox(height: 10),
        SizedBox(
          height: isQr ? 270 : 200,
          child: PageView.builder(
            controller: _codePageController,
            itemCount: total,
            onPageChanged: (index) {
              HapticFeedback.selectionClick();
              setState(() => _currentCodePage = index);
            },
            itemBuilder: (context, index) {
              final code = _generatedCodes[index];
              final serialNumber = index + 1;
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Stack(
                  children: [
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                          vertical: 20, horizontal: 16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                            color:
                            JoynColors.border.withValues(alpha: 0.8),
                            width: 1.2),
                        boxShadow: _Premium.fieldShadow,
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 11, vertical: 4.5),
                            decoration: BoxDecoration(
                              gradient: _Premium.softGradient(
                                  JoynColors.primary),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                  color: JoynColors.primary
                                      .withValues(alpha: 0.18),
                                  width: 1),
                            ),
                            child: Text('Serial No. $serialNumber',
                                style: JoynTypography.caption.copyWith(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w800,
                                    color: JoynColors.primary,
                                    letterSpacing: 0.3)),
                          ),
                          const SizedBox(height: 12),
                          isQr
                              ? QrImageView(
                              data: code,
                              size: 150,
                              backgroundColor: Colors.white)
                              : Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              BarcodeWidget(
                                barcode: Barcode.code128(),
                                data: code,
                                width: double.infinity,
                                height: 80,
                                drawText: false,
                                color: JoynColors.primary,
                              ),
                              const SizedBox(height: 8),
                              Text(code,
                                  style: JoynTypography.bodyMedium
                                      .copyWith(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: 1.4)),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Positioned(
                      top: 8,
                      right: 8,
                      child: _Pressable(
                        onTap: () => _regenerateCodeAt(index),
                        scale: 0.85,
                        borderRadius: 20,
                        child: Container(
                          padding: const EdgeInsets.all(7),
                          decoration: BoxDecoration(
                            gradient: _Premium.gradient(Colors.black87),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                  color:
                                  Colors.black.withValues(alpha: 0.25),
                                  blurRadius: 6,
                                  offset: const Offset(0, 2)),
                            ],
                          ),
                          child: const Icon(Icons.refresh_rounded,
                              size: 14, color: Colors.white),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 12),
        if (total > 1)
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 5,
            runSpacing: 5,
            children: List.generate(
              min(total, 30),
                  (i) => AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: i == safePage ? 18 : 6,
                height: 6,
                decoration: BoxDecoration(
                  gradient: i == safePage
                      ? _Premium.gradient(JoynColors.primary)
                      : null,
                  color: i == safePage ? null : JoynColors.border,
                  borderRadius: BorderRadius.circular(3),
                  boxShadow: i == safePage
                      ? [
                    BoxShadow(
                        color: JoynColors.primary
                            .withValues(alpha: 0.35),
                        blurRadius: 6,
                        offset: const Offset(0, 2)),
                  ]
                      : null,
                ),
              ),
            ),
          ),
        const SizedBox(height: 18),
        Row(
          children: [
            Expanded(
              child: _Pressable(
                onTap: () => _copyToClipboard(
                    currentCode, 'Serial No. ${safePage + 1} code'),
                scale: 0.96,
                borderRadius: 14,
                child: Container(
                  height: 52,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                        color: JoynColors.border.withValues(alpha: 0.85),
                        width: 1.3),
                    boxShadow: _Premium.fieldShadow,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.copy_rounded,
                          size: 15, color: JoynColors.primary),
                      const SizedBox(width: 7),
                      Text('Copy',
                          style: JoynTypography.bodyMedium.copyWith(
                              fontWeight: FontWeight.w800,
                              color: JoynColors.primary,
                              fontSize: 13.5)),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _GradientButton(
                onPressed: () {},
                icon: Icons.print_rounded,
                label: 'Print All ($total)',
                color: JoynColors.primary,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildOutlinedTab({
    required String label,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return _Pressable(
      onTap: onTap,
      scale: 0.96,
      borderRadius: 14,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
        height: 48,
        decoration: BoxDecoration(
          gradient: isSelected ? _Premium.gradient(JoynColors.primary) : null,
          color: isSelected ? null : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
              color: isSelected
                  ? Colors.transparent
                  : JoynColors.border.withValues(alpha: 0.85),
              width: 1.4),
          boxShadow: isSelected
              ? _Premium.chipShadow(JoynColors.primary)
              : _Premium.fieldShadow,
        ),
        child: Stack(
          children: [
            if (isSelected)
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: _Premium.topHighlight,
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            Center(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon,
                      size: 15,
                      color: isSelected
                          ? Colors.white
                          : JoynColors.secondaryText),
                  const SizedBox(width: 6),
                  Text(label,
                      style: JoynTypography.bodyMedium.copyWith(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: isSelected
                              ? Colors.white
                              : JoynColors.secondaryText)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // =====================================================================
  // PHOTO PICKER
  // =====================================================================
  Widget _buildPhotoPicker() {
    return Column(
      children: [
        Center(
          child: _FloatingAvatar(
            child: _Pressable(
              onTap: _openPhotoSourceSheet,
              scale: 0.96,
              borderRadius: 20,
              child: Container(
                height: _standardPhotoSize,
                width: _standardPhotoSize,
                decoration: BoxDecoration(
                  gradient: _photoPath == null
                      ? _Premium.softGradient(JoynColors.primary)
                      : null,
                  color: _photoPath != null ? Colors.white : null,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: _photoPath != null
                        ? Colors.transparent
                        : JoynColors.primary.withValues(alpha: 0.20),
                    width: 1.5,
                  ),
                  boxShadow: _photoPath != null
                      ? _Premium.cardShadow
                      : [
                    BoxShadow(
                        color: JoynColors.primary
                            .withValues(alpha: 0.10),
                        blurRadius: 18,
                        offset: const Offset(0, 6)),
                  ],
                ),
                child: _photoPath != null
                    ? Stack(
                  fit: StackFit.expand,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(19),
                      child: Image.file(File(_photoPath!),
                          fit: BoxFit.cover),
                    ),
                    Positioned.fill(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(19),
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              Colors.black.withValues(alpha: 0.42),
                            ],
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      top: 8,
                      right: 8,
                      child: _Pressable(
                        onTap: () =>
                            setState(() => _photoPath = null),
                        scale: 0.85,
                        borderRadius: 20,
                        child: Container(
                          padding: const EdgeInsets.all(5),
                          decoration: const BoxDecoration(
                              color: Colors.black54,
                              shape: BoxShape.circle),
                          child: const Icon(Icons.close_rounded,
                              size: 14, color: Colors.white),
                        ),
                      ),
                    ),
                    Positioned(
                      left: 10,
                      bottom: 8,
                      right: 10,
                      child: Row(
                        children: const [
                          Icon(Icons.crop_rounded,
                              size: 12, color: Colors.white),
                          SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              'Tap to change / crop',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w700),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                )
                    : Stack(
                  children: [
                    // Corner brackets
                    Positioned.fill(
                      child: Padding(
                        padding: const EdgeInsets.all(8),
                        child: _CornerAccents(
                          color: JoynColors.primary
                              .withValues(alpha: 0.35),
                          size: 16,
                          thickness: 2.2,
                          radius: 8,
                        ),
                      ),
                    ),
                    Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 66,
                            height: 66,
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                _PulsingDot(
                                    color: JoynColors.primary
                                        .withValues(alpha: 0.35),
                                    size: 28),
                                Container(
                                  padding:
                                  const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    gradient:
                                    _Premium.softGradient(
                                        JoynColors.primary),
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                        color: JoynColors.primary
                                            .withValues(alpha: 0.18),
                                        width: 1),
                                  ),
                                  child: const Icon(
                                      Icons.add_a_photo_outlined,
                                      color: JoynColors.primary,
                                      size: 22),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 14),
                          Text('Add Item Photo',
                              style: JoynTypography.bodyMedium
                                  .copyWith(
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w800,
                                  color: JoynColors.primary)),
                          const SizedBox(height: 3),
                          Text('Camera or Gallery',
                              style: JoynTypography.caption.copyWith(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: JoynColors.secondaryText)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 10),
        Text(
          'Standard size — square photo (1:1), crop after selecting',
          style: JoynTypography.caption.copyWith(
              fontSize: 11, color: JoynColors.secondaryText),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  // =====================================================================
  // STANDARD FORM FIELD
  // =====================================================================
  Widget _buildFormField({
    required String label,
    required String hintText,
    required TextEditingController controller,
    TextInputType keyboardType = TextInputType.text,
    IconData? icon,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: JoynTypography.bodyMedium.copyWith(
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
                color: JoynColors.secondaryText,
                letterSpacing: 0.1)),
        const SizedBox(height: 6),
        _FocusField(
          child: Row(
            children: [
              if (icon != null) ...[
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    gradient: _Premium.softGradient(JoynColors.primary),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, size: 15, color: JoynColors.primary),
                ),
                const SizedBox(width: 10),
              ],
              Expanded(
                child: TextField(
                  controller: controller,
                  keyboardType: keyboardType,
                  style: JoynTypography.bodyLarge.copyWith(
                      fontSize: 14.5, fontWeight: FontWeight.w600),
                  decoration: InputDecoration(
                    hintText: hintText,
                    hintStyle: JoynTypography.bodyLarge.copyWith(
                        color:
                        JoynColors.secondaryText.withValues(alpha: 0.5),
                        fontSize: 14,
                        fontWeight: FontWeight.w500),
                    border: InputBorder.none,
                    isDense: true,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}