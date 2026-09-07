import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:joyn/core/theme/joyn_typography.dart';
import 'package:joyn/core/theme/joyn_colors.dart';
import 'package:joyn/core/widgets/Premium_widget.dart';

class PartyItemRow {
  final String partyName;
  final double saleQty;
  final double purchaseQty;

  PartyItemRow({required this.partyName, required this.saleQty, required this.purchaseQty});
}

class PartyReportByItemScreen extends StatefulWidget {
  const PartyReportByItemScreen({super.key});

  @override
  State<PartyReportByItemScreen> createState() => _PartyReportByItemScreenState();
}

class _PartyReportByItemScreenState extends State<PartyReportByItemScreen> {
  String selectedPeriod = 'This Month';
  DateTime fromDate = DateTime(2026, 9, 1);
  DateTime toDate = DateTime(2026, 9, 30);
  bool _isLoading = false;

  String selectedCategory = 'All Categories';
  String itemSearch = '';
  String selectedItem = 'All Items';
  String sortBy = 'Party name';

  final List<PartyItemRow> rows = [
    PartyItemRow(partyName: 'Gopal', saleQty: 10.0, purchaseQty: 0.0),
    PartyItemRow(partyName: 'gill', saleQty: 1.0, purchaseQty: 0.0),
  ];

  double get totalSaleQty => rows.fold(0.0, (s, r) => s + r.saleQty);
  double get totalPurchaseQty => rows.fold(0.0, (s, r) => s + r.purchaseQty);

  List<PartyItemRow> get sortedRows {
    final list = [...rows];
    if (sortBy == 'Sale quantity') {
      list.sort((a, b) => b.saleQty.compareTo(a.saleQty));
    } else if (sortBy == 'Purchase quantity') {
      list.sort((a, b) => b.purchaseQty.compareTo(a.purchaseQty));
    } else {
      list.sort((a, b) => a.partyName.toLowerCase().compareTo(b.partyName.toLowerCase()));
    }
    return list;
  }

  Future<void> _pickDateRange() async {
    HapticFeedback.lightImpact();
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      initialDateRange: DateTimeRange(start: fromDate, end: toDate),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(
            primary: JoynColors.primary,
            surface: JoynColors.iconBackground,
          ),
          dialogBackgroundColor: JoynColors.background,
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() {
        fromDate = picked.start;
        toDate = picked.end;
        selectedPeriod = 'Custom';
        _isLoading = true;
      });
      await Future.delayed(const Duration(milliseconds: 500));
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _pickPeriod() async {
    HapticFeedback.selectionClick();
    final options = ['Today', 'This Week', 'This Month', 'This Year', 'Custom'];
    final result = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: JoynColors.background,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 12, 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Select Period',
                    style: JoynTypography.titleMedium.copyWith(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.close_rounded, color: JoynColors.secondaryText),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            Divider(height: 1, color: JoynColors.border),
            ...options.map((o) => ListTile(
              title: Text(
                o,
                style: JoynTypography.bodyLarge.copyWith(
                  fontWeight: o == selectedPeriod ? FontWeight.w700 : FontWeight.w500,
                  color: JoynColors.primary,
                ),
              ),
              trailing: o == selectedPeriod
                  ? Icon(Icons.check_rounded, color: JoynColors.primary)
                  : null,
              onTap: () => Navigator.pop(context, o),
            )),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
    if (result != null) setState(() => selectedPeriod = result);
  }

