import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';

part 'branding_service.g.dart';

@HiveType(typeId: 2)
class BrandingSettings {
  @HiveField(0)
  final String? logoPath;
  @HiveField(1)
  final String scale; // 'auto', 'small', 'medium', 'large'
  @HiveField(2)
  final String placement; // 'topLeft', 'topRight', 'bottomLeft', 'bottomRight', 'center'

  BrandingSettings({this.logoPath, this.scale = 'auto', this.placement = 'topRight'});
}

class BrandingService {
  static const String boxName = 'branding_settings';
  static const String key = 'branding';

  static Future<void> init() async {
    await Hive.initFlutter();
    if (!Hive.isAdapterRegistered(2)) {
      Hive.registerAdapter(BrandingSettingsAdapter());
    }
    await Hive.openBox<BrandingSettings>(boxName);
  }

  static Future<void> saveBranding(BrandingSettings settings) async {
    final box = Hive.box<BrandingSettings>(boxName);
    await box.put(key, settings);
  }

  static BrandingSettings? loadBranding() {
    final box = Hive.box<BrandingSettings>(boxName);
    return box.get(key);
  }

  static Future<void> clearBranding() async {
    final box = Hive.box<BrandingSettings>(boxName);
    await box.delete(key);
  }
}
