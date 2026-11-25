import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:joyn/features/Invoice/presentation/InvoicePreviewScreen.dart';
import '../../business_profile/data/business_profile_repository.dart';
import '../../../core/services/local_storage_service.dart';
import '../../../core/services/api_service.dart';
import '../../../core/theme/joyn_colors.dart';
import '../../../core/theme/joyn_typography.dart';
import '../models/sales_models.dart';
import '../data/sales_repository.dart';
import 'widgets/add_order_item_dialog.dart';
import '../../Inventory/presentation/add_new_party_screen.dart';
import '../../Inventory/presentation/scan_code_screen.dart';

// ==================== Premium Helpers ====================
class _P {
  static const double rSm = 10;
  static const double rMd = 14;
  static const double rLg = 18;
  static const double rXl = 24;

  static List<BoxShadow> soft = [
    BoxShadow(
        color: Colors.black.withValues(alpha: 0.04),
        blurRadius: 16,
        offset: const Offset(0, 4)),
    BoxShadow(
        color: Colors.black.withValues(alpha: 0.02),
        blurRadius: 4,
        offset: const Offset(0, 1)),
  ];
  static List<BoxShadow> glow(Color color, double opacity) => [
    BoxShadow(
        color: color.withValues(alpha: opacity),
        blurRadius: 32,
        spreadRadius: -4,
        offset: const Offset(0, 12)),
    BoxShadow(
        color: color.withValues(alpha: opacity * 0.5),
        blurRadius: 16,
        offset: const Offset(0, 6)),
  ];

  static LinearGradient get primaryGrad => LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color.lerp(JoynColors.primary, Colors.white, 0.20) ??
          JoynColors.primary,
      JoynColors.primary,
      Color.lerp(JoynColors.primary, Colors.black, 0.22) ??
          JoynColors.primary,
    ],
    stops: const [0.0, 0.5, 1.0],
  );
  static LinearGradient get heroGrad => LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color.lerp(JoynColors.primary, Colors.white, 0.05) ??
          JoynColors.primary,
      Color.lerp(JoynColors.primary, Colors.black, 0.15) ??
          JoynColors.primary,
    ],
  );
  static LinearGradient get successGrad => LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color.lerp(JoynColors.success, Colors.white, 0.15) ??
          JoynColors.success,
      JoynColors.success,
    ],
  );
  static LinearGradient get itemHeaderGrad => LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [
      JoynColors.primary.withValues(alpha: 0.14),
      JoynColors.primary.withValues(alpha: 0.04),
    ],
  );

  static Color get infoSoft => JoynColors.primary.withValues(alpha: 0.08);
  static Color get successSoft => JoynColors.success.withValues(alpha: 0.10);
  static Color get errorSoft => JoynColors.error.withValues(alpha: 0.10);
  static Color get warningSoft =>
      const Color(0xFFF59E0B).withValues(alpha: 0.10);
  static const Color warningColor = Color(0xFFF59E0B);
}

// ==================== Custom Painters ====================
class DashedLinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = JoynColors.secondaryText.withValues(alpha: 0.5)
      ..strokeWidth = 1.2;
    const dashWidth = 4.0;
    const dashSpace = 4.0;
    double startX = 0;
    while (startX < size.width) {
      canvas.drawLine(Offset(startX, size.height / 2),
          Offset(startX + dashWidth, size.height / 2), paint);
      startX += dashWidth + dashSpace;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class HeroWavePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.06)
      ..style = PaintingStyle.fill;
    final path = Path();
    path.moveTo(0, size.height * 0.6);
    path.quadraticBezierTo(size.width * 0.25, size.height * 0.35,
        size.width * 0.5, size.height * 0.55);
    path.quadraticBezierTo(size.width * 0.75, size.height * 0.75,
        size.width, size.height * 0.4);
    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();
    canvas.drawPath(path, paint);

    final paint2 = Paint()
      ..color = Colors.white.withValues(alpha: 0.04)
      ..style = PaintingStyle.fill;
    final path2 = Path();
    path2.moveTo(0, size.height * 0.75);
    path2.quadraticBezierTo(size.width * 0.3, size.height * 0.55,
        size.width * 0.6, size.height * 0.8);
    path2.quadraticBezierTo(size.width * 0.85, size.height * 0.95,
        size.width, size.height * 0.65);
    path2.lineTo(size.width, size.height);
    path2.lineTo(0, size.height);
    path2.close();
    canvas.drawPath(path2, paint2);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ==================== Animated Entry ====================
class _AnimatedEntry extends StatefulWidget {
  final Widget child;
  final int delayMs;
  const _AnimatedEntry({required this.child, this.delayMs = 0});

  @override
  State<_AnimatedEntry> createState() => _AnimatedEntryState();
}

class _AnimatedEntryState extends State<_AnimatedEntry>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fade;
  late Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 550));
    _fade = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    _slide = Tween<Offset>(begin: const Offset(0, 0.06), end: Offset.zero)
        .animate(
        CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
    Future.delayed(Duration(milliseconds: widget.delayMs), () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fade,
      child: SlideTransition(position: _slide, child: widget.child),
    );
  }
}

// ==================== Press Scale ====================
class _PressScale extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  const _PressScale({required this.child, this.onTap, this.onLongPress});

  @override
  State<_PressScale> createState() => _PressScaleState();
}

class _PressScaleState extends State<_PressScale> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      onTap: widget.onTap,
      onLongPress: widget.onLongPress,
      child: AnimatedScale(
        scale: _pressed ? 0.97 : 1.0,
        duration: const Duration(milliseconds: 120),
        child: widget.child,
      ),
    );
  }
}

// ==================== Animated Amount ====================
class _AnimatedAmount extends StatelessWidget {
  final double value;
  final TextStyle style;

  const _AnimatedAmount({required this.value, required this.style});

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: value),
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeOutCubic,
      builder: (context, val, _) {
        return Text('₹${val.toStringAsFixed(2)}', style: style);
      },
    );
  }
}

// ==================== Swipe-to-Delete ====================
class _SwipeToDelete extends StatelessWidget {
  final Widget child;
  final VoidCallback onDelete;

  const _SwipeToDelete({required this.child, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: UniqueKey(),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => onDelete(),
      background: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.only(right: 24),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              JoynColors.error.withValues(alpha: 0.85),
              JoynColors.error,
            ],
          ),
          borderRadius: BorderRadius.circular(_P.rMd),
        ),
        alignment: Alignment.centerRight,
        child: const Icon(Icons.delete_outline_rounded,
            color: Colors.white, size: 26),
      ),
      child: child,
    );
  }
}

// ==================== Section Card ====================
class _SectionCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;

  const _SectionCard({required this.child, this.padding, this.margin});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin ?? const EdgeInsets.symmetric(horizontal: 16),
      padding: padding ?? const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(_P.rLg),
        boxShadow: _P.soft,
        border: Border.all(color: JoynColors.border.withValues(alpha: 0.5)),
      ),
      child: child,
    );
  }
}

// ==================== MAIN SCREEN ====================
class AddPurchaseOrderScreen extends StatefulWidget {
  final PurchaseOrderModel? existingOrder;
  final PartyModel? initialParty;

  const AddPurchaseOrderScreen({
    super.key,
    this.initialParty,
    this.existingOrder,
  });

  @override
  State<AddPurchaseOrderScreen> createState() => _AddPurchaseOrderScreenState();
}

class _AddPurchaseOrderScreenState extends State<AddPurchaseOrderScreen> {
  final SalesRepository _salesRepository = SalesRepository();
  final ImagePicker _imagePicker = ImagePicker();

  bool _isEditing = false;
  int _orderNo = 1;
  DateTime _selectedDate = DateTime.now();
  DateTime _dueDate = DateTime.now();

  final _partyNameController = TextEditingController();
  final _totalAmountController = TextEditingController();
  final _paidController = TextEditingController(text: '0.00');
  final _noteController = TextEditingController();

  double _paidAmount = 0.00;
  bool _isPaidChecked = false;
  bool _rateExclTax = true;
  bool _isOneTimeParty = false;
  String? _selectedPartyId;

  String _paymentType = 'Cash';
  String _stateOfSupply = 'Select State';
  String? _selectedTerms;
  bool _termsExpanded = false;

  File? _pickedImage;
  File? _pickedDocument;

  final List<OrderItemModel> _items = [];

  List<PartyModel> _savedParties = [];
  List<InventoryItemModel> _savedItems = [];

  double get _currentTotalAmount =>
      _items.fold(0.0, (sum, item) => sum + item.total);

  double get _currentBalanceDue {
    final due = _currentTotalAmount - _paidAmount;
    return due < 0 ? 0 : due;
  }

  double get _subtotal => _items.fold(0.0, (sum, item) => sum + item.subtotal);
  double get _totalDiscount =>
      _items.fold(0.0, (sum, item) => sum + item.discountAmount);
  double get _totalTax => _items.fold(0.0, (sum, item) => sum + item.taxAmount);
  int get _totalQty => _items.fold(0, (sum, item) => sum + item.qty);