  Future<void> _pickOption({
    required String title,
    required List<String> options,
    required String current,
    required ValueChanged<String> onSelected,
  }) async {
    HapticFeedback.selectionClick();
    final result = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: JoynColors.background,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.only(top: 12, bottom: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: JoynColors.border,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(height: 14),
              Text(
                title,
                style: JoynTypography.titleMedium.copyWith(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              ...options.map(
                    (o) => ListTile(
                  title: Text(
                    o,
                    style: JoynTypography.bodyLarge.copyWith(
                      fontWeight: o == current ? FontWeight.w700 : FontWeight.w500,
                    ),
                  ),
                  trailing: o == current
                      ? const Icon(Icons.check_rounded, color: JoynColors.primary, size: 20)
                      : null,
                  onTap: () => Navigator.pop(context, o),
                ),
              ),
            ],
          ),
        ),
      ),
    );
    if (result != null) onSelected(result);
  }

  @override
  Widget build(BuildContext context) {
    final dateFmt = DateFormat('dd MMM');
    final qtyFmt = NumberFormat('#,##0.0');

    return Scaffold(
      backgroundColor: JoynColors.background,
      appBar: AppBar(
        backgroundColor: JoynColors.background,
        elevation: 0,
        scrolledUnderElevation: 0,
        titleSpacing: 20,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: JoynColors.primary),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Party Report By Item',
          style: JoynTypography.titleMedium.copyWith(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: JoynColors.primary,
          ),
          overflow: TextOverflow.ellipsis,
        ),
        actions: [
          _buildAppBarIconButton(
            label: 'Pdf',
            icon: Icons.picture_as_pdf_rounded,
            color: const Color(0xFFDC2626),
            onTap: () => _showSnackBar('Exporting PDF...'),
          ),
          const SizedBox(width: 6),
          _buildAppBarIconButton(
            label: 'xls',
            icon: Icons.grid_on_rounded,
            color: JoynColors.success,
            onTap: () => _showSnackBar('Exporting Excel...'),
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: Column(
        children: [
          _buildPeriodSelector(dateFmt),
          const SizedBox(height: 12),
          _buildDropdownRow(),
          const SizedBox(height: 12),
          _buildSearchField(),
          const SizedBox(height: 12),
          _buildTableHeader(),
          Expanded(
            child: _isLoading
                ? const Center(
              child: CircularProgressIndicator(color: JoynColors.primary),
            )
                : sortedRows.isEmpty
                ? _buildEmptyState()
                : _buildPartiesList(qtyFmt),
          ),
          _buildTotalBar(qtyFmt),
        ],
      ),
    );
  }

  // Enhanced Period Selector
  Widget _buildPeriodSelector(DateFormat dateFmt) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: JoynColors.iconBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: JoynColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: InkWell(
              onTap: _pickPeriod,
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: JoynColors.surfaceMuted,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(Icons.date_range_rounded, size: 18, color: JoynColors.primary),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        selectedPeriod,
                        style: JoynTypography.bodyMedium.copyWith(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: JoynColors.primary,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Icon(Icons.keyboard_arrow_down_rounded, size: 18, color: JoynColors.secondaryText),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          InkWell(
            onTap: _pickDateRange,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: JoynColors.surfaceMuted,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(Icons.calendar_today_rounded, size: 16, color: JoynColors.primary),
                  const SizedBox(width: 6),
                  Text(
                    '${dateFmt.format(fromDate)} - ${dateFmt.format(toDate)}',
                    style: JoynTypography.caption.copyWith(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: JoynColors.secondaryText,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Enhanced Dropdown Row
  Widget _buildDropdownRow() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: _DropdownField(
              label: 'Category',
              value: selectedCategory,
              icon: Icons.category_rounded,
              onTap: () => _pickOption(
                title: 'Select Category',
                options: const ['All Categories', 'Uncategorized'],
                current: selectedCategory,
                onSelected: (v) => setState(() => selectedCategory = v),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _DropdownField(
              label: 'Sort by',
              value: sortBy,
              icon: Icons.sort_rounded,
              onTap: () => _pickOption(
                title: 'Sort By',
                options: const ['Party name', 'Sale quantity', 'Purchase quantity'],
                current: sortBy,
                onSelected: (v) => setState(() => sortBy = v),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Enhanced Search Field
  Widget _buildSearchField() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      decoration: BoxDecoration(
        color: JoynColors.iconBackground,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: JoynColors.border),
      ),
      child: Row(
        children: [
          Icon(Icons.search_rounded, size: 18, color: JoynColors.secondaryText),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              decoration: InputDecoration(
                isDense: true,
                border: InputBorder.none,
                hintText: 'Enter Item Name',
                hintStyle: JoynTypography.caption.copyWith(
                  color: JoynColors.secondaryText,
                ),
              ),
              style: JoynTypography.bodyMedium.copyWith(fontWeight: FontWeight.w600),
              onChanged: (v) => setState(() {
                itemSearch = v;
                selectedItem = v.isEmpty ? 'All Items' : v;
              }),
            ),
          ),
          if (itemSearch.isNotEmpty)
            InkWell(
              onTap: () => setState(() {
                itemSearch = '';
                selectedItem = 'All Items';
              }),
              child: Icon(Icons.close_rounded, size: 16, color: JoynColors.secondaryText),
            ),
        ],
      ),
    );
  }

  // Enhanced Table Header
  Widget _buildTableHeader() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: JoynColors.surfaceMuted,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Text(
              'Party Name',
              style: JoynTypography.caption.copyWith(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: JoynColors.secondaryText,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              'Sale qty',
              textAlign: TextAlign.center,
              style: JoynTypography.caption.copyWith(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: JoynColors.secondaryText,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              'Purchase qty',
              textAlign: TextAlign.right,
              style: JoynTypography.caption.copyWith(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: JoynColors.secondaryText,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Enhanced Parties List
  Widget _buildPartiesList(NumberFormat qtyFmt) {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      itemCount: sortedRows.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final r = sortedRows[index];
        final initials = r.partyName.isNotEmpty ? r.partyName[0].toUpperCase() : '?';

        return TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: 1),
          duration: Duration(milliseconds: 300 + (index * 100)),
          builder: (context, value, child) {
            return Opacity(
              opacity: value,
              child: Transform.translate(
                offset: Offset(0, 20 * (1 - value)),
                child: child,
              ),
            );
          },
          child: Container(
            decoration: BoxDecoration(
              color: JoynColors.iconBackground,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: JoynColors.border),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  // Avatar
                  Container(
                    width: 40,
                    height: 40,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          JoynColors.primary.withValues(alpha: 0.1),
                          JoynColors.primary.withValues(alpha: 0.05),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      initials,
                      style: JoynTypography.bodyLarge.copyWith(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: JoynColors.primary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Party Name
                  Expanded(
                    flex: 3,
                    child: Text(
                      r.partyName,
                      style: JoynTypography.bodyLarge.copyWith(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: JoynColors.primary,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  // Sale Qty
                  Expanded(
                    flex: 2,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: JoynColors.success.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        qtyFmt.format(r.saleQty),
                        textAlign: TextAlign.center,
                        style: JoynTypography.bodyMedium.copyWith(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: JoynColors.success,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Purchase Qty
                  Expanded(
                    flex: 2,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: JoynColors.error.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        qtyFmt.format(r.purchaseQty),
                        textAlign: TextAlign.center,
                        style: JoynTypography.bodyMedium.copyWith(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: JoynColors.error,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // Enhanced Empty State
  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: JoynColors.surface,
                shape: BoxShape.circle,
                border: Border.all(color: JoynColors.border, width: 2),
              ),
              child: Icon(
                Icons.inventory_2_rounded,
                size: 48,
                color: JoynColors.secondaryText.withValues(alpha: 0.5),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'No data available',
              style: JoynTypography.titleMedium.copyWith(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: JoynColors.primary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Party wise item quantities will appear here once you record sales or purchases.',
              textAlign: TextAlign.center,
              style: JoynTypography.bodyMedium.copyWith(
                fontSize: 13.5,
                color: JoynColors.secondaryText,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Enhanced Total Bar
  Widget _buildTotalBar(NumberFormat qtyFmt) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [
            JoynColors.primary,
            JoynColors.primary.withValues(alpha: 0.85),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: JoynColors.primary.withValues(alpha: 0.2),
            blurRadius: 12,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Text(
              'Total',
              style: JoynTypography.bodyLarge.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              qtyFmt.format(totalSaleQty),
              textAlign: TextAlign.center,
              style: JoynTypography.bodyLarge.copyWith(
                color: const Color(0xFF4ADE80),
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              qtyFmt.format(totalPurchaseQty),
              textAlign: TextAlign.right,
              style: JoynTypography.bodyLarge.copyWith(
                color: const Color(0xFFF87171),
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // AppBar Icon Button
  Widget _buildAppBarIconButton({
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      borderRadius: BorderRadius.circular(10),
      child: Container(
        width: 38,
        height: 38,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              color.withValues(alpha: 0.9),
              color,
            ],
          ),
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.3),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: Colors.white),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 8,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: JoynTypography.bodyMedium.copyWith(color: Colors.white),
        ),
        backgroundColor: JoynColors.primary,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(milliseconds: 1500),
      ),
    );
  }
}

class _DropdownField extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final VoidCallback onTap;

  const _DropdownField({
    required this.label,
    required this.value,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: JoynColors.iconBackground,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: JoynColors.border),
        ),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: JoynColors.chipBackground,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, size: 16, color: JoynColors.primary),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
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
                    value,
                    overflow: TextOverflow.ellipsis,
                    style: JoynTypography.bodyMedium.copyWith(
                      fontWeight: FontWeight.w700,
                      color: JoynColors.primary,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.keyboard_arrow_down_rounded, size: 18, color: JoynColors.secondaryText),
          ],
        ),
      ),
    );
  }
}