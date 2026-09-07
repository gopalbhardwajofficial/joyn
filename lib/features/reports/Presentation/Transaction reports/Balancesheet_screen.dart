import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:joyn/core/theme/joyn_typography.dart';
import 'package:joyn/core/theme/joyn_colors.dart';
import 'package:joyn/core/widgets/Premium_widget.dart';

enum RowStyle { normal, subtotal }

class BsRow {
  final String label;
  final double amount;
  final RowStyle style;
  final bool expandable;
  final List<BsRow> children;

  BsRow({
    required this.label,
    required this.amount,
    this.style = RowStyle.normal,
    this.expandable = false,
    this.children = const [],
  });
}

class BsCard {
  final List<BsRow> rows;
  BsCard(this.rows);
}

class BalanceSheetScreen extends StatefulWidget {
  const BalanceSheetScreen({super.key});

  @override
  State<BalanceSheetScreen> createState() => _BalanceSheetScreenState();
}

class _BalanceSheetScreenState extends State<BalanceSheetScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  String selectedPeriod = 'This Month';
  DateTime fromDate = DateTime(2026, 9, 1);
  DateTime toDate = DateTime(2026, 9, 30);
  bool _isLoading = false;

  final Set<String> expandedRows = {};

  double get totalLiabilities => 1100.00;
  double get totalAssets => 1100.00;

  late final List<BsCard> liabilityCards = [
    BsCard([
      BsRow(label: "Owner's Equity", amount: 0.00),
      BsRow(
        label: 'Reserves & Surplus',
        amount: 1100.00,
        expandable: true,
        children: [BsRow(label: 'Net Profit', amount: 1100.00)],
      ),
      BsRow(label: 'Equity/Capital', amount: 1100.00, style: RowStyle.subtotal),
    ]),
    BsCard([
      BsRow(label: 'Loan Accounts', amount: 0.00),
      BsRow(label: 'Long Term Liabilities', amount: 0.00, style: RowStyle.subtotal),
    ]),
    BsCard([
      BsRow(label: 'Sundry Creditors', amount: 0.00),
      BsRow(label: 'Outward Duties & Taxes', amount: 0.00),
      BsRow(label: 'Other Current Liabilities', amount: 0.00),
      BsRow(label: 'Current Liabilities', amount: 0.00, style: RowStyle.subtotal),
    ]),
    BsCard([BsRow(label: 'Other Liabilities', amount: 0.00, style: RowStyle.subtotal)]),
  ];

  late final List<BsCard> assetCards = [
    BsCard([
      BsRow(label: 'Cash In Hand', amount: 500.00),
      BsRow(label: 'Bank Accounts', amount: 0.00),
      BsRow(label: 'Cash & Bank Balance', amount: 500.00, style: RowStyle.subtotal),
    ]),
    BsCard([
      BsRow(label: 'Sundry Debtors', amount: 500.00),
      BsRow(label: 'Inward Duties & Taxes', amount: 0.00),
      BsRow(label: 'Other Current Assets', amount: 0.00),
      BsRow(label: 'Stock In Hand', amount: 0.00),
      BsRow(label: 'Current Assets', amount: 1000.00, style: RowStyle.subtotal),
    ]),
    BsCard([BsRow(label: 'Fixed Assets', amount: 0.00, style: RowStyle.subtotal)]),
    BsCard([BsRow(label: 'Other Assets', amount: 100.00, style: RowStyle.subtotal)]),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _pickDateRange() async {
    HapticFeedback.lightImpact();
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      initialDateRange: DateTimeRange(start: fromDate, end: toDate),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(
            primary: JoynColors.primary,
            surface: JoynColors.iconBackground,
          ),
          dialogBackgroundColor: JoynColors.background,
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() {
        fromDate = picked.start;
        toDate = picked.end;
        selectedPeriod = 'Custom';
        _isLoading = true;
      });
      await Future.delayed(const Duration(milliseconds: 500));
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _pickPeriod() async {
    HapticFeedback.selectionClick();
    final options = ['Today', 'This Week', 'This Month', 'This Year', 'Custom'];
    final result = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: JoynColors.background,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 12, 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Select Period',
                    style: JoynTypography.titleMedium.copyWith(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.close_rounded, color: JoynColors.secondaryText),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            Divider(height: 1, color: JoynColors.border),
            ...options.map((o) => ListTile(
              title: Text(
                o,
                style: JoynTypography.bodyLarge.copyWith(
                  fontWeight: o == selectedPeriod ? FontWeight.w700 : FontWeight.w500,
                  color: JoynColors.primary,
                ),
              ),
              trailing: o == selectedPeriod
                  ? Icon(Icons.check_rounded, color: JoynColors.primary)
                  : null,
              onTap: () => Navigator.pop(context, o),
            )),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
    if (result != null) setState(() => selectedPeriod = result);
  }

  @override
  Widget build(BuildContext context) {
    final dateFmt = DateFormat('dd MMM');
    final currency = NumberFormat('#,##0.00', 'en_IN');

    return Scaffold(
      backgroundColor: JoynColors.background,
      appBar: AppBar(
        backgroundColor: JoynColors.background,
        elevation: 0,
        scrolledUnderElevation: 0,
        titleSpacing: 20,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: JoynColors.primary),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Balance Sheet',
          style: JoynTypography.titleMedium.copyWith(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: JoynColors.primary,
          ),
        ),
        actions: [
          _buildAppBarIconButton(
            label: 'Pdf',
            icon: Icons.picture_as_pdf_rounded,
            color: const Color(0xFFDC2626),
            onTap: () => _showSnackBar('Exporting PDF...'),
          ),
          const SizedBox(width: 6),
          _buildAppBarIconButton(
            label: 'xls',
            icon: Icons.grid_on_rounded,
            color: JoynColors.success,
            onTap: () => _showSnackBar('Exporting Excel...'),
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: Column(
        children: [
          _buildPeriodSelector(dateFmt),
          const SizedBox(height: 16),
          _buildTabBar(),
          const SizedBox(height: 8),
          Expanded(
            child: _isLoading
                ? const Center(
              child: CircularProgressIndicator(color: JoynColors.primary),
            )
                : TabBarView(
              controller: _tabController,
              children: [
                _BalanceSheetTab(
                  totalLabel: 'Total Liabilities',
                  totalValue: totalLiabilities,
                  formula: 'Equity/Capital + Long Term Liabilities + Current Liabilities + Other Liabilities',
                  cards: liabilityCards,
                  expandedRows: expandedRows,
                  currency: currency,
                  onToggleExpand: (key) => setState(() {
                    expandedRows.contains(key) ? expandedRows.remove(key) : expandedRows.add(key);
                  }),
                  tabKey: 'liab',
                  isLiability: true,
                ),
                _BalanceSheetTab(
                  totalLabel: 'Total Assets',
                  totalValue: totalAssets,
                  formula: 'Cash & Bank Balance + Current Assets + Fixed Assets + Other Assets',
                  cards: assetCards,
                  expandedRows: expandedRows,
                  currency: currency,
                  onToggleExpand: (key) => setState(() {
                    expandedRows.contains(key) ? expandedRows.remove(key) : expandedRows.add(key);
                  }),
                  tabKey: 'asset',
                  isLiability: false,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Enhanced Period Selector
  Widget _buildPeriodSelector(DateFormat dateFmt) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: JoynColors.iconBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: JoynColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: InkWell(
              onTap: _pickPeriod,
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: JoynColors.surfaceMuted,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(Icons.date_range_rounded, size: 18, color: JoynColors.primary),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        selectedPeriod,
                        style: JoynTypography.bodyMedium.copyWith(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: JoynColors.primary,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Icon(Icons.keyboard_arrow_down_rounded, size: 18, color: JoynColors.secondaryText),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          InkWell(
            onTap: _pickDateRange,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: JoynColors.surfaceMuted,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(Icons.calendar_today_rounded, size: 16, color: JoynColors.primary),
                  const SizedBox(width: 6),
                  Text(
                    '${dateFmt.format(fromDate)} - ${dateFmt.format(toDate)}',
                    style: JoynTypography.caption.copyWith(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: JoynColors.secondaryText,
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

  // Enhanced Tab Bar
  Widget _buildTabBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: JoynColors.surfaceMuted,
        borderRadius: BorderRadius.circular(14),
      ),
      child: TabBar(
        controller: _tabController,
        indicator: BoxDecoration(
          color: JoynColors.primary,
          borderRadius: BorderRadius.circular(11),
          boxShadow: [
            BoxShadow(
              color: JoynColors.primary.withValues(alpha: 0.3),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        dividerColor: Colors.transparent,
        labelColor: Colors.white,
        unselectedLabelColor: JoynColors.secondaryText,
        labelStyle: JoynTypography.caption.copyWith(fontWeight: FontWeight.w700),
        unselectedLabelStyle: JoynTypography.caption.copyWith(fontWeight: FontWeight.w600),
        tabs: const [Tab(text: 'Liabilities'), Tab(text: 'Assets')],
      ),
    );
  }

  // AppBar Icon Button
  Widget _buildAppBarIconButton({
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      borderRadius: BorderRadius.circular(10),
      child: Container(
        width: 38,
        height: 38,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              color.withValues(alpha: 0.9),
              color,
            ],
          ),
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.3),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: Colors.white),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 8,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: JoynTypography.bodyMedium.copyWith(color: Colors.white),
        ),
        backgroundColor: JoynColors.primary,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(milliseconds: 1500),
      ),
    );
  }
}

class _BalanceSheetTab extends StatelessWidget {
  final String totalLabel;
  final double totalValue;
  final String formula;
  final List<BsCard> cards;
  final Set<String> expandedRows;
  final NumberFormat currency;
  final void Function(String key) onToggleExpand;
  final String tabKey;
  final bool isLiability;

  const _BalanceSheetTab({
    required this.totalLabel,
    required this.totalValue,
    required this.formula,
    required this.cards,
    required this.expandedRows,
    required this.currency,
    required this.onToggleExpand,
    required this.tabKey,
    required this.isLiability,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
      children: [
        _buildTotalCard(),
        const SizedBox(height: 16),
        _buildTableHeader(),
        const SizedBox(height: 8),
        for (int i = 0; i < cards.length; i++) ...[
          _RowsCard(
            rows: cards[i].rows,
            expandedRows: expandedRows,
            currency: currency,
            onToggleExpand: onToggleExpand,
            keyPrefix: '$tabKey-$i',
          ),
          const SizedBox(height: 12),
        ],
      ],
    );
  }

  // Enhanced Total Card
  Widget _buildTotalCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            JoynColors.primary,
            JoynColors.primary.withValues(alpha: 0.9),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: JoynColors.primary.withValues(alpha: 0.2),
            blurRadius: 20,
            offset: const Offset(0, 8),
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
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      isLiability ? Icons.account_balance_rounded : Icons.trending_up_rounded,
                      size: 18,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    totalLabel,
                    style: JoynTypography.bodyMedium.copyWith(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.white70,
                    ),
                  ),
                ],
              ),
              Text(
                '₹ ${currency.format(totalValue)}',
                style: JoynTypography.bodyLarge.copyWith(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(height: 1, color: Colors.white24),
          const SizedBox(height: 10),
          Text(
            formula,
            style: JoynTypography.caption.copyWith(
              fontSize: 10,
              color: Colors.white54,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  // Enhanced Table Header
  Widget _buildTableHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: JoynColors.surfaceMuted,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Particulars',
            style: JoynTypography.caption.copyWith(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: JoynColors.secondaryText,
            ),
          ),
          Text(
            'Amount',
            style: JoynTypography.caption.copyWith(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: JoynColors.secondaryText,
            ),
          ),
        ],
      ),
    );
  }
}

class _RowsCard extends StatelessWidget {
  final List<BsRow> rows;
  final Set<String> expandedRows;
  final NumberFormat currency;
  final void Function(String key) onToggleExpand;
  final String keyPrefix;

  const _RowsCard({
    required this.rows,
    required this.expandedRows,
    required this.currency,
    required this.onToggleExpand,
    required this.keyPrefix,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: JoynColors.iconBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: JoynColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          for (int i = 0; i < rows.length; i++) ...[
            _buildRow(rows[i], '$keyPrefix-$i'),
            if (i != rows.length - 1)
              Container(
                height: 0.8,
                color: JoynColors.border.withValues(alpha: 0.5),
                margin: const EdgeInsets.symmetric(horizontal: 16),
              ),
          ],
        ],
      ),
    );
  }

  Widget _buildRow(BsRow row, String key) {
    final isSubtotal = row.style == RowStyle.subtotal;
    final isExpanded = expandedRows.contains(key);

    return Column(
      children: [
        InkWell(
          onTap: row.expandable ? () => onToggleExpand(key) : null,
          child: Container(
            color: isSubtotal ? JoynColors.surfaceMuted : Colors.transparent,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                if (row.expandable) ...[
                  AnimatedRotation(
                    turns: isExpanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 200),
                    child: Icon(
                      Icons.keyboard_arrow_down_rounded,
                      size: 20,
                      color: JoynColors.primary,
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
                Expanded(
                  child: Text(
                    row.label,
                    style: JoynTypography.bodyMedium.copyWith(
                      fontSize: isSubtotal ? 15 : 14,
                      fontWeight: isSubtotal ? FontWeight.w700 : FontWeight.w400,
                      color: JoynColors.primary,
                    ),
                  ),
                ),
                Text(
                  '₹ ${currency.format(row.amount)}',
                  style: JoynTypography.bodyMedium.copyWith(
                    fontSize: isSubtotal ? 15 : 14,
                    fontWeight: isSubtotal ? FontWeight.w700 : FontWeight.w500,
                    color: JoynColors.primary,
                  ),
                ),
              ],
            ),
          ),
        ),
        if (row.expandable && isExpanded)
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.only(left: 42, right: 16, bottom: 12, top: 4),
            child: Column(
              children: row.children
                  .map(
                    (c) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 4,
                            height: 4,
                            decoration: BoxDecoration(
                              color: JoynColors.secondaryText,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            c.label,
                            style: JoynTypography.caption.copyWith(
                              fontSize: 12,
                              color: JoynColors.secondaryText,
                            ),
                          ),
                        ],
                      ),
                      Text(
                        '₹ ${currency.format(c.amount)}',
                        style: JoynTypography.caption.copyWith(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: JoynColors.primary,
                        ),
                      ),
                    ],
                  ),
                ),
              )
                  .toList(),
            ),
          ),
      ],
    );
  }
}