import 'dart:typed_data';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class ExportService {
  static final FirebaseStorage _storage = FirebaseStorage.instance;
  
  // Generate filename with site ID and timestamp
  static String _generateFilename(String siteId, String extension) {
    final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
    return 'drawing_${siteId}_$timestamp.$extension';
  }
  
  // Get local documents directory
  static Future<Directory> get _localPath async {
    final directory = await getApplicationDocumentsDirectory();
    return directory;
  }
  
  // Save PNG file locally and upload to Firebase
  static Future<void> savePNG(Uint8List pngData, String siteId) async {
    try {
      final filename = _generateFilename(siteId, 'png');
      
      // Save locally
      final localDir = await _localPath;
      final localFile = File('${localDir.path}/$filename');
      await localFile.writeAsBytes(pngData);
      
      // Upload to Firebase Storage
      final ref = _storage.ref().child('drawings/$filename');
      await ref.putData(pngData);
      
      print('PNG saved locally: ${localFile.path}');
      print('PNG uploaded to Firebase: drawings/$filename');
    } catch (e) {
      print('Error saving PNG: $e');
      rethrow;
    }
  }
  
  // Save PDF file locally and upload to Firebase
  static Future<void> savePDF(Uint8List pngData, String siteId) async {
    try {
      final filename = _generateFilename(siteId, 'pdf');
      
      // Create PDF document
      final pdf = pw.Document();
      
      // Add page with the PNG image
      pdf.addPage(
        pw.Page(
          build: (context) => pw.Center(
            child: pw.Image(
              pw.MemoryImage(pngData),
              fit: pw.BoxFit.contain,
            ),
          ),
        ),
      );
      
      // Generate PDF bytes
      final pdfBytes = await pdf.save();
      
      // Save locally
      final localDir = await _localPath;
      final localFile = File('${localDir.path}/$filename');
      await localFile.writeAsBytes(pdfBytes);
      
      // Upload to Firebase Storage
      final ref = _storage.ref().child('drawings/$filename');
      await ref.putData(pdfBytes);
      
      print('PDF saved locally: ${localFile.path}');
      print('PDF uploaded to Firebase: drawings/$filename');
    } catch (e) {
      print('Error saving PDF: $e');
      rethrow;
    }
  }
  
  // Save DXF file locally and upload to Firebase
  static Future<void> saveDXF(String siteId, List<Map<String, dynamic>> elements) async {
    try {
      final filename = _generateFilename(siteId, 'dxf');
      
      // Generate DXF content
      final dxfContent = _generateDXF(elements);
      final dxfBytes = Uint8List.fromList(dxfContent.codeUnits);
      
      // Save locally
      final localDir = await _localPath;
      final localFile = File('${localDir.path}/$filename');
      await localFile.writeAsBytes(dxfBytes);
      
      // Upload to Firebase Storage
      final ref = _storage.ref().child('drawings/$filename');
      await ref.putData(dxfBytes);
      
      print('DXF saved locally: ${localFile.path}');
      print('DXF uploaded to Firebase: drawings/$filename');
    } catch (e) {
      print('Error saving DXF: $e');
      rethrow;
    }
  }
  
  // Save GeoJSON file locally and upload to Firebase
  static Future<void> saveGeoJSON(String siteId, Map<String, dynamic> geoJSON) async {
    try {
      final filename = _generateFilename(siteId, 'geojson');
      
      // Convert to JSON string
      final jsonString = _mapToJsonString(geoJSON);
      final jsonBytes = Uint8List.fromList(jsonString.codeUnits);
      
      // Save locally
      final localDir = await _localPath;
      final localFile = File('${localDir.path}/$filename');
      await localFile.writeAsBytes(jsonBytes);
      
      // Upload to Firebase Storage
      final ref = _storage.ref().child('drawings/$filename');
      await ref.putData(jsonBytes);
      
      print('GeoJSON saved locally: ${localFile.path}');
      print('GeoJSON uploaded to Firebase: drawings/$filename');
    } catch (e) {
      print('Error saving GeoJSON: $e');
      rethrow;
    }
  }
  
  // Generate DXF content from drawing elements
  static String _generateDXF(List<Map<String, dynamic>> elements) {
    final buffer = StringBuffer();
    
    // DXF header
    buffer.writeln('0');
    buffer.writeln('SECTION');
    buffer.writeln('2');
    buffer.writeln('HEADER');
    buffer.writeln('0');
    buffer.writeln('ENDSEC');
    
    // DXF entities
    buffer.writeln('0');
    buffer.writeln('SECTION');
    buffer.writeln('2');
    buffer.writeln('ENTITIES');
    
    // Process each element
    for (final element in elements) {
      switch (element['type']) {
        case 'circle':
          _addCircleToDXF(buffer, element);
          break;
        case 'line':
          _addLineToDXF(buffer, element);
          break;
        case 'rectangle':
          _addRectangleToDXF(buffer, element);
          break;
        case 'text':
          _addTextToDXF(buffer, element);
          break;
      }
    }
    
    // DXF footer
    buffer.writeln('0');
    buffer.writeln('ENDSEC');
    buffer.writeln('0');
    buffer.writeln('EOF');
    
    return buffer.toString();
  }
  
  // Add circle to DXF
  static void _addCircleToDXF(StringBuffer buffer, Map<String, dynamic> element) {
    final position = element['position'] as Offset;
    final radius = element['radius'] as double;
    
    buffer.writeln('0');
    buffer.writeln('CIRCLE');
    buffer.writeln('8');
    buffer.writeln('0');
    buffer.writeln('10');
    buffer.writeln(position.dx.toStringAsFixed(6));
    buffer.writeln('20');
    buffer.writeln(position.dy.toStringAsFixed(6));
    buffer.writeln('40');
    buffer.writeln(radius.toStringAsFixed(6));
  }
  
  // Add line to DXF
  static void _addLineToDXF(StringBuffer buffer, Map<String, dynamic> element) {
    final start = element['start'] as Offset;
    final end = element['end'] as Offset;
    
    buffer.writeln('0');
    buffer.writeln('LINE');
    buffer.writeln('8');
    buffer.writeln('0');
    buffer.writeln('10');
    buffer.writeln(start.dx.toStringAsFixed(6));
    buffer.writeln('20');
    buffer.writeln(start.dy.toStringAsFixed(6));
    buffer.writeln('11');
    buffer.writeln(end.dx.toStringAsFixed(6));
    buffer.writeln('21');
    buffer.writeln(end.dy.toStringAsFixed(6));
  }
  
  // Add rectangle to DXF
  static void _addRectangleToDXF(StringBuffer buffer, Map<String, dynamic> element) {
    final position = element['position'] as Offset;
    final size = element['size'] as Size;
    
    // Add 4 lines to form rectangle
    final points = [
      position,
      Offset(position.dx + size.width, position.dy),
      Offset(position.dx + size.width, position.dy + size.height),
      Offset(position.dx, position.dy + size.height),
      position, // Close the rectangle
    ];
    
    for (int i = 0; i < points.length - 1; i++) {
      buffer.writeln('0');
      buffer.writeln('LINE');
      buffer.writeln('8');
      buffer.writeln('0');
      buffer.writeln('10');
      buffer.writeln(points[i].dx.toStringAsFixed(6));
      buffer.writeln('20');
      buffer.writeln(points[i].dy.toStringAsFixed(6));
      buffer.writeln('11');
      buffer.writeln(points[i + 1].dx.toStringAsFixed(6));
      buffer.writeln('21');
      buffer.writeln(points[i + 1].dy.toStringAsFixed(6));
    }
  }
  
  // Add text to DXF
  static void _addTextToDXF(StringBuffer buffer, Map<String, dynamic> element) {
    final position = element['position'] as Offset;
    final text = element['text'] as String;
    
    buffer.writeln('0');
    buffer.writeln('TEXT');
    buffer.writeln('8');
    buffer.writeln('0');
    buffer.writeln('10');
    buffer.writeln(position.dx.toStringAsFixed(6));
    buffer.writeln('20');
    buffer.writeln(position.dy.toStringAsFixed(6));
    buffer.writeln('40');
    buffer.writeln('12.0'); // Text height
    buffer.writeln('1');
    buffer.writeln(text);
  }
  
  // Convert map to JSON string (simple implementation)
  static String _mapToJsonString(Map<String, dynamic> map) {
    final buffer = StringBuffer();
    _writeJsonValue(buffer, map);
    return buffer.toString();
  }
  
  // Recursively write JSON values
  static void _writeJsonValue(StringBuffer buffer, dynamic value) {
    if (value is Map) {
      buffer.write('{');
      final entries = value.entries.toList();
      for (int i = 0; i < entries.length; i++) {
        if (i > 0) buffer.write(',');
        buffer.write('"${entries[i].key}":');
        _writeJsonValue(buffer, entries[i].value);
      }
      buffer.write('}');
    } else if (value is List) {
      buffer.write('[');
      for (int i = 0; i < value.length; i++) {
        if (i > 0) buffer.write(',');
        _writeJsonValue(buffer, value[i]);
      }
      buffer.write(']');
    } else if (value is String) {
      buffer.write('"${value.replaceAll('"', '\\"')}"');
    } else if (value is num) {
      buffer.write(value.toString());
    } else if (value is bool) {
      buffer.write(value.toString());
    } else if (value == null) {
      buffer.write('null');
    } else {
      buffer.write('"${value.toString()}"');
    }
  }
}
