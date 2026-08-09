import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sms_autofill/sms_autofill.dart';
import '../../../core/theme/joyn_colors.dart';
import '../../../core/theme/joyn_typography.dart';
import '../../../core/widgets/joyn_button.dart';
import '../../../core/widgets/joyn_otp_input.dart';
import '../providers/auth_provider.dart';

class OtpVerificationScreen extends ConsumerStatefulWidget {
  const OtpVerificationScreen({super.key});

  @override
  ConsumerState<OtpVerificationScreen> createState() =>
      _OtpVerificationScreenState();
}

class _OtpVerificationScreenState extends ConsumerState<OtpVerificationScreen>
    with CodeAutoFill {
  String _enteredCode = '';
  bool _isVerifying = false;

  @override
  void initState() {
    super.initState();
    listenForCode();
  }

  @override
  void codeUpdated() {
    if (code != null && code!.isNotEmpty) {
      setState(() {
        _enteredCode = code!;
      });
      _verifyOtp();
    }
  }

  @override
  void dispose() {
    cancel();
    super.dispose();
  }

  void _verifyOtp() async {
    if (_isVerifying) return;
    setState(() {
      _isVerifying = true;
    });

    // Mock verification delay for authentic feel
    await Future.delayed(const Duration(milliseconds: 300));
    await ref.read(authProvider.notifier).completeLogin();

    if (mounted) {
      context.push('/company-selection');
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);

    final String countdownText = authState.resendCountdown < 10
        ? '00:0${authState.resendCountdown}'
        : '00:${authState.resendCountdown}';

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
                'Verify Number',
                style: JoynTypography.heading.copyWith(
                  fontSize: 28,
                ),
              ),

              const SizedBox(height: 8),

              // Subtitle
              Text(
                'Enter the 6-digit code sent to\n${authState.phoneNumber}',
                style: JoynTypography.subtitle.copyWith(
                  height: 1.4,
                ),
              ),

              const SizedBox(height: 36),

              // 6-digit OTP Box with Auto Read support
              JoynOtpInput(
                length: 6,
                onChanged: (code) {
                  setState(() {
                    _enteredCode = code;
                  });
                },
                onCompleted: (code) {
                  setState(() {
                    _enteredCode = code;
                  });
                  _verifyOtp();
                },
              ),

              const SizedBox(height: 32),

              // Resend Timer
              Center(
                child: authState.isTimerRunning
                    ? Text(
                        'Resend OTP in $countdownText',
                        style: JoynTypography.caption.copyWith(
                          fontSize: 14,
                          color: JoynColors.secondaryText,
                        ),
                      )
                    : TextButton(
                        onPressed: () {
                          ref.read(authProvider.notifier).startOtpTimer();
                        },
                        child: Text(
                          'Resend OTP',
                          style: JoynTypography.bodyMedium.copyWith(
                            fontWeight: FontWeight.w600,
                            color: JoynColors.primary,
                          ),
                        ),
                      ),
              ),

              const Spacer(),

              // Verify & Continue Button
              Padding(
                padding: const EdgeInsets.only(bottom: 24),
                child: JoynButton(
                  text: _isVerifying ? 'Verifying...' : 'Verify & Continue',
                  variant: JoynButtonVariant.filled,
                  isLoading: _isVerifying,
                  onPressed: () {
                    // Accept any entered OTP (or default mock verification)
                    if (_enteredCode.isEmpty) {}
                    _verifyOtp();
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
