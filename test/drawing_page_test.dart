import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:arborist_assistant/pages/drawing_page.dart';
import 'package:arborist_assistant/models/site.dart';

void main() {
  group('DrawingPage Tests', () {
    testWidgets('DrawingPage builds without errors', (WidgetTester tester) async {
      // Create a test site
      final testSite = Site(
        id: 'test-site',
        name: 'Test Site',
        address: '123 Test Street',
        notes: 'Test Site Notes',
      );

      // Build the drawing page
      await tester.pumpWidget(
        MaterialApp(
          home: DrawingPage(site: testSite),
        ),
      );
      await tester.pumpAndSettle();

      // Verify the page loads
      expect(find.text('Drawing - Test Site'), findsOneWidget);
      expect(find.text('Select'), findsOneWidget);
      expect(find.text('Save'), findsOneWidget);
      expect(find.text('Encroachment Summary'), findsOneWidget);
    });

    testWidgets('DrawingPage shows correct toolbar elements', (WidgetTester tester) async {
      final testSite = Site(
        id: 'test-site',
        name: 'Test Site',
        address: '123 Test Street',
        notes: 'Test Site Notes',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: DrawingPage(site: testSite),
        ),
      );
      await tester.pumpAndSettle();

      // Check for essential toolbar elements
      expect(find.text('Tools'), findsOneWidget);
      expect(find.text('House'), findsOneWidget);
      expect(find.text('Driveway'), findsOneWidget);
      await tester.ensureVisible(find.text('Layers'));
      expect(find.text('Layers'), findsOneWidget);
      await tester.ensureVisible(find.text('Tree Settings:'));
      expect(find.text('Tree Settings:'), findsOneWidget);
    });

    testWidgets('DrawingPage has correct tree settings', (WidgetTester tester) async {
      final testSite = Site(
        id: 'test-site',
        name: 'Test Site',
        address: '123 Test Street',
        notes: 'Test Site Notes',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: DrawingPage(site: testSite),
        ),
      );
      await tester.pumpAndSettle();

      // Check for tree-specific settings section placeholder when no data yet
      await tester.ensureVisible(find.text('Tree Settings:'));
      expect(find.text('Tree Settings:'), findsOneWidget);
      expect(find.text('No trees available for this site.'), findsOneWidget);
    });
  });
}
