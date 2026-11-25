import 'dart:io';
import 'package:flutter/material.dart';
import 'package:barcode_widget/barcode_widget.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:intl/intl.dart';
import '../models/label_model.dart';
import '../services/clipart_service.dart';
import '../theme/app_colors.dart';

class LabelCanvasView extends StatefulWidget {
  final LabelSize size;
  final List<LabelElement> elements;
  final Color backgroundColor;
  final bool isEditable;
  final String? selectedElementId;
  final Function(LabelElement)? onElementTap;
  final Function(LabelElement)? onElementDoubleTap;
  final Function(LabelElement, double dx, double dy)? onElementDragged;
  final Function(LabelElement, double newWidth, double newHeight)? onElementResized;
  final Function(LabelElement)? onElementDelete;
  final Function(LabelElement)? onElementDuplicate;
  final Function(LabelElement, double scaleFactor)? onElementScaled;

  const LabelCanvasView({
    super.key,
    required this.size,
    required this.elements,
    this.backgroundColor = Colors.white,
    this.isEditable = false,
    this.selectedElementId,
    this.onElementTap,
    this.onElementDoubleTap,
    this.onElementDragged,
    this.onElementResized,
    this.onElementDelete,
    this.onElementDuplicate,
    this.onElementScaled,
  });

  @override
  State<LabelCanvasView> createState() => _LabelCanvasViewState();
}

class _LabelCanvasViewState extends State<LabelCanvasView> {
  double _lastPinchScale = 1.0;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final double maxW = constraints.maxWidth;
        final double maxH = constraints.maxHeight;

        double canvasW = widget.size.widthPx;
        double canvasH = widget.size.heightPx;

        final double scaleX = maxW / canvasW;
        final double scaleY = maxH / canvasH;
        final double fitScale = (scaleX < scaleY ? scaleX : scaleY).clamp(0.1, 2.5);

        final double displayW = canvasW * fitScale;
        final double displayH = canvasH * fitScale;

        return Center(
          child: Container(
            width: displayW,
            height: displayH,
            decoration: BoxDecoration(
              color: widget.backgroundColor,
              borderRadius: widget.size.isRound ? BorderRadius.circular(displayW / 2) : BorderRadius.circular(8),
              border: Border.all(
                color: widget.isEditable ? AppColors.primary.withValues(alpha: 0.5) : Colors.grey.shade300,
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.06),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: widget.size.isRound ? BorderRadius.circular(displayW / 2) : BorderRadius.circular(8),
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  // Dotted boundary guide if in editable mode
                  if (widget.isEditable)
                    Positioned.fill(
                      child: CustomPaint(
                        painter: DashedGuideBorderPainter(),
                      ),
                    ),

                  // Elements
                  for (final el in widget.elements)
                    _buildElementPositioned(el, fitScale),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildElementPositioned(LabelElement el, double scale) {
    final bool isSelected = widget.isEditable && widget.selectedElementId == el.id;

    final left = el.x * scale;
    final top = el.y * scale;
    final width = el.width * scale;
    final height = el.height * scale;

    Widget child = _buildElementContent(el, scale);

    if (widget.isEditable) {
      child = GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => widget.onElementTap?.call(el),
        onDoubleTap: () => widget.onElementDoubleTap?.call(el),
        onScaleStart: (details) {
          _lastPinchScale = 1.0;
        },
        onScaleUpdate: (details) {
          if (el.isLocked) return;
          if (details.pointerCount > 1 || (details.scale - 1.0).abs() > 0.05) {
            final double factor = details.scale / _lastPinchScale;
            _lastPinchScale = details.scale;
            widget.onElementScaled?.call(el, factor);
          } else {
            widget.onElementDragged?.call(
              el,
              details.focalPointDelta.dx / scale,
              details.focalPointDelta.dy / scale,
            );
          }
        },
        child: Container(
          decoration: BoxDecoration(
            border: isSelected
                ? Border.all(color: AppColors.primary, width: 1.5)
                : Border.all(color: Colors.transparent),
          ),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned.fill(child: child),
              if (isSelected) ...[
                // Top-left delete handle (Screenshot 1, 4, 5)
                Positioned(
                  top: -11,
                  left: -11,
                  child: GestureDetector(
                    onTap: () => widget.onElementDelete?.call(el),
                    child: Container(
                      width: 22,
                      height: 22,
                      decoration: const BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.delete_outline, size: 13, color: Colors.white),
                    ),
                  ),
                ),
                // Top-right duplicate handle (Screenshot 1, 4, 5)
                Positioned(
                  top: -11,
                  right: -11,
                  child: GestureDetector(
                    onTap: () => widget.onElementDuplicate?.call(el),
                    child: Container(
                      width: 22,
                      height: 22,
                      decoration: const BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.content_copy, size: 12, color: Colors.white),
                    ),
                  ),
                ),
                // Bottom-right resize handle (Screenshot 1, 4, 5)
                Positioned(
                  bottom: -14,
                  right: -14,
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onPanUpdate: (details) {
                      if (el.isLocked) return;
                      final dx = details.delta.dx / scale;
                      final dy = details.delta.dy / scale;
                      double newW = (el.width + dx).clamp(20.0, 800.0);
                      double newH = (el.height + dy).clamp(12.0, 800.0);

                      if (el.isIsometric || el.type == ElementType.qrcode) {
                        final maxDim = (newW > newH ? newW : newH).clamp(20.0, 800.0);
                        newW = maxDim;
                        newH = maxDim;
                      }

                      widget.onElementResized?.call(el, newW, newH);
                    },
                    child: Container(
                      width: 32,
                      height: 32,
                      alignment: Alignment.center,
                      decoration: const BoxDecoration(
                        color: Colors.transparent,
                        shape: BoxShape.circle,
                      ),
                      child: Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.25),
                              blurRadius: 4,
                              offset: const Offset(0, 1),
                            ),
                          ],
                        ),
                        child: const Icon(Icons.open_in_full_rounded, size: 12, color: Colors.white),
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      );
    }

    return Positioned(
      left: left,
      top: top,
      width: width,
      height: height,
      child: Transform.rotate(
        angle: el.rotation * (3.1415926535 / 180),
        child: child,
      ),
    );
  }

