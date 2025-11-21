import 'dart:convert';
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter/rendering.dart';
import 'package:intl/intl.dart';
import 'package:latlong2/latlong.dart';
import 'package:share_plus/share_plus.dart';
import 'package:uuid/uuid.dart';

import '../models/site.dart';
import '../models/tree_entry.dart';
import '../services/tree_storage_service.dart';
import '../services/branding_service.dart';
import '../services/drawing_storage_service.dart';
import '../services/site_file_service.dart';
import '../services/notification_service.dart';
import '../utils/platform_download.dart';

enum DrawingTool {
  select,
  house,
  fence,
  driveway,
  path,
  customPolygon,
  patio,
  deck,
  pool,
  shed,
  freeformLine,
  hole,
}

enum ToolMode {
  freeform,
  measuredCm,
  measuredM,
}

enum BaseMapStyle {
  street,
  topo,
  satellite,
}

class DrawingOverlay {
  DrawingOverlay({
    required this.fileId,
    required this.originalName,
    required this.fileType,
    required this.center,
    required this.scale,
    required this.opacity,
    required this.isImage,
    this.imageBytes,
  });

  final String fileId;
  final String originalName;
  final String fileType;
  LatLng center;
  double scale;
  double opacity;
  final bool isImage;
  final Uint8List? imageBytes;

  Map<String, dynamic> toJson() => {
        'fileId': fileId,
        'originalName': originalName,
        'fileType': fileType,
        'center': {
          'lat': center.latitude,
          'lng': center.longitude,
        },
        'scale': scale,
        'opacity': opacity,
        'isImage': isImage,
        'imageData': isImage && imageBytes != null ? base64Encode(imageBytes!) : null,
      };

  factory DrawingOverlay.fromJson(Map<String, dynamic> json) {
    final imageData = json['imageData'] as String?;
    return DrawingOverlay(
      fileId: json['fileId'] as String,
      originalName: json['originalName'] as String? ?? 'overlay',
      fileType: json['fileType'] as String? ?? 'Unknown',
      center: LatLng(
        (json['center']['lat'] as num).toDouble(),
        (json['center']['lng'] as num).toDouble(),
      ),
      scale: (json['scale'] as num?)?.toDouble() ?? 1.0,
      opacity: (json['opacity'] as num?)?.toDouble() ?? 0.7,
      isImage: json['isImage'] as bool? ?? false,
      imageBytes: imageData != null ? base64Decode(imageData) : null,
    );
  }
}

class StructureFeature {
  StructureFeature({
    required this.id,
    required this.type,
    required this.vertices,
    this.holes = const [],
  });

  final String id;
  final DrawingTool type;
  final List<LatLng> vertices;
  final List<List<LatLng>> holes;

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type.name,
        'vertices': vertices
            .map((latLng) => {
                  'lat': latLng.latitude,
                  'lng': latLng.longitude,
                })
            .toList(),
        'holes': holes
            .map((hole) => hole
                .map((latLng) => {
                      'lat': latLng.latitude,
                      'lng': latLng.longitude,
                    })
                .toList())
            .toList(),
      };

  factory StructureFeature.fromJson(Map<String, dynamic> json) {
    final typeName = json['type'] as String? ?? DrawingTool.customPolygon.name;
    final tool = DrawingTool.values.firstWhere(
      (value) => value.name == typeName,
      orElse: () => DrawingTool.customPolygon,
    );

    final verticesData = (json['vertices'] as List<dynamic>? ?? [])
        .whereType<Map>()
        .map((point) {
      final lat = (point['lat'] as num?)?.toDouble();
      final lng = (point['lng'] as num?)?.toDouble();
      if (lat == null || lng == null) {
        return null;
      }
      return LatLng(lat, lng);
    }).whereType<LatLng>().toList();

    final holesData = (json['holes'] as List<dynamic>? ?? [])
        .whereType<List>()
        .map((hole) => hole
            .whereType<Map>()
            .map((point) {
              final lat = (point['lat'] as num?)?.toDouble();
              final lng = (point['lng'] as num?)?.toDouble();
              if (lat == null || lng == null) {
                return null;
              }
              return LatLng(lat, lng);
            })
            .whereType<LatLng>()
            .toList())
        .where((hole) => hole.isNotEmpty)
        .toList();

    return StructureFeature(
      id: json['id'] as String? ?? const Uuid().v4(),
      type: tool,
      vertices: verticesData,
      holes: holesData,
    );
  }

  Color get color {
    switch (type) {
      case DrawingTool.house:
        return Colors.orangeAccent;
      case DrawingTool.fence:
        return Colors.brown;
      case DrawingTool.driveway:
        return Colors.blueGrey;
      case DrawingTool.path:
        return Colors.lightBlue;
      case DrawingTool.customPolygon:
        return Colors.teal;
      case DrawingTool.patio:
        return Colors.amber;
      case DrawingTool.deck:
        return Colors.deepOrange;
      case DrawingTool.pool:
        return Colors.cyan;
      case DrawingTool.shed:
        return Colors.grey;
      case DrawingTool.freeformLine:
        return Colors.purple;
      case DrawingTool.hole:
        return Colors.redAccent;
      case DrawingTool.select:
        return Colors.deepPurple;
    }
  }

  String get label {
    switch (type) {
      case DrawingTool.house:
        return 'House';
      case DrawingTool.fence:
        return 'Fence';
      case DrawingTool.driveway:
        return 'Driveway';
      case DrawingTool.path:
        return 'Path';
      case DrawingTool.customPolygon:
        return 'Custom';
      case DrawingTool.patio:
        return 'Patio';
      case DrawingTool.deck:
        return 'Deck';
      case DrawingTool.pool:
        return 'Pool';
      case DrawingTool.shed:
        return 'Shed';
      case DrawingTool.freeformLine:
        return 'Freeform';
      case DrawingTool.hole:
        return 'Hole';
      case DrawingTool.select:
        return 'Selection';
    }
  }

  bool get isPolyline => type == DrawingTool.freeformLine;
}

class EncroachmentInfo {
  EncroachmentInfo({
    required this.treeId,
    required this.treeLabel,
    required this.structureId,
    required this.structureLabel,
    required this.tpzPercent,
    required this.impactSquareMeters,
  });

  final String treeId;
  final String treeLabel;
  final String structureId;
  final String structureLabel;
  final double tpzPercent;
  final double impactSquareMeters;
}

class DrawingPage extends StatefulWidget {
  const DrawingPage({super.key, required this.site});

  final Site site;

  @override
  State<DrawingPage> createState() => _DrawingPageState();
}

