import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

/// A fully custom crop dialog — no `image_cropper` plugin, no native
/// channels, so it can never throw MissingPluginException.
///
/// Matches the reference UI: title + subtitle, image with a resizable
/// crop box (drag corners/edges to resize, drag inside to move), and a
/// "Crop & Apply" button.
///
/// Usage (drop-in replacement for your old `_cropImage` method):
///
/// ```dart
/// Future<File?> _cropImage(String sourcePath) async {
///   return showDialog<File>(
///     context: context,
///     barrierColor: Colors.black54,
///     builder: (_) => CustomCropDialog(
///       imageFile: File(sourcePath),
///       title: 'Crop & Adjust Logo',
///       aspectRatio: 1, // null = free-form resize
///     ),
///   );
/// }
/// ```
class CustomCropDialog extends StatefulWidget {
  const CustomCropDialog({
    super.key,
    required this.imageFile,
    this.title = 'Crop & Adjust Photo',
    this.subtitle =
    'Pinch to zoom the photo, drag any corner or edge to resize the crop box, drag inside it to move',
    this.aspectRatio,
    this.outputMaxDimension = 800,
  });

  final File imageFile;
  final String title;
  final String subtitle;

  /// width / height. Pass null to allow free-form resizing (any shape).
  /// Pass 1 for a square crop (e.g. avatars/logos).
  final double? aspectRatio;

  /// Longer side of the exported PNG, in pixels.
  final double outputMaxDimension;

  @override
  State<CustomCropDialog> createState() => _CustomCropDialogState();
}

enum _CornerType { topLeft, topRight, bottomLeft, bottomRight }
enum _EdgeType { left, right, top, bottom }

class _CustomCropDialogState extends State<CustomCropDialog> {
  static const double _boxWidth = 280;
  static const double _boxHeight = 340;
  static const double _minCropSize = 60;
  static const double _handleTouchSize = 32;

  ui.Image? _image;
  Rect _imageDisplayRect = Rect.zero;
  Rect _cropRect = Rect.zero;
  bool _loading = true;
  bool _isCropping = false;

  @override
  void initState() {
    super.initState();
    _loadImage();
  }

  Future<void> _loadImage() async {
    final bytes = await widget.imageFile.readAsBytes();
    final codec = await ui.instantiateImageCodec(bytes);
    final frame = await codec.getNextFrame();
    final image = frame.image;

    final displayRect = _computeContainRect(
      const Size(_boxWidth, _boxHeight),
      Size(image.width.toDouble(), image.height.toDouble()),
    );

    // Initial crop box: centered, 80% of the smaller display dimension,
    // respecting the requested aspect ratio (if any).
    double w = displayRect.width * 0.8;
    double h = displayRect.height * 0.8;
    if (widget.aspectRatio != null) {
      if (w / h > widget.aspectRatio!) {
        w = h * widget.aspectRatio!;
      } else {
        h = w / widget.aspectRatio!;
      }
    }
    final center = displayRect.center;

    setState(() {
      _image = image;
      _imageDisplayRect = displayRect;
      _cropRect = Rect.fromCenter(center: center, width: w, height: h);
      _loading = false;
    });
  }

  /// BoxFit.contain math — the rect (in container coordinates) where the
  /// full image is drawn, letterboxed if the aspect ratios don't match.
  Rect _computeContainRect(Size container, Size natural) {
    final containerAspect = container.width / container.height;
    final naturalAspect = natural.width / natural.height;
    double w, h;
    if (naturalAspect > containerAspect) {
      w = container.width;
      h = w / naturalAspect;
    } else {
      h = container.height;
      w = h * naturalAspect;
    }
    final left = (container.width - w) / 2;
    final top = (container.height - h) / 2;
    return Rect.fromLTWH(left, top, w, h);
  }

