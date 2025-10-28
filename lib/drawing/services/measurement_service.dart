import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:math' as math;

/// Professional measurement service for arboricultural CAD operations.
/// Provides precise calculations for distance, area, bearing, and geometric operations.
class MeasurementService {
  
  /// Calculate distance between two points in meters
  static double calculateDistance(LatLng point1, LatLng point2) {
    return const Distance().as(LengthUnit.Meter, point1, point2);
  }
  
  /// Calculate bearing from point1 to point2 in degrees (0-360°)
  static double calculateBearing(LatLng point1, LatLng point2) {
    final lat1Rad = point1.latitude * (math.pi / 180);
    final lat2Rad = point2.latitude * (math.pi / 180);
    final deltaLonRad = (point2.longitude - point1.longitude) * (math.pi / 180);
    
    final y = math.sin(deltaLonRad) * math.cos(lat2Rad);
    final x = math.cos(lat1Rad) * math.sin(lat2Rad) - 
              math.sin(lat1Rad) * math.cos(lat2Rad) * math.cos(deltaLonRad);
    
    final bearingRad = math.atan2(y, x);
    final bearingDeg = bearingRad * (180 / math.pi);
    
    // Normalize to 0-360°
    return (bearingDeg + 360) % 360;
  }
  
  /// Calculate area of a polygon using precise geodetic methods
  static double calculatePolygonArea(List<LatLng> points) {
    if (points.length < 3) return 0.0;
    
    // Use spherical excess formula for accurate area calculation
    double area = 0.0;
    const double earthRadiusM = 6371000.0; // Earth radius in meters
    
    // Close the polygon if not already closed
    final closedPoints = List<LatLng>.from(points);
    if (closedPoints.first.latitude != closedPoints.last.latitude ||
        closedPoints.first.longitude != closedPoints.last.longitude) {
      closedPoints.add(closedPoints.first);
    }
    
    // Calculate spherical excess
    double sphericalExcess = 0.0;
    for (int i = 0; i < closedPoints.length - 1; i++) {
      final p1 = closedPoints[i];
      final p2 = closedPoints[(i + 1) % (closedPoints.length - 1)];
      final p3 = closedPoints[(i + 2) % (closedPoints.length - 1)];
      
      final angle = _calculateSphericalAngle(p1, p2, p3);
      sphericalExcess += angle;
    }
    
    // Subtract (n-2)π where n is number of vertices
    sphericalExcess -= (closedPoints.length - 3) * math.pi;
    
    // Area = spherical excess × radius²
    area = sphericalExcess.abs() * earthRadiusM * earthRadiusM;
    
    return area;
  }
  
  /// Calculate perimeter of a polygon or polyline
  static double calculatePerimeter(List<LatLng> points) {
    if (points.length < 2) return 0.0;
    
    double perimeter = 0.0;
    for (int i = 0; i < points.length - 1; i++) {
      perimeter += calculateDistance(points[i], points[i + 1]);
    }
    
    return perimeter;
  }
  
  /// Calculate area and perimeter of a closed polygon
  static Map<String, double> calculatePolygonMetrics(List<LatLng> points) {
    return {
      'area': calculatePolygonArea(points),
      'perimeter': calculatePerimeter(points),
    };
  }
  
  /// Calculate centroid of a polygon
  static LatLng calculateCentroid(List<LatLng> points) {
    if (points.isEmpty) return LatLng(0, 0);
    
    double latSum = 0.0;
    double lonSum = 0.0;
    
    for (final point in points) {
      latSum += point.latitude;
      lonSum += point.longitude;
    }
    
    return LatLng(latSum / points.length, lonSum / points.length);
  }
  
