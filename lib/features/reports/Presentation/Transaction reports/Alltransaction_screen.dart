import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

/// ---------------------------------------------------------------------------
/// AllTransactionsScreen — enhanced UI, matching Joyn/LedgerOne's
/// black-and-white minimal aesthetic (Plus Jakarta Sans, generous whitespace,
/// pill filters, card-based list, functional color only for status).
/// ---------------------------------------------------------------------------

enum TxnType {
  sale,
  purchase,
  expense,
  partyToPartyPaid,
  partyToPartyReceived,
  paymentIn,
  paymentOut,
  creditNote,
  debitNote,
  saleCancelled,
  purchaseJobWork,
  saleOrder,
  purchaseOrder,
  estimate,
  deliveryChallan,
  saleFA,
  purchaseFA,
  journalEntry,
  saleRepeating,
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
  bool get isSaleSide => type == TxnType.sale || type == TxnType.paymentIn;
}

/// Display label shown in the type filter dropdown and on each txn badge.
const Map<TxnType, String> kTxnTypeLabels = {
  TxnType.sale: 'Sale',
  TxnType.purchase: 'Purchase',
  TxnType.expense: 'Expense',
  TxnType.partyToPartyPaid: 'Party To Party [Paid]',
  TxnType.partyToPartyReceived: 'Party To Party [Rcvd]',
  TxnType.paymentIn: 'Payment-In',
  TxnType.paymentOut: 'Payment-Out',
  TxnType.creditNote: 'Credit Note',
  TxnType.debitNote: 'Debit Note',
  TxnType.saleCancelled: 'Sale [Cancelled]',
  TxnType.purchaseJobWork: 'Purchase (Job work)',
  TxnType.saleOrder: 'Sale Order',
  TxnType.purchaseOrder: 'Purchase Order',
  TxnType.estimate: 'Estimate',
  TxnType.deliveryChallan: 'Delivery Challan',
  TxnType.saleFA: 'Sale FA',
  TxnType.purchaseFA: 'Purchase FA',
  TxnType.journalEntry: 'Journal Entry',
  TxnType.saleRepeating: 'Sale [Repeating]',
};

/// Full ordered list for the "Transaction type" filter sheet, "All
/// Transactions" first, followed by every type in the reference order.
final List<String> kTxnTypeFilterOptions = [
  'All Transactions',
  ...kTxnTypeLabels.values,
];

class AllTransactionsScreen extends StatefulWidget {
  final List<TransactionEntry> transactions;

  const AllTransactionsScreen({super.key, required this.transactions});

  @override
  State<AllTransactionsScreen> createState() => _AllTransactionsScreenState();
}

class _AllTransactionsScreenState extends State<AllTransactionsScreen> {
  static const _ink = Color(0xFF12131A);
  static const _muted = Color(0xFF8A8D98);
  static const _line = Color(0xFFEBEBEF);
  static const _bg = Color(0xFFFAFAFB);
  static const _cardBg = Colors.white;
  static const _green = Color(0xFF1E9E5A);
  static const _red = Color(0xFFE0483C);

  DateTimeRange _range = DateTimeRange(
    start: DateTime(DateTime.now().year, DateTime.now().month, 1),
    end: DateTime(DateTime.now().year, DateTime.now().month + 1, 0),
  );
  String _period = 'This month';
  String _typeFilter = 'All Transactions';
  String _partyFilter = 'All parties';

  List<TransactionEntry> get _filtered {
    return widget.transactions.where((t) {
      final inRange = !t.date.isBefore(_range.start) &&
          !t.date.isAfter(_range.end.add(const Duration(days: 1)));
      final typeOk = _typeFilter == 'All Transactions' ||
          kTxnTypeLabels[t.type] == _typeFilter;
      final partyOk = _partyFilter == 'All parties' || t.partyName == _partyFilter;
      return inRange && typeOk && partyOk;
    }).toList()
      ..sort((a, b) => b.date.compareTo(a.date));
  }

  double get _totalAmount => _filtered.fold(0, (s, t) => s + t.total);
  double get _totalBalance => _filtered.fold(0, (s, t) => s + t.balance);

