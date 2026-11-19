import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../../../../core/services/api_service.dart';
import '../../../../core/services/report_export_service.dart';
import '../../../../core/theme/joyn_colors.dart';
import '../../../../core/theme/joyn_typography.dart';
import '../../../business_profile/data/business_profile_repository.dart';
import '../../../orders/data/sales_repository.dart';
import '../../../orders/models/sales_models.dart';
import '../../models/gst_report_models.dart';

class HsnSummaryScreen extends StatefulWidget {
  const HsnSummaryScreen({super.key});

  @override
  State<HsnSummaryScreen> createState() => _HsnSummaryScreenState();
}

class _HsnSummaryScreenState extends State<HsnSummaryScreen> {
  bool _isLoading = true;
  List<HsnSummaryItem> _hsnList = [];

  DateTime _startDate = DateTime(DateTime.now().year, DateTime.now().month, 1);
  DateTime _endDate = DateTime(DateTime.now().year, DateTime.now().month + 1, 0);

  @override
  void initState() {
    super.initState();
    _loadReport();
  }

  Future<void> _loadReport() async {
    setState(() => _isLoading = true);
    final sStr = DateFormat('yyyy-MM-dd').format(_startDate);
    final eStr = DateFormat('yyyy-MM-dd').format(_endDate);

    try {
      final res = await ApiService.getHsnSummaryReport(startDate: sStr, endDate: eStr);
      if (res['success'] == true && ((res['hsnSummary'] as List?)?.isNotEmpty ?? false)) {
        final list = (res['hsnSummary'] as List<dynamic>)
            .map((h) => HsnSummaryItem.fromJson(h as Map<String, dynamic>))
            .toList();
        if (mounted) {
          setState(() {
            _hsnList = list;
            _isLoading = false;
          });
        }
      } else {
        await _loadLocalReport();
      }
    } catch (_) {
      await _loadLocalReport();
    }
  }

