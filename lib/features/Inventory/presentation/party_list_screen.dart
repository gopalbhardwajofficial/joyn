import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/joyn_colors.dart';
import '../../../core/theme/joyn_typography.dart';
import '../../orders/models/sales_models.dart';
import '../../orders/data/sales_repository.dart';
import '../presentation/add_new_party_screen.dart';
import '../presentation/party_detail_screen.dart';
import 'package:joyn/features/Inventory/widgets/avatar.dart';
import 'package:joyn/features/Inventory/presentation/sale_form_screen.dart';
import 'package:joyn/features/Inventory/presentation/payment_in_screen.dart';
import 'package:joyn/features/orders/presentation/add_purchase_order_screen.dart';
import '../../../core/services/api_service.dart';

enum _SortOption { nameAsc, nameDesc, categoryAsc }

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

  static List<BoxShadow> heroShadow = [
    BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 6, offset: const Offset(0, 2)),
    BoxShadow(color: Colors.black.withValues(alpha: 0.10), blurRadius: 22, offset: const Offset(0, 10)),
    BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 44, offset: const Offset(0, 20)),
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
// ANIMATED REVEAL
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
// FOCUS FIELD WRAPPER
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
// HERO STATS CARD
// =====================================================================
class _HeroStatsCard extends StatelessWidget {
  const _HeroStatsCard({
    required this.totalReceivable,
    required this.totalPayable,
    required this.partyCount,
  });

  final double totalReceivable;
  final double totalPayable;
  final int partyCount;

