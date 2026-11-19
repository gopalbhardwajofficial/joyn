import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:joyn/core/theme/joyn_typography.dart';
import 'package:joyn/core/theme/joyn_colors.dart';
import 'package:joyn/core/services/api_service.dart';
import 'package:joyn/core/services/report_export_service.dart';

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
  late DateTime fromDate;
  late DateTime toDate;
  bool _isLoading = true;

  double grossProfit = 0.00;
  double netProfit = 0.00;
  double grossSales = 0.00;
  double grossMarginPct = 0.0;
  double netMarginPct = 0.0;
  double cogs = 0.00;
  double operatingExpenses = 0.00;

  List<PnlRow> rows = [];

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    fromDate = DateTime(now.year, now.month, 1);
    toDate = DateTime(now.year, now.month + 1, 0);
    _fetchProfitAndLoss();
  }

  Future<void> _fetchProfitAndLoss() async {
    setState(() => _isLoading = true);
    final startStr = DateFormat('yyyy-MM-dd').format(fromDate);
    final endStr = DateFormat('yyyy-MM-dd').format(toDate);

    try {
      final res = await ApiService.fetchProfitAndLoss(startDate: startStr, endDate: endStr);
      if (res['success'] == true) {
        final gp = (res['grossProfit'] as num?)?.toDouble() ?? 0.0;
        final np = (res['netProfit'] as num?)?.toDouble() ?? 0.0;
        final gs = (res['grossSales'] as num?)?.toDouble() ?? 0.0;
        final gm = (res['grossMarginPct'] as num?)?.toDouble() ?? 0.0;
        final nm = (res['netMarginPct'] as num?)?.toDouble() ?? 0.0;
        final cg = (res['cogs'] as num?)?.toDouble() ?? 0.0;
        final opex = (res['indirectExpenses'] as num?)?.toDouble() ?? 0.0;
        final rawRows = res['rows'] as List? ?? [];

        final mappedRows = <PnlRow>[];
        for (final r in rawRows) {
          final type = r['type']?.toString();
          final label = r['label']?.toString() ?? '';
          final amount = (r['amount'] as num?)?.toDouble();
          final isPos = r['isPositive'] == true;

          if (type == 'sectionHeader') {
            mappedRows.add(PnlRow.sectionHeader(label));
          } else if (type == 'highlight') {
            mappedRows.add(PnlRow.highlight(label, amount));
          } else {
            mappedRows.add(PnlRow.item(label, amount, isPositive: isPos));
          }
        }

        if (mounted) {
          setState(() {
            grossProfit = gp;
            netProfit = np;
            grossSales = gs;
            grossMarginPct = gm;
            netMarginPct = nm;
            cogs = cg;
            operatingExpenses = opex;
            rows = mappedRows;
            _isLoading = false;
          });
        }
      } else {
        if (mounted) setState(() => _isLoading = false);
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
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
          dialogTheme: const DialogThemeData(backgroundColor: JoynColors.background),
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
      _fetchProfitAndLoss();
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
    if (result != null) {
      final now = DateTime.now();
      setState(() {
        selectedPeriod = result;
        if (result == 'Today') {
          fromDate = DateTime(now.year, now.month, now.day);
          toDate = DateTime(now.year, now.month, now.day, 23, 59, 59);
        } else if (result == 'This Week') {
          fromDate = now.subtract(Duration(days: now.weekday - 1));
          toDate = now;
        } else if (result == 'This Month') {
          fromDate = DateTime(now.year, now.month, 1);
          toDate = DateTime(now.year, now.month + 1, 0);
        } else if (result == 'This Year') {
          fromDate = DateTime(now.year, 1, 1);
          toDate = DateTime(now.year, 12, 31);
        }
      });
      if (result == 'Custom') {
        _pickDateRange();
      } else {
        _fetchProfitAndLoss();
      }
    }
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
            onTap: _exportRealPdf,
          ),
          const SizedBox(width: 6),
          _buildAppBarIconButton(
            label: 'xls',
            icon: Icons.grid_on_rounded,
            color: JoynColors.success,
            onTap: _exportRealExcel,
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
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _buildSummaryItem(
                  icon: Icons.stacked_line_chart_rounded,
                  label: 'Gross Profit ($grossMarginPct%)',
                  value: '₹ ${currency.format(grossProfit)}',
                  valueColor: grossProfit >= 0 ? const Color(0xFF4ADE80) : const Color(0xFFF87171),
                ),
              ),
              Container(width: 1, height: 44, color: Colors.white24),
              Expanded(
                child: _buildSummaryItem(
                  icon: Icons.savings_rounded,
                  label: 'Net Profit ($netMarginPct%)',
                  value: '₹ ${currency.format(netProfit)}',
                  valueColor: netProfit >= 0 ? const Color(0xFF4ADE80) : const Color(0xFFF87171),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildSubSummaryStat('Revenue', '₹${currency.format(grossSales)}'),
                Container(width: 1, height: 18, color: Colors.white24),
                _buildSubSummaryStat('COGS', '₹${currency.format(cogs)}'),
                Container(width: 1, height: 18, color: Colors.white24),
                _buildSubSummaryStat('OpEx', '₹${currency.format(operatingExpenses)}'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubSummaryStat(String label, String value) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: JoynTypography.caption.copyWith(
            color: Colors.white70,
            fontSize: 10.5,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 1),
        Text(
          value,
          style: JoynTypography.caption.copyWith(
            color: Colors.white,
            fontSize: 11.5,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
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

  Future<void> _exportRealPdf() async {
    final dateFmt = DateFormat('dd/MM/yyyy');
    final periodStr = '${dateFmt.format(fromDate)} - ${dateFmt.format(toDate)}';
    final currency = NumberFormat('#,##,##0.00', 'en_IN');

    final tableHeaders = ['Account Head / Particulars', 'Type', 'Amount'];
    final tableRows = <List<String>>[];

    for (final r in rows) {
      if (r.type == RowType.sectionHeader) {
        tableRows.add(['[ ${r.label} ]', 'Section', '']);
      } else if (r.type == RowType.highlight) {
        tableRows.add([r.label, 'Total', r.amount != null ? '₹ ${currency.format(r.amount)}' : '']);
      } else {
        tableRows.add([r.label, 'Particulars', r.amount != null ? '₹ ${currency.format(r.amount)}' : '']);
      }
    }

    final summary = {
      'Gross Profit': '₹ ${currency.format(grossProfit)}',
      'Net Profit': '₹ ${currency.format(netProfit)}',
    };

    await ReportExportService.showPdfOptionsSheet(
      context: context,
      title: 'Profit & Loss Report',
      periodLabel: periodStr,
      summaryStats: summary,
      tableHeaders: tableHeaders,
      tableRows: tableRows,
    );
  }

  Future<void> _exportRealExcel() async {
    final dateFmt = DateFormat('dd/MM/yyyy');
    final periodStr = '${dateFmt.format(fromDate)} - ${dateFmt.format(toDate)}';

    final tableHeaders = ['Account Head / Particulars', 'Type', 'Amount (INR)'];
    final tableRows = <List<String>>[];

    for (final r in rows) {
      if (r.type == RowType.sectionHeader) {
        tableRows.add([r.label, 'Section', '']);
      } else if (r.type == RowType.highlight) {
        tableRows.add([r.label, 'Total', r.amount != null ? r.amount!.toStringAsFixed(2) : '']);
      } else {
        tableRows.add([r.label, 'Particulars', r.amount != null ? r.amount!.toStringAsFixed(2) : '']);
      }
    }

    final summary = {
      'Gross Profit': '₹ ${grossProfit.toStringAsFixed(2)}',
      'Net Profit': '₹ ${netProfit.toStringAsFixed(2)}',
    };

    await ReportExportService.showExcelOptionsSheet(
      context: context,
      title: 'Profit & Loss Report',
      periodLabel: periodStr,
      summaryStats: summary,
      tableHeaders: tableHeaders,
      tableRows: tableRows,
    );
  }
}