import 'dart:typed_data';
import 'package:archive/archive.dart';

/// Simple DOCX template service that replaces ${placeholder} with values
class SimpleDocxService {
  
  /// Process a DOCX template and replace placeholders
  static Future<Uint8List> processTemplate({
    required Uint8List templateBytes,
    required Map<String, dynamic> data,
  }) async {
    try {
      // Decode the DOCX (which is a ZIP file)
      final archive = ZipDecoder().decodeBytes(templateBytes);
      
      // Process document.xml
      final docFile = archive.findFile('word/document.xml');
      if (docFile != null) {
        // Get the content
        final contentBytes = docFile.content as List<int>;
        String content = String.fromCharCodes(contentBytes);
        
        // Replace all placeholders
        data.forEach((key, value) {
          if (value != null && value is! List && value is! Uint8List) {
            final placeholder = '\${$key}';
            final replacement = value.toString();
            content = content.replaceAll(placeholder, _escapeXml(replacement));
          }
        });
        
        // Create a new file with updated content
        final newFile = ArchiveFile('word/document.xml', content.length, content.codeUnits);
        
        // Find the index of the old file
        final index = archive.files.indexWhere((f) => f.name == 'word/document.xml');
        if (index >= 0) {
          // Use the Archive's operator []= to replace the file
          archive[index] = newFile;
        }
      }
      
      // Process headers
      for (int i = 1; i <= 3; i++) {
        final headerName = 'word/header$i.xml';
        final headerFile = archive.findFile(headerName);
        if (headerFile != null) {
          String content = String.fromCharCodes(headerFile.content as List<int>);
          
          data.forEach((key, value) {
            if (value != null && value is! List && value is! Uint8List) {
              final placeholder = '\${$key}';
              final replacement = value.toString();
              content = content.replaceAll(placeholder, _escapeXml(replacement));
            }
          });
          
          // Replace the file
          final newFile = ArchiveFile(headerName, content.length, content.codeUnits);
          final index = archive.files.indexWhere((f) => f.name == headerName);
          if (index >= 0) {
            archive[index] = newFile;
          }
        }
      }
      
      // Process footers
      for (int i = 1; i <= 3; i++) {
        final footerName = 'word/footer$i.xml';
        final footerFile = archive.findFile(footerName);
        if (footerFile != null) {
          String content = String.fromCharCodes(footerFile.content as List<int>);
          
          data.forEach((key, value) {
            if (value != null && value is! List && value is! Uint8List) {
              final placeholder = '\${$key}';
              final replacement = value.toString();
              content = content.replaceAll(placeholder, _escapeXml(replacement));
            }
          });
          
          // Replace the file
          final newFile = ArchiveFile(footerName, content.length, content.codeUnits);
          final index = archive.files.indexWhere((f) => f.name == footerName);
          if (index >= 0) {
            archive[index] = newFile;
          }
        }
      }
      
      // Encode back to ZIP
      final encoder = ZipEncoder();
      final outputBytes = encoder.encode(archive);
      
      if (outputBytes != null) {
        return Uint8List.fromList(outputBytes);
      } else {
        throw Exception('Failed to encode DOCX');
      }
    } catch (e) {
      print('Error processing DOCX template: $e');
      rethrow;
    }
  }
  
  /// Escape special XML characters
  static String _escapeXml(String text) {
    return text
      .replaceAll('&', '&amp;')
      .replaceAll('<', '&lt;')
      .replaceAll('>', '&gt;')
      .replaceAll('"', '&quot;')
      .replaceAll("'", '&apos;');
  }
  
  /// Process template with image support (simplified for now)
  static Future<Uint8List> processTemplateWithImages({
    required Uint8List templateBytes,
    required Map<String, dynamic> data,
    Map<String, Uint8List>? images,
  }) async {
    // For now, just process text
    // Image insertion in DOCX is complex and requires relationship management
    return processTemplate(templateBytes: templateBytes, data: data);
  }
}
