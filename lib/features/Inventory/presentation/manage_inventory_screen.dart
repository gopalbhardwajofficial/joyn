import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/joyn_colors.dart';
import '../../../core/theme/joyn_typography.dart';
import '../../orders/models/sales_models.dart';
import '../../orders/data/sales_repository.dart';

class ManageInventoryScreen extends StatefulWidget {
  const ManageInventoryScreen({super.key});

  @override
  State<ManageInventoryScreen> createState() => _ManageInventoryScreenState();
}

class _ManageInventoryScreenState extends State<ManageInventoryScreen> {
  final SalesRepository _salesRepository = SalesRepository();

  // Filter controllers
  final TextEditingController _nameCtrl = TextEditingController();
  final TextEditingController _hsnCtrl = TextEditingController();
  String? _selectedCategory;

  List<InventoryItemModel> _allItems = [];
  List<InventoryItemModel> _filteredItems = [];
  bool _isLoading = true;

  List<String> get _availableCategories {
    final categories = _allItems
        .map((item) => item.category)
        .where((c) => c.isNotEmpty)
        .toSet()
        .toList()
      ..sort();
    return categories;
  }

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
        _allItems = items;
        _isLoading = false;
        _applyFilters();
      });
    } catch (e) {
      debugPrint('Error loading items: $e');
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  void _applyFilters() {
    var list = _allItems.where((item) {
      final nameQuery = _nameCtrl.text.trim().toLowerCase();
      final hsnQuery = _hsnCtrl.text.trim().toLowerCase();

      final matchesName = nameQuery.isEmpty || item.name.toLowerCase().contains(nameQuery);
      final matchesHsn = hsnQuery.isEmpty || item.hsnSac.toLowerCase().contains(hsnQuery);
      final matchesCategory = _selectedCategory == null || item.category == _selectedCategory;

      return matchesName && matchesHsn && matchesCategory;
    }).toList();

    list.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    _filteredItems = list;
  }

  void _clearAllFilters() {
    setState(() {
      _nameCtrl.clear();
      _hsnCtrl.clear();
      _selectedCategory = null;
      _applyFilters();
    });
  }

  Future<void> _showItemDetail(InventoryItemModel item) async {
    HapticFeedback.lightImpact();
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        contentPadding: EdgeInsets.zero,
        content: Container(
          width: double.maxFinite,
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.75,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header with Image
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      JoynColors.primary.withValues(alpha: 0.05),
                      JoynColors.primary.withValues(alpha: 0.1),
                    ],
                  ),
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                ),
                child: Row(
                  children: [
                    // Item Image or Icon
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: item.photoPath.isNotEmpty
                          ? ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Image.file(
                          File(item.photoPath),
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return _buildItemIconFallback(item, 24);
                          },
                        ),
                      )
                          : _buildItemIconFallback(item, 24),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.name,
                            style: JoynTypography.titleMedium.copyWith(
                              fontSize: 17,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          if (item.category.isNotEmpty)
                            Text(
                              item.category,
                              style: JoynTypography.bodyMedium.copyWith(
                                fontSize: 12,
                                color: JoynColors.secondaryText,
                              ),
                            ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              // Large Image Preview (if available)
              if (item.photoPath.isNotEmpty)
                Container(
                  width: double.infinity,
                  height: 180,
                  margin: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: JoynColors.border, width: 1),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Image.file(
                      File(item.photoPath),
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Center(
                          child: Icon(
                            Icons.image_not_supported_outlined,
                            size: 48,
                            color: JoynColors.secondaryText,
                          ),
                        );
                      },
                    ),
                  ),
                ),
              // Details
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildDetailSection('Stock Information', [
                        _buildDetailRow('Quantity', '${item.qty} ${item.unit}'),
                        _buildDetailRow('Stock', '${item.stock} ${item.unit}'),
                        _buildDetailRow('Location', item.location.isEmpty ? 'Not Set' : item.location),
                        _buildDetailRow('Barcode Mode', item.barcodeMode == 'same' ? 'Same for all' : 'Separate'),
                      ]),
                      const SizedBox(height: 16),
                      _buildDetailSection('Pricing', [
                        _buildDetailRow('Purchase Price', '₹${item.purchasePrice.toStringAsFixed(2)}'),
                        _buildDetailRow('Selling Price', '₹${item.sellingPrice.toStringAsFixed(2)}'),
                        if (item.taxRatePercent > 0) ...[
                          _buildDetailRow('Tax Rate', item.taxRateLabel),
                          _buildDetailRow('Tax Percent', '${item.taxRatePercent}%'),
                        ],
                      ]),
                      const SizedBox(height: 16),
                      _buildDetailSection('Item Details', [
                        _buildDetailRow('HSN/SAC', item.hsnSac.isEmpty ? 'Not Set' : item.hsnSac),
                        _buildDetailRow('Unit', item.unit),
                        _buildDetailRow('Barcode', item.barcode.isEmpty ? 'Not Set' : item.barcode),
                      ]),
                      const SizedBox(height: 16),
                      _buildDetailSection('Created', [
                        _buildDetailRow('Date', '${item.createdAt.day}/${item.createdAt.month}/${item.createdAt.year}'),
                        _buildDetailRow('Time', '${item.createdAt.hour}:${item.createdAt.minute.toString().padLeft(2, '0')}'),
                      ]),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailSection(String title, List<Widget> children) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: JoynColors.chipBackground,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: JoynColors.border, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: JoynTypography.bodyLarge.copyWith(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: JoynColors.primary,
            ),
          ),
          const SizedBox(height: 10),
          ...children,
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: JoynTypography.bodyMedium.copyWith(
              fontSize: 12.5,
              color: JoynColors.secondaryText,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: JoynTypography.bodyMedium.copyWith(
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
                color: JoynColors.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _hsnCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
          'Manage Inventory',
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
            // Filters Card
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Colors.white, JoynColors.background],
                  ),
                  borderRadius: BorderRadius.circular(16),
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
                        const Icon(Icons.filter_alt_outlined, size: 18, color: JoynColors.primary),
                        const SizedBox(width: 6),
                        Text(
                          'Filters',
                          style: JoynTypography.bodyLarge.copyWith(
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                            color: JoynColors.primary,
                          ),
                        ),
                        const Spacer(),
                        if (_nameCtrl.text.isNotEmpty || _hsnCtrl.text.isNotEmpty || _selectedCategory != null)
                          TextButton(
                            onPressed: _clearAllFilters,
                            child: Text(
                              'Clear All',
                              style: JoynTypography.caption.copyWith(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: JoynColors.error,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Search by Name
                    _buildFieldLabel('Item Name'),
                    const SizedBox(height: 6),
                    TextField(
                      controller: _nameCtrl,
                      onChanged: (value) => setState(() => _applyFilters()),
                      decoration: _buildInputDecoration(
                        hint: 'Search by item name',
                        icon: Icons.search_rounded,
                        suffixIcon: _nameCtrl.text.isNotEmpty
                            ? IconButton(
                          icon: const Icon(Icons.clear_rounded, size: 18, color: JoynColors.secondaryText),
                          onPressed: () {
                            setState(() {
                              _nameCtrl.clear();
                              _applyFilters();
                            });
                          },
                        )
                            : null,
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Category Dropdown
                    _buildFieldLabel('Category'),
                    const SizedBox(height: 6),
                    DropdownButtonFormField<String>(
                      value: _selectedCategory,
                      isExpanded: true,
                      icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 20, color: JoynColors.secondaryText),
                      dropdownColor: Colors.white,
                      style: JoynTypography.bodyLarge.copyWith(fontSize: 14, color: JoynColors.primary),
                      decoration: _buildInputDecoration(
                        hint: 'Select category',
                        icon: Icons.category_outlined,
                      ),
                      items: [
                        const DropdownMenuItem<String>(
                          value: null,
                          child: Text('All Categories'),
                        ),
                        ..._availableCategories.map((category) => DropdownMenuItem<String>(
                          value: category,
                          child: Text(category),
                        )),
                      ],
                      onChanged: (value) {
                        setState(() {
                          _selectedCategory = value;
                          _applyFilters();
                        });
                      },
                    ),
                    const SizedBox(height: 14),

                    // HSN Search
                    _buildFieldLabel('HSN / SAC Code'),
                    const SizedBox(height: 6),
                    TextField(
                      controller: _hsnCtrl,
                      onChanged: (value) => setState(() => _applyFilters()),
                      decoration: _buildInputDecoration(
                        hint: 'Search by HSN code',
                        icon: Icons.qr_code_rounded,
                        suffixIcon: _hsnCtrl.text.isNotEmpty
                            ? IconButton(
                          icon: const Icon(Icons.clear_rounded, size: 18, color: JoynColors.secondaryText),
                          onPressed: () {
                            setState(() {
                              _hsnCtrl.clear();
                              _applyFilters();
                            });
                          },
                        )
                            : null,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Results Count
            if (!_isLoading)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${_filteredItems.length} items found',
                      style: JoynTypography.caption.copyWith(
                        fontSize: 12,
                        color: JoynColors.secondaryText,
                      ),
                    ),
                    Text(
                      'Stock Value: ₹${_calculateStockValue().toStringAsFixed(2)}',
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
                      'No Items Found',
                      style: JoynTypography.titleMedium.copyWith(fontSize: 18, fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Try adjusting your search filters',
                      style: JoynTypography.subtitle.copyWith(fontSize: 13),
                    ),
                  ],
                ),
              )
                  : RefreshIndicator(
                onRefresh: _loadItems,
                color: JoynColors.primary,
                child: ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
                  itemCount: _filteredItems.length,
                  itemBuilder: (context, index) {
                    final item = _filteredItems[index];
                    return _buildItemCard(item);
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  double _calculateStockValue() {
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
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.white, JoynColors.background],
        ),
        borderRadius: BorderRadius.circular(16),
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
          onTap: () => _showItemDetail(item),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    // Item Image or Icon
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
                            return _buildItemIconFallback(item, 20);
                          },
                        ),
                      )
                          : _buildItemIconFallback(item, 20),
                    ),
                    const SizedBox(width: 12),
                    // Name and Category
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.name,
                            style: JoynTypography.bodyLarge.copyWith(
                              fontSize: 14.5,
                              fontWeight: FontWeight.w700,
                              color: JoynColors.primary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 3),
                          if (item.category.isNotEmpty)
                            Text(
                              item.category,
                              style: JoynTypography.caption.copyWith(
                                fontSize: 11,
                                color: JoynColors.secondaryText,
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
                    const SizedBox(width: 4),
                    const Icon(Icons.chevron_right_rounded, size: 20, color: JoynColors.secondaryText),
                  ],
                ),
                const SizedBox(height: 10),
                // Info Row
                Row(
                  children: [
                    _buildInfoChip(Icons.straighten_rounded, item.unit),
                    const SizedBox(width: 8),
                    if (item.hsnSac.isNotEmpty)
                      _buildInfoChip(Icons.qr_code_rounded, 'HSN: ${item.hsnSac}'),
                    const Spacer(),
                    Text(
                      '₹${item.sellingPrice.toStringAsFixed(2)}',
                      style: JoynTypography.bodyLarge.copyWith(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: JoynColors.primary,
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

  Widget _buildItemIconFallback(InventoryItemModel item, double fontSize) {
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
          fontSize: fontSize,
          fontWeight: FontWeight.w800,
          color: JoynColors.primary,
        ),
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: JoynColors.chipBackground,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: JoynColors.secondaryText),
          const SizedBox(width: 4),
          Text(
            label,
            style: JoynTypography.caption.copyWith(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: JoynColors.secondaryText,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFieldLabel(String text) {
    return Text(
      text,
      style: JoynTypography.bodyMedium.copyWith(
        fontWeight: FontWeight.w600,
        fontSize: 12.5,
        color: JoynColors.secondaryText,
      ),
    );
  }

  InputDecoration _buildInputDecoration({
    required String hint,
    required IconData icon,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      hintText: hint,
      hintStyle: JoynTypography.bodyMedium.copyWith(
        color: JoynColors.secondaryText.withValues(alpha: 0.5),
        fontSize: 13.5,
      ),
      filled: true,
      fillColor: Colors.white,
      prefixIcon: Icon(icon, size: 18, color: JoynColors.secondaryText),
      suffixIcon: suffixIcon,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: JoynColors.border, width: 1.2),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: JoynColors.border, width: 1.2),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: JoynColors.primary, width: 1.4),
      ),
      contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
      isDense: true,
    );
  }
}