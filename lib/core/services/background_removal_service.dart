import 'dart:typed_data';
import 'package:image/image.dart' as img;

class BackgroundRemovalService {
  static Future<Uint8List?> removeBackground(Uint8List imageBytes) async {
    try {
      final image = img.decodeImage(imageBytes);
      if (image == null) return null;

      final result = _removeBackgroundLocal(image);
      return Uint8List.fromList(img.encodePng(result));
    } catch (e) {
      return null;
    }
  }

  static img.Image _removeBackgroundLocal(img.Image image) {
    final result = img.Image(
      width: image.width,
      height: image.height,
      numChannels: 4,
    );

    final edgeColors = _detectEdgeColors(image);
    final dominantColor = _findDominantColor(edgeColors);
    final tolerance = 45;

    for (int y = 0; y < image.height; y++) {
      for (int x = 0; x < image.width; x++) {
        final pixel = image.getPixel(x, y);
        final r = pixel.r.toInt();
        final g = pixel.g.toInt();
        final b = pixel.b.toInt();

        final isBackground = _colorDistance(
          r, g, b,
          dominantColor[0], dominantColor[1], dominantColor[2],
        ) < tolerance;

        if (isBackground) {
          result.setPixelRgba(x, y, 0, 0, 0, 0);
        } else {
          result.setPixelRgba(x, y, r, g, b, pixel.a.toInt());
        }
      }
    }

    return _refineEdges(result);
  }

  static List<List<int>> _detectEdgeColors(img.Image image) {
    final colors = <List<int>>[];
    final sampleSize = 10;

    for (int x = 0; x < image.width; x += sampleSize) {
      final topPixel = image.getPixel(x, 0);
      colors.add([topPixel.r.toInt(), topPixel.g.toInt(), topPixel.b.toInt()]);
      
      final bottomPixel = image.getPixel(x, image.height - 1);
      colors.add([bottomPixel.r.toInt(), bottomPixel.g.toInt(), bottomPixel.b.toInt()]);
    }

    for (int y = 0; y < image.height; y += sampleSize) {
      final leftPixel = image.getPixel(0, y);
      colors.add([leftPixel.r.toInt(), leftPixel.g.toInt(), leftPixel.b.toInt()]);
      
      final rightPixel = image.getPixel(image.width - 1, y);
      colors.add([rightPixel.r.toInt(), rightPixel.g.toInt(), rightPixel.b.toInt()]);
    }

    return colors;
  }

  static List<int> _findDominantColor(List<List<int>> colors) {
    if (colors.isEmpty) return [255, 255, 255];

    final colorCounts = <String, int>{};
    final colorMap = <String, List<int>>{};

    for (final color in colors) {
      final quantizedR = (color[0] ~/ 16) * 16;
      final quantizedG = (color[1] ~/ 16) * 16;
      final quantizedB = (color[2] ~/ 16) * 16;
      final key = '$quantizedR,$quantizedG,$quantizedB';
      
      colorCounts[key] = (colorCounts[key] ?? 0) + 1;
      colorMap[key] = [quantizedR, quantizedG, quantizedB];
    }

    String dominantKey = colorCounts.keys.first;
    int maxCount = 0;

    colorCounts.forEach((key, count) {
      if (count > maxCount) {
        maxCount = count;
        dominantKey = key;
      }
    });

    return colorMap[dominantKey] ?? [255, 255, 255];
  }

  static double _colorDistance(int r1, int g1, int b1, int r2, int g2, int b2) {
    final dr = r1 - r2;
    final dg = g1 - g2;
    final db = b1 - b2;
    return (dr * dr + dg * dg + db * db).toDouble();
  }

  static img.Image _refineEdges(img.Image image) {
    final result = img.Image(
      width: image.width,
      height: image.height,
      numChannels: 4,
    );

    for (int y = 0; y < image.height; y++) {
      for (int x = 0; x < image.width; x++) {
        final pixel = image.getPixel(x, y);
        
        if (pixel.a.toInt() > 0) {
          int transparentNeighbors = 0;
          int totalNeighbors = 0;

          for (int dy = -1; dy <= 1; dy++) {
            for (int dx = -1; dx <= 1; dx++) {
              if (dx == 0 && dy == 0) continue;
              
              final nx = x + dx;
              final ny = y + dy;
              
              if (nx >= 0 && nx < image.width && ny >= 0 && ny < image.height) {
                totalNeighbors++;
                if (image.getPixel(nx, ny).a.toInt() == 0) {
                  transparentNeighbors++;
                }
              }
            }
          }

          if (totalNeighbors > 0 && transparentNeighbors > 0) {
            final edgeFactor = 1.0 - (transparentNeighbors / totalNeighbors) * 0.3;
            final newAlpha = (pixel.a.toInt() * edgeFactor).clamp(0, 255).toInt();
            result.setPixelRgba(x, y, pixel.r.toInt(), pixel.g.toInt(), pixel.b.toInt(), newAlpha);
          } else {
            result.setPixelRgba(x, y, pixel.r.toInt(), pixel.g.toInt(), pixel.b.toInt(), pixel.a.toInt());
          }
        } else {
          result.setPixelRgba(x, y, 0, 0, 0, 0);
        }
      }
    }

    return result;
  }
}
