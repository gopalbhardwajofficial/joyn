import 'package:flutter/material.dart';
import '../../../../core/theme/joyn_colors.dart';
import '../../../../core/theme/joyn_typography.dart';
import '../../models/kpi_analytics_models.dart';

class ItemSalesAnalyticsScreen extends StatefulWidget {
  final List<ItemSalesMetric> mostSellingItems;
  final List<DeadStockMetric> leastSellingItems;
  final double totalGrossSales;
  final String dateRangeLabel;

  const ItemSalesAnalyticsScreen({
    super.key,
    required this.mostSellingItems,
    required this.leastSellingItems,
    required this.totalGrossSales,
    required this.dateRangeLabel,
  });

  @override
  State<ItemSalesAnalyticsScreen> createState() => _ItemSalesAnalyticsScreenState();
}

class _ItemSalesAnalyticsScreenState extends State<ItemSalesAnalyticsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final filteredMostSelling = widget.mostSellingItems.where((i) {
      if (_searchQuery.isEmpty) return true;
      final q = _searchQuery.toLowerCase();
      return i.name.toLowerCase().contains(q) || i.itemCode.toLowerCase().contains(q);
    }).toList();

    final filteredDeadStock = widget.leastSellingItems.where((i) {
      if (_searchQuery.isEmpty) return true;
      final q = _searchQuery.toLowerCase();
      return i.name.toLowerCase().contains(q) || i.itemCode.toLowerCase().contains(q);
    }).toList();

    final totalLockedCapital = widget.leastSellingItems.fold(0.0, (sum, i) => sum + i.lockedCapital);

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
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Item & Inventory Analytics',
              style: JoynTypography.titleMedium.copyWith(
                fontWeight: FontWeight.w800,
                fontSize: 18,
                color: JoynColors.primaryText,
              ),
            ),
            Text(
              'Period: ${widget.dateRangeLabel}',
              style: JoynTypography.caption.copyWith(
                fontSize: 11,
                color: JoynColors.secondaryText,
              ),
            ),
          ],
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Container(
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: JoynColors.border, width: 1)),
            ),
            child: TabBar(
              controller: _tabController,
              labelColor: JoynColors.primary,
              unselectedLabelColor: JoynColors.secondaryText,
              labelStyle: JoynTypography.bodyMedium.copyWith(fontWeight: FontWeight.w700),
              indicatorColor: JoynColors.primary,
              indicatorWeight: 3,
              tabs: [
                Tab(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.star_rounded, size: 18, color: Colors.amber),
                      const SizedBox(width: 6),
                      Text('Top Selling (${widget.mostSellingItems.length})'),
                    ],
                  ),
                ),
                Tab(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.warning_amber_rounded, size: 18, color: JoynColors.error),
                      const SizedBox(width: 6),
                      Text('Dead Stock (${widget.leastSellingItems.length})'),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          // Search & Summary Header
          Container(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            color: JoynColors.surface,
            child: Column(
              children: [
                TextField(
                  controller: _searchController,
                  onChanged: (val) => setState(() => _searchQuery = val.trim()),
                  decoration: InputDecoration(
                    hintText: 'Search items by name or ITM-code...',
                    hintStyle: JoynTypography.bodyMedium.copyWith(color: JoynColors.secondaryText, fontSize: 13),
                    prefixIcon: const Icon(Icons.search_rounded, size: 20, color: JoynColors.secondaryText),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear_rounded, size: 18),
                            onPressed: () {
                              _searchController.clear();
                              setState(() => _searchQuery = '');
                            },
                          )
                        : null,
                    filled: true,
                    fillColor: JoynColors.background,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: JoynColors.border),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: JoynColors.border),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: JoynColors.primary, width: 1.5),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Tab content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildTopSellingList(filteredMostSelling),
                _buildDeadStockList(filteredDeadStock, totalLockedCapital),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopSellingList(List<ItemSalesMetric> items) {
    if (items.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inventory_2_outlined, size: 54, color: JoynColors.secondaryText.withValues(alpha: 0.5)),
            const SizedBox(height: 12),
            Text('No item sales recorded for this period',
                style: JoynTypography.bodyLarge.copyWith(color: JoynColors.secondaryText, fontWeight: FontWeight.w600)),
          ],
        ),
      );
    }

    final maxQty = items.first.qtySold > 0 ? items.first.qtySold : 1.0;

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: items.length,
      separatorBuilder: (_, _) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final item = items[index];
        final rank = index + 1;
        final rankColor = rank == 1
            ? const Color(0xFFEAB308)
            : rank == 2
                ? const Color(0xFF94A3B8)
                : rank == 3
                    ? const Color(0xFFB45309)
                    : JoynColors.secondaryText;

        final double ratio = (item.qtySold / maxQty).clamp(0.0, 1.0);

        return Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: JoynColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: JoynColors.border),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.02),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: rankColor.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      '#$rank',
                      style: JoynTypography.caption.copyWith(
                        color: rankColor,
                        fontWeight: FontWeight.w800,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
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
                        if (item.itemCode.isNotEmpty)
                          Container(
                            margin: const EdgeInsets.only(top: 2),
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
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '₹${item.totalRevenue.toStringAsFixed(2)}',
                        style: JoynTypography.bodyLarge.copyWith(
                          fontWeight: FontWeight.w800,
                          fontSize: 15,
                          color: const Color(0xFF16A34A),
                        ),
                      ),
                      Text(
                        '${item.qtySold.toStringAsFixed(item.qtySold % 1 == 0 ? 0 : 2)} ${item.unit}',
                        style: JoynTypography.caption.copyWith(
                          color: JoynColors.secondaryText,
                          fontWeight: FontWeight.w600,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Relative volume progress bar
              Row(
                children: [
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: ratio,
                        minHeight: 6,
                        backgroundColor: JoynColors.border.withValues(alpha: 0.5),
                        valueColor: AlwaysStoppedAnimation<Color>(
                          rank <= 3 ? JoynColors.primary : const Color(0xFF10B981),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    '${item.percentageShare.toStringAsFixed(1)}% of Sales',
                    style: JoynTypography.caption.copyWith(
                      color: JoynColors.secondaryText,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDeadStockList(List<DeadStockMetric> items, double totalLocked) {
    if (items.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.check_circle_outline_rounded, size: 54, color: Color(0xFF16A34A)),
            const SizedBox(height: 12),
            Text('Awesome! No dead stock found',
                style: JoynTypography.bodyLarge.copyWith(color: JoynColors.primaryText, fontWeight: FontWeight.w700)),
            const SizedBox(height: 4),
            Text('All inventory items have active sales momentum.',
                style: JoynTypography.bodyMedium.copyWith(color: JoynColors.secondaryText, fontSize: 13)),
          ],
        ),
      );
    }

    return Column(
      children: [
        // Total locked capital banner
        Container(
          margin: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: const Color(0xFFFEF2F2),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFFCA5A5)),
          ),
          child: Row(
            children: [
              const Icon(Icons.lock_clock_rounded, color: JoynColors.error, size: 22),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Capital Tied Up in Dead Stock',
                        style: JoynTypography.caption.copyWith(
                          color: JoynColors.error,
                          fontWeight: FontWeight.w700,
                          fontSize: 11,
                        )),
                    Text(
                      '₹${totalLocked.toStringAsFixed(2)}',
                      style: JoynTypography.titleMedium.copyWith(
                        fontWeight: FontWeight.w800,
                        fontSize: 17,
                        color: JoynColors.error,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFFCA5A5)),
                ),
                child: Text(
                  '${items.length} Items',
                  style: JoynTypography.caption.copyWith(
                    fontWeight: FontWeight.w700,
                    color: JoynColors.error,
                    fontSize: 11,
                  ),
                ),
              ),
            ],
          ),
        ),

        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
            itemCount: items.length,
            separatorBuilder: (_, _) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final item = items[index];

              return Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: JoynColors.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: JoynColors.border),
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
                        color: const Color(0xFFFFFBEB),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFFDE68A)),
                      ),
                      child: const Icon(Icons.timer_outlined, color: Color(0xFFD97706), size: 20),
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
                              fontSize: 14.5,
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
                                'Stock: ${item.currentStock} ${item.unit}',
                                style: JoynTypography.caption.copyWith(
                                  color: JoynColors.secondaryText,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '₹${item.lockedCapital.toStringAsFixed(2)}',
                          style: JoynTypography.bodyLarge.copyWith(
                            fontWeight: FontWeight.w800,
                            fontSize: 15,
                            color: JoynColors.error,
                          ),
                        ),
                        Text(
                          'Blocked Capital',
                          style: JoynTypography.caption.copyWith(
                            color: JoynColors.secondaryText,
                            fontSize: 10.5,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

