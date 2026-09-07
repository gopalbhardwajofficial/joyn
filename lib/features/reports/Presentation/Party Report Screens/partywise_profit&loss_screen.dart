import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:joyn/core/theme/joyn_typography.dart';
import 'package:joyn/core/theme/joyn_colors.dart';
import 'package:joyn/core/widgets/Premium_widget.dart';

class PartyProfit {
  final String partyName;
  final double saleAmount;
  final double profitLoss;

  PartyProfit({
    required this.partyName,
    required this.saleAmount,
    required this.profitLoss,
  });
}

class PartyWiseProfitLossScreen extends StatefulWidget {
  const PartyWiseProfitLossScreen({super.key});

  @override
  State<PartyWiseProfitLossScreen> createState() => _PartyWiseProfitLossScreenState();
}

class _PartyWiseProfitLossScreenState extends State<PartyWiseProfitLossScreen> {
  String selectedPeriod = 'This Month';
  DateTime fromDate = DateTime(2026, 9, 1);
  DateTime toDate = DateTime(2026, 9, 30);
  bool _isLoading = false;

  final List<PartyProfit> parties = [
    PartyProfit(partyName: 'Gopal', saleAmount: 1000.00, profitLoss: 1000.00),
    PartyProfit(partyName: 'gill', saleAmount: 100.00, profitLoss: 100.00),
  ];

  double get totalSaleAmount => parties.fold(0, (sum, p) => sum + p.saleAmount);
  double get totalProfitLoss => parties.fold(0, (sum, p) => sum + p.profitLoss);

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
          'Party Wise P & L',
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
                : parties.isEmpty
                ? _buildEmptyState()
                : _buildPartiesList(currency),
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
    final isProfit = totalProfitLoss >= 0;
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
              icon: Icons.point_of_sale_rounded,
              label: 'Total Sale',
              value: '₹ ${currency.format(totalSaleAmount)}',
            ),
          ),
          Container(width: 1, height: 40, color: Colors.white24),
          Expanded(
            child: _buildSummaryItem(
              icon: isProfit ? Icons.trending_up_rounded : Icons.trending_down_rounded,
              label: 'Profit / Loss',
              value: '${isProfit ? '+' : '-'} ₹ ${currency.format(totalProfitLoss.abs())}',
              valueColor: isProfit ? const Color(0xFF4ADE80) : const Color(0xFFF87171),
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
      margin: const EdgeInsets.symmetric(horizontal: 16),
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
              'Party Name',
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
              'Sale Amount',
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
              'Profit/Loss',
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

  // Enhanced Parties List
  Widget _buildPartiesList(NumberFormat currency) {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      itemCount: parties.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final p = parties[index];
        final isProfit = p.profitLoss >= 0;
        final initials = p.partyName.isNotEmpty ? p.partyName[0].toUpperCase() : '?';

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
                onTap: () => _showPartyDetail(p, currency),
                borderRadius: BorderRadius.circular(16),
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Row(
                    children: [
                      // Avatar
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              isProfit
                                  ? JoynColors.success.withValues(alpha: 0.1)
                                  : JoynColors.error.withValues(alpha: 0.1),
                              isProfit
                                  ? JoynColors.success.withValues(alpha: 0.05)
                                  : JoynColors.error.withValues(alpha: 0.05),
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
                            color: isProfit ? JoynColors.success : JoynColors.error,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Party Name
                      Expanded(
                        flex: 3,
                        child: Text(
                          p.partyName,
                          style: JoynTypography.bodyLarge.copyWith(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: JoynColors.primary,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      // Sale Amount
                      Expanded(
                        flex: 2,
                        child: Text(
                          '₹ ${currency.format(p.saleAmount)}',
                          textAlign: TextAlign.center,
                          style: JoynTypography.bodyMedium.copyWith(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: JoynColors.primary,
                          ),
                        ),
                      ),
                      // Profit/Loss
                      Expanded(
                        flex: 2,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                          decoration: BoxDecoration(
                            color: isProfit
                                ? JoynColors.success.withValues(alpha: 0.1)
                                : JoynColors.error.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '${isProfit ? '+' : '-'} ₹ ${currency.format(p.profitLoss.abs())}',
                            textAlign: TextAlign.right,
                            style: JoynTypography.caption.copyWith(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: isProfit ? JoynColors.success : JoynColors.error,
                            ),
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

  // Enhanced Empty State
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
                Icons.groups_rounded,
                size: 48,
                color: JoynColors.secondaryText.withValues(alpha: 0.5),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'No data available',
              style: JoynTypography.titleMedium.copyWith(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: JoynColors.primary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Party wise profit and loss will appear here once you record sales.',
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

  // Party Detail Bottom Sheet
  Future<void> _showPartyDetail(PartyProfit party, NumberFormat currency) async {
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: JoynColors.background,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) {
        final isProfit = party.profitLoss >= 0;
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: JoynColors.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  width: 60,
                  height: 60,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        isProfit
                            ? JoynColors.success.withValues(alpha: 0.15)
                            : JoynColors.error.withValues(alpha: 0.15),
                        isProfit
                            ? JoynColors.success.withValues(alpha: 0.05)
                            : JoynColors.error.withValues(alpha: 0.05),
                      ],
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    party.partyName[0].toUpperCase(),
                    style: JoynTypography.titleMedium.copyWith(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      color: isProfit ? JoynColors.success : JoynColors.error,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  party.partyName,
                  style: JoynTypography.titleMedium.copyWith(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 16),
                _buildDetailRow('Sale Amount', '₹ ${currency.format(party.saleAmount)}'),
                _buildDetailRow(
                  'Profit/Loss',
                  '${isProfit ? '+' : '-'} ₹ ${currency.format(party.profitLoss.abs())}',
                  valueColor: isProfit ? JoynColors.success : JoynColors.error,
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => Navigator.pop(sheetContext),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: JoynColors.primary,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                    minimumSize: const Size(double.infinity, 48),
                  ),
                  child: Text(
                    'Close',
                    style: JoynTypography.buttonText.copyWith(fontSize: 14),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildDetailRow(String label, String value, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: JoynTypography.bodyMedium.copyWith(
              color: JoynColors.secondaryText,
            ),
          ),
          Text(
            value,
            style: JoynTypography.bodyLarge.copyWith(
              fontWeight: FontWeight.w700,
              color: valueColor ?? JoynColors.primary,
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