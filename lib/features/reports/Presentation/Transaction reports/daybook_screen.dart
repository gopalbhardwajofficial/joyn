import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:joyn/core/theme/joyn_typography.dart';
import 'package:joyn/core/theme/joyn_colors.dart';
import 'package:joyn/core/services/api_service.dart';
import 'package:joyn/core/services/report_export_service.dart';
import 'package:joyn/features/orders/presentation/add_sale_order_screen.dart';
import 'package:joyn/features/orders/presentation/add_purchase_order_screen.dart';
import 'package:joyn/features/reports/Presentation/expenses/manage_expenses_screen.dart';
import 'package:joyn/features/Inventory/presentation/payment_in_screen.dart';
import 'package:joyn/features/orders/data/sales_repository.dart';
import 'package:joyn/features/orders/models/sales_models.dart';

class DayBookScreen extends StatefulWidget {
  const DayBookScreen({super.key});

  @override
  State<DayBookScreen> createState() => _DayBookScreenState();
}

class _DayBookScreenState extends State<DayBookScreen> {
  DateTime selectedDate = DateTime.now();
  bool _isLoading = true;

  double _totalSales = 0.0;
  double _totalPurchases = 0.0;
  double _totalExpenses = 0.0;
  double _netCashFlow = 0.0;
  List<Map<String, dynamic>> _transactions = [];

  @override
  void initState() {
    super.initState();
    _fetchDayBook();
  }

  Future<void> _fetchDayBook() async {
    setState(() => _isLoading = true);
    final dateStr = DateFormat('yyyy-MM-dd').format(selectedDate);
    try {
      final res = await ApiService.fetchDayBook(date: dateStr);
      if (res['success'] == true && ((res['transactions'] as List?)?.isNotEmpty ?? false)) {
        final summary = res['summary'] as Map<String, dynamic>? ?? {};
        final list = (res['transactions'] as List?)?.cast<Map<String, dynamic>>() ?? [];
        if (mounted) {
          setState(() {
            _totalSales = (summary['totalSales'] as num?)?.toDouble() ?? 0.0;
            _totalPurchases = (summary['totalPurchases'] as num?)?.toDouble() ?? 0.0;
            _totalExpenses = (summary['totalExpenses'] as num?)?.toDouble() ?? 0.0;
            _netCashFlow = (summary['netCashFlow'] as num?)?.toDouble() ?? 0.0;
            _transactions = list;
            _isLoading = false;
          });
        }
      } else {
        await _fetchLocalDayBook(dateStr);
      }
    } catch (e) {
      await _fetchLocalDayBook(dateStr);
    }
  }

