import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;

class RealPlanningService {
  // PUBLIC MapServer endpoints - NO AUTHENTICATION REQUIRED!
  static const _overlaysMapServer =
      'https://plan-gis.mapshare.vic.gov.au/arcgis/rest/services/Planning/Vicplan_PlanningSchemeOverlays/MapServer';
  static const _zonesMapServer =
      'https://plan-gis.mapshare.vic.gov.au/arcgis/rest/services/Planning/Vicplan_PlanningSchemeZones/MapServer';
  static const _lgaMapServer =
      'https://plan-gis.mapshare.vic.gov.au/arcgis/rest/services/Planning/Vicplan_PlanningSchemeOverlays/MapServer';

  // Layer IDs for MapServer
  static const _layerOverlays = 0; // All Overlays
  static const _layerZones = 0;    // All Zones  
  static const _layerLga = 0;      // Has LGA field

  /// One call: get overlays, zones, and LGA for a WGS84 point (lat, lon).
  static Future<Map<String, dynamic>> getPlanningAtPoint({
    required double latitude,
    required double longitude,
  }) async {
    print('🔍 RealPlanningService: Querying with coordinates: $longitude, $latitude');
    
    final common = {
      'f': 'json',
      'where': '1=1',
      'geometry': '${longitude.toStringAsFixed(8)},${latitude.toStringAsFixed(8)}',
      'geometryType': 'esriGeometryPoint',
      'inSR': '4326',
      'spatialRel': 'esriSpatialRelIntersects',
      'returnGeometry': 'false',
      'outFields': '*',
    };
    
    print('🔍 RealPlanningService: Query parameters: $common');

    print('🔍 RealPlanningService: Making sequential API calls to MapServer');
    
    // Make requests SEQUENTIALLY using PUBLIC MapServer endpoints
    print('🔍 RealPlanningService: 1/3 Getting overlays...');
    final overlaysResponse = await _get('$_overlaysMapServer/$_layerOverlays/query', common);
    final overlays = _attrsList(overlaysResponse);
    
    print('🔍 RealPlanningService: 2/3 Getting zones...');
    final zonesResponse = await _get('$_zonesMapServer/$_layerZones/query', common);
    final zones = _attrsList(zonesResponse);
    
    // Extract LGA from overlays response (MapServer includes LGA field)
    print('🔍 RealPlanningService: 3/3 Extracting LGA from overlays...');
    final lgaAttrs = overlays.isNotEmpty ? overlays.first : null;
    
    print('🔍 RealPlanningService: Results:');
    print('🔍   Overlays found: ${overlays.length}');
    print('🔍   Zones found: ${zones.length}');
    print('🔍   LGA found: ${lgaAttrs != null ? 'YES' : 'NO'}');
    if (overlays.isNotEmpty) {
      print('🔍   First overlay: ${overlays.first}');
    }
    if (zones.isNotEmpty) {
      print('🔍   First zone: ${zones.first}');
    }
    if (lgaAttrs != null) {
      print('🔍   LGA data: ${lgaAttrs}');
    }

    return {
      'success': true,
      'coords': {'lat': latitude, 'lon': longitude},
      'lga': lgaAttrs,
      'overlays': overlays.map(_normaliseOverlay).toList(),
      'zones': zones.map(_normaliseZone).toList(),
      'raw': {
        'overlays': overlaysResponse,
        'zones': zonesResponse,
        'lga': overlaysResponse, // LGA included in overlays response
      }
    };
  }

  /// Fetch overlays only (optionally filter like 'VPO' or 'ESO').
  static Future<List<Map<String, dynamic>>> getOverlaysAtPoint({
    required double latitude,
    required double longitude,
    String? likeCode, // e.g. 'VPO' or 'ESO'
  }) async {
    final params = {
      'f': 'json',
      'where': likeCode == null ? '1=1' : "OVERLAY LIKE '%$likeCode%'",
      'geometry': '${longitude.toStringAsFixed(8)},${latitude.toStringAsFixed(8)}',
      'geometryType': 'esriGeometryPoint',
      'inSR': '4326',
      'spatialRel': 'esriSpatialRelIntersects',
      'returnGeometry': 'false',
      'outFields': '*',
    };
    final json = await _get('$_overlaysMapServer/$_layerOverlays/query', params);
    return _attrsList(json).map(_normaliseOverlay).toList();
  }