  @override
  Widget build(BuildContext context) {
    final items = _filtered;

    return Scaffold(
      backgroundColor: _bg,
      appBar: _buildAppBar(),
      body: Column(
        children: [
          _buildFilterBar(),
          _buildSummaryStrip(),
          const SizedBox(height: 4),
          Expanded(
            child: items.isEmpty
                ? _buildEmptyState()
                : ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              itemCount: items.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, i) => _TransactionCard(
                entry: items[i],
                ink: _ink,
                muted: _muted,
                green: _green,
                red: _red,
                cardBg: _cardBg,
                line: _line,
              ),
            ),
          ),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.white,
      elevation: 0,
      scrolledUnderElevation: 0.5,
      centerTitle: false,
      titleSpacing: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: _ink),
        onPressed: () => Navigator.of(context).maybePop(),
      ),
      title: const Text(
        'All Transactions',
        style: TextStyle(
          fontFamily: 'PlusJakartaSans',
          fontWeight: FontWeight.w700,
          fontSize: 18,
          color: _ink,
          letterSpacing: -0.2,
        ),
      ),
      actions: [
        _ExportIconButton(
          icon: Icons.ios_share_rounded,
          label: 'CA',
          background: _ink,
          onTap: () => _showExportSheet('Share with CA'),
        ),
        const SizedBox(width: 8),
        _ExportIconButton(
          icon: Icons.description_rounded,
          label: 'PDF',
          background: _red,
          onTap: () => _showExportSheet('Export as PDF'),
        ),
        const SizedBox(width: 8),
        _ExportIconButton(
          icon: Icons.grid_on_rounded,
          label: 'XLS',
          background: _green,
          onTap: () => _showExportSheet('Export as Excel'),
        ),
        const SizedBox(width: 12),
      ],
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(height: 1, color: _line),
      ),
    );
  }

  Widget _buildFilterBar() {
    final fmt = DateFormat('dd/MM/yyyy');
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: _DropdownPill(
                  label: _period,
                  onTap: () async {
                    final choice = await _showPeriodPicker();
                    if (choice != null) setState(() => _period = choice);
                  },
                ),
              ),
              const SizedBox(width: 10),
              InkWell(
                borderRadius: BorderRadius.circular(10),
                onTap: _pickDateRange,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    border: Border.all(color: _line),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.calendar_today_rounded, size: 15, color: _ink),
                      const SizedBox(width: 8),
                      Text(
                        '${fmt.format(_range.start)}  →  ${fmt.format(_range.end)}',
                        style: const TextStyle(
                          fontFamily: 'PlusJakartaSans',
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                          color: _ink,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _DropdownPill(
                  label: _typeFilter,
                  onTap: () async {
                    final choice = await _showChoiceSheet(
                      'Transaction type',
                      kTxnTypeFilterOptions,
                      _typeFilter,
                      scrollable: true,
                    );
                    if (choice != null) setState(() => _typeFilter = choice);
                  },
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _DropdownPill(
                  label: _partyFilter,
                  leadingLabel: 'Party',
                  onTap: () async {
                    final parties = <String>{'All parties', ...widget.transactions.map((t) => t.partyName)}.toList();
                    final choice = await _showChoiceSheet('Party Name', parties, _partyFilter);
                    if (choice != null) setState(() => _partyFilter = choice);
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryStrip() {
    final fmtN = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 10, 16, 0),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: _ink,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Expanded(
            child: _SummaryStat(
              label: '${_filtered.length} transactions',
              value: fmtN.format(_totalAmount),
              valueColor: Colors.white,
              labelColor: Colors.white70,
            ),
          ),
          Container(width: 1, height: 32, color: Colors.white24),
          const SizedBox(width: 16),
          Expanded(
            child: _SummaryStat(
              label: 'Balance due',
              value: fmtN.format(_totalBalance),
              valueColor: _totalBalance > 0 ? const Color(0xFFFFB86B) : Colors.white,
              labelColor: Colors.white70,
              alignEnd: true,
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
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: _line,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.receipt_long_outlined, color: _muted, size: 32),
          ),
          const SizedBox(height: 14),
          const Text(
            'No transactions found',
            style: TextStyle(
              fontFamily: 'PlusJakartaSans',
              fontWeight: FontWeight.w700,
              fontSize: 15,
              color: _ink,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Try changing the date range or filters',
            style: TextStyle(
              fontFamily: 'PlusJakartaSans',
              fontSize: 13,
              color: _muted,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _pickDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      initialDateRange: _range,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(primary: _ink),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() {
        _range = picked;
        _period = 'Custom';
      });
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
      String current, {
        bool scrollable = false,
      }) {
    HapticFeedback.selectionClick();
    return showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.white,
      isScrollControlled: scrollable,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        final header = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: _line,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                title,
                style: const TextStyle(
                  fontFamily: 'PlusJakartaSans',
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                  color: _ink,
                ),
              ),
            ),
            const SizedBox(height: 4),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Divider(height: 16, color: _line),
            ),
          ],
        );

        Widget optionTile(String o) => ListTile(
          dense: true,
          title: Text(
            o,
            style: TextStyle(
              fontFamily: 'PlusJakartaSans',
              fontWeight: o == current ? FontWeight.w700 : FontWeight.w500,
              fontSize: 14.5,
              color: _ink,
            ),
          ),
          trailing: o == current ? const Icon(Icons.check_rounded, color: _ink, size: 20) : null,
          onTap: () => Navigator.pop(context, o),
        );

        if (!scrollable) {
          return SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  header,
                  ...options.map(optionTile),
                ],
              ),
            ),
          );
        }

        // Long lists (e.g. the full transaction-type list) get a fixed-height,
        // scrollable sheet instead of stretching off-screen.
        final maxHeight = MediaQuery.of(context).size.height * 0.75;
        return SafeArea(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxHeight: maxHeight),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  header,
                  Flexible(
                    child: ListView.builder(
                      shrinkWrap: true,
                      padding: EdgeInsets.zero,
                      itemCount: options.length,
                      itemBuilder: (context, i) => optionTile(options[i]),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _showExportSheet(String action) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(action, style: const TextStyle(fontFamily: 'PlusJakartaSans')),
        backgroundColor: _ink,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }
}

