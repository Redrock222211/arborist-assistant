import 'dart:convert';
import 'package:latlong2/latlong.dart';
import 'package:flutter/material.dart';

/// Professional layer management service for arboricultural CAD operations.
/// Supports import/export of layers in GeoJSON, KML, and custom formats.
class LayerManager {
  
  /// Export layers to GeoJSON format
  static String exportLayersToGeoJson({
    required List<Map<String, dynamic>> elements,
    required List<Map<String, dynamic>> layers,
    required String siteName,
    String? siteAddress,
    String? surveyorName,
    DateTime? surveyDate,
  }) {
    final featureCollection = {
      'type': 'FeatureCollection',
      'crs': {
        'type': 'name',
        'properties': {
          'name': 'urn:ogc:def:crs:OGC:1.3:CRS84'
        }
      },
      'features': <Map<String, dynamic>>[],
      'properties': {
        'site_name': siteName,
        'site_address': siteAddress,
        'surveyor': surveyorName,
        'survey_date': surveyDate?.toIso8601String(),
        'export_date': DateTime.now().toIso8601String(),
        'software': 'Arborist Assistant',
        'version': '1.0.0',
      }
    };
    
    // Group elements by layer
    final elementsByLayer = <String, List<Map<String, dynamic>>>{};
    for (final element in elements) {
      final layerId = element['layerId'] as String? ?? 'default';
      elementsByLayer.putIfAbsent(layerId, () => []).add(element);
    }
    
    // Create features for each element
    for (final layer in layers) {
      final layerId = layer['id'] as String;
      final layerElements = elementsByLayer[layerId] ?? [];
      
      for (final element in layerElements) {
        final feature = _elementToGeoJsonFeature(element, layer);
        if (feature != null) {
          (featureCollection['features'] as List<Map<String, dynamic>>).add(feature);
        }
      }
    }
    
    return jsonEncode(featureCollection);
  }
  
  /// Export layers to KML format
  static String exportLayersToKml({
    required List<Map<String, dynamic>> elements,
    required List<Map<String, dynamic>> layers,
    required String siteName,
    String? siteAddress,
    String? surveyorName,
    DateTime? surveyDate,
  }) {
    final kml = StringBuffer();
    
    // KML header
    kml.writeln('<?xml version="1.0" encoding="UTF-8"?>');
    kml.writeln('<kml xmlns="http://www.opengis.net/kml/2.2">');
    kml.writeln('<Document>');
    
    // Document metadata
    kml.writeln('<name>${_escapeXml(siteName)}</name>');
    kml.writeln('<description>Arborist Survey - ${_escapeXml(siteName)}</description>');
    if (siteAddress != null) {
      kml.writeln('<Snippet>${_escapeXml(siteAddress)}</Snippet>');
    }
    
    // Extended data
    kml.writeln('<ExtendedData>');
    kml.writeln('  <Data name="surveyor">');
    kml.writeln('    <value>${_escapeXml(surveyorName ?? 'Unknown')}</value>');
    kml.writeln('  </Data>');
    kml.writeln('  <Data name="survey_date">');
    kml.writeln('    <value>${surveyDate?.toIso8601String() ?? DateTime.now().toIso8601String()}</value>');
    kml.writeln('  </Data>');
    kml.writeln('  <Data name="software">');
    kml.writeln('    <value>Arborist Assistant</value>');
    kml.writeln('  </Data>');
    kml.writeln('</ExtendedData>');
    
    // Group elements by layer
    final elementsByLayer = <String, List<Map<String, dynamic>>>{};
    for (final element in elements) {
      final layerId = element['layerId'] as String? ?? 'default';
      elementsByLayer.putIfAbsent(layerId, () => []).add(element);
    }
    
    // Create placemarks for each layer
    for (final layer in layers) {
      final layerId = layer['id'] as String;
      final layerName = layer['name'] as String? ?? layerId;
      final layerElements = elementsByLayer[layerId] ?? [];
      
      if (layerElements.isNotEmpty) {
        kml.writeln('<Folder>');
        kml.writeln('  <name>${_escapeXml(layerName)}</name>');
        kml.writeln('  <description>${_escapeXml(layerName)} layer</description>');
        
        for (final element in layerElements) {
          final placemark = _elementToKmlPlacemark(element, layer);
          if (placemark != null) {
            kml.writeln(placemark);
          }
        }
        
        kml.writeln('</Folder>');
      }
    }
    
    kml.writeln('</Document>');
    kml.writeln('</kml>');
    
    return kml.toString();
  }
  