  /// Calculate radius of a circle from three points
  static double calculateCircleRadius(LatLng p1, LatLng p2, LatLng p3) {
    // Convert to Cartesian coordinates for calculation
    final x1 = p1.longitude;
    final y1 = p1.latitude;
    final x2 = p2.longitude;
    final y2 = p2.latitude;
    final x3 = p3.longitude;
    final y3 = p3.latitude;
    
    // Calculate the circumradius using the formula
    final a = calculateDistance(p1, p2);
    final b = calculateDistance(p2, p3);
    final c = calculateDistance(p3, p1);
    
    // Area using Heron's formula
    final s = (a + b + c) / 2;
    final area = math.sqrt(s * (s - a) * (s - b) * (s - c));
    
    if (area == 0) return 0.0;
    
    // Circumradius = (a * b * c) / (4 * area)
    return (a * b * c) / (4 * area);
  }
  
  /// Find perpendicular distance from point to line
  static double pointToLineDistance(LatLng point, LatLng lineStart, LatLng lineEnd) {
    final A = calculateDistance(lineStart, lineEnd);
    final B = calculateDistance(lineStart, point);
    final C = calculateDistance(lineEnd, point);
    
    if (A == 0) return B; // Line has no length
    
    // Use Heron's formula to find the area of triangle
    final s = (A + B + C) / 2;
    final area = math.sqrt(s * (s - A) * (s - B) * (s - C));
    
    // Distance = 2 * area / base
    return (2 * area) / A;
  }
  
  /// Calculate the closest point on a line to a given point
  static LatLng closestPointOnLine(LatLng point, LatLng lineStart, LatLng lineEnd) {
    final dx = lineEnd.longitude - lineStart.longitude;
    final dy = lineEnd.latitude - lineStart.latitude;
    
    if (dx == 0 && dy == 0) return lineStart; // Line has no length
    
    final t = ((point.longitude - lineStart.longitude) * dx + 
               (point.latitude - lineStart.latitude) * dy) / (dx * dx + dy * dy);
    
    final clampedT = t.clamp(0.0, 1.0);
    
    return LatLng(
      lineStart.latitude + clampedT * dy,
      lineStart.longitude + clampedT * dx,
    );
  }
  
  /// Create measurement annotation with professional formatting
  static Map<String, dynamic> createMeasurementAnnotation({
    required String type,
    required double value,
    required LatLng position,
    String? units,
    String? label,
  }) {
    String formattedValue;
    String defaultUnits;
    
    switch (type) {
      case 'distance':
        defaultUnits = 'm';
        formattedValue = value.toStringAsFixed(2);
        break;
      case 'area':
        if (value >= 10000) {
          defaultUnits = 'ha';
          formattedValue = (value / 10000).toStringAsFixed(3);
        } else {
          defaultUnits = 'm²';
          formattedValue = value.toStringAsFixed(1);
        }
        break;
      case 'bearing':
        defaultUnits = '°';
        formattedValue = value.toStringAsFixed(1);
        break;
      case 'radius':
        defaultUnits = 'm';
        formattedValue = value.toStringAsFixed(2);
        break;
      default:
        defaultUnits = '';
        formattedValue = value.toStringAsFixed(2);
    }
    
    final displayUnits = units ?? defaultUnits;
    final displayLabel = label ?? type.toUpperCase();
    
    return {
      'type': 'measurement_annotation',
      'measurementType': type,
      'value': value,
      'formattedValue': formattedValue,
      'units': displayUnits,
      'label': displayLabel,
      'text': '$displayLabel: $formattedValue$displayUnits',
      'point': position,
      'color': _getMeasurementColor(type),
      'fontSize': 12.0,
      'fontWeight': 'bold',
      'backgroundColor': 'white',
      'borderColor': _getMeasurementColor(type),
      'created': DateTime.now().toIso8601String(),
    };
  }
  
