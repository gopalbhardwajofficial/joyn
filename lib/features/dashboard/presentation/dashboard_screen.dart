import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:joyn/features/Inventory/presentation/add_new_party_screen.dart';
import 'package:joyn/features/orders/presentation/sale_orders_list_screen.dart';
import 'package:joyn/features/orders/presentation/purchase_orders_list_screen.dart';
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
  int _selectedTabIndex = 0;
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
                leading: const Icon(Icons.storefront_outlined, color: JoynColors.primary),
                title: Text('Business Profile', style: JoynTypography.bodyLarge.copyWith(fontSize: 15)),
                onTap: () {
                  Navigator.pop(context);
                  context.push('/business-profile');
                },
              ),
              ListTile(
                leading: const Icon(Icons.logout_rounded, color: JoynColors.error),
                title: Text('Log Out', style: JoynTypography.bodyLarge.copyWith(fontSize: 15, color: JoynColors.error)),
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

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);

    final String appBarTitle = (authState.businessName.isNotEmpty)
        ? authState.businessName
        : (authState.selectedCompany != null &&
        authState.selectedCompany!.isNotEmpty)
        ? authState.selectedCompany!
        : 'Welcome User';

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
      body: Column(
        children: [
          const SizedBox(height: 8),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () {
                      setState(() {
                        _selectedTabIndex = 0;
                      });
                    },
                    child: Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: Text(
                            'Dashboard',
                            style: JoynTypography.bodyLarge.copyWith(
                              fontWeight: FontWeight.w700,
                              color: _selectedTabIndex == 0
                                  ? JoynColors.primary
                                  : JoynColors.secondaryText,
                              fontSize: 15,
                              letterSpacing: -0.1,
                            ),
                          ),
                        ),
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 220),
                          curve: Curves.easeOut,
                          height: 3,
                          decoration: BoxDecoration(
                            color: _selectedTabIndex == 0
                                ? JoynColors.primary
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                Expanded(
                  child: InkWell(
                    onTap: () {
                      setState(() {
                        _selectedTabIndex = 1;
                      });
                    },
                    child: Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'Overview',
                                style: JoynTypography.bodyLarge.copyWith(
                                  fontWeight: FontWeight.w500,
                                  color: _selectedTabIndex == 1
                                      ? JoynColors.primary
                                      : JoynColors.secondaryText.withValues(alpha: 0.7),
                                  fontSize: 15,
                                  letterSpacing: -0.1,
                                ),
                              ),
                              const SizedBox(height: 2),
                            ],
                          ),
                        ),
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 220),
                          curve: Curves.easeOut,
                          height: 3,
                          decoration: BoxDecoration(
                            color: _selectedTabIndex == 1
                                ? JoynColors.primary
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          const Divider(color: JoynColors.border, height: 1, thickness: 1),

          Expanded(
            child: _selectedTabIndex == 0
                ? (_bottomNavIndex == 0
                ? _buildDashboardView()
                : _buildComingSoonFeatureView(_getBottomNavLabel(_bottomNavIndex)))
                : const OverviewScreen(),
          ),
        ],
      ),
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

                if (index == 2) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const ReportsScreen()),
                  );
                  return;
                }

                setState(() {
                  _bottomNavIndex = index;
                });
                if (index != 0) {
                  _showComingSoonSnackBar(_getBottomNavLabel(index));
                }
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

  String _getBottomNavLabel(int index) {
    switch (index) {
      case 1:
        return 'Sales';
      case 2:
        return 'Inventory';
      case 3:
        return 'More';
      default:
        return 'Home';
    }
  }


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
          onArrowTap: () {
            _showComingSoonSnackBar('Inventory');
          },
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

        _buildDashboardSectionCard(
          mainIcon: Icons.qr_code_scanner_rounded,
          title: 'Barcode / QR Code',
          subtitle: 'Generate barcode or QR code',
          primaryActionLabel: 'Barcode',
          onPrimaryTap: () async {
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
          onArrowTap: () async {
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
        ),

        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildComingSoonFeatureView(String featureName) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  JoynColors.iconBackground,
                  JoynColors.iconBackground.withValues(alpha: 0.6),
                ],
              ),
              borderRadius: BorderRadius.circular(22),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Icon(
              Icons.hourglass_empty_rounded,
              size: 34,
              color: JoynColors.primary,
            ),
          ),
          const SizedBox(height: 18),
          Text(
            '$featureName Coming Soon',
            style: JoynTypography.titleMedium.copyWith(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.2,
            ),
          ),
          const SizedBox(height: 6),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              'We are working hard to bring $featureName functionality soon.',
              style: JoynTypography.subtitle.copyWith(
                fontSize: 14,
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDashboardSectionCard({
    required IconData mainIcon,
    required String title,
    required String subtitle,
    required String primaryActionLabel,
    VoidCallback? onPrimaryTap,
    IconData? secondaryIcon,
    VoidCallback? onSecondaryTap,
    VoidCallback? onArrowTap,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _DashColors.cardBackground,
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
          if (secondaryIcon != null) ...[
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: onSecondaryTap,
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: _DashColors.iconChipBackgroundStart,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: _DashColors.cardBorder),
                  ),
                  child: Icon(secondaryIcon, size: 16, color: JoynColors.primary),
                ),
              ),
            ),
            const SizedBox(width: 8),
          ],
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
                        color: _DashColors.addButtonStart.withValues(alpha: 0.35),
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
}