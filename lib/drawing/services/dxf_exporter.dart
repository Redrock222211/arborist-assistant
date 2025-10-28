import 'dart:typed_data';
import 'package:latlong2/latlong.dart';
import 'dart:math' as math;

/// DXF (Drawing Exchange Format) exporter for CAD compatibility.
/// Generates DXF files that can be opened in AutoCAD, QGIS, and other CAD software.
class DxfExporter {
  static String exportDrawingToDxf({
    required List<Map<String, dynamic>> elements,
    required String siteName,
    required String title,
    required LatLng center,
    required double zoom,
  }) {
    final buffer = StringBuffer();
    
    // DXF header
    _writeDxfHeader(buffer);
    
    // DXF entities section
    _writeEntitiesSection(buffer, elements, center, zoom);
    
    // DXF tables section
    _writeTablesSection(buffer);
    
    // DXF objects section
    _writeObjectsSection(buffer);
    
    // DXF end of file
    buffer.writeln('0');
    buffer.writeln('EOF');
    
    return buffer.toString();
  }

  // Write DXF header section
  static void _writeDxfHeader(StringBuffer buffer) {
    buffer.writeln('0');
    buffer.writeln('SECTION');
    buffer.writeln('2');
    buffer.writeln('HEADER');
    buffer.writeln('9');
    buffer.writeln('\$ACADVER');
    buffer.writeln('1');
    buffer.writeln('AC1018');
    buffer.writeln('9');
    buffer.writeln('\$DWGCODEPAGE');
    buffer.writeln('3');
    buffer.writeln('ANSI_1252');
    buffer.writeln('9');
    buffer.writeln('\$INSBASE');
    buffer.writeln('10');
    buffer.writeln('0.0');
    buffer.writeln('20');
    buffer.writeln('0.0');
    buffer.writeln('30');
    buffer.writeln('0.0');
    buffer.writeln('9');
    buffer.writeln('\$EXTMIN');
    buffer.writeln('10');
    buffer.writeln('-1000.0');
    buffer.writeln('20');
    buffer.writeln('-1000.0');
    buffer.writeln('30');
    buffer.writeln('0.0');
    buffer.writeln('9');
    buffer.writeln('\$EXTMAX');
    buffer.writeln('10');
    buffer.writeln('1000.0');
    buffer.writeln('20');
    buffer.writeln('1000.0');
    buffer.writeln('30');
    buffer.writeln('0.0');
    buffer.writeln('0');
    buffer.writeln('ENDSEC');
  }

  // Write DXF entities section
  static void _writeEntitiesSection(
    StringBuffer buffer,
    List<Map<String, dynamic>> elements,
    LatLng center,
    double zoom,
  ) {
    buffer.writeln('0');
    buffer.writeln('SECTION');
    buffer.writeln('2');
    buffer.writeln('ENTITIES');
    
    // Convert geographic coordinates to DXF coordinates
    final scale = _calculateScale(zoom);
    final offsetX = center.longitude;
    final offsetY = center.latitude;
    
    // Export each element
    for (final element in elements) {
      _exportElement(buffer, element, scale, offsetX, offsetY);
    }
    
    buffer.writeln('0');
    buffer.writeln('ENDSEC');
  }

  // Export individual drawing element
  static void _exportElement(
    StringBuffer buffer,
    Map<String, dynamic> element,
    double scale,
    double offsetX,
    double offsetY,
  ) {
    final type = element['type'] as String?;
    
    switch (type) {
      case 'tree':
        _exportTree(buffer, element, scale, offsetX, offsetY);
        break;
      case 'line':
      case 'polyline':
        _exportLine(buffer, element, scale, offsetX, offsetY);
        break;
      case 'polygon':
      case 'rectangle':
      case 'circle':
        _exportPolygon(buffer, element, scale, offsetX, offsetY);
        break;
      case 'text':
        _exportText(buffer, element, scale, offsetX, offsetY);
        break;
    }
  }

  // Export tree as circle with attributes
  static void _exportTree(
    StringBuffer buffer,
    Map<String, dynamic> element,
    double scale,
    double offsetX,
    double offsetY,
  ) {
    final point = element['point'] as LatLng;
    final x = (point.longitude - offsetX) * scale;
    final y = (point.latitude - offsetY) * scale;
    final radius = 2.0; // Tree symbol radius
    
    // Tree circle
    _writeCircle(buffer, x, y, radius);
    
    // Tree ID text
    final treeId = element['treeId'] as String?;
    if (treeId != null) {
      _writeText(buffer, x + radius + 1, y, treeId, 2.5);
    }
    
    // Tree species text
    final species = element['species'] as String?;
    if (species != null) {
      _writeText(buffer, x, y - radius - 2, species, 2.0);
    }
  }

  // Export line or polyline
  static void _exportLine(
    StringBuffer buffer,
    Map<String, dynamic> element,
    double scale,
    double offsetX,
    double offsetY,
  ) {
    final points = element['points'] as List<LatLng>?;
    if (points == null || points.length < 2) return;
    
    // Convert to DXF coordinates
    final dxfPoints = points.map((p) {
      return {
        'x': (p.longitude - offsetX) * scale,
        'y': (p.latitude - offsetY) * scale,
      };
    }).toList();
    
    // Write polyline
    _writePolyline(buffer, dxfPoints);
  }

