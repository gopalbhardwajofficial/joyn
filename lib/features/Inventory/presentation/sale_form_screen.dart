// lib/features/orders/presentation/sale_form_screen.dart
//
// One screen for both "Add Sale" and "View/Edit Sale" — matches the
// screenshots: Credit/Cash toggle (add mode only) top-right of the
// AppBar, Invoice No / Date row, Customer Name*/Phone, optional items,
// Total Amount / Received / Balance Due, Payment Type, State of
// Supply, Description + attachment slot, Add Document, Terms &
// Conditions, and a bottom bar that is Save & New / Save when adding,
// or Delete / Edit when viewing an existing sale.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/theme/joyn_colors.dart';
import '../../../core/theme/joyn_typography.dart';
import '../../orders/models/sales_models.dart';
import '../../orders/data/sales_repository.dart';

const List<String> _kPaymentTypes = ['Cash', 'UPI', 'Card', 'Bank Transfer', 'Cheque'];

const List<String> _kStates = [
  'Andaman & Nicobar Islands', 'Andhra Pradesh', 'Arunachal Pradesh', 'Assam', 'Bihar',
  'Chandigarh', 'Chhattisgarh', 'Delhi', 'Goa', 'Gujarat', 'Haryana', 'Himachal Pradesh',
  'Jammu & Kashmir', 'Jharkhand', 'Karnataka', 'Kerala', 'Madhya Pradesh', 'Maharashtra',
  'Manipur', 'Meghalaya', 'Mizoram', 'Nagaland', 'Odisha', 'Puducherry', 'Punjab',
  'Rajasthan', 'Sikkim', 'Tamil Nadu', 'Telangana', 'Tripura', 'Uttar Pradesh',
  'Uttarakhand', 'West Bengal',
];

class SaleFormScreen extends StatefulWidget {
  const SaleFormScreen({super.key, required this.party, this.existingSale});

  final PartyModel party;
  final SaleOrderModel? existingSale;

  @override
  State<SaleFormScreen> createState() => _SaleFormScreenState();
}

class _SaleFormScreenState extends State<SaleFormScreen> {
  final SalesRepository _salesRepository = SalesRepository();

  bool get _isEditMode => widget.existingSale != null;

  late final _customerNameController = TextEditingController(text: widget.existingSale?.customerName ?? widget.party.name);
  late final _customerPhoneController = TextEditingController(text: widget.existingSale?.customerPhone ?? widget.party.contactNumber);
  late final _totalAmountController = TextEditingController(text: widget.existingSale != null ? widget.existingSale!.totalAmount.toStringAsFixed(2) : '');
  late final _receivedController = TextEditingController(text: widget.existingSale != null ? widget.existingSale!.receivedAmount.toStringAsFixed(2) : '');
  late final _descriptionController = TextEditingController(text: widget.existingSale?.description ?? '');
  late final _termsController = TextEditingController(text: widget.existingSale?.termsAndConditions ?? '');

  int _invoiceNo = 0;
  String _date = '';
  String _paymentMode = 'Credit'; // Credit | Cash toggle (add mode)
  bool _receivedChecked = false;
  String _paymentType = _kPaymentTypes.first;
  String? _stateOfSupply;
  List<Map<String, dynamic>> _items = [];
  bool _termsExpanded = false;
  bool _isLoadingInvoiceNo = true;

  double get _totalAmount => double.tryParse(_totalAmountController.text) ?? 0;
  double get _receivedAmount => _receivedChecked ? (double.tryParse(_receivedController.text) ?? 0) : 0;
  double get _balanceDue => (_totalAmount - _receivedAmount).clamp(0, double.infinity);

  @override
  void initState() {
    super.initState();
    if (_isEditMode) {
      final s = widget.existingSale!;
      _invoiceNo = s.invoiceNo;
      _date = s.date;
      _paymentMode = s.paymentMode;
      _paymentType = s.paymentType;
      _stateOfSupply = s.stateOfSupply.isNotEmpty ? s.stateOfSupply : null;
      _items = List<Map<String, dynamic>>.from(s.items);
      _receivedChecked = s.receivedAmount > 0;
      _isLoadingInvoiceNo = false;
    } else {
      final now = DateTime.now();
      _date = '${now.day.toString().padLeft(2, '0')}/${now.month.toString().padLeft(2, '0')}/${now.year}';
      _loadNextInvoiceNo();
    }
  }

