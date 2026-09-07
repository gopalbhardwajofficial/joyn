import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/theme/joyn_colors.dart';
import '../../../../core/theme/joyn_typography.dart';
import '../../../../core/constants/tax_rates.dart';
import '../../models/order_item_model.dart';
import '../../models/sales_models.dart';
import '../../data/sales_repository.dart';
import '../../../Inventory/presentation/scan_code_screen.dart';
import '../../../Inventory/presentation/add_new_item_screen.dart';

class _Premium {
  static List<BoxShadow> cardShadow = [
    BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 24, offset: const Offset(0, 10)),
  ];
  static List<BoxShadow> fieldShadow = [
    BoxShadow(color: Colors.black.withValues(alpha: 0.035), blurRadius: 10, offset: const Offset(0, 3)),
  ];
  static List<BoxShadow> floatingShadow(Color color) => [
    BoxShadow(color: color.withValues(alpha: 0.35), blurRadius: 16, offset: const Offset(0, 6)),
  ];
  static LinearGradient gradient(Color color) => LinearGradient(
    begin: Alignment.topLeft, end: Alignment.bottomRight,
    colors: [color, Color.lerp(color, Colors.black, 0.18) ?? color],
  );
  static LinearGradient surfaceGradient = LinearGradient(
    begin: Alignment.topLeft, end: Alignment.bottomRight,
    colors: [Colors.white, JoynColors.background],
  );
}

class SavedItemOption {
  final String name;
  final String category;
  final String unit;
  final double purchasePrice;
  final double sellingPrice;
  final int stock;
  final String barcode;

  const SavedItemOption({
    required this.name,
    this.category = '',
    this.unit = 'Pcs',
    this.purchasePrice = 0,
    this.sellingPrice = 0,
    this.stock = 0,
    this.barcode = '',
  });

  factory SavedItemOption.fromJson(Map<String, dynamic> json) {
    return SavedItemOption(
      name: (json['name'] ?? '').toString(),
      category: (json['category'] ?? '').toString(),
      unit: (json['unit'] ?? 'Pcs').toString(),
      purchasePrice: (json['purchasePrice'] as num?)?.toDouble() ?? 0,
      sellingPrice: (json['sellingPrice'] as num?)?.toDouble() ?? 0,
      stock: (json['stock'] as num?)?.toInt() ?? 0,
      barcode: (json['barcode'] ?? '').toString(),
    );
  }

  factory SavedItemOption.fromInventoryItem(InventoryItemModel item) {
    return SavedItemOption(
      name: item.name,
      category: item.category,
      unit: item.unit,
      purchasePrice: item.purchasePrice,
      sellingPrice: item.sellingPrice,
      stock: item.stock,
      barcode: item.barcode,
    );
  }
}

enum _DiscountMode { percent, rupee }
enum _RateTaxMode { withTax, withoutTax }

class AddOrderItemDialog extends StatefulWidget {
  const AddOrderItemDialog({
    super.key,
    this.existingItem,
    this.savedItems = const [],
    this.isPurchaseOrder = false,
  });

  final OrderItemModel? existingItem;
  final List<SavedItemOption> savedItems;
  final bool isPurchaseOrder;

  @override
  State<AddOrderItemDialog> createState() => _AddOrderItemDialogState();
}

class _AddOrderItemDialogState extends State<AddOrderItemDialog> {
  final SalesRepository _salesRepository = SalesRepository();

  late List<SavedItemOption> _savedItems;
  late final TextEditingController _nameController;
  late final TextEditingController _categoryController;
  late final TextEditingController _priceController;
  late final TextEditingController _qtyController;
  final _discountController = TextEditingController();

  final FocusNode _nameFocusNode = FocusNode();

  bool _isOneTimeItem = false;
  String _selectedUnit = 'Select Unit';
  _RateTaxMode _rateTaxMode = _RateTaxMode.withoutTax;
  _DiscountMode _discountMode = _DiscountMode.percent;
  TaxRateOption? _selectedTaxRate;

  final List<(String, String)> _allUnits = const [
    ('Bags', 'Bag'), ('Bottles', 'Btl'), ('Box', 'Box'), ('Bundles', 'Bdl'),
    ('Cans', 'Can'), ('Cartons', 'Ctn'), ('Cubic Meter', 'Mtq'), ('Day', 'Day'),
    ('Dozens', 'Dzn'), ('Grammes', 'Gm'), ('Hour', 'Hur'), ('Kilograms', 'Kg'),
    ('Kilometer', 'Kmt'), ('Litre', 'Ltr'), ('Meters', 'Mtr'), ('Mililitre', 'Ml'),
    ('Numbers', 'Nos'), ('Packs', 'Pac'), ('Pairs', 'Prs'), ('Pieces', 'Pcs'),
    ('Quintal', 'Qtl'), ('Rolls', 'Rol'), ('Service', 'Ser'), ('Set', 'Set'),
    ('Square Feet', 'Sqf'), ('Square Meters', 'Sqm'), ('Tablets', 'Tbs'),
    ('Ton / Metric Ton', 'Ton'), ('Unit', 'Unit'),
  ];

