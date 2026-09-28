import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/joyn_colors.dart';
import '../../../core/theme/joyn_typography.dart';
import '../../orders/models/sales_models.dart';
import '../../orders/data/sales_repository.dart';

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
    final delay = Duration(milliseconds: (widget.index * 50).clamp(0, 600));
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
// ANIMATED REVEAL — smooth show/hide for filter fields
// =====================================================================
class _AnimatedReveal extends StatelessWidget {
  const _AnimatedReveal({
    required this.show,
    required this.child,
    this.duration = const Duration(milliseconds: 320),
  });

  final bool show;
  final Widget child;
  final Duration duration;

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
                begin: const Offset(0, 0.06),
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
// FOCUS-AWARE FIELD WRAPPER
// =====================================================================
class _FocusField extends StatefulWidget {
  const _FocusField({required this.child});
  final Widget child;

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
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          boxShadow: _focused
              ? [
            BoxShadow(
                color: JoynColors.primary.withValues(alpha: 0.14),
                blurRadius: 16,
                offset: const Offset(0, 5)),
          ]
              : null,
        ),
        child: widget.child,
      ),
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
// SHIMMER BOX
// =====================================================================
class _ShimmerBox extends StatefulWidget {
  const _ShimmerBox({
    required this.width,
    required this.height,
    this.borderRadius = 12,
  });
  final double width;
  final double height;
  final double borderRadius;

  @override
  State<_ShimmerBox> createState() => _ShimmerBoxState();
}

class _ShimmerBoxState extends State<_ShimmerBox>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  )..repeat();

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, _) {
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(widget.borderRadius),
            gradient: LinearGradient(
              begin: Alignment(-1 + 2 * _ctrl.value, 0),
              end: Alignment(1 + 2 * _ctrl.value, 0),
              colors: [
                JoynColors.chipBackground.withValues(alpha: 0.55),
                JoynColors.chipBackground,
                JoynColors.chipBackground.withValues(alpha: 0.55),
              ],
              stops: const [0.35, 0.5, 0.65],
            ),
          ),
        );
      },
    );
  }
}

// =====================================================================
// HERO STATS CARD
// =====================================================================
class _HeroStatsCard extends StatelessWidget {
  const _HeroStatsCard({
    required this.totalItems,
    required this.filteredItems,
    required this.stockValue,
    required this.lowStockCount,
  });

  final int totalItems;
  final int filteredItems;
  final double stockValue;
  final int lowStockCount;

  String _compact(double v) {
    if (v >= 10000000) return '₹${(v / 10000000).toStringAsFixed(1)}Cr';
    if (v >= 100000) return '₹${(v / 100000).toStringAsFixed(1)}L';
    if (v >= 1000) return '₹${(v / 1000).toStringAsFixed(1)}K';
    return '₹${v.toStringAsFixed(0)}';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 4, 20, 12),
      decoration: BoxDecoration(
        gradient: _Premium.deepGradient(JoynColors.primary),
        borderRadius: BorderRadius.circular(22),
        boxShadow: _Premium.floatingShadow(JoynColors.primary),
      ),
      child: Stack(
        children: [
          Positioned(
            top: -40,
            right: -30,
            child: Container(
              width: 160,
              height: 160,
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
            bottom: -50,
            left: -30,
            child: Container(
              width: 140,
              height: 140,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(colors: [
                  Colors.white.withValues(alpha: 0.10),
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
                borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
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
                          const Icon(Icons.insights_rounded,
                              size: 11, color: Colors.white),
                          const SizedBox(width: 5),
                          Text('INVENTORY',
                              style: JoynTypography.caption.copyWith(
                                  fontSize: 9.5,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.white,
                                  letterSpacing: 1.2)),
                        ],
                      ),
                    ),
                    const Spacer(),
                    if (lowStockCount > 0)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 9, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF59E0B).withValues(alpha: 0.28),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                              color: const Color(0xFFF59E0B)
                                  .withValues(alpha: 0.45),
                              width: 0.8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.warning_amber_rounded,
                                size: 11, color: Colors.white),
                            const SizedBox(width: 4),
                            Text('$lowStockCount low',
                                style: JoynTypography.caption.copyWith(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w900,
                                    color: Colors.white)),
                          ],
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _buildStat(
                        icon: Icons.inventory_2_rounded,
                        label: 'Showing',
                        value: '$filteredItems / $totalItems',
                      ),
                    ),
                    Container(
                        width: 1,
                        height: 42,
                        color: Colors.white.withValues(alpha: 0.18)),
                    Expanded(
                      child: _buildStat(
                        icon: Icons.currency_rupee_rounded,
                        label: 'Stock Value',
                        value: _compact(stockValue),
                        alignEnd: true,
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

  Widget _buildStat({
    required IconData icon,
    required String label,
    required String value,
    bool alignEnd = false,
  }) {
    return Column(
      crossAxisAlignment:
      alignEnd ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.16),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Icon(icon, size: 10, color: Colors.white),
            ),
            const SizedBox(width: 6),
            Text(label,
                style: JoynTypography.caption.copyWith(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                    color: Colors.white.withValues(alpha: 0.85),
                    letterSpacing: 0.2)),
          ],
        ),
        const SizedBox(height: 6),
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: alignEnd ? Alignment.centerRight : Alignment.centerLeft,
          child: Text(value,
              maxLines: 1,
              style: JoynTypography.titleMedium.copyWith(
                  fontSize: 19,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  letterSpacing: -0.4)),
        ),
      ],
    );
  }
}

// =====================================================================
// ACTIVE FILTER PILL
// =====================================================================
class _ActiveFilterPill extends StatelessWidget {
  const _ActiveFilterPill({required this.label, required this.onClear});

