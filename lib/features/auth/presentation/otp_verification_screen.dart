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
    _initAutoFill();
  }

  void _initAutoFill() {
    listenForCode();
  }

  @override
  void codeUpdated() {
    if (code != null && code!.isNotEmpty) {
      final digits = code!.replaceAll(RegExp(r'\D'), '');
      if (digits.length >= 4) {
        final otp4 = digits.substring(0, 4);
        setState(() {
          _enteredCode = otp4;
        });
        _verifyOtp();
      }
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

    final res = await ref.read(authProvider.notifier).verifyOtpApi(_enteredCode);

    if (mounted) {
      setState(() {
        _isVerifying = false;
      });
      if (res['success'] == true) {
        context.push('/company-selection');
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(res['message'] ?? 'OTP verification failed')),
        );
      }
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
                'Enter the 4-digit code sent to\n${authState.phoneNumber}',
                style: JoynTypography.subtitle.copyWith(
                  height: 1.4,
                ),
              ),

              const SizedBox(height: 36),

              // 4-digit OTP Box with Auto Read support
              JoynOtpInput(
                length: 4,
                value: _enteredCode,
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
                        onPressed: () async {
                          ref.read(authProvider.notifier).startOtpTimer();
                          await ref.read(authProvider.notifier).sendOtpApi(authState.phoneNumber);
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
