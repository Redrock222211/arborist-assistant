import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'dart:ui' as ui;
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'dart:convert';
import '../utils/platform_download.dart';
import 'dart:typed_data';
import 'package:uuid/uuid.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../models/site.dart';
import '../models/tree_entry.dart';
import '../models/site_file.dart';
import '../services/tree_storage_service.dart';
import '../services/site_file_service.dart';

/// Professional tree layout map for reports
/// Shows all trees with different visual styles for export
class TreeLayoutMapPage extends StatefulWidget {
  final Site site;

  const TreeLayoutMapPage({Key? key, required this.site}) : super(key: key);

  @override
  State<TreeLayoutMapPage> createState() => _TreeLayoutMapPageState();
}

class _TreeLayoutMapPageState extends State<TreeLayoutMapPage> {
  final MapController _mapController = MapController();
  final GlobalKey _mapKey = GlobalKey();
  List<TreeEntry> _trees = [];
  bool _isLoading = true;
  
  // Map style options
  String _selectedStyle = 'satellite'; // satellite, street, hybrid
  bool _showTreeLabels = true;
  bool _showProtectionZones = true;
  bool _showCanopyCircles = true;
  bool _showSRZ = false; // Structural Root Zone
  bool _showGrid = false;
  bool _showScaleBar = true;
  bool _showNorthArrow = true;
  bool _showTreeNumbers = true;
  double _treeMarkerSize = 30.0;
  double _mapOpacity = 1.0;
  String _colorScheme = 'condition'; // condition, species, priority, health

  @override
  void initState() {
    super.initState();
    _loadTrees();
  }

