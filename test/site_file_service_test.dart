import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';

import 'package:arborist_assistant/services/site_file_service.dart';
import 'package:arborist_assistant/models/site_file.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    SiteFileService.debugSetIsWeb(true);
    await SiteFileService.init();
  });

  setUp(() async {
    await SiteFileService.init();
    if (Hive.isBoxOpen(SiteFileService.boxName)) {
      await Hive.box<SiteFile>(SiteFileService.boxName).clear();
    } else {
      final box = await Hive.openBox<SiteFile>(SiteFileService.boxName);
      await box.clear();
    }
  });

  tearDownAll(() async {
    SiteFileService.debugSetIsWeb(null);
    await SiteFileService.closeForTest();
  });

  test('saveFileFromBytes stores byte data for web uploads', () async {
    final bytes = utf8.encode('example-content');

    final file = await SiteFileService.saveFileFromBytes(
      'site-web',
      bytes,
      'example.txt',
      'txt',
      uploadedBy: 'Test',
      category: 'General',
      folderPath: '/',
    );

    expect(file, isNotNull);
    expect(file!.fileBytes, isNotNull);
    expect(file.fileBytes, isNotEmpty);
    expect(String.fromCharCodes(file.fileBytes!), 'example-content');

    final stored = await SiteFileService.getFilesForSite('site-web');
    final uploadedFile = stored.firstWhere((entry) => entry.originalName == 'example.txt');
    expect(uploadedFile.fileBytes, isNotNull);
  });

  test('tree photos are organised into species folders', () async {
    final bytes = utf8.encode('photo-bytes');
    final folder = '/Photos/Tree 1 - Elm';

    final file = await SiteFileService.saveFileFromBytes(
      'site-tree',
      bytes,
      'Tree_1_1.jpg',
      'jpg',
      uploadedBy: 'Tree Form',
      category: 'Photos',
      folderPath: folder,
    );

    expect(file, isNotNull);
    expect(file!.folderPath, folder);
    expect(file.category, 'Photos');

    final folders = await SiteFileService.getFolders('site-tree', prefix: '/Photos');
    expect(folders.map((f) => f.folderPath), contains(folder));

    final files = await SiteFileService.getFilesForSite('site-tree');
    expect(files, isNotEmpty);
    expect(files.first.folderPath, folder);
  });
}
