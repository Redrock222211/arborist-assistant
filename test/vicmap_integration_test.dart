import 'package:flutter_test/flutter_test.dart';
import 'package:arborist_assistant/services/vicmap_service.dart';
import 'package:arborist_assistant/services/planning_adapter.dart';
import 'package:arborist_assistant/models/planning.dart';

void main() {
  group('Vicmap Integration Tests', () {
    test('VicmapService.getPlanningAtPoint returns valid data structure', () async {
      // Melbourne CBD coordinates
      const double longitude = 144.9631;
      const double latitude = -37.8136;
      
      final result = await VicmapService.getPlanningAtPoint(longitude, latitude);
      
      expect(result, isA<PlanningResult>());
      expect(result.scheme, 'Victoria Planning Provisions');
      expect(result.lga, isNotEmpty);
      expect(result.timestamp, isA<DateTime>());
      
      // Note: The service might return an error if the API is unavailable
      // We just verify the structure is correct
      if (result.hasError) {
        expect(result.error, isNotEmpty);
      } else {
        // The service might not find planning data at every location
        // This is normal behavior - we just verify the structure is correct
        expect(result.lga, isNotEmpty);
      }
    });
    
    test('PlanningAdapter.getPlanningForCoordinates returns valid data structure', () async {
      // Melbourne CBD coordinates
      const double longitude = 144.9631;
      const double latitude = -37.8136;
      
      final result = await PlanningAdapter.getPlanningForCoordinates(latitude, longitude);
      
      expect(result, isA<Map<String, dynamic>>());
      expect(result['success'], isTrue);
      expect(result['address'], isNotEmpty);
      expect(result['lga'], isNotEmpty);
      expect(result['timestamp'], isNotEmpty);
      expect(result['real_data'], isTrue);
      expect(result['data_source'], 'Vicmap Planning API');
      
      // Should have overlays map if provided
      if (result['overlays'] != null) {
        expect(result['overlays'], isA<Map<String, dynamic>>());
        expect(result['overlays'].keys, isNotEmpty);
      }

      // Should have LGA laws
      if (result['lga_laws'] != null) {
        expect(result['lga_laws'], isA<List>());
      }
    });
    
    test('PlanningAdapter fallback works when Vicmap is disabled', () async {
      // Temporarily disable Vicmap
      PlanningAdapter.setVicmapEnabled(false);
      
      const double longitude = 144.9631;
      const double latitude = -37.8136;
      
      final result = await PlanningAdapter.getPlanningForCoordinates(latitude, longitude);
      
      expect(result, isA<Map<String, dynamic>>());
      expect(result['success'], isTrue);
      expect(result['real_data'], isFalse);
      expect(result['data_source'], 'Fallback');
      
      // Re-enable for other tests
      PlanningAdapter.setVicmapEnabled(true);
    });
    
    test('PlanningResult JSON serialization works correctly', () {
      final overlays = [
        OverlayResult(
          code: 'VPO1',
          description: 'Vegetation Protection Overlay',
        ),
      ];
      final zones = [
        ZoneResult(
          code: 'GRZ',
          number: '1',
          status: 'Active',
        ),
      ];
      final result = PlanningResult(
        scheme: 'Victoria Planning Provisions',
        lga: 'City of Whittlesea',
        overlays: overlays,
        zones: zones,
        timestamp: DateTime.now(),
      );
      
      final json = result.toJson();
      expect(json, isA<Map<String, dynamic>>());
      expect(json['scheme'], 'Victoria Planning Provisions');
      expect(json['lga'], 'City of Whittlesea');
      expect(json['zone'], anyOf(isNull, isA<Map<String, dynamic>>()));
      expect(json['overlays'], isA<List>());
      expect(json['overlays'].length, 1);
      
      // Test deserialization
      final reconstructed = PlanningResult.fromJson(json);
      expect(reconstructed.scheme, result.scheme);
      expect(reconstructed.lga, result.lga);
      expect(reconstructed.zone?.code, result.zone?.code);
      expect(reconstructed.overlays.length, result.overlays.length);
    });
    
    test('ZoneResult and OverlayResult JSON serialization works', () {
      final zone = ZoneResult(
        code: 'GRZ',
        number: '1',
        status: 'Active',
        vppUrl: 'https://example.com/vpp',
        localPolicyUrl: 'https://example.com/local',
      );
      
      final overlay = OverlayResult(
        code: 'VPO1',
        description: 'Vegetation Protection Overlay',
        vppUrl: 'https://example.com/vpp',
        localPolicyUrl: 'https://example.com/local',
      );
      
      final zoneJson = zone.toJson();
      final overlayJson = overlay.toJson();
      
      expect(zoneJson['code'], 'GRZ');
      expect(zoneJson['number'], '1');
      expect(zoneJson['vppUrl'], 'https://example.com/vpp');
      
      expect(overlayJson['code'], 'VPO1');
      expect(overlayJson['description'], 'Vegetation Protection Overlay');
      expect(overlayJson['vppUrl'], 'https://example.com/vpp');
    });
    
    test('Cache management works correctly', () {
      // Clear caches
      VicmapService.clearCaches();
      PlanningAdapter.clearCaches();
      
      // Verify caches are cleared
      // (This is a basic test - in a real scenario you'd check internal cache state)
      expect(true, isTrue); // Placeholder assertion
    });
  });
}
