import 'package:flutter/material.dart';
import '../theme/joyn_colors.dart';
import '../theme/joyn_typography.dart';

enum PaymentMode { credit, cash }

class JoynPaymentModeToggle extends StatelessWidget {
  final PaymentMode value;
  final ValueChanged<PaymentMode> onChanged;

  const JoynPaymentModeToggle({
    super.key,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 32,
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: JoynColors.chipBackground,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _segment('Credit', PaymentMode.credit),
          _segment('Cash', PaymentMode.cash),
        ],
      ),
    );
  }

  Widget _segment(String label, PaymentMode mode) {
    final bool isSelected = value == mode;
    return InkWell(
      onTap: () => onChanged(mode),
      borderRadius: BorderRadius.circular(16),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? JoynColors.success : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          label,
          style: JoynTypography.caption.copyWith(
            fontSize: 12.5,
            fontWeight: FontWeight.w700,
            color: isSelected ? Colors.white : JoynColors.secondaryText,
          ),
        ),
      ),
    );
  }
}