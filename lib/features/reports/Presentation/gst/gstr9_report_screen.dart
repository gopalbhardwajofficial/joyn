import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import '../../../../core/services/api_service.dart';
import '../../../../core/services/report_export_service.dart';
import '../../../../core/theme/joyn_colors.dart';
import '../../../../core/theme/joyn_typography.dart';
import '../../models/gst_report_models.dart';

class Gstr9ReportScreen extends StatefulWidget {
  const Gstr9ReportScreen({super.key});

  @override
  State<Gstr9ReportScreen> createState() => _Gstr9ReportScreenState();
}

class _Gstr9ReportScreenState extends State<Gstr9ReportScreen> {
  bool _isLoading = true;
  Gstr9ReportModel? _report;

  // Defaults to current Financial Year (e.g., April 1 to March 31)
  late DateTime _startDate;
  late DateTime _endDate;
  String _selectedFyLabel = 'FY 2024-25';

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    // Indian FY runs from April 1 to March 31
    final fyStartYear = now.month >= 4 ? now.year : now.year - 1;
    _startDate = DateTime(fyStartYear, 4, 1);
    _endDate = DateTime(fyStartYear + 1, 3, 31);
    _selectedFyLabel = 'FY $fyStartYear-${(fyStartYear + 1).toString().substring(2)}';
    _loadReport();
  }

  Future<void> _loadReport() async {
    setState(() => _isLoading = true);
    try {
      final sStr = DateFormat('yyyy-MM-dd').format(_startDate);
      final eStr = DateFormat('yyyy-MM-dd').format(_endDate);
      final res = await ApiService.getGstr9Report(startDate: sStr, endDate: eStr);
      if (res['success'] == true) {
        if (mounted) {
          setState(() {
            _report = Gstr9ReportModel.fromJson(res);
            _isLoading = false;
          });
        }
      } else {
        if (mounted) setState(() => _isLoading = false);
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _selectFinancialYear() async {
    final now = DateTime.now();
    final currentFyStart = now.month >= 4 ? now.year : now.year - 1;
    final fYears = [
      currentFyStart,
      currentFyStart - 1,
      currentFyStart - 2,
    ];

    final chosenYear = await showModalBottomSheet<int>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  child: Text(
                    'Select Financial Year',
                    style: JoynTypography.titleMedium.copyWith(
                      fontWeight: FontWeight.w700,
                      color: JoynColors.primary,
                    ),
                  ),
                ),
                const Divider(),
                ...fYears.map((yr) {
                  final label = 'FY $yr-${(yr + 1).toString().substring(2)}';
                  return ListTile(
                    title: Text(label, style: JoynTypography.bodyLarge),
                    trailing: _selectedFyLabel == label
                        ? const Icon(Icons.check_circle_rounded, color: JoynColors.primary)
                        : null,
                    onTap: () => Navigator.pop(ctx, yr),
                  );
                }),
                ListTile(
                  leading: const Icon(Icons.calendar_month_rounded, color: JoynColors.primary),
                  title: const Text('Custom Date Range'),
                  onTap: () => Navigator.pop(ctx, -1),
                ),
              ],
            ),
          ),
        );
      },
    );

    if (chosenYear != null) {
      if (!mounted) return;
      if (chosenYear == -1) {
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
            _selectedFyLabel = '${DateFormat('dd MMM yy').format(_startDate)} - ${DateFormat('dd MMM yy').format(_endDate)}';
          });
          _loadReport();
        }
      } else {
        setState(() {
          _startDate = DateTime(chosenYear, 4, 1);
          _endDate = DateTime(chosenYear + 1, 3, 31);
          _selectedFyLabel = 'FY $chosenYear-${(chosenYear + 1).toString().substring(2)}';
        });
        _loadReport();
      }
    }
  }

  void _shareSummary() {
    if (_report == null) return;
    final cur = NumberFormat('#,##0.00', 'en_IN');
    final text =
'''*GSTR-9 ANNUAL RETURN SUMMARY*
${_report!.financialYear.isNotEmpty ? _report!.financialYear : _selectedFyLabel}
Period: ${DateFormat('dd/MM/yyyy').format(_startDate)} to ${DateFormat('dd/MM/yyyy').format(_endDate)}
GSTIN: ${_report!.businessGstin}
Business: ${_report!.businessName}
━━━━━━━━━━━━━━━━━━━━
1. OUTWARD SUPPLIES & TURNOVER:
• Total Taxable Turnover: ₹${cur.format(_report!.totalTaxableTurnover)}
  - B2B Supplies: ₹${cur.format(_report!.b2bTaxableTurnover)}
  - B2C Supplies: ₹${cur.format(_report!.b2cTaxableTurnover)}
• Total Outward Tax Liability: ₹${cur.format(_report!.totalOutwardTaxLiability)}
  - CGST: ₹${cur.format(_report!.totalOutwardCgst)}
  - SGST: ₹${cur.format(_report!.totalOutwardSgst)}
  - IGST: ₹${cur.format(_report!.totalOutwardIgst)}

2. INPUT TAX CREDIT (ITC) AVAILED:
• Taxable Purchases: ₹${cur.format(_report!.totalTaxablePurchases)}
• Total Eligible ITC: ₹${cur.format(_report!.totalEligibleItcAvailed)}
  - CGST: ₹${cur.format(_report!.itcCgst)}
  - SGST: ₹${cur.format(_report!.itcSgst)}
  - IGST: ₹${cur.format(_report!.itcIgst)}

3. ANNUAL TAX LIABILITY & RECONCILIATION:
• Total Tax Payable: ₹${cur.format(_report!.totalTaxPayable)}
• ITC Utilized: ₹${cur.format(_report!.totalItcUtilized)}
• Net Cash Tax Payable: ₹${cur.format(_report!.netTaxPayableCash)}
• Balance ITC Carried Forward: ₹${cur.format(_report!.excessItcCarriedForward)}
━━━━━━━━━━━━━━━━━━━━
Generated via JOYN ERP''';

    Share.share(text, subject: 'GSTR-9 Annual Return Summary');
  }

  Future<void> _exportPdf() async {
    if (_report == null) return;
    final cur = NumberFormat('#,##0.00', 'en_IN');
    final tableHeaders = ['Section & Particulars', 'Taxable Value', 'CGST', 'SGST', 'IGST', 'Total Tax'];
    final tableRows = [
      [
        '4A. B2B Outward Supplies',
        '₹${cur.format(_report!.b2bTaxableTurnover)}',
        '₹${cur.format(_report!.b2bCgst)}',
        '₹${cur.format(_report!.b2bSgst)}',
        '₹${cur.format(_report!.b2bIgst)}',
        '₹${cur.format(_report!.b2bCgst + _report!.b2bSgst + _report!.b2bIgst)}',
      ],
      [
        '4B. B2C Outward Supplies',
        '₹${cur.format(_report!.b2cTaxableTurnover)}',
        '₹${cur.format(_report!.b2cCgst)}',
        '₹${cur.format(_report!.b2cSgst)}',
        '₹${cur.format(_report!.b2cIgst)}',
        '₹${cur.format(_report!.b2cCgst + _report!.b2cSgst + _report!.b2cIgst)}',
      ],
      [
        'Total Outward Turnover',
        '₹${cur.format(_report!.totalTaxableTurnover)}',
        '₹${cur.format(_report!.totalOutwardCgst)}',
        '₹${cur.format(_report!.totalOutwardSgst)}',
        '₹${cur.format(_report!.totalOutwardIgst)}',
        '₹${cur.format(_report!.totalOutwardTaxLiability)}',
      ],
      [
        '6A. Inward Purchases (ITC)',
        '₹${cur.format(_report!.totalTaxablePurchases)}',
        '₹${cur.format(_report!.itcCgst)}',
        '₹${cur.format(_report!.itcSgst)}',
        '₹${cur.format(_report!.itcIgst)}',
        '₹${cur.format(_report!.totalEligibleItcAvailed)}',
      ],
      [
        '9. Net Tax Payable (Cash)',
        '-',
        '-',
        '-',
        '-',
        '₹${cur.format(_report!.netTaxPayableCash)}',
      ],
      [
        'Balance ITC Carried Forward',
        '-',
        '-',
        '-',
        '-',
        '₹${cur.format(_report!.excessItcCarriedForward)}',
      ],
    ];

    final summary = {
      'Financial Year': _report!.financialYear.isNotEmpty ? _report!.financialYear : _selectedFyLabel,
      'Total Taxable Turnover': '₹${cur.format(_report!.totalTaxableTurnover)}',
      'Total Output Tax': '₹${cur.format(_report!.totalOutwardTaxLiability)}',
      'Eligible ITC Availed': '₹${cur.format(_report!.totalEligibleItcAvailed)}',
      'Net Cash Payable': '₹${cur.format(_report!.netTaxPayableCash)}',
      'Balance ITC': '₹${cur.format(_report!.excessItcCarriedForward)}',
    };

    await ReportExportService.showPdfOptionsSheet(
      context: context,
      title: 'GSTR-9 Annual Return',
      periodLabel: _selectedFyLabel,
      summaryStats: summary,
      tableHeaders: tableHeaders,
      tableRows: tableRows,
    );
  }

  Future<void> _exportExcel() async {
    if (_report == null) return;
    final cur = NumberFormat('#,##0.00', 'en_IN');
    final tableHeaders = ['Section & Particulars', 'Taxable Value', 'CGST', 'SGST', 'IGST', 'Total Tax'];
    final tableRows = [
      [
        '4A. B2B Outward Supplies',
        cur.format(_report!.b2bTaxableTurnover),
        cur.format(_report!.b2bCgst),
        cur.format(_report!.b2bSgst),
        cur.format(_report!.b2bIgst),
        cur.format(_report!.b2bCgst + _report!.b2bSgst + _report!.b2bIgst),
      ],
      [
        '4B. B2C Outward Supplies',
        cur.format(_report!.b2cTaxableTurnover),
        cur.format(_report!.b2cCgst),
        cur.format(_report!.b2cSgst),
        cur.format(_report!.b2cIgst),
        cur.format(_report!.b2cCgst + _report!.b2cSgst + _report!.b2cIgst),
      ],
      [
        'Total Outward Turnover',
        cur.format(_report!.totalTaxableTurnover),
        cur.format(_report!.totalOutwardCgst),
        cur.format(_report!.totalOutwardSgst),
        cur.format(_report!.totalOutwardIgst),
        cur.format(_report!.totalOutwardTaxLiability),
      ],
      [
        '6A. Inward Purchases (ITC)',
        cur.format(_report!.totalTaxablePurchases),
        cur.format(_report!.itcCgst),
        cur.format(_report!.itcSgst),
        cur.format(_report!.itcIgst),
        cur.format(_report!.totalEligibleItcAvailed),
      ],
      [
        '9. Net Tax Payable (Cash)',
        '0.00',
        '0.00',
        '0.00',
        '0.00',
        cur.format(_report!.netTaxPayableCash),
      ],
      [
        'Balance ITC Carried Forward',
        '0.00',
        '0.00',
        '0.00',
        '0.00',
        cur.format(_report!.excessItcCarriedForward),
      ],
    ];

    final summary = {
      'Financial Year': _report!.financialYear.isNotEmpty ? _report!.financialYear : _selectedFyLabel,
      'Total Taxable Turnover': cur.format(_report!.totalTaxableTurnover),
      'Total Output Tax': cur.format(_report!.totalOutwardTaxLiability),
      'Eligible ITC Availed': cur.format(_report!.totalEligibleItcAvailed),
      'Net Cash Payable': cur.format(_report!.netTaxPayableCash),
      'Balance ITC': cur.format(_report!.excessItcCarriedForward),
    };

    await ReportExportService.showExcelOptionsSheet(
      context: context,
      title: 'GSTR-9 Annual Return',
      periodLabel: _selectedFyLabel,
      summaryStats: summary,
      tableHeaders: tableHeaders,
      tableRows: tableRows,
    );
  }

  @override
  Widget build(BuildContext context) {
    final cur = NumberFormat('#,##0.00', 'en_IN');

    return Scaffold(
      backgroundColor: JoynColors.background,
      appBar: AppBar(
        backgroundColor: JoynColors.background,
        elevation: 0,
        titleSpacing: 20,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: JoynColors.primary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'GSTR-9 Annual Return',
          style: JoynTypography.titleMedium.copyWith(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: JoynColors.primary,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.share_rounded, color: JoynColors.primary, size: 20),
            onPressed: _shareSummary,
            tooltip: 'Share Summary',
          ),
          IconButton(
            icon: const Icon(Icons.picture_as_pdf_rounded, color: Color(0xFFDC2626), size: 20),
            onPressed: _exportPdf,
            tooltip: 'Export PDF',
          ),
          IconButton(
            icon: const Icon(Icons.grid_on_rounded, color: JoynColors.success, size: 20),
            onPressed: _exportExcel,
            tooltip: 'Export Excel',
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: JoynColors.primary))
          : _report == null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.receipt_long_rounded, size: 48, color: JoynColors.secondaryText),
                      const SizedBox(height: 12),
                      Text('Unable to load GSTR-9 report', style: JoynTypography.bodyLarge),
                      const SizedBox(height: 12),
                      ElevatedButton(
                        onPressed: _loadReport,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : ListView(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                  children: [
                    // Financial Year Selector Card
                    InkWell(
                      onTap: _selectFinancialYear,
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: JoynColors.border),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.03),
                              blurRadius: 10,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: JoynColors.primary.withValues(alpha: 0.1),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.account_balance_rounded, color: JoynColors.primary, size: 20),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _selectedFyLabel,
                                    style: JoynTypography.bodyLarge.copyWith(
                                      fontWeight: FontWeight.w700,
                                      color: JoynColors.primary,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    '${DateFormat('dd MMM yyyy').format(_startDate)} - ${DateFormat('dd MMM yyyy').format(_endDate)}',
                                    style: JoynTypography.caption.copyWith(color: JoynColors.secondaryText),
                                  ),
                                ],
                              ),
                            ),
                            const Icon(Icons.arrow_drop_down_rounded, color: JoynColors.primary, size: 28),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Top KPI Highlights Card
                    Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            JoynColors.primary,
                            JoynColors.primary.withValues(alpha: 0.88),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: JoynColors.primary.withValues(alpha: 0.25),
                            blurRadius: 16,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: _buildKpiBox(
                                  label: 'Gross Annual Turnover',
                                  value: '₹${cur.format(_report!.totalGrossTurnover)}',
                                  color: Colors.white,
                                ),
                              ),
                              Container(width: 1, height: 42, color: Colors.white24),
                              Expanded(
                                child: _buildKpiBox(
                                  label: 'Output Tax Liability',
                                  value: '₹${cur.format(_report!.totalOutwardTaxLiability)}',
                                  color: const Color(0xFFFCA5A5),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          Container(height: 1, color: Colors.white24),
                          const SizedBox(height: 14),
                          Row(
                            children: [
                              Expanded(
                                child: _buildKpiBox(
                                  label: 'Eligible ITC Availed',
                                  value: '₹${cur.format(_report!.totalEligibleItcAvailed)}',
                                  color: const Color(0xFF86EFAC),
                                ),
                              ),
                              Container(width: 1, height: 42, color: Colors.white24),
                              Expanded(
                                child: _buildKpiBox(
                                  label: 'Net Cash Tax Payable',
                                  value: '₹${cur.format(_report!.netTaxPayableCash)}',
                                  color: _report!.netTaxPayableCash > 0 ? const Color(0xFFFDBA74) : const Color(0xFF86EFAC),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Section 4: Outward Supplies Details
                    _buildSectionHeader('4. Details of Outward Supplies (Sales)', Icons.upload_rounded),
                    const SizedBox(height: 10),
                    _buildCard([
                      _buildRow('B2B Taxable Supplies', '₹${cur.format(_report!.b2bTaxableTurnover)}', isHeader: true),
                      _buildSubRow('CGST: ₹${cur.format(_report!.b2bCgst)}  |  SGST: ₹${cur.format(_report!.b2bSgst)}  |  IGST: ₹${cur.format(_report!.b2bIgst)}'),
                      const Divider(height: 16),
                      _buildRow('B2C Taxable Supplies', '₹${cur.format(_report!.b2cTaxableTurnover)}', isHeader: true),
                      _buildSubRow('CGST: ₹${cur.format(_report!.b2cCgst)}  |  SGST: ₹${cur.format(_report!.b2cSgst)}  |  IGST: ₹${cur.format(_report!.b2cIgst)}'),
                      const Divider(height: 16),
                      _buildRow('Total Outward Tax Liability', '₹${cur.format(_report!.totalOutwardTaxLiability)}', isHighlight: true, highlightColor: const Color(0xFFDC2626)),
                    ]),
                    const SizedBox(height: 20),

                    // Section 6: Details of ITC Availed
                    _buildSectionHeader('6. Details of ITC Availed (Purchases)', Icons.download_rounded),
                    const SizedBox(height: 10),
                    _buildCard([
                      _buildRow('Taxable Purchase Value', '₹${cur.format(_report!.totalTaxablePurchases)}', isHeader: true),
                      _buildRow('Total Purchases (Gross)', '₹${cur.format(_report!.totalPurchasesGross)}'),
                      const Divider(height: 16),
                      _buildRow('Central Tax (CGST ITC)', '₹${cur.format(_report!.itcCgst)}'),
                      _buildRow('State Tax (SGST ITC)', '₹${cur.format(_report!.itcSgst)}'),
                      _buildRow('Integrated Tax (IGST ITC)', '₹${cur.format(_report!.itcIgst)}'),
                      const Divider(height: 16),
                      _buildRow('Total Eligible ITC Availed', '₹${cur.format(_report!.totalEligibleItcAvailed)}', isHighlight: true, highlightColor: JoynColors.success),
                    ]),
                    const SizedBox(height: 20),

                    // Section 9: Annual Tax Payable vs Paid
                    _buildSectionHeader('9. Annual Tax Liability & Settlement', Icons.verified_user_rounded),
                    const SizedBox(height: 10),
                    _buildCard([
                      _buildRow('Total Output Tax Payable', '₹${cur.format(_report!.totalTaxPayable)}'),
                      _buildRow('Less: ITC Set-off / Utilized', '- ₹${cur.format(_report!.totalItcUtilized)}', highlightColor: JoynColors.success),
                      const Divider(height: 16),
                      _buildRow('Net Tax Payable in Cash', '₹${cur.format(_report!.netTaxPayableCash)}', isHighlight: true, highlightColor: _report!.netTaxPayableCash > 0 ? const Color(0xFFDC2626) : JoynColors.success),
                      if (_report!.excessItcCarriedForward > 0) ...[
                        const Divider(height: 16),
                        _buildRow('Excess ITC Carried Forward', '₹${cur.format(_report!.excessItcCarriedForward)}', isHighlight: true, highlightColor: const Color(0xFF2563EB)),
                      ],
                    ]),
                  ],
                ),
    );
  }

  Widget _buildKpiBox({required String label, required String value, required Color color}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          label,
          textAlign: TextAlign.center,
          style: JoynTypography.caption.copyWith(color: Colors.white70, fontSize: 11),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          textAlign: TextAlign.center,
          style: JoynTypography.bodyLarge.copyWith(
            fontWeight: FontWeight.w800,
            fontSize: 16,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 18, color: JoynColors.primary),
        const SizedBox(width: 8),
        Text(
          title,
          style: JoynTypography.bodyLarge.copyWith(
            fontWeight: FontWeight.w800,
            fontSize: 14.5,
            color: JoynColors.primary,
          ),
        ),
      ],
    );
  }

  Widget _buildCard(List<Widget> children) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: JoynColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }

  Widget _buildRow(String label, String value, {bool isHeader = false, bool isHighlight = false, Color? highlightColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: JoynTypography.bodyMedium.copyWith(
              fontWeight: (isHeader || isHighlight) ? FontWeight.w700 : FontWeight.w500,
              fontSize: isHighlight ? 14 : 13,
              color: isHighlight ? (highlightColor ?? JoynColors.primary) : JoynColors.primary,
            ),
          ),
          Text(
            value,
            style: JoynTypography.bodyMedium.copyWith(
              fontWeight: (isHeader || isHighlight) ? FontWeight.w800 : FontWeight.w600,
              fontSize: isHighlight ? 15 : 13,
              color: highlightColor ?? (isHighlight ? JoynColors.primary : JoynColors.primary),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubRow(String text) {
    return Padding(
      padding: const EdgeInsets.only(top: 2, bottom: 4),
      child: Text(
        text,
        style: JoynTypography.caption.copyWith(
          color: JoynColors.secondaryText,
          fontSize: 11,
        ),
      ),
    );
  }
}
