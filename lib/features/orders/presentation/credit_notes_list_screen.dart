import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/services/api_service.dart';
import '../../../../core/theme/joyn_colors.dart';
import '../models/quotation_returns_models.dart';

class CreditNotesListScreen extends StatefulWidget {
  const CreditNotesListScreen({super.key});

  @override
  State<CreditNotesListScreen> createState() => _CreditNotesListScreenState();
}

class _CreditNotesListScreenState extends State<CreditNotesListScreen> {
  bool _isLoading = true;
  List<CreditNoteModel> _creditNotes = [];
  double _totalReturnAmount = 0.0;

  @override
  void initState() {
    super.initState();
    _loadCreditNotes();
  }

  Future<void> _loadCreditNotes() async {
    setState(() => _isLoading = true);
    try {
      final res = await ApiService.getCreditNotes(limit: 100);
      if (res['success'] == true) {
        final list = (res['creditNotes'] as List<dynamic>? ?? [])
            .map((cn) => CreditNoteModel.fromJson(cn as Map<String, dynamic>))
            .toList();
        setState(() {
          _creditNotes = list;
          _totalReturnAmount = (res['totalReturnAmount'] as num?)?.toDouble() ??
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

  void _showAddCreditNoteDialog() {
    final customerCtrl = TextEditingController();
    final invoiceNoCtrl = TextEditingController();
    final itemNameCtrl = TextEditingController();
    final qtyCtrl = TextEditingController(text: '1');
    final rateCtrl = TextEditingController(text: '0');
    final reasonCtrl = TextEditingController(text: 'Customer Return - Damaged / Defective');
    String refundMode = 'CREDIT';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) {
          final qty = double.tryParse(qtyCtrl.text) ?? 1.0;
          final rate = double.tryParse(rateCtrl.text) ?? 0.0;
          final computedTotal = qty * rate;

          return Padding(
            padding: EdgeInsets.only(
              left: 20,
              right: 20,
              top: 20,
              bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Record Sales Return (Credit Note)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(ctx)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: customerCtrl,
                    decoration: const InputDecoration(labelText: 'Customer Name *', border: OutlineInputBorder()),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: invoiceNoCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Original Invoice # (Optional)', border: OutlineInputBorder()),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: itemNameCtrl,
                    decoration: const InputDecoration(labelText: 'Returned Item Name *', border: OutlineInputBorder()),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: qtyCtrl,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          decoration: const InputDecoration(labelText: 'Return Qty', border: OutlineInputBorder()),
                          onChanged: (_) => setModalState(() {}),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextField(
                          controller: rateCtrl,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          decoration: const InputDecoration(labelText: 'Rate (₹)', border: OutlineInputBorder()),
                          onChanged: (_) => setModalState(() {}),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: reasonCtrl,
                    decoration: const InputDecoration(labelText: 'Return Reason', border: OutlineInputBorder()),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Text('Refund Method: ', style: TextStyle(fontWeight: FontWeight.w600)),
                      ChoiceChip(
                        label: const Text('Party Credit'),
                        selected: refundMode == 'CREDIT',
                        onSelected: (val) => setModalState(() => refundMode = 'CREDIT'),
                      ),
                      const SizedBox(width: 8),
                      ChoiceChip(
                        label: const Text('Cash Refund'),
                        selected: refundMode == 'CASH',
                        onSelected: (val) => setModalState(() => refundMode = 'CASH'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Total Credit: ₹${computedTotal.toStringAsFixed(2)}',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.indigo),
                      ),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: JoynColors.primary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        onPressed: () async {
                          if (customerCtrl.text.trim().isEmpty || itemNameCtrl.text.trim().isEmpty || computedTotal <= 0) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Please fill required fields and valid total.')),
                            );
                            return;
                          }
                          final scaffoldMessenger = ScaffoldMessenger.of(context);
                          Navigator.pop(ctx);
                          final res = await ApiService.createCreditNote({
                            'customerName': customerCtrl.text.trim(),
                            'originalInvoiceNo': invoiceNoCtrl.text.trim().isNotEmpty ? invoiceNoCtrl.text.trim() : null,
                            'reason': reasonCtrl.text.trim(),
                            'refundMode': refundMode,
                            'returnAmount': computedTotal,
                            'totalAmount': computedTotal,
                            'items': [
                              {
                                'name': itemNameCtrl.text.trim(),
                                'quantity': qty,
                                'rate': rate,
                                'taxPercent': 0,
                                'total': computedTotal,
                              }
                            ],
                          });
                          if (!mounted) return;
                          if (res['success'] == true) {
                            scaffoldMessenger.showSnackBar(
                              SnackBar(
                                content: Text(res['message'] ?? 'Credit Note recorded!'),
                                backgroundColor: Colors.green.shade700,
                              ),
                            );
                            _loadCreditNotes();
                          } else {
                            scaffoldMessenger.showSnackBar(
                              SnackBar(
                                content: Text(res['message'] ?? 'Failed to record credit note.'),
                                backgroundColor: Colors.red.shade700,
                              ),
                            );
                          }
                        },
                        child: const Text('Record Return'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final curFormat = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 2);

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text('Sales Returns & Credit Notes', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        backgroundColor: Colors.white,
        foregroundColor: JoynColors.primary,
        elevation: 0.5,
        actions: [
          IconButton(icon: const Icon(Icons.refresh_rounded), onPressed: _loadCreditNotes),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: Colors.indigo.shade700,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.assignment_return_outlined),
        label: const Text('Record Return', style: TextStyle(fontWeight: FontWeight.bold)),
        onPressed: _showAddCreditNoteDialog,
      ),
      body: Column(
        children: [
          // Header summary
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
                    const Text('Total Returns Value', style: TextStyle(color: Colors.grey, fontSize: 12)),
                    const SizedBox(height: 4),
                    Text(
                      curFormat.format(_totalReturnAmount),
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: Color(0xFF1E293B)),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.indigo.shade50,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${_creditNotes.length} Notes (Stock Restored)',
                    style: TextStyle(color: Colors.indigo.shade800, fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                ),
              ],
            ),
          ),

          // Main list
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _creditNotes.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.assignment_return_outlined, size: 64, color: Colors.grey.shade400),
                            const SizedBox(height: 12),
                            const Text('No Sales Returns Recorded', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black54)),
                            const SizedBox(height: 6),
                            const Text('Returned items are automatically added back into inventory.', style: TextStyle(color: Colors.grey, fontSize: 13)),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _loadCreditNotes,
                        child: ListView.separated(
                          padding: const EdgeInsets.fromLTRB(16, 12, 16, 80),
                          itemCount: _creditNotes.length,
                          separatorBuilder: (ctx, i) => const SizedBox(height: 10),
                          itemBuilder: (context, index) {
                            final cn = _creditNotes[index];

                            return Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(color: Colors.grey.shade200),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Row(
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.all(6),
                                            decoration: BoxDecoration(
                                              color: Colors.indigo.shade50,
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                            child: Icon(Icons.assignment_return, size: 16, color: Colors.indigo.shade700),
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            cn.noteNo.startsWith('CN-') ? cn.noteNo : 'CN-${cn.noteNo}',
                                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                                          ),
                                        ],
                                      ),
                                      Text(
                                        curFormat.format(cn.totalAmount),
                                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.red.shade700),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        cn.partyName,
                                        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                                      ),
                                      if (cn.invoiceNo != null)
                                        Text('Inv #${cn.invoiceNo}', style: const TextStyle(color: Colors.grey, fontSize: 12)),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFF8FAFC),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      'Reason: ${cn.reason}',
                                      style: const TextStyle(color: Color(0xFF64748B), fontSize: 12),
                                    ),
                                  ),
                                  if (cn.items.isNotEmpty) ...[
                                    const SizedBox(height: 6),
                                    Text(
                                      'Restored: ${cn.items.map((i) => "${i.name} (x${i.quantity.toInt()})").join(", ")}',
                                      style: TextStyle(color: Colors.green.shade800, fontSize: 11.5, fontWeight: FontWeight.w500),
                                    ),
                                  ],
                                  const SizedBox(height: 8),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        DateFormat('dd MMM yyyy').format(cn.noteDate),
                                        style: const TextStyle(color: Colors.grey, fontSize: 11),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: Colors.green.shade50,
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        child: Text(
                                          'Stock Restored ✓',
                                          style: TextStyle(color: Colors.green.shade700, fontSize: 11, fontWeight: FontWeight.bold),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
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
