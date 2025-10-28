import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:io';
import 'dart:convert';
import '../models/site.dart';
import '../models/tree_entry.dart';
import '../models/tree_permit.dart';
import '../models/site_file.dart';
import '../services/site_storage_service.dart';
import '../services/tree_storage_service.dart';
import '../services/tree_permit_service.dart';
import '../services/site_file_service.dart';

class BackupService {
  static Future<void> exportSiteData(String siteId) async {
    try {
      // Get all data for the site
      final site = SiteStorageService.getSiteById(siteId);
      if (site == null) throw Exception('Site not found');

      final trees = TreeStorageService.getTreesForSite(siteId);
      final permits = await TreePermitService.getPermitsForSite(siteId);
      final files = await SiteFileService.getFilesForSite(siteId);

      // Create backup data structure
      final backupData = {
        'version': '1.0',
        'exportDate': DateTime.now().toIso8601String(),
        'site': site.toMap(),
        'trees': trees.map((tree) => tree.toMap()).toList(),
        'permits': permits.map((permit) => permit.toMap()).toList(),
        'files': files.map((file) => file.toMap()).toList(),
      };

      // Convert to JSON
      final jsonData = jsonEncode(backupData);
      
      // Save to file
      final directory = await getTemporaryDirectory();
      final fileName = 'arborist_backup_${site.name.replaceAll(' ', '_')}_${DateTime.now().millisecondsSinceEpoch}.json';
      final file = File('${directory.path}/$fileName');
      await file.writeAsString(jsonData);

      // Share the file
      await Share.shareXFiles([XFile(file.path)], text: 'Arborist Assistant Backup - ${site.name}');

    } catch (e) {
      throw Exception('Failed to export site data: $e');
    }
  }

  static Future<void> importSiteData(String jsonData) async {
    try {
      final backupData = jsonDecode(jsonData) as Map<String, dynamic>;
      
      // Validate backup format
      if (!backupData.containsKey('version') || !backupData.containsKey('site')) {
        throw Exception('Invalid backup file format');
      }

      final siteData = backupData['site'] as Map<String, dynamic>;
      final treesData = backupData['trees'] as List<dynamic>;
      final permitsData = backupData['permits'] as List<dynamic>;
      final filesData = backupData['files'] as List<dynamic>;

      // Import site
      final site = Site.fromMap(siteData);
      await SiteStorageService.addSite(site);

      // Import trees
      for (final treeData in treesData) {
        final tree = TreeEntry.fromMap(treeData as Map<String, dynamic>);
        await TreeStorageService.addTree(tree);
      }

      // Import permits
      for (final permitData in permitsData) {
        final permit = TreePermit.fromMap(permitData as Map<String, dynamic>);
        await TreePermitService.addPermit(permit);
      }

      // Import files (metadata only, files need to be re-uploaded)
      for (final fileData in filesData) {
        final file = SiteFile.fromMap(fileData as Map<String, dynamic>);
        await SiteFileService.addFile(file);
      }

    } catch (e) {
      throw Exception('Failed to import site data: $e');
    }
  }

  static Future<void> exportAllData() async {
    try {
      // Get all sites
      final sites = SiteStorageService.getAllSites();
      
      // Get all data
      final allData = <String, dynamic>{
        'version': '1.0',
        'exportDate': DateTime.now().toIso8601String(),
        'sites': <Map<String, dynamic>>[],
        'trees': <Map<String, dynamic>>[],
        'permits': <Map<String, dynamic>>[],
        'files': <Map<String, dynamic>>[],
      };

      for (final site in sites) {
        allData['sites']!.add(site.toMap());
        
        final trees = TreeStorageService.getTreesForSite(site.id);
        allData['trees']!.addAll(trees.map((tree) => tree.toMap()));
        
        final permits = await TreePermitService.getPermitsForSite(site.id);
        allData['permits']!.addAll(permits.map((permit) => permit.toMap()));
        
        final files = await SiteFileService.getFilesForSite(site.id);
        allData['files']!.addAll(files.map((file) => file.toMap()));
      }

      // Convert to JSON
      final jsonData = jsonEncode(allData);
      
      // Save to file
      final directory = await getTemporaryDirectory();
      final fileName = 'arborist_full_backup_${DateTime.now().millisecondsSinceEpoch}.json';
      final file = File('${directory.path}/$fileName');
      await file.writeAsString(jsonData);

      // Share the file
      await Share.shareXFiles([XFile(file.path)], text: 'Arborist Assistant Full Backup');

    } catch (e) {
      throw Exception('Failed to export all data: $e');
    }
  }

  static Future<Map<String, dynamic>> getBackupStats() async {
    try {
      final sites = SiteStorageService.getAllSites();
      int totalTrees = 0;
      int totalPermits = 0;
      int totalFiles = 0;

      for (final site in sites) {
        totalTrees += TreeStorageService.getTreesForSite(site.id).length;
        totalPermits += (await TreePermitService.getPermitsForSite(site.id)).length;
        totalFiles += (await SiteFileService.getFilesForSite(site.id)).length;
      }

      return {
        'sites': sites.length,
        'trees': totalTrees,
        'permits': totalPermits,
        'files': totalFiles,
        'lastBackup': null, // TODO: Implement backup tracking
      };
    } catch (e) {
      throw Exception('Failed to get backup stats: $e');
    }
  }

  static Future<void> clearAllData() async {
    try {
      // Clear all Hive boxes
      await Hive.box(SiteStorageService.boxName).clear();
      await Hive.box(TreeStorageService.boxName).clear();
      await Hive.box(TreePermitService.boxName).clear();
      await Hive.box(SiteFileService.boxName).clear();
      
      // Clear app settings
      await Hive.box('app_settings').clear();
      
    } catch (e) {
      throw Exception('Failed to clear data: $e');
    }
  }
}