  /// Import layers from GeoJSON format
  static Map<String, dynamic> importLayersFromGeoJson({
    required String geoJsonContent,
    required String targetLayerId,
  }) {
    try {
      final data = jsonDecode(geoJsonContent) as Map<String, dynamic>;
      final features = data['features'] as List<dynamic>? ?? [];
      
      final importedElements = <Map<String, dynamic>>[];
      final layerInfo = <String, dynamic>{};
      
      // Extract layer information from properties
      if (data['properties'] is Map<String, dynamic>) {
        final properties = data['properties'] as Map<String, dynamic>;
        layerInfo['name'] = properties['site_name'] ?? 'Imported Layer';
        layerInfo['description'] = properties['site_address'] ?? '';
        layerInfo['source'] = properties['software'] ?? 'GeoJSON Import';
        layerInfo['import_date'] = DateTime.now().toIso8601String();
      }
      
      // Convert features to drawing elements
      for (final feature in features) {
        if (feature is Map<String, dynamic>) {
          final element = _geoJsonFeatureToElement(feature, targetLayerId);
          if (element != null) {
            importedElements.add(element);
          }
        }
      }
      
      return {
        'success': true,
        'elements': importedElements,
        'layerInfo': layerInfo,
        'count': importedElements.length,
      };
    } catch (e) {
      return {
        'success': false,
        'error': 'Failed to parse GeoJSON: $e',
        'elements': <Map<String, dynamic>>[],
        'layerInfo': <String, dynamic>{},
        'count': 0,
      };
    }
  }
  
  /// Import layers from KML format
  static Map<String, dynamic> importLayersFromKml({
    required String kmlContent,
    required String targetLayerId,
  }) {
    try {
      // Simple KML parsing - in production, use a proper XML parser
      final importedElements = <Map<String, dynamic>>[];
      final layerInfo = <String, dynamic>{};
      
      // Extract basic information
      final siteNameMatch = RegExp(r'<name>(.*?)</name>').firstMatch(kmlContent);
      if (siteNameMatch != null) {
        layerInfo['name'] = siteNameMatch.group(1) ?? 'Imported Layer';
      }
      
      // Extract coordinates from Placemark elements
      final placemarkMatches = RegExp(r'<Placemark>(.*?)</Placemark>', dotAll: true).allMatches(kmlContent);
      
      for (final match in placemarkMatches) {
        final placemark = match.group(1) ?? '';
        final element = _kmlPlacemarkToElement(placemark, targetLayerId);
        if (element != null) {
          importedElements.add(element);
        }
      }
      
      layerInfo['source'] = 'KML Import';
      layerInfo['import_date'] = DateTime.now().toIso8601String();
      
      return {
        'success': true,
        'elements': importedElements,
        'layerInfo': layerInfo,
        'count': importedElements.length,
      };
    } catch (e) {
      return {
        'success': false,
        'error': 'Failed to parse KML: $e',
        'elements': <Map<String, dynamic>>[],
        'layerInfo': <String, dynamic>{},
        'count': 0,
      };
    }
  }
  
  /// Export layer structure and metadata
  static Map<String, dynamic> exportLayerStructure({
    required List<Map<String, dynamic>> layers,
    required List<Map<String, dynamic>> elements,
  }) {
    final layerStructure = <String, dynamic>{};
    
    for (final layer in layers) {
      final layerId = layer['id'] as String;
      final layerElements = elements.where((e) => e['layerId'] == layerId).toList();
      
      layerStructure[layerId] = {
        'name': layer['name'] ?? layerId,
        'visible': layer['visible'] ?? true,
        'locked': layer['locked'] ?? false,
        'color': layer['color']?.toString(),
        'elementCount': layerElements.length,
        'elementTypes': layerElements.map((e) => e['type'] as String).toSet().toList(),
        'metadata': {
          'created': layer['created'] ?? DateTime.now().toIso8601String(),
          'modified': layer['modified'] ?? DateTime.now().toIso8601String(),
          'description': layer['description'] ?? '',
        }
      };
    }
    
    return {
      'exportDate': DateTime.now().toIso8601String(),
      'software': 'Arborist Assistant',
      'version': '1.0.0',
      'layers': layerStructure,
      'totalElements': elements.length,
      'totalLayers': layers.length,
    };
  }
  
