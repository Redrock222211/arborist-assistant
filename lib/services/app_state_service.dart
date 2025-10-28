import 'package:hive/hive.dart';
import 'package:latlong2/latlong.dart';
import '../models/site.dart';
import '../models/tree_entry.dart';
import '../services/site_storage_service.dart';
import '../services/tree_storage_service.dart';

class AppStateService {
  static const String _boxName = 'app_state';
  static const String _lastSiteKey = 'last_site_id';
  static const String _mapCenterLatKey = 'map_center_lat';
  static const String _mapCenterLngKey = 'map_center_lng';
  static const String _mapZoomKey = 'map_zoom';
  static const String _showSRZKey = 'show_srz';
  static const String _showNRZKey = 'show_nrz';
  static const String _exportGroupsPrefix = 'export_groups_'; // Per-site export preferences

  static late Box _box;

  /// Initialize the app state service
  static Future<void> init() async {
    _box = await Hive.openBox(_boxName);
  }

  /// Save the last selected site
  static Future<void> saveLastSite(String siteId) async {
    await _box.put(_lastSiteKey, siteId);
  }

  /// Get the last selected site
  static String? getLastSiteId() {
    return _box.get(_lastSiteKey) as String?;
  }

  /// Get the last selected site object
  static Site? getLastSite() {
    final siteId = getLastSiteId();
    if (siteId != null) {
      return SiteStorageService.getSiteById(siteId);
    }
    return null;
  }

  /// Save map position and zoom
  static Future<void> saveMapPosition(LatLng center, double zoom) async {
    await _box.put(_mapCenterLatKey, center.latitude);
    await _box.put(_mapCenterLngKey, center.longitude);
    await _box.put(_mapZoomKey, zoom);
  }

  /// Get saved map position and zoom
  static Map<String, dynamic>? getMapPosition() {
    final lat = _box.get(_mapCenterLatKey) as double?;
    final lng = _box.get(_mapCenterLngKey) as double?;
    final zoom = _box.get(_mapZoomKey) as double?;

    if (lat != null && lng != null && zoom != null) {
      return {
        'center': LatLng(lat, lng),
        'zoom': zoom,
      };
    }
    return null;
  }

  /// Save SRZ/NRZ visibility preferences
  static Future<void> saveCircleVisibility(bool showSRZ, bool showNRZ) async {
    await _box.put(_showSRZKey, showSRZ);
    await _box.put(_showNRZKey, showNRZ);
  }

  /// Get saved SRZ/NRZ visibility preferences
  static Map<String, bool> getCircleVisibility() {
    return {
      'showSRZ': _box.get(_showSRZKey, defaultValue: false) as bool,
      'showNRZ': _box.get(_showNRZKey, defaultValue: false) as bool,
    };
  }

  /// Clear all saved state
  static Future<void> clearState() async {
    await _box.clear();
  }

  /// Close the service
  static Future<void> close() async {
    await _box.close();
  }

  /// Save tree for offline storage
  static Future<void> saveOfflineTree(TreeEntry tree) async {
    // For now, just save to the main tree storage
    // In a real implementation, this would save to a separate offline queue
    await TreeStorageService.addTree(tree);
  }
  
  /// Save export group preferences for a specific site
  /// This allows each site to remember which groups are enabled/disabled
  static Future<void> saveExportGroupsForSite(String siteId, Map<String, bool> exportGroups) async {
    await _box.put('$_exportGroupsPrefix$siteId', exportGroups);
  }
  
  /// Get export group preferences for a specific site
  /// Returns null if no preferences saved (first tree on site)
  static Map<String, bool>? getExportGroupsForSite(String siteId) {
    final data = _box.get('$_exportGroupsPrefix$siteId');
    if (data != null) {
      return Map<String, bool>.from(data as Map);
    }
    return null;
  }
  
  /// Check if a site has export group preferences saved
  static bool hasSitePreferences(String siteId) {
    return _box.containsKey('$_exportGroupsPrefix$siteId');
  }
  
  /// Clear export group preferences for a site
  static Future<void> clearSitePreferences(String siteId) async {
    await _box.delete('$_exportGroupsPrefix$siteId');
  }
}