  Rect _clampRectToImage(Rect r) {
    double left = r.left;
    double top = r.top;
    double right = r.right;
    double bottom = r.bottom;

    if (left < _imageDisplayRect.left) left = _imageDisplayRect.left;
    if (top < _imageDisplayRect.top) top = _imageDisplayRect.top;
    if (right > _imageDisplayRect.right) right = _imageDisplayRect.right;
    if (bottom > _imageDisplayRect.bottom) bottom = _imageDisplayRect.bottom;

    return Rect.fromLTRB(left, top, right, bottom);
  }

  // ---- Gestures --------------------------------------------------------

  void _moveCropRect(Offset delta) {
    var next = _cropRect.shift(delta);
    double dx = 0, dy = 0;
    if (next.left < _imageDisplayRect.left) dx = _imageDisplayRect.left - next.left;
    if (next.right > _imageDisplayRect.right) dx = _imageDisplayRect.right - next.right;
    if (next.top < _imageDisplayRect.top) dy = _imageDisplayRect.top - next.top;
    if (next.bottom > _imageDisplayRect.bottom) dy = _imageDisplayRect.bottom - next.bottom;
    next = next.shift(Offset(dx, dy));
    setState(() => _cropRect = next);
  }

  void _resizeFromCorner(_CornerType corner, Offset delta) {
    double left = _cropRect.left;
    double top = _cropRect.top;
    double right = _cropRect.right;
    double bottom = _cropRect.bottom;

    switch (corner) {
      case _CornerType.topLeft:
        left += delta.dx;
        top += delta.dy;
        break;
      case _CornerType.topRight:
        right += delta.dx;
        top += delta.dy;
        break;
      case _CornerType.bottomLeft:
        left += delta.dx;
        bottom += delta.dy;
        break;
      case _CornerType.bottomRight:
        right += delta.dx;
        bottom += delta.dy;
        break;
    }

    left = left.clamp(_imageDisplayRect.left, _imageDisplayRect.right);
    top = top.clamp(_imageDisplayRect.top, _imageDisplayRect.bottom);
    right = right.clamp(_imageDisplayRect.left, _imageDisplayRect.right);
    bottom = bottom.clamp(_imageDisplayRect.top, _imageDisplayRect.bottom);

    if (right - left < _minCropSize) {
      if (corner == _CornerType.topLeft || corner == _CornerType.bottomLeft) {
        left = right - _minCropSize;
      } else {
        right = left + _minCropSize;
      }
    }
    if (bottom - top < _minCropSize) {
      if (corner == _CornerType.topLeft || corner == _CornerType.topRight) {
        top = bottom - _minCropSize;
      } else {
        bottom = top + _minCropSize;
      }
    }

    Rect next = Rect.fromLTRB(left, top, right, bottom);

    if (widget.aspectRatio != null) {
      final ratio = widget.aspectRatio!;
      double w = next.width;
      double h = next.height;
      if (w / h > ratio) {
        w = h * ratio;
      } else {
        h = w / ratio;
      }
      switch (corner) {
        case _CornerType.topLeft:
          next = Rect.fromLTRB(right - w, bottom - h, right, bottom);
          break;
        case _CornerType.topRight:
          next = Rect.fromLTRB(left, bottom - h, left + w, bottom);
          break;
        case _CornerType.bottomLeft:
          next = Rect.fromLTRB(right - w, top, right, top + h);
          break;
        case _CornerType.bottomRight:
          next = Rect.fromLTRB(left, top, left + w, top + h);
          break;
      }
      next = _clampRectToImage(next);
    }

    setState(() => _cropRect = next);
  }