  final List<(String, String)> _customUnits = [];

  @override
  void initState() {
    super.initState();
    _savedItems = List<SavedItemOption>.from(widget.savedItems);
    final existing = widget.existingItem;
    _nameController = TextEditingController(text: existing?.itemName ?? '');
    _categoryController = TextEditingController(text: existing?.category ?? '');
    _priceController = TextEditingController(
      text: existing != null && existing.price != 0 ? existing.price.toStringAsFixed(2) : '',
    );
    _qtyController = TextEditingController(text: existing != null ? existing.qty.toString() : '1');
    _nameFocusNode.addListener(() {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _categoryController.dispose();
    _priceController.dispose();
    _qtyController.dispose();
    _discountController.dispose();
    _nameFocusNode.dispose();
    super.dispose();
  }

  double get _price => double.tryParse(_priceController.text.trim()) ?? 0;
  int get _qty => int.tryParse(_qtyController.text.trim()) ?? 0;

  List<SavedItemOption> get _filteredSavedItems {
    final query = _nameController.text.trim().toLowerCase();
    if (query.isEmpty) return _savedItems;
    return _savedItems.where((item) {
      return item.name.toLowerCase().contains(query) || item.category.toLowerCase().contains(query);
    }).toList();
  }

  bool get _shouldShowSuggestions => !_isOneTimeItem && _nameFocusNode.hasFocus;

  // Auto-fill item details
  void _selectSavedItem(SavedItemOption item) {
    HapticFeedback.selectionClick();
    setState(() {
      _nameController.text = item.name;
      _categoryController.text = item.category;
      _selectedUnit = item.unit;
      _qtyController.text = '1'; // Default quantity

      if (widget.isPurchaseOrder) {
        _priceController.text = item.purchasePrice != 0
            ? item.purchasePrice.toStringAsFixed(2)
            : (item.sellingPrice != 0 ? item.sellingPrice.toStringAsFixed(2) : '');
      } else {
        _priceController.text = item.sellingPrice != 0
            ? item.sellingPrice.toStringAsFixed(2)
            : (item.purchasePrice != 0 ? item.purchasePrice.toStringAsFixed(2) : '');
      }
    });
    _nameFocusNode.unfocus();
  }

  Future<void> _openAddNewItemScreen() async {
    _nameFocusNode.unfocus();
    final result = await Navigator.of(context).push<Map<String, dynamic>>(
      MaterialPageRoute(builder: (_) => const AddNewItemScreen()),
    );
    if (result == null || !mounted) return;
    final name = (result['name'] ?? '').toString().trim();
    if (name.isEmpty) return;
    final category = (result['category'] ?? '').toString();
    final unit = (result['unit'] ?? '').toString();
    final buyingPrice = (result['buyingPrice'] as num?)?.toDouble() ?? 0;
    final sellingPrice = (result['sellingPrice'] as num?)?.toDouble() ?? 0;
    final barcode = (result['barcode'] ?? '').toString();
    final qty = (result['qty'] as num?)?.toInt() ?? 0;

    final newItem = SavedItemOption(
      name: name, category: category, unit: unit.isNotEmpty ? unit : 'Pcs',
      purchasePrice: buyingPrice, sellingPrice: sellingPrice, stock: qty, barcode: barcode,
    );

    final inventoryItem = InventoryItemModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: name, category: category, unit: unit.isNotEmpty ? unit : 'Pcs',
      purchasePrice: buyingPrice, sellingPrice: sellingPrice, stock: qty,
      barcode: barcode, createdAt: DateTime.now(),
    );
    await _salesRepository.insertItem(inventoryItem);

    setState(() {
      final existingIndex = _savedItems.indexWhere((item) => item.name.toLowerCase() == name.toLowerCase());
      if (existingIndex >= 0) {
        _savedItems[existingIndex] = newItem;
      } else {
        _savedItems.add(newItem);
      }
      _nameController.text = name;
      _categoryController.text = category;
      if (unit.isNotEmpty) _selectedUnit = unit;
      _qtyController.text = '1';
      final price = widget.isPurchaseOrder ? (buyingPrice != 0 ? buyingPrice : sellingPrice) : (sellingPrice != 0 ? sellingPrice : buyingPrice);
      if (price != 0) _priceController.text = price.toStringAsFixed(2);
      final sellingTaxPercent = (result['sellingTaxPercent'] as num?)?.toDouble();
      if (sellingTaxPercent != null) {
        for (final rate in kTaxRateOptions) {
          if (rate.rate == sellingTaxPercent) {
            _selectedTaxRate = rate;
            break;
          }
        }
      }
    });
    _nameFocusNode.unfocus();
    HapticFeedback.selectionClick();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Item "$name" added successfully!'),
        behavior: SnackBarBehavior.floating,
        backgroundColor: JoynColors.success,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  // Scan barcode and auto-fetch item
  Future<void> _scanBarcodeForItem() async {
    HapticFeedback.lightImpact();

    // Show loading
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)),
            const SizedBox(width: 12),
            const Text('Opening scanner...'),
          ],
        ),
        behavior: SnackBarBehavior.floating,
        backgroundColor: JoynColors.primary,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        duration: const Duration(seconds: 1),
      ),
    );

    // Open scanner
    final scannedCode = await Navigator.of(context).push<String>(
      MaterialPageRoute(builder: (_) => const ScanCodeScreen()),
    );

    if (scannedCode == null || scannedCode.isEmpty || !mounted) return;

    // Hide loading
    ScaffoldMessenger.of(context).hideCurrentSnackBar();

    // Search in local list first
    SavedItemOption? match;
    for (final item in _savedItems) {
      if (item.barcode.isNotEmpty && item.barcode == scannedCode) {
        match = item;
        break;
      }
    }

    // Search in database
    if (match == null) {
      try {
        final dbItems = await _salesRepository.getItems();
        for (final item in dbItems) {
          if (item.barcode.isNotEmpty && item.barcode == scannedCode) {
            match = SavedItemOption.fromInventoryItem(item);
            break;
          }
        }
      } catch (e) {
        debugPrint('Error searching item: $e');
      }
    }

    if (match != null) {
      // Item found - auto-fill all details
      _selectSavedItem(match);
      HapticFeedback.mediumImpact();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Item found: ${match.name}\nCategory: ${match.category}\nStock: ${match.stock}',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          behavior: SnackBarBehavior.floating,
          backgroundColor: JoynColors.success,
          margin: const EdgeInsets.all(16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          duration: const Duration(seconds: 3),
        ),
      );
    } else {
      // Item not found
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('No item found for code "$scannedCode"'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: JoynColors.error,
          margin: const EdgeInsets.all(16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          duration: const Duration(seconds: 3),
          action: SnackBarAction(
            label: 'ADD ITEM',
            textColor: Colors.white,
            onPressed: _openAddNewItemScreen,
          ),
        ),
      );
    }
  }

  List<(String, String)> get _allSelectableUnits => [..._allUnits, ..._customUnits];

  Future<void> _addNewUnit() async {
    final controller = TextEditingController();
    try {
      final result = await showDialog<String>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          backgroundColor: JoynColors.background,
          elevation: 8,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text('New Unit', style: JoynTypography.titleMedium.copyWith(fontSize: 18, fontWeight: FontWeight.w800)),
          content: TextField(
            controller: controller,
            autofocus: true,
            decoration: InputDecoration(
              hintText: 'Enter unit name (e.g. Crate)',
              filled: true, fillColor: JoynColors.chipBackground,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.of(dialogContext).pop(), child: const Text('Cancel')),
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(controller.text.trim()),
              style: TextButton.styleFrom(foregroundColor: JoynColors.primary),
              child: const Text('Add', style: TextStyle(fontWeight: FontWeight.w700)),
            ),
          ],
        ),
      );
      if (!mounted || result == null || result.isEmpty) return;
      setState(() {
        _customUnits.add((result, result));
        _selectedUnit = result;
      });
    } finally {
      controller.dispose();
    }
  }

  Future<void> _openUnitPicker() async {
    final selected = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: JoynColors.background,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            String query = '';
            return SafeArea(
              child: Padding(
                padding: EdgeInsets.only(left: 20, right: 20, top: 16, bottom: MediaQuery.of(context).viewInsets.bottom + 16),
                child: StatefulBuilder(
                  builder: (context, setInnerState) {
                    final filtered = _allSelectableUnits.where((u) {
                      if (query.isEmpty) return true;
                      final q = query.toLowerCase();
                      return u.$1.toLowerCase().contains(q) || u.$2.toLowerCase().contains(q);
                    }).toList();
                    return ConstrainedBox(
                      constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.8),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('Change Item Unit', style: JoynTypography.titleMedium.copyWith(fontSize: 18, fontWeight: FontWeight.w800)),
                              InkWell(
                                onTap: () => Navigator.pop(sheetContext),
                                borderRadius: BorderRadius.circular(20),
                                child: Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(color: JoynColors.chipBackground, shape: BoxShape.circle),
                                  child: const Icon(Icons.close_rounded, size: 18),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          TextField(
                            autofocus: false,
                            onChanged: (v) => setInnerState(() => query = v),
                            decoration: InputDecoration(
                              hintText: 'Search for a Unit',
                              prefixIcon: const Icon(Icons.search_rounded, size: 20),
                              filled: true, fillColor: JoynColors.chipBackground,
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                              contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 14),
                            ),
                          ),
                          const SizedBox(height: 14),
                          InkWell(
                            onTap: () {
                              Navigator.pop(sheetContext);
                              WidgetsBinding.instance.addPostFrameCallback((_) {
                                if (mounted) _addNewUnit();
                              });
                            },
                            child: Text('Add New Unit', style: JoynTypography.bodyMedium.copyWith(fontWeight: FontWeight.w700, color: JoynColors.primary, fontSize: 14.5)),
                          ),
                          const SizedBox(height: 10),
                          Flexible(
                            child: filtered.isEmpty
                                ? Padding(padding: const EdgeInsets.symmetric(vertical: 24), child: Text('No matching unit', style: JoynTypography.subtitle.copyWith(fontSize: 13.5)))
                                : ListView.builder(
                              shrinkWrap: true,
                              itemCount: filtered.length,
                              itemBuilder: (context, index) {
                                final unit = filtered[index];
                                final isSelected = _selectedUnit == unit.$2;
                                return InkWell(
                                  onTap: () => Navigator.pop(sheetContext, unit.$2),
                                  borderRadius: BorderRadius.circular(12),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(vertical: 14),
                                    decoration: BoxDecoration(border: Border(bottom: BorderSide(color: JoynColors.border.withValues(alpha: 0.5)))),
                                    child: Row(
                                      children: [
                                        Expanded(
                                          child: Text('${unit.$1.toUpperCase()} (${unit.$2})', style: JoynTypography.bodyLarge.copyWith(fontSize: 15, fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500, color: isSelected ? JoynColors.primary : null)),
                                        ),
                                        if (isSelected) const Icon(Icons.check_rounded, size: 18, color: JoynColors.primary),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            );
          },
        );
      },
    );
    if (selected != null && mounted) {
      setState(() => _selectedUnit = selected);
    }
  }

  ({double subtotal, double discountAmount, double taxAmount, double total}) _calculateTotals() {
    final subtotal = _price * _qty;
    final discountRaw = double.tryParse(_discountController.text.trim()) ?? 0;
    final discountAmount = _discountMode == _DiscountMode.percent ? subtotal * (discountRaw / 100) : discountRaw;
    final taxableAmount = (subtotal - discountAmount).clamp(0, double.infinity).toDouble();
    final ratePercent = _selectedTaxRate?.rate ?? 0;
    double taxAmount;
    double total;
    if (_rateTaxMode == _RateTaxMode.withoutTax) {
      taxAmount = taxableAmount * (ratePercent / 100);
      total = taxableAmount + taxAmount;
    } else {
      final base = taxableAmount / (1 + (ratePercent / 100));
      taxAmount = taxableAmount - base;
      total = taxableAmount;
    }
    return (subtotal: subtotal, discountAmount: discountAmount, taxAmount: taxAmount, total: total);
  }

  void _submit() {
    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Item name is required'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: JoynColors.error,
          margin: const EdgeInsets.all(16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
      );
      return;
    }
    HapticFeedback.mediumImpact();
    late final OrderItemModel item;
    if (_isOneTimeItem) {
      item = OrderItemModel(
        id: widget.existingItem?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
        itemName: _nameController.text.trim(),
        category: '',
        price: _price,
        qty: 1,
      );
    } else {
      final qty = _qty <= 0 ? 0 : _qty;
      final totals = _calculateTotals();
      final effectivePrice = totals.total / qty;
      item = OrderItemModel(
        id: widget.existingItem?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
        itemName: _nameController.text.trim(),
        category: _categoryController.text.trim(),
        price: effectivePrice,
        qty: qty,
      );
    }
    Navigator.pop(context, item);
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.existingItem != null;
    final totals = _calculateTotals();

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Container(
        width: double.infinity,
        constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.88),
        padding: const EdgeInsets.fromLTRB(22, 22, 22, 18),
        decoration: BoxDecoration(
          gradient: _Premium.surfaceGradient,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: JoynColors.border, width: 1.2),
          boxShadow: _Premium.cardShadow,
        ),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(isEditing ? 'Edit Item' : 'Add Item', style: JoynTypography.titleMedium.copyWith(fontSize: 20, fontWeight: FontWeight.w800, letterSpacing: -0.2, color: JoynColors.primary)),
                  InkWell(
                    onTap: () => Navigator.pop(context),
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(color: JoynColors.chipBackground, shape: BoxShape.circle),
                      child: const Icon(Icons.close_rounded, size: 18, color: JoynColors.secondaryText),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _buildOneTimeItemToggle(),
              const SizedBox(height: 16),
              if (_isOneTimeItem) ...[
                _buildFormField(label: 'Item Name *', hintText: 'Enter item name', controller: _nameController, icon: Icons.inventory_2_outlined),
                const SizedBox(height: 14),
                _buildFormField(label: 'Price *', hintText: '0.00', controller: _priceController, keyboardType: const TextInputType.numberWithOptions(decimal: true), icon: Icons.currency_rupee_rounded, onChanged: (_) => setState(() {})),
              ] else ...[
                _buildItemNameWithSuggestions(),
                const SizedBox(height: 14),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: _buildFormField(label: 'Quantity', hintText: '1', controller: _qtyController, keyboardType: TextInputType.number, icon: Icons.numbers_rounded, onChanged: (_) => setState(() {}))),
                    const SizedBox(width: 12),
                    Expanded(child: _buildUnitField()),
                  ],
                ),
                const SizedBox(height: 14),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: _buildFormField(label: 'Rate (Price/Unit)', hintText: '0.00', controller: _priceController, keyboardType: const TextInputType.numberWithOptions(decimal: true), icon: Icons.currency_rupee_rounded, onChanged: (_) => setState(() {}))),
                    const SizedBox(width: 12),
                    Expanded(child: _buildRateTaxModeField()),
                  ],
                ),
                const SizedBox(height: 18),
                _buildTotalsAndTaxesCard(totals),
              ],
              const SizedBox(height: 22),
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: _Premium.floatingShadow(JoynColors.primary),
                ),
                child: SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: JoynColors.primary,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    child: Text(isEditing ? 'Update Item' : 'Add Item', style: JoynTypography.buttonText.copyWith(fontSize: 15.5, fontWeight: FontWeight.w700)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOneTimeItemToggle() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _isOneTimeItem ? JoynColors.primary.withValues(alpha: 0.35) : JoynColors.border, width: 1.2),
        boxShadow: _Premium.fieldShadow,
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              gradient: _isOneTimeItem ? _Premium.gradient(JoynColors.primary) : null,
              color: _isOneTimeItem ? null : JoynColors.primary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(Icons.flash_on_rounded, size: 16, color: _isOneTimeItem ? Colors.white : JoynColors.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('One Time Item', style: JoynTypography.bodyMedium.copyWith(fontSize: 13.5, fontWeight: FontWeight.w700, color: JoynColors.primary)),
                const SizedBox(height: 2),
                Text(_isOneTimeItem ? 'Just Name + Price, no catalog or tax needed' : 'Turn on for a quick one-off item', style: JoynTypography.caption.copyWith(fontSize: 11.5, color: JoynColors.secondaryText)),
              ],
            ),
          ),
          Switch.adaptive(
            value: _isOneTimeItem,
            onChanged: (val) {
              HapticFeedback.selectionClick();
              setState(() => _isOneTimeItem = val);
            },
            activeTrackColor: JoynColors.primary,
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
        ],
      ),
    );
  }

  Widget _buildItemNameWithSuggestions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Item Name *', style: JoynTypography.bodyMedium.copyWith(fontSize: 13, fontWeight: FontWeight.w700, color: JoynColors.secondaryText)),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: _shouldShowSuggestions ? const BorderRadius.only(topLeft: Radius.circular(16), topRight: Radius.circular(16)) : BorderRadius.circular(16),
            border: Border.all(color: _nameFocusNode.hasFocus ? JoynColors.primary : JoynColors.border, width: 1.2),
            boxShadow: _Premium.fieldShadow,
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(color: JoynColors.primary.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(10)),
                child: const Icon(Icons.inventory_2_outlined, size: 16, color: JoynColors.primary),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: TextField(
                  controller: _nameController,
                  focusNode: _nameFocusNode,
                  onChanged: (_) => setState(() {}),
                  style: JoynTypography.bodyLarge.copyWith(fontSize: 15, fontWeight: FontWeight.w600),
                  decoration: InputDecoration(
                    hintText: 'Type to search or scan...',
                    hintStyle: JoynTypography.bodyLarge.copyWith(color: JoynColors.secondaryText.withValues(alpha: 0.5), fontSize: 14.5, fontWeight: FontWeight.w500),
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
              InkWell(
                onTap: _scanBarcodeForItem,
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [JoynColors.primary.withValues(alpha: 0.12), JoynColors.primary.withValues(alpha: 0.06)]),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: JoynColors.primary.withValues(alpha: 0.25), width: 1),
                  ),
                  child: const Icon(Icons.qr_code_scanner_rounded, size: 18, color: JoynColors.primary),
                ),
              ),
            ],
          ),
        ),
        if (_shouldShowSuggestions)
          Container(
            width: double.infinity,
            constraints: const BoxConstraints(maxHeight: 300),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(16), bottomRight: Radius.circular(16)),
              border: Border.all(color: JoynColors.primary, width: 1.2),
              boxShadow: _Premium.cardShadow,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(_filteredSavedItems.isEmpty ? 'No Items Found' : 'Saved Items (${_filteredSavedItems.length})', style: JoynTypography.bodyMedium.copyWith(fontSize: 13, fontWeight: FontWeight.w700, color: JoynColors.secondaryText)),
                      InkWell(
                        onTap: _openAddNewItemScreen,
                        borderRadius: BorderRadius.circular(10),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            gradient: _Premium.gradient(JoynColors.primary),
                            borderRadius: BorderRadius.circular(10),
                            boxShadow: [BoxShadow(color: JoynColors.primary.withValues(alpha: 0.25), blurRadius: 8, offset: const Offset(0, 3))],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.add_rounded, size: 16, color: Colors.white),
                              const SizedBox(width: 4),
                              Text('Add Item', style: JoynTypography.bodyMedium.copyWith(fontSize: 12.5, fontWeight: FontWeight.w700, color: Colors.white)),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),
                if (_filteredSavedItems.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 24),
                    child: Column(
                      children: [
                        Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: JoynColors.chipBackground, shape: BoxShape.circle), child: const Icon(Icons.inventory_2_outlined, size: 32, color: JoynColors.secondaryText)),
                        const SizedBox(height: 12),
                        Text('No matching item found', style: JoynTypography.bodyMedium.copyWith(fontSize: 14, fontWeight: FontWeight.w700, color: JoynColors.primary)),
                        const SizedBox(height: 4),
                        Text('Create a new item or scan barcode', style: JoynTypography.caption.copyWith(fontSize: 12, color: JoynColors.secondaryText)),
                        const SizedBox(height: 16),
                        InkWell(
                          onTap: _openAddNewItemScreen,
                          borderRadius: BorderRadius.circular(14),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                            decoration: BoxDecoration(
                              gradient: _Premium.gradient(JoynColors.primary),
                              borderRadius: BorderRadius.circular(14),
                              boxShadow: [BoxShadow(color: JoynColors.primary.withValues(alpha: 0.3), blurRadius: 12, offset: const Offset(0, 4))],
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.add_circle_outline_rounded, size: 20, color: Colors.white),
                                const SizedBox(width: 8),
                                Text('Add New Item', style: JoynTypography.bodyMedium.copyWith(fontSize: 14, fontWeight: FontWeight.w700, color: Colors.white)),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  Flexible(
                    child: ListView.builder(
                      shrinkWrap: true,
                      padding: EdgeInsets.zero,
                      itemCount: _filteredSavedItems.length,
                      itemBuilder: (context, index) {
                        final item = _filteredSavedItems[index];
                        final isLowStock = item.stock < 0;
                        return InkWell(
                          onTap: () => _selectSavedItem(item),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                            decoration: BoxDecoration(border: Border(bottom: BorderSide(color: JoynColors.border.withValues(alpha: 0.5)))),
                            child: Row(
                              children: [
                                Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [JoynColors.primary.withValues(alpha: 0.08), JoynColors.primary.withValues(alpha: 0.16)]),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  alignment: Alignment.center,
                                  child: Text(item.name.isNotEmpty ? item.name[0].toUpperCase() : '?', style: JoynTypography.bodyMedium.copyWith(fontWeight: FontWeight.w800, color: JoynColors.primary, fontSize: 16)),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(item.name, style: JoynTypography.bodyMedium.copyWith(fontSize: 14.5, fontWeight: FontWeight.w700)),
                                      const SizedBox(height: 3),
                                      Row(
                                        children: [
                                          Text('${widget.isPurchaseOrder ? 'Purchase' : 'Selling'}: ₹${widget.isPurchaseOrder ? item.purchasePrice.toStringAsFixed(2) : item.sellingPrice.toStringAsFixed(2)}', style: JoynTypography.caption.copyWith(fontSize: 11.5, color: JoynColors.secondaryText)),
                                          const SizedBox(width: 10),
                                          Text('Stock: ${item.stock}', style: JoynTypography.caption.copyWith(fontSize: 11.5, fontWeight: FontWeight.w700, color: isLowStock ? JoynColors.error : JoynColors.secondaryText)),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                if (item.barcode.isNotEmpty)
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                                    decoration: BoxDecoration(color: JoynColors.chipBackground, borderRadius: BorderRadius.circular(6)),
                                    child: Row(children: [const Icon(Icons.qr_code_rounded, size: 10, color: JoynColors.secondaryText), const SizedBox(width: 3), Text('Barcode', style: JoynTypography.caption.copyWith(fontSize: 9, color: JoynColors.secondaryText))]),
                                  ),
                                const SizedBox(width: 8),
                                const Icon(Icons.chevron_right_rounded, color: JoynColors.secondaryText, size: 20),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildUnitField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Unit', style: JoynTypography.bodyMedium.copyWith(fontSize: 13, fontWeight: FontWeight.w700, color: JoynColors.secondaryText)),
        const SizedBox(height: 6),
        InkWell(
          onTap: _openUnitPicker,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            height: 54,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: JoynColors.border, width: 1.2), boxShadow: _Premium.fieldShadow),
            child: Row(
              children: [
                Expanded(
                  child: Text(_selectedUnit, style: JoynTypography.bodyLarge.copyWith(fontSize: 15, color: _selectedUnit != 'Select Unit' ? JoynColors.primary : JoynColors.secondaryText)),
                ),
                const Icon(Icons.keyboard_arrow_down_rounded, color: JoynColors.primary, size: 20),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRateTaxModeField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 19),
        Container(
          height: 54,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: JoynColors.border, width: 1.2), boxShadow: _Premium.fieldShadow),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<_RateTaxMode>(
              value: _rateTaxMode,
              isExpanded: true,
              icon: const Icon(Icons.keyboard_arrow_down_rounded, color: JoynColors.primary, size: 20),
              style: JoynTypography.bodyLarge.copyWith(fontSize: 14.5, color: JoynColors.primary),
              onChanged: (val) {
                if (val == null) return;
                HapticFeedback.selectionClick();
                setState(() => _rateTaxMode = val);
              },
              items: const [
                DropdownMenuItem(value: _RateTaxMode.withoutTax, child: Text('Without Tax')),
                DropdownMenuItem(value: _RateTaxMode.withTax, child: Text('With Tax')),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTotalsAndTaxesCard(({double subtotal, double discountAmount, double taxAmount, double total}) totals) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: JoynColors.chipBackground.withValues(alpha: 0.4), borderRadius: BorderRadius.circular(18), border: Border.all(color: JoynColors.border, width: 1.2)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Totals & Taxes', style: JoynTypography.bodyLarge.copyWith(fontSize: 15, fontWeight: FontWeight.w800, color: JoynColors.primary)),
          const SizedBox(height: 4),
          const Divider(height: 20),
          _buildTotalsRow('Subtotal (Rate x Qty)', totals.subtotal),
          const SizedBox(height: 14),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Discount', style: JoynTypography.caption.copyWith(fontSize: 12, fontWeight: FontWeight.w700, color: JoynColors.secondaryText)),
                    const SizedBox(height: 6),
                    Container(
                      height: 48,
                      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: JoynColors.border, width: 1.2)),
                      child: Row(
                        children: [
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 12),
                              child: TextField(
                                controller: _discountController,
                                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                onChanged: (_) => setState(() {}),
                                style: JoynTypography.bodyLarge.copyWith(fontSize: 14.5, fontWeight: FontWeight.w600),
                                decoration: const InputDecoration(hintText: '0', border: InputBorder.none, isDense: true),
                              ),
                            ),
                          ),
                          InkWell(
                            onTap: () {
                              HapticFeedback.selectionClick();
                              setState(() {
                                _discountMode = _discountMode == _DiscountMode.percent ? _DiscountMode.rupee : _DiscountMode.percent;
                              });
                            },
                            child: Container(
                              height: 48,
                              width: 40,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(color: JoynColors.primary.withValues(alpha: 0.12), borderRadius: const BorderRadius.only(topRight: Radius.circular(11), bottomRight: Radius.circular(11))),
                              child: Text(_discountMode == _DiscountMode.percent ? '%' : '₹', style: JoynTypography.bodyLarge.copyWith(fontWeight: FontWeight.w800, color: JoynColors.primary)),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Expanded(child: _buildReadOnlyAmountBox(totals.discountAmount)),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Tax %', style: JoynTypography.caption.copyWith(fontSize: 12, fontWeight: FontWeight.w700, color: JoynColors.secondaryText)),
                    const SizedBox(height: 6),
                    Container(
                      height: 48,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: JoynColors.border, width: 1.2)),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<TaxRateOption?>(
                          value: _selectedTaxRate,
                          isExpanded: true,
                          hint: Text('None', style: JoynTypography.bodyLarge.copyWith(fontSize: 14.5)),
                          icon: const Icon(Icons.keyboard_arrow_down_rounded, color: JoynColors.primary, size: 20),
                          style: JoynTypography.bodyLarge.copyWith(fontSize: 14.5, color: JoynColors.primary),
                          onChanged: (val) {
                            HapticFeedback.selectionClick();
                            setState(() => _selectedTaxRate = val);
                          },
                          items: [
                            const DropdownMenuItem<TaxRateOption?>(value: null, child: Text('None')),
                            ...kTaxRateOptions.map((t) => DropdownMenuItem<TaxRateOption?>(value: t, child: Text(t.label))),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Expanded(child: _buildReadOnlyAmountBox(totals.taxAmount)),
            ],
          ),
          const SizedBox(height: 16),
          Container(height: 1, color: JoynColors.border),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Total Amount', style: JoynTypography.bodyLarge.copyWith(fontSize: 15.5, fontWeight: FontWeight.w800, color: JoynColors.primary)),
              Text('₹${totals.total.toStringAsFixed(2)}', style: JoynTypography.bodyLarge.copyWith(fontSize: 18, fontWeight: FontWeight.w800, color: JoynColors.primary)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTotalsRow(String label, double value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: JoynTypography.bodyMedium.copyWith(fontSize: 13, color: JoynColors.secondaryText)),
        Text('₹${value.toStringAsFixed(2)}', style: JoynTypography.bodyMedium.copyWith(fontSize: 14, fontWeight: FontWeight.w700, color: JoynColors.primary)),
      ],
    );
  }

  Widget _buildReadOnlyAmountBox(double value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 18),
        Container(
          height: 48,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          alignment: Alignment.centerLeft,
          decoration: BoxDecoration(color: JoynColors.border.withValues(alpha: 0.25), borderRadius: BorderRadius.circular(12), border: Border.all(color: JoynColors.border, width: 1.2)),
          child: Row(
            children: [
              const Icon(Icons.currency_rupee_rounded, size: 13, color: JoynColors.secondaryText),
              const SizedBox(width: 4),
              Expanded(child: Text(value.toStringAsFixed(2), style: JoynTypography.bodyMedium.copyWith(fontSize: 13.5, fontWeight: FontWeight.w700, color: JoynColors.secondaryText), overflow: TextOverflow.ellipsis)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFormField({
    required String label,
    required String hintText,
    required TextEditingController controller,
    TextInputType keyboardType = TextInputType.text,
    IconData? icon,
    ValueChanged<String>? onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: JoynTypography.bodyMedium.copyWith(fontSize: 13, fontWeight: FontWeight.w700, color: JoynColors.secondaryText)),
        const SizedBox(height: 6),
        Container(
          height: 54,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: JoynColors.border, width: 1.2), boxShadow: _Premium.fieldShadow),
          child: Row(
            children: [
              if (icon != null) ...[
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(color: JoynColors.primary.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(10)),
                  child: Icon(icon, size: 16, color: JoynColors.primary),
                ),
                const SizedBox(width: 10),
              ],
              Expanded(
                child: TextField(
                  controller: controller,
                  keyboardType: keyboardType,
                  onChanged: onChanged,
                  style: JoynTypography.bodyLarge.copyWith(fontSize: 15, fontWeight: FontWeight.w600),
                  decoration: InputDecoration(
                    hintText: hintText,
                    hintStyle: JoynTypography.bodyLarge.copyWith(color: JoynColors.secondaryText.withValues(alpha: 0.5), fontSize: 14.5, fontWeight: FontWeight.w500),
                    border: InputBorder.none,
                    isDense: true,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}