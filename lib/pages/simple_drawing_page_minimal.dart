import 'package:flutter/material.dart';
import '../models/site.dart';

class DrawnLine {
  final List<Offset> points;
  final Color color;
  final double strokeWidth;

  DrawnLine({
    required this.points,
    required this.color,
    required this.strokeWidth,
  });
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

  DrawnShape({
    required this.type,
    required this.color,
    required this.strokeWidth,
    required this.startPoint,
    required this.endPoint,
    this.radius,
    this.filled = false,
    this.text,
  });
}

class SimpleDrawingPage extends StatefulWidget {
  final Site site;

  const SimpleDrawingPage({Key? key, required this.site}) : super(key: key);

  @override
  State<SimpleDrawingPage> createState() => _SimpleDrawingPageState();
}

class _SimpleDrawingPageState extends State<SimpleDrawingPage> {
  String _currentTool = 'pen';
  Color _drawingColor = Colors.black;
  double _strokeWidth = 2.0;
  List<DrawnLine> _lines = [];
  List<DrawnShape> _shapes = [];
  List<Offset> _currentLine = [];
  bool _showGrid = false;
  bool _snapToGrid = false;
  final double _gridSize = 20.0;
  bool _isDrawing = false;
  Offset? _startPoint;
  Offset? _currentPoint;

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
    }
  }

  void _clearAll() {
    setState(() {
      _lines.clear();
      _shapes.clear();
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

  Offset _snapToGridIfEnabled(Offset point) {
    if (!_snapToGrid) return point;
    
    final snappedX = (point.dx / _gridSize).round() * _gridSize;
    final snappedY = (point.dy / _gridSize).round() * _gridSize;
    return Offset(snappedX, snappedY);
  }

  void _onPanStart(DragStartDetails details) {
    final point = _snapToGridIfEnabled(details.localPosition);
    
    setState(() {
      if (_currentTool == 'pen') {
        _currentLine = [point];
        _isDrawing = true;
      } else if (['line', 'rectangle', 'circle'].contains(_currentTool)) {
        _isDrawing = true;
        _startPoint = point;
        _currentPoint = point;
      }
    });
  }

  void _onPanUpdate(DragUpdateDetails details) {
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
    setState(() {
      if (_currentTool == 'pen') {
        _lines.add(DrawnLine(
          points: List.from(_currentLine),
          color: _drawingColor,
          strokeWidth: _strokeWidth,
        ));
        _currentLine = [];
      } else if (['line', 'rectangle', 'circle'].contains(_currentTool)) {
        _addShape();
      }
      _isDrawing = false;
    });
  }

  void _addShape() {
    if (_startPoint == null || _currentPoint == null) return;

    _shapes.add(DrawnShape(
      type: _currentTool,
      color: _drawingColor,
      strokeWidth: _strokeWidth,
      startPoint: _startPoint!,
      endPoint: _currentPoint!,
      radius: _currentTool == 'circle' 
        ? (_currentPoint! - _startPoint!).distance 
        : null,
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Drawing - ${widget.site.name}'),
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
                _buildToolButton(Icons.edit, 'pen', 'Pen'),
                _buildToolButton(Icons.timeline, 'line', 'Line'),
                _buildToolButton(Icons.crop_square, 'rectangle', 'Rectangle'),
                _buildToolButton(Icons.circle_outlined, 'circle', 'Circle'),
                const SizedBox(width: 20),
                _buildToolButton(Icons.grid_on, 'grid', 'Toggle Grid'),
                _buildToolButton(Icons.grid_4x4, 'snap', 'Snap to Grid'),
                const SizedBox(width: 20),
                _buildToolButton(Icons.clear, 'clear', 'Clear All'),
                const Spacer(),
                // Color picker
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
                // Stroke width
                Text('Width: ${_strokeWidth.toInt()}'),
                Slider(
                  value: _strokeWidth,
                  min: 1,
                  max: 10,
                  divisions: 9,
                  onChanged: (value) => setState(() => _strokeWidth = value),
                ),
              ],
            ),
          ),
          // Drawing area
          Expanded(
            child: GestureDetector(
              onPanStart: _onPanStart,
              onPanUpdate: _onPanUpdate,
              onPanEnd: _onPanEnd,
              child: CustomPaint(
                painter: DrawingPainter(
                  lines: _lines,
                  shapes: _shapes,
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
  final List<DrawnLine> lines;
  final List<DrawnShape> shapes;
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
    required this.lines,
    required this.shapes,
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

      // Draw vertical lines
      for (double x = 0; x <= size.width; x += gridSize) {
        canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
      }

      // Draw horizontal lines
      for (double y = 0; y <= size.height; y += gridSize) {
        canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
      }
    }

    // Draw completed lines
    for (final line in lines) {
      final paint = Paint()
        ..color = line.color
        ..strokeWidth = line.strokeWidth
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke;

      for (int i = 0; i < line.points.length - 1; i++) {
        canvas.drawLine(line.points[i], line.points[i + 1], paint);
      }
    }

    // Draw completed shapes
    for (final shape in shapes) {
      _drawShape(canvas, shape);
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
    }
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
