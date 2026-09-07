import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/joyn_colors.dart';
import '../../../core/theme/joyn_typography.dart';
import '../../orders/models/sales_models.dart';
import '../../orders/data/sales_repository.dart';
import '../../Inventory/presentation/add_new_item_screen.dart';
import '../../Inventory/presentation/item_detail_screen.dart';

enum _SortOption { nameAsc, nameDesc, stockLow, stockHigh, priceLow, priceHigh, recentlyAdded }
enum _StockFilter { all, inStock, lowStock, outOfStock }

class ItemsListScreen extends StatefulWidget {
  const ItemsListScreen({super.key});

  @override
  State<ItemsListScreen> createState() => _ItemsListScreenState();
}

class _ItemsListScreenState extends State<ItemsListScreen> {
  final SalesRepository _salesRepository = SalesRepository();
  List<InventoryItemModel> _items = [];
  List<InventoryItemModel> _filteredItems = [];
  bool _isLoading = true;
  String _searchQuery = '';

  _SortOption _sortOption = _SortOption.nameAsc;
  _StockFilter _stockFilter = _StockFilter.all;
  String? _filterCategory;

  @override
  void initState() {
    super.initState();
    _loadItems();
  }

  Future<void> _loadItems() async {
    try {
      final items = await _salesRepository.getItems();
      if (!mounted) return;
      setState(() {
        _items = List<InventoryItemModel>.from(items);
        _isLoading = false;
        _applyFilters();
      });
    } catch (e) {
      debugPrint('Error loading items: $e');
      if (!mounted) return;
      setState(() {
        _items = [];
        _isLoading = false;
      });
    }
  }

  List<String> get _availableCategories {
    final categories = _items
        .map((item) => item.category)
        .where((c) => c.isNotEmpty)
        .toSet()
        .toList()
      ..sort();
    return categories;
  }

  void _applyFilters() {
    var list = _items.where((item) {
      // Search filter
      final query = _searchQuery.toLowerCase().trim();
      final matchesQuery = query.isEmpty ||
          item.name.toLowerCase().contains(query) ||
          item.category.toLowerCase().contains(query) ||
          item.barcode.contains(query) ||
          item.hsnSac.toLowerCase().contains(query);

      // Stock filter
      final matchesStock = _stockFilter == _StockFilter.all ||
          (_stockFilter == _StockFilter.inStock && item.stock > 5) ||
          (_stockFilter == _StockFilter.lowStock && item.stock > 0 && item.stock <= 5) ||
          (_stockFilter == _StockFilter.outOfStock && item.stock <= 0);

      // Category filter
      final matchesCategory = _filterCategory == null || item.category == _filterCategory;

      return matchesQuery && matchesStock && matchesCategory;
    }).toList();

    // Apply sorting
    switch (_sortOption) {
      case _SortOption.nameAsc:
        list.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
        break;
      case _SortOption.nameDesc:
        list.sort((a, b) => b.name.toLowerCase().compareTo(a.name.toLowerCase()));
        break;
      case _SortOption.stockLow:
        list.sort((a, b) => a.stock.compareTo(b.stock));
        break;
      case _SortOption.stockHigh:
        list.sort((a, b) => b.stock.compareTo(a.stock));
        break;
      case _SortOption.priceLow:
        list.sort((a, b) => a.sellingPrice.compareTo(b.sellingPrice));
        break;
      case _SortOption.priceHigh:
        list.sort((a, b) => b.sellingPrice.compareTo(a.sellingPrice));
        break;
      case _SortOption.recentlyAdded:
        list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        break;
    }

    _filteredItems = list;
  }

  void _onSearchChanged(String value) {
    setState(() {
      _searchQuery = value;
      _applyFilters();
    });
  }

