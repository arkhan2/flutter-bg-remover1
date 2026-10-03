import 'dart:typed_data';
import 'package:background_remover/core/services/image_processing_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;

Uint8List _transparentPng() {
  final image = img.Image(width: 8, height: 8, numChannels: 4);
  for (int y = 0; y < 8; y++) {
    for (int x = 0; x < 8; x++) {
      image.setPixelRgba(x, y, 10, 20, 30, x < 4 ? 0 : 255);
    }
  }
  return Uint8List.fromList(img.encodePng(image));
}

void main() {
  test('PNG export keeps an alpha channel', () {
    final exported = ImageProcessingService.exportImageSync(
      imageBytes: _transparentPng(),
      format: ExportFormat.png,
    );
    expect(exported, isNotNull);

    final decoded = img.decodeImage(exported!);
    expect(decoded, isNotNull);
    expect(decoded!.hasPalette, isFalse);
    expect(decoded.numChannels, 4);
    expect(decoded.getPixel(0, 0).a.toInt(), 0);
    expect(decoded.getPixel(7, 0).a.toInt(), 255);
  });

  test('JPEG export is opaque', () {
    final exported = ImageProcessingService.exportImageSync(
      imageBytes: _transparentPng(),
      format: ExportFormat.jpeg,
      quality: 80,
    );
    expect(exported, isNotNull);

    final decoded = img.decodeImage(exported!);
    expect(decoded, isNotNull);
    expect(decoded!.getPixel(0, 0).a.toInt(), 255);
  });

  test('export formats are only png and jpeg', () {
    expect(ExportFormat.values, [ExportFormat.png, ExportFormat.jpeg]);
  });
}
