// lib/features/orders/presentation/sale_orders_list_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/joyn_colors.dart';
import '../../../core/theme/joyn_typography.dart';
import '../../../core/router/route_observer.dart';
import '../models/sales_models.dart';
import '../data/sales_repository.dart';
import 'add_sale_order_screen.dart';
import 'sale_order_detail_screen.dart';
import 'widgets/order_filter_widgets.dart';
import 'widgets/order_list_widgets.dart';

enum _SortOption { dateDesc, dateAsc, amountHigh, amountLow, customerAsc }

// ==================== Main Screen ====================
class SaleOrdersListScreen extends StatefulWidget {
  const SaleOrdersListScreen({super.key});

  @override
  State<SaleOrdersListScreen> createState() => _SaleOrdersListScreenState();
}

class _SaleOrdersListScreenState extends State<SaleOrdersListScreen>
    with RouteAware {
  final SalesRepository _salesRepository = SalesRepository();
  List<SaleOrderModel> _orders = [];
  List<SaleOrderModel> _filteredOrders = [];
  bool _isLoading = true;

  _SortOption _sortOption = _SortOption.dateDesc;

  // Filters — settings (⚙) se toggle hote hain, default mein sirf Customer Name on hai
  static const List<OrderFilterDef> _filterDefs = [
    OrderFilterDef(
      key: 'name',
      label: 'Customer Name',
      shortLabel: 'Customer',
      icon: Icons.person_outline_rounded,
      type: OrderFilterType.text,
      hint: 'Search by customer name',
    ),
    OrderFilterDef(
      key: 'invoice',
      label: 'Invoice No',
      shortLabel: 'Invoice',
      icon: Icons.receipt_long_outlined,
      type: OrderFilterType.text,
      hint: 'Search by invoice no',
      keyboard: TextInputType.number,
    ),
    OrderFilterDef(
      key: 'phone',
      label: 'Phone',
      icon: Icons.phone_outlined,
      type: OrderFilterType.text,
      hint: 'Search by phone number',
      keyboard: TextInputType.phone,
    ),
    OrderFilterDef(
      key: 'payment',
      label: 'Payment Mode',
      shortLabel: 'Payment',
      icon: Icons.account_balance_wallet_outlined,
      type: OrderFilterType.choice,
      choices: ['Credit', 'Cash'],
      allLabel: 'All Payment Modes',
    ),
    OrderFilterDef(
      key: 'date',
      label: 'Date Range',
      shortLabel: 'Date',
      icon: Icons.calendar_today_rounded,
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
  double get _totalCredit => _filteredOrders
      .where((o) => o.paymentMode.toLowerCase() == 'credit')
      .fold(0.0, (s, o) => s + o.totalAmount);

  // TODO: agar SaleOrderModel mein paid/balance field hai to yahan wahi use karo.
  double _balanceOf(SaleOrderModel o) =>
      o.paymentMode.toLowerCase() == 'credit' ? o.totalAmount : 0;

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
    debugPrint('Sale list: didPopNext → reloading');
    _loadOrders();
  }

  void _onFiltersChanged() {
    if (!mounted) return;
    setState(_applyFilters);
  }

  Future<void> _loadOrders() async {
    try {
      final orders = await _salesRepository.getSaleOrders();
      if (!mounted) return;
      setState(() {
        _orders = orders;
        _isLoading = false;
        _applyFilters();
      });
    } catch (e) {
      debugPrint('Error loading orders: $e');
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  void _applyFilters() {
    final nameQ = _filters.textQuery('name');
    final invoiceQ = _filters.textQuery('invoice');
    final phoneQ = _filters.textQuery('phone');
    final mode = _filters.choiceOf('payment')?.toLowerCase();
    final dateRange = _filters.rangeOf('date');
    final minAmt = _filters.minOf('amount');
    final maxAmt = _filters.maxOf('amount');

    final list = _orders.where((o) {
      if (nameQ.isNotEmpty && !o.customerName.toLowerCase().contains(nameQ)) {
        return false;
      }
      if (invoiceQ.isNotEmpty && !o.invoiceNo.toString().contains(invoiceQ)) {
        return false;
      }
      if (phoneQ.isNotEmpty && !o.customerPhone.contains(phoneQ)) {
        return false;
      }
      if (mode != null && o.paymentMode.toLowerCase() != mode) {
        return false;
      }
      if (dateRange != null &&
          !OrderFilters.inDateRange(_parseDate(o.date), dateRange)) {
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
      case _SortOption.customerAsc:
        list.sort((a, b) => a.customerName
            .toLowerCase()
            .compareTo(b.customerName.toLowerCase()));
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

  Future<void> _openDetail(SaleOrderModel order) async {
    HapticFeedback.lightImpact();
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => SaleOrderDetailScreen(
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

  Future<void> _deleteOrder(SaleOrderModel order) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Text('Delete Sale?',
            style: JoynTypography.titleMedium
                .copyWith(fontSize: 17, fontWeight: FontWeight.w700)),
        content: Text(
          'Delete Invoice #${order.invoiceNo} for ${order.customerName}?',
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
      await _salesRepository.deleteSaleOrder(order.id);
      _loadOrders();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Sale deleted successfully!'),
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
            _buildSortTile('Customer Name (A-Z)',
                Icons.sort_by_alpha_rounded, _SortOption.customerAsc),
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

    final subtitle = '${_filteredOrders.length} invoices  •  '
        '₹${_totalAmount.toStringAsFixed(0)}'
        '${_totalCredit > 0 ? '  •  ₹${_totalCredit.toStringAsFixed(0)} credit' : ''}';

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
                        title: 'Sales',
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
                          icon: Icons.receipt_long_outlined,
                          title: hasFilter ? 'No Sales Found' : 'No Sales Yet',
                          subtitle: hasFilter
                              ? 'Try adjusting your filters'
                              : 'Tap "Add Sale" to create your first sale',
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
  Widget _buildOrderCard(SaleOrderModel order) {
    return OrderListCard(
      title: order.customerName.isEmpty ? 'Walk-in Customer' : order.customerName,
      badge: 'SALE',
      badgeColor: JoynColors.success,
      number: '#${order.invoiceNo}',
      date: formatOrderDate(order.date),
      total: order.totalAmount,
      balance: _balanceOf(order),
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
                      builder: (_) => const AddSaleOrderScreen()),
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
                        'Add Sale',
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