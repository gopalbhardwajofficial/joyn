import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:joyn/features/Inventory/presentation/add_new_item_screen.dart';
import 'package:joyn/features/Inventory/presentation/add_new_party_screen.dart';
import 'package:joyn/features/Inventory/presentation/manage_inventory_screen.dart';
import 'package:joyn/features/reports/Presentation/overview_screen.dart';
import 'package:joyn/features/auth/presentation/company_selection_screen.dart';
import 'package:joyn/features/auth/presentation/manual_login_screen.dart';
import 'package:joyn/features/auth/presentation/onboarding_screen.dart';
import 'package:joyn/features/auth/presentation/otp_verification_screen.dart';
import 'package:joyn/features/auth/presentation/splash_screen.dart';
import 'package:joyn/features/barcode/presentation/barcode_screen.dart';
import 'package:joyn/features/barcode/presentation/label_editor_screen.dart';
import 'package:joyn/features/barcode/presentation/newlable_screen.dart';
import 'package:joyn/features/team_management/models/team_member_model.dart';
import 'package:joyn/features/business_profile/presentation/business_profile_screen.dart';
import 'package:joyn/features/business_profile/presentation/team_member_activity_log_screen.dart';
import 'package:joyn/features/business_profile/presentation/team_member_detail_screen.dart';
import 'package:joyn/features/dashboard/presentation/dashboard_screen.dart';
import 'package:joyn/features/orders/presentation/add_purchase_order_screen.dart';
import 'package:joyn/features/orders/presentation/add_sale_order_screen.dart';
import 'package:joyn/features/orders/presentation/sale_orders_list_screen.dart';
import 'package:joyn/features/orders/presentation/purchase_orders_list_screen.dart';
import 'package:joyn/features/orders/presentation/sale_order_detail_screen.dart';
import 'package:joyn/features/orders/presentation/purchase_order_detail_screen.dart';
import 'package:joyn/features/orders/models/sales_models.dart';
import 'package:joyn/features/Inventory/presentation/party_list_screen.dart';
import 'package:joyn/features/Inventory/presentation/items_list_screen.dart';

