import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_sign_in/google_sign_in.dart';
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
  late final TapGestureRecognizer _termsRecognizer;
  late final TapGestureRecognizer _privacyRecognizer;

  @override
  void initState() {
    super.initState();
    _phoneController.text = ''; // No hardcoded/static default values
    _termsRecognizer = TapGestureRecognizer()
      ..onTap = () => context.push('/terms-of-service');
    _privacyRecognizer = TapGestureRecognizer()
      ..onTap = () => context.push('/privacy-policy');
  }

  @override
  void dispose() {
    _termsRecognizer.dispose();
    _privacyRecognizer.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _handleGoogleSignIn() async {
    HapticFeedback.lightImpact();
    try {
      final GoogleSignIn googleSignIn = GoogleSignIn(
        serverClientId: '1031382782366-mg6d7m4nj9uk751i3o33clfcee4mnrr2.apps.googleusercontent.com',
        scopes: ['email', 'profile'],
      );

      // Sign out any cached session so the native account picker always shows device accounts
      await googleSignIn.signOut().catchError((_) => null);

      // Trigger the native system Google Account Picker
      final GoogleSignInAccount? account = await googleSignIn.signIn();

      if (account == null) {
        // User cancelled account selection
        return;
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Signing in with ${account.email}...'),
          duration: const Duration(milliseconds: 1500),
          behavior: SnackBarBehavior.floating,
        ),
      );

      final res = await ref.read(authProvider.notifier).googleLoginApi(
        email: account.email,
        displayName: account.displayName,
        photoUrl: account.photoUrl,
      );

      if (mounted) {
        if (res['success'] == true) {
          final businesses = (res['businesses'] as List?) ?? [];
          if (businesses.isNotEmpty) {
            context.go('/dashboard');
          } else {
            context.go('/company-selection');
          }
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(res['message']?.toString() ?? 'Google sign in failed. Please try again.'),
              backgroundColor: JoynColors.error,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    } catch (e) {
      if (!mounted) return;
      debugPrint('Google Sign In Error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Google Sign-In: ${e.toString()}'),
          backgroundColor: JoynColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
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
                onPressed: () async {
                  final rawPhone = _phoneController.text.trim();
                  if (rawPhone.isNotEmpty) {
                    var cleanPhone = rawPhone.replaceAll(RegExp(r'\D'), '');
                    if (cleanPhone.length == 12 && cleanPhone.startsWith('91')) {
                      cleanPhone = cleanPhone.substring(2);
                    } else if (cleanPhone.length == 11 && (cleanPhone.startsWith('0') || cleanPhone.startsWith('1'))) {
                      cleanPhone = cleanPhone.substring(1);
                    } else if (cleanPhone.length > 10) {
                      cleanPhone = cleanPhone.substring(cleanPhone.length - 10);
                    }
                    final fullPhone = cleanPhone.length == 10 ? '+91 $cleanPhone' : rawPhone;
                    await ref.read(authProvider.notifier).sendOtpApi(fullPhone);
                  }
                  if (mounted) {
                    context.push('/otp');
                  }
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
                leadingIcon: const _GoogleIcon(size: 20),
                onPressed: _handleGoogleSignIn,
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
                          recognizer: _termsRecognizer,
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
                          recognizer: _privacyRecognizer,
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
  final double size;
  const _GoogleIcon({this.size = 20});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        size: Size(size, size),
        painter: _GoogleIconPainter(),
      ),
    );
  }
}

class _GoogleIconPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final scale = size.width / 48.0;
    canvas.scale(scale, scale);

    // Official 48x48 Google 'G' geometry
    final paintBlue = Paint()..color = const Color(0xFF4285F4)..style = PaintingStyle.fill;
    final pathBlue = Path()
      ..moveTo(46.98, 24.55)
      ..cubicTo(46.98, 22.88, 46.83, 21.28, 46.55, 19.74)
      ..lineTo(24, 19.74)
      ..lineTo(24, 28.98)
      ..lineTo(36.93, 28.98)
      ..cubicTo(36.37, 31.98, 34.68, 34.52, 32.14, 36.22)
      ..lineTo(32.14, 42.24)
      ..lineTo(39.9, 42.24)
      ..cubicTo(44.44, 38.05, 46.98, 31.88, 46.98, 24.55)
      ..close();
    canvas.drawPath(pathBlue, paintBlue);

    final paintGreen = Paint()..color = const Color(0xFF34A853)..style = PaintingStyle.fill;
    final pathGreen = Path()
      ..moveTo(24, 48)
      ..cubicTo(30.48, 48, 35.91, 45.85, 39.9, 42.24)
      ..lineTo(32.14, 36.22)
      ..cubicTo(30, 37.66, 27.24, 38.53, 24, 38.53)
      ..cubicTo(17.75, 38.53, 12.46, 34.31, 10.57, 28.62)
      ..lineTo(2.57, 28.62)
      ..lineTo(2.57, 34.82)
      ..cubicTo(6.55, 42.72, 14.67, 48, 24, 48)
      ..close();
    canvas.drawPath(pathGreen, paintGreen);

    final paintYellow = Paint()..color = const Color(0xFFFBBC05)..style = PaintingStyle.fill;
    final pathYellow = Path()
      ..moveTo(10.57, 28.62)
      ..cubicTo(10.09, 27.18, 9.82, 25.62, 9.82, 24)
      ..cubicTo(9.82, 22.38, 10.09, 20.82, 10.57, 19.38)
      ..lineTo(10.57, 13.18)
      ..lineTo(2.57, 13.18)
      ..cubicTo(0.93, 16.44, 0, 20.11, 0, 24)
      ..cubicTo(0, 27.89, 0.93, 31.56, 2.57, 34.82)
      ..lineTo(10.57, 28.62)
      ..close();
    canvas.drawPath(pathYellow, paintYellow);

    final paintRed = Paint()..color = const Color(0xFFEA4335)..style = PaintingStyle.fill;
    final pathRed = Path()
      ..moveTo(24, 9.47)
      ..cubicTo(27.52, 9.47, 30.68, 10.68, 33.17, 13.06)
      ..lineTo(40.07, 6.16)
      ..cubicTo(35.89, 2.27, 30.46, 0, 24, 0)
      ..cubicTo(14.67, 0, 6.55, 5.28, 2.57, 13.18)
      ..lineTo(10.57, 19.38)
      ..cubicTo(12.46, 13.69, 17.75, 9.47, 24, 9.47)
      ..close();
    canvas.drawPath(pathRed, paintRed);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
