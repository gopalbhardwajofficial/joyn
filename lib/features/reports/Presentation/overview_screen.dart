import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../core/theme/joyn_colors.dart';
import '../../../core/theme/joyn_typography.dart';
import '../../orders/data/sales_repository.dart';
import '../../orders/models/sales_models.dart';

class ReportsSummary {
  final double youllGet;
  final double youllGive;
  final Map<String, double> saleOverview;
  final double purchasesThisMonth;
  final double cashInHand;
  final double stockValue;
  final int noOfItems;
  final List<InventoryItemModel> lowStockItems;
  final List<Map<String, dynamic>> mostSellingItems;
  final int openPurchaseOrders;
  final double openPurchaseAmount;

  const ReportsSummary({
    required this.youllGet,
    required this.youllGive,
    required this.saleOverview,
    required this.purchasesThisMonth,
    required this.cashInHand,
    required this.stockValue,
    required this.noOfItems,
    required this.lowStockItems,
    required this.mostSellingItems,
    required this.openPurchaseOrders,
    required this.openPurchaseAmount,
  });
}

final reportsSummaryProvider = FutureProvider<ReportsSummary>((ref) async {
  final repository = SalesRepository();
  final data = await repository.getReportsData();

  final inventorySummary = data['inventorySummary'] as Map<String, dynamic>;
  final openPO = data['openPurchaseOrders'] as Map<String, dynamic>;

  return ReportsSummary(
    youllGet: (data['youllGet'] as num?)?.toDouble() ?? 0,
    youllGive: (data['youllGive'] as num?)?.toDouble() ?? 0,
    saleOverview: Map<String, double>.from(data['saleOverview'] as Map? ?? {}),
    purchasesThisMonth: (data['purchasesThisMonth'] as num?)?.toDouble() ?? 0,
    cashInHand: (data['cashInHand'] as num?)?.toDouble() ?? 0,
    stockValue: (inventorySummary['stockValue'] as num?)?.toDouble() ?? 0,
    noOfItems: (inventorySummary['noOfItems'] as num?)?.toInt() ?? 0,
    lowStockItems: (data['lowStockItems'] as List? ?? [])
        .map((item) => InventoryItemModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: item['name'] as String? ?? '',
      unit: item['unit'] as String? ?? 'Pcs',
      stock: (item['stock'] as num?)?.toInt() ?? 0,
      createdAt: DateTime.now(),
    ))
        .toList(),
    mostSellingItems: (data['mostSellingItems'] as List? ?? [])
        .map((item) => Map<String, dynamic>.from(item as Map))
        .toList(),
    openPurchaseOrders: (openPO['count'] as num?)?.toInt() ?? 0,
    openPurchaseAmount: (openPO['amount'] as num?)?.toDouble() ?? 0,
  );
});

class _Premium {
  static List<BoxShadow> cardShadow = [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.05),
      blurRadius: 20,
      offset: const Offset(0, 8),
    ),
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.025),
      blurRadius: 4,
      offset: const Offset(0, 1),
    ),
  ];

  static List<BoxShadow> fieldShadow = [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.035),
      blurRadius: 10,
      offset: const Offset(0, 3),
    ),
  ];

  static List<BoxShadow> chipShadow(Color color) => [
    BoxShadow(
      color: color.withValues(alpha: 0.28),
      blurRadius: 14,
      offset: const Offset(0, 6),
    ),
  ];

  static List<BoxShadow> floatingShadow(Color color) => [
    BoxShadow(
      color: color.withValues(alpha: 0.35),
      blurRadius: 16,
      offset: const Offset(0, 6),
    ),
  ];

  static LinearGradient gradient(Color color) => LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      color,
      Color.lerp(color, Colors.black, 0.18) ?? color,
    ],
  );

  static LinearGradient surfaceGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Colors.white,
      JoynColors.background,
    ],
  );
}

class _ReportColors {
  static const success = Color(0xFF16A34A);
  static const primaryText = Color(0xFF1A1A1A);
}

class OverviewScreen extends ConsumerWidget {
  const OverviewScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summaryAsync = ref.watch(reportsSummaryProvider);