  /// Import layer structure and metadata
  static Map<String, dynamic> importLayerStructure({
    required Map<String, dynamic> structureData,
    required List<Map<String, dynamic>> existingLayers,
  }) {
    try {
      final importedLayers = <Map<String, dynamic>>[];
      final layerMappings = <String, String>{}; // oldId -> newId
      
      if (structureData['layers'] is Map<String, dynamic>) {
        final layers = structureData['layers'] as Map<String, dynamic>;
        
        for (final entry in layers.entries) {
          final oldId = entry.key;
          final layerData = entry.value as Map<String, dynamic>;
          
          // Generate new unique ID
          final newId = _generateUniqueLayerId(layerData['name'] ?? oldId, existingLayers);
          layerMappings[oldId] = newId;
          
          final newLayer = {
            'id': newId,
            'name': layerData['name'] ?? oldId,
            'visible': layerData['visible'] ?? true,
            'locked': layerData['locked'] ?? false,
            'color': _parseColor(layerData['color']),
            'description': layerData['metadata']?['description'] ?? '',
            'created': DateTime.now().toIso8601String(),
            'modified': DateTime.now().toIso8601String(),
            'imported': true,
            'source': structureData['software'] ?? 'Unknown',
            'originalId': oldId,
          };
          
          importedLayers.add(newLayer);
        }
      }
      
      return {
        'success': true,
        'layers': importedLayers,
        'mappings': layerMappings,
        'count': importedLayers.length,
      };
    } catch (e) {
      return {
        'success': false,
        'error': 'Failed to import layer structure: $e',
        'layers': <Map<String, dynamic>>[],
        'mappings': <String, String>{},
        'count': 0,
      };
    }
  }
  
  // Helper methods
  
  /// Convert drawing element to GeoJSON feature
  static Map<String, dynamic>? _elementToGeoJsonFeature(
    Map<String, dynamic> element,
    Map<String, dynamic> layer,
  ) {
    final type = element['type'] as String?;
    if (type == null) return null;
    
    Map<String, dynamic>? geometry;
    Map<String, dynamic> properties = {
      'type': type,
      'layer': layer['name'] ?? layer['id'],
      'color': element['color']?.toString(),
      'width': element['width'],
    };
    
    switch (type) {
      case 'tree':
        final point = element['point'] as LatLng?;
        if (point != null) {
          geometry = {
            'type': 'Point',
            'coordinates': [point.longitude, point.latitude],
          };
          properties['treeId'] = element['treeId'];
          properties['species'] = element['species'];
          properties['dbh'] = element['dbh'];
        }
        break;
        
      case 'line':
      case 'polyline':
        final points = element['points'] as List<LatLng>?;
        if (points != null && points.isNotEmpty) {
          geometry = {
            'type': 'LineString',
            'coordinates': points.map((p) => [p.longitude, p.latitude]).toList(),
          };
        }
        break;
        
      case 'polygon':
      case 'rectangle':
      case 'circle':
        final points = element['points'] as List<LatLng>?;
        if (points != null && points.isNotEmpty) {
          geometry = {
            'type': 'Polygon',
            'coordinates': [points.map((p) => [p.longitude, p.latitude]).toList()],
          };
          properties['area'] = element['area'];
          properties['perimeter'] = element['perimeter'];
        }
        break;
        
      case 'text':
        final point = element['point'] as LatLng?;
        if (point != null) {
          geometry = {
            'type': 'Point',
            'coordinates': [point.longitude, point.latitude],
          };
          properties['text'] = element['text'];
        }
        break;
    }
    
    if (geometry == null) return null;
    
    return {
      'type': 'Feature',
      'geometry': geometry,
      'properties': properties,
    };
  }
  
