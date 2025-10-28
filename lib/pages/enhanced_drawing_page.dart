import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../models/site.dart';
import '../models/tree_entry.dart';
import '../services/tree_storage_service.dart';
import 'dart:math' as math;

class DrawnLine {
  final List<Offset> points;
  final Color color;
  final double strokeWidth;
  final String layerId;

  DrawnLine({
    required this.points,
    required this.color,
    required this.strokeWidth,
    required this.layerId,
  });
}

class DrawingLayer {
  final String id;
  final String name;
  final bool visible;
  final bool locked;
  final Color color;
  final List<DrawnLine> lines;
  final List<DrawnShape> shapes;

  DrawingLayer({
    required this.id,
    required this.name,
    this.visible = true,
    this.locked = false,
    this.color = Colors.black,
    List<DrawnLine>? lines,
    List<DrawnShape>? shapes,
  }) : lines = lines ?? [], shapes = shapes ?? [];

  DrawingLayer copyWith({
    String? id,
    String? name,
    bool? visible,
    bool? locked,
    Color? color,
    List<DrawnLine>? lines,
    List<DrawnShape>? shapes,
  }) {
    return DrawingLayer(
      id: id ?? this.id,
      name: name ?? this.name,
      visible: visible ?? this.visible,
      locked: locked ?? this.locked,
      color: color ?? this.color,
      lines: lines ?? this.lines,
      shapes: shapes ?? this.shapes,
    );
  }
}

class DrawnShape {
  final String type;
  final Color color;
  final double strokeWidth;
  final Offset startPoint;
  final Offset endPoint;
  final double? radius;
  final bool filled;
  final String? text;
  final String layerId;

  DrawnShape({
    required this.type,
    required this.color,
    required this.strokeWidth,
    required this.startPoint,
    required this.endPoint,
    this.radius,
    this.filled = false,
    this.text,
    required this.layerId,
  });
}

class EnhancedDrawingPage extends StatefulWidget {
  final Site site;

  const EnhancedDrawingPage({Key? key, required this.site}) : super(key: key);

  @override
  State<EnhancedDrawingPage> createState() => _EnhancedDrawingPageState();
}

class _EnhancedDrawingPageState extends State<EnhancedDrawingPage> {
  // Drawing state
  String _currentTool = 'pen';
  Color _drawingColor = Colors.black;
  double _strokeWidth = 2.0;
  List<DrawingLayer> _layers = [];
  String _currentLayerId = 'default';
  List<Offset> _currentLine = [];
  bool _showGrid = false;
  bool _snapToGrid = false;
  final double _gridSize = 20.0;
  bool _isDrawing = false;
  Offset? _startPoint;
  Offset? _currentPoint;
  bool _showLayersPanel = false;

  // Map state
  final List<TreeEntry> _treeEntries = [];
  final List<Marker> _markers = [];
  final List<CircleMarker> _srzCircles = [];
  final List<CircleMarker> _nrzCircles = [];
  final MapController _mapController = MapController();
  LatLng _center = LatLng(-37.8136, 144.9631); // Melbourne default
  double _zoom = 18.0;
  bool _showSRZ = true;
  bool _showNRZ = false;
  bool _satelliteView = true;
  bool _showMap = true; // Toggle between map and drawing canvas
  bool _mapLocked = false; // Lock map to prevent accidental movement

  @override
  void initState() {
    super.initState();
    _loadMapPosition();
    _loadTrees();
    _initializeLayers();
  }

  void _initializeLayers() {
    _layers = [
      DrawingLayer(id: 'trees', name: 'Trees & Vegetation', color: Colors.green),
      DrawingLayer(id: 'boundaries', name: 'Property Boundaries', color: Colors.red),
      DrawingLayer(id: 'utilities', name: 'Utilities', color: Colors.blue),
      DrawingLayer(id: 'annotations', name: 'Annotations', color: Colors.black),
      DrawingLayer(id: 'default', name: 'General Drawing', color: Colors.black),
    ];
  }

  void _loadMapPosition() {
    if (widget.site.latitude != null && widget.site.longitude != null) {
      _center = LatLng(widget.site.latitude!, widget.site.longitude!);
    }
  }

