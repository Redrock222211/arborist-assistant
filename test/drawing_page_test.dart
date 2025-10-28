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

      // Verify the page loads
      expect(find.text('Drawing - Test Site'), findsOneWidget);
      expect(find.text('Select'), findsOneWidget);
      expect(find.text('Tree'), findsOneWidget);
      expect(find.text('Save'), findsOneWidget);
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

      // Check for essential toolbar elements
      expect(find.text('Tools'), findsOneWidget);
      expect(find.text('Layers'), findsOneWidget);
      expect(find.text('Tree Settings:'), findsOneWidget);
      expect(find.text('Layers:'), findsOneWidget);
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

      // Check for tree-specific settings
      expect(find.text('Tree #1'), findsOneWidget);
      expect(find.text('TPZ:'), findsOneWidget);
      expect(find.text('SRZ:'), findsOneWidget);
    });
  });
}
