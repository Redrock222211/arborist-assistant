import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'dart:math' as math;

/// Mobile-specific gesture service for arboricultural CAD operations.
/// Provides touch-optimized controls, pinch-to-zoom, and mobile drawing tools.
class MobileGestureService {
  
  /// Handle pinch-to-zoom gesture for map
  static double handlePinchZoom({
    required double currentZoom,
    required double scale,
    required double minZoom,
    required double maxZoom,
  }) {
    final newZoom = currentZoom * scale;
    return newZoom.clamp(minZoom, maxZoom);
  }
  
  /// Handle two-finger pan gesture for map
  static LatLng handleTwoFingerPan({
    required LatLng currentCenter,
    required Offset panDelta,
    required double zoom,
    required Size mapSize,
  }) {
    // Convert screen pixels to geographic coordinates
    final latDelta = (panDelta.dy / mapSize.height) * (180.0 / math.pow(2, zoom - 1));
    final lonDelta = (panDelta.dx / mapSize.width) * (360.0 / math.pow(2, zoom - 1));
    
    return LatLng(
      currentCenter.latitude - latDelta,
      currentCenter.longitude + lonDelta,
    );
  }
  
  /// Handle double-tap to zoom
  static double handleDoubleTapZoom({
    required double currentZoom,
    required double zoomFactor,
    required double minZoom,
    required double maxZoom,
  }) {
    final newZoom = currentZoom * zoomFactor;
    return newZoom.clamp(minZoom, maxZoom);
  }
  
  /// Calculate optimal touch target size for mobile
  static double getOptimalTouchTargetSize() {
    // Material Design recommends minimum 48x48 logical pixels
    return 48.0;
  }
  
  /// Calculate optimal drawing tool size for mobile
  static double getOptimalDrawingToolSize() {
    // Larger touch targets for drawing tools
    return 56.0;
  }
  
  /// Handle long press for context menu
  static void handleLongPress({
    required BuildContext context,
    required LatLng position,
    required List<Map<String, dynamic>> nearbyElements,
    required Function(Map<String, dynamic>) onElementSelected,
    required Function(LatLng) onAddElement,
  }) {
    if (nearbyElements.isNotEmpty) {
      // Show element selection menu
      _showElementSelectionMenu(
        context: context,
        elements: nearbyElements,
        onElementSelected: onElementSelected,
        onAddElement: onAddElement,
        position: position,
      );
    } else {
      // Show add element menu
      _showAddElementMenu(
        context: context,
        position: position,
        onAddElement: onAddElement,
      );
    }
  }
  
  /// Handle swipe gesture for tool switching
  static String handleSwipeToolSwitch({
    required String currentTool,
    required List<String> availableTools,
    required SwipeDirection direction,
  }) {
    final currentIndex = availableTools.indexOf(currentTool);
    if (currentIndex == -1) return currentTool;
    
    int newIndex;
    switch (direction) {
      case SwipeDirection.left:
        newIndex = (currentIndex + 1) % availableTools.length;
        break;
      case SwipeDirection.right:
        newIndex = (currentIndex - 1 + availableTools.length) % availableTools.length;
        break;
      default:
        return currentTool;
    }
    
    return availableTools[newIndex];
  }
  
  /// Handle pinch-to-scale for drawing elements
  static Map<String, dynamic> handleElementScaling({
    required Map<String, dynamic> element,
    required double scale,
    required LatLng center,
  }) {
    final type = element['type'] as String?;
    if (type == null) return element;
    
    final scaledElement = Map<String, dynamic>.from(element);
    
    switch (type) {
      case 'circle':
        final radius = (element['radius'] as double?) ?? 0.0;
        scaledElement['radius'] = radius * scale;
        break;
        
      case 'rectangle':
        final width = (element['width'] as double?) ?? 0.0;
        final height = (element['height'] as double?) ?? 0.0;
        scaledElement['width'] = width * scale;
        scaledElement['height'] = height * scale;
        break;
        
      case 'polygon':
      case 'polyline':
        final points = element['points'] as List<LatLng>?;
        if (points != null) {
          final scaledPoints = points.map((point) {
            final dx = point.longitude - center.longitude;
            final dy = point.latitude - center.latitude;
            return LatLng(
              center.latitude + dy * scale,
              center.longitude + dx * scale,
            );
          }).toList();
          scaledElement['points'] = scaledPoints;
        }
        break;
    }
    
    return scaledElement;
  }
  