  // Export polygon (including TPZ/SRZ zones)
  static void _exportPolygon(
    StringBuffer buffer,
    Map<String, dynamic> element,
    double scale,
    double offsetX,
    double offsetY,
  ) {
    final points = element['points'] as List<LatLng>?;
    if (points == null || points.length < 3) return;
    
    // Convert to DXF coordinates
    final dxfPoints = points.map((p) {
      return {
        'x': (p.longitude - offsetX) * scale,
        'y': (p.latitude - offsetY) * scale,
      };
    }).toList();
    
    // Close the polygon
    dxfPoints.add(dxfPoints.first);
    
    // Write polyline
    _writePolyline(buffer, dxfPoints);
    
    // Add zone label
    final layerId = element['layerId'] as String?;
    final label = element['label'] as String?;
    if (label != null && (layerId == 'tpz' || layerId == 'srz')) {
      final xValues = dxfPoints.map((p) => p['x'] as double).toList();
      final yValues = dxfPoints.map((p) => p['y'] as double).toList();
      final centerX = xValues.reduce((a, b) => a + b) / xValues.length;
      final centerY = yValues.reduce((a, b) => a + b) / yValues.length;
      _writeText(buffer, centerX, centerY, label, 3.0);
    }
  }

  // Export text
  static void _exportText(
    StringBuffer buffer,
    Map<String, dynamic> element,
    double scale,
    double offsetX,
    double offsetY,
  ) {
    final point = element['point'] as LatLng;
    final text = element['text'] as String?;
    if (text == null) return;
    
    final x = (point.longitude - offsetX) * scale;
    final y = (point.latitude - offsetY) * scale;
    
    _writeText(buffer, x, y, text, 2.5);
  }

  // Write DXF circle
  static void _writeCircle(StringBuffer buffer, double x, double y, double radius) {
    buffer.writeln('0');
    buffer.writeln('CIRCLE');
    buffer.writeln('8');
    buffer.writeln('TREES');
    buffer.writeln('10');
    buffer.writeln(x.toStringAsFixed(3));
    buffer.writeln('20');
    buffer.writeln(y.toStringAsFixed(3));
    buffer.writeln('30');
    buffer.writeln('0.0');
    buffer.writeln('40');
    buffer.writeln(radius.toStringAsFixed(3));
  }

  // Write DXF polyline
  static void _writePolyline(StringBuffer buffer, List<Map<String, double>> points) {
    buffer.writeln('0');
    buffer.writeln('POLYLINE');
    buffer.writeln('8');
    buffer.writeln('ANNOTATIONS');
    buffer.writeln('66');
    buffer.writeln('1');
    buffer.writeln('70');
    buffer.writeln('1'); // Closed polyline
    
    for (final point in points) {
      buffer.writeln('0');
      buffer.writeln('VERTEX');
      buffer.writeln('8');
      buffer.writeln('ANNOTATIONS');
      buffer.writeln('10');
      buffer.writeln(point['x']!.toStringAsFixed(3));
      buffer.writeln('20');
      buffer.writeln(point['y']!.toStringAsFixed(3));
      buffer.writeln('30');
      buffer.writeln('0.0');
    }
    
    buffer.writeln('0');
    buffer.writeln('SEQEND');
  }

  // Write DXF text
  static void _writeText(StringBuffer buffer, double x, double y, String text, double height) {
    buffer.writeln('0');
    buffer.writeln('TEXT');
    buffer.writeln('8');
    buffer.writeln('TEXT');
    buffer.writeln('10');
    buffer.writeln(x.toStringAsFixed(3));
    buffer.writeln('20');
    buffer.writeln(y.toStringAsFixed(3));
    buffer.writeln('30');
    buffer.writeln('0.0');
    buffer.writeln('40');
    buffer.writeln(height.toStringAsFixed(2));
    buffer.writeln('1');
    buffer.writeln(text);
    buffer.writeln('72');
    buffer.writeln('1'); // Left alignment
    buffer.writeln('73');
    buffer.writeln('2'); // Top alignment
  }

  // Write DXF tables section
  static void _writeTablesSection(StringBuffer buffer) {
    // Layer table
    buffer.writeln('0');
    buffer.writeln('SECTION');
    buffer.writeln('2');
    buffer.writeln('TABLES');
    
    // Layer table
    buffer.writeln('0');
    buffer.writeln('TABLE');
    buffer.writeln('2');
    buffer.writeln('LAYER');
    buffer.writeln('70');
    buffer.writeln('3');
    
    // Default layer
    _writeLayer(buffer, '0', '7', 'CONTINUOUS');
    // Tree layer
    _writeLayer(buffer, 'TREES', '1', 'CONTINUOUS');
    // Annotation layer
    _writeLayer(buffer, 'ANNOTATIONS', '2', 'CONTINUOUS');
    // Text layer
    _writeLayer(buffer, 'TEXT', '3', 'CONTINUOUS');
    
    buffer.writeln('0');
    buffer.writeln('ENDTAB');
    
    buffer.writeln('0');
    buffer.writeln('ENDSEC');
  }

  // Write DXF layer
  static void _writeLayer(StringBuffer buffer, String name, String color, String linetype) {
    buffer.writeln('0');
    buffer.writeln('LAYER');
    buffer.writeln('2');
    buffer.writeln(name);
    buffer.writeln('70');
    buffer.writeln('0');
    buffer.writeln('62');
    buffer.writeln(color);
    buffer.writeln('6');
    buffer.writeln(linetype);
  }

  // Write DXF objects section
  static void _writeObjectsSection(StringBuffer buffer) {
    buffer.writeln('0');
    buffer.writeln('SECTION');
    buffer.writeln('2');
    buffer.writeln('OBJECTS');
    buffer.writeln('0');
    buffer.writeln('ENDSEC');
  }

  // Calculate scale factor based on zoom level
  static double _calculateScale(double zoom) {
    // Approximate scale: zoom 18 = 1:1000, zoom 19 = 1:500, etc.
    return math.pow(2, 18 - zoom) * 1000;
  }
}