  /// Generate comprehensive measurement report
  static Map<String, dynamic> generateMeasurementReport(List<Map<String, dynamic>> elements) {
    final report = <String, dynamic>{
      'totalElements': elements.length,
      'measurements': <String, dynamic>{},
      'summary': <String, String>{},
      'generated': DateTime.now().toIso8601String(),
    };
    
    double totalLength = 0.0;
    double totalArea = 0.0;
    double totalPerimeter = 0.0;
    int lineCount = 0;
    int polygonCount = 0;
    int treeCount = 0;
    
    for (final element in elements) {
      final type = element['type'] as String;
      
      switch (type) {
        case 'line':
        case 'polyline':
          if (element['points'] is List<LatLng>) {
            final points = element['points'] as List<LatLng>;
            final length = calculatePerimeter(points);
            totalLength += length;
            lineCount++;
          }
          break;
          
        case 'polygon':
        case 'rectangle':
        case 'circle':
          if (element['points'] is List<LatLng>) {
            final points = element['points'] as List<LatLng>;
            final metrics = calculatePolygonMetrics(points);
            totalArea += metrics['area']!;
            totalPerimeter += metrics['perimeter']!;
            polygonCount++;
          }
          break;
          
        case 'tree':
          treeCount++;
          break;
      }
    }
    
    report['measurements'] = {
      'totalLength': totalLength,
      'totalArea': totalArea,
      'totalPerimeter': totalPerimeter,
      'lineCount': lineCount,
      'polygonCount': polygonCount,
      'treeCount': treeCount,
    };
    
    report['summary'] = {
      'totalLength': '${totalLength.toStringAsFixed(2)} m',
      'totalArea': totalArea >= 10000 
          ? '${(totalArea / 10000).toStringAsFixed(3)} ha'
          : '${totalArea.toStringAsFixed(1)} m²',
      'totalPerimeter': '${totalPerimeter.toStringAsFixed(2)} m',
      'elementCount': '${elements.length} elements',
    };
    
    return report;
  }
  
  // Private helper methods
  
  /// Calculate spherical angle for area calculations
  static double _calculateSphericalAngle(LatLng p1, LatLng p2, LatLng p3) {
    final lat1 = p1.latitude * (math.pi / 180);
    final lon1 = p1.longitude * (math.pi / 180);
    final lat2 = p2.latitude * (math.pi / 180);
    final lon2 = p2.longitude * (math.pi / 180);
    final lat3 = p3.latitude * (math.pi / 180);
    final lon3 = p3.longitude * (math.pi / 180);
    
    // Calculate vectors
    final v1x = math.cos(lat1) * math.cos(lon1);
    final v1y = math.cos(lat1) * math.sin(lon1);
    final v1z = math.sin(lat1);
    
    final v2x = math.cos(lat2) * math.cos(lon2);
    final v2y = math.cos(lat2) * math.sin(lon2);
    final v2z = math.sin(lat2);
    
    final v3x = math.cos(lat3) * math.cos(lon3);
    final v3y = math.cos(lat3) * math.sin(lon3);
    final v3z = math.sin(lat3);
    
    // Calculate cross products
    final c1x = v1y * v2z - v1z * v2y;
    final c1y = v1z * v2x - v1x * v2z;
    final c1z = v1x * v2y - v1y * v2x;
    
    final c2x = v2y * v3z - v2z * v3y;
    final c2y = v2z * v3x - v2x * v3z;
    final c2z = v2x * v3y - v2y * v3x;
    
    // Calculate dot product and magnitudes
    final dot = c1x * c2x + c1y * c2y + c1z * c2z;
    final mag1 = math.sqrt(c1x * c1x + c1y * c1y + c1z * c1z);
    final mag2 = math.sqrt(c2x * c2x + c2y * c2y + c2z * c2z);
    
    if (mag1 == 0 || mag2 == 0) return 0.0;
    
    return math.acos((dot / (mag1 * mag2)).clamp(-1.0, 1.0));
  }
  
  /// Get color for measurement type
  static String _getMeasurementColor(String type) {
    switch (type) {
      case 'distance':
        return 'blue';
      case 'area':
        return 'green';
      case 'bearing':
        return 'orange';
      case 'radius':
        return 'purple';
      default:
        return 'black';
    }
  }
}

