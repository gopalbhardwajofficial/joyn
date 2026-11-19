import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:barcode/barcode.dart';
import 'package:qr/qr.dart';
import 'package:image/image.dart' as img;
import 'package:intl/intl.dart';
import '../models/label_model.dart';
import '../services/clipart_service.dart';

class CanvasRasterizerService {
  /// Converts a label with elements into an img.Image at standard thermal resolution (203 DPI = 8 dots/mm)
  static Future<img.Image> rasterizeLabel({
    required LabelSize size,
    required List<LabelElement> elements,
    LabelShape shape = LabelShape.rectangle,
    Color backgroundColor = Colors.white,
    double dotsPerMm = 8.0, // 203 DPI is 8 dots/mm
  }) async {
    final int widthDots = (size.widthMm * dotsPerMm).round();
    final int heightDots = (size.heightMm * dotsPerMm).round();

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder, Rect.fromLTWH(0, 0, widthDots.toDouble(), heightDots.toDouble()));

    // 1. Fill background with white
    final bgPaint = Paint()..color = Colors.white;
    if (shape == LabelShape.circle || size.isRound) {
      canvas.drawOval(Rect.fromLTWH(0, 0, widthDots.toDouble(), heightDots.toDouble()), bgPaint);
    } else {
      canvas.drawRect(Rect.fromLTWH(0, 0, widthDots.toDouble(), heightDots.toDouble()), bgPaint);
    }

    // Scale factor from logical points (1mm ≈ 3.78px) to printer dots (8 dots/mm)
    // ratio = 8.0 / 3.78 ≈ 2.1164
    final double scale = dotsPerMm / 3.78;

    // 2. Draw each element
    for (final el in elements) {
      canvas.save();

      final double elX = el.x * scale;
      final double elY = el.y * scale;
      final double elW = el.width * scale;
      final double elH = el.height * scale;

      canvas.translate(elX + elW / 2, elY + elH / 2);
      if (el.rotation != 0.0) {
        canvas.rotate(el.rotation * (3.1415926535 / 180));
      }
      canvas.translate(-elW / 2, -elH / 2);

      _drawElement(canvas, el, elW, elH, scale);

      canvas.restore();
    }

    final picture = recorder.endRecording();
    final uiImage = await picture.toImage(widthDots, heightDots);
    final byteData = await uiImage.toByteData(format: ui.ImageByteFormat.rawRgba);

    if (byteData == null) {
      // Fallback blank image
      final fallback = img.Image(width: widthDots, height: heightDots);
      img.fill(fallback, color: img.ColorRgb8(255, 255, 255));
      return fallback;
    }

    // Convert raw RGBA buffer into img.Image
    final output = img.Image.fromBytes(
      width: widthDots,
      height: heightDots,
      bytes: byteData.buffer,
      numChannels: 4,
    );

