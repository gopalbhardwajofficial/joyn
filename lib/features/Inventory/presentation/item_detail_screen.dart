// lib/features/Inventory/presentation/item_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/joyn_colors.dart';
import '../../../core/theme/joyn_typography.dart';
import '../../orders/models/sales_models.dart';
import '../../orders/data/sales_repository.dart';
import 'add_new_item_screen.dart';

class ItemDetailScreen extends StatefulWidget {
  const ItemDetailScreen({super.key, required this.item});

  final InventoryItemModel item;

  @override
  State<ItemDetailScreen> createState() => _ItemDetailScreenState();
}

class _ItemDetailScreenState extends State<ItemDetailScreen> {
  final SalesRepository _salesRepository = SalesRepository();
  late InventoryItemModel _item;

  @override
  void initState() {
    super.initState();
    _item = widget.item;
  }

  Future<void> _editItem() async {
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => AddNewItemScreen(existingItem: _item),
      ),
    );

    if (result == true && mounted) {
      // Reload item from database
      final items = await _salesRepository.getItems();
      for (final item in items) {
        if (item.id == _item.id) {
          setState(() => _item = item);
          break;
        }
      }
    }
  }

  Future<void> _deleteItem() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Text('Delete Item?', style: JoynTypography.titleMedium.copyWith(fontSize: 17, fontWeight: FontWeight.w700)),
        content: Text(
          'Remove "${_item.name}" from your inventory?',
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
      await _salesRepository.deleteItem(_item.id);
      if (mounted) {
        Navigator.of(context).pop();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: JoynColors.background,
      appBar: AppBar(
        backgroundColor: JoynColors.background,
        elevation: 0,
        leading: IconButton(
          icon: Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: JoynColors.chipBackground,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.arrow_back_rounded, size: 18),
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
        centerTitle: true,
        title: Text(
          'Item Details',
          style: JoynTypography.titleMedium.copyWith(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.2,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            onPressed: _editItem,
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline_rounded),
            onPressed: _deleteItem,
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
          children: [
            // Item Name Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    JoynColors.primary.withValues(alpha: 0.05),
                    JoynColors.primary.withValues(alpha: 0.1),
                  ],
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: JoynColors.primary.withValues(alpha: 0.1)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          JoynColors.primary.withValues(alpha: 0.15),
                          JoynColors.primary.withValues(alpha: 0.25),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      _item.name.isNotEmpty ? _item.name[0].toUpperCase() : '?',
                      style: JoynTypography.titleMedium.copyWith(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        color: JoynColors.primary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _item.name,
                          style: JoynTypography.titleMedium.copyWith(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 4),
                        if (_item.category.isNotEmpty)
                          Text(
                            _item.category,
                            style: JoynTypography.bodyMedium.copyWith(
                              fontSize: 13,
                              color: JoynColors.secondaryText,
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Stock Info
            _buildDetailCard(
              title: 'Stock Information',
              icon: Icons.inventory_2_outlined,
              children: [
                _buildDetailRow('Quantity', '${_item.qty} ${_item.unit}'),
                _buildDetailRow('Stock', '${_item.stock} ${_item.unit}'),
                _buildDetailRow('Location', _item.location.isEmpty ? 'Not Set' : _item.location),
              ],
            ),
            const SizedBox(height: 16),

            // Pricing Info
            _buildDetailCard(
              title: 'Pricing',
              icon: Icons.currency_rupee_rounded,
              children: [
                _buildDetailRow('Purchase Price', '₹${_item.purchasePrice.toStringAsFixed(2)}'),
                _buildDetailRow('Selling Price', '₹${_item.sellingPrice.toStringAsFixed(2)}'),
                if (_item.taxRatePercent > 0) ...[
                  _buildDetailRow('Tax Rate', _item.taxRateLabel),
                  _buildDetailRow('Tax Percent', '${_item.taxRatePercent}%'),
                ],
              ],
            ),
            const SizedBox(height: 16),

            // Item Details
            _buildDetailCard(
              title: 'Item Details',
              icon: Icons.info_outline_rounded,
              children: [
                _buildDetailRow('SKU', _item.barcode.isEmpty ? 'Not Set' : _item.barcode),
                _buildDetailRow('HSN/SAC', _item.hsnSac.isEmpty ? 'Not Set' : _item.hsnSac),
                _buildDetailRow('Unit', _item.unit),
                _buildDetailRow('Barcode Mode', _item.barcodeMode == 'same' ? 'Same for all' : 'Separate'),
              ],
            ),
            const SizedBox(height: 16),

            // Barcode
            if (_item.barcode.isNotEmpty)
              _buildDetailCard(
                title: 'Barcode',
                icon: Icons.qr_code_rounded,
                children: [
                  _buildDetailRow('Barcode', _item.barcode),
                  const SizedBox(height: 10),
                  Center(
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        children: [
                          Text(
                            _item.barcode,
                            style: JoynTypography.titleMedium.copyWith(
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 2,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),

            const SizedBox(height: 24),

            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _editItem,
                    icon: const Icon(Icons.edit_outlined, size: 18),
                    label: const Text('Edit Item'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: JoynColors.primary,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      side: BorderSide(color: JoynColors.primary.withValues(alpha: 0.3)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _deleteItem,
                    icon: const Icon(Icons.delete_outline_rounded, size: 18),
                    label: const Text('Delete'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: JoynColors.error,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      side: BorderSide(color: JoynColors.error.withValues(alpha: 0.3)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailCard({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.white, JoynColors.background],
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: JoynColors.border, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.035),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: JoynColors.primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, size: 16, color: JoynColors.primary),
              ),
              const SizedBox(width: 10),
              Text(
                title,
                style: JoynTypography.bodyLarge.copyWith(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: JoynColors.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: JoynTypography.bodyMedium.copyWith(
              fontSize: 13,
              color: JoynColors.secondaryText,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: JoynTypography.bodyMedium.copyWith(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: JoynColors.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}