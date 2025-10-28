import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:share_plus/share_plus.dart';
import 'package:flutter/foundation.dart';
import 'dart:io';
import 'dart:typed_data';
import '../models/site_file.dart';
import 'package:uuid/uuid.dart';

class SiteFileService {
  static const String boxName = 'site_files';
  static const _uuid = Uuid();

  static Future<void> init() async {
    await Hive.initFlutter();
    if (!Hive.isAdapterRegistered(5)) {
      Hive.registerAdapter(SiteFileAdapter());
    }
    await Hive.openBox<SiteFile>(boxName);
  }

  static Future<List<SiteFile>> getFilesForSite(String siteId) async {
    final box = Hive.box<SiteFile>(boxName);
    if (!box.isOpen) {
      await Hive.openBox<SiteFile>(boxName);
    }
    return box.values.where((file) => file.siteId == siteId).toList();
  }

  static Future<SiteFile?> getFile(String fileId) async {
    final box = Hive.box<SiteFile>(boxName);
    return box.values.firstWhere((file) => file.id == fileId);
  }

  static Future<void> addFile(SiteFile file) async {
    final box = Hive.box<SiteFile>(boxName);
    await box.add(file);
  }

  static Future<void> updateFile(String fileId, SiteFile updatedFile) async {
    final box = Hive.box<SiteFile>(boxName);
    final key = box.keys.firstWhere((k) => box.get(k)?.id == fileId);
    await box.put(key, updatedFile);
  }

  static Future<void> deleteFile(String fileId) async {
    final box = Hive.box<SiteFile>(boxName);
    if (!box.isOpen) {
      await Hive.openBox<SiteFile>(boxName);
    }
    final file = box.values.firstWhere((file) => file.id == fileId);
    
    // Delete local file
    try {
      final localFile = File(file.filePath);
      if (await localFile.exists()) {
        await localFile.delete();
      }
    } catch (e) {
      print('Error deleting local file: $e');
    }
    
    // Remove from database
    final key = box.keys.firstWhere((k) => box.get(k)?.id == fileId);
    await box.delete(key);
  }

  static String _getFileExtension(String fileName) {
    final parts = fileName.split('.');
    return parts.length > 1 ? parts.last.toLowerCase() : '';
  }

  static String _getFileType(String extension) {
    switch (extension.toLowerCase()) {
      case 'pdf':
        return 'PDF Document';
      case 'doc':
      case 'docx':
        return 'Word Document';
      case 'xls':
      case 'xlsx':
        return 'Excel Spreadsheet';
      case 'jpg':
      case 'jpeg':
      case 'png':
      case 'gif':
        return 'Image';
      case 'dwg':
        return 'AutoCAD Drawing';
      case 'txt':
        return 'Text File';
      case 'csv':
        return 'CSV File';
      default:
        return 'Unknown File';
    }
  }

