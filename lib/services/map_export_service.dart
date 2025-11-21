import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:intl/intl.dart';
import 'package:latlong2/latlong.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../models/site.dart';
import '../models/tree_entry.dart';
import '../services/tree_storage_service.dart';
import '../utils/platform_download.dart';

class MapExportService {
  static const double _defaultZoom = 18.0;
  static const double _mapWidth = 800.0;
  static const double _mapHeight = 600.0;
  static const double _exportPixelRatio = 2.5;

  static Future<Uint8List?> Function(
    Site site, {
    bool showSRZ,
    bool showNRZ,
    bool showTreeNumbers,
    bool satelliteView,
  })? _captureSiteMapImageOverride;

  static void setCaptureSiteMapImageOverride(
    Future<Uint8List?> Function(
      Site site, {
      bool showSRZ,
      bool showNRZ,
      bool showTreeNumbers,
      bool satelliteView,
    }
  )?
      override,
  ) {
    _captureSiteMapImageOverride = override;
  }

  static void resetOverrides() {
    _captureSiteMapImageOverride = null;
  }

  /// Capture site map as image bytes (for embedding in reports)
  static Future<Uint8List?> captureSiteMapImage(Site site, {
    bool showSRZ = true,
    bool showNRZ = true,
    bool showTreeNumbers = true,
    bool satelliteView = false,
  }) async {
    if (_captureSiteMapImageOverride != null) {
      return _captureSiteMapImageOverride!(
        site,
        showSRZ: showSRZ,
        showNRZ: showNRZ,
        showTreeNumbers: showTreeNumbers,
        satelliteView: satelliteView,
      );
    }

    try {
      final trees = TreeStorageService.getTreesForSite(site.id)
          .where((tree) => tree.latitude != null && tree.longitude != null)
          .toList();
      if (trees.isEmpty) {
        print('⚠️  No trees with coordinates for site: ${site.name}');
        return null;
      }

      print('📸 Rendering site map for ${site.name}...');

      final widget = _buildSiteMapWidget(
        site: site,
        trees: trees,
        showSRZ: showSRZ,
        showNRZ: showNRZ,
        showTreeNumbers: showTreeNumbers,
        satelliteView: satelliteView,
      );

      final bytes = await renderWidgetToImage(
        widget,
        size: const Size(_mapWidth, _mapHeight),
        pixelRatio: _exportPixelRatio,
      );
      print('✅ Site map rendered: ${bytes.length} bytes');
      return bytes;
    } catch (e) {
      print('❌ Error capturing site map: $e');
      return null;
    }
  }
  /// Export site map as PNG with all trees
  static Future<String?> exportSiteMapAsPng(Site site, {
    bool showSRZ = true,
    bool showNRZ = true,
    bool showTreeNumbers = true,
    bool satelliteView = false,
  }) async {
    try {
      final bytes = await captureSiteMapImage(
        site,
        showSRZ: showSRZ,
        showNRZ: showNRZ,
        showTreeNumbers: showTreeNumbers,
        satelliteView: satelliteView,
      );

      if (bytes == null) {
        return null;
      }

      final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
      final baseName = _sanitizeFileComponent(site.name);
      final fileName = '${baseName}_site-map_$timestamp.png';

      if (kIsWeb) {
        await _downloadBytes(bytes, fileName);
        return 'web://$fileName';
      }

      final directory = await getApplicationDocumentsDirectory();
      final folder = Directory('${directory.path}/site_maps');
      if (!await folder.exists()) {
        await folder.create(recursive: true);
      }
      final file = File('${folder.path}/$fileName');
      await file.writeAsBytes(bytes);
      return file.path;
    } catch (e) {
      print('Error exporting site map: $e');
      return null;
    }
  }

  /// Export individual tree map as PNG
  static Future<String?> exportTreeMapAsPng(TreeEntry tree, {
    bool showSRZ = true,
    bool showNRZ = true,
    bool satelliteView = false,
  }) async {
    try {
      if (tree.latitude == null || tree.longitude == null) {
        print('⚠️ Tree ${tree.id} missing coordinates');
        return null;
      }

      final widget = _buildTreeMapWidget(
        tree: tree,
        showSRZ: showSRZ,
        showNRZ: showNRZ,
        satelliteView: satelliteView,
      );

      final bytes = await renderWidgetToImage(
        widget,
        size: const Size(_mapWidth, _mapHeight),
        pixelRatio: _exportPixelRatio,
      );

      final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
      final baseName = _sanitizeFileComponent(tree.id);
      final fileName = 'tree_${baseName}_map_$timestamp.png';

      if (kIsWeb) {
        await _downloadBytes(bytes, fileName);
        return 'web://$fileName';
      }

      final directory = await getApplicationDocumentsDirectory();
      final folder = Directory('${directory.path}/tree_maps');
      if (!await folder.exists()) {
        await folder.create(recursive: true);
      }
      final file = File('${folder.path}/$fileName');
      await file.writeAsBytes(bytes);
      return file.path;
    } catch (e) {
      print('Error exporting tree map: $e');
      return null;
    }
  }

