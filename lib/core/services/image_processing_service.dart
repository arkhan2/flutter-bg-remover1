import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;
import '../../models/edited_image.dart';

class ImageProcessingService {
  static Future<Uint8List?> applyBackground({
    required Uint8List foregroundBytes,
    required BackgroundType backgroundType,
    Color? solidColor,
    List<Color>? gradientColors,
    double? blurRadius,
    Uint8List? originalImageBytes,
  }) async {
    try {
      final foreground = img.decodeImage(foregroundBytes);
      if (foreground == null) return null;

      img.Image result;

      switch (backgroundType) {
        case BackgroundType.transparent:
          result = foreground;
          break;
        case BackgroundType.solid:
          result = _applySolidBackground(foreground, solidColor ?? Colors.white);
          break;
        case BackgroundType.gradient:
          result = _applyGradientBackground(
            foreground,
            gradientColors ?? [Colors.blue, Colors.purple],
          );
          break;
        case BackgroundType.blur:
          if (originalImageBytes != null) {
            result = await _applyBlurBackground(
              foreground,
              originalImageBytes,
              blurRadius ?? 20.0,
            );
          } else {
            result = foreground;
          }
          break;
      }

      return Uint8List.fromList(img.encodePng(result));
    } catch (e) {
      return null;
    }
  }

  static img.Image _applySolidBackground(img.Image foreground, Color color) {
    final result = img.Image(
      width: foreground.width,
      height: foreground.height,
      numChannels: 4,
    );

    final bgR = color.red;
    final bgG = color.green;
    final bgB = color.blue;

    for (int y = 0; y < foreground.height; y++) {
      for (int x = 0; x < foreground.width; x++) {
        final fgPixel = foreground.getPixel(x, y);
        final alpha = fgPixel.a.toInt() / 255.0;

        if (alpha == 0) {
          result.setPixelRgba(x, y, bgR, bgG, bgB, 255);
        } else if (alpha == 1) {
          result.setPixelRgba(x, y, fgPixel.r.toInt(), fgPixel.g.toInt(), fgPixel.b.toInt(), 255);
        } else {
          final r = (fgPixel.r.toInt() * alpha + bgR * (1 - alpha)).round();
          final g = (fgPixel.g.toInt() * alpha + bgG * (1 - alpha)).round();
          final b = (fgPixel.b.toInt() * alpha + bgB * (1 - alpha)).round();
          result.setPixelRgba(x, y, r, g, b, 255);
        }
      }
    }

    return result;
  }

  static img.Image _applyGradientBackground(img.Image foreground, List<Color> colors) {
    final result = img.Image(
      width: foreground.width,
      height: foreground.height,
      numChannels: 4,
    );

    final startColor = colors.first;
    final endColor = colors.last;

    for (int y = 0; y < foreground.height; y++) {
      final t = y / foreground.height;
      final bgR = (startColor.red + (endColor.red - startColor.red) * t).round();
      final bgG = (startColor.green + (endColor.green - startColor.green) * t).round();
      final bgB = (startColor.blue + (endColor.blue - startColor.blue) * t).round();

      for (int x = 0; x < foreground.width; x++) {
        final fgPixel = foreground.getPixel(x, y);
        final alpha = fgPixel.a.toInt() / 255.0;

        if (alpha == 0) {
          result.setPixelRgba(x, y, bgR, bgG, bgB, 255);
        } else if (alpha == 1) {
          result.setPixelRgba(x, y, fgPixel.r.toInt(), fgPixel.g.toInt(), fgPixel.b.toInt(), 255);
        } else {
          final r = (fgPixel.r.toInt() * alpha + bgR * (1 - alpha)).round();
          final g = (fgPixel.g.toInt() * alpha + bgG * (1 - alpha)).round();
          final b = (fgPixel.b.toInt() * alpha + bgB * (1 - alpha)).round();
          result.setPixelRgba(x, y, r, g, b, 255);
        }
      }
    }

    return result;
  }

  static Future<img.Image> _applyBlurBackground(
    img.Image foreground,
    Uint8List originalBytes,
    double blurRadius,
  ) async {
    final original = img.decodeImage(originalBytes);
    if (original == null) return foreground;

    final blurred = img.gaussianBlur(original, radius: blurRadius.toInt());

    final result = img.Image(
      width: foreground.width,
      height: foreground.height,
      numChannels: 4,
    );

    for (int y = 0; y < foreground.height; y++) {
      for (int x = 0; x < foreground.width; x++) {
        final fgPixel = foreground.getPixel(x, y);
        final alpha = fgPixel.a.toInt() / 255.0;

        if (alpha == 0) {
          final bgPixel = blurred.getPixel(x, y);
          result.setPixelRgba(x, y, bgPixel.r.toInt(), bgPixel.g.toInt(), bgPixel.b.toInt(), 255);
        } else if (alpha == 1) {
          result.setPixelRgba(x, y, fgPixel.r.toInt(), fgPixel.g.toInt(), fgPixel.b.toInt(), 255);
        } else {
          final bgPixel = blurred.getPixel(x, y);
          final r = (fgPixel.r.toInt() * alpha + bgPixel.r.toInt() * (1 - alpha)).round();
          final g = (fgPixel.g.toInt() * alpha + bgPixel.g.toInt() * (1 - alpha)).round();
          final b = (fgPixel.b.toInt() * alpha + bgPixel.b.toInt() * (1 - alpha)).round();
          result.setPixelRgba(x, y, r, g, b, 255);
        }
      }
    }

    return result;
  }

  static Future<Uint8List?> exportImage({
    required Uint8List imageBytes,
    required ExportFormat format,
    int quality = 90,
  }) async {
    try {
      final image = img.decodeImage(imageBytes);
      if (image == null) return null;

      switch (format) {
        case ExportFormat.png:
          return Uint8List.fromList(img.encodePng(image));
        case ExportFormat.jpeg:
          return Uint8List.fromList(img.encodeJpg(image, quality: quality));
        case ExportFormat.webp:
          return Uint8List.fromList(img.encodePng(image));
      }
    } catch (e) {
      return null;
    }
  }
}

enum ExportFormat { png, jpeg, webp }