  void _resizeFromEdge(_EdgeType edge, Offset delta) {
    // Edge handles only apply when free-form (no locked aspect ratio) —
    // with a locked ratio, resizing always goes through the corners so
    // the shape stays correct.
    if (widget.aspectRatio != null) return;

    double left = _cropRect.left;
    double top = _cropRect.top;
    double right = _cropRect.right;
    double bottom = _cropRect.bottom;

    switch (edge) {
      case _EdgeType.left:
        left += delta.dx;
        break;
      case _EdgeType.right:
        right += delta.dx;
        break;
      case _EdgeType.top:
        top += delta.dy;
        break;
      case _EdgeType.bottom:
        bottom += delta.dy;
        break;
    }

    left = left.clamp(_imageDisplayRect.left, _imageDisplayRect.right);
    top = top.clamp(_imageDisplayRect.top, _imageDisplayRect.bottom);
    right = right.clamp(_imageDisplayRect.left, _imageDisplayRect.right);
    bottom = bottom.clamp(_imageDisplayRect.top, _imageDisplayRect.bottom);

    if (right - left < _minCropSize) {
      if (edge == _EdgeType.left) left = right - _minCropSize;
      if (edge == _EdgeType.right) right = left + _minCropSize;
    }
    if (bottom - top < _minCropSize) {
      if (edge == _EdgeType.top) top = bottom - _minCropSize;
      if (edge == _EdgeType.bottom) bottom = top + _minCropSize;
    }

    setState(() => _cropRect = Rect.fromLTRB(left, top, right, bottom));
  }

  // ---- Export ------------------------------------------------------------