  Future<void> _fetchLocalDayBook(String dateStr) async {
    try {
      final repo = SalesRepository();
      final allSales = await repo.getSaleOrders();
      final daySales = allSales.where((s) {
        final d = s.date.trim();
        return d.startsWith(dateStr) || d == dateStr;
      }).toList();

      double salesSum = 0.0;
      final txs = <Map<String, dynamic>>[];
      for (final s in daySales) {
        salesSum += s.totalAmount;
        txs.add({
          'type': 'SALE',
          'title': 'Sale Invoice #${s.invoiceNo}',
          'subtitle': s.customerName.isNotEmpty ? s.customerName : 'Walk-in Customer',
          'partyName': s.customerName,
          'amount': s.totalAmount,
          'isPositive': true,
          'timestamp': s.createdAt.toIso8601String(),
        });
      }

      if (mounted) {
        setState(() {
          _totalSales = salesSum;
          _totalPurchases = 0.0;
          _totalExpenses = 0.0;
          _netCashFlow = salesSum;
          _transactions = txs;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _pickDate() async {
    HapticFeedback.lightImpact();
    final picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
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
    if (picked != null && picked != selectedDate) {
      setState(() {
        selectedDate = picked;
      });
      _fetchDayBook();
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateText = DateFormat('dd MMM, yyyy').format(selectedDate);
    final dayName = DateFormat('EEEE').format(selectedDate);
    final isToday = DateFormat('yyyy-MM-dd').format(selectedDate) ==
        DateFormat('yyyy-MM-dd').format(DateTime.now());

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
          'Day Book',
          style: JoynTypography.titleMedium.copyWith(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: JoynColors.primary,
          ),
        ),
        actions: [
          _buildAppBarIconButton(
            label: 'Add',
            icon: Icons.add_circle_outline_rounded,
            color: JoynColors.primary,
            onTap: () => _showAddRecordModal(context),
          ),
          const SizedBox(width: 6),
          _buildAppBarIconButton(
            label: 'Pdf',
            icon: Icons.picture_as_pdf_rounded,
            color: const Color(0xFFDC2626),
            onTap: _exportPdf,
          ),
          const SizedBox(width: 6),
          _buildAppBarIconButton(
            label: 'xls',
            icon: Icons.grid_on_rounded,
            color: JoynColors.success,
            onTap: _exportExcel,
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: Column(
        children: [
          _buildDateSelector(dateText, dayName, isToday),
          const SizedBox(height: 16),
          _buildSummaryStrip(),
          const SizedBox(height: 8),
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: JoynColors.primary),
                  )
                : _transactions.isEmpty
                    ? _buildEmptyState()
                    : RefreshIndicator(
                        onRefresh: _fetchDayBook,
                        color: JoynColors.primary,
                        child: ListView.builder(
                          padding: const EdgeInsets.only(top: 4, bottom: 20),
                          itemCount: _transactions.length,
                          itemBuilder: (context, index) => _buildTransactionTile(_transactions[index]),
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  // Enhanced Date Selector
  Widget _buildDateSelector(String dateText, String dayName, bool isToday) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
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
      child: InkWell(
        onTap: _pickDate,
        borderRadius: BorderRadius.circular(12),
        child: Row(
          children: [
            // Calendar Icon Container
            Container(
              width: 48,
              height: 48,
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
              child: Icon(
                Icons.calendar_today_rounded,
                size: 20,
                color: JoynColors.primary,
              ),
            ),
            const SizedBox(width: 12),
            // Date Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        'Selected Date',
                        style: JoynTypography.caption.copyWith(
                          fontSize: 11,
                          color: JoynColors.secondaryText,
                        ),
                      ),
                      if (isToday) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: JoynColors.success.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            'Today',
                            style: JoynTypography.caption.copyWith(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: JoynColors.success,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    dateText,
                    style: JoynTypography.bodyLarge.copyWith(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: JoynColors.primary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    dayName,
                    style: JoynTypography.caption.copyWith(
                      fontSize: 11,
                      color: JoynColors.secondaryText,
                    ),
                  ),
                ],
              ),
            ),
            // Arrow
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: JoynColors.surfaceMuted,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.keyboard_arrow_down_rounded,
                size: 18,
                color: JoynColors.secondaryText,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Enhanced Summary Strip
  Widget _buildSummaryStrip() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 0),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            JoynColors.primary,
            JoynColors.primary.withValues(alpha: 0.9),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
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
              label: 'Sales',
              value: '₹${_totalSales.toStringAsFixed(2)}',
            ),
          ),
          Container(width: 1, height: 40, color: Colors.white24),
          Expanded(
            child: _buildSummaryItem(
              icon: Icons.receipt_rounded,
              label: 'Purchases',
              value: '₹${_totalPurchases.toStringAsFixed(2)}',
            ),
          ),
          Container(width: 1, height: 40, color: Colors.white24),
          Expanded(
            child: _buildSummaryItem(
              icon: Icons.payments_rounded,
              label: 'Expenses',
              value: '₹${_totalExpenses.toStringAsFixed(2)}',
              valueColor: const Color(0xFFFFB86B),
            ),
          ),
          Container(width: 1, height: 40, color: Colors.white24),
          Expanded(
            child: _buildSummaryItem(
              icon: Icons.account_balance_wallet_rounded,
              label: 'Net Cash',
              value: '₹${_netCashFlow.toStringAsFixed(2)}',
              valueColor: _netCashFlow >= 0 ? const Color(0xFF4ADE80) : const Color(0xFFF87171),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionTile(Map<String, dynamic> item) {
    final type = item['type']?.toString() ?? 'Sale';
    final title = item['title']?.toString() ?? 'Transaction';
    final subtitle = item['subtitle']?.toString() ?? '';
    final partyName = item['partyName']?.toString() ?? '';
    final amount = (item['amount'] as num?)?.toDouble() ?? 0.0;
    final isPositive = item['isPositive'] == true;
    final timestamp = DateTime.tryParse(item['timestamp']?.toString() ?? '') ?? DateTime.now();
    final timeStr = DateFormat('hh:mm a').format(timestamp);

    Color badgeColor;
    IconData badgeIcon;
    if (type == 'Sale') {
      badgeColor = JoynColors.primary;
      badgeIcon = Icons.shopping_bag_outlined;
    } else if (type == 'Purchase') {
      badgeColor = Colors.orange;
      badgeIcon = Icons.inventory_2_outlined;
    } else if (type == 'PaymentIn') {
      badgeColor = JoynColors.success;
      badgeIcon = Icons.arrow_downward_rounded;
    } else if (type == 'PaymentOut') {
      badgeColor = Colors.redAccent;
      badgeIcon = Icons.arrow_upward_rounded;
    } else {
      badgeColor = Colors.deepPurple;
      badgeIcon = Icons.payments_outlined;
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: JoynColors.border.withValues(alpha: 0.6)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: badgeColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(badgeIcon, color: badgeColor, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: JoynTypography.bodyLarge.copyWith(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    color: JoynColors.primary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle.isNotEmpty ? subtitle : partyName,
                  style: JoynTypography.caption.copyWith(
                    color: JoynColors.secondaryText,
                    fontSize: 12,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${isPositive ? '+' : '-'}₹${amount.toStringAsFixed(2)}',
                style: JoynTypography.bodyLarge.copyWith(
                  fontWeight: FontWeight.w800,
                  fontSize: 14,
                  color: isPositive ? JoynColors.success : const Color(0xFFDC2626),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                timeStr,
                style: JoynTypography.caption.copyWith(
                  color: JoynColors.secondaryText.withValues(alpha: 0.8),
                  fontSize: 11,
                ),
              ),
            ],
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
                Icons.receipt_long_rounded,
                size: 48,
                color: JoynColors.secondaryText.withValues(alpha: 0.5),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'No entries yet',
              style: JoynTypography.titleMedium.copyWith(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: JoynColors.primary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'There\u2019s no data available for this day. Sales, purchases and expenses recorded on this date will show up here.',
              textAlign: TextAlign.center,
              style: JoynTypography.bodyMedium.copyWith(
                fontSize: 13.5,
                color: JoynColors.secondaryText,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 24),
            // Add Record Button
            Material(
              color: JoynColors.primary,
              borderRadius: BorderRadius.circular(24),
              child: InkWell(
                onTap: () => _showAddRecordModal(context),
                borderRadius: BorderRadius.circular(24),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.add_rounded, size: 18, color: Colors.white),
                      const SizedBox(width: 6),
                      Text(
                        'Add Record',
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
      ),
    );
  }

  void _showAddRecordModal(BuildContext context) {
    HapticFeedback.lightImpact();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.black12,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Text(
                'Record Day Transaction',
                style: JoynTypography.titleMedium.copyWith(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: JoynColors.primary,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Choose transaction type to record for today',
                style: JoynTypography.caption.copyWith(
                  fontSize: 13,
                  color: JoynColors.secondaryText,
                ),
              ),
              const SizedBox(height: 20),
              _buildAddRecordTile(
                icon: Icons.point_of_sale_rounded,
                iconColor: JoynColors.primary,
                title: 'Sale Invoice',
                subtitle: 'Create a new customer invoice / bill',
                onTap: () async {
                  Navigator.pop(ctx);
                  await Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const AddSaleOrderScreen()),
                  );
                  _fetchDayBook();
                },
              ),
              const SizedBox(height: 10),
              _buildAddRecordTile(
                icon: Icons.shopping_cart_checkout_rounded,
                iconColor: Colors.blue.shade700,
                title: 'Purchase Bill',
                subtitle: 'Record supplier purchase or stock entry',
                onTap: () async {
                  Navigator.pop(ctx);
                  await Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const AddPurchaseOrderScreen()),
                  );
                  _fetchDayBook();
                },
              ),
              const SizedBox(height: 10),
              _buildAddRecordTile(
                icon: Icons.receipt_long_rounded,
                iconColor: Colors.orange.shade800,
                title: 'Record Expense',
                subtitle: 'Log operating, utility or general business expenses',
                onTap: () async {
                  Navigator.pop(ctx);
                  await Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const ManageExpensesScreen()),
                  );
                  _fetchDayBook();
                },
              ),
              const SizedBox(height: 10),
              _buildAddRecordTile(
                icon: Icons.call_received_rounded,
                iconColor: JoynColors.success,
                title: 'Receive Payment',
                subtitle: 'Record customer payment or cash receipt',
                onTap: () async {
                  Navigator.pop(ctx);
                  final parties = await SalesRepository().getParties();
                  PartyModel? selectedParty;
                  if (parties.isNotEmpty && context.mounted) {
                    selectedParty = await showModalBottomSheet<PartyModel>(
                      context: context,
                      backgroundColor: Colors.white,
                      shape: const RoundedRectangleBorder(
                        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                      ),
                      builder: (c) => SafeArea(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Padding(
                              padding: const EdgeInsets.all(16),
                              child: Text(
                                'Select Party for Payment',
                                style: JoynTypography.titleMedium.copyWith(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                            const Divider(height: 1),
                            Flexible(
                              child: ListView.builder(
                                shrinkWrap: true,
                                itemCount: parties.length,
                                itemBuilder: (_, i) => ListTile(
                                  title: Text(parties[i].name, style: JoynTypography.bodyLarge),
                                  subtitle: parties[i].contactNumber.isNotEmpty
                                      ? Text(parties[i].contactNumber)
                                      : null,
                                  trailing: const Icon(Icons.chevron_right_rounded),
                                  onTap: () => Navigator.pop(c, parties[i]),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  } else {
                    selectedParty = PartyModel(
                      id: 'walkin',
                      name: 'Cash Customer',
                      createdAt: DateTime.now(),
                    );
                  }

                  if (selectedParty != null && context.mounted) {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => PaymentInScreen(party: selectedParty!),
                      ),
                    );
                    _fetchDayBook();
                  }
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAddRecordTile({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: iconColor.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: iconColor.withValues(alpha: 0.15)),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: iconColor, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: JoynTypography.bodyLarge.copyWith(
                      fontWeight: FontWeight.w700,
                      fontSize: 14.5,
                      color: JoynColors.primary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: JoynTypography.caption.copyWith(
                      fontSize: 12,
                      color: JoynColors.secondaryText,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: JoynColors.secondaryText.withValues(alpha: 0.5)),
          ],
        ),
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

  Future<void> _exportPdf() async {
    final dateStr = DateFormat('dd/MM/yyyy').format(selectedDate);
    final tableHeaders = ['Time', 'Type', 'Title / Party', 'Details', 'Amount'];
    final tableRows = _transactions.map((item) {
      final type = item['type']?.toString() ?? 'Sale';
      final title = item['title']?.toString() ?? 'Transaction';
      final subtitle = item['subtitle']?.toString() ?? '';
      final partyName = item['partyName']?.toString() ?? '';
      final amount = (item['amount'] as num?)?.toDouble() ?? 0.0;
      final isPositive = item['isPositive'] == true;
      final timestamp = DateTime.tryParse(item['timestamp']?.toString() ?? '') ?? DateTime.now();
      final timeStr = DateFormat('hh:mm a').format(timestamp);
      final partyDisplay = partyName.isNotEmpty ? partyName : title;
      final sign = isPositive ? '+' : '-';
      return [
        timeStr,
        type,
        partyDisplay,
        subtitle,
        '$sign₹${amount.toStringAsFixed(2)}',
      ];
    }).toList();

    final summary = {
      'Date': dateStr,
      'Total Sales': '₹${_totalSales.toStringAsFixed(2)}',
      'Total Purchases': '₹${_totalPurchases.toStringAsFixed(2)}',
      'Total Expenses': '₹${_totalExpenses.toStringAsFixed(2)}',
      'Net Cash Flow': '₹${_netCashFlow.toStringAsFixed(2)}',
    };

    await ReportExportService.showPdfOptionsSheet(
      context: context,
      title: 'Day Book Report',
      periodLabel: dateStr,
      summaryStats: summary,
      tableHeaders: tableHeaders,
      tableRows: tableRows,
    );
  }

  Future<void> _exportExcel() async {
    final dateStr = DateFormat('dd/MM/yyyy').format(selectedDate);
    final tableHeaders = ['Time', 'Type', 'Title / Party', 'Details', 'Amount (INR)'];
    final tableRows = _transactions.map((item) {
      final type = item['type']?.toString() ?? 'Sale';
      final title = item['title']?.toString() ?? 'Transaction';
      final subtitle = item['subtitle']?.toString() ?? '';
      final partyName = item['partyName']?.toString() ?? '';
      final amount = (item['amount'] as num?)?.toDouble() ?? 0.0;
      final isPositive = item['isPositive'] == true;
      final timestamp = DateTime.tryParse(item['timestamp']?.toString() ?? '') ?? DateTime.now();
      final timeStr = DateFormat('hh:mm a').format(timestamp);
      final partyDisplay = partyName.isNotEmpty ? partyName : title;
      final signedAmount = (isPositive ? amount : -amount).toStringAsFixed(2);
      return [
        timeStr,
        type,
        partyDisplay,
        subtitle,
        signedAmount,
      ];
    }).toList();

    final summary = {
      'Date': dateStr,
      'Total Sales': '₹${_totalSales.toStringAsFixed(2)}',
      'Total Purchases': '₹${_totalPurchases.toStringAsFixed(2)}',
      'Total Expenses': '₹${_totalExpenses.toStringAsFixed(2)}',
      'Net Cash Flow': '₹${_netCashFlow.toStringAsFixed(2)}',
    };

    await ReportExportService.showExcelOptionsSheet(
      context: context,
      title: 'Day Book Report',
      periodLabel: dateStr,
      summaryStats: summary,
      tableHeaders: tableHeaders,
      tableRows: tableRows,
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