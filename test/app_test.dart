import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:arborist_assistant/main.dart';
import 'package:arborist_assistant/models/site.dart';
import 'package:arborist_assistant/models/tree_entry.dart';
import 'package:arborist_assistant/services/site_storage_service.dart';
import 'package:arborist_assistant/services/tree_storage_service.dart';

void main() {
  group('Arborist Assistant App Tests', () {
    testWidgets('App should start without crashing', (WidgetTester tester) async {
      // Build our app and trigger a frame
      await tester.pumpWidget(const ArboristAssistantApp());
      
      // Verify the app starts
      expect(find.byType(ArboristAssistantApp), findsOneWidget);
    });

    test('Site model should work correctly', () {
      final site = Site(
        id: 'test-123',
        name: 'Test Site',
        address: '123 Test Street',
        notes: 'Test notes',
      );
      
      expect(site.id, 'test-123');
      expect(site.name, 'Test Site');
      expect(site.address, '123 Test Street');
      expect(site.notes, 'Test notes');
    });

    test('Tree entry model should work correctly', () {
      final tree = TreeEntry(
        id: 'T001',
        species: 'Oak',
        dsh: 50.0,
        height: 15.0,
        condition: 'Good',
        comments: 'Healthy tree',
        permitRequired: false,
        latitude: -37.8136,
        longitude: 144.9631,
        srz: 600.0,
        nrz: 100.0,
        ageClass: 'Mature',
        retentionValue: 'High',
        riskRating: 'Low',
        locationDescription: 'Front yard',
        habitatValue: 'High',
        recommendedWorks: 'None required',
        healthForm: 'Good',
        diseasesPresent: 'None',
        canopySpread: 12.0,
        clearanceToStructures: 3.0,
        origin: 'Native',
        pastManagement: 'Regular pruning',
        pestPresence: 'None',
        notes: 'Well maintained tree',
        siteId: 'test-site',
        targetOccupancy: 'Residential',
        defectsObserved: [],
        likelihoodOfFailure: 'Low',
        likelihoodOfImpact: 'Low',
        consequenceOfFailure: 'Low',
        overallRiskRating: 'Low',
        vtaNotes: 'No defects observed',
        vtaDefects: [],
        inspectionDate: DateTime.now(),
        inspectorName: 'Test Inspector',
        voiceNotes: '',
        voiceNoteAudioPath: '',
        voiceAudioUrl: '',
        imageUrls: [],
        imageLocalPaths: [],
        syncStatus: 'synced',
      );
      
      expect(tree.id, 'T001');
      expect(tree.species, 'Oak');
      expect(tree.dsh, 50.0);
      expect(tree.condition, 'Good');
      expect(tree.siteId, 'test-site');
    });

    test('Condition color mapping should work', () {
      // Test condition color mapping (this would be in a utility function)
      Color getConditionColor(String condition) {
        switch (condition) {
          case 'Excellent':
            return const Color(0xFF4CAF50);
          case 'Good':
            return const Color(0xFF8BC34A);
          case 'Fair':
            return const Color(0xFFFFEB3B);
          case 'Poor':
            return const Color(0xFFFF9800);
          case 'Critical':
            return const Color(0xFFF44336);
          default:
            return const Color(0xFF9E9E9E);
        }
      }
      
      expect(getConditionColor('Excellent'), const Color(0xFF4CAF50));
      expect(getConditionColor('Good'), const Color(0xFF8BC34A));
      expect(getConditionColor('Critical'), const Color(0xFFF44336));
    });
  });
}
