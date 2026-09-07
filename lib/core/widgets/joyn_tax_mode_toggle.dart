import 'package:flutter/material.dart';
import '../theme/joyn_colors.dart';
import '../theme/joyn_typography.dart';

enum TaxModeOption { withTax, withoutTax }

class JoynTaxModeToggle extends StatelessWidget {
  final TaxModeOption value;
  final ValueChanged<TaxModeOption> onChanged;

  const JoynTaxModeToggle({
    super.key,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final bool isWithTax = value == TaxModeOption.withTax;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          isWithTax ? 'With Tax' : 'Without Tax',
          style: JoynTypography.caption.copyWith(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: isWithTax ? JoynColors.primary : JoynColors.secondaryText,
          ),
        ),
        const SizedBox(width: 6),
        Switch.adaptive(
          value: isWithTax,
          onChanged: (bool newValue) {
            onChanged(newValue ? TaxModeOption.withTax : TaxModeOption.withoutTax);
          },
          activeTrackColor: JoynColors.primary,
          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
      ],
    );
  }
}