class _DrawingPageState extends State<DrawingPage> {
  final MapController _mapController = MapController();
  final Uuid _uuid = const Uuid();
  final GlobalKey _mapRepaintKey = GlobalKey(debugLabel: 'drawingMap');

  late LatLng _mapCenter;
  double _mapZoom = 18;

  BaseMapStyle _baseMapStyle = BaseMapStyle.street;

  bool _showTPZ = true;
  bool _showSRZ = false;
  bool _showTreeNumbers = false;

  DrawingTool _activeTool = DrawingTool.select;
  ToolMode _toolMode = ToolMode.freeform;
  
  // Measurement guide state
  CircleMarker? _measurementGuide;
  Polyline? _measurementProjection;  // Line showing measurement direction
  double _lastMeasuredDistance = 0;
  bool _isWaitingForMeasurement = false;

  final List<TreeEntry> _treeEntries = [];
  final List<StructureFeature> _structures = [];
  final List<LatLng> _draftVertices = [];

  final List<EncroachmentInfo> _encroachments = [];
  DrawingOverlay? _overlay;

  static const double _overlayBaseSizeMeters = 60;

  final List<List<StructureFeature>> _undoStack = [];
  final List<List<StructureFeature>> _redoStack = [];

  bool get _canUndo => _undoStack.isNotEmpty;
  bool get _canRedo => _redoStack.isNotEmpty;

  @override
  void initState() {
    super.initState();
    _mapCenter = LatLng(
      widget.site.latitude ?? -37.8136,
      widget.site.longitude ?? 144.9631,
    );
    _loadTrees();
    Future.microtask(_loadPersistedDrawing);
  }

  void _loadTrees() {
    final trees = TreeStorageService.getTreesForSite(widget.site.id);
    _treeEntries
      ..clear()
      ..addAll(trees);

    if (_treeEntries.isNotEmpty) {
      _mapCenter = LatLng(_treeEntries.first.latitude, _treeEntries.first.longitude);
    }

    setState(() {});
    _recalculateEncroachments();
    _undoStack.clear();
    _redoStack.clear();
  }

  Future<void> _loadPersistedDrawing() async {
    try {
      final stored = await DrawingStorageService.loadDrawing(widget.site.id);
      if (stored == null) {
        return;
      }

      final actionList = (stored['actions'] as List<dynamic>? ?? [])
          .whereType<Map>()
          .map((entry) => StructureFeature.fromJson(Map<String, dynamic>.from(entry)))
          .toList();

      final overlay = stored['overlay'] as Map<String, dynamic>?;

      setState(() {
        _structures
          ..clear()
          ..addAll(actionList);
        if (overlay != null) {
          _showTPZ = overlay['showTPZ'] as bool? ?? _showTPZ;
          _showSRZ = overlay['showSRZ'] as bool? ?? _showSRZ;
          final overlayData = overlay['data'] as Map<String, dynamic>?;
          if (overlayData != null) {
            try {
              _overlay = DrawingOverlay.fromJson(overlayData);
            } catch (e) {
              debugPrint('Failed to parse overlay: $e');
              _overlay = null;
            }
          }
        }
      });

      _recalculateEncroachments();
    } catch (error) {
      debugPrint('Failed to load drawing data: $error');
    }
  }

  void _onMapTap(TapPosition tapPosition, LatLng latLng) {
    if (_activeTool == DrawingTool.select) {
      return;
    }

    if (_activeTool == DrawingTool.hole) {
      _handleHoleTap(latLng);
      return;
    }
    
    // Handle house tool - create rectangle from two corners
    if (_activeTool == DrawingTool.house) {
      _handleHouseTap(latLng);
      return;
    }

    // Handle measured mode
    if (_toolMode != ToolMode.freeform) {
      _handleMeasuredModeTap(latLng);
      return;
    }

    // Freeform mode - add points normally
    setState(() {
      _draftVertices.add(latLng);
    });
  }
  
  void _handleHouseTap(LatLng latLng) {
    if (_draftVertices.isEmpty) {
      // First corner
      setState(() {
        _draftVertices.add(latLng);
      });
    } else if (_draftVertices.length == 1) {
      // Second corner - create rectangle
      final corner1 = _draftVertices[0];
      final corner2 = latLng;
      
      // Create rectangle from two corners
      setState(() {
        _draftVertices.clear();
        _draftVertices.add(corner1);
        _draftVertices.add(LatLng(corner1.latitude, corner2.longitude));
        _draftVertices.add(corner2);
        _draftVertices.add(LatLng(corner2.latitude, corner1.longitude));
      });
      
      // Auto-finalize the house
      _finalizeDraft();
    }
  }