  String _compact(double v) {
    if (v >= 10000000) return '₹${(v / 10000000).toStringAsFixed(1)}Cr';
    if (v >= 100000) return '₹${(v / 100000).toStringAsFixed(1)}L';
    if (v >= 1000) return '₹${(v / 1000).toStringAsFixed(1)}K';
    return '₹${v.toStringAsFixed(0)}';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 4, 16, 12),
      decoration: BoxDecoration(
        gradient: _Premium.deepGradient(JoynColors.primary),
        borderRadius: BorderRadius.circular(22),
        boxShadow: _Premium.heroShadow,
      ),
      child: Stack(
        children: [
          Positioned(
            top: -40,
            right: -30,
            child: Container(
              width: 140,
              height: 140,
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
          Positioned(
            bottom: -50,
            left: -30,
            child: Container(
              width: 120,
              height: 120,
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
          Positioned(
            left: 0,
            right: 0,
            top: 0,
            height: 30,
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
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                            color: Colors.white.withValues(alpha: 0.22), width: 0.8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.insights_rounded,
                              size: 11, color: Colors.white),
                          const SizedBox(width: 5),
                          Text('OVERVIEW',
                              style: JoynTypography.caption.copyWith(
                                  fontSize: 9.5,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                  letterSpacing: 1.0)),
                        ],
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.14),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.people_alt_rounded,
                              size: 11, color: Colors.white),
                          const SizedBox(width: 4),
                          Text('$partyCount',
                              style: JoynTypography.caption.copyWith(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
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
                        icon: Icons.call_received_rounded,
                        label: "You'll Get",
                        value: _compact(totalReceivable),
                      ),
                    ),
                    Container(
                        width: 1,
                        height: 42,
                        color: Colors.white.withValues(alpha: 0.18)),
                    Expanded(
                      child: _buildStat(
                        icon: Icons.call_made_rounded,
                        label: "You'll Give",
                        value: _compact(totalPayable),
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
          alignment:
          alignEnd ? Alignment.centerRight : Alignment.centerLeft,
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
  const _ActiveFilterPill({
    required this.label,
    required this.onClear,
  });

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
          border: Border.all(
              color: JoynColors.primary.withValues(alpha: 0.22), width: 1),
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
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: JoynColors.primary),
              ),
            ),
            const SizedBox(width: 5),
            Container(
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                color: JoynColors.primary.withValues(alpha: 0.16),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.close_rounded,
                  size: 10, color: JoynColors.primary),
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
class PartyListScreen extends StatefulWidget {
  const PartyListScreen({super.key});

  @override
  State<PartyListScreen> createState() => _PartyListScreenState();
}

class _PartyListScreenState extends State<PartyListScreen> {
  final SalesRepository _salesRepository = SalesRepository();

  // Controllers
  final TextEditingController _nameCtrl = TextEditingController();
  final TextEditingController _cityCtrl = TextEditingController();
  final TextEditingController _phoneCtrl = TextEditingController();

  // Dropdown values
  String? _selectedCategory;
  String? _selectedPartyType;
  String? _selectedPriority;
  _SortOption _sortOption = _SortOption.nameAsc;
  String _quickFilter = 'all'; // 'all', 'customer', 'supplier', 'toReceive', 'toPay'

  // Which filters are visible
  Set<String> _activeFilters = {'name'};

  List<PartyModel> _parties = [];
  List<PartyModel> _filteredParties = [];
  Map<String, Map<String, dynamic>> _balances = {};
  bool _isLoading = true;
  String _searchQuery = '';
  bool _searchFocused = false;

  final List<_FilterOption> _filterOptions = const [
    _FilterOption('name', 'Party Name', Icons.search_rounded),
    _FilterOption('category', 'Category', Icons.category_outlined),
    _FilterOption('type', 'Customer / Supplier', Icons.people_outline_rounded),
    _FilterOption('priority', 'Priority', Icons.flag_outlined),
    _FilterOption('city', 'City', Icons.location_city_rounded),
    _FilterOption('phone', 'Phone', Icons.phone_outlined),
    _FilterOption('sort', 'Sort By', Icons.swap_vert_rounded),
  ];

  List<String> get _availableCategories =>
      _parties.map((p) => p.category).where((c) => c.isNotEmpty).toSet().toList()
        ..sort();

  double get _totalReceivable {
    double total = 0;
    for (final entry in _balances.values) {
      final balance = (entry['balance'] as double?) ?? 0;
      final isReceivable = entry['isReceivable'] as bool? ?? true;
      if (isReceivable) total += balance;
    }
    return total;
  }

  double get _totalPayable {
    double total = 0;
    for (final entry in _balances.values) {
      final balance = (entry['balance'] as double?) ?? 0;
      final isReceivable = entry['isReceivable'] as bool? ?? true;
      if (!isReceivable) total += balance;
    }
    return total;
  }

  int get _activeFilterCount {
    int count = 0;
    if (_quickFilter != 'all') count++;
    if (_nameCtrl.text.isNotEmpty) count++;
    if (_selectedCategory != null) count++;
    if (_selectedPartyType != null) count++;
    if (_selectedPriority != null) count++;
    if (_cityCtrl.text.isNotEmpty) count++;
    if (_phoneCtrl.text.isNotEmpty) count++;
    if (_sortOption != _SortOption.nameAsc) count++;
    return count;
  }

  bool get _hasActiveFilters => _activeFilterCount > 0;

  @override
  void initState() {
    super.initState();
    _loadParties();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _cityCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadParties() async {
    try {
      final parties = await _salesRepository.getParties();
      final balances = await _salesRepository.getAllPartyBalances();
      if (!mounted) return;

      // In-memory deduplication by name so UI never shows duplicate cards
      final Map<String, PartyModel> uniqueMap = {};
      for (final p in parties) {
        final key = p.name.trim().toLowerCase();
        if (!uniqueMap.containsKey(key)) {
          uniqueMap[key] = p;
        }
      }
      final deduplicated = uniqueMap.values.toList();

      setState(() {
        _parties = deduplicated;
        _balances = balances;
        _isLoading = false;
        _applyFilters();
      });

      // Background sync from live PostgreSQL backend
      ApiService.fetchParties().then((res) async {
        final rawList = (res['parties'] ?? res['data']) as List? ?? [];
        debugPrint('Fetched ${rawList.length} parties from backend API');
        if (rawList.isNotEmpty) {
          bool updated = false;
          for (final raw in rawList) {
            final pMap = raw as Map<String, dynamic>;
            final pid = (pMap['id'] ?? pMap['party_id'] ?? '').toString();
            final pName = (pMap['name'] ?? '').toString().trim().toLowerCase();
            final alreadyExists = _parties.any((p) =>
                p.id == pid ||
                (p.name.trim().toLowerCase() == pName && pName.isNotEmpty));

            if (pid.isNotEmpty && !alreadyExists) {
              final pModel = PartyModel(
                id: pid,
                name: pMap['name']?.toString() ?? '',
                category: pMap['category']?.toString() ?? '',
                contactNumber: (pMap['contact_number'] ?? pMap['phone'] ?? '').toString(),
                email: pMap['email']?.toString() ?? '',
                address: (pMap['billing_address'] ?? pMap['address'] ?? '').toString(),
                city: pMap['city']?.toString() ?? '',
                partyType: (pMap['party_type'] ?? pMap['type'] ?? 'customer').toString(),
                priorityLevel: (pMap['priority_level'] ?? 'medium').toString(),
                photoPath: '',
                createdAt: DateTime.tryParse(pMap['created_at']?.toString() ?? '') ?? DateTime.now(),
                openingBalance: (pMap['opening_balance'] as num?)?.toDouble() ?? 0,
                balanceType: (pMap['balance_type'] ?? 'toReceive').toString(),
                creditLimit: (pMap['credit_limit'] as num?)?.toDouble() ?? 0,
                partyNumber: (pMap['party_number'] as num?)?.toInt(),
                partyCode: pMap['party_code']?.toString(),
              );
              await _salesRepository.upsertPartyFromRemote(pModel);
              updated = true;
            }
          }
          if (updated && mounted) {
            final refreshed = await _salesRepository.getParties();
            final balancesRefreshed = await _salesRepository.getAllPartyBalances();

            final Map<String, PartyModel> refMap = {};
            for (final p in refreshed) {
              final key = p.name.trim().toLowerCase();
              if (!refMap.containsKey(key)) {
                refMap[key] = p;
              }
            }

            setState(() {
              _parties = refMap.values.toList();
              _balances = balancesRefreshed;
              _applyFilters();
            });
          }
        }
      }).catchError((err) {
        debugPrint('Remote fetch parties error: $err');
      });
    } catch (e) {
      debugPrint('Error loading parties: $e');
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  void _applyFilters() {
    final sq = _searchQuery.trim().toLowerCase();
    final nameQuery = _nameCtrl.text.trim().toLowerCase();
    final cityQuery = _cityCtrl.text.trim().toLowerCase();
    final phoneQuery = _phoneCtrl.text.trim();
    final selCat = _selectedCategory?.trim().toLowerCase();
    final selType = _selectedPartyType?.trim().toLowerCase();
    final selPri = _selectedPriority?.trim().toLowerCase();

    var list = _parties.where((party) {
      final partyType = party.partyType.trim().toLowerCase();
      final partyCat = party.category.trim().toLowerCase();
      final partyPri = party.priorityLevel.trim().toLowerCase();
      final partyCity = party.city.trim().toLowerCase();
      final partyCode = party.displayPartyCode.trim().toLowerCase();

      // Quick filter tabs (treat 'both' as valid for both customer and supplier)
      if (_quickFilter == 'customer' && partyType != 'customer' && partyType != 'both') return false;
      if (_quickFilter == 'supplier' && partyType != 'supplier' && partyType != 'both') return false;
      if (_quickFilter == 'toReceive') {
        final info = _balances[party.id];
        final bal = (info?['balance'] as double?) ?? 0;
        final isRec = info?['isReceivable'] as bool? ?? true;
        if (!(bal > 0 && isRec)) return false;
      }
      if (_quickFilter == 'toPay') {
        final info = _balances[party.id];
        final bal = (info?['balance'] as double?) ?? 0;
        final isRec = info?['isReceivable'] as bool? ?? true;
        if (!(bal > 0 && !isRec)) return false;
      }

      // Search query (from main search bar)
      final matchesSearch = sq.isEmpty ||
          party.name.toLowerCase().contains(sq) ||
          partyCat.contains(sq) ||
          partyCity.contains(sq) ||
          party.contactNumber.contains(sq) ||
          partyCode.contains(sq) ||
          (party.partyNumber != null && party.partyNumber.toString().contains(sq));

      // Filter card fields
      final matchesName = nameQuery.isEmpty ||
          party.name.toLowerCase().contains(nameQuery) ||
          partyCat.contains(nameQuery) ||
          partyCode.contains(nameQuery);

      final matchesCategory = selCat == null ||
          selCat.isEmpty ||
          selCat == 'all categories' ||
          partyCat == selCat;

      final matchesType = selType == null ||
          selType.isEmpty ||
          selType == 'all' ||
          selType == 'both' ||
          partyType == selType ||
          partyType == 'both';

      final matchesPriority = selPri == null ||
          selPri.isEmpty ||
          selPri == 'all' ||
          partyPri == selPri;

      final matchesCity = cityQuery.isEmpty || partyCity.contains(cityQuery);

      final matchesPhone = phoneQuery.isEmpty ||
          party.contactNumber.contains(phoneQuery);

      return matchesSearch &&
          matchesName &&
          matchesCategory &&
          matchesType &&
          matchesPriority &&
          matchesCity &&
          matchesPhone;
    }).toList();

    switch (_sortOption) {
      case _SortOption.nameAsc:
        list.sort(
                (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
        break;
      case _SortOption.nameDesc:
        list.sort(
                (a, b) => b.name.toLowerCase().compareTo(a.name.toLowerCase()));
        break;
      case _SortOption.categoryAsc:
        list.sort((a, b) =>
            a.category.toLowerCase().compareTo(b.category.toLowerCase()));
        break;
    }

    _filteredParties = list;
  }

  void _clearAllFilters() {
    setState(() {
      _quickFilter = 'all';
      _searchQuery = '';
      _nameCtrl.clear();
      _cityCtrl.clear();
      _phoneCtrl.clear();
      _selectedCategory = null;
      _selectedPartyType = null;
      _selectedPriority = null;
      _sortOption = _SortOption.nameAsc;
      _applyFilters();
    });
  }

  Future<void> _deleteParty(PartyModel party) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text('Delete Party?',
            style: JoynTypography.titleMedium
                .copyWith(fontSize: 17, fontWeight: FontWeight.w800)),
        content: Text(
          'Remove "${party.name}" from your parties list?',
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
      await _salesRepository.deleteParty(party.id);
      _loadParties();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Party deleted successfully!'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: JoynColors.error,
            margin: const EdgeInsets.all(16),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14)),
          ),
        );
      }
    }
  }

  Future<void> _editParty(PartyModel party) async {
    HapticFeedback.lightImpact();
    final updatedData =
    await Navigator.of(context).push<Map<String, dynamic>>(
      MaterialPageRoute(
          builder: (_) => AddNewPartyScreen(existingParty: party)),
    );
    if (updatedData != null) _loadParties();
  }

  Future<void> _openPartyDetail(PartyModel party) async {
    HapticFeedback.lightImpact();
    await Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false,
        barrierColor: Colors.black.withValues(alpha: 0.15),
        transitionDuration: const Duration(milliseconds: 280),
        pageBuilder: (context, animation, secondary) =>
            PartyDetailScreen(party: party),
        transitionsBuilder: (context, animation, secondary, child) {
          final offset = Tween<Offset>(
              begin: const Offset(0, 0.10), end: Offset.zero)
              .chain(CurveTween(curve: Curves.easeOutCubic))
              .animate(animation);
          final scale = Tween<double>(begin: 0.975, end: 1.0)
              .chain(CurveTween(curve: Curves.easeOutCubic))
              .animate(animation);
          return FadeTransition(
            opacity: animation,
            child: SlideTransition(
              position: offset,
              child: ScaleTransition(scale: scale, child: child),
            ),
          );
        },
      ),
    );
    _loadParties();
  }

