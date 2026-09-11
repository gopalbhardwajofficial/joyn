// lib/features/orders/presentation/sale_orders_list_screen.dart

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
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      height: 44,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: JoynColors.border, width: 1),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.03),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: TextField(
                        onChanged: _onSearchChanged,
                        decoration: InputDecoration(
                          hintText: 'Search sales...',
                          hintStyle: JoynTypography.bodyMedium.copyWith(
                            color: JoynColors.secondaryText.withValues(alpha: 0.5),
                            fontSize: 13,
                          ),
                          prefixIcon: const Icon(Icons.search_rounded, size: 18, color: JoynColors.secondaryText),
                          suffixIcon: _searchQuery.isNotEmpty
                              ? IconButton(
                            icon: const Icon(Icons.clear_rounded, size: 16, color: JoynColors.secondaryText),
                            onPressed: () => _onSearchChanged(''),
                          )
                              : null,
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(vertical: 10),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Tooltip(
                    message: 'Sort',
                    child: InkWell(
                      onTap: _showSortSheet,
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: JoynColors.border, width: 1),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.03),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: const Icon(Icons.swap_vert_rounded, size: 18, color: JoynColors.primary),
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Tooltip(
                    message: 'Filter',
                    child: InkWell(
                      onTap: _showFilterSheet,
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: JoynColors.border, width: 1),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.03),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            const Icon(Icons.filter_list_rounded, size: 18, color: JoynColors.primary),
                            if (_paymentFilter != _PaymentFilter.all)
                              Positioned(
                                top: 6,
                                right: 6,
                                child: Container(
                                  width: 6,
                                  height: 6,
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
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${_filteredOrders.length} sales',
                      style: JoynTypography.caption.copyWith(
                        fontSize: 11.5,
                        color: JoynColors.secondaryText,
                      ),
                    ),
                    Text(
                      'Total: ₹${_calculateTotal().toStringAsFixed(2)}',
                      style: JoynTypography.caption.copyWith(
                        fontSize: 11.5,
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
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        color: JoynColors.iconBackground,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Icon(Icons.receipt_long_outlined, size: 36, color: JoynColors.secondaryText),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      _searchQuery.isNotEmpty || _paymentFilter != _PaymentFilter.all
                          ? 'No Sales Found'
                          : 'No Sales Yet',
                      style: JoynTypography.titleMedium.copyWith(fontSize: 17, fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _searchQuery.isNotEmpty || _paymentFilter != _PaymentFilter.all
                          ? 'Try adjusting your search or filter'
                          : 'Tap "Add Sale" to create your first sale',
                      style: JoynTypography.subtitle.copyWith(fontSize: 12.5),
                    ),
                  ],
                ),
              )
                  : RefreshIndicator(
                onRefresh: _loadOrders,
                color: JoynColors.primary,
                child: ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                  itemCount: _filteredOrders.length,
                  itemBuilder: (context, index) {
                    final order = _filteredOrders[index];
                    return _buildOrderCard(order);
                  },
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 6, 16, 16),
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
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: JoynColors.primary.withValues(alpha: 0.25),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: () async {
                      HapticFeedback.lightImpact();
                      await Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const AddSaleOrderScreen()),
                      );
                      _loadOrders();
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.add_rounded, color: Colors.white, size: 18),
                          const SizedBox(width: 6),
                          Text(
                            'Add Sale',
                            style: JoynTypography.bodyMedium.copyWith(
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                              fontSize: 14,
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

  // ========== COMPACT & ATTRACTIVE CARD ==========
  Widget _buildOrderCard(SaleOrderModel order) {
    final isCredit = order.paymentMode.toLowerCase() == 'credit';
    List<OrderItemModel> items = [];
    try {
      items = order.items.map((map) => OrderItemModel.fromJson(map)).toList();
    } catch (e) {
      debugPrint('Error parsing items for order ${order.invoiceNo}: $e');
    }
    final showExpand = items.length > 2;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: JoynColors.border.withOpacity(0.4), width: 0.8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
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
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header row – more compact
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: JoynColors.primary.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(Icons.receipt_long_outlined, size: 16, color: JoynColors.primary),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  order.customerName,
                                  style: JoynTypography.bodyMedium.copyWith(
                                    fontSize: 13.5,
                                    fontWeight: FontWeight.w700,
                                    color: JoynColors.primary,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Text(
                                  'Invoice #${order.invoiceNo} • ${order.date}',
                                  style: JoynTypography.caption.copyWith(
                                    fontSize: 10.5,
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
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: isCredit
                            ? JoynColors.error.withValues(alpha: 0.08)
                            : JoynColors.success.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isCredit
                              ? JoynColors.error.withValues(alpha: 0.2)
                              : JoynColors.success.withValues(alpha: 0.2),
                          width: 0.8,
                        ),
                      ),
                      child: Text(
                        order.paymentMode,
                        style: JoynTypography.caption.copyWith(
                          fontSize: 9.5,
                          fontWeight: FontWeight.w700,
                          color: isCredit ? JoynColors.error : JoynColors.success,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                // Summary row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${order.items.length} items',
                      style: JoynTypography.caption.copyWith(
                        fontSize: 11,
                        color: JoynColors.secondaryText,
                      ),
                    ),
                    Text(
                      '₹${order.totalAmount.toStringAsFixed(2)}',
                      style: JoynTypography.bodyLarge.copyWith(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: JoynColors.primary,
                      ),
                    ),
                  ],
                ),
                // Item preview
                if (items.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  ...items.take(2).map((item) => _buildItemRow(item)),
                  if (showExpand)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.keyboard_arrow_down_rounded, size: 14, color: JoynColors.secondaryText),
                          Text(
                            ' + ${items.length - 2} more',
                            style: JoynTypography.caption.copyWith(
                              fontSize: 10,
                              color: JoynColors.secondaryText,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
                const SizedBox(height: 6),
                // Delete button (smaller)
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    InkWell(
                      onTap: () => _deleteOrder(order),
                      borderRadius: BorderRadius.circular(6),
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: JoynColors.error.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Icon(Icons.delete_outline_rounded, size: 14, color: JoynColors.error),
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

  // ========== COMPACT ITEM ROW with full breakdown ==========
  Widget _buildItemRow(OrderItemModel item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 5),
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 6),
      decoration: BoxDecoration(
        color: JoynColors.chipBackground.withOpacity(0.5),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: JoynColors.border.withOpacity(0.2), width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Item name
          Text(
            item.itemName,
            style: JoynTypography.bodyMedium.copyWith(
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
              color: JoynColors.primary,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          // Subtotal
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Subtotal',
                style: JoynTypography.caption.copyWith(
                  fontSize: 9.5,
                  color: JoynColors.secondaryText,
                ),
              ),
              Text(
                '${item.qty} ${item.unit.isNotEmpty ? item.unit : ''} × ₹${item.unitPrice.toStringAsFixed(2)} = ₹${item.subtotal.toStringAsFixed(2)}',
                style: JoynTypography.caption.copyWith(
                  fontSize: 9.5,
                  fontWeight: FontWeight.w600,
                  color: JoynColors.primary,
                ),
              ),
            ],
          ),
          // Discount
          if (item.discountAmount > 0)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Discount',
                  style: JoynTypography.caption.copyWith(
                    fontSize: 9.5,
                    color: JoynColors.secondaryText,
                  ),
                ),
                Text(
                  '-₹${item.discountAmount.toStringAsFixed(2)}',
                  style: JoynTypography.caption.copyWith(
                    fontSize: 9.5,
                    fontWeight: FontWeight.w600,
                    color: JoynColors.error,
                  ),
                ),
              ],
            ),
          // Tax
          if (item.taxAmount > 0)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Tax @${item.taxRate}%',
                  style: JoynTypography.caption.copyWith(
                    fontSize: 9.5,
                    color: JoynColors.secondaryText,
                  ),
                ),
                Text(
                  '+₹${item.taxAmount.toStringAsFixed(2)}',
                  style: JoynTypography.caption.copyWith(
                    fontSize: 9.5,
                    fontWeight: FontWeight.w600,
                    color: JoynColors.primary,
                  ),
                ),
              ],
            ),
          const Divider(height: 4, thickness: 0.3, color: JoynColors.border),
          // Total
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Total',
                style: JoynTypography.caption.copyWith(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: JoynColors.primary,
                ),
              ),
              Text(
                '₹${item.total.toStringAsFixed(2)}',
                style: JoynTypography.caption.copyWith(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  color: JoynColors.primary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}