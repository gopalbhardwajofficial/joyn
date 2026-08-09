import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/joyn_colors.dart';
import '../../../core/theme/joyn_typography.dart';
import '../../../core/widgets/joyn_button.dart';
import '../../auth/providers/auth_provider.dart';

class BusinessSetupBottomSheet extends ConsumerStatefulWidget {
  const BusinessSetupBottomSheet({super.key});

  @override
  ConsumerState<BusinessSetupBottomSheet> createState() =>
      _BusinessSetupBottomSheetState();
}

class _BusinessSetupBottomSheetState
    extends ConsumerState<BusinessSetupBottomSheet> {
  late TextEditingController _nameController;
  late TextEditingController _businessNameController;
  late TextEditingController _emailController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _businessNameController = TextEditingController();
    _emailController = TextEditingController();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _businessNameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  void _submit(bool isSkip) {
    if (!isSkip) {
      ref.read(authProvider.notifier).updateBusinessInfo(
            name: _nameController.text.trim(),
            businessName: _businessNameController.text.trim(),
            email: _emailController.text.trim(),
          );
    }
    Navigator.of(context).pop();
    context.push('/dashboard');
  }

  Widget _buildLabeledInputField({
    required String label,
    required String hintText,
    required TextEditingController controller,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: JoynTypography.bodyMedium.copyWith(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: JoynColors.secondaryText,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          height: 52,
          decoration: BoxDecoration(
            color: JoynColors.background,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: JoynColors.border, width: 1.2),
          ),
          child: TextField(
            controller: controller,
            keyboardType: keyboardType,
            style: JoynTypography.bodyLarge.copyWith(fontSize: 15),
            decoration: InputDecoration(
              hintText: hintText,
              hintStyle: JoynTypography.bodyLarge.copyWith(
                color: JoynColors.secondaryText.withValues(alpha: 0.5),
                fontSize: 15,
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16),
              border: InputBorder.none,
              focusedBorder: InputBorder.none,
              enabledBorder: InputBorder.none,
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: JoynColors.background,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 12,
        bottom: bottomPadding + MediaQuery.of(context).padding.bottom + 20,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Drag Handle
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: JoynColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Header Title
            Text(
              'Set up your business',
              style: JoynTypography.titleMedium.copyWith(
                fontSize: 22,
                fontWeight: FontWeight.w700,
              ),
            ),

            const SizedBox(height: 4),

            // Subtitle
            Text(
              'Tell us about your business (Optional)',
              style: JoynTypography.subtitle.copyWith(
                fontSize: 14,
                color: JoynColors.secondaryText,
              ),
            ),

            const SizedBox(height: 24),

            // Field 1: Name
            _buildLabeledInputField(
              label: 'Name (Optional)',
              hintText: 'Enter your name',
              controller: _nameController,
            ),

            const SizedBox(height: 16),

            // Field 2: Business Name
            _buildLabeledInputField(
              label: 'Business Name *',
              hintText: 'Enter your business name',
              controller: _businessNameController,
            ),

            const SizedBox(height: 16),

            // Field 3: Email
            _buildLabeledInputField(
              label: 'Email (Optional)',
              hintText: 'Enter your email address',
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
            ),

            const SizedBox(height: 28),

            // Save & Continue Button
            JoynButton(
              text: 'Save & Continue',
              variant: JoynButtonVariant.filled,
              onPressed: () => _submit(false),
            ),

            const SizedBox(height: 12),

            // Skip for Now Button
            Center(
              child: JoynButton(
                text: 'Skip for Now',
                variant: JoynButtonVariant.text,
                textStyle: JoynTypography.bodyMedium.copyWith(
                  fontWeight: FontWeight.w600,
                  color: JoynColors.primary,
                ),
                onPressed: () => _submit(true),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
