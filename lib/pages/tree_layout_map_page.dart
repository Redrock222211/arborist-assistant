import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:intl/intl.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:math' as math;
import '../services/tree_csv_exporter.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:uuid/uuid.dart';

import '../models/site.dart';
import '../models/site_file.dart';
import '../models/tree_entry.dart';
import '../services/site_file_service.dart';
import '../services/tree_storage_service.dart';
import '../utils/platform_download.dart';

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
  final GlobalKey _mapKey = GlobalKey(debugLabel: 'treeLayoutMap');
  List<TreeEntry> _trees = [];
  bool _isLoading = true;
  LatLng? _lastCenter;
  double? _lastZoom;
  
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
    _lastCenter = LatLng(
      widget.site.latitude ?? -37.8136,
      widget.site.longitude ?? 144.9631,
    );
    _lastZoom = 19.0;
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
    final layout = MediaQuery.of(context);
    final showSidebar = layout.size.width > 1100;

    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Site Map - ${widget.site.name}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.picture_as_pdf),
            tooltip: 'Export Site Map',
            onPressed: _exportAsPDF,
          ),
          IconButton(
            icon: const Icon(Icons.image_outlined),
            tooltip: 'Export as image',
            onPressed: _exportAsImage,
          ),
          IconButton(
            icon: const Icon(Icons.table_chart),
            tooltip: 'Download tree data CSV',
            onPressed: _exportTreeDataCSV,
          ),
        ],
      ),
      body: Row(
        children: [
          SizedBox(
            width: showSidebar ? 280 : 240,
            child: _buildControlPanel(),
          ),
          Expanded(
            child: Stack(
              children: [
                Positioned.fill(
                  child: RepaintBoundary(
                    key: _mapKey,
                    child: FlutterMap(
                      mapController: _mapController,
                      options: MapOptions(
                        initialCenter: _lastCenter!,
                        initialZoom: _lastZoom!,
                        maxZoom: 22.0,
                        minZoom: 14.0,
                        onMapEvent: (event) {
                          try {
                            final camera = _mapController.camera;
                            setState(() {
                              _lastCenter = camera.center;
                              _lastZoom = camera.zoom;
                            });
                          } catch (_) {
                            // Map controller not yet ready; ignore.
                          }
                        },
                      ),
                      children: _buildMapLayers(),
                    ),
                  ),
                ),
                Positioned(
                  top: 16,
                  left: 16,
                  child: _buildMapBadge(),
                ),
                if (_showScaleBar)
                  Positioned(
                    bottom: 24,
                    left: 24,
                    child: _ScaleBar(),
                  ),
                if (_showNorthArrow)
                  Positioned(
                    bottom: 24,
                    right: 24,
                    child: _NorthArrow(),
                  ),
              ],
            ),
          ),
          if (showSidebar)
            SizedBox(
              width: 320,
              child: _buildInsightsPanel(),
            ),
        ],
      ),
      bottomNavigationBar: showSidebar ? null : SizedBox(height: 220, child: _buildInsightsPanel()),
    );
  }

  Widget _ScaleBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.92),
        borderRadius: BorderRadius.circular(999),
        boxShadow: const [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 6,
            offset: Offset(0, 3),
          ),
        ],
        border: Border.all(color: Colors.black12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _ScaleTick(label: '0m'),
          const SizedBox(width: 12),
          const SizedBox(
            width: 48,
            child: Divider(
              thickness: 2,
              color: Colors.black54,
            ),
          ),
          const SizedBox(width: 12),
          _ScaleTick(label: '10m'),
        ],
      ),
    );
  }

  Widget _NorthArrow() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.9),
        shape: BoxShape.circle,
        boxShadow: const [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 6,
            offset: Offset(0, 3),
          ),
        ],
        border: Border.all(color: Colors.black12),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: const [
          Text(
            'N',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          Icon(
            Icons.navigation,
            size: 24,
            color: Colors.black87,
          ),
        ],
      ),
    );
  }

  Widget _ScaleTick({required String label}) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 2,
          height: 12,
          color: Colors.black54,
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }

  Widget _buildControlPanel() {
    return Material(
      color: Colors.grey.shade50,
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Base Map', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _styleChip('Satellite', 'satellite', Icons.satellite_alt),
                  _styleChip('Street', 'street', Icons.map),
                  _styleChip('Hybrid', 'hybrid', Icons.layers),
                ],
              ),
              const SizedBox(height: 24),
              const Text('Layers', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 12),
              _layerSwitch('Show Tree Labels', _showTreeLabels, (value) => setState(() => _showTreeLabels = value)),
              _layerSwitch('Tree Protection Zone (TPZ)', _showProtectionZones, (value) => setState(() => _showProtectionZones = value)),
              _layerSwitch('Structural Root Zone (SRZ)', _showSRZ, (value) => setState(() => _showSRZ = value)),
              _layerSwitch('Canopy Spread', _showCanopyCircles, (value) => setState(() => _showCanopyCircles = value)),
              _layerSwitch('Tree Numbers', _showTreeNumbers, (value) => setState(() => _showTreeNumbers = value)),
              const SizedBox(height: 24),
              const Text('Map Appearance', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 12),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Marker size'),
                subtitle: Slider(
                  value: _treeMarkerSize,
                  min: 24,
                  max: 60,
                  divisions: 6,
                  label: _treeMarkerSize.round().toString(),
                  onChanged: (value) => setState(() => _treeMarkerSize = value),
                ),
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Map brightness'),
                subtitle: Slider(
                  value: _mapOpacity,
                  min: 0.4,
                  max: 1.0,
                  divisions: 6,
                  label: '${(_mapOpacity * 100).round()}%',
                  onChanged: (value) => setState(() => _mapOpacity = value),
                ),
              ),
              _layerSwitch('Grid overlay', _showGrid, (value) => setState(() => _showGrid = value)),
              _layerSwitch('Scale bar', _showScaleBar, (value) => setState(() => _showScaleBar = value)),
              _layerSwitch('North arrow', _showNorthArrow, (value) => setState(() => _showNorthArrow = value)),
              const Divider(height: 32),
              const Text('Colour scheme', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: _colorScheme,
                decoration: const InputDecoration(border: OutlineInputBorder(), isDense: true),
                items: const [
                  DropdownMenuItem(value: 'condition', child: Text('Tree condition')),
                  DropdownMenuItem(value: 'species', child: Text('Species family')),
                  DropdownMenuItem(value: 'health', child: Text('Health/vigor')),
                  DropdownMenuItem(value: 'priority', child: Text('Risk priority')),
                ],
                onChanged: (value) => setState(() => _colorScheme = value ?? 'condition'),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _fitAllTrees,
                icon: const Icon(Icons.zoom_out_map),
                label: const Text('Fit all trees'),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: _resetView,
                icon: const Icon(Icons.refresh),
                label: const Text('Reset view'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMapBadge() {
    return Card(
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _selectedStyle == 'satellite'
                  ? 'Base map: Satellite imagery'
                  : _selectedStyle == 'street'
                      ? 'Base map: Street map'
                      : 'Base map: Hybrid',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            if (_lastCenter != null)
              Text(
                'Center: '
                '${(_lastCenter!.latitude).toStringAsFixed(5)}, '
                '${(_lastCenter!.longitude).toStringAsFixed(5)}',
              ),
            if (_lastZoom != null)
              Text('Zoom: ${_lastZoom!.toStringAsFixed(1)}'),
            const SizedBox(height: 4),
            Text('${_trees.length} trees loaded'),
          ],
        ),
      ),
    );
  }

  Widget _buildInsightsPanel() {
    final totalTrees = _trees.length;
    final labelled = _trees.where((t) => t.species?.isNotEmpty ?? false).length;
    final highRisk = _trees.where((t) => (t.riskRating ?? '').toLowerCase().contains('high')).length;

    return Material(
      color: Colors.white,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Site overview', style: TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text(widget.site.address ?? 'Address not provided'),
            trailing: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(DateFormat('d MMM yyyy').format(DateTime.now())),
                Text('Prepared for: ${widget.site.name}'),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _insightChip(Icons.forest, 'Total trees', totalTrees.toString()),
              _insightChip(Icons.local_florist, 'Identified species', labelled.toString()),
              _insightChip(Icons.warning_amber, 'High risk flags', highRisk.toString()),
            ],
          ),
          const SizedBox(height: 24),
          ExpansionTile(
            initiallyExpanded: true,
            leading: const Icon(Icons.layers_outlined),
            title: const Text('Layer legend'),
            children: [
              Wrap(
                spacing: 16,
                runSpacing: 12,
                children: _getLegendItems(),
              ),
              const SizedBox(height: 16),
            ],
          ),
          const SizedBox(height: 16),
          Card(
            child: ListTile(
              leading: const Icon(Icons.info_outline, color: Colors.blue),
              title: const Text('Export tips'),
              subtitle: const Text('Use the toolbar icons in the app bar to generate PDF, image, or CSV outputs with this site map.'),
            ),
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

  Widget _styleChip(String label, String style, IconData icon) {
    final isSelected = _selectedStyle == style;
    return ChoiceChip(
      avatar: Icon(icon, size: 16, color: isSelected ? Colors.white : Colors.black87),
      label: Text(label),
      selected: isSelected,
      showCheckmark: false,
      labelStyle: TextStyle(color: isSelected ? Colors.white : Colors.black87),
      selectedColor: Colors.deepPurple,
      backgroundColor: Colors.grey.shade200,
      onSelected: (_) => setState(() => _selectedStyle = style),
    );
  }

  Widget _insightChip(IconData icon, String label, String value) {
    return Chip(
      avatar: Icon(icon, size: 16),
      label: Text('$label: $value'),
    );
  }

  Widget _layerSwitch(String label, bool value, ValueChanged<bool> onChanged) {
    return SwitchListTile.adaptive(
      dense: true,
      contentPadding: EdgeInsets.zero,
      title: Text(label),
      value: value,
      onChanged: onChanged,
    );
  }

  List<Widget> _buildMapLayers() {
    final layers = <Widget>[
      Opacity(
        opacity: _mapOpacity,
        child: TileLayer(
          urlTemplate: _getTileUrl(),
          subdomains: const ['a', 'b', 'c'],
        ),
      ),
    ];

    if (_showProtectionZones) {
      layers.addAll(_buildProtectionZones());
    }
    if (_showSRZ) {
      layers.addAll(_buildSRZZones());
    }
    if (_showCanopyCircles) {
      layers.addAll(_buildCanopyCircles());
    }

    layers.addAll(_buildTreeMarkers());
    if (_showTreeLabels) {
      layers.addAll(_buildTreeLabels());
    }

    return layers;
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

      // Capture map
      final boundary = _mapKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Unable to capture map widget.')));
        return;
      }

      await Future.delayed(const Duration(milliseconds: 250));

      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to encode map image.')));
        return;
      }

      final pngBytes = byteData.buffer.asUint8List();
      final filename = 'site_map_${widget.site.name.replaceAll(' ', '_')}_${DateTime.now().millisecondsSinceEpoch}.png';

      await downloadFile(pngBytes, filename, 'image/png');

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
        debugPrint('Could not save map image to Files tab: $e');
      }
      Navigator.pop(context);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Site map exported as $filename')),
      );
    } catch (e) {
      Navigator.pop(context); // Close loading
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Image export failed: $e'),
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
      await downloadFile(bytes, filename, 'application/pdf');
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
      await _downloadFile(filename, kmlContent, 'application/vnd.google-earth.kml+xml');
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
      final csvContent = TreeCsvExporter.generate(
      trees: _trees,
      includePhotos: true,
    );
      final filename = '${widget.site.name.replaceAll(' ', '_')}_trees_${DateTime.now().millisecondsSinceEpoch}.csv';
      
      print('📤 Exporting CSV: $filename');
      print('📊 Content size: ${csvContent.length} bytes');
      print('📊 Trees exported: ${_trees.length}');
      
      // Download file
      await _downloadFile(filename, csvContent, 'text/csv');
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
      
      await _downloadFile(filename, htmlString, 'application/msword');
      
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

  String _generateTreeCSV() {
    return TreeCsvExporter.generate(
      trees: _trees,
      includePhotos: true,
    );
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

  Future<void> _downloadFile(String filename, String content, String mimeType) async {
    final bytes = Uint8List.fromList(utf8.encode(content));
    await downloadFile(bytes, filename, mimeType);
  }

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