  final String label;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return _Pressable(
      onTap: onClear,
      scale: 0.95,
      borderRadius: 20,
      child: Container(
        padding: const EdgeInsets.fromLTRB(11, 6, 6, 6),
        decoration: BoxDecoration(
          gradient: _Premium.softGradient(JoynColors.primary),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: JoynColors.primary.withValues(alpha: 0.22), width: 1),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: JoynTypography.caption.copyWith(
                    fontSize: 11, fontWeight: FontWeight.w800, color: JoynColors.primary),
              ),
            ),
            const SizedBox(width: 5),
            Container(
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                color: JoynColors.primary.withValues(alpha: 0.16),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.close_rounded, size: 10, color: JoynColors.primary),
            ),
          ],
        ),
      ),
    );
  }
}

// =====================================================================
// FILTER OPTION
// =====================================================================
class _FilterOption {
  final String key;
  final String label;
  final IconData icon;
  const _FilterOption(this.key, this.label, this.icon);
}

// =====================================================================
// MAIN SCREEN
// =====================================================================
class ManageInventoryScreen extends StatefulWidget {
  const ManageInventoryScreen({super.key});

  @override
  State<ManageInventoryScreen> createState() => _ManageInventoryScreenState();
}

class _ManageInventoryScreenState extends State<ManageInventoryScreen> {
  final SalesRepository _salesRepository = SalesRepository();

  // Quick search — bound to the top search bar (always active, like Items List screen)
  final TextEditingController _nameCtrl = TextEditingController();
  bool _searchFocused = false;

  String? _selectedCategory;
  final TextEditingController _hsnCtrl = TextEditingController();
  final TextEditingController _locationCtrl = TextEditingController();
  final TextEditingController _skuCtrl = TextEditingController();
  final TextEditingController _unitCtrl = TextEditingController();
  final TextEditingController _priceMinCtrl = TextEditingController();
  final TextEditingController _priceMaxCtrl = TextEditingController();

  Set<String> _activeFilters = {};

  List<InventoryItemModel> _allItems = [];
  List<InventoryItemModel> _filteredItems = [];
  bool _isLoading = true;

  final List<_FilterOption> _filterOptions = const [
    _FilterOption('category', 'Category', Icons.category_outlined),
    _FilterOption('hsn', 'HSN / SAC', Icons.qr_code_rounded),
    _FilterOption('location', 'Location', Icons.place_outlined),
    _FilterOption('sku', 'SKU', Icons.inventory_2_outlined),
    _FilterOption('unit', 'Unit', Icons.straighten_rounded),
    _FilterOption('price', 'Price Range', Icons.currency_rupee_rounded),
  ];

  List<String> get _availableCategories {
    final categories = _allItems
        .map((item) => item.category)
        .where((c) => c.isNotEmpty)
        .toSet()
        .toList()
      ..sort();
    return categories;
  }

  int get _lowStockCount {
    return _allItems.where((item) => item.stock > 0 && item.stock <= 5).length;
  }

  bool get _hasActiveFilters =>
      (_activeFilters.contains('category') && _selectedCategory != null) ||
          (_activeFilters.contains('hsn') && _hsnCtrl.text.isNotEmpty) ||
          (_activeFilters.contains('location') && _locationCtrl.text.isNotEmpty) ||
          (_activeFilters.contains('sku') && _skuCtrl.text.isNotEmpty) ||
          (_activeFilters.contains('unit') && _unitCtrl.text.isNotEmpty) ||
          (_activeFilters.contains('price') &&
              (_priceMinCtrl.text.isNotEmpty || _priceMaxCtrl.text.isNotEmpty));

  /// Active filter pills (only show advanced filters with values; quick search excluded)
  List<MapEntry<String, String>> get _activeFilterPills {
    final list = <MapEntry<String, String>>[];
    if (_activeFilters.contains('category') && _selectedCategory != null) {
      list.add(MapEntry('category', 'Cat: $_selectedCategory'));
    }
    if (_activeFilters.contains('hsn') && _hsnCtrl.text.isNotEmpty) {
      list.add(MapEntry('hsn', 'HSN: ${_hsnCtrl.text}'));
    }
    if (_activeFilters.contains('location') && _locationCtrl.text.isNotEmpty) {
      list.add(MapEntry('location', 'Loc: ${_locationCtrl.text}'));
    }
    if (_activeFilters.contains('sku') && _skuCtrl.text.isNotEmpty) {
      list.add(MapEntry('sku', 'SKU: ${_skuCtrl.text}'));
    }
    if (_activeFilters.contains('unit') && _unitCtrl.text.isNotEmpty) {
      list.add(MapEntry('unit', 'Unit: ${_unitCtrl.text}'));
    }
    if (_activeFilters.contains('price') &&
        (_priceMinCtrl.text.isNotEmpty || _priceMaxCtrl.text.isNotEmpty)) {
      list.add(MapEntry('price',
          '₹${_priceMinCtrl.text.isEmpty ? '0' : _priceMinCtrl.text} - ${_priceMaxCtrl.text.isEmpty ? '∞' : _priceMaxCtrl.text}'));
    }
    return list;
  }

  @override
  void initState() {
    super.initState();
    _loadItems();
  }

