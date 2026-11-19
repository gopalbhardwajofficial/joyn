import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;

enum FilterMode {
  original,
  bwThreshold,
  dithering,
}

class ImageProcessingService {
  /// Converts an img.Image into a 1-bit monochrome image based on the selected filter and threshold
  static img.Image processForThermal({
    required img.Image src,
    required FilterMode filterMode,
    int threshold = 200,
    bool invert = false,
  }) {
    // 1. Convert to grayscale first
    final grayscale = img.grayscale(src);
    final width = grayscale.width;
    final height = grayscale.height;

    final output = img.Image(width: width, height: height, numChannels: 1);

    if (filterMode == FilterMode.bwThreshold) {
      for (int y = 0; y < height; y++) {
        for (int x = 0; x < width; x++) {
          final pixel = grayscale.getPixel(x, y);
          final luminance = pixel.r; // In grayscale, r=g=b=luminance
          final bool isBlack = invert ? (luminance >= threshold) : (luminance < threshold);
          output.setPixelRgb(x, y, isBlack ? 0 : 255, isBlack ? 0 : 255, isBlack ? 0 : 255);
        }
      }
    } else if (filterMode == FilterMode.dithering) {
      // Floyd-Steinberg error diffusion dithering
      // Make a 2D float buffer of luminance values
      final buffer = List.generate(height, (y) => List<double>.generate(width, (x) => grayscale.getPixel(x, y).r.toDouble()));

      for (int y = 0; y < height; y++) {
        for (int x = 0; x < width; x++) {
          final oldVal = buffer[y][x];
          final newVal = oldVal < threshold ? 0.0 : 255.0;
          final error = oldVal - newVal;

          final bool isBlack = invert ? (newVal >= 128) : (newVal < 128);
          output.setPixelRgb(x, y, isBlack ? 0 : 255, isBlack ? 0 : 255, isBlack ? 0 : 255);

          // Diffuse error to neighboring pixels
          if (x + 1 < width) {
            buffer[y][x + 1] += error * (7.0 / 16.0);
          }
          if (y + 1 < height) {
            if (x - 1 >= 0) {
              buffer[y + 1][x - 1] += error * (3.0 / 16.0);
            }
            buffer[y + 1][x] += error * (5.0 / 16.0);
            if (x + 1 < width) {
              buffer[y + 1][x + 1] += error * (1.0 / 16.0);
            }
          }
        }
      }
    } else {
      // Original grayscale
      return grayscale;
    }

    return output;
  }

  /// AI Cropping algorithm: detects the bounding box of non-white content
  /// trims unwanted page margins from shipping labels or receipts
  static Rect detectAICropBounds(img.Image image, {int whiteThreshold = 245}) {
    final width = image.width;
    final height = image.height;

    int minX = width;
    int minY = height;
    int maxX = 0;
    int maxY = 0;

    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        final pixel = image.getPixel(x, y);
        // If not white / background
        if (pixel.r < whiteThreshold || pixel.g < whiteThreshold || pixel.b < whiteThreshold) {
          if (x < minX) minX = x;
          if (x > maxX) maxX = x;
          if (y < minY) minY = y;
          if (y > maxY) maxY = y;
        }
      }
    }

    // Add safe padding
    if (minX >= maxX || minY >= maxY) {
      return Rect.fromLTWH(0, 0, width.toDouble(), height.toDouble());
    }

    final padX = (width * 0.02).clamp(4.0, 20.0);
    final padY = (height * 0.02).clamp(4.0, 20.0);

    final left = (minX - padX).clamp(0.0, width.toDouble());
    final top = (minY - padY).clamp(0.0, height.toDouble());
    final right = (maxX + padX).clamp(0.0, width.toDouble());
    final bottom = (maxY + padY).clamp(0.0, height.toDouble());

    return Rect.fromLTRB(left, top, right, bottom);
  }

  /// Encodes an image into 1-bit packed bitmap data for TSPL / ESC-POS
  /// TSPL BITMAP mode: 0 is black, 1 is white (or inverted depending on mode)
  /// Returns {widthBytes, heightDots, bytes}
  static Uint8List encodeTo1BitBitmap(img.Image monochromeImg, {bool invert = false}) {
    final width = monochromeImg.width;
    final height = monochromeImg.height;
    final widthBytes = (width + 7) ~/ 8;

    final bytes = Uint8List(widthBytes * height);

    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        final p = monochromeImg.getPixel(x, y);
        // Is pixel black?
        final isBlack = p.r < 128;

        // In TSPL: 0 = print black dot, 1 = no dot (white)
        // If invert is true, 1 = black, 0 = white
        final bitVal = invert ? (isBlack ? 1 : 0) : (isBlack ? 0 : 1);

        if (bitVal == 1) {
          final byteIndex = y * widthBytes + (x ~/ 8);
          final bitPosition = 7 - (x % 8);
          bytes[byteIndex] |= (1 << bitPosition);
        }
      }
    }

    return bytes;
  }
}