class _SummaryStat extends StatelessWidget {
  final String label;
  final String value;
  final Color valueColor;
  final Color labelColor;
  final bool alignEnd;

  const _SummaryStat({
    required this.label,
    required this.value,
    required this.valueColor,
    required this.labelColor,
    this.alignEnd = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: alignEnd ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontFamily: 'PlusJakartaSans',
            fontSize: 11.5,
            fontWeight: FontWeight.w500,
            color: labelColor,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          value,
          style: TextStyle(
            fontFamily: 'PlusJakartaSans',
            fontSize: 17,
            fontWeight: FontWeight.w800,
            color: valueColor,
            letterSpacing: -0.3,
          ),
        ),
      ],
    );
  }
}

class _ExportIconButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color background;
  final VoidCallback onTap;

  const _ExportIconButton({
    required this.icon,
    required this.label,
    required this.background,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(9),
      onTap: onTap,
      child: Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(9),
        ),
        child: Icon(icon, size: 16, color: Colors.white),
      ),
    );
  }
}

class _DropdownPill extends StatelessWidget {
  final String label;
  final String? leadingLabel;
  final VoidCallback onTap;

  const _DropdownPill({required this.label, required this.onTap, this.leadingLabel});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          border: Border.all(color: const Color(0xFFEBEBEF)),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (leadingLabel != null) ...[
              Text(
                '$leadingLabel  ',
                style: const TextStyle(
                  fontFamily: 'PlusJakartaSans',
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF3B67F5),
                ),
              ),
            ],
            Flexible(
              child: Text(
                label,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontFamily: 'PlusJakartaSans',
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF12131A),
                ),
              ),
            ),
            const SizedBox(width: 4),
            const Icon(Icons.keyboard_arrow_down_rounded, size: 17, color: Color(0xFF8A8D98)),
          ],
        ),
      ),
    );
  }
}

