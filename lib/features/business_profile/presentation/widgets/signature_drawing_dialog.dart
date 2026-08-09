import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import '../../../../core/theme/joyn_colors.dart';
import '../../../../core/theme/joyn_typography.dart';
import '../../../../core/widgets/joyn_button.dart';

class SignaturePoint {
  final Offset offset;
  final bool isEnd;

  SignaturePoint(this.offset, {this.isEnd = false});
}

class SignatureDrawingDialog extends StatefulWidget {
  const SignatureDrawingDialog({super.key});

  @override
  State<SignatureDrawingDialog> createState() => _SignatureDrawingDialogState();
}

class _SignatureDrawingDialogState extends State<SignatureDrawingDialog> {
  final List<SignaturePoint> _points = [];

  void _clear() {
    setState(() {
      _points.clear();
    });
  }

  void _undo() {
    if (_points.isEmpty) return;
    setState(() {
      while (_points.isNotEmpty && !_points.last.isEnd) {
        _points.removeLast();
      }
      if (_points.isNotEmpty && _points.last.isEnd) {
        _points.removeLast();
      }
    });
  }

  // Export Drawn Canvas to PNG File
  Future<void> _saveSignatureImage() async {
    if (_points.isEmpty) return;

    try {
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(
        recorder,
        Rect.fromPoints(
          const Offset(0, 0),
          const Offset(300, 150),
        ),
      );

      final painter = _SignatureCanvasPainter(_points);
      painter.paint(canvas, const Size(300, 150));

      final picture = recorder.endRecording();
      final img = await picture.toImage(300, 150);
      final ByteData? byteData =
          await img.toByteData(format: ui.ImageByteFormat.png);

      if (byteData != null) {
        final tempDir = await getTemporaryDirectory();
        final file = File(
            '${tempDir.path}/signature_${DateTime.now().millisecondsSinceEpoch}.png');
        await file.writeAsBytes(byteData.buffer.asUint8List());

        if (mounted) {
          Navigator.of(context).pop(file.path);
        }
      }
    } catch (_) {
      if (mounted) {
        Navigator.of(context).pop(true);
      }
    }
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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title Header Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Draw Signature',
                  style: JoynTypography.titleMedium.copyWith(
                    fontSize: 20,
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
              'Sign with your finger on the canvas below',
              style: JoynTypography.subtitle.copyWith(fontSize: 13),
            ),

            const SizedBox(height: 16),

            // Drawing Canvas Area
            Container(
              height: 200,
              width: double.infinity,
              decoration: BoxDecoration(
                color: JoynColors.background,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: JoynColors.border, width: 1.5),
              ),
              child: GestureDetector(
                onPanStart: (details) {
                  setState(() {
                    _points.add(SignaturePoint(details.localPosition));
                  });
                },
                onPanUpdate: (details) {
                  setState(() {
                    _points.add(SignaturePoint(details.localPosition));
                  });
                },
                onPanEnd: (details) {
                  setState(() {
                    _points.add(SignaturePoint(Offset.zero, isEnd: true));
                  });
                },
                child: CustomPaint(
                  painter: _SignatureCanvasPainter(_points),
                  size: Size.infinite,
                ),
              ),
            ),

            const SizedBox(height: 12),

            // Canvas Toolbar (Undo & Clear)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton.icon(
                  onPressed: _points.isNotEmpty ? _undo : null,
                  icon: const Icon(Icons.undo_rounded, size: 16),
                  label: const Text('Undo'),
                  style: TextButton.styleFrom(
                    foregroundColor: JoynColors.primary,
                  ),
                ),
                TextButton.icon(
                  onPressed: _points.isNotEmpty ? _clear : null,
                  icon: const Icon(Icons.delete_outline_rounded, size: 16),
                  label: const Text('Clear Canvas'),
                  style: TextButton.styleFrom(
                    foregroundColor: JoynColors.error,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // Save Signature Button
            JoynButton(
              text: 'Save Signature',
              variant: JoynButtonVariant.filled,
              onPressed: _points.isNotEmpty ? _saveSignatureImage : null,
            ),
          ],
        ),
      ),
    );
  }
}

class _SignatureCanvasPainter extends CustomPainter {
  final List<SignaturePoint> points;

  _SignatureCanvasPainter(this.points);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = JoynColors.primary
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 3.0;

    for (int i = 0; i < points.length - 1; i++) {
      if (!points[i].isEnd && !points[i + 1].isEnd) {
        canvas.drawLine(points[i].offset, points[i + 1].offset, paint);
      } else if (!points[i].isEnd && points[i + 1].isEnd) {
        canvas.drawPoints(ui.PointMode.points, [points[i].offset], paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
