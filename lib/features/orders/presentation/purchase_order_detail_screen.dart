// lib/features/orders/presentation/purchase_order_detail_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/joyn_colors.dart';
import '../../../core/theme/joyn_typography.dart';
import '../models/sales_models.dart';
import '../data/sales_repository.dart';

class PurchaseOrderDetailScreen extends StatefulWidget {
  final PurchaseOrderModel order;

  const PurchaseOrderDetailScreen({super.key, required this.order});

  @override
  State<PurchaseOrderDetailScreen> createState() => _PurchaseOrderDetailScreenState();
}

class _PurchaseOrderDetailScreenState extends State<PurchaseOrderDetailScreen> {
  late List<OrderItemModel> _items;
  final SalesRepository _repository = SalesRepository();

  static const Color _fieldBorder = Color(0xFFE2E5EA);
  static const Color _warningOrange = Color(0xFFF59E0B);
  static const Color _successGreen = Color(0xFF16A34A);

  static const List<String> _indianStates = [
    'Andhra Pradesh', 'Arunachal Pradesh', 'Assam', 'Bihar', 'Chhattisgarh', 'Goa', 'Gujarat',
    'Haryana', 'Himachal Pradesh', 'Jharkhand', 'Karnataka', 'Kerala', 'Madhya Pradesh',
    'Maharashtra', 'Manipur', 'Meghalaya', 'Mizoram', 'Nagaland', 'Odisha', 'Punjab', 'Rajasthan',
    'Sikkim', 'Tamil Nadu', 'Telangana', 'Tripura', 'Uttar Pradesh', 'Uttarakhand', 'West Bengal',
    'Andaman and Nicobar Islands', 'Chandigarh', 'Dadra and Nagar Haveli and Daman and Diu',
    'Delhi', 'Jammu and Kashmir', 'Ladakh', 'Lakshadweep', 'Puducherry',
  ];