class _TransactionCard extends StatelessWidget {
  final TransactionEntry entry;
  final Color ink;
  final Color muted;
  final Color green;
  final Color red;
  final Color cardBg;
  final Color line;

  const _TransactionCard({
    required this.entry,
    required this.ink,
    required this.muted,
    required this.green,
    required this.red,
    required this.cardBg,
    required this.line,
  });

  String get _typeLabel => kTxnTypeLabels[entry.type] ?? 'Transaction';

  Color get _typeColor {
    switch (entry.type) {
      case TxnType.sale:
      case TxnType.saleOrder:
      case TxnType.saleFA:
      case TxnType.saleRepeating:
      case TxnType.partyToPartyReceived:
        return green;
      case TxnType.purchase:
      case TxnType.purchaseOrder:
      case TxnType.purchaseFA:
      case TxnType.purchaseJobWork:
      case TxnType.expense:
      case TxnType.saleCancelled:
        return red;
      case TxnType.paymentIn:
      case TxnType.partyToPartyPaid:
        return const Color(0xFF3B67F5);
      case TxnType.paymentOut:
      case TxnType.debitNote:
        return const Color(0xFFE08A00);
      case TxnType.creditNote:
      case TxnType.estimate:
      case TxnType.deliveryChallan:
      case TxnType.journalEntry:
        return const Color(0xFF8756D6);
    }
  }

  @override
  Widget build(BuildContext context) {
    final fmtN = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 2);
    final fmtD = DateFormat('dd MMM yyyy');
    final initials = entry.partyName.trim().isNotEmpty
        ? entry.partyName.trim()[0].toUpperCase()
        : '?';

    return Material(
      color: cardBg,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () {},
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: line),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: _typeColor.withOpacity(0.10),
                  borderRadius: BorderRadius.circular(11),
                ),
                alignment: Alignment.center,
                child: Text(
                  initials,
                  style: TextStyle(
                    fontFamily: 'PlusJakartaSans',
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                    color: _typeColor,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            entry.partyName,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontFamily: 'PlusJakartaSans',
                              fontWeight: FontWeight.w700,
                              fontSize: 15,
                              color: Color(0xFF12131A),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Text(
                          fmtD.format(entry.date),
                          style: TextStyle(
                            fontFamily: 'PlusJakartaSans',
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: muted,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                          decoration: BoxDecoration(
                            color: _typeColor.withOpacity(0.10),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            '$_typeLabel #${entry.txnNumber}',
                            style: TextStyle(
                              fontFamily: 'PlusJakartaSans',
                              fontSize: 10.5,
                              fontWeight: FontWeight.w700,
                              color: _typeColor,
                            ),
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
                    fmtN.format(entry.total),
                    style: const TextStyle(
                      fontFamily: 'PlusJakartaSans',
                      fontWeight: FontWeight.w800,
                      fontSize: 15,
                      color: Color(0xFF12131A),
                      letterSpacing: -0.2,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                    decoration: BoxDecoration(
                      color: entry.isFullyPaid ? green.withOpacity(0.10) : red.withOpacity(0.10),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      entry.isFullyPaid ? 'Paid' : 'Due ${fmtN.format(entry.balance)}',
                      style: TextStyle(
                        fontFamily: 'PlusJakartaSans',
                        fontSize: 10.5,
                        fontWeight: FontWeight.w700,
                        color: entry.isFullyPaid ? green : red,
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
  }
}

/// ---------------------------------------------------------------------------
/// Sample data matching the screenshot, for quick preview / testing.
/// ---------------------------------------------------------------------------
final sampleTransactions = <TransactionEntry>[
  TransactionEntry(
    partyName: 'Gopal',
    date: DateTime(2026, 9, 5),
    type: TxnType.sale,
    txnNumber: 1,
    total: 1000,
    balance: 500,
  ),
  TransactionEntry(
    partyName: 'gill',
    date: DateTime(2026, 9, 5),
    type: TxnType.sale,
    txnNumber: 2,
    total: 100,
    balance: 100,
  ),
];