  Future<void> _cropAndApply() async {
    if (_image == null) return;
    setState(() => _isCropping = true);

    try {
      final scaleX = _image!.width / _imageDisplayRect.width;
      final scaleY = _image!.height / _imageDisplayRect.height;

      final srcRect = Rect.fromLTWH(
        (_cropRect.left - _imageDisplayRect.left) * scaleX,
        (_cropRect.top - _imageDisplayRect.top) * scaleY,
        _cropRect.width * scaleX,
        _cropRect.height * scaleY,
      );

      final cropAspect = srcRect.width / srcRect.height;
      double outW, outH;
      if (srcRect.width >= srcRect.height) {
        outW = widget.outputMaxDimension;
        outH = outW / cropAspect;
      } else {
        outH = widget.outputMaxDimension;
        outW = outH * cropAspect;
      }

      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);
      final dstRect = Rect.fromLTWH(0, 0, outW, outH);
      canvas.drawImageRect(
        _image!,
        srcRect,
        dstRect,
        Paint()..filterQuality = FilterQuality.high,
      );
      final picture = recorder.endRecording();
      final outputImage = await picture.toImage(outW.round(), outH.round());
      final byteData = await outputImage.toByteData(format: ui.ImageByteFormat.png);

      if (byteData == null) {
        if (mounted) Navigator.pop(context);
        return;
      }

      final pngBytes = byteData.buffer.asUint8List();
      final tempDir = await getTemporaryDirectory();
      final file = File(
        '${tempDir.path}/cropped_${DateTime.now().millisecondsSinceEpoch}.png',
      );
      await file.writeAsBytes(pngBytes);

      if (mounted) Navigator.pop(context, file);
    } catch (e) {
      if (mounted) {
        setState(() => _isCropping = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not crop image: $e')),
        );
      }
    }
  }

  // ---- Build ---------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    widget.title,
                    style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w800),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded),
                  onPressed: _isCropping ? null : () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              widget.subtitle,
              style: TextStyle(fontSize: 13, color: Colors.grey.shade600, height: 1.4),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: _boxWidth,
              height: _boxHeight,
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : _buildCropArea(),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: (_loading || _isCropping) ? null : _cropAndApply,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: _isCropping
                    ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.4,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
                    : const Text(
                  'Crop & Apply',
                  style: TextStyle(fontSize: 15.5, fontWeight: FontWeight.w700),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCropArea() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(16),
      ),
      clipBehavior: Clip.hardEdge,
      child: Stack(
        children: [
          Positioned(
            left: _imageDisplayRect.left,
            top: _imageDisplayRect.top,
            width: _imageDisplayRect.width,
            height: _imageDisplayRect.height,
            child: RawImage(image: _image, fit: BoxFit.fill),
          ),
          Positioned.fill(
            child: IgnorePointer(
              child: CustomPaint(painter: _DimOverlayPainter(cropRect: _cropRect)),
            ),
          ),
          Positioned(
            left: _cropRect.left,
            top: _cropRect.top,
            width: _cropRect.width,
            height: _cropRect.height,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onPanUpdate: (details) => _moveCropRect(details.delta),
              child: Container(
                decoration: BoxDecoration(border: Border.all(color: Colors.white, width: 2)),
                child: CustomPaint(painter: _GridPainter()),
              ),
            ),
          ),
          _buildCornerHandle(_CornerType.topLeft),
          _buildCornerHandle(_CornerType.topRight),
          _buildCornerHandle(_CornerType.bottomLeft),
          _buildCornerHandle(_CornerType.bottomRight),
          if (widget.aspectRatio == null) ...[
            _buildEdgeHandle(_EdgeType.top),
            _buildEdgeHandle(_EdgeType.bottom),
            _buildEdgeHandle(_EdgeType.left),
            _buildEdgeHandle(_EdgeType.right),
          ],
        ],
      ),
    );
  }

  Widget _buildCornerHandle(_CornerType corner) {
    late Offset center;
    switch (corner) {
      case _CornerType.topLeft:
        center = _cropRect.topLeft;
        break;
      case _CornerType.topRight:
        center = _cropRect.topRight;
        break;
      case _CornerType.bottomLeft:
        center = _cropRect.bottomLeft;
        break;
      case _CornerType.bottomRight:
        center = _cropRect.bottomRight;
        break;
    }

    return Positioned(
      left: center.dx - _handleTouchSize / 2,
      top: center.dy - _handleTouchSize / 2,
      width: _handleTouchSize,
      height: _handleTouchSize,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onPanUpdate: (details) => _resizeFromCorner(corner, details.delta),
        child: Center(
          child: Container(
            width: 18,
            height: 18,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white,
              border: Border.all(color: Colors.black87, width: 2),
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.25), blurRadius: 4)],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEdgeHandle(_EdgeType edge) {
    const double thickness = 28;
    const double barLength = 22;
    const double barThickness = 5;

    Offset center;
    double w, h;
    bool horizontal;

    switch (edge) {
      case _EdgeType.top:
        center = Offset(_cropRect.center.dx, _cropRect.top);
        w = thickness;
        h = _handleTouchSize;
        horizontal = true;
        break;
      case _EdgeType.bottom:
        center = Offset(_cropRect.center.dx, _cropRect.bottom);
        w = thickness;
        h = _handleTouchSize;
        horizontal = true;
        break;
      case _EdgeType.left:
        center = Offset(_cropRect.left, _cropRect.center.dy);
        w = _handleTouchSize;
        h = thickness;
        horizontal = false;
        break;
      case _EdgeType.right:
        center = Offset(_cropRect.right, _cropRect.center.dy);
        w = _handleTouchSize;
        h = thickness;
        horizontal = false;
        break;
    }

    return Positioned(
      left: center.dx - w / 2,
      top: center.dy - h / 2,
      width: w,
      height: h,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onPanUpdate: (details) => _resizeFromEdge(edge, details.delta),
        child: Center(
          child: Container(
            width: horizontal ? barLength : barThickness,
            height: horizontal ? barThickness : barLength,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(3),
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.25), blurRadius: 3)],
            ),
          ),
        ),
      ),
    );
  }
}

/// Faint rule-of-thirds guide lines inside the crop box.
class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.5)
      ..strokeWidth = 1;
    canvas.drawLine(Offset(size.width / 2, 0), Offset(size.width / 2, size.height), paint);
    canvas.drawLine(Offset(0, size.height / 2), Offset(size.width, size.height / 2), paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Darkens everything outside the crop rect.
class _DimOverlayPainter extends CustomPainter {
  _DimOverlayPainter({required this.cropRect});
  final Rect cropRect;

  @override
  void paint(Canvas canvas, Size size) {
    final outer = Path()..addRect(Rect.fromLTWH(0, 0, size.width, size.height));
    final inner = Path()..addRect(cropRect);
    final diff = Path.combine(PathOperation.difference, outer, inner);
    canvas.drawPath(diff, Paint()..color = Colors.black.withValues(alpha: 0.45));
  }

  @override
  bool shouldRepaint(covariant _DimOverlayPainter oldDelegate) => oldDelegate.cropRect != cropRect;
}