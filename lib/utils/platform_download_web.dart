import 'dart:typed_data';
import 'dart:html' as html;

Future<void> downloadFileImpl(Uint8List bytes, String filename, String mimeType) async {
  final blob = html.Blob([bytes], mimeType);
  final url = html.Url.createObjectUrlFromBlob(blob);
  final anchor = html.AnchorElement(href: url)
    ..setAttribute('download', filename)
    ..click();
  html.Url.revokeObjectUrl(url);
}

Future<void> openUrlImpl(String url) async {
  html.window.open(url, '_blank');
}