  Future<void> _loadNextInvoiceNo() async {
    final next = await _salesRepository.getNextInvoiceNo();
    if (!mounted) return;
    setState(() {
      _invoiceNo = next;
      _isLoadingInvoiceNo = false;
    });
  }

  @override
  void dispose() {
    _customerNameController.dispose();
    _customerPhoneController.dispose();
    _totalAmountController.dispose();
    _receivedController.dispose();
    _descriptionController.dispose();
    _termsController.dispose();
    super.dispose();
  }

  // ---- Actions -------------------------------------------------------

  Future<void> _pickDate() async {
    final parts = _date.split('/');
    DateTime initial = DateTime.now();
    if (parts.length == 3) {
      initial = DateTime(int.tryParse(parts[2]) ?? initial.year, int.tryParse(parts[1]) ?? initial.month, int.tryParse(parts[0]) ?? initial.day);
    }
    final picked = await showDatePicker(context: context, initialDate: initial, firstDate: DateTime(2000), lastDate: DateTime(2035));
    if (picked != null) {
      setState(() => _date = '${picked.day.toString().padLeft(2, '0')}/${picked.month.toString().padLeft(2, '0')}/${picked.year}');
    }
  }

  Future<void> _editInvoiceNo() async {
    final controller = TextEditingController(text: _invoiceNo.toString());
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Invoice Number'),
        content: TextField(controller: controller, keyboardType: TextInputType.number),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(context, controller.text.trim()), child: const Text('Save')),
        ],
      ),
    );
    if (result != null && result.isNotEmpty) setState(() => _invoiceNo = int.tryParse(result) ?? _invoiceNo);
  }

  Future<void> _addPaymentType() async {
    final controller = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('New Payment Type'),
        content: TextField(controller: controller, decoration: const InputDecoration(hintText: 'e.g. Wallet')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(context, controller.text.trim()), child: const Text('Add')),
        ],
      ),
    );
    if (result != null && result.isNotEmpty) setState(() => _paymentType = result);
  }

  Future<void> _showStatePicker() async {
    final picked = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.white,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (context) => SafeArea(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.6),
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: _kStates.length,
            itemBuilder: (context, index) => ListTile(
              title: Text(_kStates[index]),
              onTap: () => Navigator.pop(context, _kStates[index]),
            ),
          ),
        ),
      ),
    );
    if (picked != null) setState(() => _stateOfSupply = picked);
  }

  Future<void> _addItemsDialog() async {
    final nameController = TextEditingController();
    final qtyController = TextEditingController(text: '1');
    final priceController = TextEditingController();

    final item = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Add Item'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nameController, decoration: const InputDecoration(labelText: 'Item name')),
            TextField(controller: qtyController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Qty')),
            TextField(controller: priceController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Price')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              final qty = double.tryParse(qtyController.text) ?? 1;
              final price = double.tryParse(priceController.text) ?? 0;
              Navigator.pop(context, {
                'name': nameController.text.trim(),
                'qty': qty,
                'price': price,
                'amount': qty * price,
              });
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );

    if (item != null && (item['name'] as String).isNotEmpty) {
      setState(() {
        _items.add(item);
        final sum = _items.fold<double>(0, (a, b) => a + (b['amount'] as double));
        _totalAmountController.text = sum.toStringAsFixed(2);
      });
    }
  }

  Future<void> _deleteSale() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Text('Delete Sale?'),
        content: const Text('This cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: Text('Delete', style: TextStyle(color: JoynColors.error))),
        ],
      ),
    );
    if (confirmed == true) {
      await _salesRepository.deleteSaleOrder(widget.existingSale!.id);
      if (mounted) Navigator.of(context).pop(true);
    }
  }

  Future<void> _save({bool andNew = false}) async {
    if (_customerNameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Customer Name is required')));
      return;
    }
    if (_totalAmount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Enter a total amount')));
      return;
    }

    final sale = SaleOrderModel(
      id: widget.existingSale?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
      invoiceNo: _invoiceNo,
      date: _date,
      paymentMode: _paymentMode,
      partyId: widget.party.id,
      customerName: _customerNameController.text.trim(),
      customerPhone: _customerPhoneController.text.trim(),
      items: _items,
      totalAmount: _totalAmount,
      receivedAmount: _receivedAmount,
      paymentType: _paymentType,
      stateOfSupply: _stateOfSupply ?? '',
      description: _descriptionController.text.trim(),
      termsAndConditions: _termsController.text.trim(),
      createdAt: widget.existingSale?.createdAt ?? DateTime.now(),
    );

    if (_isEditMode) {
      await _salesRepository.updateSaleOrder(sale);
    } else {
      await _salesRepository.insertSaleOrder(sale);
    }

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(_isEditMode ? 'Sale updated!' : 'Sale saved!'),
        backgroundColor: JoynColors.primary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );

    if (andNew) {
      setState(() {
        _totalAmountController.clear();
        _receivedController.clear();
        _receivedChecked = false;
        _items = [];
        _descriptionController.clear();
      });
      _loadNextInvoiceNo();
      return;
    }

    Navigator.of(context).pop(true);
  }

  // ---- Build -----------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: JoynColors.background,
      appBar: AppBar(
        backgroundColor: JoynColors.background,
        elevation: 0,
        leading: IconButton(icon: const Icon(Icons.arrow_back_rounded), onPressed: () => Navigator.of(context).pop()),
        title: Text('Sale', style: JoynTypography.titleMedium.copyWith(fontSize: 18, fontWeight: FontWeight.w800)),
        actions: [
          if (!_isEditMode) _buildCreditCashToggle(),
          IconButton(icon: const Icon(Icons.ios_share_rounded), onPressed: () {}),
          IconButton(icon: const Icon(Icons.more_vert_rounded), onPressed: () {}),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
          children: [
            _buildTopRow(),
            const SizedBox(height: 14),
            _buildPartyFieldsCard(),
            const SizedBox(height: 14),
            _buildTotalsCard(),
            const SizedBox(height: 14),
            _buildPaymentTypeRow(),
            const SizedBox(height: 14),
            _buildDropdownField(label: 'State of Supply', value: _stateOfSupply ?? 'Select State', onTap: _showStatePicker),
            const SizedBox(height: 14),
            _buildDescriptionRow(),
            const SizedBox(height: 14),
            _buildDocumentField(),
            const SizedBox(height: 14),
            _buildTermsField(),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomBar(),
    );
  }

  Widget _buildCreditCashToggle() {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(color: JoynColors.chipBackground, borderRadius: BorderRadius.circular(20)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _togglePill('Credit', _paymentMode == 'Credit', () => setState(() => _paymentMode = 'Credit')),
          _togglePill('Cash', _paymentMode == 'Cash', () => setState(() => _paymentMode = 'Cash')),
        ],
      ),
    );
  }

  Widget _togglePill(String label, bool selected, VoidCallback onTap) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(color: selected ? JoynColors.success : Colors.transparent, borderRadius: BorderRadius.circular(18)),
        child: Text(label, style: JoynTypography.caption.copyWith(fontSize: 12.5, fontWeight: FontWeight.w700, color: selected ? Colors.white : JoynColors.secondaryText)),
      ),
    );
  }

  Widget _buildTopRow() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: JoynColors.border, width: 1.2)),
      child: Row(
        children: [
          Expanded(
            child: InkWell(
              onTap: _editInvoiceNo,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Invoice No.', style: JoynTypography.caption.copyWith(fontSize: 11.5, color: JoynColors.secondaryText)),
                  const SizedBox(height: 2),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(_isLoadingInvoiceNo ? '...' : '$_invoiceNo', style: JoynTypography.bodyLarge.copyWith(fontSize: 15, fontWeight: FontWeight.w700)),
                      const Icon(Icons.keyboard_arrow_down_rounded, size: 18, color: JoynColors.secondaryText),
                    ],
                  ),
                ],
              ),
            ),
          ),
          Container(width: 1, height: 32, color: JoynColors.border),
          Expanded(
            child: InkWell(
              onTap: _pickDate,
              child: Padding(
                padding: const EdgeInsets.only(left: 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Date', style: JoynTypography.caption.copyWith(fontSize: 11.5, color: JoynColors.secondaryText)),
                    const SizedBox(height: 2),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(_date, style: JoynTypography.bodyLarge.copyWith(fontSize: 15, fontWeight: FontWeight.w700)),
                        const Icon(Icons.keyboard_arrow_down_rounded, size: 18, color: JoynColors.secondaryText),
                      ],
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

  Widget _buildPartyFieldsCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: JoynColors.border, width: 1.2)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Align(
            alignment: Alignment.centerRight,
            child: Text('Party Balance: ₹0.00', style: JoynTypography.caption.copyWith(fontSize: 12, color: JoynColors.success, fontWeight: FontWeight.w700)),
          ),
          const SizedBox(height: 8),
          _labeledField(label: 'Customer Name *', controller: _customerNameController),
          const SizedBox(height: 14),
          _labeledField(label: 'Phone Number', controller: _customerPhoneController, keyboardType: TextInputType.phone),
          const SizedBox(height: 14),
          InkWell(
            onTap: _addItemsDialog,
            borderRadius: BorderRadius.circular(14),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 13),
              decoration: BoxDecoration(borderRadius: BorderRadius.circular(14), border: Border.all(color: JoynColors.primary.withValues(alpha: 0.35))),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.add_circle_rounded, size: 18, color: JoynColors.primary),
                  const SizedBox(width: 8),
                  Text('Add Items (Optional)', style: JoynTypography.bodyMedium.copyWith(fontSize: 13.5, fontWeight: FontWeight.w700, color: JoynColors.primary)),
                ],
              ),
            ),
          ),
          if (_items.isNotEmpty) ...[
            const SizedBox(height: 10),
            ..._items.map((item) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  Expanded(child: Text('${item['name']} x${item['qty']}', style: JoynTypography.bodyMedium.copyWith(fontSize: 13))),
                  Text('₹${(item['amount'] as double).toStringAsFixed(2)}', style: JoynTypography.bodyMedium.copyWith(fontSize: 13, fontWeight: FontWeight.w700)),
                ],
              ),
            )),
          ],
        ],
      ),
    );
  }

  Widget _buildTotalsCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: JoynColors.chipBackground, borderRadius: BorderRadius.circular(16)),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Total Amount', style: JoynTypography.bodyLarge.copyWith(fontSize: 14.5, fontWeight: FontWeight.w700)),
              SizedBox(
                width: 130,
                child: TextField(
                  controller: _totalAmountController,
                  enabled: _items.isEmpty,
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.right,
                  onChanged: (_) => setState(() {}),
                  decoration: const InputDecoration(prefixText: '₹ ', border: InputBorder.none, isDense: true),
                  style: JoynTypography.bodyLarge.copyWith(fontSize: 16, fontWeight: FontWeight.w800),
                ),
              ),
            ],
          ),
          const Divider(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Checkbox(
                    value: _receivedChecked,
                    activeColor: JoynColors.primary,
                    onChanged: (v) => setState(() => _receivedChecked = v ?? false),
                  ),
                  Text('Received', style: JoynTypography.bodyLarge.copyWith(fontSize: 14.5, fontWeight: FontWeight.w600)),
                ],
              ),
              SizedBox(
                width: 130,
                child: TextField(
                  controller: _receivedController,
                  enabled: _receivedChecked,
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.right,
                  onChanged: (_) => setState(() {}),
                  decoration: const InputDecoration(prefixText: '₹ ', border: InputBorder.none, isDense: true),
                  style: JoynTypography.bodyLarge.copyWith(fontSize: 15, fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
          const Divider(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Balance Due', style: JoynTypography.bodyLarge.copyWith(fontSize: 14.5, fontWeight: FontWeight.w700, color: JoynColors.success)),
              Text('₹${_balanceDue.toStringAsFixed(2)}', style: JoynTypography.titleMedium.copyWith(fontSize: 17, fontWeight: FontWeight.w800, color: JoynColors.success)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentTypeRow() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Payment Type', style: JoynTypography.bodyMedium.copyWith(fontSize: 13, fontWeight: FontWeight.w700, color: JoynColors.secondaryText)),
              const SizedBox(height: 6),
              Container(
                height: 50,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), border: Border.all(color: JoynColors.border, width: 1.2)),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _paymentType,
                    isExpanded: true,
                    icon: const Icon(Icons.keyboard_arrow_down_rounded),
                    onChanged: (val) {
                      if (val != null) setState(() => _paymentType = val);
                    },
                    items: _kPaymentTypes.map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
                  ),
                ),
              ),
              const SizedBox(height: 6),
              InkWell(
                onTap: _addPaymentType,
                child: Text('+ Add Payment Type', style: JoynTypography.caption.copyWith(fontSize: 12, fontWeight: FontWeight.w700, color: JoynColors.primary)),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDropdownField({required String label, required String value, required VoidCallback onTap}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: JoynTypography.bodyMedium.copyWith(fontSize: 13, fontWeight: FontWeight.w700, color: JoynColors.secondaryText)),
        const SizedBox(height: 6),
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Container(
            height: 50,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), border: Border.all(color: JoynColors.border, width: 1.2)),
            child: Row(
              children: [
                Expanded(child: Text(value, style: JoynTypography.bodyLarge.copyWith(fontSize: 14.5, fontWeight: FontWeight.w600))),
                const Icon(Icons.keyboard_arrow_down_rounded),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDescriptionRow() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Description', style: JoynTypography.bodyMedium.copyWith(fontSize: 13, fontWeight: FontWeight.w700, color: JoynColors.secondaryText)),
              const SizedBox(height: 6),
              Container(
                constraints: const BoxConstraints(minHeight: 80),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), border: Border.all(color: JoynColors.border, width: 1.2)),
                child: TextField(
                  controller: _descriptionController,
                  maxLines: 3,
                  decoration: const InputDecoration(hintText: 'Add Note', border: InputBorder.none, isDense: true),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 10),
        Container(
          width: 70,
          height: 92,
          margin: const EdgeInsets.only(top: 28),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), border: Border.all(color: JoynColors.border, width: 1.2)),
          child: Stack(
            alignment: Alignment.center,
            children: [
              const Icon(Icons.image_outlined, size: 26, color: JoynColors.secondaryText),
              Positioned(
                bottom: 6,
                right: 6,
                child: Container(
                  padding: const EdgeInsets.all(3),
                  decoration: const BoxDecoration(color: JoynColors.primary, shape: BoxShape.circle),
                  child: const Icon(Icons.add_rounded, size: 12, color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDocumentField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 20),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), border: Border.all(color: JoynColors.border, width: 1.2)),
          child: Column(
            children: [
              const Icon(Icons.insert_drive_file_outlined, size: 22, color: JoynColors.secondaryText),
              const SizedBox(height: 6),
              Text('Add Document', style: JoynTypography.bodyMedium.copyWith(fontSize: 13, color: JoynColors.secondaryText)),
            ],
          ),
        ),
        const SizedBox(height: 4),
        Text('Internet is required to upload', style: JoynTypography.caption.copyWith(fontSize: 10.5, color: JoynColors.secondaryText.withValues(alpha: 0.7))),
      ],
    );
  }

  Widget _buildTermsField() {
    return Container(
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), border: Border.all(color: JoynColors.border, width: 1.2)),
      child: Column(
        children: [
          InkWell(
            onTap: () => setState(() => _termsExpanded = !_termsExpanded),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Terms & Conditions', style: JoynTypography.bodyLarge.copyWith(fontSize: 14.5, fontWeight: FontWeight.w700)),
                  Icon(_termsExpanded ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded),
                ],
              ),
            ),
          ),
          if (_termsExpanded)
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
              child: TextField(
                controller: _termsController,
                maxLines: 3,
                decoration: const InputDecoration(hintText: 'Add terms & conditions', border: InputBorder.none, isDense: true),
              ),
            ),
        ],
      ),
    );
  }

  Widget _labeledField({required String label, required TextEditingController controller, TextInputType keyboardType = TextInputType.text}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: JoynTypography.bodyMedium.copyWith(fontSize: 13, fontWeight: FontWeight.w700, color: JoynColors.secondaryText)),
        const SizedBox(height: 6),
        Container(
          height: 50,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(border: Border.all(color: JoynColors.border, width: 1.2), borderRadius: BorderRadius.circular(12)),
          alignment: Alignment.centerLeft,
          child: TextField(
            controller: controller,
            keyboardType: keyboardType,
            decoration: const InputDecoration(border: InputBorder.none, isDense: true),
            style: JoynTypography.bodyLarge.copyWith(fontSize: 15, fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }

  Widget _buildBottomBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      decoration: BoxDecoration(color: Colors.white, boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 18, offset: const Offset(0, -4))]),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            if (_isEditMode) ...[
              Expanded(child: OutlinedButton(onPressed: _deleteSale, style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14)), child: const Text('Delete'))),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: ElevatedButton(
                  onPressed: () => _save(),
                  style: ElevatedButton.styleFrom(backgroundColor: JoynColors.primary, padding: const EdgeInsets.symmetric(vertical: 14)),
                  child: const Text('Edit', style: TextStyle(color: Colors.white)),
                ),
              ),
            ] else ...[
              Expanded(child: OutlinedButton(onPressed: () => _save(andNew: true), style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14)), child: const Text('Save & New'))),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: ElevatedButton(
                  onPressed: () => _save(),
                  style: ElevatedButton.styleFrom(backgroundColor: JoynColors.primary, padding: const EdgeInsets.symmetric(vertical: 14)),
                  child: const Text('Save', style: TextStyle(color: Colors.white)),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}