import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import '../models/site.dart';

class DrawnLine {
  final List<Offset> points;
  final Color color;
  final double strokeWidth;
  
  DrawnLine({required this.points, required this.color, required this.strokeWidth});
}

class CleanDrawingPage extends StatefulWidget {
  final Site site;
  
  const CleanDrawingPage({Key? key, required this.site}) : super(key: key);

  @override
  State<CleanDrawingPage> createState() => _CleanDrawingPageState();
}

class _CleanDrawingPageState extends State<CleanDrawingPage> {
  String _currentTool = 'pen';
  Color _drawingColor = Colors.black;
  double _strokeWidth = 2.0;
  List<DrawnLine> _lines = [];
  List<Offset> _currentLine = [];
  List<List<DrawnLine>> _undoStack = [];

  void _selectTool(String tool) {
    setState(() {
      _currentTool = tool;
      _currentLine.clear();
    });
    
    switch (tool) {
      case 'save':
        _saveDrawing();
        break;
      case 'undo':
        _undo();
        break;
      case 'clear':
        _clearAll();
        break;
    }
  }

  void _undo() {
    if (_lines.isNotEmpty) {
      setState(() {
        _undoStack.add(List.from(_lines));
        _lines.removeLast();
      });
    }
  }

  void _clearAll() {
    if (_lines.isNotEmpty) {
      setState(() {
        _undoStack.add(List.from(_lines));
        _lines.clear();
      });
    }
  }

  void _saveDrawing() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Drawing saved successfully')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(80),
        child: Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 2, offset: Offset(0, 1))],
          ),
          child: Column(
            children: [
              // Top menu bar
              Container(
                height: 30,
                color: Colors.grey[200],
                child: Row(
                  children: [
                    _buildMenuButton('File'),
                    _buildMenuButton('Edit'),
                    _buildMenuButton('View'),
                    _buildMenuButton('Tools'),
                    const Spacer(),
                    Text('ArborCAD - ${widget.site.name}', style: const TextStyle(fontSize: 12)),
                    const SizedBox(width: 16),
                  ],
                ),
              ),
              // Main toolbar
              Container(
                height: 50,
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Row(
                  children: [
                    _buildToolButton(Icons.edit, 'pen', 'Pen', _currentTool == 'pen'),
                    _buildToolButton(Icons.timeline, 'line', 'Line', _currentTool == 'line'),
                    _buildToolButton(Icons.crop_square, 'rectangle', 'Rectangle', _currentTool == 'rectangle'),
                    _buildToolButton(Icons.circle_outlined, 'circle', 'Circle', _currentTool == 'circle'),
                    _buildToolButton(Icons.text_fields, 'text', 'Text', _currentTool == 'text'),
                    const SizedBox(width: 16),
                    _buildColorPicker(),
                    _buildStrokeSelector(),
                    const SizedBox(width: 16),
                    _buildToolButton(Icons.undo, 'undo', 'Undo', false),
                    _buildToolButton(Icons.clear, 'clear', 'Clear', false),
                    _buildToolButton(Icons.save, 'save', 'Save', false),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      body: Container(
        color: Colors.white,
        child: GestureDetector(
          onPanStart: _onPanStart,
          onPanUpdate: _onPanUpdate,
          onPanEnd: _onPanEnd,
          child: CustomPaint(
            painter: DrawingPainter(_lines, _currentLine, _drawingColor, _strokeWidth),
            size: Size.infinite,
          ),
        ),
      ),
    );
  }

  Widget _buildMenuButton(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Text(text, style: const TextStyle(fontSize: 11)),
    );
  }

  Widget _buildToolButton(IconData icon, String tool, String tooltip, bool isSelected) {
    return Tooltip(
      message: tooltip,
      child: Container(
        margin: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          color: isSelected ? Colors.blue[100] : Colors.transparent,
          borderRadius: BorderRadius.circular(4),
          border: isSelected ? Border.all(color: Colors.blue) : null,
        ),
        child: IconButton(
          icon: Icon(icon, size: 20),
          onPressed: () => _selectTool(tool),
          padding: const EdgeInsets.all(4),
        ),
      ),
    );
  }

  Widget _buildColorPicker() {
    return GestureDetector(
      onTap: _showColorPicker,
      child: Container(
        width: 30,
        height: 30,
        decoration: BoxDecoration(
          color: _drawingColor,
          border: Border.all(color: Colors.grey),
          borderRadius: BorderRadius.circular(4),
        ),
      ),
    );
  }

  Widget _buildStrokeSelector() {
    return DropdownButton<double>(
      value: _strokeWidth,
      items: [1.0, 2.0, 3.0, 4.0, 5.0, 8.0].map((width) {
        return DropdownMenuItem(
          value: width,
          child: Text('${width.toInt()}px'),
        );
      }).toList(),
      onChanged: (value) {
        setState(() {
          _strokeWidth = value ?? 2.0;
        });
      },
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
            onColorChanged: (color) {
              setState(() {
                _drawingColor = color;
              });
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Done'),
          ),
        ],
      ),
    );
  }

  void _onPanStart(DragStartDetails details) {
    if (_currentTool == 'pen') {
      setState(() {
        _currentLine = [details.localPosition];
      });
    }
  }

  void _onPanUpdate(DragUpdateDetails details) {
    if (_currentTool == 'pen') {
      setState(() {
        _currentLine.add(details.localPosition);
      });
    }
  }

  void _onPanEnd(DragEndDetails details) {
    if (_currentTool == 'pen' && _currentLine.isNotEmpty) {
      setState(() {
        _lines.add(DrawnLine(
          points: List.from(_currentLine),
          color: _drawingColor,
          strokeWidth: _strokeWidth,
        ));
        _currentLine.clear();
      });
    }
  }
}

class DrawingPainter extends CustomPainter {
  final List<DrawnLine> lines;
  final List<Offset> currentLine;
  final Color currentColor;
  final double currentStrokeWidth;

  DrawingPainter(this.lines, this.currentLine, this.currentColor, this.currentStrokeWidth);

  @override
  void paint(Canvas canvas, Size size) {
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

    // Draw current line being drawn
    if (currentLine.length > 1) {
      final paint = Paint()
        ..color = currentColor
        ..strokeWidth = currentStrokeWidth
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke;

      for (int i = 0; i < currentLine.length - 1; i++) {
        canvas.drawLine(currentLine[i], currentLine[i + 1], paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