  Widget _buildElementContent(LabelElement el, double scale) {
    switch (el.type) {
      case ElementType.text:
      case ElementType.dateTime:
      case ElementType.serial:
      case ElementType.excelField:
        String displayText = el.effectiveText;
        if (el.type == ElementType.dateTime) {
          try {
            displayText = DateFormat(el.dateTimeFormat).format(DateTime.now());
          } catch (_) {
            displayText = el.text;
          }
        }
        return Align(
          alignment: _getAlignment(el.textAlign),
          child: Text(
            displayText,
            textAlign: el.textAlign,
            style: TextStyle(
              fontSize: el.fontSize * scale,
              fontWeight: el.isBold ? FontWeight.bold : FontWeight.normal,
              fontStyle: el.isItalic ? FontStyle.italic : FontStyle.normal,
              decoration: el.isUnderline ? TextDecoration.underline : TextDecoration.none,
              letterSpacing: el.letterSpacing,
              height: el.lineSpacing > 0 ? (1.0 + el.lineSpacing / 10.0) : 1.15,
              fontFamily: el.fontFamily.isNotEmpty ? el.fontFamily : 'Roboto',
              color: Colors.black,
            ),
          ),
        );

      case ElementType.barcode:
        final bcData = el.effectiveBarcodeData;
        Barcode barcodeObj;
        switch (el.barcodeEncoding.toUpperCase()) {
          case 'CODE93':
            barcodeObj = Barcode.code93();
            break;
          case 'CODE39':
            barcodeObj = Barcode.code39();
            break;
          case 'EAN13':
            barcodeObj = Barcode.ean13();
            break;
          case 'CODE128':
          default:
            barcodeObj = Barcode.code128();
            break;
        }

        return BarcodeWidget(
          barcode: barcodeObj,
          data: bcData,
          drawText: el.showBarcodeText,
          color: Colors.black,
          width: el.width * scale,
          height: el.height * scale,
          errorBuilder: (context, error) => Center(
            child: Text(
              'Code39 requires UPPERCASE & numbers',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 8 * scale, color: Colors.grey.shade600),
            ),
          ),
        );

      case ElementType.qrcode:
        final qrData = el.effectiveQrData;
        switch (el.qrEncoding.toUpperCase()) {
          case 'PDF417':
            return BarcodeWidget(
              barcode: Barcode.pdf417(),
              data: qrData,
              drawText: false,
              color: Colors.black,
              width: el.width * scale,
              height: el.height * scale,
            );
          case 'DATA_MATRIX':
            return BarcodeWidget(
              barcode: Barcode.dataMatrix(),
              data: qrData,
              drawText: false,
              color: Colors.black,
              width: el.width * scale,
              height: el.height * scale,
            );
          case 'AZTEC':
            return BarcodeWidget(
              barcode: Barcode.aztec(),
              data: qrData,
              drawText: false,
              color: Colors.black,
              width: el.width * scale,
              height: el.height * scale,
            );
          case 'QR_CODE':
          default:
            return QrImageView(
              data: qrData,
              version: QrVersions.auto,
              padding: EdgeInsets.zero,
              eyeStyle: const QrEyeStyle(eyeShape: QrEyeShape.square, color: Colors.black),
              dataModuleStyle: const QrDataModuleStyle(dataModuleShape: QrDataModuleShape.square, color: Colors.black),
            );
        }

      case ElementType.clipart:
        return Icon(
          ClipartService.getIcon(el.clipartKey),
          size: el.height * scale,
          color: Colors.black,
        );

      case ElementType.shape:
        return CustomPaint(
          painter: ShapeElementPainter(
            shapeType: el.shapeType,
            strokeWidth: el.strokeWidth * scale,
            color: Colors.black,
          ),
        );

      case ElementType.border:
        return Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.black, width: el.strokeWidth * scale),
            borderRadius: BorderRadius.circular(6),
          ),
        );

      case ElementType.image:
        if (el.imagePath != null && File(el.imagePath!).existsSync()) {
          return Image.file(
            File(el.imagePath!),
            fit: BoxFit.contain,
          );
        }
        return Container(
          color: Colors.grey.shade200,
          child: const Center(
            child: Icon(Icons.image, color: Colors.grey),
          ),
        );
    }
  }

  Alignment _getAlignment(TextAlign align) {
    switch (align) {
      case TextAlign.left:
        return Alignment.centerLeft;
      case TextAlign.center:
        return Alignment.center;
      case TextAlign.right:
        return Alignment.centerRight;
      case TextAlign.justify:
        return Alignment.centerLeft;
      case TextAlign.start:
        return Alignment.centerLeft;
      case TextAlign.end:
        return Alignment.centerRight;
    }
  }
}