    return summaryAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, _) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: JoynColors.surface,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: JoynColors.border, width: 1.2),
                  boxShadow: _Premium.cardShadow,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: _Premium.gradient(JoynColors.error),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.error_outline_rounded, color: Colors.white, size: 32),
                    ),
                    const SizedBox(height: 16),
                    Text('Failed to load reports',
                        style: JoynTypography.bodyLarge.copyWith(fontWeight: FontWeight.w800, fontSize: 17)),
                    const SizedBox(height: 8),
                    Text('$err',
                        style: JoynTypography.bodyMedium.copyWith(fontSize: 13, color: JoynColors.secondaryText),
                        textAlign: TextAlign.center),
                    const SizedBox(height: 20),
                    ElevatedButton.icon(
                      onPressed: () => ref.refresh(reportsSummaryProvider.future),
                      icon: const Icon(Icons.refresh_rounded, size: 18),
                      label: const Text('Retry'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: JoynColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        elevation: 0,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      data: (summary) => RefreshIndicator(
        onRefresh: () => ref.refresh(reportsSummaryProvider.future),
        color: JoynColors.primary,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Business Overview',
                      style: JoynTypography.bodyLarge.copyWith(fontWeight: FontWeight.w800, fontSize: 18, letterSpacing: -0.3)),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: JoynColors.primary.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.calendar_today_rounded, size: 12, color: JoynColors.primary),
                        const SizedBox(width: 4),
                        Text('This Month',
                            style: JoynTypography.caption.copyWith(fontSize: 11, fontWeight: FontWeight.w700, color: JoynColors.primary)),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              Row(
                children: [
                  _buildSummaryCard(
                    icon: Icons.call_received_rounded,
                    iconColor: _ReportColors.success,
                    title: "You'll Get",
                    amount: '₹${summary.youllGet.toStringAsFixed(2)}',
                    subtitle: 'Credit Sales',
                  ),
                  const SizedBox(width: 12),
                  _buildSummaryCard(
                    icon: Icons.call_made_rounded,
                    iconColor: JoynColors.error,
                    title: "You'll Give",
                    amount: '₹${summary.youllGive.toStringAsFixed(2)}',
                    subtitle: 'Purchase Orders',
                  ),
                ],
              ),
              const SizedBox(height: 30),

              _buildSectionHeader(1, 'Inventory'),
              const SizedBox(height: 16),
              _buildInventorySection(summary),
              const SizedBox(height: 30),

              _buildSectionHeader(2, 'Sale Overview'),
              const SizedBox(height: 16),
              _buildSaleOverviewCard(summary),
              const SizedBox(height: 30),

              _buildSectionHeader(3, 'Quick Stats'),
              const SizedBox(height: 16),
              Row(
                children: [
                  _buildMiniStatCard(
                    'Purchases',
                    '₹${summary.purchasesThisMonth.toStringAsFixed(2)}',
                    Icons.shopping_cart_outlined,
                    JoynColors.primary,
                  ),
                  const SizedBox(width: 12),
                  _buildMiniStatCard(
                    'Cash In-Hand',
                    '₹${summary.cashInHand.toStringAsFixed(2)}',
                    Icons.account_balance_wallet_outlined,
                    _ReportColors.success,
                  ),
                ],
              ),
              const SizedBox(height: 30),

              _buildSectionHeader(4, 'Purchase Orders'),
              const SizedBox(height: 16),
              _buildOpenPurchaseCard(summary),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(int number, String title) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 30,
              height: 30,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                gradient: _Premium.gradient(Colors.black87),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.22),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Text(
                '$number',
                style: JoynTypography.caption.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 13,
                ),
              ),
            ),
            // const SizedBox(width: 10),
            // // Container(
            //   padding: const EdgeInsets.all(7),
            //   decoration: BoxDecoration(
            //     gradient: _Premium.gradient(JoynColors.primary),
            //     borderRadius: BorderRadius.circular(9),
            //     boxShadow: [
            //       BoxShadow(
            //         color: JoynColors.primary.withValues(alpha: 0.25),
            //         blurRadius: 8,
            //         offset: const Offset(0, 3),
            //       ),
            //     ],
            //   ),
            // ),
            const SizedBox(width: 8),
            Text(
              title,
              style: JoynTypography.bodyLarge.copyWith(
                fontWeight: FontWeight.w800,
                fontSize: 17,
                letterSpacing: -0.2,
                color: JoynColors.primary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          height: 1.2,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                JoynColors.border,
                JoynColors.border.withValues(alpha: 0.0),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryCard({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String amount,
    required String subtitle,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          gradient: _Premium.surfaceGradient,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: JoynColors.border, width: 1.2),
          boxShadow: _Premium.cardShadow,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    gradient: _Premium.gradient(iconColor),
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color: iconColor.withValues(alpha: 0.25),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Icon(icon, size: 14, color: Colors.white),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(title,
                      style: JoynTypography.caption.copyWith(fontSize: 11.5, color: JoynColors.secondaryText, fontWeight: FontWeight.w700)),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(amount,
                style: JoynTypography.titleMedium.copyWith(fontWeight: FontWeight.w800, fontSize: 20, letterSpacing: -0.5)),
            const SizedBox(height: 4),
            Text(subtitle,
                style: JoynTypography.caption.copyWith(fontSize: 10.5, color: JoynColors.secondaryText)),
          ],
        ),
      ),
    );
  }

  Widget _buildInventorySection(ReportsSummary summary) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: _Premium.surfaceGradient,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: JoynColors.border, width: 1.2),
        boxShadow: _Premium.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: _buildStatTile(
                  'Stock Value',
                  '₹${summary.stockValue.toStringAsFixed(2)}',
                  Icons.inventory_2_outlined,
                  _ReportColors.success,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildStatTile(
                  'Total Items',
                  '${summary.noOfItems}',
                  Icons.category_outlined,
                  JoynColors.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _CollapsibleItemList(
            title: 'Low Stock Items',
            items: summary.lowStockItems
                .map((item) => (item.name, '${item.stock} ${item.unit}'))
                .toList(),
            valuePrefix: '',
            icon: Icons.warning_amber_rounded,
            iconColor: JoynColors.error,
          ),
          const SizedBox(height: 8),
          _CollapsibleItemList(
            title: 'Most Selling Items',
            items: summary.mostSellingItems
                .map((item) => (
            item['name'] as String? ?? 'Unknown',
            '${(item['quantity'] as num?)?.toInt() ?? 0} units'
            ))
                .toList(),
            valuePrefix: '',
            icon: Icons.trending_up_rounded,
            iconColor: _ReportColors.success,
          ),
        ],
      ),
    );
  }

  Widget _buildStatTile(String label, String value, IconData icon, Color iconColor) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: JoynColors.border, width: 1.2),
        boxShadow: _Premium.fieldShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, size: 14, color: iconColor),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(label,
                    style: JoynTypography.caption.copyWith(fontSize: 10.5, color: JoynColors.secondaryText, fontWeight: FontWeight.w600)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(value,
              style: JoynTypography.bodyLarge.copyWith(fontWeight: FontWeight.w800, fontSize: 15, color: _ReportColors.primaryText)),
        ],
      ),
    );
  }

  Widget _buildMiniStatCard(String title, String amount, IconData icon, Color iconColor) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          gradient: _Premium.surfaceGradient,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: JoynColors.border, width: 1.2),
          boxShadow: _Premium.cardShadow,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: _Premium.gradient(iconColor),
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(
                    color: iconColor.withValues(alpha: 0.25),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Icon(icon, size: 14, color: Colors.white),
            ),
            const SizedBox(height: 12),
            Text(title,
                style: JoynTypography.caption.copyWith(fontSize: 11.5, color: JoynColors.secondaryText, fontWeight: FontWeight.w600)),
            const SizedBox(height: 6),
            Text(amount,
                style: JoynTypography.bodyLarge.copyWith(fontWeight: FontWeight.w800, fontSize: 17, letterSpacing: -0.3)),
          ],
        ),
      ),
    );
  }

  Widget _buildOpenPurchaseCard(ReportsSummary summary) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: _Premium.surfaceGradient,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: JoynColors.border, width: 1.2),
        boxShadow: _Premium.cardShadow,
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildStatTile(
              'Open POs',
              '${summary.openPurchaseOrders}',
              Icons.receipt_long_outlined,
              JoynColors.primary,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _buildStatTile(
              'Total Amount',
              '₹${summary.openPurchaseAmount.toStringAsFixed(2)}',
              Icons.payments_outlined,
              JoynColors.error,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSaleOverviewCard(ReportsSummary summary) {
    final months = summary.saleOverview.keys.toList();
    final values = summary.saleOverview.values.toList();
    final currentMonthValue = values.isNotEmpty ? values.last : 0.0;
    final prevMonthValue = values.length > 1 ? values[values.length - 2] : 0.0;

    final maxY = values.isEmpty ? 10.0 : values.reduce((a, b) => a > b ? a : b);
    final spots = List.generate(values.length, (i) => FlSpot(i.toDouble(), values[i]));

    final bool isDecline = currentMonthValue < prevMonthValue;
    final double changePercent = prevMonthValue == 0
        ? (currentMonthValue == 0 ? 0 : 100)
        : (((currentMonthValue - prevMonthValue).abs() / prevMonthValue) * 100);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: _Premium.surfaceGradient,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: JoynColors.border, width: 1.2),
        boxShadow: _Premium.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Monthly Sales',
                  style: JoynTypography.bodyLarge.copyWith(fontWeight: FontWeight.w800, fontSize: 15)),
              if (months.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: JoynColors.chipBackground,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(months.last,
                      style: JoynTypography.caption.copyWith(fontSize: 10.5, fontWeight: FontWeight.w700, color: JoynColors.secondaryText)),
                ),
            ],
          ),
          const SizedBox(height: 16),
          Center(
            child: Column(
              children: [
                Text('Total Sale',
                    style: JoynTypography.caption.copyWith(fontSize: 10.5, color: JoynColors.secondaryText)),
                const SizedBox(height: 4),
                Text('₹${currentMonthValue.toStringAsFixed(2)}',
                    style: JoynTypography.titleMedium.copyWith(
                      fontWeight: FontWeight.w800,
                      fontSize: 22,
                      letterSpacing: -0.5,
                      color: isDecline ? JoynColors.error : _ReportColors.success,
                    )),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    gradient: _Premium.gradient(isDecline ? JoynColors.error : _ReportColors.success),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: (isDecline ? JoynColors.error : _ReportColors.success).withValues(alpha: 0.3),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isDecline ? Icons.trending_down_rounded : Icons.trending_up_rounded,
                        size: 14,
                        color: Colors.white,
                      ),
                      const SizedBox(width: 4),
                      Text('${changePercent.toStringAsFixed(0)}% ${isDecline ? 'Decline' : 'Growth'}',
                          style: JoynTypography.caption.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 11,
                          )),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 180,
            child: spots.isEmpty
                ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.bar_chart_rounded, size: 40, color: JoynColors.secondaryText.withValues(alpha: 0.3)),
                  const SizedBox(height: 8),
                  Text('No sales data yet',
                      style: JoynTypography.caption.copyWith(color: JoynColors.secondaryText)),
                ],
              ),
            )
                : LineChart(
              LineChartData(
                minY: 0,
                maxY: maxY == 0 ? 10 : maxY * 1.2,
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: maxY == 0 ? 2.5 : (maxY * 1.2) / 4,
                  getDrawingHorizontalLine: (value) {
                    return FlLine(
                      color: JoynColors.border.withValues(alpha: 0.5),
                      strokeWidth: 0.8,
                      dashArray: [5, 5],
                    );
                  },
                ),
                borderData: FlBorderData(show: false),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 35,
                      getTitlesWidget: (value, meta) {
                        return Text(
                          '₹${value.toInt()}',
                          style: JoynTypography.caption.copyWith(fontSize: 9, color: JoynColors.secondaryText),
                        );
                      },
                    ),
                  ),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 24,
                      getTitlesWidget: (value, meta) {
                        final i = value.toInt();
                        if (i < 0 || i >= months.length) return const SizedBox.shrink();
                        return Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(months[i],
                              style: JoynTypography.caption.copyWith(fontSize: 10, color: JoynColors.secondaryText, fontWeight: FontWeight.w600)),
                        );
                      },
                    ),
                  ),
                ),
                lineTouchData: LineTouchData(
                  touchTooltipData: LineTouchTooltipData(
                    getTooltipColor: (_) => JoynColors.primary,
                    tooltipPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    getTooltipItems: (touchedSpots) => touchedSpots.map((s) {
                      return LineTooltipItem(
                        '₹${s.y.toStringAsFixed(0)}',
                        const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 12),
                      );
                    }).toList(),
                  ),
                ),
                lineBarsData: [
                  LineChartBarData(
                    spots: spots,
                    isCurved: true,
                    curveSmoothness: 0.3,
                    preventCurveOverShooting: true,
                    color: JoynColors.primary,
                    barWidth: 3,
                    isStrokeCapRound: true,
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (spot, percent, bar, index) => FlDotCirclePainter(
                        radius: 5,
                        color: JoynColors.primary,
                        strokeWidth: 2.5,
                        strokeColor: Colors.white,
                      ),
                    ),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          JoynColors.primary.withValues(alpha: 0.2),
                          JoynColors.primary.withValues(alpha: 0.0),
                        ],
                      ),
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
}

