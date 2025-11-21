import 'dart:typed_data';
import 'package:archive/archive.dart';
import 'docx_image_service.dart';

/// Direct DOCX manipulation service that bypasses docx_template
class DirectDocxService {
  static Future<Uint8List> generateFromTemplate({
    required Uint8List templateBytes,
    required Map<String, dynamic> data,
    Map<String, Uint8List>? images,
  }) async {
    try {
      print('🔧 DirectDocxService: Processing template directly');
      final archive = ZipDecoder().decodeBytes(templateBytes);
      
      // Build comprehensive replacement map
      final replacements = <String, String>{};
      final imageData = <String, Uint8List>{};
      
      data.forEach((key, value) {
        if (value == null) {
          replacements[key] = '';
        } else if (value is Uint8List) {
          imageData[key] = value;
        } else if (value is List) {
          // Skip lists for now - handle tables separately
          if (value.isNotEmpty && value.first is! Map) {
            replacements[key] = value.join(', ');
          }
        } else if (value is! Map) {
          replacements[key] = _escapeXml(value.toString());
        }
      });
      
      // Add images if provided
      if (images != null) {
        imageData.addAll(images);
      }
      
      print('📊 Replacements prepared: ${replacements.length} text, ${imageData.length} images');
      
      // Process all XML files in the archive
      for (int i = 0; i < archive.files.length; i++) {
        final file = archive.files[i];
        if (!file.isFile) continue;
        
        final name = file.name;
        if (name.endsWith('.xml')) {
          String content = String.fromCharCodes(file.content as List<int>);
          final originalLength = content.length;
          
          // Replace all placeholder patterns
          content = _replaceAllPatterns(content, replacements);
          
          // Handle table data if this is document.xml
          if (name == 'word/document.xml' && data['trees'] is List) {
            content = _processTableData(content, data['trees'] as List);
          }
          
          if (content.length != originalLength) {
            print('✅ Modified ${name}: ${originalLength} -> ${content.length} chars');
          }
          
          archive[i] = ArchiveFile(name, content.length, content.codeUnits);
        }
      }
      
      // Handle images by adding them to media folder and updating relationships
      if (imageData.isNotEmpty) {
        _embedImages(archive, imageData);
      }
      
      // First encode the document with text replacements
      var encoded = ZipEncoder().encode(archive);
      var result = Uint8List.fromList(encoded!);
      
      // Then embed images properly using DocxImageService
      if (imageData.isNotEmpty) {
        result = await DocxImageService.embedImages(
          docxBytes: result,
          images: imageData,
        );
      }
      
      print('✅ DirectDocxService: Document generated');
      return result;
    } catch (e) {
      print('❌ Error in DirectDocxService: $e');
      rethrow;
    }
  }
  
  static String _replaceAllPatterns(String content, Map<String, String> replacements) {
    var result = content;
    
    // First, handle all direct replacements
    replacements.forEach((key, value) {
      // Try all common placeholder formats
      final patterns = [
        '{{$key}}',
        '{$key}',
        '\${$key}',
        '\${{$key}}',
      ];
      
      for (final pattern in patterns) {
        if (result.contains(pattern)) {
          result = result.replaceAll(pattern, value);
        }
      }
      
      // Handle split placeholders (Word often splits text across XML runs)
      result = _replaceSplitPlaceholder(result, key, value);
    });
    
    // Second pass: Clean up any unmatched placeholders
    result = _cleanupUnmatchedPlaceholders(result, replacements);
    
    return result;
  }
  
