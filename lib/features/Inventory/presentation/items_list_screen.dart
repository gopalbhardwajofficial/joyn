import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';
import '../../../core/theme/joyn_colors.dart';
import '../../../core/theme/joyn_typography.dart';
import '../../orders/models/sales_models.dart';
import '../../orders/data/sales_repository.dart';
import '../../Inventory/presentation/add_new_item_screen.dart';
import '../../Inventory/presentation/item_detail_screen.dart';
import 'scan_code_screen.dart';
import '../../../core/services/api_service.dart';

enum _SortOption { nameAsc, nameDesc, stockLow, stockHigh, priceLow, priceHigh, recentlyAdded }
enum _StockFilter { all, inStock, lowStock, outOfStock }

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
    this.onLongPress,
    this.scale = 0.97,
    this.borderRadius = 16,
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
// HERO STATS CARD — inventory overview
// =====================================================================
class _HeroStatsCard extends StatelessWidget {
  const _HeroStatsCard({
    required this.totalItems,
    required this.stockValue,
    required this.lowStockCount,
  });

  final int totalItems;
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
                        border: Border.all(color: Colors.white.withValues(alpha: 0.20), width: 0.8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.insights_rounded, size: 11, color: Colors.white),
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
                        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF59E0B).withValues(alpha: 0.24),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                              color: const Color(0xFFF59E0B).withValues(alpha: 0.4), width: 0.8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.warning_amber_rounded, size: 11, color: Colors.white),
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
                        label: 'Total Items',
                        value: '$totalItems',
                      ),
                    ),
                    Container(width: 1, height: 42, color: Colors.white.withValues(alpha: 0.18)),
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
      crossAxisAlignment: alignEnd ? CrossAxisAlignment.end : CrossAxisAlignment.start,
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
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  letterSpacing: -0.5)),
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
class ItemsListScreen extends StatefulWidget {
  const ItemsListScreen({super.key});

  @override
  State<ItemsListScreen> createState() => _ItemsListScreenState();
}

class _ItemsListScreenState extends State<ItemsListScreen> {
  final SalesRepository _salesRepository = SalesRepository();
  List<InventoryItemModel> _items = [];
  List<InventoryItemModel> _filteredItems = [];
  bool _isLoading = true;
  String _searchQuery = '';
  bool _searchFocused = false;

  _SortOption _sortOption = _SortOption.nameAsc;
  _StockFilter _stockFilter = _StockFilter.all;
  String? _selectedCategory;

  // Manage-Inventory style advanced filters
  final TextEditingController _searchCtrl = TextEditingController();
  final TextEditingController _hsnCtrl = TextEditingController();
  final TextEditingController _locationCtrl = TextEditingController();
  final TextEditingController _skuCtrl = TextEditingController();
  final TextEditingController _unitCtrl = TextEditingController();
  final TextEditingController _priceMinCtrl = TextEditingController();
  final TextEditingController _priceMaxCtrl = TextEditingController();

  Set<String> _activeFilters = {};

  final List<_FilterOption> _filterOptions = const [
    _FilterOption('category', 'Category', Icons.category_outlined),
    _FilterOption('stock', 'Stock Status', Icons.inventory_2_outlined),
    _FilterOption('hsn', 'HSN / SAC', Icons.qr_code_rounded),
    _FilterOption('location', 'Location', Icons.place_outlined),
    _FilterOption('sku', 'SKU', Icons.inventory_2_outlined),
    _FilterOption('unit', 'Unit', Icons.straighten_rounded),
    _FilterOption('price', 'Price Range', Icons.currency_rupee_rounded),
  ];