  /// Fetch zones only.
  static Future<List<Map<String, dynamic>>> getZonesAtPoint({
    required double latitude,
    required double longitude,
  }) async {
    final params = {
      'f': 'json',
      'where': '1=1',
      'geometry': '${longitude.toStringAsFixed(8)},${latitude.toStringAsFixed(8)}',
      'geometryType': 'esriGeometryPoint',
      'inSR': '4326',
      'spatialRel': 'esriSpatialRelIntersects',
      'returnGeometry': 'false',
      'outFields': '*',
    };
    final json = await _get('$_zonesMapServer/$_layerZones/query', params);
    return _attrsList(json).map(_normaliseZone).toList();
  }

  /// Fetch LGA from overlays (MapServer includes LGA field).
  static Future<Map<String, dynamic>?> getLgaAtPoint({
    required double latitude,
    required double longitude,
  }) async {
    final params = {
      'f': 'json',
      'where': '1=1',
      'geometry': '${longitude.toStringAsFixed(8)},${latitude.toStringAsFixed(8)}',
      'geometryType': 'esriGeometryPoint',
      'inSR': '4326',
      'spatialRel': 'esriSpatialRelIntersects',
      'returnGeometry': 'false',
      'outFields': '*',
    };
    final json = await _get('$_lgaMapServer/$_layerLga/query', params);
    return _firstAttrs(json);
  }

  // --- HTTP + helpers ---

  static Future<Map<String, dynamic>> _get(
      String url, Map<String, String> params) async {
    try {
      final uri = Uri.parse(url).replace(queryParameters: params);
      print('🔍 RealPlanningService: Calling $uri');
      
      final res = await http
          .get(uri, headers: {
            'Accept': 'application/json',
          })
          .timeout(const Duration(seconds: 15), onTimeout: () {
            print('⚠️ RealPlanningService: Request timeout');
            // Return empty features instead of throwing
            return http.Response('{"features":[]}', 200);
          });
      
      print('🔍 RealPlanningService: Response status: ${res.statusCode}');
      
      if (res.statusCode != 200) {
        print('⚠️ RealPlanningService: HTTP ${res.statusCode}');
        // Return empty features for non-200 responses
        return {'features': []};
      }
      
      final jsonBody = json.decode(res.body) as Map<String, dynamic>;
      
      // If there's an error but it's not auth-related, just return empty
      if (jsonBody.containsKey('error')) {
        final error = jsonBody['error'];
        print('⚠️ RealPlanningService: API returned error: $error');
        return {'features': []};
      }
      
      return jsonBody;
    } catch (e) {
      print('❌ RealPlanningService: Exception: $e');
      // Return empty features instead of crashing
      return {'features': []};
    }
  }

  static List<Map<String, dynamic>> _attrsList(Map<String, dynamic> json) {
    final feats = (json['features'] as List?) ?? const [];
    return feats
        .map((f) => (f as Map)['attributes'] as Map<String, dynamic>)
        .toList();
  }

  static Map<String, dynamic>? _firstAttrs(Map<String, dynamic> json) {
    final feats = (json['features'] as List?) ?? const [];
    if (feats.isEmpty) return null;
    return (feats.first as Map)['attributes'] as Map<String, dynamic>;
  }

  // --- Field normalisers (handles slight schema differences safely) ---

  static Map<String, dynamic> _normaliseOverlay(Map<String, dynamic> a) {
    // MapServer field names: ZONE_CODE, ZONE_DESCRIPTION, SCHEME_CODE, LGA, etc.
    String? _pick(List<String> keys) =>
        keys.map((k) => a[k]).firstWhere((v) => v != null, orElse: () => null);

    return {
      'overlay': _pick(['ZONE_CODE', 'CODE_PARENT', 'SCHEME_CODE']) ?? '',
      'description': _pick(['ZONE_DESCRIPTION', 'ZONE_CODE_GROUP_LABEL']) ?? '',
      'scheme_code': _pick(['SCHEME_CODE', 'LGA_CODE']) ?? '',
      'lga': _pick(['LGA']) ?? '',
      'source': 'VicPlan MapShare (Public)'
    };
  }

  static Map<String, dynamic> _normaliseZone(Map<String, dynamic> a) {
    // MapServer field names
    String? _pick(List<String> keys) =>
        keys.map((k) => a[k]).firstWhere((v) => v != null, orElse: () => null);

    return {
      'zone': _pick(['ZONE_CODE']) ?? '',
      'description': _pick(['ZONE_DESCRIPTION', 'ZONE_CODE_GROUP_LABEL']) ?? '',
      'scheme_code': _pick(['SCHEME_CODE', 'LGA_CODE']) ?? '',
      'lga_name': _pick(['LGA']) ?? '',
      'source': 'VicPlan MapShare (Public)'
    };
  }
}
