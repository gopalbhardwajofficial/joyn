import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/joyn_colors.dart';
import '../../../core/theme/joyn_typography.dart';
import '../../auth/providers/auth_provider.dart';
import 'business_setup_bottom_sheet.dart';

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

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);

    // Dynamic AppBar Title: Business Name or "Welcome User"
    final String appBarTitle = (authState.businessName.isNotEmpty)
        ? authState.businessName
        : (authState.selectedCompany != null &&
                authState.selectedCompany!.isNotEmpty)
            ? authState.selectedCompany!
            : 'Welcome User';

    return Scaffold(
      backgroundColor: JoynColors.background,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: JoynColors.background,
        elevation: 0,
        scrolledUnderElevation: 0,
        titleSpacing: 20,
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Left Store Icon
            InkWell(
              onTap: () {
                context.push('/business-profile');
              },
              borderRadius: BorderRadius.circular(12),
              child: Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: JoynColors.background,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: JoynColors.border, width: 1.2),
                ),
                child: const Icon(
                  Icons.storefront_outlined,
                  color: JoynColors.primary,
                  size: 20,
                ),
              ),
            ),

            // Center Business Selector Dropdown
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
                    Text(
                      appBarTitle,
                      style: JoynTypography.bodyLarge.copyWith(
                        fontWeight: FontWeight.w700,
                        fontSize: 17,
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

            // Right Settings Gear Icon
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: JoynColors.background,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: JoynColors.border, width: 1.2),
              ),
              child: const Icon(
                Icons.settings_outlined,
                color: JoynColors.primary,
                size: 20,
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          const SizedBox(height: 8),

          // Custom Tab Bar (Dashboard | Reporting Coming Soon)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                // Dashboard Tab
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
                            ),
                          ),
                        ),
                        Container(
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

                // Reporting Tab (With Coming Soon badge)
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
                                'Reporting',
                                style: JoynTypography.bodyLarge.copyWith(
                                  fontWeight: FontWeight.w500,
                                  color: _selectedTabIndex == 1
                                      ? JoynColors.primary
                                      : JoynColors.secondaryText.withValues(alpha: 0.7),
                                  fontSize: 15,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 6, vertical: 1.5),
                                decoration: BoxDecoration(
                                  color: JoynColors.chipBackground,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  'Coming Soon',
                                  style: JoynTypography.caption.copyWith(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w500,
                                    color: JoynColors.secondaryText,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
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

          // Main Tab Body
          Expanded(
            child: _selectedTabIndex == 0
                ? (_bottomNavIndex == 0
                    ? _buildDashboardView()
                    : _buildComingSoonFeatureView(_getBottomNavLabel(_bottomNavIndex)))
                : _buildReportingComingSoonView(),
          ),
        ],
      ),

      // Bottom Navigation Bar
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: JoynColors.background,
          border: Border(top: BorderSide(color: JoynColors.border, width: 1)),
        ),
        child: BottomNavigationBar(
          currentIndex: _bottomNavIndex,
          onTap: (index) {
            setState(() {
              _bottomNavIndex = index;
            });
            if (index != 0) {
              _showComingSoonSnackBar(_getBottomNavLabel(index));
            }
          },
          type: BottomNavigationBarType.fixed,
          backgroundColor: JoynColors.background,
          selectedItemColor: JoynColors.primary,
          unselectedItemColor: JoynColors.secondaryText,
          selectedLabelStyle: JoynTypography.caption.copyWith(
            fontWeight: FontWeight.w700,
            fontSize: 12,
          ),
          unselectedLabelStyle: JoynTypography.caption.copyWith(
            fontWeight: FontWeight.w500,
            fontSize: 12,
          ),
          elevation: 0,
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
              icon: Icon(Icons.inventory_2_outlined),
              label: 'Inventory',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.more_horiz_rounded),
              label: 'More',
            ),
          ],
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

  // Dashboard Scroll View
  Widget _buildDashboardView() {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      children: [
        // 1. Sale Card
        _buildDashboardSectionCard(
          mainIcon: Icons.shopping_cart_outlined,
          title: 'Sale',
          subtitle: 'Manage all your sales',
          actionButtons: [
            _buildGridActionButton(
              icon: Icons.add_rounded,
              title: 'Add Sales',
            ),
            _buildGridActionButton(
              icon: Icons.visibility_outlined,
              title: 'View Sales',
            ),
            _buildGridActionButton(
              icon: Icons.bar_chart_rounded,
              title: 'Sales Report',
            ),
          ],
        ),

        const SizedBox(height: 16),

        // 2. Purchase Card
        _buildDashboardSectionCard(
          mainIcon: Icons.shopping_bag_outlined,
          title: 'Purchase',
          subtitle: 'Manage all your purchases',
          actionButtons: [
            _buildGridActionButton(
              icon: Icons.add_rounded,
              title: 'Add Purchase',
            ),
            _buildGridActionButton(
              icon: Icons.visibility_outlined,
              title: 'View Purchase',
            ),
            _buildGridActionButton(
              icon: Icons.bar_chart_rounded,
              title: 'Purchase Report',
            ),
          ],
        ),

        const SizedBox(height: 16),

        // 3. Inventory Card
        _buildDashboardSectionCard(
          mainIcon: Icons.inventory_2_outlined,
          title: 'Inventory',
          subtitle: 'Manage your inventory',
          actionButtons: [
            _buildGridActionButton(
              icon: Icons.add_rounded,
              title: 'Add New Inventory',
              flex: 1,
            ),
            _buildGridActionButton(
              icon: Icons.inventory_outlined,
              title: 'Manage Inventory',
              flex: 1,
            ),
          ],
        ),

        const SizedBox(height: 16),

        // 4. Party Details Card
        _buildDashboardSectionCard(
          mainIcon: Icons.people_outline_rounded,
          title: 'Party Details',
          subtitle: 'Manage all your parties',
          actionButtons: [
            _buildGridActionButton(
              icon: Icons.add_rounded,
              title: 'Add New Party',
              flex: 1,
            ),
            _buildGridActionButton(
              icon: Icons.visibility_outlined,
              title: 'View Parties',
              flex: 1,
            ),
          ],
        ),

        const SizedBox(height: 16),

        // 5. Create Barcode / QR Code Card
        _buildDashboardSectionCard(
          mainIcon: Icons.qr_code_scanner_rounded,
          title: 'Create Barcode / QR Code',
          subtitle: 'Generate barcode or QR code',
          actionButtons: [
            _buildGridActionButton(
              icon: Icons.document_scanner_outlined,
              title: 'Generate Barcode',
              flex: 1,
            ),
            _buildGridActionButton(
              icon: Icons.qr_code_2_rounded,
              title: 'Generate QR Code',
              flex: 1,
            ),
          ],
        ),

        const SizedBox(height: 24),
      ],
    );
  }

  // Placeholder view for bottom nav items (Sales, Inventory, More)
  Widget _buildComingSoonFeatureView(String featureName) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: JoynColors.iconBackground,
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Icon(
              Icons.hourglass_empty_rounded,
              size: 32,
              color: JoynColors.primary,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            '$featureName Coming Soon',
            style: JoynTypography.titleMedium.copyWith(
              fontSize: 20,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'We are working hard to bring $featureName functionality soon.',
            style: JoynTypography.subtitle.copyWith(
              fontSize: 14,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // Placeholder view when Reporting tab is selected
  Widget _buildReportingComingSoonView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: JoynColors.iconBackground,
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Icon(
              Icons.analytics_outlined,
              size: 32,
              color: JoynColors.primary,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Reporting Coming Soon',
            style: JoynTypography.titleMedium.copyWith(
              fontSize: 20,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Advanced analytics & financial reporting will be available soon.',
            style: JoynTypography.subtitle.copyWith(
              fontSize: 14,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // Helper widget to build a section card
  Widget _buildDashboardSectionCard({
    required IconData mainIcon,
    required String title,
    required String subtitle,
    required List<Widget> actionButtons,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: JoynColors.background,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: JoynColors.border, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Header Row
          Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: JoynColors.iconBackground,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  mainIcon,
                  color: JoynColors.primary,
                  size: 22,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: JoynTypography.bodyLarge.copyWith(
                        fontWeight: FontWeight.w700,
                        fontSize: 17,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: JoynTypography.subtitle.copyWith(
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              // Circular Black Right Arrow
              Container(
                width: 34,
                height: 34,
                decoration: const BoxDecoration(
                  color: JoynColors.primary,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.arrow_forward_rounded,
                  color: Colors.white,
                  size: 18,
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Sub-Action Grid Buttons Row
          Row(
            children: [
              for (int i = 0; i < actionButtons.length; i++) ...[
                actionButtons[i],
                if (i < actionButtons.length - 1) const SizedBox(width: 10),
              ],
            ],
          ),
        ],
      ),
    );
  }

  // Helper widget to build individual sub-action grid button
  Widget _buildGridActionButton({
    required IconData icon,
    required String title,
    int flex = 1,
  }) {
    return Expanded(
      flex: flex,
      child: Container(
        height: 60,
        decoration: BoxDecoration(
          color: JoynColors.background,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: JoynColors.border, width: 1),
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(14),
          child: InkWell(
            onTap: () {
              // Action handler
            },
            borderRadius: BorderRadius.circular(14),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    icon,
                    size: 18,
                    color: JoynColors.primary,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    title,
                    style: JoynTypography.caption.copyWith(
                      fontWeight: FontWeight.w600,
                      color: JoynColors.primary,
                      fontSize: 11.5,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
