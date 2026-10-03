import 'dart:typed_data';
import 'package:background_remover/core/services/background_removal_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;

Uint8List _solidSubjectOnWhite() {
  final image = img.Image(width: 40, height: 40, numChannels: 4);
  img.fill(image, color: img.ColorRgba8(255, 255, 255, 255));
  for (int y = 10; y < 30; y++) {
    for (int x = 10; x < 30; x++) {
      image.setPixelRgba(x, y, 220, 20, 20, 255);
    }
  }
  return Uint8List.fromList(img.encodePng(image));
}

void main() {
  test('makes white edges transparent and keeps the red subject', () {
    final resultBytes = BackgroundRemovalService.removeBackgroundSync(
      _solidSubjectOnWhite(),
    );
    expect(resultBytes, isNotNull);

    final result = img.decodeImage(resultBytes!);
    expect(result, isNotNull);

    final corner = result!.getPixel(0, 0);
    expect(corner.a.toInt(), 0);

    final subject = result.getPixel(20, 20);
    expect(subject.a.toInt(), greaterThan(200));
    expect(subject.r.toInt(), greaterThan(150));
  });

  test('returns null for undecodable bytes', () {
    final result = BackgroundRemovalService.removeBackgroundSync(
      Uint8List.fromList([1, 2, 3, 4]),
    );
    expect(result, isNull);
  });
}
