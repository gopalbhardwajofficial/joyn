import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../core/theme/joyn_colors.dart';
import '../../../core/theme/joyn_typography.dart';
import '../data/kpi_analytics_repository.dart';
import '../models/kpi_analytics_models.dart';
import 'analytics/item_sales_analytics_screen.dart';
import 'analytics/party_analytics_screen.dart';
import 'analytics/stock_health_screen.dart';

class OverviewScreen extends ConsumerStatefulWidget {
  const OverviewScreen({super.key});

  @override
  ConsumerState<OverviewScreen> createState() => _OverviewScreenState();
}

class _OverviewScreenState extends ConsumerState<OverviewScreen> {
  final KpiAnalyticsRepository _repository = KpiAnalyticsRepository();

  ReportTimeRange _selectedRange = ReportTimeRange.thisMonth;
  DateTimeRange? _customRange;

  bool _isLoading = true;
  String? _errorMessage;
  KpiExecutiveSummary _summary = KpiExecutiveSummary.empty();

  // Chart series visibility toggles
  bool _showSalesLine = true;
  bool _showPurchasesLine = true;
  bool _showExpensesLine = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  DateTimeRange get _activeDateRange =>
      _selectedRange.toDateRange(customRange: _customRange);

  String get _rangeLabel {
    final range = _activeDateRange;
    final startStr = '${range.start.day} ${_monthShort(range.start.month)}';
    final endStr = '${range.end.day} ${_monthShort(range.end.month)}';
    return '${_selectedRange.label} ($startStr - $endStr)';
  }

