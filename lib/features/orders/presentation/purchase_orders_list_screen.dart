import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/joyn_colors.dart';
import '../../../core/theme/joyn_typography.dart';
import '../models/sales_models.dart';
import '../data/sales_repository.dart';
import 'add_purchase_order_screen.dart';
import 'purchase_order_detail_screen.dart';

enum _SortOption { dateDesc, dateAsc, amountHigh, amountLow, partyAsc }

class PurchaseOrdersListScreen extends StatefulWidget {
  const PurchaseOrdersListScreen({super.key});

  @override
  State<PurchaseOrdersListScreen> createState() => _PurchaseOrdersListScreenState();
}

class _PurchaseOrdersListScreenState extends State<PurchaseOrdersListScreen> {
  final SalesRepository _salesRepository = SalesRepository();
  List<PurchaseOrderModel> _orders = [];
  List<PurchaseOrderModel> _filteredOrders = [];
  bool _isLoading = true;
  String _searchQuery = '';

  _SortOption _sortOption = _SortOption.dateDesc;
  String? _filterDueDate;

  @override
  void initState() {
    super.initState();
    _loadOrders();
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
          order.partyName.toLowerCase().contains(query) ||
          order.orderNo.toString().contains(query) ||
          order.date.contains(query);

      final matchesDueDate = _filterDueDate == null || order.dueDate.contains(_filterDueDate!);

      return matchesQuery && matchesDueDate;
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
        list.sort((a, b) => a.partyName.toLowerCase().compareTo(b.partyName.toLowerCase()));
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

  Future<void> _deleteOrder(PurchaseOrderModel order) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Text('Delete Purchase Order?', style: JoynTypography.titleMedium.copyWith(fontSize: 17, fontWeight: FontWeight.w700)),
        content: Text(
          'Delete Order #${order.orderNo} for ${order.partyName}?',
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
      await _salesRepository.deletePurchaseOrder(order.id);
      _loadOrders();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Purchase order deleted successfully!'),
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
            _buildSortTile('Party Name (A-Z)', Icons.sort_by_alpha_rounded, _SortOption.partyAsc),
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
          'Purchase Orders',
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
            // Search + Sort row
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
                          hintText: 'Search by party name, order no, date...',
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
                      '${_filteredOrders.length} orders',
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
                      child: const Icon(Icons.shopping_cart_outlined, size: 40, color: JoynColors.secondaryText),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _searchQuery.isNotEmpty ? 'No Orders Found' : 'No Purchase Orders Yet',
                      style: JoynTypography.titleMedium.copyWith(fontSize: 18, fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _searchQuery.isNotEmpty
                          ? 'Try adjusting your search'
                          : 'Tap "Add Purchase Order" to create your first order',
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
                        MaterialPageRoute(builder: (_) => const AddPurchaseOrderScreen()),
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
                            'Add Purchase Order',
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

  Widget _buildOrderCard(PurchaseOrderModel order) {
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
                builder: (_) => PurchaseOrderDetailScreen(order: order),
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
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: JoynColors.primary.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.shopping_cart_outlined, size: 18, color: JoynColors.primary),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            order.partyName,
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
                            'Order #${order.orderNo} • ${order.date}',
                            style: JoynTypography.caption.copyWith(
                              fontSize: 11.5,
                              color: JoynColors.secondaryText,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          'Due: ${order.dueDate}',
                          style: JoynTypography.caption.copyWith(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w700,
                            color: JoynColors.error,
                          ),
                        ),
                      ],
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