  double get _completionProgress {
    double p = 0;
    if (_partyNameController.text.isNotEmpty) p += 0.4;
    if (_items.isNotEmpty) p += 0.4;
    if (_currentTotalAmount > 0) p += 0.2;
    return p;
  }

  @override
  void initState() {
    super.initState();
    _isEditing = widget.existingOrder != null;

    if (_isEditing) {
      _prefillFromExisting(widget.existingOrder!);
    } else if (widget.initialParty != null) {
      _partyNameController.text = widget.initialParty!.name;
    }

    _loadSavedParties();
    _loadSavedItems();

    if (!_isEditing) {
      _loadNextOrderNo();
    }
  }

  @override
  void dispose() {
    _partyNameController.dispose();
    _totalAmountController.dispose();
    _paidController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  DateTime _parseDateStr(String dateStr) {
    try {
      final parts = dateStr.split('/');
      if (parts.length == 3) {
        return DateTime(
            int.parse(parts[2]), int.parse(parts[1]), int.parse(parts[0]));
      }
    } catch (_) {}
    return DateTime.now();
  }

  void _prefillFromExisting(PurchaseOrderModel order) {
    _orderNo = order.orderNo;
    _selectedDate = _parseDateStr(order.date);
    _dueDate = _parseDateStr(order.dueDate);

    _partyNameController.text = order.partyName;
    _paidController.text = '0.00';
    _paidAmount = 0.00;
    _isPaidChecked = false;

    _salesRepository.getPaymentById('${order.id}_pay').then((p) {
      if (p != null && mounted) {
        setState(() {
          _paidAmount = p.receivedAmount;
          _paidController.text = p.receivedAmount.toStringAsFixed(2);
          _isPaidChecked = p.receivedAmount > 0;
          if (p.paymentType.isNotEmpty) _paymentType = p.paymentType;
          if (p.partyId.isNotEmpty) _selectedPartyId = p.partyId;
        });
      }
    });

    try {
      _items.addAll(order.items.map((m) => OrderItemModel.fromJson(m)));
    } catch (e) {
      debugPrint('Error parsing items: $e');
    }

    _recalcTotal();
  }

  Future<void> _loadNextOrderNo() async {
    try {
      final orders = await _salesRepository.getPurchaseOrders();
      if (orders.isNotEmpty && mounted) {
        final maxOrderNo =
        orders.map((o) => o.orderNo).reduce((a, b) => a > b ? a : b);
        setState(() => _orderNo = maxOrderNo + 1);
      }
    } catch (e) {
      debugPrint('Error loading order no: $e');
    }
  }

  Future<void> _loadSavedParties() async {
    try {
      final parties = await _salesRepository.getParties();
      if (!mounted) return;
      setState(() => _savedParties = parties);
    } catch (e) {
      debugPrint('Error loading parties: $e');
    }
  }

  Future<void> _loadSavedItems() async {
    try {
      final items = await _salesRepository.getItems();
      if (!mounted) return;
      setState(() => _savedItems = items);
    } catch (e) {
      debugPrint('Error loading items: $e');
    }
  }

  List<SavedItemOption> get _savedItemOptions => _savedItems.map((item) {
    return SavedItemOption(
      name: item.name,
      category: item.category,
      unit: item.unit,
      purchasePrice: item.purchasePrice,
      sellingPrice: item.sellingPrice,
      stock: item.stock,
      barcode: item.barcode,
    );
  }).toList();

  String _formatDate(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  Future<void> _pickDueDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _dueDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) setState(() => _dueDate = picked);
  }

