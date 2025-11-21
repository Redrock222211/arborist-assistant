import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:uuid/uuid.dart';

import '../models/site_file.dart';
import '../utils/platform_download.dart' as platform_download;

class SiteFileService {
  static const String boxName = 'site_files';
  static const _uuid = Uuid();
  static bool? _overrideIsWeb;
  static bool _hiveInitialized = false;

  static bool get _isWeb => _overrideIsWeb ?? kIsWeb;

  static void debugSetIsWeb(bool? value) {
    _overrideIsWeb = value;
  }

  static Future<void> closeForTest() async {
    await Hive.close();
    _hiveInitialized = false;
  }

  static String normalizeFolderPath(String path) {
    if (path.isEmpty || path == '/') {
      return '/';
    }
    var normalized = path.replaceAll('\\', '/');
    if (!normalized.startsWith('/')) {
      normalized = '/$normalized';
    }
    if (normalized.length > 1 && normalized.endsWith('/')) {
      normalized = normalized.substring(0, normalized.length - 1);
    }
    return normalized;
  }

  static String combineFolderPath(String base, String suffix) {
    final normalizedBase = normalizeFolderPath(base);
    var adjustedSuffix = suffix;
    if (adjustedSuffix.isEmpty) {
      return normalizedBase;
    }
    if (adjustedSuffix.startsWith('/')) {
      adjustedSuffix = adjustedSuffix.substring(1);
    }
    if (normalizedBase == '/') {
      return adjustedSuffix.isEmpty ? '/' : '/$adjustedSuffix';
    }
    return '$normalizedBase/${adjustedSuffix.isEmpty ? '' : adjustedSuffix}'
        .replaceAll('//', '/');
  }

  static Future<void> init() async {
    if (!_hiveInitialized) {
      try {
        await Hive.initFlutter();
      } on MissingPluginException {
        final tempDir = Directory.systemTemp.createTempSync('site_files_hive');
        Hive.init(tempDir.path);
      }
      if (!Hive.isAdapterRegistered(5)) {
        Hive.registerAdapter(SiteFileAdapter());
      }
      _hiveInitialized = true;
    }
    if (!Hive.isBoxOpen(boxName)) {
      await Hive.openBox<SiteFile>(boxName);
    }
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
    // Ensure box is open
    if (!Hive.isBoxOpen(boxName)) {
      await init();
    }
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

  static Future<List<SiteFile>> pickAndUploadFiles(
    String siteId,
    String uploadedBy, {
    String category = 'General',
    String folderPath = '/',
  }) async {
    try {
      final result = await FilePicker.platform.pickFiles(
        allowMultiple: true,
        type: FileType.any,
        withData: true,
      );

      if (result != null && result.files.isNotEmpty) {
        final uploaded = <SiteFile>[];
        for (final platformFile in result.files) {
          if (platformFile.path == null && platformFile.bytes == null) {
            continue;
          }
          final originalName = platformFile.name;
          final fileSize = platformFile.size;
          final extension = _getFileExtension(originalName);
          final fileType = _getFileType(extension);

          // Create unique filename
          final fileName = '${_uuid.v4()}.$extension';

          // For web, we'll store the file data directly
          String filePath;
          Uint8List? fileBytes;
          if (_isWeb) {
            filePath = 'web://$fileName';
            fileBytes = platformFile.bytes != null ? Uint8List.fromList(platformFile.bytes!) : null;
          } else {
            // Mobile/Desktop: store in file system
            final appDir = await getApplicationDocumentsDirectory();
            final siteDir = Directory('${appDir.path}/sites/$siteId/files');
            if (!await siteDir.exists()) {
              await siteDir.create(recursive: true);
            }
            filePath = '${siteDir.path}/$fileName';

            // Copy file to app directory
            if (platformFile.path != null) {
              final originalFile = File(platformFile.path!);
              await originalFile.copy(filePath);
            } else if (platformFile.bytes != null) {
              final originalFile = File(filePath);
              await originalFile.writeAsBytes(platformFile.bytes!);
            }
            fileBytes = null;
          }

          // Create SiteFile object
          final targetFolder = normalizeFolderPath(folderPath);
          await createFolder(siteId, targetFolder);
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
            category: category,
            folderPath: targetFolder,
            fileBytes: fileBytes,
          );

          // Save to database
          await addFile(siteFile);

          uploaded.add(siteFile);
        }

        return uploaded;
      }
    } catch (e) {
      print('Error picking/uploading file: $e');
    }
    return [];
  }

