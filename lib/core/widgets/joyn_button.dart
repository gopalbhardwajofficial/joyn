import 'package:flutter/material.dart';
import '../theme/joyn_colors.dart';
import '../theme/joyn_typography.dart';

enum JoynButtonVariant { filled, whiteFilled, outlined, text }

class JoynButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final JoynButtonVariant variant;
  final Widget? leadingIcon;
  final bool isLoading;
  final double height;
  final double borderRadius;
  final TextStyle? textStyle;

  const JoynButton({
    super.key,
    required this.text,
    this.onPressed,
    this.variant = JoynButtonVariant.filled,
    this.leadingIcon,
    this.isLoading = false,
    this.height = 56.0,
    this.borderRadius = 18.0,
    this.textStyle,
  });

  @override
  Widget build(BuildContext context) {
    if (variant == JoynButtonVariant.text) {
      return TextButton(
        onPressed: isLoading ? null : onPressed,
        style: TextButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          minimumSize: Size.zero,
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
        child: Text(
          text,
          style: textStyle ??
              JoynTypography.bodyLarge.copyWith(
                color: JoynColors.primary,
                fontWeight: FontWeight.w600,
              ),
        ),
      );
    }

    Color bgColor;
    Color textColor;
    BorderSide borderSide;

    switch (variant) {
      case JoynButtonVariant.filled:
        bgColor = JoynColors.primary;
        textColor = Colors.white;
        borderSide = BorderSide.none;
        break;
      case JoynButtonVariant.whiteFilled:
        bgColor = Colors.white;
        textColor = JoynColors.primary;
        borderSide = BorderSide.none;
        break;
      case JoynButtonVariant.outlined:
        bgColor = Colors.white;
        textColor = JoynColors.primary;
        borderSide = const BorderSide(color: JoynColors.border, width: 1.2);
        break;
      case JoynButtonVariant.text:
        bgColor = Colors.transparent;
        textColor = JoynColors.primary;
        borderSide = BorderSide.none;
        break;
    }

    return SizedBox(
      height: height,
      width: double.infinity,
      child: Material(
        color: bgColor,
        borderRadius: BorderRadius.circular(borderRadius),
        child: InkWell(
          onTap: isLoading ? null : onPressed,
          borderRadius: BorderRadius.circular(borderRadius),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(borderRadius),
              border: borderSide != BorderSide.none
                  ? Border.fromBorderSide(borderSide)
                  : null,
            ),
            child: Center(
              child: isLoading
                  ? SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        valueColor: AlwaysStoppedAnimation<Color>(textColor),
                      ),
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (leadingIcon != null) ...[
                          leadingIcon!,
                          const SizedBox(width: 10),
                        ],
                        Text(
                          text,
                          style: textStyle ??
                              JoynTypography.buttonText.copyWith(
                                color: textColor,
                              ),
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
