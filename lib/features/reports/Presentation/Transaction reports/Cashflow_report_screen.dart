import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:joyn/core/theme/joyn_typography.dart';
import 'package:joyn/core/theme/joyn_colors.dart';
import 'package:joyn/core/widgets/Premium_widget.dart';

class CashTxn {
  final String name;
  final DateTime date;
  final String txnType;
  final double amount;

  CashTxn({required this.name, required this.date, required this.txnType, required this.amount});
}

class CashflowReportScreen extends StatefulWidget {
  const CashflowReportScreen({super.key});

  @override
  State<CashflowReportScreen> createState() => _CashflowReportScreenState();
}

class _CashflowReportScreenState extends State<CashflowReportScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  String selectedPeriod = 'This Month';
  DateTime fromDate = DateTime(2026, 9, 1);
  DateTime toDate = DateTime(2026, 9, 30);

  bool showZeroValueTxns = true;
  bool considerOpeningClosingCash = true;

  double openingCash = 0.00;
  double moneyIn = 500.00;
  double moneyOut = 0.00;
  double get closingCash => openingCash + moneyIn - moneyOut;

  final List<CashTxn> moneyInTxns = [
    CashTxn(name: 'Gopal', date: DateTime(2026, 9, 5), txnType: 'Sale', amount: 500.00),
    CashTxn(name: 'gill', date: DateTime(2026, 9, 5), txnType: 'Sale', amount: 0.00),
  ];

  final List<CashTxn> moneyOutTxns = [];

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
      });
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

  void _openFiltersSheet() async {
    HapticFeedback.selectionClick();
    bool tempShowZero = showZeroValueTxns;
    bool tempConsider = considerOpeningClosingCash;

    final result = await showModalBottomSheet<Map<String, bool>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: JoynColors.background,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: JoynColors.border,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Filters',
                          style: JoynTypography.titleMedium.copyWith(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        IconButton(
                          icon: Icon(Icons.close_rounded, color: JoynColors.secondaryText),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    _filterToggleRow(
                      title: '0 Value Transactions',
                      trueLabel: 'Show',
                      falseLabel: "Don't Show",
                      value: tempShowZero,
                      onChanged: (v) => setModalState(() => tempShowZero = v),
                    ),
                    const SizedBox(height: 16),
                    _filterToggleRow(
                      title: 'Opening / Closing Cash',
                      trueLabel: 'Consider',
                      falseLabel: "Don't Consider",
                      value: tempConsider,
                      onChanged: (v) => setModalState(() => tempConsider = v),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                              side: BorderSide(color: JoynColors.border),
                              backgroundColor: JoynColors.surface,
                            ),
                            onPressed: () => setModalState(() {
                              tempShowZero = true;
                              tempConsider = true;
                            }),
                            child: Text(
                              'Reset',
                              style: JoynTypography.bodyMedium.copyWith(fontWeight: FontWeight.w600),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: JoynColors.primary,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                              elevation: 0,
                            ),
                            onPressed: () => Navigator.pop(context, {
                              'showZero': tempShowZero,
                              'consider': tempConsider
                            }),
                            child: Text('Apply', style: JoynTypography.buttonText.copyWith(fontSize: 14)),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );

    if (result != null) {
      setState(() {
        showZeroValueTxns = result['showZero']!;
        considerOpeningClosingCash = result['consider']!;
      });
    }
  }

  Widget _filterToggleRow({
    required String title,
    required String trueLabel,
    required String falseLabel,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: JoynTypography.bodyMedium.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(child: _toggleOption(trueLabel, value == true, () => onChanged(true))),
            const SizedBox(width: 10),
            Expanded(child: _toggleOption(falseLabel, value == false, () => onChanged(false))),
          ],
        ),
      ],
    );
  }

  Widget _toggleOption(String label, bool selected, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? JoynColors.primary : JoynColors.chipBackground,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          label,
          style: JoynTypography.caption.copyWith(
            color: selected ? Colors.white : JoynColors.primary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
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
          'Cashflow',
          style: JoynTypography.titleMedium.copyWith(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: JoynColors.primary,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search_rounded, color: JoynColors.primary),
            onPressed: () => _showSnackBar('Search coming soon!'),
          ),
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
          const SizedBox(height: 12),
          _buildFilterChips(),
          const SizedBox(height: 12),
          _buildCashSummaryCard(currency),
          const SizedBox(height: 16),
          _buildTabBar(),
          _buildTableHeader(),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _TxnListView(
                  txns: moneyInTxns,
                  amountColor: JoynColors.success,
                  totalLabel: 'Total Money In',
                  totalValue: moneyInTxns.fold(0.0, (s, t) => s + t.amount),
                  totalPrefix: '+',
                  totalColor: const Color(0xFF4ADE80),
                  currency: currency,
                  isMoneyIn: true,
                ),
                _TxnListView(
                  txns: moneyOutTxns,
                  amountColor: JoynColors.error,
                  totalLabel: 'Total Money Out',
                  totalValue: moneyOutTxns.fold(0.0, (s, t) => s + t.amount),
                  totalPrefix: '-',
                  totalColor: const Color(0xFFF87171),
                  currency: currency,
                  isMoneyIn: false,
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

  // Enhanced Filter Chips
  Widget _buildFilterChips() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                _buildFilterChip(
                  icon: Icons.filter_none_rounded,
                  label: '0 Value · ${showZeroValueTxns ? 'Show' : "Don't Show"}',
                ),
                _buildFilterChip(
                  icon: Icons.account_balance_rounded,
                  label: 'Open/Close · ${considerOpeningClosingCash ? 'Consider' : 'Skip'}',
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Material(
            color: JoynColors.primary,
            borderRadius: BorderRadius.circular(24),
            child: InkWell(
              onTap: _openFiltersSheet,
              borderRadius: BorderRadius.circular(24),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                child: Row(
                  children: [
                    const Icon(Icons.tune_rounded, size: 16, color: Colors.white),
                    const SizedBox(width: 6),
                    Text(
                      'Filters',
                      style: JoynTypography.bodyMedium.copyWith(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip({required IconData icon, required String label}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: JoynColors.iconBackground,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: JoynColors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: JoynColors.primary),
          const SizedBox(width: 4),
          Text(
            label,
            style: JoynTypography.caption.copyWith(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: JoynColors.primary,
            ),
          ),
        ],
      ),
    );
  }

  // Enhanced Cash Summary Card
  Widget _buildCashSummaryCard(NumberFormat currency) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
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
          // Closing Cash
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.account_balance_wallet_rounded,
                  size: 20,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Closing Cash',
                    style: JoynTypography.caption.copyWith(
                      fontSize: 11,
                      color: Colors.white70,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '₹ ${currency.format(closingCash)}',
                    style: JoynTypography.bodyLarge.copyWith(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF4ADE80),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(height: 1, color: Colors.white24),
          const SizedBox(height: 14),
          // Cash Flow Breakdown
          Row(
            children: [
              _buildCashFlowItem('Opening', openingCash, Colors.white, currency),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Text('+', style: TextStyle(color: Colors.white54, fontSize: 18)),
              ),
              _buildCashFlowItem('Money In', moneyIn, const Color(0xFF4ADE80), currency),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Text('-', style: TextStyle(color: Colors.white54, fontSize: 18)),
              ),
              _buildCashFlowItem('Money Out', moneyOut, const Color(0xFFF87171), currency),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCashFlowItem(String label, double value, Color color, NumberFormat currency) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: JoynTypography.caption.copyWith(
              fontSize: 10,
              color: Colors.white70,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '₹ ${currency.format(value)}',
            style: JoynTypography.bodyMedium.copyWith(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: color,
            ),
            overflow: TextOverflow.ellipsis,
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
        tabs: const [Tab(text: 'Money In'), Tab(text: 'Money Out')],
      ),
    );
  }

  // Enhanced Table Header
  Widget _buildTableHeader() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: JoynColors.surfaceMuted,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Text(
              'Name & Date',
              style: JoynTypography.caption.copyWith(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: JoynColors.secondaryText,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              'Type',
              textAlign: TextAlign.center,
              style: JoynTypography.caption.copyWith(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: JoynColors.secondaryText,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              _tabController.index == 0 ? 'Money In' : 'Money Out',
              textAlign: TextAlign.right,
              style: JoynTypography.caption.copyWith(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: JoynColors.secondaryText,
              ),
            ),
          ),
        ],
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

class _TxnListView extends StatelessWidget {
  final List<CashTxn> txns;
  final Color amountColor;
  final String totalLabel;
  final double totalValue;
  final String totalPrefix;
  final Color totalColor;
  final NumberFormat currency;
  final bool isMoneyIn;

  const _TxnListView({
    required this.txns,
    required this.amountColor,
    required this.totalLabel,
    required this.totalValue,
    required this.totalPrefix,
    required this.totalColor,
    required this.currency,
    required this.isMoneyIn,
  });

  @override
  Widget build(BuildContext context) {
    final dateFmt = DateFormat('dd MMM, yy');

    return Column(
      children: [
        Expanded(
          child: txns.isEmpty
              ? Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      color: JoynColors.surface,
                      shape: BoxShape.circle,
                      border: Border.all(color: JoynColors.border, width: 2),
                    ),
                    child: Icon(
                      isMoneyIn ? Icons.south_west_rounded : Icons.north_east_rounded,
                      size: 40,
                      color: JoynColors.secondaryText.withValues(alpha: 0.5),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Nothing here',
                    style: JoynTypography.titleMedium.copyWith(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: JoynColors.primary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Transactions in this category will show up here.',
                    textAlign: TextAlign.center,
                    style: JoynTypography.bodyMedium.copyWith(
                      fontSize: 12,
                      color: JoynColors.secondaryText,
                    ),
                  ),
                ],
              ),
            ),
          )
              : ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            itemCount: txns.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final t = txns[index];
              final initials = t.name.isNotEmpty ? t.name[0].toUpperCase() : '?';

              return TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: 1),
                duration: Duration(milliseconds: 300 + (index * 100)),
                builder: (context, value, child) {
                  return Opacity(
                    opacity: value,
                    child: Transform.translate(
                      offset: Offset(0, 20 * (1 - value)),
                      child: child,
                    ),
                  );
                },
                child: Container(
                  decoration: BoxDecoration(
                    color: JoynColors.iconBackground,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: JoynColors.border),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.03),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: [
                        // Avatar
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                amountColor.withValues(alpha: 0.1),
                                amountColor.withValues(alpha: 0.05),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            initials,
                            style: JoynTypography.bodyLarge.copyWith(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              color: amountColor,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        // Name & Date
                        Expanded(
                          flex: 3,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                t.name,
                                style: JoynTypography.bodyLarge.copyWith(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: JoynColors.primary,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 2),
                              Text(
                                dateFmt.format(t.date),
                                style: JoynTypography.caption.copyWith(
                                  fontSize: 10,
                                  color: JoynColors.secondaryText,
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Type
                        Expanded(
                          flex: 2,
                          child: Center(
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: JoynColors.chipBackground,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                t.txnType,
                                style: JoynTypography.caption.copyWith(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: JoynColors.primary,
                                ),
                              ),
                            ),
                          ),
                        ),
                        // Amount
                        Expanded(
                          flex: 2,
                          child: Text(
                            '₹ ${currency.format(t.amount)}',
                            textAlign: TextAlign.right,
                            style: JoynTypography.bodyMedium.copyWith(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: t.amount == 0 ? JoynColors.primary : amountColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        // Total Bar
        Container(
          width: double.infinity,
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [
                JoynColors.primary,
                JoynColors.primary.withValues(alpha: 0.85),
              ],
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: JoynColors.primary.withValues(alpha: 0.2),
                blurRadius: 12,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                totalLabel,
                style: JoynTypography.bodyMedium.copyWith(
                  color: Colors.white70,
                  fontSize: 13,
                ),
              ),
              Text(
                '$totalPrefix ₹ ${currency.format(totalValue)}',
                style: JoynTypography.bodyLarge.copyWith(
                  color: totalColor,
                  fontWeight: FontWeight.w800,
                  fontSize: 15,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}