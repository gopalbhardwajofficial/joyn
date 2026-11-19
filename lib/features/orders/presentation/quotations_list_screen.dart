import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../core/services/api_service.dart';
import '../../../../core/theme/joyn_colors.dart';
import '../models/quotation_returns_models.dart';

class QuotationsListScreen extends StatefulWidget {
  const QuotationsListScreen({super.key});

  @override
  State<QuotationsListScreen> createState() => _QuotationsListScreenState();
}

class _QuotationsListScreenState extends State<QuotationsListScreen> {
  bool _isLoading = true;
  List<QuotationModel> _quotations = [];
  double _totalAmount = 0.0;
  String _selectedFilter = 'ALL';

  final List<String> _filters = ['ALL', 'OPEN', 'ACCEPTED', 'CONVERTED'];

  @override
  void initState() {
    super.initState();
    _loadQuotations();
  }

  Future<void> _loadQuotations() async {
    setState(() => _isLoading = true);
    try {
      final statusParam = _selectedFilter == 'ALL' ? null : _selectedFilter;
      final res = await ApiService.getQuotations(status: statusParam, limit: 100);
      if (res['success'] == true) {
        final list = (res['quotations'] as List<dynamic>? ?? [])
            .map((q) => QuotationModel.fromJson(q as Map<String, dynamic>))
            .toList();
        setState(() {
          _quotations = list;
          _totalAmount = (res['totalAmount'] as num?)?.toDouble() ??
              list.fold(0.0, (sum, item) => sum + item.totalAmount);
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
      }
    } catch (_) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _convertToInvoice(QuotationModel q) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Convert to Tax Invoice', style: TextStyle(fontWeight: FontWeight.bold)),
        content: Text(
          'Convert quotation ${q.quotationNo} (${q.partyName}) for ₹${q.totalAmount.toStringAsFixed(2)} directly into a Tax Invoice?\n\n'
          '• Next invoice number will be generated automatically.\n'
          '• Item quantities will be atomically deducted from stock.\n'
          '• Quotation status will be locked to CONVERTED.',
          style: const TextStyle(fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: JoynColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Convert Now'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Converting quotation to invoice...'), duration: Duration(seconds: 1)),
    );

    final res = await ApiService.convertQuotationToInvoice(q.id);
    if (!mounted) return;
    if (res['success'] == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(res['message'] ?? 'Successfully converted to invoice!'),
          backgroundColor: Colors.green.shade700,
        ),
      );
      _loadQuotations();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(res['message'] ?? 'Failed to convert quotation.'),
          backgroundColor: Colors.red.shade700,
        ),
      );
    }
  }

  Future<void> _updateStatus(QuotationModel q, String newStatus) async {
    final res = await ApiService.updateQuotationStatus(q.id, newStatus);
    if (!mounted) return;
    if (res['success'] == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Status updated to $newStatus'), backgroundColor: Colors.teal),
      );
      _loadQuotations();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(res['message'] ?? 'Failed to update status'), backgroundColor: Colors.red),
      );
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toUpperCase()) {
      case 'OPEN':
      case 'DRAFT':
        return Colors.orange;
      case 'ACCEPTED':
        return Colors.blue;
      case 'CONVERTED':
        return Colors.green;
      case 'REJECTED':
      case 'EXPIRED':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final curFormat = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 2);

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text('Quotations & Estimates', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        backgroundColor: Colors.white,
        foregroundColor: JoynColors.primary,
        elevation: 0.5,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _loadQuotations,
            tooltip: 'Refresh',
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: JoynColors.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('New Estimate', style: TextStyle(fontWeight: FontWeight.bold)),
        onPressed: () async {
          final created = await context.push<bool>('/add-quotation');
          if (created == true) _loadQuotations();
        },
      ),
      body: Column(
        children: [
          // Summary Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Total Pipeline Value', style: TextStyle(color: Colors.grey, fontSize: 12)),
                    const SizedBox(height: 4),
                    Text(
                      curFormat.format(_totalAmount),
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: Color(0xFF1E293B)),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: JoynColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${_quotations.length} Estimates',
                    style: TextStyle(color: JoynColors.primary, fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                ),
              ],
            ),
          ),

          // Filter Tabs
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              children: _filters.map((f) {
                final isSelected = _selectedFilter == f;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(f),
                    selected: isSelected,
                    selectedColor: JoynColors.primary,
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.white : Colors.black87,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      fontSize: 12,
                    ),
                    backgroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                      side: BorderSide(color: isSelected ? JoynColors.primary : Colors.grey.shade300),
                    ),
                    onSelected: (val) {
                      if (val) {
                        setState(() => _selectedFilter = f);
                        _loadQuotations();
                      }
                    },
                  ),
                );
              }).toList(),
            ),
          ),

          // Main List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _quotations.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.request_quote_outlined, size: 64, color: Colors.grey.shade400),
                            const SizedBox(height: 12),
                            const Text(
                              'No Quotations Found',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black54),
                            ),
                            const SizedBox(height: 6),
                            const Text(
                              'Create quotations and convert them to invoices with 1 tap.',
                              style: TextStyle(color: Colors.grey, fontSize: 13),
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _loadQuotations,
                        child: ListView.separated(
                          padding: const EdgeInsets.fromLTRB(16, 6, 16, 80),
                          itemCount: _quotations.length,
                          separatorBuilder: (ctx, i) => const SizedBox(height: 10),
                          itemBuilder: (context, index) {
                            final q = _quotations[index];
                            final statusColor = _getStatusColor(q.status);
                            final isConverted = q.status.toUpperCase() == 'CONVERTED';

                            return Container(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(14),
                                boxShadow: [
                                  BoxSideShadow(
                                    color: Colors.black.withValues(alpha: 0.03),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                                border: Border.all(color: Colors.grey.shade200),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(14),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Row 1: Estimate No & Status
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Row(
                                          children: [
                                            Container(
                                              padding: const EdgeInsets.all(6),
                                              decoration: BoxDecoration(
                                                color: JoynColors.primary.withValues(alpha: 0.1),
                                                borderRadius: BorderRadius.circular(8),
                                              ),
                                              child: Icon(Icons.description_outlined, size: 16, color: JoynColors.primary),
                                            ),
                                            const SizedBox(width: 8),
                                            Text(
                                              q.quotationNo.startsWith('QT-') || q.quotationNo.startsWith('EST-') ? q.quotationNo : 'EST-${q.quotationNo}',
                                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                                            ),
                                          ],
                                        ),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: statusColor.withValues(alpha: 0.12),
                                            borderRadius: BorderRadius.circular(20),
                                            border: Border.all(color: statusColor.withValues(alpha: 0.3)),
                                          ),
                                          child: Text(
                                            q.status.toUpperCase(),
                                            style: TextStyle(
                                              color: statusColor,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 11,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 10),

                                    // Row 2: Customer Name & Amount
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                q.partyName,
                                                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                              if (q.partyPhone != null && q.partyPhone!.isNotEmpty)
                                                Text(
                                                  q.partyPhone!,
                                                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                                                ),
                                            ],
                                          ),
                                        ),
                                        Text(
                                          curFormat.format(q.totalAmount),
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                            color: Color(0xFF0F172A),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 10),

                                    // Items summary
                                    if (q.items.isNotEmpty)
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFF1F5F9),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Text(
                                          '${q.items.length} item(s): ${q.items.map((i) => "${i.name} (x${i.quantity.toInt()})").join(", ")}',
                                          style: const TextStyle(fontSize: 11.5, color: Color(0xFF475569)),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    const SizedBox(height: 12),

                                    // Action Buttons Row
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          'Created ${DateFormat('dd MMM yyyy').format(q.createdAt)}',
                                          style: const TextStyle(color: Colors.grey, fontSize: 11),
                                        ),
                                        Row(
                                          children: [
                                            if (!isConverted) ...[
                                              if (q.status.toUpperCase() == 'OPEN' || q.status.toUpperCase() == 'DRAFT')
                                                TextButton(
                                                  style: TextButton.styleFrom(
                                                    visualDensity: VisualDensity.compact,
                                                    foregroundColor: Colors.blue.shade700,
                                                  ),
                                                  onPressed: () => _updateStatus(q, 'ACCEPTED'),
                                                  child: const Text('Accept', style: TextStyle(fontSize: 12)),
                                                ),
                                              ElevatedButton.icon(
                                                style: ElevatedButton.styleFrom(
                                                  backgroundColor: Colors.teal.shade700,
                                                  foregroundColor: Colors.white,
                                                  visualDensity: VisualDensity.compact,
                                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                                ),
                                                icon: const Icon(Icons.receipt_long, size: 14),
                                                label: const Text('Convert to Invoice', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold)),
                                                onPressed: () => _convertToInvoice(q),
                                              ),
                                            ] else ...[
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                                decoration: BoxDecoration(
                                                  color: Colors.green.shade50,
                                                  borderRadius: BorderRadius.circular(6),
                                                ),
                                                child: Row(
                                                  children: [
                                                    Icon(Icons.check_circle_outline, size: 13, color: Colors.green.shade700),
                                                    const SizedBox(width: 4),
                                                    Text(
                                                      'Converted to Tax Invoice',
                                                      style: TextStyle(color: Colors.green.shade800, fontSize: 11, fontWeight: FontWeight.w600),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ],
                                          ],
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }
}

class BoxSideShadow extends BoxShadow {
  const BoxSideShadow({
    super.color,
    super.offset,
    super.blurRadius,
    super.spreadRadius,
  });
}