  /// Export all individual tree maps for a site
  static Future<List<String>> exportAllTreeMaps(Site site, {
    bool showSRZ = true,
    bool showNRZ = true,
    bool satelliteView = false,
  }) async {
    final trees = TreeStorageService.getTreesForSite(site.id)
        .where((tree) => tree.latitude != null && tree.longitude != null)
        .toList();
    final paths = <String>[];
    
    for (final tree in trees) {
      final path = await exportTreeMapAsPng(
        tree,
        showSRZ: showSRZ,
        showNRZ: showNRZ,
        satelliteView: satelliteView,
      );
      if (path != null) {
        paths.add(path);
      }
    }
    
    return paths;
  }

  /// Build circle markers for SRZ/NRZ display
  static List<CircleMarker> _buildCircleMarkers(
    List<TreeEntry> trees,
    bool showSRZ,
    bool showNRZ,
  ) {
    final circles = <CircleMarker>[];

    for (final tree in trees) {
      if (showSRZ && tree.srz > 0) {
        circles.add(
          CircleMarker(
            point: LatLng(tree.latitude!, tree.longitude!),
            radius: tree.srz,
            useRadiusInMeter: true,
            color: Colors.red.withOpacity(0.15),
            borderColor: Colors.red,
            borderStrokeWidth: 2,
          ),
        );
      }

      if (showNRZ && tree.nrz > 0) {
        circles.add(
          CircleMarker(
            point: LatLng(tree.latitude!, tree.longitude!),
            radius: tree.nrz,
            useRadiusInMeter: true,
            color: Colors.green.withOpacity(0.15),
            borderColor: Colors.green,
            borderStrokeWidth: 2,
          ),
        );
      }
    }

    return circles;
  }

  /// Render a widget to PNG image bytes
  static Future<Uint8List> renderWidgetToImage(
    Widget widget, {
    Size? size,
    double pixelRatio = _exportPixelRatio,
  }) async {
    final renderSize = size ?? const Size(_mapWidth, _mapHeight);
    final repaintBoundary = RenderRepaintBoundary();

    final pipelineOwner = PipelineOwner();
    final buildOwner = BuildOwner(focusManager: FocusManager());

    final view = WidgetsBinding.instance.platformDispatcher.implicitView ??
        WidgetsBinding.instance.platformDispatcher.views.first;

    final renderView = RenderView(
      view: view,
      configuration: ViewConfiguration(
        logicalConstraints: BoxConstraints.tight(renderSize),
        physicalConstraints: BoxConstraints.tight(renderSize * pixelRatio),
        devicePixelRatio: pixelRatio,
      ),
      child: RenderPositionedBox(
        alignment: Alignment.center,
        child: repaintBoundary,
      ),
    );

    renderView.attach(pipelineOwner);
    renderView.prepareInitialFrame();

    final wrapped = Directionality(
      textDirection: ui.TextDirection.ltr,
      child: MediaQuery(
        data: MediaQueryData(
          size: renderSize,
          devicePixelRatio: pixelRatio,
        ),
        child: Material(
          color: Colors.white,
          child: SizedBox(
            width: renderSize.width,
            height: renderSize.height,
            child: widget,
          ),
        ),
      ),
    );

    final rootElement = RenderObjectToWidgetAdapter<RenderBox>(
      container: repaintBoundary,
      child: wrapped,
    ).attachToRenderTree(buildOwner);

    buildOwner.buildScope(rootElement);
    buildOwner.finalizeTree();

    pipelineOwner.flushLayout();
    pipelineOwner.flushCompositingBits();
    pipelineOwner.flushPaint();

    final image = await repaintBoundary.toImage(pixelRatio: pixelRatio);
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);

    rootElement.detachRenderObject();
    renderView.detach();
    pipelineOwner.dispose();

