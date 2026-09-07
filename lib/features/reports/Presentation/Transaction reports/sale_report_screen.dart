import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/joyn_colors.dart';
import '../../../../core/theme/joyn_typography.dart';

enum ReportPeriod { today, thisWeek, thisMonth, thisQuarter, thisFinancialYear, custom }

enum TxnTypeFilter { saleAndCreditNote, sale, creditNote, saleCancelled, saleRepeating }

class SaleLineItemModel {
  const SaleLineItemModel({
    required this.name,
    required this.qty,
    required this.unit,
    required this.rate,
    this.discountPercent = 0,
    this.taxPercent = 0,
  });

  final String name;
  final double qty;
  final String unit;
  final double rate;
  final double discountPercent;
  final double taxPercent;

  double get subtotal => qty * rate;
  double get discountAmount => subtotal * (discountPercent / 100);
  double get taxAmount => (subtotal - discountAmount) * (taxPercent / 100);
  double get lineTotal => subtotal - discountAmount + taxAmount;
}

class SaleReportEntry {
  SaleReportEntry({
    required this.id,
    required this.invoiceNo,
    required this.partyName,
    required this.phone,
    required this.date,
    required this.items,
    this.received = 0,
    this.paymentType = 'Cash',
    this.description = '',
    this.isCreditNote = false,
    this.isCancelled = false,
    this.isRepeating = false,
  });

  final String id;
  final int invoiceNo;
  final String partyName;
  final String phone;
  final DateTime date;
  final List<SaleLineItemModel> items;
  final double received;
  final String paymentType;
  final String description;
  final bool isCreditNote;
  final bool isCancelled;
  final bool isRepeating;

  double get totalAmount => items.fold(0.0, (sum, i) => sum + i.lineTotal);
  double get balanceDue => (totalAmount - received).clamp(0, double.infinity);

  String get typeLabel {
    if (isCreditNote) return 'CREDIT NOTE';
    if (isCancelled) return 'SALE [CANCELLED]';
    if (isRepeating) return 'SALE [REPEATING]';
    return 'SALE';
  }
}

class SaleReportScreen extends StatefulWidget {
  const SaleReportScreen({super.key});

  @override
  State<SaleReportScreen> createState() => _SaleReportScreenState();
}

class _SaleReportScreenState extends State<SaleReportScreen> {
  ReportPeriod _period = ReportPeriod.thisMonth;
  DateTimeRange? _customRange;
  TxnTypeFilter _txnTypeFilter = TxnTypeFilter.saleAndCreditNote;
  String? _partyFilter;
  late List<SaleReportEntry> _allSales;

  @override
  void initState() {
    super.initState();
    _allSales = _loadSampleSales();
  }

  List<SaleReportEntry> _loadSampleSales() {
    final now = DateTime.now();
    return [
      SaleReportEntry(
        id: 'sale_2',
        invoiceNo: 2,
        partyName: 'gill',
        phone: '9958761582',
        date: DateTime(now.year, now.month, 5),
        items: const [SaleLineItemModel(name: 'Pasta', qty: 1, unit: 'Btl', rate: 100)],
        received: 0,
      ),
      SaleReportEntry(
        id: 'sale_1',
        invoiceNo: 1,
        partyName: 'Gopal',
        phone: '9876543210',
        date: DateTime(now.year, now.month, 5),
        items: const [SaleLineItemModel(name: 'Rice Bag', qty: 2, unit: 'Bag', rate: 500)],
        received: 500,
      ),
    ];
  }

