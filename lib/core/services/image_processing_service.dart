import 'package:flutter/foundation.dart';
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
  }) {
    return compute(_applyBackgroundIsolate, <String, Object?>{
      'foreground': foregroundBytes,
      'type': backgroundType.index,
      'solid': solidColor?.toARGB32(),
      'gradient': gradientColors?.map((c) => c.toARGB32()).toList(),
      'blur': blurRadius,
      'original': originalImageBytes,
    });
  }

  static Future<Uint8List?> exportImage({
    required Uint8List imageBytes,
    required ExportFormat format,
    int quality = 90,
  }) {
    return compute(_exportImageIsolate, <String, Object?>{
      'bytes': imageBytes,
      'format': format.index,
      'quality': quality,
    });
  }

  static Uint8List? exportImageSync({
    required Uint8List imageBytes,
    required ExportFormat format,
    int quality = 90,
  }) {
    return _exportImageIsolate(<String, Object?>{
      'bytes': imageBytes,
      'format': format.index,
      'quality': quality,
    });
  }
}

enum ExportFormat { png, jpeg }

Uint8List? _applyBackgroundIsolate(Map<String, Object?> args) {
  try {
    final foregroundBytes = args['foreground'] as Uint8List;
    final foreground = img.decodeImage(foregroundBytes);
    if (foreground == null) return null;

    final type = BackgroundType.values[args['type'] as int];
    img.Image result;

    switch (type) {
      case BackgroundType.transparent:
        result = foreground;
        break;
      case BackgroundType.solid:
        result = _applySolidBackground(
          foreground,
          args['solid'] as int? ?? 0xFFFFFFFF,
        );
        break;
      case BackgroundType.gradient:
        final colors = (args['gradient'] as List<dynamic>?)
                ?.map((e) => e as int)
                .toList() ??
            const [0xFF2196F3, 0xFF9C27B0];
        result = _applyGradientBackground(foreground, colors);
        break;
      case BackgroundType.blur:
        final originalBytes = args['original'] as Uint8List?;
        final blurRadius = (args['blur'] as num?)?.toDouble() ?? 20.0;
        if (originalBytes != null) {
          result = _applyBlurBackground(foreground, originalBytes, blurRadius);
        } else {
          result = foreground;
        }
        break;
    }

    return Uint8List.fromList(img.encodePng(result));
  } catch (_) {
    return null;
  }
}

Uint8List? _exportImageIsolate(Map<String, Object?> args) {
  try {
    final imageBytes = args['bytes'] as Uint8List;
    final image = img.decodeImage(imageBytes);
    if (image == null) return null;

    final format = ExportFormat.values[args['format'] as int];
    final quality = args['quality'] as int? ?? 90;

    switch (format) {
      case ExportFormat.png:
        return Uint8List.fromList(img.encodePng(image));
      case ExportFormat.jpeg:
        return Uint8List.fromList(img.encodeJpg(image, quality: quality));
    }
  } catch (_) {
    return null;
  }
}

int _red(int color) => (color >> 16) & 0xFF;
int _green(int color) => (color >> 8) & 0xFF;
int _blue(int color) => color & 0xFF;

img.Image _applySolidBackground(img.Image foreground, int color) {
  final result = img.Image(
    width: foreground.width,
    height: foreground.height,
    numChannels: 4,
  );

  final bgR = _red(color);
  final bgG = _green(color);
  final bgB = _blue(color);

  for (int y = 0; y < foreground.height; y++) {
    for (int x = 0; x < foreground.width; x++) {
      _compositePixel(result, foreground, x, y, bgR, bgG, bgB);
    }
  }

  return result;
}

img.Image _applyGradientBackground(img.Image foreground, List<int> colors) {
  final result = img.Image(
    width: foreground.width,
    height: foreground.height,
    numChannels: 4,
  );

  final startColor = colors.first;
  final endColor = colors.last;
  final startR = _red(startColor);
  final startG = _green(startColor);
  final startB = _blue(startColor);
  final endR = _red(endColor);
  final endG = _green(endColor);
  final endB = _blue(endColor);

  for (int y = 0; y < foreground.height; y++) {
    final t = y / foreground.height;
    final bgR = (startR + (endR - startR) * t).round();
    final bgG = (startG + (endG - startG) * t).round();
    final bgB = (startB + (endB - startB) * t).round();

    for (int x = 0; x < foreground.width; x++) {
      _compositePixel(result, foreground, x, y, bgR, bgG, bgB);
    }
  }

  return result;
}

img.Image _applyBlurBackground(
  img.Image foreground,
  Uint8List originalBytes,
  double blurRadius,
) {
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
      if (x >= blurred.width || y >= blurred.height) {
        final fgPixel = foreground.getPixel(x, y);
        result.setPixelRgba(
          x,
          y,
          fgPixel.r.toInt(),
          fgPixel.g.toInt(),
          fgPixel.b.toInt(),
          fgPixel.a.toInt(),
        );
        continue;
      }
      final bgPixel = blurred.getPixel(x, y);
      _compositePixel(
        result,
        foreground,
        x,
        y,
        bgPixel.r.toInt(),
        bgPixel.g.toInt(),
        bgPixel.b.toInt(),
      );
    }
  }

  return result;
}

void _compositePixel(
  img.Image result,
  img.Image foreground,
  int x,
  int y,
  int bgR,
  int bgG,
  int bgB,
) {
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
