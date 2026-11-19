import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import '../../../../core/services/api_service.dart';
import '../../models/gst_report_models.dart';

class Gstr3bReportScreen extends StatefulWidget {
  const Gstr3bReportScreen({super.key});

  @override
  State<Gstr3bReportScreen> createState() => _Gstr3bReportScreenState();
}

class _Gstr3bReportScreenState extends State<Gstr3bReportScreen> {
  bool _isLoading = true;
  Gstr3bReportModel? _report;

  DateTime _startDate = DateTime(DateTime.now().year, DateTime.now().month, 1);
  DateTime _endDate = DateTime(DateTime.now().year, DateTime.now().month + 1, 0);

  @override
  void initState() {
    super.initState();
    _loadReport();
  }

  Future<void> _loadReport() async {
    setState(() => _isLoading = true);
    try {
      final sStr = DateFormat('yyyy-MM-dd').format(_startDate);
      final eStr = DateFormat('yyyy-MM-dd').format(_endDate);
      final res = await ApiService.getGstr3bReport(startDate: sStr, endDate: eStr);
      if (res['success'] == true) {
        setState(() {
          _report = Gstr3bReportModel.fromJson(res);
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
    );

    if (picked != null) {
      setState(() {
        _startDate = picked.start;
        _endDate = picked.end;
      });
      _loadReport();
    }
  }

  void _shareSummary() {
    if (_report == null) return;
    final text =
'''*GSTR-3B MONTHLY RETURN SUMMARY*
Period: ${DateFormat('dd MMM yyyy').format(_startDate)} to ${DateFormat('dd MMM yyyy').format(_endDate)}
━━━━━━━━━━━━━━━━━━━━
1. OUTWARD TAX LIABILITY (SALES):
• Taxable Turnover: ₹${_report!.outwardTaxableTurnover.toStringAsFixed(2)}
• Total Tax Liability: ₹${_report!.totalOutwardTax.toStringAsFixed(2)}
  - CGST: ₹${_report!.outwardCgst.toStringAsFixed(2)}
  - SGST: ₹${_report!.outwardSgst.toStringAsFixed(2)}
  - IGST: ₹${_report!.outwardIgst.toStringAsFixed(2)}

2. ELIGIBLE INPUT TAX CREDIT (PURCHASES):
• Taxable Purchases: ₹${_report!.itcTaxablePurchases.toStringAsFixed(2)}
• Total Eligible ITC: ₹${_report!.totalEligibleItc.toStringAsFixed(2)}
  - CGST ITC: ₹${_report!.itcCgst.toStringAsFixed(2)}
  - SGST ITC: ₹${_report!.itcSgst.toStringAsFixed(2)}

3. NET TAX PAYABLE / EXCESS CREDIT:
• Status: ${_report!.status}
• Net Tax Payable: ₹${_report!.totalNetPayable.toStringAsFixed(2)}
• Excess ITC Carried Forward: ₹${_report!.excessItcCarriedForward.toStringAsFixed(2)}
━━━━━━━━━━━━━━━━━━━━
Generated via JOYN ERP''';

    Share.share(text, subject: 'GSTR-3B Return Summary');
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
          'GSTR-3B Monthly Return',
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
              tooltip: 'Share',
              icon: const Icon(Icons.share_outlined, color: Color(0xFF64748B)),
              onPressed: _shareSummary,
            ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF4338CA), strokeWidth: 2.5),
            )
          : RefreshIndicator(
              color: const Color(0xFF4338CA),
              onRefresh: _loadReport,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _buildDateChip(),
                  const SizedBox(height: 14),

                  // Net Payable / Refund Banner
                  _buildNetPayableBanner(),
                  const SizedBox(height: 16),

                  // Section 3.1: Outward Supplies
                  _buildSection31Card(),
                  const SizedBox(height: 14),

                  // Section 4: Eligible ITC
                  _buildSection4Card(),
                  const SizedBox(height: 14),

                  // Section 5: Net Payable Breakdown
                  _buildNetBreakdownCard(),
                ],
              ),
            ),
    );
  }

  Widget _buildDateChip() {
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

  Widget _buildNetPayableBanner() {
    final isPayable = _report!.totalNetPayable > 0;
    final primaryColor = isPayable ? const Color(0xFFDC2626) : const Color(0xFF059669);
    final secondaryColor = isPayable ? const Color(0xFF991B1B) : const Color(0xFF065F46);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [primaryColor, secondaryColor],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: primaryColor.withValues(alpha: 0.25),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            isPayable ? 'NET GST TAX PAYABLE' : 'NET EXCESS ITC CREDIT',
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            isPayable
                ? '₹${_report!.totalNetPayable.toStringAsFixed(2)}'
                : '₹${_report!.excessItcCarriedForward.toStringAsFixed(2)}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 26,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            isPayable
                ? 'Output Tax (₹${_report!.totalOutwardTax.toStringAsFixed(2)}) exceeds ITC (₹${_report!.totalEligibleItc.toStringAsFixed(2)})'
                : 'Eligible ITC exceeds Output Tax Liability. Credit carried forward.',
            style: const TextStyle(color: Colors.white70, fontSize: 11),
          ),
        ],
      ),
    );
  }

  Widget _buildSection31Card() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                '3.1 Outward Taxable Supplies',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF0F172A)),
              ),
              Text(
                '₹${_report!.totalOutwardTax.toStringAsFixed(2)}',
                style: const TextStyle(fontWeight: FontWeight.w800, color: Color(0xFFDC2626)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text('Taxable Turnover: ₹${_report!.outwardTaxableTurnover.toStringAsFixed(2)}', style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
          const SizedBox(height: 8),
          const Divider(height: 1, color: Color(0xFFF1F5F9)),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('CGST: ₹${_report!.outwardCgst.toStringAsFixed(2)}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
              Text('SGST: ₹${_report!.outwardSgst.toStringAsFixed(2)}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
              Text('IGST: ₹${_report!.outwardIgst.toStringAsFixed(2)}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSection4Card() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                '4. Eligible Input Tax Credit (ITC)',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF0F172A)),
              ),
              Text(
                '₹${_report!.totalEligibleItc.toStringAsFixed(2)}',
                style: const TextStyle(fontWeight: FontWeight.w800, color: Color(0xFF059669)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text('Taxable Purchases: ₹${_report!.itcTaxablePurchases.toStringAsFixed(2)}', style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
          const SizedBox(height: 8),
          const Divider(height: 1, color: Color(0xFFF1F5F9)),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('CGST: ₹${_report!.itcCgst.toStringAsFixed(2)}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
              Text('SGST: ₹${_report!.itcSgst.toStringAsFixed(2)}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
              Text('IGST: ₹${_report!.itcIgst.toStringAsFixed(2)}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNetBreakdownCard() {
    return Container(
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
            '5. Net Tax Payment Breakdown',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF0F172A)),
          ),
          const SizedBox(height: 10),
          _buildNetRow('Central Tax (CGST) Payable', _report!.netCgstPayable),
          _buildNetRow('State Tax (SGST) Payable', _report!.netSgstPayable),
          _buildNetRow('Integrated Tax (IGST) Payable', _report!.netIgstPayable),
          const Divider(height: 14, color: Color(0xFFE2E8F0)),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Total Net Payable in Cash', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: Color(0xFF0F172A))),
              Text(
                '₹${_report!.totalNetPayable.toStringAsFixed(2)}',
                style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: Color(0xFF4338CA)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNetRow(String label, double val) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
          Text('₹${val.toStringAsFixed(2)}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF0F172A))),
        ],
      ),
    );
  }
}

