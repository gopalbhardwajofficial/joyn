import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/joyn_colors.dart';
import '../../../core/theme/joyn_typography.dart';
import '../models/order_item_model.dart';
import '../models/sales_models.dart';
import '../data/sales_repository.dart';
import 'widgets/add_order_item_dialog.dart';
import '../../Inventory/presentation/add_new_party_screen.dart';
import '../../Inventory/presentation/scan_code_screen.dart';

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

class AddPurchaseOrderScreen extends StatefulWidget {
  const AddPurchaseOrderScreen({super.key});

  @override
  State<AddPurchaseOrderScreen> createState() => _AddPurchaseOrderScreenState();
}

class _AddPurchaseOrderScreenState extends State<AddPurchaseOrderScreen> {
  final SalesRepository _salesRepository = SalesRepository();

  int _orderNo = 1;
  DateTime _selectedDate = DateTime.now();
  DateTime _dueDate = DateTime.now();

  final _partyNameController = TextEditingController();
  final _totalAmountController = TextEditingController();

  final List<OrderItemModel> _items = [];
  bool _userEditedTotalManually = false;

  List<PartyModel> _savedParties = [];
  List<InventoryItemModel> _savedItems = [];

  @override
  void initState() {
    super.initState();
    _loadSavedParties();
    _loadSavedItems();
    _loadNextOrderNo();
  }

  @override
  void dispose() {
    _partyNameController.dispose();
    _totalAmountController.dispose();
    super.dispose();
  }

  Future<void> _loadNextOrderNo() async {
    try {
      final orders = await _salesRepository.getPurchaseOrders();
      if (orders.isNotEmpty && mounted) {
        final maxOrderNo = orders.map((o) => o.orderNo).reduce((a, b) => a > b ? a : b);
        setState(() {
          _orderNo = maxOrderNo + 1;
        });
      }
    } catch (e) {
      debugPrint('Error loading order no: $e');
    }
  }

  Future<void> _loadSavedParties() async {
    try {
      final parties = await _salesRepository.getParties();
      if (!mounted) return;
      setState(() {
        _savedParties = parties;
      });
    } catch (e) {
      debugPrint('Error loading parties: $e');
    }
  }

