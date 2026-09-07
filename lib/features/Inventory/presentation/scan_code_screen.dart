import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../../core/theme/joyn_colors.dart';
import '../../../core/theme/joyn_typography.dart';

class ScanCodeScreen extends StatefulWidget {
  const ScanCodeScreen({super.key});

  @override
  State<ScanCodeScreen> createState() => _ScanCodeScreenState();
}

class _ScanCodeScreenState extends State<ScanCodeScreen> with WidgetsBindingObserver {
  MobileScannerController? _controller;
  bool _isScanning = true;
  bool _isTorchOn = false;
  String? _error;
  String? _lastScanned;
  bool _isInitializing = true;
  int _retryCount = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Delay init to ensure camera is ready
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) _initScanner();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller?.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_controller == null) return;
    switch (state) {
      case AppLifecycleState.resumed:
        _controller!.start();
        break;
      case AppLifecycleState.inactive:
      case AppLifecycleState.paused:
      case AppLifecycleState.detached:
        _controller!.stop();
        break;
      case AppLifecycleState.hidden:
        break;
    }
  }

  Future<void> _initScanner() async {
    try {
      // Dispose old controller
      await _controller?.dispose();
      _controller = null;

      if (!mounted) return;

      setState(() {
        _isInitializing = true;
        _error = null;
      });

      // Create new controller
      _controller = MobileScannerController(
        formats: const [
          BarcodeFormat.qrCode,
          BarcodeFormat.code128,
          BarcodeFormat.code39,
          BarcodeFormat.ean13,
          BarcodeFormat.ean8,
          BarcodeFormat.upcA,
          BarcodeFormat.upcE,
        ],
        detectionSpeed: DetectionSpeed.noDuplicates,
        facing: CameraFacing.back,
        torchEnabled: false,
      );

      if (mounted) {
        setState(() {
          _isInitializing = false;
          _error = null;
          _retryCount = 0;
        });
      }
    } catch (e) {
      debugPrint('Scanner init error: $e');
      if (mounted) {
        setState(() {
          _isInitializing = false;
          _error = 'Unable to initialize camera. Please try again.';
        });
      }
    }
  }

  void _onDetect(BarcodeCapture capture) {
    if (!_isScanning || !mounted) return;

    final barcode = capture.barcodes.firstOrNull;
    if (barcode == null || barcode.rawValue == null) return;

    final value = barcode.rawValue!.trim();
    if (value.isEmpty) return;

    if (_lastScanned == value) return;
    _lastScanned = value;

    setState(() => _isScanning = false);

    HapticFeedback.mediumImpact();
    SystemSound.play(SystemSoundType.click);

    // Show success
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
            const SizedBox(width: 10),
            Text('Code scanned!', style: JoynTypography.bodyMedium.copyWith(fontWeight: FontWeight.w700, color: Colors.white)),
          ],
        ),
        backgroundColor: JoynColors.success,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        duration: const Duration(milliseconds: 600),
      ),
    );

    // Return after short delay
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) {
        Navigator.pop(context, value);
      }
    });
  }

  void _toggleTorch() async {
    if (_controller == null) return;
    try {
      await _controller!.toggleTorch();
      if (mounted) setState(() => _isTorchOn = !_isTorchOn);
    } catch (e) {
      debugPrint('Torch error: $e');
    }
  }

  void _switchCamera() async {
    if (_controller == null) return;
    try {
      await _controller!.switchCamera();
    } catch (e) {
      debugPrint('Switch camera error: $e');
    }
  }

  void _retry() {
    _retryCount++;
    _initScanner();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Scan Code',
          style: JoynTypography.titleMedium.copyWith(
            fontSize: 17,
            fontWeight: FontWeight.w800,
            color: Colors.white,
          ),
        ),
        actions: [
          if (_controller != null && _error == null) ...[
            IconButton(
              onPressed: _toggleTorch,
              icon: Icon(
                _isTorchOn ? Icons.flash_on_rounded : Icons.flash_off_rounded,
                color: _isTorchOn ? Colors.yellow : Colors.white,
              ),
            ),
            IconButton(
              onPressed: _switchCamera,
              icon: const Icon(Icons.flip_camera_ios_rounded, color: Colors.white, size: 20),
            ),
          ],
        ],
      ),
      body: Stack(
        children: [
          // Scanner area
          Positioned.fill(
            child: _buildScannerArea(),
          ),

          // Overlay (only when camera is ready)
          if (_error == null && !_isInitializing)
            Positioned.fill(
              child: IgnorePointer(
                child: Container(
                  color: Colors.black.withValues(alpha: 0.4),
                  child: Center(
                    child: Container(
                      width: 250,
                      height: 250,
                      decoration: BoxDecoration(
                        border: Border.all(color: JoynColors.primary, width: 3),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: JoynColors.primary.withValues(alpha: 0.3),
                            blurRadius: 20,
                            spreadRadius: 4,
                          ),
                        ],
                      ),
                      child: Stack(
                        children: [
                          // Corner markers
                          Positioned(
                            top: -1,
                            left: -1,
                            child: Container(
                              width: 30,
                              height: 30,
                              decoration: const BoxDecoration(
                                border: Border(
                                  top: BorderSide(color: Colors.white, width: 4),
                                  left: BorderSide(color: Colors.white, width: 4),
                                ),
                                borderRadius: BorderRadius.only(topLeft: Radius.circular(15)),
                              ),
                            ),
                          ),
                          Positioned(
                            top: -1,
                            right: -1,
                            child: Container(
                              width: 30,
                              height: 30,
                              decoration: const BoxDecoration(
                                border: Border(
                                  top: BorderSide(color: Colors.white, width: 4),
                                  right: BorderSide(color: Colors.white, width: 4),
                                ),
                                borderRadius: BorderRadius.only(topRight: Radius.circular(15)),
                              ),
                            ),
                          ),
                          Positioned(
                            bottom: -1,
                            left: -1,
                            child: Container(
                              width: 30,
                              height: 30,
                              decoration: const BoxDecoration(
                                border: Border(
                                  bottom: BorderSide(color: Colors.white, width: 4),
                                  left: BorderSide(color: Colors.white, width: 4),
                                ),
                                borderRadius: BorderRadius.only(bottomLeft: Radius.circular(15)),
                              ),
                            ),
                          ),
                          Positioned(
                            bottom: -1,
                            right: -1,
                            child: Container(
                              width: 30,
                              height: 30,
                              decoration: const BoxDecoration(
                                border: Border(
                                  bottom: BorderSide(color: Colors.white, width: 4),
                                  right: BorderSide(color: Colors.white, width: 4),
                                ),
                                borderRadius: BorderRadius.only(bottomRight: Radius.circular(15)),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),

          // Bottom controls
          Positioned(
            bottom: 40,
            left: 0,
            right: 0,
            child: Column(
              children: [
                if (_error == null && !_isInitializing) ...[
                  Text(
                    'Align code within the frame',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Scanning will happen automatically',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.7),
                      fontSize: 12,
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                TextButton.icon(
                  onPressed: () => _showManualEntry(context),
                  icon: const Icon(Icons.keyboard_rounded, color: Colors.white),
                  label: Text(
                    'Enter Manually',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                  ),
                  style: TextButton.styleFrom(
                    backgroundColor: Colors.white.withValues(alpha: 0.1),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScannerArea() {
    // Loading state
    if (_isInitializing) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: Colors.white),
            SizedBox(height: 16),
            Text('Starting camera...', style: TextStyle(color: Colors.white)),
          ],
        ),
      );
    }

    // Error state
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.camera_alt_outlined, color: Colors.white, size: 48),
              ),
              const SizedBox(height: 16),
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white, fontSize: 14),
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: _retry,
                icon: const Icon(Icons.refresh_rounded, size: 18),
                label: const Text('Retry Camera'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: JoynColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Camera view
    if (_controller == null) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.white),
      );
    }

    return MobileScanner(
      controller: _controller!,
      onDetect: _onDetect,
      errorBuilder: (context, error, child) {
        return Center(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, color: Colors.red, size: 48),
                const SizedBox(height: 12),
                Text(
                  'Camera error: ${error.errorCode}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: _retry,
                  icon: const Icon(Icons.refresh_rounded, size: 18),
                  label: const Text('Retry'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: JoynColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _showManualEntry(BuildContext context) async {
    final controller = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: Colors.white,
        elevation: 8,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Enter Code',
          style: JoynTypography.titleMedium.copyWith(fontSize: 18, fontWeight: FontWeight.w800),
        ),
        content: TextField(
          controller: controller,
          autofocus: true,
          keyboardType: TextInputType.text,
          decoration: InputDecoration(
            hintText: 'Enter barcode/QR code',
            filled: true,
            fillColor: JoynColors.chipBackground,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            prefixIcon: const Icon(Icons.qr_code_rounded, size: 20),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, controller.text.trim()),
            style: TextButton.styleFrom(foregroundColor: JoynColors.primary),
            child: const Text('Submit', style: TextStyle(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );

    if (result != null && result.isNotEmpty && mounted) {
      Navigator.pop(context, result);
    }
  }
}