    return byteData!.buffer.asUint8List();
  }

  static Widget _buildSiteMapWidget({
    required Site site,
    required List<TreeEntry> trees,
    required bool showSRZ,
    required bool showNRZ,
    required bool showTreeNumbers,
    required bool satelliteView,
  }) {
    final center = _calculateCenter(trees, fallback: LatLng(
      site.latitude ?? -37.8136,
      site.longitude ?? 144.9631,
    ));

    final markers = _buildTreeMarkers(trees, showTreeNumbers: showTreeNumbers);
    final circles = _buildCircleMarkers(trees, showSRZ, showNRZ);

    final totalTrees = trees.length;

    return SizedBox(
      width: _mapWidth,
      height: _mapHeight,
      child: Stack(
        children: [
          Positioned.fill(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: FlutterMap(
                options: MapOptions(
                  initialCenter: center,
                  initialZoom: _defaultZoom,
                  interactionOptions: const InteractionOptions(flags: InteractiveFlag.none),
                ),
                children: [
                  TileLayer(
                    urlTemplate: satelliteView
                        ? 'https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}'
                        : 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'com.arboristassistant.app',
                  ),
                  if (circles.isNotEmpty)
                    CircleLayer(
                      circles: circles,
                    ),
                  MarkerLayer(markers: markers),
                ],
              ),
            ),
          ),
          Positioned(
            top: 16,
            left: 16,
            child: _InfoPanel(
              title: site.name,
              subtitle: site.address,
              lines: [
                'Total trees: $totalTrees',
                if (site.notes.isNotEmpty) 'Notes: ${site.notes}',
              ],
            ),
          ),
          Positioned(
            top: 16,
            right: 16,
            child: _LegendPanel(
              showSRZ: showSRZ,
              showNRZ: showNRZ,
            ),
          ),
          const Positioned(
            bottom: 20,
            right: 20,
            child: _NorthArrow(),
          ),
          const Positioned(
            bottom: 20,
            left: 20,
            child: _ScaleBar(),
          ),
        ],
      ),
    );
  }

  static Widget _buildTreeMapWidget({
    required TreeEntry tree,
    required bool showSRZ,
    required bool showNRZ,
    required bool satelliteView,
  }) {
    final center = LatLng(tree.latitude!, tree.longitude!);
    final markers = _buildTreeMarkers([tree], showTreeNumbers: true, highlight: tree.id);
    final circles = _buildCircleMarkers([tree], showSRZ, showNRZ);

    return SizedBox(
      width: _mapWidth,
      height: _mapHeight,
      child: Stack(
        children: [
          Positioned.fill(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: FlutterMap(
                options: MapOptions(
                  initialCenter: center,
                  initialZoom: _defaultZoom + 1.5,
                  interactionOptions: const InteractionOptions(flags: InteractiveFlag.none),
                ),
                children: [
                  TileLayer(
                    urlTemplate: satelliteView
                        ? 'https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}'
                        : 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'com.arboristassistant.app',
                  ),
                  if (circles.isNotEmpty)
                    CircleLayer(circles: circles),
                  MarkerLayer(markers: markers),
                ],
              ),
            ),
          ),
          Positioned(
            top: 16,
            left: 16,
            child: _InfoPanel(
              title: 'Tree ${tree.id}',
              subtitle: tree.species.isNotEmpty ? tree.species : 'Species unknown',
              lines: [
                if (tree.height > 0) 'Height: ${tree.height.toStringAsFixed(1)} m',
                if (tree.dsh > 0) 'DSH: ${tree.dsh.toStringAsFixed(1)} cm',
                if (tree.condition.isNotEmpty) 'Condition: ${tree.condition}',
                if (tree.riskRating.isNotEmpty) 'Risk: ${tree.riskRating}',
              ],
            ),
          ),
          const Positioned(
            bottom: 20,
            right: 20,
            child: _NorthArrow(),
          ),
          const Positioned(
            bottom: 20,
            left: 20,
            child: _ScaleBar(),
          ),
        ],
      ),
    );
  }

  static List<Marker> _buildTreeMarkers(
    List<TreeEntry> trees, {
    required bool showTreeNumbers,
    String? highlight,
  }) {
    return trees.asMap().entries.map((entry) {
      final index = entry.key + 1;
      final tree = entry.value;
      final isHighlight = highlight != null && tree.id == highlight;

      return Marker(
        point: LatLng(tree.latitude!, tree.longitude!),
        width: isHighlight ? 44 : 36,
        height: isHighlight ? 44 : 36,
        child: Container(
          decoration: BoxDecoration(
            color: isHighlight ? Colors.deepOrange : Colors.green,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: isHighlight ? 3 : 2),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Center(
            child: showTreeNumbers
                ? Text(
                    'T$index',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: isHighlight ? 14 : 12,
                    ),
                  )
                : const SizedBox.shrink(),
          ),
        ),
      );
    }).toList();
  }

  static LatLng _calculateCenter(List<TreeEntry> trees, {required LatLng fallback}) {
    if (trees.isEmpty) return fallback;

    final lat = trees.map((t) => t.latitude!).reduce((a, b) => a + b) / trees.length;
    final lng = trees.map((t) => t.longitude!).reduce((a, b) => a + b) / trees.length;
    return LatLng(lat, lng);
  }

  static String _sanitizeFileComponent(String value) {
    final sanitized = value.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '_');
    return sanitized.isEmpty ? 'site' : sanitized.trim().replaceAll(RegExp(r'_+'), '_');
  }

  /// Share map image
  static Future<void> shareMapImage(String imagePath) async {
    await Share.shareXFiles([XFile(imagePath)], text: 'Tree Map Export');
  }

  /// Get map export options for reports
  static Map<String, dynamic> getMapExportOptions() {
    return {
      'siteMap': {
        'name': 'Site Map (All Trees)',
        'description': 'Single map showing all trees in the site',
        'options': {
          'showSRZ': true,
          'showNRZ': true,
          'showTreeNumbers': true,
          'satelliteView': false,
        }
      },
      'individualTreeMaps': {
        'name': 'Individual Tree Maps',
        'description': 'Separate map for each tree',
        'options': {
          'showSRZ': true,
          'showNRZ': true,
          'satelliteView': false,
        }
      },
      'satelliteView': {
        'name': 'Satellite View',
        'description': 'Maps with satellite imagery background',
        'options': {
          'satelliteView': true,
        }
      },
    };
  }

  /// Download bytes as a file in web browser
  static Future<void> _downloadBytes(Uint8List bytes, String fileName) async {
    if (kIsWeb) {
      await downloadFile(bytes, fileName, 'image/png');
    }
  }
}

