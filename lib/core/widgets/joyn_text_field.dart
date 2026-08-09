import 'package:flutter/material.dart';

import '../theme/joyn_colors.dart';
import '../theme/joyn_typography.dart';

class JoynPhoneTextField extends StatelessWidget {
  final TextEditingController controller;
  final String countryCode;
  final ValueChanged<String>? onCountryCodeChanged;
  final ValueChanged<String>? onChanged;

  const JoynPhoneTextField({
    super.key,
    required this.controller,
    this.countryCode = '+91',
    this.onCountryCodeChanged,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 56,
      decoration: BoxDecoration(
        color: JoynColors.background,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: JoynColors.border, width: 1.2),
      ),
      child: Row(
        children: [
          // Country picker button
          InkWell(
            onTap: () {
              // Could toggle country selector
            },
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(18),
              bottomLeft: Radius.circular(18),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Text(
                    countryCode,
                    style: JoynTypography.bodyLarge.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Icon(
                    Icons.keyboard_arrow_down_rounded,
                    size: 18,
                    color: JoynColors.secondaryText,
                  ),
                ],
              ),
            ),
          ),
          Container(
            width: 1,
            height: 24,
            color: JoynColors.border,
          ),
          // Phone Input
          Expanded(
            child: TextField(
              controller: controller,
              keyboardType: TextInputType.phone,
              onChanged: onChanged,
              style: JoynTypography.bodyLarge,
              decoration: InputDecoration(
                hintText: 'Mobile Number',
                hintStyle: JoynTypography.bodyLarge.copyWith(
                  color: JoynColors.secondaryText.withValues(alpha: 0.6),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                border: InputBorder.none,
                focusedBorder: InputBorder.none,
                enabledBorder: InputBorder.none,
                errorBorder: InputBorder.none,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
