import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../../../../core/services/api_service.dart';
import '../../../../core/services/report_export_service.dart';
import '../../../orders/data/sales_repository.dart';

enum TxnType {
  sale,
  purchase,
  paymentIn,
  paymentOut,
  expense,
  creditNote,
  debitNote,
  estimate,
}

class TransactionEntry {
  final String partyName;
  final DateTime date;
  final TxnType type;
  final int txnNumber;
  final double total;
  final double balance;

  const TransactionEntry({
    required this.partyName,
    required this.date,
    required this.type,
    required this.txnNumber,
    required this.total,
    required this.balance,
  });

  bool get isFullyPaid => balance <= 0;
}

const Map<TxnType, String> kTxnTypeLabels = {
  TxnType.sale: 'Sale',
  TxnType.purchase: 'Purchase',
  TxnType.paymentIn: 'Payment-In',
  TxnType.paymentOut: 'Payment-Out',
  TxnType.expense: 'Expense',
  TxnType.creditNote: 'Credit Note',
  TxnType.debitNote: 'Debit Note',
  TxnType.estimate: 'Estimate',
};

final List<String> kTxnTypeFilterOptions = [
  'All Transactions',
  ...kTxnTypeLabels.values,
];

class AllTransactionsScreen extends StatefulWidget {
  final List<TransactionEntry>? transactions;

  const AllTransactionsScreen({super.key, this.transactions});

  @override
  State<AllTransactionsScreen> createState() => _AllTransactionsScreenState();
}

class _AllTransactionsScreenState extends State<AllTransactionsScreen> {
  // Vyapar Theme Colors
  static const _appBarColor = Color(0xFF087099); // Exact Vyapar Cyan-Blue
  static const _dividerColor = Color(0xFFE2E8F0);
  static const _labelGrey = Color(0xFF94A3B8);
  static const _textDark = Color(0xFF1E293B);
  static const _blueAccent = Color(0xFF0284C7);