class _InfoPanel extends StatelessWidget {
  const _InfoPanel({
    required this.title,
    this.subtitle,
    this.lines = const [],
    Key? key,
  }) : super(key: key);

  final String title;
  final String? subtitle;
  final List<String> lines;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 240),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.92),
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 8,
            offset: Offset(0, 4),
          ),
        ],
        border: Border.all(color: Colors.black12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          if (subtitle != null && subtitle!.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              subtitle!,
              style: const TextStyle(fontSize: 12, color: Colors.black54),
            ),
          ],
          for (final line in lines)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                line,
                style: const TextStyle(fontSize: 12, color: Colors.black87),
              ),
            ),
        ],
      ),
    );
  }
}

class _LegendPanel extends StatelessWidget {
  const _LegendPanel({
    required this.showSRZ,
    required this.showNRZ,
    Key? key,
  }) : super(key: key);

  final bool showSRZ;
  final bool showNRZ;

  @override
  Widget build(BuildContext context) {
    if (!showSRZ && !showNRZ) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.92),
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 8,
            offset: Offset(0, 4),
          ),
        ],
        border: Border.all(color: Colors.black12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Legend',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
          if (showSRZ) ...[
            const SizedBox(height: 8),
            _LegendEntry(
              color: Colors.red.withOpacity(0.35),
              borderColor: Colors.red,
              label: 'SRZ (Structural Root Zone)',
            ),
          ],
          if (showNRZ) ...[
            const SizedBox(height: 8),
            _LegendEntry(
              color: Colors.green.withOpacity(0.35),
              borderColor: Colors.green,
              label: 'NRZ (Nominated Root Zone)',
            ),
          ],
        ],
      ),
    );
  }
}

class _LegendEntry extends StatelessWidget {
  const _LegendEntry({
    Key? key,
    required this.color,
    required this.borderColor,
    required this.label,
  }) : super(key: key);

  final Color color;
  final Color borderColor;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 18,
          height: 18,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            border: Border.all(color: borderColor, width: 2),
          ),
        ),
        const SizedBox(width: 8),
        Flexible(
          child: Text(
            label,
            style: const TextStyle(fontSize: 12),
          ),
        ),
      ],
    );
  }
}

class _NorthArrow extends StatelessWidget {
  const _NorthArrow({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 52,
      height: 52,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const LinearGradient(
          colors: [Colors.black87, Colors.black54],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        boxShadow: const [
          BoxShadow(
            color: Colors.black38,
            blurRadius: 6,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: const Center(
        child: Text(
          'N',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}

class _ScaleBar extends StatelessWidget {
  const _ScaleBar({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
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
          SizedBox(
            width: 48,
            child: const Divider(
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
}

class _ScaleTick extends StatelessWidget {
  const _ScaleTick({Key? key, required this.label}) : super(key: key);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 2,
          height: 12,
          color: Colors.black,
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(fontSize: 10, color: Colors.black87),
        ),
      ],
    );
  }
}
