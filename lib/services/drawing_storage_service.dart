import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/site.dart';
import 'dart:convert';

class DrawingStorageService {
  static const String boxName = 'site_drawings';

  static Future<void> init() async {
    await Hive.initFlutter();
    await Hive.openBox(boxName);
  }

  static Future<void> saveDrawing(
      String siteId,
      List<Map<String, dynamic>> actions,
      Map<String, dynamic>? overlay,
      List<Map<String, dynamic>> layers) async {
    if (!Hive.isBoxOpen(boxName)) {
      return;
    }
    final box = Hive.box(boxName);
    await box.put(
      siteId,
      jsonEncode({'actions': actions, 'overlay': overlay, 'layers': layers}),
    );
  }

  static Future<Map<String, dynamic>?> loadDrawing(String siteId) async {
    if (!Hive.isBoxOpen(boxName)) {
      return null;
    }
    final box = Hive.box(boxName);
    final data = box.get(siteId);
    if (data == null) return null;
    return jsonDecode(data);
  }

  static Future<void> clearDrawing(String siteId) async {
    if (!Hive.isBoxOpen(boxName)) {
      return;
    }
    final box = Hive.box(boxName);
    await box.delete(siteId);
  }
}