  Future<void> _handleMeasuredModeTap(LatLng latLng) async {
    if (_draftVertices.isEmpty) {
      // First point - add it and ask for distance
      setState(() {
        _draftVertices.add(latLng);
      });
      await _showDistanceInputDialog();
    } else {
      // Check if the tap is at the correct distance from the last point
      final lastPoint = _draftVertices.last;
      final distance = _calculateDistance(lastPoint, latLng);
      final expectedDistance = _lastMeasuredDistance;
      final tolerance = expectedDistance * 0.1; // 10% tolerance
      
      if ((distance - expectedDistance).abs() <= tolerance) {
        // Distance is acceptable - add the point
        setState(() {
          _draftVertices.add(latLng);
          _measurementGuide = null;
        });
        await _showDistanceInputDialog();
      } else {
        // Show feedback - tap is too far/close
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Tap ${expectedDistance.toStringAsFixed(1)}${_toolMode == ToolMode.measuredCm ? 'cm' : 'm'} from the last point (current: ${distance.toStringAsFixed(1)})'),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  Future<void> _showDistanceInputDialog() async {
    if (_draftVertices.isEmpty) return;
    
    final controller = TextEditingController();
    final unit = _toolMode == ToolMode.measuredCm ? 'cm' : 'm';
    
    final distance = await showDialog<double>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Enter Distance ($unit)'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            labelText: 'Distance in $unit',
            suffixText: unit,
            border: const OutlineInputBorder(),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              final value = double.tryParse(controller.text);
              if (value != null && value > 0) {
                Navigator.of(context).pop(value);
              }
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );

    if (distance != null) {
      final distanceInMeters = _toolMode == ToolMode.measuredCm ? distance / 100 : distance;
      setState(() {
        _lastMeasuredDistance = distanceInMeters;
        _updateMeasurementGuide();
      });
    }
  }

  void _updateMeasurementGuide() {
    if (_draftVertices.isEmpty || _lastMeasuredDistance <= 0) {
      _measurementGuide = null;
      _measurementProjection = null;
      return;
    }
    
    final lastPoint = _draftVertices.last;
    _measurementGuide = CircleMarker(
      point: lastPoint,
      radius: _lastMeasuredDistance,
      color: Colors.blue.withOpacity(0.1),
      borderColor: Colors.blue,
      borderStrokeWidth: 2,
      useRadiusInMeter: true,
    );
  }
  
  void _updateMeasurementProjection(LatLng currentPosition) {
    if (_draftVertices.isEmpty || _toolMode == ToolMode.freeform) {
      setState(() {
        _measurementProjection = null;
      });
      return;
    }
    
    final lastPoint = _draftVertices.last;
    final distance = _calculateDistance(lastPoint, currentPosition);
    final unit = _toolMode == ToolMode.measuredCm ? 'cm' : 'm';
    final displayDistance = _toolMode == ToolMode.measuredCm ? distance * 100 : distance;
    
    setState(() {
      _measurementProjection = Polyline(
        points: [lastPoint, currentPosition],
        color: Colors.blue,
        strokeWidth: 2,
      );
    });
  }

  double _calculateDistance(LatLng point1, LatLng point2) {
    const Distance distance = Distance();
    return distance.as(LengthUnit.Meter, point1, point2);
  }

  StructureFeature? _selectedPolygonForHole;

  void _handleHoleTap(LatLng latLng) {
    // Find if user tapped on an existing polygon
    final tappedPolygon = _structures.firstWhere(
      (structure) => !structure.isPolyline && _isPointInPolygon(latLng, structure.vertices),
      orElse: () => _structures.first, // fallback
    );

    if (!tappedPolygon.isPolyline && _isPointInPolygon(latLng, tappedPolygon.vertices)) {
      setState(() {
        _selectedPolygonForHole = tappedPolygon;
        _draftVertices.add(latLng);
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please tap inside a polygon to add a hole.')),
      );
    }
  }

  bool _isPointInPolygon(LatLng point, List<LatLng> polygon) {
    if (polygon.length < 3) return false;
    
    bool inside = false;
    int j = polygon.length - 1;
    
    for (int i = 0; i < polygon.length; i++) {
      final pi = polygon[i];
      final pj = polygon[j];
      
      if (((pi.latitude > point.latitude) != (pj.latitude > point.latitude)) &&
          (point.longitude < (pj.longitude - pi.longitude) * (point.latitude - pi.latitude) / (pj.latitude - pi.latitude) + pi.longitude)) {
        inside = !inside;
      }
      j = i;
    }
    
    return inside;
  }
  Future<void> _finalizeDraft() async {
    if (_activeTool == DrawingTool.hole) {
      await _finalizeHole();
      return;
    }

    final minPoints = _activeTool == DrawingTool.freeformLine ? 2 : 3;
    if (_draftVertices.length < minPoints) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Add at least $minPoints points to create this feature.')),
      );
      return;
    }

    final structure = StructureFeature(
      id: _uuid.v4(),
      type: _activeTool == DrawingTool.select ? DrawingTool.customPolygon : _activeTool,
      vertices: List<LatLng>.from(_draftVertices),
    );

    setState(() {
      _pushUndoState();
      _structures.add(structure);
      _draftVertices.clear();
      _activeTool = DrawingTool.select;
      _redoStack.clear();
    });

    _recalculateEncroachments();
    await _saveDrawing(showMessage: false);
  }

  Future<void> _finalizeHole() async {
    if (_selectedPolygonForHole == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a polygon first.')),
      );
      return;
    }

