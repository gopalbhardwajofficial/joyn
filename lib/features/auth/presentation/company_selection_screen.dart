import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/joyn_colors.dart';
import '../../../core/theme/joyn_typography.dart';
import '../providers/auth_provider.dart';

class _Premium {
  static List<BoxShadow> cardShadow = [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.05),
      blurRadius: 20,
      offset: const Offset(0, 8),
    ),
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.025),
      blurRadius: 4,
      offset: const Offset(0, 1),
    ),
  ];

  static List<BoxShadow> fieldShadow = [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.035),
      blurRadius: 10,
      offset: const Offset(0, 3),
    ),
  ];

  static List<BoxShadow> chipShadow(Color color) => [
    BoxShadow(
      color: color.withValues(alpha: 0.28),
      blurRadius: 14,
      offset: const Offset(0, 6),
    ),
  ];

  static List<BoxShadow> floatingShadow(Color color) => [
    BoxShadow(
      color: color.withValues(alpha: 0.35),
      blurRadius: 16,
      offset: const Offset(0, 6),
    ),
  ];

  static LinearGradient gradient(Color color) => LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      color,
      Color.lerp(color, Colors.black, 0.18) ?? color,
    ],
  );

  static LinearGradient surfaceGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Colors.white,
      JoynColors.background,
    ],
  );
}

class CompanySelectionScreen extends ConsumerStatefulWidget {
  const CompanySelectionScreen({super.key});

  @override
  ConsumerState<CompanySelectionScreen> createState() =>
      _CompanySelectionScreenState();
}

class _CompanySelectionScreenState
    extends ConsumerState<CompanySelectionScreen> {
  void _handleExistingCompanySelect(
      BuildContext context, WidgetRef ref, String companyName) {
    HapticFeedback.selectionClick();
    ref.read(authProvider.notifier).selectCompany(companyName);
    context.push('/dashboard');
  }

  void _handleCreateNewBusiness(BuildContext context, WidgetRef ref) {
    HapticFeedback.selectionClick();
    context.push('/dashboard?autoShowSetup=true');
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final businesses = authState.createdBusinesses;

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
            child: const Icon(
              Icons.arrow_back_rounded,
              size: 18,
              color: JoynColors.secondaryText,
            ),
          ),
          onPressed: () => context.pop(),
        ),
        centerTitle: true,
        title: Text(
          'Choose Company',
          style: JoynTypography.titleMedium.copyWith(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.2,
            color: JoynColors.primary,
          ),
        ),
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
                children: [

                  Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          gradient: _Premium.gradient(JoynColors.primary),
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: _Premium.chipShadow(JoynColors.primary),
                        ),
                        child: const Icon(
                          Icons.business_center_rounded,
                          size: 20,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Select Company',
                              style: JoynTypography.titleMedium.copyWith(
                                fontSize: 22,
                                fontWeight: FontWeight.w800,
                                letterSpacing: -0.2,
                                color: JoynColors.primary,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Choose a company to continue or create a new one',
                              style: JoynTypography.subtitle.copyWith(
                                fontSize: 13,
                                height: 1.4,
                                color: JoynColors.secondaryText,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 28),

                  if (businesses.isNotEmpty) ...[
                    _buildSectionHeader(
                      1,
                      'Your Businesses',
                      Icons.work_outline_rounded,
                    ),
                    const SizedBox(height: 16),
                  ],

                  ...businesses.map((company) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 14),
                      child: _buildBusinessCard(
                        context: context,
                        ref: ref,
                        companyName: company,
                      ),
                    );
                  }),

                  if (businesses.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: Container(
                            height: 1,
                            color: JoynColors.border,
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: Text(
                            'OR',
                            style: JoynTypography.caption.copyWith(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: JoynColors.secondaryText,
                              letterSpacing: 1,
                            ),
                          ),
                        ),
                        Expanded(
                          child: Container(
                            height: 1,
                            color: JoynColors.border,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                  ],

                  if (businesses.isNotEmpty) ...[
                    _buildSectionHeader(
                      2,
                      'Create New',
                      Icons.add_circle_outline_rounded,
                    ),
                    const SizedBox(height: 16),
                  ],

                  _buildCreateNewBusinessCard(
                    context: context,
                    ref: ref,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }


  Widget _buildSectionHeader(int number, String title, IconData icon) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 30,
              height: 30,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                gradient: _Premium.gradient(Colors.black87),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.22),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Text(
                '$number',
                style: JoynTypography.caption.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 13,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Icon(icon, size: 17, color: JoynColors.primary),
            const SizedBox(width: 6),
            Text(
              title,
              style: JoynTypography.bodyLarge.copyWith(
                fontWeight: FontWeight.w800,
                fontSize: 17,
                letterSpacing: -0.2,
                color: JoynColors.primary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          height: 1.2,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                JoynColors.border,
                JoynColors.border.withValues(alpha: 0.0),
              ],
            ),
          ),
        ),
      ],
    );
  }



  Widget _buildBusinessCard({
    required BuildContext context,
    required WidgetRef ref,
    required String companyName,
  }) {
    return Container(
      decoration: BoxDecoration(
        gradient: _Premium.surfaceGradient,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: JoynColors.border,
          width: 1.2,
        ),
        boxShadow: _Premium.cardShadow,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () {
            HapticFeedback.lightImpact();
            _handleExistingCompanySelect(context, ref, companyName);
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
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
                    companyName.isNotEmpty
                        ? companyName[0].toUpperCase()
                        : '?',
                    style: JoynTypography.titleMedium.copyWith(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: JoynColors.primary,
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        companyName,
                        style: JoynTypography.bodyLarge.copyWith(
                          fontSize: 15.5,
                          fontWeight: FontWeight.w700,
                          color: JoynColors.primary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: JoynColors.chipBackground,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          'Business',
                          style: JoynTypography.caption.copyWith(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w700,
                            color: JoynColors.secondaryText,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: JoynColors.chipBackground,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.arrow_forward_rounded,
                    size: 16,
                    color: JoynColors.secondaryText,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }


  Widget _buildCreateNewBusinessCard({
    required BuildContext context,
    required WidgetRef ref,
  }) {
    return Container(
      decoration: BoxDecoration(
        gradient: _Premium.gradient(JoynColors.primary),
        borderRadius: BorderRadius.circular(20),
        boxShadow: _Premium.floatingShadow(JoynColors.primary),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () {
            HapticFeedback.mediumImpact();
            _handleCreateNewBusiness(context, ref);
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  alignment: Alignment.center,
                  child: const Icon(
                    Icons.add_rounded,
                    size: 26,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Create New Business',
                        style: JoynTypography.bodyLarge.copyWith(
                          fontSize: 15.5,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Start fresh with a new company',
                        style: JoynTypography.caption.copyWith(
                          fontSize: 12,
                          color: Colors.white.withValues(alpha: 0.8),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.arrow_forward_rounded,
                    size: 16,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}