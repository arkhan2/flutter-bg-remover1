import 'dart:math';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;

class ColorSampler {
  ColorSampler._(this._display, this._original);

  final img.Image _display;
  final img.Image? _original;

  int get width => _display.width;
  int get height => _display.height;

  static ColorSampler? fromBytes({
    required Uint8List displayBytes,
    Uint8List? originalBytes,
  }) {
    final display = img.decodeImage(displayBytes);
    if (display == null) return null;
    final original = originalBytes == null ? null : img.decodeImage(originalBytes);
    return ColorSampler._(display, original);
  }

  Color? colorAtDisplayPoint(Offset local, Size boxSize) {
    final mapped = mapToPixel(local, boxSize);
    if (mapped == null) return null;
    return colorAt(mapped.dx.round(), mapped.dy.round());
  }

  Offset? mapToPixel(Offset local, Size boxSize) {
    if (width <= 0 || height <= 0 || boxSize.isEmpty) return null;

    final scale = min(boxSize.width / width, boxSize.height / height);
    final fittedWidth = width * scale;
    final fittedHeight = height * scale;
    final left = (boxSize.width - fittedWidth) / 2;
    final top = (boxSize.height - fittedHeight) / 2;

    final x = ((local.dx - left) / scale).floor();
    final y = ((local.dy - top) / scale).floor();
    if (x < 0 || y < 0 || x >= width || y >= height) return null;
    return Offset(x.toDouble(), y.toDouble());
  }

  Color? colorAt(int x, int y) {
    if (x < 0 || y < 0 || x >= width || y >= height) return null;

    final displayPixel = _display.getPixel(x, y);
    if (displayPixel.a.toInt() >= 16) {
      return _toColor(displayPixel);
    }

    final original = _original;
    if (original != null && x < original.width && y < original.height) {
      final originalPixel = original.getPixel(x, y);
      if (originalPixel.a.toInt() >= 16) {
        return _toColor(originalPixel);
      }
    }

    return null;
  }

  static Color _toColor(img.Pixel pixel) {
    return Color.fromARGB(
      255,
      pixel.r.toInt(),
      pixel.g.toInt(),
      pixel.b.toInt(),
    );
  }
}

String colorToHex(Color color) {
  final r = (color.r * 255.0).round().clamp(0, 255).toRadixString(16).padLeft(2, '0');
  final g = (color.g * 255.0).round().clamp(0, 255).toRadixString(16).padLeft(2, '0');
  final b = (color.b * 255.0).round().clamp(0, 255).toRadixString(16).padLeft(2, '0');
  return '#$r$g$b'.toUpperCase();
}
