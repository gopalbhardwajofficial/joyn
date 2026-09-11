import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/joyn_colors.dart';
import '../../../core/theme/joyn_typography.dart';
import '../../orders/models/sales_models.dart';
import '../../orders/data/sales_repository.dart';
import 'add_new_party_screen.dart';
import 'sale_form_screen.dart';
import 'payment_in_screen.dart';

class PartyDetailScreen extends StatefulWidget {
  const PartyDetailScreen({super.key, required this.party});

  final PartyModel party;

  @override
  State<PartyDetailScreen> createState() => _PartyDetailScreenState();
}

class _PartyDetailScreenState extends State<PartyDetailScreen> {
  final SalesRepository _salesRepository = SalesRepository();

  late PartyModel _party = widget.party;
  List<SaleOrderModel> _sales = [];
  bool _isLoading = true;
  double _balance = 0;
  bool _isReceivable = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final sales = await _salesRepository.getSaleOrdersForParty(_party.id);
    final balanceInfo = await _salesRepository.getPartyBalance(_party.id);
    if (!mounted) return;
    setState(() {
      _sales = sales;
      _balance = balanceInfo['balance'] as double;
      _isReceivable = balanceInfo['isReceivable'] as bool;
      _isLoading = false;
    });
  }

  Future<void> _openEdit() async {
    HapticFeedback.lightImpact();
    final updatedData = await Navigator.of(context).push<Map<String, dynamic>>(
      MaterialPageRoute(builder: (_) => AddNewPartyScreen(existingParty: _party)),
    );
    if (updatedData == null || !mounted) return;

    setState(() {
      _party = _party.copyWith(
        name: (updatedData['name'] as String?)?.trim().isNotEmpty == true ? updatedData['name'] : null,
        category: updatedData['category'] as String?,
        contactNumber: updatedData['contactNumber'] as String?,
        email: updatedData['email'] as String?,
        address: updatedData['billingAddress'] as String?,
        city: updatedData['city'] as String?,
        partyType: updatedData['partyType'] as String?,
        priorityLevel: updatedData['priorityLevel'] as String?,
        photoPath: updatedData['photoPath'] as String?,
        avatarIndex: updatedData['avatarIndex'] as int?,
      );
    });
    _loadData();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Party updated'),
          backgroundColor: JoynColors.primary,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }

  Future<void> _openTakePayment() async {
    HapticFeedback.lightImpact();
    final saved = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => PaymentInScreen(party: _party)),
    );
    if (saved == true) _loadData();
  }

  Future<void> _openAddSale() async {
    HapticFeedback.lightImpact();
    final saved = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => SaleFormScreen(party: _party)),
    );
    if (saved == true) _loadData();
  }

  Future<void> _openSale(SaleOrderModel sale) async {
    HapticFeedback.lightImpact();
    final saved = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => SaleFormScreen(party: _party, existingSale: sale)),
    );
    if (saved == true) _loadData();
  }

  void _sendReminder() {
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Send Reminder — wire this to SMS/WhatsApp share')));
  }

  void _sendStatement() {
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Send Statement — wire this to PDF export')));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: JoynColors.background,
      appBar: AppBar(
        backgroundColor: JoynColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.pop(_party),
        ),
        centerTitle: true,
        title: Text('Party Details', style: JoynTypography.titleMedium.copyWith(fontSize: 18, fontWeight: FontWeight.w800)),
        actions: [
          IconButton(icon: const Icon(Icons.edit_outlined), tooltip: 'Edit', onPressed: _openEdit),
          IconButton(icon: const Icon(Icons.more_vert_rounded), onPressed: () {
            showModalBottomSheet(
              context: context,
              backgroundColor: Colors.white,
              shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
              builder: (context) => SafeArea(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(height: 10),
                    Container(width: 40, height: 4.5, decoration: BoxDecoration(color: JoynColors.border, borderRadius: BorderRadius.circular(3))),
                    const SizedBox(height: 12),
                    ListTile(
                      leading: const Icon(Icons.point_of_sale_rounded, color: JoynColors.primary),
                      title: const Text('Add Sale'),
                      onTap: () {
                        Navigator.pop(context);
                        _openAddSale();
                      },
                    ),
                    ListTile(
                      leading: const Icon(Icons.call_received_rounded, color: JoynColors.success),
                      title: const Text('Take Payment'),
                      onTap: () {
                        Navigator.pop(context);
                        _openTakePayment();
                      },
                    ),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator(color: JoynColors.primary))
            : RefreshIndicator(
          onRefresh: _loadData,
          color: JoynColors.primary,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            children: [
              _buildHeaderCard(),
              const SizedBox(height: 14),
              if (_sales.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 60),
                  child: Center(
                    child: Column(
                      children: [
                        const Icon(Icons.receipt_long_outlined, size: 44, color: JoynColors.secondaryText),
                        const SizedBox(height: 12),
                        Text('No sales yet', style: JoynTypography.bodyLarge.copyWith(fontWeight: FontWeight.w700)),
                        const SizedBox(height: 4),
                        Text('Tap "Add Sale" from menu to create one', style: JoynTypography.subtitle.copyWith(fontSize: 12.5)),
                      ],
                    ),
                  ),
                )
              else
                ..._sales.map((sale) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _buildSaleCard(sale),
                )),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderCard() {
    final balanceColor = _isReceivable ? JoynColors.success : JoynColors.error;
    final balanceLabel = _isReceivable ? 'Receivable' : 'Payable';
    final balanceIcon = _isReceivable ? Icons.call_received_rounded : Icons.call_made_rounded;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: JoynColors.border, width: 1.2),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.035), blurRadius: 10, offset: const Offset(0, 3))],
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(_party.name, style: JoynTypography.titleMedium.copyWith(fontSize: 17, fontWeight: FontWeight.w800)),
                    const SizedBox(height: 4),
                    if (_party.contactNumber.isNotEmpty)
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(_party.contactNumber, style: JoynTypography.bodyMedium.copyWith(fontSize: 13, color: JoynColors.secondaryText)),
                          const SizedBox(width: 6),
                          const Icon(Icons.call_rounded, size: 14, color: JoynColors.secondaryText),
                        ],
                      ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(balanceIcon, size: 15, color: balanceColor),
                      const SizedBox(width: 4),
                      Text(
                        '$balanceLabel: ₹${_balance.toStringAsFixed(2)}',
                        style: JoynTypography.bodyMedium.copyWith(fontSize: 13, fontWeight: FontWeight.w700, color: balanceColor),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _party.creditLimit != null ? 'Credit Limit: ₹${_party.creditLimit!.toStringAsFixed(0)}' : 'No Credit Limit Set',
                    style: JoynTypography.caption.copyWith(fontSize: 11.5, color: JoynColors.secondaryText),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(height: 1, color: JoynColors.border),
          const SizedBox(height: 4),
          Row(
            children: [
              Expanded(
                child: InkWell(
                  onTap: _sendReminder,
                  borderRadius: BorderRadius.circular(10),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.notifications_active_outlined, size: 16, color: JoynColors.primary),
                        const SizedBox(width: 6),
                        Text('Send Reminder', style: JoynTypography.bodyMedium.copyWith(fontSize: 13, fontWeight: FontWeight.w700, color: JoynColors.primary)),
                      ],
                    ),
                  ),
                ),
              ),
              Container(width: 1, height: 20, color: JoynColors.border),
              Expanded(
                child: InkWell(
                  onTap: _sendStatement,
                  borderRadius: BorderRadius.circular(10),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.description_outlined, size: 16, color: JoynColors.primary),
                        const SizedBox(width: 6),
                        Text('Send Statement', style: JoynTypography.bodyMedium.copyWith(fontSize: 13, fontWeight: FontWeight.w700, color: JoynColors.primary)),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSaleCard(SaleOrderModel sale) {
    return InkWell(
      onTap: () => _openSale(sale),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: JoynColors.border, width: 1.2),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.035), blurRadius: 10, offset: const Offset(0, 3))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Sale', style: JoynTypography.bodyLarge.copyWith(fontSize: 15, fontWeight: FontWeight.w700)),
                const Spacer(),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text('#${sale.invoiceNo}', style: JoynTypography.caption.copyWith(fontSize: 12, color: JoynColors.secondaryText)),
                    Text(sale.date, style: JoynTypography.caption.copyWith(fontSize: 11.5, color: JoynColors.secondaryText)),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Total', style: JoynTypography.caption.copyWith(fontSize: 11, color: JoynColors.secondaryText)),
                      const SizedBox(height: 2),
                      Text('₹${sale.totalAmount.toStringAsFixed(2)}', style: JoynTypography.bodyLarge.copyWith(fontSize: 14.5, fontWeight: FontWeight.w700)),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Balance', style: JoynTypography.caption.copyWith(fontSize: 11, color: JoynColors.secondaryText)),
                      const SizedBox(height: 2),
                      Text('₹${sale.balanceDue.toStringAsFixed(2)}', style: JoynTypography.bodyLarge.copyWith(fontSize: 14.5, fontWeight: FontWeight.w700)),
                    ],
                  ),
                ),
                IconButton(icon: const Icon(Icons.print_outlined, size: 20, color: JoynColors.secondaryText), onPressed: () {}),
                IconButton(icon: const Icon(Icons.ios_share_rounded, size: 19, color: JoynColors.secondaryText), onPressed: () {}),
                IconButton(icon: const Icon(Icons.more_vert_rounded, size: 20, color: JoynColors.secondaryText), onPressed: () => _openSale(sale)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}