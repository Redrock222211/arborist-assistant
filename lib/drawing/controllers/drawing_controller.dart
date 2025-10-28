import 'dart:math' as math;
import 'package:latlong2/latlong.dart';
import '../models/drawing_element.dart';

/// Lightweight controller to manage drawing state, preview, and measurements.
class DrawingController {
  final List<DrawingElement> _elements = [];
  final List<DrawingElement> _undo = [];

  List<DrawingElement> get elements => List.unmodifiable(_elements);

  void add(DrawingElement e) {
    _elements.add(e);
    _undo.clear();
  }

  void removeLast() {
    if (_elements.isNotEmpty) {
      _undo.add(_elements.removeLast());
    }
  }

  void undo() {
    if (_elements.isNotEmpty) {
      _undo.add(_elements.removeLast());
    }
  }

  void redo() {
    if (_undo.isNotEmpty) {
      _elements.add(_undo.removeLast());
    }
  }

  // Measurements
  double lineLengthMeters(LatLng a, LatLng b) {
    final d = const Distance();
    return d(a, b);
  }

  double polylineLengthMeters(List<LatLng> pts) {
    double sum = 0;
    for (int i = 1; i < pts.length; i++) {
      sum += lineLengthMeters(pts[i - 1], pts[i]);
    }
    return sum;
  }

  // Simple polygon area using planar approximation (sufficient for site scale)
  // Returns square meters.
  double polygonAreaSqM(List<LatLng> pts) {
    if (pts.length < 3) return 0;
    // Convert to meters using local equirectangular approximation
    final lat0 = pts.first.latitude * (math.pi / 180.0);
    const earthRadius = 6371000.0; // meters
    List<({double x, double y})> xy = pts.map((p) {
      final lat = p.latitude * (math.pi / 180.0);
      final lon = p.longitude * (math.pi / 180.0);
      final x = earthRadius * lon * math.cos(lat0);
      final y = earthRadius * lat;
      return (x: x, y: y);
    }).toList();
    double area = 0;
    for (int i = 0; i < xy.length; i++) {
      final j = (i + 1) % xy.length;
      area += xy[i].x * xy[j].y - xy[j].x * xy[i].y;
    }
    return (area.abs() * 0.5);
  }
}

