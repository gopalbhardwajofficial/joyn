import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/joyn_colors.dart';
import '../../../core/theme/joyn_typography.dart';
import '../../../core/widgets/joyn_button.dart';
import '../../auth/providers/auth_provider.dart';

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

  final FocusNode _nameFocusNode = FocusNode();
  final FocusNode _businessNameFocusNode = FocusNode();
  final FocusNode _emailFocusNode = FocusNode();

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
    _nameFocusNode.dispose();
    _businessNameFocusNode.dispose();
    _emailFocusNode.dispose();
    super.dispose();
  }

  void _submit(bool isSkip) {
    if (!isSkip) {

      if (_businessNameController.text.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline_rounded, color: Colors.white, size: 20),
                const SizedBox(width: 10),
                Text(
                  'Business name is required',
                  style: JoynTypography.bodyMedium.copyWith(
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
            behavior: SnackBarBehavior.floating,
            backgroundColor: JoynColors.error,
            margin: const EdgeInsets.all(16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            duration: const Duration(seconds: 2),
          ),
        );
        return;
      }

      HapticFeedback.mediumImpact();
      ref.read(authProvider.notifier).updateBusinessInfo(
        name: _nameController.text.trim(),
        businessName: _businessNameController.text.trim(),
        email: _emailController.text.trim(),
      );
    } else {
      HapticFeedback.selectionClick();
    }

    Navigator.of(context).pop();
    context.push('/dashboard');
  }

  Widget _buildLabeledInputField({
    required String label,
    required String hintText,
    required TextEditingController controller,
    required FocusNode focusNode,
    TextInputType keyboardType = TextInputType.text,
    IconData? icon,
    bool isRequired = false,
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [

        Row(
          children: [
            Text(
              label,
              style: JoynTypography.bodyMedium.copyWith(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: JoynColors.secondaryText,
              ),
            ),
            if (isRequired) ...[
              const SizedBox(width: 2),
              Text(
                '*',
                style: JoynTypography.bodyMedium.copyWith(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: JoynColors.error,
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 6),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: focusNode.hasFocus
                  ? JoynColors.primary
                  : JoynColors.border,
              width: 1.2,
            ),
            boxShadow: _Premium.fieldShadow,
          ),
          child: Row(
            crossAxisAlignment: maxLines > 1
                ? CrossAxisAlignment.start
                : CrossAxisAlignment.center,
            children: [
              if (icon != null) ...[
                Padding(
                  padding: EdgeInsets.only(left: 14, top: maxLines > 1 ? 14 : 0),
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: JoynColors.primary.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(icon, size: 16, color: JoynColors.primary),
                  ),
                ),
                const SizedBox(width: 10),
              ],
              Expanded(
                child: TextField(
                  controller: controller,
                  focusNode: focusNode,
                  keyboardType: keyboardType,
                  maxLines: maxLines,
                  style: JoynTypography.bodyLarge.copyWith(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: JoynColors.primary,
                  ),
                  decoration: InputDecoration(
                    hintText: hintText,
                    hintStyle: JoynTypography.bodyLarge.copyWith(
                      color: JoynColors.secondaryText.withValues(alpha: 0.5),
                      fontSize: 14.5,
                      fontWeight: FontWeight.w500,
                    ),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: icon != null ? 0 : 14,
                      vertical: maxLines > 1 ? 14 : 0,
                    ),
                    border: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    isDense: true,
                  ),
                  onSubmitted: (_) {
                    if (controller == _nameController) {
                      _businessNameFocusNode.requestFocus();
                    } else if (controller == _businessNameController) {
                      _emailFocusNode.requestFocus();
                    } else {
                      _submit(false);
                    }
                  },
                ),
              ),
              if (controller.text.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: InkWell(
                    onTap: () {
                      HapticFeedback.lightImpact();
                      setState(() {
                        controller.clear();
                      });
                    },
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      width: 22,
                      height: 22,
                      decoration: const BoxDecoration(
                        color: JoynColors.secondaryText,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.close_rounded,
                        size: 14,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
            ],
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
      decoration: BoxDecoration(
        gradient: _Premium.surfaceGradient,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 30,
            offset: const Offset(0, -10),
          ),
        ],
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
            Center(
              child: Container(
                width: 42,
                height: 5,
                decoration: BoxDecoration(
                  color: const Color(0xFFD1D5DB),
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            const SizedBox(height: 20),

            Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    gradient: _Premium.gradient(JoynColors.primary),
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: _Premium.chipShadow(JoynColors.primary),
                  ),
                  child: const Icon(
                    Icons.storefront_rounded,
                    size: 24,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Set up your business',
                        style: JoynTypography.titleMedium.copyWith(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.2,
                          color: JoynColors.primary,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        'Tell us about your business',
                        style: JoynTypography.subtitle.copyWith(
                          fontSize: 13,
                          color: JoynColors.secondaryText,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            _buildLabeledInputField(
              label: 'Name',
              hintText: 'Enter your name',
              controller: _nameController,
              focusNode: _nameFocusNode,
              icon: Icons.person_outline_rounded,
              isRequired: false,
            ),

            const SizedBox(height: 16),

            _buildLabeledInputField(
              label: 'Business Name',
              hintText: 'Enter your business name',
              controller: _businessNameController,
              focusNode: _businessNameFocusNode,
              icon: Icons.storefront_outlined,
              isRequired: true,
            ),

            const SizedBox(height: 16),

            _buildLabeledInputField(
              label: 'Email',
              hintText: 'Enter your email address',
              controller: _emailController,
              focusNode: _emailFocusNode,
              keyboardType: TextInputType.emailAddress,
              icon: Icons.email_outlined,
              isRequired: false,
            ),

            const SizedBox(height: 28),

            Container(
              decoration: BoxDecoration(
                gradient: _Premium.gradient(JoynColors.primary),
                borderRadius: BorderRadius.circular(18),
                boxShadow: _Premium.floatingShadow(JoynColors.primary),
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(18),
                  onTap: () => _submit(false),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.arrow_forward_rounded,
                          color: Colors.white,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Save & Continue',
                          style: JoynTypography.buttonText.copyWith(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                            letterSpacing: 0.2,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 12),

            Center(
              child: TextButton(
                onPressed: () => _submit(true),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Skip for Now',
                      style: JoynTypography.bodyMedium.copyWith(
                        fontWeight: FontWeight.w700,
                        color: JoynColors.secondaryText,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(
                      Icons.arrow_forward_rounded,
                      size: 16,
                      color: JoynColors.secondaryText,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}