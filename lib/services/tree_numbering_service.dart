import 'package:hive_flutter/hive_flutter.dart';
import '../models/tree_entry.dart';
import 'tree_storage_service.dart';

class TreeNumberingService {
  static const String _lastTreeNumberKey = 'last_tree_number';
  
  /// Get the next available tree number for a site
  static String getNextTreeNumber(String siteId) {
    final box = Hive.box('app_settings');
    final lastNumber = box.get('${_lastTreeNumberKey}_$siteId', defaultValue: 0) as int;
    final nextNumber = lastNumber + 1;
    
    // Format as 3-digit number (001, 002, etc.)
    return nextNumber.toString().padLeft(3, '0');
  }
  
  /// Check if a tree number already exists in the site
  static bool isTreeNumberExists(String siteId, String treeNumber) {
    final trees = TreeStorageService.getTreesForSite(siteId);
    return trees.any((tree) => tree.id == treeNumber);
  }
  
  /// Reserve a tree number (mark it as used)
  static void reserveTreeNumber(String siteId, String treeNumber) {
    final box = Hive.box('app_settings');
    final number = int.tryParse(treeNumber) ?? 0;
    final currentLast = box.get('${_lastTreeNumberKey}_$siteId', defaultValue: 0) as int;
    
    // Update the last number if this one is higher
    if (number > currentLast) {
      box.put('${_lastTreeNumberKey}_$siteId', number);
    }
  }
  
  /// Get the highest tree number used in a site
  static int getHighestTreeNumber(String siteId) {
    final box = Hive.box('app_settings');
    return box.get('${_lastTreeNumberKey}_$siteId', defaultValue: 0) as int;
  }
  
  /// Reset tree numbering for a site (useful for testing)
  static void resetTreeNumbering(String siteId) {
    final box = Hive.box('app_settings');
    box.delete('${_lastTreeNumberKey}_$siteId');
  }
  
  /// Get all used tree numbers in a site
  static List<String> getUsedTreeNumbers(String siteId) {
    final trees = TreeStorageService.getTreesForSite(siteId);
    return trees.map((tree) => tree.id).toList();
  }
  
  /// Find the next available tree number (handles gaps)
  static String findNextAvailableNumber(String siteId) {
    final usedNumbers = getUsedTreeNumbers(siteId);
    final usedInts = usedNumbers.map((n) => int.tryParse(n) ?? 0).toSet();
    
    int nextNumber = 1;
    while (usedInts.contains(nextNumber)) {
      nextNumber++;
    }
    
    return nextNumber.toString().padLeft(3, '0');
  }
}
