import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/theme/joyn_colors.dart';
import '../../../core/theme/joyn_typography.dart';
import '../../Inventory/presentation/scan_code_screen.dart';
import '../models/sales_models.dart';
import '../data/sales_repository.dart';

class BarcodeService {
  final SalesRepository _repository = SalesRepository();

  // Scan barcode and find item
  Future<InventoryItemModel?> scanAndFindItem(BuildContext context) async {
    final barcode = await Navigator.of(context).push<String>(
      MaterialPageRoute(
        builder: (context) => const ScanCodeScreen(),
      ),
    );

    if (barcode == null || barcode.isEmpty) return null;

    return await _findItemByBarcode(barcode);
  }

  // Find item by barcode from database
  Future<InventoryItemModel?> _findItemByBarcode(String barcode) async {
    try {
      final items = await _repository.getItems();
      for (final item in items) {
        if (item.barcode.isNotEmpty && item.barcode == barcode) {
          return item;
        }
      }
      return null;
    } catch (e) {
      debugPrint('Error finding item by barcode: $e');
      return null;
    }
  }

  // Show message if item not found
  void showItemNotFound(BuildContext context, String barcode) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('No item found for barcode "$barcode"'),
        behavior: SnackBarBehavior.floating,
        backgroundColor: JoynColors.error,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    );
  }
}