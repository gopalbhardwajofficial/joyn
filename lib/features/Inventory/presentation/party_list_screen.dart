import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/joyn_colors.dart';
import '../../../core/theme/joyn_typography.dart';
import '../../orders/models/sales_models.dart';
import '../../orders/data/sales_repository.dart';
import '../presentation/add_new_party_screen.dart';
import '../presentation/party_detail_screen.dart';
import 'package:joyn/features/Inventory/presentation/sale_form_screen.dart';
import 'package:joyn/features/Inventory/presentation/payment_in_screen.dart';

enum _SortOption { nameAsc, nameDesc, categoryAsc }

class PartyListScreen extends StatefulWidget {
  const PartyListScreen({super.key});

  @override
  State<PartyListScreen> createState() => _PartyListScreenState();
}

class _PartyListScreenState extends State<PartyListScreen> {
  final SalesRepository _salesRepository = SalesRepository();
  List<PartyModel> _parties = [];
  bool _isLoading = true;
  String _searchQuery = '';

  _SortOption _sortOption = _SortOption.nameAsc;
  String? _filterCategory;

  @override
  void initState() {
    super.initState();
    _loadParties();
  }

  Future<void> _loadParties() async {
    try {
      final parties = await _salesRepository.getParties();
      if (!mounted) return;
      setState(() {
        _parties = parties;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading parties: $e');
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  List<String> get _availableCategories =>
      _parties.map((p) => p.category).where((c) => c.isNotEmpty).toSet().toList()..sort();

  List<PartyModel> get _filteredParties {
    var list = _parties.where((party) {
      final matchesQuery = _searchQuery.isEmpty ||
          party.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          party.category.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          party.contactNumber.contains(_searchQuery);
      final matchesFilter = _filterCategory == null || party.category == _filterCategory;
      return matchesQuery && matchesFilter;
    }).toList();

    switch (_sortOption) {
      case _SortOption.nameAsc:
        list.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
        break;
      case _SortOption.nameDesc:
        list.sort((a, b) => b.name.toLowerCase().compareTo(a.name.toLowerCase()));
        break;
      case _SortOption.categoryAsc:
        list.sort((a, b) => a.category.toLowerCase().compareTo(b.category.toLowerCase()));
        break;
    }
    return list;
  }

  Future<void> _deleteParty(PartyModel party) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Text('Delete Party?', style: JoynTypography.titleMedium.copyWith(fontSize: 17, fontWeight: FontWeight.w700)),
        content: Text(
          'Remove "${party.name}" from your parties list?',
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
      await _salesRepository.deleteParty(party.id);
      _loadParties();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Party deleted successfully!'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: JoynColors.error,
            margin: const EdgeInsets.all(16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
        );
      }
    }
  }

  Future<void> _editParty(PartyModel party) async {
    HapticFeedback.lightImpact();
    final updatedData = await Navigator.of(context).push<Map<String, dynamic>>(
      MaterialPageRoute(builder: (_) => AddNewPartyScreen(existingParty: party)),
    );
    if (updatedData != null) _loadParties();
  }

  Future<void> _openPartyDetail(PartyModel party) async {
    HapticFeedback.lightImpact();
    await Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false,
        barrierColor: Colors.black.withValues(alpha: 0.15),
        transitionDuration: const Duration(milliseconds: 220),
        pageBuilder: (context, animation, secondary) => PartyDetailScreen(party: party),
        transitionsBuilder: (context, animation, secondary, child) {
          final offset = Tween<Offset>(begin: const Offset(0, 0.06), end: Offset.zero)
              .chain(CurveTween(curve: Curves.easeOutCubic))
              .animate(animation);
          return FadeTransition(
            opacity: animation,
            child: SlideTransition(position: offset, child: child),
          );
        },
      ),
    );
    _loadParties();
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
            Text('Sort By', style: JoynTypography.titleMedium.copyWith(fontSize: 17, fontWeight: FontWeight.w800)),
            const SizedBox(height: 8),
            _sortTile('Name (A → Z)', _SortOption.nameAsc),
            _sortTile('Name (Z → A)', _SortOption.nameDesc),
            _sortTile('Category', _SortOption.categoryAsc),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _sortTile(String label, _SortOption option) {
    final selected = _sortOption == option;
    return ListTile(
      title: Text(label, style: JoynTypography.bodyLarge.copyWith(fontSize: 14.5, fontWeight: selected ? FontWeight.w700 : FontWeight.w500)),
      trailing: selected ? const Icon(Icons.check_rounded, color: JoynColors.primary) : null,
      onTap: () {
        setState(() => _sortOption = option);
        Navigator.pop(context);
      },
    );
  }

  void _showFilterSheet() {
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
            Text('Filter By Category', style: JoynTypography.titleMedium.copyWith(fontSize: 17, fontWeight: FontWeight.w800)),
            const SizedBox(height: 8),
            ListTile(
              title: Text('All', style: JoynTypography.bodyLarge.copyWith(fontSize: 14.5, fontWeight: _filterCategory == null ? FontWeight.w700 : FontWeight.w500)),
              trailing: _filterCategory == null ? const Icon(Icons.check_rounded, color: JoynColors.primary) : null,
              onTap: () {
                setState(() => _filterCategory = null);
                Navigator.pop(context);
              },
            ),
            ..._availableCategories.map((category) => ListTile(
              title: Text(category, style: JoynTypography.bodyLarge.copyWith(fontSize: 14.5, fontWeight: _filterCategory == category ? FontWeight.w700 : FontWeight.w500)),
              trailing: _filterCategory == category ? const Icon(Icons.check_rounded, color: JoynColors.primary) : null,
              onTap: () {
                setState(() => _filterCategory = category);
                Navigator.pop(context);
              },
            )),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  // ---- Bottom bar actions ----------------------------------------------

  Future<void> _pickPartyThen(void Function(PartyModel party) onPicked) async {
    if (_parties.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No parties available. Add a party first.')),
      );
      return;
    }

    final party = await showModalBottomSheet<PartyModel>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) => SafeArea(
        child: Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
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
              Text('Select Party', style: JoynTypography.titleMedium.copyWith(fontSize: 17, fontWeight: FontWeight.w800)),
              const SizedBox(height: 8),
              ConstrainedBox(
                constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.5),
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: _parties.length,
                  itemBuilder: (context, index) {
                    final p = _parties[index];
                    return ListTile(
                      leading: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              JoynColors.primary.withValues(alpha: 0.08),
                              JoynColors.primary.withValues(alpha: 0.16),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          p.name.isNotEmpty ? p.name[0].toUpperCase() : '?',
                          style: JoynTypography.titleMedium.copyWith(fontSize: 16, fontWeight: FontWeight.w800, color: JoynColors.primary),
                        ),
                      ),
                      title: Text(p.name, style: JoynTypography.bodyLarge.copyWith(fontSize: 14.5, fontWeight: FontWeight.w600)),
                      subtitle: p.category.isNotEmpty ? Text(p.category) : null,
                      trailing: const Icon(Icons.chevron_right_rounded, size: 20, color: JoynColors.secondaryText),
                      onTap: () => Navigator.pop(context, p),
                    );
                  },
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );

    if (party != null) onPicked(party);
  }

  Future<void> _openTakePayment(PartyModel party) async {
    HapticFeedback.lightImpact();
    final saved = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => PaymentInScreen(party: party)),
    );
    if (saved == true) _loadParties();
  }

  Future<void> _openAddSale(PartyModel party) async {
    HapticFeedback.lightImpact();
    final saved = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => SaleFormScreen(party: party)),
    );
    if (saved == true) _loadParties();
  }

  void _openTakePaymentGeneric() {
    HapticFeedback.lightImpact();
    _pickPartyThen(_openTakePayment);
  }

  void _openAddSaleGeneric() {
    HapticFeedback.lightImpact();
    _pickPartyThen(_openAddSale);
  }

  Widget _buildBottomActionButton({
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [color, Color.lerp(color, Colors.black, 0.18) ?? color]),
            borderRadius: BorderRadius.circular(18),
            boxShadow: [BoxShadow(color: color.withValues(alpha: 0.28), blurRadius: 14, offset: const Offset(0, 6))],
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 15),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: Colors.white, size: 19),
                const SizedBox(width: 8),
                Text(label, style: JoynTypography.bodyMedium.copyWith(fontWeight: FontWeight.w700, color: Colors.white, fontSize: 14)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildIconButton(IconData icon, VoidCallback onTap, {bool badge = false}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: JoynColors.border, width: 1.2),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.035), blurRadius: 10, offset: const Offset(0, 3))],
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Icon(icon, size: 20, color: JoynColors.primary),
            if (badge)
              Positioned(
                top: 8,
                right: 8,
                child: Container(width: 7, height: 7, decoration: const BoxDecoration(color: JoynColors.error, shape: BoxShape.circle)),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildPartyCard(PartyModel party) {
    return InkWell(
      onTap: () => _openPartyDetail(party),
      borderRadius: BorderRadius.circular(18),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Colors.white, JoynColors.background]),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: JoynColors.border, width: 1.2),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.035), blurRadius: 10, offset: const Offset(0, 3))],
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [
                    JoynColors.primary.withValues(alpha: 0.08),
                    JoynColors.primary.withValues(alpha: 0.16),
                  ]),
                  borderRadius: BorderRadius.circular(14),
                ),
                alignment: Alignment.center,
                child: Text(
                  party.name.isNotEmpty ? party.name[0].toUpperCase() : '?',
                  style: JoynTypography.titleMedium.copyWith(fontSize: 20, fontWeight: FontWeight.w800, color: JoynColors.primary),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(party.name, style: JoynTypography.bodyLarge.copyWith(fontSize: 15, fontWeight: FontWeight.w700, color: JoynColors.primary), maxLines: 1, overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 4),
                    if (party.category.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(color: JoynColors.chipBackground, borderRadius: BorderRadius.circular(20)),
                        child: Text(party.category, style: JoynTypography.caption.copyWith(fontSize: 10.5, fontWeight: FontWeight.w600, color: JoynColors.secondaryText)),
                      ),
                    const SizedBox(height: 4),
                    if (party.contactNumber.isNotEmpty)
                      Row(
                        children: [
                          const Icon(Icons.phone_outlined, size: 12, color: JoynColors.secondaryText),
                          const SizedBox(width: 4),
                          Text(party.contactNumber, style: JoynTypography.caption.copyWith(fontSize: 11.5, color: JoynColors.secondaryText)),
                        ],
                      ),
                  ],
                ),
              ),
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  InkWell(
                    onTap: () => _editParty(party),
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(color: JoynColors.primary.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(8)),
                      child: const Icon(Icons.edit_outlined, size: 18, color: JoynColors.primary),
                    ),
                  ),
                  const SizedBox(height: 8),
                  InkWell(
                    onTap: () => _deleteParty(party),
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(color: JoynColors.error.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(8)),
                      child: const Icon(Icons.delete_outline_rounded, size: 18, color: JoynColors.error),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
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
            decoration: BoxDecoration(color: JoynColors.chipBackground, shape: BoxShape.circle),
            child: const Icon(Icons.arrow_back_rounded, size: 18),
          ),
          onPressed: () => context.pop(),
        ),
        centerTitle: true,
        title: Text('Parties', style: JoynTypography.titleMedium.copyWith(fontSize: 18, fontWeight: FontWeight.w800, letterSpacing: -0.2)),
        actions: [
          IconButton(
            icon: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(color: JoynColors.chipBackground, shape: BoxShape.circle),
              child: const Icon(Icons.person_add_alt_1_rounded, size: 18, color: JoynColors.primary),
            ),
            tooltip: 'Add Party',
            onPressed: () async {
              HapticFeedback.lightImpact();
              await Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const AddNewPartyScreen()),
              );
              _loadParties();
            },
          ),
          const SizedBox(width: 6),
        ],
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
                        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.035), blurRadius: 10, offset: const Offset(0, 3))],
                      ),
                      child: TextField(
                        onChanged: (value) => setState(() => _searchQuery = value),
                        decoration: InputDecoration(
                          hintText: 'Search by name, category, phone...',
                          hintStyle: JoynTypography.bodyMedium.copyWith(color: JoynColors.secondaryText.withValues(alpha: 0.5), fontSize: 13.5),
                          prefixIcon: const Icon(Icons.search_rounded, size: 20, color: JoynColors.secondaryText),
                          suffixIcon: _searchQuery.isNotEmpty
                              ? IconButton(
                            icon: const Icon(Icons.clear_rounded, size: 18, color: JoynColors.secondaryText),
                            onPressed: () => setState(() => _searchQuery = ''),
                          )
                              : null,
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  _buildIconButton(Icons.swap_vert_rounded, _showSortSheet),
                  const SizedBox(width: 8),
                  _buildIconButton(Icons.filter_list_rounded, _showFilterSheet, badge: _filterCategory != null),
                ],
              ),
            ),

            if (_filterCategory != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Chip(
                    label: Text('Category: $_filterCategory'),
                    onDeleted: () => setState(() => _filterCategory = null),
                    backgroundColor: JoynColors.chipBackground,
                  ),
                ),
              ),

            // Parties List
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator(color: JoynColors.primary))
                  : _filteredParties.isEmpty
                  ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(color: JoynColors.iconBackground, borderRadius: BorderRadius.circular(24)),
                      child: const Icon(Icons.people_outline_rounded, size: 40, color: JoynColors.secondaryText),
                    ),
                    const SizedBox(height: 16),
                    Text('No Parties Yet', style: JoynTypography.titleMedium.copyWith(fontSize: 18, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 6),
                    Text('Tap "Add Party" to create your first party', style: JoynTypography.subtitle.copyWith(fontSize: 13)),
                  ],
                ),
              )
                  : RefreshIndicator(
                onRefresh: _loadParties,
                color: JoynColors.primary,
                child: ListView.builder(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                  itemCount: _filteredParties.length,
                  itemBuilder: (context, index) => _buildPartyCard(_filteredParties[index]),
                ),
              ),
            ),

            // Bottom action bar
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
              child: Row(
                children: [
                  Expanded(
                    child: _buildBottomActionButton(
                      label: 'Take Payment',
                      icon: Icons.call_received_rounded,
                      color: JoynColors.success,
                      onTap: _openTakePaymentGeneric,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildBottomActionButton(
                      label: 'Add Sale',
                      icon: Icons.point_of_sale_rounded,
                      color: JoynColors.primary,
                      onTap: _openAddSaleGeneric,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}