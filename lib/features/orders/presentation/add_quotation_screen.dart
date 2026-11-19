import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/services/api_service.dart';
import '../../../../core/theme/joyn_colors.dart';

class AddQuotationScreen extends StatefulWidget {
  const AddQuotationScreen({super.key});

  @override
  State<AddQuotationScreen> createState() => _AddQuotationScreenState();
}

class _LineItem {
  final TextEditingController nameCtrl = TextEditingController();
  final TextEditingController qtyCtrl = TextEditingController(text: '1');
  final TextEditingController rateCtrl = TextEditingController(text: '0');
  final TextEditingController taxCtrl = TextEditingController(text: '18');

  double get quantity => double.tryParse(qtyCtrl.text) ?? 1.0;
  double get rate => double.tryParse(rateCtrl.text) ?? 0.0;
  double get taxPercent => double.tryParse(taxCtrl.text) ?? 0.0;

  double get lineSubtotal => quantity * rate;
  double get lineTax => lineSubtotal * (taxPercent / 100);
  double get lineTotal => lineSubtotal + lineTax;

  void dispose() {
    nameCtrl.dispose();
    qtyCtrl.dispose();
    rateCtrl.dispose();
    taxCtrl.dispose();
  }
}

class _AddQuotationScreenState extends State<AddQuotationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _customerNameCtrl = TextEditingController();
  final _customerPhoneCtrl = TextEditingController();
  final _notesCtrl = TextEditingController(text: 'Estimate valid for 15 days.');
  final _termsCtrl = TextEditingController(text: 'Payment: 50% advance, balance on delivery.');

  DateTime _expiryDate = DateTime.now().add(const Duration(days: 15));
  bool _isSaving = false;

  final List<_LineItem> _items = [];

  @override
  void initState() {
    super.initState();
    _addNewLineItem();
  }

  @override
  void dispose() {
    _customerNameCtrl.dispose();
    _customerPhoneCtrl.dispose();
    _notesCtrl.dispose();
    _termsCtrl.dispose();
    for (final itm in _items) {
      itm.dispose();
    }
    super.dispose();
  }

  void _addNewLineItem() {
    setState(() {
      _items.add(_LineItem());
    });
  }

  void _removeLineItem(int index) {
    if (_items.length <= 1) return;
    setState(() {
      final removed = _items.removeAt(index);
      removed.dispose();
    });
  }

  double get _computedSubtotal => _items.fold(0.0, (sum, i) => sum + i.lineSubtotal);
  double get _computedTax => _items.fold(0.0, (sum, i) => sum + i.lineTax);
  double get _computedTotal => _computedSubtotal + _computedTax;

  Future<void> _pickExpiryDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _expiryDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() => _expiryDate = picked);
    }
  }

  Future<void> _saveQuotation() async {
    if (!_formKey.currentState!.validate()) return;

    final validItems = _items.where((i) => i.nameCtrl.text.trim().isNotEmpty).toList();
    if (validItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add at least one line item.'), backgroundColor: Colors.red),
      );
      return;
    }

    setState(() => _isSaving = true);

    final payload = {
      'customerName': _customerNameCtrl.text.trim(),
      'customerPhone': _customerPhoneCtrl.text.trim(),
      'expiryDate': _expiryDate.toIso8601String().split('T')[0],
      'notes': _notesCtrl.text.trim(),
      'terms': _termsCtrl.text.trim(),
      'subtotal': _computedSubtotal,
      'taxAmount': _computedTax,
      'discountAmount': 0.0,
      'totalAmount': _computedTotal,
      'items': validItems.map((i) => {
        'name': i.nameCtrl.text.trim(),
        'quantity': i.quantity,
        'rate': i.rate,
        'taxPercent': i.taxPercent,
        'total': i.lineTotal,
      }).toList(),
    };

    final res = await ApiService.createQuotation(payload);
    setState(() => _isSaving = false);

    if (res['success'] == true) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(res['message'] ?? 'Quotation created successfully!'),
            backgroundColor: Colors.green.shade700,
          ),
        );
        Navigator.pop(context, true);
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(res['message'] ?? 'Failed to create quotation.'),
            backgroundColor: Colors.red.shade700,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final curFormat = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 2);

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text('Create Quotation / Estimate', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        backgroundColor: Colors.white,
        foregroundColor: JoynColors.primary,
        elevation: 0.5,
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: Colors.grey.shade200)),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Total Value', style: TextStyle(color: Colors.grey, fontSize: 12)),
                  Text(
                    curFormat.format(_computedTotal),
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Color(0xFF0F172A)),
                  ),
                ],
              ),
            ),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: JoynColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              icon: _isSaving
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Icon(Icons.check),
              label: Text(_isSaving ? 'Saving...' : 'Create Estimate', style: const TextStyle(fontWeight: FontWeight.bold)),
              onPressed: _isSaving ? null : _saveQuotation,
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Client details card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Client / Customer Details', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _customerNameCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Customer or Business Name *',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.person_outline),
                      ),
                      validator: (v) => (v == null || v.trim().isEmpty) ? 'Please enter customer name' : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _customerPhoneCtrl,
                      keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(
                        labelText: 'Phone Number (Optional)',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.phone_outlined),
                      ),
                    ),
                    const SizedBox(height: 12),
                    InkWell(
                      onTap: _pickExpiryDate,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade400),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.calendar_today, size: 18, color: Colors.grey),
                                const SizedBox(width: 8),
                                Text(
                                  'Valid Until: ${DateFormat('dd MMM yyyy').format(_expiryDate)}',
                                  style: const TextStyle(fontSize: 14),
                                ),
                              ],
                            ),
                            const Text('Change', style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold, fontSize: 12)),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Items Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Estimate Line Items', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  TextButton.icon(
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('Add Item'),
                    onPressed: _addNewLineItem,
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Dynamic Items List
              ..._items.asMap().entries.map((entry) {
                final idx = entry.key;
                final item = entry.value;

                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: item.nameCtrl,
                              decoration: InputDecoration(
                                labelText: 'Item Name #${idx + 1} *',
                                border: const OutlineInputBorder(),
                                isDense: true,
                              ),
                              onChanged: (_) => setState(() {}),
                              validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                            ),
                          ),
                          if (_items.length > 1)
                            IconButton(
                              icon: const Icon(Icons.delete_outline, color: Colors.red),
                              onPressed: () => _removeLineItem(idx),
                            ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: item.qtyCtrl,
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              decoration: const InputDecoration(
                                labelText: 'Qty',
                                border: OutlineInputBorder(),
                                isDense: true,
                              ),
                              onChanged: (_) => setState(() {}),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: TextFormField(
                              controller: item.rateCtrl,
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              decoration: const InputDecoration(
                                labelText: 'Rate (₹)',
                                border: OutlineInputBorder(),
                                isDense: true,
                              ),
                              onChanged: (_) => setState(() {}),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: TextFormField(
                              controller: item.taxCtrl,
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              decoration: const InputDecoration(
                                labelText: 'Tax %',
                                border: OutlineInputBorder(),
                                isDense: true,
                              ),
                              onChanged: (_) => setState(() {}),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Text(
                            'Item Total: ${curFormat.format(item.lineTotal)}',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF0F172A)),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              }),

              // Terms & Notes
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Notes & Terms', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: _notesCtrl,
                      decoration: const InputDecoration(labelText: 'Notes', border: OutlineInputBorder()),
                    ),
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: _termsCtrl,
                      decoration: const InputDecoration(labelText: 'Payment Terms & Conditions', border: OutlineInputBorder()),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 80),
            ],
          ),
        ),
      ),
    );
  }
}

