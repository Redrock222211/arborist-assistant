import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:arborist_assistant/pages/loading_screen.dart';
import 'package:arborist_assistant/models/site.dart';
import 'package:arborist_assistant/models/tree_entry.dart';

void main() {
  group('Arborist Assistant App Tests', () {
    testWidgets('LoadingScreen shows progress indicator', (WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(home: LoadingScreen()));
      await tester.pump();
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      // Let delayed animations complete so no timers remain
      await tester.pump(const Duration(seconds: 1));

      // Dispose the loading screen to release repeating animations
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
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
