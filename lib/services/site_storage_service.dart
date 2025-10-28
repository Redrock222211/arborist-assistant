import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/site.dart';

class SiteStorageService {
  static const String boxName = 'sites';

  static Future<void> init() async {
    await Hive.initFlutter();
    if (!Hive.isAdapterRegistered(1)) {
      Hive.registerAdapter(SiteAdapter());
    }
    await Hive.openBox<Site>(boxName);
  }

  static Future<void> addSite(Site site) async {
    final box = Hive.box<Site>(boxName);
    await box.put(site.id, site);
  }

  static List<Site> getAllSites() {
    final box = Hive.box<Site>(boxName);
    return box.values.toList();
  }

  static Site? getSiteById(String id) {
    final box = Hive.box<Site>(boxName);
    return box.get(id);
  }

  static Future<void> deleteSite(String id) async {
    final box = Hive.box<Site>(boxName);
    if (!box.isOpen) {
      await Hive.openBox<Site>(boxName);
    }
    await box.delete(id);
  }

  static Future<void> updateSite(String id, Site site) async {
    final box = Hive.box<Site>(boxName);
    await box.put(id, site);
  }
}