class _CollapsibleItemList extends StatefulWidget {
  final String title;
  final List<(String, String)> items;
  final String valuePrefix;
  final IconData icon;
  final Color iconColor;

  const _CollapsibleItemList({
    required this.title,
    required this.items,
    required this.valuePrefix,
    required this.icon,
    required this.iconColor,
  });

  @override
  State<_CollapsibleItemList> createState() => _CollapsibleItemListState();
}

class _CollapsibleItemListState extends State<_CollapsibleItemList> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: JoynColors.border, width: 1.2),
        boxShadow: _Premium.fieldShadow,
      ),
      child: Column(
        children: [
          InkWell(
            onTap: () {
              HapticFeedback.selectionClick();
              setState(() => _expanded = !_expanded);
            },
            borderRadius: BorderRadius.circular(14),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(7),
                    decoration: BoxDecoration(
                      gradient: _Premium.gradient(widget.iconColor),
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(
                          color: widget.iconColor.withValues(alpha: 0.25),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Icon(widget.icon, size: 13, color: Colors.white),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      widget.title,
                      style: JoynTypography.bodyMedium.copyWith(fontWeight: FontWeight.w700, fontSize: 13),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: JoynColors.chipBackground,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text('${widget.items.length}',
                        style: JoynTypography.caption.copyWith(fontSize: 10.5, fontWeight: FontWeight.w800, color: JoynColors.primary)),
                  ),
                  const SizedBox(width: 6),
                  AnimatedRotation(
                    turns: _expanded ? 0.5 : 0.0,
                    duration: const Duration(milliseconds: 200),
                    child: Icon(Icons.keyboard_arrow_down_rounded,
                        size: 18, color: JoynColors.secondaryText),
                  ),
                ],
              ),
            ),
          ),
          AnimatedCrossFade(
            firstChild: const SizedBox.shrink(),
            secondChild: Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
              child: Column(
                children: widget.items.isEmpty
                    ? [
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: Text('No items to display',
                        style: JoynTypography.caption.copyWith(fontSize: 11.5, color: JoynColors.secondaryText)),
                  ),
                ]
                    : widget.items.map((item) {
                  return Container(
                    margin: const EdgeInsets.only(top: 6),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: JoynColors.background,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(item.$1,
                              style: JoynTypography.bodyMedium.copyWith(fontSize: 12.5, fontWeight: FontWeight.w600),
                              overflow: TextOverflow.ellipsis),
                        ),
                        const SizedBox(width: 8),
                        Text('${widget.valuePrefix}${item.$2}',
                            style: JoynTypography.bodyMedium.copyWith(fontSize: 12, fontWeight: FontWeight.w800, color: widget.iconColor)),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
            crossFadeState: _expanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 250),
          ),
        ],
      ),
    );
  }
}