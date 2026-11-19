// lib/features/orders/presentation/purchase_orders_list_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/joyn_colors.dart';
import '../../../core/theme/joyn_typography.dart';
import '../../../core/router/route_observer.dart';
import '../models/sales_models.dart';
import '../data/sales_repository.dart';
import 'add_purchase_order_screen.dart';
import 'purchase_order_detail_screen.dart';
import 'widgets/order_filter_widgets.dart';
import 'widgets/order_list_widgets.dart';

enum _SortOption { dateDesc, dateAsc, amountHigh, amountLow, partyAsc }

const Color _warningColor = Color(0xFFF59E0B);

// ==================== Main Screen ====================
class PurchaseOrdersListScreen extends StatefulWidget {
  const PurchaseOrdersListScreen({super.key});

  @override
  State<PurchaseOrdersListScreen> createState() =>
      _PurchaseOrdersListScreenState();
}

class _PurchaseOrdersListScreenState extends State<PurchaseOrdersListScreen>
    with RouteAware {
  final SalesRepository _salesRepository = SalesRepository();
  List<PurchaseOrderModel> _orders = [];
  List<PurchaseOrderModel> _filteredOrders = [];
  bool _isLoading = true;

  _SortOption _sortOption = _SortOption.dateDesc;

  // Filters — settings (⚙) se toggle hote hain, default mein sirf Party Name on hai
  static const List<OrderFilterDef> _filterDefs = [
    OrderFilterDef(
      key: 'name',
      label: 'Party Name',
      shortLabel: 'Party',
      icon: Icons.storefront_outlined,
      type: OrderFilterType.text,
      hint: 'Search by party name',
    ),
    OrderFilterDef(
      key: 'order',
      label: 'Order No',
      shortLabel: 'Order',
      icon: Icons.tag_rounded,
      type: OrderFilterType.text,
      hint: 'Search by order no',
      keyboard: TextInputType.number,
    ),
    OrderFilterDef(
      key: 'status',
      label: 'Due Status',
      shortLabel: 'Status',
      icon: Icons.warning_amber_rounded,
      type: OrderFilterType.choice,
      choices: ['Overdue', 'Upcoming'],
      allLabel: 'All Orders',
    ),
    OrderFilterDef(
      key: 'date',
      label: 'Order Date',
      shortLabel: 'Date',
      icon: Icons.calendar_today_rounded,
      type: OrderFilterType.dateRange,
    ),
    OrderFilterDef(
      key: 'due',
      label: 'Due Date',
      shortLabel: 'Due',
      icon: Icons.event_available_outlined,
      type: OrderFilterType.dateRange,
    ),
    OrderFilterDef(
      key: 'amount',
      label: 'Amount Range',
      icon: Icons.currency_rupee_rounded,
      type: OrderFilterType.amountRange,
    ),
  ];

  late final OrderFilters _filters =
  OrderFilters(_filterDefs, initialActive: {'name'});

  double get _totalAmount =>
      _filteredOrders.fold(0.0, (s, o) => s + o.totalAmount);

  int get _dueOrders => _filteredOrders.where((o) {
    final due = _parseDate(o.dueDate);
    return due.isBefore(DateTime.now());
  }).length;

  @override
  void initState() {
    super.initState();
    _filters.addListener(_onFiltersChanged);
    _loadOrders();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final route = ModalRoute.of(context);
    if (route != null) {
      routeObserver.subscribe(this, route);
    }
  }

  @override
  void dispose() {
    routeObserver.unsubscribe(this);
    _filters.removeListener(_onFiltersChanged);
    _filters.dispose();
    super.dispose();
  }

  // ✅ Jab bhi detail/add screen se wapas aayenge, list reload hogi
  @override
  void didPopNext() {
    debugPrint('Purchase list: didPopNext → reloading');
    _loadOrders();
  }

  void _onFiltersChanged() {
    if (!mounted) return;
    setState(_applyFilters);
  }

  Future<void> _loadOrders() async {
    try {
      final orders = await _salesRepository.getPurchaseOrders();
      if (!mounted) return;
      setState(() {
        _orders = orders;
        _isLoading = false;
        _applyFilters();
      });

      // Background cloud sync
      _salesRepository.syncPurchaseOrdersFromCloud().then((cloudOrders) {
        if (mounted && cloudOrders.isNotEmpty) {
          setState(() {
            _orders = cloudOrders;
            _applyFilters();
          });
        }
      }).catchError((_) {});
    } catch (e) {
      debugPrint('Error loading orders: $e');
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  void _applyFilters() {
    final nameQ = _filters.textQuery('name');
    final orderQ = _filters.textQuery('order');
    final status = _filters.choiceOf('status');
    final dateRange = _filters.rangeOf('date');
    final dueRange = _filters.rangeOf('due');
    final minAmt = _filters.minOf('amount');
    final maxAmt = _filters.maxOf('amount');
    final now = DateTime.now();

    final list = _orders.where((o) {
      if (nameQ.isNotEmpty && !o.partyName.toLowerCase().contains(nameQ)) {
        return false;
      }
      if (orderQ.isNotEmpty && !o.orderNo.toString().contains(orderQ)) {
        return false;
      }

      final due = _parseDate(o.dueDate);
      if (status == 'Overdue' && !due.isBefore(now)) return false;
      if (status == 'Upcoming' && due.isBefore(now)) return false;

      if (dateRange != null &&
          !OrderFilters.inDateRange(_parseDate(o.date), dateRange)) {
        return false;
      }
      if (dueRange != null && !OrderFilters.inDateRange(due, dueRange)) {
        return false;
      }
      if (minAmt != null && o.totalAmount < minAmt) return false;
      if (maxAmt != null && o.totalAmount > maxAmt) return false;
      return true;
    }).toList();

    switch (_sortOption) {
      case _SortOption.dateDesc:
        list.sort((a, b) => _parseDate(b.date).compareTo(_parseDate(a.date)));
        break;
      case _SortOption.dateAsc:
        list.sort((a, b) => _parseDate(a.date).compareTo(_parseDate(b.date)));
        break;
      case _SortOption.amountHigh:
        list.sort((a, b) => b.totalAmount.compareTo(a.totalAmount));
        break;
      case _SortOption.amountLow:
        list.sort((a, b) => a.totalAmount.compareTo(b.totalAmount));
        break;
      case _SortOption.partyAsc:
        list.sort((a, b) =>
            a.partyName.toLowerCase().compareTo(b.partyName.toLowerCase()));
        break;
    }

    _filteredOrders = list;
  }

  DateTime _parseDate(String dateStr) {
    try {
      final parts = dateStr.split('/');
      if (parts.length == 3) {
        return DateTime(
            int.parse(parts[2]), int.parse(parts[1]), int.parse(parts[0]));
      }
    } catch (_) {}
    return DateTime.now();
  }

  Future<void> _openDetail(PurchaseOrderModel order) async {
    HapticFeedback.lightImpact();
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => PurchaseOrderDetailScreen(
          order: order,
          onChanged: _loadOrders,
        ),
      ),
    );
    _loadOrders();
  }

  void _comingSoon(String what) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$what coming soon'),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    );
  }

  Future<void> _deleteOrder(PurchaseOrderModel order) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Text('Delete Purchase Order?',
            style: JoynTypography.titleMedium
                .copyWith(fontSize: 17, fontWeight: FontWeight.w700)),
        content: Text(
          'Delete Order #${order.orderNo} for ${order.partyName}?',
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
      await _salesRepository.deletePurchaseOrder(order.id);
      _loadOrders();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Purchase order deleted successfully!'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: JoynColors.error,
            margin: const EdgeInsets.all(16),
            shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
        );
      }
    }
  }

  // ==================== Sort Sheet ====================
  void _showSortSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: JoynColors.background,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(
              width: 44,
              height: 4,
              decoration: BoxDecoration(
                  color: JoynColors.border,
                  borderRadius: BorderRadius.circular(3)),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Text('Sort By',
                  style: JoynTypography.titleMedium
                      .copyWith(fontSize: 18, fontWeight: FontWeight.w800)),
            ),
            const Divider(height: 1, color: Color(0xFFF1F5F9)),
            _buildSortTile('Date (Newest First)', Icons.calendar_today_rounded,
                _SortOption.dateDesc),
            _buildSortTile('Date (Oldest First)', Icons.calendar_today_rounded,
                _SortOption.dateAsc),
            _buildSortTile('Amount (High to Low)',
                Icons.currency_rupee_rounded, _SortOption.amountHigh),
            _buildSortTile('Amount (Low to High)',
                Icons.currency_rupee_rounded, _SortOption.amountLow),
            _buildSortTile('Party Name (A-Z)', Icons.sort_by_alpha_rounded,
                _SortOption.partyAsc),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _buildSortTile(String label, IconData icon, _SortOption option) {
    final selected = _sortOption == option;
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: selected ? OrderUi.infoSoft : JoynColors.chipBackground,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon,
            size: 18,
            color: selected ? JoynColors.primary : JoynColors.secondaryText),
      ),
      title: Text(
        label,
        style: JoynTypography.bodyLarge.copyWith(
          fontSize: 14.5,
          fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
          color: selected ? JoynColors.primary : Colors.black87,
        ),
      ),
      trailing: selected
          ? Container(
        padding: const EdgeInsets.all(3),
        decoration: BoxDecoration(
          gradient: OrderUi.primaryGrad,
          shape: BoxShape.circle,
        ),
        child: const Icon(Icons.check, color: Colors.white, size: 14),
      )
          : null,
      onTap: () {
        setState(() {
          _sortOption = option;
          _applyFilters();
        });
        Navigator.pop(context);
      },
    );
  }

  // ==================== Build ====================
  @override
  Widget build(BuildContext context) {
    final hasFilter = _filters.hasValues;

    final subtitle = '${_filteredOrders.length} orders  •  '
        '₹${_totalAmount.toStringAsFixed(0)}'
        '${_dueOrders > 0 ? '  •  $_dueOrders overdue' : ''}';

    return Scaffold(
      backgroundColor: JoynColors.background,
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            Expanded(
              child: RefreshIndicator(
                onRefresh: _loadOrders,
                color: JoynColors.primary,
                edgeOffset: MediaQuery.of(context).padding.top,
                // Poori screen ek hi scroll view — header + filters + list saath scroll
                child: CustomScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  keyboardDismissBehavior:
                  ScrollViewKeyboardDismissBehavior.onDrag,
                  slivers: [
                    SliverToBoxAdapter(
                      child: OrderListHeader(
                        title: 'Purchase Orders',
                        subtitle: subtitle,
                        onBack: () => context.pop(),
                        onSort: _showSortSheet,
                        onFilterSettings: () =>
                            showOrderFilterSettings(context, _filters),
                        filterActive: hasFilter,
                      ),
                    ),
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
                        child: OrderFilterCard(filters: _filters),
                      ),
                    ),
                    SliverToBoxAdapter(
                      child: OrderActiveFilterPills(filters: _filters),
                    ),
                    if (_isLoading)
                      const SliverFillRemaining(
                        hasScrollBody: false,
                        child: Center(
                          child: CircularProgressIndicator(
                              color: JoynColors.primary),
                        ),
                      )
                    else if (_filteredOrders.isEmpty)
                      SliverFillRemaining(
                        hasScrollBody: false,
                        child: OrderEmptyState(
                          icon: Icons.shopping_cart_outlined,
                          title: hasFilter
                              ? 'No Orders Found'
                              : 'No Purchase Orders Yet',
                          subtitle: hasFilter
                              ? 'Try adjusting your filters'
                              : 'Tap "Add Purchase Order" to create your first order',
                        ),
                      )
                    else
                      SliverPadding(
                        padding: const EdgeInsets.fromLTRB(16, 6, 16, 16),
                        sliver: SliverList(
                          delegate: SliverChildBuilderDelegate(
                                (context, index) {
                              final order = _filteredOrders[index];
                              return AnimatedEntry(
                                delayMs: (index.clamp(0, 6)) * 40,
                                child: _buildOrderCard(order),
                              );
                            },
                            childCount: _filteredOrders.length,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            _buildBottomBar(),
          ],
        ),
      ),
    );
  }

  // ==================== Order Card ====================
  Widget _buildOrderCard(PurchaseOrderModel order) {
    final isOverdue = _parseDate(order.dueDate).isBefore(DateTime.now());

    return OrderListCard(
      title: order.partyName.isEmpty ? 'Unknown Party' : order.partyName,
      badge: isOverdue ? 'OVERDUE' : 'PURCHASE ORDER',
      badgeColor: isOverdue ? JoynColors.error : _warningColor,
      number: '#${order.orderNo}',
      date: formatOrderDate(order.date),
      total: order.totalAmount,
      // TODO: agar PurchaseOrderModel mein paid/balance field hai to wahi use karo.
      balance: order.totalAmount,
      onTap: () => _openDetail(order),
      onView: () => _openDetail(order),
      onPrint: () => _comingSoon('Print'),
      onShare: () => _comingSoon('Share'),
      onDelete: () => _deleteOrder(order),
    );
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
        child: SizedBox(
          height: 52,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(OrderUi.rMd),
              boxShadow: OrderUi.glow(JoynColors.primary, 0.35),
            ),
            child: ElevatedButton(
              onPressed: () async {
                HapticFeedback.lightImpact();
                await Navigator.of(context).push(
                  MaterialPageRoute(
                      builder: (_) => const AddPurchaseOrderScreen()),
                );
                _loadOrders();
              },
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.zero,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(OrderUi.rMd)),
                elevation: 0,
                backgroundColor: Colors.transparent,
              ),
              child: Ink(
                decoration: BoxDecoration(
                  gradient: OrderUi.primaryGrad,
                  borderRadius: BorderRadius.circular(OrderUi.rMd),
                ),
                child: Container(
                  alignment: Alignment.center,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.add_rounded,
                          color: Colors.white, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'Add Purchase Order',
                        style: JoynTypography.bodyMedium.copyWith(
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          fontSize: 15,
                          letterSpacing: 0.2,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}