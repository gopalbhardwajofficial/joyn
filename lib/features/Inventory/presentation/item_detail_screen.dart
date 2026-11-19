// lib/features/Inventory/presentation/item_detail_screen.dart
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/joyn_colors.dart';
import '../../../core/theme/joyn_typography.dart';
import '../../orders/models/sales_models.dart';
import '../../orders/data/sales_repository.dart';
import 'add_new_item_screen.dart';

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

  static List<BoxShadow> softShadow = [
    BoxShadow(color: Colors.black.withValues(alpha: 0.025), blurRadius: 3, offset: const Offset(0, 1)),
    BoxShadow(color: Colors.black.withValues(alpha: 0.035), blurRadius: 12, offset: const Offset(0, 4)),
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
    final delay = Duration(milliseconds: (widget.index * 55).clamp(0, 500));
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
  const _FloatingAvatar({required this.child});
  final Widget child;

  @override
  State<_FloatingAvatar> createState() => _FloatingAvatarState();
}

class _FloatingAvatarState extends State<_FloatingAvatar>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2400),
  )..repeat(reverse: true);

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
class ItemDetailScreen extends StatefulWidget {
  const ItemDetailScreen({super.key, required this.item});

  final InventoryItemModel item;

  @override
  State<ItemDetailScreen> createState() => _ItemDetailScreenState();
}

class _ItemDetailScreenState extends State<ItemDetailScreen> {
  final SalesRepository _salesRepository = SalesRepository();
  late InventoryItemModel _item;

  @override
  void initState() {
    super.initState();
    _item = widget.item;
  }

