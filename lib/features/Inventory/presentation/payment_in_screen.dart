// lib/features/orders/presentation/payment_in_screen.dart
//
// Matches the "Payment-In" screenshot: Receipt No / Date, Customer
// Name*/Phone (prefilled from the party), a big Received amount
// field, a live "Total Amount" line showing the party's remaining
// balance after this receipt, and Save & New / Save at the bottom.
// Persists to the local sqlite `payments` table via SalesRepository.

import 'package:flutter/material.dart';
import '../../../core/theme/joyn_colors.dart';
import '../../../core/theme/joyn_typography.dart';
import '../../orders/models/sales_models.dart';
import '../../orders/data/sales_repository.dart';

class PaymentInScreen extends StatefulWidget {
  const PaymentInScreen({super.key, required this.party});

  final PartyModel party;

  @override
  State<PaymentInScreen> createState() => _PaymentInScreenState();
}

class _PaymentInScreenState extends State<PaymentInScreen> {
  final SalesRepository _salesRepository = SalesRepository();

  late final _customerNameController = TextEditingController(text: widget.party.name);
  late final _customerPhoneController = TextEditingController(text: widget.party.contactNumber);
  final _receivedController = TextEditingController();

  int _receiptNo = 0;
  String _date = '';
  double _currentBalance = 0;
  bool _isReceivable = true;
  bool _isLoading = true;

  double get _receivedAmount => double.tryParse(_receivedController.text) ?? 0;
  double get _remainingBalance => (_currentBalance - _receivedAmount).clamp(0, double.infinity);

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _date = '${now.day.toString().padLeft(2, '0')}/${now.month.toString().padLeft(2, '0')}/${now.year}';
    _load();
  }

  Future<void> _load() async {
    final nextReceipt = await _salesRepository.getNextReceiptNo();
    final balanceInfo = await _salesRepository.getPartyBalance(widget.party.id);
    if (!mounted) return;
    setState(() {
      _receiptNo = nextReceipt;
      _currentBalance = balanceInfo['balance'] as double;
      _isReceivable = balanceInfo['isReceivable'] as bool;
      _isLoading = false;
    });
  }

  @override
  void dispose() {
    _customerNameController.dispose();
    _customerPhoneController.dispose();
    _receivedController.dispose();
    super.dispose();
  }

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

  Future<void> _save({bool andNew = false}) async {
    if (_receivedAmount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Enter a received amount')));
      return;
    }

    final payment = PaymentModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      receiptNo: _receiptNo,
      date: _date,
      partyId: widget.party.id,
      partyName: _customerNameController.text.trim(),
      partyPhone: _customerPhoneController.text.trim(),
      receivedAmount: _receivedAmount,
      isPaymentOut: !_isReceivable,
      createdAt: DateTime.now(),
    );

    await _salesRepository.insertPayment(payment);

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Payment saved!'),
        backgroundColor: JoynColors.primary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );

    if (andNew) {
      _receivedController.clear();
      await _load();
      return;
    }

    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: JoynColors.background,
      appBar: AppBar(
        backgroundColor: JoynColors.background,
        elevation: 0,
        leading: IconButton(icon: const Icon(Icons.arrow_back_rounded), onPressed: () => Navigator.of(context).pop()),
        title: Text('Payment-In', style: JoynTypography.titleMedium.copyWith(fontSize: 18, fontWeight: FontWeight.w800)),
        actions: [IconButton(icon: const Icon(Icons.settings_outlined), onPressed: () {})],
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator(color: JoynColors.primary))
            : ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
          children: [
            _buildTopRow(),
            const SizedBox(height: 14),
            _buildPartyFieldsCard(),
            const SizedBox(height: 14),
            _buildAmountCard(),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomBar(),
    );
  }

  Widget _buildTopRow() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: JoynColors.border, width: 1.2)),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Receipt No.', style: JoynTypography.caption.copyWith(fontSize: 11.5, color: JoynColors.secondaryText)),
                const SizedBox(height: 2),
                Text('$_receiptNo', style: JoynTypography.bodyLarge.copyWith(fontSize: 15, fontWeight: FontWeight.w700)),
              ],
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
            child: Text(
              'Party Balance: ₹${_currentBalance.toStringAsFixed(2)}',
              style: JoynTypography.caption.copyWith(fontSize: 12, color: _isReceivable ? JoynColors.success : JoynColors.error, fontWeight: FontWeight.w700),
            ),
          ),
          const SizedBox(height: 8),
          _labeledField(label: 'Customer Name *', controller: _customerNameController),
          const SizedBox(height: 14),
          _labeledField(label: 'Phone Number', controller: _customerPhoneController, keyboardType: TextInputType.phone),
        ],
      ),
    );
  }

  Widget _buildAmountCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: JoynColors.chipBackground, borderRadius: BorderRadius.circular(16)),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Received', style: JoynTypography.bodyLarge.copyWith(fontSize: 14.5, fontWeight: FontWeight.w700)),
              SizedBox(
                width: 150,
                child: TextField(
                  controller: _receivedController,
                  autofocus: true,
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.right,
                  onChanged: (_) => setState(() {}),
                  decoration: const InputDecoration(prefixText: '₹ ', border: InputBorder.none, isDense: true),
                  style: JoynTypography.titleMedium.copyWith(fontSize: 18, fontWeight: FontWeight.w800),
                ),
              ),
            ],
          ),
          const Divider(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Total Amount', style: JoynTypography.bodyLarge.copyWith(fontSize: 14.5, fontWeight: FontWeight.w700, color: JoynColors.success)),
              Text('₹${_remainingBalance.toStringAsFixed(2)}', style: JoynTypography.titleMedium.copyWith(fontSize: 17, fontWeight: FontWeight.w800, color: JoynColors.success)),
            ],
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
        ),
      ),
    );
  }
}