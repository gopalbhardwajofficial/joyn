import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import '../../../../core/services/api_service.dart';
import '../../models/gst_report_models.dart';

class Gstr1ReportScreen extends StatefulWidget {
  const Gstr1ReportScreen({super.key});

  @override
  State<Gstr1ReportScreen> createState() => _Gstr1ReportScreenState();
}

class _Gstr1ReportScreenState extends State<Gstr1ReportScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = true;
  Gstr1ReportModel? _report;

  DateTime _startDate = DateTime(DateTime.now().year, DateTime.now().month, 1);
  DateTime _endDate = DateTime(DateTime.now().year, DateTime.now().month + 1, 0);

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadReport();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadReport() async {
    setState(() => _isLoading = true);
    try {
      final sStr = DateFormat('yyyy-MM-dd').format(_startDate);
      final eStr = DateFormat('yyyy-MM-dd').format(_endDate);
      final res = await ApiService.getGstr1Report(startDate: sStr, endDate: eStr);
      if (res['success'] == true) {
        setState(() {
          _report = Gstr1ReportModel.fromJson(res);
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
      }
    } catch (_) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _selectDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      initialDateRange: DateTimeRange(start: _startDate, end: _endDate),
      builder: (ctx, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF4338CA),
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

  void _shareGstr1Summary() {
    if (_report == null) return;
    final s = _report!.summary;
    final text =
'''*GSTR-1 OUTWARD SUPPLIES SUMMARY*
Period: ${DateFormat('dd MMM yyyy').format(_startDate)} to ${DateFormat('dd MMM yyyy').format(_endDate)}
Business: ${_report!.businessName}
GSTIN: ${_report!.businessGstin.isNotEmpty ? _report!.businessGstin : 'Unregistered / Composition'}
━━━━━━━━━━━━━━━━━━━━
• Total Invoices: ${s.totalInvoices}
• Taxable Turnover: ₹${s.totalTaxableValue.toStringAsFixed(2)}
• Total Tax Liability: ₹${s.totalTaxLiability.toStringAsFixed(2)}
  - CGST: ₹${s.totalCgst.toStringAsFixed(2)}
  - SGST: ₹${s.totalSgst.toStringAsFixed(2)}
  - IGST: ₹${s.totalIgst.toStringAsFixed(2)}
• Total Invoice Value: ₹${s.totalInvoiceValue.toStringAsFixed(2)}
• B2B Invoices: ${_report!.b2bInvoices.length}
• HSN Categories: ${_report!.hsnSummary.length}
━━━━━━━━━━━━━━━━━━━━
Generated via JOYN ERP''';

    Share.share(text, subject: 'GSTR-1 Tax Return Summary');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFF0F172A), size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'GSTR-1 Outward Supplies',
          style: TextStyle(
            color: Color(0xFF0F172A),
            fontWeight: FontWeight.w700,
            fontSize: 18,
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'Filter Date',
            icon: const Icon(Icons.calendar_month_rounded, color: Color(0xFF4338CA)),
            onPressed: _selectDateRange,
          ),
          if (_report != null)
            IconButton(
              tooltip: 'Share Summary',
              icon: const Icon(Icons.share_outlined, color: Color(0xFF64748B)),
              onPressed: _shareGstr1Summary,
            ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: const Color(0xFF4338CA),
          unselectedLabelColor: const Color(0xFF64748B),
          indicatorColor: const Color(0xFF4338CA),
          indicatorWeight: 3,
          labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
          tabs: const [
            Tab(text: 'Summary & Rates'),
            Tab(text: 'B2B Invoices'),
            Tab(text: 'HSN Summary'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                color: Color(0xFF4338CA),
                strokeWidth: 2.5,
              ),
            )
          : RefreshIndicator(
              color: const Color(0xFF4338CA),
              onRefresh: _loadReport,
              child: _report == null
                  ? const Center(child: Text('No data found.'))
                  : TabBarView(
                      controller: _tabController,
                      children: [
                        _buildSummaryTab(),
                        _buildB2bTab(),
                        _buildHsnTab(),
                      ],
                    ),
            ),
    );
  }

  Widget _buildSummaryTab() {
    final s = _report!.summary;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Date range indicator
        _buildDateRangeChip(),
        const SizedBox(height: 14),

        // Primary Hero Card
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF4338CA), Color(0xFF312E81)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF4338CA).withValues(alpha: 0.25),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'TOTAL TAXABLE TURNOVER',
                style: TextStyle(
                  color: Color(0xFFC7D2FE),
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.8,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                '₹${s.totalTaxableValue.toStringAsFixed(2)}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 14),
              const Divider(color: Color(0xFF6366F1), height: 1),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildHeroSubCol('Total Invoices', '${s.totalInvoices}'),
                  _buildHeroSubCol('Tax Liability', '₹${s.totalTaxLiability.toStringAsFixed(2)}'),
                  _buildHeroSubCol('Gross Value', '₹${s.totalInvoiceValue.toStringAsFixed(2)}'),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Tax Breakdown Card
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Tax Breakdown (Output GST)',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF0F172A)),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(child: _buildTaxTile('Central Tax (CGST)', s.totalCgst, const Color(0xFF0284C7))),
                  const SizedBox(width: 10),
                  Expanded(child: _buildTaxTile('State Tax (SGST)', s.totalSgst, const Color(0xFF059669))),
                  const SizedBox(width: 10),
                  Expanded(child: _buildTaxTile('Integrated (IGST)', s.totalIgst, const Color(0xFF7C3AED))),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Rate Slab Breakdown Table
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Rate Slab-Wise Outward Supplies',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF0F172A)),
              ),
              const SizedBox(height: 12),
              ..._report!.rateWiseBreakup.map((r) => _buildRateRow(r)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildB2bTab() {
    final list = _report!.b2bInvoices;
    if (list.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: Color(0xFFEEF2FF),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.receipt_long_outlined, size: 36, color: Color(0xFF4338CA)),
            ),
            const SizedBox(height: 12),
            const Text(
              'No B2B Invoices Found',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Color(0xFF0F172A)),
            ),
            const SizedBox(height: 4),
            const Text(
              'Sales to registered GSTIN parties will appear here.',
              style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: list.length,
      separatorBuilder: (ctx, i) => const SizedBox(height: 10),
      itemBuilder: (ctx, i) {
        final inv = list[i];
        return Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'INV-${inv.invoiceNo}',
                    style: const TextStyle(fontWeight: FontWeight.w800, color: Color(0xFF4338CA)),
                  ),
                  Text(
                    inv.date,
                    style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                inv.customerName,
                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: Color(0xFF0F172A)),
              ),
              const SizedBox(height: 2),
              Text(
                'GSTIN: ${inv.customerGstin} • ${inv.stateOfSupply}',
                style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
              ),
              const SizedBox(height: 10),
              const Divider(height: 1, color: Color(0xFFF1F5F9)),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Taxable: ₹${inv.taxableValue.toStringAsFixed(2)}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                  Text('Total: ₹${inv.totalAmount.toStringAsFixed(2)}', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: Color(0xFF0F172A))),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHsnTab() {
    final list = _report!.hsnSummary;
    if (list.isEmpty) {
      return const Center(child: Text('No HSN entries found.'));
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: list.length,
      separatorBuilder: (ctx, i) => const SizedBox(height: 10),
      itemBuilder: (ctx, i) {
        final h = list[i];
        return Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEEF2FF),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      'HSN: ${h.hsnCode}',
                      style: const TextStyle(color: Color(0xFF4338CA), fontWeight: FontWeight.w700, fontSize: 12),
                    ),
                  ),
                  Text(
                    '${h.totalQuantity} ${h.unit}',
                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: Color(0xFF0F172A)),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                h.description,
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF334155)),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Taxable: ₹${h.taxableValue.toStringAsFixed(2)}', style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                  Text('Tax: ₹${(h.cgst + h.sgst + h.igst).toStringAsFixed(2)} (${h.taxRatePercent}%)', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF4338CA))),
                  Text('Total: ₹${h.totalValue.toStringAsFixed(2)}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: Color(0xFF0F172A))),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDateRangeChip() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              const Icon(Icons.calendar_today_rounded, size: 14, color: Color(0xFF64748B)),
              const SizedBox(width: 8),
              Text(
                '${DateFormat('dd MMM yyyy').format(_startDate)} - ${DateFormat('dd MMM yyyy').format(_endDate)}',
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF334155)),
              ),
            ],
          ),
          InkWell(
            onTap: _selectDateRange,
            child: const Text('Change', style: TextStyle(color: Color(0xFF4338CA), fontSize: 12, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  Widget _buildHeroSubCol(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Color(0xFFC7D2FE), fontSize: 11, fontWeight: FontWeight.w500)),
        const SizedBox(height: 2),
        Text(value, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w700)),
      ],
    );
  }

  Widget _buildTaxTile(String label, double amount, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: color)),
          const SizedBox(height: 4),
          Text('₹${amount.toStringAsFixed(2)}', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: color)),
        ],
      ),
    );
  }

  Widget _buildRateRow(RateWiseItem r) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Container(
            width: 44,
            padding: const EdgeInsets.symmetric(vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFFEEF2FF),
              borderRadius: BorderRadius.circular(6),
            ),
            alignment: Alignment.center,
            child: Text('${r.rate.toInt()}%', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12, color: Color(0xFF4338CA))),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Taxable: ₹${r.taxableValue.toStringAsFixed(2)}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                Text('CGST: ₹${r.cgst.toStringAsFixed(2)} • SGST: ₹${r.sgst.toStringAsFixed(2)}', style: const TextStyle(fontSize: 11, color: Color(0xFF64748B))),
              ],
            ),
          ),
          Text(
            '₹${r.totalTax.toStringAsFixed(2)}',
            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: Color(0xFF0F172A)),
          ),
        ],
      ),
    );
  }
}

