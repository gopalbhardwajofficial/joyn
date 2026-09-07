import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:path_provider/path_provider.dart';
import '../../../../core/theme/joyn_colors.dart';
import '../../../../core/theme/joyn_typography.dart';
import '../../../../core/widgets/joyn_button.dart';

enum _Corner { topLeft, topRight, bottomLeft, bottomRight }

enum _Edge { left, right, top, bottom }

class ImageCropDialog extends StatefulWidget {
  final String imagePath;
  final String title;


  final double? aspectRatio;


  final Size outputSize;

  const ImageCropDialog({
    super.key,
    required this.imagePath,
    this.title = 'Crop & Adjust Image',
    this.aspectRatio = 1.0,
    this.outputSize = const Size(512, 512),
  });

  @override
  State<ImageCropDialog> createState() => _ImageCropDialogState();
}

class _ImageCropDialogState extends State<ImageCropDialog> {
  final TransformationController _transformationController =
  TransformationController();
  final GlobalKey _imageBoundaryKey = GlobalKey();

  static const double _cropAreaHeight = 260;
  static const double _minCropSize = 60;

  Rect? _cropRect;
  Size? _containerSize;

  Rect _initialCropRect(Size containerSize) {
    double w, h;
    if (widget.aspectRatio != null) {
      final ratio = widget.aspectRatio!;
      final maxW = containerSize.width * 0.78;
      final maxH = containerSize.height * 0.78;
      if (maxW / ratio <= maxH) {
        w = maxW;
        h = w / ratio;
      } else {
        h = maxH;
        w = h * ratio;
      }
    } else {
      w = containerSize.width * 0.78;
      h = containerSize.height * 0.78;
    }
    final left = (containerSize.width - w) / 2;
    final top = (containerSize.height - h) / 2;
    return Rect.fromLTWH(left, top, w, h);
  }

  void _moveCropRect(Offset delta) {
    if (_cropRect == null || _containerSize == null) return;
    setState(() {
      Rect r = _cropRect!.shift(delta);
      double dx = 0, dy = 0;
      if (r.left < 0) dx = -r.left;
      if (r.right > _containerSize!.width) dx = _containerSize!.width - r.right;
      if (r.top < 0) dy = -r.top;
      if (r.bottom > _containerSize!.height) dy = _containerSize!.height - r.bottom;
      _cropRect = r.shift(Offset(dx, dy));
    });
  }


  void _resizeCorner(_Corner corner, Offset delta) {
    if (_cropRect == null || _containerSize == null) return;

    setState(() {
      final r = _cropRect!;
      double left = r.left, top = r.top, right = r.right, bottom = r.bottom;

      switch (corner) {
        case _Corner.topLeft:
          left += delta.dx;
          top += delta.dy;
          break;
        case _Corner.topRight:
          right += delta.dx;
          top += delta.dy;
          break;
        case _Corner.bottomLeft:
          left += delta.dx;
          bottom += delta.dy;
          break;
        case _Corner.bottomRight:
          right += delta.dx;
          bottom += delta.dy;
          break;
      }

      left = left.clamp(0.0, _containerSize!.width);
      top = top.clamp(0.0, _containerSize!.height);
      right = right.clamp(0.0, _containerSize!.width);
      bottom = bottom.clamp(0.0, _containerSize!.height);

      if (right - left < _minCropSize) {
        if (corner == _Corner.topLeft || corner == _Corner.bottomLeft) {
          left = right - _minCropSize;
        } else {
          right = left + _minCropSize;
        }
      }
      if (bottom - top < _minCropSize) {
        if (corner == _Corner.topLeft || corner == _Corner.topRight) {
          top = bottom - _minCropSize;
        } else {
          bottom = top + _minCropSize;
        }
      }

      if (widget.aspectRatio != null) {
        final ratio = widget.aspectRatio!;
        late Offset anchor;
        late Offset dragPoint;

        switch (corner) {
          case _Corner.topLeft:
            anchor = Offset(r.right, r.bottom);
            dragPoint = Offset(left, top);
            break;
          case _Corner.topRight:
            anchor = Offset(r.left, r.bottom);
            dragPoint = Offset(right, top);
            break;
          case _Corner.bottomLeft:
            anchor = Offset(r.right, r.top);
            dragPoint = Offset(left, bottom);
            break;
          case _Corner.bottomRight:
            anchor = Offset(r.left, r.top);
            dragPoint = Offset(right, bottom);
            break;
        }

        final dx = dragPoint.dx - anchor.dx;
        final dy = dragPoint.dy - anchor.dy;

        double targetW = math.max(dx.abs(), dy.abs() * ratio);
        targetW = math.max(targetW, _minCropSize);
        double targetH = targetW / ratio;

        final signedW = dx.isNegative ? -targetW : targetW;
        final signedH = dy.isNegative ? -targetH : targetH;

        final newPoint = anchor + Offset(signedW, signedH);

        switch (corner) {
          case _Corner.topLeft:
            left = newPoint.dx;
            top = newPoint.dy;
            right = anchor.dx;
            bottom = anchor.dy;
            break;
          case _Corner.topRight:
            right = newPoint.dx;
            top = newPoint.dy;
            left = anchor.dx;
            bottom = anchor.dy;
            break;
          case _Corner.bottomLeft:
            left = newPoint.dx;
            bottom = newPoint.dy;
            right = anchor.dx;
            top = anchor.dy;
            break;
          case _Corner.bottomRight:
            right = newPoint.dx;
            bottom = newPoint.dy;
            left = anchor.dx;
            top = anchor.dy;
            break;
        }

        left = left.clamp(0.0, _containerSize!.width);
        top = top.clamp(0.0, _containerSize!.height);
        right = right.clamp(0.0, _containerSize!.width);
        bottom = bottom.clamp(0.0, _containerSize!.height);
      }

      _cropRect = Rect.fromLTRB(
        math.min(left, right),
        math.min(top, bottom),
        math.max(left, right),
        math.max(top, bottom),
      );
    });
  }