  Future<void> _loadItems() async {
    try {
      final items = await _salesRepository.getItems();
      if (!mounted) return;
      setState(() {
        _allItems = items;
        _isLoading = false;
        _applyFilters();
      });
    } catch (e) {
      debugPrint('Error loading items: $e');
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  void _applyFilters() {
    var list = _allItems.where((item) {
      final nameQuery = _nameCtrl.text.trim().toLowerCase();
      final matchesName = nameQuery.isEmpty ||
          item.name.toLowerCase().contains(nameQuery) ||
          item.category.toLowerCase().contains(nameQuery) ||
          item.barcode.contains(nameQuery) ||
          item.hsnSac.toLowerCase().contains(nameQuery);

      final matchesCategory = !_activeFilters.contains('category') ||
          _selectedCategory == null ||
          item.category == _selectedCategory;

      final hsnQuery = _hsnCtrl.text.trim().toLowerCase();
      final matchesHsn = !_activeFilters.contains('hsn') ||
          hsnQuery.isEmpty ||
          item.hsnSac.toLowerCase().contains(hsnQuery);

      final locationQuery = _locationCtrl.text.trim().toLowerCase();
      final matchesLocation = !_activeFilters.contains('location') ||
          locationQuery.isEmpty ||
          item.location.toLowerCase().contains(locationQuery);

      final skuQuery = _skuCtrl.text.trim().toLowerCase();
      final matchesSku = !_activeFilters.contains('sku') ||
          skuQuery.isEmpty ||
          item.name.toLowerCase().contains(skuQuery);

      final unitQuery = _unitCtrl.text.trim().toLowerCase();
      final matchesUnit = !_activeFilters.contains('unit') ||
          unitQuery.isEmpty ||
          item.unit.toLowerCase().contains(unitQuery);

      final minPrice = double.tryParse(_priceMinCtrl.text.trim());
      final maxPrice = double.tryParse(_priceMaxCtrl.text.trim());
      bool matchesPrice = true;
      if (_activeFilters.contains('price')) {
        final sellPrice = item.sellingPrice;
        if (minPrice != null && sellPrice < minPrice) matchesPrice = false;
        if (maxPrice != null && sellPrice > maxPrice) matchesPrice = false;
      }

      return matchesName &&
          matchesCategory &&
          matchesHsn &&
          matchesLocation &&
          matchesSku &&
          matchesUnit &&
          matchesPrice;
    }).toList();

    list.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    _filteredItems = list;
  }

  void _onSearchChanged(String value) {
    setState(_applyFilters);
  }

  void _clearAllFilters() {
    setState(() {
      _nameCtrl.clear();
      _hsnCtrl.clear();
      _locationCtrl.clear();
      _skuCtrl.clear();
      _unitCtrl.clear();
      _priceMinCtrl.clear();
      _priceMaxCtrl.clear();
      _selectedCategory = null;
      _activeFilters = {};
      _applyFilters();
    });
  }

  void _clearSingleFilter(String key) {
    setState(() {
      switch (key) {
        case 'category':
          _selectedCategory = null;
          break;
        case 'hsn':
          _hsnCtrl.clear();
          break;
        case 'location':
          _locationCtrl.clear();
          break;
        case 'sku':
          _skuCtrl.clear();
          break;
        case 'unit':
          _unitCtrl.clear();
          break;
        case 'price':
          _priceMinCtrl.clear();
          _priceMaxCtrl.clear();
          break;
      }
      _applyFilters();
    });
  }

  void _toggleFilter(String filterKey) {
    setState(() {
      if (_activeFilters.contains(filterKey)) {
        _activeFilters.remove(filterKey);
        switch (filterKey) {
          case 'hsn':
            _hsnCtrl.clear();
            break;
          case 'location':
            _locationCtrl.clear();
            break;
          case 'sku':
            _skuCtrl.clear();
            break;
          case 'unit':
            _unitCtrl.clear();
            break;
          case 'price':
            _priceMinCtrl.clear();
            _priceMaxCtrl.clear();
            break;
          case 'category':
            _selectedCategory = null;
            break;
        }
      } else {
        _activeFilters.add(filterKey);
      }
      _applyFilters();
    });
  }

  // =====================================================================
  // FILTER SETTINGS SHEET
  // =====================================================================
  void _showFilterSettings() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      isScrollControlled: true,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (sheetContext, setSheetState) {
            return SafeArea(
              child: Padding(
                padding: EdgeInsets.only(
                    left: 20,
                    right: 20,
                    top: 16,
                    bottom: MediaQuery.of(sheetContext).viewInsets.bottom + 16),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                      maxHeight: MediaQuery.of(sheetContext).size.height * 0.85),
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Center(
                          child: Container(
                            width: 40,
                            height: 4.5,
                            margin: const EdgeInsets.only(bottom: 16),
                            decoration: BoxDecoration(
                              color: JoynColors.border,
                              borderRadius: BorderRadius.circular(3),
                            ),
                          ),
                        ),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(7),
                              decoration: BoxDecoration(
                                gradient:
                                _Premium.softGradient(JoynColors.primary),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                    color: JoynColors.primary
                                        .withValues(alpha: 0.12),
                                    width: 1),
                              ),
                              child: const Icon(Icons.tune_rounded,
                                  size: 15, color: JoynColors.primary),
                            ),
                            const SizedBox(width: 10),
                            Text('Filter Settings',
                                style: JoynTypography.titleMedium.copyWith(
                                    fontSize: 18, fontWeight: FontWeight.w800)),
                            const Spacer(),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 9, vertical: 4),
                              decoration: BoxDecoration(
                                color: JoynColors.primary
                                    .withValues(alpha: 0.10),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                  '${_activeFilters.length}/${_filterOptions.length}',
                                  style: JoynTypography.caption.copyWith(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w900,
                                      color: JoynColors.primary)),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Toggle filters to show/hide them on the main screen',
                          style: JoynTypography.caption.copyWith(
                            fontSize: 13,
                            color: JoynColors.secondaryText,
                          ),
                        ),
                        const SizedBox(height: 16),
                        ..._filterOptions.map((option) {
                          final isActive = _activeFilters.contains(option.key);
                          return _Pressable(
                            onTap: () {
                              HapticFeedback.selectionClick();
                              setSheetState(() => _toggleFilter(option.key));
                            },
                            scale: 0.98,
                            borderRadius: 14,
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 220),
                              margin: const EdgeInsets.symmetric(vertical: 3),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 12),
                              decoration: BoxDecoration(
                                gradient: isActive
                                    ? _Premium.softGradient(JoynColors.primary)
                                    : null,
                                color: isActive ? null : Colors.white,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: isActive
                                      ? JoynColors.primary
                                      .withValues(alpha: 0.25)
                                      : JoynColors.border
                                      .withValues(alpha: 0.6),
                                  width: isActive ? 1.3 : 1.1,
                                ),
                                boxShadow: isActive
                                    ? [
                                  BoxShadow(
                                      color: JoynColors.primary
                                          .withValues(alpha: 0.08),
                                      blurRadius: 10,
                                      offset: const Offset(0, 3)),
                                ]
                                    : null,
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 36,
                                    height: 36,
                                    alignment: Alignment.center,
                                    decoration: BoxDecoration(
                                      gradient: isActive
                                          ? _Premium.gradient(
                                          JoynColors.primary)
                                          : _Premium.softGradient(
                                          JoynColors.primary),
                                      borderRadius: BorderRadius.circular(10),
                                      boxShadow: isActive
                                          ? [
                                        BoxShadow(
                                            color: JoynColors.primary
                                                .withValues(alpha: 0.28),
                                            blurRadius: 8,
                                            offset:
                                            const Offset(0, 3)),
                                      ]
                                          : null,
                                    ),
                                    child: Icon(option.icon,
                                        size: 16,
                                        color: isActive
                                            ? Colors.white
                                            : JoynColors.primary),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      option.label,
                                      style: JoynTypography.bodyLarge.copyWith(
                                        fontSize: 14.5,
                                        fontWeight: isActive
                                            ? FontWeight.w800
                                            : FontWeight.w600,
                                        color: isActive
                                            ? JoynColors.primary
                                            : Colors.black87,
                                      ),
                                    ),
                                  ),
                                  Transform.scale(
                                    scale: 0.72,
                                    child: Switch.adaptive(
                                      value: isActive,
                                      onChanged: (_) {
                                        HapticFeedback.selectionClick();
                                        setSheetState(
                                                () => _toggleFilter(option.key));
                                      },
                                      activeTrackColor: JoynColors.primary,
                                      materialTapTargetSize:
                                      MaterialTapTargetSize.shrinkWrap,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }),
                        const SizedBox(height: 20),
                        _Pressable(
                          onTap: () => Navigator.pop(sheetContext),
                          scale: 0.97,
                          borderRadius: 14,
                          child: Container(
                            width: double.infinity,
                            height: 52,
                            decoration: BoxDecoration(
                              gradient: _Premium.gradient(JoynColors.primary),
                              borderRadius: BorderRadius.circular(14),
                              boxShadow:
                              _Premium.chipShadow(JoynColors.primary),
                            ),
                            child: Stack(
                              children: [
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
                                    mainAxisAlignment:
                                    MainAxisAlignment.center,
                                    children: [
                                      const Icon(Icons.check_rounded,
                                          color: Colors.white, size: 16),
                                      const SizedBox(width: 8),
                                      Text('Done',
                                          style: JoynTypography.bodyMedium
                                              .copyWith(
                                              fontWeight: FontWeight.w800,
                                              color: Colors.white,
                                              fontSize: 15)),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _hsnCtrl.dispose();
    _locationCtrl.dispose();
    _skuCtrl.dispose();
    _unitCtrl.dispose();
    _priceMinCtrl.dispose();
    _priceMaxCtrl.dispose();
    super.dispose();
  }

  // =====================================================================
  // FILTER FIELD — with focus glow
  // =====================================================================
  Widget _buildFilterField({
    required String label,
    required String hint,
    required TextEditingController controller,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return _FocusField(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: JoynTypography.bodyMedium.copyWith(
                  fontWeight: FontWeight.w700,
                  fontSize: 11.5,
                  color: JoynColors.secondaryText,
                  letterSpacing: 0.1)),
          const SizedBox(height: 6),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                  color: JoynColors.border.withValues(alpha: 0.85),
                  width: 1.2),
            ),
            child: TextField(
              controller: controller,
              keyboardType: keyboardType,
              onChanged: (_) => setState(_applyFilters),
              style: JoynTypography.bodyLarge.copyWith(
                  fontSize: 13.5, fontWeight: FontWeight.w600),
              decoration: InputDecoration(
                hintText: hint,
                hintStyle: JoynTypography.bodyMedium.copyWith(
                    color: JoynColors.secondaryText.withValues(alpha: 0.5),
                    fontSize: 13),
                prefixIcon: Padding(
                  padding: const EdgeInsets.only(left: 10, right: 6),
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 9),
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      gradient: _Premium.softGradient(JoynColors.primary),
                      borderRadius: BorderRadius.circular(7),
                    ),
                    child: Icon(icon, size: 12, color: JoynColors.primary),
                  ),
                ),
                suffixIcon: controller.text.isNotEmpty
                    ? IconButton(
                  icon: Container(
                    padding: const EdgeInsets.all(3),
                    decoration: BoxDecoration(
                      color: JoynColors.chipBackground,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.clear_rounded,
                        size: 11, color: JoynColors.secondaryText),
                  ),
                  onPressed: () => setState(() {
                    controller.clear();
                    _applyFilters();
                  }),
                )
                    : null,
                border: InputBorder.none,
                contentPadding:
                const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                isDense: true,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // =====================================================================
  // CATEGORY DROPDOWN
  // =====================================================================
  Widget _buildCategoryDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Category',
            style: JoynTypography.bodyMedium.copyWith(
                fontWeight: FontWeight.w700,
                fontSize: 11.5,
                color: JoynColors.secondaryText,
                letterSpacing: 0.1)),
        const SizedBox(height: 6),
        Container(
          height: 50,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
                color: JoynColors.border.withValues(alpha: 0.85), width: 1.2),
            boxShadow: _Premium.hairlineShadow,
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(5),
                decoration: BoxDecoration(
                  gradient: _Premium.softGradient(JoynColors.primary),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.category_outlined,
                    size: 13, color: JoynColors.primary),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String?>(
                    value: _selectedCategory,
                    isExpanded: true,
                    isDense: true,
                    itemHeight: null,
                    icon: const Icon(Icons.keyboard_arrow_down_rounded,
                        size: 20, color: JoynColors.primary),
                    dropdownColor: Colors.white,
                    style: JoynTypography.bodyLarge.copyWith(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                        color: Colors.black87),
                    borderRadius: BorderRadius.circular(14),
                    hint: Text('Select category',
                        style: JoynTypography.bodyMedium.copyWith(
                            color:
                            JoynColors.secondaryText.withValues(alpha: 0.5),
                            fontSize: 13.5)),
                    selectedItemBuilder: (context) {
                      return [
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Text('All Categories',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              softWrap: false,
                              style: JoynTypography.bodyLarge.copyWith(
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.black87)),
                        ),
                        ..._availableCategories.map((c) => Align(
                          alignment: Alignment.centerLeft,
                          child: Text(c,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              softWrap: false,
                              style: JoynTypography.bodyLarge.copyWith(
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.black87)),
                        )),
                      ];
                    },
                    items: [
                      const DropdownMenuItem<String?>(
                        value: null,
                        child: Text('All Categories'),
                      ),
                      ..._availableCategories.map((category) =>
                          DropdownMenuItem<String?>(
                            value: category,
                            child: Text(category),
                          )),
                    ],
                    onChanged: (value) {
                      setState(() {
                        _selectedCategory = value;
                        _applyFilters();
                      });
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // =====================================================================
  // INLINE ADVANCED FILTER CARD — shown when at least one filter is toggled on
  // =====================================================================
  Widget _buildInlineFilterCard() {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 12),
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        gradient: _Premium.surfaceGradient,
        borderRadius: BorderRadius.circular(16),
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
                height: 14,
                margin: const EdgeInsets.only(right: 8),
                decoration: BoxDecoration(
                  gradient: _Premium.gradient(JoynColors.primary),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Text('Advanced Filters',
                  style: JoynTypography.bodyMedium.copyWith(
                      fontSize: 12.5, fontWeight: FontWeight.w800, color: Colors.black87)),
              const Spacer(),
              if (_hasActiveFilters)
                _Pressable(
                  onTap: _clearAllFilters,
                  scale: 0.94,
                  borderRadius: 10,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                    decoration: BoxDecoration(
                      gradient: _Premium.softGradient(JoynColors.error),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                          color: JoynColors.error.withValues(alpha: 0.20), width: 1),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.close_rounded, size: 11, color: JoynColors.error),
                        const SizedBox(width: 4),
                        Text('Clear',
                            style: JoynTypography.caption.copyWith(
                                fontSize: 10.5,
                                fontWeight: FontWeight.w800,
                                color: JoynColors.error)),
                      ],
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          _AnimatedReveal(
            show: _activeFilters.contains('category'),
            child: _buildCategoryDropdown(),
          ),
          if (_activeFilters.contains('category')) const SizedBox(height: 10),
          _AnimatedReveal(
            show: _activeFilters.contains('hsn'),
            child: _buildFilterField(
              label: 'HSN / SAC Code',
              hint: 'Search by HSN code',
              controller: _hsnCtrl,
              icon: Icons.qr_code_rounded,
            ),
          ),
          if (_activeFilters.contains('hsn')) const SizedBox(height: 10),
          _AnimatedReveal(
            show: _activeFilters.contains('location'),
            child: _buildFilterField(
              label: 'Location',
              hint: 'Search by location',
              controller: _locationCtrl,
              icon: Icons.place_outlined,
            ),
          ),
          if (_activeFilters.contains('location')) const SizedBox(height: 10),
          _AnimatedReveal(
            show: _activeFilters.contains('sku'),
            child: _buildFilterField(
              label: 'SKU',
              hint: 'Search by SKU',
              controller: _skuCtrl,
              icon: Icons.inventory_2_outlined,
            ),
          ),
          if (_activeFilters.contains('sku')) const SizedBox(height: 10),
          _AnimatedReveal(
            show: _activeFilters.contains('unit'),
            child: _buildFilterField(
              label: 'Unit',
              hint: 'Search by unit',
              controller: _unitCtrl,
              icon: Icons.straighten_rounded,
            ),
          ),
          if (_activeFilters.contains('unit')) const SizedBox(height: 10),
          _AnimatedReveal(
            show: _activeFilters.contains('price'),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: _buildFilterField(
                    label: 'Min Price',
                    hint: '0',
                    controller: _priceMinCtrl,
                    icon: Icons.currency_rupee_rounded,
                    keyboardType: TextInputType.number,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildFilterField(
                    label: 'Max Price',
                    hint: '∞',
                    controller: _priceMaxCtrl,
                    icon: Icons.currency_rupee_rounded,
                    keyboardType: TextInputType.number,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // =====================================================================
  // BUILD
  // =====================================================================
  @override
  Widget build(BuildContext context) {
    final activeFilterCount = _activeFilterPills.length;

    return Scaffold(
      backgroundColor: JoynColors.background,
      body: RefreshIndicator(
        onRefresh: _loadItems,
        color: JoynColors.primary,
        backgroundColor: Colors.white,
        strokeWidth: 2.6,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
          slivers: [
            // SCROLLABLE APP BAR — hides on scroll down, reappears on scroll up
            SliverAppBar(
              backgroundColor: JoynColors.background,
              elevation: 0,
              scrolledUnderElevation: 0,
              floating: true,
              snap: true,
              centerTitle: true,
              leading: Padding(
                padding: const EdgeInsets.only(left: 8),
                child: _Pressable(
                  onTap: () => context.pop(),
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
              title: Text(
                'Manage Inventory',
                style: JoynTypography.titleMedium.copyWith(
                    fontSize: 18, fontWeight: FontWeight.w800, letterSpacing: -0.3),
              ),
            ),

            // HERO STATS
            if (!_isLoading && _allItems.isNotEmpty)
              SliverToBoxAdapter(
                child: _HeroStatsCard(
                  totalItems: _allItems.length,
                  filteredItems: _filteredItems.length,
                  stockValue: _calculateStockValue(),
                  lowStockCount: _lowStockCount,
                ),
              ),

            // SEARCH + FILTER ROW — same visual language as Items List screen
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
                child: Row(
                  children: [
                    Expanded(
                      child: Focus(
                        onFocusChange: (f) => setState(() => _searchFocused = f),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          height: 50,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: _searchFocused
                                  ? JoynColors.primary.withValues(alpha: 0.55)
                                  : JoynColors.border.withValues(alpha: 0.75),
                              width: _searchFocused ? 1.5 : 1.1,
                            ),
                            boxShadow: _searchFocused
                                ? [
                              BoxShadow(
                                  color: JoynColors.primary.withValues(alpha: 0.14),
                                  blurRadius: 16,
                                  offset: const Offset(0, 5)),
                              ..._Premium.softShadow,
                            ]
                                : _Premium.softShadow,
                          ),
                          child: TextField(
                            controller: _nameCtrl,
                            onChanged: _onSearchChanged,
                            style: JoynTypography.bodyMedium
                                .copyWith(fontSize: 13.5, fontWeight: FontWeight.w600),
                            decoration: InputDecoration(
                              hintText: 'Search by name, category, barcode...',
                              hintStyle: JoynTypography.bodyMedium.copyWith(
                                  color: JoynColors.secondaryText.withValues(alpha: 0.5),
                                  fontSize: 13.5),
                              prefixIcon: Padding(
                                padding: const EdgeInsets.only(left: 6, right: 4),
                                child: Container(
                                  margin: const EdgeInsets.all(9),
                                  decoration: BoxDecoration(
                                    gradient: _Premium.softGradient(JoynColors.primary),
                                    borderRadius: BorderRadius.circular(9),
                                  ),
                                  child: const Icon(Icons.search_rounded,
                                      size: 16, color: JoynColors.primary),
                                ),
                              ),
                              suffixIcon: _nameCtrl.text.isNotEmpty
                                  ? IconButton(
                                icon: Container(
                                  padding: const EdgeInsets.all(3),
                                  decoration: BoxDecoration(
                                    color: JoynColors.chipBackground,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.clear_rounded,
                                      size: 12, color: JoynColors.secondaryText),
                                ),
                                onPressed: () {
                                  _nameCtrl.clear();
                                  _onSearchChanged('');
                                },
                              )
                                  : null,
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(vertical: 13),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    _buildIconButton(Icons.tune_rounded, _showFilterSettings,
                        countBadge: activeFilterCount),
                  ],
                ),
              ),
            ),

            // INLINE ADVANCED FILTER CARD
            if (_activeFilters.isNotEmpty)
              SliverToBoxAdapter(child: _buildInlineFilterCard()),

            // ACTIVE FILTER PILLS
            if (_activeFilterPills.isNotEmpty)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _activeFilterPills
                        .map((e) => _ActiveFilterPill(
                      label: e.value,
                      onClear: () => _clearSingleFilter(e.key),
                    ))
                        .toList(),
                  ),
                ),
              ),

            // RESULTS COUNT
            if (!_isLoading)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                  child: Row(
                    children: [
                      Text(
                        '${_filteredItems.length} items found',
                        style: JoynTypography.caption.copyWith(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: JoynColors.secondaryText),
                      ),
                      const Spacer(),
                      Text(
                        'Stock Value: ₹${_calculateStockValue().toStringAsFixed(0)}',
                        style: JoynTypography.caption.copyWith(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            color: JoynColors.primary),
                      ),
                    ],
                  ),
                ),
              ),

            const SliverToBoxAdapter(child: SizedBox(height: 4)),

            // ITEMS LIST
            if (_isLoading)
              SliverToBoxAdapter(child: _buildSkeletonLoader())
            else if (_filteredItems.isEmpty)
              SliverFillRemaining(
                hasScrollBody: false,
                child: _buildEmptyState(),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 20),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                        (context, index) => _StaggeredItem(
                      index: index,
                      child: _buildItemCard(_filteredItems[index]),
                    ),
                    childCount: _filteredItems.length,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildIconButton(IconData icon, VoidCallback onTap, {int? countBadge}) {
    return _Pressable(
      onTap: onTap,
      scale: 0.92,
      borderRadius: 14,
      child: Container(
        width: 50,
        height: 50,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: JoynColors.border.withValues(alpha: 0.8), width: 1),
          boxShadow: _Premium.softShadow,
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Icon(icon, size: 20, color: JoynColors.primary),
            if (countBadge != null && countBadge > 0)
              Positioned(
                top: 6,
                right: 6,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 4.5, vertical: 1.5),
                  constraints: const BoxConstraints(minWidth: 16),
                  decoration: BoxDecoration(
                    gradient: _Premium.gradient(JoynColors.primary),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.white, width: 1.4),
                    boxShadow: [
                      BoxShadow(
                          color: JoynColors.primary.withValues(alpha: 0.45),
                          blurRadius: 6,
                          spreadRadius: 0.5),
                    ],
                  ),
                  alignment: Alignment.center,
                  child: Text('$countBadge',
                      style: JoynTypography.caption.copyWith(
                          fontSize: 9,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          height: 1.0)),
                ),
              ),
          ],
        ),
      ),
    );
  }

  double _calculateStockValue() {
    double total = 0;
    for (final item in _filteredItems) {
      total += item.stock * item.purchasePrice;
    }
    return total;
  }

  // =====================================================================
  // ITEM CARD — compact
  // =====================================================================
  Widget _buildItemCard(InventoryItemModel item) {
    final isLowStock = item.stock <= 5 && item.stock > 0;
    final isOutOfStock = item.stock <= 0;

    final stripeColor = isOutOfStock
        ? JoynColors.error
        : isLowStock
        ? const Color(0xFFF59E0B)
        : JoynColors.success;

    return _Pressable(
      onTap: () => _showItemDetail(item),
      scale: 0.985,
      borderRadius: 16,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
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
                        stripeColor.withValues(alpha: 0.85),
                        stripeColor.withValues(alpha: 0.35),
                      ],
                    ),
                  ),
                ),
              ),
              Positioned(
                left: 0,
                right: 0,
                top: 0,
                height: 26,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.white.withValues(alpha: 0.7),
                        Colors.white.withValues(alpha: 0.0),
                      ],
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 10, 10, 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(11),
                            boxShadow: [
                              BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.06),
                                  blurRadius: 6,
                                  offset: const Offset(0, 2)),
                            ],
                          ),
                          child: item.photoPath.isNotEmpty
                              ? ClipRRect(
                            borderRadius: BorderRadius.circular(11),
                            child: Image.file(
                              File(item.photoPath),
                              fit: BoxFit.cover,
                              errorBuilder:
                                  (context, error, stackTrace) =>
                                  _buildItemIconFallback(item, 16),
                            ),
                          )
                              : _buildItemIconFallback(item, 16),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item.name,
                                style: JoynTypography.bodyLarge.copyWith(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.black87,
                                    letterSpacing: -0.2),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 3),
                              if (item.category.isNotEmpty)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 7, vertical: 2.5),
                                  decoration: BoxDecoration(
                                    color: JoynColors.primary
                                        .withValues(alpha: 0.075),
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                        color: JoynColors.primary
                                            .withValues(alpha: 0.14),
                                        width: 1),
                                  ),
                                  child: Text(item.category,
                                      style: JoynTypography.caption.copyWith(
                                          fontSize: 9,
                                          fontWeight: FontWeight.w700,
                                          color: JoynColors.primary)),
                                ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 7, vertical: 4),
                          decoration: BoxDecoration(
                            gradient: _Premium.softGradient(stripeColor),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                                color: stripeColor.withValues(alpha: 0.28),
                                width: 1),
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Text('${item.stock}',
                                  style: JoynTypography.caption.copyWith(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w900,
                                      color: stripeColor,
                                      height: 1.0)),
                              Text(item.unit,
                                  style: JoynTypography.caption.copyWith(
                                      fontSize: 7.5,
                                      fontWeight: FontWeight.w700,
                                      color:
                                      stripeColor.withValues(alpha: 0.85),
                                      height: 1.2,
                                      letterSpacing: 0.3)),
                            ],
                          ),
                        ),
                        const SizedBox(width: 3),
                        if (isLowStock || isOutOfStock)
                          Padding(
                            padding: const EdgeInsets.only(right: 3),
                            child: _PulsingDot(color: stripeColor, size: 5),
                          ),
                        const Icon(Icons.chevron_right_rounded,
                            size: 18, color: JoynColors.secondaryText),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 7),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            JoynColors.chipBackground.withValues(alpha: 0.75),
                            JoynColors.chipBackground.withValues(alpha: 0.45),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                            color: JoynColors.border.withValues(alpha: 0.45),
                            width: 1),
                      ),
                      child: Row(
                        children: [
                          _buildInfoChip(Icons.straighten_rounded, item.unit),
                          if (item.hsnSac.isNotEmpty) ...[
                            const SizedBox(width: 6),
                            _buildInfoChip(
                                Icons.qr_code_rounded, item.hsnSac),
                          ],
                          const Spacer(),
                          Text(
                            '₹${item.sellingPrice.toStringAsFixed(0)}',
                            style: JoynTypography.bodyLarge.copyWith(
                                fontSize: 13,
                                fontWeight: FontWeight.w900,
                                color: JoynColors.primary,
                                letterSpacing: -0.3),
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
      ),
    );
  }

  Widget _buildItemIconFallback(InventoryItemModel item, double fontSize) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            JoynColors.primary.withValues(alpha: 0.12),
            JoynColors.primary.withValues(alpha: 0.22),
          ],
        ),
        borderRadius: BorderRadius.circular(11),
        border:
        Border.all(color: Colors.white.withValues(alpha: 0.75), width: 1.2),
      ),
      alignment: Alignment.center,
      child: Text(
        item.name.isNotEmpty ? item.name[0].toUpperCase() : '?',
        style: JoynTypography.titleMedium.copyWith(
          fontSize: fontSize,
          fontWeight: FontWeight.w900,
          color: JoynColors.primary,
        ),
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3.5),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
            color: JoynColors.border.withValues(alpha: 0.6), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 9, color: JoynColors.primary),
          const SizedBox(width: 4),
          Text(
            label,
            style: JoynTypography.caption.copyWith(
              fontSize: 9,
              fontWeight: FontWeight.w700,
              color: JoynColors.primary,
            ),
          ),
        ],
      ),
    );
  }

  // =====================================================================
  // EMPTY STATE
  // =====================================================================
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 120,
            height: 120,
            child: Stack(
              alignment: Alignment.center,
              children: [
                _PulsingDot(color: JoynColors.primary, size: 36),
                Container(
                  width: 86,
                  height: 86,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Colors.white, JoynColors.background],
                    ),
                    borderRadius: BorderRadius.circular(28),
                    border: _Premium.hairline(width: 1.1),
                    boxShadow: _Premium.cardShadow,
                  ),
                  child: Icon(Icons.inventory_2_outlined,
                      size: 40,
                      color: JoynColors.primary.withValues(alpha: 0.6)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Text('No Items Found',
              style: JoynTypography.titleMedium.copyWith(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.2)),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              'Try adjusting your search or tap the filter icon to add more filters',
              textAlign: TextAlign.center,
              style: JoynTypography.subtitle.copyWith(
                  fontSize: 13,
                  color: JoynColors.secondaryText,
                  height: 1.4),
            ),
          ),
        ],
      ),
    );
  }

  // =====================================================================
  // SKELETON LOADER
  // =====================================================================
  Widget _buildSkeletonLoader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 20),
      child: Column(
        children: List.generate(
          4,
              (index) => Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: _Premium.surfaceGradient,
              borderRadius: BorderRadius.circular(16),
              border: _Premium.hairline(width: 1.0, alpha: 0.8),
              boxShadow: _Premium.softShadow,
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    const _ShimmerBox(width: 38, height: 38, borderRadius: 11),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          _ShimmerBox(width: 130, height: 12, borderRadius: 6),
                          SizedBox(height: 6),
                          _ShimmerBox(width: 70, height: 10, borderRadius: 6),
                        ],
                      ),
                    ),
                    const _ShimmerBox(width: 44, height: 32, borderRadius: 8),
                  ],
                ),
                const SizedBox(height: 8),
                const _ShimmerBox(width: double.infinity, height: 32, borderRadius: 10),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // =====================================================================
  // DETAIL DIALOG — premium (FIXED padding)
  // =====================================================================
  Future<void> _showItemDetail(InventoryItemModel item) async {
    HapticFeedback.lightImpact();
    await showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
        child: Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.85,
          ),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: _Premium.floatingShadow(Colors.black),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    gradient: _Premium.deepGradient(JoynColors.primary),
                  ),
                  child: Stack(
                    children: [
                      Positioned(
                        top: -30,
                        right: -20,
                        child: Container(
                          width: 100,
                          height: 100,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: RadialGradient(colors: [
                              Colors.white.withValues(alpha: 0.20),
                              Colors.white.withValues(alpha: 0.0),
                            ]),
                          ),
                        ),
                      ),
                      Row(
                        children: [
                          Container(
                            width: 60,
                            height: 60,
                            padding: const EdgeInsets.all(2),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(16),
                              color: Colors.white,
                              boxShadow: [
                                BoxShadow(
                                    color:
                                    Colors.black.withValues(alpha: 0.15),
                                    blurRadius: 12,
                                    offset: const Offset(0, 4)),
                              ],
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(14),
                              child: item.photoPath.isNotEmpty
                                  ? Image.file(
                                File(item.photoPath),
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stack) =>
                                    _buildItemIconFallback(item, 24),
                              )
                                  : _buildItemIconFallback(item, 24),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item.name,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: JoynTypography.titleMedium.copyWith(
                                    fontSize: 17,
                                    fontWeight: FontWeight.w900,
                                    color: Colors.white,
                                    letterSpacing: -0.3,
                                    height: 1.15,
                                  ),
                                ),
                                if (item.category.isNotEmpty) ...[
                                  const SizedBox(height: 6),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 9, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: Colors.white
                                          .withValues(alpha: 0.16),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Text(item.category,
                                        style:
                                        JoynTypography.caption.copyWith(
                                            fontSize: 10.5,
                                            fontWeight: FontWeight.w800,
                                            color: Colors.white)),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          _Pressable(
                            onTap: () => Navigator.pop(context),
                            scale: 0.9,
                            borderRadius: 20,
                            child: Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.18),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.close_rounded,
                                  size: 16, color: Colors.white),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Content
                Flexible(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (item.photoPath.isNotEmpty)
                          Container(
                            width: double.infinity,
                            height: 180,
                            margin: const EdgeInsets.only(bottom: 18),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(16),
                              border: _Premium.hairline(width: 1.2),
                              boxShadow: _Premium.softShadow,
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(16),
                              child: Image.file(
                                File(item.photoPath),
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stack) => Center(
                                  child: Icon(
                                      Icons.image_not_supported_outlined,
                                      size: 48,
                                      color: JoynColors.secondaryText),
                                ),
                              ),
                            ),
                          ),
                        _buildDetailSection(
                            'Stock Information', Icons.inventory_2_outlined, [
                          _buildDetailRow('Quantity', '${item.qty} ${item.unit}'),
                          _buildDetailRow('Stock', '${item.stock} ${item.unit}'),
                          _buildDetailRow(
                              'Location',
                              item.location.isEmpty
                                  ? 'Not Set'
                                  : item.location),
                          _buildDetailRow(
                              'Barcode Mode',
                              item.barcodeMode == 'same'
                                  ? 'Same for all'
                                  : 'Separate'),
                        ]),
                        const SizedBox(height: 14),
                        _buildDetailSection(
                            'Pricing', Icons.currency_rupee_rounded, [
                          _buildDetailRow('Purchase Price',
                              '₹${item.purchasePrice.toStringAsFixed(2)}'),
                          _buildDetailRow('Selling Price',
                              '₹${item.sellingPrice.toStringAsFixed(2)}'),
                          if (item.taxRatePercent > 0) ...[
                            _buildDetailRow('Tax Rate', item.taxRateLabel),
                            _buildDetailRow(
                                'Tax Percent', '${item.taxRatePercent}%'),
                          ],
                        ]),
                        const SizedBox(height: 14),
                        _buildDetailSection(
                            'Item Details', Icons.info_outline_rounded, [
                          _buildDetailRow('HSN/SAC',
                              item.hsnSac.isEmpty ? 'Not Set' : item.hsnSac),
                          _buildDetailRow('Unit', item.unit),
                          _buildDetailRow('Barcode',
                              item.barcode.isEmpty ? 'Not Set' : item.barcode),
                        ]),
                        const SizedBox(height: 14),
                        _buildDetailSection(
                            'Created', Icons.access_time_rounded, [
                          _buildDetailRow(
                              'Date',
                              '${item.createdAt.day}/${item.createdAt.month}/${item.createdAt.year}'),
                          _buildDetailRow(
                              'Time',
                              '${item.createdAt.hour}:${item.createdAt.minute.toString().padLeft(2, '0')}'),
                        ]),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDetailSection(
      String title, IconData icon, List<Widget> children) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: _Premium.surfaceGradient,
        borderRadius: BorderRadius.circular(14),
        border: _Premium.hairline(width: 1.0, alpha: 0.85),
        boxShadow: _Premium.softShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 3,
                height: 16,
                margin: const EdgeInsets.only(right: 8),
                decoration: BoxDecoration(
                  gradient: _Premium.gradient(JoynColors.primary),
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
              Container(
                padding: const EdgeInsets.all(5),
                decoration: BoxDecoration(
                  gradient: _Premium.softGradient(JoynColors.primary),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, size: 12, color: JoynColors.primary),
              ),
              const SizedBox(width: 8),
              Text(
                title,
                style: JoynTypography.bodyLarge.copyWith(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: Colors.black87),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: JoynTypography.bodyMedium.copyWith(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: JoynColors.secondaryText),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: JoynTypography.bodyMedium.copyWith(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w800,
                  color: Colors.black87),
            ),
          ),
        ],
      ),
    );
  }
}