  Future<void> _loadLocalReport() async {
    try {
      final repo = SalesRepository();
      final allSales = await repo.getSaleOrders();
      final allItems = await repo.getItems();
      final biz = await BusinessProfileRepository().getBusinessProfile();
      final bizState = (biz?.state ?? '').trim().toLowerCase();

      final dbItemsMap = <String, InventoryItemModel>{};
      for (final itm in allItems) {
        dbItemsMap[itm.name.toLowerCase().trim()] = itm;
      }

      final sStr = DateFormat('yyyy-MM-dd').format(_startDate);
      final eStr = DateFormat('yyyy-MM-dd').format(_endDate);

      final dateSales = allSales.where((s) {
        final d = s.date.trim();
        return (d.compareTo(sStr) >= 0 && d.compareTo(eStr) <= 0) || d.startsWith(sStr);
      }).toList();

      final hsnMap = <String, HsnSummaryItem>{};

      for (final sale in dateSales) {
        final isInterState = sale.stateOfSupply.isNotEmpty && bizState.isNotEmpty
            ? sale.stateOfSupply.trim().toLowerCase() != bizState
            : false;

        for (final itm in sale.items) {
          final itemName = (itm['name'] ?? itm['itemName'] ?? itm['description'] ?? 'Sample Item').toString().trim();
          String rawHsn = (itm['hsnSac'] ?? itm['hsn_sac'] ?? itm['hsnCode'] ?? '').toString().trim();

          // Auto-resolve HSN from local inventory if missing
          if (rawHsn.isEmpty || rawHsn.toUpperCase() == 'NA' || rawHsn.toUpperCase() == 'N/A') {
            final inv = dbItemsMap[itemName.toLowerCase()];
            if (inv != null && inv.hsnSac.isNotEmpty) {
              rawHsn = inv.hsnSac;
            }
          }

          final hsn = (rawHsn.toUpperCase() == 'N/A' || rawHsn.toUpperCase() == 'NA' || rawHsn.isEmpty)
              ? 'NA'
              : rawHsn;
          final key = '${hsn}_${itemName.toLowerCase()}';

          final qty = (itm['quantity'] as num?)?.toDouble() ?? (itm['qty'] as num?)?.toDouble() ?? 1.0;
          final rate = (itm['rate'] as num?)?.toDouble() ?? (itm['sellingPrice'] as num?)?.toDouble() ?? (itm['unitPrice'] as num?)?.toDouble() ?? (itm['price'] as num?)?.toDouble() ?? 0.0;
          final taxRate = (itm['taxRatePercent'] as num?)?.toDouble() ?? (itm['tax_rate_percent'] as num?)?.toDouble() ?? (itm['taxRate'] as num?)?.toDouble() ?? 0.0;
          final discount = (itm['discount'] as num?)?.toDouble() ?? (itm['discountAmount'] as num?)?.toDouble() ?? 0.0;
          final isWithTax = itm['salePriceTaxMode'] == 'withTax' || itm['taxInclusive'] == 1 || itm['taxInclusive'] == true;

          final rawTotal = (qty * rate) - discount;
          final lineTaxable = isWithTax ? (rawTotal / (1 + (taxRate / 100))) : rawTotal;
          final lineTax = (lineTaxable * taxRate) / 100;

          double lineCgst = 0.0;
          double lineSgst = 0.0;
          double lineIgst = 0.0;

          if (isInterState) {
            lineIgst = lineTax;
          } else {
            lineCgst = lineTax / 2;
            lineSgst = lineTax / 2;
          }

          final lineCess = (itm['cess'] as num?)?.toDouble() ?? 0.0;
          final lineAddCess = (itm['additionalCess'] as num?)?.toDouble() ?? 0.0;
          final lineFloodCess = (itm['floodCess'] as num?)?.toDouble() ?? 0.0;
          final lineOtherTaxes = (itm['otherTaxes'] as num?)?.toDouble() ?? 0.0;
          final lineTotal = lineTaxable + lineTax + lineCess + lineAddCess + lineFloodCess + lineOtherTaxes;

          String unit = (itm['unit'] ?? '').toString();
          if (unit.isEmpty) {
            final inv = dbItemsMap[itemName.toLowerCase()];
            if (inv != null && inv.unit.isNotEmpty) {
              unit = inv.unit;
            }
          }

          if (!hsnMap.containsKey(key)) {
            hsnMap[key] = HsnSummaryItem(
              hsnCode: hsn,
              description: itemName,
              unit: unit,
              totalQuantity: qty,
              taxableValue: lineTaxable,
              taxRatePercent: taxRate,
              cgst: lineCgst,
              sgst: lineSgst,
              igst: lineIgst,
              cess: lineCess,
              additionalCess: lineAddCess,
              floodCess: lineFloodCess,
              otherTaxes: lineOtherTaxes,
              totalValue: lineTotal,
            );
          } else {
            final old = hsnMap[key]!;
            hsnMap[key] = HsnSummaryItem(
              hsnCode: old.hsnCode,
              description: old.description,
              unit: old.unit.isNotEmpty ? old.unit : unit,
              totalQuantity: old.totalQuantity + qty,
              taxableValue: old.taxableValue + lineTaxable,
              taxRatePercent: old.taxRatePercent,
              cgst: old.cgst + lineCgst,
              sgst: old.sgst + lineSgst,
              igst: old.igst + lineIgst,
              cess: old.cess + lineCess,
              additionalCess: old.additionalCess + lineAddCess,
              floodCess: old.floodCess + lineFloodCess,
              otherTaxes: old.otherTaxes + lineOtherTaxes,
              totalValue: old.totalValue + lineTotal,
            );
          }
        }
      }

      final list = hsnMap.values.toList()..sort((a, b) => b.taxableValue.compareTo(a.taxableValue));

      if (mounted) {
        setState(() {
          _hsnList = list;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _selectDateRange() async {
    HapticFeedback.lightImpact();
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      initialDateRange: DateTimeRange(start: _startDate, end: _endDate),
      builder: (ctx, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: const ColorScheme.light(
              primary: JoynColors.primary,
              onPrimary: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _startDate = picked.start;
        _endDate = picked.end;
      });
      _loadReport();
    }
  }

  Future<void> _exportPdf() async {
    if (_hsnList.isEmpty) return;
    final cur = NumberFormat('#,##0.00', 'en_IN');
    final period = '${DateFormat('dd/MM/yyyy').format(_startDate)} to ${DateFormat('dd/MM/yyyy').format(_endDate)}';
    final tableHeaders = ['HSN Code', 'Item Name', 'Total QTY', 'Total Value', 'Taxable Value', 'IGST', 'CGST', 'SGST'];
    final tableRows = _hsnList.map((h) {
      final qtyText = h.unit.isNotEmpty
          ? '${h.totalQuantity.toStringAsFixed(1)} ${h.unit}'
          : h.totalQuantity.toStringAsFixed(1);
      return [
        h.hsnCode == 'NA' ? 'NA' : h.hsnCode,
        h.description,
        qtyText,
        '₹ ${cur.format(h.totalValue)}',
        '₹ ${cur.format(h.taxableValue)}',
        '₹ ${cur.format(h.igst)}',
        '₹ ${cur.format(h.cgst)}',
        '₹ ${cur.format(h.sgst)}',
      ];
    }).toList();

    final totalTaxable = _hsnList.fold(0.0, (sum, i) => sum + i.taxableValue);
    final totalTurnover = _hsnList.fold(0.0, (sum, i) => sum + i.totalValue);

    final summary = {
      'Period': period,
      'Total HSN Items': '${_hsnList.length}',
      'Total Taxable Turnover': '₹ ${cur.format(totalTaxable)}',
      'Total Sales Turnover': '₹ ${cur.format(totalTurnover)}',
    };

    await ReportExportService.showPdfOptionsSheet(
      context: context,
      title: 'Sale Summary by HSN',
      periodLabel: period,
      summaryStats: summary,
      tableHeaders: tableHeaders,
      tableRows: tableRows,
    );
  }

  Future<void> _exportExcel() async {
    if (_hsnList.isEmpty) return;
    final cur = NumberFormat('#,##0.00', 'en_IN');
    final period = '${DateFormat('dd/MM/yyyy').format(_startDate)} to ${DateFormat('dd/MM/yyyy').format(_endDate)}';
    final tableHeaders = ['HSN Code', 'Item Name', 'Total QTY', 'Total Value', 'Taxable Value', 'IGST', 'CGST', 'SGST', 'CESS'];
    final tableRows = _hsnList.map((h) {
      final qtyText = h.unit.isNotEmpty
          ? '${h.totalQuantity.toStringAsFixed(1)} ${h.unit}'
          : h.totalQuantity.toStringAsFixed(1);
      return [
        h.hsnCode == 'NA' ? 'NA' : h.hsnCode,
        h.description,
        qtyText,
        cur.format(h.totalValue),
        cur.format(h.taxableValue),
        cur.format(h.igst),
        cur.format(h.cgst),
        cur.format(h.sgst),
        '0.00',
      ];
    }).toList();

    final totalTaxable = _hsnList.fold(0.0, (sum, i) => sum + i.taxableValue);
    final totalTurnover = _hsnList.fold(0.0, (sum, i) => sum + i.totalValue);

    final summary = {
      'Period': period,
      'Total HSN Items': '${_hsnList.length}',
      'Total Taxable Turnover': cur.format(totalTaxable),
      'Total Sales Turnover': cur.format(totalTurnover),
    };

    await ReportExportService.showExcelOptionsSheet(
      context: context,
      title: 'Sale Summary by HSN',
      periodLabel: period,
      summaryStats: summary,
      tableHeaders: tableHeaders,
      tableRows: tableRows,
    );
  }

  @override
  Widget build(BuildContext context) {
    final currency = NumberFormat('#,##0.00', 'en_IN');

    return Scaffold(
      backgroundColor: const Color(0xFFE8F1FC), // Exact Vyapar soft blue-grey background
      appBar: AppBar(
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF1E293B), size: 22),
          onPressed: () => Navigator.of(context).pop(),
        ),
        titleSpacing: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Sale Summary by HSN',
              style: JoynTypography.titleMedium.copyWith(
                color: const Color(0xFF1E293B),
                fontWeight: FontWeight.w700,
                fontSize: 17,
              ),
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 1),
            Text(
              '${DateFormat('dd MMM').format(_startDate)} - ${DateFormat('dd MMM yyyy').format(_endDate)}',
              style: const TextStyle(
                fontSize: 11.5,
                color: Color(0xFF64748B),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        actions: [
          // Date Filter Button
          IconButton(
            tooltip: 'Filter Date',
            icon: const Icon(Icons.calendar_today_rounded, color: Color(0xFF475569), size: 20),
            onPressed: _selectDateRange,
          ),
          // PDF Export Button (Red Badge)
          _buildActionButton(
            label: 'Pdf',
            color: const Color(0xFFDC2626),
            onTap: _exportPdf,
          ),
          const SizedBox(width: 8),
          // Excel Export Button (Green Badge)
          _buildActionButton(
            label: 'xls',
            color: const Color(0xFF16A34A),
            onTap: _exportExcel,
          ),
          const SizedBox(width: 14),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: JoynColors.primary, strokeWidth: 2.5),
            )
          : RefreshIndicator(
              color: JoynColors.primary,
              onRefresh: _loadReport,
              child: _hsnList.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.inventory_2_outlined, size: 54, color: Colors.blueGrey.shade300),
                          const SizedBox(height: 14),
                          Text(
                            'No HSN records found for this period',
                            style: JoynTypography.bodyLarge.copyWith(
                              color: const Color(0xFF64748B),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 12),
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: JoynColors.primary,
                              elevation: 0,
                              side: const BorderSide(color: Color(0xFFCBD5E1)),
                            ),
                            icon: const Icon(Icons.calendar_month_rounded, size: 18),
                            label: const Text('Change Date Range'),
                            onPressed: _selectDateRange,
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      itemCount: _hsnList.length,
                      itemBuilder: (context, index) {
                        return _buildVyaparHsnCard(_hsnList[index], currency);
                      },
                    ),
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
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(6),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.25),
              blurRadius: 4,
              offset: const Offset(0, 2),
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
  // EXACT VYAPAR HSN CARD
  // =========================================================================
  Widget _buildVyaparHsnCard(HsnSummaryItem h, NumberFormat currency) {
    final rawHsn = h.hsnCode.trim().replaceAll(RegExp(r'^#+'), '').replaceAll(RegExp(r'^hsn\s*:?\s*#?', caseSensitive: false), '').trim();
    final cleanHsn = (rawHsn.isEmpty || rawHsn.toUpperCase() == 'NA' || rawHsn.toUpperCase() == 'N/A')
        ? 'NA'
        : rawHsn;
    final hsnDisplay = 'HSN #$cleanHsn';

    final qtyStr = h.unit.isNotEmpty
        ? '${h.totalQuantity.toStringAsFixed(1)} ${h.unit}'
        : h.totalQuantity.toStringAsFixed(1);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFDCE8F6), width: 1.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header Row: HSN #Code (Left) | Description (Right) ───────────
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  hsnDisplay,
                  style: const TextStyle(
                    fontSize: 15.5,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1E293B),
                    letterSpacing: -0.2,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                h.description.isNotEmpty ? h.description : 'Sample Item',
                textAlign: TextAlign.right,
                style: const TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF94A3B8), // Muted grey as in Vyapar
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // ── Grid Row 1: Total QTY | Total Value | Taxable Value ──────────
          Row(
            children: [
              _buildGridCell('Total QTY', qtyStr),
              _buildGridCell('Total Value', '₹ ${currency.format(h.totalValue)}'),
              _buildGridCell('Taxable Value', '₹ ${currency.format(h.taxableValue)}'),
            ],
          ),

          const SizedBox(height: 14),

          // ── Grid Row 2: IGST | CGST | SGST ───────────────────────────────
          Row(
            children: [
              _buildGridCell('IGST', '₹ ${currency.format(h.igst)}'),
              _buildGridCell('CGST', '₹ ${currency.format(h.cgst)}'),
              _buildGridCell('SGST', '₹ ${currency.format(h.sgst)}'),
            ],
          ),

          const SizedBox(height: 14),

          // ── Grid Row 3: CESS | Additional CESS | FLOOD CESS ──────────────
          Row(
            children: [
              _buildGridCell('CESS', '₹ ${currency.format(h.cess)}'),
              _buildGridCell('Additional CESS', '₹ ${currency.format(h.additionalCess)}'),
              _buildGridCell('FLOOD CESS', '₹ ${currency.format(h.floodCess)}'),
            ],
          ),

          const SizedBox(height: 14),

          // ── Grid Row 4: Other Taxes ──────────────────────────────────────
          Row(
            children: [
              _buildGridCell('Other Taxes', '₹ ${currency.format(h.otherTaxes)}'),
              const Expanded(child: SizedBox()),
              const Expanded(child: SizedBox()),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildGridCell(String label, String value) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w400,
              color: Color(0xFF94A3B8), // Vyapar light-slate label
              height: 1.2,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            value,
            style: const TextStyle(
              fontSize: 13.5,
              fontWeight: FontWeight.w500,
              color: Color(0xFF334155), // Vyapar darker slate value
              height: 1.2,
            ),
          ),
        ],
      ),
    );
  }
}