  /// Convert drawing element to KML placemark
  static String? _elementToKmlPlacemark(
    Map<String, dynamic> element,
    Map<String, dynamic> layer,
  ) {
    final type = element['type'] as String?;
    if (type == null) return null;
    
    final name = element['label'] ?? element['text'] ?? type;
    final description = _buildKmlDescription(element, layer);
    
    String coordinates = '';
    String geometryType = '';
    
    switch (type) {
      case 'tree':
        final point = element['point'] as LatLng?;
        if (point != null) {
          coordinates = '${point.longitude},${point.latitude},0';
          geometryType = 'Point';
        }
        break;
        
      case 'line':
      case 'polyline':
        final points = element['points'] as List<LatLng>?;
        if (points != null && points.isNotEmpty) {
          coordinates = points.map((p) => '${p.longitude},${p.latitude},0').join(' ');
          geometryType = 'LineString';
        }
        break;
        
      case 'polygon':
      case 'rectangle':
      case 'circle':
        final points = element['points'] as List<LatLng>?;
        if (points != null && points.isNotEmpty) {
          coordinates = points.map((p) => '${p.longitude},${p.latitude},0').join(' ');
          geometryType = 'Polygon';
        }
        break;
        
      case 'text':
        final point = element['point'] as LatLng?;
        if (point != null) {
          coordinates = '${point.longitude},${point.latitude},0';
          geometryType = 'Point';
        }
        break;
    }
    
    if (coordinates.isEmpty) return null;
    
    return '''
  <Placemark>
    <name>${_escapeXml(name)}</name>
    <description><![CDATA[$description]]></description>
    <styleUrl>#${_getKmlStyle(type)}</styleUrl>
    <${geometryType.toLowerCase()}>
      <coordinates>$coordinates</coordinates>
    </${geometryType.toLowerCase()}>
  </Placemark>''';
  }
  
  /// Convert GeoJSON feature to drawing element
  static Map<String, dynamic>? _geoJsonFeatureToElement(
    Map<String, dynamic> feature,
    String targetLayerId,
  ) {
    final geometry = feature['geometry'] as Map<String, dynamic>?;
    final properties = feature['properties'] as Map<String, dynamic>?;
    
    if (geometry == null || properties == null) return null;
    
    final type = properties['type'] as String?;
    if (type == null) return null;
    
    final coordinates = geometry['coordinates'] as dynamic;
    
    switch (type) {
      case 'tree':
        if (coordinates is List && coordinates.length >= 2) {
          return {
            'type': 'tree',
            'point': LatLng(coordinates[1].toDouble(), coordinates[0].toDouble()),
            'treeId': properties['treeId'] ?? 'T${DateTime.now().millisecondsSinceEpoch}',
            'species': properties['species'] ?? '',
            'dbh': properties['dbh'] ?? 0.0,
            'color': _parseColor(properties['color']),
            'width': (properties['width'] as num?)?.toDouble() ?? 2.0,
            'layerId': targetLayerId,
            'imported': true,
          };
        }
        break;
        
      case 'line':
      case 'polyline':
        if (coordinates is List) {
          final points = coordinates.map<LatLng>((coord) {
            if (coord is List && coord.length >= 2) {
              return LatLng(coord[1].toDouble(), coord[0].toDouble());
            }
            return LatLng(0, 0);
          }).toList();
          
          return {
            'type': type,
            'points': points,
            'color': _parseColor(properties['color']),
            'width': (properties['width'] as num?)?.toDouble() ?? 2.0,
            'layerId': targetLayerId,
            'imported': true,
          };
        }
        break;
        
      case 'polygon':
        if (coordinates is List && coordinates.isNotEmpty) {
          final outerRing = coordinates[0] as List?;
          if (outerRing != null) {
            final points = outerRing.map<LatLng>((coord) {
              if (coord is List && coord.length >= 2) {
                return LatLng(coord[1].toDouble(), coord[0].toDouble());
              }
              return LatLng(0, 0);
            }).toList();
            
            return {
              'type': 'polygon',
              'points': points,
              'color': _parseColor(properties['color']),
              'width': (properties['width'] as num?)?.toDouble() ?? 2.0,
              'layerId': targetLayerId,
              'imported': true,
            };
          }
        }
        break;
        
      case 'text':
        if (coordinates is List && coordinates.length >= 2) {
          return {
            'type': 'text',
            'point': LatLng(coordinates[1].toDouble(), coordinates[0].toDouble()),
            'text': properties['text'] ?? '',
            'color': _parseColor(properties['color']),
            'layerId': targetLayerId,
            'imported': true,
          };
        }
        break;
    }
    
    return null;
  }
  
