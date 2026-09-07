import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:joyn/core/theme/joyn_typography.dart';
import 'package:joyn/core/theme/joyn_colors.dart';
import 'package:joyn/core/widgets/Premium_widget.dart';

enum ReportPeriod { today, thisWeek, thisMonth, thisQuarter, thisFinancialYear, custom }

class PartySalePurchaseEntry {
  const PartySalePurchaseEntry({
    required this.partyName,
    required this.saleAmount,
    required this.purchaseAmount,
  });

  final String partyName;
  final double saleAmount;
  final double purchaseAmount;
}

class SalePurchaseByPartyScreen extends StatefulWidget {
  const SalePurchaseByPartyScreen({super.key});

  @override
  State<SalePurchaseByPartyScreen> createState() => _SalePurchaseByPartyScreenState();
}

class _SalePurchaseByPartyScreenState extends State<SalePurchaseByPartyScreen> {
  ReportPeriod _period = ReportPeriod.thisMonth;
  DateTimeRange? _customRange;
  bool _isLoading = false;

  late List<PartySalePurchaseEntry> _allEntries;

  @override
  void initState() {
    super.initState();
    _allEntries = _loadSampleEntries();
  }

  List<PartySalePurchaseEntry> _loadSampleEntries() {
    return const [
      PartySalePurchaseEntry(partyName: 'gill', saleAmount: 100, purchaseAmount: 0),
      PartySalePurchaseEntry(partyName: 'Gopal', saleAmount: 1000, purchaseAmount: 0),
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

  List<PartySalePurchaseEntry> get _filteredEntries {
    return [..._allEntries]..sort((a, b) => b.saleAmount.compareTo(a.saleAmount));
  }

  double get _totalSale => _filteredEntries.fold(0.0, (sum, e) => sum + e.saleAmount);
  double get _totalPurchase => _filteredEntries.fold(0.0, (sum, e) => sum + e.purchaseAmount);

  String _fmt(double v) => NumberFormat('#,##0.00', 'en_IN').format(v);

  @override
  Widget build(BuildContext context) {
    final entries = _filteredEntries;
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
          'Sale/Purchase by Party',
          style: JoynTypography.titleMedium.copyWith(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: JoynColors.primary,
          ),
          overflow: TextOverflow.ellipsis,
        ),
        actions: [
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
          const SizedBox(height: 12),
          _buildSummaryCards(),
          const SizedBox(height: 12),
          _buildTableHeader(),
          Expanded(
            child: _isLoading
                ? const Center(
              child: CircularProgressIndicator(color: JoynColors.primary),
            )
                : entries.isEmpty
                ? _buildEmptyState()
                : _buildPartiesList(entries),
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

  Widget _buildSummaryCards() {
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
      child: Row(
        children: [
          Expanded(
            child: _buildSummaryItem(
              icon: Icons.trending_up_rounded,
              label: 'Total Sale',
              value: '₹${_fmt(_totalSale)}',
              valueColor: const Color(0xFF4ADE80),
            ),
          ),
          Container(width: 1, height: 40, color: Colors.white24),
          Expanded(
            child: _buildSummaryItem(
              icon: Icons.trending_down_rounded,
              label: 'Total Purchase',
              value: '₹${_fmt(_totalPurchase)}',
              valueColor: const Color(0xFFF87171),
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

  Widget _buildTableHeader() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: JoynColors.surfaceMuted,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 4,
            child: Text(
              'Party Name',
              style: JoynTypography.caption.copyWith(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: JoynColors.secondaryText,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              'Sale',
              textAlign: TextAlign.right,
              style: JoynTypography.caption.copyWith(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: JoynColors.secondaryText,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              'Purchase',
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

  Widget _buildPartiesList(List<PartySalePurchaseEntry> entries) {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      itemCount: entries.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final entry = entries[index];
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
            child: Material(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(14),
              child: InkWell(
                onTap: () => _showPartyDetail(entry),
                borderRadius: BorderRadius.circular(14),
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Row(
                    children: [
                      Container(
                        width: 42,
                        height: 42,
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
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                            color: JoynColors.primary,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),

                      Expanded(
                        flex: 4,
                        child: Text(
                          entry.partyName,
                          style: JoynTypography.bodyLarge.copyWith(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: JoynColors.primary,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),

                      Expanded(
                        flex: 3,
                        child: Text(
                          '₹${_fmt(entry.saleAmount)}',
                          textAlign: TextAlign.right,
                          style: JoynTypography.bodyMedium.copyWith(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: entry.saleAmount > 0 ? JoynColors.success : JoynColors.secondaryText,
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 3,
                        child: Text(
                          '₹${_fmt(entry.purchaseAmount)}',
                          textAlign: TextAlign.right,
                          style: JoynTypography.bodyMedium.copyWith(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: entry.purchaseAmount > 0 ? JoynColors.error : JoynColors.secondaryText,
                          ),
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(Icons.chevron_right_rounded, color: JoynColors.secondaryText, size: 18),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
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
                Icons.groups_outlined,
                size: 48,
                color: JoynColors.secondaryText.withValues(alpha: 0.5),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'No party transactions found',
              style: JoynTypography.titleMedium.copyWith(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: JoynColors.primary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Sale and purchase transactions by party will appear here.',
              textAlign: TextAlign.center,
              style: JoynTypography.bodyMedium.copyWith(
                fontSize: 13.5,
                color: JoynColors.secondaryText,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }

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
                          Icon(Icons.check_circle_rounded, size: 20, color: JoynColors.primary),
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
    HapticFeedback.lightImpact();
    final result = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      initialDateRange: _customRange ?? _rangeForPeriod(ReportPeriod.thisMonth),
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
  Future<void> _showPartyDetail(PartySalePurchaseEntry entry) async {
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: JoynColors.background,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
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
                      entry.partyName,
                      style: JoynTypography.titleMedium.copyWith(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.close_rounded, color: JoynColors.secondaryText),
                      onPressed: () => Navigator.pop(sheetContext),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _buildAmountTile(
                        'Sale',
                        entry.saleAmount,
                        JoynColors.success,
                        Icons.trending_up_rounded,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildAmountTile(
                        'Purchase',
                        entry.purchaseAmount,
                        JoynColors.error,
                        Icons.trending_down_rounded,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildAmountTile(String label, double value, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: JoynColors.iconBackground,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: JoynColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, size: 14, color: color),
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: JoynTypography.caption.copyWith(
                  fontSize: 11,
                  color: JoynColors.secondaryText,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '₹${_fmt(value)}',
            style: JoynTypography.bodyLarge.copyWith(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
        ],
      ),
    );
  }


  Future<void> _showPdfOptions() async {
    await _showOptionsSheet(
      title: 'PDF Options',
      options: [
        _OptionItem(icon: Icons.description_outlined, label: 'Open PDF', onTap: () {}),
        _OptionItem(icon: Icons.print_outlined, label: 'Print PDF', onTap: () {}),
        _OptionItem(icon: Icons.ios_share_rounded, label: 'Share PDF', onTap: () {}),
        _OptionItem(icon: Icons.download_rounded, label: 'Save PDF to Phone', onTap: () {}),
      ],
    );
  }

  Future<void> _showExcelOptions() async {
    await _showOptionsSheet(
      title: 'Excel Options',
      options: [
        _OptionItem(icon: Icons.description_outlined, label: 'Open Excel', onTap: () {}),
        _OptionItem(icon: Icons.ios_share_rounded, label: 'Share Excel', onTap: () {}),
        _OptionItem(icon: Icons.file_upload_outlined, label: 'Export to Excel', onTap: () {}),
        _OptionItem(icon: Icons.calendar_today_outlined, label: 'Schedule Report', onTap: () {}),
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