import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:joyn/core/theme/joyn_typography.dart';
import 'package:joyn/core/theme/joyn_colors.dart';
import 'package:joyn/core/widgets/Premium_widget.dart';

enum RowType { sectionHeader, item, highlight }

class PnlRow {
  final RowType type;
  final String label;
  final double? amount;
  final bool isPositive;

  PnlRow.sectionHeader(this.label)
      : type = RowType.sectionHeader,
        amount = null,
        isPositive = true;

  PnlRow.item(this.label, this.amount, {this.isPositive = true}) : type = RowType.item;

  PnlRow.highlight(this.label, this.amount)
      : type = RowType.highlight,
        isPositive = true;
}

class ProfitAndLossReportScreen extends StatefulWidget {
  const ProfitAndLossReportScreen({super.key});

  @override
  State<ProfitAndLossReportScreen> createState() => _ProfitAndLossReportScreenState();
}

class _ProfitAndLossReportScreenState extends State<ProfitAndLossReportScreen> {
  String selectedPeriod = 'This Month';
  DateTime fromDate = DateTime(2026, 9, 1);
  DateTime toDate = DateTime(2026, 9, 30);
  bool _isLoading = false;

  double grossProfit = 1100.00;
  double netProfit = 1100.00;

  late final List<PnlRow> rows = [
    PnlRow.item('Sale (+)', 1100.00, isPositive: true),
    PnlRow.item('Sale FA (+)', 0.00, isPositive: true),
    PnlRow.item('Cr. Note/Sale Return (-)', 0.00, isPositive: false),
    PnlRow.item('Purchase (-)', 0.00, isPositive: false),
    PnlRow.item('Purchase FA (-)', 0.00, isPositive: false),
    PnlRow.item('Dr. Note/Purchase Return (+)', 0.00, isPositive: true),
    PnlRow.item('Payment Out Discount (+)', 0.00, isPositive: true),
    PnlRow.sectionHeader('Stocks'),
    PnlRow.item('Opening Stock (-)', 0.00, isPositive: false),
    PnlRow.item('Closing Stock (+)', 0.00, isPositive: true),
    PnlRow.item('Opening FA Stock (-)', 0.00, isPositive: false),
    PnlRow.item('Closing FA Stock (+)', 0.00, isPositive: true),
    PnlRow.sectionHeader('Direct Expenses (-)'),
    PnlRow.item('Other Direct Expense', 0.00, isPositive: false),
    PnlRow.item('Payment In Discount', 0.00, isPositive: false),
    PnlRow.sectionHeader('Tax Payable (-)'),
    PnlRow.item('GST Payable', 0.00, isPositive: false),
    PnlRow.item('TCS Payable', 0.00, isPositive: false),
    PnlRow.item('TDS Payable', 0.00, isPositive: false),
    PnlRow.sectionHeader('Tax Receivable (+)'),
    PnlRow.item('GST Receivable', 0.00, isPositive: true),
    PnlRow.item('TCS Receivable', 0.00, isPositive: true),
    PnlRow.item('TDS Receivable', 0.00, isPositive: true),
    PnlRow.highlight('Gross Profit', 1100.00),
    PnlRow.sectionHeader('Other Income (+)'),
    PnlRow.item('Other Income', 0.00, isPositive: true),
    PnlRow.sectionHeader('Indirect Expenses (-)'),
    PnlRow.item('Other Expense', 0.00, isPositive: false),
    PnlRow.item('Loan Interest Expense', 0.00, isPositive: false),
    PnlRow.item('Loan Processing Fee Expense', 0.00, isPositive: false),
    PnlRow.item('Charges on Loan Expense', 0.00, isPositive: false),
    PnlRow.highlight('Net Profit', 1100.00),
  ];

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
          'Profit & Loss',
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
          const SizedBox(height: 12),
          _buildSummaryCards(currency),
          const SizedBox(height: 12),
          _buildTableHeader(),
          Expanded(
            child: _isLoading
                ? const Center(
              child: CircularProgressIndicator(color: JoynColors.primary),
            )
                : _buildPnlList(currency),
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

  // Enhanced Summary Cards
  Widget _buildSummaryCards(NumberFormat currency) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 0),
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
      child: Row(
        children: [
          Expanded(
            child: _buildSummaryItem(
              icon: Icons.stacked_line_chart_rounded,
              label: 'Gross Profit',
              value: '₹ ${currency.format(grossProfit)}',
              valueColor: const Color(0xFF4ADE80),
            ),
          ),
          Container(width: 1, height: 40, color: Colors.white24),
          Expanded(
            child: _buildSummaryItem(
              icon: Icons.savings_rounded,
              label: 'Net Profit',
              value: '₹ ${currency.format(netProfit)}',
              valueColor: const Color(0xFF4ADE80),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryItem({
    required IconData icon,
    required String label,
    required String value,
    Color? valueColor,
  }) {
    return Column(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 18, color: Colors.white),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: JoynTypography.caption.copyWith(
            fontSize: 10,
            color: Colors.white70,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: JoynTypography.bodyMedium.copyWith(
            fontSize: 14,
            fontWeight: FontWeight.w800,
            color: valueColor ?? Colors.white,
          ),
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  // Enhanced Table Header
  Widget _buildTableHeader() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: JoynColors.surfaceMuted,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              'Particulars',
              style: JoynTypography.caption.copyWith(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: JoynColors.secondaryText,
              ),
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

  // Enhanced P&L List
  Widget _buildPnlList(NumberFormat currency) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 20),
      decoration: BoxDecoration(
        color: JoynColors.iconBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: JoynColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: ListView.builder(
        padding: EdgeInsets.zero,
        itemCount: rows.length,
        itemBuilder: (context, index) {
          final row = rows[index];

          if (row.type == RowType.sectionHeader) {
            return Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              color: JoynColors.surfaceMuted,
              child: Row(
                children: [
                  Container(
                    width: 3,
                    height: 14,
                    decoration: BoxDecoration(
                      color: JoynColors.primary,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    row.label,
                    style: JoynTypography.caption.copyWith(
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.3,
                      color: JoynColors.primary,
                    ),
                  ),
                ],
              ),
            );
          }

          if (row.type == RowType.highlight) {
            return Container(
              width: double.infinity,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: [
                    JoynColors.success.withValues(alpha: 0.15),
                    JoynColors.success.withValues(alpha: 0.05),
                  ],
                ),
                border: Border(
                  top: BorderSide(color: JoynColors.success.withValues(alpha: 0.3)),
                  bottom: BorderSide(color: JoynColors.success.withValues(alpha: 0.3)),
                ),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(Icons.star_rounded, size: 16, color: JoynColors.success),
                      const SizedBox(width: 6),
                      Text(
                        row.label,
                        style: JoynTypography.bodyLarge.copyWith(
                          fontWeight: FontWeight.w800,
                          color: JoynColors.success,
                        ),
                      ),
                    ],
                  ),
                  Text(
                    '₹ ${currency.format(row.amount ?? 0)}',
                    style: JoynTypography.bodyLarge.copyWith(
                      fontWeight: FontWeight.w800,
                      color: JoynColors.success,
                    ),
                  ),
                ],
              ),
            );
          }

          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(color: JoynColors.border.withValues(alpha: 0.5)),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Container(
                        width: 4,
                        height: 4,
                        decoration: BoxDecoration(
                          color: row.isPositive ? JoynColors.success : JoynColors.error,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          row.label,
                          style: JoynTypography.bodyMedium.copyWith(
                            fontSize: 13,
                            color: JoynColors.primary,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  '₹ ${currency.format(row.amount ?? 0)}',
                  style: JoynTypography.bodyMedium.copyWith(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: row.isPositive ? JoynColors.success : JoynColors.error,
                  ),
                ),
              ],
            ),
          );
        },
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