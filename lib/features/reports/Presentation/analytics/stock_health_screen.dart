import 'package:flutter/material.dart';
import '../../../../core/theme/joyn_colors.dart';
import '../../../../core/theme/joyn_typography.dart';
import '../../../orders/presentation/add_purchase_order_screen.dart';
import '../../models/kpi_analytics_models.dart';

class StockHealthScreen extends StatefulWidget {
  final List<StockAlertMetric> outOfStockItems;
  final List<StockAlertMetric> lowStockItems;
  final double totalStockCost;
  final double potentialStockSale;
  final int totalItemsCount;

  const StockHealthScreen({
    super.key,
    required this.outOfStockItems,
    required this.lowStockItems,
    required this.totalStockCost,
    required this.potentialStockSale,
    required this.totalItemsCount,
  });

  @override
  State<StockHealthScreen> createState() => _StockHealthScreenState();
}

class _StockHealthScreenState extends State<StockHealthScreen> {
  String _selectedFilter = 'ALL'; // ALL, OUT, LOW
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final combinedAlerts = [
      ...widget.outOfStockItems,
      ...widget.lowStockItems,
    ];

    final filteredList = combinedAlerts.where((item) {
      if (_selectedFilter == 'OUT' && !item.isOutOfStock) return false;
      if (_selectedFilter == 'LOW' && item.isOutOfStock) return false;
      if (_searchQuery.isNotEmpty) {
        final q = _searchQuery.toLowerCase();
        return item.name.toLowerCase().contains(q) || item.itemCode.toLowerCase().contains(q);
      }
      return true;
    }).toList();

    final potentialProfit = (widget.potentialStockSale - widget.totalStockCost).clamp(0.0, double.infinity);