  void _resizeEdge(_Edge edge, Offset delta) {
    if (_cropRect == null || _containerSize == null) return;

    setState(() {
      final r = _cropRect!;
      double left = r.left, top = r.top, right = r.right, bottom = r.bottom;

      switch (edge) {
        case _Edge.left:
          left += delta.dx;
          break;
        case _Edge.right:
          right += delta.dx;
          break;
        case _Edge.top:
          top += delta.dy;
          break;
        case _Edge.bottom:
          bottom += delta.dy;
          break;
      }

      left = left.clamp(0.0, _containerSize!.width);
      top = top.clamp(0.0, _containerSize!.height);
      right = right.clamp(0.0, _containerSize!.width);
      bottom = bottom.clamp(0.0, _containerSize!.height);

      if (right - left < _minCropSize) {
        if (edge == _Edge.left) {
          left = right - _minCropSize;
        } else {
          right = left + _minCropSize;
        }
      }
      if (bottom - top < _minCropSize) {
        if (edge == _Edge.top) {
          top = bottom - _minCropSize;
        } else {
          bottom = top + _minCropSize;
        }
      }

      if (widget.aspectRatio != null) {
        final ratio = widget.aspectRatio!;

        if (edge == _Edge.left || edge == _Edge.right) {
          double newWidth = (right - left).clamp(_minCropSize, _containerSize!.width);
          double newHeight = newWidth / ratio;
          if (newHeight > _containerSize!.height) {
            newHeight = _containerSize!.height;
            newWidth = newHeight * ratio;
            if (edge == _Edge.left) {
              left = right - newWidth;
            } else {
              right = left + newWidth;
            }
          }
          final centerY = (top + bottom) / 2;
          top = centerY - newHeight / 2;
          bottom = centerY + newHeight / 2;

          if (top < 0) {
            top = 0;
            bottom = newHeight;
          } else if (bottom > _containerSize!.height) {
            bottom = _containerSize!.height;
            top = bottom - newHeight;
          }
        } else {
          double newHeight = (bottom - top).clamp(_minCropSize, _containerSize!.height);
          double newWidth = newHeight * ratio;
          if (newWidth > _containerSize!.width) {
            newWidth = _containerSize!.width;
            newHeight = newWidth / ratio;
            if (edge == _Edge.top) {
              top = bottom - newHeight;
            } else {
              bottom = top + newHeight;
            }
          }
          final centerX = (left + right) / 2;
          left = centerX - newWidth / 2;
          right = centerX + newWidth / 2;

          if (left < 0) {
            left = 0;
            right = newWidth;
          } else if (right > _containerSize!.width) {
            right = _containerSize!.width;
            left = right - newWidth;
          }
        }
      }

      _cropRect = Rect.fromLTRB(
        math.min(left, right),
        math.min(top, bottom),
        math.max(left, right),
        math.max(top, bottom),
      );
    });
  }