  static String _replaceSplitPlaceholder(String content, String key, String value) {
    // This handles cases where Word splits a placeholder across multiple XML runs
    // e.g., {{spe</w:t></w:r><w:r><w:t>cies}}
    
    // Build a pattern that matches the key with possible XML tags between characters
    final keyChars = key.split('');
    final patternParts = <String>[];
    
    // Start with opening braces
    patternParts.add(r'\{\{');
    
    // Add each character with optional XML between
    for (int i = 0; i < keyChars.length; i++) {
      if (i > 0) {
        patternParts.add(r'(?:</w:t></w:r><w:r[^>]*><w:t[^>]*>)?');
      }
      patternParts.add(RegExp.escape(keyChars[i]));
    }
    
    // End with closing braces
    patternParts.add(r'(?:</w:t></w:r><w:r[^>]*><w:t[^>]*>)?');
    patternParts.add(r'\}\}');
    
    final pattern = patternParts.join('');
    
    try {
      final regex = RegExp(pattern);
      if (regex.hasMatch(content)) {
        content = content.replaceAll(regex, value);
      }
    } catch (e) {
      // Ignore regex errors
    }
    
    return content;
  }
  
  static String _cleanupUnmatchedPlaceholders(String content, Map<String, String> replacements) {
    // Find all remaining placeholders
    final placeholderRegex = RegExp(r'\{\{([^}]+)\}\}');
    
    return content.replaceAllMapped(placeholderRegex, (match) {
      final placeholder = match.group(1)!;
      
      // Try to find a match based on partial key matching
      for (final entry in replacements.entries) {
        // Check if placeholder contains the key
        if (placeholder.toLowerCase().contains(entry.key.toLowerCase())) {
          return entry.value;
        }
        
        // Check if key contains the placeholder
        if (entry.key.toLowerCase().contains(placeholder.toLowerCase())) {
          return entry.value;
        }
        
        // Check for suffix patterns
        if (placeholder.endsWith('_botanical') || placeholder.endsWith('_common')) {
          final base = placeholder.substring(0, placeholder.lastIndexOf('_'));
          if (base == entry.key || entry.key.contains(base)) {
            return entry.value;
          }
        }
      }
      
      // Special handling for known patterns
      if (placeholder.contains('insert_image') || placeholder.contains('insert_im')) {
        return ''; // Image placeholder
      }
      
      if (placeholder.contains('profile_')) {
        if (placeholder.contains('company')) return 'Arborists By Nature';
        return '';
      }
      
      // Remove unmatched
      print('⚠️ Removing unmatched placeholder: {{$placeholder}}');
      return '';
    });
  }
  
  static String _processTableData(String content, List<dynamic> trees) {
    // Find table rows with tree data placeholders and duplicate/fill them
    // This is a simplified approach - in production you'd want more robust XML parsing
    
    if (trees.isEmpty) return content;
    
    // Look for table row patterns with tree placeholders
    final rowPattern = RegExp(r'<w:tr[^>]*>.*?{{species.*?</w:tr>', dotAll: true);
    
    if (rowPattern.hasMatch(content)) {
      final templateRow = rowPattern.firstMatch(content)!.group(0)!;
      final rows = StringBuffer();
      
      for (int i = 0; i < trees.length; i++) {
        final tree = trees[i];
        if (tree is! Map<String, dynamic>) continue;
        
        var row = templateRow;
        
        // Replace placeholders in this row
        tree.forEach((key, value) {
          if (value != null && value is! List && value is! Map) {
            final strValue = _escapeXml(value.toString());
            row = row.replaceAll('{{$key}}', strValue);
            row = row.replaceAll('{$key}', strValue);
          }
        });
        
        rows.write(row);
      }
      
      // Replace the template row with all generated rows
      content = content.replaceFirst(rowPattern, rows.toString());
    }
    
    return content;
  }
  
  static void _embedImages(Archive archive, Map<String, Uint8List> images) {
    // Add images to word/media folder
    int imageId = 1;
    images.forEach((key, imageBytes) {
      final imageName = 'image$imageId.png';
      archive.addFile(ArchiveFile('word/media/$imageName', imageBytes.length, imageBytes));
      imageId++;
    });
    
    // Note: In a complete implementation, you'd also need to:
    // 1. Update word/_rels/document.xml.rels with image relationships
    // 2. Update word/document.xml with image references
    // 3. Handle content types in [Content_Types].xml
  }
  
  static String _escapeXml(String text) {
    return text
        .replaceAll('&', '&amp;')
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;')
        .replaceAll('"', '&quot;')
        .replaceAll("'", '&apos;');
  }
}