    if (_draftVertices.length < 3) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Add at least 3 points to create a hole.')),
      );
      return;
    }

    setState(() {
      _pushUndoState();
      
      // Find and update the selected polygon with the new hole
      final index = _structures.indexWhere((s) => s.id == _selectedPolygonForHole!.id);
      if (index != -1) {
        final updatedStructure = StructureFeature(
          id: _selectedPolygonForHole!.id,
          type: _selectedPolygonForHole!.type,
          vertices: List<LatLng>.from(_selectedPolygonForHole!.vertices),
          holes: [..._selectedPolygonForHole!.holes, List<LatLng>.from(_draftVertices)],
        );
        _structures[index] = updatedStructure;
      }
      
      _draftVertices.clear();
      _selectedPolygonForHole = null;
      _activeTool = DrawingTool.select;
      _redoStack.clear();
    });

    _recalculateEncroachments();
    await _saveDrawing(showMessage: false);
  }

  void _cancelDraft() {
    setState(() {
      _draftVertices.clear();
      _selectedPolygonForHole = null;
    });
  }

  void _removeStructure(String id) {
    setState(() {
      _pushUndoState();
      _structures.removeWhere((s) => s.id == id);
      _redoStack.clear();
    });
    _recalculateEncroachments();
    _saveDrawing(showMessage: false);
  }

  void _recalculateEncroachments() {
    _encroachments
      ..clear()
      ..addAll(
        EncroachmentCalculator.calculate(
          trees: _treeEntries,
          structures: _structures,
          includeTPZ: _showTPZ,
          includeSRZ: _showSRZ,
        ),
      );
    setState(() {});
  }

  void _pushUndoState() {
    _undoStack.add(_structures.map((e) => StructureFeature(
      id: e.id, 
      type: e.type, 
      vertices: List<LatLng>.from(e.vertices),
      holes: e.holes.map((hole) => List<LatLng>.from(hole)).toList(),
    )).toList());
    if (_undoStack.length > 50) {
      _undoStack.removeAt(0);
    }
  }

  void _undo() {
    if (!_canUndo) return;
    final previous = _undoStack.removeLast();
    _redoStack.add(_structures.map((e) => StructureFeature(
      id: e.id, 
      type: e.type, 
      vertices: List<LatLng>.from(e.vertices),
      holes: e.holes.map((hole) => List<LatLng>.from(hole)).toList(),
    )).toList());
    setState(() {
      _structures
        ..clear()
        ..addAll(previous);
    });
    _recalculateEncroachments();
    _saveDrawing(showMessage: false);
  }

  void _redo() {
    if (!_canRedo) return;
    final next = _redoStack.removeLast();
    _undoStack.add(_structures.map((e) => StructureFeature(
      id: e.id, 
      type: e.type, 
      vertices: List<LatLng>.from(e.vertices),
      holes: e.holes.map((hole) => List<LatLng>.from(hole)).toList(),
    )).toList());
    setState(() {
      _structures
        ..clear()
        ..addAll(next);
    });
    _recalculateEncroachments();
    _saveDrawing(showMessage: false);
  }

  List<Marker> _buildTreeMarkers() {
    return _treeEntries
        .map(
          (tree) => Marker(
            point: LatLng(tree.latitude, tree.longitude),
            width: _showTreeNumbers ? 60 : 24,
            height: _showTreeNumbers ? 30 : 24,
            child: Tooltip(
              message: 'Tree #${tree.id}\n${tree.species}',
              child: _showTreeNumbers
                  ? Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.green,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                      child: Text(
                        tree.id,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    )
                  : Container(
                      decoration: BoxDecoration(
                        color: Colors.green,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                    ),
            ),
          ),
        )
        .toList();
  }

  List<CircleMarker> _buildTreeCircles() {
    final circles = <CircleMarker>[];
    for (final tree in _treeEntries) {
      if (_showTPZ && tree.nrz > 0) {
        circles.add(
          CircleMarker(
            point: LatLng(tree.latitude, tree.longitude),
            radius: tree.nrz,
            color: Colors.orange.withOpacity(0.15),
            borderColor: Colors.orange,
            borderStrokeWidth: 2,
            useRadiusInMeter: true,
          ),
        );
      }
      if (_showSRZ && tree.srz > 0) {
        circles.add(
          CircleMarker(
            point: LatLng(tree.latitude, tree.longitude),
            radius: tree.srz,
            color: Colors.red.withOpacity(0.15),
            borderColor: Colors.red,
            borderStrokeWidth: 2,
            useRadiusInMeter: true,
          ),
        );
      }
    }
    
    // Add measurement guide if in measured mode
    if (_measurementGuide != null) {
      circles.add(_measurementGuide!);
    }
    
    return circles;
  }

  List<Polygon<Object>> _buildStructurePolygons() {
    return _structures
        .where((structure) => !structure.isPolyline && structure.vertices.length >= 3)
        .map(
          (structure) => Polygon<Object>(
            points: structure.vertices,
            color: structure.color.withOpacity(0.2),
            borderStrokeWidth: 2,
            borderColor: structure.color,
          ),
        )
        .cast<Polygon<Object>>()
        .toList();
  }

  List<Polygon> _buildOverlayPolygon() {
    if (_overlay == null || _overlay!.isImage) {
      return const [];
    }

    final bounds = _overlayBounds(_overlay!);
    final points = _boundsToPolygon(bounds);
    return [
      Polygon(
        points: points,
        color: Colors.blueAccent.withOpacity(_overlay!.opacity * 0.4),
        borderStrokeWidth: 2,
        borderColor: Colors.blueAccent,
      ),
    ];
  }

  Polygon? _buildDraftPolygon() {
    if (_draftVertices.length < 2) {
      return null;
    }

    return Polygon(
      points: List<LatLng>.from(_draftVertices),
      color: Colors.deepPurple.withOpacity(0.1),
      borderStrokeWidth: 2,
      borderColor: Colors.deepPurple,
    );
  }

  List<Polyline> _buildStructurePolylines() {
    return _structures
        .where((structure) => structure.isPolyline && structure.vertices.length >= 2)
        .map(
          (structure) => Polyline(
            points: structure.vertices,
            strokeWidth: 4,
            color: structure.color,
          ),
        )
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final layout = MediaQuery.of(context);
    final showSidePanels = layout.size.width > 900;

    return Scaffold(
      appBar: AppBar(
        title: Text('Drawing - ${widget.site.name}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.undo),
            tooltip: 'Undo',
            onPressed: _canUndo ? _undo : null,
          ),
          IconButton(
            icon: const Icon(Icons.redo),
            tooltip: 'Redo',
            onPressed: _canRedo ? _redo : null,
          ),
          TextButton.icon(
            onPressed: () {
              _saveDrawing();
            },
            icon: const Icon(Icons.save, color: Colors.white),
            label: const Text('Save', style: TextStyle(color: Colors.white)),
          ),
          IconButton(
            icon: const Icon(Icons.picture_as_pdf),
            tooltip: 'Export Map',
            onPressed: _exportAnnotatedMap,
          ),
        ],
      ),
      body: Row(
        children: [
          SizedBox(
            width: showSidePanels ? 260 : 220,
            child: _buildToolPanel(),
          ),
          Expanded(
            child: Stack(
              children: [
                Positioned.fill(
                  child: RepaintBoundary(
                    key: _mapRepaintKey,
                    child: SizedBox.expand(
                      child: FlutterMap(
                        mapController: _mapController,
                        options: MapOptions(
                          initialCenter: _mapCenter,
                          initialZoom: _mapZoom,
                          onPointerHover: (event, latLng) {
                            if (_toolMode != ToolMode.freeform && _draftVertices.isNotEmpty) {
                              _updateMeasurementProjection(latLng);
                            }
                          },
                          onTap: _onMapTap,
                          onMapEvent: (event) {
                            final center = event.camera.center;
                            final zoom = event.camera.zoom;
                            setState(() {
                              _mapCenter = center;
                              _mapZoom = zoom;
                            });
                          },
                        ),
                        children: [
                          _buildBaseMapLayer(),
                          if (_overlay != null && _overlay!.isImage && _overlay!.imageBytes != null)
                            OverlayImageLayer(
                              overlayImages: [
                                OverlayImage(
                                  bounds: _overlayBounds(_overlay!),
                                  opacity: _overlay!.opacity.clamp(0.0, 1.0),
                                  imageProvider: MemoryImage(_overlay!.imageBytes!),
                                ),
                              ],
                            ),
                          if (_showTPZ || _showSRZ)
                            CircleLayer(
                              circles: _buildTreeCircles(),
                            ),
                          if (_overlay != null && !_overlay!.isImage)
                            PolygonLayer(polygons: _buildOverlayPolygon()),
                          MarkerLayer(markers: _buildTreeMarkers()),
                          PolygonLayer(polygons: _buildStructurePolygons()),
                          if (_buildStructurePolylines().isNotEmpty)
                            PolylineLayer(polylines: _buildStructurePolylines()),
                          if (_measurementProjection != null)
                            PolylineLayer(polylines: [_measurementProjection!]),
                          if (_buildDraftPolygon() != null)
                            PolygonLayer(polygons: [_buildDraftPolygon()!]),
                        ],
                      ),
                    ),
                  ),
                ),
                if (_draftVertices.isNotEmpty)
                  Positioned(
                    left: 16,
                    bottom: 16,
                    child: Card(
                      color: Colors.deepPurple,
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Row(
                          children: [
                            const Icon(Icons.edit, color: Colors.white),
                            const SizedBox(width: 8),
                            const Text(
                              'Tap map to add points. Finish when ready.',
                              style: TextStyle(color: Colors.white),
                            ),
                            const SizedBox(width: 12),
                            TextButton(
                              onPressed: _finalizeDraft,
                              child: const Text('Finish', style: TextStyle(color: Colors.white)),
                            ),
                            const SizedBox(width: 8),
                            TextButton(
                              onPressed: _cancelDraft,
                              child: const Text('Cancel', style: TextStyle(color: Colors.white70)),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          if (showSidePanels)
            SizedBox(
              width: 280,
              child: _buildInsightsPanel(),
            ),
        ],
      ),
      bottomNavigationBar: showSidePanels ? null : SizedBox(height: 200, child: _buildInsightsPanel()),
    );
  }

  Widget _buildToolPanel() {
    return Material(
      color: Colors.grey.shade50,
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Tools', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _toolChip('Select', DrawingTool.select, Icons.pan_tool_alt),
                  _toolChip('House', DrawingTool.house, Icons.house),
                  _toolChip('Fence', DrawingTool.fence, Icons.fence),
                  _toolChip('Driveway', DrawingTool.driveway, Icons.directions_car),
                  _toolChip('Path', DrawingTool.path, Icons.route),
                  _toolChip('Custom', DrawingTool.customPolygon, Icons.polyline),
                  _toolChip('Patio', DrawingTool.patio, Icons.deck),
                  _toolChip('Deck', DrawingTool.deck, Icons.grass),
                  _toolChip('Pool', DrawingTool.pool, Icons.pool),
                  _toolChip('Shed', DrawingTool.shed, Icons.home_work),
                  _toolChip('Freeform', DrawingTool.freeformLine, Icons.timeline),
                  _toolChip('Hole', DrawingTool.hole, Icons.radio_button_unchecked),
                ],
              ),
              const SizedBox(height: 24),
              const Text('Layers', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 12),
              SwitchListTile(
                title: const Text('Show TPZ'),
                value: _showTPZ,
                onChanged: (value) {
                  setState(() {
                    _showTPZ = value;
                  });
                  _recalculateEncroachments();
                  _saveDrawing(showMessage: false);
                },
              ),
              SwitchListTile(
                title: const Text('Show SRZ'),
                value: _showSRZ,
                onChanged: (value) {
                  setState(() {
                    _showSRZ = value;
                  });
                  _recalculateEncroachments();
                  _saveDrawing(showMessage: false);
                },
              ),
              SwitchListTile(
                title: const Text('Show Tree Numbers'),
                value: _showTreeNumbers,
                onChanged: (value) {
                  setState(() {
                    _showTreeNumbers = value;
                  });
                  _saveDrawing(showMessage: false);
                },
              ),
              const SizedBox(height: 24),
              const Text('Base Map', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 12),
              DropdownButtonFormField<BaseMapStyle>(
                value: _baseMapStyle,
                decoration: const InputDecoration(
                  labelText: 'Base map style',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.map),
                ),
                items: BaseMapStyle.values
                    .map(
                      (style) => DropdownMenuItem(
                        value: style,
                        child: Text(_baseMapLabel(style)),
                      ),
                    )
                    .toList(),
                onChanged: (style) {
                  if (style == null) return;
                  setState(() {
                    _baseMapStyle = style;
                  });
                },
              ),
              const SizedBox(height: 12),
              Card(
                margin: EdgeInsets.zero,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Base Map Summary',
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 8),
                      Text('Style: ${_baseMapLabel(_baseMapStyle)}'),
                      Text('Center: ${_mapCenter.latitude.toStringAsFixed(4)}, ${_mapCenter.longitude.toStringAsFixed(4)}'),
                      Text('Zoom: ${_mapZoom.toStringAsFixed(1)}'),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              const Text('Tree Settings:', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              if (_treeEntries.isEmpty)
                const Text('No trees available for this site.'),
              for (final tree in _treeEntries)
                Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Tree #${tree.id}', style: const TextStyle(fontWeight: FontWeight.w600)),
                        if (tree.species.isNotEmpty)
                          Text(tree.species, style: const TextStyle(color: Colors.grey)),
                        const SizedBox(height: 8),
                        Text('TPZ: ${tree.nrz.toStringAsFixed(1)} m'),
                        Text('SRZ: ${tree.srz.toStringAsFixed(1)} m'),
                      ],
                    ),
                  ),
                ),
              if (_structures.isNotEmpty) ...[
                const SizedBox(height: 24),
                const Text('Layers:', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                for (final structure in _structures)
                  ListTile(
                    dense: true,
                    title: Text(structure.label),
                    subtitle: Text('${structure.vertices.length} points'),
                    leading: CircleAvatar(backgroundColor: structure.color),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete),
                      onPressed: () => _removeStructure(structure.id),
                    ),
                  ),
              ],
              const SizedBox(height: 24),
              const Text('Overlay', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 12),
              if (_overlay == null)
                ElevatedButton.icon(
                  onPressed: _uploadOverlay,
                  icon: const Icon(Icons.upload_file),
                  label: const Text('Upload overlay (PNG/JPG/DWG)'),
                )
              else ...[
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(_overlay!.originalName, style: const TextStyle(fontWeight: FontWeight.w600)),
                        const SizedBox(height: 8),
                        Text('Type: ${_overlay!.fileType}'),
                        const SizedBox(height: 12),
                        Text('Opacity ${( _overlay!.opacity * 100).round()}%'),
                        Slider(
                          value: _overlay!.opacity,
                          min: 0.2,
                          max: 1.0,
                          divisions: 8,
                          onChanged: (value) {
                            setState(() {
                              _overlay!.opacity = value;
                            });
                            _saveDrawing(showMessage: false);
                          },
                        ),
                        const SizedBox(height: 8),
                        Text('Size scale x${_overlay!.scale.toStringAsFixed(2)}'),
                        Slider(
                          value: _overlay!.scale,
                          min: 0.5,
                          max: 3.0,
                          divisions: 25,
                          onChanged: (value) {
                            setState(() {
                              _overlay!.scale = value;
                            });
                            _saveDrawing(showMessage: false);
                          },
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            ElevatedButton.icon(
                              onPressed: _setOverlayCenterToMap,
                              icon: const Icon(Icons.my_location),
                              label: const Text('Align to map center'),
                            ),
                            OutlinedButton.icon(
                              onPressed: _removeOverlay,
                              icon: const Icon(Icons.delete_outline),
                              label: const Text('Remove overlay'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInsightsPanel() {
    final totalEncroachments = _encroachments.length;
    final highImpactCount = _encroachments.where((info) => info.tpzPercent >= 10).length;
    final totalImpactArea = _encroachments.fold<double>(0, (sum, info) => sum + info.impactSquareMeters);

    return Material(
      color: Colors.white,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          ExpansionTile(
            initiallyExpanded: true,
            leading: Icon(Icons.area_chart, color: Colors.green[700]),
            title: Text(
              'Encroachment Summary',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text(
              totalEncroachments == 0
                  ? 'Live monitoring active — no encroachments detected'
                  : '$totalEncroachments encroachments detected (updated live)',
            ),
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _insightChip(Icons.circle, 'Total', totalEncroachments.toString()),
                        _insightChip(Icons.warning, 'High Impact', highImpactCount.toString()),
                        _insightChip(Icons.square_foot, 'Total Area', '${totalImpactArea.toStringAsFixed(2)} m²'),
                      ],
                    ),
                    const SizedBox(height: 12),
                    if (totalEncroachments == 0)
                      const Text('Start drawing structures or adjust overlays to calculate encroachments automatically.')
                    else
                      ..._encroachments.map(
                        (info) => Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: info.tpzPercent >= 10 ? Colors.red.shade400 : Colors.orange.shade300,
                              child: Text('${info.tpzPercent.toStringAsFixed(0)}%'),
                            ),
                            title: Text(info.structureLabel),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Tree: ${info.treeLabel}'),
                                Text('Impact area: ${info.impactSquareMeters.toStringAsFixed(2)} m²'),
                              ],
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Card(
            child: ListTile(
              leading: const Icon(Icons.autorenew, color: Colors.blue),
              title: const Text('Live encroachment monitoring'),
              subtitle: const Text('Encroachment metrics update automatically as you edit drawings and layers.'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _toolChip(String label, DrawingTool tool, IconData icon) {
    final isActive = _activeTool == tool;
    return ChoiceChip(
      avatar: Icon(icon, size: 16, color: isActive ? Colors.white : Colors.black87),
      label: Text(
        label,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(color: isActive ? Colors.white : Colors.black87, fontSize: 12),
      ),
      labelPadding: const EdgeInsets.symmetric(horizontal: 6),
      visualDensity: const VisualDensity(horizontal: -2, vertical: -2),
      selectedColor: Colors.deepPurple,
      backgroundColor: Colors.grey.shade200,
      showCheckmark: false,
      selected: isActive,
      onSelected: (selected) {
        if (!selected) return;
        if (tool == DrawingTool.select) {
          setState(() {
            _activeTool = tool;
            _draftVertices.clear();
            _measurementGuide = null;
          });
        } else {
          _showToolModeDialog(tool);
        }
      },
    );
  }

  Future<void> _showToolModeDialog(DrawingTool tool) async {
    final toolName = tool.name.replaceAll(RegExp(r'([A-Z])'), ' \$1').trim();
    final result = await showDialog<ToolMode>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Select $toolName Mode'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('Freeform'),
              subtitle: const Text('Click points freely until finished'),
              leading: const Icon(Icons.draw),
              onTap: () => Navigator.of(context).pop(ToolMode.freeform),
            ),
            ListTile(
              title: const Text('Measured (cm)'),
              subtitle: const Text('Specify exact distances in centimeters'),
              leading: const Icon(Icons.straighten),
              onTap: () => Navigator.of(context).pop(ToolMode.measuredCm),
            ),
            ListTile(
              title: const Text('Measured (m)'),
              subtitle: const Text('Specify exact distances in meters'),
              leading: const Icon(Icons.straighten),
              onTap: () => Navigator.of(context).pop(ToolMode.measuredM),
            ),
          ],
        ),
      ),
    );

    if (result != null) {
      setState(() {
        _activeTool = tool;
        _toolMode = result;
        _draftVertices.clear();
        _measurementGuide = null;
      });
    }
  }

  String _buildTileUrl() {
    switch (_baseMapStyle) {
      case BaseMapStyle.street:
        return 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png';
      case BaseMapStyle.topo:
        return 'https://{s}.tile.opentopomap.org/{z}/{x}/{y}.png';
      case BaseMapStyle.satellite:
        return 'https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}';
    }
  }

  Future<void> _saveDrawing({bool showMessage = true}) async {
    try {
      await DrawingStorageService.saveDrawing(
        widget.site.id,
        _structures.map((structure) => structure.toJson()).toList(),
        {
          'showTPZ': _showTPZ,
          'showSRZ': _showSRZ,
          'data': _overlay?.toJson(),
        },
        const [],
      );

      if (showMessage && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Drawing saved.')),
        );
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save drawing: $error')),
        );
      }
    }
  }

  Future<void> _uploadOverlay() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        allowMultiple: false,
        type: FileType.custom,
        allowedExtensions: ['png', 'jpg', 'jpeg', 'dwg'],
        withData: true,
      );

      if (result == null || result.files.isEmpty) {
        return;
      }

      final file = result.files.single;
      final bytes = file.bytes;

      if (bytes == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Unable to read selected file.')),
          );
        }
        return;
      }

      final extension = (file.extension ?? '').toLowerCase();
      final isImage = extension == 'png' || extension == 'jpg' || extension == 'jpeg';

      final saved = await SiteFileService.saveFileFromBytes(
        widget.site.id,
        bytes,
        file.name,
        isImage ? 'Image' : 'AutoCAD Drawing',
      );

      if (saved == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to store overlay file.')),
          );
        }
        return;
      }

      setState(() {
        _overlay = DrawingOverlay(
          fileId: saved.id,
          originalName: saved.originalName,
          fileType: saved.fileType,
          center: _mapCenter,
          scale: 1.0,
          opacity: 0.7,
          isImage: isImage,
          imageBytes: isImage ? bytes : null,
        );
      });

      await _saveDrawing();
    } catch (e) {
      debugPrint('Overlay upload failed: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Overlay upload failed: $e')),
        );
      }
    }
  }

  void _removeOverlay() {
    setState(() {
      _overlay = null;
    });
    _saveDrawing(showMessage: false);
  }

  void _setOverlayCenterToMap() {
    if (_overlay == null) return;
    setState(() {
      _overlay!.center = _mapCenter;
    });
    _saveDrawing(showMessage: false);
  }

  LatLngBounds _overlayBounds(DrawingOverlay overlay) {
    final halfSize = _overlayBaseSizeMeters * overlay.scale / 2;
    const earthRadius = 6378137.0;
    final latRad = overlay.center.latitude * math.pi / 180.0;

    final deltaLat = (halfSize / earthRadius) * (180 / math.pi);
    final deltaLon = (halfSize / (earthRadius * math.cos(latRad))) * (180 / math.pi);

    final south = overlay.center.latitude - deltaLat;
    final north = overlay.center.latitude + deltaLat;
    final west = overlay.center.longitude - deltaLon;
    final east = overlay.center.longitude + deltaLon;

    return LatLngBounds(LatLng(south, west), LatLng(north, east));
  }

  List<LatLng> _boundsToPolygon(LatLngBounds bounds) {
    final sw = bounds.southWest;
    final ne = bounds.northEast;
    final nw = LatLng(ne.latitude, sw.longitude);
    final se = LatLng(sw.latitude, ne.longitude);
    return [sw, se, ne, nw, sw];
  }

  Widget _buildBaseMapLayer() {
    final template = _buildTileUrl();
    switch (_baseMapStyle) {
      case BaseMapStyle.street:
      case BaseMapStyle.topo:
        return TileLayer(
          urlTemplate: template,
          subdomains: const ['a', 'b', 'c'],
        );
      case BaseMapStyle.satellite:
        return TileLayer(
          urlTemplate: template,
          userAgentPackageName: 'com.arboristassistant.app',
        );
    }
  }

  String _baseMapLabel(BaseMapStyle style) {
    switch (style) {
      case BaseMapStyle.street:
        return 'Street Map';
      case BaseMapStyle.topo:
        return 'Topographic';
      case BaseMapStyle.satellite:
        return 'Satellite Imagery';
    }
  }

  Widget _insightChip(IconData icon, String label, String value) {
    return Chip(
      avatar: Icon(icon, size: 16),
      label: Text('$label: $value'),
      padding: const EdgeInsets.symmetric(horizontal: 8),
    );
  }

  Future<void> _exportAnnotatedMap() async {
    ui.Image? mapImage;
    ui.Image? logoImage;
    ui.Picture? picture;
    ui.Image? finalImage;
    
    try {
      NotificationService.showLoadingDialog(context, 'Preparing export...');

      // Capture map as image from repaint boundary
      final mapBoundary = _mapRepaintKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (mapBoundary == null || !mapBoundary.attached) {
        NotificationService.hideLoadingDialog(context);
        NotificationService.showError(context, 'Unable to capture map.');
        return;
      }

      mapImage = await mapBoundary.toImage(pixelRatio: 2.0);
      final mapWidth = mapImage.width.toDouble();
      final mapHeight = mapImage.height.toDouble();
      const double footerHeight = 220;

      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);
      final paint = Paint();
      final mapRect = Rect.fromLTWH(0, 0, mapWidth, mapHeight);
      canvas.drawImageRect(
        mapImage,
        Rect.fromLTWH(0, 0, mapImage.width.toDouble(), mapImage.height.toDouble()),
        mapRect,
        paint,
      );

      // Footer background
      final footerRect = Rect.fromLTWH(0, mapHeight, mapWidth, footerHeight);
      canvas.drawRect(footerRect, Paint()..color = Colors.white.withOpacity(0.92));

      final branding = BrandingService.loadBranding();
      if (branding?.logoPath != null && branding!.logoPath!.isNotEmpty) {
        try {
          final fileBytes = await SiteFileService.loadFileBytes(branding.logoPath!);
          if (fileBytes != null) {
            logoImage = await decodeImageFromList(fileBytes);
          }
        } catch (_) {}
      }

      // Draw logo if available
      const double logoSize = 150;
      if (logoImage != null) {
        final logoRect = Rect.fromLTWH(32, mapHeight + footerHeight / 2 - logoSize / 2, logoSize, logoSize);
        canvas.drawImageRect(
          logoImage,
          Rect.fromLTWH(0, 0, logoImage.width.toDouble(), logoImage.height.toDouble()),
          logoRect,
          paint,
        );
      } else {
        final placeholderRect = Rect.fromLTWH(32, mapHeight + footerHeight / 2 - logoSize / 2, logoSize, logoSize);
        canvas.drawRect(placeholderRect, Paint()..color = Colors.black87);
        final paragraphBuilder = ui.ParagraphBuilder(
          ui.ParagraphStyle(textAlign: TextAlign.center, fontSize: 16, fontWeight: FontWeight.bold),
        )
          ..pushStyle(ui.TextStyle(color: Colors.white))
          ..addText('LOGO');
        final paragraph = paragraphBuilder.build()..layout(const ui.ParagraphConstraints(width: logoSize));
        canvas.drawParagraph(paragraph, Offset(32, mapHeight + footerHeight / 2 - paragraph.height / 2));
      }

      final textPaint = Paint();
      final textLeft = 32 + 150 + 32;
      final paragraphBuilder = ui.ParagraphBuilder(ui.ParagraphStyle(fontSize: 16, height: 1.4));
      final dateFormat = DateFormat('dd/MM/yyyy');
      paragraphBuilder.pushStyle(ui.TextStyle(color: Colors.black87, fontWeight: FontWeight.w600));
      paragraphBuilder.addText('Report commissioned for ${widget.site.name}\n');
      paragraphBuilder.pop();
      paragraphBuilder.addText('Address: ${widget.site.address}\n');
      paragraphBuilder.addText('Date of Assessment: ${dateFormat.format(DateTime.now())}\n');
      paragraphBuilder.addText('Report prepared for: ${widget.site.name}\n');
      paragraphBuilder.addText('Planner Notes: ${widget.site.notes.isEmpty ? 'N/A' : widget.site.notes}\n');
      paragraphBuilder.addText('Map Style: ${_baseMapLabel(_baseMapStyle)}\n');
      paragraphBuilder.addText('SRZ shown: ${_showSRZ ? 'Yes' : 'No'}    TPZ shown: ${_showTPZ ? 'Yes' : 'No'}\n');

      final paragraph = paragraphBuilder.build()
        ..layout(ui.ParagraphConstraints(width: mapWidth - textLeft - 32));
      canvas.drawParagraph(paragraph, Offset(textLeft.toDouble(), mapHeight + 32));

      picture = recorder.endRecording();
      finalImage = await picture.toImage(mapWidth.toInt(), (mapHeight + footerHeight).toInt());
      final bytes = await finalImage.toByteData(format: ui.ImageByteFormat.png);
      if (bytes == null) {
        NotificationService.hideLoadingDialog(context);
        NotificationService.showError(context, 'Failed to encode map export.');
        return;
      }

      final fileName = 'map_export_${DateTime.now().millisecondsSinceEpoch}.png';
      final data = bytes.buffer.asUint8List();
      if (kIsWeb) {
        await downloadFile(data, fileName, 'image/png');
      } else {
        final directory = await SiteFileService.getExportDirectory();
        final file = await SiteFileService.saveBytesToFile(directory, fileName, data);
        await Share.shareXFiles([XFile(file.path)], text: 'Map export for ${widget.site.name}');
      }

      NotificationService.hideLoadingDialog(context);
      NotificationService.showSuccess(context, 'Map exported successfully.');
    } catch (e) {
      NotificationService.hideLoadingDialog(context);
      NotificationService.showError(context, 'Export failed: $e');
    } finally {
      mapImage?.dispose();
      logoImage?.dispose();
      picture?.dispose();
      finalImage?.dispose();
    }
  }
}