class ShapeElementPainter extends CustomPainter {
  final ShapeType shapeType;
  final double strokeWidth;
  final Color color;

  ShapeElementPainter({
    required this.shapeType,
    required this.strokeWidth,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    switch (shapeType) {
      case ShapeType.rectangle:
        canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), paint);
        break;
      case ShapeType.roundedRectangle:
        canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(0, 0, size.width, size.height), const Radius.circular(8)), paint);
        break;
      case ShapeType.circle:
        canvas.drawOval(Rect.fromLTWH(0, 0, size.width, size.height), paint);
        break;
      case ShapeType.horizontalLine:
        canvas.drawLine(Offset(0, size.height / 2), Offset(size.width, size.height / 2), paint);
        break;
      case ShapeType.verticalLine:
        canvas.drawLine(Offset(size.width / 2, 0), Offset(size.width / 2, size.height), paint);
        break;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class DashedGuideBorderPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.grey.shade300
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

    const dashWidth = 4.0;
    const dashSpace = 4.0;

    // Draw dashed rectangle border
    final path = Path()
      ..addRect(Rect.fromLTWH(2, 2, size.width - 4, size.height - 4));

    for (final metric in path.computeMetrics()) {
      double start = 0.0;
      while (start < metric.length) {
        final end = (start + dashWidth).clamp(0.0, metric.length);
        final extractPath = metric.extractPath(start, end);
        canvas.drawPath(extractPath, paint);
        start += dashWidth + dashSpace;
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