  DateTimeRange _range = DateTimeRange(
    start: DateTime(DateTime.now().year, DateTime.now().month, 1),
    end: DateTime(DateTime.now().year, DateTime.now().month + 1, 0),
  );
  String _period = 'This month';
  String _typeFilter = 'All Transactions';
  String _partyFilter = 'All parties';
  List<TransactionEntry> _loadedTransactions = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    if (widget.transactions != null && widget.transactions!.isNotEmpty) {
      _loadedTransactions = widget.transactions!;
      _isLoading = false;
    } else {
      _loadDynamicTransactions();
    }
  }

  TxnType _parseTxnType(String raw) {
    final lower = raw.toLowerCase().trim();
    if (lower.contains('sale')) return TxnType.sale;
    if (lower.contains('purchase')) return TxnType.purchase;
    if (lower.contains('payment-in') || lower.contains('payment in') || lower.contains('payment_in')) return TxnType.paymentIn;
    if (lower.contains('payment-out') || lower.contains('payment out') || lower.contains('payment_out')) return TxnType.paymentOut;
    if (lower.contains('expense')) return TxnType.expense;
    if (lower.contains('credit')) return TxnType.creditNote;
    if (lower.contains('debit')) return TxnType.debitNote;
    if (lower.contains('estimate') || lower.contains('quotation')) return TxnType.estimate;
    return TxnType.sale;
  }

  Future<void> _loadDynamicTransactions() async {
    setState(() => _isLoading = true);
    final sStr = DateFormat('yyyy-MM-dd').format(_range.start);
    final eStr = DateFormat('yyyy-MM-dd').format(_range.end);

    try {
      final res = await ApiService.getAllTransactionsReport(
        startDate: sStr,
        endDate: eStr,
        txnType: _typeFilter == 'All Transactions' ? null : _typeFilter,
      );

      if (res['success'] == true && res['transactions'] is List && (res['transactions'] as List).isNotEmpty) {
        final list = (res['transactions'] as List).map((t) {
          final typeStr = (t['type'] ?? 'Sale').toString();
          return TransactionEntry(
            partyName: (t['partyName'] ?? 'Customer').toString(),
            date: DateTime.tryParse(t['date']?.toString() ?? '') ?? DateTime.now(),
            type: _parseTxnType(typeStr),
            txnNumber: (t['txnNumber'] as num?)?.toInt() ?? 0,
            total: (t['total'] as num?)?.toDouble() ?? 0.0,
            balance: (t['balance'] as num?)?.toDouble() ?? 0.0,
          );
        }).toList();

        if (mounted) {
          setState(() {
            _loadedTransactions = list;
            _isLoading = false;
          });
          return;
        }
      }
      await _loadLocalTransactions();
    } catch (_) {
      await _loadLocalTransactions();
    }
  }

  Future<void> _loadLocalTransactions() async {
    try {
      final repo = SalesRepository();
      final sales = await repo.getSaleOrders();
      final purchases = await repo.getPurchaseOrders();

      final List<TransactionEntry> entries = [];
      for (final s in sales) {
        entries.add(TransactionEntry(
          partyName: s.customerName.isNotEmpty ? s.customerName : 'Cash Customer',
          date: DateTime.tryParse(s.date) ?? s.createdAt,
          type: TxnType.sale,
          txnNumber: s.invoiceNo,
          total: s.totalAmount,
          balance: s.balanceDue,
        ));
      }
      for (final p in purchases) {
        entries.add(TransactionEntry(
          partyName: p.partyName.isNotEmpty ? p.partyName : 'Supplier',
          date: DateTime.tryParse(p.date) ?? p.createdAt,
          type: TxnType.purchase,
          txnNumber: p.orderNo,
          total: p.totalAmount,
          balance: 0,
        ));
      }

      if (mounted) {
        setState(() {
          _loadedTransactions = entries;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _loadedTransactions = [];
          _isLoading = false;
        });
      }
    }
  }

  List<TransactionEntry> get _filtered {
    final list = widget.transactions ?? _loadedTransactions;
    return list.where((t) {
      final inRange = !t.date.isBefore(_range.start) &&
          !t.date.isAfter(_range.end.add(const Duration(days: 1)));
      final typeOk = _typeFilter == 'All Transactions' ||
          kTxnTypeLabels[t.type] == _typeFilter;
      final partyOk = _partyFilter == 'All parties' || t.partyName == _partyFilter;
      return inRange && typeOk && partyOk;
    }).toList()
      ..sort((a, b) => b.date.compareTo(a.date));
  }

  @override
  Widget build(BuildContext context) {
    final items = _filtered;
    final cur = NumberFormat('#,##0.00', 'en_IN');

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: _appBarColor,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleSpacing: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white, size: 22),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        title: const Text(
          'All Transactions',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: 18,
          ),
          overflow: TextOverflow.ellipsis,
        ),
        actions: [
          _buildActionButton(
            label: 'Pdf',
            color: const Color(0xFFDC2626),
            onTap: _exportRealPdf,
          ),
          const SizedBox(width: 8),
          _buildActionButton(
            label: 'xls',
            color: const Color(0xFF16A34A),
            onTap: _exportRealExcel,
          ),
          const SizedBox(width: 14),
        ],
      ),
      body: Column(
        children: [
          // ── Vyapar 3-Row Filter Bar ────────────────────────────────────────
          _buildVyaparFilters(),

          // ── Transactions List (Table Style) ───────────────────────────────
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: _appBarColor, strokeWidth: 2.5))
                : RefreshIndicator(
                    color: _appBarColor,
                    onRefresh: _loadDynamicTransactions,
                    child: items.isEmpty
                        ? _buildEmptyState()
                        : ListView.separated(
                            itemCount: items.length,
                            separatorBuilder: (_, __) => Container(height: 1, color: _dividerColor),
                            itemBuilder: (context, i) => _buildTransactionRow(items[i], cur),
                          ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      borderRadius: BorderRadius.circular(5),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(5),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.3),
              blurRadius: 4,
              offset: const Offset(0, 1.5),
            ),
          ],
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w800,
            fontSize: 12,
            height: 1.0,
          ),
        ),
      ),
    );
  }

  // =========================================================================
  // EXACT VYAPAR 3-ROW FILTER SECTION
  // =========================================================================
  Widget _buildVyaparFilters() {
    final dateFmt = DateFormat('dd/MM/yyyy');
    return Container(
      color: Colors.white,
      child: Column(
        children: [
          // ── Row 1: Period Dropdown | Date Range ──────────────────────────
          Container(
            height: 44,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Row(
              children: [
                // Left: Period (e.g. Custom / This Month)
                InkWell(
                  onTap: () async {
                    HapticFeedback.lightImpact();
                    final choice = await _showPeriodPicker();
                    if (choice != null) {
                      setState(() => _period = choice);
                      _loadDynamicTransactions();
                    }
                  },
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _period,
                        style: const TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w400,
                          color: _textDark,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(Icons.arrow_drop_down, color: Color(0xFF475569), size: 20),
                    ],
                  ),
                ),

                const SizedBox(width: 10),
                // Vertical divider
                Container(width: 1, height: 24, color: const Color(0xFFCBD5E1)),
                const SizedBox(width: 12),

                // Right: Calendar Icon & Dates
                Expanded(
                  child: InkWell(
                    onTap: _pickDateRange,
                    child: Row(
                      children: [
                        const Icon(Icons.calendar_today_outlined, size: 16, color: _blueAccent),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            '${dateFmt.format(_range.start)}   to   ${dateFmt.format(_range.end)}',
                            style: const TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w400,
                              color: _textDark,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          Container(height: 1, color: _dividerColor),

          // ── Row 2: All Transactions Dropdown ─────────────────────────────
          InkWell(
            onTap: () async {
              HapticFeedback.lightImpact();
              final choice = await _showChoiceSheet(
                'Transaction type',
                kTxnTypeFilterOptions,
                _typeFilter,
                scrollable: true,
              );
              if (choice != null) {
                setState(() => _typeFilter = choice);
                _loadDynamicTransactions();
              }
            },
            child: Container(
              height: 42,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: Row(
                children: [
                  Text(
                    _typeFilter,
                    style: const TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w400,
                      color: _textDark,
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Icon(Icons.arrow_drop_down, color: Color(0xFF475569), size: 20),
                ],
              ),
            ),
          ),
          Container(height: 1, color: _dividerColor),

          // ── Row 3: Party Name All parties Dropdown ────────────────────────
          InkWell(
            onTap: () async {
              HapticFeedback.lightImpact();
              final sourceList = widget.transactions ?? _loadedTransactions;
              final parties = <String>{'All parties', ...sourceList.map((t) => t.partyName)}.toList();
              final choice = await _showChoiceSheet('Party Name', parties, _partyFilter);
              if (choice != null) {
                setState(() => _partyFilter = choice);
              }
            },
            child: Container(
              height: 42,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: Row(
                children: [
                  const Text(
                    'Party Name',
                    style: TextStyle(
                      color: _blueAccent,
                      fontSize: 13.5,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      _partyFilter,
                      style: const TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w400,
                        color: _textDark,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const Icon(Icons.arrow_drop_down, color: Color(0xFF475569), size: 20),
                ],
              ),
            ),
          ),
          Container(height: 1, color: _dividerColor),
        ],
      ),
    );
  }

  // =========================================================================
  // EXACT VYAPAR TRANSACTION ROW
  // =========================================================================
  Widget _buildTransactionRow(TransactionEntry entry, NumberFormat cur) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Left Column: Party Name & Date ────────────────────────────────
          Expanded(
            flex: 4,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.partyName.isNotEmpty ? entry.partyName : 'Cash Customer',
                  style: const TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w500,
                    color: _textDark,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  DateFormat('dd/MM/yyyy').format(entry.date),
                  style: const TextStyle(
                    fontSize: 12,
                    color: _labelGrey,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),

          // ── Center Column: Type : Txn# ────────────────────────────────────
          Expanded(
            flex: 3,
            child: Text(
              '${kTxnTypeLabels[entry.type] ?? 'Sale'} : ${entry.txnNumber}',
              style: const TextStyle(
                fontSize: 13,
                color: Color(0xFF334155),
                fontWeight: FontWeight.w400,
              ),
            ),
          ),

          // ── Right Column: Total & Balance ─────────────────────────────────
          Expanded(
            flex: 4,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  'Total : ₹ ${cur.format(entry.total)}',
                  textAlign: TextAlign.right,
                  style: const TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w500,
                    color: _textDark,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  'Balance: ₹ ${cur.format(entry.balance)}',
                  textAlign: TextAlign.right,
                  style: const TextStyle(
                    fontSize: 12,
                    color: _labelGrey,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.receipt_long_outlined, color: Colors.blueGrey.shade300, size: 50),
          const SizedBox(height: 12),
          const Text(
            'No transactions found for this period',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 14.5,
              color: Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              foregroundColor: _appBarColor,
              side: const BorderSide(color: Color(0xFFCBD5E1)),
            ),
            icon: const Icon(Icons.calendar_month_rounded, size: 16),
            label: const Text('Change Date Range'),
            onPressed: _pickDateRange,
          ),
        ],
      ),
    );
  }

  Future<void> _pickDateRange() async {
    HapticFeedback.lightImpact();
    final picked = await showDateRangePicker(
      context: context,
      initialDateRange: _range,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(primary: _appBarColor),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() {
        _range = picked;
        _period = 'Custom';
      });
      _loadDynamicTransactions();
    }
  }

  Future<String?> _showPeriodPicker() {
    return _showChoiceSheet(
      'Period',
      const ['Today', 'This week', 'This month', 'Last month', 'This year', 'Custom'],
      _period,
    );
  }

  Future<String?> _showChoiceSheet(
    String title,
    List<String> options,
    String selected, {
    bool scrollable = false,
  }) {
    return showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                margin: const EdgeInsets.symmetric(vertical: 8),
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: _textDark,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.close, size: 20),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: options.length,
                  itemBuilder: (ctx, i) {
                    final opt = options[i];
                    final isSel = opt == selected;
                    return ListTile(
                      dense: true,
                      title: Text(
                        opt,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: isSel ? FontWeight.w700 : FontWeight.w400,
                          color: isSel ? _appBarColor : _textDark,
                        ),
                      ),
                      trailing: isSel ? const Icon(Icons.check, color: _appBarColor, size: 20) : null,
                      onTap: () => Navigator.pop(ctx, opt),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _exportRealPdf() async {
    if (_filtered.isEmpty) return;
    final dateFmt = DateFormat('dd/MM/yyyy');
    final cur = NumberFormat('#,##0.00', 'en_IN');
    final periodStr = '${dateFmt.format(_range.start)} to ${dateFmt.format(_range.end)}';
    final entries = _filtered;
    final tableHeaders = ['Date', 'Txn #', 'Party', 'Type', 'Total', 'Balance'];

    final tableRows = entries.map((e) {
      return [
        dateFmt.format(e.date),
        e.txnNumber.toString(),
        e.partyName,
        kTxnTypeLabels[e.type] ?? 'Sale',
        '₹ ${cur.format(e.total)}',
        '₹ ${cur.format(e.balance)}',
      ];
    }).toList();

    final totalVol = entries.fold(0.0, (s, t) => s + t.total);
    final totalBal = entries.fold(0.0, (s, t) => s + t.balance);

    await ReportExportService.showPdfOptionsSheet(
      context: context,
      title: 'All Transactions',
      periodLabel: periodStr,
      summaryStats: {
        'Period': periodStr,
        'Transactions': entries.length.toString(),
        'Total Amount': '₹ ${cur.format(totalVol)}',
        'Balance Due': '₹ ${cur.format(totalBal)}',
      },
      tableHeaders: tableHeaders,
      tableRows: tableRows,
    );
  }

  Future<void> _exportRealExcel() async {
    if (_filtered.isEmpty) return;
    final dateFmt = DateFormat('dd/MM/yyyy');
    final cur = NumberFormat('#,##0.00', 'en_IN');
    final periodStr = '${dateFmt.format(_range.start)} to ${dateFmt.format(_range.end)}';
    final entries = _filtered;
    final tableHeaders = ['Date', 'Txn #', 'Party', 'Type', 'Total (INR)', 'Balance (INR)'];

    final tableRows = entries.map((e) {
      return [
        dateFmt.format(e.date),
        e.txnNumber.toString(),
        e.partyName,
        kTxnTypeLabels[e.type] ?? 'Sale',
        cur.format(e.total),
        cur.format(e.balance),
      ];
    }).toList();

    final totalVol = entries.fold(0.0, (s, t) => s + t.total);
    final totalBal = entries.fold(0.0, (s, t) => s + t.balance);

    await ReportExportService.showExcelOptionsSheet(
      context: context,
      title: 'All Transactions',
      periodLabel: periodStr,
      summaryStats: {
        'Period': periodStr,
        'Transactions': entries.length.toString(),
        'Total Amount': cur.format(totalVol),
        'Balance Due': cur.format(totalBal),
      },
      tableHeaders: tableHeaders,
      tableRows: tableRows,
    );
  }
}
