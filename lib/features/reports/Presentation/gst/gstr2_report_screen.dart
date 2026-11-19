import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import '../../../../core/services/api_service.dart';
import '../../models/gst_report_models.dart';

class Gstr2ReportScreen extends StatefulWidget {
  const Gstr2ReportScreen({super.key});

  @override
  State<Gstr2ReportScreen> createState() => _Gstr2ReportScreenState();
}

class _Gstr2ReportScreenState extends State<Gstr2ReportScreen> {
  bool _isLoading = true;
  Gstr2ReportModel? _report;

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
      final res = await ApiService.getGstr2Report(startDate: sStr, endDate: eStr);
      if (res['success'] == true) {
        setState(() {
          _report = Gstr2ReportModel.fromJson(res);
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
'''*GSTR-2 INWARD SUPPLIES (ITC) SUMMARY*
Period: ${DateFormat('dd MMM yyyy').format(_startDate)} to ${DateFormat('dd MMM yyyy').format(_endDate)}
Business: ${_report!.businessName}
━━━━━━━━━━━━━━━━━━━━
• Total Purchase Orders: ${_report!.totalPurchaseOrders}
• Total Taxable Purchases: ₹${_report!.totalTaxablePurchase.toStringAsFixed(2)}
• Total Eligible ITC: ₹${_report!.totalEligibleItc.toStringAsFixed(2)}
  - CGST ITC: ₹${_report!.eligibleItcCgst.toStringAsFixed(2)}
  - SGST ITC: ₹${_report!.eligibleItcSgst.toStringAsFixed(2)}
  - IGST ITC: ₹${_report!.eligibleItcIgst.toStringAsFixed(2)}
• Gross Purchase Value: ₹${_report!.totalPurchaseAmount.toStringAsFixed(2)}
━━━━━━━━━━━━━━━━━━━━
Generated via JOYN ERP''';

    Share.share(text, subject: 'GSTR-2 ITC Return Summary');
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
          'GSTR-2 Inward (ITC)',
          style: TextStyle(
            color: Color(0xFF0F172A),
            fontWeight: FontWeight.w700,
            fontSize: 18,
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'Filter Date',
            icon: const Icon(Icons.calendar_month_rounded, color: Color(0xFF059669)),
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
              child: CircularProgressIndicator(color: Color(0xFF059669), strokeWidth: 2.5),
            )
          : RefreshIndicator(
              color: const Color(0xFF059669),
              onRefresh: _loadReport,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // Date range chip
                  _buildDateChip(),
                  const SizedBox(height: 14),

                  // Hero ITC Card
                  _buildHeroCard(),
                  const SizedBox(height: 16),

                  // Inward Purchase List
                  const Text(
                    'Purchase Invoices & Input Tax Credit',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF0F172A)),
                  ),
                  const SizedBox(height: 10),

                  if (_report!.inwardSupplies.isEmpty)
                    _buildEmptySupplies()
                  else
                    ..._report!.inwardSupplies.map((item) => _buildInwardCard(item)),
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
            child: const Text('Change', style: TextStyle(color: Color(0xFF059669), fontSize: 12, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  Widget _buildHeroCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF059669), Color(0xFF065F46)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF059669).withValues(alpha: 0.25),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'TOTAL ELIGIBLE INPUT TAX CREDIT (ITC)',
            style: TextStyle(
              color: Color(0xFFA7F3D0),
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '₹${_report!.totalEligibleItc.toStringAsFixed(2)}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 26,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 14),
          const Divider(color: Color(0xFF34D399), height: 1),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildSubCol('Purchases', '${_report!.totalPurchaseOrders} Orders'),
              _buildSubCol('Taxable Purchases', '₹${_report!.totalTaxablePurchase.toStringAsFixed(2)}'),
              _buildSubCol('Gross Purchases', '₹${_report!.totalPurchaseAmount.toStringAsFixed(2)}'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSubCol(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Color(0xFFA7F3D0), fontSize: 11)),
        const SizedBox(height: 2),
        Text(value, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w700)),
      ],
    );
  }

  Widget _buildInwardCard(InwardSupplyItem item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
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
                'PO-${item.orderNo}',
                style: const TextStyle(fontWeight: FontWeight.w700, color: Color(0xFF059669)),
              ),
              Text(item.date, style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            item.supplierName,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF0F172A)),
          ),
          const SizedBox(height: 2),
          Text('GSTIN: ${item.supplierGstin}', style: const TextStyle(fontSize: 11, color: Color(0xFF64748B))),
          const SizedBox(height: 8),
          const Divider(height: 1, color: Color(0xFFF1F5F9)),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Taxable: ₹${item.taxableValue.toStringAsFixed(2)}', style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
              Text(
                'ITC: ₹${item.totalItc.toStringAsFixed(2)}',
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: Color(0xFF059669)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmptySupplies() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 30),
      alignment: Alignment.center,
      child: const Text('No purchase records found for this period.', style: TextStyle(color: Color(0xFF64748B))),
    );
  }
}

