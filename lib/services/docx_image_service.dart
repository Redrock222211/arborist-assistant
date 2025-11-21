import 'dart:typed_data';
import 'package:archive/archive.dart';
import 'package:uuid/uuid.dart';

/// Service to properly embed images in DOCX files
class DocxImageService {
  static const _uuid = Uuid();
  
  /// Process a DOCX file and embed images properly
  static Future<Uint8List> embedImages({
    required Uint8List docxBytes,
    required Map<String, Uint8List> images,
  }) async {
    if (images.isEmpty) {
      return docxBytes;
    }
    
    try {
      print('🖼️ Embedding ${images.length} images in DOCX');
      final archive = ZipDecoder().decodeBytes(docxBytes);
      
      // Track relationships for images
      final imageRelationships = <String, String>{};
      final mediaFiles = <String, Uint8List>{};
      
      // Process each image
      int imageId = 1;
      images.forEach((placeholder, imageBytes) {
        final imageFileName = 'image$imageId.png';
        final rId = 'rId${1000 + imageId}'; // Use high IDs to avoid conflicts
        
        mediaFiles[imageFileName] = imageBytes;
        imageRelationships[placeholder] = rId;
        
        // Add image to media folder
        archive.addFile(ArchiveFile(
          'word/media/$imageFileName',
          imageBytes.length,
          imageBytes,
        ));
        
        imageId++;
      });
      
      // Update document.xml to reference images
      _updateDocumentXml(archive, imageRelationships);
      
      // Update relationships file
      _updateRelationships(archive, mediaFiles);
      
      // Update content types
      _updateContentTypes(archive);
      
      final encoded = ZipEncoder().encode(archive);
      print('✅ Images embedded successfully');
      return Uint8List.fromList(encoded!);
    } catch (e) {
      print('❌ Error embedding images: $e');
      return docxBytes; // Return original if embedding fails
    }
  }
  
  static void _updateDocumentXml(Archive archive, Map<String, String> imageRelationships) {
    final docIndex = archive.files.indexWhere((f) => f.name == 'word/document.xml');
    if (docIndex == -1) return;
    
    String content = String.fromCharCodes(archive.files[docIndex].content as List<int>);
    
    // Replace image placeholders with actual image references
    imageRelationships.forEach((placeholder, rId) {
      // Look for various image placeholder patterns
      final patterns = [
        '{{$placeholder}}',
        '{$placeholder}',
        placeholder,
      ];
      
      for (final pattern in patterns) {
        if (content.contains(pattern)) {
          // Create proper Word image XML
          final imageXml = _createImageXml(rId);
          content = content.replaceAll(pattern, imageXml);
        }
      }
    });
    
    archive[docIndex] = ArchiveFile(
      'word/document.xml',
      content.length,
      content.codeUnits,
    );
  }
  
  static String _createImageXml(String rId) {
    final docId = _uuid.v4().replaceAll('-', '');
    final name = 'Picture ${rId.substring(3)}';
    
    return '''<w:r>
      <w:drawing>
        <wp:inline distT="0" distB="0" distL="0" distR="0">
          <wp:extent cx="5486400" cy="3657600"/>
          <wp:effectExtent l="0" t="0" r="0" b="0"/>
          <wp:docPr id="$docId" name="$name"/>
          <wp:cNvGraphicFramePr>
            <a:graphicFrameLocks xmlns:a="http://schemas.openxmlformats.org/drawingml/2006/main" noChangeAspect="1"/>
          </wp:cNvGraphicFramePr>
          <a:graphic xmlns:a="http://schemas.openxmlformats.org/drawingml/2006/main">
            <a:graphicData uri="http://schemas.openxmlformats.org/drawingml/2006/picture">
              <pic:pic xmlns:pic="http://schemas.openxmlformats.org/drawingml/2006/picture">
                <pic:nvPicPr>
                  <pic:cNvPr id="0" name="$name"/>
                  <pic:cNvPicPr/>
                </pic:nvPicPr>
                <pic:blipFill>
                  <a:blip r:embed="$rId" xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships"/>
                  <a:stretch>
                    <a:fillRect/>
                  </a:stretch>
                </pic:blipFill>
                <pic:spPr>
                  <a:xfrm>
                    <a:off x="0" y="0"/>
                    <a:ext cx="5486400" cy="3657600"/>
                  </a:xfrm>
                  <a:prstGeom prst="rect">
                    <a:avLst/>
                  </a:prstGeom>
                </pic:spPr>
              </pic:pic>
            </a:graphicData>
          </a:graphic>
        </wp:inline>
      </w:drawing>
    </w:r>''';
  }
  
  static void _updateRelationships(Archive archive, Map<String, Uint8List> mediaFiles) {
    final relsPath = 'word/_rels/document.xml.rels';
    final relsIndex = archive.files.indexWhere((f) => f.name == relsPath);
    
    String relsContent;
    if (relsIndex == -1) {
      // Create new relationships file
      relsContent = '''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">
</Relationships>''';
    } else {
      relsContent = String.fromCharCodes(archive.files[relsIndex].content as List<int>);
    }
    
    // Add image relationships
    final endTag = '</Relationships>';
    final imageRels = StringBuffer();
    int imageId = 1;
    
    mediaFiles.forEach((fileName, _) {
      final rId = 'rId${1000 + imageId}';
      imageRels.writeln(
        '<Relationship Id="$rId" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/image" Target="media/$fileName"/>',
      );
      imageId++;
    });
    
    relsContent = relsContent.replaceAll(
      endTag,
      '${imageRels.toString()}$endTag',
    );
    
    if (relsIndex == -1) {
      archive.addFile(ArchiveFile(relsPath, relsContent.length, relsContent.codeUnits));
    } else {
      archive[relsIndex] = ArchiveFile(relsPath, relsContent.length, relsContent.codeUnits);
    }
  }
  
  static void _updateContentTypes(Archive archive) {
    final ctPath = '[Content_Types].xml';
    final ctIndex = archive.files.indexWhere((f) => f.name == ctPath);
    if (ctIndex == -1) return;
    
    String content = String.fromCharCodes(archive.files[ctIndex].content as List<int>);
    
    // Add PNG content type if not present
    if (!content.contains('Extension="png"')) {
      final endTag = '</Types>';
      content = content.replaceAll(
        endTag,
        '<Default Extension="png" ContentType="image/png"/>$endTag',
      );
    }
    
    // Add JPEG content type if not present
    if (!content.contains('Extension="jpeg"') && !content.contains('Extension="jpg"')) {
      final endTag = '</Types>';
      content = content.replaceAll(
        endTag,
        '<Default Extension="jpeg" ContentType="image/jpeg"/><Default Extension="jpg" ContentType="image/jpeg"/>$endTag',
      );
    }
    
    archive[ctIndex] = ArchiveFile(ctPath, content.length, content.codeUnits);
  }
}