  Future<void> _loadSavedItems() async {
    try {
      final items = await _salesRepository.getItems();
      if (!mounted) return;
      setState(() {
        _savedItems = items;
      });
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

  double get _itemsTotal => _items.fold(0, (sum, item) => sum + item.amount);

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
        backgroundColor: JoynColors.background,
        elevation: 8,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Order Number', style: JoynTypography.titleMedium.copyWith(fontSize: 18, fontWeight: FontWeight.w800)),
        content: TextField(
          controller: controller,
          autofocus: true,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            hintText: 'Enter order number',
            filled: true,
            fillColor: JoynColors.chipBackground,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            style: TextButton.styleFrom(foregroundColor: JoynColors.primary),
            child: const Text('Update', style: TextStyle(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
    if (result != null && result.isNotEmpty) {
      setState(() => _orderNo = int.tryParse(result) ?? _orderNo);
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
        if (!_userEditedTotalManually) {
          _totalAmountController.text = _itemsTotal.toStringAsFixed(2);
        }
      });
    }
  }

  void _removeItem(String id) {
    HapticFeedback.lightImpact();
    setState(() {
      _items.removeWhere((i) => i.id == id);
      if (!_userEditedTotalManually) {
        _totalAmountController.text = _items.isEmpty ? '' : _itemsTotal.toStringAsFixed(2);
      }
    });
  }

  Future<void> _scanBarcodeAndAddItem() async {
    HapticFeedback.lightImpact();

    final barcode = await Navigator.of(context).push<String>(
      MaterialPageRoute(builder: (_) => const ScanCodeScreen()),
    );

    if (barcode == null || barcode.isEmpty || !mounted) return;

    InventoryItemModel? foundItem;
    for (final item in _savedItems) {
      if (item.barcode.isNotEmpty && item.barcode == barcode) {
        foundItem = item;
        break;
      }
    }

    if (foundItem == null) {
      try {
        final dbItems = await _salesRepository.getItems();
        for (final item in dbItems) {
          if (item.barcode.isNotEmpty && item.barcode == barcode) {
            foundItem = item;
            break;
          }
        }
      } catch (e) {
        debugPrint('Error searching item: $e');
      }
    }

    if (foundItem != null) {
      final newItem = OrderItemModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        itemName: foundItem.name,
        category: foundItem.category,
        price: foundItem.purchasePrice != 0 ? foundItem.purchasePrice : foundItem.sellingPrice,
        qty: 1,
      );

      setState(() {
        _items.add(newItem);
        if (!_userEditedTotalManually) {
          _totalAmountController.text = _itemsTotal.toStringAsFixed(2);
        }
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${foundItem.name} added to items'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: JoynColors.success,
          margin: const EdgeInsets.all(16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          duration: const Duration(seconds: 2),
        ),
      );
    } else {
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

  Future<void> _openPartyPicker() async {
    final selected = await showModalBottomSheet<PartyModel>(
      context: context,
      isScrollControlled: true,
      backgroundColor: JoynColors.background,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
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
                  top: 12,
                  bottom: MediaQuery.of(context).viewInsets.bottom + 12,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4.5,
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(color: JoynColors.border, borderRadius: BorderRadius.circular(3)),
                      ),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Select Party', style: JoynTypography.titleMedium.copyWith(fontSize: 17, fontWeight: FontWeight.w800)),
                        IconButton(
                          icon: const Icon(Icons.close_rounded),
                          onPressed: () => Navigator.pop(sheetContext),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    TextField(
                      autofocus: false,
                      onChanged: (v) => setSheetState(() => query = v),
                      decoration: InputDecoration(
                        hintText: 'Search by name or category',
                        prefixIcon: const Icon(Icons.search_rounded, size: 20),
                        filled: true,
                        fillColor: JoynColors.chipBackground,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 14),
                      ),
                    ),
                    const SizedBox(height: 12),
                    InkWell(
                      onTap: () async {
                        Navigator.pop(sheetContext);
                        final result = await Navigator.of(context).push<Map<String, dynamic>>(
                          MaterialPageRoute(builder: (_) => const AddNewPartyScreen()),
                        );
                        if (result != null) {
                          final newParty = PartyModel(
                            id: DateTime.now().millisecondsSinceEpoch.toString(),
                            name: (result['name'] ?? '').toString(),
                            category: (result['category'] ?? '').toString(),
                            contactNumber: (result['contactNumber'] ?? '').toString(),
                            createdAt: DateTime.now(),
                          );
                          await _salesRepository.insertParty(newParty);
                          _loadSavedParties();
                          setState(() {
                            _partyNameController.text = newParty.name;
                          });
                        }
                      },
                      borderRadius: BorderRadius.circular(14),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
                        decoration: BoxDecoration(
                          color: JoynColors.primary.withValues(alpha: 0.06),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: JoynColors.primary.withValues(alpha: 0.25), width: 1.2),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.person_add_alt_1_rounded, size: 18, color: JoynColors.primary),
                            const SizedBox(width: 8),
                            Text(
                              'Add New Party',
                              style: JoynTypography.bodyMedium.copyWith(fontWeight: FontWeight.w700, color: JoynColors.primary, fontSize: 13.5),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    if (filtered.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 32),
                        child: Center(
                          child: Text(
                            _savedParties.isEmpty ? 'No saved parties yet' : 'No match found',
                            style: JoynTypography.subtitle.copyWith(fontSize: 13.5),
                          ),
                        ),
                      )
                    else
                      ConstrainedBox(
                        constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.45),
                        child: ListView.builder(
                          shrinkWrap: true,
                          itemCount: filtered.length,
                          itemBuilder: (context, index) {
                            final party = filtered[index];
                            return InkWell(
                              onTap: () => Navigator.pop(sheetContext, party),
                              borderRadius: BorderRadius.circular(14),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 40,
                                      height: 40,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        gradient: LinearGradient(
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                          colors: [
                                            JoynColors.primary.withValues(alpha: 0.10),
                                            JoynColors.primary.withValues(alpha: 0.20),
                                          ],
                                        ),
                                      ),
                                      alignment: Alignment.center,
                                      child: Text(
                                        party.name.isNotEmpty ? party.name[0].toUpperCase() : '?',
                                        style: JoynTypography.bodyLarge.copyWith(fontWeight: FontWeight.w800, color: JoynColors.primary),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(party.name, style: JoynTypography.bodyMedium.copyWith(fontWeight: FontWeight.w700, fontSize: 14.5)),
                                          if (party.category.isNotEmpty)
                                            Padding(
                                              padding: const EdgeInsets.only(top: 2),
                                              child: Text(
                                                party.category,
                                                style: JoynTypography.caption.copyWith(fontSize: 11.5, color: JoynColors.secondaryText),
                                              ),
                                            ),
                                        ],
                                      ),
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

    if (selected != null) {
      setState(() {
        _partyNameController.text = selected.name;
      });
    }
  }

  Future<void> _save({bool andNew = false}) async {
    if (_partyNameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Party name is required'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: JoynColors.error,
          margin: const EdgeInsets.all(16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
      );
      return;
    }

    final purchaseOrder = PurchaseOrderModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      orderNo: _orderNo,
      date: _formatDate(_selectedDate),
      dueDate: _formatDate(_dueDate),
      partyName: _partyNameController.text.trim(),
      items: _items.map((i) => {
        'name': i.itemName,
        'category': i.category,
        'price': i.price,
        'qty': i.qty,
        'amount': i.amount,
      }).toList(),
      totalAmount: double.tryParse(_totalAmountController.text.trim()) ?? 0,
      createdAt: DateTime.now(),
    );

    await _salesRepository.insertPurchaseOrder(purchaseOrder);

    HapticFeedback.mediumImpact();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Purchase Order saved successfully!'),
        backgroundColor: JoynColors.primary,
        behavior: SnackBarBehavior.floating,
        elevation: 6,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    );

    if (andNew) {
      setState(() {
        _orderNo++;
        _partyNameController.clear();
        _totalAmountController.clear();
        _items.clear();
        _userEditedTotalManually = false;
      });
    } else {
      context.pop();
    }
  }

  void _showMoreOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: JoynColors.background,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.delete_outline_rounded, color: JoynColors.error),
              title: Text('Discard', style: JoynTypography.bodyLarge.copyWith(fontSize: 15)),
              onTap: () {
                Navigator.pop(context);
                context.pop();
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: JoynColors.background,
      appBar: AppBar(
        elevation: 0,
        scrolledUnderElevation: 0.5,
        backgroundColor: JoynColors.background,
        leading: IconButton(
          icon: Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: JoynColors.chipBackground,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.arrow_back_rounded, size: 18),
          ),
          onPressed: () => context.pop(),
        ),
        centerTitle: true,
        title: Text(
          'Purchase Order',
          style: JoynTypography.titleMedium.copyWith(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.2,
          ),
        ),
        actions: [
          IconButton(
            onPressed: _scanBarcodeAndAddItem,
            icon: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: JoynColors.primary.withValues(alpha: 0.08),
                shape: BoxShape.circle,
                border: Border.all(
                  color: JoynColors.primary.withValues(alpha: 0.2),
                  width: 1,
                ),
              ),
              child: const Icon(Icons.qr_code_scanner_rounded, size: 18, color: JoynColors.primary),
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: JoynColors.chipBackground,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.settings_outlined, size: 18, color: JoynColors.secondaryText),
            ),
            onPressed: () {},
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                children: [
                  _buildSectionHeader(1, 'Order Details', Icons.receipt_long_outlined),
                  const SizedBox(height: 16),
                  _buildOrderDetailsCard(),
                  const SizedBox(height: 30),
                  _buildSectionHeader(2, 'Items', Icons.inventory_2_outlined),
                  const SizedBox(height: 16),
                  _buildItemsCard(),
                  const SizedBox(height: 16),
                ],
              ),
            ),
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border(top: BorderSide(color: JoynColors.border, width: 1)),
                boxShadow: _Premium.fieldShadow,
              ),
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Total Amount',
                    style: JoynTypography.bodyLarge.copyWith(fontSize: 16, fontWeight: FontWeight.w700, color: JoynColors.primary),
                  ),
                  Row(
                    children: [
                      Text('₹', style: JoynTypography.bodyLarge.copyWith(fontSize: 16, fontWeight: FontWeight.w800, color: JoynColors.primary)),
                      const SizedBox(width: 6),
                      SizedBox(
                        width: 110,
                        child: TextField(
                          controller: _totalAmountController,
                          textAlign: TextAlign.right,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          style: JoynTypography.bodyLarge.copyWith(fontSize: 16, fontWeight: FontWeight.w800, color: JoynColors.primary),
                          decoration: InputDecoration(
                            hintText: '0.00',
                            hintStyle: JoynTypography.bodyLarge.copyWith(fontSize: 16, color: JoynColors.secondaryText.withValues(alpha: 0.4)),
                            isDense: true,
                            contentPadding: EdgeInsets.zero,
                            border: const UnderlineInputBorder(borderSide: BorderSide(color: JoynColors.border)),
                            focusedBorder: const UnderlineInputBorder(borderSide: BorderSide(color: JoynColors.primary, width: 1.5)),
                            enabledBorder: const UnderlineInputBorder(borderSide: BorderSide(color: JoynColors.border)),
                          ),
                          onChanged: (_) => _userEditedTotalManually = true,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Container(
              decoration: const BoxDecoration(
                color: JoynColors.background,
                border: Border(top: BorderSide(color: JoynColors.border, width: 1)),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => _save(andNew: true),
                      child: Text(
                        'Save & New',
                        style: JoynTypography.bodyLarge.copyWith(fontSize: 15, fontWeight: FontWeight.w600, color: JoynColors.secondaryText),
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: _Premium.floatingShadow(JoynColors.primary),
                      ),
                      child: SizedBox(
                        height: 46,
                        child: ElevatedButton(
                          onPressed: () => _save(),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: JoynColors.primary,
                            elevation: 0,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: Text('Save', style: JoynTypography.buttonText.copyWith(fontSize: 15)),
                        ),
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: _showMoreOptions,
                    icon: const Icon(Icons.more_vert_rounded, color: JoynColors.secondaryText),
                  ),
                ],
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
              width: 30,
              height: 30,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                gradient: _Premium.gradient(Colors.black87),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.22),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Text(
                '$number',
                style: JoynTypography.caption.copyWith(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 13),
              ),
            ),
            const SizedBox(width: 10),
            Icon(icon, size: 17, color: JoynColors.primary),
            const SizedBox(width: 6),
            Text(
              title,
              style: JoynTypography.bodyLarge.copyWith(
                fontWeight: FontWeight.w800,
                fontSize: 17,
                letterSpacing: -0.2,
                color: JoynColors.primary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          height: 1.2,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [JoynColors.border, JoynColors.border.withValues(alpha: 0.0)],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildOrderDetailsCard() {
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
                child: InkWell(
                  onTap: _editOrderNo,
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
                          decoration: BoxDecoration(
                            color: JoynColors.primary.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.tag_rounded, size: 16, color: JoynColors.primary),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text('Order No.', style: JoynTypography.caption.copyWith(fontSize: 10.5, color: JoynColors.secondaryText, fontWeight: FontWeight.w700)),
                              Text('$_orderNo', style: JoynTypography.bodyLarge.copyWith(fontSize: 12, fontWeight: FontWeight.w700, color: JoynColors.primary)),
                            ],
                          ),
                        ),
                        const Icon(Icons.keyboard_arrow_down_rounded, size: 18, color: JoynColors.primary),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: InkWell(
                  onTap: _pickDate,
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
                          decoration: BoxDecoration(
                            color: JoynColors.primary.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.calendar_today_outlined, size: 15, color: JoynColors.primary),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text('Date', style: JoynTypography.caption.copyWith(fontSize: 10.5, color: JoynColors.secondaryText, fontWeight: FontWeight.w700)),
                              Text(_formatDate(_selectedDate), style: JoynTypography.bodyLarge.copyWith(fontSize: 10.5, fontWeight: FontWeight.w700, color: JoynColors.primary)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _buildPartyPickerField(),
          const SizedBox(height: 14),
          InkWell(
            onTap: _pickDueDate,
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
                    decoration: BoxDecoration(
                      color: JoynColors.primary.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.event_available_outlined, size: 16, color: JoynColors.primary),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('Due Date', style: JoynTypography.caption.copyWith(fontSize: 10.5, color: JoynColors.secondaryText, fontWeight: FontWeight.w700)),
                        Text(_formatDate(_dueDate), style: JoynTypography.bodyLarge.copyWith(fontSize: 15, fontWeight: FontWeight.w700, color: JoynColors.primary)),
                      ],
                    ),
                  ),
                  const Icon(Icons.keyboard_arrow_down_rounded, size: 18, color: JoynColors.primary),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPartyPickerField() {
    final hasValue = _partyNameController.text.trim().isNotEmpty;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Party Name *', style: JoynTypography.bodyMedium.copyWith(fontSize: 13, fontWeight: FontWeight.w700, color: JoynColors.secondaryText)),
        const SizedBox(height: 6),
        InkWell(
          onTap: _openPartyPicker,
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
                  decoration: BoxDecoration(
                    color: JoynColors.primary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.storefront_outlined, size: 16, color: JoynColors.primary),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    hasValue ? _partyNameController.text : 'Search or select party',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: JoynTypography.bodyLarge.copyWith(
                      fontSize: 15,
                      fontWeight: hasValue ? FontWeight.w600 : FontWeight.w500,
                      color: hasValue ? JoynColors.primary : JoynColors.secondaryText.withValues(alpha: 0.6),
                    ),
                  ),
                ),
                const Icon(Icons.search_rounded, size: 18, color: JoynColors.primary),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildItemsCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: _Premium.surfaceGradient,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: JoynColors.border, width: 1.2),
        boxShadow: _Premium.cardShadow,
      ),
      child: _items.isEmpty
          ? InkWell(
        onTap: () => _addItem(),
        borderRadius: BorderRadius.circular(14),
        child: Container(
          height: 52,
          decoration: BoxDecoration(
            color: JoynColors.chipBackground,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: JoynColors.border, width: 1.2),
          ),
          child: Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.add_circle_rounded, color: JoynColors.primary, size: 20),
                const SizedBox(width: 8),
                Text('Add Items ', style: JoynTypography.bodyLarge.copyWith(fontSize: 15.5, fontWeight: FontWeight.w700, color: JoynColors.primary)),
                Text('(Optional)', style: JoynTypography.bodyLarge.copyWith(fontSize: 15.5, color: JoynColors.secondaryText)),
              ],
            ),
          ),
        ),
      )
          : Column(
        children: [
          ..._items.map((item) => _buildItemRow(item)),
          const SizedBox(height: 4),
          InkWell(
            onTap: () => _addItem(),
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.add_circle_outline_rounded, size: 18, color: JoynColors.primary),
                  const SizedBox(width: 6),
                  Text('Add Another Item', style: JoynTypography.bodyMedium.copyWith(fontSize: 13.5, fontWeight: FontWeight.w700, color: JoynColors.primary)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildItemRow(OrderItemModel item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: JoynColors.border, width: 1.2),
        boxShadow: _Premium.fieldShadow,
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: JoynColors.primary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.inventory_2_outlined, size: 16, color: JoynColors.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.itemName, style: JoynTypography.bodyMedium.copyWith(fontWeight: FontWeight.w700, fontSize: 14)),
                const SizedBox(height: 2),
                Text('${item.qty} x ₹${item.price.toStringAsFixed(2)}', style: JoynTypography.caption.copyWith(fontSize: 12, color: JoynColors.secondaryText)),
              ],
            ),
          ),
          Text('₹${item.amount.toStringAsFixed(2)}', style: JoynTypography.bodyLarge.copyWith(fontWeight: FontWeight.w800, fontSize: 15, color: JoynColors.primary)),
          const SizedBox(width: 10),
          InkWell(onTap: () => _addItem(existing: item), child: const Icon(Icons.edit_outlined, size: 18, color: JoynColors.secondaryText)),
          const SizedBox(width: 10),
          InkWell(onTap: () => _removeItem(item.id), child: const Icon(Icons.delete_outline_rounded, size: 18, color: JoynColors.error)),
        ],
      ),
    );
  }
}