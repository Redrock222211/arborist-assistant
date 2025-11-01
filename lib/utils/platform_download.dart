import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;

// Conditional imports
import 'platform_download_stub.dart'
    if (dart.library.html) 'platform_download_web.dart'
    if (dart.library.io) 'platform_download_mobile.dart';

Future<void> downloadFile(Uint8List bytes, String filename, String mimeType) async {
  await downloadFileImpl(bytes, filename, mimeType);
}

Future<void> openUrlInBrowser(String url) async {
  await openUrlImpl(url);
}