  String _monthShort(int month) {
    const m = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return m[(month - 1).clamp(0, 11)];
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final range = _activeDateRange;
      final prevRange = _selectedRange.toPreviousDateRange(range);
      final data = await _repository.getExecutiveAnalytics(
        range: range,
        prevRange: prevRange,
      );
      if (mounted) {
        setState(() {
          _summary = data;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _showDateRangePickerSheet() async {
    HapticFeedback.lightImpact();
    await showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
          decoration: const BoxDecoration(
            color: JoynColors.surface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: JoynColors.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Select Time Period',
                    style: JoynTypography.titleMedium.copyWith(
                      fontWeight: FontWeight.w800,
                      fontSize: 18,
                      color: JoynColors.primaryText,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, size: 20),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ...ReportTimeRange.values.map((rangeOption) {
                final isSelected = _selectedRange == rangeOption;
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? JoynColors.primary.withValues(alpha: 0.12)
                          : JoynColors.background,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      rangeOption == ReportTimeRange.custom
                          ? Icons.calendar_month_rounded
                          : Icons.access_time_rounded,
                      size: 18,
                      color: isSelected ? JoynColors.primary : JoynColors.secondaryText,
                    ),
                  ),
                  title: Text(
                    rangeOption.label,
                    style: JoynTypography.bodyLarge.copyWith(
                      fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                      color: isSelected ? JoynColors.primary : JoynColors.primaryText,
                    ),
                  ),
                  trailing: isSelected
                      ? const Icon(Icons.check_circle_rounded, color: JoynColors.primary)
                      : null,
                  onTap: () async {
                    Navigator.pop(context);
                    if (rangeOption == ReportTimeRange.custom) {
                      final picked = await showDateRangePicker(
                        context: this.context,
                        firstDate: DateTime(2020),
                        lastDate: DateTime(2100),
                        initialDateRange: _customRange ?? _activeDateRange,
                      );
                      if (picked != null) {
                        setState(() {
                          _selectedRange = ReportTimeRange.custom;
                          _customRange = picked;
                        });
                        _loadData();
                      }
                    } else {
                      setState(() {
                        _selectedRange = rangeOption;
                      });
                      _loadData();
                    }
                  },
                );
              }),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: JoynColors.background,
      body: RefreshIndicator(
        onRefresh: _loadData,
        color: JoynColors.primary,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _errorMessage != null
                ? _buildErrorView()
                : SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Top Header with Time Range Filter Pill
                        _buildTopFilterHeader(),
                        const SizedBox(height: 16),

                        // Actionable Alert Banners (if any critical thresholds met)
                        _buildActionAlerts(),

                        // 4 Executive Financial Hero Cards
                        _buildExecutiveHeroCards(),
                        const SizedBox(height: 24),

                        // Interactive Spline Trend Chart (fl_chart)
                        _buildSplineTrendChart(),
                        const SizedBox(height: 24),

                        // Most Selling Items (Star Products)
                        _buildMostSellingSection(),
                        const SizedBox(height: 24),

                        // Least Selling / Dead Stock Warning Section
                        _buildDeadStockSection(),
                        const SizedBox(height: 24),

                        // Top VIP Customers & Suppliers
                        _buildTopPartiesSection(),
                        const SizedBox(height: 24),

                        // Payment Modes Breakdown
                        _buildPaymentModesSection(),
                        const SizedBox(height: 24),

                        // Stock Health & Total Asset Valuation
                        _buildStockValuationSection(),
                      ],
                    ),
                  ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // TOP FILTER HEADER
  // ═══════════════════════════════════════════════════════════════
  Widget _buildTopFilterHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Business Intelligence',
              style: JoynTypography.caption.copyWith(
                color: JoynColors.primary,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.5,
                fontSize: 11,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              'Executive KPIs',
              style: JoynTypography.titleMedium.copyWith(
                fontWeight: FontWeight.w900,
                fontSize: 22,
                color: JoynColors.primaryText,
                letterSpacing: -0.5,
              ),
            ),
          ],
        ),
        // Filter Pill
        InkWell(
          onTap: _showDateRangePickerSheet,
          borderRadius: BorderRadius.circular(20),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            decoration: BoxDecoration(
              color: JoynColors.primary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: JoynColors.primary.withValues(alpha: 0.25),
                width: 1.2,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.calendar_today_rounded, size: 13, color: JoynColors.primary),
                const SizedBox(width: 6),
                Text(
                  _selectedRange.label,
                  style: JoynTypography.caption.copyWith(
                    fontWeight: FontWeight.w800,
                    fontSize: 12,
                    color: JoynColors.primary,
                  ),
                ),
                const SizedBox(width: 4),
                const Icon(Icons.keyboard_arrow_down_rounded, size: 16, color: JoynColors.primary),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // ACTIONABLE ALERT BANNERS
  // ═══════════════════════════════════════════════════════════════
  Widget _buildActionAlerts() {
    final hasStockAlert = _summary.outOfStockCount > 0 || _summary.lowStockCount > 0;
    final overdue60d = _summary.creditAging['60+ Days'] ?? 0.0;
    final hasOverdueAlert = overdue60d > 0;

    if (!hasStockAlert && !hasOverdueAlert) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        children: [
          if (hasStockAlert)
            InkWell(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => StockHealthScreen(
                      outOfStockItems: _summary.outOfStockItems,
                      lowStockItems: _summary.lowStockItems,
                      totalStockCost: _summary.totalStockValuationCost,
                      potentialStockSale: _summary.potentialStockValuationSale,
                      totalItemsCount: _summary.totalItemsCount,
                    ),
                  ),
                );
              },
              borderRadius: BorderRadius.circular(14),
              child: Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF2F2),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFFCA5A5)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.warning_amber_rounded, color: JoynColors.error, size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        '${_summary.outOfStockCount} items Out of Stock • ${_summary.lowStockCount} Low Stock',
                        style: JoynTypography.caption.copyWith(
                          color: JoynColors.error,
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    const Icon(Icons.arrow_forward_ios_rounded, size: 12, color: JoynColors.error),
                  ],
                ),
              ),
            ),
          if (hasOverdueAlert)
            InkWell(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => PartyAnalyticsScreen(
                      topCustomers: _summary.topCustomers,
                      topSuppliers: _summary.topSuppliers,
                      creditAging: _summary.creditAging,
                      totalReceivables: _summary.youllGet,
                      dateRangeLabel: _rangeLabel,
                    ),
                  ),
                );
              },
              borderRadius: BorderRadius.circular(14),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFFBEB),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFFDE68A)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.timer_outlined, color: Color(0xFFD97706), size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        '₹${overdue60d.toStringAsFixed(0)} overdue credit (>60 days). Review debtors.',
                        style: JoynTypography.caption.copyWith(
                          color: const Color(0xFFB45309),
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    const Icon(Icons.arrow_forward_ios_rounded, size: 12, color: Color(0xFFD97706)),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // 4 EXECUTIVE FINANCIAL HERO CARDS
  // ═══════════════════════════════════════════════════════════════
  Widget _buildExecutiveHeroCards() {
    return Column(
      children: [
        // Row 1: Net Profit & Gross Revenue
        Row(
          children: [
            // Card 1: Net Profit
            Expanded(
              child: _buildHeroCard(
                title: 'Net Profit',
                amount: '₹${_summary.netProfit.toStringAsFixed(2)}',
                badgeText: '${_summary.netMarginPercent.toStringAsFixed(1)}% Margin',
                badgeColor: _summary.netProfit >= 0 ? const Color(0xFF10B981) : JoynColors.error,
                subText: 'Gross ₹${_summary.grossProfit.toStringAsFixed(0)} - Exp ₹${_summary.totalExpenses.toStringAsFixed(0)}',
                icon: Icons.account_balance_wallet_rounded,
                iconColor: const Color(0xFF10B981),
              ),
            ),
            const SizedBox(width: 12),
            // Card 2: Total Revenue / Gross Sales
            Expanded(
              child: _buildHeroCard(
                title: 'Gross Sales',
                amount: '₹${_summary.grossSales.toStringAsFixed(2)}',
                badgeText: _summary.salesGrowthPercent >= 0
                    ? '+${_summary.salesGrowthPercent.toStringAsFixed(1)}% Growth'
                    : '${_summary.salesGrowthPercent.toStringAsFixed(1)}% Growth',
                badgeColor: _summary.salesGrowthPercent >= 0 ? JoynColors.primary : JoynColors.error,
                subText: '${_summary.invoicesCount} Invoices • AOV ₹${_summary.aov.toStringAsFixed(0)}',
                icon: Icons.trending_up_rounded,
                iconColor: JoynColors.primary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Row 2: Liquidity (Cash & Bank) & Working Capital (You'll Get / Give)
        Row(
          children: [
            // Card 3: Total Liquidity
            Expanded(
              child: _buildHeroCard(
                title: 'Total Funds (Cash+Bank)',
                amount: '₹${(_summary.cashInHand + _summary.bankBalance).toStringAsFixed(2)}',
                badgeText: 'Liquid Funds',
                badgeColor: const Color(0xFF8B5CF6),
                subText: 'Cash ₹${_summary.cashInHand.toStringAsFixed(0)} • Bank ₹${_summary.bankBalance.toStringAsFixed(0)}',
                icon: Icons.payments_rounded,
                iconColor: const Color(0xFF8B5CF6),
              ),
            ),
            const SizedBox(width: 12),
            // Card 4: Market Receivables vs Payables
            Expanded(
              child: _buildHeroCard(
                title: "You'll Get (Credit)",
                amount: '₹${_summary.youllGet.toStringAsFixed(2)}',
                badgeText: "Give ₹${_summary.youllGive.toStringAsFixed(0)}",
                badgeColor: JoynColors.error,
                subText: 'Pending market receivables',
                icon: Icons.call_received_rounded,
                iconColor: const Color(0xFF0EA5E9),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildHeroCard({
    required String title,
    required String amount,
    required String badgeText,
    required Color badgeColor,
    required String subText,
    required IconData icon,
    required Color iconColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: JoynColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: JoynColors.border, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
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
              Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Icon(icon, size: 15, color: iconColor),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: badgeColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  badgeText,
                  style: JoynTypography.caption.copyWith(
                    color: badgeColor,
                    fontWeight: FontWeight.w800,
                    fontSize: 10,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            title,
            style: JoynTypography.caption.copyWith(
              color: JoynColors.secondaryText,
              fontWeight: FontWeight.w600,
              fontSize: 11,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            amount,
            style: JoynTypography.titleMedium.copyWith(
              fontWeight: FontWeight.w900,
              fontSize: 16.5,
              color: JoynColors.primaryText,
              letterSpacing: -0.4,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subText,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: JoynTypography.caption.copyWith(
              color: JoynColors.secondaryText,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // INTERACTIVE SPLINE TREND CHART (fl_chart)
  // ═══════════════════════════════════════════════════════════════
  Widget _buildSplineTrendChart() {
    final points = _summary.trendPoints;
    if (points.isEmpty) {
      return const SizedBox.shrink();
    }

    double maxY = 100.0;
    for (final p in points) {
      if (_showSalesLine && p.sales > maxY) maxY = p.sales;
      if (_showPurchasesLine && p.purchases > maxY) maxY = p.purchases;
      if (_showExpensesLine && p.expenses > maxY) maxY = p.expenses;
    }

    final salesSpots = List.generate(
      points.length,
      (i) => FlSpot(i.toDouble(), points[i].sales),
    );

    final purchaseSpots = List.generate(
      points.length,
      (i) => FlSpot(i.toDouble(), points[i].purchases),
    );

    final expenseSpots = List.generate(
      points.length,
      (i) => FlSpot(i.toDouble(), points[i].expenses),
    );

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: JoynColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: JoynColors.border, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header + Series Toggles
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Financial Velocity Trends',
                style: JoynTypography.bodyLarge.copyWith(
                  fontWeight: FontWeight.w800,
                  fontSize: 15.5,
                  color: JoynColors.primaryText,
                ),
              ),
              Text(
                _rangeLabel,
                style: JoynTypography.caption.copyWith(
                  fontSize: 10.5,
                  color: JoynColors.secondaryText,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Toggle chips
          Row(
            children: [
              _buildChartToggleChip(
                label: 'Sales',
                color: const Color(0xFF10B981),
                isActive: _showSalesLine,
                onTap: () => setState(() => _showSalesLine = !_showSalesLine),
              ),
              const SizedBox(width: 8),
              _buildChartToggleChip(
                label: 'Purchases',
                color: const Color(0xFFF59E0B),
                isActive: _showPurchasesLine,
                onTap: () => setState(() => _showPurchasesLine = !_showPurchasesLine),
              ),
              const SizedBox(width: 8),
              _buildChartToggleChip(
                label: 'Expenses',
                color: const Color(0xFFEF4444),
                isActive: _showExpensesLine,
                onTap: () => setState(() => _showExpensesLine = !_showExpensesLine),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // The Chart Canvas
          SizedBox(
            height: 200,
            child: LineChart(
              LineChartData(
                minX: 0,
                maxX: (points.length - 1).toDouble(),
                minY: 0,
                maxY: maxY * 1.15,
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: (maxY / 4).clamp(1.0, double.infinity),
                  getDrawingHorizontalLine: (val) => FlLine(
                    color: JoynColors.border.withValues(alpha: 0.6),
                    strokeWidth: 1,
                    dashArray: [4, 4],
                  ),
                ),
                titlesData: FlTitlesData(
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 42,
                      interval: (maxY / 3).clamp(1.0, double.infinity),
                      getTitlesWidget: (val, _) {
                        String text = '₹0';
                        if (val >= 100000) {
                          text = '₹${(val / 100000).toStringAsFixed(1)}L';
                        } else if (val >= 1000) {
                          text = '₹${(val / 1000).toStringAsFixed(0)}k';
                        } else if (val > 0) {
                          text = '₹${val.toInt()}';
                        }
                        return Text(
                          text,
                          style: JoynTypography.caption.copyWith(
                            color: JoynColors.secondaryText,
                            fontSize: 9.5,
                            fontWeight: FontWeight.w600,
                          ),
                        );
                      },
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 24,
                      interval: (points.length / 5).clamp(1.0, double.infinity),
                      getTitlesWidget: (val, _) {
                        final idx = val.toInt();
                        if (idx >= 0 && idx < points.length) {
                          return Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: Text(
                              points[idx].dayLabel,
                              style: JoynTypography.caption.copyWith(
                                color: JoynColors.secondaryText,
                                fontSize: 9.5,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          );
                        }
                        return const SizedBox.shrink();
                      },
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                lineTouchData: LineTouchData(
                  touchTooltipData: LineTouchTooltipData(
                    getTooltipColor: (_) => const Color(0xFF0F172A),
                    tooltipPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    getTooltipItems: (touchedSpots) {
                      return touchedSpots.map((s) {
                        final idx = s.x.toInt();
                        final pt = points[idx.clamp(0, points.length - 1)];
                        String label = 'Amount';
                        if (s.barIndex == 0 && _showSalesLine) label = 'Sales';
                        return LineTooltipItem(
                          '${pt.dayLabel}\n$label: ₹${s.y.toStringAsFixed(0)}',
                          const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 11),
                        );
                      }).toList();
                    },
                  ),
                ),
                lineBarsData: [
                  if (_showSalesLine)
                    LineChartBarData(
                      spots: salesSpots,
                      isCurved: true,
                      curveSmoothness: 0.35,
                      preventCurveOverShooting: true,
                      color: const Color(0xFF10B981),
                      barWidth: 3,
                      isStrokeCapRound: true,
                      dotData: const FlDotData(show: false),
                      belowBarData: BarAreaData(
                        show: true,
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            const Color(0xFF10B981).withValues(alpha: 0.28),
                            const Color(0xFF10B981).withValues(alpha: 0.0),
                          ],
                        ),
                      ),
                    ),
                  if (_showPurchasesLine)
                    LineChartBarData(
                      spots: purchaseSpots,
                      isCurved: true,
                      curveSmoothness: 0.35,
                      preventCurveOverShooting: true,
                      color: const Color(0xFFF59E0B),
                      barWidth: 2.5,
                      isStrokeCapRound: true,
                      dotData: const FlDotData(show: false),
                      belowBarData: BarAreaData(
                        show: true,
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            const Color(0xFFF59E0B).withValues(alpha: 0.15),
                            const Color(0xFFF59E0B).withValues(alpha: 0.0),
                          ],
                        ),
                      ),
                    ),
                  if (_showExpensesLine)
                    LineChartBarData(
                      spots: expenseSpots,
                      isCurved: true,
                      curveSmoothness: 0.35,
                      preventCurveOverShooting: true,
                      color: const Color(0xFFEF4444),
                      barWidth: 2.5,
                      isStrokeCapRound: true,
                      dotData: const FlDotData(show: false),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChartToggleChip({
    required String label,
    required Color color,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
        decoration: BoxDecoration(
          color: isActive ? color.withValues(alpha: 0.12) : JoynColors.background,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isActive ? color : JoynColors.border,
            width: 1.2,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: isActive ? color : JoynColors.secondaryText,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 5),
            Text(
              label,
              style: JoynTypography.caption.copyWith(
                fontWeight: isActive ? FontWeight.w800 : FontWeight.w600,
                fontSize: 11,
                color: isActive ? color : JoynColors.secondaryText,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // TOP 5 MOST SELLING ITEMS (STAR PRODUCTS)
  // ═══════════════════════════════════════════════════════════════
  Widget _buildMostSellingSection() {
    final items = _summary.mostSellingItems.take(5).toList();

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: JoynColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: JoynColors.border, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
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
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEF3C7),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.star_rounded, color: Color(0xFFD97706), size: 16),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Most Selling Items',
                    style: JoynTypography.bodyLarge.copyWith(
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                      color: JoynColors.primaryText,
                    ),
                  ),
                ],
              ),
              InkWell(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ItemSalesAnalyticsScreen(
                        mostSellingItems: _summary.mostSellingItems,
                        leastSellingItems: _summary.leastSellingItems,
                        totalGrossSales: _summary.grossSales,
                        dateRangeLabel: _rangeLabel,
                      ),
                    ),
                  );
                },
                child: Row(
                  children: [
                    Text(
                      'View All',
                      style: JoynTypography.caption.copyWith(
                        color: JoynColors.primary,
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                      ),
                    ),
                    const Icon(Icons.arrow_forward_ios_rounded, size: 11, color: JoynColors.primary),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          if (items.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Center(
                child: Text(
                  'No items sold during this period',
                  style: JoynTypography.bodyMedium.copyWith(color: JoynColors.secondaryText),
                ),
              ),
            )
          else
            ...items.asMap().entries.map((entry) {
              final rank = entry.key + 1;
              final item = entry.value;
              final rankColor = rank == 1
                  ? const Color(0xFFEAB308)
                  : rank == 2
                      ? const Color(0xFF94A3B8)
                      : rank == 3
                          ? const Color(0xFFB45309)
                          : JoynColors.secondaryText;

              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  children: [
                    Container(
                      width: 26,
                      height: 26,
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
                          fontSize: 11,
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
                            style: JoynTypography.bodyMedium.copyWith(
                              fontWeight: FontWeight.w700,
                              fontSize: 13.5,
                              color: JoynColors.primaryText,
                            ),
                          ),
                          Row(
                            children: [
                              if (item.itemCode.isNotEmpty) ...[
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                                  decoration: BoxDecoration(
                                    color: JoynColors.primary.withValues(alpha: 0.08),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    item.itemCode,
                                    style: JoynTypography.caption.copyWith(
                                      color: JoynColors.primary,
                                      fontSize: 9.5,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 6),
                              ],
                              Text(
                                '${item.qtySold.toStringAsFixed(item.qtySold % 1 == 0 ? 0 : 2)} ${item.unit} sold',
                                style: JoynTypography.caption.copyWith(
                                  color: JoynColors.secondaryText,
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
                          '₹${item.totalRevenue.toStringAsFixed(2)}',
                          style: JoynTypography.bodyMedium.copyWith(
                            fontWeight: FontWeight.w800,
                            fontSize: 14,
                            color: const Color(0xFF16A34A),
                          ),
                        ),
                        Text(
                          '${item.percentageShare.toStringAsFixed(1)}% share',
                          style: JoynTypography.caption.copyWith(
                            color: JoynColors.secondaryText,
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // DEAD STOCK / LEAST SELLING ITEMS
  // ═══════════════════════════════════════════════════════════════
  Widget _buildDeadStockSection() {
    final deadItems = _summary.leastSellingItems.take(4).toList();

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: JoynColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: JoynColors.border, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
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
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEF2F2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.inventory_rounded, color: JoynColors.error, size: 16),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Dead Stock & Slow Movers',
                    style: JoynTypography.bodyLarge.copyWith(
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                      color: JoynColors.primaryText,
                    ),
                  ),
                ],
              ),
              InkWell(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ItemSalesAnalyticsScreen(
                        mostSellingItems: _summary.mostSellingItems,
                        leastSellingItems: _summary.leastSellingItems,
                        totalGrossSales: _summary.grossSales,
                        dateRangeLabel: _rangeLabel,
                      ),
                    ),
                  );
                },
                child: Row(
                  children: [
                    Text(
                      'View All (${_summary.leastSellingItems.length})',
                      style: JoynTypography.caption.copyWith(
                        color: JoynColors.primary,
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                      ),
                    ),
                    const Icon(Icons.arrow_forward_ios_rounded, size: 11, color: JoynColors.primary),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Active inventory items with zero sales movement during this timeframe',
            style: JoynTypography.caption.copyWith(
              color: JoynColors.secondaryText,
              fontSize: 11,
            ),
          ),
          const SizedBox(height: 14),

          if (deadItems.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Center(
                child: Text(
                  'Great job! No dead inventory items found.',
                  style: JoynTypography.bodyMedium.copyWith(color: const Color(0xFF16A34A), fontWeight: FontWeight.w600),
                ),
              ),
            )
          else
            ...deadItems.map((item) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(7),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFFBEB),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.hourglass_empty_rounded, size: 14, color: Color(0xFFD97706)),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.name,
                            style: JoynTypography.bodyMedium.copyWith(
                              fontWeight: FontWeight.w700,
                              fontSize: 13.5,
                              color: JoynColors.primaryText,
                            ),
                          ),
                          Row(
                            children: [
                              if (item.itemCode.isNotEmpty) ...[
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                                  decoration: BoxDecoration(
                                    color: JoynColors.primary.withValues(alpha: 0.08),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    item.itemCode,
                                    style: JoynTypography.caption.copyWith(
                                      color: JoynColors.primary,
                                      fontSize: 9.5,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 6),
                              ],
                              Text(
                                '${item.currentStock} ${item.unit} in stock',
                                style: JoynTypography.caption.copyWith(
                                  color: JoynColors.secondaryText,
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
                          style: JoynTypography.bodyMedium.copyWith(
                            fontWeight: FontWeight.w800,
                            fontSize: 14,
                            color: JoynColors.error,
                          ),
                        ),
                        Text(
                          'Blocked Capital',
                          style: JoynTypography.caption.copyWith(
                            color: JoynColors.secondaryText,
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // TOP PARTIES (CUSTOMERS & SUPPLIERS)
  // ═══════════════════════════════════════════════════════════════
  Widget _buildTopPartiesSection() {
    final customers = _summary.topCustomers.take(4).toList();

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: JoynColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: JoynColors.border, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
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
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEFF6FF),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.people_alt_rounded, color: Color(0xFF2563EB), size: 16),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'VIP Customers',
                    style: JoynTypography.bodyLarge.copyWith(
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                      color: JoynColors.primaryText,
                    ),
                  ),
                ],
              ),
              InkWell(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => PartyAnalyticsScreen(
                        topCustomers: _summary.topCustomers,
                        topSuppliers: _summary.topSuppliers,
                        creditAging: _summary.creditAging,
                        totalReceivables: _summary.youllGet,
                        dateRangeLabel: _rangeLabel,
                      ),
                    ),
                  );
                },
                child: Row(
                  children: [
                    Text(
                      'View All (${_summary.topCustomers.length})',
                      style: JoynTypography.caption.copyWith(
                        color: JoynColors.primary,
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                      ),
                    ),
                    const Icon(Icons.arrow_forward_ios_rounded, size: 11, color: JoynColors.primary),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          if (customers.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Center(
                child: Text(
                  'No customer sales recorded for this period',
                  style: JoynTypography.bodyMedium.copyWith(color: JoynColors.secondaryText),
                ),
              ),
            )
          else
            ...customers.asMap().entries.map((entry) {
              final rank = entry.key + 1;
              final party = entry.value;

              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  children: [
                    Container(
                      width: 26,
                      height: 26,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: JoynColors.primary.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        '#$rank',
                        style: JoynTypography.caption.copyWith(
                          color: JoynColors.primary,
                          fontWeight: FontWeight.w800,
                          fontSize: 11,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            party.name,
                            style: JoynTypography.bodyMedium.copyWith(
                              fontWeight: FontWeight.w700,
                              fontSize: 13.5,
                              color: JoynColors.primaryText,
                            ),
                          ),
                          Row(
                            children: [
                              if (party.partyCode.isNotEmpty) ...[
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                                  decoration: BoxDecoration(
                                    color: JoynColors.primary.withValues(alpha: 0.08),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    party.partyCode,
                                    style: JoynTypography.caption.copyWith(
                                      color: JoynColors.primary,
                                      fontSize: 9.5,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 6),
                              ],
                              Text(
                                '${party.orderCount} Orders',
                                style: JoynTypography.caption.copyWith(
                                  color: JoynColors.secondaryText,
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
                          '₹${party.totalVolume.toStringAsFixed(2)}',
                          style: JoynTypography.bodyMedium.copyWith(
                            fontWeight: FontWeight.w800,
                            fontSize: 14,
                            color: const Color(0xFF16A34A),
                          ),
                        ),
                        if (party.balanceDue > 0)
                          Text(
                            'Due ₹${party.balanceDue.toStringAsFixed(0)}',
                            style: JoynTypography.caption.copyWith(
                              color: JoynColors.error,
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // PAYMENT MODES BREAKDOWN
  // ═══════════════════════════════════════════════════════════════
  Widget _buildPaymentModesSection() {
    final modes = _summary.paymentModeBreakdown;
    final total = modes.values.fold(0.0, (sum, val) => sum + val);

    final cash = modes['Cash'] ?? 0.0;
    final upi = modes['UPI / Online'] ?? 0.0;
    final bank = modes['Bank'] ?? 0.0;
    final credit = modes['Credit'] ?? 0.0;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: JoynColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: JoynColors.border, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: const Color(0xFFF3E8FF),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.pie_chart_outline_rounded, color: Color(0xFF9333EA), size: 16),
              ),
              const SizedBox(width: 8),
              Text(
                'Payment Mode Distribution',
                style: JoynTypography.bodyLarge.copyWith(
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                  color: JoynColors.primaryText,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Proportional Bar
          if (total > 0)
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: SizedBox(
                height: 10,
                child: Row(
                  children: [
                    if (cash > 0)
                      Expanded(
                        flex: ((cash / total) * 100).toInt().clamp(1, 100),
                        child: Container(color: const Color(0xFF10B981)),
                      ),
                    if (upi > 0)
                      Expanded(
                        flex: ((upi / total) * 100).toInt().clamp(1, 100),
                        child: Container(color: const Color(0xFF8B5CF6)),
                      ),
                    if (bank > 0)
                      Expanded(
                        flex: ((bank / total) * 100).toInt().clamp(1, 100),
                        child: Container(color: const Color(0xFF3B82F6)),
                      ),
                    if (credit > 0)
                      Expanded(
                        flex: ((credit / total) * 100).toInt().clamp(1, 100),
                        child: Container(color: const Color(0xFFEF4444)),
                      ),
                  ],
                ),
              ),
            ),
          const SizedBox(height: 14),

          // Legend Chips
          Row(
            children: [
              Expanded(
                child: _buildPaymentLegend(
                  'Cash',
                  '₹${cash.toStringAsFixed(0)}',
                  total > 0 ? '${((cash / total) * 100).toStringAsFixed(0)}%' : '0%',
                  const Color(0xFF10B981),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildPaymentLegend(
                  'UPI / QR',
                  '₹${upi.toStringAsFixed(0)}',
                  total > 0 ? '${((upi / total) * 100).toStringAsFixed(0)}%' : '0%',
                  const Color(0xFF8B5CF6),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _buildPaymentLegend(
                  'Bank / Cheque',
                  '₹${bank.toStringAsFixed(0)}',
                  total > 0 ? '${((bank / total) * 100).toStringAsFixed(0)}%' : '0%',
                  const Color(0xFF3B82F6),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildPaymentLegend(
                  'Credit / Khata',
                  '₹${credit.toStringAsFixed(0)}',
                  total > 0 ? '${((credit / total) * 100).toStringAsFixed(0)}%' : '0%',
                  const Color(0xFFEF4444),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentLegend(String title, String amount, String share, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: JoynColors.background,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: JoynColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: JoynTypography.caption.copyWith(fontSize: 10, color: JoynColors.secondaryText)),
                Text(amount, style: JoynTypography.caption.copyWith(fontSize: 12, fontWeight: FontWeight.w800, color: JoynColors.primaryText)),
              ],
            ),
          ),
          Text(share, style: JoynTypography.caption.copyWith(fontSize: 11, fontWeight: FontWeight.w700, color: color)),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // STOCK HEALTH & ASSET VALUATION
  // ═══════════════════════════════════════════════════════════════
  Widget _buildStockValuationSection() {
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => StockHealthScreen(
              outOfStockItems: _summary.outOfStockItems,
              lowStockItems: _summary.lowStockItems,
              totalStockCost: _summary.totalStockValuationCost,
              potentialStockSale: _summary.potentialStockValuationSale,
              totalItemsCount: _summary.totalItemsCount,
            ),
          ),
        );
      },
      borderRadius: BorderRadius.circular(20),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [const Color(0xFF1E293B), const Color(0xFF0F172A)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
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
                Row(
                  children: [
                    const Icon(Icons.warehouse_rounded, color: Color(0xFF38BDF8), size: 18),
                    const SizedBox(width: 8),
                    Text(
                      'Inventory Assets & Valuation',
                      style: JoynTypography.bodyLarge.copyWith(
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
                const Icon(Icons.arrow_forward_ios_rounded, size: 12, color: Colors.white70),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Stock Value at Cost',
                          style: JoynTypography.caption.copyWith(color: Colors.white60, fontSize: 10.5)),
                      Text(
                        '₹${_summary.totalStockValuationCost.toStringAsFixed(2)}',
                        style: JoynTypography.titleMedium.copyWith(
                          fontWeight: FontWeight.w800,
                          fontSize: 16.5,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(width: 1, height: 30, color: Colors.white24),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Potential Sale Value',
                          style: JoynTypography.caption.copyWith(color: Colors.white60, fontSize: 10.5)),
                      Text(
                        '₹${_summary.potentialStockValuationSale.toStringAsFixed(2)}',
                        style: JoynTypography.titleMedium.copyWith(
                          fontWeight: FontWeight.w800,
                          fontSize: 16.5,
                          color: const Color(0xFF34D399),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.check_circle_outline_rounded, color: Color(0xFF38BDF8), size: 14),
                  const SizedBox(width: 6),
                  Text(
                    '${_summary.totalItemsCount} catalog items • Tap to inspect reorder alerts',
                    style: JoynTypography.caption.copyWith(color: Colors.white70, fontSize: 11),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // ERROR VIEW
  // ═══════════════════════════════════════════════════════════════
  Widget _buildErrorView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline_rounded, color: JoynColors.error, size: 48),
            const SizedBox(height: 16),
            Text(
              'Failed to load Analytics',
              style: JoynTypography.titleMedium.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            Text(
              '$_errorMessage',
              textAlign: TextAlign.center,
              style: JoynTypography.bodyMedium.copyWith(color: JoynColors.secondaryText, fontSize: 13),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _loadData,
              icon: const Icon(Icons.refresh_rounded, size: 16),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: JoynColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