  Future<void> _performCrop() async {
    try {
      final boundary = _imageBoundaryKey.currentContext?.findRenderObject()
      as RenderRepaintBoundary?;

      if (boundary != null && _cropRect != null) {
        const pixelRatio = 3.0;
        final ui.Image fullImage = await boundary.toImage(pixelRatio: pixelRatio);

        final srcRect = Rect.fromLTWH(
          _cropRect!.left * pixelRatio,
          _cropRect!.top * pixelRatio,
          _cropRect!.width * pixelRatio,
          _cropRect!.height * pixelRatio,
        );

        final outputW = widget.outputSize.width;
        final outputH = widget.outputSize.height;

        final recorder = ui.PictureRecorder();
        final canvas = Canvas(recorder, Rect.fromLTWH(0, 0, outputW, outputH));
        final paint = Paint()..filterQuality = FilterQuality.high;
        canvas.drawImageRect(
          fullImage,
          srcRect,
          Rect.fromLTWH(0, 0, outputW, outputH),
          paint,
        );
        final picture = recorder.endRecording();
        final ui.Image outputImage =
        await picture.toImage(outputW.round(), outputH.round());

        final ByteData? byteData =
        await outputImage.toByteData(format: ui.ImageByteFormat.png);

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
              'Pinch to zoom the photo, drag any corner or edge to resize the crop box, drag inside it to move',
              style: JoynTypography.subtitle.copyWith(fontSize: 12.5),
            ),

            const SizedBox(height: 16),
            LayoutBuilder(
              builder: (context, constraints) {
                final containerSize = Size(constraints.maxWidth, _cropAreaHeight);
                _containerSize = containerSize;
                _cropRect ??= _initialCropRect(containerSize);
                final cropRect = _cropRect!;

                return Container(
                  height: containerSize.height,
                  width: containerSize.width,
                  clipBehavior: Clip.hardEdge,
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Stack(
                    children: [

                      Positioned.fill(
                        child: RepaintBoundary(
                          key: _imageBoundaryKey,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(18),
                            child: InteractiveViewer(
                              transformationController:
                              _transformationController,
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
                        ),
                      ),

                      IgnorePointer(
                        child: CustomPaint(
                          size: containerSize,
                          painter: _CropOverlayPainter(cropRect),
                        ),
                      ),

                      Positioned.fromRect(
                        rect: cropRect,
                        child: GestureDetector(
                          behavior: HitTestBehavior.translucent,
                          onPanUpdate: (details) =>
                              _moveCropRect(details.delta),
                        ),
                      ),

                      ..._buildEdgeHandles(cropRect),

                      ..._buildCornerHandles(cropRect),
                    ],
                  ),
                );
              },
            ),

            const SizedBox(height: 20),

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

  List<Widget> _buildCornerHandles(Rect cropRect) {
    const touchSize = 40.0;
    const knobSize = 16.0;

    Widget handle(_Corner corner, Offset point) {
      return Positioned(
        left: point.dx - touchSize / 2,
        top: point.dy - touchSize / 2,
        width: touchSize,
        height: touchSize,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onPanUpdate: (details) => _resizeCorner(corner, details.delta),
          child: Center(
            child: Container(
              width: knobSize,
              height: knobSize,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                border: Border.all(color: JoynColors.primary, width: 3),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.25),
                    blurRadius: 4,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return [
      handle(_Corner.topLeft, cropRect.topLeft),
      handle(_Corner.topRight, cropRect.topRight),
      handle(_Corner.bottomLeft, cropRect.bottomLeft),
      handle(_Corner.bottomRight, cropRect.bottomRight),
    ];
  }

  List<Widget> _buildEdgeHandles(Rect cropRect) {
    const touchThickness = 32.0;
    const barLength = 22.0;
    const barThickness = 5.0;

    final leftMid = Offset(cropRect.left, cropRect.top + cropRect.height / 2);
    final rightMid = Offset(cropRect.right, cropRect.top + cropRect.height / 2);
    final topMid = Offset(cropRect.left + cropRect.width / 2, cropRect.top);
    final bottomMid = Offset(cropRect.left + cropRect.width / 2, cropRect.bottom);

    Widget verticalBar() => Container(
      width: barThickness,
      height: barLength,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(3),
        border: Border.all(color: JoynColors.primary, width: 1.4),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.25),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
    );

    Widget horizontalBar() => Container(
      width: barLength,
      height: barThickness,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(3),
        border: Border.all(color: JoynColors.primary, width: 1.4),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.25),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
    );

    Widget sideHandle({
      required Offset point,
      required bool isVertical,
      required _Edge edge,
    }) {
      final w = isVertical ? touchThickness : touchThickness + barLength;
      final h = isVertical ? touchThickness + barLength : touchThickness;

      return Positioned(
        left: point.dx - w / 2,
        top: point.dy - h / 2,
        width: w,
        height: h,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onPanUpdate: (details) => _resizeEdge(edge, details.delta),
          child: Center(child: isVertical ? verticalBar() : horizontalBar()),
        ),
      );
    }

    return [
      sideHandle(point: leftMid, isVertical: true, edge: _Edge.left),
      sideHandle(point: rightMid, isVertical: true, edge: _Edge.right),
      sideHandle(point: topMid, isVertical: false, edge: _Edge.top),
      sideHandle(point: bottomMid, isVertical: false, edge: _Edge.bottom),
    ];
  }
}

class _CropOverlayPainter extends CustomPainter {
  final Rect cropRect;

  _CropOverlayPainter(this.cropRect);

  @override
  void paint(Canvas canvas, Size size) {
    final maskPaint = Paint()..color = Colors.black.withValues(alpha: 0.45);

    final outerPath = Path()..addRect(Offset.zero & size);
    final innerPath = Path()..addRect(cropRect);
    final maskPath = Path.combine(
      PathOperation.difference,
      outerPath,
      innerPath,
    );
    canvas.drawPath(maskPath, maskPaint);

    final borderPaint = Paint()
      ..color = JoynColors.primary
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;
    canvas.drawRect(cropRect, borderPaint);

    final gridPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.5)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    final w = cropRect.width;
    final h = cropRect.height;

    canvas.drawLine(
      Offset(cropRect.left + w / 3, cropRect.top),
      Offset(cropRect.left + w / 3, cropRect.bottom),
      gridPaint,
    );
    canvas.drawLine(
      Offset(cropRect.left + w * 2 / 3, cropRect.top),
      Offset(cropRect.left + w * 2 / 3, cropRect.bottom),
      gridPaint,
    );
    canvas.drawLine(
      Offset(cropRect.left, cropRect.top + h / 3),
      Offset(cropRect.right, cropRect.top + h / 3),
      gridPaint,
    );
    canvas.drawLine(
      Offset(cropRect.left, cropRect.top + h * 2 / 3),
      Offset(cropRect.right, cropRect.top + h * 2 / 3),
      gridPaint,
    );

    final handlePaint = Paint()
      ..color = JoynColors.primary
      ..strokeWidth = 3.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    const handleLength = 16.0;

    canvas.drawLine(cropRect.topLeft, cropRect.topLeft + const Offset(handleLength, 0), handlePaint);
    canvas.drawLine(cropRect.topLeft, cropRect.topLeft + const Offset(0, handleLength), handlePaint);
    canvas.drawLine(cropRect.topRight, cropRect.topRight + const Offset(-handleLength, 0), handlePaint);
    canvas.drawLine(cropRect.topRight, cropRect.topRight + const Offset(0, handleLength), handlePaint);
    canvas.drawLine(cropRect.bottomLeft, cropRect.bottomLeft + const Offset(handleLength, 0), handlePaint);
    canvas.drawLine(cropRect.bottomLeft, cropRect.bottomLeft + const Offset(0, -handleLength), handlePaint);
    canvas.drawLine(cropRect.bottomRight, cropRect.bottomRight + const Offset(-handleLength, 0), handlePaint);
    canvas.drawLine(cropRect.bottomRight, cropRect.bottomRight + const Offset(0, -handleLength), handlePaint);
  }

  @override
  bool shouldRepaint(covariant _CropOverlayPainter oldDelegate) =>
      oldDelegate.cropRect != cropRect;
}