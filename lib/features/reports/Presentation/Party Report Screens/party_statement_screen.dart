import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:joyn/core/theme/joyn_typography.dart';
import 'package:joyn/core/theme/joyn_colors.dart';
import 'package:joyn/core/services/api_service.dart';
import 'package:joyn/core/services/report_export_service.dart';
import 'package:joyn/features/orders/data/sales_repository.dart';

class LedgerEntry {
  final DateTime date;
  final String type;
  final double debit;
  final double credit;

  LedgerEntry({
    required this.date,
    required this.type,
    this.debit = 0,
    this.credit = 0,
  });
}

class PartyStatementScreen extends StatefulWidget {
  const PartyStatementScreen({super.key});

  @override
  State<PartyStatementScreen> createState() => _PartyStatementScreenState();
}

class _PartyStatementScreenState extends State<PartyStatementScreen> {
  String selectedPeriod = 'This Month';
  DateTime fromDate = DateTime.now();
  DateTime toDate = DateTime.now();

  String selectedTheme = 'Joyn View';
  String? selectedParty;
  String? selectedPartyId;
  bool _isLoading = false;

  List<Map<String, dynamic>> parties = [];
  List<LedgerEntry> currentLedger = [];

  double totalSale = 0.0;
  double totalPayment = 0.0;
  double closingBalance = 0.0;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    fromDate = DateTime(now.year, now.month, 1);
    toDate = DateTime(now.year, now.month + 1, 0);
    _loadParties();
  }

  Future<void> _loadParties() async {
    setState(() => _isLoading = true);
    try {
      // 1. Instant local load
      final localParties = await SalesRepository().getParties();
      if (localParties.isNotEmpty && mounted) {
        setState(() {
          parties = localParties.map((p) => {
            'id': p.id,
            'name': p.name,
            'contactNumber': p.contactNumber,
            'partyType': p.partyType,
          }).toList();
          selectedParty = parties[0]['name']?.toString();
          selectedPartyId = parties[0]['id']?.toString();
        });
      }

      // 2. Fetch from backend API
      final res = await ApiService.fetchParties();
      if (res['success'] == true) {
        final rawList = (res['data'] ?? res['parties']) as List? ?? [];
        final mappedParties = rawList.map((e) => Map<String, dynamic>.from(e as Map)).toList();
        if (mounted && mappedParties.isNotEmpty) {
          setState(() {
            parties = mappedParties;
            if (selectedPartyId == null || !parties.any((p) => p['id']?.toString() == selectedPartyId)) {
              selectedParty = parties[0]['name']?.toString();
              selectedPartyId = parties[0]['id']?.toString();
            }
          });
        }
      }

      if (selectedPartyId != null && selectedPartyId!.isNotEmpty) {
        await _fetchPartyStatement();
      } else {
        if (mounted) setState(() => _isLoading = false);
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _fetchPartyStatement() async {
    if (selectedPartyId == null) return;
    setState(() => _isLoading = true);
    final startStr = DateFormat('yyyy-MM-dd').format(fromDate);
    final endStr = DateFormat('yyyy-MM-dd').format(toDate);

    try {
      final res = await ApiService.fetchPartyStatement(
        partyId: selectedPartyId!,
        startDate: startStr,
        endDate: endStr,
      );
      if (res['success'] == true) {
        final summary = res['summary'] as Map<String, dynamic>? ?? {};
        final rawLedger = res['ledger'] as List? ?? [];

        final entries = <LedgerEntry>[];
        for (final r in rawLedger) {
          entries.add(LedgerEntry(
            date: DateTime.tryParse(r['date']?.toString() ?? '') ?? DateTime.now(),
            type: r['type']?.toString() ?? '',
            debit: (r['debit'] as num?)?.toDouble() ?? 0.0,
            credit: (r['credit'] as num?)?.toDouble() ?? 0.0,
          ));
        }

        final tDebit = (summary['totalDebit'] as num?)?.toDouble() ?? 0.0;
        final tCredit = (summary['totalCredit'] as num?)?.toDouble() ?? 0.0;
        final netBal = (summary['netBalance'] as num?)?.toDouble() ?? 0.0;

        if (mounted) {
          setState(() {
            currentLedger = entries;
            totalSale = tDebit;
            totalPayment = tCredit;
            closingBalance = netBal;
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
      _fetchPartyStatement();
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
          toDate = DateTime(now.year, now.month, now.day);
        } else if (result == 'This Week') {
          final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
          fromDate = DateTime(startOfWeek.year, startOfWeek.month, startOfWeek.day);
          toDate = DateTime(now.year, now.month, now.day);
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
        _fetchPartyStatement();
      }
    }
  }

  Future<void> _pickParty() async {
    HapticFeedback.selectionClick();
    final result = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      backgroundColor: JoynColors.background,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.only(top: 12, bottom: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: JoynColors.border,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(height: 14),
              Text(
                'Select Party',
                style: JoynTypography.titleMedium.copyWith(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              if (parties.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(24),
                  child: Text('No parties found', style: TextStyle(color: JoynColors.secondaryText)),
                )
              else
                Flexible(
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: parties.length,
                    itemBuilder: (context, idx) {
                      final p = parties[idx];
                      final name = p['name']?.toString() ?? 'Party #${p['id']}';
                      final isSelected = p['id']?.toString() == selectedPartyId;
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: JoynColors.surfaceMuted,
                          child: Text(
                            name.isNotEmpty ? name[0].toUpperCase() : '?',
                            style: const TextStyle(fontWeight: FontWeight.bold, color: JoynColors.primary),
                          ),
                        ),
                        title: Text(
                          name,
                          style: JoynTypography.bodyLarge.copyWith(
                            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                          ),
                        ),
                        subtitle: Text(
                          p['contact_number']?.toString() ?? p['party_type']?.toString() ?? '',
                          style: JoynTypography.caption.copyWith(color: JoynColors.secondaryText),
                        ),
                        trailing: isSelected
                            ? const Icon(Icons.check_rounded, color: JoynColors.primary, size: 20)
                            : null,
                        onTap: () => Navigator.pop(context, p),
                      );
                    },
                  ),
                ),
            ],
          ),
        ),
      ),
    );
    if (result != null) {
      setState(() {
        selectedParty = result['name']?.toString();
        selectedPartyId = result['id']?.toString();
      });
      _fetchPartyStatement();
    }
  }

  void _openFiltersSheet() async {
    HapticFeedback.selectionClick();
    String tempTheme = selectedTheme;

    final result = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: JoynColors.background,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
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
                          'Filters',
                          style: JoynTypography.titleMedium.copyWith(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        IconButton(
                          icon: Icon(Icons.close_rounded, color: JoynColors.secondaryText),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'By Theme',
                      style: JoynTypography.bodyMedium.copyWith(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 10),
                    _themeOption('Joyn View', tempTheme, (v) => setModalState(() => tempTheme = v)),
                    const SizedBox(height: 10),
                    _themeOption('Accounting View', tempTheme, (v) => setModalState(() => tempTheme = v)),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                              side: BorderSide(color: JoynColors.border),
                              backgroundColor: JoynColors.surface,
                            ),
                            onPressed: () => setModalState(() => tempTheme = 'Joyn View'),
                            child: Text(
                              'Reset',
                              style: JoynTypography.bodyMedium.copyWith(fontWeight: FontWeight.w600),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: JoynColors.primary,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                              elevation: 0,
                            ),
                            onPressed: () => Navigator.pop(context, tempTheme),
                            child: Text('Apply', style: JoynTypography.buttonText.copyWith(fontSize: 14)),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );

    if (result != null) setState(() => selectedTheme = result);
  }

  Widget _themeOption(String label, String current, ValueChanged<String> onChanged) {
    final selected = label == current;
    return InkWell(
      onTap: () => onChanged(label),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        decoration: BoxDecoration(
          color: selected ? JoynColors.chipBackground : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: JoynColors.border),
        ),
        child: Row(
          children: [
            Icon(
              selected ? Icons.radio_button_checked_rounded : Icons.radio_button_off_rounded,
              size: 20,
              color: selected ? JoynColors.primary : JoynColors.secondaryText,
            ),
            const SizedBox(width: 12),
            Text(
              label,
              style: JoynTypography.bodyMedium.copyWith(fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final dateFmt = DateFormat('dd MMM');
    final entryDateFmt = DateFormat('dd MMM, yy');
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
          'Party Statement',
          style: JoynTypography.titleMedium.copyWith(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: JoynColors.primary,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.ios_share_rounded, color: JoynColors.primary),
            tooltip: 'Share',
            onPressed: _exportRealPdf,
          ),
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
          _buildFilterSection(),
          const SizedBox(height: 12),
          _buildPartySelector(),
          Expanded(
            child: _isLoading
                ? const Center(
              child: CircularProgressIndicator(color: JoynColors.primary),
            )
                : selectedParty == null
                ? _buildEmptyState()
                : _buildLedgerList(entryDateFmt, currency),
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

  // Enhanced Filter Section
  Widget _buildFilterSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                _buildFilterChip(
                  icon: Icons.palette_outlined,
                  label: 'Theme · $selectedTheme',
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Material(
            color: JoynColors.primary,
            borderRadius: BorderRadius.circular(24),
            child: InkWell(
              onTap: _openFiltersSheet,
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

  // Enhanced Party Selector
  Widget _buildPartySelector() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Material(
        color: JoynColors.iconBackground,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: _pickParty,
          borderRadius: BorderRadius.circular(14),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              border: Border.all(color: JoynColors.border),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        JoynColors.primary.withValues(alpha: 0.1),
                        JoynColors.primary.withValues(alpha: 0.05),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.person_outline_rounded,
                    size: 18,
                    color: JoynColors.primary,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Select Party',
                        style: JoynTypography.caption.copyWith(
                          fontSize: 10,
                          color: JoynColors.secondaryText,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        selectedParty ?? 'Choose a party',
                        style: JoynTypography.bodyLarge.copyWith(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: selectedParty != null ? JoynColors.primary : JoynColors.secondaryText,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.keyboard_arrow_down_rounded,
                  size: 20,
                  color: JoynColors.secondaryText,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Enhanced Ledger List
  Widget _buildLedgerList(DateFormat entryDateFmt, NumberFormat currency) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
      children: [
        _buildPartySummaryCard(currency),
        const SizedBox(height: 16),
        _buildTableHeader(),
        const SizedBox(height: 8),
        for (int i = 0; i < currentLedger.length; i++) ...[
          _LedgerRow(entry: currentLedger[i], currency: currency, dateFmt: entryDateFmt, index: i),
          if (i != currentLedger.length - 1) const SizedBox(height: 8),
        ],
      ],
    );
  }

  // Enhanced Party Summary Card
  Widget _buildPartySummaryCard(NumberFormat currency) {
    final initials = selectedParty != null && selectedParty!.isNotEmpty
        ? selectedParty![0].toUpperCase()
        : '?';
    final isPositiveBalance = closingBalance >= 0;

    return Container(
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Text(
                  initials,
                  style: JoynTypography.bodyLarge.copyWith(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  selectedParty!,
                  style: JoynTypography.bodyLarge.copyWith(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(height: 1, color: Colors.white24),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _buildSummaryItem(
                  icon: Icons.point_of_sale_rounded,
                  label: 'Total Sale',
                  value: '₹ ${currency.format(totalSale)}',
                ),
              ),
              Container(width: 1, height: 40, color: Colors.white24),
              Expanded(
                child: _buildSummaryItem(
                  icon: Icons.account_balance_wallet_rounded,
                  label: 'Closing Balance',
                  value: '₹ ${currency.format(closingBalance.abs())}',
                  valueColor: isPositiveBalance ? const Color(0xFF4ADE80) : const Color(0xFFF87171),
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

  // Enhanced Table Header
  Widget _buildTableHeader() {
    return Container(
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
              'Date & Type',
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
              'Debit',
              textAlign: TextAlign.right,
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
              'Credit',
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
                Icons.person_search_rounded,
                size: 48,
                color: JoynColors.secondaryText.withValues(alpha: 0.5),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Select a party',
              style: JoynTypography.titleMedium.copyWith(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: JoynColors.primary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'To see the statement in full detail, please select a party.',
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
    final partyName = selectedParty ?? 'All Parties';
    final dateFmt = DateFormat('dd/MM/yyyy');
    final periodStr = '${dateFmt.format(fromDate)} - ${dateFmt.format(toDate)}';
    final currency = NumberFormat('#,##,##0.00', 'en_IN');

    final tableHeaders = ['Date', 'Txn Type', 'Debit (+)', 'Credit (-)', 'Running Balance'];
    double runningBal = 0.0;
    final tableRows = currentLedger.map((entry) {
      runningBal += (entry.debit - entry.credit);
      return [
        dateFmt.format(entry.date),
        entry.type,
        entry.debit > 0 ? '₹${currency.format(entry.debit)}' : '-',
        entry.credit > 0 ? '₹${currency.format(entry.credit)}' : '-',
        '₹${currency.format(runningBal)}',
      ];
    }).toList();

    final summary = {
      'Party Name': partyName,
      'Total Sales / Debit': '₹${currency.format(totalSale)}',
      'Total Payment / Credit': '₹${currency.format(totalPayment)}',
      'Closing Balance': '₹${currency.format(closingBalance)}',
    };

    await ReportExportService.showPdfOptionsSheet(
      context: context,
      title: 'Party Statement - $partyName',
      periodLabel: periodStr,
      summaryStats: summary,
      tableHeaders: tableHeaders,
      tableRows: tableRows,
    );
  }

  Future<void> _exportRealExcel() async {
    final partyName = selectedParty ?? 'All Parties';
    final dateFmt = DateFormat('dd/MM/yyyy');
    final periodStr = '${dateFmt.format(fromDate)} - ${dateFmt.format(toDate)}';

    final tableHeaders = ['Date', 'Txn Type', 'Debit (INR)', 'Credit (INR)', 'Balance (INR)'];
    double runningBal = 0.0;
    final tableRows = currentLedger.map((entry) {
      runningBal += (entry.debit - entry.credit);
      return [
        dateFmt.format(entry.date),
        entry.type,
        entry.debit > 0 ? entry.debit.toStringAsFixed(2) : '0.00',
        entry.credit > 0 ? entry.credit.toStringAsFixed(2) : '0.00',
        runningBal.toStringAsFixed(2),
      ];
    }).toList();

    final summary = {
      'Party Name': partyName,
      'Total Sales / Debit': totalSale.toStringAsFixed(2),
      'Total Payment / Credit': totalPayment.toStringAsFixed(2),
      'Closing Balance': closingBalance.toStringAsFixed(2),
    };

    await ReportExportService.showExcelOptionsSheet(
      context: context,
      title: 'Party Statement - $partyName',
      periodLabel: periodStr,
      summaryStats: summary,
      tableHeaders: tableHeaders,
      tableRows: tableRows,
    );
  }
}

class _LedgerRow extends StatelessWidget {
  final LedgerEntry entry;
  final NumberFormat currency;
  final DateFormat dateFmt;
  final int index;

  const _LedgerRow({
    required this.entry,
    required this.currency,
    required this.dateFmt,
    required this.index,
  });

  @override
  Widget build(BuildContext context) {
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
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Expanded(
                flex: 3,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      entry.type,
                      style: JoynTypography.bodyMedium.copyWith(
                        fontWeight: FontWeight.w700,
                        color: JoynColors.primary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      dateFmt.format(entry.date),
                      style: JoynTypography.caption.copyWith(
                        fontSize: 10,
                        color: JoynColors.secondaryText,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                flex: 2,
                child: Text(
                  entry.debit > 0 ? '₹ ${currency.format(entry.debit)}' : '—',
                  textAlign: TextAlign.right,
                  style: JoynTypography.bodyMedium.copyWith(
                    fontWeight: FontWeight.w600,
                    color: entry.debit > 0 ? JoynColors.error : JoynColors.secondaryText,
                  ),
                ),
              ),
              Expanded(
                flex: 2,
                child: Text(
                  entry.credit > 0 ? '₹ ${currency.format(entry.credit)}' : '—',
                  textAlign: TextAlign.right,
                  style: JoynTypography.bodyMedium.copyWith(
                    fontWeight: FontWeight.w600,
                    color: entry.credit > 0 ? JoynColors.success : JoynColors.secondaryText,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}