  Future<void> _loadTrees() async {
    final trees = await TreeStorageService.getTreesForSite(widget.site.id);
    setState(() {
      _trees = trees;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                _buildToolbar(),
                Expanded(child: _buildMap()),
                _buildLegend(),
              ],
            ),
    );
  }

  Widget _buildToolbar() {
    return Container(
      padding: const EdgeInsets.all(8),
      color: Colors.white,
      child: Column(
        children: [
          // Row 1: Map styles and basic toggles
          Row(
            children: [
              // Map style selector
              _buildStyleButton('Satellite', 'satellite', Icons.satellite),
              const SizedBox(width: 8),
              _buildStyleButton('Street', 'street', Icons.map),
              const SizedBox(width: 8),
              _buildStyleButton('Hybrid', 'hybrid', Icons.layers),
              const SizedBox(width: 16),
              
              // Toggle options
              _buildToggleButton('Labels', _showTreeLabels, Icons.label, () {
                setState(() => _showTreeLabels = !_showTreeLabels);
              }),
              const SizedBox(width: 8),
              _buildToggleButton('TPZ', _showProtectionZones, Icons.circle_outlined, () {
                setState(() => _showProtectionZones = !_showProtectionZones);
              }),
              const SizedBox(width: 8),
              _buildToggleButton('SRZ', _showSRZ, Icons.radar, () {
                setState(() => _showSRZ = !_showSRZ);
              }),
              const SizedBox(width: 8),
              _buildToggleButton('Canopy', _showCanopyCircles, Icons.forest, () {
                setState(() => _showCanopyCircles = !_showCanopyCircles);
              }),
              const SizedBox(width: 8),
              _buildToggleButton('Grid', _showGrid, Icons.grid_on, () {
                setState(() => _showGrid = !_showGrid);
              }),
              
              const Spacer(),
              
              // More options button
              IconButton(
                onPressed: _showMoreOptions,
                icon: const Icon(Icons.settings),
                tooltip: 'More Options',
              ),
              
              // Export Map Image button
              ElevatedButton.icon(
                onPressed: () {
                  print('🔘 EXPORT MAP IMAGE BUTTON CLICKED!');
                  _exportAsImage();
                },
                icon: const Icon(Icons.image),
                label: const Text('Map Image'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                ),
              ),
              const SizedBox(width: 8),
              // Export PDF Report button
              Tooltip(
                message: '📄 Professional PDF reports for clients and compliance',
                child: ElevatedButton.icon(
                  onPressed: () {
                    print('🔘 EXPORT PDF BUTTON CLICKED!');
                    _exportAsPDF();
                  },
                  icon: const Icon(Icons.picture_as_pdf),
                  label: const Text('PDF Report'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red[700],
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              // Export CSV button
              Tooltip(
                message: '📊 Spreadsheet data for analysis in Excel/Google Sheets',
                child: ElevatedButton.icon(
                  onPressed: () {
                    print('🔘 EXPORT CSV BUTTON CLICKED!');
                    _exportTreeDataCSV();
                  },
                  icon: const Icon(Icons.table_chart),
                  label: const Text('CSV'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              // Export Word button
              Tooltip(
                message: '📝 Editable Word documents for customization',
                child: ElevatedButton.icon(
                  onPressed: () {
                    print('🔘 EXPORT WORD BUTTON CLICKED!');
                    _exportAsWord();
                  },
                  icon: const Icon(Icons.description),
                  label: const Text('Word'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue[800],
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 8),
          
          // Row 2: Color scheme and tree count only (moved sliders to More Options)
          Row(
            children: [
              const Text('Color by:', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(width: 8),
              DropdownButton<String>(
                value: _colorScheme,
                items: const [
                  DropdownMenuItem(value: 'condition', child: Text('Condition')),
                  DropdownMenuItem(value: 'species', child: Text('Species')),
                  DropdownMenuItem(value: 'health', child: Text('Health')),
                  DropdownMenuItem(value: 'priority', child: Text('Risk')),
                ],
                onChanged: (value) => setState(() => _colorScheme = value!),
              ),
              
              const Spacer(),
              
              // Tree count
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.green.shade200),
                ),
                child: Text(
                  '${_trees.length} trees',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStyleButton(String label, String style, IconData icon) {
    final isSelected = _selectedStyle == style;
    return ElevatedButton.icon(
      onPressed: () => setState(() => _selectedStyle = style),
      icon: Icon(icon, size: 18),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        backgroundColor: isSelected ? Colors.blue : Colors.grey[300],
        foregroundColor: isSelected ? Colors.white : Colors.black87,
      ),
    );
  }

  Widget _buildToggleButton(String label, bool isActive, IconData icon, VoidCallback onPressed) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 18),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        backgroundColor: isActive ? Colors.green : Colors.grey[300],
        foregroundColor: isActive ? Colors.white : Colors.black87,
      ),
    );
  }

  Widget _buildMap() {
    final center = LatLng(
      widget.site.latitude ?? -37.8136,
      widget.site.longitude ?? 144.9631,
    );

    return RepaintBoundary(
      key: _mapKey,
      child: FlutterMap(
        mapController: _mapController,
        options: MapOptions(
          initialCenter: center,
          initialZoom: 19.0,
          maxZoom: 22.0,
          minZoom: 15.0,
        ),
        children: [
        Opacity(
          opacity: _mapOpacity,
          child: TileLayer(
            urlTemplate: _getTileUrl(),
            subdomains: const ['a', 'b', 'c'],
          ),
        ),
        
        // Tree protection zones (TPZ)
        if (_showProtectionZones) ..._buildProtectionZones(),
        
        // Structural root zones (SRZ)
        if (_showSRZ) ..._buildSRZZones(),
        
        // Tree canopy circles
        if (_showCanopyCircles) ..._buildCanopyCircles(),
        
        // Tree markers
        ..._buildTreeMarkers(),
        
        // Tree labels
        if (_showTreeLabels) ..._buildTreeLabels(),
      ],
      ),
    );
  }

  String _getTileUrl() {
    switch (_selectedStyle) {
      case 'satellite':
        return 'https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}';
      case 'hybrid':
        return 'https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}';
      case 'street':
      default:
        return 'https://tile.openstreetmap.org/{z}/{x}/{y}.png';
    }
  }

  List<Widget> _buildProtectionZones() {
    return _trees.where((t) => t.latitude != null && t.longitude != null).map((tree) {
      final dsh = tree.dsh ?? 10.0;
      final tpzRadius = dsh * 12; // TPZ = 12 x DSH in cm
      
      return CircleLayer(
        circles: [
          CircleMarker(
            point: LatLng(tree.latitude!, tree.longitude!),
            radius: tpzRadius / 100, // Convert cm to meters (approximately)
            color: Colors.orange.withOpacity(0.2),
            borderColor: Colors.orange,
            borderStrokeWidth: 2,
          ),
        ],
      );
    }).toList();
  }

  List<Widget> _buildSRZZones() {
    return _trees.where((t) => t.latitude != null && t.longitude != null).map((tree) {
      final srz = tree.srz ?? (tree.dsh ?? 10.0) * 6; // SRZ = 6 x DSH (if not specified)
      
      return CircleLayer(
        circles: [
          CircleMarker(
            point: LatLng(tree.latitude!, tree.longitude!),
            radius: srz / 100, // Convert cm to meters
            color: Colors.red.withOpacity(0.15),
            borderColor: Colors.red.shade700,
            borderStrokeWidth: 2,
            useRadiusInMeter: true,
          ),
        ],
      );
    }).toList();
  }

  List<Widget> _buildCanopyCircles() {
    return _trees.where((t) => t.latitude != null && t.longitude != null).map((tree) {
      final canopyWidth = tree.canopySpread ?? 5.0;
      
      return CircleLayer(
        circles: [
          CircleMarker(
            point: LatLng(tree.latitude!, tree.longitude!),
            radius: canopyWidth / 2,
            color: Colors.green.withOpacity(0.3),
            borderColor: Colors.green.shade700,
            borderStrokeWidth: 1,
          ),
        ],
      );
    }).toList();
  }

  List<Widget> _buildTreeMarkers() {
    final treesWithCoords = _trees.where((t) => t.latitude != null && t.longitude != null).toList();
    
    return [
      MarkerLayer(
        markers: treesWithCoords.asMap().entries.map((entry) {
          final index = entry.key;
          final tree = entry.value;
          final treeNumber = index + 1; // Start from 1
          
          return Marker(
            point: LatLng(tree.latitude!, tree.longitude!),
            width: _treeMarkerSize,
            height: _treeMarkerSize,
            child: GestureDetector(
              onTap: () => _showTreeInfo(tree, treeNumber),
              child: Container(
                decoration: BoxDecoration(
                  color: _getTreeColor(tree),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: 4,
                    ),
                  ],
                ),
                child: Center(
                  child: _showTreeNumbers
                      ? Text(
                          treeNumber.toString(),
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: _treeMarkerSize / 3, // Dynamic font size
                            fontWeight: FontWeight.bold,
                          ),
                        )
                      : const SizedBox.shrink(),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    ];
  }

  List<Widget> _buildTreeLabels() {
    final treesWithCoords = _trees.where((t) => t.latitude != null && t.longitude != null).toList();
    
    return [
      MarkerLayer(
        markers: treesWithCoords.asMap().entries.map((entry) {
          final index = entry.key;
          final tree = entry.value;
          final treeNumber = index + 1;
          
          return Marker(
            point: LatLng(tree.latitude!, tree.longitude!),
            width: 120,
            height: 40,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.9),
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: Colors.black26),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'T$treeNumber',
                    style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    tree.species ?? 'Unknown',
                    style: const TextStyle(fontSize: 8),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    ];
  }

  Color _getTreeColor(TreeEntry tree) {
    switch (_colorScheme) {
      case 'condition':
        switch (tree.condition?.toLowerCase()) {
          case 'excellent': return Colors.green.shade700;
          case 'good': return Colors.green;
          case 'fair': return Colors.orange;
          case 'poor': return Colors.red.shade300;
          case 'dead': return Colors.grey;
          default: return Colors.blue;
        }
      
      case 'health':
        // Use vigorRating as proxy for health
        switch (tree.vigorRating?.toLowerCase()) {
          case 'high': return Colors.green.shade700;
          case 'medium': return Colors.green;
          case 'low': return Colors.orange;
          case 'very low': return Colors.red;
          default: return Colors.grey;
        }
      
      case 'priority':
        // Use riskRating as proxy for priority
        switch (tree.riskRating?.toLowerCase()) {
          case 'extreme': case 'high': return Colors.red;
          case 'medium': case 'moderate': return Colors.orange;
          case 'low': return Colors.green;
          default: return Colors.grey;
        }
      
      case 'species':
        // Color by species family (simplified)
        final species = tree.species?.toLowerCase() ?? '';
        if (species.contains('eucalyptus') || species.contains('gum')) return Colors.green.shade700;
        if (species.contains('acacia') || species.contains('wattle')) return Colors.yellow.shade700;
        if (species.contains('oak')) return Colors.brown;
        if (species.contains('pine')) return Colors.teal;
        return Colors.blue;
      
      default:
        return Colors.blue;
    }
  }

  void _showTreeInfo(TreeEntry tree, int treeNumber) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Tree $treeNumber'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Species: ${tree.species ?? 'Unknown'}'),
            Text('DSH: ${tree.dsh ?? '?'} cm'),
            Text('Height: ${tree.height ?? '?'} m'),
            Text('Condition: ${tree.condition ?? 'Unknown'}'),
            Text('Vigor: ${tree.vigorRating ?? 'Unknown'}'),
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

  Widget _buildLegend() {
    return Container(
      padding: const EdgeInsets.all(12),
      color: Colors.white,
      child: Row(
        children: [
          const Text('Legend: ', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(width: 16),
          ..._getLegendItems(),
        ],
      ),
    );
  }

  List<Widget> _getLegendItems() {
    switch (_colorScheme) {
      case 'condition':
        return [
          _legendItem('Excellent', Colors.green.shade700),
          _legendItem('Good', Colors.green),
          _legendItem('Fair', Colors.orange),
          _legendItem('Poor', Colors.red.shade300),
          _legendItem('Dead', Colors.grey),
        ];
      case 'health':
        return [
          _legendItem('High Vigor', Colors.green.shade700),
          _legendItem('Medium Vigor', Colors.green),
          _legendItem('Low Vigor', Colors.orange),
          _legendItem('Very Low Vigor', Colors.red),
        ];
      case 'priority':
        return [
          _legendItem('High Risk', Colors.red),
          _legendItem('Medium Risk', Colors.orange),
          _legendItem('Low Risk', Colors.green),
        ];
      case 'species':
        return [
          _legendItem('Eucalyptus', Colors.green.shade700),
          _legendItem('Acacia', Colors.yellow.shade700),
          _legendItem('Oak', Colors.brown),
          _legendItem('Pine', Colors.teal),
          _legendItem('Other', Colors.blue),
        ];
      default:
        return [];
    }
  }

  Widget _legendItem(String label, Color color) {
    return Padding(
      padding: const EdgeInsets.only(right: 16),
      child: Row(
        children: [
          Container(
            width: 16,
            height: 16,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 1),
            ),
          ),
          const SizedBox(width: 4),
          Text(label, style: const TextStyle(fontSize: 12)),
        ],
      ),
    );
  }

  void _showExportMenu() {
    print('📋 _showExportMenu() called - showing dialog');
    print('📊 Trees available: ${_trees.length}');
    print('📍 Trees with coordinates: ${_trees.where((t) => t.latitude != null && t.longitude != null).length}');
    
    showDialog(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black54,
      builder: (context) {
        print('🎨 Dialog builder called - creating AlertDialog');
        return AlertDialog(
        title: const Text('Export Site Map'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.image, color: Colors.blue),
              title: const Text('Export as PNG Image'),
              subtitle: const Text('High-resolution raster image for reports'),
              onTap: () {
                print('📸 PNG export selected');
                Navigator.pop(context);
                _exportAsImage();
              },
            ),
            ListTile(
              leading: const Icon(Icons.picture_as_pdf, color: Colors.red),
              title: const Text('Export as PDF'),
              subtitle: const Text('Professional site plan document'),
              onTap: () {
                print('📄 PDF export selected');
                Navigator.pop(context);
                _exportAsPDF();
              },
            ),
            ListTile(
              leading: const Icon(Icons.code, color: Colors.orange),
              title: const Text('Export as KML'),
              subtitle: const Text('Google Earth / GIS format'),
              onTap: () {
                print('🗺️ KML export selected');
                Navigator.pop(context);
                _exportAsKML();
              },
            ),
            ListTile(
              leading: const Icon(Icons.table_chart, color: Colors.green),
              title: const Text('Export Tree Data (CSV)'),
              subtitle: const Text('Spreadsheet with tree coordinates'),
              onTap: () {
                print('📊 CSV export selected');
                Navigator.pop(context);
                _exportTreeDataCSV();
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              print('❌ Export cancelled');
              Navigator.pop(context);
            },
            child: const Text('Cancel'),
          ),
        ],
        );
      },
    );
  }

  Future<void> _exportAsImage() async {
    try {
      // Show loading
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: Card(
            child: Padding(
              padding: EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Capturing Map Screenshot...'),
                ],
              ),
            ),
          ),
        ),
      );

      print('📸 Capturing map as image...');
      
      // Wait a moment for map to render
      await Future.delayed(const Duration(milliseconds: 500));
      
      // Capture the map widget as an image
      final RenderRepaintBoundary boundary = _mapKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
      final ui.Image image = await boundary.toImage(pixelRatio: 3.0); // High resolution
      final ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      final Uint8List pngBytes = byteData!.buffer.asUint8List();
      
      final filename = '${widget.site.name.replaceAll(' ', '_')}_map_${DateTime.now().millisecondsSinceEpoch}.png';
      
      print('📊 Map image captured: ${pngBytes.length} bytes, Size: ${image.width}x${image.height}');
      
      // Download as PNG
      await downloadFile(pngBytes, 'export.file', 'image/png');
      print('✅ Image downloaded');
      
      // Save to Files tab
      try {
        await _saveToFilesTab(
          filename: filename,
          content: String.fromCharCodes(pngBytes),
          fileType: 'image/png',
          category: 'Site Maps',
          description: 'Map screenshot with tree locations and markers',
        );
        print('✅ File saved to Files tab');
      } catch (e) {
        print('⚠️ Could not save to Files tab: $e');
      }
      
      // Close loading dialog
      Navigator.pop(context);
      
      // Show success
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('✅ Map screenshot saved!\n\n$filename\n\n• Downloaded to computer\n• Saved to Files tab (click refresh icon)'),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 5),
        ),
      );
      
      print('✅ Map screenshot complete');
    } catch (e) {
      Navigator.pop(context); // Close loading
      print('❌ Image export error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Image export failed: $e'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 5),
        ),
      );
    }
  }

  Future<void> _exportAsPDF() async {
    try {
      // Show loading
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: Card(
            child: Padding(
              padding: EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Generating PDF...'),
                ],
              ),
            ),
          ),
        ),
      );

      print('📄 Creating PDF document based on export groups...');
      
      // Get export groups from first tree (all trees on site should have same preferences)
      final exportGroups = _trees.isNotEmpty 
          ? Map<String, bool>.from(_trees.first.exportGroups)
          : <String, bool>{};
      
      // Create PDF
      final pdf = pw.Document();
      
      // Build list of widgets dynamically based on enabled groups
      List<pw.Widget> pdfWidgets = [
            // Header
            pw.Header(
              level: 0,
              child: pw.Text(
                '${widget.site.name} - Tree Site Plan',
                style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold),
              ),
            ),
            pw.SizedBox(height: 20),
            
            // Site Info
            pw.Text('Site Address: ${widget.site.address}'),
            pw.Text('Location: ${widget.site.latitude?.toStringAsFixed(6) ?? "N/A"}, ${widget.site.longitude?.toStringAsFixed(6) ?? "N/A"}'),
            pw.Text('Date: ${DateTime.now().toString().split(' ')[0]}'),
            pw.SizedBox(height: 20),
            
            // Tree Summary
            pw.Header(level: 1, text: 'Tree Inventory Summary'),
            pw.Text('Total Trees: ${_trees.length}'),
            pw.Text('Trees with GPS Coordinates: ${_trees.where((t) => t.latitude != null).length}'),
            pw.SizedBox(height: 20),
      ];
      
      // Only include tables for enabled export groups
      if (exportGroups['basic_data'] ?? true) {
        pdfWidgets.addAll([
            // Tree Table - Basic Data
            pw.Header(level: 1, text: 'Tree Inventory - Basic Data'),
            pw.TableHelper.fromTextArray(
              headers: ['No.', 'Species', 'DSH\n(cm)', 'Height\n(m)', 'Age', 'Condition', 'Vigor'],
              data: _trees.asMap().entries.map((entry) {
                final i = entry.key + 1;
                final tree = entry.value;
                return [
                  'T$i',
                  tree.species ?? 'Unknown',
                  tree.dsh?.toString() ?? '-',
                  tree.height?.toString() ?? '-',
                  tree.ageClass ?? '-',
                  tree.condition ?? '-',
                  tree.vigorRating ?? '-',
                ];
              }).toList(),
              headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 8, color: PdfColors.white),
              cellStyle: const pw.TextStyle(fontSize: 7),
              cellHeight: 25,
              headerDecoration: const pw.BoxDecoration(color: PdfColors.green700),
            ),
            
            pw.SizedBox(height: 20),
        ]);
      }
      
      if (exportGroups['health'] ?? true) {
        pdfWidgets.addAll([
            // Health Assessment
            pw.Header(level: 1, text: 'Health Assessment'),
            pw.TableHelper.fromTextArray(
              headers: ['No.', 'Vigor', 'Foliage\nDensity', 'Foliage\nColor', 'Dieback\n%', 'Growth\nRate', 'Health\nForm'],
              data: _trees.asMap().entries.map((entry) {
                final i = entry.key + 1;
                final tree = entry.value;
                return [
                  'T$i',
                  tree.vigorRating ?? '-',
                  tree.foliageDensity ?? '-',
                  tree.foliageColor ?? '-',
                  tree.diebackPercent?.toString() ?? '-',
                  tree.growthRate ?? '-',
                  tree.healthForm ?? '-',
                ];
              }).toList(),
              headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 8, color: PdfColors.white),
              cellStyle: const pw.TextStyle(fontSize: 7),
              cellHeight: 25,
              headerDecoration: const pw.BoxDecoration(color: PdfColors.blue700),
            ),
            
            pw.SizedBox(height: 20),
        ]);
      }
      
      if (exportGroups['structure'] ?? true) {
        pdfWidgets.addAll([
            // Structure Assessment
            pw.Header(level: 1, text: 'Structure Assessment'),
            pw.TableHelper.fromTextArray(
              headers: ['No.', 'Crown\nForm', 'Crown\nDensity', 'Trunk\nForm', 'Trunk\nLean', 'Root Plate', 'Structural\nRating'],
              data: _trees.asMap().entries.map((entry) {
                final i = entry.key + 1;
                final tree = entry.value;
                return [
                  'T$i',
                  tree.crownForm ?? '-',
                  tree.crownDensity ?? '-',
                  tree.trunkForm ?? '-',
                  tree.trunkLean ?? '-',
                  tree.rootPlateCondition ?? '-',
                  tree.structuralRating ?? '-',
                ];
              }).toList(),
              headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 8, color: PdfColors.white),
              cellStyle: const pw.TextStyle(fontSize: 7),
              cellHeight: 25,
              headerDecoration: const pw.BoxDecoration(color: PdfColors.orange700),
            ),
            
            pw.SizedBox(height: 20),
        ]);
      }
      
      // Location & Site Context
      if (exportGroups['location'] ?? true) {
        pdfWidgets.addAll([
            pw.Header(level: 1, text: 'Location & Site Context'),
            pw.TableHelper.fromTextArray(
              headers: ['No.', 'Location', 'Latitude', 'Longitude', 'Site\nType', 'Soil\nType'],
              data: _trees.asMap().entries.map((entry) {
                final i = entry.key + 1;
                final tree = entry.value;
                return [
                  'T$i',
                  tree.locationDescription ?? '-',
                  tree.latitude?.toStringAsFixed(6) ?? '-',
                  tree.longitude?.toStringAsFixed(6) ?? '-',
                  tree.siteType ?? '-',
                  tree.soilType ?? '-',
                ];
              }).toList(),
              headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 8, color: PdfColors.white),
              cellStyle: const pw.TextStyle(fontSize: 7),
              cellHeight: 25,
              headerDecoration: const pw.BoxDecoration(color: PdfColors.teal700),
            ),
            pw.SizedBox(height: 20),
        ]);
      }
      
      if (exportGroups['protection_zones'] ?? true) {
        pdfWidgets.addAll([
            // Protection Zones
            pw.Header(level: 1, text: 'Protection Zones'),
            pw.TableHelper.fromTextArray(
              headers: ['No.', 'Canopy\n(m)', 'TPZ\n(m²)', 'SRZ\n(m)', 'NRZ\n(m)', 'Latitude', 'Longitude'],
              data: _trees.asMap().entries.map((entry) {
                final i = entry.key + 1;
                final tree = entry.value;
                return [
                  'T$i',
                  tree.canopySpread?.toString() ?? '-',
                  tree.tpzArea?.toString() ?? '-',
                  tree.srz?.toString() ?? '-',
                  tree.nrz?.toString() ?? '-',
                  tree.latitude?.toStringAsFixed(6) ?? '-',
                  tree.longitude?.toStringAsFixed(6) ?? '-',
                ];
              }).toList(),
              headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 8, color: PdfColors.white),
              cellStyle: const pw.TextStyle(fontSize: 7),
              cellHeight: 25,
              headerDecoration: const pw.BoxDecoration(color: PdfColors.blue700),
            ),
            
            pw.SizedBox(height: 20),
        ]);
      }
      
      // ISA Risk Assessment
      if (exportGroups['isa_risk'] ?? true) {
        pdfWidgets.addAll([
            pw.Header(level: 1, text: 'ISA Risk Assessment'),
            pw.TableHelper.fromTextArray(
              headers: ['No.', 'Likelihood\nFailure', 'Likelihood\nImpact', 'Consequence', 'Overall\nRisk', 'Risk\nRating'],
              data: _trees.asMap().entries.map((entry) {
                final i = entry.key + 1;
                final tree = entry.value;
                return [
                  'T$i',
                  tree.likelihoodOfFailure ?? '-',
                  tree.likelihoodOfImpact ?? '-',
                  tree.consequenceOfFailure ?? '-',
                  tree.overallRiskRating ?? '-',
                  tree.riskRating ?? '-',
                ];
              }).toList(),
              headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 8, color: PdfColors.white),
              cellStyle: const pw.TextStyle(fontSize: 7),
              cellHeight: 25,
              headerDecoration: const pw.BoxDecoration(color: PdfColors.red700),
            ),
            pw.SizedBox(height: 20),
        ]);
      }
      
      // Retention & Removal
      if (exportGroups['retention_removal'] ?? true) {
        pdfWidgets.addAll([
            pw.Header(level: 1, text: 'Retention & Removal Assessment'),
            pw.TableHelper.fromTextArray(
              headers: ['No.', 'Retention\nValue', 'Retention\nRecommendation', 'Significance', 'Replanting\nRequired'],
              data: _trees.asMap().entries.map((entry) {
                final i = entry.key + 1;
                final tree = entry.value;
                return [
                  'T$i',
                  tree.retentionValue ?? '-',
                  tree.retentionRecommendation ?? '-',
                  tree.significance ?? '-',
                  tree.replantingRequired == true ? 'Yes' : 'No',
                ];
              }).toList(),
              headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 8, color: PdfColors.white),
              cellStyle: const pw.TextStyle(fontSize: 7),
              cellHeight: 25,
              headerDecoration: const pw.BoxDecoration(color: PdfColors.deepPurple700),
            ),
            pw.SizedBox(height: 20),
        ]);
      }
      
      // Management & Works
      if (exportGroups['management'] ?? true) {
        pdfWidgets.addAll([
            pw.Header(level: 1, text: 'Management & Works'),
            pw.TableHelper.fromTextArray(
              headers: ['No.', 'Recommended\nWorks', 'Works\nPriority', 'Timeframe', 'Supervision\nRequired'],
              data: _trees.asMap().entries.map((entry) {
                final i = entry.key + 1;
                final tree = entry.value;
                final works = tree.recommendedWorks ?? '-';
                return [
                  'T$i',
                  works.length > 40 ? works.substring(0, 40) + '...' : works,
                  tree.worksPriority ?? '-',
                  tree.worksTimeframe ?? '-',
                  tree.arboristSupervisionRequired == true ? 'Yes' : 'No',
                ];
              }).toList(),
              headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 8, color: PdfColors.white),
              cellStyle: const pw.TextStyle(fontSize: 7),
              cellHeight: 25,
              headerDecoration: const pw.BoxDecoration(color: PdfColors.brown700),
            ),
            pw.SizedBox(height: 20),
        ]);
      }
      
      // QTRA
      if (exportGroups['qtra'] ?? true) {
        pdfWidgets.addAll([
            pw.Header(level: 1, text: 'QTRA (Quantified Tree Risk)'),
            pw.TableHelper.fromTextArray(
              headers: ['No.', 'Target\nType', 'Occupancy\nRate', 'Impact\nPotential', 'Risk\nRating'],
              data: _trees.asMap().entries.map((entry) {
                final i = entry.key + 1;
                final tree = entry.value;
                return [
                  'T$i',
                  tree.qtraTargetType ?? '-',
                  tree.qtraOccupancyRate ?? '-',
                  tree.qtraImpactPotential ?? '-',
                  tree.qtraRiskRating ?? '-',
                ];
              }).toList(),
              headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 8, color: PdfColors.white),
              cellStyle: const pw.TextStyle(fontSize: 7),
              cellHeight: 25,
              headerDecoration: const pw.BoxDecoration(color: PdfColors.deepOrange700),
            ),
            pw.SizedBox(height: 20),
        ]);
      }
      
      // Impact Assessment
      if (exportGroups['impact_assessment'] ?? true) {
        pdfWidgets.addAll([
            pw.Header(level: 1, text: 'Tree Impact Assessment'),
            pw.TableHelper.fromTextArray(
              headers: ['No.', 'Development\nType', 'Construction\nDistance (m)', 'Root\nEncroachment %', 'Impact\nRating'],
              data: _trees.asMap().entries.map((entry) {
                final i = entry.key + 1;
                final tree = entry.value;
                return [
                  'T$i',
                  tree.developmentType ?? '-',
                  tree.constructionZoneDistance?.toString() ?? '-',
                  tree.rootZoneEncroachmentPercent?.toString() ?? '-',
                  tree.impactRating ?? '-',
                ];
              }).toList(),
              headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 8, color: PdfColors.white),
              cellStyle: const pw.TextStyle(fontSize: 7),
              cellHeight: 25,
              headerDecoration: const pw.BoxDecoration(color: PdfColors.amber800),
            ),
            pw.SizedBox(height: 20),
        ]);
      }
      
      // Ecological Value
      if (exportGroups['ecological'] ?? true) {
        pdfWidgets.addAll([
            pw.Header(level: 1, text: 'Ecological Value'),
            pw.TableHelper.fromTextArray(
              headers: ['No.', 'Wildlife\nHabitat', 'Hollow\nBearing', 'Nesting\nSites', 'Biodiversity\nValue'],
              data: _trees.asMap().entries.map((entry) {
                final i = entry.key + 1;
                final tree = entry.value;
                return [
                  'T$i',
                  tree.wildlifeHabitatValue ?? '-',
                  tree.hollowBearingTree?.toString() ?? '-',
                  tree.nestingSites?.toString() ?? '-',
                  tree.biodiversityValue ?? '-',
                ];
              }).toList(),
              headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 8, color: PdfColors.white),
              cellStyle: const pw.TextStyle(fontSize: 7),
              cellHeight: 25,
              headerDecoration: const pw.BoxDecoration(color: PdfColors.lightGreen700),
            ),
            pw.SizedBox(height: 20),
        ]);
      }
      
      // Regulatory & Compliance
      if (exportGroups['regulatory'] ?? true) {
        pdfWidgets.addAll([
            pw.Header(level: 1, text: 'Regulatory & Compliance'),
            pw.TableHelper.fromTextArray(
              headers: ['No.', 'State\nSignificant', 'Heritage\nListed', 'Significant Tree\nRegister', 'Bushfire\nOverlay'],
              data: _trees.asMap().entries.map((entry) {
                final i = entry.key + 1;
                final tree = entry.value;
                return [
                  'T$i',
                  tree.stateSignificant?.toString() ?? '-',
                  tree.heritageListed?.toString() ?? '-',
                  tree.significantTreeRegister?.toString() ?? '-',
                  tree.bushfireManagementOverlay?.toString() ?? '-',
                ];
              }).toList(),
              headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 8, color: PdfColors.white),
              cellStyle: const pw.TextStyle(fontSize: 7),
              cellHeight: 25,
              headerDecoration: const pw.BoxDecoration(color: PdfColors.red900),
            ),
            pw.SizedBox(height: 20),
        ]);
      }
      
      // Monitoring & Scheduling
      if (exportGroups['monitoring'] ?? true) {
        pdfWidgets.addAll([
            pw.Header(level: 1, text: 'Monitoring & Scheduling'),
            pw.TableHelper.fromTextArray(
              headers: ['No.', 'Next\nInspection', 'Inspection\nFrequency', 'Monitoring\nRequired', 'Alert\nLevel'],
              data: _trees.asMap().entries.map((entry) {
                final i = entry.key + 1;
                final tree = entry.value;
                return [
                  'T$i',
                  tree.nextInspectionDate?.toString().split(' ')[0] ?? '-',
                  tree.inspectionFrequency ?? '-',
                  tree.monitoringRequired?.toString() ?? '-',
                  tree.alertLevel ?? '-',
                ];
              }).toList(),
              headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 8, color: PdfColors.white),
              cellStyle: const pw.TextStyle(fontSize: 7),
              cellHeight: 25,
              headerDecoration: const pw.BoxDecoration(color: PdfColors.cyan700),
            ),
            pw.SizedBox(height: 20),
        ]);
      }
      
      // Photos & Documentation
      if (exportGroups['photos'] ?? true) {
        pdfWidgets.addAll([
            pw.Header(level: 1, text: 'Photos & Documentation'),
            pw.TableHelper.fromTextArray(
              headers: ['No.', 'Image\nCount', 'Image\nPaths'],
              data: _trees.asMap().entries.map((entry) {
                final i = entry.key + 1;
                final tree = entry.value;
                return [
                  'T$i',
                  tree.imageLocalPaths.length.toString(),
                  tree.imageLocalPaths.take(2).join(', ') + (tree.imageLocalPaths.length > 2 ? '...' : ''),
                ];
              }).toList(),
              headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 8, color: PdfColors.white),
              cellStyle: const pw.TextStyle(fontSize: 7),
              cellHeight: 25,
              headerDecoration: const pw.BoxDecoration(color: PdfColors.purple700),
            ),
            pw.SizedBox(height: 20),
        ]);
      }
      
      // Voice Notes
      if (exportGroups['voice_notes'] ?? true) {
        pdfWidgets.addAll([
            pw.Header(level: 1, text: 'Voice Notes & Audio'),
            pw.TableHelper.fromTextArray(
              headers: ['No.', 'Voice\nNotes', 'Audio\nFile'],
              data: _trees.asMap().entries.map((entry) {
                final i = entry.key + 1;
                final tree = entry.value;
                final notes = tree.voiceNotes ?? '';
                return [
                  'T$i',
                  notes.length > 50 ? notes.substring(0, 50) + '...' : (notes.isEmpty ? '-' : notes),
                  tree.voiceNoteAudioPath?.isNotEmpty == true ? 'Yes' : 'No',
                ];
              }).toList(),
              headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 8, color: PdfColors.white),
              cellStyle: const pw.TextStyle(fontSize: 7),
              cellHeight: 25,
              headerDecoration: const pw.BoxDecoration(color: PdfColors.indigo700),
            ),
            pw.SizedBox(height: 20),
        ]);
      }
      
      // VTA Details (if enabled)
      if (exportGroups['vta'] ?? true) {
        pdfWidgets.addAll([
            pw.Header(level: 1, text: 'VTA Detailed Assessment'),
            pw.TableHelper.fromTextArray(
              headers: ['No.', 'Cavity', 'Decay', 'Fungal', 'Cracks', 'Dead Wood %', 'Root\nDamage'],
              data: _trees.asMap().entries.map((entry) {
                final i = entry.key + 1;
                final tree = entry.value;
                return [
                  'T$i',
                  tree.cavityPresent == true ? 'Yes' : 'No',
                  tree.decayExtent ?? '-',
                  tree.fungalFruitingBodies == true ? 'Yes' : 'No',
                  tree.cracksSplits == true ? 'Yes' : 'No',
                  tree.deadWoodPercent?.toString() ?? '-',
                  tree.rootDamage == true ? 'Yes' : 'No',
                ];
              }).toList(),
              headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 8, color: PdfColors.white),
              cellStyle: const pw.TextStyle(fontSize: 7),
              cellHeight: 25,
              headerDecoration: const pw.BoxDecoration(color: PdfColors.brown700),
            ),
            pw.SizedBox(height: 20),
        ]);
      }
      
      // Development Compliance Details
      if (exportGroups['development'] ?? true) {
        pdfWidgets.addAll([
            pw.Header(level: 1, text: 'Development Compliance Details'),
            pw.TableHelper.fromTextArray(
              headers: ['No.', 'Heritage\nOverlay', 'VPO', 'Local Law\nProtected', 'Arborist\nReport Req.'],
              data: _trees.asMap().entries.map((entry) {
                final i = entry.key + 1;
                final tree = entry.value;
                return [
                  'T$i',
                  tree.heritageOverlay == true ? 'Yes' : 'No',
                  tree.vegetationProtectionOverlay == true ? 'Yes' : 'No',
                  tree.localLawProtected == true ? 'Yes' : 'No',
                  tree.arboristReportRequired == true ? 'Yes' : 'No',
                ];
              }).toList(),
              headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 8, color: PdfColors.white),
              cellStyle: const pw.TextStyle(fontSize: 7),
              cellHeight: 25,
              headerDecoration: const pw.BoxDecoration(color: PdfColors.blueGrey800),
            ),
            pw.SizedBox(height: 20),
        ]);
      }
      
      // Tree Valuation (if enabled)
      if (exportGroups['valuation'] ?? false) {
        pdfWidgets.addAll([
            pw.Header(level: 1, text: 'Tree Valuation'),
            pw.TableHelper.fromTextArray(
              headers: ['No.', 'Method', 'Base\nValue', 'Total\nValuation', 'Valuation\nDate'],
              data: _trees.asMap().entries.map((entry) {
                final i = entry.key + 1;
                final tree = entry.value;
                return [
                  'T$i',
                  tree.valuationMethod ?? '-',
                  tree.baseValue?.toString() ?? '-',
                  tree.totalValuation?.toString() ?? '-',
                  tree.valuationDate?.toString().split(' ')[0] ?? '-',
                ];
              }).toList(),
              headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 8, color: PdfColors.white),
              cellStyle: const pw.TextStyle(fontSize: 7),
              cellHeight: 25,
              headerDecoration: const pw.BoxDecoration(color: PdfColors.green900),
            ),
            pw.SizedBox(height: 20),
        ]);
      }
      
      // Advanced Diagnostics (if enabled)
      if (exportGroups['diagnostics'] ?? false) {
        pdfWidgets.addAll([
            pw.Header(level: 1, text: 'Advanced Diagnostics'),
            pw.TableHelper.fromTextArray(
              headers: ['No.', 'Resistograph', 'Sonic\nTomography', 'Pulling\nTest', 'Specialist'],
              data: _trees.asMap().entries.map((entry) {
                final i = entry.key + 1;
                final tree = entry.value;
                return [
                  'T$i',
                  tree.resistographTest == true ? 'Done' : 'No',
                  tree.sonicTomography == true ? 'Done' : 'No',
                  tree.pullingTest == true ? 'Done' : 'No',
                  tree.specialistConsultant ?? '-',
                ];
              }).toList(),
              headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 8, color: PdfColors.white),
              cellStyle: const pw.TextStyle(fontSize: 7),
              cellHeight: 25,
              headerDecoration: const pw.BoxDecoration(color: PdfColors.pink700),
            ),
            pw.SizedBox(height: 20),
        ]);
      }
      
      // Inspector Details
      if (exportGroups['inspector_details'] ?? true) {
        pdfWidgets.addAll([
            pw.Header(level: 1, text: 'Inspector & Report Details'),
            pw.TableHelper.fromTextArray(
              headers: ['No.', 'Inspector\nName', 'Inspection\nDate', 'Sync\nStatus'],
              data: _trees.asMap().entries.map((entry) {
                final i = entry.key + 1;
                final tree = entry.value;
                return [
                  'T$i',
                  tree.inspectorName ?? '-',
                  tree.inspectionDate?.toString().split(' ')[0] ?? '-',
                  tree.syncStatus ?? '-',
                ];
              }).toList(),
              headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 8, color: PdfColors.white),
              cellStyle: const pw.TextStyle(fontSize: 7),
              cellHeight: 25,
              headerDecoration: const pw.BoxDecoration(color: PdfColors.grey800),
            ),
            pw.SizedBox(height: 20),
        ]);
      }
      
      // Add all collected widgets to the PDF
      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          build: (context) => pdfWidgets,
        ),
      );

      // Save PDF
      final bytes = await pdf.save();
      final filename = '${widget.site.name.replaceAll(' ', '_')}_site_plan_${DateTime.now().millisecondsSinceEpoch}.pdf';
      
      print('📊 PDF generated: ${bytes.length} bytes');
      
      // Download file
      await downloadFile(bytes, 'export.file', 'application/pdf');
      print('✅ PDF downloaded');
      
      // Save to Files tab
      try {
        await _saveToFilesTab(
          filename: filename,
          content: String.fromCharCodes(bytes),
          fileType: 'application/pdf',
          category: 'Reports',
          description: 'PDF site plan with tree inventory table',
        );
        print('✅ File saved to Files tab');
      } catch (e) {
        print('⚠️ Could not save to Files tab: $e');
      }
      
      // Close loading dialog
      Navigator.pop(context);
      
      // Show success
      final enabledGroups = pdfWidgets.length > 5 ? '${(pdfWidgets.length - 5) ~/ 3} sections' : 'basic info';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('✅ PDF exported with $enabledGroups!\n\n$filename\n\n• Downloaded to computer\n• Saved to Files tab (click refresh icon)'),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 5),
        ),
      );
      
      print('✅ PDF export complete');
    } catch (e) {
      Navigator.pop(context); // Close loading
      print('❌ PDF export error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ PDF export failed: $e'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 5),
        ),
      );
    }
  }

  Future<void> _exportAsKML() async {
    try {
      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: Card(
            child: Padding(
              padding: EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Exporting KML...'),
                ],
              ),
            ),
          ),
        ),
      );

      // Generate KML file with tree locations
      final kmlContent = _generateKML();
      final filename = '${widget.site.name.replaceAll(' ', '_')}_trees_${DateTime.now().millisecondsSinceEpoch}.kml';
      
      print('📤 Exporting KML: $filename');
      print('📊 Content size: ${kmlContent.length} bytes');
      
      // Download file
      _downloadFile(filename, kmlContent, 'application/vnd.google-earth.kml+xml');
      print('✅ File downloaded to browser');
      
      // Save to Files tab
      await _saveToFilesTab(
        filename: filename,
        content: kmlContent,
        fileType: 'application/vnd.google-earth.kml+xml',
        category: 'Site Maps',
        description: 'KML export of tree locations for Google Earth',
      );
      print('✅ File saved to Files tab');
      
      // Close loading dialog
      Navigator.pop(context);
      
      // Show success dialog with file locations
      _showExportSuccessDialog(
        filename: filename,
        fileType: 'KML',
        fileSize: kmlContent.length,
        locations: [
          '📥 Downloads folder on your computer',
          '📁 Files tab → Site Maps category',
        ],
      );
    } catch (e) {
      Navigator.pop(context); // Close loading dialog
      print('❌ Export error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Export failed: $e'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 5),
        ),
      );
    }
  }

  Future<void> _exportTreeDataCSV() async {
    try {
      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: Card(
            child: Padding(
              padding: EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Exporting CSV...'),
                ],
              ),
            ),
          ),
        ),
      );

      // Generate CSV with tree data including coordinates
      final csvContent = _generateTreeCSV();
      final filename = '${widget.site.name.replaceAll(' ', '_')}_trees_${DateTime.now().millisecondsSinceEpoch}.csv';
      
      print('📤 Exporting CSV: $filename');
      print('📊 Content size: ${csvContent.length} bytes');
      print('📊 Trees exported: ${_trees.length}');
      
      // Download file
      _downloadFile(filename, csvContent, 'text/csv');
      print('✅ File downloaded to browser');
      
      // Save to Files tab
      try {
        await _saveToFilesTab(
          filename: filename,
          content: csvContent,
          fileType: 'text/csv',
          category: 'Tree Data',
          description: 'CSV export of tree inventory with GPS coordinates',
        );
        print('✅ File saved to Files tab');
      } catch (e) {
        print('⚠️ Could not save to Files tab: $e');
      }
      
      // Close loading dialog
      Navigator.pop(context);
      
      // Show success message  
      final csvExportGroups = _trees.isNotEmpty 
          ? Map<String, bool>.from(_trees.first.exportGroups)
          : <String, bool>{};
      final enabledCount = csvExportGroups.values.where((v) => v == true).length;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('✅ CSV exported with $enabledCount enabled groups!\n\n$filename\n\n• Downloaded to computer\n• Saved to Files tab (click refresh icon)'),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 5),
        ),
      );
    } catch (e) {
      Navigator.pop(context); // Close loading dialog
      print('❌ Export error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Export failed: $e'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 5),
        ),
      );
    }
  }

  void _showExportSuccessDialog({
    required String filename,
    required String fileType,
    required int fileSize,
    required List<String> locations,
  }) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green, size: 32),
            const SizedBox(width: 12),
            const Text('Export Successful!'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              filename,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
            const SizedBox(height: 8),
            Text('Type: $fileType'),
            Text('Size: ${(fileSize / 1024).toStringAsFixed(1)} KB'),
            const SizedBox(height: 16),
            const Text(
              'File saved to:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            ...locations.map((loc) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text('• $loc'),
            )),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pop(context);
                // TODO: Navigate to Files tab
              },
              icon: const Icon(Icons.folder),
              label: const Text('Go to Files Tab'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _saveToFilesTab({
    required String filename,
    required String content,
    required String fileType,
    required String category,
    required String description,
  }) async {
    print('💾 Saving to Files tab: $filename');
    print('   Category: $category');
    print('   Size: ${content.length} bytes');
    
    try {
      const uuid = Uuid();
      final bytes = utf8.encode(content);
      
      // Create a data URL for web (since we can't save actual files in web)
      final dataUrl = 'data:$fileType;base64,${base64.encode(bytes)}';
      
      // Ensure service is initialized
      await SiteFileService.init();
      
      final siteFile = SiteFile(
        id: uuid.v4(),
        siteId: widget.site.id,
        fileName: filename,
        originalName: filename,
        filePath: dataUrl, // Store as data URL for web
        fileUrl: dataUrl,
        fileType: fileType,
        fileSize: bytes.length,
        uploadDate: DateTime.now(),
        uploadedBy: 'System (Export)',
        description: description,
        category: category,
        isSynced: false,
      );
      
      await SiteFileService.addFile(siteFile);
      print('✅ File saved to Hive successfully');
    } catch (e, stackTrace) {
      print('❌ Failed to save to Files tab: $e');
      print('   Stack trace: $stackTrace');
      rethrow;
    }
  }

  String _generateKML() {
    print('🌳 Generating KML for ${_trees.length} trees');
    final buffer = StringBuffer();
    buffer.writeln('<?xml version="1.0" encoding="UTF-8"?>');
    buffer.writeln('<kml xmlns="http://www.opengis.net/kml/2.2">');
    buffer.writeln('  <Document>');
    buffer.writeln('    <name>${widget.site.name} - Tree Locations</name>');
    buffer.writeln('    <description>Generated by Arborist Assistant</description>');
    
    final treesWithCoords = _trees.where((t) => t.latitude != null && t.longitude != null).toList();
    print('🌳 ${treesWithCoords.length} trees have coordinates');
    
    for (var i = 0; i < treesWithCoords.length; i++) {
      final tree = treesWithCoords[i];
      final treeNum = i + 1; // Start from 1
      buffer.writeln('    <Placemark>');
      buffer.writeln('      <name>Tree $treeNum</name>');
      buffer.writeln('      <description>');
      buffer.writeln('        Species: ${tree.species ?? "Unknown"}\\n');
      buffer.writeln('        DSH: ${tree.dsh ?? "?"} cm\\n');
      buffer.writeln('        Height: ${tree.height ?? "?"} m\\n');
      buffer.writeln('        Condition: ${tree.condition ?? "Unknown"}');
      buffer.writeln('      </description>');
      buffer.writeln('      <Point>');
      buffer.writeln('        <coordinates>${tree.longitude},${tree.latitude},0</coordinates>');
      buffer.writeln('      </Point>');
      buffer.writeln('    </Placemark>');
    }
    
    buffer.writeln('  </Document>');
    buffer.writeln('</kml>');
    print('✅ KML generated: ${buffer.length} characters');
    return buffer.toString();
  }

  String _generateTreeCSV() {
    print('🌳 Generating CSV for ${_trees.length} trees based on export groups');
    final buffer = StringBuffer();
    
    // Determine which columns to include based on first tree's export groups
    // (assuming all trees in site use same export preferences)
    final exportGroups = _trees.isNotEmpty 
        ? Map<String, bool>.from(_trees.first.exportGroups) 
        : <String, bool>{};
    
    // Build header dynamically based on enabled groups
    List<String> headers = ['Tree_ID'];
    
    // Photos & Documentation
    if (exportGroups['photos'] ?? true) {
      headers.addAll(['Image_Local_Paths', 'Image_URLs', 'Photo_Count']);
    }
    
    // Voice Notes & Audio
    if (exportGroups['voice_notes'] ?? true) {
      headers.addAll(['Voice_Notes', 'Voice_Audio_Path', 'Voice_Audio_URL']);
    }
    
    // Basic Data
    if (exportGroups['basic_data'] ?? true) {
      headers.addAll(['Species', 'DSH_cm', 'Height_m', 'Age_Class', 'Condition', 'Canopy_Spread_m', 'Clearance_To_Structures_m', 'Origin', 'Past_Management', 'Permit_Required', 'Comments']);
    }
    
    // Location
    if (exportGroups['location'] ?? true) {
      headers.addAll(['Location_Description', 'Latitude', 'Longitude', 'Site_Type', 'Land_Use_Zone', 'Soil_Type', 'Soil_Compaction', 'Drainage', 'Site_Slope', 'Aspect', 'Proximity_To_Buildings_m', 'Proximity_To_Services']);
    }
    
    // Health Assessment
    if (exportGroups['health'] ?? true) {
      headers.addAll(['Vigor_Rating', 'Foliage_Density', 'Foliage_Color', 'Dieback_Percent', 'Stress_Indicators', 'Growth_Rate', 'Seasonal_Condition', 'Health_Form', 'Pest_Presence']);
    }
    
    // Structure
    if (exportGroups['structure'] ?? true) {
      headers.addAll(['Crown_Form', 'Crown_Density', 'Branch_Structure', 'Trunk_Form', 'Trunk_Lean', 'Lean_Direction', 'Root_Plate_Condition', 'Buttress_Roots', 'Surface_Roots', 'Included_Bark', 'Included_Bark_Location', 'Structural_Defects', 'Structural_Rating']);
    }
    
    // Protection Zones
    if (exportGroups['protection_zones'] ?? true) {
      headers.addAll(['TPZ_Area_m2', 'SRZ_m', 'NRZ_m']);
    }
    
    // VTA
    if (exportGroups['vta'] ?? true) {
      headers.addAll(['Cavity_Present', 'Cavity_Size', 'Cavity_Location', 'Decay_Extent', 'Decay_Type', 'Fungal_Fruiting_Bodies', 'Fungal_Species', 'Bark_Damage_%', 'Bark_Damage_Type', 'Cracks_Splits', 'Cracks_Location', 'Dead_Wood_%', 'Girdling_Roots', 'Girdling_Severity', 'Root_Damage', 'Root_Damage_Description', 'Mechanical_Damage', 'Mechanical_Damage_Description', 'VTA_Notes', 'VTA_Defects', 'Diseases_Present']);
    }
    
    // ISA Risk
    if (exportGroups['isa_risk'] ?? true) {
      headers.addAll(['Target_Occupancy', 'Defects_Observed', 'Likelihood_Failure', 'Likelihood_Impact', 'Consequence_Failure', 'Overall_Risk_Rating', 'Risk_Rating']);
    }
    
    // Development Compliance
    if (exportGroups['development'] ?? true) {
      headers.addAll(['Planning_Permit_Required', 'Planning_Permit_Number', 'Planning_Permit_Status', 'Planning_Overlay', 'Heritage_Overlay', 'Significant_Landscape_Overlay', 'Vegetation_Protection_Overlay', 'Local_Law_Protected', 'Local_Law_Reference', 'AS4970_Compliant', 'Arborist_Report_Required', 'Council_Notification', 'Neighbor_Notification']);
    }
    
    // Retention & Removal
    if (exportGroups['retention_removal'] ?? true) {
      headers.addAll(['Retention_Value', 'Retention_Recommendation', 'Retention_Justification', 'Removal_Justification', 'Significance', 'Replanting_Required', 'Replacement_Ratio', 'Offset_Requirements']);
    }
    
    // Management & Works
    if (exportGroups['management'] ?? true) {
      headers.addAll(['Recommended_Works', 'Pruning_Type', 'Pruning_Specification', 'Works_Priority', 'Works_Timeframe', 'Estimated_Cost', 'Access_Requirements', 'Arborist_Supervision_Required', 'Tree_Protection_Measures', 'Post_Works_Monitoring', 'Post_Works_Monitoring_Frequency', 'Works_Completion_Date', 'Works_Compliance']);
    }
    
    // QTRA
    if (exportGroups['qtra'] ?? true) {
      headers.addAll(['QTRA_Target_Type', 'QTRA_Target_Value', 'QTRA_Occupancy_Rate', 'QTRA_Impact_Potential', 'QTRA_Probability_Failure', 'QTRA_Probability_Impact', 'QTRA_Risk_Of_Harm', 'QTRA_Risk_Rating']);
    }
    
    // Impact Assessment
    if (exportGroups['impact_assessment'] ?? true) {
      headers.addAll(['Development_Type', 'Construction_Distance_m', 'Root_Encroachment_%', 'Canopy_Encroachment_%', 'Excavation_Impact', 'Service_Installation_Impact', 'Service_Installation_Description', 'Demolition_Impact', 'Demolition_Description', 'Access_Route_Impact', 'Access_Route_Description', 'Impact_Rating', 'Mitigation_Measures']);
    }
    
    // Valuation
    if (exportGroups['valuation'] ?? false) {
      headers.addAll(['Valuation_Method', 'Base_Value', 'Condition_Factor', 'Location_Factor', 'Contribution_Factor', 'Total_Valuation', 'Valuation_Date', 'Valuer_Name']);
    }
    
    // Ecological Value
    if (exportGroups['ecological'] ?? true) {
      headers.addAll(['Wildlife_Habitat_Value', 'Hollow_Bearing_Tree', 'Nesting_Sites', 'Nesting_Species', 'Habitat_Features', 'Biodiversity_Value', 'Indigenous_Significance', 'Indigenous_Significance_Details', 'Cultural_Heritage', 'Cultural_Heritage_Details', 'Amenity_Value', 'Shade_Provision']);
    }
    
    // Regulatory & Compliance
    if (exportGroups['regulatory'] ?? true) {
      headers.addAll(['State_Significant', 'Heritage_Listed', 'Heritage_Reference', 'Significant_Tree_Register', 'Bushfire_Management_Overlay', 'Environmental_Significance_Overlay', 'Waterway_Protection', 'Threatened_Species_Habitat', 'Insurance_Notification_Required', 'Legal_Liability_Assessment', 'Compliance_Notes']);
    }
    
    // Monitoring & Scheduling
    if (exportGroups['monitoring'] ?? true) {
      headers.addAll(['Next_Inspection_Date', 'Inspection_Frequency', 'Monitoring_Required', 'Monitoring_Focus', 'Alert_Level', 'Follow_Up_Actions', 'Compliance_Check_Date']);
    }
    
    // Advanced Diagnostics
    if (exportGroups['diagnostics'] ?? false) {
      headers.addAll(['Resistograph_Test', 'Resistograph_Date', 'Resistograph_Results', 'Sonic_Tomography', 'Sonic_Tomography_Date', 'Sonic_Tomography_Results', 'Pulling_Test', 'Pulling_Test_Date', 'Pulling_Test_Results', 'Root_Collar_Excavation', 'Root_Collar_Findings', 'Soil_Testing', 'Soil_Testing_Results', 'Pathology_Report', 'Diagnostic_Images', 'Specialist_Consultant', 'Diagnostic_Summary']);
    }
    
    // Inspector Details
    if (exportGroups['inspector_details'] ?? true) {
      headers.addAll(['Inspector_Name', 'Inspection_Date', 'Sync_Status', 'Notes']);
    }
    
    buffer.writeln(headers.join(','));
    
    for (var i = 0; i < _trees.length; i++) {
      final tree = _trees[i];
      final treeNum = i + 1;
      final treeExportGroups = Map<String, bool>.from(tree.exportGroups);
      
      // Helper function to escape CSV values
      String csv(dynamic value) {
        if (value == null) return '';
        final str = value.toString();
        if (str.contains(',') || str.contains('"') || str.contains('\n')) {
          return '"${str.replaceAll('"', '""')}"';
        }
        return str;
      }
      
      // Build row dynamically based on enabled groups (matching header order)
      List<String> rowValues = ['T$treeNum'];
      
      if (treeExportGroups['photos'] ?? true) {
        rowValues.addAll([
          csv(tree.imageLocalPaths.join(';')), 
          csv(tree.imageUrls.join(';')), 
          csv(tree.imageLocalPaths.length)
        ]);
      }
      
      if (treeExportGroups['voice_notes'] ?? true) {
        rowValues.addAll([
          csv(tree.voiceNotes), 
          csv(tree.voiceNoteAudioPath), 
          csv(tree.voiceAudioUrl)
        ]);
      }
      
      if (treeExportGroups['basic_data'] ?? true) {
        rowValues.addAll([
          csv(tree.species), csv(tree.dsh), csv(tree.height), csv(tree.ageClass),
          csv(tree.condition), csv(tree.canopySpread), csv(tree.clearanceToStructures),
          csv(tree.origin), csv(tree.pastManagement), csv(tree.permitRequired), csv(tree.comments)
        ]);
      }
      
      if (treeExportGroups['location'] ?? true) {
        rowValues.addAll([
          csv(tree.locationDescription), csv(tree.latitude), csv(tree.longitude),
          csv(tree.siteType), csv(tree.landUseZone), csv(tree.soilType), csv(tree.soilCompaction),
          csv(tree.drainage), csv(tree.siteSlope), csv(tree.aspect), 
          csv(tree.proximityToBuildings), csv(tree.proximityToServices)
        ]);
      }
      
      if (treeExportGroups['health'] ?? true) {
        rowValues.addAll([
          csv(tree.vigorRating), csv(tree.foliageDensity), csv(tree.foliageColor),
          csv(tree.diebackPercent), csv(tree.stressIndicators.join(';')), csv(tree.growthRate), 
          csv(tree.seasonalCondition), csv(tree.healthForm), csv(tree.pestPresence)
        ]);
      }
      
      if (treeExportGroups['structure'] ?? true) {
        rowValues.addAll([
          csv(tree.crownForm), csv(tree.crownDensity), csv(tree.branchStructure),
          csv(tree.trunkForm), csv(tree.trunkLean), csv(tree.leanDirection), csv(tree.rootPlateCondition),
          csv(tree.buttressRoots), csv(tree.surfaceRoots), csv(tree.includedBark), 
          csv(tree.includedBarkLocation), csv(tree.structuralDefects.join(';')), csv(tree.structuralRating)
        ]);
      }
      
      if (treeExportGroups['protection_zones'] ?? true) {
        rowValues.addAll([csv(tree.tpzArea), csv(tree.srz), csv(tree.nrz)]);
      }
      
      if (treeExportGroups['vta'] ?? true) {
        rowValues.addAll([
          csv(tree.cavityPresent), csv(tree.cavitySize), csv(tree.cavityLocation),
          csv(tree.decayExtent), csv(tree.decayType), csv(tree.fungalFruitingBodies), csv(tree.fungalSpecies),
          csv(tree.barkDamagePercent), csv(tree.barkDamageType.join(';')), csv(tree.cracksSplits), csv(tree.cracksSplitsLocation),
          csv(tree.deadWoodPercent), csv(tree.girdlingRoots), csv(tree.girdlingRootsSeverity),
          csv(tree.rootDamage), csv(tree.rootDamageDescription), csv(tree.mechanicalDamage), csv(tree.mechanicalDamageDescription),
          csv(tree.vtaNotes), csv(tree.vtaDefects.join(';')), csv(tree.diseasesPresent)
        ]);
      }
      
      if (treeExportGroups['isa_risk'] ?? true) {
        rowValues.addAll([
          csv(tree.targetOccupancy), csv(tree.defectsObserved.join(';')),
          csv(tree.likelihoodOfFailure), csv(tree.likelihoodOfImpact),
          csv(tree.consequenceOfFailure), csv(tree.overallRiskRating), csv(tree.riskRating)
        ]);
      }
      
      if (treeExportGroups['development'] ?? true) {
        rowValues.addAll([
          csv(tree.planningPermitRequired), csv(tree.planningPermitNumber), csv(tree.planningPermitStatus),
          csv(tree.planningOverlay), csv(tree.heritageOverlay), csv(tree.significantLandscapeOverlay),
          csv(tree.vegetationProtectionOverlay), csv(tree.localLawProtected), csv(tree.localLawReference),
          csv(tree.as4970Compliant), csv(tree.arboristReportRequired), csv(tree.councilNotification), csv(tree.neighborNotification)
        ]);
      }
      
      if (treeExportGroups['retention_removal'] ?? true) {
        rowValues.addAll([
          csv(tree.retentionValue), csv(tree.retentionRecommendation), csv(tree.retentionJustification),
          csv(tree.removalJustification), csv(tree.significance), csv(tree.replantingRequired),
          csv(tree.replacementRatio), csv(tree.offsetRequirements)
        ]);
      }
      
      if (treeExportGroups['management'] ?? true) {
        rowValues.addAll([
          csv(tree.recommendedWorks), csv(tree.pruningType.join(';')), csv(tree.pruningSpecification),
          csv(tree.worksPriority), csv(tree.worksTimeframe), csv(tree.estimatedCostRange),
          csv(tree.accessRequirements.join(';')), csv(tree.arboristSupervisionRequired),
          csv(tree.treeProtectionMeasures), csv(tree.postWorksMonitoring), csv(tree.postWorksMonitoringFrequency),
          csv(tree.worksCompletionDate), csv(tree.worksCompliance)
        ]);
      }
      
      if (treeExportGroups['qtra'] ?? true) {
        rowValues.addAll([
          csv(tree.qtraTargetType), csv(tree.qtraTargetValue), csv(tree.qtraOccupancyRate),
          csv(tree.qtraImpactPotential), csv(tree.qtraProbabilityOfFailure), csv(tree.qtraProbabilityOfImpact),
          csv(tree.qtraRiskOfHarm), csv(tree.qtraRiskRating)
        ]);
      }
      
      if (treeExportGroups['impact_assessment'] ?? true) {
        rowValues.addAll([
          csv(tree.developmentType), csv(tree.constructionZoneDistance), csv(tree.rootZoneEncroachmentPercent),
          csv(tree.canopyEncroachmentPercent), csv(tree.excavationImpact), csv(tree.serviceInstallationImpact),
          csv(tree.serviceInstallationDescription), csv(tree.demolitionImpact), csv(tree.demolitionDescription),
          csv(tree.accessRouteImpact), csv(tree.accessRouteDescription), csv(tree.impactRating), csv(tree.mitigationMeasures)
        ]);
      }
      
      if (treeExportGroups['valuation'] ?? false) {
        rowValues.addAll([
          csv(tree.valuationMethod), csv(tree.baseValue), csv(tree.conditionFactor),
          csv(tree.locationFactor), csv(tree.contributionFactor), csv(tree.totalValuation),
          csv(tree.valuationDate), csv(tree.valuerName)
        ]);
      }
      
      if (treeExportGroups['ecological'] ?? true) {
        rowValues.addAll([
          csv(tree.wildlifeHabitatValue), csv(tree.hollowBearingTree), csv(tree.nestingSites),
          csv(tree.nestingSpecies), csv(tree.habitatFeatures.join(';')), csv(tree.biodiversityValue),
          csv(tree.indigenousSignificance), csv(tree.indigenousSignificanceDetails),
          csv(tree.culturalHeritage), csv(tree.culturalHeritageDetails), csv(tree.amenityValue), csv(tree.shadeProvision)
        ]);
      }
      
      if (treeExportGroups['regulatory'] ?? true) {
        rowValues.addAll([
          csv(tree.stateSignificant), csv(tree.heritageListed), csv(tree.heritageReference),
          csv(tree.significantTreeRegister), csv(tree.bushfireManagementOverlay), csv(tree.environmentalSignificanceOverlay),
          csv(tree.waterwayProtection), csv(tree.threatenedSpeciesHabitat), csv(tree.insuranceNotificationRequired),
          csv(tree.legalLiabilityAssessment), csv(tree.complianceNotes)
        ]);
      }
      
      if (treeExportGroups['monitoring'] ?? true) {
        rowValues.addAll([
          csv(tree.nextInspectionDate), csv(tree.inspectionFrequency), csv(tree.monitoringRequired),
          csv(tree.monitoringFocus.join(';')), csv(tree.alertLevel), csv(tree.followUpActions), csv(tree.complianceCheckDate)
        ]);
      }
      
      if (treeExportGroups['diagnostics'] ?? false) {
        rowValues.addAll([
          csv(tree.resistographTest), csv(tree.resistographDate), csv(tree.resistographResults),
          csv(tree.sonicTomography), csv(tree.sonicTomographyDate), csv(tree.sonicTomographyResults),
          csv(tree.pullingTest), csv(tree.pullingTestDate), csv(tree.pullingTestResults),
          csv(tree.rootCollarExcavation), csv(tree.rootCollarFindings), csv(tree.soilTesting), csv(tree.soilTestingResults),
          csv(tree.pathologyReport), csv(tree.diagnosticImages.join(';')), csv(tree.specialistConsultant), csv(tree.diagnosticSummary)
        ]);
      }
      
      if (treeExportGroups['inspector_details'] ?? true) {
        rowValues.addAll([
          csv(tree.inspectorName), csv(tree.inspectionDate), csv(tree.syncStatus), csv(tree.notes)
        ]);
      }
      
      buffer.writeln(rowValues.join(','));
    }
    
    print('✅ Comprehensive CSV generated: ${buffer.length} characters, ${_trees.length} trees');
    return buffer.toString();
  }

  Future<void> _exportAsWord() async {
    try {
      print('📄 Starting Word export...');
      
      // Show loading
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );
      
      // Generate the same data as CSV but format as HTML table
      final csvData = _generateTreeCSV();
      final lines = csvData.split('\n');
      
      // Build HTML document with better formatting for Word
      final html = StringBuffer();
      html.writeln('<!DOCTYPE html>');
      html.writeln('<html xmlns:o="urn:schemas-microsoft-com:office:office" xmlns:w="urn:schemas-microsoft-com:office:word">');
      html.writeln('<head>');
      html.writeln('<meta charset="UTF-8">');
      html.writeln('<title>${widget.site.name} - Tree Inventory Report</title>');
      html.writeln('<!--[if gte mso 9]><xml><w:WordDocument><w:View>Print</w:View><w:Zoom>100</w:Zoom></w:WordDocument></xml><![endif]-->');
      html.writeln('<style>');
      html.writeln('body { font-family: Calibri, Arial, sans-serif; margin: 20px; font-size: 11pt; }');
      html.writeln('h1 { color: #2e7d32; font-size: 20pt; margin-bottom: 10px; page-break-after: avoid; }');
      html.writeln('h2 { color: #1b5e20; font-size: 14pt; margin-top: 20px; margin-bottom: 10px; page-break-after: avoid; }');
      html.writeln('.header-info { margin-bottom: 20px; border-bottom: 2px solid #2e7d32; padding-bottom: 10px; }');
      html.writeln('.header-info p { margin: 5px 0; }');
      html.writeln('table { border-collapse: collapse; width: 100%; margin-top: 15px; margin-bottom: 25px; page-break-inside: avoid; }');
      html.writeln('th { background-color: #2e7d32; color: white; padding: 8px; text-align: left; border: 1px solid #2e7d32; font-size: 10pt; white-space: nowrap; }');
      html.writeln('td { padding: 6px 8px; border: 1px solid #cccccc; vertical-align: top; font-size: 10pt; }');
      html.writeln('tr:nth-child(even) { background-color: #f9f9f9; }');
      html.writeln('.section { margin-top: 30px; page-break-inside: avoid; }');
      html.writeln('@media print { .pagebreak { page-break-before: always; } }');
      html.writeln('</style>');
      html.writeln('</head>');
      html.writeln('<body>');
      
      // Header info
      html.writeln('<h1>${widget.site.name} - Tree Inventory Report</h1>');
      html.writeln('<div class="header-info">');
      html.writeln('<p><strong>Site Address:</strong> ${widget.site.address}</p>');
      html.writeln('<p><strong>Location:</strong> ${widget.site.latitude?.toStringAsFixed(6) ?? "N/A"}, ${widget.site.longitude?.toStringAsFixed(6) ?? "N/A"}</p>');
      html.writeln('<p><strong>Total Trees:</strong> ${_trees.length}</p>');
      html.writeln('<p><strong>Report Generated:</strong> ${DateTime.now().toString().split('.')[0]}</p>');
      html.writeln('</div>');
      
      // Get export groups to create sections
      final exportGroups = _trees.isNotEmpty 
          ? Map<String, bool>.from(_trees.first.exportGroups)
          : <String, bool>{};
      
      // Create separate tables for each enabled group with key fields
      int tableCount = 0;
      
      for (var i = 0; i < _trees.length; i++) {
        final tree = _trees[i];
        final treeNum = i + 1;
        
        if (i == 0 || i % 10 == 0) {
          // Close previous table if exists
          if (tableCount > 0) {
            html.writeln('</tbody></table>');
          }
          
          tableCount++;
          html.writeln('<div class="section ${i > 0 ? 'pagebreak' : ''}">');
          html.writeln('<h2>Trees ${i + 1} to ${(i + 10 > _trees.length ? _trees.length : i + 10)}</h2>');
          
          // Basic data table
          html.writeln('<table>');
          html.writeln('<thead><tr>');
          html.writeln('<th style="min-width: 50px;">Tree ID</th>');
          html.writeln('<th style="min-width: 150px;">Species</th>');
          html.writeln('<th style="min-width: 60px;">DSH (cm)</th>');
          html.writeln('<th style="min-width: 70px;">Height (m)</th>');
          html.writeln('<th style="min-width: 80px;">Condition</th>');
          html.writeln('<th style="min-width: 100px;">Risk Rating</th>');
          html.writeln('<th style="min-width: 120px;">Recommended Works</th>');
          html.writeln('<th style="min-width: 200px;">Comments</th>');
          html.writeln('</tr></thead>');
          html.writeln('<tbody>');
        }
        
        // Add row
        html.writeln('<tr>');
        html.writeln('<td><strong>T$treeNum</strong></td>');
        html.writeln('<td>${tree.species ?? '-'}</td>');
        html.writeln('<td>${tree.dsh?.toString() ?? '-'}</td>');
        html.writeln('<td>${tree.height?.toString() ?? '-'}</td>');
        html.writeln('<td>${tree.condition ?? '-'}</td>');
        html.writeln('<td>${tree.riskRating ?? '-'}</td>');
        final works = tree.recommendedWorks ?? '-';
        html.writeln('<td>${works.length > 50 ? works.substring(0, 50) + '...' : works}</td>');
        final comments = tree.comments ?? '-';
        html.writeln('<td>${comments.length > 100 ? comments.substring(0, 100) + '...' : comments}</td>');
        html.writeln('</tr>');
      }
      
      // Close final table
      html.writeln('</tbody></table>');
      html.writeln('</div>');
      
      html.writeln('<p style="margin-top: 30px; font-size: 9pt; color: #666; border-top: 1px solid #ccc; padding-top: 10px;">');
      html.writeln('<em>For complete detailed data including all ${exportGroups.values.where((v) => v == true).length} assessment groups, please refer to the CSV export.</em>');
      html.writeln('</p>');
      
      html.writeln('</body>');
      html.writeln('</html>');
      
      // Save as .doc file (Word can open HTML)
      final htmlString = html.toString();
      final filename = '${widget.site.name.replaceAll(' ', '_')}_tree_inventory_${DateTime.now().millisecondsSinceEpoch}.doc';
      
      _downloadFile(filename, htmlString, 'application/msword');
      
      // Save to Files tab
      try {
        final fileId = '${widget.site.id}_${DateTime.now().millisecondsSinceEpoch}';
        final siteFile = SiteFile(
          id: fileId,
          siteId: widget.site.id,
          fileName: filename,
          originalName: filename,
          filePath: '',
          fileUrl: '',
          fileType: 'application/msword',
          category: 'Reports',
          description: 'Word document export of tree inventory',
          uploadDate: DateTime.now(),
          uploadedBy: 'System',
          fileSize: htmlString.length,
        );
        await SiteFileService.addFile(siteFile);
        print('✅ File saved to Files tab');
      } catch (e) {
        print('⚠️ Could not save to Files tab: $e');
      }
      
      // Close loading
      Navigator.pop(context);
      
      // Show success
      final enabledCount = exportGroups.values.where((v) => v == true).length;
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('✅ Word document exported with $enabledCount enabled groups!\n\n$filename\n\n• Downloaded to computer\n• Saved to Files tab (click refresh icon)'),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 5),
        ),
      );
      
      print('✅ Word export complete');
    } catch (e) {
      Navigator.pop(context); // Close loading
      print('❌ Word export error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Export failed: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
  
  // Helper to parse CSV line (handles quoted commas)
  List<String> _parseCSVLine(String line) {
    final List<String> cells = [];
    final buffer = StringBuffer();
    bool inQuotes = false;
    
    for (int i = 0; i < line.length; i++) {
      final char = line[i];
      
      if (char == '"') {
        inQuotes = !inQuotes;
      } else if (char == ',' && !inQuotes) {
        cells.add(buffer.toString());
        buffer.clear();
      } else {
        buffer.write(char);
      }
    }
    cells.add(buffer.toString());
    
    return cells;
  }

  void _downloadFile(String filename, String content, String mimeType) async {
    final bytes = utf8.encode(content);
    await downloadFile(bytes, "export", mimeType);  }

  void _showMoreOptions() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Map Display Options'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Marker size slider
              ListTile(
                title: const Text('Marker Size'),
                subtitle: Slider(
                  value: _treeMarkerSize,
                  min: 20,
                  max: 50,
                  divisions: 6,
                  label: _treeMarkerSize.round().toString(),
                  onChanged: (value) => setState(() => _treeMarkerSize = value),
                ),
              ),
              // Map opacity slider
              ListTile(
                title: const Text('Map Opacity'),
                subtitle: Slider(
                  value: _mapOpacity,
                  min: 0.3,
                  max: 1.0,
                  divisions: 7,
                  label: '${(_mapOpacity * 100).round()}%',
                  onChanged: (value) => setState(() => _mapOpacity = value),
                ),
              ),
              const Divider(),
              SwitchListTile(
                title: const Text('Show Scale Bar'),
                value: _showScaleBar,
                onChanged: (value) => setState(() => _showScaleBar = value),
              ),
              SwitchListTile(
                title: const Text('Show North Arrow'),
                value: _showNorthArrow,
                onChanged: (value) => setState(() => _showNorthArrow = value),
              ),
              SwitchListTile(
                title: const Text('Show Tree Numbers'),
                value: _showTreeNumbers,
                onChanged: (value) => setState(() => _showTreeNumbers = value),
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.refresh),
                title: const Text('Reset View'),
                subtitle: const Text('Return to site center'),
                onTap: () {
                  Navigator.pop(context);
                  _resetView();
                },
              ),
              ListTile(
                leading: const Icon(Icons.fullscreen),
                title: const Text('Fit All Trees'),
                subtitle: const Text('Zoom to show all trees'),
                onTap: () {
                  Navigator.pop(context);
                  _fitAllTrees();
                },
              ),
            ],
          ),
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

  void _resetView() {
    final center = LatLng(
      widget.site.latitude ?? -37.8136,
      widget.site.longitude ?? 144.9631,
    );
    _mapController.move(center, 19.0);
  }

  void _fitAllTrees() {
    if (_trees.isEmpty) return;
    
    final treesWithCoords = _trees.where((t) => t.latitude != null && t.longitude != null).toList();
    if (treesWithCoords.isEmpty) return;
    
    // Calculate bounds
    double minLat = treesWithCoords.first.latitude!;
    double maxLat = treesWithCoords.first.latitude!;
    double minLng = treesWithCoords.first.longitude!;
    double maxLng = treesWithCoords.first.longitude!;
    
    for (final tree in treesWithCoords) {
      if (tree.latitude! < minLat) minLat = tree.latitude!;
      if (tree.latitude! > maxLat) maxLat = tree.latitude!;
      if (tree.longitude! < minLng) minLng = tree.longitude!;
      if (tree.longitude! > maxLng) maxLng = tree.longitude!;
    }
    
    // Add padding
    final latPadding = (maxLat - minLat) * 0.2;
    final lngPadding = (maxLng - minLng) * 0.2;
    
    // Center and zoom
    final center = LatLng((minLat + maxLat) / 2, (minLng + maxLng) / 2);
    _mapController.move(center, 18.0);
  }
}
