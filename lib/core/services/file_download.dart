import 'dart:typed_data';
import 'file_download_stub.dart' if (dart.library.html) 'file_download_web.dart' as impl;

void downloadBytes(Uint8List bytes, String filename, String mimeType) {
  impl.downloadBytesImpl(bytes, filename, mimeType);
}