  // =====================================================================
  // SORT SHEET (simple)
  // =====================================================================
  void _showSortSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                  color: JoynColors.border,
                  borderRadius: BorderRadius.circular(3)),
            ),
            Text('Sort By',
                style: JoynTypography.titleMedium
                    .copyWith(fontSize: 17, fontWeight: FontWeight.w800)),
            const SizedBox(height: 8),
            _sortTile('Name (A → Z)', _SortOption.nameAsc),
            _sortTile('Name (Z → A)', _SortOption.nameDesc),
            _sortTile('Category', _SortOption.categoryAsc),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _sortTile(String label, _SortOption option) {
    final selected = _sortOption == option;
    return _Pressable(
      onTap: () {
        setState(() => _sortOption = option);
        _applyFilters();
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
              ? Border.all(
              color: JoynColors.primary.withValues(alpha: 0.20), width: 1)
              : null,
        ),
        child: Row(
          children: [
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
                child:
                const Icon(Icons.check_rounded, color: Colors.white, size: 12),
              ),
          ],
        ),
      ),
    );
  }

  // =====================================================================
  // FILTER SETTINGS SHEET (Manage Inventory style — toggles + fields)
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
                          'Toggle filters to show/hide them',
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
                              setSheetState(() {
                                if (isActive) {
                                  _activeFilters.remove(option.key);
                                  switch (option.key) {
                                    case 'name':
                                      _nameCtrl.clear();
                                      break;
                                    case 'category':
                                      _selectedCategory = null;
                                      break;
                                    case 'type':
                                      _selectedPartyType = null;
                                      break;
                                    case 'priority':
                                      _selectedPriority = null;
                                      break;
                                    case 'city':
                                      _cityCtrl.clear();
                                      break;
                                    case 'phone':
                                      _phoneCtrl.clear();
                                      break;
                                    case 'sort':
                                      _sortOption = _SortOption.nameAsc;
                                      break;
                                  }
                                } else {
                                  _activeFilters.add(option.key);
                                }
                              });
                              setState(() => _applyFilters());
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
                                        setSheetState(() {
                                          if (isActive) {
                                            _activeFilters.remove(option.key);
                                            switch (option.key) {
                                              case 'name':
                                                _nameCtrl.clear();
                                                break;
                                              case 'category':
                                                _selectedCategory = null;
                                                break;
                                              case 'type':
                                                _selectedPartyType = null;
                                                break;
                                              case 'priority':
                                                _selectedPriority = null;
                                                break;
                                              case 'city':
                                                _cityCtrl.clear();
                                                break;
                                              case 'phone':
                                                _phoneCtrl.clear();
                                                break;
                                              case 'sort':
                                                _sortOption =
                                                    _SortOption.nameAsc;
                                                break;
                                            }
                                          } else {
                                            _activeFilters.add(option.key);
                                          }
                                        });
                                        setState(() => _applyFilters());
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
                        }).toList(),
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
                            child: const Center(
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.check_rounded,
                                      color: Colors.white, size: 16),
                                  SizedBox(width: 8),
                                  Text('Done',
                                      style: TextStyle(
                                          fontWeight: FontWeight.w800,
                                          color: Colors.white,
                                          fontSize: 15)),
                                ],
                              ),
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
    ).then((_) {
      if (mounted) setState(() => _applyFilters());
    });
  }

  // =====================================================================
  // FILTER CARD IN BODY — shows active filters inline
  // =====================================================================
  Widget _buildFilterCard() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      decoration: BoxDecoration(
        gradient: _Premium.surfaceGradient,
        borderRadius: BorderRadius.circular(18),
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
                height: 20,
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
                child: const Icon(Icons.filter_alt_outlined,
                    size: 14, color: JoynColors.primary),
              ),
              const SizedBox(width: 10),
              Text('Filters',
                  style: JoynTypography.bodyLarge.copyWith(
                      fontWeight: FontWeight.w800,
                      fontSize: 15.5,
                      letterSpacing: -0.2,
                      color: Colors.black87)),
              const Spacer(),
              _Pressable(
                onTap: _showFilterSettings,
                scale: 0.9,
                borderRadius: 10,
                child: Container(
                  padding: const EdgeInsets.all(7),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                        color: JoynColors.border.withValues(alpha: 0.7),
                        width: 1),
                    boxShadow: _Premium.hairlineShadow,
                  ),
                  child: const Icon(Icons.settings_rounded,
                      size: 15, color: JoynColors.primary),
                ),
              ),
              if (_hasActiveFilters) ...[
                const SizedBox(width: 8),
                _Pressable(
                  onTap: _clearAllFilters,
                  scale: 0.94,
                  borderRadius: 10,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      gradient: _Premium.softGradient(JoynColors.error),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                          color: JoynColors.error.withValues(alpha: 0.20),
                          width: 1),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.close_rounded,
                            size: 12, color: JoynColors.error),
                        const SizedBox(width: 4),
                        Text('Clear',
                            style: JoynTypography.caption.copyWith(
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                color: JoynColors.error)),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 14),

          _AnimatedReveal(
            show: _activeFilters.contains('name'),
            child: _buildFilterField(
              label: 'Party Name',
              hint: 'Search by name or category',
              controller: _nameCtrl,
              icon: Icons.search_rounded,
              onChanged: (_) => setState(_applyFilters),
            ),
          ),
          if (_activeFilters.contains('name')) const SizedBox(height: 12),

          _AnimatedReveal(
            show: _activeFilters.contains('category'),
            child: _buildCategoryDropdown(),
          ),
          if (_activeFilters.contains('category')) const SizedBox(height: 12),

          _AnimatedReveal(
            show: _activeFilters.contains('type'),
            child: _buildDropdownField(
              label: 'Customer / Supplier',
              hint: 'Select type',
              icon: Icons.people_outline_rounded,
              value: _selectedPartyType,
              items: const ['customer', 'supplier', 'both'],
              labels: const {
                'customer': 'Customer',
                'supplier': 'Supplier',
                'both': 'Both'
              },
              onChanged: (v) => setState(() {
                _selectedPartyType = v;
                _applyFilters();
              }),
            ),
          ),
          if (_activeFilters.contains('type')) const SizedBox(height: 12),

          _AnimatedReveal(
            show: _activeFilters.contains('priority'),
            child: _buildDropdownField(
              label: 'Priority',
              hint: 'Select priority',
              icon: Icons.flag_outlined,
              value: _selectedPriority,
              items: const ['high', 'medium', 'low'],
              labels: const {
                'high': 'High',
                'medium': 'Medium',
                'low': 'Low'
              },
              onChanged: (v) => setState(() {
                _selectedPriority = v;
                _applyFilters();
              }),
            ),
          ),
          if (_activeFilters.contains('priority')) const SizedBox(height: 12),

          _AnimatedReveal(
            show: _activeFilters.contains('city'),
            child: _buildFilterField(
              label: 'City',
              hint: 'Search by city',
              controller: _cityCtrl,
              icon: Icons.location_city_rounded,
              onChanged: (_) => setState(_applyFilters),
            ),
          ),
          if (_activeFilters.contains('city')) const SizedBox(height: 12),

          _AnimatedReveal(
            show: _activeFilters.contains('phone'),
            child: _buildFilterField(
              label: 'Phone',
              hint: 'Search by phone number',
              controller: _phoneCtrl,
              icon: Icons.phone_outlined,
              keyboardType: TextInputType.phone,
              onChanged: (_) => setState(_applyFilters),
            ),
          ),
          if (_activeFilters.contains('phone')) const SizedBox(height: 12),

          _AnimatedReveal(
            show: _activeFilters.contains('sort'),
            child: _buildDropdownField<_SortOption>(
              label: 'Sort By',
              hint: 'Name A → Z',
              icon: Icons.swap_vert_rounded,
              value: _sortOption,
              items: const [
                _SortOption.nameAsc,
                _SortOption.nameDesc,
                _SortOption.categoryAsc
              ],
              labels: const {
                _SortOption.nameAsc: 'Name (A → Z)',
                _SortOption.nameDesc: 'Name (Z → A)',
                _SortOption.categoryAsc: 'Category',
              },
              onChanged: (v) => setState(() {
                if (v != null) _sortOption = v;
                _applyFilters();
              }),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterField({
    required String label,
    required String hint,
    required TextEditingController controller,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    required ValueChanged<String> onChanged,
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
              onChanged: onChanged,
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
                  onPressed: () {
                    controller.clear();
                    onChanged('');
                  },
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

  Widget _buildDropdownField<T>({
    required String label,
    required String hint,
    required IconData icon,
    required T? value,
    required List<T> items,
    required Map<T, String> labels,
    required ValueChanged<T?> onChanged,
  }) {
    return Column(
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
                child: Icon(icon, size: 13, color: JoynColors.primary),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<T?>(
                    value: value,
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
                    hint: Text(hint,
                        style: JoynTypography.bodyMedium.copyWith(
                            color:
                            JoynColors.secondaryText.withValues(alpha: 0.5),
                            fontSize: 13.5)),
                    items: [
                      DropdownMenuItem<T?>(
                        value: null,
                        child: Text('All',
                            style: JoynTypography.bodyLarge.copyWith(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w700,
                                color: Colors.black87)),
                      ),
                      ...items.map((item) => DropdownMenuItem<T?>(
                        value: item,
                        child: Text(labels[item] ?? item.toString()),
                      )),
                    ],
                    onChanged: onChanged,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
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
        centerTitle: true,
        title: Text('Parties',
            style: JoynTypography.titleMedium.copyWith(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.3)),
        actions: [
          _Pressable(
            onTap: () async {
              HapticFeedback.lightImpact();
              await Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const AddNewPartyScreen()),
              );
              _loadParties();
            },
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
              child: const Icon(Icons.person_add_alt_1_rounded,
                  size: 17, color: Colors.white),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // ✅ SCROLLABLE CONTENT
            Expanded(
              child: RefreshIndicator(
                onRefresh: _loadParties,
                color: JoynColors.primary,
                backgroundColor: Colors.white,
                strokeWidth: 2.6,
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(
                      parent: BouncingScrollPhysics()),
                  padding: const EdgeInsets.only(bottom: 20),
                  children: [
                    // HERO STATS
                    if (!_isLoading && _parties.isNotEmpty)
                      _StaggeredItem(
                        index: 0,
                        child: _HeroStatsCard(
                          totalReceivable: _totalReceivable,
                          totalPayable: _totalPayable,
                          partyCount: _parties.length,
                        ),
                      ),

                    // ✅ SEARCH BAR ROW (SAME AS BEFORE)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
                      child: Row(
                        children: [
                          Expanded(
                            child: Focus(
                              onFocusChange: (focused) =>
                                  setState(() => _searchFocused = focused),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                height: 50,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(15),
                                  border: Border.all(
                                    color: _searchFocused
                                        ? JoynColors.primary
                                        .withValues(alpha: 0.55)
                                        : JoynColors.border
                                        .withValues(alpha: 0.75),
                                    width: _searchFocused ? 1.5 : 1.1,
                                  ),
                                  boxShadow: _searchFocused
                                      ? [
                                    BoxShadow(
                                        color: JoynColors.primary
                                            .withValues(alpha: 0.14),
                                        blurRadius: 16,
                                        offset: const Offset(0, 5)),
                                    ..._Premium.softShadow,
                                  ]
                                      : _Premium.softShadow,
                                ),
                                child: TextField(
                                  onChanged: (value) => setState(() {
                                    _searchQuery = value;
                                    _applyFilters();
                                  }),
                                  style: JoynTypography.bodyMedium.copyWith(
                                      fontSize: 13.5,
                                      fontWeight: FontWeight.w600),
                                  decoration: InputDecoration(
                                    hintText:
                                    'Search by name, category, phone...',
                                    hintStyle:
                                    JoynTypography.bodyMedium.copyWith(
                                        color: JoynColors.secondaryText
                                            .withValues(alpha: 0.5),
                                        fontSize: 13.5,
                                        fontWeight: FontWeight.w500),
                                    prefixIcon: Padding(
                                      padding: const EdgeInsets.only(
                                          left: 6, right: 4),
                                      child: Container(
                                        margin: const EdgeInsets.all(9),
                                        decoration: BoxDecoration(
                                          gradient: _Premium.softGradient(
                                              JoynColors.primary),
                                          borderRadius:
                                          BorderRadius.circular(9),
                                        ),
                                        child: const Icon(
                                            Icons.search_rounded,
                                            size: 16,
                                            color: JoynColors.primary),
                                      ),
                                    ),
                                    suffixIcon: _searchQuery.isNotEmpty
                                        ? IconButton(
                                      icon: Container(
                                        padding:
                                        const EdgeInsets.all(3),
                                        decoration: BoxDecoration(
                                          color:
                                          JoynColors.chipBackground,
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(
                                            Icons.clear_rounded,
                                            size: 12,
                                            color: JoynColors
                                                .secondaryText),
                                      ),
                                      onPressed: () => setState(() {
                                        _searchQuery = '';
                                        _applyFilters();
                                      }),
                                    )
                                        : null,
                                    border: InputBorder.none,
                                    contentPadding:
                                    const EdgeInsets.symmetric(
                                        vertical: 13),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          _buildIconButton(
                              Icons.swap_vert_rounded, _showSortSheet),
                          const SizedBox(width: 10),
                          _buildIconButton(
                            Icons.tune_rounded,
                            _showFilterSettings,
                            badge: _activeFilterCount > 0,
                            countBadge: _activeFilterCount,
                          ),
                        ],
                      ),
                    ),

                    // QUICK FILTER CHIPS
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 2, 16, 6),
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        physics: const BouncingScrollPhysics(),
                        child: Row(
                          children: [
                            _buildQuickFilterChip('All', _quickFilter == 'all', () {
                              setState(() {
                                _quickFilter = 'all';
                                _applyFilters();
                              });
                            }),
                            const SizedBox(width: 8),
                            _buildQuickFilterChip('Customers', _quickFilter == 'customer', () {
                              setState(() {
                                _quickFilter = 'customer';
                                _applyFilters();
                              });
                            }),
                            const SizedBox(width: 8),
                            _buildQuickFilterChip('Suppliers', _quickFilter == 'supplier', () {
                              setState(() {
                                _quickFilter = 'supplier';
                                _applyFilters();
                              });
                            }),
                            const SizedBox(width: 8),
                            _buildQuickFilterChip('To Receive', _quickFilter == 'toReceive', () {
                              setState(() {
                                _quickFilter = 'toReceive';
                                _applyFilters();
                              });
                            }),
                            const SizedBox(width: 8),
                            _buildQuickFilterChip('To Pay', _quickFilter == 'toPay', () {
                              setState(() {
                                _quickFilter = 'toPay';
                                _applyFilters();
                              });
                            }),
                          ],
                        ),
                      ),
                    ),

                    // FILTER CARD (below search, shows active filter fields)
                    if (_activeFilters.isNotEmpty &&
                        (_activeFilters.length > 1 ||
                            _activeFilters.contains('category') ||
                            _activeFilters.contains('type') ||
                            _activeFilters.contains('priority') ||
                            _activeFilters.contains('city') ||
                            _activeFilters.contains('phone') ||
                            _activeFilters.contains('sort')))
                      _StaggeredItem(
                        index: 1,
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                          child: _buildFilterCard(),
                        ),
                      ),

                    // RESULTS COUNT
                    if (!_isLoading)
                      Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 4),
                        child: Text(
                          '${_filteredParties.length} parties found',
                          style: JoynTypography.caption.copyWith(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: JoynColors.secondaryText),
                        ),
                      ),

                    const SizedBox(height: 4),

                    // SKELETON / EMPTY / LIST
                    if (_isLoading)
                      _buildSkeletonContent()
                    else if (_filteredParties.isEmpty)
                      SizedBox(height: 400, child: _buildEmptyState())
                    else
                      ...List.generate(
                        _filteredParties.length,
                            (index) => _StaggeredItem(
                          index: index + 3,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16),
                            child: _buildPartyCard(
                                _filteredParties[index], index),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),

            // ✅ FIXED BOTTOM ACTION BAR
            _buildFrostedActionBar(),
          ],
        ),
      ),
    );
  }

  // =====================================================================
  // QUICK FILTER CHIP
  // =====================================================================
  Widget _buildQuickFilterChip(String label, bool selected, VoidCallback onTap) {
    return _Pressable(
      onTap: onTap,
      scale: 0.95,
      borderRadius: 20,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          gradient: selected ? _Premium.gradient(JoynColors.primary) : null,
          color: selected ? null : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected
                ? JoynColors.primary
                : JoynColors.border.withValues(alpha: 0.8),
            width: selected ? 1.4 : 1.0,
          ),
          boxShadow: selected
              ? _Premium.chipShadow(JoynColors.primary)
              : _Premium.hairlineShadow,
        ),
        child: Text(
          label,
          style: JoynTypography.caption.copyWith(
            fontSize: 12,
            fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
            color: selected ? Colors.white : Colors.black87,
          ),
        ),
      ),
    );
  }

  // =====================================================================
  // ICON BUTTON
  // =====================================================================
  Widget _buildIconButton(
      IconData icon,
      VoidCallback onTap, {
        bool badge = false,
        int? countBadge,
      }) {
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
          border: Border.all(
              color: JoynColors.border.withValues(alpha: 0.8), width: 1),
          boxShadow: _Premium.softShadow,
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Icon(icon, size: 20, color: JoynColors.primary),
            if (badge && countBadge != null && countBadge > 0)
              Positioned(
                top: 6,
                right: 6,
                child: Container(
                  padding:
                  const EdgeInsets.symmetric(horizontal: 4.5, vertical: 1.5),
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

  // =====================================================================
  // SKELETON CONTENT
  // =====================================================================
  Widget _buildSkeletonContent() {
    return Column(
      children: List.generate(
        5,
            (index) => Container(
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
          padding: const EdgeInsets.fromLTRB(14, 10, 10, 10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: _Premium.hairline(width: 1.0, alpha: 0.7),
            boxShadow: _Premium.hairlineShadow,
          ),
          child: Row(
            children: [
              const _ShimmerBox(width: 42, height: 42, borderRadius: 14),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    _ShimmerBox(width: 120, height: 12, borderRadius: 6),
                    SizedBox(height: 6),
                    _ShimmerBox(width: 80, height: 10, borderRadius: 6),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: const [
                  _ShimmerBox(width: 50, height: 12, borderRadius: 6),
                  SizedBox(height: 4),
                  _ShimmerBox(width: 30, height: 9, borderRadius: 6),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // =====================================================================
  // PARTY AVATAR
  // =====================================================================
  Widget _buildPartyAvatar(PartyModel party, {double size = 50}) {
    if (party.photoPath.isNotEmpty && File(party.photoPath).existsSync()) {
      return Container(
        width: size,
        height: size,
        padding: const EdgeInsets.all(1.8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(size * 0.32),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.white,
              JoynColors.border.withValues(alpha: 0.5),
            ],
          ),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: 0.06),
                blurRadius: 10,
                offset: const Offset(0, 3)),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(size * 0.28),
          child: Image.file(File(party.photoPath), fit: BoxFit.cover),
        ),
      );
    }

    if (party.avatarIndex != null &&
        party.avatarIndex! >= 0 &&
        party.avatarIndex! < kPartyAvatarOptions.length) {
      final option = kPartyAvatarOptions[party.avatarIndex!];
      return Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          gradient: LinearGradient(
              colors: option.gradient,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight),
          borderRadius: BorderRadius.circular(size * 0.32),
          border: Border.all(
              color: Colors.white.withValues(alpha: 0.85), width: 1.6),
          boxShadow: [
            BoxShadow(
                color: option.gradient.last.withValues(alpha: 0.30),
                blurRadius: 12,
                offset: const Offset(0, 4)),
            BoxShadow(
                color: option.gradient.last.withValues(alpha: 0.15),
                blurRadius: 20,
                offset: const Offset(0, 8)),
          ],
        ),
        alignment: Alignment.center,
        child: Text(option.emoji, style: TextStyle(fontSize: size * 0.46)),
      );
    }

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            JoynColors.primary.withValues(alpha: 0.14),
            JoynColors.primary.withValues(alpha: 0.26),
          ],
        ),
        borderRadius: BorderRadius.circular(size * 0.32),
        border: Border.all(
            color: Colors.white.withValues(alpha: 0.75), width: 1.6),
        boxShadow: [
          BoxShadow(
              color: JoynColors.primary.withValues(alpha: 0.14),
              blurRadius: 10,
              offset: const Offset(0, 3)),
        ],
      ),
      alignment: Alignment.center,
      child: Text(
        party.name.isNotEmpty ? party.name[0].toUpperCase() : '?',
        style: JoynTypography.titleMedium.copyWith(
            fontSize: size * 0.42,
            fontWeight: FontWeight.w800,
            color: JoynColors.primary),
      ),
    );
  }

  Color _priorityStripeColor(PartyModel party) {
    switch (party.priorityLevel) {
      case 'high':
        return JoynColors.error;
      case 'low':
        return JoynColors.success;
      default:
        return const Color(0xFFF59E0B);
    }
  }

  // =====================================================================
  // PARTY CARD
  // =====================================================================
  Widget _buildPartyCard(PartyModel party, int index) {
    final stripeColor = _priorityStripeColor(party);
    final info = _balances[party.id];
    final balance = (info?['balance'] as double?) ?? 0;
    final isReceivable = info?['isReceivable'] as bool? ?? true;
    final balColor = balance <= 0
        ? JoynColors.success
        : (isReceivable ? JoynColors.success : JoynColors.error);

    return _Pressable(
      onTap: () => _openPartyDetail(party),
      scale: 0.985,
      borderRadius: 16,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: _Premium.hairline(width: 1.0, alpha: 0.7),
          boxShadow: _Premium.hairlineShadow,
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
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 10, 10, 10),
                child: Row(
                  children: [
                    _buildPartyAvatar(party, size: 42),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  party.name,
                                  style: JoynTypography.bodyLarge.copyWith(
                                      fontSize: 14,
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
                                    horizontal: 6, vertical: 1.5),
                                decoration: BoxDecoration(
                                  color: JoynColors.primary.withValues(alpha: 0.08),
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(
                                    color: JoynColors.primary.withValues(alpha: 0.20),
                                    width: 0.8,
                                  ),
                                ),
                                child: Text(
                                  party.displayPartyCode,
                                  style: JoynTypography.caption.copyWith(
                                    fontSize: 9.5,
                                    fontWeight: FontWeight.w800,
                                    color: JoynColors.primary,
                                    letterSpacing: 0.3,
                                  ),
                                ),
                              ),
                              if (party.priorityLevel == 'high')
                                Padding(
                                  padding: const EdgeInsets.only(left: 4),
                                  child: _PulsingDot(
                                      color: JoynColors.error, size: 5),
                                ),
                            ],
                          ),
                          const SizedBox(height: 3),
                          Row(
                            children: [
                              if (party.category.isNotEmpty) ...[
                                Flexible(
                                  child: Text(
                                    party.category,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: JoynTypography.caption.copyWith(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        color: JoynColors.primary),
                                  ),
                                ),
                                if (party.contactNumber.isNotEmpty)
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 6),
                                    child: Text('•',
                                        style: TextStyle(
                                            fontSize: 11,
                                            color: JoynColors.secondaryText
                                                .withValues(alpha: 0.5))),
                                  ),
                              ],
                              if (party.contactNumber.isNotEmpty)
                                Flexible(
                                  child: Text(
                                    party.contactNumber,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: JoynTypography.caption.copyWith(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w500,
                                        color: JoynColors.secondaryText),
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          balance <= 0
                              ? '₹0'
                              : '₹${balance.toStringAsFixed(0)}',
                          style: JoynTypography.bodyMedium.copyWith(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w800,
                              color: balColor),
                        ),
                        const SizedBox(height: 1),
                        Text(
                          balance <= 0
                              ? 'Settled'
                              : (isReceivable ? 'Get' : 'Give'),
                          style: JoynTypography.caption.copyWith(
                              fontSize: 9.5,
                              fontWeight: FontWeight.w700,
                              color: balColor.withValues(alpha: 0.85),
                              letterSpacing: 0.2),
                        ),
                      ],
                    ),
                    const SizedBox(width: 4),
                    Icon(Icons.chevron_right_rounded,
                        size: 18,
                        color: JoynColors.secondaryText
                            .withValues(alpha: 0.55)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // =====================================================================
  // BOTTOM ACTION BAR
  // =====================================================================
  Widget _buildFrostedActionBar() {
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Container(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 16),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.72),
            border: Border(
              top: BorderSide(
                  color: JoynColors.border.withValues(alpha: 0.6), width: 1),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Expanded(
                    child: _buildBottomActionButton(
                      label: 'Take Payment',
                      icon: Icons.call_received_rounded,
                      color: JoynColors.success,
                      onTap: _openTakePaymentGeneric,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildBottomActionButton(
                      label: 'Add Sale',
                      icon: Icons.point_of_sale_rounded,
                      color: JoynColors.primary,
                      onTap: _openAddSaleGeneric,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildBottomActionButton(
                      label: 'Add Purchase',
                      icon: Icons.shopping_cart_checkout_rounded,
                      color: JoynColors.primary,
                      onTap: _openAddPurchaseGeneric,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildBottomActionButton(
                      label: 'Make Payment',
                      icon: Icons.call_made_rounded,
                      color: JoynColors.error,
                      onTap: _openMakePaymentGeneric,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBottomActionButton({
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return _Pressable(
      onTap: onTap,
      scale: 0.96,
      borderRadius: 18,
      child: Container(
        decoration: BoxDecoration(
          gradient: _Premium.gradient(color),
          borderRadius: BorderRadius.circular(18),
          boxShadow: _Premium.chipShadow(color),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 13, horizontal: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(5),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.22),
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Icon(icon, color: Colors.white, size: 14),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: JoynTypography.bodyMedium.copyWith(
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      fontSize: 12.5,
                      letterSpacing: 0.2),
                ),
              ),
            ],
          ),
        ),
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
            width: 140,
            height: 140,
            child: Stack(
              alignment: Alignment.center,
              children: [
                _PulsingDot(color: JoynColors.primary, size: 40),
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
                  child: Icon(Icons.people_outline_rounded,
                      size: 42,
                      color: JoynColors.primary.withValues(alpha: 0.65)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Text('No Parties Found',
              style: JoynTypography.titleMedium.copyWith(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.2)),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              'Try adjusting your search filters or add a new party below',
              textAlign: TextAlign.center,
              style: JoynTypography.subtitle.copyWith(
                  fontSize: 13,
                  color: JoynColors.secondaryText,
                  height: 1.4),
            ),
          ),
          const SizedBox(height: 18),
          _Pressable(
            onTap: () async {
              HapticFeedback.lightImpact();
              await Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const AddNewPartyScreen()),
              );
              _loadParties();
            },
            borderRadius: 14,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 11),
              decoration: BoxDecoration(
                gradient: _Premium.gradient(JoynColors.primary),
                borderRadius: BorderRadius.circular(14),
                boxShadow: _Premium.chipShadow(JoynColors.primary),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.add_rounded, color: Colors.white, size: 18),
                  const SizedBox(width: 8),
                  Text(
                    'Add New Party',
                    style: JoynTypography.bodyMedium.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
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

  // =====================================================================
  // NAVIGATION ACTIONS
  // =====================================================================
  Future<void> _openTakePayment(PartyModel party) async {
    HapticFeedback.lightImpact();
    final saved = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => PaymentInScreen(party: party)),
    );
    if (saved == true) _loadParties();
  }

  Future<void> _openAddSale(PartyModel party) async {
    HapticFeedback.lightImpact();
    final saved = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => SaleFormScreen(party: party)),
    );
    if (saved == true) _loadParties();
  }

  Future<void> _openAddPurchase(PartyModel party) async {
    HapticFeedback.lightImpact();
    final saved = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
          builder: (_) => AddPurchaseOrderScreen(initialParty: party)),
    );
    if (saved == true) _loadParties();
  }

  Future<void> _openMakePayment(PartyModel party) async {
    HapticFeedback.lightImpact();
    final saved = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
          builder: (_) => PaymentInScreen(party: party, isPaymentOut: true)),
    );
    if (saved == true) _loadParties();
  }

  Future<void> _pickPartyThen(void Function(PartyModel party) onPicked) async {
    if (_parties.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('No parties available. Add a party first.'),
          behavior: SnackBarBehavior.floating,
          shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
      );
      return;
    }

    final party = await showModalBottomSheet<PartyModel>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (context) => SafeArea(
        child: Padding(
          padding:
          EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
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
              Text('Select Party',
                  style: JoynTypography.titleMedium
                      .copyWith(fontSize: 17, fontWeight: FontWeight.w800)),
              const SizedBox(height: 8),
              ConstrainedBox(
                constraints: BoxConstraints(
                    maxHeight: MediaQuery.of(context).size.height * 0.5),
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: _parties.length,
                  itemBuilder: (context, index) {
                    final p = _parties[index];
                    return ListTile(
                      leading: _buildPartyAvatar(p, size: 40),
                      title: Text(p.name,
                          style: JoynTypography.bodyLarge.copyWith(
                              fontSize: 14.5, fontWeight: FontWeight.w700)),
                      subtitle: p.category.isNotEmpty
                          ? Text(p.category,
                          style: JoynTypography.caption.copyWith(
                              fontSize: 11.5,
                              color: JoynColors.secondaryText))
                          : null,
                      trailing: const Icon(Icons.chevron_right_rounded,
                          size: 20, color: JoynColors.secondaryText),
                      onTap: () => Navigator.pop(context, p),
                    );
                  },
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );

    if (party != null) onPicked(party);
  }

  void _openTakePaymentGeneric() {
    HapticFeedback.lightImpact();
    _pickPartyThen(_openTakePayment);
  }

  void _openAddSaleGeneric() {
    HapticFeedback.lightImpact();
    _pickPartyThen(_openAddSale);
  }

  void _openAddPurchaseGeneric() {
    HapticFeedback.lightImpact();
    _pickPartyThen(_openAddPurchase);
  }

  void _openMakePaymentGeneric() {
    HapticFeedback.lightImpact();
    _pickPartyThen(_openMakePayment);
  }
}