  Future<void> _editOrderNo() async {
    final controller = TextEditingController(text: _orderNo.toString());
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Order Number'),
        content: TextField(
          controller: controller,
          autofocus: true,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(hintText: 'Enter order number'),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          TextButton(
              onPressed: () => Navigator.pop(context, controller.text.trim()),
              child: const Text('Update')),
        ],
      ),
    );
    if (result != null && result.isNotEmpty) {
      setState(() => _orderNo = int.tryParse(result) ?? _orderNo);
    }
  }

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
          source: ImageSource.gallery, imageQuality: 75);
      if (image == null) return;
      setState(() => _pickedImage = File(image.path));
    } catch (e) {
      debugPrint('Image pick error: $e');
    }
  }

  Future<void> _pickDocument() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'doc', 'docx', 'xls', 'xlsx', 'txt'],
      );
      if (result == null || result.files.single.path == null) return;
      setState(() => _pickedDocument = File(result.files.single.path!));
    } catch (e) {
      debugPrint('Document pick error: $e');
    }
  }

  Future<void> _addItem({OrderItemModel? existing}) async {
    final result = await showDialog<OrderItemModel>(
      context: context,
      builder: (context) => AddOrderItemDialog(
        existingItem: existing,
        savedItems: _savedItemOptions,
        isPurchaseOrder: true,
      ),
    );
    if (result != null) {
      setState(() {
        if (existing != null) {
          final index = _items.indexWhere((i) => i.id == existing.id);
          if (index != -1) _items[index] = result;
        } else {
          _items.add(result);
        }
        _recalcTotal();
      });
    }
  }

  void _removeItem(String id) {
    HapticFeedback.lightImpact();
    setState(() {
      _items.removeWhere((i) => i.id == id);
      _recalcTotal();
    });
  }

  void _recalcTotal() {
    final total = _items.fold(0.0, (sum, item) => sum + item.total);
    _totalAmountController.text = total.toStringAsFixed(2);
  }

  Future<void> _scanBarcodeAndAddItem() async {
    HapticFeedback.lightImpact();
    final barcode = await Navigator.of(context).push<String>(
        MaterialPageRoute(builder: (_) => const ScanCodeScreen()));
    if (barcode == null || barcode.isEmpty || !mounted) return;

    final cleanScanned = barcode.trim().toLowerCase();
    bool _matches(InventoryItemModel item) {
      if (item.barcode.trim().toLowerCase() == cleanScanned) return true;
      if ((item.itemCode ?? '').trim().toLowerCase() == cleanScanned) return true;
      if (item.itemNumber != null && item.itemNumber.toString() == cleanScanned) return true;
      if (item.name.trim().toLowerCase() == cleanScanned) return true;
      return false;
    }

    InventoryItemModel? foundItem;
    for (final item in _savedItems) {
      if (_matches(item)) {
        foundItem = item;
        break;
      }
    }

    if (foundItem == null) {
      try {
        final allDbItems = await _salesRepository.getItems();
        for (final item in allDbItems) {
          if (_matches(item)) {
            foundItem = item;
            break;
          }
        }
      } catch (_) {}
    }

    if (foundItem == null) {
      try {
        final cloudItem = await ApiService.searchBarcode(barcode);
        if (cloudItem != null) {
          foundItem = InventoryItemModel(
            id: cloudItem['id']?.toString() ?? DateTime.now().millisecondsSinceEpoch.toString(),
            name: cloudItem['name']?.toString() ?? '',
            barcode: cloudItem['barcode']?.toString() ?? barcode,
            sellingPrice: (cloudItem['sale_price'] as num?)?.toDouble() ??
                (cloudItem['sellingPrice'] as num?)?.toDouble() ??
                0.0,
            purchasePrice: (cloudItem['purchase_price'] as num?)?.toDouble() ??
                (cloudItem['purchasePrice'] as num?)?.toDouble() ??
                0.0,
            stock: (cloudItem['current_stock'] as num?)?.toInt() ??
                (cloudItem['stock'] as num?)?.toInt() ??
                0,
            unit: cloudItem['unit']?.toString() ?? 'Pcs',
            category: cloudItem['category']?.toString() ?? '',
            createdAt: DateTime.now(),
          );
        }
      } catch (_) {}
    }

    if (foundItem != null) {
      final newItem = OrderItemModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        itemName: foundItem.name,
        category: foundItem.category,
        unitPrice: foundItem.purchasePrice != 0
            ? foundItem.purchasePrice
            : foundItem.sellingPrice,
        qty: 1,
        unit: foundItem.unit,
        hsnSac: foundItem.hsnSac,
        taxRate: foundItem.taxRatePercent,
        taxInclusive: foundItem.purchasePriceTaxMode == PriceTaxMode.withTax,
      );
      setState(() {
        _items.add(newItem);
        _recalcTotal();
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Added "${foundItem.name}" to purchase order'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: JoynColors.success,
            duration: const Duration(seconds: 2),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('No item found with barcode "$barcode"'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: JoynColors.error,
            duration: const Duration(seconds: 3),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    }
  }

  // ==================== Party Picker ====================
  Future<void> _openPartyPicker() async {
    final selected = await showModalBottomSheet<PartyModel>(
      context: context,
      isScrollControlled: true,
      backgroundColor: JoynColors.background,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (sheetContext) {
        String query = '';
        return StatefulBuilder(
          builder: (context, setSheetState) {
            final filtered = _savedParties.where((party) {
              if (query.isEmpty) return true;
              final q = query.toLowerCase();
              return party.name.toLowerCase().contains(q) ||
                  party.category.toLowerCase().contains(q);
            }).toList();

            return SafeArea(
              child: Padding(
                padding: EdgeInsets.only(
                  left: 20,
                  right: 20,
                  top: 8,
                  bottom: MediaQuery.of(context).viewInsets.bottom + 16,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 44,
                        height: 4,
                        margin: const EdgeInsets.only(bottom: 20),
                        decoration: BoxDecoration(
                            color: JoynColors.border,
                            borderRadius: BorderRadius.circular(3)),
                      ),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Select Party',
                            style: JoynTypography.titleMedium.copyWith(
                                fontSize: 20, fontWeight: FontWeight.w800)),
                        IconButton(
                          icon: const Icon(Icons.close, size: 22),
                          onPressed: () => Navigator.pop(sheetContext),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    TextField(
                      onChanged: (v) => setSheetState(() => query = v),
                      decoration: InputDecoration(
                        hintText: 'Search by name or category',
                        prefixIcon: const Icon(Icons.search,
                            size: 20, color: JoynColors.secondaryText),
                        filled: true,
                        fillColor: JoynColors.chipBackground,
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(_P.rMd),
                            borderSide: BorderSide.none),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 14),
                      ),
                    ),
                    const SizedBox(height: 14),
                    // Add New Party
                    InkWell(
                      onTap: () async {
                        Navigator.pop(sheetContext);
                        final result = await Navigator.of(context)
                            .push<Map<String, dynamic>>(MaterialPageRoute(
                            builder: (_) => const AddNewPartyScreen()));
                        if (result != null) {
                          await _loadSavedParties();
                          final partyName = (result['name'] ?? '').toString();
                          PartyModel? matched;
                          for (final p in _savedParties) {
                            if (p.name.trim().toLowerCase() == partyName.trim().toLowerCase()) {
                              matched = p;
                              break;
                            }
                          }
                          setState(() {
                            _selectedPartyId = matched?.id ?? '';
                            _partyNameController.text = partyName;
                            _isOneTimeParty = false;
                          });
                        }
                      },
                      borderRadius: BorderRadius.circular(_P.rMd),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            vertical: 14, horizontal: 16),
                        decoration: BoxDecoration(
                          color: _P.infoSoft,
                          borderRadius: BorderRadius.circular(_P.rMd),
                          border: Border.all(
                              color: JoynColors.primary.withValues(alpha: 0.25),
                              width: 1.5),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                gradient: _P.primaryGrad,
                                borderRadius: BorderRadius.circular(8),
                                boxShadow: _P.glow(JoynColors.primary, 0.3),
                              ),
                              child: const Icon(Icons.person_add_alt_1,
                                  size: 14, color: Colors.white),
                            ),
                            const SizedBox(width: 10),
                            Text('Add New Party',
                                style: JoynTypography.bodyMedium.copyWith(
                                    color: JoynColors.primary,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 14)),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    if (filtered.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 40),
                        child: Center(
                          child: Column(
                            children: [
                              Icon(Icons.storefront_outlined,
                                  size: 48, color: JoynColors.secondaryText),
                              const SizedBox(height: 8),
                              Text('No saved parties',
                                  style: JoynTypography.subtitle.copyWith(
                                      fontSize: 13.5)),
                            ],
                          ),
                        ),
                      )
                    else
                      ConstrainedBox(
                        constraints: BoxConstraints(
                            maxHeight:
                            MediaQuery.of(context).size.height * 0.45),
                        child: ListView.builder(
                          shrinkWrap: true,
                          itemCount: filtered.length,
                          itemBuilder: (context, index) {
                            final party = filtered[index];
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: InkWell(
                                onTap: () =>
                                    Navigator.pop(sheetContext, party),
                                borderRadius:
                                BorderRadius.circular(_P.rMd),
                                child: Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: JoynColors.chipBackground,
                                    borderRadius:
                                    BorderRadius.circular(_P.rMd),
                                  ),
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 44,
                                        height: 44,
                                        decoration: BoxDecoration(
                                          gradient: _P.primaryGrad,
                                          shape: BoxShape.circle,
                                          boxShadow: _P.glow(
                                              JoynColors.primary, 0.25),
                                        ),
                                        alignment: Alignment.center,
                                        child: Text(
                                          party.name.isNotEmpty
                                              ? party.name[0].toUpperCase()
                                              : '?',
                                          style: const TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.w800,
                                              fontSize: 16),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                          children: [
                                            Text(party.name,
                                                maxLines: 1,
                                                overflow:
                                                TextOverflow.ellipsis,
                                                style: JoynTypography
                                                    .bodyMedium
                                                    .copyWith(
                                                    fontWeight:
                                                    FontWeight.w700,
                                                    fontSize: 15)),
                                            if (party.category.isNotEmpty)
                                              Text(party.category,
                                                  maxLines: 1,
                                                  overflow: TextOverflow
                                                      .ellipsis,
                                                  style: JoynTypography
                                                      .caption
                                                      .copyWith(
                                                      fontSize: 12,
                                                      color: JoynColors
                                                          .secondaryText)),
                                          ],
                                        ),
                                      ),
                                      const Icon(Icons.chevron_right,
                                          color: JoynColors.secondaryText,
                                          size: 20),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );

    if (selected != null) {
      setState(() {
        _selectedPartyId = selected.id;
        _partyNameController.text = selected.name;
        _isOneTimeParty = false;
      });
    }
  }

  Future<void> _openPaymentTypePicker() async {
    final result = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: JoynColors.background,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(
              width: 44,
              height: 4,
              decoration: BoxDecoration(
                  color: JoynColors.border,
                  borderRadius: BorderRadius.circular(3)),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Text('Payment Type',
                      style: JoynTypography.titleMedium.copyWith(
                          fontSize: 18, fontWeight: FontWeight.w800)),
                  const Spacer(),
                  IconButton(
                      icon: const Icon(Icons.close, size: 22),
                      onPressed: () => Navigator.pop(context)),
                ],
              ),
            ),
            const Divider(height: 1, color: Color(0xFFF1F5F9)),
            _paymentOption('Cash', Icons.currency_rupee, JoynColors.success),
            _paymentOption('Cheque', Icons.receipt_long, _P.warningColor),
            _paymentOption(
                'Bank Transfer', Icons.account_balance, JoynColors.primary),
            const Divider(height: 1, color: Color(0xFFF1F5F9)),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: _P.infoSoft,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.add,
                    color: JoynColors.primary, size: 18),
              ),
              title: Text('Add Bank A/c',
                  style: JoynTypography.bodyMedium.copyWith(
                      color: JoynColors.primary,
                      fontWeight: FontWeight.w700)),
              onTap: () => Navigator.pop(context, 'Bank A/c'),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
    if (result != null) setState(() => _paymentType = result);
  }

  Widget _paymentOption(String label, IconData icon, Color color) {
    return ListTile(
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: color, size: 20),
      ),
      title: Text(label,
          style:
          JoynTypography.bodyMedium.copyWith(fontWeight: FontWeight.w600)),
      onTap: () => Navigator.pop(context, label),
    );
  }

  Future<void> _openStateOfSupplyPicker() async {
    final states = [
      'Select State',
      'Andhra Pradesh',
      'Delhi',
      'Gujarat',
      'Karnataka',
      'Maharashtra',
      'Punjab',
      'Tamil Nadu',
      'Uttar Pradesh',
      'West Bengal'
    ];
    final result = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: JoynColors.background,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(
              width: 44,
              height: 4,
              decoration: BoxDecoration(
                  color: JoynColors.border,
                  borderRadius: BorderRadius.circular(3)),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Text('State of Supply',
                  style: JoynTypography.titleMedium.copyWith(
                      fontSize: 18, fontWeight: FontWeight.w800)),
            ),
            const Divider(height: 1, color: Color(0xFFF1F5F9)),
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: states.length,
                itemBuilder: (context, i) => ListTile(
                  title: Text(states[i]),
                  trailing: states[i] == _stateOfSupply
                      ? Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      gradient: _P.primaryGrad,
                      shape: BoxShape.circle,
                      boxShadow: _P.glow(JoynColors.primary, 0.3),
                    ),
                    child: const Icon(Icons.check,
                        color: Colors.white, size: 14),
                  )
                      : null,
                  onTap: () => Navigator.pop(context, states[i]),
                ),
              ),
            ),
          ],
        ),
      ),
    );
    if (result != null) setState(() => _stateOfSupply = result);
  }

  Future<void> _openTermsPicker() async {
    final result = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: JoynColors.background,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(
              width: 44,
              height: 4,
              decoration: BoxDecoration(
                  color: JoynColors.border,
                  borderRadius: BorderRadius.circular(3)),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Text('Terms & Conditions',
                  style: JoynTypography.titleMedium.copyWith(
                      fontSize: 18, fontWeight: FontWeight.w800)),
            ),
            const Divider(height: 1, color: Color(0xFFF1F5F9)),
            ListTile(
              leading: const Icon(Icons.bookmark_outline),
              title: const Text('Select saved T&C'),
              onTap: () => Navigator.pop(context, 'Standard T&C'),
            ),
            ListTile(
              leading:
              const Icon(Icons.edit_note, color: JoynColors.primary),
              title: Text('Add terms & Conditions',
                  style: JoynTypography.bodyMedium.copyWith(
                      color: JoynColors.primary,
                      fontWeight: FontWeight.w700)),
              onTap: () => Navigator.pop(context, 'Custom T&C'),
            ),
            const Divider(height: 1, color: Color(0xFFF1F5F9)),
            ListTile(
              leading: const Icon(Icons.block_outlined),
              title: const Text('None'),
              onTap: () => Navigator.pop(context, 'None'),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
    if (result != null) setState(() => _selectedTerms = result);
  }

  Future<void> _openPurchaseOrderPreview(PurchaseOrderModel order,
      {bool popAfterClose = false}) async {
    final profile = await BusinessProfileRepository().getBusinessProfile();

    final bizAddr = [
      if (profile?.address.isNotEmpty == true) profile!.address,
      if (profile?.city.isNotEmpty == true) profile!.city,
      if (profile?.state.isNotEmpty == true) profile!.state,
      if (profile?.pincode.isNotEmpty == true) profile!.pincode,
    ].join(', ');

    String resolvedBusinessName = (profile?.businessName.isNotEmpty == true && profile!.businessName != 'My Business')
        ? profile!.businessName
        : (LocalStorageService().businessName.isNotEmpty
            ? LocalStorageService().businessName
            : 'JOYN Enterprise');

    if (!mounted) return;

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => InvoicePreviewScreen(
          data: InvoicePreviewData(
            invoiceNo: order.orderNo,
            date: order.date,
            dueDate: order.dueDate,
            customerName: order.partyName.isEmpty ? '—' : order.partyName,
            customerPhone: '',
            items: List<OrderItemModel>.from(_items),
            totalAmount: order.totalAmount,
            receivedAmount: _paidAmount,
            businessName: resolvedBusinessName,
            businessPhone: profile?.phone1 ?? LocalStorageService().phoneNumber,
            businessEmail: profile?.email ?? LocalStorageService().email,
            businessAddress: bizAddr,
            businessGstin: profile?.gstNumber ?? '',
            termsAndConditions: _selectedTerms ?? '',
            logoPath: profile?.logoPath,
            logoUrl: profile?.logoUrl,
            bankName: profile?.bankName ?? '',
            accountNumber: profile?.accountNumber ?? '',
            ifscCode: profile?.ifscCode ?? '',
            upiId: profile?.upiId ?? '',
            title: 'Purchase Order',
          ),
        ),
      ),
    ).then((_) {
      if (popAfterClose && mounted) {
        Navigator.of(context).pop(order);
      }
    });
  }

  Future<void> _save({bool andNew = false}) async {
    if (_partyNameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Party name is required'),
        behavior: SnackBarBehavior.floating,
      ));
      return;
    }

    final total = _items.fold(0.0, (sum, item) => sum + item.total);

    final purchaseOrder = PurchaseOrderModel(
      id: _isEditing
          ? widget.existingOrder!.id
          : DateTime.now().millisecondsSinceEpoch.toString(),
      orderNo: _orderNo,
      date: _formatDate(_selectedDate),
      dueDate: _formatDate(_dueDate),
      partyName: _partyNameController.text.trim(),
      items: _items
          .map((i) => {
        'name': i.itemName,
        'category': i.category,
        'unitPrice': i.unitPrice,
        'qty': i.qty,
        'discountAmount': i.discountAmount,
        'taxAmount': i.taxAmount,
        'taxRate': i.taxRate,
        'taxInclusive': i.taxInclusive ? 1 : 0,
        'total': i.total,
        'unit': i.unit,
      })
          .toList(),
      totalAmount: total,
      createdAt: _isEditing
          ? widget.existingOrder!.createdAt
          : DateTime.now(),
    );

    if (_isEditing) {
      await _salesRepository.updatePurchaseOrder(purchaseOrder);
    } else {
      await _salesRepository.insertPurchaseOrder(purchaseOrder);
    }

    // Auto-record or update Payment Out for upfront paid amount
    if (_paidAmount > 0) {
      try {
        String pId = _selectedPartyId ?? '';
        if (pId.isEmpty && _savedParties.isNotEmpty) {
          final match = _savedParties.where((p) =>
              p.name.trim().toLowerCase() ==
              _partyNameController.text.trim().toLowerCase());
          if (match.isNotEmpty) pId = match.first.id;
        }

        final nextRecNo = await _salesRepository.getNextReceiptNo();
        final payment = PaymentModel(
          id: '${purchaseOrder.id}_pay',
          receiptNo: nextRecNo,
          date: purchaseOrder.date,
          partyId: pId,
          partyName: purchaseOrder.partyName,
          partyPhone: '',
          receivedAmount: _paidAmount,
          paymentType: _paymentType,
          isPaymentOut: true,
          createdAt: DateTime.now(),
        );
        await _salesRepository.insertPayment(payment);
      } catch (e) {
        debugPrint('Error recording purchase payment out: $e');
      }
    } else if (_isEditing) {
      try {
        await _salesRepository.deletePayment('${purchaseOrder.id}_pay');
      } catch (_) {}
    }

    HapticFeedback.mediumImpact();
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(_isEditing
          ? 'Purchase updated successfully!'
          : 'Purchase saved successfully!'),
      backgroundColor: JoynColors.success,
      behavior: SnackBarBehavior.floating,
      margin: const EdgeInsets.all(16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
    ));

    if (andNew && !_isEditing) {
      setState(() {
        _orderNo++;
        _partyNameController.clear();
        _totalAmountController.clear();
        _paidController.text = "0.00";
        _paidAmount = 0.00;
        _noteController.clear();
        _items.clear();
        _isPaidChecked = false;
        _isOneTimeParty = false;
        _pickedImage = null;
        _pickedDocument = null;
      });
      _openPurchaseOrderPreview(purchaseOrder, popAfterClose: false);
    } else {
      _openPurchaseOrderPreview(purchaseOrder, popAfterClose: true);
    }
  }

  void _showMoreOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: JoynColors.background,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(
              width: 44,
              height: 4,
              decoration: BoxDecoration(
                  color: JoynColors.border,
                  borderRadius: BorderRadius.circular(3)),
            ),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _P.errorSoft,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.delete_outline,
                    color: JoynColors.error, size: 20),
              ),
              title: Text('Discard',
                  style: JoynTypography.bodyMedium.copyWith(
                      color: JoynColors.error,
                      fontWeight: FontWeight.w700)),
              onTap: () {
                Navigator.pop(context);
                Navigator.of(context).pop();
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: JoynColors.background,
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: EdgeInsets.zero,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildHeroHeader(),
                  const SizedBox(height: 12),
                  _AnimatedEntry(delayMs: 0, child: _buildInfoCard()),
                  const SizedBox(height: 14),
                  _AnimatedEntry(delayMs: 60, child: _buildPartyCard()),
                  const SizedBox(height: 14),
                  _AnimatedEntry(delayMs: 120, child: _buildItemsSection()),
                  const SizedBox(height: 14),
                  _AnimatedEntry(
                      delayMs: 180, child: _buildPaymentSummaryCard()),
                  const SizedBox(height: 14),
                  _AnimatedEntry(
                      delayMs: 240, child: _buildMoreDetailsCard()),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
          _buildBottomBar(),
        ],
      ),
    );
  }

  // ==================== Hero Header ====================
  Widget _buildHeroHeader() {
    return Container(
      decoration: BoxDecoration(
        gradient: _P.heroGrad,
        boxShadow: _P.glow(JoynColors.primary, 0.25),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(22),
          bottomRight: Radius.circular(22),
        ),
      ),
      child: Stack(
        children: [
          Positioned.fill(child: CustomPaint(painter: HeroWavePainter())),
          SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      _heroIconBtn(
                          Icons.arrow_back, () => Navigator.of(context).pop()),
                      const Spacer(),
                      _heroIconBtn(
                          Icons.qr_code_scanner_rounded,
                          _scanBarcodeAndAddItem),
                      const SizedBox(width: 6),
                      _heroIconBtn(Icons.settings_outlined, _showMoreOptions),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                                _isEditing
                                    ? 'Edit Purchase'
                                    : 'New Purchase',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: -0.4,
                                )),
                            const SizedBox(height: 2),
                            Text(
                                'Order #$_orderNo  •  ${_formatDate(_selectedDate)}',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.75),
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w600,
                                )),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      _buildProgressRing(),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: _buildHeroStat(
                          icon: Icons.inventory_2_outlined,
                          label: 'Items',
                          value: '${_items.length}',
                        ),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: _buildHeroStat(
                          icon: Icons.receipt_long_outlined,
                          label: 'Total',
                          value:
                          '₹${_currentTotalAmount.toStringAsFixed(0)}',
                        ),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: _buildHeroStat(
                          icon: Icons.trending_up,
                          label: 'Due',
                          value:
                          '₹${_currentBalanceDue.toStringAsFixed(0)}',
                          danger: _currentBalanceDue > 0,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _heroIconBtn(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(7),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.15),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
        ),
        child: Icon(icon, color: Colors.white, size: 17),
      ),
    );
  }

  Widget _buildProgressRing() {
    return SizedBox(
      width: 42,
      height: 42,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            width: 42,
            height: 42,
            child: CircularProgressIndicator(
              value: _completionProgress,
              strokeWidth: 3,
              backgroundColor: Colors.white.withValues(alpha: 0.2),
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
              strokeCap: StrokeCap.round,
            ),
          ),
          Text(
            '${(_completionProgress * 100).toInt()}%',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeroStat({
    required IconData icon,
    required String label,
    required String value,
    bool danger = false,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(icon,
                  size: 10, color: Colors.white.withValues(alpha: 0.85)),
              const SizedBox(width: 3),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.75),
                    fontSize: 9.5,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.2,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(value,
                maxLines: 1,
                style: TextStyle(
                  color: danger ? const Color(0xFFFFB4AB) : Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.2,
                )),
          ),
        ],
      ),
    );
  }

  // ==================== Info Card ====================
  Widget _buildInfoCard() {
    return _SectionCard(
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          Expanded(
            child: _PressScale(
              onTap: _editOrderNo,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        gradient: _P.primaryGrad,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: _P.glow(JoynColors.primary, 0.3),
                      ),
                      child: const Icon(Icons.tag_rounded,
                          size: 18, color: Colors.white),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Order No.',
                              style: JoynTypography.caption.copyWith(
                                  fontSize: 11,
                                  color: JoynColors.secondaryText,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 0.3)),
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              Flexible(
                                child: Text('#$_orderNo',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style:
                                    JoynTypography.bodyMedium.copyWith(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w800,
                                        color: JoynColors.primary)),
                              ),
                              const SizedBox(width: 4),
                              const Icon(Icons.keyboard_arrow_down,
                                  size: 18,
                                  color: JoynColors.secondaryText),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Container(
              width: 1,
              height: 44,
              color: JoynColors.border.withValues(alpha: 0.6)),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(left: 12),
              child: _PressScale(
                onTap: _pickDate,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: _P.infoSoft,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.calendar_today_rounded,
                            size: 17, color: JoynColors.primary),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Date',
                                style: JoynTypography.caption.copyWith(
                                    fontSize: 11,
                                    color: JoynColors.secondaryText,
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: 0.3)),
                            const SizedBox(height: 2),
                            Row(
                              children: [
                                Flexible(
                                  child: Text(_formatDate(_selectedDate),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: JoynTypography.bodyMedium
                                          .copyWith(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w800,
                                          color: JoynColors.primary)),
                                ),
                                const SizedBox(width: 4),
                                const Icon(Icons.keyboard_arrow_down,
                                    size: 18,
                                    color: JoynColors.secondaryText),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ==================== Party Card (with One-time Toggle) ====================
  Widget _buildPartyCard() {
    return _SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: _P.infoSoft,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.storefront_outlined,
                    size: 14, color: JoynColors.primary),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text('Party Details',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: JoynTypography.bodyLarge.copyWith(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.2,
                        color: JoynColors.primary)),
              ),
              const Spacer(),
              // ✅ One-time toggle button (jaise sale me customer card me hai)
              GestureDetector(
                onTap: () {
                  HapticFeedback.lightImpact();
                  setState(() {
                    _isOneTimeParty = !_isOneTimeParty;
                    if (_isOneTimeParty) {
                      _partyNameController.clear();
                    }
                  });
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 220),
                  curve: Curves.easeOutCubic,
                  padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: _isOneTimeParty
                        ? _P.warningColor.withValues(alpha: 0.12)
                        : JoynColors.chipBackground,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: _isOneTimeParty
                          ? _P.warningColor.withValues(alpha: 0.4)
                          : JoynColors.border.withValues(alpha: 0.8),
                      width: 1.2,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _isOneTimeParty
                            ? Icons.flash_on_rounded
                            : Icons.flash_off_rounded,
                        size: 13,
                        color: _isOneTimeParty
                            ? _P.warningColor
                            : JoynColors.secondaryText,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'One-time',
                        style: JoynTypography.caption.copyWith(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: _isOneTimeParty
                              ? _P.warningColor
                              : JoynColors.secondaryText,
                          letterSpacing: 0.2,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Padding(
            padding: const EdgeInsets.only(left: 4),
            child: Text(
              _isOneTimeParty
                  ? 'Just type the name — no need to save'
                  : 'Tap party field to pick from saved parties',
              style: JoynTypography.caption.copyWith(
                fontSize: 11,
                color: JoynColors.secondaryText.withValues(alpha: 0.75),
              ),
            ),
          ),
          const SizedBox(height: 14),
          // ✅ One-time ON → editable text field | OFF → picker only
          _isOneTimeParty
              ? _premiumField(
            label: 'Party Name *',
            controller: _partyNameController,
            icon: Icons.storefront_outlined,
            hint: 'Enter party name',
            textCapitalization: TextCapitalization.words,
            onChanged: (_) => setState(() {}),
          )
              : _premiumField(
            label: 'Party *',
            controller: _partyNameController,
            icon: Icons.storefront_outlined,
            onTap: _openPartyPicker,
            enabled: false,
            hint: 'Tap to select party',
          ),
          const SizedBox(height: 14),
          _premiumDateField(
            label: 'Due Date',
            date: _dueDate,
            onTap: _pickDueDate,
            icon: Icons.event_available_outlined,
          ),
        ],
      ),
    );
  }

  Widget _premiumField({
    required String label,
    required TextEditingController controller,
    required IconData icon,
    TextInputType? keyboardType,
    VoidCallback? onTap,
    bool enabled = true,
    String? hint,
    TextCapitalization textCapitalization = TextCapitalization.none,
    ValueChanged<String>? onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(label,
              style: JoynTypography.caption.copyWith(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: JoynColors.secondaryText,
                  letterSpacing: 0.2)),
        ),
        _PressScale(
          onTap: onTap,
          child: Container(
            decoration: BoxDecoration(
              color: JoynColors.chipBackground,
              borderRadius: BorderRadius.circular(_P.rMd),
              border: Border.all(
                  color: JoynColors.border.withValues(alpha: 0.8),
                  width: 1.2),
            ),
            child: TextField(
              controller: controller,
              enabled: enabled,
              keyboardType: keyboardType,
              textCapitalization: textCapitalization,
              onChanged: onChanged,
              style: JoynTypography.bodyMedium.copyWith(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: JoynColors.primary),
              decoration: InputDecoration(
                hintText: hint ?? '',
                hintStyle: JoynTypography.bodyMedium.copyWith(
                    fontSize: 14,
                    color: JoynColors.secondaryText.withValues(alpha: 0.6),
                    fontWeight: FontWeight.w500),
                prefixIcon: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: _P.infoSoft,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(icon, size: 14, color: JoynColors.primary),
                  ),
                ),
                border: InputBorder.none,
                contentPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _premiumDateField({
    required String label,
    required DateTime date,
    required VoidCallback onTap,
    required IconData icon,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(label,
              style: JoynTypography.caption.copyWith(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: JoynColors.secondaryText,
                  letterSpacing: 0.2)),
        ),
        _PressScale(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
            decoration: BoxDecoration(
              color: JoynColors.chipBackground,
              borderRadius: BorderRadius.circular(_P.rMd),
              border: Border.all(
                  color: JoynColors.border.withValues(alpha: 0.8),
                  width: 1.2),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: _P.infoSoft,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, size: 14, color: JoynColors.primary),
                ),
                const SizedBox(width: 10),
                Flexible(
                  child: Text(_formatDate(date),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: JoynTypography.bodyMedium.copyWith(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: JoynColors.primary)),
                ),
                const Spacer(),
                Icon(Icons.keyboard_arrow_down,
                    size: 18, color: JoynColors.secondaryText),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ==================== Quick Add Strip ====================
  Widget _buildQuickAddStrip() {
    if (_savedItems.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  gradient: _P.primaryGrad,
                  borderRadius: BorderRadius.circular(6),
                  boxShadow: _P.glow(JoynColors.primary, 0.25),
                ),
                child: const Icon(Icons.bolt_rounded,
                    size: 11, color: Colors.white),
              ),
              const SizedBox(width: 6),
              Text('Quick Add',
                  style: JoynTypography.caption.copyWith(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: JoynColors.primary,
                      letterSpacing: 0.2)),
              const Spacer(),
              Text('${_savedItems.length} saved',
                  style: JoynTypography.caption.copyWith(
                      fontSize: 10.5,
                      color: JoynColors.secondaryText,
                      fontWeight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 88,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              itemCount: _savedItems.length,
              itemBuilder: (context, i) {
                final item = _savedItems[i];
                final price = item.purchasePrice != 0
                    ? item.purchasePrice
                    : item.sellingPrice;
                final isLowStock = item.stock <= 0;

                return _PressScale(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    final newItem = OrderItemModel(
                      id: DateTime.now().millisecondsSinceEpoch.toString(),
                      itemName: item.name,
                      category: item.category,
                      unitPrice: price,
                      qty: 1,
                      unit: item.unit,
                    );
                    setState(() {
                      _items.add(newItem);
                      _recalcTotal();
                    });
                  },
                  child: Container(
                    width: 150,
                    margin: const EdgeInsets.only(right: 10),
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color: JoynColors.border.withValues(alpha: 0.7),
                          width: 1.2),
                      boxShadow: _P.soft,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                item.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: JoynTypography.bodyMedium.copyWith(
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w800,
                                    color: JoynColors.primary),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.all(3),
                              decoration: BoxDecoration(
                                gradient: _P.primaryGrad,
                                shape: BoxShape.circle,
                                boxShadow:
                                _P.glow(JoynColors.primary, 0.3),
                              ),
                              child: const Icon(Icons.add,
                                  size: 10, color: Colors.white),
                            ),
                          ],
                        ),
                        if (item.category.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(item.category,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: JoynTypography.caption.copyWith(
                                  fontSize: 10,
                                  color: JoynColors.secondaryText)),
                        ],
                        const Spacer(),
                        Row(
                          children: [
                            Text('₹${price.toStringAsFixed(0)}',
                                style: JoynTypography.bodyMedium.copyWith(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w800,
                                    color: JoynColors.success)),
                            const Spacer(),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 5, vertical: 2),
                              decoration: BoxDecoration(
                                color: isLowStock
                                    ? _P.errorSoft
                                    : _P.infoSoft,
                                borderRadius: BorderRadius.circular(5),
                              ),
                              child: Text('${item.stock}',
                                  style: JoynTypography.caption.copyWith(
                                      fontSize: 9.5,
                                      fontWeight: FontWeight.w800,
                                      color: isLowStock
                                          ? JoynColors.error
                                          : JoynColors.primary)),
                            ),
                          ],
                        ),
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
  }

  // ==================== Items Section ====================
  Widget _buildItemsSection() {
    return _SectionCard(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              gradient: _P.itemHeaderGrad,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(_P.rLg),
                topRight: Radius.circular(_P.rLg),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                    gradient: _P.primaryGrad,
                    shape: BoxShape.circle,
                    boxShadow: _P.glow(JoynColors.primary, 0.35),
                  ),
                  child: const Icon(Icons.check_rounded,
                      size: 13, color: Colors.white),
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: Text('Purchased Items',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: JoynTypography.bodyMedium.copyWith(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: JoynColors.primary,
                          letterSpacing: 0.1)),
                ),
                if (_items.isNotEmpty) ...[
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 7, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.9),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                          color: JoynColors.primary.withValues(alpha: 0.15)),
                    ),
                    child: Text('$_totalQty',
                        style: JoynTypography.caption.copyWith(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: JoynColors.primary)),
                  ),
                ],
                const Spacer(),
                GestureDetector(
                  onTap: () => setState(() => _rateExclTax = !_rateExclTax),
                  child: Container(
                    padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.8),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                          color: JoynColors.primary.withValues(alpha: 0.15)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(_rateExclTax ? 'Excl.' : 'Incl.',
                            style: JoynTypography.caption.copyWith(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: JoynColors.primary)),
                        const Icon(Icons.keyboard_arrow_down,
                            size: 13, color: JoynColors.primary),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (_items.isEmpty)
            _buildEmptyItemsState()
          else
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                children: [
                  ..._items.asMap().entries.map((e) => _SwipeToDelete(
                    onDelete: () => _removeItem(e.value.id),
                    child: _buildPremiumItemCard(e.value, e.key),
                  )),
                  const SizedBox(height: 6),
                  _buildItemsSummaryRow(),
                ],
              ),
            ),

          // ✅ Quick Add Strip
          _buildQuickAddStrip(),

          Padding(
            padding: const EdgeInsets.fromLTRB(14, 0, 14, 16),
            child: Row(
              children: [
                Expanded(
                  flex: 3,
                  child: _PressScale(
                    onTap: () => _addItem(),
                    child: Container(
                      height: 52,
                      decoration: BoxDecoration(
                        color: _P.infoSoft,
                        borderRadius: BorderRadius.circular(_P.rMd),
                        border: Border.all(
                            color: JoynColors.primary.withValues(alpha: 0.2),
                            width: 1.5),
                      ),
                      child: Center(
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                gradient: _P.primaryGrad,
                                shape: BoxShape.circle,
                                boxShadow: _P.glow(JoynColors.primary, 0.35),
                              ),
                              child: const Icon(Icons.add,
                                  color: Colors.white, size: 16),
                            ),
                            const SizedBox(width: 8),
                            Text('Add Items',
                                style: JoynTypography.bodyMedium.copyWith(
                                    fontSize: 14.5,
                                    color: JoynColors.primary,
                                    fontWeight: FontWeight.w700)),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  flex: 2,
                  child: _PressScale(
                    onTap: _scanBarcodeAndAddItem,
                    child: Container(
                      height: 52,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(_P.rMd),
                        border: Border.all(
                            color: JoynColors.primary.withValues(alpha: 0.25),
                            width: 1.5),
                        boxShadow: _P.soft,
                      ),
                      child: Center(
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.qr_code_scanner_rounded,
                                color: JoynColors.primary, size: 18),
                            const SizedBox(width: 6),
                            Text('Scan',
                                style: JoynTypography.bodyMedium.copyWith(
                                    fontSize: 14,
                                    color: JoynColors.primary,
                                    fontWeight: FontWeight.w700)),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyItemsState() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              color: JoynColors.chipBackground,
              shape: BoxShape.circle,
              border: Border.all(
                  color: JoynColors.border.withValues(alpha: 0.5),
                  width: 1.5),
            ),
            child: Icon(Icons.inventory_2_outlined,
                size: 34, color: JoynColors.secondaryText),
          ),
          const SizedBox(height: 14),
          Text('No items added yet',
              style: JoynTypography.bodyMedium.copyWith(
                  fontSize: 14.5,
                  fontWeight: FontWeight.w700,
                  color: JoynColors.secondaryText)),
          const SizedBox(height: 4),
          Text('Tap below to add your first item',
              style: JoynTypography.caption
                  .copyWith(fontSize: 12, color: JoynColors.secondaryText)),
        ],
      ),
    );
  }

  Widget _buildPremiumItemCard(OrderItemModel item, int index) {
    final discountPercent = item.subtotal > 0
        ? ((item.discountAmount / item.subtotal) * 100).toStringAsFixed(0)
        : '0';

    return _PressScale(
      onTap: () => _addItem(existing: item),
      onLongPress: () => _removeItem(item.id),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: JoynColors.chipBackground,
          borderRadius: BorderRadius.circular(_P.rMd),
          border: Border.all(color: JoynColors.border.withValues(alpha: 0.5)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    gradient: _P.primaryGrad,
                    borderRadius: BorderRadius.circular(6),
                    boxShadow: _P.glow(JoynColors.primary, 0.25),
                  ),
                  child: Text('#${index + 1}',
                      style: JoynTypography.caption.copyWith(
                          fontSize: 11,
                          color: Colors.white,
                          fontWeight: FontWeight.w800)),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(item.itemName,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: JoynTypography.bodyLarge.copyWith(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.2,
                          color: JoynColors.primary)),
                ),
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: _P.successSoft,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                        color: JoynColors.success.withValues(alpha: 0.2)),
                  ),
                  child: Text('₹${item.total.toStringAsFixed(0)}',
                      style: JoynTypography.bodyMedium.copyWith(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: JoynColors.success)),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _itemDetailRow(
              'Item Subtotal',
              '${item.qty} ${item.unit.isNotEmpty ? '${item.unit} ' : ''}x ${item.unitPrice.toStringAsFixed(0)}',
              JoynColors.secondaryText,
              valueColor: JoynColors.primary,
            ),
            const SizedBox(height: 6),
            _itemDetailRow(
              'Discount ($discountPercent%)',
              '₹ ${item.discountAmount.toStringAsFixed(0)}',
              _P.warningColor,
              valueColor: _P.warningColor,
            ),
            const SizedBox(height: 6),
            _itemDetailRow(
              'Tax',
              '${item.taxRate.toStringAsFixed(0)}%  •  ₹${item.taxAmount.toStringAsFixed(0)}',
              JoynColors.secondaryText,
              valueColor: JoynColors.primary,
            ),
          ],
        ),
      ),
    );
  }

  Widget _itemDetailRow(String label, String value, Color labelColor,
      {Color? valueColor}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Flexible(
          flex: 3,
          child: Text(label,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: JoynTypography.caption.copyWith(
                  fontSize: 12.5,
                  color: labelColor,
                  fontWeight: FontWeight.w600)),
        ),
        const SizedBox(width: 8),
        Flexible(
          flex: 2,
          child: Text(value,
              textAlign: TextAlign.right,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: JoynTypography.caption.copyWith(
                  fontSize: 12.5,
                  color: valueColor ?? JoynColors.primary,
                  fontWeight: FontWeight.w700)),
        ),
      ],
    );
  }

  Widget _buildItemsSummaryRow() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            JoynColors.primary.withValues(alpha: 0.06),
            JoynColors.primary.withValues(alpha: 0.02),
          ],
        ),
        borderRadius: BorderRadius.circular(_P.rMd),
        border: Border.all(color: JoynColors.primary.withValues(alpha: 0.12)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _summaryChip('Disc', _totalDiscount.toStringAsFixed(2),
                    _P.warningColor),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _summaryChip(
                    'Tax', _totalTax.toStringAsFixed(2), JoynColors.primary),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _summaryChip(
                    'Qty', _totalQty.toString(), JoynColors.secondaryText),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _summaryChip('Subtotal', _subtotal.toStringAsFixed(2),
                    JoynColors.success),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _summaryChip(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Flexible(
            child: Text(label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: JoynTypography.caption.copyWith(
                    fontSize: 11,
                    color: JoynColors.secondaryText,
                    fontWeight: FontWeight.w600)),
          ),
          const SizedBox(width: 4),
          Flexible(
            child: Text(value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.right,
                style: JoynTypography.caption.copyWith(
                    fontSize: 13, color: color, fontWeight: FontWeight.w800)),
          ),
        ],
      ),
    );
  }

  // ==================== Payment Summary ====================
  Widget _buildPaymentSummaryCard() {
    return _SectionCard(
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: _P.infoSoft,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.receipt_long_outlined,
                    size: 14, color: JoynColors.primary),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text('Payment Summary',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: JoynTypography.bodyLarge.copyWith(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.2,
                        color: JoynColors.primary)),
              ),
            ],
          ),
          const SizedBox(height: 18),
          _buildTotalAmountSection(),
          const SizedBox(height: 16),
          Container(
              height: 1, color: JoynColors.border.withValues(alpha: 0.4)),
          const SizedBox(height: 16),
          _buildPaidSection(),
          const SizedBox(height: 20),
          _buildBalanceDueSection(),
        ],
      ),
    );
  }

  Widget _buildTotalAmountSection() {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Total Amount',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: JoynTypography.bodyMedium.copyWith(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: JoynColors.secondaryText)),
              const SizedBox(height: 2),
              Text('(Auto from items)',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: JoynTypography.caption.copyWith(
                      fontSize: 10.5,
                      color: JoynColors.secondaryText.withValues(alpha: 0.7))),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                gradient: _P.primaryGrad,
                borderRadius: BorderRadius.circular(8),
                boxShadow: _P.glow(JoynColors.primary, 0.25),
              ),
              child: const Icon(Icons.currency_rupee,
                  size: 14, color: Colors.white),
            ),
            const SizedBox(width: 8),
            SizedBox(
              width: 120,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextField(
                    controller: _totalAmountController,
                    readOnly: true,
                    enabled: false,
                    textAlign: TextAlign.right,
                    keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                    style: JoynTypography.bodyLarge.copyWith(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: JoynColors.primary),
                    decoration: const InputDecoration(
                      isDense: true,
                      contentPadding: EdgeInsets.only(bottom: 4),
                      border: InputBorder.none,
                      hintText: '0.00',
                    ),
                  ),
                  SizedBox(
                      height: 1.5,
                      child: CustomPaint(
                          painter: DashedLinePainter(),
                          size: const Size(double.infinity, 1.5))),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPaidSection() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SizedBox(
          width: 24,
          height: 24,
          child: Checkbox(
            value: _isPaidChecked,
            onChanged: (v) {
              setState(() {
                _isPaidChecked = v ?? false;
                if (_isPaidChecked) {
                  _paidController.text =
                      _currentTotalAmount.toStringAsFixed(2);
                  _paidAmount = _currentTotalAmount;
                } else {
                  _paidController.text = '0.00';
                  _paidAmount = 0.0;
                }
              });
            },
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            visualDensity: VisualDensity.compact,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(6)),
            side: BorderSide(color: JoynColors.primary, width: 2),
            activeColor: JoynColors.primary,
          ),
        ),
        const SizedBox(width: 12),
        Flexible(
          child: Text('Paid',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: JoynTypography.bodyMedium.copyWith(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: JoynColors.primary)),
        ),
        const Spacer(),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: JoynColors.chipBackground,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: JoynColors.border.withValues(alpha: 0.7)),
          ),
          child: Row(
            children: [
              Text('₹',
                  style: JoynTypography.bodyMedium.copyWith(
                      fontSize: 14,
                      color: JoynColors.secondaryText,
                      fontWeight: FontWeight.w700)),
              const SizedBox(width: 6),
              SizedBox(
                width: 110,
                child: TextField(
                  controller: _paidController,
                  textAlign: TextAlign.right,
                  keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
                  style: JoynTypography.bodyMedium.copyWith(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: JoynColors.primary),
                  decoration: const InputDecoration(
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                    border: InputBorder.none,
                    hintText: '0',
                  ),
                  onChanged: (val) {
                    final parsed = double.tryParse(val) ?? 0.0;
                    setState(() {
                      _paidAmount = parsed;
                      _isPaidChecked = parsed > 0;
                    });
                  },
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBalanceDueSection() {
    final isDue = _currentBalanceDue > 0;
    final color = isDue ? JoynColors.error : JoynColors.success;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            color.withValues(alpha: 0.10),
            color.withValues(alpha: 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(_P.rMd),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(10),
              boxShadow: _P.glow(color, 0.35),
            ),
            child: Icon(isDue ? Icons.trending_up : Icons.check_circle,
                color: Colors.white, size: 16),
          ),
          const SizedBox(width: 12),
          Flexible(
            child: Text('Balance Due',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: JoynTypography.bodyMedium.copyWith(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: color,
                    letterSpacing: 0.1)),
          ),
          const SizedBox(width: 8),
          Flexible(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerRight,
              child: _AnimatedAmount(
                value: _currentBalanceDue,
                style: JoynTypography.bodyLarge.copyWith(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: color),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ==================== More Details ====================
  Widget _buildMoreDetailsCard() {
    return _SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: _P.infoSoft,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.tune_rounded,
                    size: 14, color: JoynColors.primary),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text('More Details',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: JoynTypography.bodyLarge.copyWith(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.2,
                        color: JoynColors.primary)),
              ),
            ],
          ),
          const SizedBox(height: 18),
          _moreDetailRow(
            icon: Icons.payment_rounded,
            iconColor: JoynColors.success,
            label: 'Payment Type',
            value: _paymentType,
            onTap: _openPaymentTypePicker,
          ),
          const SizedBox(height: 12),
          _moreDetailRow(
            icon: Icons.location_on_outlined,
            iconColor: _P.warningColor,
            label: 'State of Supply',
            value: _stateOfSupply,
            onTap: _openStateOfSupplyPicker,
          ),
          const SizedBox(height: 20),
          Divider(height: 1, color: JoynColors.border.withValues(alpha: 0.4)),
          const SizedBox(height: 20),
          Text('Description / Note',
              style: JoynTypography.caption.copyWith(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: JoynColors.secondaryText,
                  letterSpacing: 0.2)),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 3,
                child: Container(
                  decoration: BoxDecoration(
                    color: JoynColors.chipBackground,
                    borderRadius: BorderRadius.circular(_P.rMd),
                    border: Border.all(
                        color: JoynColors.border.withValues(alpha: 0.8),
                        width: 1.2),
                  ),
                  child: TextField(
                    controller: _noteController,
                    maxLines: 4,
                    style: JoynTypography.bodyMedium.copyWith(
                        fontSize: 14, fontWeight: FontWeight.w500),
                    decoration: InputDecoration(
                      hintText: 'Add Note',
                      hintStyle: JoynTypography.bodyMedium.copyWith(
                          fontSize: 14,
                          color:
                          JoynColors.secondaryText.withValues(alpha: 0.6)),
                      contentPadding: const EdgeInsets.all(14),
                      border: InputBorder.none,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              _PressScale(
                onTap: _pickImage,
                child: Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: JoynColors.chipBackground,
                    border: Border.all(
                        color: JoynColors.border.withValues(alpha: 0.8),
                        width: 1.2),
                    borderRadius: BorderRadius.circular(_P.rMd),
                  ),
                  child: _pickedImage != null
                      ? Stack(
                    fit: StackFit.expand,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.file(_pickedImage!,
                            fit: BoxFit.cover),
                      ),
                      Positioned(
                        top: 6,
                        right: 6,
                        child: GestureDetector(
                          onTap: () =>
                              setState(() => _pickedImage = null),
                          child: Container(
                            padding: const EdgeInsets.all(3),
                            decoration: const BoxDecoration(
                                color: Colors.black54,
                                shape: BoxShape.circle),
                            child: const Icon(Icons.close,
                                size: 12, color: Colors.white),
                          ),
                        ),
                      ),
                    ],
                  )
                      : Stack(
                    children: [
                      Center(
                        child: Icon(Icons.image_outlined,
                            size: 36,
                            color: JoynColors.secondaryText
                                .withValues(alpha: 0.6)),
                      ),
                      Positioned(
                        top: 6,
                        right: 6,
                        child: Container(
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            gradient: _P.primaryGrad,
                            shape: BoxShape.circle,
                            boxShadow:
                            _P.glow(JoynColors.primary, 0.35),
                          ),
                          child: const Icon(Icons.add,
                              size: 14, color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _PressScale(
            onTap: _pickDocument,
            child: Container(
              height: 60,
              decoration: BoxDecoration(
                color: JoynColors.chipBackground,
                borderRadius: BorderRadius.circular(_P.rMd),
                border: Border.all(
                    color: JoynColors.border.withValues(alpha: 0.8),
                    width: 1.2),
              ),
              child: Center(
                child: _pickedDocument != null
                    ? Row(
                  children: [
                    const SizedBox(width: 14),
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        gradient: _P.primaryGrad,
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: _P.glow(JoynColors.primary, 0.25),
                      ),
                      child: const Icon(Icons.description,
                          color: Colors.white, size: 14),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        _pickedDocument!.path.split('/').last,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: JoynTypography.bodyMedium.copyWith(
                            fontSize: 13,
                            color: JoynColors.primary,
                            fontWeight: FontWeight.w600),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, size: 18),
                      onPressed: () =>
                          setState(() => _pickedDocument = null),
                    ),
                  ],
                )
                    : Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.description_outlined,
                        size: 20,
                        color: JoynColors.secondaryText
                            .withValues(alpha: 0.7)),
                    const SizedBox(width: 10),
                    Text('Add Document',
                        style: JoynTypography.bodyMedium.copyWith(
                            fontSize: 14,
                            color: JoynColors.secondaryText,
                            fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.only(left: 4),
            child: Row(
              children: [
                Icon(Icons.info_outline,
                    size: 11,
                    color: JoynColors.secondaryText.withValues(alpha: 0.7)),
                const SizedBox(width: 4),
                Text('Internet is required to upload',
                    style: JoynTypography.caption.copyWith(
                        fontSize: 11, color: JoynColors.secondaryText)),
              ],
            ),
          ),
          const SizedBox(height: 20),
          _buildTermsAndConditionsSection(),
        ],
      ),
    );
  }

  Widget _moreDetailRow({
    required IconData icon,
    required Color iconColor,
    required String label,
    required String value,
    required VoidCallback onTap,
  }) {
    return _PressScale(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: JoynColors.chipBackground,
          borderRadius: BorderRadius.circular(_P.rMd),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, size: 16, color: iconColor),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: JoynTypography.bodyMedium.copyWith(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w700,
                      color: JoynColors.primary)),
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Text(value,
                  textAlign: TextAlign.right,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: JoynTypography.bodyMedium.copyWith(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w700,
                      color: JoynColors.secondaryText)),
            ),
            const SizedBox(width: 6),
            Icon(Icons.chevron_right,
                size: 18, color: JoynColors.secondaryText),
          ],
        ),
      ),
    );
  }

  Widget _buildTermsAndConditionsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        InkWell(
          onTap: () => setState(() => _termsExpanded = !_termsExpanded),
          borderRadius: BorderRadius.circular(10),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              children: [
                Icon(Icons.gavel_rounded,
                    size: 16, color: JoynColors.secondaryText),
                const SizedBox(width: 8),
                Flexible(
                  child: Text('Terms & Conditions',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: JoynTypography.bodyMedium.copyWith(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: JoynColors.primary,
                          letterSpacing: -0.1)),
                ),
                const Spacer(),
                AnimatedRotation(
                  turns: _termsExpanded ? 0.5 : 0,
                  duration: const Duration(milliseconds: 200),
                  child: Icon(Icons.keyboard_arrow_down,
                      color: JoynColors.secondaryText),
                ),
              ],
            ),
          ),
        ),
        if (_termsExpanded) ...[
          const SizedBox(height: 12),
          _PressScale(
            onTap: _openTermsPicker,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
              decoration: BoxDecoration(
                color: JoynColors.chipBackground,
                borderRadius: BorderRadius.circular(_P.rMd),
                border: Border.all(
                    color: JoynColors.border.withValues(alpha: 0.8),
                    width: 1.2),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(_selectedTerms ?? 'Select Terms & Conditions',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: JoynTypography.bodyMedium.copyWith(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w600,
                            color: _selectedTerms == null
                                ? JoynColors.secondaryText
                                : JoynColors.primary)),
                  ),
                  Icon(Icons.chevron_right,
                      size: 18, color: JoynColors.secondaryText),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _PressScale(
                  onTap: () =>
                      setState(() => _selectedTerms = 'Standard T&C'),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: _P.infoSoft,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Center(
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text('Saved T&C',
                            maxLines: 1,
                            style: JoynTypography.caption.copyWith(
                                color: JoynColors.primary,
                                fontWeight: FontWeight.w700,
                                fontSize: 13)),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _PressScale(
                  onTap: () => setState(() => _selectedTerms = 'Custom T&C'),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: _P.infoSoft,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Center(
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text('Add Custom',
                            maxLines: 1,
                            style: JoynTypography.caption.copyWith(
                                color: JoynColors.primary,
                                fontWeight: FontWeight.w700,
                                fontSize: 13)),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  // ==================== Bottom Bar ====================
  Widget _buildBottomBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 28,
            offset: const Offset(0, -8),
          ),
        ],
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            if (!_isEditing) ...[
              Expanded(
                flex: 3,
                child: SizedBox(
                  height: 52,
                  child: OutlinedButton(
                    onPressed: () => _save(andNew: true),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                      foregroundColor: JoynColors.primary,
                      side: BorderSide(
                          color: JoynColors.border.withValues(alpha: 0.8),
                          width: 1.5),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(_P.rMd)),
                      backgroundColor: Colors.white,
                    ),
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text('Save & New',
                          maxLines: 1,
                          style: JoynTypography.caption.copyWith(
                              fontSize: 13.5,
                              color: JoynColors.primary,
                              fontWeight: FontWeight.w700)),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
            ],
            Expanded(
              flex: _isEditing ? 1 : 4,
              child: _PressScale(
                onTap: () => _save(),
                child: Container(
                  height: 52,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(_P.rMd),
                    boxShadow: _P.glow(JoynColors.primary, 0.4),
                  ),
                  child: ElevatedButton(
                    onPressed: () => _save(),
                    style: ElevatedButton.styleFrom(
                      padding: EdgeInsets.zero,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(_P.rMd)),
                      elevation: 0,
                      backgroundColor: Colors.transparent,
                    ),
                    child: Ink(
                      decoration: BoxDecoration(
                        gradient: _P.primaryGrad,
                        borderRadius: BorderRadius.circular(_P.rMd),
                      ),
                      child: Container(
                        alignment: Alignment.center,
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.check_rounded,
                                color: Colors.white, size: 18),
                            const SizedBox(width: 6),
                            Flexible(
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Text(
                                    _isEditing ? 'Update' : 'Save',
                                    maxLines: 1,
                                    style:
                                    JoynTypography.buttonText.copyWith(
                                        fontSize: 15,
                                        color: Colors.white,
                                        fontWeight: FontWeight.w800,
                                        letterSpacing: 0.2)),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            if (!_isEditing) ...[
              const SizedBox(width: 8),
              SizedBox(
                width: 52,
                height: 52,
                child: IconButton(
                  style: IconButton.styleFrom(
                    backgroundColor: _P.infoSoft,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(_P.rMd)),
                  ),
                  icon: Icon(Icons.more_vert,
                      color: JoynColors.primary, size: 20),
                  onPressed: _showMoreOptions,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}