  @override
  void initState() {
    super.initState();
    _loadItems();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _hsnCtrl.dispose();
    _locationCtrl.dispose();
    _skuCtrl.dispose();
    _unitCtrl.dispose();
    _priceMinCtrl.dispose();
    _priceMaxCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadItems() async {
    try {
      final items = await _salesRepository.getItems();
      if (!mounted) return;
      setState(() {
        _items = List<InventoryItemModel>.from(items);
        _isLoading = false;
        _applyFilters();
      });

      // Background sync from live PostgreSQL backend
      ApiService.fetchItems().then((remoteItems) {
        debugPrint('Fetched ${remoteItems.length} items from backend API');
      }).catchError((err) {
        debugPrint('Remote fetch items error: $err');
      });
    } catch (e) {
      debugPrint('Error loading items: $e');
      if (!mounted) return;
      setState(() {
        _items = [];
        _isLoading = false;
      });
    }
  }

  List<String> get _availableCategories {
    final categories = _items
        .map((item) => item.category)
        .where((c) => c.isNotEmpty)
        .toSet()
        .toList()
      ..sort();
    return categories;
  }

  int get _lowStockCount {
    return _items.where((item) => item.stock > 0 && item.stock <= 5).length;
  }

  double get _totalStockValue {
    double total = 0;
    for (final item in _items) {
      total += item.stock * item.purchasePrice;
    }
    return total;
  }

  bool get _hasActiveFilters =>
      _activeFilters.contains('category') && _selectedCategory != null ||
          _activeFilters.contains('stock') && _stockFilter != _StockFilter.all ||
          _activeFilters.contains('hsn') && _hsnCtrl.text.isNotEmpty ||
          _activeFilters.contains('location') && _locationCtrl.text.isNotEmpty ||
          _activeFilters.contains('sku') && _skuCtrl.text.isNotEmpty ||
          _activeFilters.contains('unit') && _unitCtrl.text.isNotEmpty ||
          _activeFilters.contains('price') &&
              (_priceMinCtrl.text.isNotEmpty || _priceMaxCtrl.text.isNotEmpty);

  List<MapEntry<String, String>> get _activeFilterPills {
    final list = <MapEntry<String, String>>[];
    if (_activeFilters.contains('category') && _selectedCategory != null) {
      list.add(MapEntry('category', 'Cat: $_selectedCategory'));
    }
    if (_activeFilters.contains('stock') && _stockFilter != _StockFilter.all) {
      final label = _stockFilter == _StockFilter.inStock
          ? 'In Stock'
          : _stockFilter == _StockFilter.lowStock
          ? 'Low Stock'
          : 'Out of Stock';
      list.add(MapEntry('stock', label));
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

  void _applyFilters() {
    var list = _items.where((item) {
      final query = _searchQuery.toLowerCase().trim();
      final matchesQuery = query.isEmpty ||
          item.name.toLowerCase().contains(query) ||
          item.category.toLowerCase().contains(query) ||
          item.barcode.contains(query) ||
          item.displayItemCode.toLowerCase().contains(query) ||
          (item.itemNumber != null && item.itemNumber.toString().contains(query)) ||
          item.hsnSac.toLowerCase().contains(query);

      final matchesCategory = !_activeFilters.contains('category') ||
          _selectedCategory == null ||
          item.category == _selectedCategory;

      final matchesStock = !_activeFilters.contains('stock') ||
          _stockFilter == _StockFilter.all ||
          (_stockFilter == _StockFilter.inStock && item.stock > 5) ||
          (_stockFilter == _StockFilter.lowStock && item.stock > 0 && item.stock <= 5) ||
          (_stockFilter == _StockFilter.outOfStock && item.stock <= 0);

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

      return matchesQuery &&
          matchesCategory &&
          matchesStock &&
          matchesHsn &&
          matchesLocation &&
          matchesSku &&
          matchesUnit &&
          matchesPrice;
    }).toList();

    switch (_sortOption) {
      case _SortOption.nameAsc:
        list.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
        break;
      case _SortOption.nameDesc:
        list.sort((a, b) => b.name.toLowerCase().compareTo(a.name.toLowerCase()));
        break;
      case _SortOption.stockLow:
        list.sort((a, b) => a.stock.compareTo(b.stock));
        break;
      case _SortOption.stockHigh:
        list.sort((a, b) => b.stock.compareTo(a.stock));
        break;
      case _SortOption.priceLow:
        list.sort((a, b) => a.sellingPrice.compareTo(b.sellingPrice));
        break;
      case _SortOption.priceHigh:
        list.sort((a, b) => b.sellingPrice.compareTo(a.sellingPrice));
        break;
      case _SortOption.recentlyAdded:
        list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        break;
    }

    _filteredItems = list;
  }

  void _onSearchChanged(String value) {
    setState(() {
      _searchQuery = value;
      _applyFilters();
    });
  }

  Future<void> _scanBarcodeToSearch() async {
    HapticFeedback.lightImpact();
    final scannedCode = await Navigator.of(context).push<String>(
      MaterialPageRoute(builder: (_) => const ScanCodeScreen()),
    );
    if (scannedCode != null && scannedCode.trim().isNotEmpty && mounted) {
      final code = scannedCode.trim();
      _searchCtrl.text = code;
      _onSearchChanged(code);
    }
  }

  void _toggleFilter(String key) {
    setState(() {
      if (_activeFilters.contains(key)) {
        _activeFilters.remove(key);
        switch (key) {
          case 'category':
            _selectedCategory = null;
            break;
          case 'stock':
            _stockFilter = _StockFilter.all;
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
      } else {
        _activeFilters.add(key);
      }
      _applyFilters();
    });
  }

  void _clearSingleFilter(String key) {
    setState(() {
      switch (key) {
        case 'category':
          _selectedCategory = null;
          break;
        case 'stock':
          _stockFilter = _StockFilter.all;
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

  void _clearAllFilters() {
    setState(() {
      _selectedCategory = null;
      _stockFilter = _StockFilter.all;
      _hsnCtrl.clear();
      _locationCtrl.clear();
      _skuCtrl.clear();
      _unitCtrl.clear();
      _priceMinCtrl.clear();
      _priceMaxCtrl.clear();
      _activeFilters = {};
      _applyFilters();
    });
  }

  Future<void> _shareItem(InventoryItemModel item) async {
    final String shareText = '''
🛒 *Item Details*
📦 Name: ${item.name}
🏷️ Category: ${item.category.isNotEmpty ? item.category : 'N/A'}
💰 Selling Price: ₹${item.sellingPrice.toStringAsFixed(2)}
📊 Stock: ${item.stock} ${item.unit}
📍 Location: ${item.location.isNotEmpty ? item.location : 'N/A'}
🧾 HSN/SAC: ${item.hsnSac.isNotEmpty ? item.hsnSac : 'N/A'}
''';

    try {
      await Share.share(shareText, subject: 'Item: ${item.name}');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not share: $e'),
            backgroundColor: JoynColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _navigateToAddItem() async {
    HapticFeedback.lightImpact();
    await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => const AddNewItemScreen()),
    );
    if (mounted) await _loadItems();
  }

  Future<void> _navigateToEditItem(InventoryItemModel item) async {
    HapticFeedback.lightImpact();
    await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => AddNewItemScreen(existingItem: item)),
    );
    if (mounted) await _loadItems();
  }

  Future<void> _navigateToItemDetail(InventoryItemModel item) async {
    HapticFeedback.lightImpact();
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => ItemDetailScreen(item: item)),
    );
    if (mounted) await _loadItems();
  }

  Future<void> _deleteItem(InventoryItemModel item) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        title: Text('Delete Item?',
            style: JoynTypography.titleMedium.copyWith(fontSize: 17, fontWeight: FontWeight.w800)),
        content: Text(
          'Remove "${item.name}" from your inventory?',
          style: JoynTypography.bodyMedium.copyWith(fontSize: 13.5, color: JoynColors.secondaryText),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Delete',
                style: TextStyle(color: JoynColors.error, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _salesRepository.deleteItem(item.id);
      await _loadItems();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Item deleted successfully!'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: JoynColors.error,
            margin: const EdgeInsets.all(16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
        );
      }
    }
  }

  Future<void> _duplicateItem(InventoryItemModel item) async {
    final newItem = InventoryItemModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: '${item.name} (Copy)',
      qty: item.qty,
      barcode: item.barcode,
      unit: item.unit,
      category: item.category,
      hsnSac: item.hsnSac,
      location: item.location,
      barcodeMode: item.barcodeMode,
      photoPath: item.photoPath,
      purchasePrice: item.purchasePrice,
      sellingPrice: item.sellingPrice,
      salePriceTaxMode: item.salePriceTaxMode,
      discountOnSalePrice: item.discountOnSalePrice,
      discountType: item.discountType,
      purchasePriceTaxMode: item.purchasePriceTaxMode,
      taxRateLabel: item.taxRateLabel,
      taxRatePercent: item.taxRatePercent,
      stock: item.stock,
      createdAt: DateTime.now(),
    );

    await _salesRepository.insertItem(newItem);
    await _loadItems();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Item duplicated: ${newItem.name}'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: JoynColors.primary,
          margin: const EdgeInsets.all(16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
      );
    }
  }

  // =====================================================================
  // OPTIONS SHEET
  // =====================================================================
  Future<void> _showItemOptions(InventoryItemModel item) async {
    await showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4.5,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: JoynColors.border,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          gradient: _Premium.softGradient(JoynColors.primary),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.inventory_2_outlined,
                            size: 16, color: JoynColors.primary),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          item.name,
                          style: JoynTypography.titleMedium.copyWith(
                              fontSize: 16, fontWeight: FontWeight.w800),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                _buildOptionTile(
                  icon: Icons.visibility_outlined,
                  label: 'View Details',
                  color: JoynColors.primary,
                  onTap: () {
                    Navigator.pop(context);
                    _navigateToItemDetail(item);
                  },
                ),
                _buildOptionTile(
                  icon: Icons.edit_outlined,
                  label: 'Edit Item',
                  color: const Color(0xFFF59E0B),
                  onTap: () {
                    Navigator.pop(context);
                    _navigateToEditItem(item);
                  },
                ),
                _buildOptionTile(
                  icon: Icons.copy_outlined,
                  label: 'Duplicate',
                  color: const Color(0xFF2563EB),
                  onTap: () {
                    Navigator.pop(context);
                    _duplicateItem(item);
                  },
                ),
                _buildOptionTile(
                  icon: Icons.share_outlined,
                  label: 'Share Item',
                  color: const Color(0xFF7C3AED),
                  onTap: () {
                    Navigator.pop(context);
                    _shareItem(item);
                  },
                ),
                _buildOptionTile(
                  icon: Icons.delete_outline_rounded,
                  label: 'Delete',
                  color: JoynColors.error,
                  isDestructive: true,
                  onTap: () {
                    Navigator.pop(context);
                    _deleteItem(item);
                  },
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildOptionTile({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
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
                border: Border.all(color: color.withValues(alpha: 0.15), width: 1),
              ),
              child: Icon(icon, color: color, size: 18),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                label,
                style: JoynTypography.bodyLarge.copyWith(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: isDestructive ? JoynColors.error : Colors.black87,
                ),
              ),
            ),
            Icon(Icons.chevron_right_rounded,
                size: 20, color: JoynColors.secondaryText.withValues(alpha: 0.5)),
          ],
        ),
      ),
    );
  }

  // =====================================================================
  // SORT SHEET
  // =====================================================================
  void _showSortSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4.5,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                  color: JoynColors.border,
                  borderRadius: BorderRadius.circular(3)),
            ),
            Row(
              children: [
                Padding(
                  padding: const EdgeInsets.only(left: 20),
                  child: Container(
                    padding: const EdgeInsets.all(7),
                    decoration: BoxDecoration(
                      gradient: _Premium.softGradient(JoynColors.primary),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.swap_vert_rounded,
                        size: 15, color: JoynColors.primary),
                  ),
                ),
                const SizedBox(width: 10),
                Text('Sort Items',
                    style: JoynTypography.titleMedium
                        .copyWith(fontSize: 17, fontWeight: FontWeight.w800)),
              ],
            ),
            const SizedBox(height: 12),
            _buildSortTile('Name (A-Z)', Icons.sort_by_alpha_rounded, _SortOption.nameAsc),
            _buildSortTile('Name (Z-A)', Icons.sort_by_alpha_rounded, _SortOption.nameDesc),
            _buildSortTile('Stock (Low to High)', Icons.inventory_2_outlined, _SortOption.stockLow),
            _buildSortTile('Stock (High to Low)', Icons.inventory_2_outlined, _SortOption.stockHigh),
            _buildSortTile('Price (Low to High)', Icons.currency_rupee_rounded, _SortOption.priceLow),
            _buildSortTile('Price (High to Low)', Icons.currency_rupee_rounded, _SortOption.priceHigh),
            _buildSortTile('Recently Added', Icons.access_time_rounded, _SortOption.recentlyAdded),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _buildSortTile(String label, IconData icon, _SortOption option) {
    final selected = _sortOption == option;
    return _Pressable(
      onTap: () {
        setState(() {
          _sortOption = option;
          _applyFilters();
        });
        Navigator.pop(context);
      },
      scale: 0.98,
      borderRadius: 14,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 3),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
        decoration: BoxDecoration(
          gradient: selected ? _Premium.softGradient(JoynColors.primary) : null,
          borderRadius: BorderRadius.circular(14),
          border: selected
              ? Border.all(color: JoynColors.primary.withValues(alpha: 0.20), width: 1)
              : null,
        ),
        child: Row(
          children: [
            Icon(icon,
                size: 19,
                color: selected ? JoynColors.primary : JoynColors.secondaryText),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                label,
                style: JoynTypography.bodyLarge.copyWith(
                  fontSize: 14.5,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  color: selected ? JoynColors.primary : Colors.black87,
                ),
              ),
            ),
            if (selected)
              Container(
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  gradient: _Premium.gradient(JoynColors.primary),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                        color: JoynColors.primary.withValues(alpha: 0.3),
                        blurRadius: 6,
                        offset: const Offset(0, 2)),
                  ],
                ),
                child: const Icon(Icons.check_rounded, color: Colors.white, size: 12),
              ),
          ],
        ),
      ),
    );
  }

  // =====================================================================
  // FILTER SETTINGS SHEET (Manage-Inventory style toggles)
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
                                gradient: _Premium.softGradient(JoynColors.primary),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                    color: JoynColors.primary.withValues(alpha: 0.12),
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
                              padding:
                              const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                              decoration: BoxDecoration(
                                color: JoynColors.primary.withValues(alpha: 0.10),
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
                              padding:
                              const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                              decoration: BoxDecoration(
                                gradient: isActive
                                    ? _Premium.softGradient(JoynColors.primary)
                                    : null,
                                color: isActive ? null : Colors.white,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: isActive
                                      ? JoynColors.primary.withValues(alpha: 0.25)
                                      : JoynColors.border.withValues(alpha: 0.6),
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
                                          ? _Premium.gradient(JoynColors.primary)
                                          : _Premium.softGradient(JoynColors.primary),
                                      borderRadius: BorderRadius.circular(10),
                                      boxShadow: isActive
                                          ? [
                                        BoxShadow(
                                            color: JoynColors.primary
                                                .withValues(alpha: 0.28),
                                            blurRadius: 8,
                                            offset: const Offset(0, 3)),
                                      ]
                                          : null,
                                    ),
                                    child: Icon(option.icon,
                                        size: 16,
                                        color: isActive ? Colors.white : JoynColors.primary),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      option.label,
                                      style: JoynTypography.bodyLarge.copyWith(
                                        fontSize: 14.5,
                                        fontWeight:
                                        isActive ? FontWeight.w800 : FontWeight.w600,
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
                                        setSheetState(() => _toggleFilter(option.key));
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
                              boxShadow: _Premium.chipShadow(JoynColors.primary),
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
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Icon(Icons.check_rounded,
                                          color: Colors.white, size: 16),
                                      const SizedBox(width: 8),
                                      Text('Done',
                                          style: JoynTypography.bodyMedium.copyWith(
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

  Widget _buildFilterChip(String label, bool selected, VoidCallback onTap) {
    return _Pressable(
      onTap: onTap,
      scale: 0.95,
      borderRadius: 20,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          gradient: selected ? _Premium.gradient(JoynColors.primary) : null,
          color: selected ? null : JoynColors.chipBackground,
          borderRadius: BorderRadius.circular(20),
          border: selected
              ? null
              : Border.all(color: JoynColors.border.withValues(alpha: 0.6), width: 1),
          boxShadow: selected ? _Premium.chipShadow(JoynColors.primary) : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (selected) ...[
              const Icon(Icons.check_rounded, size: 12, color: Colors.white),
              const SizedBox(width: 4),
            ],
            Text(
              label,
              style: JoynTypography.caption.copyWith(
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
                color: selected ? Colors.white : JoynColors.secondaryText,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // =====================================================================
  // INLINE FILTER FIELD (text)
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
              border: Border.all(color: JoynColors.border.withValues(alpha: 0.85), width: 1.2),
            ),
            child: TextField(
              controller: controller,
              keyboardType: keyboardType,
              onChanged: (_) => setState(_applyFilters),
              style: JoynTypography.bodyLarge.copyWith(fontSize: 13.5, fontWeight: FontWeight.w600),
              decoration: InputDecoration(
                hintText: hint,
                hintStyle: JoynTypography.bodyMedium.copyWith(
                    color: JoynColors.secondaryText.withValues(alpha: 0.5), fontSize: 13),
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
                contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                isDense: true,
              ),
            ),
          ),
        ],
      ),
    );
  }

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
            border: Border.all(color: JoynColors.border.withValues(alpha: 0.85), width: 1.2),
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
                child: const Icon(Icons.category_outlined, size: 13, color: JoynColors.primary),
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
                        fontSize: 13.5, fontWeight: FontWeight.w700, color: Colors.black87),
                    borderRadius: BorderRadius.circular(14),
                    hint: Text('Select category',
                        style: JoynTypography.bodyMedium.copyWith(
                            color: JoynColors.secondaryText.withValues(alpha: 0.5),
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
                      ..._availableCategories.map(
                            (category) => DropdownMenuItem<String?>(
                          value: category,
                          child: Text(category),
                        ),
                      ),
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
  // INLINE FILTER CARD — shown when at least one advanced filter is active
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
            show: _activeFilters.contains('stock'),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Stock Status',
                    style: JoynTypography.bodyMedium.copyWith(
                        fontWeight: FontWeight.w700,
                        fontSize: 11.5,
                        color: JoynColors.secondaryText)),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _buildFilterChip('All', _stockFilter == _StockFilter.all,
                            () => setState(() {
                          _stockFilter = _StockFilter.all;
                          _applyFilters();
                        })),
                    _buildFilterChip('In Stock', _stockFilter == _StockFilter.inStock,
                            () => setState(() {
                          _stockFilter = _StockFilter.inStock;
                          _applyFilters();
                        })),
                    _buildFilterChip('Low Stock', _stockFilter == _StockFilter.lowStock,
                            () => setState(() {
                          _stockFilter = _StockFilter.lowStock;
                          _applyFilters();
                        })),
                    _buildFilterChip('Out of Stock', _stockFilter == _StockFilter.outOfStock,
                            () => setState(() {
                          _stockFilter = _StockFilter.outOfStock;
                          _applyFilters();
                        })),
                  ],
                ),
              ],
            ),
          ),
          if (_activeFilters.contains('stock')) const SizedBox(height: 10),
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
      body: Column(
        children: [
          Expanded(
            child: CustomScrollView(
              physics: const BouncingScrollPhysics(),
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
                    'Items',
                    style: JoynTypography.titleMedium.copyWith(
                        fontSize: 18, fontWeight: FontWeight.w800, letterSpacing: -0.3),
                  ),
                  actions: [
                    _Pressable(
                      onTap: _scanBarcodeToSearch,
                      scale: 0.9,
                      borderRadius: 22,
                      child: Container(
                        margin: const EdgeInsets.fromLTRB(0, 6, 8, 6),
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: JoynColors.primary.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                          border: _Premium.hairline(width: 1.0),
                        ),
                        child: const Icon(Icons.qr_code_scanner_rounded,
                            size: 19, color: JoynColors.primary),
                      ),
                    ),
                    _Pressable(
                      onTap: _navigateToAddItem,
                      scale: 0.9,
                      borderRadius: 22,
                      child: Container(
                        margin: const EdgeInsets.fromLTRB(0, 6, 12, 6),
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          gradient: _Premium.gradient(JoynColors.primary),
                          shape: BoxShape.circle,
                          boxShadow: _Premium.chipShadow(JoynColors.primary),
                        ),
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            Positioned.fill(
                              child: Container(
                                decoration: BoxDecoration(
                                  gradient: _Premium.topHighlight,
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ),
                            const Icon(Icons.add_rounded, size: 20, color: Colors.white),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),

                // HERO STATS
                if (!_isLoading && _items.isNotEmpty && _searchQuery.isEmpty)
                  SliverToBoxAdapter(
                    child: _HeroStatsCard(
                      totalItems: _items.length,
                      stockValue: _totalStockValue,
                      lowStockCount: _lowStockCount,
                    ),
                  ),

                // SEARCH + SORT + FILTER ROW
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
                                controller: _searchCtrl,
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
                                  suffixIcon: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      if (_searchQuery.isNotEmpty)
                                        IconButton(
                                          icon: Container(
                                            padding: const EdgeInsets.all(3),
                                            decoration: const BoxDecoration(
                                              color: JoynColors.chipBackground,
                                              shape: BoxShape.circle,
                                            ),
                                            child: const Icon(Icons.clear_rounded,
                                                size: 12, color: JoynColors.secondaryText),
                                          ),
                                          onPressed: () {
                                            _searchCtrl.clear();
                                            _onSearchChanged('');
                                          },
                                        ),
                                      IconButton(
                                        icon: Container(
                                          padding: const EdgeInsets.all(4),
                                          decoration: BoxDecoration(
                                            color: JoynColors.primary.withValues(alpha: 0.1),
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: const Icon(Icons.qr_code_scanner_rounded,
                                              size: 18, color: JoynColors.primary),
                                        ),
                                        tooltip: 'Scan Barcode',
                                        onPressed: _scanBarcodeToSearch,
                                      ),
                                      const SizedBox(width: 4),
                                    ],
                                  ),
                                  border: InputBorder.none,
                                  contentPadding: const EdgeInsets.symmetric(vertical: 13),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        _buildIconButton(Icons.swap_vert_rounded, _showSortSheet),
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

                // ITEM COUNT + STOCK VALUE
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                    child: Row(
                      children: [
                        Text(
                          '${_filteredItems.length} items',
                          style: JoynTypography.caption.copyWith(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: JoynColors.secondaryText),
                        ),
                        const Spacer(),
                        if (_items.isNotEmpty)
                          Text(
                            'Stock Value: ₹${_calculateTotalStockValue().toStringAsFixed(0)}',
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

                // MAIN LIST
                if (_isLoading)
                  SliverToBoxAdapter(child: _buildSkeletonLoader())
                else if (_filteredItems.isEmpty)
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: _buildEmptyState(activeFilterCount),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
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

          // FROSTED ACTION BAR — stays fixed while list scrolls
          _buildFrostedActionBar(),
        ],
      ),
    );
  }

  // =====================================================================
  // HELPERS
  // =====================================================================
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

  double _calculateTotalStockValue() {
    double total = 0;
    for (final item in _filteredItems) {
      total += item.stock * item.purchasePrice;
    }
    return total;
  }

  // =====================================================================
  // ITEM CARD — premium, compact
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
      onTap: () => _navigateToItemDetail(item),
      onLongPress: () => _showItemOptions(item),
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
              // Left priority stripe
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
              // Top highlight
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
                        // Item photo/icon
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
                              errorBuilder: (context, error, stackTrace) =>
                                  _buildItemIconFallback(item),
                            ),
                          )
                              : _buildItemIconFallback(item),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Flexible(
                                    child: Text(
                                      item.name,
                                      style: JoynTypography.bodyLarge.copyWith(
                                          fontSize: 13.5,
                                          fontWeight: FontWeight.w800,
                                          color: Colors.black87,
                                          letterSpacing: -0.2),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 5, vertical: 1.5),
                                    decoration: BoxDecoration(
                                      color: JoynColors.primary.withValues(alpha: 0.08),
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border.all(
                                        color: JoynColors.primary.withValues(alpha: 0.20),
                                        width: 0.8,
                                      ),
                                    ),
                                    child: Text(
                                      item.displayItemCode,
                                      style: JoynTypography.caption.copyWith(
                                        fontSize: 9.5,
                                        fontWeight: FontWeight.w800,
                                        color: JoynColors.primary,
                                        letterSpacing: 0.3,
                                      ),
                                    ),
                                  ),
                                  if (isOutOfStock)
                                    Padding(
                                      padding: const EdgeInsets.only(left: 4),
                                      child: _PulsingDot(color: JoynColors.error, size: 5),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 3),
                              Row(
                                children: [
                                  if (item.category.isNotEmpty)
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 7, vertical: 2.5),
                                      decoration: BoxDecoration(
                                        color: JoynColors.primary.withValues(alpha: 0.075),
                                        borderRadius: BorderRadius.circular(20),
                                        border: Border.all(
                                            color: JoynColors.primary.withValues(alpha: 0.14),
                                            width: 1),
                                      ),
                                      child: Text(
                                        item.category,
                                        style: JoynTypography.caption.copyWith(
                                            fontSize: 9,
                                            fontWeight: FontWeight.w700,
                                            color: JoynColors.primary),
                                      ),
                                    ),
                                  if (item.barcode.isNotEmpty) ...[
                                    const SizedBox(width: 5),
                                    Icon(Icons.qr_code_rounded,
                                        size: 10,
                                        color: JoynColors.secondaryText.withValues(alpha: 0.75)),
                                    const SizedBox(width: 3),
                                    Flexible(
                                      child: Text(
                                        item.barcode,
                                        style: JoynTypography.caption.copyWith(
                                            fontSize: 9,
                                            fontWeight: FontWeight.w600,
                                            color: JoynColors.secondaryText),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ],
                          ),
                        ),
                        // Stock badge
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
                          decoration: BoxDecoration(
                            gradient: _Premium.softGradient(stripeColor),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                                color: stripeColor.withValues(alpha: 0.28), width: 1),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            mainAxisSize: MainAxisSize.min,
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
                                      color: stripeColor.withValues(alpha: 0.85),
                                      height: 1.2,
                                      letterSpacing: 0.3)),
                            ],
                          ),
                        ),
                        const SizedBox(width: 3),
                        // Share icon
                        _Pressable(
                          onTap: () => _shareItem(item),
                          scale: 0.88,
                          borderRadius: 9,
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: JoynColors.chipBackground,
                              borderRadius: BorderRadius.circular(9),
                              border: Border.all(
                                  color: JoynColors.border.withValues(alpha: 0.5), width: 1),
                            ),
                            child: const Icon(Icons.share_outlined,
                                size: 13, color: JoynColors.primary),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    // Prices row
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
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
                            color: JoynColors.border.withValues(alpha: 0.45), width: 1),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: _buildPriceInfo(
                                'PURCHASE', '₹${item.purchasePrice.toStringAsFixed(0)}',
                                color: JoynColors.secondaryText),
                          ),
                          Container(
                              width: 1, height: 22, color: JoynColors.border.withValues(alpha: 0.5)),
                          Expanded(
                            child: _buildPriceInfo(
                                'SELLING', '₹${item.sellingPrice.toStringAsFixed(0)}',
                                color: JoynColors.primary),
                          ),
                          Container(
                              width: 1, height: 22, color: JoynColors.border.withValues(alpha: 0.5)),
                          Expanded(
                            child: _buildPriceInfo(
                                'MARGIN',
                                '₹${(item.sellingPrice - item.purchasePrice).toStringAsFixed(0)}',
                                color: (item.sellingPrice - item.purchasePrice) >= 0
                                    ? JoynColors.success
                                    : JoynColors.error,
                                alignEnd: true),
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

  Widget _buildItemIconFallback(InventoryItemModel item) {
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
        border: Border.all(color: Colors.white.withValues(alpha: 0.75), width: 1.2),
      ),
      alignment: Alignment.center,
      child: Text(
        item.name.isNotEmpty ? item.name[0].toUpperCase() : '?',
        style: JoynTypography.titleMedium.copyWith(
          fontSize: 16,
          fontWeight: FontWeight.w900,
          color: JoynColors.primary,
        ),
      ),
    );
  }

  Widget _buildPriceInfo(String label, String value,
      {required Color color, bool alignEnd = false}) {
    return Column(
      crossAxisAlignment: alignEnd ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: JoynTypography.caption.copyWith(
              fontSize: 7.5,
              fontWeight: FontWeight.w800,
              color: JoynColors.secondaryText,
              letterSpacing: 0.5),
        ),
        const SizedBox(height: 2),
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: alignEnd ? Alignment.centerRight : Alignment.centerLeft,
          child: Text(
            value,
            maxLines: 1,
            style:
            JoynTypography.bodyLarge.copyWith(fontSize: 12, fontWeight: FontWeight.w900, color: color),
          ),
        ),
      ],
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
            child: _Pressable(
              onTap: _navigateToAddItem,
              scale: 0.97,
              borderRadius: 18,
              child: Container(
                height: 54,
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
                      height: 22,
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: _Premium.topHighlight,
                          borderRadius:
                          const BorderRadius.vertical(top: Radius.circular(18)),
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
                            child: const Icon(Icons.add_rounded,
                                color: Colors.white, size: 15),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            'Add Item',
                            style: JoynTypography.bodyMedium.copyWith(
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                                fontSize: 14.5,
                                letterSpacing: 0.2),
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
      ),
    );
  }

  // =====================================================================
  // EMPTY STATE
  // =====================================================================
  Widget _buildEmptyState(int activeFilterCount) {
    final hasSearch = _searchQuery.isNotEmpty || activeFilterCount > 0;
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
                      size: 40, color: JoynColors.primary.withValues(alpha: 0.6)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Text(
            hasSearch ? 'No Items Found' : 'No Items Yet',
            style: JoynTypography.titleMedium.copyWith(
                fontSize: 18, fontWeight: FontWeight.w800, letterSpacing: -0.2),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              hasSearch
                  ? 'Try adjusting your search or filters'
                  : 'Tap "Add Item" to create your first item',
              textAlign: TextAlign.center,
              style: JoynTypography.subtitle.copyWith(
                  fontSize: 13, color: JoynColors.secondaryText, height: 1.4),
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
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
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
}