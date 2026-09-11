// lib/features/dashboard/presentation/dashboard_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:joyn/features/Inventory/presentation/add_new_party_screen.dart';
import 'package:joyn/features/Inventory/presentation/payment_in_screen.dart';
import 'package:joyn/features/orders/presentation/sale_orders_list_screen.dart';
import 'package:joyn/features/orders/presentation/purchase_orders_list_screen.dart';
import 'package:joyn/features/orders/models/sales_models.dart';
import 'package:joyn/features/orders/data/sales_repository.dart';
import '../../../core/theme/joyn_colors.dart';
import '../../../core/theme/joyn_typography.dart';
import '../../auth/providers/auth_provider.dart';
import 'business_setup_bottom_sheet.dart';
import 'package:joyn/core/widgets/joyn_logout_dialog.dart';
import 'package:joyn/features/barcode/presentation/newlable_screen.dart';
import 'package:joyn/features/barcode/presentation/label_editor_screen.dart';
import '../../Inventory/presentation/manage_inventory_screen.dart';
import 'package:joyn/features/reports/Presentation/overview_screen.dart';
import 'package:joyn/features/reports/Presentation/reports_screen.dart';

class _DashColors {
  static const pageBackground = Color.fromRGBO(221, 221, 221, 1);
  static const cardBackground = Color.fromRGBO(255, 255, 255, 1.0);
  static const cardBorder = Color.fromRGBO(235, 236, 240, 1.0);
  static const iconChipBackgroundStart = Color.fromRGBO(250, 250, 252, 1.0);
  static const iconChipBackgroundEnd = Color.fromRGBO(240, 240, 244, 1.0);
  static const addButtonStart = Color.fromRGBO(200, 40, 51, 1.0);
  static const addButtonEnd = Color.fromRGBO(168, 24, 34, 1.0);
  static const addButtonText = Color.fromRGBO(255, 255, 255, 1.0);
  static const arrowButtonStart = Color.fromRGBO(32, 32, 38, 1.0);
  static const arrowButtonEnd = Color.fromRGBO(14, 14, 18, 1.0);
}

class DashboardScreen extends ConsumerStatefulWidget {
  final bool autoShowSetup;

