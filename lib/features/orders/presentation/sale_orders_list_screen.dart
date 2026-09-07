import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/joyn_colors.dart';
import '../../../core/theme/joyn_typography.dart';
import '../models/sales_models.dart';
import '../data/sales_repository.dart';
import 'add_sale_order_screen.dart';
import 'sale_order_detail_screen.dart';

enum _SortOption { dateDesc, dateAsc, amountHigh, amountLow, customerAsc }
enum _PaymentFilter { all, credit, cash }

class SaleOrdersListScreen extends StatefulWidget {
  const SaleOrdersListScreen({super.key});

  @override
  State<SaleOrdersListScreen> createState() => _SaleOrdersListScreenState();
}

class _SaleOrdersListScreenState extends State<SaleOrdersListScreen> {
  final SalesRepository _salesRepository = SalesRepository();
  List<SaleOrderModel> _orders = [];
  List<SaleOrderModel> _filteredOrders = [];
  bool _isLoading = true;
  String _searchQuery = '';

  _SortOption _sortOption = _SortOption.dateDesc;
  _PaymentFilter _paymentFilter = _PaymentFilter.all;

  @override
  void initState() {
    super.initState();
    _loadOrders();
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
    var list = _orders.where((order) {
      final query = _searchQuery.toLowerCase().trim();
      final matchesQuery = query.isEmpty ||
          order.customerName.toLowerCase().contains(query) ||
          order.invoiceNo.toString().contains(query) ||
          order.customerPhone.contains(query);

      final matchesPayment = _paymentFilter == _PaymentFilter.all ||
          (_paymentFilter == _PaymentFilter.credit && order.paymentMode.toLowerCase() == 'credit') ||
          (_paymentFilter == _PaymentFilter.cash && order.paymentMode.toLowerCase() == 'cash');

      return matchesQuery && matchesPayment;
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
        list.sort((a, b) => a.customerName.toLowerCase().compareTo(b.customerName.toLowerCase()));
        break;
    }

    _filteredOrders = list;
  }

  DateTime _parseDate(String dateStr) {
    try {
      final parts = dateStr.split('/');
      if (parts.length == 3) {
        return DateTime(
          int.parse(parts[2]),
          int.parse(parts[1]),
          int.parse(parts[0]),
        );
      }
    } catch (_) {}
    return DateTime.now();
  }

  void _onSearchChanged(String value) {
    setState(() {
      _searchQuery = value;
      _applyFilters();
    });
  }

  Future<void> _deleteOrder(SaleOrderModel order) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Text('Delete Sale?', style: JoynTypography.titleMedium.copyWith(fontSize: 17, fontWeight: FontWeight.w700)),
        content: Text(
          'Delete Invoice #${order.invoiceNo} for ${order.customerName}?',
          style: JoynTypography.bodyMedium.copyWith(fontSize: 13.5, color: JoynColors.secondaryText),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Delete', style: TextStyle(color: JoynColors.error, fontWeight: FontWeight.w700)),
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
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
        );
      }
    }
  }

  void _showSortSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4.5,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(color: JoynColors.border, borderRadius: BorderRadius.circular(3)),
            ),
            Text('Sort By', style: JoynTypography.titleMedium.copyWith(fontSize: 17, fontWeight: FontWeight.w800)),
            const SizedBox(height: 8),
            _buildSortTile('Date (Newest First)', Icons.calendar_today_rounded, _SortOption.dateDesc),
            _buildSortTile('Date (Oldest First)', Icons.calendar_today_rounded, _SortOption.dateAsc),
            _buildSortTile('Amount (High to Low)', Icons.currency_rupee_rounded, _SortOption.amountHigh),
            _buildSortTile('Amount (Low to High)', Icons.currency_rupee_rounded, _SortOption.amountLow),
            _buildSortTile('Customer Name (A-Z)', Icons.sort_by_alpha_rounded, _SortOption.customerAsc),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _buildSortTile(String label, IconData icon, _SortOption option) {
    final selected = _sortOption == option;
    return ListTile(
      leading: Icon(icon, size: 20, color: selected ? JoynColors.primary : JoynColors.secondaryText),
      title: Text(
        label,
        style: JoynTypography.bodyLarge.copyWith(
          fontSize: 14.5,
          fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
          color: selected ? JoynColors.primary : Colors.black87,
        ),
      ),
      trailing: selected ? const Icon(Icons.check_rounded, color: JoynColors.primary) : null,
      onTap: () {
        setState(() {
          _sortOption = option;
          _applyFilters();
        });
        Navigator.pop(context);
      },
    );
  }

  void _showFilterSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4.5,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(color: JoynColors.border, borderRadius: BorderRadius.circular(3)),
            ),
            Text('Filter by Payment Mode', style: JoynTypography.titleMedium.copyWith(fontSize: 17, fontWeight: FontWeight.w800)),
            const SizedBox(height: 8),
            _buildFilterTile('All', _PaymentFilter.all),
            _buildFilterTile('Credit', _PaymentFilter.credit),
            _buildFilterTile('Cash', _PaymentFilter.cash),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterTile(String label, _PaymentFilter filter) {
    final selected = _paymentFilter == filter;
    return ListTile(
      leading: Icon(
        filter == _PaymentFilter.credit
            ? Icons.account_balance_wallet_outlined
            : filter == _PaymentFilter.cash
            ? Icons.payments_outlined
            : Icons.all_inclusive_rounded,
        size: 20,
        color: selected ? JoynColors.primary : JoynColors.secondaryText,
      ),
      title: Text(
        label,
        style: JoynTypography.bodyLarge.copyWith(
          fontSize: 14.5,
          fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
          color: selected ? JoynColors.primary : Colors.black87,
        ),
      ),
      trailing: selected ? const Icon(Icons.check_rounded, color: JoynColors.primary) : null,
      onTap: () {
        setState(() {
          _paymentFilter = filter;
          _applyFilters();
        });
        Navigator.pop(context);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: JoynColors.background,
      appBar: AppBar(
        backgroundColor: JoynColors.background,
        elevation: 0,
        scrolledUnderElevation: 0.5,
        leading: IconButton(
          icon: Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: JoynColors.chipBackground,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.arrow_back_rounded, size: 18),
          ),
          onPressed: () => context.pop(),
        ),
        centerTitle: true,
        title: Text(
          'Sales',
          style: JoynTypography.titleMedium.copyWith(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.2,
          ),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Search + Sort + Filter row
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      height: 48,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: JoynColors.border, width: 1.2),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.035),
                            blurRadius: 10,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: TextField(
                        onChanged: _onSearchChanged,
                        decoration: InputDecoration(
                          hintText: 'Search by customer, invoice no...',
                          hintStyle: JoynTypography.bodyMedium.copyWith(
                            color: JoynColors.secondaryText.withValues(alpha: 0.5),
                            fontSize: 13.5,
                          ),
                          prefixIcon: const Icon(Icons.search_rounded, size: 20, color: JoynColors.secondaryText),
                          suffixIcon: _searchQuery.isNotEmpty
                              ? IconButton(
                            icon: const Icon(Icons.clear_rounded, size: 18, color: JoynColors.secondaryText),
                            onPressed: () => _onSearchChanged(''),
                          )
                              : null,
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Tooltip(
                    message: 'Sort',
                    child: InkWell(
                      onTap: _showSortSheet,
                      borderRadius: BorderRadius.circular(14),
                      child: Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: JoynColors.border, width: 1.2),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.035),
                              blurRadius: 10,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: const Icon(Icons.swap_vert_rounded, size: 20, color: JoynColors.primary),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Tooltip(
                    message: 'Filter',
                    child: InkWell(
                      onTap: _showFilterSheet,
                      borderRadius: BorderRadius.circular(14),
                      child: Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: JoynColors.border, width: 1.2),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.035),
                              blurRadius: 10,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            const Icon(Icons.filter_list_rounded, size: 20, color: JoynColors.primary),
                            if (_paymentFilter != _PaymentFilter.all)
                              Positioned(
                                top: 6,
                                right: 6,
                                child: Container(
                                  width: 7,
                                  height: 7,
                                  decoration: const BoxDecoration(
                                    color: JoynColors.error,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Results count
            if (_orders.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${_filteredOrders.length} sales',
                      style: JoynTypography.caption.copyWith(
                        fontSize: 12,
                        color: JoynColors.secondaryText,
                      ),
                    ),
                    Text(
                      'Total: ₹${_calculateTotal().toStringAsFixed(2)}',
                      style: JoynTypography.caption.copyWith(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: JoynColors.primary,
                      ),
                    ),
                  ],
                ),
              ),

            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator(color: JoynColors.primary))
                  : _filteredOrders.isEmpty
                  ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: JoynColors.iconBackground,
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: const Icon(Icons.receipt_long_outlined, size: 40, color: JoynColors.secondaryText),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _searchQuery.isNotEmpty || _paymentFilter != _PaymentFilter.all
                          ? 'No Sales Found'
                          : 'No Sales Yet',
                      style: JoynTypography.titleMedium.copyWith(fontSize: 18, fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _searchQuery.isNotEmpty || _paymentFilter != _PaymentFilter.all
                          ? 'Try adjusting your search or filter'
                          : 'Tap "Add Sale" to create your first sale',
                      style: JoynTypography.subtitle.copyWith(fontSize: 13),
                    ),
                  ],
                ),
              )
                  : RefreshIndicator(
                onRefresh: _loadOrders,
                color: JoynColors.primary,
                child: ListView.builder(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                  itemCount: _filteredOrders.length,
                  itemBuilder: (context, index) {
                    final order = _filteredOrders[index];
                    return _buildOrderCard(order);
                  },
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      JoynColors.primary,
                      Color.lerp(JoynColors.primary, Colors.black, 0.18) ?? JoynColors.primary,
                    ],
                  ),
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [
                    BoxShadow(
                      color: JoynColors.primary.withValues(alpha: 0.28),
                      blurRadius: 14,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(18),
                    onTap: () async {
                      HapticFeedback.lightImpact();
                      await Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const AddSaleOrderScreen()),
                      );
                      _loadOrders();
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.add_rounded, color: Colors.white, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            'Add Sale',
                            style: JoynTypography.bodyMedium.copyWith(
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                              fontSize: 14.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  double _calculateTotal() {
    double total = 0;
    for (final order in _filteredOrders) {
      total += order.totalAmount;
    }
    return total;
  }

  Widget _buildOrderCard(SaleOrderModel order) {
    final isCredit = order.paymentMode.toLowerCase() == 'credit';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.white, JoynColors.background],
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: JoynColors.border, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.035),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: () async {
            HapticFeedback.lightImpact();
            await Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => SaleOrderDetailScreen(order: order),
              ),
            );
            _loadOrders();
          },
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: JoynColors.primary.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(Icons.receipt_long_outlined, size: 18, color: JoynColors.primary),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  order.customerName,
                                  style: JoynTypography.bodyLarge.copyWith(
                                    fontSize: 14.5,
                                    fontWeight: FontWeight.w700,
                                    color: JoynColors.primary,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Invoice #${order.invoiceNo} • ${order.date}',
                                  style: JoynTypography.caption.copyWith(
                                    fontSize: 11.5,
                                    color: JoynColors.secondaryText,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: isCredit
                            ? JoynColors.error.withValues(alpha: 0.08)
                            : JoynColors.success.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isCredit
                              ? JoynColors.error.withValues(alpha: 0.2)
                              : JoynColors.success.withValues(alpha: 0.2),
                          width: 1,
                        ),
                      ),
                      child: Text(
                        order.paymentMode,
                        style: JoynTypography.caption.copyWith(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w700,
                          color: isCredit ? JoynColors.error : JoynColors.success,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${order.items.length} items',
                      style: JoynTypography.caption.copyWith(
                        fontSize: 12,
                        color: JoynColors.secondaryText,
                      ),
                    ),
                    Text(
                      '₹${order.totalAmount.toStringAsFixed(2)}',
                      style: JoynTypography.bodyLarge.copyWith(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: JoynColors.primary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    InkWell(
                      onTap: () => _deleteOrder(order),
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: JoynColors.error.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.delete_outline_rounded, size: 16, color: JoynColors.error),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}