final GoRouter appRouter = GoRouter(
  initialLocation: '/',
  debugLogDiagnostics: true,
  routes: [
    // --- Splash & Onboarding ---
    GoRoute(
      path: '/',
      builder: (context, state) => const SplashScreen(),
    ),
    GoRoute(
      path: '/onboarding',
      pageBuilder: (context, state) => CustomTransitionPage(
        key: state.pageKey,
        child: const OnboardingScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
    ),

    // --- Authentication ---
    GoRoute(
      path: '/manual-login',
      pageBuilder: (context, state) => CustomTransitionPage(
        key: state.pageKey,
        child: const ManualLoginScreen(),
        transitionsBuilder: _slideTransition,
      ),
    ),
    GoRoute(
      path: '/otp',
      pageBuilder: (context, state) => CustomTransitionPage(
        key: state.pageKey,
        child: const OtpVerificationScreen(),
        transitionsBuilder: _slideTransition,
      ),
    ),
    GoRoute(
      path: '/company-selection',
      pageBuilder: (context, state) => CustomTransitionPage(
        key: state.pageKey,
        child: const CompanySelectionScreen(),
        transitionsBuilder: _slideTransition,
      ),
    ),

    // --- Dashboard ---
    GoRoute(
      path: '/dashboard',
      pageBuilder: (context, state) {
        final bool autoShowSetup = state.uri.queryParameters['autoShowSetup'] == 'true';
        return CustomTransitionPage(
          key: state.pageKey,
          child: DashboardScreen(autoShowSetup: autoShowSetup),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(opacity: animation, child: child);
          },
        );
      },
    ),

    // --- Orders ---
    GoRoute(
      path: '/add-sale-order',
      pageBuilder: (context, state) => CustomTransitionPage(
        key: state.pageKey,
        child: const AddSaleOrderScreen(),
        transitionsBuilder: _slideTransition,
      ),
    ),
    GoRoute(
      path: '/add-purchase-order',
      pageBuilder: (context, state) => CustomTransitionPage(
        key: state.pageKey,
        child: const AddPurchaseOrderScreen(),
        transitionsBuilder: _slideTransition,
      ),
    ),
    GoRoute(
      path: '/sale-orders-list',
      builder: (context, state) => const SaleOrdersListScreen(),
    ),
    GoRoute(
      path: '/purchase-orders-list',
      builder: (context, state) => const PurchaseOrdersListScreen(),
    ),
    GoRoute(
      path: '/sale-order-detail',
      builder: (context, state) {
        final order = state.extra as SaleOrderModel;
        return SaleOrderDetailScreen(order: order);
      },
    ),
    GoRoute(
      path: '/purchase-order-detail',
      builder: (context, state) {
        final order = state.extra as PurchaseOrderModel;
        return PurchaseOrderDetailScreen(order: order);
      },
    ),

    // --- Inventory & Parties ---
    GoRoute(
      path: '/add-party',
      pageBuilder: (context, state) {
        final mode = state.extra as PartySaveMode? ?? PartySaveMode.mainParty;
        return CustomTransitionPage(
          key: state.pageKey,
          child: AddNewPartyScreen(initialSaveMode: mode),
          transitionsBuilder: _slideTransition,
        );
      },
    ),
    GoRoute(
      path: '/add-inventory',
      pageBuilder: (context, state) => CustomTransitionPage(
        key: state.pageKey,
        child: const ManageInventoryScreen(),
        transitionsBuilder: _slideTransition,
      ),
    ),
    GoRoute(
      path: '/add-new-item',
      pageBuilder: (context, state) => CustomTransitionPage(
        key: state.pageKey,
        child: const AddNewItemScreen(),
        transitionsBuilder: _slideTransition,
      ),
    ),
    GoRoute(
      path: '/Overview',
      pageBuilder: (context, state) => CustomTransitionPage(
        key: state.pageKey,
        child: const OverviewScreen(),
        transitionsBuilder: _slideTransition,
      ),
    ),
    GoRoute(
      path: '/label-editor',
      builder: (context, state) {
        final sizeResult = state.extra as LabelSizeResult?;
        return LabelEditorScreen(labelSize: sizeResult);
      },
    ),
    GoRoute(
      path: '/add-barcode',
      builder: (context, state) => const NewLabelSizeScreen(),
    ),
    GoRoute(
      path: '/party-list',
      builder: (context, state) => const PartyListScreen(),
    ),
    GoRoute(
      path: '/items-list',
      builder: (context, state) => const ItemsListScreen(),
    ),

    // --- Business Profile & Team ---
    GoRoute(
      path: '/business-profile',
      pageBuilder: (context, state) => CustomTransitionPage(
        key: state.pageKey,
        child: const BusinessProfileScreen(),
        transitionsBuilder: _slideTransition,
      ),
    ),
    GoRoute(
      path: '/team-member-detail',
      pageBuilder: (context, state) {
        final member = state.extra as TeamMemberModel;
        return CustomTransitionPage(
          key: state.pageKey,
          child: TeamMemberDetailScreen(member: member),
          transitionsBuilder: _slideTransition,
        );
      },
    ),
    GoRoute(
      path: '/team-member-activity-log',
      pageBuilder: (context, state) {
        final member = state.extra as TeamMemberModel;
        return CustomTransitionPage(
          key: state.pageKey,
          child: TeamMemberActivityLogScreen(member: member),
          transitionsBuilder: _slideTransition,
        );
      },
    ),
  ],
);

/// Common slide transition from right to left
Widget _slideTransition(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
    ) {
  const begin = Offset(1.0, 0.0);
  const end = Offset.zero;
  const curve = Curves.easeInOutCubic;
  final tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
  return SlideTransition(
    position: animation.drive(tween),
    child: child,
  );
}