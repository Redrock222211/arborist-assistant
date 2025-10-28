import 'dart:async';
import '../models/planning.dart';
import 'vicmap_service.dart';
import 'vicplan_service.dart';

/// Planning Adapter Service
/// 
/// This service acts as an adapter between the existing VicPlan service interface
/// and the new Vicmap Planning REST API. It maintains backward compatibility
/// while providing real planning data from official sources.
/// 
/// The adapter handles coordinate conversion, data mapping, and fallback
/// to ensure the existing app continues to work without breaking changes.
class PlanningAdapter {
  // Feature flag to enable Vicmap integration
  // ENABLED: Using original endpoints with graceful error handling
  static bool _enableVicmap = true;
  
  /// Get planning information for an address
  /// 
  /// This method maintains the existing VicPlan service interface while
  /// optionally using real data from Vicmap when available.
  static Future<Map<String, dynamic>> getPlanningForAddress(String address, {double? latitude, double? longitude}) async {
    try {
      // If we have coordinates and Vicmap is enabled, use real data
      if (_enableVicmap && latitude != null && longitude != null) {
        return await _getRealPlanningData(latitude, longitude, address);
      }
      
      // Fallback to existing VicPlan service behavior
      return await _getFallbackPlanningData(address);
    } catch (e) {
      return await _getFallbackPlanningData(address);
    }
  }
  
  /// Get planning information for coordinates
  /// 
  /// This method provides real planning data from Vicmap when coordinates
  /// are available, maintaining the existing interface structure.
  static Future<Map<String, dynamic>> getPlanningForCoordinates(double latitude, double longitude, {String? address}) async {
    try {
      if (_enableVicmap) {
        return await _getRealPlanningData(latitude, longitude, address);
      }
      
      return await _getFallbackPlanningData(address ?? '${latitude}, ${longitude}');
    } catch (e) {
      return await _getFallbackPlanningData(address ?? '${latitude}, ${longitude}');
    }
  }
  
  /// Get real planning data from Vicmap service
  static Future<Map<String, dynamic>> _getRealPlanningData(
    double latitude, 
    double longitude, 
    String? address
  ) async {
    print('🔍 PlanningAdapter: Getting real planning data from Vicmap service');
    
    try {
      // Sequential requests take longer - allow 35 seconds
      final planningResult = await VicmapService.getPlanningAtPoint(longitude, latitude)
          .timeout(const Duration(seconds: 35), onTimeout: () {
        print('⚠️ PlanningAdapter: Vicmap API timeout after 35s, using fallback');
        throw TimeoutException('Vicmap API timeout');
      });
      print('🔍 PlanningAdapter: Vicmap returned planning result: ${planningResult.lga}');
      
      // Convert overlays to the expected format
      final overlaysMap = <String, Map<String, dynamic>>{};
      for (final overlay in planningResult.overlays) {
        overlaysMap[overlay.code] = {
          'code': overlay.code,
          'description': overlay.description,
          'vpp_url': overlay.vppUrl,
          'local_policy_url': overlay.localPolicyUrl,
          'permit_requirements': overlay.permitRequirements,
        };
      }
      
      // Check if we have real data from Vicmap API
      final hasRealData = planningResult.overlays.isNotEmpty || planningResult.zones.isNotEmpty;
      
      print('🔍 PlanningAdapter: Data sources - Vicmap API: $hasRealData');
      
      return {
        'success': true,
        'address': address ?? '${latitude}, ${longitude}',
        'coordinates': {
          'latitude': latitude,
          'longitude': longitude,
          'accuracy': 'high',
        },
        'lga': planningResult.lga,
        'lga_key': _extractLGAKey(planningResult.lga),
        'overlays': overlaysMap,
        'vicplan_url': _generateVicPlanUrl(planningResult.lga),
        'timestamp': planningResult.timestamp.toIso8601String(),
        'data_source': 'Vicmap Planning API',
        'real_data': hasRealData,
        'local_tree_laws': null, // Will be populated from Vicmap API when available
        'victorian_planning_overlays': overlaysMap,
        'data_summary': {
                  'has_local_tree_laws': false, // Will be populated from Vicmap API when available
        'has_victorian_planning_overlays': hasRealData,
                  'total_data_sources': hasRealData ? 1 : 0,
        'last_updated': DateTime.now().toIso8601String(),
        },
      };
    } catch (e) {
      print('🔍 PlanningAdapter: Error getting real planning data: $e');
      return {
        'success': false,
        'error': 'Failed to get planning data: $e',
        'data_source': 'Error',
        'real_data': false,
      };
    }
  }
  
