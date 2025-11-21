import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import '../models/site.dart';
import '../models/tree_entry.dart';

class AtlasMapService {
  /// Generate an atlas-style report with individual tree location maps and data
  static Future<List<Uint8List>> generateTreeAtlas({
    required Site site,
    required List<TreeEntry> trees,
    required bool includeData,
  }) async {
    final List<Uint8List> atlasPages = [];
    
    for (int i = 0; i < trees.length; i++) {
      final tree = trees[i];
      final pageImage = await _generateTreeAtlasPage(
        site: site,
        tree: tree,
        treeNumber: i + 1,
        totalTrees: trees.length,
        includeData: includeData,
      );
      
      if (pageImage != null) {
        atlasPages.add(pageImage);
      }
    }
    
    return atlasPages;
  }
  
  /// Generate a single atlas page for a tree
  static Future<Uint8List?> _generateTreeAtlasPage({
    required Site site,
    required TreeEntry tree,
    required int treeNumber,
    required int totalTrees,
    required bool includeData,
  }) async {
    try {
      // Create the atlas page widget
      final widget = Container(
        width: 800,
        height: 1100,
        color: Colors.white,
        child: Column(
          children: [
            // Header
            Container(
              padding: EdgeInsets.all(16),
              color: Colors.green.shade700,
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          site.name,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'Tree ${tree.id} - ${tree.species}',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      'Tree $treeNumber of $totalTrees',
                      style: TextStyle(
                        color: Colors.green.shade700,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            // Map section
            Expanded(
              flex: includeData ? 3 : 5,
              child: Container(
                margin: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300, width: 2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Stack(
                  children: [
                    // Placeholder for actual map
                    Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.map, size: 100, color: Colors.grey.shade400),
                          SizedBox(height: 16),
                          Text(
                            'Tree Location Map',
                            style: TextStyle(
                              fontSize: 18,
                              color: Colors.grey.shade600,
                            ),
                          ),
                          Text(
                            'Lat: ${tree.latitude.toStringAsFixed(6)}',
                            style: TextStyle(color: Colors.grey.shade500),
                          ),
                          Text(
                            'Lng: ${tree.longitude.toStringAsFixed(6)}',
                            style: TextStyle(color: Colors.grey.shade500),
                          ),
                        ],
                      ),
                    ),
                    
                    // Tree marker
                    Positioned(
                      left: 400 - 20, // Center horizontally
                      top: 200 - 20, // Center vertically in map area
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: _getConditionColor(tree.condition),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 3),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black26,
                              blurRadius: 4,
                              offset: Offset(2, 2),
                            ),
                          ],
                        ),
                        child: Center(
                          child: Text(
                            tree.id,
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ),
                    ),
                    
                    // Scale bar
                    Positioned(
                      bottom: 16,
                      right: 16,
                      child: Container(
                        padding: EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.9),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 100,
                              height: 2,
                              color: Colors.black,
                            ),
                            SizedBox(width: 8),
                            Text('10m', style: TextStyle(fontSize: 12)),
                          ],
                        ),
                      ),
                    ),
                    
                    // North arrow
                    Positioned(
                      top: 16,
                      right: 16,
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.9),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.navigation, color: Colors.black87),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            // Data section (if requested)
            if (includeData) ...[
              Container(
                margin: EdgeInsets.symmetric(horizontal: 16),
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Column(
                  children: [
                    _buildDataRow('Species', tree.species),
                    _buildDataRow('DSH', '${tree.dsh} cm'),
                    _buildDataRow('Height', '${tree.height} m'),
                    _buildDataRow('Canopy', '${tree.canopySpread} m'),
                    _buildDataRow('Condition', tree.condition),
                    _buildDataRow('Health', tree.healthForm),
                    _buildDataRow('Risk Rating', tree.riskRating.isEmpty ? 'Not assessed' : tree.riskRating),
                    _buildDataRow('Retention Value', tree.retentionValue.isEmpty ? 'Not assessed' : tree.retentionValue),
                    if (tree.recommendedWorks.isNotEmpty)
                      _buildDataRow('Recommended Works', tree.recommendedWorks),
                    _buildDataRow('TPZ', '${tree.nrz.toStringAsFixed(1)} m'),
                    _buildDataRow('SRZ', '${tree.srz.toStringAsFixed(1)} m'),
                  ],
                ),
              ),
              
              // Tree images section
              Container(
                margin: EdgeInsets.all(16),
                height: 120,
                child: Row(
                  children: [
                    for (int i = 0; i < 4; i++)
                      Expanded(
                        child: Container(
                          margin: EdgeInsets.symmetric(horizontal: 4),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade200,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.grey.shade300),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.image, color: Colors.grey.shade400, size: 40),
                              SizedBox(height: 4),
                              Text(
                                _getImageLabel(i),
                                style: TextStyle(
                                  fontSize: 10,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
            
            // Footer
            Container(
              padding: EdgeInsets.all(8),
              color: Colors.grey.shade100,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Generated: ${DateTime.now().toString().split(' ')[0]}',
                    style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
                  ),
                  Text(
                    'Arborist Assistant - Tree Atlas Report',
                    style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
                  ),
                  Text(
                    'Page $treeNumber of $totalTrees',
                    style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
      
      // Render widget to image
      return await _widgetToImage(widget);
    } catch (e) {
      print('Error generating atlas page: $e');
      return null;
    }
  }
  
  static Widget _buildDataRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          SizedBox(
            width: 140,
            child: Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 12,
                color: Colors.grey.shade700,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 12,
                color: Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  static Color _getConditionColor(String condition) {
    switch (condition.toLowerCase()) {
      case 'excellent':
        return Colors.green.shade600;
      case 'good':
        return Colors.green.shade400;
      case 'fair':
        return Colors.orange.shade400;
      case 'poor':
        return Colors.orange.shade600;
      case 'critical':
      case 'dead':
        return Colors.red.shade600;
      default:
        return Colors.grey.shade600;
    }
  }
  
  static String _getImageLabel(int index) {
    switch (index) {
      case 0:
        return 'Canopy';
      case 1:
        return 'Base';
      case 2:
        return 'Context';
      case 3:
        return 'Defects';
      default:
        return 'Photo ${index + 1}';
    }
  }
  
  /// Convert a widget to an image
  static Future<Uint8List?> _widgetToImage(Widget widget) async {
    try {
      final RenderRepaintBoundary boundary = RenderRepaintBoundary();
      final RenderView renderView = RenderView(
        view: ui.PlatformDispatcher.instance.views.first,
        child: RenderPositionedBox(
          alignment: Alignment.center,
          child: boundary,
        ),
        configuration: ViewConfiguration(
          size: Size(800, 1100),
          devicePixelRatio: 2.0,
        ),
      );
      
      final PipelineOwner pipelineOwner = PipelineOwner()
        ..rootNode = renderView;
      
      final BuildOwner buildOwner = BuildOwner(focusManager: FocusManager());
      
      final RenderObjectToWidgetElement<RenderBox> rootElement = 
        RenderObjectToWidgetAdapter<RenderBox>(
          container: boundary,
          child: widget,
        ).attachToRenderTree(buildOwner);
      
      buildOwner
        ..buildScope(rootElement)
        ..finalizeTree();
      
      pipelineOwner
        ..flushLayout()
        ..flushCompositingBits()
        ..flushPaint();
      
      final ui.Image image = await boundary.toImage(pixelRatio: 2.0);
      final ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      
      if (byteData != null) {
        return byteData.buffer.asUint8List();
      }
    } catch (e) {
      print('Error converting widget to image: $e');
    }
    return null;
  }
}