  static Future<SiteFile?> pickAndUploadFile(
    String siteId,
    String uploadedBy, {
    String category = 'General',
    String folderPath = '/',
  }) async {
    final files = await pickAndUploadFiles(
      siteId,
      uploadedBy,
      category: category,
      folderPath: folderPath,
    );
    return files.isNotEmpty ? files.first : null;
  }

  static Future<void> downloadFile(SiteFile file) async {
    try {
      if (kIsWeb) {
        final bytes = file.fileBytes;
        if (bytes == null) {
          throw Exception('File data not available for web download');
        }
        await platform_download.downloadFile(bytes, file.originalName, 'application/octet-stream');
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

  static Future<Uint8List?> loadFileBytes(String path) async {
    try {
      if (kIsWeb) {
        // Web storage not yet implemented for direct path loading
        return null;
      }
      final file = File(path);
      if (await file.exists()) {
        return await file.readAsBytes();
      }
    } catch (e) {
      print('Error reading file bytes: $e');
    }
    return null;
  }

  static Future<Directory> getExportDirectory() async {
    if (kIsWeb) {
      throw UnsupportedError('Export directory not available on web');
    }
    final appDir = await getApplicationDocumentsDirectory();
    final exportDir = Directory('${appDir.path}/exports');
    if (!await exportDir.exists()) {
      await exportDir.create(recursive: true);
    }
    return exportDir;
  }

  static Future<File> saveBytesToFile(Directory directory, String fileName, List<int> bytes) async {
    final file = File('${directory.path}/$fileName');
    await file.writeAsBytes(bytes, flush: true);
    return file;
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

  static Future<SiteFile?> saveFileFromBytes(
    String siteId,
    List<int> bytes,
    String fileName,
    String fileType, {
    String uploadedBy = 'System',
    String category = 'General',
    String folderPath = '/',
  }) async {
    try {
      final originalName = fileName;
      final fileSize = bytes.length;
      final extension = _getFileExtension(fileName);
      final fileTypeDescription = _getFileType(extension);

      // Create unique filename
      final uniqueFileName = '${_uuid.v4()}.$extension';
      
      // For web, we'll store the file data directly
      String filePath;
      Uint8List? storedBytes;
      if (_isWeb) {
        filePath = 'web://$uniqueFileName';
        storedBytes = Uint8List.fromList(bytes);
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
        storedBytes = null;
      }
      
      // Create SiteFile object
      final targetFolder = normalizeFolderPath(folderPath);
      await createFolder(siteId, targetFolder);
      final siteFile = SiteFile(
        id: _uuid.v4(),
        siteId: siteId,
        fileName: uniqueFileName,
        originalName: originalName,
        filePath: filePath,
        fileType: fileTypeDescription,
        fileSize: fileSize,
        uploadDate: DateTime.now(),
        uploadedBy: uploadedBy,
        category: category,
        folderPath: targetFolder,
        fileBytes: storedBytes,
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

  static Future<bool> fileExists(String siteId, String originalName) async {
    final box = Hive.box<SiteFile>(boxName);
    if (!box.isOpen) {
      await Hive.openBox<SiteFile>(boxName);
    }
    return box.values.any(
      (file) => file.siteId == siteId && file.originalName == originalName,
    );
  }

  static Future<List<SiteFile>> getFolders(String siteId, {String prefix = '/'}) async {
    final box = Hive.box<SiteFile>(boxName);
    if (!box.isOpen) {
      await Hive.openBox<SiteFile>(boxName);
    }
    final normalizedPrefix = normalizeFolderPath(prefix);
    return box.values
        .where((file) =>
            file.siteId == siteId &&
            file.isFolder &&
            file.folderPath.startsWith(normalizedPrefix))
        .toList();
  }

  static Future<SiteFile> createFolder(String siteId, String folderPath) async {
    final normalized = normalizeFolderPath(folderPath);
    final box = Hive.box<SiteFile>(boxName);
    if (!box.isOpen) {
      await Hive.openBox<SiteFile>(boxName);
    }
    SiteFile? existing;
    for (final file in box.values) {
      if (file.siteId == siteId && file.isFolder && file.folderPath == normalized) {
        existing = file;
        break;
      }
    }
    if (existing != null) {
      return existing;
    }
    final folder = SiteFile(
      id: _uuid.v4(),
      siteId: siteId,
      fileName: normalized,
      originalName: normalized,
      filePath: normalized,
      fileType: 'Folder',
      fileSize: 0,
      uploadDate: DateTime.now(),
      uploadedBy: 'System',
      category: 'General',
      folderPath: normalized,
      isFolder: true,
    );
    await addFile(folder);
    return folder;
  }

  static Future<void> deleteFolder(String siteId, String folderPath) async {
    final box = Hive.box<SiteFile>(boxName);
    if (!box.isOpen) {
      await Hive.openBox<SiteFile>(boxName);
    }
    final targetPath = normalizeFolderPath(folderPath);
    final targets = box.keys.where((key) {
      final file = box.get(key);
      if (file == null) return false;
      if (file.siteId != siteId) return false;
      if (!file.folderPath.startsWith(targetPath)) return false;
      return true;
    }).toList();

    for (final key in targets) {
      final file = box.get(key) as SiteFile?;
      if (file != null && !file.isFolder && !_isWeb) {
        final localFile = File(file.filePath);
        if (await localFile.exists()) {
          await localFile.delete();
        }
      }
      await box.delete(key);
    }
  }

  static Future<bool> folderExists(String siteId, String folderPath) async {
    final box = Hive.box<SiteFile>(boxName);
    if (!box.isOpen) {
      await Hive.openBox<SiteFile>(boxName);
    }
    final normalized = normalizeFolderPath(folderPath);
    return box.values.any(
      (file) =>
          file.siteId == siteId &&
          file.isFolder &&
          file.folderPath == normalized,
    );
  }

  static Future<List<String>> getFolderPaths(String siteId) async {
    final box = Hive.box<SiteFile>(boxName);
    if (!box.isOpen) {
      await Hive.openBox<SiteFile>(boxName);
    }
    final paths = <String>{'/'};
    for (final file in box.values) {
      if (file.siteId == siteId && file.isFolder) {
        paths.add(file.folderPath);
      }
    }
    final list = paths.toList()..sort();
    return list;
  }

  static Future<void> moveFile(String fileId, String folderPath) async {
    final box = Hive.box<SiteFile>(boxName);
    if (!box.isOpen) {
      await Hive.openBox<SiteFile>(boxName);
    }
    final normalized = normalizeFolderPath(folderPath);
    final key = box.keys.firstWhere((k) => box.get(k)?.id == fileId);
    final file = box.get(key) as SiteFile;
    await box.put(key, file.copyWith(folderPath: normalized));
  }

  static Future<void> renameFile(String fileId, String newName) async {
    final box = Hive.box<SiteFile>(boxName);
    if (!box.isOpen) {
      await Hive.openBox<SiteFile>(boxName);
    }
    final key = box.keys.firstWhere((k) => box.get(k)?.id == fileId);
    final file = box.get(key) as SiteFile;
    var desiredName = newName.trim();
    if (desiredName.isEmpty) return;
    final currentExtension = _getFileExtension(file.originalName);
    final desiredExtension = _getFileExtension(desiredName);
    if (currentExtension.isNotEmpty && desiredExtension.isEmpty) {
      desiredName = '$desiredName.$currentExtension';
    }
    await box.put(key, file.copyWith(originalName: desiredName));
  }

  static Future<void> renameFolder(String siteId, String oldPath, String newPath) async {
    final box = Hive.box<SiteFile>(boxName);
    if (!box.isOpen) {
      await Hive.openBox<SiteFile>(boxName);
    }
    final normalizedOld = normalizeFolderPath(oldPath);
    final normalizedNew = normalizeFolderPath(newPath);
    if (normalizedOld == normalizedNew) {
      return;
    }
    if (await folderExists(siteId, normalizedNew)) {
      throw Exception('Folder already exists');
    }
    for (final key in box.keys) {
      final file = box.get(key) as SiteFile?;
      if (file == null) continue;
      if (file.siteId != siteId) continue;
      if (!file.folderPath.startsWith(normalizedOld)) continue;
      final suffix = file.folderPath.substring(normalizedOld.length);
      final updatedFolderPath = combineFolderPath(normalizedNew, suffix);
      final updated = file.copyWith(
        folderPath: updatedFolderPath,
        fileName: file.isFolder ? updatedFolderPath : file.fileName,
        originalName: file.isFolder
            ? (updatedFolderPath == '/' ? 'Root' : updatedFolderPath.split('/').last)
            : file.originalName,
      );
      await box.put(key, updated);
    }
  }
}