  /// Convert overlays to the existing map format
  static Map<String, Map<String, dynamic>> _convertOverlaysToMap(List<OverlayResult> overlays) {
    final result = <String, Map<String, dynamic>>{};
    
    for (final overlay in overlays) {
      result[overlay.code] = {
        'name': overlay.description,
        'code': overlay.code,
        'description': overlay.description,
        'vpp_url': overlay.vppUrl,
        'local_policy_url': overlay.localPolicyUrl,
        // Include real permit requirements from Vicmap
        'permit_requirements': overlay.permitRequirements,
        'overlay_type': overlay.permitRequirements?['overlay_type'] ?? 'Planning Overlay',
      };
    }
    
    return result;
  }
  
  /// Convert zones to the existing map format
  static Map<String, Map<String, dynamic>> _convertZonesToMap(List<ZoneResult> zones) {
    final result = <String, Map<String, dynamic>>{};
    for (final zone in zones) {
      result[zone.code] = {
        'name': zone.description,
        'code': zone.code,
        'description': zone.description,
        'vpp_url': zone.vppUrl,
        'local_policy_url': zone.localPolicyUrl,
        'zone_type': zone.zoneType,
      };
    }
    return result;
  }
  
  /// Generate tree removal requirements based on overlay code
  /// REMOVED: This was generating fake data. Now returns null to force real data usage.
  static String? _generateTreeRemovalRequirement(String overlayCode) {
    // This method was generating fake permit requirements
    // Return null to indicate no fake data should be used
    return null;
  }
  
  /// Generate tree pruning requirements based on overlay code
  /// REMOVED: This was generating fake data. Now returns null to force real data usage.
  static String? _generateTreePruningRequirement(String overlayCode) {
    // This method was generating fake permit requirements
    // Return null to indicate no fake data should be used
    return null;
  }
  
  /// Generate native vegetation requirements based on overlay code
  /// REMOVED: This was generating fake data. Now returns null to force real data usage.
  static String? _generateNativeVegetationRequirement(String overlayCode) {
    // This method was generating fake permit requirements
    // Return null to indicate no fake data should be used
    return null;
  }
  
  /// Generate heritage tree requirements based on overlay code
  /// REMOVED: This was generating fake data. Now returns null to force real data usage.
  static String? _generateHeritageTreeRequirement(String overlayCode) {
    // This method was generating fake permit requirements
    // Return null to indicate no fake data should be used
    return null;
  }
  
  /// Extract LGA key from full LGA name
  static String _extractLGAKey(String lga) {
    final lowerLga = lga.toLowerCase();
    
    if (lowerLga.contains('whittlesea')) return 'whittlesea';
    if (lowerLga.contains('melbourne')) return 'melbourne';
    if (lowerLga.contains('port phillip')) return 'port_phillip';
    if (lowerLga.contains('yarra')) return 'yarra';
    
    // Extract first word as key
    final words = lga.split(' ');
    return words.isNotEmpty ? words.first.toLowerCase() : 'unknown';
  }
  
  /// Generate VicPlan URL for the LGA
  static String _generateVicPlanUrl(String lga) {
    final lgaKey = _extractLGAKey(lga);
    
    switch (lgaKey.toLowerCase()) {
      case 'whittlesea':
        return 'https://www.planning.vic.gov.au/schemes/whittlesea';
      case 'melbourne':
        return 'https://www.planning.vic.gov.au/schemes/melbourne';
      case 'port_phillip':
        return 'https://www.planning.vic.gov.au/schemes/port-phillip';
      case 'yarra':
        return 'https://www.planning.vic.gov.au/schemes/yarra';
      default:
        return 'https://www.planning.vic.gov.au';
    }
  }
  
  /// Get fallback planning data (existing VicPlan service behavior)
  static Future<Map<String, dynamic>> _getFallbackPlanningData(String address) async {
    return {
      'success': true,
      'address': address,
      'vicplan_url': 'https://www.planning.vic.gov.au',
      'note': 'No permit data provided. Visit VicPlan directly for real, current planning information.',
      'timestamp': DateTime.now().toIso8601String(),
      'data_source': 'Fallback',
      'real_data': false,
    };
  }
  
  /// Check if Vicmap integration is enabled
  static bool get isVicmapEnabled => _enableVicmap;
  
  /// Enable or disable Vicmap integration (for testing)
  static void setVicmapEnabled(bool enabled) {
    _enableVicmap = enabled;
    print('Vicmap integration is ${enabled ? "enabled" : "disabled"}');
  }
  
  /// Clear all caches (useful for testing)
  static void clearCaches() {
    VicmapService.clearCaches();
  }
}
