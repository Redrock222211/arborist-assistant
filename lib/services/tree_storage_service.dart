import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/tree_entry.dart';

class TreeStorageService {
  static const String boxName = 'tree_entries';

  static Future<void> init() async {
    await Hive.initFlutter();
    if (!Hive.isAdapterRegistered(0)) {
      Hive.registerAdapter(TreeEntryAdapter());
    }
    await Hive.openBox<TreeEntry>(boxName);
  }

  static Future<void> addTree(TreeEntry entry) async {
    final box = Hive.box<TreeEntry>(boxName);
    await box.add(entry);
  }

  static List<TreeEntry> getAllTrees() {
    final box = Hive.box<TreeEntry>(boxName);
    return box.values.toList();
  }

  static List<TreeEntry> getTreesForSite(String siteId) {
    final box = Hive.box<TreeEntry>(boxName);
    return box.values.where((tree) => tree.siteId == siteId).toList();
  }

  static List<MapEntry<dynamic, TreeEntry>> getTreeEntriesWithKeysForSite(String siteId) {
    final box = Hive.box<TreeEntry>(boxName);
    return box.toMap().entries.where((e) => e.value.siteId == siteId).toList();
  }

  static Future<void> updateTree(dynamic key, TreeEntry entry) async {
    final box = Hive.box<TreeEntry>(boxName);
    await box.put(key, entry);
  }

  static Future<void> deleteTree(dynamic key) async {
    final box = Hive.box<TreeEntry>(boxName);
    await box.delete(key);
  }

  static Future<void> clearAllForSite(String siteId) async {
    final box = Hive.box<TreeEntry>(boxName);
    if (!box.isOpen) {
      await Hive.openBox<TreeEntry>(boxName);
    }
    final keysToDelete = box.toMap().entries.where((e) => e.value.siteId == siteId).map((e) => e.key).toList();
    for (final key in keysToDelete) {
      await box.delete(key);
    }
  }

  static Future<void> clearAll() async {
    final box = Hive.box<TreeEntry>(boxName);
    await box.clear();
  }

  static String getNextTreeId(String siteId) {
    final trees = getTreesForSite(siteId);
    if (trees.isEmpty) return '1';
    
    final existingIds = trees.map((t) => int.tryParse(t.id) ?? 0).toList();
    final maxId = existingIds.isNotEmpty ? existingIds.reduce((a, b) => a > b ? a : b) : 0;
    return (maxId + 1).toString();
  }
}
