import 'dart:typed_data';
import 'dart:html' as html;

Future<void> downloadFile(Uint8List bytes, String filename, String mimeType) async {
  print('📥 Downloading file: $filename');
  print('📊 File size: ${bytes.length} bytes');
  print('📄 MIME type: $mimeType');

  final blob = html.Blob([bytes], mimeType);
  final url = html.Url.createObjectUrlFromBlob(blob);
  final anchor = html.AnchorElement(href: url)
    ..setAttribute('download', filename)
    ..style.display = 'none';

  html.document.body?.append(anchor);
  anchor
    ..click()
    ..remove();

  // Delay revoke to ensure download starts
  Future.delayed(const Duration(seconds: 1), () {
    html.Url.revokeObjectUrl(url);
  });

  print('✅ Download initiated for: $filename');
}

Future<void> openUrlInBrowser(String url) async {
  html.window.open(url, '_blank');
}
