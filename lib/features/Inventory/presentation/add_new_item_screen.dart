import 'dart:io';
import 'dart:math';

import 'package:barcode_widget/barcode_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../../core/constants/tax_rates.dart';
import '../../../core/theme/joyn_colors.dart';
import '../../../core/theme/joyn_typography.dart';
import '../../../core/widgets/joyn_button.dart';
import '../../orders/data/sales_repository.dart';
import '../../orders/models/sales_models.dart';
import 'scan_code_screen.dart';
import '../../business_profile/presentation/widgets/image_crop_dialog.dart';

enum PricingTab { buying, selling }
enum TaxMode { inclusive, exclusive }
enum TaxVisibility { withTax, withoutTax }
enum BarcodeTab { barcode, qrCode }
enum BarcodeQtyMode { same, different }

class _AccentColors {
  static const addRed = Color(0xFFC0202B);
  static const addRedDark = Color(0xFF8E1620);
  static const toggleGreen = Color(0xFF16A34A);
  static const toggleBlue = Color(0xFF2563EB);
  static const togglePurple = Color(0xFF7C3AED);
}

class _Premium {
  static List<BoxShadow> cardShadow = [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.05),
      blurRadius: 20,
      offset: const Offset(0, 8),
    ),
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.025),
      blurRadius: 4,
      offset: const Offset(0, 1),
    ),
  ];

  static List<BoxShadow> fieldShadow = [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.035),
      blurRadius: 10,
      offset: const Offset(0, 3),
    ),
  ];

  static List<BoxShadow> chipShadow(Color color) => [
    BoxShadow(
      color: color.withValues(alpha: 0.28),
      blurRadius: 14,
      offset: const Offset(0, 6),
    ),
  ];

  static List<BoxShadow> floatingShadow(Color color) => [
    BoxShadow(
      color: color.withValues(alpha: 0.35),
      blurRadius: 16,
      offset: const Offset(0, 6),
    ),
  ];

  static LinearGradient gradient(Color color) => LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      color,
      Color.lerp(color, Colors.black, 0.18) ?? color,
    ],
  );

  static LinearGradient surfaceGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Colors.white,
      JoynColors.background,
    ],
  );
}

class _GradientButton extends StatelessWidget {
  const _GradientButton({
    required this.onPressed,
    required this.icon,
    required this.label,
    required this.color,
    this.compact = false,
  });