  static String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }

  static Future<SiteFile?> pickAndUploadFile(String siteId, String uploadedBy) async {
    try {
      final result = await FilePicker.platform.pickFiles(
        allowMultiple: false,
        type: FileType.any,
      );

      if (result != null && result.files.single.path != null) {
        final platformFile = result.files.single;
        final originalName = platformFile.name;
        final fileSize = platformFile.size;
        final extension = _getFileExtension(originalName);
        final fileType = _getFileType(extension);

        // Create unique filename
        final fileName = '${_uuid.v4()}.$extension';
        
        // For web, we'll store the file data directly
        String filePath;
        if (kIsWeb) {
          // Web: store file data in memory/database
          filePath = 'web://$fileName';
        } else {
          // Mobile/Desktop: store in file system
          final appDir = await getApplicationDocumentsDirectory();
          final siteDir = Directory('${appDir.path}/sites/$siteId/files');
          if (!await siteDir.exists()) {
            await siteDir.create(recursive: true);
          }
          filePath = '${siteDir.path}/$fileName';
          
          // Copy file to app directory
          final originalFile = File(platformFile.path!);
          await originalFile.copy(filePath);
        }
        
        // Create SiteFile object
        final siteFile = SiteFile(
          id: _uuid.v4(),
          siteId: siteId,
          fileName: fileName,
          originalName: originalName,
          filePath: filePath,
          fileType: fileType,
          fileSize: fileSize,
          uploadDate: DateTime.now(),
          uploadedBy: uploadedBy,
        );
        
        // Save to database
        await addFile(siteFile);
        
        return siteFile;
      }
    } catch (e) {
      print('Error picking/uploading file: $e');
    }
    return null;
  }

  static Future<void> downloadFile(SiteFile file) async {
    try {
      if (kIsWeb) {
        // Web: show info message
        print('Web download not yet implemented for: ${file.originalName}');
        // TODO: Implement web download using html package
      } else {
        final localFile = File(file.filePath);
        if (await localFile.exists()) {
          await Share.shareXFiles([XFile(file.filePath)], text: 'File: ${file.originalName}');
        } else {
          throw Exception('File not found locally');
        }
      }
    } catch (e) {
      print('Error downloading file: $e');
      rethrow;
    }
  }

  static Future<void> shareFile(SiteFile file) async {
    try {
      if (kIsWeb) {
        // Web: show info message
        print('Web sharing not yet implemented for: ${file.originalName}');
        // TODO: Implement web sharing
      } else {
        final localFile = File(file.filePath);
        if (await localFile.exists()) {
          await Share.shareXFiles([XFile(file.filePath)], text: 'Site file: ${file.originalName}');
        } else {
          throw Exception('File not found locally');
        }
      }
    } catch (e) {
      print('Error sharing file: $e');
      rethrow;
    }
  }

  static Future<void> updateFileDescription(String fileId, String description) async {
    final file = await getFile(fileId);
    if (file != null) {
      final updatedFile = file.copyWith(description: description);
      await updateFile(fileId, updatedFile);
    }
  }

  static Future<SiteFile?> saveFileFromBytes(String siteId, List<int> bytes, String fileName, String fileType) async {
    try {
      final originalName = fileName;
      final fileSize = bytes.length;
      final extension = _getFileExtension(fileName);
      final fileTypeDescription = _getFileType(extension);

      // Create unique filename
      final uniqueFileName = '${_uuid.v4()}.$extension';
      
      // For web, we'll store the file data directly
      String filePath;
      if (kIsWeb) {
        // Web: store file data in memory/database
        filePath = 'web://$uniqueFileName';
      } else {
        // Mobile/Desktop: store in file system
        final appDir = await getApplicationDocumentsDirectory();
        final siteDir = Directory('${appDir.path}/sites/$siteId/files');
        if (!await siteDir.exists()) {
          await siteDir.create(recursive: true);
        }
        filePath = '${siteDir.path}/$uniqueFileName';
        
        // Write bytes to file
        final file = File(filePath);
        await file.writeAsBytes(bytes);
      }
      
      // Create SiteFile object
      final siteFile = SiteFile(
        id: _uuid.v4(),
        siteId: siteId,
        fileName: uniqueFileName,
        originalName: originalName,
        filePath: filePath,
        fileType: fileTypeDescription,
        fileSize: fileSize,
        uploadDate: DateTime.now(),
        uploadedBy: 'System',
      );
      
      // Save to database
      await addFile(siteFile);
      
      return siteFile;
    } catch (e) {
      print('Error saving file from bytes: $e');
      return null;
    }
  }

  static Future<void> updateFileCategory(String fileId, String category) async {
    final file = await getFile(fileId);
    if (file != null) {
      final updatedFile = file.copyWith(category: category);
      await updateFile(fileId, updatedFile);
    }
  }

  static List<String> getFileCategories() {
    return [
      'General',
      'Reports',
      'Maps',
      'Photos',
      'Drawings',
      'Permits',
      'Contracts',
      'Invoices',
      'Specifications',
      'Other',
    ];
  }

  static String formatFileSize(int bytes) {
    return _formatFileSize(bytes);
  }
}
