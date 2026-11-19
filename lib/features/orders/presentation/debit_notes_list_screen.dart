import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/services/api_service.dart';
import '../../../../core/theme/joyn_colors.dart';
import '../models/quotation_returns_models.dart';

class DebitNotesListScreen extends StatefulWidget {
  const DebitNotesListScreen({super.key});

  @override
  State<DebitNotesListScreen> createState() => _DebitNotesListScreenState();
}

class _DebitNotesListScreenState extends State<DebitNotesListScreen> {
  bool _isLoading = true;
  List<DebitNoteModel> _debitNotes = [];
  double _totalReturnAmount = 0.0;

  @override
  void initState() {
    super.initState();
    _loadDebitNotes();
  }

  Future<void> _loadDebitNotes() async {
    setState(() => _isLoading = true);
    try {
      final res = await ApiService.getDebitNotes(limit: 100);
      if (res['success'] == true) {
        final list = (res['debitNotes'] as List<dynamic>? ?? [])
            .map((dn) => DebitNoteModel.fromJson(dn as Map<String, dynamic>))
            .toList();
        setState(() {
          _debitNotes = list;
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

  void _showAddDebitNoteDialog() {
    final supplierCtrl = TextEditingController();
    final orderNoCtrl = TextEditingController();
    final itemNameCtrl = TextEditingController();
    final qtyCtrl = TextEditingController(text: '1');
    final rateCtrl = TextEditingController(text: '0');
    final reasonCtrl = TextEditingController(text: 'Damaged / Defective Goods Returned to Supplier');

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
                      const Text('Record Purchase Return (Debit Note)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(ctx)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: supplierCtrl,
                    decoration: const InputDecoration(labelText: 'Supplier Name *', border: OutlineInputBorder()),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: orderNoCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Original Purchase Order # (Optional)', border: OutlineInputBorder()),
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
                          decoration: const InputDecoration(labelText: 'Purchase Rate (₹)', border: OutlineInputBorder()),
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
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Total Debit: ₹${computedTotal.toStringAsFixed(2)}',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.deepOrange),
                      ),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.deepOrange.shade700,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        onPressed: () async {
                          if (supplierCtrl.text.trim().isEmpty || itemNameCtrl.text.trim().isEmpty || computedTotal <= 0) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Please fill required fields and valid total.')),
                            );
                            return;
                          }
                          final scaffoldMessenger = ScaffoldMessenger.of(context);
                          Navigator.pop(ctx);
                          final res = await ApiService.createDebitNote({
                            'supplierName': supplierCtrl.text.trim(),
                            'originalOrderNo': orderNoCtrl.text.trim().isNotEmpty ? orderNoCtrl.text.trim() : null,
                            'reason': reasonCtrl.text.trim(),
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
                                content: Text(res['message'] ?? 'Debit Note recorded!'),
                                backgroundColor: Colors.green.shade700,
                              ),
                            );
                            _loadDebitNotes();
                          } else {
                            scaffoldMessenger.showSnackBar(
                              SnackBar(
                                content: Text(res['message'] ?? 'Failed to record debit note.'),
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
        title: const Text('Purchase Returns & Debit Notes', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        backgroundColor: Colors.white,
        foregroundColor: JoynColors.primary,
        elevation: 0.5,
        actions: [
          IconButton(icon: const Icon(Icons.refresh_rounded), onPressed: _loadDebitNotes),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: Colors.deepOrange.shade700,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.outbox_outlined),
        label: const Text('Record Return', style: TextStyle(fontWeight: FontWeight.bold)),
        onPressed: _showAddDebitNoteDialog,
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
                    const Text('Total Supplier Returns', style: TextStyle(color: Colors.grey, fontSize: 12)),
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
                    color: Colors.deepOrange.shade50,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${_debitNotes.length} Notes (Stock Deducted)',
                    style: TextStyle(color: Colors.deepOrange.shade800, fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                ),
              ],
            ),
          ),

          // Main list
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _debitNotes.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.outbox_outlined, size: 64, color: Colors.grey.shade400),
                            const SizedBox(height: 12),
                            const Text('No Purchase Returns Recorded', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black54)),
                            const SizedBox(height: 6),
                            const Text('Returned items are automatically deducted from inventory.', style: TextStyle(color: Colors.grey, fontSize: 13)),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _loadDebitNotes,
                        child: ListView.separated(
                          padding: const EdgeInsets.fromLTRB(16, 12, 16, 80),
                          itemCount: _debitNotes.length,
                          separatorBuilder: (ctx, i) => const SizedBox(height: 10),
                          itemBuilder: (context, index) {
                            final dn = _debitNotes[index];

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
                                              color: Colors.deepOrange.shade50,
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                            child: Icon(Icons.outbox_rounded, size: 16, color: Colors.deepOrange.shade700),
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            dn.noteNo.startsWith('DN-') ? dn.noteNo : 'DN-${dn.noteNo}',
                                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                                          ),
                                        ],
                                      ),
                                      Text(
                                        curFormat.format(dn.totalAmount),
                                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.deepOrange.shade800),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        dn.supplierName,
                                        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                                      ),
                                      if (dn.purchaseNo != null)
                                        Text('PO #${dn.purchaseNo}', style: const TextStyle(color: Colors.grey, fontSize: 12)),
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
                                      'Reason: ${dn.reason}',
                                      style: const TextStyle(color: Color(0xFF64748B), fontSize: 12),
                                    ),
                                  ),
                                  if (dn.items.isNotEmpty) ...[
                                    const SizedBox(height: 6),
                                    Text(
                                      'Deducted: ${dn.items.map((i) => "${i.name} (x${i.quantity.toInt()})").join(", ")}',
                                      style: TextStyle(color: Colors.deepOrange.shade800, fontSize: 11.5, fontWeight: FontWeight.w500),
                                    ),
                                  ],
                                  const SizedBox(height: 8),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        DateFormat('dd MMM yyyy').format(dn.noteDate),
                                        style: const TextStyle(color: Colors.grey, fontSize: 11),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: Colors.deepOrange.shade50,
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        child: Text(
                                          'Stock Deducted ✓',
                                          style: TextStyle(color: Colors.deepOrange.shade700, fontSize: 11, fontWeight: FontWeight.bold),
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
