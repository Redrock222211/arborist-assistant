import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../models/site.dart';
import '../models/tree_entry.dart';
import 'map_export_service.dart';

class PdfReportService {
  static Future<Uint8List> generateSiteReport({
    required Site site,
    required List<TreeEntry> trees,
  }) async {
    final pdf = pw.Document();
    final dateFormat = DateFormat('d MMMM yyyy');

    final siteMapBytes = await MapExportService.captureSiteMapImage(
      site,
      showSRZ: true,
      showNRZ: true,
      showTreeNumbers: true,
    );

    pw.ImageProvider? siteMapImage;
    if (siteMapBytes != null) {
      siteMapImage = pw.MemoryImage(siteMapBytes);
    }

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (context) {
          return [
            _buildHeader(site, dateFormat),
            if (siteMapImage != null) ...[
              pw.SizedBox(height: 16),
              pw.Text('Site Map', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 8),
              pw.Center(child: pw.Image(siteMapImage, height: 240, fit: pw.BoxFit.cover)),
            ],
            pw.SizedBox(height: 24),
            _buildSummary(trees),
            pw.SizedBox(height: 24),
            _buildTreeTable(trees),
            pw.SizedBox(height: 24),
            ..._buildPhotoPages(trees),
          ];
        },
      ),
    );

    return pdf.save();
  }

  static pw.Widget _buildHeader(Site site, DateFormat formatter) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          site.name,
          style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold),
        ),
        if (site.address?.isNotEmpty == true)
          pw.Text(site.address!, style: const pw.TextStyle(fontSize: 12)),
        pw.Text('Generated: ${formatter.format(DateTime.now())}', style: const pw.TextStyle(fontSize: 12)),
      ],
    );
  }

  static pw.Widget _buildSummary(List<TreeEntry> trees) {
    final totalTrees = trees.length;
    final highRisk = trees.where((t) => t.overallRiskRating.toLowerCase().contains('high')).length;
    final permitRequired = trees.where((t) => t.permitRequired).length;
    final species = trees.map((t) => t.species).toSet().length;

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text('Summary', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
        pw.SizedBox(height: 8),
        pw.Wrap(
          spacing: 12,
          runSpacing: 8,
          children: [
            _summaryChip('Total trees', totalTrees.toString()),
            _summaryChip('Unique species', species.toString()),
            _summaryChip('High risk flags', highRisk.toString()),
            _summaryChip('Permit required', permitRequired.toString()),
          ],
        ),
      ],
    );
  }

  static pw.Widget _summaryChip(String label, String value) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: pw.BoxDecoration(
        color: PdfColors.grey200,
        borderRadius: pw.BorderRadius.circular(12),
      ),
      child: pw.Column(
        mainAxisSize: pw.MainAxisSize.min,
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(label, style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey800)),
          pw.Text(value, style: const pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold)),
        ],
      ),
    );
  }

  static pw.Widget _buildTreeTable(List<TreeEntry> trees) {
    final headers = ['Tree', 'Species', 'DSH (cm)', 'Height (m)', 'Condition', 'Risk'];
    final data = trees.map((tree) {
      return [
        tree.id,
        tree.species,
        tree.dsh.toStringAsFixed(1),
        tree.height.toStringAsFixed(1),
        tree.condition,
        tree.overallRiskRating,
      ];
    }).toList();

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text('Tree Inventory', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
        pw.SizedBox(height: 8),
        pw.Table.fromTextArray(
          headers: headers,
          data: data,
          headerDecoration: const pw.BoxDecoration(color: PdfColors.green200),
          headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.green900),
          cellStyle: const pw.TextStyle(fontSize: 10),
          headerAlignment: pw.Alignment.centerLeft,
          cellAlignment: pw.Alignment.centerLeft,
          columnWidths: {
            0: const pw.FixedColumnWidth(50),
            1: const pw.FlexColumnWidth(),
            2: const pw.FixedColumnWidth(60),
            3: const pw.FixedColumnWidth(60),
            4: const pw.FixedColumnWidth(80),
            5: const pw.FixedColumnWidth(60),
          },
        ),
      ],
    );
  }

  static List<pw.Widget> _buildPhotoPages(List<TreeEntry> trees) {
    if (trees.isEmpty) {
      return [];
    }

    final widgets = <pw.Widget>[];
    final entriesWithPhotos = trees.where((tree) => tree.imageLocalPaths.isNotEmpty).toList();
    if (entriesWithPhotos.isEmpty) {
      return widgets;
    }

    widgets.add(pw.Text('Photographic Appendix', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)));
    widgets.add(const pw.SizedBox(height: 12));

    for (final tree in entriesWithPhotos) {
      widgets.add(pw.Text('Tree ${tree.id} – ${tree.species}', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)));
      widgets.add(const pw.SizedBox(height: 6));

      final imageWidgets = <pw.Widget>[];
      for (final path in tree.imageLocalPaths.take(4)) {
        final image = _loadImage(path);
        if (image != null) {
          imageWidgets.add(pw.Expanded(
            child: pw.Container(
              margin: const pw.EdgeInsets.all(4),
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: PdfColors.grey400, width: 0.5),
              ),
              child: pw.Image(image, height: 120, fit: pw.BoxFit.cover),
            ),
          ));
        }
      }

      if (imageWidgets.isNotEmpty) {
        widgets.add(pw.Row(children: imageWidgets));
        widgets.add(const pw.SizedBox(height: 12));
      }
    }

    return widgets;
  }

  static pw.ImageProvider? _loadImage(String path) {
    try {
      if (kIsWeb) {
        return null; // Local file paths not accessible on web
      }
      final file = File(path);
      if (!file.existsSync()) {
        return null;
      }
      final bytes = file.readAsBytesSync();
      return pw.MemoryImage(bytes);
    } catch (_) {
      return null;
    }
  }
}