  Future<void> _navigateToAddItem() async {
    HapticFeedback.lightImpact();
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => const AddNewItemScreen()),
    );

    if (mounted) {
      await _loadItems();
    }
  }

  Future<void> _navigateToEditItem(InventoryItemModel item) async {
    HapticFeedback.lightImpact();
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => AddNewItemScreen(existingItem: item),
      ),
    );

    if (mounted) {
      await _loadItems();
    }
  }

  Future<void> _navigateToItemDetail(InventoryItemModel item) async {
    HapticFeedback.lightImpact();
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ItemDetailScreen(item: item),
      ),
    );

    if (mounted) {
      await _loadItems();
    }
  }

  Future<void> _deleteItem(InventoryItemModel item) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Text('Delete Item?', style: JoynTypography.titleMedium.copyWith(fontSize: 17, fontWeight: FontWeight.w700)),
        content: Text(
          'Remove "${item.name}" from your inventory?',
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
      await _salesRepository.deleteItem(item.id);
      await _loadItems();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Item deleted successfully!'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: JoynColors.error,
            margin: const EdgeInsets.all(16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
        );
      }
    }
  }

  Future<void> _duplicateItem(InventoryItemModel item) async {
    final newItem = InventoryItemModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: '${item.name} (Copy)',
      qty: item.qty,
      barcode: item.barcode,
      unit: item.unit,
      category: item.category,
      hsnSac: item.hsnSac,
      location: item.location,
      barcodeMode: item.barcodeMode,
      photoPath: item.photoPath,
      purchasePrice: item.purchasePrice,
      sellingPrice: item.sellingPrice,
      salePriceTaxMode: item.salePriceTaxMode,
      discountOnSalePrice: item.discountOnSalePrice,
      discountType: item.discountType,
      purchasePriceTaxMode: item.purchasePriceTaxMode,
      taxRateLabel: item.taxRateLabel,
      taxRatePercent: item.taxRatePercent,
      stock: item.stock,
      createdAt: DateTime.now(),
    );

    await _salesRepository.insertItem(newItem);
    await _loadItems();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Item duplicated: ${newItem.name}'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: JoynColors.primary,
          margin: const EdgeInsets.all(16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
      );
    }
  }

  Future<void> _showItemOptions(InventoryItemModel item) async {
    await showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4.5,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: JoynColors.border,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      item.name,
                      style: JoynTypography.titleMedium.copyWith(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                _buildOptionTile(
                  icon: Icons.visibility_outlined,
                  label: 'View Details',
                  color: JoynColors.primary,
                  onTap: () {
                    Navigator.pop(context);
                    _navigateToItemDetail(item);
                  },
                ),
                _buildOptionTile(
                  icon: Icons.edit_outlined,
                  label: 'Edit Item',
                  color: const Color(0xFFF59E0B),
                  onTap: () {
                    Navigator.pop(context);
                    _navigateToEditItem(item);
                  },
                ),
                _buildOptionTile(
                  icon: Icons.copy_outlined,
                  label: 'Duplicate',
                  color: const Color(0xFF2563EB),
                  onTap: () {
                    Navigator.pop(context);
                    _duplicateItem(item);
                  },
                ),
                _buildOptionTile(
                  icon: Icons.delete_outline_rounded,
                  label: 'Delete',
                  color: JoynColors.error,
                  isDestructive: true,
                  onTap: () {
                    Navigator.pop(context);
                    _deleteItem(item);
                  },
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildOptionTile({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
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
                color: isDestructive ? JoynColors.error : Colors.black87,
              ),
            ),
            const Spacer(),
            Icon(Icons.chevron_right_rounded, size: 20, color: Colors.grey.shade400),
          ],
        ),
      ),
    );
  }

  void _showSortSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4.5,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(color: JoynColors.border, borderRadius: BorderRadius.circular(3)),
            ),
            Text('Sort Items', style: JoynTypography.titleMedium.copyWith(fontSize: 17, fontWeight: FontWeight.w800)),
            const SizedBox(height: 8),
            _buildSortTile('Name (A-Z)', Icons.sort_by_alpha_rounded, _SortOption.nameAsc),
            _buildSortTile('Name (Z-A)', Icons.sort_by_alpha_rounded, _SortOption.nameDesc),
            _buildSortTile('Stock (Low to High)', Icons.inventory_2_outlined, _SortOption.stockLow),
            _buildSortTile('Stock (High to Low)', Icons.inventory_2_outlined, _SortOption.stockHigh),
            _buildSortTile('Price (Low to High)', Icons.currency_rupee_rounded, _SortOption.priceLow),
            _buildSortTile('Price (High to Low)', Icons.currency_rupee_rounded, _SortOption.priceHigh),
            _buildSortTile('Recently Added', Icons.access_time_rounded, _SortOption.recentlyAdded),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _buildSortTile(String label, IconData icon, _SortOption option) {
    final selected = _sortOption == option;
    return ListTile(
      leading: Icon(icon, size: 20, color: selected ? JoynColors.primary : JoynColors.secondaryText),
      title: Text(
        label,
        style: JoynTypography.bodyLarge.copyWith(
          fontSize: 14.5,
          fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
          color: selected ? JoynColors.primary : Colors.black87,
        ),
      ),
      trailing: selected ? const Icon(Icons.check_rounded, color: JoynColors.primary) : null,
      onTap: () {
        setState(() {
          _sortOption = option;
          _applyFilters();
        });
        Navigator.pop(context);
      },
    );
  }

  void _showFilterSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          return SafeArea(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 12),
                  Center(
                    child: Container(
                      width: 40,
                      height: 4.5,
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(color: JoynColors.border, borderRadius: BorderRadius.circular(3)),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Text('Filter Items', style: JoynTypography.titleMedium.copyWith(fontSize: 17, fontWeight: FontWeight.w800)),
                  ),
                  const SizedBox(height: 16),

                  // Stock Filter
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Text('Stock Status', style: JoynTypography.bodyMedium.copyWith(fontSize: 13, fontWeight: FontWeight.w700, color: JoynColors.secondaryText)),
                  ),
                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _buildFilterChip('All', _stockFilter == _StockFilter.all, () {
                          setModalState(() => _stockFilter = _StockFilter.all);
                        }),
                        _buildFilterChip('In Stock', _stockFilter == _StockFilter.inStock, () {
                          setModalState(() => _stockFilter = _StockFilter.inStock);
                        }),
                        _buildFilterChip('Low Stock', _stockFilter == _StockFilter.lowStock, () {
                          setModalState(() => _stockFilter = _StockFilter.lowStock);
                        }),
                        _buildFilterChip('Out of Stock', _stockFilter == _StockFilter.outOfStock, () {
                          setModalState(() => _stockFilter = _StockFilter.outOfStock);
                        }),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Category Filter
                  if (_availableCategories.isNotEmpty) ...[
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Text('Category', style: JoynTypography.bodyMedium.copyWith(fontSize: 13, fontWeight: FontWeight.w700, color: JoynColors.secondaryText)),
                    ),
                    const SizedBox(height: 8),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _buildFilterChip('All', _filterCategory == null, () {
                            setModalState(() => _filterCategory = null);
                          }),
                          ..._availableCategories.map((category) => _buildFilterChip(
                            category,
                            _filterCategory == category,
                                () {
                              setModalState(() => _filterCategory = category);
                            },
                          )),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],

                  // Apply buttons
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () {
                              setState(() {
                                _stockFilter = _StockFilter.all;
                                _filterCategory = null;
                                _applyFilters();
                              });
                              Navigator.pop(context);
                            },
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            ),
                            child: const Text('Clear All'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 2,
                          child: ElevatedButton(
                            onPressed: () {
                              setState(() {
                                _applyFilters();
                              });
                              Navigator.pop(context);
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: JoynColors.primary,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            ),
                            child: const Text('Apply Filters', style: TextStyle(color: Colors.white)),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildFilterChip(String label, bool selected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          gradient: selected ? LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [JoynColors.primary, Color.lerp(JoynColors.primary, Colors.black, 0.18) ?? JoynColors.primary],
          ) : null,
          color: selected ? null : JoynColors.chipBackground,
          borderRadius: BorderRadius.circular(20),
          border: selected ? null : Border.all(color: JoynColors.border, width: 1),
        ),
        child: Text(
          label,
          style: JoynTypography.caption.copyWith(
            fontSize: 12.5,
            fontWeight: FontWeight.w700,
            color: selected ? Colors.white : JoynColors.secondaryText,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final activeFilterCount = (_stockFilter != _StockFilter.all ? 1 : 0) + (_filterCategory != null ? 1 : 0);

    return Scaffold(
      backgroundColor: JoynColors.background,
      appBar: AppBar(
        backgroundColor: JoynColors.background,
        elevation: 0,
        scrolledUnderElevation: 0.5,
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
          'Items',
          style: JoynTypography.titleMedium.copyWith(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.2,
          ),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Search + Sort + Filter row
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      height: 48,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: JoynColors.border, width: 1.2),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.035),
                            blurRadius: 10,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: TextField(
                        onChanged: _onSearchChanged,
                        decoration: InputDecoration(
                          hintText: 'Search by name, category, barcode...',
                          hintStyle: JoynTypography.bodyMedium.copyWith(
                            color: JoynColors.secondaryText.withValues(alpha: 0.5),
                            fontSize: 13.5,
                          ),
                          prefixIcon: const Icon(Icons.search_rounded, size: 20, color: JoynColors.secondaryText),
                          suffixIcon: _searchQuery.isNotEmpty
                              ? IconButton(
                            icon: const Icon(Icons.clear_rounded, size: 18, color: JoynColors.secondaryText),
                            onPressed: () => _onSearchChanged(''),
                          )
                              : null,
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Tooltip(
                    message: 'Sort',
                    child: InkWell(
                      onTap: _showSortSheet,
                      borderRadius: BorderRadius.circular(14),
                      child: Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: JoynColors.border, width: 1.2),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.035),
                              blurRadius: 10,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: const Icon(Icons.swap_vert_rounded, size: 20, color: JoynColors.primary),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Tooltip(
                    message: 'Filter',
                    child: InkWell(
                      onTap: _showFilterSheet,
                      borderRadius: BorderRadius.circular(14),
                      child: Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: JoynColors.border, width: 1.2),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.035),
                              blurRadius: 10,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            const Icon(Icons.filter_list_rounded, size: 20, color: JoynColors.primary),
                            if (activeFilterCount > 0)
                              Positioned(
                                top: 6,
                                right: 6,
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: const BoxDecoration(
                                    color: JoynColors.error,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Text(
                                    '$activeFilterCount',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 9,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Active filters display
            if (activeFilterCount > 0)
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                child: Row(
                  children: [
                    Text(
                      '${_filteredItems.length} items',
                      style: JoynTypography.caption.copyWith(
                        fontSize: 12,
                        color: JoynColors.secondaryText,
                      ),
                    ),
                    const Spacer(),
                    if (_stockFilter != _StockFilter.all)
                      Padding(
                        padding: const EdgeInsets.only(right: 4),
                        child: Chip(
                          label: Text(
                            _stockFilter == _StockFilter.inStock
                                ? 'In Stock'
                                : _stockFilter == _StockFilter.lowStock
                                ? 'Low Stock'
                                : 'Out of Stock',
                            style: const TextStyle(fontSize: 11),
                          ),
                          onDeleted: () {
                            setState(() {
                              _stockFilter = _StockFilter.all;
                              _applyFilters();
                            });
                          },
                          backgroundColor: JoynColors.chipBackground,
                          visualDensity: VisualDensity.compact,
                        ),
                      ),
                    if (_filterCategory != null)
                      Chip(
                        label: Text('Category: $_filterCategory', style: const TextStyle(fontSize: 11)),
                        onDeleted: () {
                          setState(() {
                            _filterCategory = null;
                            _applyFilters();
                          });
                        },
                        backgroundColor: JoynColors.chipBackground,
                        visualDensity: VisualDensity.compact,
                      ),
                  ],
                ),
              )
            else if (_items.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${_filteredItems.length} items',
                      style: JoynTypography.caption.copyWith(
                        fontSize: 12,
                        color: JoynColors.secondaryText,
                      ),
                    ),
                    Text(
                      'Stock Value: ₹${_calculateTotalStockValue().toStringAsFixed(2)}',
                      style: JoynTypography.caption.copyWith(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: JoynColors.primary,
                      ),
                    ),
                  ],
                ),
              ),

            // Items List
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator(color: JoynColors.primary))
                  : _filteredItems.isEmpty
                  ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: JoynColors.iconBackground,
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: const Icon(Icons.inventory_2_outlined, size: 40, color: JoynColors.secondaryText),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _searchQuery.isNotEmpty || activeFilterCount > 0
                          ? 'No Items Found'
                          : 'No Items Yet',
                      style: JoynTypography.titleMedium.copyWith(fontSize: 18, fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _searchQuery.isNotEmpty || activeFilterCount > 0
                          ? 'Try adjusting your search or filters'
                          : 'Tap "Add Item" to create your first item',
                      style: JoynTypography.subtitle.copyWith(fontSize: 13),
                    ),
                  ],
                ),
              )
                  : RefreshIndicator(
                onRefresh: _loadItems,
                color: JoynColors.primary,
                child: ListView.builder(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                  itemCount: _filteredItems.length,
                  itemBuilder: (context, index) {
                    final item = _filteredItems[index];
                    return _buildItemCard(item);
                  },
                ),
              ),
            ),

            // Add Item Button
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      JoynColors.primary,
                      Color.lerp(JoynColors.primary, Colors.black, 0.18) ?? JoynColors.primary,
                    ],
                  ),
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [
                    BoxShadow(
                      color: JoynColors.primary.withValues(alpha: 0.28),
                      blurRadius: 14,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(18),
                    onTap: _navigateToAddItem,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.add_rounded, color: Colors.white, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            'Add Item',
                            style: JoynTypography.bodyMedium.copyWith(
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                              fontSize: 14.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  double _calculateTotalStockValue() {
    double total = 0;
    for (final item in _filteredItems) {
      total += item.stock * item.purchasePrice;
    }
    return total;
  }

  Widget _buildItemCard(InventoryItemModel item) {
    final isLowStock = item.stock <= 5 && item.stock > 0;
    final isOutOfStock = item.stock <= 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
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
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _navigateToItemDetail(item),
          onLongPress: () => _showItemOptions(item),
          borderRadius: BorderRadius.circular(18),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    // Item Photo or Icon
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: item.photoPath.isNotEmpty
                          ? ClipRRect(
                        borderRadius: BorderRadius.circular(14),
                        child: Image.file(
                          File(item.photoPath),
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return _buildItemIconFallback(item);
                          },
                        ),
                      )
                          : _buildItemIconFallback(item),
                    ),
                    const SizedBox(width: 14),
                    // Item Info
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.name,
                            style: JoynTypography.bodyLarge.copyWith(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: JoynColors.primary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          if (item.category.isNotEmpty)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: JoynColors.chipBackground,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                item.category,
                                style: JoynTypography.caption.copyWith(
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w600,
                                  color: JoynColors.secondaryText,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    // Stock Badge
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: isOutOfStock
                            ? JoynColors.error.withValues(alpha: 0.08)
                            : isLowStock
                            ? const Color(0xFFF59E0B).withValues(alpha: 0.08)
                            : JoynColors.success.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isOutOfStock
                              ? JoynColors.error.withValues(alpha: 0.2)
                              : isLowStock
                              ? const Color(0xFFF59E0B).withValues(alpha: 0.2)
                              : JoynColors.success.withValues(alpha: 0.2),
                          width: 1,
                        ),
                      ),
                      child: Text(
                        'Stock: ${item.stock}',
                        style: JoynTypography.caption.copyWith(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w700,
                          color: isOutOfStock
                              ? JoynColors.error
                              : isLowStock
                              ? const Color(0xFFF59E0B)
                              : JoynColors.success,
                        ),
                      ),
                    ),
                    // More Options Button
                    IconButton(
                      icon: const Icon(Icons.more_vert_rounded, size: 20, color: JoynColors.secondaryText),
                      onPressed: () => _showItemOptions(item),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                // Price Info
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildPriceInfo('Purchase', item.purchasePrice),
                    _buildPriceInfo('Selling', item.sellingPrice),
                    _buildPriceInfo('Unit', item.unit),
                  ],
                ),
                if (item.barcode.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      const Icon(Icons.qr_code_rounded, size: 14, color: JoynColors.secondaryText),
                      const SizedBox(width: 6),
                      Text(
                        'Barcode: ${item.barcode}',
                        style: JoynTypography.caption.copyWith(
                          fontSize: 11,
                          color: JoynColors.secondaryText,
                        ),
                      ),
                    ],
                  ),
                ],
                // Edit Button
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton.icon(
                      onPressed: () => _navigateToEditItem(item),
                      icon: const Icon(Icons.edit_outlined, size: 16, color: const Color(0xFFF59E0B)),
                      label: Text(
                        'Edit',
                        style: JoynTypography.caption.copyWith(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFFF59E0B),
                        ),
                      ),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        backgroundColor: const Color(0xFFF59E0B).withValues(alpha: 0.08),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildItemIconFallback(InventoryItemModel item) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            JoynColors.primary.withValues(alpha: 0.08),
            JoynColors.primary.withValues(alpha: 0.16),
          ],
        ),
        borderRadius: BorderRadius.circular(14),
      ),
      alignment: Alignment.center,
      child: Text(
        item.name.isNotEmpty ? item.name[0].toUpperCase() : '?',
        style: JoynTypography.titleMedium.copyWith(
          fontSize: 20,
          fontWeight: FontWeight.w800,
          color: JoynColors.primary,
        ),
      ),
    );
  }

  Widget _buildPriceInfo(String label, dynamic value) {
    final displayValue = value is double
        ? '₹${value.toStringAsFixed(2)}'
        : value.toString();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: JoynTypography.caption.copyWith(
            fontSize: 10,
            color: JoynColors.secondaryText,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          displayValue,
          style: JoynTypography.caption.copyWith(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: JoynColors.primary,
          ),
        ),
      ],
    );
  }
}