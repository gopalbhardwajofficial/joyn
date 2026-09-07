import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/joyn_colors.dart';
import '../../../core/theme/joyn_typography.dart';
import '../../../core/widgets/joyn_button.dart';
import '../../../core/widgets/joyn_text_field.dart';
import '../providers/auth_provider.dart';

class ManualLoginScreen extends ConsumerStatefulWidget {
  const ManualLoginScreen({super.key});

  @override
  ConsumerState<ManualLoginScreen> createState() => _ManualLoginScreenState();
}

class _ManualLoginScreenState extends ConsumerState<ManualLoginScreen> {
  final TextEditingController _phoneController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _phoneController.text = '81308 20030';
  }

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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


              Text(
                'Sign in',
                style: JoynTypography.heading.copyWith(
                  fontSize: 28,
                ),
              ),

              const SizedBox(height: 8),

              Text(
                'Enter your mobile number to continue',
                style: JoynTypography.subtitle,
              ),

              const SizedBox(height: 32),


              JoynPhoneTextField(
                controller: _phoneController,
                onChanged: (val) {
                  ref.read(authProvider.notifier).setPhoneNumber('+91 $val');
                },
              ),

              const SizedBox(height: 20),


              JoynButton(
                text: 'Continue',
                variant: JoynButtonVariant.filled,
                onPressed: () {
                  ref.read(authProvider.notifier).startOtpTimer();
                  context.push('/otp');
                },
              ),

              const SizedBox(height: 28),

              Row(
                children: [
                  const Expanded(
                    child: Divider(color: JoynColors.border, thickness: 1),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      'or',
                      style: JoynTypography.caption.copyWith(
                        color: JoynColors.secondaryText,
                        fontSize: 13,
                      ),
                    ),
                  ),
                  const Expanded(
                    child: Divider(color: JoynColors.border, thickness: 1),
                  ),
                ],
              ),

              const SizedBox(height: 28),

              JoynButton(
                text: 'Continue with Google',
                variant: JoynButtonVariant.outlined,
                leadingIcon: _GoogleIcon(),
                onPressed: () {

                },
              ),

              const Spacer(),


              Center(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: RichText(
                    textAlign: TextAlign.center,
                    text: TextSpan(
                      style: JoynTypography.caption.copyWith(
                        fontSize: 12,
                        height: 1.4,
                      ),
                      children: [
                        const TextSpan(text: 'By continuing you agree to our\n'),
                        TextSpan(
                          text: 'Terms of Service',
                          style: JoynTypography.caption.copyWith(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: JoynColors.primary,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                        const TextSpan(text: ' and '),
                        TextSpan(
                          text: 'Privacy Policy',
                          style: JoynTypography.caption.copyWith(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: JoynColors.primary,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GoogleIcon extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 20,
      height: 25,
      child: CustomPaint(
        painter: _GoogleIconPainter(),
      ),
    );
  }
}

class _GoogleIconPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final double w = size.width;
    final double h = size.height;

    final paintRed = Paint()..color = const Color(0xFFEA4335);
    final paintBlue = Paint()..color = const Color(0xFF4285F4);
    final paintGreen = Paint()..color = const Color(0xFF34A853);
    final paintYellow = Paint()..color = const Color(0xFFFBBC05);

    final pathRed = Path()
      ..moveTo(w * 0.5, h * 0.2)
      ..cubicTo(w * 0.68, h * 0.2, w * 0.81, h * 0.27, w * 0.9, h * 0.35)
      ..lineTo(w * 0.77, h * 0.48)
      ..cubicTo(w * 0.7, h * 0.41, w * 0.61, h * 0.38, w * 0.5, h * 0.38)
      ..cubicTo(w * 0.35, h * 0.38, w * 0.23, h * 0.48, w * 0.19, h * 0.62)
      ..lineTo(w * 0.05, h * 0.51)
      ..cubicTo(w * 0.12, h * 0.32, w * 0.29, h * 0.2, w * 0.5, h * 0.2);
    canvas.drawPath(pathRed, paintRed);

    final pathBlue = Path()
      ..moveTo(w * 0.95, h * 0.51)
      ..cubicTo(w * 0.95, h * 0.48, w * 0.94, h * 0.44, w * 0.94, h * 0.41)
      ..lineTo(w * 0.5, h * 0.41)
      ..lineTo(w * 0.5, h * 0.59)
      ..lineTo(w * 0.76, h * 0.59)
      ..cubicTo(w * 0.75, h * 0.66, w * 0.71, h * 0.72, w * 0.65, h * 0.76)
      ..lineTo(w * 0.79, h * 0.87)
      ..cubicTo(w * 0.89, h * 0.78, w * 0.95, h * 0.66, w * 0.95, h * 0.51);
    canvas.drawPath(pathBlue, paintBlue);

    final pathGreen = Path()
      ..moveTo(w * 0.5, h * 0.82)
      ..cubicTo(w * 0.61, h * 0.82, w * 0.7, h * 0.78, w * 0.77, h * 0.72)
      ..lineTo(w * 0.63, h * 0.61)
      ..cubicTo(w * 0.59, h * 0.64, w * 0.54, h * 0.66, w * 0.5, h * 0.66)
      ..cubicTo(w * 0.35, h * 0.66, w * 0.23, h * 0.56, w * 0.19, h * 0.42)
      ..lineTo(w * 0.05, h * 0.53)
      ..cubicTo(w * 0.12, h * 0.72, w * 0.29, h * 0.82, w * 0.5, h * 0.82);
    canvas.drawPath(pathGreen, paintGreen);

    final pathYellow = Path()
      ..moveTo(w * 0.19, h * 0.62)
      ..cubicTo(w * 0.17, h * 0.58, w * 0.16, h * 0.54, w * 0.16, h * 0.5)
      ..cubicTo(w * 0.16, h * 0.46, w * 0.17, h * 0.42, w * 0.19, h * 0.38)
      ..lineTo(w * 0.05, h * 0.27)
      ..cubicTo(w * 0.02, h * 0.34, 0, h * 0.42, 0, h * 0.5)
      ..cubicTo(0, h * 0.58, w * 0.02, h * 0.66, w * 0.05, h * 0.73)
      ..lineTo(w * 0.19, h * 0.62);
    canvas.drawPath(pathYellow, paintYellow);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
