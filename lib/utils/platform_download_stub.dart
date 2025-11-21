import 'dart:typed_data';

Future<void> downloadFile(Uint8List bytes, String filename, String mimeType) async {
  throw UnsupportedError('File downloads are not supported on this platform.');
}

Future<void> openUrlInBrowser(String url) async {
  throw UnsupportedError('Opening URLs is not supported on this platform.');
}