    return Scaffold(
      backgroundColor: JoynColors.background,
      appBar: AppBar(
        backgroundColor: JoynColors.surface,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: JoynColors.primaryText),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Inventory Health & Alerts',
          style: JoynTypography.titleMedium.copyWith(
            fontWeight: FontWeight.w800,
            fontSize: 18,
            color: JoynColors.primaryText,
          ),
        ),
      ),
      body: Column(
        children: [
          // Stock Valuation Header Card
          Container(
            margin: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [const Color(0xFF1E293B), const Color(0xFF0F172A)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.15),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'TOTAL INVENTORY VALUATION',
                      style: JoynTypography.caption.copyWith(
                        color: Colors.white.withValues(alpha: 0.7),
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.8,
                        fontSize: 10.5,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '${widget.totalItemsCount} Total Items',
                        style: JoynTypography.caption.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('At Cost Price',
                              style: JoynTypography.caption.copyWith(
                                color: Colors.white.withValues(alpha: 0.6),
                                fontSize: 11,
                              )),
                          Text(
                            '₹${widget.totalStockCost.toStringAsFixed(2)}',
                            style: JoynTypography.titleMedium.copyWith(
                              fontWeight: FontWeight.w800,
                              fontSize: 18,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(width: 1, height: 32, color: Colors.white.withValues(alpha: 0.15)),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Potential Sale Value',
                              style: JoynTypography.caption.copyWith(
                                color: Colors.white.withValues(alpha: 0.6),
                                fontSize: 11,
                              )),
                          Text(
                            '₹${widget.potentialStockSale.toStringAsFixed(2)}',
                            style: JoynTypography.titleMedium.copyWith(
                              fontWeight: FontWeight.w800,
                              fontSize: 18,
                              color: const Color(0xFF34D399),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.trending_up_rounded, color: Color(0xFF34D399), size: 16),
                      const SizedBox(width: 6),
                      Text(
                        'Expected Inventory Profit Margin: ₹${potentialProfit.toStringAsFixed(2)}',
                        style: JoynTypography.caption.copyWith(
                          color: Colors.white.withValues(alpha: 0.9),
                          fontWeight: FontWeight.w600,
                          fontSize: 11.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Search & Filter Row
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    onChanged: (val) => setState(() => _searchQuery = val.trim()),
                    decoration: InputDecoration(
                      hintText: 'Search items...',
                      hintStyle: JoynTypography.bodyMedium.copyWith(color: JoynColors.secondaryText, fontSize: 13),
                      prefixIcon: const Icon(Icons.search_rounded, size: 20, color: JoynColors.secondaryText),
                      filled: true,
                      fillColor: JoynColors.surface,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: JoynColors.border),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: JoynColors.border),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Filter Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Row(
              children: [
                _buildFilterChip('ALL', 'All Alerts (${combinedAlerts.length})'),
                const SizedBox(width: 8),
                _buildFilterChip('OUT', 'Out of Stock (${widget.outOfStockItems.length})', isDanger: true),
                const SizedBox(width: 8),
                _buildFilterChip('LOW', 'Low Stock (${widget.lowStockItems.length})', isWarning: true),
              ],
            ),
          ),
          const SizedBox(height: 6),

          // Alert Items List
          Expanded(
            child: filteredList.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.check_circle_outline_rounded, size: 52, color: Color(0xFF16A34A)),
                        const SizedBox(height: 12),
                        Text('Great! No stock alerts found',
                            style: JoynTypography.bodyLarge.copyWith(fontWeight: FontWeight.w700)),
                        const SizedBox(height: 4),
                        Text('All inventory levels are adequate.',
                            style: JoynTypography.bodyMedium.copyWith(color: JoynColors.secondaryText)),
                      ],
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                    itemCount: filteredList.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final item = filteredList[index];

                      return Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: JoynColors.surface,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: item.isOutOfStock ? const Color(0xFFFCA5A5) : const Color(0xFFFDE68A),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.02),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: item.isOutOfStock ? const Color(0xFFFEF2F2) : const Color(0xFFFFFBEB),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                item.isOutOfStock ? Icons.error_outline_rounded : Icons.warning_amber_rounded,
                                color: item.isOutOfStock ? JoynColors.error : const Color(0xFFD97706),
                                size: 22,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item.name,
                                    style: JoynTypography.bodyLarge.copyWith(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 15,
                                      color: JoynColors.primaryText,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Row(
                                    children: [
                                      if (item.itemCode.isNotEmpty) ...[
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                                          decoration: BoxDecoration(
                                            color: JoynColors.primary.withValues(alpha: 0.08),
                                            borderRadius: BorderRadius.circular(4),
                                          ),
                                          child: Text(
                                            item.itemCode,
                                            style: JoynTypography.caption.copyWith(
                                              color: JoynColors.primary,
                                              fontSize: 10,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 6),
                                      ],
                                      Text(
                                        item.isOutOfStock
                                            ? 'Out of Stock (0 ${item.unit})'
                                            : 'Only ${item.currentStock} ${item.unit} left',
                                        style: JoynTypography.caption.copyWith(
                                          color: item.isOutOfStock ? JoynColors.error : const Color(0xFFD97706),
                                          fontWeight: FontWeight.w700,
                                          fontSize: 11.5,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            // Quick Reorder action button
                            ElevatedButton.icon(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => const AddPurchaseOrderScreen(),
                                  ),
                                );
                              },
                              icon: const Icon(Icons.add_shopping_cart_rounded, size: 14),
                              label: const Text('Reorder'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: JoynColors.primary,
                                foregroundColor: Colors.white,
                                elevation: 0,
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                textStyle: JoynTypography.caption.copyWith(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 12,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String key, String label, {bool isDanger = false, bool isWarning = false}) {
    final isSelected = _selectedFilter == key;
    Color activeColor = JoynColors.primary;
    if (isDanger) activeColor = JoynColors.error;
    if (isWarning) activeColor = const Color(0xFFD97706);

    return InkWell(
      onTap: () => setState(() => _selectedFilter = key),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? activeColor : JoynColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? activeColor : JoynColors.border,
            width: 1.2,
          ),
        ),
        child: Text(
          label,
          style: JoynTypography.caption.copyWith(
            fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
            fontSize: 12,
            color: isSelected ? Colors.white : JoynColors.primaryText,
          ),
        ),
      ),
    );
  }
}