  final VoidCallback onPressed;
  final IconData icon;
  final String label;
  final Color color;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Ink(
      decoration: BoxDecoration(
        gradient: _Premium.gradient(color),
        borderRadius: BorderRadius.circular(14),
        boxShadow: _Premium.floatingShadow(color),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () {
            HapticFeedback.lightImpact();
            onPressed();
          },
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: compact ? 12 : 13),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 16, color: Colors.white),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: JoynTypography.buttonText.copyWith(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.2,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class AddNewItemScreen extends StatefulWidget {
  const AddNewItemScreen({super.key, this.existingItem});

  final InventoryItemModel? existingItem;

  @override
  State<AddNewItemScreen> createState() => _AddNewItemScreenState();
}

class _AddNewItemScreenState extends State<AddNewItemScreen> {
  final _salesRepository = SalesRepository();

  final _skuController = TextEditingController();
  final _itemNameController = TextEditingController();
  final _qtyController = TextEditingController();
  final _hsnSacController = TextEditingController();

  String _selectedUnit = 'Select Unit';
  String? _selectedCategory;
  String _selectedLocation = 'Select Location';

  bool _primaryUnitOnly = true;
  String _selectedSecondaryUnit = 'Select Unit';
  final _secondaryConversionController = TextEditingController();

  final List<String> _units = [
    'Select Unit', 'Pcs', 'Kg', 'Gram', 'Litre', 'ml',
    'Box', 'Dozen', 'Meter', 'Bag', 'Packet', 'Other',
  ];

  final List<String> _categories = [
    'Grocery', 'Electronics', 'Garments', 'Stationery', 'Other',
  ];

  final List<String> _locations = [
    'Select Location', 'Rack A1', 'Rack A2', 'Warehouse 1', 'Store Front',
  ];

  PricingTab _pricingTab = PricingTab.selling;
  final _buyingPriceController = TextEditingController();
  TaxVisibility _buyingTaxVisibility = TaxVisibility.withoutTax;
  TaxMode _buyingTaxMode = TaxMode.exclusive;
  TaxRateOption _buyingTaxRate = kTaxRateOptions.first;

  final _sellingPriceController = TextEditingController();
  TaxVisibility _sellingTaxVisibility = TaxVisibility.withoutTax;
  TaxMode _sellingTaxMode = TaxMode.exclusive;
  TaxRateOption _sellingTaxRate = kTaxRateOptions.first;

  BarcodeTab _barcodeTab = BarcodeTab.barcode;
  BarcodeQtyMode _barcodeQtyMode = BarcodeQtyMode.same;

  final _barcodeController = TextEditingController();
  final _qrValueController = TextEditingController();

  final List<String> _generatedCodes = [];
  final PageController _codePageController = PageController();
  int _currentCodePage = 0;

  String? _photoPath;
  static const double _standardPhotoSize = 180;
  bool _isSaving = false;

  bool get _isEditMode => widget.existingItem != null;

  @override
  void initState() {
    super.initState();
    _buyingPriceController.addListener(_onPriceChanged);
    _sellingPriceController.addListener(_onPriceChanged);
    _qtyController.addListener(_onQtyChanged);

    // Prefill if editing
    if (_isEditMode) {
      _prefillFromExistingItem();
    }
  }

  void _prefillFromExistingItem() {
    final item = widget.existingItem;
    if (item == null) return;

    _itemNameController.text = item.name;
    _qtyController.text = item.qty.toString();
    _hsnSacController.text = item.hsnSac;
    _buyingPriceController.text = item.purchasePrice.toString();
    _sellingPriceController.text = item.sellingPrice.toString();
    _barcodeController.text = item.barcode;
    _selectedUnit = item.unit;
    _selectedCategory = item.category.isNotEmpty ? item.category : null;
    _selectedLocation = item.location.isNotEmpty ? item.location : 'Select Location';

    // Add category to list if not exists
    if (item.category.isNotEmpty && !_categories.contains(item.category)) {
      _categories.add(item.category);
    }

    // Add location to list if not exists
    if (item.location.isNotEmpty && !_locations.contains(item.location)) {
      _locations.add(item.location);
    }

    // Set tax modes
    _buyingTaxMode = item.purchasePriceTaxMode == PriceTaxMode.withTax
        ? TaxMode.inclusive
        : TaxMode.exclusive;
    _sellingTaxMode = item.salePriceTaxMode == PriceTaxMode.withTax
        ? TaxMode.inclusive
        : TaxMode.exclusive;

    // Set tax rate
    for (final rate in kTaxRateOptions) {
      if (rate.rate == item.taxRatePercent) {
        _buyingTaxRate = rate;
        _sellingTaxRate = rate;
        break;
      }
    }
  }

  void _onPriceChanged() {
    if (mounted) setState(() {});
  }

  void _onQtyChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _itemNameController.dispose();
    _qtyController.removeListener(_onQtyChanged);
    _skuController.dispose();
    _qtyController.dispose();
    _hsnSacController.dispose();
    _secondaryConversionController.dispose();
    _buyingPriceController.removeListener(_onPriceChanged);
    _sellingPriceController.removeListener(_onPriceChanged);
    _buyingPriceController.dispose();
    _sellingPriceController.dispose();
    _barcodeController.dispose();
    _qrValueController.dispose();
    _codePageController.dispose();
    super.dispose();
  }

  void _ensureGeneratedCodesLength(int count) {
    final target = count.clamp(0, 500);
    if (_generatedCodes.length < target) {
      while (_generatedCodes.length < target) {
        _generatedCodes.add(_generateCode());
      }
    } else if (_generatedCodes.length > target) {
      _generatedCodes.removeRange(target, _generatedCodes.length);
    }
    if (_currentCodePage >= _generatedCodes.length) {
      _currentCodePage = _generatedCodes.isEmpty ? 0 : _generatedCodes.length - 1;
    }
  }

  void _regenerateAllCodes() {
    HapticFeedback.lightImpact();
    setState(() {
      for (var i = 0; i < _generatedCodes.length; i++) {
        _generatedCodes[i] = _generateCode();
      }
    });
  }

  void _regenerateCodeAt(int index) {
    if (index < 0 || index >= _generatedCodes.length) return;
    HapticFeedback.selectionClick();
    setState(() {
      _generatedCodes[index] = _generateCode();
    });
  }

  void _copyToClipboard(String value, String label) {
    if (value.isEmpty) return;
    HapticFeedback.lightImpact();
    Clipboard.setData(ClipboardData(text: value));
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_rounded, color: Colors.white, size: 18),
            const SizedBox(width: 10),
            Text('$label copied'),
          ],
        ),
        duration: const Duration(seconds: 2),
        backgroundColor: JoynColors.primary,
        behavior: SnackBarBehavior.floating,
        elevation: 6,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    );
  }

  String _generateCode() {
    final rand = Random();
    return List.generate(6, (_) => rand.nextInt(10)).join();
  }

  void _regenerateCode() {
    HapticFeedback.lightImpact();
    setState(() {
      final code = _generateCode();
      if (_barcodeTab == BarcodeTab.barcode) {
        _barcodeController.text = code;
      } else {
        _qrValueController.text = code;
      }
    });
  }

  Future<void> _openScanner() async {
    final result = await Navigator.of(context).push<String>(
      MaterialPageRoute(builder: (_) => const ScanCodeScreen()),
    );
    if (result != null && result.isNotEmpty) {
      setState(() {
        if (_barcodeTab == BarcodeTab.barcode) {
          _barcodeController.text = result;
        } else {
          _qrValueController.text = result;
        }
      });
    }
  }

  Future<void> _createLocation() async {
    final controller = TextEditingController();
    final focusNode = FocusNode();

    try {
      final result = await showDialog<String>(
        context: context,
        useRootNavigator: false,
        builder: (dialogContext) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (focusNode.canRequestFocus) {
              focusNode.requestFocus();
            }
          });
          return AlertDialog(
            backgroundColor: JoynColors.background,
            elevation: 8,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: Text(
              'New Location',
              style: JoynTypography.titleMedium.copyWith(
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
            content: TextField(
              controller: controller,
              focusNode: focusNode,
              autofocus: false,
              decoration: InputDecoration(
                hintText: 'Enter Warehouse location name',
                filled: true,
                fillColor: JoynColors.chipBackground,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () {
                  final value = controller.text.trim();
                  Navigator.of(dialogContext).pop(value);
                },
                style: TextButton.styleFrom(
                  foregroundColor: _AccentColors.addRed,
                ),
                child: const Text(
                  'Add',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          );
        },
      );

      if (!mounted) return;

      if (result != null && result.isNotEmpty) {
        setState(() {
          if (!_locations.contains(result)) {
            _locations.add(result);
          }
          _selectedLocation = result;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Location "$result" added'),
            backgroundColor: JoynColors.primary,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 1),
            margin: const EdgeInsets.all(16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not add location: $e'),
          backgroundColor: JoynColors.error,
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      );
    } finally {
      controller.dispose();
      focusNode.dispose();
    }
  }

  Future<void> _confirmDeleteLocation(String location) async {
    final confirmed = await showDialog<bool>(
      context: context,
      useRootNavigator: false,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: JoynColors.background,
        elevation: 8,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Delete Location?', style: JoynTypography.titleMedium.copyWith(fontSize: 17, fontWeight: FontWeight.w800)),
        content: Text('Remove "$location" from your locations list?', style: JoynTypography.bodyMedium.copyWith(fontSize: 13.5, color: JoynColors.secondaryText)),
        actions: [
          TextButton(onPressed: () => Navigator.of(dialogContext).pop(false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text('Delete', style: TextStyle(color: JoynColors.error, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      setState(() {
        _locations.remove(location);
        if (_selectedLocation == location) _selectedLocation = 'Select Location';
      });
    }
  }

  Future<void> _createCategory() async {
    final controller = TextEditingController();
    final focusNode = FocusNode();

    try {
      final result = await showDialog<String>(
        context: context,
        useRootNavigator: false,
        builder: (dialogContext) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (focusNode.canRequestFocus) {
              focusNode.requestFocus();
            }
          });
          return AlertDialog(
            backgroundColor: JoynColors.background,
            elevation: 8,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: Text(
              'New Category',
              style: JoynTypography.titleMedium.copyWith(
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
            content: TextField(
              controller: controller,
              focusNode: focusNode,
              autofocus: false,
              decoration: InputDecoration(
                hintText: 'Enter category name',
                filled: true,
                fillColor: JoynColors.chipBackground,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () {
                  final value = controller.text.trim();
                  Navigator.of(dialogContext).pop(value);
                },
                style: TextButton.styleFrom(
                  foregroundColor: _AccentColors.addRed,
                ),
                child: const Text(
                  'Add',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          );
        },
      );

      if (!mounted) return;

      if (result != null && result.isNotEmpty) {
        setState(() {
          if (!_categories.contains(result)) {
            _categories.add(result);
          }
          _selectedCategory = result;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Category "$result" added'),
            backgroundColor: JoynColors.primary,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 1),
            margin: const EdgeInsets.all(16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not add category: $e'),
          backgroundColor: JoynColors.error,
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      );
    } finally {
      controller.dispose();
      focusNode.dispose();
    }
  }

  Future<void> _confirmDeleteCategory(String category) async {
    final confirmed = await showDialog<bool>(
      context: context,
      useRootNavigator: false,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: JoynColors.background,
        elevation: 8,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Delete Category?', style: JoynTypography.titleMedium.copyWith(fontSize: 17, fontWeight: FontWeight.w800)),
        content: Text('Remove "$category" from your categories list?', style: JoynTypography.bodyMedium.copyWith(fontSize: 13.5, color: JoynColors.secondaryText)),
        actions: [
          TextButton(onPressed: () => Navigator.of(dialogContext).pop(false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text('Delete', style: TextStyle(color: JoynColors.error, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      setState(() {
        _categories.remove(category);
        if (_selectedCategory == category) _selectedCategory = null;
      });
    }
  }

  Future<void> _openCategoryPicker() async {
    await showModalBottomSheet<void>(
      context: context,
      useRootNavigator: false,
      backgroundColor: JoynColors.background,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (sheetContext, setSheetState) {
            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 40, height: 4.5,
                      margin: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(color: JoynColors.border, borderRadius: BorderRadius.circular(3)),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Item Category', style: JoynTypography.titleMedium.copyWith(fontSize: 17, fontWeight: FontWeight.w800)),
                          InkWell(
                            onTap: () {
                              Navigator.pop(sheetContext);
                              Future.delayed(const Duration(milliseconds: 200), () {
                                if (mounted) _createCategory();
                              });
                            },
                            borderRadius: BorderRadius.circular(20),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: _AccentColors.addRed.withValues(alpha: 0.08),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.add_circle_outline_rounded, size: 15, color: _AccentColors.addRed),
                                  const SizedBox(width: 4),
                                  Text('Add New', style: JoynTypography.bodyMedium.copyWith(fontSize: 12.5, fontWeight: FontWeight.w700, color: _AccentColors.addRed)),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Text('Long-press a category to delete it', style: JoynTypography.caption.copyWith(fontSize: 11.5, color: JoynColors.secondaryText)),
                    ),
                    const SizedBox(height: 8),
                    if (_categories.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 32),
                        child: Text('No categories yet', style: JoynTypography.subtitle.copyWith(fontSize: 13.5)),
                      )
                    else
                      ConstrainedBox(
                        constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.5),
                        child: ListView.builder(
                          shrinkWrap: true,
                          itemCount: _categories.length,
                          itemBuilder: (context, index) {
                            final category = _categories[index];
                            final isSelected = _selectedCategory == category;
                            return InkWell(
                              onTap: () {
                                HapticFeedback.selectionClick();
                                setState(() => _selectedCategory = category);
                                Navigator.pop(sheetContext);
                              },
                              onLongPress: () async {
                                await _confirmDeleteCategory(category);
                                setSheetState(() {});
                              },
                              child: Container(
                                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                decoration: BoxDecoration(
                                  color: isSelected ? JoynColors.chipBackground : Colors.transparent,
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        category,
                                        style: JoynTypography.bodyLarge.copyWith(fontSize: 15, fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500),
                                      ),
                                    ),
                                    if (isSelected)
                                      Container(
                                        padding: const EdgeInsets.all(3),
                                        decoration: BoxDecoration(
                                          gradient: _Premium.gradient(JoynColors.primary),
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(Icons.check_rounded, size: 13, color: Colors.white),
                                      ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
    if (mounted) setState(() {});
  }

  Future<void> _openLocationPicker() async {
    await showModalBottomSheet<void>(
      context: context,
      useRootNavigator: false,
      backgroundColor: JoynColors.background,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (sheetContext, setSheetState) {
            final selectable = _locations.where((l) => l != 'Select Location').toList();
            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 40, height: 4.5,
                      margin: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(color: JoynColors.border, borderRadius: BorderRadius.circular(3)),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Item Location', style: JoynTypography.titleMedium.copyWith(fontSize: 17, fontWeight: FontWeight.w800)),
                          InkWell(
                            onTap: () {
                              Navigator.pop(sheetContext);
                              Future.delayed(const Duration(milliseconds: 200), () {
                                if (mounted) _createLocation();
                              });
                            },
                            borderRadius: BorderRadius.circular(20),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: _AccentColors.addRed.withValues(alpha: 0.08),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.add_circle_outline_rounded, size: 15, color: _AccentColors.addRed),
                                  const SizedBox(width: 4),
                                  Text('Add New', style: JoynTypography.bodyMedium.copyWith(fontSize: 12.5, fontWeight: FontWeight.w700, color: _AccentColors.addRed)),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Text('Long-press a location to delete it', style: JoynTypography.caption.copyWith(fontSize: 11.5, color: JoynColors.secondaryText)),
                    ),
                    const SizedBox(height: 8),
                    if (selectable.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 32),
                        child: Text('No locations yet', style: JoynTypography.subtitle.copyWith(fontSize: 13.5)),
                      )
                    else
                      ConstrainedBox(
                        constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.5),
                        child: ListView.builder(
                          shrinkWrap: true,
                          itemCount: selectable.length,
                          itemBuilder: (context, index) {
                            final location = selectable[index];
                            final isSelected = _selectedLocation == location;
                            return InkWell(
                              onTap: () {
                                HapticFeedback.selectionClick();
                                setState(() => _selectedLocation = location);
                                Navigator.pop(sheetContext);
                              },
                              onLongPress: () async {
                                await _confirmDeleteLocation(location);
                                setSheetState(() {});
                              },
                              child: Container(
                                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                decoration: BoxDecoration(
                                  color: isSelected ? JoynColors.chipBackground : Colors.transparent,
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        location,
                                        style: JoynTypography.bodyLarge.copyWith(fontSize: 15, fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500),
                                      ),
                                    ),
                                    if (isSelected)
                                      Container(
                                        padding: const EdgeInsets.all(3),
                                        decoration: BoxDecoration(
                                          gradient: _Premium.gradient(JoynColors.primary),
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(Icons.check_rounded, size: 13, color: Colors.white),
                                      ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
    if (mounted) setState(() {});
  }

  Future<void> _pickAndCropPhoto(ImageSource source) async {
    try {
      final picker = ImagePicker();
      final image = await picker.pickImage(source: source, imageQuality: 90, maxWidth: 1600, maxHeight: 1600);
      if (image == null || !mounted) return;

      final String? croppedPath = await showDialog<String>(
        context: context,
        useRootNavigator: false,
        builder: (context) => ImageCropDialog(imagePath: image.path, title: 'Crop & Adjust Item Photo'),
      );
      if (croppedPath != null && mounted) {
        setState(() => _photoPath = croppedPath);
      }
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(source == ImageSource.camera ? 'Unable to open camera.' : 'Unable to open gallery.'),
          backgroundColor: JoynColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _openPhotoSourceSheet() async {
    await showModalBottomSheet<void>(
      context: context,
      useRootNavigator: false,
      backgroundColor: JoynColors.background,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40, height: 4.5,
                  margin: const EdgeInsets.only(bottom: 8),
                  decoration: BoxDecoration(color: JoynColors.border, borderRadius: BorderRadius.circular(3)),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text('Add Item Photo', style: JoynTypography.titleMedium.copyWith(fontSize: 16, fontWeight: FontWeight.w800)),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text('Photo will be cropped to a standard square size', style: JoynTypography.caption.copyWith(fontSize: 11.5, color: JoynColors.secondaryText)),
                  ),
                ),
                const SizedBox(height: 6),
                _buildSheetTile(
                  icon: Icons.photo_camera_outlined,
                  label: 'Take Photo',
                  onTap: () {
                    Navigator.pop(sheetContext);
                    _pickAndCropPhoto(ImageSource.camera);
                  },
                ),
                _buildSheetTile(
                  icon: Icons.photo_library_outlined,
                  label: 'Choose from Gallery',
                  onTap: () {
                    Navigator.pop(sheetContext);
                    _pickAndCropPhoto(ImageSource.gallery);
                  },
                ),
                if (_photoPath != null) ...[
                  _buildSheetTile(
                    icon: Icons.crop_rounded,
                    label: 'Re-crop Current Photo',
                    onTap: () async {
                      Navigator.pop(sheetContext);
                      final path = _photoPath;
                      if (path == null || !mounted) return;
                      final croppedPath = await showDialog<String>(
                        context: context,
                        useRootNavigator: false,
                        builder: (context) => ImageCropDialog(imagePath: path, title: 'Crop & Adjust Item Photo'),
                      );
                      if (croppedPath != null && mounted) {
                        setState(() => _photoPath = croppedPath);
                      }
                    },
                  ),
                  _buildSheetTile(
                    icon: Icons.delete_outline_rounded,
                    label: 'Remove Photo',
                    isDestructive: true,
                    onTap: () {
                      Navigator.pop(sheetContext);
                      setState(() => _photoPath = null);
                    },
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSheetTile({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    final color = isDestructive ? JoynColors.error : _AccentColors.addRed;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
        child: Row(
          children: [
            Container(
              width: 38, height: 38,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.09),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 19),
            ),
            const SizedBox(width: 14),
            Text(
              label,
              style: JoynTypography.bodyLarge.copyWith(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: isDestructive ? JoynColors.error : JoynColors.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  ({double base, double taxAmount, double finalPrice}) _calculateTax({
    required double price,
    required TaxMode mode,
    required double ratePercent,
  }) {
    if (mode == TaxMode.inclusive) {
      final base = price / (1 + (ratePercent / 100));
      final taxAmount = price - base;
      return (base: base, taxAmount: taxAmount, finalPrice: price);
    } else {
      final taxAmount = price * (ratePercent / 100);
      final finalPrice = price + taxAmount;
      return (base: price, taxAmount: taxAmount, finalPrice: finalPrice);
    }
  }

  Future<void> _saveToDatabase() async {
    if (_itemNameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Item Name is required'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: JoynColors.error,
          margin: const EdgeInsets.all(16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final item = InventoryItemModel(
        id: widget.existingItem?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
        name: _itemNameController.text.trim(),
        qty: int.tryParse(_qtyController.text.trim()) ?? 0,
        barcode: _barcodeController.text.trim(),
        unit: _selectedUnit == 'Select Unit' ? 'Pcs' : _selectedUnit,
        category: _selectedCategory ?? '',
        hsnSac: _hsnSacController.text.trim(),
        location: _selectedLocation == 'Select Location' ? '' : _selectedLocation,
        barcodeMode: _barcodeQtyMode == BarcodeQtyMode.different ? 'separate' : 'same',
        purchasePrice: double.tryParse(_buyingPriceController.text.trim()) ?? 0,
        sellingPrice: double.tryParse(_sellingPriceController.text.trim()) ?? 0,
        purchasePriceTaxMode: _buyingTaxMode == TaxMode.inclusive ? PriceTaxMode.withTax : PriceTaxMode.withoutTax,
        salePriceTaxMode: _sellingTaxMode == TaxMode.inclusive ? PriceTaxMode.withTax : PriceTaxMode.withoutTax,
        taxRateLabel: _sellingTaxRate.label,
        taxRatePercent: _sellingTaxRate.rate,
        stock: int.tryParse(_qtyController.text.trim()) ?? 0,
        createdAt: widget.existingItem?.createdAt ?? DateTime.now(),
      );

      debugPrint('Saving item: ${item.toDb()}');
      debugPrint('Is Edit Mode: $_isEditMode');

      if (_isEditMode) {
        await _salesRepository.updateItem(item);
        debugPrint('Item updated successfully');
      } else {
        await _salesRepository.insertItem(item);
        debugPrint('Item inserted successfully');
      }

      // Verify save
      final savedItems = await _salesRepository.getItems();
      debugPrint('Total items after save: ${savedItems.length}');

      if (!mounted) return;

      HapticFeedback.mediumImpact();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle_rounded, color: Colors.white, size: 18),
              const SizedBox(width: 10),
              Text(_isEditMode ? 'Item updated successfully!' : 'Item saved successfully!'),
            ],
          ),
          backgroundColor: JoynColors.primary,
          behavior: SnackBarBehavior.floating,
          elevation: 6,
          margin: const EdgeInsets.all(16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
      );

      // Pop with success result
      Navigator.of(context).pop(true);
    } catch (e) {
      debugPrint('Error saving item: $e');
      if (!mounted) return;
      setState(() => _isSaving = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to save item: $e'),
          backgroundColor: JoynColors.error,
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: JoynColors.background,
      extendBodyBehindAppBar: false,
      appBar: AppBar(
        elevation: 0,
        scrolledUnderElevation: 0.5,
        backgroundColor: JoynColors.background,
        leading: IconButton(
          icon: Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(color: JoynColors.chipBackground, shape: BoxShape.circle),
            child: const Icon(Icons.arrow_back_rounded, size: 18),
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
        centerTitle: true,
        title: Text(
          _isEditMode ? 'Edit Item' : 'Add New Item',
          style: JoynTypography.titleMedium.copyWith(fontSize: 18, fontWeight: FontWeight.w800, letterSpacing: -0.2),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
          children: [
            _buildSectionHeader(1, 'Item Details', Icons.inventory_2_outlined),
            const SizedBox(height: 16),
            _buildItemDetailsCard(),
            const SizedBox(height: 30),
            _buildSectionHeader(2, 'Pricing', Icons.sell_outlined),
            const SizedBox(height: 16),
            _buildPricingCard(),
            const SizedBox(height: 30),
            _buildSectionHeader(3, 'Barcode', Icons.qr_code_2_rounded),
            const SizedBox(height: 16),
            _buildBarcodeCard(),
            const SizedBox(height: 30),
            _buildSectionHeader(4, 'Photo', Icons.image_outlined),
            const SizedBox(height: 16),
            _buildPhotoPicker(),
            const SizedBox(height: 30),
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                boxShadow: _Premium.floatingShadow(JoynColors.primary),
              ),
              child: JoynButton(
                text: _isSaving ? 'Saving...' : (_isEditMode ? 'Update Item' : 'Save Item'),
                variant: JoynButtonVariant.filled,
                onPressed: _isSaving ? null : () {
                  HapticFeedback.mediumImpact();
                  _saveToDatabase();
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(int number, String title, IconData icon) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 30, height: 30,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                gradient: _Premium.gradient(Colors.black87),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(color: Colors.black.withValues(alpha: 0.22), blurRadius: 8, offset: const Offset(0, 3)),
                ],
              ),
              child: Text('$number', style: JoynTypography.caption.copyWith(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 13)),
            ),
            const SizedBox(width: 10),
            Icon(icon, size: 17, color: JoynColors.primary),
            const SizedBox(width: 6),
            Text(title, style: JoynTypography.bodyLarge.copyWith(fontWeight: FontWeight.w800, fontSize: 17, letterSpacing: -0.2, color: JoynColors.primary)),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          height: 1.2,
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [JoynColors.border, JoynColors.border.withValues(alpha: 0.0)]),
          ),
        ),
      ],
    );
  }

  Widget _buildItemDetailsCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: _Premium.surfaceGradient,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: JoynColors.border, width: 1.2),
        boxShadow: _Premium.cardShadow,
      ),
      child: Column(
        children: [
          _buildFormField(label: 'Item Name *', hintText: 'Enter item name', controller: _itemNameController, icon: Icons.inventory_2_outlined),
          const SizedBox(height: 14),
          _buildFormField(label: 'SKU', controller: _skuController, hintText: 'Enter SKU', icon: Icons.inventory_2_outlined),
          const SizedBox(height: 14),
          _buildFormField(label: 'Qty', hintText: '0', controller: _qtyController, keyboardType: TextInputType.number, icon: Icons.numbers_rounded),
          const SizedBox(height: 14),
          _buildUnitDropdown(),
          const SizedBox(height: 14),
          _buildSecondaryUnitSection(),
          const SizedBox(height: 14),
          _buildCategoryPickerField(),
          const SizedBox(height: 14),
          _buildFormField(label: 'HSN / SAC Code', hintText: 'Enter HSN or SAC code', controller: _hsnSacController, icon: Icons.receipt_long_outlined),
          const SizedBox(height: 14),
          _buildLocationField(),
        ],
      ),
    );
  }

  Widget _buildUnitDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Unit', style: JoynTypography.bodyMedium.copyWith(fontSize: 13, fontWeight: FontWeight.w700, color: JoynColors.secondaryText)),
        const SizedBox(height: 6),
        Container(
          height: 54,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: JoynColors.border, width: 1.2),
            boxShadow: _Premium.fieldShadow,
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(color: JoynColors.primary.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(10)),
                child: const Icon(Icons.straighten_rounded, size: 16, color: JoynColors.primary),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedUnit,
                    isExpanded: true,
                    icon: const Icon(Icons.keyboard_arrow_down_rounded, color: JoynColors.primary, size: 20),
                    style: JoynTypography.bodyLarge.copyWith(fontSize: 15, color: JoynColors.primary),
                    borderRadius: BorderRadius.circular(16),
                    onChanged: (val) {
                      HapticFeedback.selectionClick();
                      setState(() => _selectedUnit = val ?? _selectedUnit);
                    },
                    items: _units.map((u) => DropdownMenuItem(value: u, child: Text(u))).toList(),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSecondaryUnitSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Secondary Unit',
                    style: JoynTypography.bodyMedium.copyWith(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: JoynColors.secondaryText,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _primaryUnitOnly
                        ? 'Only primary unit will be used'
                        : 'Track item in a second unit too',
                    style: JoynTypography.caption.copyWith(
                      fontSize: 11.5,
                      color: JoynColors.secondaryText,
                    ),
                  ),
                ],
              ),
            ),
            Switch.adaptive(
              value: !_primaryUnitOnly,
              onChanged: (enabled) {
                HapticFeedback.selectionClick();
                setState(() => _primaryUnitOnly = !enabled);
              },
              activeTrackColor: _AccentColors.togglePurple,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ],
        ),
        if (!_primaryUnitOnly) ...[
          const SizedBox(height: 10),
          Container(
            height: 54,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: JoynColors.border, width: 1.2),
              boxShadow: _Premium.fieldShadow,
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: JoynColors.primary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.straighten_rounded, size: 16, color: JoynColors.primary),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _selectedSecondaryUnit,
                      isExpanded: true,
                      icon: const Icon(Icons.keyboard_arrow_down_rounded, color: JoynColors.primary, size: 20),
                      style: JoynTypography.bodyLarge.copyWith(fontSize: 15, color: JoynColors.primary),
                      borderRadius: BorderRadius.circular(16),
                      onChanged: (val) {
                        HapticFeedback.selectionClick();
                        setState(() => _selectedSecondaryUnit = val ?? _selectedSecondaryUnit);
                      },
                      items: _units.map((u) => DropdownMenuItem(value: u, child: Text(u))).toList(),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Container(
            height: 54,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: JoynColors.border, width: 1.2),
              boxShadow: _Premium.fieldShadow,
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: JoynColors.primary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.swap_horiz_rounded, size: 16, color: JoynColors.primary),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    controller: _secondaryConversionController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    style: JoynTypography.bodyLarge.copyWith(fontSize: 15, fontWeight: FontWeight.w600),
                    decoration: InputDecoration(
                      hintText: '1 $_selectedUnit = ? $_selectedSecondaryUnit',
                      hintStyle: JoynTypography.bodyLarge.copyWith(
                        color: JoynColors.secondaryText.withValues(alpha: 0.6),
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                      border: InputBorder.none,
                      isDense: true,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildCategoryPickerField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Item Category', style: JoynTypography.bodyMedium.copyWith(fontSize: 13, fontWeight: FontWeight.w700, color: JoynColors.secondaryText)),
        const SizedBox(height: 6),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: InkWell(
                onTap: _openCategoryPicker,
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  height: 54,
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: JoynColors.border, width: 1.2),
                    boxShadow: _Premium.fieldShadow,
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(color: JoynColors.primary.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(10)),
                        child: const Icon(Icons.category_outlined, size: 16, color: JoynColors.primary),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          _selectedCategory ?? 'Select Category',
                          style: JoynTypography.bodyLarge.copyWith(fontSize: 15, color: _selectedCategory != null ? JoynColors.primary : JoynColors.secondaryText),
                        ),
                      ),
                      const Icon(Icons.keyboard_arrow_down_rounded, color: JoynColors.primary, size: 20),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            _buildInlineAddButton(onTap: _createCategory),
          ],
        ),
      ],
    );
  }

  Widget _buildLocationField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Location', style: JoynTypography.bodyMedium.copyWith(fontSize: 13, fontWeight: FontWeight.w700, color: JoynColors.secondaryText)),
        const SizedBox(height: 6),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: InkWell(
                onTap: _openLocationPicker,
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  height: 54,
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: JoynColors.border, width: 1.2),
                    boxShadow: _Premium.fieldShadow,
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(color: JoynColors.primary.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(10)),
                        child: const Icon(Icons.place_outlined, size: 16, color: JoynColors.primary),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          _selectedLocation,
                          style: JoynTypography.bodyLarge.copyWith(fontSize: 15, color: _selectedLocation != 'Select Location' ? JoynColors.primary : JoynColors.secondaryText),
                        ),
                      ),
                      const Icon(Icons.keyboard_arrow_down_rounded, color: JoynColors.primary, size: 20),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            _buildInlineAddButton(onTap: _createLocation),
          ],
        ),
      ],
    );
  }

  Widget _buildInlineAddButton({required VoidCallback onTap}) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          HapticFeedback.lightImpact();
          onTap();
        },
        borderRadius: BorderRadius.circular(16),
        child: Container(
          height: 54,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            gradient: _Premium.gradient(_AccentColors.addRed),
            borderRadius: BorderRadius.circular(16),
            boxShadow: _Premium.chipShadow(_AccentColors.addRed),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: const [
              Icon(Icons.add_rounded, color: Colors.white, size: 18),
              SizedBox(width: 4),
              Text(
                'Add',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPricingCard() {
    final isSelling = _pricingTab == PricingTab.selling;
    final priceController = isSelling ? _sellingPriceController : _buyingPriceController;
    final taxVisibility = isSelling ? _sellingTaxVisibility : _buyingTaxVisibility;
    final taxMode = isSelling ? _sellingTaxMode : _buyingTaxMode;
    final taxRate = isSelling ? _sellingTaxRate : _buyingTaxRate;
    final hasTax = taxVisibility == TaxVisibility.withTax;
    final enteredPrice = double.tryParse(priceController.text.trim()) ?? 0;
    final taxResult = hasTax && enteredPrice > 0
        ? _calculateTax(price: enteredPrice, mode: taxMode, ratePercent: taxRate.rate)
        : null;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: _Premium.surfaceGradient,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: JoynColors.border, width: 1.2),
        boxShadow: _Premium.cardShadow,
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(color: JoynColors.chipBackground, borderRadius: BorderRadius.circular(16)),
            child: Row(
              children: [
                Expanded(
                  child: _buildPricingTab(
                    label: 'Buying',
                    icon: Icons.arrow_downward_rounded,
                    isSelected: !isSelling,
                    onTap: () {
                      HapticFeedback.selectionClick();
                      setState(() => _pricingTab = PricingTab.buying);
                    },
                  ),
                ),
                Expanded(
                  child: _buildPricingTab(
                    label: 'Selling',
                    icon: Icons.arrow_upward_rounded,
                    isSelected: isSelling,
                    onTap: () {
                      HapticFeedback.selectionClick();
                      setState(() => _pricingTab = PricingTab.selling);
                    },
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Container(
            height: 54,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: JoynColors.border, width: 1.2),
              boxShadow: _Premium.fieldShadow,
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(color: JoynColors.primary.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(10)),
                  child: const Icon(Icons.currency_rupee_rounded, size: 16, color: JoynColors.primary),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    controller: priceController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    style: JoynTypography.bodyLarge.copyWith(fontSize: 15.5, fontWeight: FontWeight.w600),
                    decoration: InputDecoration(
                      hintText: isSelling ? 'Selling Price (Per Unit)' : 'Buying Price (Per Unit)',
                      hintStyle: JoynTypography.bodyLarge.copyWith(color: JoynColors.secondaryText.withValues(alpha: 0.6), fontSize: 14.5, fontWeight: FontWeight.w500),
                      border: InputBorder.none,
                      isDense: true,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(hasTax ? 'With Tax' : 'Without Tax', style: JoynTypography.bodyMedium.copyWith(fontSize: 13.5, fontWeight: FontWeight.w700, color: JoynColors.primary)),
                    const SizedBox(height: 2),
                    Text(hasTax ? 'Tax will be applied to this price' : 'No tax will be applied', style: JoynTypography.caption.copyWith(fontSize: 11.5, color: JoynColors.secondaryText)),
                  ],
                ),
              ),
              Switch.adaptive(
                value: hasTax,
                onChanged: (withTax) {
                  HapticFeedback.selectionClick();
                  setState(() {
                    final newVisibility = withTax ? TaxVisibility.withTax : TaxVisibility.withoutTax;
                    if (isSelling) {
                      _sellingTaxVisibility = newVisibility;
                    } else {
                      _buyingTaxVisibility = newVisibility;
                    }
                  });
                },
                activeTrackColor: _AccentColors.toggleGreen,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ],
          ),
          if (hasTax) ...[
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(taxMode == TaxMode.inclusive ? 'Inclusive of Tax' : 'Exclusive of Tax', style: JoynTypography.bodyMedium.copyWith(fontSize: 13.5, fontWeight: FontWeight.w700, color: JoynColors.primary)),
                Switch.adaptive(
                  value: taxMode == TaxMode.inclusive,
                  onChanged: (isInclusive) {
                    HapticFeedback.selectionClick();
                    setState(() {
                      final newMode = isInclusive ? TaxMode.inclusive : TaxMode.exclusive;
                      if (isSelling) {
                        _sellingTaxMode = newMode;
                      } else {
                        _buyingTaxMode = newMode;
                      }
                    });
                  },
                  activeTrackColor: _AccentColors.toggleGreen,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerLeft,
              child: Text('Tax Rate', style: JoynTypography.caption.copyWith(fontSize: 12, fontWeight: FontWeight.w600, color: JoynColors.secondaryText)),
            ),
            const SizedBox(height: 6),
            Container(
              height: 52,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: JoynColors.border, width: 1.2),
                boxShadow: _Premium.fieldShadow,
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<TaxRateOption>(
                  value: taxRate,
                  isExpanded: true,
                  icon: const Icon(Icons.keyboard_arrow_down_rounded, color: JoynColors.primary, size: 20),
                  style: JoynTypography.bodyLarge.copyWith(fontSize: 15, color: JoynColors.primary),
                  borderRadius: BorderRadius.circular(14),
                  onChanged: (val) {
                    if (val == null) return;
                    HapticFeedback.selectionClick();
                    setState(() {
                      if (isSelling) {
                        _sellingTaxRate = val;
                      } else {
                        _buyingTaxRate = val;
                      }
                    });
                  },
                  selectedItemBuilder: (context) {
                    return kTaxRateOptions.map((t) => Align(
                      alignment: Alignment.centerLeft,
                      child: Text(t.label, style: JoynTypography.bodyLarge.copyWith(fontSize: 15)),
                    )).toList();
                  },
                  items: kTaxRateOptions.map((t) {
                    return DropdownMenuItem<TaxRateOption>(
                      value: t,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(t.label, style: JoynTypography.bodyLarge.copyWith(fontSize: 14)),
                          Text('${t.rate}%', style: JoynTypography.caption.copyWith(fontSize: 13, color: JoynColors.secondaryText)),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
            if (taxResult != null) ...[
              const SizedBox(height: 14),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [JoynColors.chipBackground, JoynColors.primary.withValues(alpha: 0.05)],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: JoynColors.primary.withValues(alpha: 0.08), width: 1),
                ),
                child: Column(
                  children: [
                    _buildTaxRow('Base Price', taxResult.base),
                    const SizedBox(height: 8),
                    _buildTaxRow('${taxMode == TaxMode.inclusive ? 'Tax Included' : 'Tax Added'} (${taxRate.rate}%)', taxResult.taxAmount),
                    const SizedBox(height: 10),
                    Container(height: 1, color: JoynColors.border),
                    const SizedBox(height: 10),
                    _buildTaxRow('Final Price', taxResult.finalPrice, emphasize: true),
                  ],
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }

  Widget _buildTaxRow(String label, double value, {bool emphasize = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: JoynTypography.bodyMedium.copyWith(fontSize: emphasize ? 13.5 : 12.5, fontWeight: emphasize ? FontWeight.w700 : FontWeight.w500, color: emphasize ? JoynColors.primary : JoynColors.secondaryText)),
        Text('₹${value.toStringAsFixed(2)}', style: JoynTypography.bodyMedium.copyWith(fontSize: emphasize ? 15.5 : 12.5, fontWeight: emphasize ? FontWeight.w800 : FontWeight.w600, color: emphasize ? _AccentColors.addRed : JoynColors.primary)),
      ],
    );
  }

  Widget _buildPricingTab({required String label, required IconData icon, required bool isSelected, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(13),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
        height: 46,
        decoration: BoxDecoration(
          gradient: isSelected ? _Premium.gradient(JoynColors.primary) : null,
          color: isSelected ? null : Colors.transparent,
          borderRadius: BorderRadius.circular(13),
          boxShadow: isSelected ? _Premium.chipShadow(JoynColors.primary) : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 16, color: isSelected ? Colors.white : JoynColors.secondaryText),
            const SizedBox(width: 6),
            Text(label, style: JoynTypography.bodyMedium.copyWith(fontSize: 14, fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500, color: isSelected ? Colors.white : JoynColors.secondaryText)),
          ],
        ),
      ),
    );
  }

  Widget _buildBarcodeCard() {
    final isQr = _barcodeTab == BarcodeTab.qrCode;
    final controller = isQr ? _qrValueController : _barcodeController;
    final isDifferentMode = _barcodeQtyMode == BarcodeQtyMode.different;
    final qty = int.tryParse(_qtyController.text.trim()) ?? 0;

    if (isDifferentMode) {
      _ensureGeneratedCodesLength(qty);
    }

    final hasValue = controller.text.trim().isNotEmpty;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: _Premium.surfaceGradient,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: JoynColors.border, width: 1.2),
        boxShadow: _Premium.cardShadow,
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _buildOutlinedTab(
                  label: 'Barcode',
                  icon: Icons.view_week_rounded,
                  isSelected: !isQr,
                  onTap: () {
                    HapticFeedback.selectionClick();
                    setState(() => _barcodeTab = BarcodeTab.barcode);
                  },
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildOutlinedTab(
                  label: 'QR Code',
                  icon: Icons.qr_code_rounded,
                  isSelected: isQr,
                  onTap: () {
                    HapticFeedback.selectionClick();
                    setState(() => _barcodeTab = BarcodeTab.qrCode);
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isDifferentMode ? 'Different Barcode for each Qty' : 'Same Barcode for all Qty',
                      style: JoynTypography.bodyMedium.copyWith(fontSize: 13.5, fontWeight: FontWeight.w700, color: JoynColors.primary),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      isDifferentMode ? 'A unique code will be generated per unit' : 'One code will be used for the whole quantity',
                      style: JoynTypography.caption.copyWith(fontSize: 11.5, color: JoynColors.secondaryText),
                    ),
                  ],
                ),
              ),
              Switch.adaptive(
                value: isDifferentMode,
                onChanged: (isDifferent) {
                  HapticFeedback.selectionClick();
                  setState(() => _barcodeQtyMode = isDifferent ? BarcodeQtyMode.different : BarcodeQtyMode.same);
                },
                activeTrackColor: _AccentColors.toggleBlue,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ],
          ),
          const SizedBox(height: 14),
          Container(height: 1, color: JoynColors.border),
          const SizedBox(height: 14),
          if (!isDifferentMode) ...[
            Align(
              alignment: Alignment.centerLeft,
              child: Text(isQr ? 'QR Code Value' : 'Barcode', style: JoynTypography.caption.copyWith(fontSize: 12, color: JoynColors.secondaryText, fontWeight: FontWeight.w700)),
            ),
            const SizedBox(height: 6),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Container(
                    height: 52,
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: JoynColors.border, width: 1.2),
                      boxShadow: _Premium.fieldShadow,
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.qr_code_rounded, size: 18, color: JoynColors.secondaryText),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextField(
                            controller: controller,
                            style: JoynTypography.bodyLarge.copyWith(fontSize: 15, fontWeight: FontWeight.w600),
                            onChanged: (_) => setState(() {}),
                            decoration: InputDecoration(
                              hintText: isQr ? 'QR Code Value' : 'Barcode',
                              hintStyle: JoynTypography.bodyLarge.copyWith(color: JoynColors.secondaryText.withValues(alpha: 0.6), fontSize: 14.5, fontWeight: FontWeight.w500),
                              border: InputBorder.none,
                              isDense: true,
                            ),
                          ),
                        ),
                        if (hasValue)
                          InkWell(
                            onTap: () {
                              HapticFeedback.lightImpact();
                              setState(() => controller.clear());
                            },
                            child: Container(
                              width: 20, height: 20,
                              decoration: const BoxDecoration(color: JoynColors.secondaryText, shape: BoxShape.circle),
                              child: const Icon(Icons.close_rounded, size: 13, color: Colors.white),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  decoration: BoxDecoration(
                    gradient: _Premium.gradient(JoynColors.primary),
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: _Premium.chipShadow(JoynColors.primary),
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () {
                        HapticFeedback.lightImpact();
                        _openScanner();
                      },
                      borderRadius: BorderRadius.circular(14),
                      child: const SizedBox(
                        width: 52, height: 52,
                        child: Icon(Icons.qr_code_scanner_rounded, color: Colors.white, size: 22),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                InkWell(
                  onTap: _regenerateCode,
                  borderRadius: BorderRadius.circular(14),
                  child: Container(
                    width: 52, height: 52,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: JoynColors.primary, width: 1.4),
                      boxShadow: _Premium.fieldShadow,
                    ),
                    child: const Icon(Icons.refresh_rounded, color: JoynColors.primary, size: 22),
                  ),
                ),
              ],
            ),
            if (hasValue) ...[
              const SizedBox(height: 18),
              Container(height: 1, color: JoynColors.border),
              const SizedBox(height: 16),
              Center(
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 22, horizontal: 16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: JoynColors.border, width: 1.2),
                    boxShadow: _Premium.fieldShadow,
                  ),
                  child: isQr
                      ? QrImageView(data: controller.text, size: 170, backgroundColor: Colors.white)
                      : Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      BarcodeWidget(barcode: Barcode.code128(), data: controller.text, width: double.infinity, height: 90, drawText: false, color: JoynColors.primary),
                      const SizedBox(height: 10),
                      Text(controller.text, style: JoynTypography.bodyMedium.copyWith(fontSize: 14, fontWeight: FontWeight.w700, letterSpacing: 1.4)),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _copyToClipboard(controller.text.trim(), isQr ? 'QR value' : 'Barcode'),
                      icon: const Icon(Icons.copy_rounded, size: 16, color: JoynColors.primary),
                      label: Text('Copy', style: JoynTypography.bodyMedium.copyWith(fontWeight: FontWeight.w700, color: JoynColors.primary)),
                      style: OutlinedButton.styleFrom(
                        backgroundColor: Colors.white,
                        side: const BorderSide(color: JoynColors.border, width: 1.3),
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _GradientButton(
                      onPressed: () {},
                      icon: Icons.print_rounded,
                      label: 'Print Label',
                      color: JoynColors.primary,
                    ),
                  ),
                ],
              ),
            ],
          ] else
            _buildQtyCodeCarousel(isQr, qty),
        ],
      ),
    );
  }

  Widget _buildQtyCodeCarousel(bool isQr, int qty) {
    if (qty <= 0) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 30, horizontal: 16),
        decoration: BoxDecoration(color: JoynColors.chipBackground, borderRadius: BorderRadius.circular(16)),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: JoynColors.secondaryText.withValues(alpha: 0.08), shape: BoxShape.circle),
              child: Icon(Icons.info_outline_rounded, size: 20, color: JoynColors.secondaryText),
            ),
            const SizedBox(height: 10),
            Text('Enter a Qty above to generate a code for each unit', style: JoynTypography.subtitle.copyWith(fontSize: 13), textAlign: TextAlign.center),
          ],
        ),
      );
    }

    final total = _generatedCodes.length;
    final safePage = _currentCodePage.clamp(0, total - 1);
    final currentCode = _generatedCodes[safePage];

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(color: JoynColors.primary.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(20)),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.tag_rounded, size: 13, color: JoynColors.primary),
                  const SizedBox(width: 4),
                  Text('Serial No. ${safePage + 1} of $total', style: JoynTypography.bodyMedium.copyWith(fontSize: 13, fontWeight: FontWeight.w800, color: JoynColors.primary)),
                ],
              ),
            ),
            InkWell(
              onTap: _regenerateAllCodes,
              borderRadius: BorderRadius.circular(10),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.refresh_rounded, size: 15, color: JoynColors.primary),
                    const SizedBox(width: 4),
                    Text('Regenerate All', style: JoynTypography.caption.copyWith(fontSize: 11.5, fontWeight: FontWeight.w700, color: JoynColors.primary)),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text('Swipe to see each unit\'s code', style: JoynTypography.caption.copyWith(fontSize: 11, color: JoynColors.secondaryText)),
        const SizedBox(height: 10),
        SizedBox(
          height: isQr ? 270 : 200,
          child: PageView.builder(
            controller: _codePageController,
            itemCount: total,
            onPageChanged: (index) {
              HapticFeedback.selectionClick();
              setState(() => _currentCodePage = index);
            },
            itemBuilder: (context, index) {
              final code = _generatedCodes[index];
              final serialNumber = index + 1;
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Stack(
                  children: [
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: JoynColors.border, width: 1.2),
                        boxShadow: _Premium.fieldShadow,
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(color: JoynColors.chipBackground, borderRadius: BorderRadius.circular(20)),
                            child: Text('Serial No. $serialNumber', style: JoynTypography.caption.copyWith(fontSize: 11, fontWeight: FontWeight.w800, color: JoynColors.primary, letterSpacing: 0.3)),
                          ),
                          const SizedBox(height: 12),
                          isQr
                              ? QrImageView(data: code, size: 150, backgroundColor: Colors.white)
                              : Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              BarcodeWidget(barcode: Barcode.code128(), data: code, width: double.infinity, height: 80, drawText: false, color: JoynColors.primary),
                              const SizedBox(height: 8),
                              Text(code, style: JoynTypography.bodyMedium.copyWith(fontSize: 14, fontWeight: FontWeight.w700, letterSpacing: 1.4)),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Positioned(
                      top: 8,
                      right: 8,
                      child: InkWell(
                        onTap: () => _regenerateCodeAt(index),
                        child: Container(
                          padding: const EdgeInsets.all(7),
                          decoration: BoxDecoration(
                            gradient: _Premium.gradient(Colors.black87),
                            shape: BoxShape.circle,
                            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.25), blurRadius: 6, offset: const Offset(0, 2))],
                          ),
                          child: const Icon(Icons.refresh_rounded, size: 14, color: Colors.white),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 12),
        if (total > 1)
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 5,
            runSpacing: 5,
            children: List.generate(min(total, 30), (i) => AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: i == safePage ? 18 : 6,
              height: 6,
              decoration: BoxDecoration(
                gradient: i == safePage ? _Premium.gradient(JoynColors.primary) : null,
                color: i == safePage ? null : JoynColors.border,
                borderRadius: BorderRadius.circular(3),
              ),
            )),
          ),
        const SizedBox(height: 18),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _copyToClipboard(currentCode, 'Serial No. ${safePage + 1} code'),
                icon: const Icon(Icons.copy_rounded, size: 16, color: JoynColors.primary),
                label: Text('Copy', style: JoynTypography.bodyMedium.copyWith(fontWeight: FontWeight.w700, color: JoynColors.primary)),
                style: OutlinedButton.styleFrom(
                  backgroundColor: Colors.white,
                  side: const BorderSide(color: JoynColors.border, width: 1.3),
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _GradientButton(
                onPressed: () {},
                icon: Icons.print_rounded,
                label: 'Print All ($total)',
                color: JoynColors.primary,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildOutlinedTab({required String label, required IconData icon, required bool isSelected, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
        height: 48,
        decoration: BoxDecoration(
          gradient: isSelected ? _Premium.gradient(JoynColors.primary) : null,
          color: isSelected ? null : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: isSelected ? Colors.transparent : JoynColors.border, width: 1.4),
          boxShadow: isSelected ? _Premium.chipShadow(JoynColors.primary) : _Premium.fieldShadow,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 16, color: isSelected ? Colors.white : JoynColors.secondaryText),
            const SizedBox(width: 6),
            Text(label, style: JoynTypography.bodyMedium.copyWith(fontSize: 14.5, fontWeight: FontWeight.w700, color: isSelected ? Colors.white : JoynColors.secondaryText)),
          ],
        ),
      ),
    );
  }

  Widget _buildPhotoPicker() {
    return Column(
      children: [
        Center(
          child: InkWell(
            onTap: () {
              HapticFeedback.lightImpact();
              _openPhotoSourceSheet();
            },
            borderRadius: BorderRadius.circular(18),
            child: Container(
              height: _standardPhotoSize,
              width: _standardPhotoSize,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: _photoPath != null ? Colors.transparent : JoynColors.border, width: 1.2),
                boxShadow: _Premium.cardShadow,
              ),
              child: _photoPath != null
                  ? Stack(
                fit: StackFit.expand,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(17),
                    child: Image.file(File(_photoPath!), fit: BoxFit.cover),
                  ),
                  Positioned.fill(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(17),
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [Colors.transparent, Colors.black.withValues(alpha: 0.38)],
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: InkWell(
                      onTap: () {
                        HapticFeedback.lightImpact();
                        setState(() => _photoPath = null);
                      },
                      child: Container(
                        padding: const EdgeInsets.all(5),
                        decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle),
                        child: const Icon(Icons.close_rounded, size: 15, color: Colors.white),
                      ),
                    ),
                  ),
                  Positioned(
                    left: 10,
                    bottom: 8,
                    right: 10,
                    child: Row(
                      children: const [
                        Icon(Icons.crop_rounded, size: 12, color: Colors.white),
                        SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            'Tap to change / crop',
                            style: TextStyle(color: Colors.white, fontSize: 10.5, fontWeight: FontWeight.w600),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              )
                  : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: JoynColors.primary.withValues(alpha: 0.08),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.add_a_photo_outlined, color: JoynColors.primary, size: 24),
                  ),
                  const SizedBox(height: 10),
                  Text('Add Item Photo', style: JoynTypography.bodyMedium.copyWith(fontSize: 13.5, fontWeight: FontWeight.w700, color: JoynColors.primary)),
                  const SizedBox(height: 3),
                  Text('Camera or Gallery', style: JoynTypography.caption.copyWith(fontSize: 11, color: JoynColors.secondaryText)),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Standard size — square photo (1:1), crop after selecting',
          style: JoynTypography.caption.copyWith(fontSize: 11, color: JoynColors.secondaryText),
          textAlign: TextAlign.center,
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
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: JoynTypography.bodyMedium.copyWith(fontSize: 13, fontWeight: FontWeight.w700, color: JoynColors.secondaryText)),
        const SizedBox(height: 6),
        Container(
          height: 54,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: JoynColors.border, width: 1.2),
            boxShadow: _Premium.fieldShadow,
          ),
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