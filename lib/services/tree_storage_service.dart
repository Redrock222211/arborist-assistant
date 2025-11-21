import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/tree_entry.dart';
import 'firebase_service.dart';

class TreeStorageService {
  static const String boxName = 'tree_entries';
  static const String counterBoxName = 'tree_counters';

  static Future<void> init() async {
    await Hive.initFlutter();
    if (!Hive.isAdapterRegistered(0)) {
      Hive.registerAdapter(TreeEntryAdapter());
    }
    await Hive.openBox<TreeEntry>(boxName);
    await Hive.openBox<int>(counterBoxName);
  }

  /// Get the next sequential tree number for a site
  static Future<int> getNextTreeNumber(String siteId) async {
    final counterBox = Hive.box<int>(counterBoxName);
    final currentNumber = (counterBox.get(siteId, defaultValue: 0) ?? 0) as int;
    final nextNumber = currentNumber + 1;
    await counterBox.put(siteId, nextNumber);
    return nextNumber;
  }

  /// Generate sequential tree ID for a site (e.g., "Tree 1", "Tree 2")
  static Future<String> generateSequentialTreeId(String siteId) async {
    final treeNumber = await getNextTreeNumber(siteId);
    return 'Tree $treeNumber';
  }

  /// Get next tree ID (for backward compatibility)
  static Future<String> getNextTreeId(String siteId) async {
    return generateSequentialTreeId(siteId);
  }

  static Future<void> addTree(TreeEntry entry) async {
    // Ensure box is open before accessing
    Box<TreeEntry> box;
    try {
      if (!Hive.isBoxOpen(boxName)) {
        box = await Hive.openBox<TreeEntry>(boxName);
      } else {
        box = Hive.box<TreeEntry>(boxName);
      }
    } catch (e) {
      print('⚠️ Error opening box, attempting to reinitialize: $e');
      await init();
      box = Hive.box<TreeEntry>(boxName);
    }
    
    // Save to local storage
    await box.add(entry);
    
    // Sync to Firebase if online
    try {
      if (FirebaseService.isOnline && FirebaseService.currentUser != null) {
        await FirebaseService.saveTree(entry);
        print('✅ Tree synced to cloud: ${entry.id}');
      }
    } catch (e) {
      print('⚠️ Failed to sync tree to cloud: $e');
      // Continue anyway - data is saved locally
    }
  }

  static List<TreeEntry> getAllTrees() {
    if (!Hive.isBoxOpen(boxName)) {
      return [];
    }
    final box = Hive.box<TreeEntry>(boxName);
    return box.values.toList();
  }

  static List<TreeEntry> getTreesForSite(String siteId) {
    if (!Hive.isBoxOpen(boxName)) {
      return [];
    }
    final box = Hive.box<TreeEntry>(boxName);
    return box.values.where((tree) => tree.siteId == siteId).toList();
  }

  static List<MapEntry<dynamic, TreeEntry>> getTreeEntriesWithKeysForSite(String siteId) {
    if (!Hive.isBoxOpen(boxName)) {
      return [];
    }
    final box = Hive.box<TreeEntry>(boxName);
    return box.toMap().entries.where((e) => e.value.siteId == siteId).toList();
  }

  static Future<void> updateTree(dynamic key, TreeEntry entry) async {
    // Ensure box is open before accessing
    Box<TreeEntry> box;
    try {
      if (!Hive.isBoxOpen(boxName)) {
        box = await Hive.openBox<TreeEntry>(boxName);
      } else {
        box = Hive.box<TreeEntry>(boxName);
      }
    } catch (e) {
      print('⚠️ Error opening box, attempting to reinitialize: $e');
      await init();
      box = Hive.box<TreeEntry>(boxName);
    }
    
    // Update local storage
    await box.put(key, entry);
    
    // Sync to Firebase if online
    try {
      if (FirebaseService.isOnline && FirebaseService.currentUser != null) {
        await FirebaseService.saveTree(entry);
        print('✅ Tree updated in cloud: ${entry.id}');
      }
    } catch (e) {
      print('⚠️ Failed to sync tree update to cloud: $e');
      // Continue anyway - data is saved locally
    }
  }

  static Future<void> deleteTree(dynamic key) async {
    if (!Hive.isBoxOpen(boxName)) {
      await Hive.openBox<TreeEntry>(boxName);
    }
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
    if (!Hive.isBoxOpen(boxName)) {
      await Hive.openBox<TreeEntry>(boxName);
    }
    final box = Hive.box<TreeEntry>(boxName);
    await box.clear();
  }

  static bool isBoxOpen() {
    return Hive.isBoxOpen(boxName);
  }
}
