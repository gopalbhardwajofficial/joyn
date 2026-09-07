import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/joyn_colors.dart';
import '../../../../core/theme/joyn_typography.dart';

enum ReportPeriod { today, thisWeek, thisMonth, thisQuarter, thisFinancialYear, custom }

enum PurchaseTxnTypeFilter { purchaseAndDebitNote, purchase, debitNote, purchaseCancelled, purchaseRepeating }

class PurchaseLineItemModel {
  const PurchaseLineItemModel({
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

class PurchaseReportEntry {
  PurchaseReportEntry({
    required this.id,
    required this.invoiceNo,
    required this.supplierName,
    required this.phone,
    required this.date,
    required this.items,
    this.paid = 0,
    this.paymentType = 'Cash',
    this.description = '',
    this.isDebitNote = false,
    this.isCancelled = false,
    this.isRepeating = false,
  });

  final String id;
  final int invoiceNo;
  final String supplierName;
  final String phone;
  final DateTime date;
  final List<PurchaseLineItemModel> items;
  final double paid;
  final String paymentType;
  final String description;
  final bool isDebitNote;
  final bool isCancelled;
  final bool isRepeating;

  double get totalAmount => items.fold(0.0, (sum, i) => sum + i.lineTotal);
  double get balanceDue => (totalAmount - paid).clamp(0, double.infinity);

  String get typeLabel {
    if (isDebitNote) return 'DEBIT NOTE';
    if (isCancelled) return 'PURCHASE [CANCELLED]';
    if (isRepeating) return 'PURCHASE [REPEATING]';
    return 'PURCHASE';
  }
}

class PurchaseReportScreen extends StatefulWidget {
  const PurchaseReportScreen({super.key});

  @override
  State<PurchaseReportScreen> createState() => _PurchaseReportScreenState();
}

class _PurchaseReportScreenState extends State<PurchaseReportScreen> {
  ReportPeriod _period = ReportPeriod.thisMonth;
  DateTimeRange? _customRange;
  PurchaseTxnTypeFilter _txnTypeFilter = PurchaseTxnTypeFilter.purchaseAndDebitNote;
  String? _partyFilter;
  late List<PurchaseReportEntry> _allPurchases;

  @override
  void initState() {
    super.initState();
    _allPurchases = _loadSamplePurchases();
  }

  List<PurchaseReportEntry> _loadSamplePurchases() => [];

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
      _allPurchases.map((p) => p.supplierName).toSet().toList()..sort();

  List<PurchaseReportEntry> get _filteredPurchases {
    final range = _rangeForPeriod(_period);
    final endInclusive = DateTime(range.end.year, range.end.month, range.end.day, 23, 59, 59);
    return _allPurchases.where((p) {
      final inRange = !p.date.isBefore(range.start) && !p.date.isAfter(endInclusive);
      if (!inRange) return false;

      final typeMatches = switch (_txnTypeFilter) {
        PurchaseTxnTypeFilter.purchaseAndDebitNote => !p.isCancelled,
        PurchaseTxnTypeFilter.purchase => !p.isDebitNote && !p.isCancelled && !p.isRepeating,
        PurchaseTxnTypeFilter.debitNote => p.isDebitNote,
        PurchaseTxnTypeFilter.purchaseCancelled => p.isCancelled,
        PurchaseTxnTypeFilter.purchaseRepeating => p.isRepeating,
      };
      if (!typeMatches) return false;

      if (_partyFilter != null && p.supplierName != _partyFilter) return false;

      return true;
    }).toList()
      ..sort((a, b) => b.date.compareTo(a.date));
  }

  String _txnTypeLabel(PurchaseTxnTypeFilter f) {
    switch (f) {
      case PurchaseTxnTypeFilter.purchaseAndDebitNote:
        return 'Purchase & Dr. Note';
      case PurchaseTxnTypeFilter.purchase:
        return 'Purchase';
      case PurchaseTxnTypeFilter.debitNote:
        return 'Debit Note';
      case PurchaseTxnTypeFilter.purchaseCancelled:
        return 'Purchase [Cancelled]';
      case PurchaseTxnTypeFilter.purchaseRepeating:
        return 'Purchase [Repeating]';
    }
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredPurchases;
    final totalPurchase = filtered.fold(0.0, (sum, p) => sum + p.totalAmount);
    final balanceDue = filtered.fold(0.0, (sum, p) => sum + p.balanceDue);
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
          'Purchase Report',
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
          if (filtered.isNotEmpty) _buildSummaryCards(filtered, totalPurchase, balanceDue),
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

  Widget _buildSummaryCards(List<PurchaseReportEntry> filtered, double totalPurchase, double balanceDue) {
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
              icon: Icons.shopping_cart_rounded,
              label: 'Transactions',
              value: filtered.length.toString(),
            ),
          ),
          Container(width: 1, height: 40, color: Colors.white24),
          Expanded(
            child: _buildSummaryItem(
              icon: Icons.currency_rupee_rounded,
              label: 'Total Purchase',
              value: '₹${_fmt(totalPurchase)}',
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

  Widget _buildTransactionList(List<PurchaseReportEntry> filtered) {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      itemCount: filtered.length,
      itemBuilder: (context, index) {
        final entry = filtered[index];
        return _buildTxnCard(entry, index);
      },
    );
  }

  Widget _buildTxnCard(PurchaseReportEntry entry, int index) {
    final initials = entry.supplierName.isNotEmpty ? entry.supplierName[0].toUpperCase() : '?';

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
            onTap: () {},
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
                              JoynColors.error.withValues(alpha: 0.1),
                              JoynColors.error.withValues(alpha: 0.05),
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
                            color: JoynColors.error,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              entry.supplierName,
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
                        icon: Icons.inventory_2_rounded,
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
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: JoynColors.surface,
              shape: BoxShape.circle,
              border: Border.all(color: JoynColors.border, width: 2),
            ),
            child: Icon(
              Icons.shopping_cart_outlined,
              size: 48,
              color: JoynColors.secondaryText.withValues(alpha: 0.5),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'No Data Available',
            style: JoynTypography.titleMedium.copyWith(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: JoynColors.primary,
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              'No data is available for this report. Please try again after making relevant changes.',
              textAlign: TextAlign.center,
              style: JoynTypography.bodyMedium.copyWith(
                fontSize: 13.5,
                color: JoynColors.secondaryText,
                height: 1.4,
              ),
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
                                  ? PurchaseTxnTypeFilter.values.map((f) {
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
                                tempTxnType = PurchaseTxnTypeFilter.purchaseAndDebitNote;
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