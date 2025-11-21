import 'dart:typed_data';
import 'package:archive/archive.dart';

/// Comprehensive DOCX placeholder replacement service that handles all edge cases
class AdvancedDocxService {
  static Future<Uint8List> processTemplate({
    required Uint8List templateBytes,
    required Map<String, dynamic> data,
    List<Map<String, dynamic>>? tableData,
    Map<String, Uint8List>? images,
  }) async {
    try {
      final archive = ZipDecoder().decodeBytes(templateBytes);
      
      // Process all XML parts in the DOCX
      for (int i = 0; i < archive.files.length; i++) {
        final file = archive.files[i];
        if (!file.isFile) continue;
        
        final name = file.name;
        if (name.endsWith('.xml') && 
            (name.contains('document') || 
             name.contains('header') || 
             name.contains('footer'))) {
          
          String content = String.fromCharCodes(file.content as List<int>);
          
          // Replace all placeholder patterns comprehensively
          content = _replaceAllPlaceholders(content, data);
          
          // Update the archive with the processed content
          archive[i] = ArchiveFile(name, content.length, content.codeUnits);
        }
      }
      
      final encoded = ZipEncoder().encode(archive);
      return Uint8List.fromList(encoded!);
    } catch (e) {
      print('❌ Error in AdvancedDocxService: $e');
      rethrow;
    }
  }
  
  static String _replaceAllPlaceholders(String content, Map<String, dynamic> data) {
    var result = content;
    
    // Build comprehensive replacement map
    final replacements = <String, String>{};
    
    data.forEach((key, value) {
      if (value == null || value is List || value is Uint8List) return;
      
      final strValue = _escapeXml(value.toString());
      replacements[key] = strValue;
      
      // Handle table field patterns that docx_template generates
      // When it processes tables, it often creates keys like "species_botanical"
      // from the original "species" field
      if (key == 'species' || key == 'species_botanical' || key == 'species_common') {
        replacements['species'] = strValue;
        replacements['species_botanical'] = strValue;
        replacements['species_common'] = strValue;
      }
      
      // Handle other common suffixed patterns
      if (key.contains('_')) {
        final parts = key.split('_');
        if (parts.length >= 2) {
          final baseKey = parts[0];
          // Also map the base key if not already present
          replacements.putIfAbsent(baseKey, () => strValue);
        }
      }
    });
    
    // First pass: Replace all standard placeholders
    replacements.forEach((key, value) {
      // Direct replacements for various placeholder formats
      result = result.replaceAll('{{$key}}', value);
      result = result.replaceAll('{$key}', value);
      result = result.replaceAll('\${$key}', value);
      
      // Handle cases where the placeholder might be split by XML tags
      // This regex matches the key with possible XML tags or control chars between letters
      final splitPattern = _buildSplitPattern(key);
      if (splitPattern != null) {
        try {
          result = result.replaceAllMapped(
            RegExp(splitPattern),
            (match) => value,
          );
        } catch (e) {
          // Ignore regex errors
        }
      }
    });
    
    // Second pass: Handle complex placeholders that weren't in our data
    // These are placeholders that appear in the template but we don't have exact matches for
    result = result.replaceAllMapped(
      RegExp(r'\{\{([^}]+)\}\}'),
      (match) {
        final placeholder = match.group(1)!;
        
        // Try to find a partial match in our data
        // For example, {{Test Site_address}} might match 'site_address'
        for (final entry in replacements.entries) {
          if (placeholder.contains(entry.key) || 
              placeholder.endsWith('_' + entry.key) ||
              placeholder.startsWith(entry.key + '_')) {
            return entry.value;
          }
        }
        
        // Handle special patterns
        if (placeholder.contains('_address')) {
          return replacements['site_address'] ?? '';
        }
        if (placeholder.contains('_qualifications')) {
          return replacements['assessor_qualifications'] ?? '';
        }
        if (placeholder.contains('_context')) {
          return replacements['site_context'] ?? '';
        }
        if (placeholder.contains('insert_im') || placeholder.contains('insert_image')) {
          // This is an image placeholder, leave it empty
          return '';
        }
        if (placeholder.contains('profile_')) {
          // Profile placeholders - use defaults
          if (placeholder.contains('company_name')) {
            return 'Arborists By Nature';
          }
          return '';
        }
        if (placeholder.endsWith('_number') || placeholder.endsWith('_1')) {
          // Numeric placeholders
          return '0';
        }
        if (placeholder == 'Improbable_of_impact') {
          return 'Improbable';
        }
        
        // Check if this is a value that got duplicated (like species name)
        for (final value in replacements.values) {
          if (placeholder == value || placeholder.startsWith(value + '_')) {
            return value;
          }
        }
        
        print('⚠️ Unmatched placeholder: {{$placeholder}}');
        return ''; // Remove unmatched placeholders
      },
    );
    
    return result;
  }
  
  static String? _buildSplitPattern(String key) {
    if (key.isEmpty) return null;
    
    // Build a pattern that allows for XML tags or control characters between each character
    final buffer = StringBuffer();
    buffer.write(r'\{\{');
    
    for (int i = 0; i < key.length; i++) {
      if (i > 0) {
        // Allow XML tags or control chars between characters
        buffer.write(r'(?:<[^>]+>|\s)*');
      }
      buffer.write(RegExp.escape(key[i]));
    }
    
    buffer.write(r'\}\}');
    return buffer.toString();
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