  Future<void> _editItem() async {
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => AddNewItemScreen(existingItem: _item),
      ),
    );

    if (result == true && mounted) {
      final items = await _salesRepository.getItems();
      for (final item in items) {
        if (item.id == _item.id) {
          setState(() => _item = item);
          break;
        }
      }
    }
  }

  Future<void> _deleteItem() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        title: Text('Delete Item?',
            style: JoynTypography.titleMedium
                .copyWith(fontSize: 17, fontWeight: FontWeight.w800)),
        content: Text(
          'Remove "${_item.name}" from your inventory?',
          style: JoynTypography.bodyMedium
              .copyWith(fontSize: 13.5, color: JoynColors.secondaryText),
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
      await _salesRepository.deleteItem(_item.id);
      if (mounted) Navigator.of(context).pop();
    }
  }

  // Stock health color
  Color get _stockColor {
    if (_item.stock <= 0) return JoynColors.error;
    if (_item.stock <= 5) return const Color(0xFFF59E0B);
    return JoynColors.success;
  }

  String get _stockLabel {
    if (_item.stock <= 0) return 'Out of Stock';
    if (_item.stock <= 5) return 'Low Stock';
    return 'In Stock';
  }

  IconData get _stockIcon {
    if (_item.stock <= 0) return Icons.error_outline_rounded;
    if (_item.stock <= 5) return Icons.warning_amber_rounded;
    return Icons.check_circle_outline_rounded;
  }

  double get _profitMargin =>
      _item.sellingPrice - _item.purchasePrice;

  double get _marginPercent {
    if (_item.purchasePrice <= 0) return 0;
    return (_profitMargin / _item.purchasePrice) * 100;
  }

  // =====================================================================
  // BUILD
  // =====================================================================
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
          'Item Details',
          style: JoynTypography.titleMedium.copyWith(
              fontSize: 18, fontWeight: FontWeight.w800, letterSpacing: -0.3),
        ),
        actions: [
          _Pressable(
            onTap: _editItem,
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
            onTap: _deleteItem,
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
              child: const Icon(Icons.delete_outline_rounded,
                  size: 17, color: JoynColors.error),
            ),
          ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(
              parent: BouncingScrollPhysics()),
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
          children: [
            // HERO HEADER
            _StaggeredItem(index: 0, child: _buildHeroHeader()),
            const SizedBox(height: 18),

            // QUICK STATS
            _StaggeredItem(index: 1, child: _buildQuickStats()),

            const SizedBox(height: 24),

            // STOCK INFO
            _StaggeredItem(
              index: 2,
              child: _buildDetailCard(
                title: 'Stock Information',
                icon: Icons.inventory_2_outlined,
                accentColor: _stockColor,
                children: [
                  _buildDetailRow('Quantity', '${_item.qty} ${_item.unit}'),
                  _buildDetailRow('Stock', '${_item.stock} ${_item.unit}'),
                  _buildDetailRow('Location',
                      _item.location.isEmpty ? 'Not Set' : _item.location),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // PRICING
            _StaggeredItem(
              index: 3,
              child: _buildDetailCard(
                title: 'Pricing',
                icon: Icons.currency_rupee_rounded,
                accentColor: JoynColors.primary,
                children: [
                  _buildDetailRow(
                      'Purchase Price', '₹${_item.purchasePrice.toStringAsFixed(2)}'),
                  _buildDetailRow(
                      'Selling Price', '₹${_item.sellingPrice.toStringAsFixed(2)}'),
                  _buildDetailRow(
                    'Profit Margin',
                    '₹${_profitMargin.toStringAsFixed(2)} (${_marginPercent.toStringAsFixed(1)}%)',
                    valueColor: _profitMargin >= 0
                        ? JoynColors.success
                        : JoynColors.error,
                  ),
                  if (_item.taxRatePercent > 0) ...[
                    _buildDetailRow('Tax Rate', _item.taxRateLabel),
                    _buildDetailRow('Tax Percent', '${_item.taxRatePercent}%'),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 16),

            // ITEM DETAILS
            _StaggeredItem(
              index: 4,
              child: _buildDetailCard(
                title: 'Item Details',
                icon: Icons.info_outline_rounded,
                accentColor: const Color(0xFF7C3AED),
                children: [
                  _buildDetailRow('Item ID & Number', _item.displayItemCode),
                  _buildDetailRow(
                      'SKU', _item.barcode.isEmpty ? 'Not Set' : _item.barcode),
                  _buildDetailRow('HSN/SAC',
                      _item.hsnSac.isEmpty ? 'Not Set' : _item.hsnSac),
                  _buildDetailRow('Unit', _item.unit),
                  _buildDetailRow('Barcode Mode',
                      _item.barcodeMode == 'same' ? 'Same for all' : 'Separate'),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // BARCODE
            if (_item.barcode.isNotEmpty)
              _StaggeredItem(
                index: 5,
                child: _buildDetailCard(
                  title: 'Barcode',
                  icon: Icons.qr_code_rounded,
                  accentColor: const Color(0xFF2563EB),
                  children: [
                    const SizedBox(height: 6),
                    Center(
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                            vertical: 20, horizontal: 16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                              color: JoynColors.border.withValues(alpha: 0.8),
                              width: 1.2),
                          boxShadow: _Premium.softShadow,
                        ),
                        child: Column(
                          children: [
                            Text(
                              _item.barcode,
                              textAlign: TextAlign.center,
                              style: JoynTypography.titleMedium.copyWith(
                                fontSize: 20,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 3,
                                color: Colors.black87,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                  ],
                ),
              ),
          ],
        ),
      ),

      // FROSTED ACTION BAR
      bottomNavigationBar: _buildFrostedActionBar(),
    );
  }

  // =====================================================================
  // HERO HEADER — gradient card
  // =====================================================================
  Widget _buildHeroHeader() {
    return Container(
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
            padding: const EdgeInsets.fromLTRB(18, 20, 18, 20),
            child: Column(
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Floating photo/avatar
                    _FloatingAvatar(
                      child: Container(
                        width: 72,
                        height: 72,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white,
                          boxShadow: [
                            BoxShadow(
                                color: Colors.black.withValues(alpha: 0.20),
                                blurRadius: 20,
                                offset: const Offset(0, 6)),
                          ],
                        ),
                        padding: const EdgeInsets.all(3),
                        child: ClipOval(
                          child: _item.photoPath.isNotEmpty
                              ? Image.file(
                            File(_item.photoPath),
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) =>
                                _buildHeroFallbackAvatar(),
                          )
                              : _buildHeroFallbackAvatar(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _item.name,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: JoynTypography.titleMedium.copyWith(
                              fontSize: 19,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                              letterSpacing: -0.4,
                              height: 1.15,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 6,
                            runSpacing: 6,
                            children: [
                              _buildHeroPill(
                                  Icons.fingerprint_rounded, _item.displayItemCode),
                              if (_item.category.isNotEmpty)
                                _buildHeroPill(
                                    Icons.local_offer_outlined, _item.category),
                              if (_item.unit.isNotEmpty)
                                _buildHeroPill(
                                    Icons.straighten_rounded, _item.unit),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 18),

                // Stock status bar
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                        color: Colors.white.withValues(alpha: 0.18), width: 1),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.18),
                          borderRadius: BorderRadius.circular(9),
                        ),
                        child: Icon(_stockIcon, size: 15, color: Colors.white),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _stockLabel.toUpperCase(),
                              style: JoynTypography.caption.copyWith(
                                  fontSize: 9.5,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.white.withValues(alpha: 0.85),
                                  letterSpacing: 1.0),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${_item.stock} ${_item.unit} available',
                              style: JoynTypography.bodyMedium.copyWith(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white),
                            ),
                          ],
                        ),
                      ),
                      if (_item.stock <= 5)
                        _PulsingDot(color: Colors.white, size: 6),
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

  Widget _buildHeroFallbackAvatar() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            JoynColors.primary.withValues(alpha: 0.15),
            JoynColors.primary.withValues(alpha: 0.28),
          ],
        ),
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: Text(
        _item.name.isNotEmpty ? _item.name[0].toUpperCase() : '?',
        style: JoynTypography.titleMedium.copyWith(
          fontSize: 30,
          fontWeight: FontWeight.w900,
          color: JoynColors.primary,
        ),
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
                fontWeight: FontWeight.w800,
                color: Colors.white,
                height: 1.0),
          ),
        ],
      ),
    );
  }

  // =====================================================================
  // QUICK STATS ROW — 3 tiles
  // =====================================================================
  Widget _buildQuickStats() {
    return Row(
      children: [
        Expanded(
          child: _buildStatTile(
            label: 'PURCHASE',
            value: '₹${_item.purchasePrice.toStringAsFixed(0)}',
            icon: Icons.shopping_bag_outlined,
            color: const Color(0xFF7C3AED),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _buildStatTile(
            label: 'SELLING',
            value: '₹${_item.sellingPrice.toStringAsFixed(0)}',
            icon: Icons.currency_rupee_rounded,
            color: JoynColors.primary,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _buildStatTile(
            label: 'MARGIN',
            value: '₹${_profitMargin.toStringAsFixed(0)}',
            icon: _profitMargin >= 0
                ? Icons.trending_up_rounded
                : Icons.trending_down_rounded,
            color: _profitMargin >= 0
                ? JoynColors.success
                : JoynColors.error,
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
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: _Premium.surfaceGradient,
        borderRadius: BorderRadius.circular(16),
        border: _Premium.hairline(width: 1.0, alpha: 0.85),
        boxShadow: _Premium.softShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(5),
            decoration: BoxDecoration(
              gradient: _Premium.softGradient(color),
              borderRadius: BorderRadius.circular(8),
              border:
              Border.all(color: color.withValues(alpha: 0.15), width: 0.8),
            ),
            child: Icon(icon, size: 12, color: color),
          ),
          const SizedBox(height: 8),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              maxLines: 1,
              style: JoynTypography.bodyLarge.copyWith(
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                  color: Colors.black87,
                  letterSpacing: -0.3),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: JoynTypography.caption.copyWith(
                fontSize: 9,
                fontWeight: FontWeight.w800,
                color: JoynColors.secondaryText,
                letterSpacing: 0.6),
          ),
        ],
      ),
    );
  }

  // =====================================================================
  // DETAIL CARD
  // =====================================================================
  Widget _buildDetailCard({
    required String title,
    required IconData icon,
    required Color accentColor,
    required List<Widget> children,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: _Premium.surfaceGradient,
        borderRadius: BorderRadius.circular(20),
        border: _Premium.hairline(width: 1.0, alpha: 0.85),
        boxShadow: _Premium.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 3,
                height: 22,
                margin: const EdgeInsets.only(right: 10),
                decoration: BoxDecoration(
                  gradient: _Premium.gradient(accentColor),
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  gradient: _Premium.softGradient(accentColor),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                      color: accentColor.withValues(alpha: 0.12), width: 1),
                ),
                child: Icon(icon, size: 14, color: accentColor),
              ),
              const SizedBox(width: 10),
              Text(
                title,
                style: JoynTypography.bodyLarge.copyWith(
                  fontSize: 15.5,
                  fontWeight: FontWeight.w800,
                  color: Colors.black87,
                  letterSpacing: -0.2,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            height: 1,
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [
                accentColor.withValues(alpha: 0.30),
                accentColor.withValues(alpha: 0.05),
                accentColor.withValues(alpha: 0.0),
              ]),
            ),
          ),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: JoynTypography.bodyMedium.copyWith(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: JoynColors.secondaryText,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: JoynTypography.bodyMedium.copyWith(
                fontSize: 13.5,
                fontWeight: FontWeight.w800,
                color: valueColor ?? Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // =====================================================================
  // FROSTED ACTION BAR
  // =====================================================================
  Widget _buildFrostedActionBar() {
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
                  color: JoynColors.border.withValues(alpha: 0.55), width: 1),
            ),
          ),
          child: SafeArea(
            top: false,
            child: Row(
              children: [
                Expanded(
                  flex: 3,
                  child: _buildBottomButton(
                    label: 'Delete',
                    icon: Icons.delete_outline_rounded,
                    color: JoynColors.error,
                    isOutline: true,
                    onTap: _deleteItem,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 4,
                  child: _buildBottomButton(
                    label: 'Edit Item',
                    icon: Icons.edit_outlined,
                    color: JoynColors.primary,
                    onTap: _editItem,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBottomButton({
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
    bool isOutline = false,
  }) {
    if (isOutline) {
      return _Pressable(
        onTap: onTap,
        scale: 0.96,
        borderRadius: 16,
        child: Container(
          height: 54,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
                color: color.withValues(alpha: 0.5), width: 1.3),
            boxShadow: _Premium.softShadow,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 7),
              Text(
                label,
                style: JoynTypography.bodyMedium.copyWith(
                    fontWeight: FontWeight.w800,
                    color: color,
                    fontSize: 13.5),
              ),
            ],
          ),
        ),
      );
    }

    return _Pressable(
      onTap: onTap,
      scale: 0.96,
      borderRadius: 16,
      child: Container(
        height: 54,
        decoration: BoxDecoration(
          gradient: _Premium.gradient(color),
          borderRadius: BorderRadius.circular(16),
          boxShadow: _Premium.chipShadow(color),
        ),
        child: Stack(
          children: [
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: _Premium.shineSweep,
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
            Positioned(
              left: 0,
              right: 0,
              top: 0,
              height: 22,
              child: Container(
                decoration: BoxDecoration(
                  gradient: _Premium.topHighlight,
                  borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(16)),
                ),
              ),
            ),
            Center(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(5),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.24),
                      borderRadius: BorderRadius.circular(9),
                      border: Border.all(
                          color: Colors.white.withValues(alpha: 0.18),
                          width: 0.6),
                    ),
                    child: Icon(icon, color: Colors.white, size: 13),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    label,
                    style: JoynTypography.bodyMedium.copyWith(
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        fontSize: 14,
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
}