  late TextEditingController _partyNameController;
  late TextEditingController _descriptionController;
  late String _orderDateStr;
  late String _dueDateStr;
  String _stateOfSupply = '';
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    try {
      _items = widget.order.items.map((map) => OrderItemModel.fromJson(map)).toList();
    } catch (e) {
      _items = [];
      debugPrint('Error parsing items: $e');
    }
    _partyNameController = TextEditingController(text: widget.order.partyName);
    _descriptionController = TextEditingController();
    _orderDateStr = widget.order.date;
    _dueDateStr = widget.order.dueDate;
  }

  @override
  void dispose() {
    _partyNameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickDate({required String initial, required ValueChanged<String> onPicked}) async {
    DateTime initialDate = DateTime.now();
    final parts = initial.split('/');
    if (parts.length == 3) {
      final d = int.tryParse(parts[0]);
      final m = int.tryParse(parts[1]);
      final y = int.tryParse(parts[2]);
      if (d != null && m != null && y != null) initialDate = DateTime(y, m, d);
    }
    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null && mounted) {
      setState(() {
        onPicked('${picked.day.toString().padLeft(2, '0')}/${picked.month.toString().padLeft(2, '0')}/${picked.year}');
      });
    }
  }

  Future<void> _pickStateOfSupply() async {
    final selected = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.white,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (sheetContext) => SafeArea(
        child: SizedBox(
          height: MediaQuery.of(sheetContext).size.height * 0.6,
          child: Column(
            children: [
              Container(
                width: 42,
                height: 5,
                margin: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(color: const Color(0xFFD1D5DB), borderRadius: BorderRadius.circular(10)),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Select State of Supply',
                    style: JoynTypography.titleMedium.copyWith(fontSize: 17, fontWeight: FontWeight.w800, color: JoynColors.primary),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: ListView.builder(
                  itemCount: _indianStates.length,
                  itemBuilder: (context, index) {
                    final option = _indianStates[index];
                    final isSelected = option == _stateOfSupply;
                    return ListTile(
                      title: Text(
                        option,
                        style: JoynTypography.bodyMedium.copyWith(
                          fontSize: 15,
                          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                          color: isSelected ? JoynColors.primary : Colors.black87,
                        ),
                      ),
                      trailing: isSelected ? Icon(Icons.check_rounded, color: JoynColors.primary) : null,
                      onTap: () => Navigator.pop(sheetContext, option),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
    if (selected != null && mounted) {
      setState(() => _stateOfSupply = selected);
    }
  }

  Future<void> _saveChanges() async {
    FocusScope.of(context).unfocus();
    setState(() => _isSaving = true);

    // NOTE: this updates the in-memory/UI state only. Wire this up to your
    // SalesRepository's update method (e.g. _repository.updatePurchaseOrder(...))
    // once you confirm its exact signature against your PurchaseOrderModel.
    await Future.delayed(const Duration(milliseconds: 300));

    if (!mounted) return;
    setState(() => _isSaving = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Purchase order updated successfully!'),
        behavior: SnackBarBehavior.floating,
        backgroundColor: _successGreen,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    );
  }

  void _showMoreOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 42,
                height: 5,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: const Color(0xFFD1D5DB),
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'More Options',
                    style: JoynTypography.titleMedium.copyWith(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.2,
                      color: JoynColors.primary,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              _buildMenuItem(
                icon: Icons.copy_rounded,
                label: 'Duplicate',
                color: const Color(0xFF2563EB),
                onTap: () {
                  Navigator.pop(sheetContext);
                  _showComingSoon(context, 'Duplicate');
                },
              ),
              _buildMenuItem(
                icon: Icons.payments_outlined,
                label: 'Make Payment',
                color: const Color(0xFF16A34A),
                onTap: () {
                  Navigator.pop(sheetContext);
                  _showComingSoon(context, 'Make Payment');
                },
              ),
              _buildMenuItem(
                icon: Icons.keyboard_return_rounded,
                label: 'Return',
                color: const Color(0xFFF59E0B),
                onTap: () {
                  Navigator.pop(sheetContext);
                  _showComingSoon(context, 'Return');
                },
              ),
              _buildMenuItem(
                icon: Icons.inventory_2_outlined,
                label: 'Goods Receipt',
                color: const Color(0xFF7C3AED),
                onTap: () {
                  Navigator.pop(sheetContext);
                  _showComingSoon(context, 'Goods Receipt');
                },
              ),
              _buildMenuItem(
                icon: Icons.picture_as_pdf_outlined,
                label: 'Share as PDF',
                color: const Color(0xFFC0202B),
                onTap: () {
                  Navigator.pop(sheetContext);
                  _showComingSoon(context, 'Share as PDF');
                },
              ),
              _buildMenuItem(
                icon: Icons.download_rounded,
                label: 'Download PDF',
                color: const Color(0xFF0284C7),
                onTap: () {
                  Navigator.pop(sheetContext);
                  _showComingSoon(context, 'Download PDF');
                },
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: SizedBox(
                  width: double.infinity,
                  child: TextButton(
                    onPressed: () => Navigator.pop(sheetContext),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      backgroundColor: JoynColors.chipBackground,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: Text(
                      'Cancel',
                      style: JoynTypography.bodyMedium.copyWith(
                        fontWeight: FontWeight.w700,
                        color: JoynColors.secondaryText,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: color.withValues(alpha: 0.15), width: 1),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                label,
                style: JoynTypography.bodyLarge.copyWith(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: JoynColors.primary,
                ),
              ),
            ),
            const Icon(Icons.chevron_right_rounded, size: 20, color: JoynColors.secondaryText),
          ],
        ),
      ),
    );
  }

  void _showComingSoon(BuildContext context, String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$feature feature coming soon'),
        behavior: SnackBarBehavior.floating,
        backgroundColor: JoynColors.primary,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<void> _deleteOrder() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Text('Delete Purchase Order?', style: JoynTypography.titleMedium.copyWith(fontSize: 17, fontWeight: FontWeight.w700)),
        content: Text(
          'Delete Order #${widget.order.orderNo} for ${widget.order.partyName}?',
          style: JoynTypography.bodyMedium.copyWith(fontSize: 13.5, color: JoynColors.secondaryText),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Delete', style: TextStyle(color: JoynColors.error, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _repository.deletePurchaseOrder(widget.order.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Purchase order deleted successfully!'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: JoynColors.error,
            margin: const EdgeInsets.all(16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
        );
        Navigator.of(context).pop();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, size: 22, color: JoynColors.primary),
          onPressed: () => context.pop(),
        ),
        centerTitle: true,
        title: Text(
          'Purchase',
          style: JoynTypography.titleMedium.copyWith(
            fontSize: 19,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.2,
          ),
        ),
        actions: [
          IconButton(
            onPressed: () => _showComingSoon(context, 'Share'),
            icon: const Icon(Icons.ios_share_rounded, size: 20, color: JoynColors.secondaryText),
          ),
          IconButton(
            onPressed: () => _showMoreOptions(context),
            icon: const Icon(Icons.more_vert_rounded, size: 22, color: JoynColors.secondaryText),
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
          children: [
            // Order No. / Date row, split by a vertical divider, with the
            // "Purchase" badge floated to the right.
            Container(
              decoration: const BoxDecoration(
                border: Border(bottom: BorderSide(color: _fieldBorder, width: 1)),
              ),
              padding: const EdgeInsets.symmetric(vertical: 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: _warningOrange.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'Purchase',
                      style: JoynTypography.caption.copyWith(fontSize: 11, fontWeight: FontWeight.w700, color: _warningOrange),
                    ),
                  ),
                  const SizedBox(height: 10),
                  IntrinsicHeight(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(
                          child: _buildDropdownLabel(label: 'Order No.', value: widget.order.orderNo.toString()),
                        ),
                        const VerticalDivider(color: _fieldBorder, width: 1, thickness: 1),
                        const SizedBox(width: 16),
                        Expanded(
                          child: InkWell(
                            onTap: () => _pickDate(initial: _dueDateStr, onPicked: (v) => _dueDateStr = v),
                            child: _buildDropdownLabel(label: 'Due Date', value: _dueDateStr, valueColor: JoynColors.error),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Party Name field
            TextFormField(
              controller: _partyNameController,
              style: JoynTypography.bodyMedium.copyWith(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.black87),
              decoration: _fieldDecoration(label: 'Party Name *'),
            ),

            const SizedBox(height: 16),

            // Order Date field
            InkWell(
              onTap: () => _pickDate(initial: _orderDateStr, onPicked: (v) => _orderDateStr = v),
              child: InputDecorator(
                decoration: _fieldDecoration(label: 'Order Date'),
                child: Text(
                  _orderDateStr,
                  style: JoynTypography.bodyMedium.copyWith(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.black87),
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Items header bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: JoynColors.primary,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.expand_more_rounded, size: 18, color: Colors.white),
                      const SizedBox(width: 6),
                      Text(
                        'Items',
                        style: JoynTypography.bodyMedium.copyWith(fontSize: 14, fontWeight: FontWeight.w700, color: Colors.white),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      Text(
                        'Rate excl. tax',
                        style: JoynTypography.caption.copyWith(fontSize: 12, color: Colors.white70),
                      ),
                      const Icon(Icons.expand_more_rounded, size: 16, color: Colors.white70),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // Items
            ..._items.map((item) => _buildItemCard(item)),

            const SizedBox(height: 4),

            // Ticket-style total card
            ClipPath(
              clipper: _TicketBottomClipper(),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(4, 12, 4, 18),
                decoration: BoxDecoration(
                  color: JoynColors.chipBackground,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Total Amount',
                      style: JoynTypography.bodyMedium.copyWith(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.black87),
                    ),
                    Text(
                      '₹${widget.order.totalAmount.toStringAsFixed(2)}',
                      style: JoynTypography.bodyMedium.copyWith(fontSize: 16, fontWeight: FontWeight.w700, color: JoynColors.primary),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // State of Supply
            InkWell(
              onTap: _pickStateOfSupply,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'State of Supply',
                    style: JoynTypography.bodyMedium.copyWith(fontSize: 14, color: JoynColors.secondaryText),
                  ),
                  Row(
                    children: [
                      Text(
                        _stateOfSupply.isEmpty ? 'Select' : _stateOfSupply,
                        style: JoynTypography.bodyMedium.copyWith(fontSize: 14, fontWeight: FontWeight.w700, color: JoynColors.primary),
                      ),
                      const Icon(Icons.keyboard_arrow_down_rounded, size: 20, color: JoynColors.secondaryText),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),
            const Divider(color: _fieldBorder, height: 1),
            const SizedBox(height: 16),

            // Description + attach image
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _descriptionController,
                    maxLines: 3,
                    style: JoynTypography.bodyMedium.copyWith(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.black87),
                    decoration: _fieldDecoration(label: 'Description', placeholder: 'Add Note', minHeight: 64),
                  ),
                ),
                const SizedBox(width: 10),
                Stack(
                  children: [
                    Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        border: Border.all(color: _fieldBorder),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.image_outlined, size: 24, color: JoynColors.secondaryText),
                    ),
                    Positioned(
                      top: -4,
                      right: -4,
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: const BoxDecoration(color: Color(0xFF2563EB), shape: BoxShape.circle),
                        child: const Icon(Icons.add, size: 14, color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Add Document
            InkWell(
              onTap: () => _showComingSoon(context, 'Add Document'),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 18),
                decoration: BoxDecoration(
                  border: Border.all(color: _fieldBorder),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(
                  children: [
                    const Icon(Icons.description_outlined, size: 22, color: JoynColors.secondaryText),
                    const SizedBox(height: 6),
                    Text(
                      'Add Document',
                      style: JoynTypography.bodyMedium.copyWith(fontSize: 13.5, color: JoynColors.secondaryText),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 6),

            Text(
              'Internet is required to upload',
              style: JoynTypography.caption.copyWith(fontSize: 11, color: JoynColors.secondaryText),
            ),

            const SizedBox(height: 16),
            const Divider(color: _fieldBorder, height: 1),
            const SizedBox(height: 4),

            // Terms & Conditions expandable header
            InkWell(
              onTap: () => _showComingSoon(context, 'Terms & Conditions'),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Terms & Conditions',
                      style: JoynTypography.bodyMedium.copyWith(fontSize: 14, fontWeight: FontWeight.w700, color: Colors.black87),
                    ),
                    const Icon(Icons.keyboard_arrow_down_rounded, size: 22, color: Color(0xFF2563EB)),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Delete & Edit Buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _deleteOrder,
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      side: const BorderSide(color: _fieldBorder),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Text(
                      'Delete',
                      style: JoynTypography.bodyMedium.copyWith(fontWeight: FontWeight.w700, color: Colors.black87, fontSize: 15),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isSaving ? null : _saveChanges,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: JoynColors.primary,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: _isSaving
                        ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                        : Text(
                      'Save',
                      style: JoynTypography.bodyMedium.copyWith(fontWeight: FontWeight.w700, color: Colors.white, fontSize: 15),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  /// A label above value, with a trailing dropdown chevron — used for the
  /// Order No. / Due Date row that has no visible box border.
  Widget _buildDropdownLabel({required String label, required String value, Color? valueColor}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: JoynTypography.caption.copyWith(fontSize: 13, color: JoynColors.secondaryText),
            ),
            const SizedBox(height: 2),
            Text(
              value,
              style: JoynTypography.bodyLarge.copyWith(fontSize: 16, fontWeight: FontWeight.w700, color: valueColor ?? Colors.black87),
            ),
          ],
        ),
        const Icon(Icons.keyboard_arrow_down_rounded, size: 20, color: JoynColors.secondaryText),
      ],
    );
  }

  /// Shared InputDecoration for the notched-label bordered fields.
  InputDecoration _fieldDecoration({required String label, String placeholder = '', double minHeight = 52}) {
    return InputDecoration(
      isDense: true,
      constraints: BoxConstraints(minHeight: minHeight),
      labelText: label,
      hintText: placeholder,
      hintStyle: JoynTypography.bodyMedium.copyWith(fontSize: 14, color: JoynColors.secondaryText),
      labelStyle: JoynTypography.bodyMedium.copyWith(fontSize: 14, color: JoynColors.secondaryText),
      floatingLabelBehavior: FloatingLabelBehavior.always,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: _fieldBorder),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: _fieldBorder),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: JoynColors.primary),
      ),
    );
  }

  Widget _buildItemCard(OrderItemModel item) {
    final discountPercent = item.subtotal > 0 ? (item.discountAmount / item.subtotal * 100) : 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: JoynColors.chipBackground,
        borderRadius: BorderRadius.circular(10),
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
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: _fieldBorder),
                    ),
                    child: Text(
                      '#${_items.indexOf(item) + 1}',
                      style: JoynTypography.caption.copyWith(fontSize: 11, fontWeight: FontWeight.w700, color: JoynColors.secondaryText),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    item.itemName,
                    style: JoynTypography.bodyMedium.copyWith(fontSize: 14, fontWeight: FontWeight.w700, color: Colors.black87),
                  ),
                ],
              ),
              Text(
                '₹${item.total.toStringAsFixed(0)}',
                style: JoynTypography.bodyMedium.copyWith(fontSize: 15, fontWeight: FontWeight.w700, color: Colors.black87),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Item Subtotal',
                style: JoynTypography.caption.copyWith(fontSize: 12, color: JoynColors.secondaryText),
              ),
              Text(
                '${item.qty} ${item.unit.isNotEmpty ? item.unit : ''} x ${item.unitPrice.toStringAsFixed(0)} = ₹${item.subtotal.toStringAsFixed(0)}',
                style: JoynTypography.caption.copyWith(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.black87),
              ),
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Discount (%): ${discountPercent.toStringAsFixed(0)}',
                style: JoynTypography.caption.copyWith(fontSize: 12, color: _warningOrange),
              ),
              Text(
                '₹${item.discountAmount.toStringAsFixed(0)}',
                style: JoynTypography.caption.copyWith(fontSize: 12, fontWeight: FontWeight.w600, color: _warningOrange),
              ),
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Tax : ${item.taxRate}%',
                style: JoynTypography.caption.copyWith(fontSize: 12, color: JoynColors.secondaryText),
              ),
              Text(
                '₹${item.taxAmount.toStringAsFixed(0)}',
                style: JoynTypography.caption.copyWith(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.black87),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Clips a zig-zag "torn ticket" edge along the bottom of the total card.
class _TicketBottomClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    const double toothHeight = 7;
    const double approxToothWidth = 16;
    final int teeth = (size.width / approxToothWidth).round().clamp(4, 200);
    final double toothWidth = size.width / teeth;

    final path = Path()
      ..lineTo(0, 0)
      ..lineTo(size.width, 0)
      ..lineTo(size.width, size.height - toothHeight);

    for (int i = teeth; i >= 1; i--) {
      final double xRight = i * toothWidth;
      final double xMid = xRight - toothWidth / 2;
      final double xLeft = xRight - toothWidth;
      path.lineTo(xMid, size.height);
      path.lineTo(xLeft, size.height - toothHeight);
    }

    path.close();
    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}