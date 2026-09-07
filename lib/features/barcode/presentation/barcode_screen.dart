import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../../core/theme/joyn_colors.dart';
import '../../../core/theme/joyn_typography.dart';

class _Premium {
  static List<BoxShadow> chipShadow(Color color) => [
    BoxShadow(
      color: color.withValues(alpha: 0.32),
      blurRadius: 14,
      offset: const Offset(0, 6),
    ),
  ];

  static LinearGradient gradient(Color color) => LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      color,
      Color.lerp(color, Colors.black, 0.18) ?? color,
    ],
  );
}

class AddBarcodeScreen extends StatefulWidget {
  const AddBarcodeScreen({super.key});

  @override
  State<AddBarcodeScreen> createState() => _AddBarcodeScreenState();
}

class _AddBarcodeScreenState extends State<AddBarcodeScreen>
    with WidgetsBindingObserver {
  late final MobileScannerController _controller;
  final ImagePicker _imagePicker = ImagePicker();

  bool _torchOn = false;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _controller = MobileScannerController(
      detectionSpeed: DetectionSpeed.noDuplicates,
      facing: CameraFacing.back,
      torchEnabled: false,
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!_controller.value.isInitialized) return;
    switch (state) {
      case AppLifecycleState.resumed:
        _controller.start();
        break;
      case AppLifecycleState.inactive:
      case AppLifecycleState.paused:
        _controller.stop();
        break;
      default:
        break;
    }
  }

  void _onDetect(BarcodeCapture capture) {
    if (_isProcessing) return;
    final barcodes = capture.barcodes;
    if (barcodes.isEmpty) return;

    final String? value = barcodes.first.rawValue;
    if (value == null || value.isEmpty) return;

    _isProcessing = true;
    _controller.stop();
    HapticFeedback.lightImpact();
    _goToLabelEditor(value);
  }

  void _goToLabelEditor(String scannedValue) {
    context.pushReplacement('/label-editor', extra: scannedValue);
  }

  Future<void> _toggleTorch() async {
    await _controller.toggleTorch();
    setState(() => _torchOn = !_torchOn);
  }

  Future<void> _scanFromGallery() async {
    final XFile? picked =
    await _imagePicker.pickImage(source: ImageSource.gallery);
    if (picked == null) return;

    final BarcodeCapture? capture =
    await _controller.analyzeImage(picked.path);

    if (!mounted) return;

    if (capture != null && capture.barcodes.isNotEmpty) {
      final value = capture.barcodes.first.rawValue;
      if (value != null && value.isNotEmpty) {
        _goToLabelEditor(value);
        return;
      }
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('No barcode/QR code found in the selected image'),
        behavior: SnackBarBehavior.floating,
        backgroundColor: JoynColors.error,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final double boxSize = size.width * 0.62;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: JoynColors.background,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: JoynColors.chipBackground,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.arrow_back_rounded, size: 18, color: JoynColors.primary),
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Scan',
          style: JoynTypography.titleMedium.copyWith(
            fontWeight: FontWeight.w800,
            fontSize: 18,
            color: JoynColors.primary,
          ),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Expanded(
            child: Stack(
              fit: StackFit.expand,
              children: [

                MobileScanner(
                  controller: _controller,
                  onDetect: _onDetect,
                  scanWindow: Rect.fromCenter(
                    center: Offset(size.width / 2,
                        (size.height * 0.62) / 2),
                    width: boxSize,
                    height: boxSize,
                  ),
                  errorBuilder: (context, error, child) {
                    return _CameraErrorView(error: error);
                  },
                ),

                _ScannerOverlay(boxSize: boxSize),

                Center(
                  child: SizedBox(
                    width: boxSize,
                    height: boxSize,
                    child: CustomPaint(
                      painter: _CornerPainter(color: JoynColors.primary),
                    ),
                  ),
                ),

                Positioned(
                  top: (size.height * 0.62) / 2 + boxSize / 2 + 74,
                  left: 32,
                  right: 32,
                  child: Text(
                    'Place the QR code/barcode in the box to scan\nautomatically',
                    textAlign: TextAlign.center,
                    style: JoynTypography.bodyMedium.copyWith(
                      color: Colors.white,
                      fontSize: 14.5,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),

          Container(
            color: JoynColors.background,
            padding: const EdgeInsets.symmetric(vertical: 22, horizontal: 60),
            child: SafeArea(
              top: false,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _BottomIconButton(
                    icon: _torchOn
                        ? Icons.flash_on_rounded
                        : Icons.flash_on_outlined,
                    active: _torchOn,
                    onTap: _toggleTorch,
                  ),
                  _BottomIconButton(
                    icon: Icons.photo_size_select_actual_outlined,
                    active: false,
                    onTap: _scanFromGallery,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ScannerOverlay extends StatelessWidget {
  final double boxSize;
  const _ScannerOverlay({required this.boxSize});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return ClipPath(
          clipper: _HoleClipper(boxSize: boxSize),
          child: Container(color: Colors.black.withValues(alpha: 0.55)),
        );
      },
    );
  }
}

class _HoleClipper extends CustomClipper<Path> {
  final double boxSize;
  _HoleClipper({required this.boxSize});

  @override
  Path getClip(Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final outer = Path()..addRect(Rect.fromLTWH(0, 0, size.width, size.height));
    final hole = Path()
      ..addRRect(RRect.fromRectAndRadius(
        Rect.fromCenter(center: center, width: boxSize, height: boxSize),
        const Radius.circular(18),
      ));
    return Path.combine(PathOperation.difference, outer, hole);
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}

class _CornerPainter extends CustomPainter {
  final Color color;
  _CornerPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 4.5
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    const double len = 28;

    canvas.drawLine(const Offset(0, 0), const Offset(len, 0), paint);
    canvas.drawLine(const Offset(0, 0), const Offset(0, len), paint);
    canvas.drawLine(Offset(size.width, 0), Offset(size.width - len, 0), paint);
    canvas.drawLine(Offset(size.width, 0), Offset(size.width, len), paint);
    canvas.drawLine(Offset(0, size.height), Offset(len, size.height), paint);
    canvas.drawLine(Offset(0, size.height), Offset(0, size.height - len), paint);
    canvas.drawLine(Offset(size.width, size.height),
        Offset(size.width - len, size.height), paint);
    canvas.drawLine(Offset(size.width, size.height),
        Offset(size.width, size.height - len), paint);
  }

  @override
  bool shouldRepaint(covariant _CornerPainter oldDelegate) => false;
}

class _BottomIconButton extends StatelessWidget {
  final IconData icon;
  final bool active;
  final VoidCallback onTap;

  const _BottomIconButton({
    required this.icon,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          HapticFeedback.lightImpact();
          onTap();
        },
        borderRadius: BorderRadius.circular(16),
        child: Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            gradient: active ? _Premium.gradient(JoynColors.primary) : null,
            color: active ? null : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: active
                ? null
                : Border.all(color: JoynColors.border, width: 1.2),
            boxShadow: active
                ? _Premium.chipShadow(JoynColors.primary)
                : [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.06),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Icon(
            icon,
            color: active ? Colors.white : JoynColors.primary,
            size: 22,
          ),
        ),
      ),
    );
  }
}

class _CameraErrorView extends StatelessWidget {
  final MobileScannerException error;
  const _CameraErrorView({required this.error});

  @override
  Widget build(BuildContext context) {
    String message;
    switch (error.errorCode) {
      case MobileScannerErrorCode.permissionDenied:
        message = 'Camera permission is required to scan.\n'
            'Please enable it from app settings.';
        break;
      default:
        message = 'Unable to start the camera.\n${error.errorDetails?.message ?? ''}';
    }
    return Container(
      color: Colors.black,
      alignment: Alignment.center,
      padding: const EdgeInsets.all(24),
      child: Text(
        message,
        textAlign: TextAlign.center,
        style: const TextStyle(color: Colors.white, fontSize: 14),
      ),
    );
  }
}