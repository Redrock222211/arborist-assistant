import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'dart:typed_data';
import 'dart:math' as math;

/// Professional arboricultural CAD PDF exporter with scale bar, north arrow, and title block.
class PdfExporter {
  static Future<Uint8List> generateAnnotatedPdfBytes({
    required List<String> legendItems,
    required String title,
    required String scaleText,
    required String siteName,
    required String date,
    required String surveyor,
    String? notes,
    double mapScale = 1.0, // 1:100, 1:200, etc.
    String northDirection = 'N',
  }) async {
    final doc = pw.Document();

    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a3,
        build: (context) {
          return pw.Container(
            padding: const pw.EdgeInsets.all(20),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                // Professional Title Block
                _buildTitleBlock(title, siteName, date, surveyor),
                pw.SizedBox(height: 16),
                
                // Main Content Area
                pw.Row(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    // Map Area (left side)
                    pw.Expanded(
                      flex: 3,
                      child: pw.Container(
                        height: 600,
                        decoration: pw.BoxDecoration(
                          border: pw.Border.all(color: PdfColors.black, width: 1),
                        ),
                        child: pw.Stack(
                          children: [
                            // Map placeholder
                            pw.Container(
                              width: double.infinity,
                              height: double.infinity,
                              color: PdfColors.grey200,
                              child: pw.Center(
                                child: pw.Text(
                                  'Map will be rendered here',
                                  style: pw.TextStyle(
                                    fontSize: 16,
                                    color: PdfColors.grey600,
                                  ),
                                ),
                              ),
                            ),
                            
                            // Scale Bar (bottom right)
                            pw.Positioned(
                              bottom: 20,
                              right: 20,
                              child: _buildScaleBar(mapScale),
                            ),
                            
                            // North Arrow (top right)
                            pw.Positioned(
                              top: 20,
                              right: 20,
                              child: PdfDrawingUtils.buildNorthArrow(),
                            ),
                            
                            // Scale Text
                            pw.Positioned(
                              bottom: 50,
                              left: 20,
                              child: pw.Text(
                                'Scale: $scaleText',
                                style: pw.TextStyle(
                                  fontSize: 12,
                                  fontWeight: pw.FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    
                    pw.SizedBox(width: 16),
                    
                    // Side Panel (right side)
                    pw.Expanded(
                      flex: 1,
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          // Legend
                          _buildLegend(legendItems),
                          pw.SizedBox(height: 20),
                          
                          // Site Information
                          _buildSiteInfo(siteName, date, surveyor),
                          pw.SizedBox(height: 20),
                          
                          // Notes
                          if (notes != null && notes.isNotEmpty) ...[
                            _buildNotes(notes),
                            pw.SizedBox(height: 20),
                          ],
                          
                          // Drawing Tools Used
                          _buildDrawingTools(),
                        ],
                      ),
                    ),
                  ],
                ),
                
                // Footer
                pw.SizedBox(height: 20),
                _buildFooter(),
              ],
            ),
          );
        },
      ),
    );

    return await doc.save();
  }