  /// Handle rotation gesture for drawing elements
  static Map<String, dynamic> handleElementRotation({
    required Map<String, dynamic> element,
    required double angle,
    required LatLng center,
  }) {
    final type = element['type'] as String?;
    if (type == null) return element;
    
    final rotatedElement = Map<String, dynamic>.from(element);
    
    switch (type) {
      case 'rectangle':
      case 'polygon':
      case 'polyline':
        final points = element['points'] as List<LatLng>?;
        if (points != null) {
          final rotatedPoints = points.map((point) {
            return _rotatePoint(point, center, angle);
          }).toList();
          rotatedElement['points'] = rotatedPoints;
        }
        break;
        
      case 'text':
        final currentRotation = (element['rotation'] as double?) ?? 0.0;
        rotatedElement['rotation'] = (currentRotation + angle) % (2 * math.pi);
        break;
    }
    
    return rotatedElement;
  }
  
  /// Handle multi-touch drawing for complex shapes
  static List<LatLng> handleMultiTouchDrawing({
    required List<Offset> touchPoints,
    required Size mapSize,
    required double zoom,
    required LatLng mapCenter,
  }) {
    // Convert touch points to geographic coordinates
    return touchPoints.map((touchPoint) {
      return _screenToLatLng(
        touchPoint,
        mapSize,
        zoom,
        mapCenter,
      );
    }).toList();
  }
  
  /// Handle touch-based measurement
  static Map<String, dynamic> handleTouchMeasurement({
    required List<LatLng> points,
    required String measurementType,
  }) {
    switch (measurementType) {
      case 'distance':
        if (points.length >= 2) {
          final distance = _calculateDistance(points[0], points[1]);
          return {
            'type': 'measurement',
            'measurementType': 'distance',
            'value': distance,
            'unit': 'meters',
            'points': points,
          };
        }
        break;
        
      case 'area':
        if (points.length >= 3) {
          final area = _calculatePolygonArea(points);
          return {
            'type': 'measurement',
            'measurementType': 'area',
            'value': area,
            'unit': 'square_meters',
            'points': points,
          };
        }
        break;
        
      case 'perimeter':
        if (points.length >= 3) {
          final perimeter = _calculatePolygonPerimeter(points);
          return {
            'type': 'measurement',
            'measurementType': 'perimeter',
            'value': perimeter,
            'unit': 'meters',
            'points': points,
          };
        }
        break;
    }
    
    return {};
  }
  
  /// Handle touch-based snapping
  static LatLng handleTouchSnapping({
    required LatLng touchPoint,
    required List<Map<String, dynamic>> elements,
    required double snapThreshold,
    required bool snapToGrid,
    required double gridSize,
  }) {
    LatLng snappedPoint = touchPoint;
    
    // Snap to existing elements
    for (final element in elements) {
      final snapPoint = _findSnapPoint(touchPoint, element, snapThreshold);
      if (snapPoint != null) {
        snappedPoint = snapPoint;
        break;
      }
    }
    
    // Snap to grid
    if (snapToGrid) {
      snappedPoint = _snapToGrid(snappedPoint, gridSize);
    }
    
    return snappedPoint;
  }
  
  /// Handle touch-based selection
  static Map<String, dynamic>? handleTouchSelection({
    required LatLng touchPoint,
    required List<Map<String, dynamic>> elements,
    required double selectionRadius,
  }) {
    for (final element in elements) {
      if (_isPointNearElement(touchPoint, element, selectionRadius)) {
        return element;
      }
    }
    return null;
  }
  
