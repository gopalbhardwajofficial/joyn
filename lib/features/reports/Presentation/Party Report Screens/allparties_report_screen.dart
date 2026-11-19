import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:joyn/core/theme/joyn_typography.dart';
import 'package:joyn/core/theme/joyn_colors.dart';
import 'package:joyn/core/widgets/Premium_widget.dart';
import 'package:joyn/core/services/api_service.dart';
import 'package:joyn/core/services/report_export_service.dart';

class PartyReportRow {
  final String name;
  final double? creditLimit;
  final double balance; // positive = receivable, negative = payable

  PartyReportRow({required this.name, this.creditLimit, required this.balance});
}

class AllPartyReportScreen extends StatefulWidget {
  const AllPartyReportScreen({super.key});

  @override
  State<AllPartyReportScreen> createState() => _AllPartyReportScreenState();
}

class _AllPartyReportScreenState extends State<AllPartyReportScreen> {
  bool dateFilterEnabled = false;
  DateTime selectedDate = DateTime.now();
  bool _isLoading = false;

  String showFilter = 'All parties';
  String sortBy = 'Name';
  bool showZeroBalanceParty = true;

  List<PartyReportRow> allParties = [];

  @override
  void initState() {
    super.initState();
    _fetchAllPartiesReport();
  }

  Future<void> _fetchAllPartiesReport() async {
    setState(() => _isLoading = true);
    final asOfStr = dateFilterEnabled ? DateFormat('yyyy-MM-dd').format(selectedDate) : null;

    try {
      final res = await ApiService.fetchAllPartiesReport(asOfDate: asOfStr);
      if (res['success'] == true) {
        final rawList = res['parties'] as List? ?? [];
        final mapped = <PartyReportRow>[];
        for (final p in rawList) {
          mapped.add(PartyReportRow(
            name: p['name']?.toString() ?? 'Party #${p['id']}',
            creditLimit: (p['creditLimit'] as num?)?.toDouble(),
            balance: (p['balance'] as num?)?.toDouble() ?? 0.0,
          ));
        }
        if (mounted) {
          setState(() {
            allParties = mapped;
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

  List<PartyReportRow> get filteredParties {
    var list = allParties.where((p) {
      if (!showZeroBalanceParty && p.balance == 0) return false;
      if (showFilter == 'Receivables') return p.balance > 0;
      if (showFilter == 'Payables') return p.balance < 0;
      return true;
    }).toList();

    list.sort((a, b) => sortBy == 'Amount'
        ? b.balance.abs().compareTo(a.balance.abs())
        : a.name.toLowerCase().compareTo(b.name.toLowerCase()));

    return list;
  }

  Future<void> _exportRealPdf() async {
    final list = filteredParties;
    final currency = NumberFormat('#,##0.00', 'en_IN');
    final asOfStr = dateFilterEnabled ? DateFormat('dd/MM/yyyy').format(selectedDate) : 'All Time';

    final tableHeaders = ['Party Name', 'Credit Limit', 'Balance', 'Type'];
    final tableRows = list.map((p) {
      final isReceivable = p.balance >= 0;
      final typeStr = p.balance == 0 ? 'Settled' : (isReceivable ? 'Receivable (To Collect)' : 'Payable (To Pay)');
      return [
        p.name,
        p.creditLimit != null ? '₹ ${currency.format(p.creditLimit)}' : '-',
        '₹ ${currency.format(p.balance.abs())}',
        typeStr,
      ];
    }).toList();

    final totalReceivables = list.where((p) => p.balance > 0).fold(0.0, (s, p) => s + p.balance);
    final totalPayables = list.where((p) => p.balance < 0).fold(0.0, (s, p) => s + p.balance.abs());

    final summary = {
      'Total Parties': '${list.length}',
      'Total Receivables': '₹ ${currency.format(totalReceivables)}',
      'Total Payables': '₹ ${currency.format(totalPayables)}',
    };

    await ReportExportService.showPdfOptionsSheet(
      context: context,
      title: 'All Parties Report',
      periodLabel: 'As of: $asOfStr',
      summaryStats: summary,
      tableHeaders: tableHeaders,
      tableRows: tableRows,
    );
  }

  Future<void> _exportRealExcel() async {
    final list = filteredParties;
    final asOfStr = dateFilterEnabled ? DateFormat('dd/MM/yyyy').format(selectedDate) : 'All Time';

    final tableHeaders = ['Party Name', 'Credit Limit (INR)', 'Balance (INR)', 'Type'];
    final tableRows = list.map((p) {
      final isReceivable = p.balance >= 0;
      final typeStr = p.balance == 0 ? 'Settled' : (isReceivable ? 'Receivable' : 'Payable');
      return [
        p.name,
        p.creditLimit?.toStringAsFixed(2) ?? '',
        p.balance.toStringAsFixed(2),
        typeStr,
      ];
    }).toList();

    final totalReceivables = list.where((p) => p.balance > 0).fold(0.0, (s, p) => s + p.balance);
    final totalPayables = list.where((p) => p.balance < 0).fold(0.0, (s, p) => s + p.balance.abs());

    final summary = {
      'Total Parties': '${list.length}',
      'Total Receivables': totalReceivables.toStringAsFixed(2),
      'Total Payables': totalPayables.toStringAsFixed(2),
    };

    await ReportExportService.showExcelOptionsSheet(
      context: context,
      title: 'All Parties Report',
      periodLabel: 'As of: $asOfStr',
      summaryStats: summary,
      tableHeaders: tableHeaders,
      tableRows: tableRows,
    );
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() => selectedDate = picked);
      if (dateFilterEnabled) {
        _fetchAllPartiesReport();
      }
    }
  }

  Future<void> _pickOption({
    required String title,
    required List<String> options,
    required String current,
    required ValueChanged<String> onSelected,
  }) async {
    final result = await showModalBottomSheet<String>(
      context: context,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.only(top: 12, bottom: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(color: JoynColors.border, borderRadius: BorderRadius.circular(4)),
              ),
              const SizedBox(height: 14),
              Text(title, style: JoynTypography.bodyLarge.copyWith(fontWeight: FontWeight.w700)),
              ...options.map(
                    (o) => ListTile(
                  title: Text(o, style: JoynTypography.bodyMedium),
                  trailing: o == current
                      ? const Icon(Icons.check_rounded, color: JoynColors.primary, size: 20)
                      : null,
                  onTap: () => Navigator.pop(context, o),
                ),
              ),
            ],
          ),
        ),
      ),
    );
    if (result != null) onSelected(result);
  }

