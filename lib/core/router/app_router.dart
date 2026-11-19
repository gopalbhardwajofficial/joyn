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
import 'package:joyn/features/auth/presentation/terms_of_service_screen.dart';
import 'package:joyn/features/auth/presentation/privacy_policy_screen.dart';
import 'package:joyn/features/auth/presentation/splash_screen.dart';
import 'package:joyn/features/barcode/presentation/label_editor_screen.dart';
import 'package:joyn/features/barcode/presentation/newlable_screen.dart';
import 'package:joyn/features/barcode/flashlabel/screens/new_label_screen.dart';
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
import 'package:joyn/features/backup/presentation/cloud_backup_screen.dart';
import 'package:joyn/features/notifications/presentation/notifications_screen.dart';
import 'package:joyn/features/reports/presentation/payment_reminders_screen.dart';
import 'package:joyn/features/reports/Presentation/gst/gstr1_report_screen.dart';
import 'package:joyn/features/reports/Presentation/gst/gstr2_report_screen.dart';
import 'package:joyn/features/reports/Presentation/gst/gstr3b_report_screen.dart';
import 'package:joyn/features/reports/Presentation/gst/hsn_summary_screen.dart';
import 'package:joyn/features/reports/Presentation/expenses/manage_expenses_screen.dart';
import 'package:joyn/features/orders/presentation/quotations_list_screen.dart';
import 'package:joyn/features/orders/presentation/add_quotation_screen.dart';
import 'package:joyn/features/orders/presentation/credit_notes_list_screen.dart';
import 'package:joyn/features/orders/presentation/debit_notes_list_screen.dart';
import 'route_observer.dart'; // ✅ ADDED

final GoRouter appRouter = GoRouter(
  initialLocation: '/',
  debugLogDiagnostics: true,
  observers: [routeObserver], // ✅ ADDED — auto-refresh ke liye
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
    GoRoute(
      path: '/terms-of-service',
      pageBuilder: (context, state) => CustomTransitionPage(
        key: state.pageKey,
        child: const TermsOfServiceScreen(),
        transitionsBuilder: _slideTransition,
      ),
    ),
    GoRoute(
      path: '/privacy-policy',
      pageBuilder: (context, state) => CustomTransitionPage(
        key: state.pageKey,
        child: const PrivacyPolicyScreen(),
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
      pageBuilder: (context, state) {
        SaleOrderModel? existing;
        PartyModel? preParty;
        if (state.extra is SaleOrderModel) {
          existing = state.extra as SaleOrderModel;
        } else if (state.extra is PartyModel) {
          preParty = state.extra as PartyModel;
        }
        return CustomTransitionPage(
          key: state.pageKey,
          child: AddSaleOrderScreen(existingOrder: existing, preSelectedParty: preParty),
          transitionsBuilder: _slideTransition,
        );
      },
    ),
    GoRoute(
      path: '/add-purchase-order',
      pageBuilder: (context, state) {
        final existing = state.extra as PurchaseOrderModel?;
        return CustomTransitionPage(
          key: state.pageKey,
          child: AddPurchaseOrderScreen(existingOrder: existing),
          transitionsBuilder: _slideTransition,
        );
      },
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
      path: '/manage-inventory',
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
      builder: (context, state) => const NewLabelScreen(),
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
    GoRoute(
      path: '/cloud-backup',
      pageBuilder: (context, state) => CustomTransitionPage(
        key: state.pageKey,
        child: const CloudBackupScreen(),
        transitionsBuilder: _slideTransition,
      ),
    ),
    GoRoute(
      path: '/notifications',
      pageBuilder: (context, state) => CustomTransitionPage(
        key: state.pageKey,
        child: const NotificationsScreen(),
        transitionsBuilder: _slideTransition,
      ),
    ),
    GoRoute(
      path: '/payment-reminders',
      pageBuilder: (context, state) => CustomTransitionPage(
        key: state.pageKey,
        child: const PaymentRemindersScreen(),
        transitionsBuilder: _slideTransition,
      ),
    ),
    GoRoute(
      path: '/gstr-1',
      pageBuilder: (context, state) => CustomTransitionPage(
        key: state.pageKey,
        child: const Gstr1ReportScreen(),
        transitionsBuilder: _slideTransition,
      ),
    ),
    GoRoute(
      path: '/gstr-2',
      pageBuilder: (context, state) => CustomTransitionPage(
        key: state.pageKey,
        child: const Gstr2ReportScreen(),
        transitionsBuilder: _slideTransition,
      ),
    ),
    GoRoute(
      path: '/gstr-3b',
      pageBuilder: (context, state) => CustomTransitionPage(
        key: state.pageKey,
        child: const Gstr3bReportScreen(),
        transitionsBuilder: _slideTransition,
      ),
    ),
    GoRoute(
      path: '/hsn-summary',
      pageBuilder: (context, state) => CustomTransitionPage(
        key: state.pageKey,
        child: const HsnSummaryScreen(),
        transitionsBuilder: _slideTransition,
      ),
    ),
    GoRoute(
      path: '/expenses',
      pageBuilder: (context, state) => CustomTransitionPage(
        key: state.pageKey,
        child: const ManageExpensesScreen(),
        transitionsBuilder: _slideTransition,
      ),
    ),

    // --- Phase 11: Quotations / Estimates & Returns ---
    GoRoute(
      path: '/quotations',
      pageBuilder: (context, state) => CustomTransitionPage(
        key: state.pageKey,
        child: const QuotationsListScreen(),
        transitionsBuilder: _slideTransition,
      ),
    ),
    GoRoute(
      path: '/add-quotation',
      pageBuilder: (context, state) => CustomTransitionPage(
        key: state.pageKey,
        child: const AddQuotationScreen(),
        transitionsBuilder: _slideTransition,
      ),
    ),
    GoRoute(
      path: '/credit-notes',
      pageBuilder: (context, state) => CustomTransitionPage(
        key: state.pageKey,
        child: const CreditNotesListScreen(),
        transitionsBuilder: _slideTransition,
      ),
    ),
    GoRoute(
      path: '/debit-notes',
      pageBuilder: (context, state) => CustomTransitionPage(
        key: state.pageKey,
        child: const DebitNotesListScreen(),
        transitionsBuilder: _slideTransition,
      ),
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