  DateTimeRange _rangeForPeriod(ReportPeriod period) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    switch (period) {
      case ReportPeriod.today:
        return DateTimeRange(start: today, end: today);
      case ReportPeriod.thisWeek:
        final start = today.subtract(Duration(days: today.weekday - 1));
        return DateTimeRange(start: start, end: today);
      case ReportPeriod.thisMonth:
        return DateTimeRange(start: DateTime(now.year, now.month, 1), end: DateTime(now.year, now.month + 1, 0));
      case ReportPeriod.thisQuarter:
        final qStartMonth = ((now.month - 1) ~/ 3) * 3 + 1;
        return DateTimeRange(
          start: DateTime(now.year, qStartMonth, 1),
          end: DateTime(now.year, qStartMonth + 3, 0),
        );
      case ReportPeriod.thisFinancialYear:
        final fyStartYear = now.month >= 4 ? now.year : now.year - 1;
        return DateTimeRange(start: DateTime(fyStartYear, 4, 1), end: DateTime(fyStartYear + 1, 3, 31));
      case ReportPeriod.custom:
        return _customRange ?? DateTimeRange(start: today, end: today);
    }
  }

  String _periodLabel(ReportPeriod period) {
    switch (period) {
      case ReportPeriod.today:
        return 'Today';
      case ReportPeriod.thisWeek:
        return 'This Week';
      case ReportPeriod.thisMonth:
        return 'This Month';
      case ReportPeriod.thisQuarter:
        return 'This Quarter';
      case ReportPeriod.thisFinancialYear:
        return 'This Financial Year';
      case ReportPeriod.custom:
        return 'Custom';
    }
  }

  List<String> get _partyNames =>
      _allSales.map((s) => s.partyName).toSet().toList()..sort();

  List<SaleReportEntry> get _filteredSales {
    final range = _rangeForPeriod(_period);
    final endInclusive = DateTime(range.end.year, range.end.month, range.end.day, 23, 59, 59);
    return _allSales.where((s) {
      final inRange = !s.date.isBefore(range.start) && !s.date.isAfter(endInclusive);
      if (!inRange) return false;

      final typeMatches = switch (_txnTypeFilter) {
        TxnTypeFilter.saleAndCreditNote => !s.isCancelled,
        TxnTypeFilter.sale => !s.isCreditNote && !s.isCancelled && !s.isRepeating,
        TxnTypeFilter.creditNote => s.isCreditNote,
        TxnTypeFilter.saleCancelled => s.isCancelled,
        TxnTypeFilter.saleRepeating => s.isRepeating,
      };
      if (!typeMatches) return false;

      if (_partyFilter != null && s.partyName != _partyFilter) return false;

      return true;
    }).toList()
      ..sort((a, b) => b.date.compareTo(a.date));
  }

  String _txnTypeLabel(TxnTypeFilter f) {
    switch (f) {
      case TxnTypeFilter.saleAndCreditNote:
        return 'Sale & Cr. Note';
      case TxnTypeFilter.sale:
        return 'Sale';
      case TxnTypeFilter.creditNote:
        return 'Credit Note';
      case TxnTypeFilter.saleCancelled:
        return 'Sale [Cancelled]';
      case TxnTypeFilter.saleRepeating:
        return 'Sale [Repeating]';
    }
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredSales;
    final totalSale = filtered.fold(0.0, (sum, s) => sum + s.totalAmount);
    final balanceDue = filtered.fold(0.0, (sum, s) => sum + s.balanceDue);
    final range = _rangeForPeriod(_period);
    final dateFmt = DateFormat('dd/MM/yyyy');

    return Scaffold(
      backgroundColor: JoynColors.background,
      appBar: AppBar(
        backgroundColor: JoynColors.background,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: JoynColors.primary),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Sale Report',
          style: JoynTypography.titleMedium.copyWith(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: JoynColors.primary,
          ),
        ),
        actions: [
          _buildAppBarIconButton(
            label: 'CA',
            icon: Icons.file_upload_rounded,
            color: const Color(0xFF2563EB),
            onTap: _showCaShareDialog,
          ),
          const SizedBox(width: 6),
          _buildAppBarIconButton(
            label: 'Pdf',
            icon: Icons.picture_as_pdf_rounded,
            color: const Color(0xFFDC2626),
            onTap: _showPdfOptions,
          ),
          const SizedBox(width: 6),
          _buildAppBarIconButton(
            label: 'xls',
            icon: Icons.grid_on_rounded,
            color: JoynColors.success,
            onTap: _showExcelOptions,
          ),
          const SizedBox(width: 12),
        ],
      ),
      body: Column(
        children: [
          _buildPeriodSelector(range, dateFmt),
          _buildFilterSection(),
          if (filtered.isNotEmpty) _buildSummaryCards(filtered, totalSale, balanceDue),
          Expanded(
            child: filtered.isEmpty
                ? _buildEmptyState()
                : _buildTransactionList(filtered),
          ),
        ],
      ),
    );
  }

  Widget _buildPeriodSelector(DateTimeRange range, DateFormat dateFmt) {
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
              onTap: _showPeriodPicker,
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
                        _periodLabel(_period),
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
            onTap: _pickCustomRange,
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
                    '${dateFmt.format(range.start)} - ${dateFmt.format(range.end)}',
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

  Widget _buildFilterSection() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Row(
        children: [
          Expanded(
            child: Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                _buildFilterChip(
                  icon: Icons.swap_horiz_rounded,
                  label: _txnTypeLabel(_txnTypeFilter),
                ),
                _buildFilterChip(
                  icon: Icons.person_outline_rounded,
                  label: _partyFilter ?? 'All Party',
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Material(
            color: JoynColors.primary,
            borderRadius: BorderRadius.circular(24),
            child: InkWell(
              onTap: _showFiltersSheet,
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

  Widget _buildSummaryCards(List<SaleReportEntry> filtered, double totalSale, double balanceDue) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
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
              icon: Icons.receipt_long_rounded,
              label: 'Transactions',
              value: filtered.length.toString(),
            ),
          ),
          Container(width: 1, height: 40, color: Colors.white24),
          Expanded(
            child: _buildSummaryItem(
              icon: Icons.currency_rupee_rounded,
              label: 'Total Sale',
              value: '₹${_fmt(totalSale)}',
            ),
          ),
          Container(width: 1, height: 40, color: Colors.white24),
          Expanded(
            child: _buildSummaryItem(
              icon: Icons.account_balance_wallet_rounded,
              label: 'Balance Due',
              value: '₹${_fmt(balanceDue)}',
              valueColor: const Color(0xFFFFB86B),
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

  Widget _buildTransactionList(List<SaleReportEntry> filtered) {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      itemCount: filtered.length,
      itemBuilder: (context, index) {
        final entry = filtered[index];
        return _buildTxnCard(entry, index);
      },
    );
  }

  Widget _buildTxnCard(SaleReportEntry entry, int index) {
    final initials = entry.partyName.isNotEmpty ? entry.partyName[0].toUpperCase() : '?';

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
        margin: const EdgeInsets.only(bottom: 12),
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
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          child: InkWell(
            onTap: () => _showSaleDetail(entry),
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              JoynColors.primary.withValues(alpha: 0.1),
                              JoynColors.primary.withValues(alpha: 0.05),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          initials,
                          style: JoynTypography.bodyLarge.copyWith(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: JoynColors.primary,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              entry.partyName,
                              style: JoynTypography.bodyLarge.copyWith(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: JoynColors.primary,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Text(
                                  DateFormat('dd MMM yy').format(entry.date).toUpperCase(),
                                  style: JoynTypography.caption.copyWith(
                                    fontSize: 10,
                                    color: JoynColors.secondaryText,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  width: 3,
                                  height: 3,
                                  decoration: BoxDecoration(
                                    color: JoynColors.secondaryText,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  '${entry.typeLabel} #${entry.invoiceNo}',
                                  style: JoynTypography.caption.copyWith(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                    color: JoynColors.primary,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            '₹${_fmt(entry.totalAmount)}',
                            style: JoynTypography.bodyLarge.copyWith(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              color: JoynColors.primary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: entry.balanceDue > 0
                                  ? JoynColors.error.withValues(alpha: 0.1)
                                  : JoynColors.success.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              entry.balanceDue > 0 ? 'Due ₹${_fmt(entry.balanceDue)}' : 'Paid',
                              style: JoynTypography.caption.copyWith(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: entry.balanceDue > 0 ? JoynColors.error : JoynColors.success,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Container(height: 1, color: JoynColors.border),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      _buildInfoItem(
                        icon: Icons.receipt_rounded,
                        label: 'Items',
                        value: '${entry.items.length}',
                      ),
                      const SizedBox(width: 16),
                      _buildInfoItem(
                        icon: Icons.payments_rounded,
                        label: 'Payment',
                        value: entry.paymentType,
                      ),
                      const Spacer(),
                      Icon(Icons.arrow_forward_rounded, size: 16, color: JoynColors.secondaryText),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoItem({required IconData icon, required String label, required String value}) {
    return Row(
      children: [
        Icon(icon, size: 14, color: JoynColors.secondaryText),
        const SizedBox(width: 4),
        Text(
          '$label: ',
          style: JoynTypography.caption.copyWith(
            fontSize: 10,
            color: JoynColors.secondaryText,
          ),
        ),
        Text(
          value,
          style: JoynTypography.caption.copyWith(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: JoynColors.primary,
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: JoynColors.chipBackground,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.receipt_long_outlined,
              size: 36,
              color: JoynColors.secondaryText.withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'No transactions found',
            style: JoynTypography.subtitle.copyWith(
              fontWeight: FontWeight.w700,
              fontSize: 16,
              color: JoynColors.primary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Try adjusting filters or date range',
            style: JoynTypography.caption.copyWith(
              fontSize: 12,
              color: JoynColors.secondaryText,
            ),
          ),
        ],
      ),
    );
  }

  String _fmt(double v) => NumberFormat('#,##0.00', 'en_IN').format(v);

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

  // ---------------- Period Picker ----------------
  Future<void> _showPeriodPicker() async {
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: JoynColors.background,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildSheetHeader('Select Period', sheetContext),
              Divider(height: 1, color: JoynColors.border),
              ...ReportPeriod.values.map((p) {
                final isSelected = _period == p;
                return InkWell(
                  onTap: () {
                    Navigator.pop(sheetContext);
                    if (p == ReportPeriod.custom) {
                      setState(() => _period = p);
                      _pickCustomRange();
                    } else {
                      setState(() => _period = p);
                    }
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _periodLabel(p),
                          style: JoynTypography.bodyLarge.copyWith(fontSize: 15),
                        ),
                        if (isSelected)
                          Icon(
                            Icons.check_circle_rounded,
                            size: 20,
                            color: JoynColors.primary,
                          ),
                      ],
                    ),
                  ),
                );
              }),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  Future<void> _pickCustomRange() async {
    final result = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      initialDateRange: _customRange ?? _rangeForPeriod(ReportPeriod.thisMonth),
    );
    if (result != null && mounted) {
      setState(() => _customRange = result);
    }
  }

  Widget _buildSheetHeader(String title, BuildContext sheetContext) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 12, 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: JoynTypography.titleMedium.copyWith(
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          IconButton(
            icon: Icon(Icons.close_rounded, color: JoynColors.secondaryText),
            onPressed: () => Navigator.pop(sheetContext),
          ),
        ],
      ),
    );
  }

  // ---------------- Filters Sheet ----------------
  Future<void> _showFiltersSheet() async {
    var tempTxnType = _txnTypeFilter;
    String? tempParty = _partyFilter;
    var activeTab = 0;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: JoynColors.background,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (sheetContext, setSheetState) {
            return SafeArea(
              child: SizedBox(
                height: MediaQuery.of(context).size.height * 0.7,
                child: Column(
                  children: [
                    _buildSheetHeader('Filters', sheetContext),
                    Divider(height: 1, color: JoynColors.border),
                    Expanded(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 120,
                            color: JoynColors.surfaceMuted,
                            child: Column(
                              children: [
                                _buildFilterTab('By Txns Type', activeTab == 0, () => setSheetState(() => activeTab = 0)),
                                _buildFilterTab('By Party', activeTab == 1, () => setSheetState(() => activeTab = 1)),
                              ],
                            ),
                          ),
                          Expanded(
                            child: ListView(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              children: activeTab == 0
                                  ? TxnTypeFilter.values.map((f) {
                                return _buildRadioRow(
                                  label: _txnTypeLabel(f),
                                  selected: tempTxnType == f,
                                  onTap: () => setSheetState(() => tempTxnType = f),
                                );
                              }).toList()
                                  : [
                                _buildRadioRow(
                                  label: 'All Party',
                                  selected: tempParty == null,
                                  onTap: () => setSheetState(() => tempParty = null),
                                ),
                                ..._partyNames.map((name) => _buildRadioRow(
                                  label: name,
                                  selected: tempParty == name,
                                  onTap: () => setSheetState(() => tempParty = name),
                                )),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    Divider(height: 1, color: JoynColors.border),
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () => setSheetState(() {
                                tempTxnType = TxnTypeFilter.saleAndCreditNote;
                                tempParty = null;
                              }),
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                side: BorderSide(color: JoynColors.border),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                                backgroundColor: JoynColors.surface,
                              ),
                              child: Text(
                                'Reset',
                                style: JoynTypography.bodyMedium.copyWith(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: JoynColors.secondaryText,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () {
                                setState(() {
                                  _txnTypeFilter = tempTxnType;
                                  _partyFilter = tempParty;
                                });
                                Navigator.pop(sheetContext);
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: JoynColors.primary,
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                              ),
                              child: Text(
                                'Apply',
                                style: JoynTypography.buttonText.copyWith(fontSize: 14),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildFilterTab(String label, bool isSelected, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        color: isSelected ? JoynColors.background : Colors.transparent,
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        child: Text(
          label,
          style: JoynTypography.bodyMedium.copyWith(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            color: isSelected ? JoynColors.primary : JoynColors.secondaryText,
          ),
        ),
      ),
    );
  }

  Widget _buildRadioRow({required String label, required bool selected, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: JoynTypography.bodyLarge.copyWith(fontSize: 14),
            ),
            Icon(
              selected ? Icons.radio_button_checked_rounded : Icons.radio_button_off_rounded,
              color: selected ? JoynColors.primary : JoynColors.border,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  // ---------------- Sale Detail ----------------
  Future<void> _showSaleDetail(SaleReportEntry entry) async {
    final dateFmt = DateFormat('dd/MM/yyyy');
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: JoynColors.background,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) {
        return DraggableScrollableSheet(
          initialChildSize: 0.9,
          maxChildSize: 0.95,
          minChildSize: 0.5,
          expand: false,
          builder: (context, scrollController) {
            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 8, 8),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back_rounded),
                        onPressed: () => Navigator.pop(sheetContext),
                      ),
                      Expanded(
                        child: Text(
                          'Sale Details',
                          style: JoynTypography.titleMedium.copyWith(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.ios_share_rounded, size: 20),
                        onPressed: () {},
                      ),
                    ],
                  ),
                ),
                Divider(height: 1, color: JoynColors.border),
                Expanded(
                  child: ListView(
                    controller: scrollController,
                    padding: const EdgeInsets.all(16),
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Invoice No.\n${entry.invoiceNo}',
                              style: JoynTypography.bodyMedium.copyWith(
                                fontSize: 13,
                                color: JoynColors.secondaryText,
                                height: 1.6,
                              ),
                            ),
                          ),
                          Container(width: 1, height: 40, color: JoynColors.border),
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.only(left: 16),
                              child: Text(
                                'Date\n${dateFmt.format(entry.date)}',
                                style: JoynTypography.bodyMedium.copyWith(
                                  fontSize: 13,
                                  color: JoynColors.secondaryText,
                                  height: 1.6,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Align(
                        alignment: Alignment.centerRight,
                        child: Text(
                          'Party Balance: ₹${_fmt(entry.balanceDue)}',
                          style: JoynTypography.bodyMedium.copyWith(
                            fontSize: 12,
                            color: JoynColors.success,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      _buildDetailField('Customer Name *', entry.partyName),
                      const SizedBox(height: 12),
                      _buildDetailField('Phone Number', entry.phone),
                      const SizedBox(height: 16),
                      Container(
                        color: JoynColors.surfaceMuted,
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        child: Row(
                          children: [
                            Icon(Icons.check_circle_rounded, size: 16, color: JoynColors.primary),
                            const SizedBox(width: 8),
                            Text(
                              'Billed Items',
                              style: JoynTypography.bodyMedium.copyWith(
                                fontWeight: FontWeight.w700,
                                fontSize: 13,
                              ),
                            ),
                            const Spacer(),
                            Text(
                              'Rate excl. tax',
                              style: JoynTypography.caption.copyWith(
                                fontSize: 10,
                                color: JoynColors.secondaryText,
                              ),
                            ),
                          ],
                        ),
                      ),
                      ...entry.items.asMap().entries.map((e) {
                        final i = e.key + 1;
                        final item = e.value;
                        return Container(
                          padding: const EdgeInsets.all(12),
                          margin: const EdgeInsets.only(top: 8),
                          decoration: BoxDecoration(
                            color: JoynColors.surface,
                            borderRadius: BorderRadius.circular(8),
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
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        color: JoynColors.iconBackground,
                                        child: Text(
                                          '#$i',
                                          style: JoynTypography.caption.copyWith(fontSize: 10),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        item.name,
                                        style: JoynTypography.bodyLarge.copyWith(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ],
                                  ),
                                  Text(
                                    '₹${_fmt(item.lineTotal)}',
                                    style: JoynTypography.bodyLarge.copyWith(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Item Subtotal',
                                    style: JoynTypography.caption.copyWith(
                                      fontSize: 10,
                                      color: JoynColors.secondaryText,
                                    ),
                                  ),
                                  Text(
                                    '${item.qty.toStringAsFixed(item.qty % 1 == 0 ? 0 : 1)} ${item.unit} x ${item.rate.toStringAsFixed(0)} = ₹${_fmt(item.subtotal)}',
                                    style: JoynTypography.caption.copyWith(
                                      fontSize: 10,
                                      color: JoynColors.secondaryText,
                                    ),
                                  ),
                                ],
                              ),
                              if (item.discountPercent > 0) ...[
                                const SizedBox(height: 4),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'Discount (%): ${item.discountPercent.toStringAsFixed(0)}',
                                      style: JoynTypography.caption.copyWith(
                                        fontSize: 10,
                                        color: Colors.orange,
                                      ),
                                    ),
                                    Text(
                                      '₹${_fmt(item.discountAmount)}',
                                      style: JoynTypography.caption.copyWith(
                                        fontSize: 10,
                                        color: Colors.orange,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                              const SizedBox(height: 4),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Tax : ${item.taxPercent.toStringAsFixed(0)}%',
                                    style: JoynTypography.caption.copyWith(
                                      fontSize: 10,
                                      color: JoynColors.secondaryText,
                                    ),
                                  ),
                                  Text(
                                    '₹${_fmt(item.taxAmount)}',
                                    style: JoynTypography.caption.copyWith(
                                      fontSize: 10,
                                      color: JoynColors.secondaryText,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        );
                      }),
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
                        decoration: BoxDecoration(
                          color: JoynColors.surface,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          children: [
                            _buildAmountRow('Total Amount', entry.totalAmount, big: true),
                            const SizedBox(height: 10),
                            Row(
                              children: [
                                Icon(
                                  entry.received > 0 ? Icons.check_box_rounded : Icons.check_box_outline_blank_rounded,
                                  color: JoynColors.primary,
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'Received',
                                    style: JoynTypography.bodyLarge.copyWith(fontSize: 14),
                                  ),
                                ),
                                Text(
                                  '₹${_fmt(entry.received)}',
                                  style: JoynTypography.bodyLarge.copyWith(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Balance Due',
                                  style: JoynTypography.bodyLarge.copyWith(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: JoynColors.success,
                                  ),
                                ),
                                Text(
                                  '₹${_fmt(entry.balanceDue)}',
                                  style: JoynTypography.bodyLarge.copyWith(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w800,
                                    color: JoynColors.success,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Payment Type',
                            style: JoynTypography.bodyMedium.copyWith(
                              fontSize: 13,
                              color: JoynColors.secondaryText,
                            ),
                          ),
                          Row(
                            children: [
                              Icon(Icons.currency_rupee_rounded, size: 16, color: JoynColors.success),
                              const SizedBox(width: 4),
                              Text(
                                entry.paymentType,
                                style: JoynTypography.bodyLarge.copyWith(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Text(
                        'Description',
                        style: JoynTypography.caption.copyWith(
                          fontSize: 11,
                          color: JoynColors.secondaryText,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          border: Border.all(color: JoynColors.border),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          entry.description.isEmpty ? 'Add Note' : entry.description,
                          style: JoynTypography.bodyMedium.copyWith(
                            fontSize: 13,
                            color: entry.description.isEmpty ? JoynColors.secondaryText : JoynColors.primary,
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
                Divider(height: 1, color: JoynColors.border),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            Navigator.pop(sheetContext);
                            setState(() => _allSales.removeWhere((s) => s.id == entry.id));
                          },
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            side: BorderSide(color: JoynColors.border),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                            backgroundColor: JoynColors.surface,
                          ),
                          child: Text(
                            'Delete',
                            style: JoynTypography.bodyLarge.copyWith(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () => Navigator.pop(sheetContext),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: JoynColors.primary,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                          ),
                          child: Text(
                            'Edit',
                            style: JoynTypography.buttonText.copyWith(fontSize: 14),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildDetailField(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: JoynTypography.caption.copyWith(
            fontSize: 11,
            color: JoynColors.secondaryText,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            border: Border.all(color: JoynColors.border),
            borderRadius: BorderRadius.circular(8),
            color: JoynColors.surface,
          ),
          child: Text(
            value,
            style: JoynTypography.bodyLarge.copyWith(fontSize: 14),
          ),
        ),
      ],
    );
  }

  Widget _buildAmountRow(String label, double value, {bool big = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: JoynTypography.bodyLarge.copyWith(
            fontSize: big ? 14 : 13,
            fontWeight: FontWeight.w600,
          ),
        ),
        Text(
          '₹${_fmt(value)}',
          style: JoynTypography.bodyLarge.copyWith(
            fontSize: big ? 18 : 13,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }

  // ---------------- CA Share Dialog ----------------
  Future<void> _showCaShareDialog() async {
    final nameController = TextEditingController();
    final emailController = TextEditingController();
    final whatsappController = TextEditingController();

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: JoynColors.background,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) {
        return Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(sheetContext).viewInsets.bottom),
          child: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          'Share Reports with your CA',
                          style: JoynTypography.titleMedium.copyWith(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.close_rounded, color: JoynColors.secondaryText),
                        onPressed: () => Navigator.pop(sheetContext),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    height: 120,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          JoynColors.success.withValues(alpha: 0.1),
                          JoynColors.success.withValues(alpha: 0.02),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: Icon(
                        Icons.forward_to_inbox_rounded,
                        size: 48,
                        color: JoynColors.success.withValues(alpha: 0.5),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    "CA's Name",
                    style: JoynTypography.caption.copyWith(
                      fontSize: 11,
                      color: JoynColors.secondaryText,
                    ),
                  ),
                  const SizedBox(height: 6),
                  _buildTextInput(nameController, hint: 'Enter CA name'),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Text(
                        "CA's Email",
                        style: JoynTypography.caption.copyWith(
                          fontSize: 11,
                          color: JoynColors.secondaryText,
                        ),
                      ),
                      Text(' *', style: TextStyle(color: JoynColors.error)),
                    ],
                  ),
                  const SizedBox(height: 6),
                  _buildTextInput(emailController, hint: 'Enter email', keyboardType: TextInputType.emailAddress),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Text(
                        "CA's WhatsApp Number",
                        style: JoynTypography.caption.copyWith(
                          fontSize: 11,
                          color: JoynColors.secondaryText,
                        ),
                      ),
                      Text(' *', style: TextStyle(color: JoynColors.error)),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: JoynColors.border),
                      borderRadius: BorderRadius.circular(8),
                      color: JoynColors.surface,
                    ),
                    child: Row(
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 14),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: const [
                              Text('🇮🇳', style: TextStyle(fontSize: 16)),
                              SizedBox(width: 6),
                              Text('+91', style: TextStyle(fontSize: 14)),
                              Icon(Icons.keyboard_arrow_down_rounded, size: 16),
                            ],
                          ),
                        ),
                        Container(width: 1, height: 24, color: JoynColors.border),
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 10),
                            child: TextField(
                              controller: whatsappController,
                              keyboardType: TextInputType.phone,
                              decoration: const InputDecoration(
                                border: InputBorder.none,
                                isDense: true,
                                contentPadding: EdgeInsets.symmetric(vertical: 14),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(sheetContext),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            side: BorderSide(color: JoynColors.border),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                            backgroundColor: JoynColors.surface,
                          ),
                          child: Text(
                            'Cancel',
                            style: JoynTypography.bodyLarge.copyWith(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.pop(sheetContext);
                            _showSnackBar('Report shared with CA successfully!');
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: JoynColors.primary,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                          ),
                          child: Text(
                            'Send',
                            style: JoynTypography.buttonText.copyWith(fontSize: 14),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildTextInput(
      TextEditingController controller, {
        required String hint,
        TextInputType keyboardType = TextInputType.text,
      }) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: JoynColors.border),
        borderRadius: BorderRadius.circular(8),
        color: JoynColors.surface,
      ),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          hintText: hint,
          border: InputBorder.none,
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        ),
      ),
    );
  }

  // ---------------- PDF / Excel Options ----------------
  Future<void> _showPdfOptions() async {
    await _showOptionsSheet(
      title: 'PDF Options',
      options: [
        _OptionItem(icon: Icons.description_outlined, label: 'Open PDF', onTap: () {
          _showSnackBar('Opening PDF...');
        }),
        _OptionItem(icon: Icons.print_outlined, label: 'Print PDF', onTap: () {
          _showSnackBar('Printing PDF...');
        }),
        _OptionItem(icon: Icons.ios_share_rounded, label: 'Share PDF', onTap: () {
          _showSnackBar('Sharing PDF...');
        }),
        _OptionItem(icon: Icons.download_rounded, label: 'Save PDF to Phone', onTap: () {
          _showSnackBar('Saving PDF...');
        }),
      ],
    );
  }

  Future<void> _showExcelOptions() async {
    await _showOptionsSheet(
      title: 'Excel Options',
      options: [
        _OptionItem(icon: Icons.description_outlined, label: 'Open Excel', onTap: () {
          _showSnackBar('Opening Excel...');
        }),
        _OptionItem(icon: Icons.ios_share_rounded, label: 'Share Excel', onTap: () {
          _showSnackBar('Sharing Excel...');
        }),
        _OptionItem(icon: Icons.file_upload_outlined, label: 'Export to Excel', onTap: () {
          _showSnackBar('Exporting to Excel...');
        }),
        _OptionItem(icon: Icons.calendar_today_outlined, label: 'Schedule Report', onTap: () {
          _showSnackBar('Scheduling Report...');
        }),
      ],
    );
  }

  Future<void> _showOptionsSheet({
    required String title,
    required List<_OptionItem> options,
  }) async {
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: JoynColors.background,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildSheetHeader(title, sheetContext),
              Divider(height: 1, color: JoynColors.border),
              ...options.map((opt) => InkWell(
                onTap: () {
                  Navigator.pop(sheetContext);
                  opt.onTap();
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                  child: Row(
                    children: [
                      Icon(opt.icon, size: 20, color: JoynColors.primary),
                      const SizedBox(width: 16),
                      Text(
                        opt.label,
                        style: JoynTypography.bodyLarge.copyWith(fontSize: 14),
                      ),
                    ],
                  ),
                ),
              )),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
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

class _OptionItem {
  const _OptionItem({
    required this.icon,
    required this.label,
    required this.onTap,
  });
  final IconData icon;
  final String label;
  final VoidCallback onTap;
}