class EncroachmentCalculator {
  static const int _circleSegments = 48;

  static List<EncroachmentInfo> calculate({
    required List<TreeEntry> trees,
    required List<StructureFeature> structures,
    required bool includeTPZ,
    required bool includeSRZ,
  }) {
    if (structures.isEmpty || trees.isEmpty) {
      return const [];
    }

    final results = <EncroachmentInfo>[];

    for (final structure in structures) {
      for (final tree in trees) {
        final base = LatLng(tree.latitude, tree.longitude);
        final structureOffsets = _projectLatLngs(base, structure.vertices);
        final structureArea = _polygonArea(structureOffsets).abs();
        if (structureArea <= 0) {
          continue;
        }

        if (includeTPZ && tree.nrz > 0) {
          final circle = _buildCirclePolygon(tree.nrz, base);
          final encroachment = _intersectArea(structureOffsets, circle);
          if (encroachment > 0) {
            final circleArea = math.pi * tree.nrz * tree.nrz;
            results.add(
              EncroachmentInfo(
                treeId: tree.id,
                treeLabel: 'Tree #${tree.id}',
                structureId: structure.id,
                structureLabel: structure.label,
                tpzPercent: (encroachment / circleArea) * 100,
                impactSquareMeters: encroachment,
              ),
            );
          }
        }

        if (includeSRZ && tree.srz > 0) {
          final circle = _buildCirclePolygon(tree.srz, base);
          final encroachment = _intersectArea(structureOffsets, circle);
          if (encroachment > 0) {
            final circleArea = math.pi * tree.srz * tree.srz;
            results.add(
              EncroachmentInfo(
                treeId: tree.id,
                treeLabel: 'Tree #${tree.id} (SRZ)',
                structureId: structure.id,
                structureLabel: structure.label,
                tpzPercent: (encroachment / circleArea) * 100,
                impactSquareMeters: encroachment,
              ),
            );
          }
        }
      }
    }

    return results;
  }

