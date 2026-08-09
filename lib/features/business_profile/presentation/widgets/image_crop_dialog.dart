import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:path_provider/path_provider.dart';
import '../../../../core/theme/joyn_colors.dart';
import '../../../../core/theme/joyn_typography.dart';
import '../../../../core/widgets/joyn_button.dart';

class ImageCropDialog extends StatefulWidget {
  final String imagePath;
  final String title;

  const ImageCropDialog({
    super.key,
    required this.imagePath,
    this.title = 'Crop & Adjust Image',
  });

  @override
  State<ImageCropDialog> createState() => _ImageCropDialogState();
}

class _ImageCropDialogState extends State<ImageCropDialog> {
  final TransformationController _transformationController =
      TransformationController();
  final GlobalKey _cropAreaKey = GlobalKey();

  Future<void> _performCrop() async {
    try {
      final boundary = _cropAreaKey.currentContext?.findRenderObject()
          as RenderRepaintBoundary?;
      if (boundary != null) {
        final ui.Image image = await boundary.toImage(pixelRatio: 2.5);
        final ByteData? byteData =
            await image.toByteData(format: ui.ImageByteFormat.png);

        if (byteData != null) {
          final tempDir = await getTemporaryDirectory();
          final file = File(
              '${tempDir.path}/cropped_${DateTime.now().millisecondsSinceEpoch}.png');
          await file.writeAsBytes(byteData.buffer.asUint8List());

          if (mounted) {
            Navigator.of(context).pop(file.path);
            return;
          }
        }
      }
    } catch (_) {}

    if (mounted) {
      Navigator.of(context).pop(widget.imagePath);
    }
  }

  @override
  void dispose() {
    _transformationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: JoynColors.background,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
      ),
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  widget.title,
                  style: JoynTypography.titleMedium.copyWith(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close_rounded, size: 22),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),

            const SizedBox(height: 4),

            Text(
              'Pinch to zoom and drag to position image inside crop box',
              style: JoynTypography.subtitle.copyWith(fontSize: 12.5),
            ),

            const SizedBox(height: 16),

            // Interactive Crop Box Container with Crop Handle Grid
            RepaintBoundary(
              key: _cropAreaKey,
              child: Container(
                height: 220,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: JoynColors.primary, width: 2),
                ),
                child: Stack(
                  children: [
                    // Interactive Zoom & Pan Image Layer
                    ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: InteractiveViewer(
                        transformationController: _transformationController,
                        minScale: 0.5,
                        maxScale: 4.0,
                        child: Center(
                          child: Image.file(
                            File(widget.imagePath),
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),
                    ),

                    // Crop Grid Guidelines Overlay
                    IgnorePointer(
                      child: CustomPaint(
                        size: Size.infinite,
                        painter: _CropGridOverlayPainter(),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Crop & Apply Button
            JoynButton(
              text: 'Crop & Apply',
              variant: JoynButtonVariant.filled,
              onPressed: _performCrop,
            ),
          ],
        ),
      ),
    );
  }
}

// Crop Grid Lines & Corner Handles Painter
class _CropGridOverlayPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final linePaint = Paint()
      ..color = JoynColors.primary.withValues(alpha: 0.3)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    final handlePaint = Paint()
      ..color = JoynColors.primary
      ..strokeWidth = 3.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    // Draw 3x3 Grid Lines
    canvas.drawLine(Offset(size.width / 3, 0), Offset(size.width / 3, size.height), linePaint);
    canvas.drawLine(Offset(size.width * 2 / 3, 0), Offset(size.width * 2 / 3, size.height), linePaint);
    canvas.drawLine(Offset(0, size.height / 3), Offset(size.width, size.height / 3), linePaint);
    canvas.drawLine(Offset(0, size.height * 2 / 3), Offset(size.width, size.height * 2 / 3), linePaint);

    const handleLength = 16.0;

    // Top-Left Corner Handle
    canvas.drawLine(const Offset(0, 0), const Offset(handleLength, 0), handlePaint);
    canvas.drawLine(const Offset(0, 0), const Offset(0, handleLength), handlePaint);

    // Top-Right Corner Handle
    canvas.drawLine(Offset(size.width, 0), Offset(size.width - handleLength, 0), handlePaint);
    canvas.drawLine(Offset(size.width, 0), Offset(size.width, handleLength), handlePaint);

    // Bottom-Left Corner Handle
    canvas.drawLine(Offset(0, size.height), Offset(handleLength, size.height), handlePaint);
    canvas.drawLine(Offset(0, size.height), Offset(0, size.height - handleLength), handlePaint);

    // Bottom-Right Corner Handle
    canvas.drawLine(Offset(size.width, size.height), Offset(size.width - handleLength, size.height), handlePaint);
    canvas.drawLine(Offset(size.width, size.height), Offset(size.width, size.height - handleLength), handlePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