  const DashboardScreen({
    super.key,
    this.autoShowSetup = false,
  });

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  int _bottomNavIndex = 0;
  bool _hasTriggeredPopup = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_hasTriggeredPopup && widget.autoShowSetup && mounted) {
        _hasTriggeredPopup = true;
        _showBusinessSetupPopup();
      }
    });
  }

  void _showBusinessSetupPopup() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const BusinessSetupBottomSheet(),
    );
  }

  void _showComingSoonSnackBar(String featureName) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$featureName feature coming soon'),
        duration: const Duration(seconds: 2),
        backgroundColor: JoynColors.primary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  void _showSettingsMenu() {
    showModalBottomSheet(
      context: context,
      backgroundColor: JoynColors.background,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 36,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: JoynColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.storefront_outlined,
                    color: JoynColors.primary),
                title: Text('Business Profile',
                    style:
                    JoynTypography.bodyLarge.copyWith(fontSize: 15)),
                onTap: () {
                  Navigator.pop(context);
                  context.push('/business-profile');
                },
              ),
              ListTile(
                leading:
                const Icon(Icons.logout_rounded, color: JoynColors.error),
                title: Text('Log Out',
                    style: JoynTypography.bodyLarge.copyWith(
                        fontSize: 15, color: JoynColors.error)),
                onTap: () async {
                  Navigator.pop(context);
                  await _handleLogout();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _handleLogout() async {
    final confirmed = await showJoynLogoutConfirmation(context);
    if (confirmed && mounted) {
      await ref.read(authProvider.notifier).logout();
      if (mounted) {
        context.go('/onboarding');
      }
    }
  }

  // ============================================================
  // PAYMENT IN / OUT FLOW
  // ============================================================
  Future<void> _openPaymentFlow({required bool isPaymentOut}) async {
    final repo = SalesRepository();

    List<PartyModel> parties = [];
    try {
      parties = await repo.getParties();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to load parties: $e'),
          backgroundColor: JoynColors.error,
          behavior: SnackBarBehavior.floating,
          shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      return;
    }

    if (!mounted) return;
    if (parties.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('No parties found. Add a party first.'),
          backgroundColor: JoynColors.primary,
          behavior: SnackBarBehavior.floating,
          shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      return;
    }

    final selected = await showModalBottomSheet<PartyModel>(
      context: context,
      backgroundColor: JoynColors.background,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => _PartyPickerSheet(
        parties: parties,
        title: isPaymentOut
            ? 'Select Party — Payment Out'
            : 'Select Party — Payment In',
      ),
    );

    if (selected == null || !mounted) return;

    final saved = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => PaymentInScreen(
          party: selected,
          isPaymentOut: isPaymentOut,
        ),
      ),
    );

    if (saved == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              isPaymentOut ? 'Payment Out recorded' : 'Payment In recorded'),
          backgroundColor: JoynColors.primary,
          behavior: SnackBarBehavior.floating,
          shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);

    final String appBarTitle = (authState.businessName.isNotEmpty)
        ? authState.businessName
        : (authState.selectedCompany != null &&
        authState.selectedCompany!.isNotEmpty)
        ? authState.selectedCompany!
        : 'Welcome User';

    Widget body;
    switch (_bottomNavIndex) {
      case 0:
        body = _buildDashboardView();
        break;
      case 1:
        body = const SaleOrdersListScreen();
        break;
      case 2:
        body = const ReportsScreen();
        break;
      case 3:
        body = _buildMoreView();
        break;
      default:
        body = _buildDashboardView();
    }

    return Scaffold(
      backgroundColor: _DashColors.pageBackground,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: _DashColors.pageBackground,
        elevation: 0,
        scrolledUnderElevation: 0,
        titleSpacing: 20,
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            InkWell(
              onTap: () {
                context.push('/business-profile');
              },
              borderRadius: BorderRadius.circular(12),
              child: Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: _DashColors.cardBackground,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: JoynColors.border, width: 1),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.storefront_outlined,
                  color: JoynColors.primary,
                  size: 20,
                ),
              ),
            ),
            InkWell(
              onTap: () {
                context.push('/company-selection');
              },
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Flexible(
                      child: Text(
                        appBarTitle,
                        style: JoynTypography.bodyLarge.copyWith(
                          fontWeight: FontWeight.w700,
                          fontSize: 17,
                          letterSpacing: -0.2,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(
                      Icons.keyboard_arrow_down_rounded,
                      size: 20,
                      color: JoynColors.primary,
                    ),
                  ],
                ),
              ),
            ),
            InkWell(
              onTap: _showSettingsMenu,
              borderRadius: BorderRadius.circular(12),
              child: Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: _DashColors.cardBackground,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: JoynColors.border, width: 1),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.settings_outlined,
                  color: JoynColors.primary,
                  size: 20,
                ),
              ),
            ),
          ],
        ),
      ),
      body: body,
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: _DashColors.pageBackground,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 16,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: SafeArea(
          top: false,
          child: Container(
            margin: const EdgeInsets.fromLTRB(16, 8, 16, 10),
            padding: const EdgeInsets.symmetric(vertical: 4),
            decoration: BoxDecoration(
              color: _DashColors.cardBackground,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: _DashColors.cardBorder, width: 1),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 14,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: BottomNavigationBar(
              currentIndex: _bottomNavIndex,
              onTap: (index) {
                setState(() {
                  _bottomNavIndex = index;
                });
              },
              type: BottomNavigationBarType.fixed,
              backgroundColor: Colors.transparent,
              elevation: 0,
              selectedItemColor: JoynColors.primary,
              unselectedItemColor: JoynColors.secondaryText,
              selectedLabelStyle: JoynTypography.caption.copyWith(
                fontWeight: FontWeight.w700,
                fontSize: 11.5,
              ),
              unselectedLabelStyle: JoynTypography.caption.copyWith(
                fontWeight: FontWeight.w500,
                fontSize: 11.5,
              ),
              items: const [
                BottomNavigationBarItem(
                  icon: Icon(Icons.home_rounded),
                  label: 'Home',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.shopping_cart_outlined),
                  label: 'Sales',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.file_copy),
                  label: 'Reports',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.more_horiz_rounded),
                  label: 'More',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ============ DASHBOARD VIEW ============

  Widget _buildDashboardView() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      children: [
        _buildDashboardSectionCard(
          mainIcon: Icons.shopping_cart_outlined,
          title: 'Sale',
          subtitle: 'Manage all your sales',
          primaryActionLabel: 'Add',
          onPrimaryTap: () => context.push('/add-sale-order'),
          onArrowTap: () => context.push('/sale-orders-list'),
        ),
        const SizedBox(height: 12),

        _buildDashboardSectionCard(
          mainIcon: Icons.shopping_bag_outlined,
          title: 'Purchase',
          subtitle: 'Manage all your purchases',
          primaryActionLabel: 'Add',
          onPrimaryTap: () => context.push('/add-purchase-order'),
          onArrowTap: () => context.push('/purchase-orders-list'),
        ),
        const SizedBox(height: 12),

        _buildDashboardSectionCard(
          mainIcon: Icons.inventory_2_outlined,
          title: 'Inventory',
          subtitle: 'Manage your inventory',
          primaryActionLabel: 'Add',
          onPrimaryTap: () => context.push('/add-inventory'),
          onArrowTap: () => context.push('/manage-inventory'),
        ),
        const SizedBox(height: 12),

        _buildDashboardSectionCard(
          mainIcon: Icons.people_outline_rounded,
          title: 'Party',
          subtitle: 'Manage all your parties',
          primaryActionLabel: 'Add',
          onPrimaryTap: () => context.push('/add-party'),
          onArrowTap: () => context.push('/party-list'),
        ),
        const SizedBox(height: 12),

        _buildDashboardSectionCard(
          mainIcon: Icons.category_outlined,
          title: 'Items',
          subtitle: 'Manage your item catalog',
          primaryActionLabel: 'Add',
          onPrimaryTap: () => context.push('/add-new-item'),
          onArrowTap: () => context.push('/items-list'),
        ),
        const SizedBox(height: 12),

        // ============ BARCODE CARD ============
        _buildBarcodeCard(),

        const SizedBox(height: 16),

        // ============ PAYMENT IN / OUT BUTTONS ============
        Row(
          children: [
            Expanded(
              child: _buildPaymentButton(
                icon: Icons.arrow_downward_rounded,
                label: 'Payment IN',
                color: const Color(0xFF16A34A),
                onTap: () => _openPaymentFlow(isPaymentOut: false),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildPaymentButton(
                icon: Icons.arrow_upward_rounded,
                label: 'Payment OUT',
                color: const Color(0xFFC0202B),
                onTap: () => _openPaymentFlow(isPaymentOut: true),
              ),
            ),
          ],
        ),

        const SizedBox(height: 16),
      ],
    );
  }

  // ============ BARCODE CARD ============
  Widget _buildBarcodeCard() {
    return GestureDetector(
      onTap: () async {
        final result = await Navigator.push<LabelSizeResult>(
          context,
          MaterialPageRoute(builder: (_) => const NewLabelSizeScreen()),
        );
        if (result != null && context.mounted) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => LabelEditorScreen(labelSize: result),
            ),
          );
        }
      },
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.blue,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: _DashColors.cardBorder, width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 2,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 44,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '                              +',
                    style: JoynTypography.bodyLarge.copyWith(
                      fontWeight: FontWeight.w700,
                      fontSize: 17.5,
                      letterSpacing: -0.1,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Generate new barcodes/QR code',
                    style: JoynTypography.subtitle.copyWith(fontSize: 11.5),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============ PAYMENT BUTTON ============
  Widget _buildPaymentButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            color,
            Color.lerp(color, Colors.black, 0.18) ?? color,
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.35),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 22, color: Colors.white),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: JoynTypography.bodyMedium.copyWith(
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    fontSize: 15,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ============ DASHBOARD SECTION CARD ============
  Widget _buildDashboardSectionCard({
    required IconData mainIcon,
    required String title,
    required String subtitle,
    required String primaryActionLabel,
    VoidCallback? onPrimaryTap,
    VoidCallback? onArrowTap,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _DashColors.cardBorder, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 2,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 44,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  _DashColors.iconChipBackgroundStart,
                  _DashColors.iconChipBackgroundEnd,
                ],
              ),
              borderRadius: BorderRadius.circular(13),
              border: Border.all(color: _DashColors.cardBorder, width: 1),
            ),
            child: Icon(
              mainIcon,
              color: JoynColors.primary,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: JoynTypography.bodyLarge.copyWith(
                    fontWeight: FontWeight.w700,
                    fontSize: 14.5,
                    letterSpacing: -0.1,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: JoynTypography.subtitle.copyWith(fontSize: 11.5),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Tooltip(
            message: primaryActionLabel,
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: onPrimaryTap,
                borderRadius: BorderRadius.circular(14),
                child: Container(
                  width: 52,
                  height: 44,
                  padding: const EdgeInsets.symmetric(vertical: 5),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        _DashColors.addButtonStart,
                        _DashColors.addButtonEnd
                      ],
                    ),
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: _DashColors.addButtonStart
                            .withValues(alpha: 0.35),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.add_rounded,
                        size: 16,
                        color: _DashColors.addButtonText,
                      ),
                      const SizedBox(height: 1),
                      Text(
                        primaryActionLabel.replaceFirst('Add ', ''),
                        style: JoynTypography.caption.copyWith(
                          color: _DashColors.addButtonText,
                          fontWeight: FontWeight.w700,
                          fontSize: 8.5,
                          height: 1,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onArrowTap ?? onPrimaryTap,
              borderRadius: BorderRadius.circular(17),
              child: Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      _DashColors.arrowButtonStart,
                      _DashColors.arrowButtonEnd
                    ],
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.18),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.arrow_forward_rounded,
                  color: Colors.white,
                  size: 16,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============ MORE VIEW ============
  Widget _buildMoreView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.more_horiz_rounded,
            size: 72,
            color: JoynColors.primary,
          ),
          const SizedBox(height: 16),
          Text(
            'More Options',
            style: JoynTypography.titleMedium.copyWith(
              fontSize: 20,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              'Settings, Inventory, Parties, Items, and more will appear here.',
              style: JoynTypography.subtitle.copyWith(fontSize: 14),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => context.push('/manage-inventory'),
            icon: const Icon(Icons.inventory_2_outlined),
            label: const Text('Manage Inventory'),
            style: ElevatedButton.styleFrom(
              backgroundColor: JoynColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            onPressed: () => context.push('/party-list'),
            icon: const Icon(Icons.people_outline_rounded),
            label: const Text('Manage Parties'),
            style: ElevatedButton.styleFrom(
              backgroundColor: JoynColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            onPressed: () => context.push('/items-list'),
            icon: const Icon(Icons.category_outlined),
            label: const Text('Manage Items'),
            style: ElevatedButton.styleFrom(
              backgroundColor: JoynColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// PARTY PICKER SHEET
// ============================================================
class _PartyPickerSheet extends StatefulWidget {
  const _PartyPickerSheet({required this.parties, required this.title});

  final List<PartyModel> parties;
  final String title;

  @override
  State<_PartyPickerSheet> createState() => _PartyPickerSheetState();
}

class _PartyPickerSheetState extends State<_PartyPickerSheet> {
  final _searchController = TextEditingController();
  late List<PartyModel> _filtered;

  @override
  void initState() {
    super.initState();
    _filtered = widget.parties;
    _searchController.addListener(_onSearch);
  }

  void _onSearch() {
    final q = _searchController.text.trim().toLowerCase();
    setState(() {
      _filtered = q.isEmpty
          ? widget.parties
          : widget.parties.where((p) {
        return p.name.toLowerCase().contains(q) ||
            p.contactNumber.toLowerCase().contains(q);
      }).toList();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final maxH = MediaQuery.of(context).size.height * 0.75;
    return SafeArea(
      child: Container(
        constraints: BoxConstraints(maxHeight: maxH),
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 36,
              height: 4,
              margin: const EdgeInsets.only(bottom: 14),
              decoration: BoxDecoration(
                color: JoynColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Text(
              widget.title,
              style: JoynTypography.titleMedium.copyWith(
                fontSize: 16,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search party...',
                prefixIcon: const Icon(Icons.search_rounded),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 4),
              ),
            ),
            const SizedBox(height: 12),
            Flexible(
              child: _filtered.isEmpty
                  ? Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(
                    'No parties found',
                    style:
                    JoynTypography.subtitle.copyWith(fontSize: 14),
                  ),
                ),
              )
                  : ListView.separated(
                shrinkWrap: true,
                itemCount: _filtered.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (context, i) {
                  final p = _filtered[i];
                  final phone = p.contactNumber;
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor:
                      JoynColors.primary.withValues(alpha: 0.1),
                      child: const Icon(
                        Icons.person_outline_rounded,
                        color: JoynColors.primary,
                      ),
                    ),
                    title: Text(
                      p.name,
                      style: JoynTypography.bodyLarge.copyWith(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    subtitle: phone.isNotEmpty ? Text(phone) : null,
                    onTap: () => Navigator.of(context).pop(p),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}