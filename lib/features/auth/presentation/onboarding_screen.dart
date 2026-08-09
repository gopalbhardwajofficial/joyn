import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sms_autofill/sms_autofill.dart';
import 'package:video_player/video_player.dart';
import '../../../core/theme/joyn_typography.dart';
import '../../../core/widgets/joyn_button.dart';
import '../../../core/widgets/joyn_logo.dart';
import '../providers/auth_provider.dart';
import 'phone_picker_bottom_sheet.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  late VideoPlayerController _videoController;
  bool _isVideoInitialized = false;
  bool _hasAutoTriggeredPhonePicker = false;

  @override
  void initState() {
    super.initState();
    _videoController = VideoPlayerController.asset('assets/JoynSplashVideo.mp4')
      ..setLooping(true)
      ..setVolume(0.0)
      ..initialize().then((_) {
        if (mounted) {
          setState(() {
            _isVideoInitialized = true;
          });
          _videoController.play();
        }
      }).catchError((_) {});

    // Automatically pop-up the Phone Number bottom sheet / Credential Manager on screen launch
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_hasAutoTriggeredPhonePicker && mounted) {
        _hasAutoTriggeredPhonePicker = true;
        _handlePhoneLogin();
      }
    });
  }

  @override
  void dispose() {
    _videoController.dispose();
    super.dispose();
  }

  Future<void> _handlePhoneLogin() async {
    try {
      // Trigger native Android Phone Hint / Credential Manager popup
      final String? autoNumber = await SmsAutoFill().hint;
      if (autoNumber != null && autoNumber.isNotEmpty) {
        String formatted = autoNumber;
        if (!formatted.startsWith('+')) {
          formatted = '+91 $formatted';
        }
        ref.read(authProvider.notifier).setPhoneNumber(formatted);
      }
    } catch (_) {
      // Graceful fallback if hint picker is dismissed or unavailable
    }

    if (mounted) {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (context) => const PhonePickerBottomSheet(),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Background Video
          Positioned.fill(
            child: _isVideoInitialized
                ? SizedBox.expand(
                    child: FittedBox(
                      fit: BoxFit.cover,
                      child: SizedBox(
                        width: _videoController.value.size.width > 0
                            ? _videoController.value.size.width
                            : size.width,
                        height: _videoController.value.size.height > 0
                            ? _videoController.value.size.height
                            : size.height,
                        child: VideoPlayer(_videoController),
                      ),
                    ),
                  )
                : Container(color: Colors.black),
          ),

          // Dark Overlay (~40% Opacity)
          Positioned.fill(
            child: Container(
              color: Colors.black.withValues(alpha: 0.42),
            ),
          ),

          // Content Layer
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Top Left Logo
                  const JoynLogo(
                    color: Colors.white,
                    size: 26,
                  ),

                  const Spacer(),

                  // Center Left Premium Headline
                  Text(
                    'Every Sale.\nEvery Store.\nOne Platform.',
                    style: JoynTypography.titleLarge.copyWith(
                      color: Colors.white,
                      fontSize: 34,
                      height: 1.15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),

                  const SizedBox(height: 14),

                  // Small Subtitle
                  Text(
                    'Built for growing businesses like yours.',
                    style: JoynTypography.subtitle.copyWith(
                      color: Colors.white.withValues(alpha: 0.85),
                      fontSize: 15,
                      fontWeight: FontWeight.w400,
                    ),
                  ),

                  const SizedBox(height: 44),

                  // Primary White Button: Login with Phone Number
                  JoynButton(
                    text: 'Login with Phone Number',
                    variant: JoynButtonVariant.whiteFilled,
                    onPressed: _handlePhoneLogin,
                  ),

                  const SizedBox(height: 14),

                  // Text Button: Use Another Method
                  Center(
                    child: JoynButton(
                      text: 'Use Another Method',
                      variant: JoynButtonVariant.text,
                      textStyle: JoynTypography.bodyMedium.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w500,
                      ),
                      onPressed: () {
                        context.push('/manual-login');
                      },
                    ),
                  ),

                  const SizedBox(height: 10),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
