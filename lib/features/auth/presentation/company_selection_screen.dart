import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/joyn_colors.dart';
import '../../../core/theme/joyn_typography.dart';
import '../../../core/widgets/joyn_company_card.dart';
import '../providers/auth_provider.dart';

class CompanySelectionScreen extends ConsumerWidget {
  const CompanySelectionScreen({super.key});

  void _handleExistingCompanySelect(
      BuildContext context, WidgetRef ref, String companyName) {
    ref.read(authProvider.notifier).selectCompany(companyName);
    context.push('/dashboard');
  }

  void _handleCreateNewBusiness(BuildContext context, WidgetRef ref) {
    // Navigate to dashboard and signal to auto-open setup popup over dashboard
    context.push('/dashboard?autoShowSetup=true');
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final businesses = authState.createdBusinesses;

    return Scaffold(
      backgroundColor: JoynColors.background,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 12),

              // Heading
              Text(
                'Choose Company',
                style: JoynTypography.heading.copyWith(
                  fontSize: 28,
                ),
              ),

              const SizedBox(height: 8),

              // Subtitle
              Text(
                'Select a company to continue\nor create a new one',
                style: JoynTypography.subtitle.copyWith(
                  height: 1.4,
                ),
              ),

              const SizedBox(height: 32),

              // Dynamically render locally created business cards
              Expanded(
                child: ListView(
                  children: [
                    for (final company in businesses) ...[
                      JoynCompanyCard(
                        title: company,
                        subtitle: 'Business',
                        icon: const Icon(
                          Icons.work_outline_rounded,
                          color: JoynColors.primary,
                          size: 22,
                        ),
                        onTap: () => _handleExistingCompanySelect(
                            context, ref, company),
                      ),
                      const SizedBox(height: 16),
                    ],

                    // Always show Create New Business Card at bottom
                    JoynCompanyCard(
                      title: 'Create New Business',
                      subtitle: 'Start fresh',
                      isBlackIconContainer: true,
                      icon: const Icon(
                        Icons.add_rounded,
                        color: Colors.white,
                        size: 24,
                      ),
                      onTap: () => _handleCreateNewBusiness(context, ref),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
