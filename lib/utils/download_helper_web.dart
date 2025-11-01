import 'dart:html' as html;
import 'dart:typed_data';

void downloadFile(Uint8List bytes, String filename, String mimeType) {
  final blob = html.Blob([bytes], mimeType);
  final url = html.Url.createObjectUrlFromBlob(blob);
  final anchor = html.AnchorElement(href: url)
    ..setAttribute('download', filename)
    ..click();
  html.Url.revokeObjectUrl(url);
}

void openUrl(String url) {
  html.window.open(url, '_blank');
}