  // Build professional title block
  static pw.Widget _buildTitleBlock(String title, String siteName, String date, String surveyor) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(16),
      decoration: pw.BoxDecoration(
        color: PdfColors.blue50,
        border: pw.Border.all(color: PdfColors.blue200, width: 2),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
      ),
      child: pw.Row(
        children: [
          // Left side - Title and Site
          pw.Expanded(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  title,
                  style: pw.TextStyle(
                    fontSize: 24,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.blue900,
                  ),
                ),
                pw.SizedBox(height: 4),
                pw.Text(
                  'Site: $siteName',
                  style: pw.TextStyle(
                    fontSize: 14,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          
          // Right side - Date and Surveyor
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            children: [
              pw.Text(
                'Date: $date',
                style: pw.TextStyle(fontSize: 12),
              ),
              pw.Text(
                'Surveyor: $surveyor',
                style: pw.TextStyle(fontSize: 12),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Build scale bar with measurements
  static pw.Widget _buildScaleBar(double mapScale) {
    final scaleBarWidth = 120.0;
    final scaleBarHeight = 20.0;
    final divisions = 5;
    final divisionWidth = scaleBarWidth / divisions;
    
    // Calculate actual distance represented by scale bar
    final actualDistance = (scaleBarWidth / mapScale).round();
    
    return pw.Container(
      width: scaleBarWidth,
      height: scaleBarHeight,
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.black, width: 1),
        color: PdfColors.white,
      ),
      child: pw.Stack(
        children: [
          // Division lines
          ...List.generate(divisions + 1, (index) {
            final x = index * divisionWidth;
            return pw.Positioned(
              left: x,
              top: 0,
              child: pw.Container(
                width: 1,
                height: scaleBarHeight,
                color: PdfColors.black,
              ),
            );
          }),
          
          // Scale text
          pw.Positioned(
            bottom: -15,
            left: 0,
            child: pw.Text(
              '0',
              style: pw.TextStyle(fontSize: 8),
            ),
          ),
          pw.Positioned(
            bottom: -15,
            right: 0,
            child: pw.Text(
              '${actualDistance}m',
              style: pw.TextStyle(fontSize: 8),
            ),
          ),
        ],
      ),
    );
  }

  // Build legend with symbols
  static pw.Widget _buildLegend(List<String> legendItems) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey400, width: 1),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'Legend',
            style: pw.TextStyle(
              fontSize: 14,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.SizedBox(height: 8),
          ...legendItems.map((item) => pw.Padding(
            padding: const pw.EdgeInsets.only(bottom: 4),
            child: pw.Row(
              children: [
                pw.Container(
                  width: 8,
                  height: 8,
                  decoration: pw.BoxDecoration(
                    color: PdfColors.black,
                    shape: pw.BoxShape.circle,
                  ),
                ),
                pw.SizedBox(width: 8),
                pw.Text(item, style: pw.TextStyle(fontSize: 10)),
              ],
            ),
          )).toList(),
        ],
      ),
    );
  }

  // Build site information panel
  static pw.Widget _buildSiteInfo(String siteName, String date, String surveyor) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey400, width: 1),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'Site Information',
            style: pw.TextStyle(
              fontSize: 12,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.SizedBox(height: 8),
          pw.Text('Site: $siteName', style: pw.TextStyle(fontSize: 10)),
          pw.Text('Date: $date', style: pw.TextStyle(fontSize: 10)),
          pw.Text('Surveyor: $surveyor', style: pw.TextStyle(fontSize: 10)),
        ],
      ),
    );
  }

  // Build notes section
  static pw.Widget _buildNotes(String notes) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey400, width: 1),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'Notes',
            style: pw.TextStyle(
              fontSize: 12,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.SizedBox(height: 8),
          pw.Text(
            notes,
            style: pw.TextStyle(fontSize: 10),
            maxLines: 5,
          ),
        ],
      ),
    );
  }

  // Build drawing tools used section
  static pw.Widget _buildDrawingTools() {
    final tools = [
      'Tree Markers',
      'TPZ/SRZ Zones',
      'Measurement Lines',
      'Protection Areas',
      'Service Lines',
    ];
    
    return pw.Container(
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey400, width: 1),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'Drawing Tools Used',
            style: pw.TextStyle(
              fontSize: 12,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.SizedBox(height: 8),
          ...tools.map((tool) => pw.Text(
            '• $tool',
            style: pw.TextStyle(fontSize: 10),
          )).toList(),
        ],
      ),
    );
  }

  // Build footer with company info
  static pw.Widget _buildFooter() {
    return pw.Container(
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        color: PdfColors.grey100,
        border: pw.Border.all(color: PdfColors.grey300, width: 1),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            'Arborist Assistant - Professional Tree Survey',
            style: pw.TextStyle(
              fontSize: 10,
              color: PdfColors.grey600,
            ),
          ),
          pw.Text(
            'Generated on ${DateTime.now().toString().split(' ')[0]}',
            style: pw.TextStyle(
              fontSize: 10,
              color: PdfColors.grey600,
            ),
          ),
        ],
      ),
    );
  }
}

// Simple PDF drawing methods for north arrow
class PdfDrawingUtils {
  static pw.Widget buildNorthArrow({double size = 40.0}) {
    return pw.Container(
      width: size,
      height: size,
      decoration: pw.BoxDecoration(
        color: PdfColors.red,
        shape: pw.BoxShape.circle,
      ),
      child: pw.Center(
        child: pw.Text(
          'N',
          style: pw.TextStyle(
            color: PdfColors.white,
            fontSize: 16,
            fontWeight: pw.FontWeight.bold,
          ),
        ),
      ),
    );
  }
}