    return output;
  }

  static void _drawElement(Canvas canvas, LabelElement el, double w, double h, double scale) {
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

        final textSpan = TextSpan(
          text: displayText,
          style: TextStyle(
            color: Colors.black,
            fontSize: el.fontSize * scale,
            fontWeight: el.isBold ? FontWeight.bold : FontWeight.normal,
            fontStyle: el.isItalic ? FontStyle.italic : FontStyle.normal,
            decoration: el.isUnderline ? TextDecoration.underline : TextDecoration.none,
            letterSpacing: el.letterSpacing,
            fontFamily: el.fontFamily.isNotEmpty ? el.fontFamily : 'Roboto',
          ),
        );
        final tp = TextPainter(
          text: textSpan,
          textAlign: el.textAlign,
          textDirection: ui.TextDirection.ltr,
        );
        tp.layout(maxWidth: w);
        tp.paint(canvas, Offset.zero);
        break;

      case ElementType.barcode:
        try {
          final data = el.effectiveBarcodeData;
          Barcode bc;
          switch (el.barcodeEncoding.toUpperCase()) {
            case 'CODE93':
              bc = Barcode.code93();
              break;
            case 'CODE39':
              bc = Barcode.code39();
              break;
            case 'EAN13':
              bc = Barcode.ean13();
              break;
            case 'CODE128':
            default:
              bc = Barcode.code128();
              break;
          }

          final paint = Paint()
            ..color = Colors.black
            ..style = PaintingStyle.fill;

          final double barHeight = el.showBarcodeText ? h * 0.78 : h;
          final operations = bc.make(data, width: w, height: barHeight, drawText: false);
          for (final op in operations) {
            if (op is BarcodeBar && op.black) {
              canvas.drawRect(Rect.fromLTWH(op.left, op.top, op.width, op.height), paint);
            }
          }

          if (el.showBarcodeText) {
            final textSpan = TextSpan(
              text: data,
              style: TextStyle(color: Colors.black, fontSize: 10 * scale, fontFamily: 'Roboto'),
            );
            final tp = TextPainter(text: textSpan, textAlign: TextAlign.center, textDirection: ui.TextDirection.ltr);
            tp.layout(maxWidth: w);
            tp.paint(canvas, Offset((w - tp.width) / 2, barHeight + 2));
          }
        } catch (_) {}
        break;

      case ElementType.qrcode:
        try {
          final qrData = el.effectiveQrData;
          if (el.qrEncoding.toUpperCase() == 'QR_CODE' || el.qrEncoding.isEmpty) {
            final qrCode = QrCode.fromData(
              data: qrData,
              errorCorrectLevel: QrErrorCorrectLevel.M,
            );
            final qrImage = QrImage(qrCode);
            final int moduleCount = qrImage.moduleCount;
            final double moduleSize = w / moduleCount;
            final paint = Paint()..color = Colors.black;

            for (int x = 0; x < moduleCount; x++) {
              for (int y = 0; y < moduleCount; y++) {
                if (qrImage.isDark(y, x)) {
                  canvas.drawRect(
                    Rect.fromLTWH(x * moduleSize, y * moduleSize, moduleSize, moduleSize),
                    paint,
                  );
                }
              }
            }
          } else {
            // PDF417, DATA_MATRIX, AZTEC
            Barcode barcode2D;
            switch (el.qrEncoding.toUpperCase()) {
              case 'PDF417':
                barcode2D = Barcode.pdf417();
                break;
              case 'DATA_MATRIX':
                barcode2D = Barcode.dataMatrix();
                break;
              case 'AZTEC':
              default:
                barcode2D = Barcode.aztec();
                break;
            }
            final paint = Paint()..color = Colors.black;
            final ops = barcode2D.make(qrData, width: w, height: h, drawText: false);
            for (final op in ops) {
              if (op is BarcodeBar && op.black) {
                canvas.drawRect(Rect.fromLTWH(op.left, op.top, op.width, op.height), paint);
              }
            }
          }
        } catch (_) {}
        break;

      case ElementType.clipart:
        final icon = ClipartService.getIcon(el.clipartKey);
        final textSpan = TextSpan(
          text: String.fromCharCode(icon.codePoint),
          style: TextStyle(
            fontSize: h,
            fontFamily: icon.fontFamily,
            package: icon.fontPackage,
            color: Colors.black,
          ),
        );
        final tp = TextPainter(text: textSpan, textDirection: ui.TextDirection.ltr);
        tp.layout();
        tp.paint(canvas, Offset((w - tp.width) / 2, (h - tp.height) / 2));
        break;

      case ElementType.shape:
        final paint = Paint()
          ..color = Colors.black
          ..strokeWidth = el.strokeWidth * scale
          ..style = PaintingStyle.stroke;

        switch (el.shapeType) {
          case ShapeType.rectangle:
            canvas.drawRect(Rect.fromLTWH(0, 0, w, h), paint);
            break;
          case ShapeType.roundedRectangle:
            canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(0, 0, w, h), Radius.circular(8 * scale)), paint);
            break;
          case ShapeType.circle:
            canvas.drawOval(Rect.fromLTWH(0, 0, w, h), paint);
            break;
          case ShapeType.horizontalLine:
            canvas.drawLine(Offset(0, h / 2), Offset(w, h / 2), paint);
            break;
          case ShapeType.verticalLine:
            canvas.drawLine(Offset(w / 2, 0), Offset(w / 2, h), paint);
            break;
        }
        break;

      case ElementType.border:
        final paint = Paint()
          ..color = Colors.black
          ..strokeWidth = el.strokeWidth * scale
          ..style = PaintingStyle.stroke;
        canvas.drawRect(Rect.fromLTWH(0, 0, w, h), paint);
        break;

      case ElementType.image:
        final paint = Paint()
          ..color = Colors.black
          ..style = PaintingStyle.stroke;
        canvas.drawRect(Rect.fromLTWH(0, 0, w, h), paint);
        break;
    }
  }
}