  static List<Offset> _buildCirclePolygon(double radiusMeters, LatLng origin) {
    final points = <LatLng>[];
    for (var i = 0; i < _circleSegments; i++) {
      final theta = (i / _circleSegments) * 2 * math.pi;
      final dx = math.cos(theta) * radiusMeters;
      final dy = math.sin(theta) * radiusMeters;
      points.add(_offsetToLatLng(origin, dx, dy));
    }
    return _projectLatLngs(origin, points);
  }

  static LatLng _offsetToLatLng(LatLng origin, double eastMeters, double northMeters) {
    const earthRadius = 6378137.0;
    final dLat = northMeters / earthRadius;
    final dLon = eastMeters / (earthRadius * math.cos(origin.latitude * math.pi / 180));
    final lat = origin.latitude + dLat * 180 / math.pi;
    final lon = origin.longitude + dLon * 180 / math.pi;
    return LatLng(lat, lon);
  }

  static List<Offset> _projectLatLngs(LatLng origin, List<LatLng> points) {
    const earthRadius = 6378137.0;
    final originLat = origin.latitude * math.pi / 180;
    return points
        .map(
          (p) {
            final lat = p.latitude * math.pi / 180;
            final lon = p.longitude * math.pi / 180;
            final x = earthRadius * (lon - origin.longitude * math.pi / 180) * math.cos(originLat);
            final y = earthRadius * (lat - originLat);
            return Offset(x, y);
          },
        )
        .toList();
  }

