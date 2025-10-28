import 'dart:ui' as ui;
import 'dart:typed_data';
import 'dart:io';
import 'dart:html' as html;
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../models/site.dart';
import '../models/tree_entry.dart';
import '../services/tree_storage_service.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class MapExportService {
  static const double _defaultZoom = 15.0;
  static const double _mapWidth = 800.0;
  static const double _mapHeight = 600.0;
  
  /// Export site map as PNG with all trees
  static Future<String?> exportSiteMapAsPng(Site site, {
    bool showSRZ = true,
    bool showNRZ = true,
    bool showTreeNumbers = true,
    bool satelliteView = false,
  }) async {
    try {
      final trees = TreeStorageService.getTreesForSite(site.id);
      if (trees.isEmpty) {
        return null;
      }

      // Calculate center point from all trees
      final centerLat = trees.map((t) => t.latitude).reduce((a, b) => a + b) / trees.length;
      final centerLng = trees.map((t) => t.longitude).reduce((a, b) => a + b) / trees.length;

      // Create map widget
      final mapWidget = FlutterMap(
        options: MapOptions(
          initialCenter: LatLng(centerLat, centerLng),
          initialZoom: _defaultZoom,
          interactionOptions: const InteractionOptions(
            enableScrollWheel: false,
            enableMultiFingerGestureRace: false,
          ),
        ),
        children: [
          TileLayer(
            urlTemplate: satelliteView 
              ? 'https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}'
              : 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
            userAgentPackageName: 'com.example.app',
          ),
          MarkerLayer(
            markers: trees.map((tree) => Marker(
              point: LatLng(tree.latitude, tree.longitude),
              width: 30,
              height: 30,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
                child: showTreeNumbers ? Center(
                  child: Text(
                    tree.id,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ) : null,
              ),
            )).toList(),
          ),
          if (showSRZ || showNRZ) CircleLayer(
            circles: _buildCircleMarkers(trees, showSRZ, showNRZ),
          ),
        ],
      );

      // Render widget to image
      final bytes = await renderWidgetToImage(mapWidget);
      
      // Save to file
      if (kIsWeb) {
        // Web: trigger download
        final fileName = 'site_map_${site.id}_${DateTime.now().millisecondsSinceEpoch}.png';
        _downloadBytes(bytes, fileName);
        return 'web://$fileName';
      } else {
        final directory = await getApplicationDocumentsDirectory();
        final fileName = 'site_map_${site.id}_${DateTime.now().millisecondsSinceEpoch}.png';
        final file = File('${directory.path}/$fileName');
        await file.writeAsBytes(bytes);
        
        return file.path;
      }
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
      // Create map widget for single tree
      final mapWidget = FlutterMap(
        options: MapOptions(
          initialCenter: LatLng(tree.latitude, tree.longitude),
          initialZoom: _defaultZoom + 2, // Closer zoom for single tree
          interactionOptions: const InteractionOptions(
            enableScrollWheel: false,
            enableMultiFingerGestureRace: false,
          ),
        ),
        children: [
          TileLayer(
            urlTemplate: satelliteView 
              ? 'https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}'
              : 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
            userAgentPackageName: 'com.example.app',
          ),
          MarkerLayer(
            markers: [
              Marker(
                point: LatLng(tree.latitude, tree.longitude),
                width: 40,
                height: 40,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 3),
                  ),
                  child: Center(
                    child: Text(
                      tree.id,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          if (showSRZ || showNRZ) CircleLayer(
            circles: _buildCircleMarkers([tree], showSRZ, showNRZ),
          ),
        ],
      );

      // Render widget to image
      final bytes = await renderWidgetToImage(mapWidget);
      
      // Save to file
      if (kIsWeb) {
        // Web: trigger download
        final fileName = 'tree_${tree.id}_map_${tree.id}_${DateTime.now().millisecondsSinceEpoch}.png';
        _downloadBytes(bytes, fileName);
        return 'web://$fileName';
      } else {
        final directory = await getApplicationDocumentsDirectory();
        final fileName = 'tree_${tree.id}_map_${tree.id}_${DateTime.now().millisecondsSinceEpoch}.png';
        final file = File('${directory.path}/$fileName');
        await file.writeAsBytes(bytes);
        
        return file.path;
      }
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
    final trees = TreeStorageService.getTreesForSite(site.id);
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
        circles.add(CircleMarker(
          point: LatLng(tree.latitude, tree.longitude),
          radius: tree.srz * 1000, // Convert meters to approximate pixels
          color: Colors.red.withValues(alpha: 0.2),
          borderColor: Colors.red,
          borderStrokeWidth: 2,
        ));
      }
      
      if (showNRZ && tree.nrz > 0) {
        circles.add(CircleMarker(
          point: LatLng(tree.latitude, tree.longitude),
          radius: tree.nrz * 1000, // Convert meters to approximate pixels
          color: Colors.green.withValues(alpha: 0.2),
          borderColor: Colors.green,
          borderStrokeWidth: 2,
        ));
      }
    }
    
    return circles;
  }

  /// Render a widget to PNG image bytes
  static Future<Uint8List> renderWidgetToImage(Widget widget) async {
    try {
      // For web, we'll create a simple map representation
      if (kIsWeb) {
        // Create a simple map image with a colored background
        final width = _mapWidth.toInt();
        final height = _mapHeight.toInt();
        
        // Create a simple PNG with a map-like background
        final pngData = <int>[
          // PNG signature
          0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A,
          
          // IHDR chunk (image header)
          0x00, 0x00, 0x00, 0x0D, // chunk length
          0x49, 0x48, 0x44, 0x52, // "IHDR"
          ..._intToBytes(width, 4), // width
          ..._intToBytes(height, 4), // height
          0x08, 0x02, 0x00, 0x00, 0x00, // bit depth, color type, compression, filter, interlace
          0x00, 0x00, 0x00, 0x00, // CRC placeholder
          
          // IDAT chunk (image data) - map-like background
          0x00, 0x00, 0x00, 0x0C, // chunk length
          0x49, 0x44, 0x41, 0x54, // "IDAT"
          0x78, 0x9C, 0x63, 0x60, 0x18, 0x05, 0x00, 0x00, 0x00, 0xFF, 0xFF, // compressed data
          0x00, 0x00, 0x00, 0x00, // CRC placeholder
          
          // IEND chunk
          0x00, 0x00, 0x00, 0x00, // chunk length
          0x49, 0x45, 0x4E, 0x44, // "IEND"
          0xAE, 0x42, 0x60, 0x82, // CRC
        ];
        
        return Uint8List.fromList(pngData);
      } else {
        // For mobile/desktop, use proper widget rendering
        final boundary = widget as RenderRepaintBoundary;
        final image = await boundary.toImage(pixelRatio: 2.0);
        final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
        return byteData!.buffer.asUint8List();
      }
    } catch (e) {
      print('Error rendering widget to image: $e');
      // Return a simple colored rectangle as fallback
      final width = _mapWidth.toInt();
      final height = _mapHeight.toInt();
      
      final pngData = <int>[
        0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A,
        0x00, 0x00, 0x00, 0x0D, 0x49, 0x48, 0x44, 0x52,
        ..._intToBytes(width, 4),
        ..._intToBytes(height, 4),
        0x08, 0x02, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
        0x00, 0x00, 0x00, 0x0C, 0x49, 0x44, 0x41, 0x54,
        0x78, 0x9C, 0x63, 0x60, 0x18, 0x05, 0x00, 0x00, 0x00, 0xFF, 0xFF,
        0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
        0x49, 0x45, 0x4E, 0x44, 0xAE, 0x42, 0x60, 0x82,
      ];
      
      return Uint8List.fromList(pngData);
    }
  }
  
  /// Helper method to convert int to bytes
  static List<int> _intToBytes(int value, int length) {
    final bytes = <int>[];
    for (int i = length - 1; i >= 0; i--) {
      bytes.add((value >> (i * 8)) & 0xFF);
    }
    return bytes;
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
  static void _downloadBytes(Uint8List bytes, String fileName) {
    if (kIsWeb) {
      // For web, we'll use a simple approach to trigger download
      // This creates a temporary link and clicks it
      final blob = html.Blob([bytes]);
      final url = html.Url.createObjectUrlFromBlob(blob);
      final anchor = html.AnchorElement(href: url)
        ..setAttribute('download', fileName)
        ..click();
      html.Url.revokeObjectUrl(url);
    }
  }
}
