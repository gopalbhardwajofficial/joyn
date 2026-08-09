import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/joyn_colors.dart';
import '../../../core/theme/joyn_typography.dart';
import '../../../core/widgets/joyn_button.dart';
import '../../../core/widgets/joyn_logo.dart';
import '../providers/auth_provider.dart';

class PhonePickerBottomSheet extends ConsumerWidget {
  const PhonePickerBottomSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);

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
        bottom: MediaQuery.of(context).padding.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag handle
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

          // Header Row with JOYN logo & Language Chip
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const JoynLogo(size: 24),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: JoynColors.chipBackground,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: JoynColors.border, width: 1),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.language_rounded,
                      size: 14,
                      color: JoynColors.primary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'EN',
                      style: JoynTypography.caption.copyWith(
                        fontWeight: FontWeight.w600,
                        color: JoynColors.primary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 28),

          // Subtitle
          Text(
            'Continue as',
            style: JoynTypography.subtitle.copyWith(
              fontSize: 14,
              color: JoynColors.secondaryText,
            ),
          ),

          const SizedBox(height: 6),

          // Large Phone Number
          Text(
            authState.phoneNumber,
            style: JoynTypography.heading.copyWith(
              fontSize: 26,
              fontWeight: FontWeight.w700,
            ),
          ),

          const SizedBox(height: 4),

          // User Name
          Text(
            authState.userName,
            style: JoynTypography.bodyMedium.copyWith(
              color: JoynColors.secondaryText,
              fontSize: 14,
            ),
          ),

          const SizedBox(height: 32),

          // Continue Button
          JoynButton(
            text: 'Continue',
            variant: JoynButtonVariant.filled,
            onPressed: () {
              Navigator.of(context).pop();
              ref.read(authProvider.notifier).startOtpTimer();
              context.push('/otp');
            },
          ),

          const SizedBox(height: 12),

          // Use Another Method Button
          Center(
            child: JoynButton(
              text: 'Use Another Method',
              variant: JoynButtonVariant.text,
              onPressed: () {
                Navigator.of(context).pop();
                context.push('/manual-login');
              },
            ),
          ),
        ],
      ),
    );
  }
}