  @override
  Widget build(BuildContext context) {
    final dateFmt = DateFormat('dd MMM, yyyy');
    final currency = NumberFormat('#,##0.00', 'en_IN');

    return Scaffold(
      backgroundColor: JoynColors.background,
      appBar: AppBar(
        titleSpacing: 20,
        title: Text('Party Report', style: JoynTypography.screenTitle),
        actions: [
          ExportActions(onPdf: _exportRealPdf, onXls: _exportRealExcel),
          const SizedBox(width: 16),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 10),
            child: PremiumCard(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              child: Row(
                children: [
                  Checkbox(
                    value: dateFilterEnabled,
                    activeColor: JoynColors.primary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                    onChanged: (v) {
                      setState(() => dateFilterEnabled = v ?? false);
                      _fetchAllPartiesReport();
                    },
                  ),
                  Text('Date Filter', style: JoynTypography.bodyMedium.copyWith(fontWeight: FontWeight.w600)),
                  const Spacer(),
                  InkWell(
                    onTap: dateFilterEnabled ? _pickDate : null,
                    borderRadius: BorderRadius.circular(10),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Row(
                        children: [
                          Icon(Icons.calendar_today_rounded,
                              size: 15,
                              color: dateFilterEnabled ? JoynColors.primary : JoynColors.secondaryText),
                          const SizedBox(width: 8),
                          Text(
                            dateFmt.format(selectedDate),
                            style: JoynTypography.bodyMedium.copyWith(
                              fontWeight: FontWeight.w600,
                              color: dateFilterEnabled ? JoynColors.primary : JoynColors.secondaryText,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 10),
            child: Row(
              children: [
                Expanded(
                  child: _DropdownField(
                    label: 'Show',
                    value: showFilter,
                    onTap: () => _pickOption(
                      title: 'Show',
                      options: const ['All parties', 'Receivables', 'Payables'],
                      current: showFilter,
                      onSelected: (v) => setState(() => showFilter = v),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _DropdownField(
                    label: 'Sort by',
                    value: sortBy,
                    onTap: () => _pickOption(
                      title: 'Sort by',
                      options: const ['Name', 'Amount'],
                      current: sortBy,
                      onSelected: (v) => setState(() => sortBy = v),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
            child: Row(
              children: [
                Checkbox(
                  value: showZeroBalanceParty,
                  activeColor: JoynColors.primary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                  onChanged: (v) => setState(() => showZeroBalanceParty = v ?? true),
                ),
                Text('Show 0 balance party', style: JoynTypography.bodyMedium.copyWith(fontWeight: FontWeight.w600)),
              ],
            ),
          ),
          ColumnHeaderRow(children: [
            Expanded(flex: 3, child: Text('Party Name', style: JoynTypography.caption)),
            Expanded(flex: 2, child: Text('Credit Limit', textAlign: TextAlign.center, style: JoynTypography.caption)),
            Expanded(flex: 2, child: Text('Balance', textAlign: TextAlign.right, style: JoynTypography.caption)),
          ]),
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: JoynColors.primary),
                  )
                : filteredParties.isEmpty
                    ? const PremiumEmptyState(
                        icon: Icons.groups_rounded,
                        title: 'No parties found',
                        subtitle: 'Try a different Show or balance filter.',
                      )
                    : ListView.separated(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              itemCount: filteredParties.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final p = filteredParties[index];
                final isReceivable = p.balance >= 0;
                return PremiumCard(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  child: Row(
                    children: [
                      Container(
                        width: 38,
                        height: 38,
                        alignment: Alignment.center,
                        decoration: const BoxDecoration(color: JoynColors.chipBackground, shape: BoxShape.circle),
                        child: Text(
                          p.name.substring(0, 1).toUpperCase(),
                          style: JoynTypography.bodyMedium.copyWith(fontWeight: FontWeight.w700),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 3,
                        child: Text(p.name, style: JoynTypography.bodyLarge.copyWith(fontWeight: FontWeight.w700)),
                      ),
                      Expanded(
                        flex: 2,
                        child: Text(
                          p.creditLimit != null ? '\u20B9 ${currency.format(p.creditLimit)}' : '\u2014',
                          textAlign: TextAlign.center,
                          style: JoynTypography.bodyMedium.copyWith(color: JoynColors.secondaryText),
                        ),
                      ),
                      Expanded(
                        flex: 2,
                        child: Text(
                          '\u20B9 ${currency.format(p.balance.abs())}',
                          textAlign: TextAlign.right,
                          style: JoynTypography.bodyMedium.copyWith(
                            fontWeight: FontWeight.w700,
                            color: isReceivable ? JoynColors.success : JoynColors.error,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _DropdownField extends StatelessWidget {
  final String label;
  final String value;
  final VoidCallback onTap;

  const _DropdownField({required this.label, required this.value, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: JoynColors.cardSurface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: JoynColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: JoynTypography.statLabel),
            const SizedBox(height: 4),
            Row(
              children: [
                Expanded(
                  child: Text(value,
                      overflow: TextOverflow.ellipsis,
                      style: JoynTypography.bodyMedium.copyWith(fontWeight: FontWeight.w700)),
                ),
                Icon(Icons.keyboard_arrow_down_rounded, size: 18, color: JoynColors.secondaryText),
              ],
            ),
          ],
        ),
      ),
    );
  }
}