  Future<void> _loadTrees() async {
    try {
      final trees = await TreeStorageService.getTreesForSite(widget.site.id);
      setState(() {
        _treeEntries.clear();
        _treeEntries.addAll(trees);
        _updateMarkers();
      });
    } catch (e) {
      print('Error loading trees: $e');
    }
  }

  void _updateMarkers() {
    _markers.clear();
    _srzCircles.clear();
    _nrzCircles.clear();

    for (final tree in _treeEntries) {
      if (tree.latitude != null && tree.longitude != null) {
        final position = LatLng(tree.latitude!, tree.longitude!);
        
        // Add tree marker
        _markers.add(
          Marker(
            point: position,
            width: 30,
            height: 30,
            child: GestureDetector(
              onTap: () => _showTreeInfo(tree),
              child: Container(
                decoration: BoxDecoration(
                  color: _getTreeConditionColor(tree.condition),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
                child: Center(
                  child: Text(
                    tree.id.substring(0, 1).toUpperCase(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
            ),
          ),
        );

        // Add SRZ circle if enabled
        if (_showSRZ && tree.dsh > 0) {
          final srzRadius = _calculateSRZ(tree.dsh);
          _srzCircles.add(
            CircleMarker(
              point: position,
              radius: srzRadius,
              color: Colors.orange.withOpacity(0.3),
              borderColor: Colors.orange,
              borderStrokeWidth: 2,
            ),
          );
        }

        // Add NRZ circle if enabled
        if (_showNRZ && tree.dsh > 0) {
          final nrzRadius = _calculateNRZ(tree.dsh);
          _nrzCircles.add(
            CircleMarker(
              point: position,
              radius: nrzRadius,
              color: Colors.red.withOpacity(0.2),
              borderColor: Colors.red,
              borderStrokeWidth: 2,
            ),
          );
        }
      }
    }
  }

  Color _getTreeConditionColor(String condition) {
    switch (condition.toLowerCase()) {
      case 'excellent':
        return Colors.green;
      case 'good':
        return Colors.lightGreen;
      case 'fair':
        return Colors.yellow;
      case 'poor':
        return Colors.orange;
      case 'critical':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  double _calculateSRZ(double dsh) {
    // AS4970 SRZ calculation: radius = DSH * 12 (in cm), convert to meters
    return (dsh * 12) / 100;
  }

  double _calculateNRZ(double dsh) {
    // Simplified NRZ calculation
    return (dsh * 6) / 100;
  }

  void _showTreeInfo(TreeEntry tree) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Tree ${tree.id}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Species: ${tree.species}'),
            Text('DSH: ${tree.dsh.toStringAsFixed(1)} cm'),
            Text('Height: ${tree.height.toStringAsFixed(1)} m'),
            Text('Condition: ${tree.condition}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _selectTool(String tool) {
    setState(() {
      _currentTool = tool;
      _currentLine.clear();
      _startPoint = null;
      _currentPoint = null;
      _isDrawing = false;
    });

    switch (tool) {
      case 'clear':
        _clearAll();
        break;
      case 'grid':
        _toggleGrid();
        break;
      case 'snap':
        _toggleSnap();
        break;
      case 'map':
        _toggleMapView();
        break;
      case 'srz':
        _toggleSRZ();
        break;
      case 'nrz':
        _toggleNRZ();
        break;
      case 'lock':
        _toggleMapLock();
        break;
      case 'layers':
        _toggleLayersPanel();
        break;
    }
  }

  void _clearAll() {
    setState(() {
      for (var layer in _layers) {
        layer.lines.clear();
        layer.shapes.clear();
      }
      _currentLine.clear();
    });
  }

  void _toggleGrid() {
    setState(() {
      _showGrid = !_showGrid;
    });
  }

  void _toggleSnap() {
    setState(() {
      _snapToGrid = !_snapToGrid;
    });
  }

  void _toggleMapView() {
    setState(() {
      _showMap = !_showMap;
    });
  }

  void _toggleSRZ() {
    setState(() {
      _showSRZ = !_showSRZ;
      _updateMarkers();
    });
  }

  void _toggleNRZ() {
    setState(() {
      _showNRZ = !_showNRZ;
      _updateMarkers();
    });
  }

  void _toggleMapLock() {
    setState(() {
      _mapLocked = !_mapLocked;
    });
  }

  void _toggleLayersPanel() {
    setState(() {
      _showLayersPanel = !_showLayersPanel;
    });
  }

  DrawingLayer get _currentLayer {
    return _layers.firstWhere(
      (layer) => layer.id == _currentLayerId,
      orElse: () => _layers.first,
    );
  }

  void _setCurrentLayer(String layerId) {
    setState(() {
      _currentLayerId = layerId;
    });
  }

  void _toggleLayerVisibility(String layerId) {
    setState(() {
      final layerIndex = _layers.indexWhere((l) => l.id == layerId);
      if (layerIndex != -1) {
        _layers[layerIndex] = _layers[layerIndex].copyWith(
          visible: !_layers[layerIndex].visible,
        );
      }
    });
  }

  void _toggleLayerLock(String layerId) {
    setState(() {
      final layerIndex = _layers.indexWhere((l) => l.id == layerId);
      if (layerIndex != -1) {
        _layers[layerIndex] = _layers[layerIndex].copyWith(
          locked: !_layers[layerIndex].locked,
        );
      }
    });
  }

  Offset _snapToGridIfEnabled(Offset point) {
    if (!_snapToGrid) return point;
    
    final snappedX = (point.dx / _gridSize).round() * _gridSize;
    final snappedY = (point.dy / _gridSize).round() * _gridSize;
    return Offset(snappedX, snappedY);
  }

  void _onPanStart(DragStartDetails details) {
    if (_showMap) return; // Don't draw on map
    if (_currentLayer.locked) return; // Don't draw on locked layers
    
    final point = _snapToGridIfEnabled(details.localPosition);
    
    setState(() {
      if (_currentTool == 'pen') {
        _currentLine = [point];
        _isDrawing = true;
      } else if (['line', 'rectangle', 'circle', 'arrow'].contains(_currentTool)) {
        _isDrawing = true;
        _startPoint = point;
        _currentPoint = point;
      }
    });
  }

  void _onPanUpdate(DragUpdateDetails details) {
    if (_showMap) return;
    if (_currentLayer.locked) return; // Don't draw on locked layers
    
    final point = _snapToGridIfEnabled(details.localPosition);
    
    setState(() {
      if (_currentTool == 'pen' && _isDrawing) {
        _currentLine.add(point);
      } else if (_isDrawing) {
        _currentPoint = point;
      }
    });
  }

  void _onPanEnd(DragEndDetails details) {
    if (_showMap) return;
    if (_currentLayer.locked) return; // Don't draw on locked layers
    
    setState(() {
      if (_currentTool == 'pen') {
        _currentLayer.lines.add(DrawnLine(
          points: List.from(_currentLine),
          color: _drawingColor,
          strokeWidth: _strokeWidth,
          layerId: _currentLayerId,
        ));
        _currentLine = [];
      } else if (['line', 'rectangle', 'circle', 'arrow'].contains(_currentTool)) {
        _addShape();
      }
      _isDrawing = false;
    });
  }

  void _addShape() {
    if (_startPoint == null || _currentPoint == null) return;
    if (_currentLayer.locked) return; // Don't add to locked layers

    _currentLayer.shapes.add(DrawnShape(
      type: _currentTool,
      color: _drawingColor,
      strokeWidth: _strokeWidth,
      startPoint: _startPoint!,
      endPoint: _currentPoint!,
      radius: _currentTool == 'circle' 
        ? (_currentPoint! - _startPoint!).distance 
        : null,
      layerId: _currentLayerId,
    ));
  }

  Widget _buildToolButton(IconData icon, String tool, String tooltip) {
    return Tooltip(
      message: tooltip,
      child: IconButton(
        icon: Icon(
          icon,
          color: _currentTool == tool ? Colors.blue : Colors.black87,
        ),
        onPressed: () => _selectTool(tool),
      ),
    );
  }

  Widget _buildToggleButton(IconData icon, String tool, String tooltip, bool isActive) {
    return Tooltip(
      message: tooltip,
      child: IconButton(
        icon: Icon(
          icon,
          color: isActive ? Colors.blue : Colors.black87,
        ),
        onPressed: () => _selectTool(tool),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Site Plan - ${widget.site.name}'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // Toolbar
          Container(
            padding: const EdgeInsets.all(8.0),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              border: Border(bottom: BorderSide(color: Colors.grey[300]!)),
            ),
            child: Row(
              children: [
                // View toggle
                _buildToggleButton(Icons.map, 'map', 'Toggle Map View', _showMap),
                const SizedBox(width: 10),
                
                // Drawing tools
                _buildToolButton(Icons.edit, 'pen', 'Pen'),
                _buildToolButton(Icons.timeline, 'line', 'Line'),
                _buildToolButton(Icons.crop_square, 'rectangle', 'Rectangle'),
                _buildToolButton(Icons.circle_outlined, 'circle', 'Circle'),
                _buildToolButton(Icons.arrow_forward, 'arrow', 'Arrow'),
                const SizedBox(width: 20),
                
                // Map overlays
                _buildToggleButton(Icons.account_tree, 'srz', 'Show SRZ', _showSRZ),
                _buildToggleButton(Icons.dangerous, 'nrz', 'Show NRZ', _showNRZ),
                const SizedBox(width: 20),
                
                // Map controls
                _buildToggleButton(Icons.lock, 'lock', 'Lock Map', _mapLocked),
                const SizedBox(width: 20),
                
                // Drawing options
                _buildToggleButton(Icons.grid_on, 'grid', 'Toggle Grid', _showGrid),
                _buildToggleButton(Icons.grid_4x4, 'snap', 'Snap to Grid', _snapToGrid),
                const SizedBox(width: 10),
                
                // Layers
                _buildToggleButton(Icons.layers, 'layers', 'Show Layers', _showLayersPanel),
                const SizedBox(width: 20),
                
                _buildToolButton(Icons.clear, 'clear', 'Clear All'),
                const Spacer(),
                
                // Color picker
                if (!_showMap) ...[
                  GestureDetector(
                    onTap: () => _showColorPicker(),
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: _drawingColor,
                        border: Border.all(color: Colors.grey),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text('Width: ${_strokeWidth.toInt()}'),
                  SizedBox(
                    width: 100,
                    child: Slider(
                      value: _strokeWidth,
                      min: 1,
                      max: 10,
                      divisions: 9,
                      onChanged: (value) => setState(() => _strokeWidth = value),
                    ),
                  ),
                  const SizedBox(width: 10),
                  // Current layer indicator
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _currentLayer.color.withOpacity(0.2),
                      border: Border.all(color: _currentLayer.color),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      'Layer: ${_currentLayer.name}',
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),
                ],
              ],
            ),
          ),
          
          // Main content area
          Expanded(
            child: Stack(
              children: [
                // Map view
                if (_showMap)
                  FlutterMap(
                    mapController: _mapController,
                    options: MapOptions(
                      initialCenter: _center,
                      initialZoom: _zoom,
                      minZoom: 10,
                      maxZoom: 22,
                      interactionOptions: InteractionOptions(
                        flags: _mapLocked 
                          ? InteractiveFlag.none 
                          : InteractiveFlag.all,
                      ),
                    ),
                    children: [
                      TileLayer(
                        urlTemplate: _satelliteView
                          ? 'https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}'
                          : 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                        userAgentPackageName: 'com.arborist.assistant',
                      ),
                      CircleLayer(circles: _srzCircles),
                      CircleLayer(circles: _nrzCircles),
                      MarkerLayer(markers: _markers),
                    ],
                  ),
                
                // Drawing canvas overlay
                if (!_showMap)
                  GestureDetector(
                    onPanStart: _onPanStart,
                    onPanUpdate: _onPanUpdate,
                    onPanEnd: _onPanEnd,
                    child: CustomPaint(
                      painter: DrawingPainter(
                        layers: _layers,
                        currentLine: _currentLine,
                        currentTool: _currentTool,
                        currentColor: _drawingColor,
                        currentStrokeWidth: _strokeWidth,
                        startPoint: _startPoint,
                        currentPoint: _currentPoint,
                        isDrawing: _isDrawing,
                        showGrid: _showGrid,
                        gridSize: _gridSize,
                      ),
                      size: Size.infinite,
                    ),
                  ),
              ],
            ),
          ),
          
          // Layers panel overlay
          if (_showLayersPanel)
            Positioned(
              right: 0,
              top: 0,
              bottom: 50, // Above status bar
              child: _buildLayersPanel(),
            ),
          
          // Status bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.grey[200],
              border: Border(top: BorderSide(color: Colors.grey[300]!)),
            ),
            child: Row(
              children: [
                Text('Trees: ${_treeEntries.length}'),
                const SizedBox(width: 20),
                Text('Mode: ${_showMap ? 'Map View' : 'Drawing Mode'}'),
                if (_mapLocked && _showMap) ...[
                  const SizedBox(width: 10),
                  const Icon(Icons.lock, size: 16, color: Colors.red),
                  const Text('Map Locked', style: TextStyle(color: Colors.red, fontSize: 12)),
                ],
                const Spacer(),
                Text('Layer: ${_currentLayer.name}'),
                const SizedBox(width: 20),
                Text('Site: ${widget.site.name}'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLayersPanel() {
    return Container(
      width: 250,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.grey[300]!),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(-2, 0),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              border: Border(bottom: BorderSide(color: Colors.grey[300]!)),
            ),
            child: Row(
              children: [
                const Icon(Icons.layers, size: 20),
                const SizedBox(width: 8),
                const Text('Layers', style: TextStyle(fontWeight: FontWeight.bold)),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close, size: 18),
                  onPressed: () => _toggleLayersPanel(),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
          ),
          
          // Layers list
          Expanded(
            child: ListView.builder(
              itemCount: _layers.length,
              itemBuilder: (context, index) {
                final layer = _layers[index];
                final isActive = layer.id == _currentLayerId;
                
                return Container(
                  decoration: BoxDecoration(
                    color: isActive ? Colors.blue.withOpacity(0.1) : null,
                    border: Border(bottom: BorderSide(color: Colors.grey[200]!)),
                  ),
                  child: ListTile(
                    dense: true,
                    leading: Container(
                      width: 20,
                      height: 20,
                      decoration: BoxDecoration(
                        color: layer.color,
                        border: Border.all(color: Colors.grey),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    title: Text(
                      layer.name,
                      style: TextStyle(
                        fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                        fontSize: 14,
                      ),
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: Icon(
                            layer.visible ? Icons.visibility : Icons.visibility_off,
                            size: 18,
                            color: layer.visible ? Colors.black54 : Colors.grey,
                          ),
                          onPressed: () => _toggleLayerVisibility(layer.id),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          icon: Icon(
                            layer.locked ? Icons.lock : Icons.lock_open,
                            size: 18,
                            color: layer.locked ? Colors.red : Colors.black54,
                          ),
                          onPressed: () => _toggleLayerLock(layer.id),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                      ],
                    ),
                    onTap: () => _setCurrentLayer(layer.id),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _showColorPicker() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Color'),
        content: SingleChildScrollView(
          child: BlockPicker(
            pickerColor: _drawingColor,
            onColorChanged: (color) => setState(() => _drawingColor = color),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Done'),
          ),
        ],
      ),
    );
  }
}

class DrawingPainter extends CustomPainter {
  final List<DrawingLayer> layers;
  final List<Offset> currentLine;
  final String currentTool;
  final Color currentColor;
  final double currentStrokeWidth;
  final Offset? startPoint;
  final Offset? currentPoint;
  final bool isDrawing;
  final bool showGrid;
  final double gridSize;

  DrawingPainter({
    required this.layers,
    required this.currentLine,
    required this.currentTool,
    required this.currentColor,
    required this.currentStrokeWidth,
    this.startPoint,
    this.currentPoint,
    required this.isDrawing,
    required this.showGrid,
    required this.gridSize,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Draw grid if enabled
    if (showGrid) {
      final paint = Paint()
        ..color = Colors.grey.withOpacity(0.3)
        ..strokeWidth = 0.5;

      for (double x = 0; x <= size.width; x += gridSize) {
        canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
      }

      for (double y = 0; y <= size.height; y += gridSize) {
        canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
      }
    }

    // Draw layers in order (visible layers only)
    for (final layer in layers) {
      if (!layer.visible) continue;
      
      // Draw lines in this layer
      for (final line in layer.lines) {
        final paint = Paint()
          ..color = line.color
          ..strokeWidth = line.strokeWidth
          ..strokeCap = StrokeCap.round
          ..style = PaintingStyle.stroke;

        for (int i = 0; i < line.points.length - 1; i++) {
          canvas.drawLine(line.points[i], line.points[i + 1], paint);
        }
      }
      
      // Draw shapes in this layer
      for (final shape in layer.shapes) {
        _drawShape(canvas, shape);
      }
    }

    // Draw current line being drawn
    if (currentLine.length > 1 && currentTool == 'pen') {
      final paint = Paint()
        ..color = currentColor
        ..strokeWidth = currentStrokeWidth
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke;

      for (int i = 0; i < currentLine.length - 1; i++) {
        canvas.drawLine(currentLine[i], currentLine[i + 1], paint);
      }
    }

    // Draw preview for shape tools
    if (startPoint != null && currentPoint != null && isDrawing && currentTool != 'pen') {
      _drawPreview(canvas);
    }
  }

  void _drawShape(Canvas canvas, DrawnShape shape) {
    final paint = Paint()
      ..color = shape.color
      ..strokeWidth = shape.strokeWidth
      ..strokeCap = StrokeCap.round;

    switch (shape.type) {
      case 'line':
        paint.style = PaintingStyle.stroke;
        canvas.drawLine(shape.startPoint, shape.endPoint, paint);
        break;
      case 'rectangle':
        paint.style = shape.filled ? PaintingStyle.fill : PaintingStyle.stroke;
        final rect = Rect.fromPoints(shape.startPoint, shape.endPoint);
        canvas.drawRect(rect, paint);
        break;
      case 'circle':
        paint.style = shape.filled ? PaintingStyle.fill : PaintingStyle.stroke;
        if (shape.radius != null) {
          canvas.drawCircle(shape.startPoint, shape.radius!, paint);
        }
        break;
      case 'arrow':
        paint.style = PaintingStyle.stroke;
        _drawArrow(canvas, shape.startPoint, shape.endPoint, paint);
        break;
    }
  }

  void _drawArrow(Canvas canvas, Offset start, Offset end, Paint paint) {
    canvas.drawLine(start, end, paint);
    
    // Draw arrowhead
    final direction = (end - start).direction;
    final arrowLength = 15.0;
    final arrowAngle = 0.5;
    
    final arrowPoint1 = end + Offset(
      arrowLength * math.cos(direction + math.pi - arrowAngle),
      arrowLength * math.sin(direction + math.pi - arrowAngle),
    );
    
    final arrowPoint2 = end + Offset(
      arrowLength * math.cos(direction + math.pi + arrowAngle),
      arrowLength * math.sin(direction + math.pi + arrowAngle),
    );
    
    canvas.drawLine(end, arrowPoint1, paint);
    canvas.drawLine(end, arrowPoint2, paint);
  }

  void _drawPreview(Canvas canvas) {
    final paint = Paint()
      ..color = currentColor.withOpacity(0.5)
      ..strokeWidth = currentStrokeWidth
      ..strokeCap = StrokeCap.round;

    switch (currentTool) {
      case 'line':
        paint.style = PaintingStyle.stroke;
        canvas.drawLine(startPoint!, currentPoint!, paint);
        break;
      case 'rectangle':
        paint.style = PaintingStyle.stroke;
        final rect = Rect.fromPoints(startPoint!, currentPoint!);
        canvas.drawRect(rect, paint);
        break;
      case 'circle':
        paint.style = PaintingStyle.stroke;
        final radius = (currentPoint! - startPoint!).distance;
        canvas.drawCircle(startPoint!, radius, paint);
        break;
      case 'arrow':
        paint.style = PaintingStyle.stroke;
        _drawArrow(canvas, startPoint!, currentPoint!, paint);
        break;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

// Simple color picker
class BlockPicker extends StatelessWidget {
  final Color pickerColor;
  final ValueChanged<Color> onColorChanged;

  const BlockPicker({
    Key? key,
    required this.pickerColor,
    required this.onColorChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final colors = [
      Colors.black,
      Colors.red,
      Colors.green,
      Colors.blue,
      Colors.yellow,
      Colors.orange,
      Colors.purple,
      Colors.brown,
      Colors.grey,
    ];

    return Wrap(
      children: colors.map((color) => GestureDetector(
        onTap: () => onColorChanged(color),
        child: Container(
          width: 40,
          height: 40,
          margin: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: color,
            border: Border.all(
              color: pickerColor == color ? Colors.white : Colors.grey,
              width: pickerColor == color ? 3 : 1,
            ),
            borderRadius: BorderRadius.circular(4),
          ),
        ),
      )).toList(),
    );
  }
}
