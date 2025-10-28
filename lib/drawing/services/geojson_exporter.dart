import 'dart:convert';
import 'package:latlong2/latlong.dart';

/// Minimal GeoJSON exporter for drawn elements represented as maps.
class GeoJsonExporter {
  static String export(List<Map<String, dynamic>> elements) {
    final features = <Map<String, dynamic>>[];
    for (final e in elements) {
      final type = e['type'];
      final layer = e['layerId'];
      if (type == 'tree' || type == 'point') {
        final LatLng p = e['point'] as LatLng;
        features.add(_feature('Point', [p.longitude, p.latitude], {
          'type': type,
          'layer': layer,
          'color': e['color']?.toString(),
          'width': e['width'],
        }));
      } else if (type == 'line' || type == 'arrow') {
        final pts = (e['points'] as List<LatLng>).map((p) => [p.longitude, p.latitude]).toList();
        features.add(_feature('LineString', pts, {
          'type': type,
          'layer': layer,
          'color': e['color']?.toString(),
          'width': e['width'],
        }));
      } else if (type == 'polyline') {
        final pts = (e['points'] as List<LatLng>).map((p) => [p.longitude, p.latitude]).toList();
        features.add(_feature('LineString', pts, {
          'type': type,
          'layer': layer,
          'color': e['color']?.toString(),
          'width': e['width'],
        }));
      } else if (type == 'rectangle' || type == 'polygon' || type == 'circle') {
        final pts = (e['points'] as List<LatLng>).map((p) => [p.longitude, p.latitude]).toList();
        // Close ring
        if (pts.isNotEmpty && (pts.first[0] != pts.last[0] || pts.first[1] != pts.last[1])) {
          pts.add(pts.first);
        }
        features.add(_feature('Polygon', [pts], {
          'type': type,
          'layer': layer,
          'color': e['color']?.toString(),
          'width': e['width'],
          'fill': e['fill']?.toString(),
        }));
      } else if (type == 'text') {
        final LatLng p = e['point'] as LatLng;
        features.add(_feature('Point', [p.longitude, p.latitude], {
          'type': 'text',
          'text': e['text'],
          'layer': layer,
        }));
      }
    }
    return jsonEncode({
      'type': 'FeatureCollection',
      'features': features,
    });
  }

  static Map<String, dynamic> _feature(String geomType, dynamic coords, Map<String, dynamic> props) {
    return {
      'type': 'Feature',
      'geometry': {'type': geomType, 'coordinates': coords},
      'properties': props,
    };
  }
}



