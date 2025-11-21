import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:latlong2/latlong.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:arborist_assistant/drawing/services/csv_exporter.dart';
import 'package:arborist_assistant/models/report_type.dart';
import 'package:arborist_assistant/models/site.dart';
import 'package:arborist_assistant/models/tree_entry.dart';
import 'package:arborist_assistant/services/map_export_service.dart';
import 'package:arborist_assistant/services/report_generation_service.dart';
import 'package:arborist_assistant/services/tree_storage_service.dart';
import 'package:archive/archive.dart';

class _TestPathProviderPlatform extends PathProviderPlatform {
  _TestPathProviderPlatform(this._rootPath);

  final String _rootPath;

  @override
  Future<String?> getTemporaryPath() async => _rootPath;

  @override
  Future<String?> getApplicationDocumentsPath() async => _rootPath;

  @override
  Future<String?> getApplicationSupportPath() async => _rootPath;

  @override
  Future<List<String>?> getApplicationSupportPaths({String? suffix}) async => <String>[_rootPath];

  @override
  Future<String?> getDownloadsPath() async => _rootPath;

  @override
  Future<String?> getLibraryPath() async => _rootPath;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;
  late Box<TreeEntry> treeBox;
  late Site testSite;
  late TreeEntry baseTree;
  late String sampleImagePath;

  setUpAll(() async {
    SharedPreferences.setMockInitialValues(<String, Object>{});

    tempDir = await Directory.systemTemp.createTemp('report_exports_test');
    PathProviderPlatform.instance = _TestPathProviderPlatform(tempDir.path);

    // Create a tiny PNG image for embedding tests
    final pngBytes = Uint8List.fromList(
      const [
        0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, // PNG header
        0x00, 0x00, 0x00, 0x0D, // IHDR chunk length
        0x49, 0x48, 0x44, 0x52, // "IHDR"
        0x00, 0x00, 0x00, 0x01, // width:1
        0x00, 0x00, 0x00, 0x01, // height:1
        0x08, // bit depth
        0x02, // color type
        0x00, // compression
        0x00, // filter
        0x00, // interlace
        0x90, 0x77, 0x53, 0xDE, // CRC
        0x00, 0x00, 0x00, 0x0A, // IDAT length
        0x49, 0x44, 0x41, 0x54, // "IDAT"
        0x08, 0xD7, 0x63, 0xF8, 0x0F, 0x00, 0x01, 0x05, 0x01, 0x02, 0xE5, 0x27, 0xD4, 0xA2,
        0x00, 0x00, 0x00, 0x00, // IEND length
        0x49, 0x45, 0x4E, 0x44, 0xAE, 0x42, 0x60, 0x82,
      ],
    );
    final imageFile = File('${tempDir.path}/sample.png');
    await imageFile.writeAsBytes(pngBytes, flush: true);
    sampleImagePath = imageFile.path;

    MapExportService.setCaptureSiteMapImageOverride((
      _, {
      bool showSRZ = true,
      bool showNRZ = true,
      bool showTreeNumbers = true,
      bool satelliteView = false,
    }) async {
      return Uint8List.fromList(<int>[1, 2, 3, 4]);
    });

    Hive.init(tempDir.path);
    if (!Hive.isAdapterRegistered(0)) {
      Hive.registerAdapter(TreeEntryAdapter());
    }
    treeBox = await Hive.openBox<TreeEntry>(TreeStorageService.boxName);

    testSite = Site(
      id: 'site-1',
      name: 'Test Site',
      address: '1 Testing Avenue',
      latitude: -37.8136,
      longitude: 144.9631,
      notes: 'Verification site',
      createdAt: DateTime(2024, 5, 20),
    );
  });

  setUp(() async {
    await treeBox.clear();
    baseTree = _buildTree(siteId: testSite.id, imagePath: sampleImagePath);
    await treeBox.add(baseTree);
  });

  tearDownAll(() async {
    MapExportService.resetOverrides();
    await treeBox.close();
    await Hive.deleteBoxFromDisk(TreeStorageService.boxName);
    await Hive.close();
    if (tempDir.existsSync()) {
      await tempDir.delete(recursive: true);
    }
  });

  testWidgets('generateReport populates DOCX placeholders and embeds image', (WidgetTester tester) async {
    final Uint8List? bytes = await tester.runAsync(() async {
      return ReportGenerationService.generateReport(
        site: testSite,
        trees: <TreeEntry>[baseTree],
        reportType: ReportType.paa,
      );
    });

    expect(bytes, isNotNull);
    expect(bytes, isNotEmpty);
    _verifyDocxContent(bytes!, shouldContainImage: true);
  });

