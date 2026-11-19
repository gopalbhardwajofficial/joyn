// lib/features/dashboard/presentation/dashboard_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:joyn/features/Inventory/presentation/payment_in_screen.dart';
import 'package:joyn/features/orders/presentation/sale_orders_list_screen.dart';
import 'package:joyn/features/orders/models/sales_models.dart';
import 'package:joyn/features/orders/data/sales_repository.dart';
import '../../../core/theme/joyn_colors.dart';
import '../../../core/theme/joyn_typography.dart';
import '../../auth/providers/auth_provider.dart';
import 'business_setup_bottom_sheet.dart';
import 'package:joyn/core/widgets/joyn_logout_dialog.dart';
import 'package:joyn/features/barcode/flashlabel/screens/new_label_screen.dart';
import 'package:joyn/features/barcode/presentation/newlable_screen.dart';
import 'package:joyn/features/barcode/presentation/label_editor_screen.dart';
import 'package:joyn/features/reports/Presentation/overview_screen.dart';
import 'package:joyn/features/reports/Presentation/reports_screen.dart';
import '../../../core/services/sync_service.dart';
import '../../../core/services/api_service.dart';

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

  // ── Toggle colors ──
  static const toggleTrack = Color.fromRGBO(255, 255, 255, 1.0);
  static const toggleActiveStart = Color.fromRGBO(200, 40, 51, 1.0);
  static const toggleActiveEnd = Color.fromRGBO(168, 24, 34, 1.0);
  static const toggleInactiveText = Color.fromRGBO(110, 112, 122, 1.0);
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
  int _unreadNotifications = 0;

  /// Home tab ke andar toggle: 0 = Dashboard, 1 = Overview
  int _homeTabIndex = 0;

  @override
  void initState() {
    super.initState();
    _fetchUnreadNotifications();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_hasTriggeredPopup && widget.autoShowSetup && mounted) {
        _hasTriggeredPopup = true;
        _showBusinessSetupPopup();
      }
      // Silently reconcile pending offline mutations with cloud in background
      SyncService.getInstance()
          .then((s) => s.performFullSync())
          .catchError((_) => <String, dynamic>{'success': false});
    });
  }

  Future<void> _fetchUnreadNotifications() async {
    try {
      final res = await ApiService.getNotifications(limit: 1);
      if (res['success'] == true && mounted) {
        setState(() {
          _unreadNotifications = res['unreadCount'] ?? 0;
        });
      }
    } catch (_) {}
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
                leading: const Icon(Icons.notifications_outlined, color: JoynColors.primary),
                title: Text('Notifications', style: JoynTypography.bodyLarge.copyWith(fontSize: 15)),
                subtitle: Text('Alerts, stock warnings & system messages', style: JoynTypography.bodySmall.copyWith(fontSize: 12, color: JoynColors.secondaryText)),
                trailing: _unreadNotifications > 0
                    ? Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEF4444),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '$_unreadNotifications',
                          style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700),
                        ),
                      )
                    : null,
                onTap: () {
                  Navigator.pop(context);
                  setState(() => _unreadNotifications = 0);
                  context.push('/notifications').then((_) => _fetchUnreadNotifications());
                },
              ),
              ListTile(
                leading: const Icon(Icons.currency_rupee_rounded, color: JoynColors.primary),
                title: Text('Payment Reminders', style: JoynTypography.bodyLarge.copyWith(fontSize: 15)),
                subtitle: Text('Overdue debtors, WhatsApp reminders & UPI payment links', style: JoynTypography.bodySmall.copyWith(fontSize: 12, color: JoynColors.secondaryText)),
                onTap: () {
                  Navigator.pop(context);
                  context.push('/payment-reminders');
                },
              ),
              ListTile(
                leading: const Icon(Icons.cloud_sync_outlined, color: JoynColors.primary),
                title: Text('Cloud Backup & Sync', style: JoynTypography.bodyLarge.copyWith(fontSize: 15)),
                subtitle: Text('Manage automatic sync and cloud database backups', style: JoynTypography.bodySmall.copyWith(fontSize: 12, color: JoynColors.secondaryText)),
                onTap: () {
                  Navigator.pop(context);
                  context.push('/cloud-backup');
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

  // ============================================================
  // SNACKBAR HELPER
  // ============================================================
  void _showSnack(String msg, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(
                isError ? Icons.error_outline_rounded : Icons.check_circle_rounded,
                color: Colors.white,
                size: 18,
              ),
              const SizedBox(width: 8),
              Expanded(child: Text(msg)),
            ],
          ),
          backgroundColor: isError ? JoynColors.error : JoynColors.primary,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          duration: const Duration(seconds: 2),
        ),
      );
  }

  // ============================================================
  // PAYMENT IN / OUT FLOW  ✅ FULLY WIRED
  // ============================================================
  Future<void> _openPaymentFlow({required bool isPaymentOut}) async {
    // ── Step 1: Show loading while fetching parties
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(
        child: CircularProgressIndicator(color: JoynColors.primary),
      ),
    );

    final repo = SalesRepository();
    List<PartyModel> parties = [];
    try {
      parties = await repo.getParties();
    } catch (e) {
      if (!mounted) return;
      Navigator.of(context).pop(); // close loader
      _showSnack('Failed to load parties: $e', isError: true);
      return;
    }

    if (!mounted) return;
    Navigator.of(context).pop(); // close loader

    // ── Step 2: No parties → prompt to add one
    if (parties.isEmpty) {
      _showSnack('No parties found. Add a party first.', isError: false);
      return;
    }

    // ── Step 3: Party picker sheet
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

    // ── Step 4: Open PaymentInScreen with forced direction
    final saved = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => PaymentInScreen(
          party: selected,
          isPaymentOut: isPaymentOut, // ✅ forced direction
        ),
      ),
    );

    // ── Step 5: Success feedback
    if (saved == true && mounted) {
      _showSnack(
        isPaymentOut
            ? 'Payment Out recorded successfully'
            : 'Payment In recorded successfully',
      );
    }
  }

  Future<bool> _showExitConfirmationDialog() async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: JoynColors.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.exit_to_app_rounded, color: JoynColors.primary, size: 22),
            ),
            const SizedBox(width: 12),
            const Text(
              'Exit JOYN?',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
          ],
        ),
        content: const Text(
          'Are you sure you want to close and exit the app?',
          style: TextStyle(fontSize: 14, color: Colors.black87),
        ),
        actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(false),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            ),
            child: Text(
              'Cancel',
              style: TextStyle(
                color: Colors.grey.shade700,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(dialogCtx).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: JoynColors.primary,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            ),
            child: const Text(
              'Exit',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);

    final String appBarTitle = (authState.businessName.isNotEmpty)
        ? authState.businessName
        : (authState.selectedCompany != null && authState.selectedCompany!.isNotEmpty)
        ? authState.selectedCompany!
        : 'Welcome User';

    Widget body;
    switch (_bottomNavIndex) {
      case 0:
        body = _buildHomeView();
        break;
      case 1:
        body = authState.permissions.accessSales
            ? const SaleOrdersListScreen()
            : _buildAccessDeniedView('Sales', authState.userRole);
        break;
      case 2:
        body = authState.permissions.accessReports
            ? const ReportsScreen()
            : _buildAccessDeniedView('Reports', authState.userRole);
        break;
      case 3:
        body = _buildMoreView();
        break;
      default:
        body = _buildHomeView();
    }

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final shouldExit = await _showExitConfirmationDialog();
        if (shouldExit) {
          SystemNavigator.pop();
        }
      },
      child: Scaffold(
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
                          fontWeight: FontWeight.w800,
                          fontSize: 16.5,
                          letterSpacing: -0.3,
                          color: const Color(0xFF1A1A1F),
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
              onTap: () => context.push('/cloud-backup'),
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
                  Icons.cloud_sync_outlined,
                  color: JoynColors.primary,
                  size: 20,
                ),
              ),
            ),
            const SizedBox(width: 8),
            InkWell(
              onTap: () {
                setState(() => _unreadNotifications = 0);
                context.push('/notifications').then((_) => _fetchUnreadNotifications());
              },
              borderRadius: BorderRadius.circular(12),
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
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
                      Icons.notifications_outlined,
                      color: JoynColors.primary,
                      size: 20,
                    ),
                  ),
                  if (_unreadNotifications > 0)
                    Positioned(
                      top: -2,
                      right: -2,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: Color(0xFFEF4444),
                          shape: BoxShape.circle,
                        ),
                        constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                        child: Text(
                          _unreadNotifications > 9 ? '9+' : '$_unreadNotifications',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 8),
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
                if (index == 1 && !authState.permissions.accessSales) {
                  _showSnack('Access Restricted: Your role (${authState.userRole}) does not have permission to access Sales.', isError: true);
                  return;
                }
                if (index == 2 && !authState.permissions.accessReports) {
                  _showSnack('Access Restricted: Your role (${authState.userRole}) does not have permission to access Reports.', isError: true);
                  return;
                }
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
              items: [
                const BottomNavigationBarItem(
                  icon: Icon(Icons.home_rounded),
                  label: 'Home',
                ),
                BottomNavigationBarItem(
                  icon: Icon(
                    authState.permissions.accessSales
                        ? Icons.shopping_cart_outlined
                        : Icons.lock_outline_rounded,
                  ),
                  label: 'Sales',
                ),
                BottomNavigationBarItem(
                  icon: Icon(
                    authState.permissions.accessReports
                        ? Icons.file_copy
                        : Icons.lock_outline_rounded,
                  ),
                  label: 'Reports',
                ),
                const BottomNavigationBarItem(
                  icon: Icon(Icons.more_horiz_rounded),
                  label: 'More',
                ),
              ],
            ),
          ),
        ),
      ),
    ),
    );
  }

  // ============================================================
  // HOME VIEW
  // ============================================================
  Widget _buildHomeView() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
          child: _buildHomeToggle(),
        ),
        Expanded(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 260),
            switchInCurve: Curves.easeOutCubic,
            switchOutCurve: Curves.easeInCubic,
            transitionBuilder: (child, animation) {
              return FadeTransition(
                opacity: animation,
                child: SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0.03, 0),
                    end: Offset.zero,
                  ).animate(animation),
                  child: child,
                ),
              );
            },
            child: _homeTabIndex == 0
                ? KeyedSubtree(
              key: const ValueKey('home_dash'),
              child: _buildDashboardSectionCardsList(),
            )
                : const OverviewScreen(key: ValueKey('home_overview')),
          ),
        ),
      ],
    );
  }

  Widget _buildHomeToggle() {
    return Container(
      height: 50,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: _DashColors.toggleTrack,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _DashColors.cardBorder, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 2,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final segWidth = constraints.maxWidth / 2;
          return Stack(
            children: [
              AnimatedPositioned(
                duration: const Duration(milliseconds: 280),
                curve: Curves.easeOutCubic,
                left: _homeTabIndex == 0 ? 0 : segWidth,
                top: 0,
                bottom: 0,
                width: segWidth,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [
                        _DashColors.toggleActiveStart,
                        _DashColors.toggleActiveEnd,
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: _DashColors.toggleActiveStart.withValues(alpha: 0.32),
                        blurRadius: 12,
                        offset: const Offset(0, 5),
                      ),
                      BoxShadow(
                        color: _DashColors.toggleActiveStart.withValues(alpha: 0.14),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                ),
              ),
              Row(
                children: [
                  _buildToggleLabel(
                    index: 0,
                    icon: Icons.dashboard_rounded,
                    label: 'Dashboard',
                  ),
                  _buildToggleLabel(
                    index: 1,
                    icon: Icons.insights_rounded,
                    label: 'Overview',
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildToggleLabel({
    required int index,
    required IconData icon,
    required String label,
  }) {
    final isActive = _homeTabIndex == index;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          if (_homeTabIndex != index) {
            setState(() => _homeTabIndex = index);
          }
        },
        behavior: HitTestBehavior.opaque,
        child: Center(
          child: AnimatedDefaultTextStyle(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOut,
            style: JoynTypography.bodyMedium.copyWith(
              fontSize: 13.5,
              fontWeight: isActive ? FontWeight.w800 : FontWeight.w600,
              color: isActive ? Colors.white : _DashColors.toggleInactiveText,
              letterSpacing: -0.1,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                AnimatedScale(
                  duration: const Duration(milliseconds: 220),
                  curve: Curves.easeOutBack,
                  scale: isActive ? 1.0 : 0.92,
                  child: Icon(
                    icon,
                    size: 16,
                    color: isActive ? Colors.white : _DashColors.toggleInactiveText,
                  ),
                ),
                const SizedBox(width: 7),
                Text(label),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDashboardSectionCardsList() {
    final authState = ref.watch(authProvider);
    final permissions = authState.permissions;
    final userRole = authState.userRole;

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
      children: [
        _buildDashboardSectionCard(
          mainIcon: Icons.shopping_cart_outlined,
          title: 'Sale',
          subtitle: 'Manage all your sales',
          primaryActionLabel: 'Add',
          accent: const Color(0xFF16A34A),
          isEnabled: permissions.accessSales,
          disabledReason: 'Role ($userRole) has no Sales access',
          onPrimaryTap: () => context.push('/add-sale-order'),
          onArrowTap: () => context.push('/sale-orders-list'),
        ),
        const SizedBox(height: 12),
        _buildDashboardSectionCard(
          mainIcon: Icons.shopping_bag_outlined,
          title: 'Purchase',
          subtitle: 'Manage all your purchases',
          primaryActionLabel: 'Add',
          accent: const Color(0xFFEA580C),
          isEnabled: permissions.accessPurchase,
          disabledReason: 'Role ($userRole) has no Purchase access',
          onPrimaryTap: () => context.push('/add-purchase-order'),
          onArrowTap: () => context.push('/purchase-orders-list'),
        ),
        const SizedBox(height: 12),
        _buildDashboardSectionCard(
          mainIcon: Icons.people_outline_rounded,
          title: 'Party',
          subtitle: 'Manage all your parties',
          primaryActionLabel: 'Add',
          accent: const Color(0xFF2563EB),
          isEnabled: permissions.accessPartyDetails,
          disabledReason: 'Role ($userRole) has no Party access',
          onPrimaryTap: () => context.push('/add-party'),
          onArrowTap: () => context.push('/party-list'),
        ),
        const SizedBox(height: 12),
        _buildDashboardSectionCard(
          mainIcon: Icons.category_outlined,
          title: 'Items',
          subtitle: 'Manage your item catalog',
          primaryActionLabel: 'Add',
          accent: const Color(0xFF0891B2),
          isEnabled: permissions.accessInventory,
          disabledReason: 'Role ($userRole) has no Inventory access',
          onPrimaryTap: () => context.push('/add-new-item'),
          onArrowTap: () => context.push('/items-list'),
        ),
        const SizedBox(height: 12),
        _buildDashboardSectionCard(
          mainIcon: Icons.inventory_2_outlined,
          title: 'Inventory',
          subtitle: 'Manage your inventory',
          primaryActionLabel: 'Add',
          accent: const Color(0xFF7C3AED),
          isEnabled: permissions.accessInventory,
          disabledReason: 'Role ($userRole) has no Inventory access',
          onPrimaryTap: () => context.push('/add-inventory'),
          onArrowTap: () => context.push('/manage-inventory'),
        ),
        const SizedBox(height: 16),
        _buildBarcodeCard(
          isEnabled: permissions.accessInventory,
          userRole: userRole,
        ),
        const SizedBox(height: 16),

        // ── PAYMENT IN / OUT BUTTONS ──
        Row(
          children: [
            Expanded(
              child: _buildPaymentButton(
                icon: Icons.arrow_downward_rounded,
                label: 'Payment IN',
                color: const Color(0xFF16A34A),
                isEnabled: permissions.accessSales,
                disabledReason: 'Role ($userRole) has no Payment IN access',
                onTap: () => _openPaymentFlow(isPaymentOut: false),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildPaymentButton(
                icon: Icons.arrow_upward_rounded,
                label: 'Payment OUT',
                color: const Color(0xFFC0202B),
                isEnabled: permissions.accessPurchase,
                disabledReason: 'Role ($userRole) has no Payment OUT access',
                onTap: () => _openPaymentFlow(isPaymentOut: true),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildBarcodeCard({bool isEnabled = true, String userRole = 'Staff'}) {
    return GestureDetector(
      onTap: () {
        if (!isEnabled) {
          HapticFeedback.lightImpact();
          _showSnack('Access Restricted: Role ($userRole) does not have permission for Barcodes/Inventory.', isError: true);
          return;
        }
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const NewLabelScreen()),
        );
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          gradient: isEnabled
              ? const LinearGradient(
                  colors: [Color(0xFF2563EB), Color(0xFF1D4ED8)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : const LinearGradient(
                  colors: [Color(0xFF94A3B8), Color(0xFF64748B)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: isEnabled
              ? [
                  BoxShadow(
                    color: const Color(0xFF2563EB).withValues(alpha: 0.30),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 3,
                    offset: const Offset(0, 1),
                  ),
                ]
              : [],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: 26,
              height: 26,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.22),
                borderRadius: BorderRadius.circular(9),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.32),
                  width: 1,
                ),
              ),
              child: Icon(isEnabled ? Icons.add_rounded : Icons.lock_rounded, size: 18, color: Colors.white),
            ),
            const SizedBox(height: 5),
            Text(
              isEnabled ? 'Barcodes & QR' : 'Barcodes & QR (Locked)',
              style: JoynTypography.bodyLarge.copyWith(
                fontWeight: FontWeight.w800,
                fontSize: 13.5,
                color: Colors.white,
                letterSpacing: -0.1,
                height: 1.1,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 2),
            Text(
              isEnabled ? 'Generate new barcodes / QR codes' : 'Access restricted by firm owner',
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 11,
                height: 1.2,
                fontWeight: FontWeight.w500,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
    bool isEnabled = true,
    String? disabledReason,
  }) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isEnabled
              ? [
                  color,
                  Color.lerp(color, Colors.black, 0.20) ?? color,
                ]
              : [
                  const Color(0xFF94A3B8),
                  const Color(0xFF64748B),
                ],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: isEnabled
            ? [
                BoxShadow(
                  color: color.withValues(alpha: 0.35),
                  blurRadius: 14,
                  offset: const Offset(0, 6),
                ),
              ]
            : [],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: isEnabled
              ? onTap
              : () {
                  HapticFeedback.lightImpact();
                  _showSnack(disabledReason ?? 'Access Restricted: Your role does not have permission for $label.', isError: true);
                },
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.22),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(isEnabled ? icon : Icons.lock_rounded, size: 17, color: Colors.white),
                ),
                const SizedBox(width: 10),
                Text(
                  label,
                  style: JoynTypography.bodyMedium.copyWith(
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    fontSize: 14.5,
                    letterSpacing: -0.1,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDashboardSectionCard({
    required IconData mainIcon,
    required String title,
    required String subtitle,
    required String primaryActionLabel,
    required Color accent,
    VoidCallback? onPrimaryTap,
    VoidCallback? onArrowTap,
    bool isEnabled = true,
    String? disabledReason,
  }) {
    final effectiveColor = isEnabled ? accent : const Color(0xFF94A3B8);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isEnabled ? Colors.white : const Color(0xFFFAFAFB),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isEnabled ? _DashColors.cardBorder : const Color(0xFFE2E8F0),
          width: 1,
        ),
        boxShadow: isEnabled
            ? [
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
              ]
            : [],
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  effectiveColor.withValues(alpha: 0.14),
                  effectiveColor.withValues(alpha: 0.06),
                ],
              ),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: effectiveColor.withValues(alpha: 0.18),
                width: 1,
              ),
            ),
            child: Icon(mainIcon, color: effectiveColor, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        title,
                        style: JoynTypography.bodyLarge.copyWith(
                          fontWeight: FontWeight.w800,
                          fontSize: 15,
                          letterSpacing: -0.2,
                          color: isEnabled ? const Color(0xFF16171D) : const Color(0xFF64748B),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (!isEnabled) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(5),
                          border: Border.all(color: const Color(0xFFCBD5E1), width: 0.8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.lock_rounded, size: 9, color: Color(0xFF64748B)),
                            const SizedBox(width: 2.5),
                            Text(
                              'LOCKED',
                              style: JoynTypography.caption.copyWith(
                                fontSize: 8.5,
                                fontWeight: FontWeight.w800,
                                color: const Color(0xFF64748B),
                                letterSpacing: 0.3,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  isEnabled ? subtitle : (disabledReason ?? 'Disabled for your role'),
                  style: JoynTypography.subtitle.copyWith(
                    fontSize: 11.5,
                    color: const Color(0xFF8A8D99),
                    height: 1.2,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          if (isEnabled) ...[
            Tooltip(
              message: primaryActionLabel,
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: onPrimaryTap,
                  borderRadius: BorderRadius.circular(14),
                  child: Container(
                    width: 54,
                    height: 46,
                    padding: const EdgeInsets.symmetric(vertical: 5),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          _DashColors.addButtonStart,
                          _DashColors.addButtonEnd,
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
                        const Icon(Icons.add_rounded, size: 17, color: _DashColors.addButtonText),
                        const SizedBox(height: 1),
                        Text(
                          primaryActionLabel.replaceFirst('Add ', ''),
                          style: JoynTypography.caption.copyWith(
                            color: _DashColors.addButtonText,
                            fontWeight: FontWeight.w800,
                            fontSize: 9,
                            height: 1,
                            letterSpacing: 0.1,
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
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        _DashColors.arrowButtonStart,
                        _DashColors.arrowButtonEnd,
                      ],
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.20),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: const Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 16),
                ),
              ),
            ),
          ] else ...[
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () {
                  HapticFeedback.lightImpact();
                  _showSnack(disabledReason ?? 'Access Restricted: Your role does not have permission to access $title.', isError: true);
                },
                borderRadius: BorderRadius.circular(14),
                child: Container(
                  height: 46,
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.lock_outline_rounded, size: 16, color: Color(0xFF94A3B8)),
                      SizedBox(width: 4),
                      Icon(Icons.chevron_right_rounded, size: 16, color: Color(0xFF94A3B8)),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildAccessDeniedView(String module, String role) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: const Color(0xFFFEE2E2),
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFFFCA5A5), width: 1.5),
              ),
              child: const Icon(Icons.lock_rounded, size: 36, color: Color(0xFFDC2626)),
            ),
            const SizedBox(height: 20),
            Text(
              'Access Restricted',
              style: JoynTypography.titleMedium.copyWith(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: JoynColors.primary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Your role ($role) does not have permission to access the $module module in this business.',
              textAlign: TextAlign.center,
              style: JoynTypography.subtitle.copyWith(
                fontSize: 13.5,
                color: JoynColors.secondaryText,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => setState(() => _bottomNavIndex = 0),
              icon: const Icon(Icons.home_rounded, size: 18),
              label: const Text('Back to Home'),
              style: ElevatedButton.styleFrom(
                backgroundColor: JoynColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMoreView() {
    final authState = ref.watch(authProvider);
    final permissions = authState.permissions;
    final userRole = authState.userRole;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.more_horiz_rounded, size: 72, color: JoynColors.primary),
          const SizedBox(height: 16),
          Text(
            'More Options',
            style: JoynTypography.titleMedium.copyWith(fontSize: 20, fontWeight: FontWeight.w700),
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
            onPressed: () {
              if (!permissions.accessInventory) {
                _showSnack('Access Restricted: Your role ($userRole) does not have permission to access Inventory.', isError: true);
                return;
              }
              context.push('/manage-inventory');
            },
            icon: Icon(permissions.accessInventory ? Icons.inventory_2_outlined : Icons.lock_outline_rounded),
            label: const Text('Manage Inventory'),
            style: ElevatedButton.styleFrom(
              backgroundColor: JoynColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            onPressed: () {
              if (!permissions.accessPartyDetails) {
                _showSnack('Access Restricted: Your role ($userRole) does not have permission to access Parties.', isError: true);
                return;
              }
              context.push('/party-list');
            },
            icon: Icon(permissions.accessPartyDetails ? Icons.people_outline_rounded : Icons.lock_outline_rounded),
            label: const Text('Manage Parties'),
            style: ElevatedButton.styleFrom(
              backgroundColor: JoynColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            onPressed: () {
              if (!permissions.accessInventory) {
                _showSnack('Access Restricted: Your role ($userRole) does not have permission to access Items.', isError: true);
                return;
              }
              context.push('/items-list');
            },
            icon: Icon(permissions.accessInventory ? Icons.category_outlined : Icons.lock_outline_rounded),
            label: const Text('Manage Items'),
            style: ElevatedButton.styleFrom(
              backgroundColor: JoynColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            onPressed: () {
              context.push('/payment-reminders');
            },
            icon: const Icon(Icons.currency_rupee_rounded),
            label: const Text('Payment Reminders & Debtors'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF4338CA),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            onPressed: () {
              setState(() => _unreadNotifications = 0);
              context.push('/notifications').then((_) => _fetchUnreadNotifications());
            },
            icon: const Icon(Icons.notifications_outlined),
            label: Text(_unreadNotifications > 0 ? 'Notifications ($_unreadNotifications new)' : 'Notifications Feed'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1E293B),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
              style: JoynTypography.titleMedium.copyWith(fontSize: 16, fontWeight: FontWeight.w800),
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
                  child: Text('No parties found', style: JoynTypography.subtitle.copyWith(fontSize: 14)),
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
                      backgroundColor: JoynColors.primary.withValues(alpha: 0.1),
                      child: const Icon(Icons.person_outline_rounded, color: JoynColors.primary),
                    ),
                    title: Text(
                      p.name,
                      style: JoynTypography.bodyLarge.copyWith(fontSize: 14.5, fontWeight: FontWeight.w700),
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