  static double _polygonArea(List<Offset> points) {
    if (points.length < 3) {
      return 0;
    }
    double area = 0;
    for (int i = 0; i < points.length; i++) {
      final j = (i + 1) % points.length;
      area += points[i].dx * points[j].dy;
      area -= points[j].dx * points[i].dy;
    }
    return area / 2.0;
  }

  static double _intersectArea(List<Offset> subject, List<Offset> clip) {
    final clipped = _sutherlandHodgman(subject, clip);
    if (clipped.isEmpty) {
      return 0;
    }
    return _polygonArea(clipped).abs();
  }

  static List<Offset> _sutherlandHodgman(List<Offset> subject, List<Offset> clip) {
    var output = List<Offset>.from(subject);
    for (int i = 0; i < clip.length; i++) {
      final input = List<Offset>.from(output);
      output = [];
      final A = clip[i];
      final B = clip[(i + 1) % clip.length];
      for (int j = 0; j < input.length; j++) {
        final P = input[j];
        final Q = input[(j + 1) % input.length];
        final insideP = _isInside(A, B, P);
        final insideQ = _isInside(A, B, Q);
        if (insideP && insideQ) {
          output.add(Q);
        } else if (insideP && !insideQ) {
          output.add(_intersection(A, B, P, Q));
        } else if (!insideP && insideQ) {
          output.add(_intersection(A, B, P, Q));
          output.add(Q);
        }
      }
    }
    return output;
  }

  static bool _isInside(Offset a, Offset b, Offset p) {
    return ((b.dx - a.dx) * (p.dy - a.dy) - (b.dy - a.dy) * (p.dx - a.dx)) >= 0;
  }

  static Offset _intersection(Offset a, Offset b, Offset p, Offset q) {
    final A1 = b.dy - a.dy;
    final B1 = a.dx - b.dx;
    final C1 = A1 * a.dx + B1 * a.dy;

    final A2 = q.dy - p.dy;
    final B2 = p.dx - q.dx;
    final C2 = A2 * p.dx + B2 * p.dy;

    final det = A1 * B2 - A2 * B1;
    if (det == 0) {
      return q;
    }

    final x = (B2 * C1 - B1 * C2) / det;
    final y = (A1 * C2 - A2 * C1) / det;
    return Offset(x, y);
  }
}