  testWidgets('exportReport writes DOCX with populated data to temporary directory', (WidgetTester tester) async {
    final String? filePath = await tester.runAsync(() async {
      return ReportGenerationService.exportReport(
        site: testSite,
        trees: <TreeEntry>[baseTree],
        reportType: ReportType.paa,
      );
    });

    expect(filePath, isNotNull);
    final File file = File(filePath!);
    expect(file.existsSync(), isTrue);
    expect(file.lengthSync(), greaterThan(0));

    final Uint8List bytes = await file.readAsBytes();
    _verifyDocxContent(bytes, shouldContainImage: true);

    await tester.runAsync(() async {
      if (await file.exists()) {
        await file.delete();
      }
    });
  });

  test('CsvExporter exports tree data including tree id and species', () {
    final List<Map<String, dynamic>> elements = <Map<String, dynamic>>[
      <String, dynamic>{
        'type': 'tree',
        'point': LatLng(baseTree.latitude, baseTree.longitude),
        'treeId': baseTree.id,
        'species': baseTree.species,
        'commonName': 'River Red Gum',
        'dbh': baseTree.dsh,
        'height': baseTree.height,
        'canopySpread': baseTree.canopySpread,
        'condition': baseTree.condition,
        'healthRating': baseTree.healthForm,
        'structureRating': baseTree.structuralRating,
        'retentionValue': baseTree.retentionValue,
        'riskRating': baseTree.riskRating,
        'recommendedActions': baseTree.recommendedWorks,
        'notes': baseTree.notes,
      },
    ];

    final String csv = CsvExporter.exportTreeDataToCsv(
      elements: elements,
      siteName: testSite.name,
      siteAddress: testSite.address,
      surveyorName: 'Test Arborist',
      surveyDate: DateTime(2024, 6, 1),
    );

    expect(csv, contains('Tree_ID'));
    expect(csv, contains(baseTree.id));
    expect(csv, contains(baseTree.species));
  });

  testWidgets('renderWidgetToImage captures widget snapshot bytes', (WidgetTester tester) async {
    final Uint8List? bytes = await tester.runAsync(() async {
      return MapExportService.renderWidgetToImage(
        Container(
          color: Colors.green,
          child: const Center(child: Text('Snapshot')),
        ),
        size: const Size(120, 80),
        pixelRatio: 1.5,
      );
    });

    expect(bytes, isNotNull);
    expect(bytes, isNotEmpty);
  });
}

TreeEntry _buildTree({required String siteId, required String imagePath}) {
  return TreeEntry(
    id: '1',
    species: 'Eucalyptus camaldulensis',
    dsh: 35,
    height: 14,
    condition: 'Good',
    comments: 'Healthy canopy with minor deadwood.',
    permitRequired: false,
    latitude: -37.8135,
    longitude: 144.9630,
    srz: 2.4,
    nrz: 6.2,
    ageClass: 'Mature',
    retentionValue: 'High',
    riskRating: 'Low',
    locationDescription: 'Front setback adjacent to driveway',
    habitatValue: 'Moderate',
    recommendedWorks: 'Minor formative pruning within 12 months',
    healthForm: 'Vigorous',
    diseasesPresent: 'None observed',
    canopySpread: 10,
    clearanceToStructures: 3,
    origin: 'Indigenous',
    pastManagement: 'Routine pruning',
    pestPresence: 'Nil',
    notes: 'Monitoring recommended following nearby construction activity.',
    siteId: siteId,
    structuralDefects: const <String>['Minor included bark at fork'],
    structuralRating: 'Good',
    inspectionDate: DateTime(2024, 5, 12),
    inspectorName: 'Alex Arborist',
    imageLocalPaths: <String>[imagePath],
    vtaDefects: const <String>[],
    stressIndicators: const <String>[],
    pruningType: const <String>[],
    habitatFeatures: const <String>[],
    monitoringFocus: const <String>[],
    exportGroups: const <String, bool>{
      'photos': true,
      'voice_notes': false,
    },
  );
}

void _verifyDocxContent(Uint8List bytes, {bool shouldContainImage = false}) {
  final debugDir = Directory('build/test_debug_reports');
  if (!debugDir.existsSync()) {
    debugDir.createSync(recursive: true);
  }
  final debugFile = File('${debugDir.path}/last_report.docx');
  debugFile.writeAsBytesSync(bytes, flush: true);

  final archive = ZipDecoder().decodeBytes(bytes);
  final documentFile = archive.files.firstWhere((file) => file.name == 'word/document.xml');
  final documentXml = utf8.decode(documentFile.content as List<int>);

  expect(documentXml.contains('\u0000'), isFalse, reason: 'Document XML should not contain null characters');
  expect(documentXml.contains(r'${'), isFalse, reason: 'All placeholders should have been replaced');
  expect(documentXml.contains('Test Site'), isTrue, reason: 'Site name should appear in DOCX');
  expect(documentXml.contains('Eucalyptus camaldulensis'), isTrue, reason: 'Tree species should appear in DOCX');

  final mediaFiles = archive.files.where((file) => file.name.startsWith('word/media/')).toList();
  if (shouldContainImage) {
    expect(mediaFiles, isNotEmpty, reason: 'Embedded images should be present in DOCX');
  }
}