  /// Convert KML placemark to drawing element
  static Map<String, dynamic>? _kmlPlacemarkToElement(
    String placemark,
    String targetLayerId,
  ) {
    // Simple KML parsing - extract coordinates and basic info
    final coordinatesMatch = RegExp(r'<coordinates>(.*?)</coordinates>').firstMatch(placemark);
    if (coordinatesMatch == null) return null;
    
    final coordsText = coordinatesMatch.group(1) ?? '';
    final coordPairs = coordsText.trim().split(' ');
    
    if (coordPairs.isEmpty) return null;
    
    // Parse first coordinate pair
    final firstCoord = coordPairs.first.split(',');
    if (firstCoord.length < 2) return null;
    
    final longitude = double.tryParse(firstCoord[0]) ?? 0.0;
    final latitude = double.tryParse(firstCoord[1]) ?? 0.0;
    
    // Determine type based on coordinate count
    if (coordPairs.length == 1) {
      // Single point - could be tree or text
      final nameMatch = RegExp(r'<name>(.*?)</name>').firstMatch(placemark);
      final name = nameMatch?.group(1) ?? 'Imported Point';
      
      return {
        'type': 'tree',
        'point': LatLng(latitude, longitude),
        'treeId': 'T${DateTime.now().millisecondsSinceEpoch}',
        'species': 'Imported',
        'color': Colors.green,
        'width': 2.0,
        'layerId': targetLayerId,
        'imported': true,
        'label': name,
      };
    } else {
      // Multiple coordinates - line or polygon
      final points = coordPairs.map<LatLng>((coordText) {
        final parts = coordText.split(',');
        if (parts.length >= 2) {
          return LatLng(
            double.tryParse(parts[1]) ?? 0.0,
            double.tryParse(parts[0]) ?? 0.0,
          );
        }
        return LatLng(0, 0);
      }).toList();
      
      return {
        'type': coordPairs.length > 2 ? 'polygon' : 'line',
        'points': points,
        'color': Colors.blue,
        'width': 2.0,
        'layerId': targetLayerId,
        'imported': true,
      };
    }
  }
  
  /// Build KML description for element
  static String _buildKmlDescription(Map<String, dynamic> element, Map<String, dynamic> layer) {
    final buffer = StringBuffer();
    buffer.writeln('<b>Type:</b> ${element['type']}<br>');
    buffer.writeln('<b>Layer:</b> ${layer['name'] ?? layer['id']}<br>');
    
    if (element['treeId'] != null) {
      buffer.writeln('<b>Tree ID:</b> ${element['treeId']}<br>');
    }
    if (element['species'] != null) {
      buffer.writeln('<b>Species:</b> ${element['species']}<br>');
    }
    if (element['dbh'] != null) {
      buffer.writeln('<b>DBH:</b> ${element['dbh']} cm<br>');
    }
    if (element['text'] != null) {
      buffer.writeln('<b>Text:</b> ${element['text']}<br>');
    }
    if (element['area'] != null) {
      buffer.writeln('<b>Area:</b> ${element['area']} m²<br>');
    }
    
    return buffer.toString();
  }
  
  /// Get KML style for element type
  static String _getKmlStyle(String type) {
    switch (type) {
      case 'tree':
        return 'tree-style';
      case 'line':
      case 'polyline':
        return 'line-style';
      case 'polygon':
      case 'rectangle':
      case 'circle':
        return 'polygon-style';
      case 'text':
        return 'text-style';
      default:
        return 'default-style';
    }
  }
  
  /// Generate unique layer ID
  static String _generateUniqueLayerId(String baseName, List<Map<String, dynamic>> existingLayers) {
    String candidateId = baseName.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '_');
    int counter = 1;
    
    while (existingLayers.any((layer) => layer['id'] == candidateId)) {
      candidateId = '${baseName.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '_')}_$counter';
      counter++;
    }
    
    return candidateId;
  }
  
  /// Parse color from string
  static Color _parseColor(dynamic colorValue) {
    if (colorValue == null) return Colors.black;
    
    if (colorValue is String) {
      // Try to parse hex color
      if (colorValue.startsWith('#')) {
        try {
          return Color(int.parse(colorValue.substring(1), radix: 16));
        } catch (e) {
          // Fall through to default
        }
      }
      
      // Try to parse named colors
      switch (colorValue.toLowerCase()) {
        case 'red':
          return Colors.red;
        case 'green':
          return Colors.green;
        case 'blue':
          return Colors.blue;
        case 'yellow':
          return Colors.yellow;
        case 'orange':
          return Colors.orange;
        case 'purple':
          return Colors.purple;
        case 'black':
          return Colors.black;
        case 'white':
          return Colors.white;
        case 'gray':
        case 'grey':
          return Colors.grey;
      }
    }
    
    return Colors.black;
  }
  
  /// Escape XML special characters
  static String _escapeXml(String text) {
    return text
        .replaceAll('&', '&amp;')
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;')
        .replaceAll('"', '&quot;')
        .replaceAll("'", '&apos;');
  }
}