  /// Handle touch-based editing
  static Map<String, dynamic> handleTouchEditing({
    required Map<String, dynamic> element,
    required LatLng newPosition,
    required String editType,
  }) {
    final editedElement = Map<String, dynamic>.from(element);
    
    switch (editType) {
      case 'move':
        if (element['type'] == 'tree' || element['type'] == 'text') {
          editedElement['point'] = newPosition;
        } else if (element['points'] != null) {
          final points = element['points'] as List<LatLng>;
          final offset = LatLng(
            newPosition.latitude - points.first.latitude,
            newPosition.longitude - points.first.longitude,
          );
          
          final newPoints = points.map((point) {
            return LatLng(
              point.latitude + offset.latitude,
              point.longitude + offset.longitude,
            );
          }).toList();
          
          editedElement['points'] = newPoints;
        }
        break;
        
      case 'resize':
        // Handle resizing based on element type
        break;
        
      case 'rotate':
        // Handle rotation based on element type
        break;
    }
    
    return editedElement;
  }
  
  // Helper methods
  
  /// Show element selection menu
  static void _showElementSelectionMenu({
    required BuildContext context,
    required List<Map<String, dynamic>> elements,
    required Function(Map<String, dynamic>) onElementSelected,
    required Function(LatLng) onAddElement,
    required LatLng position,
  }) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Select Element',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 16),
            ...elements.map((element) => ListTile(
              leading: Icon(_getElementIcon(element['type'])),
              title: Text(_getElementTitle(element)),
              subtitle: Text(_getElementSubtitle(element)),
              onTap: () {
                Navigator.of(context).pop();
                onElementSelected(element);
              },
            )),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.add),
              title: const Text('Add New Element'),
              onTap: () {
                Navigator.of(context).pop();
                onAddElement(position);
              },
            ),
          ],
        ),
      ),
    );
  }
  
  /// Show add element menu
  static void _showAddElementMenu({
    required BuildContext context,
    required LatLng position,
    required Function(LatLng) onAddElement,
  }) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Add Element',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.park),
              title: const Text('Tree'),
              onTap: () {
                Navigator.of(context).pop();
                onAddElement(position);
              },
            ),
            ListTile(
              leading: const Icon(Icons.show_chart),
              title: const Text('Line'),
              onTap: () {
                Navigator.of(context).pop();
                onAddElement(position);
              },
            ),
            ListTile(
              leading: const Icon(Icons.crop_square),
              title: const Text('Rectangle'),
              onTap: () {
                Navigator.of(context).pop();
                onAddElement(position);
              },
            ),
            ListTile(
              leading: const Icon(Icons.circle_outlined),
              title: const Text('Circle'),
              onTap: () {
                Navigator.of(context).pop();
                onAddElement(position);
              },
            ),
          ],
        ),
      ),
    );
  }
  
  /// Get element icon
  static IconData _getElementIcon(String? type) {
    switch (type) {
      case 'tree':
        return Icons.park;
      case 'line':
      case 'polyline':
        return Icons.show_chart;
      case 'polygon':
      case 'rectangle':
        return Icons.crop_square;
      case 'circle':
        return Icons.circle_outlined;
      case 'text':
        return Icons.text_fields;
      default:
        return Icons.help_outline;
    }
  }
  
  /// Get element title
  static String _getElementTitle(Map<String, dynamic> element) {
    final type = element['type'] as String?;
    switch (type) {
      case 'tree':
        return 'Tree ${element['treeId'] ?? ''}';
      case 'line':
      case 'polyline':
        return 'Line';
      case 'polygon':
      case 'rectangle':
        return 'Polygon';
      case 'circle':
        return 'Circle';
      case 'text':
        return element['text'] ?? 'Text';
      default:
        return 'Element';
    }
  }
  
  /// Get element subtitle
  static String _getElementSubtitle(Map<String, dynamic> element) {
    final type = element['type'] as String?;
    switch (type) {
      case 'tree':
        return element['species'] ?? 'Unknown species';
      case 'text':
        return 'Text element';
      default:
        return 'Drawing element';
    }
  }
  
  /// Rotate point around center
  static LatLng _rotatePoint(LatLng point, LatLng center, double angle) {
    final cosA = math.cos(angle);
    final sinA = math.sin(angle);
    
    final dx = point.longitude - center.longitude;
    final dy = point.latitude - center.latitude;
    
    final rotatedX = dx * cosA - dy * sinA;
    final rotatedY = dx * sinA + dy * cosA;
    
    return LatLng(
      center.latitude + rotatedY,
      center.longitude + rotatedX,
    );
  }
  
  /// Convert screen coordinates to LatLng
  static LatLng _screenToLatLng(
    Offset screenPoint,
    Size mapSize,
    double zoom,
    LatLng mapCenter,
  ) {
    final normalizedX = (screenPoint.dx / mapSize.width) - 0.5;
    final normalizedY = (screenPoint.dy / mapSize.height) - 0.5;
    
    final latDelta = normalizedY * (180.0 / math.pow(2, zoom - 1));
    final lonDelta = normalizedX * (360.0 / math.pow(2, zoom - 1));
    
    return LatLng(
      mapCenter.latitude - latDelta,
      mapCenter.longitude + lonDelta,
    );
  }
  
  /// Calculate distance between two points
  static double _calculateDistance(LatLng p1, LatLng p2) {
    const earthRadius = 6371000.0; // meters
    
    final lat1Rad = p1.latitude * (math.pi / 180.0);
    final lat2Rad = p2.latitude * (math.pi / 180.0);
    final deltaLatRad = (p2.latitude - p1.latitude) * (math.pi / 180.0);
    final deltaLonRad = (p2.longitude - p1.longitude) * (math.pi / 180.0);
    
    final a = math.sin(deltaLatRad / 2) * math.sin(deltaLatRad / 2) +
              math.cos(lat1Rad) * math.cos(lat2Rad) *
              math.sin(deltaLonRad / 2) * math.sin(deltaLonRad / 2);
    
    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    
    return earthRadius * c;
  }
  
  /// Calculate polygon area
  static double _calculatePolygonArea(List<LatLng> points) {
    if (points.length < 3) return 0.0;
    
    double area = 0.0;
    for (int i = 0; i < points.length; i++) {
      final j = (i + 1) % points.length;
      area += points[i].longitude * points[j].latitude;
      area -= points[j].longitude * points[i].latitude;
    }
    
    area = area.abs() / 2.0;
    const degToM = 111320.0; // meters per degree at equator
    return area * degToM * degToM;
  }
  
  /// Calculate polygon perimeter
  static double _calculatePolygonPerimeter(List<LatLng> points) {
    if (points.length < 2) return 0.0;
    
    double perimeter = 0.0;
    for (int i = 0; i < points.length; i++) {
      final j = (i + 1) % points.length;
      perimeter += _calculateDistance(points[i], points[j]);
    }
    
    return perimeter;
  }
  
  /// Find snap point for element
  static LatLng? _findSnapPoint(
    LatLng touchPoint,
    Map<String, dynamic> element,
    double threshold,
  ) {
    final type = element['type'] as String?;
    
    switch (type) {
      case 'tree':
      case 'text':
        final point = element['point'] as LatLng?;
        if (point != null && _calculateDistance(touchPoint, point) <= threshold) {
          return point;
        }
        break;
        
      case 'line':
      case 'polyline':
        final points = element['points'] as List<LatLng>?;
        if (points != null) {
          for (final point in points) {
            if (_calculateDistance(touchPoint, point) <= threshold) {
              return point;
            }
          }
        }
        break;
    }
    
    return null;
  }
  
  /// Snap point to grid
  static LatLng _snapToGrid(LatLng point, double gridSize) {
    final lat = (point.latitude / gridSize).round() * gridSize;
    final lon = (point.longitude / gridSize).round() * gridSize;
    return LatLng(lat, lon);
  }
  
  /// Check if point is near element
  static bool _isPointNearElement(
    LatLng point,
    Map<String, dynamic> element,
    double radius,
  ) {
    final type = element['type'] as String?;
    
    switch (type) {
      case 'tree':
      case 'text':
        final elementPoint = element['point'] as LatLng?;
        if (elementPoint != null) {
          return _calculateDistance(point, elementPoint) <= radius;
        }
        break;
        
      case 'line':
      case 'polyline':
        final points = element['points'] as List<LatLng>?;
        if (points != null) {
          for (final elementPoint in points) {
            if (_calculateDistance(point, elementPoint) <= radius) {
              return true;
            }
          }
        }
        break;
    }
    
    return false;
  }
}

/// Swipe direction enum
enum SwipeDirection {
  left,
  right,
  up,
  down,
}

