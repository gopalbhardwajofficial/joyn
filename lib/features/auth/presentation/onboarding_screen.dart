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

class _OnboardingScreenState extends ConsumerState<OnboardingScreen>
    with WidgetsBindingObserver {
  VideoPlayerController? _videoController;
  bool _isVideoInitialized = false;
  bool _hasAutoTriggeredPhonePicker = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeVideo();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_hasAutoTriggeredPhonePicker && mounted) {
        _hasAutoTriggeredPhonePicker = true;
        _handlePhoneLogin();
      }
    });
  }

  Future<void> _initializeVideo() async {

    await _disposeVideoController();

    final controller = VideoPlayerController.asset('assets/JoynSplashVideo.mp4');
    _videoController = controller;

    controller
      ..setLooping(true)
      ..setVolume(0.0);

    try {
      await controller.initialize();
      if (!mounted) {

        await controller.dispose();
        return;
      }
      setState(() {
        _isVideoInitialized = true;
      });
      await controller.play();
    } catch (_) {

    }
  }

  Future<void> _disposeVideoController() async {
    final old = _videoController;
    _videoController = null;
    if (old != null) {
      try {
        await old.pause();
      } catch (_) {}
      await old.dispose();
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final controller = _videoController;
    if (controller == null || !controller.value.isInitialized) return;

    if (state == AppLifecycleState.paused || state == AppLifecycleState.inactive) {
      controller.pause();
    } else if (state == AppLifecycleState.resumed) {
      if (mounted) controller.play();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _disposeVideoController();
    super.dispose();
  }

  Future<void> _handlePhoneLogin() async {
    try {

      final String? autoNumber = await SmsAutoFill().hint;
      if (autoNumber != null && autoNumber.isNotEmpty) {
        String formatted = autoNumber;
        if (!formatted.startsWith('+')) {
          formatted = '+91 $formatted';
        }
        ref.read(authProvider.notifier).setPhoneNumber(formatted);
      }
    } catch (_) {

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

          Positioned.fill(
            child: (_isVideoInitialized && _videoController != null)
                ? SizedBox.expand(

              key: ValueKey(_videoController.hashCode),
              child: FittedBox(
                fit: BoxFit.cover,
                child: SizedBox(
                  width: _videoController!.value.size.width > 0
                      ? _videoController!.value.size.width
                      : size.width,
                  height: _videoController!.value.size.height > 0
                      ? _videoController!.value.size.height
                      : size.height,
                  child: VideoPlayer(_videoController!),
                ),
              ),
            )
                : Container(color: Colors.black),
          ),


          Positioned.fill(
            child: Container(
              color: Colors.black.withValues(alpha: 0.42),
            ),
          ),


          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

                  const JoynLogo(
                    color: Colors.white,
                    size: 26,
                  ),

                  const Spacer(),

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

                  Text(
                    'Built for growing businesses like yours.',
                    style: JoynTypography.subtitle.copyWith(
                      color: Colors.white.withValues(alpha: 0.85),
                      fontSize: 15,
                      fontWeight: FontWeight.w400,
                    ),
                  ),

                  const SizedBox(height: 44),


                  JoynButton(
                    text: 'Login with Phone Number',
                    variant: JoynButtonVariant.whiteFilled,
                    onPressed: _handlePhoneLogin,
                  ),

                  const SizedBox(height: 14),


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