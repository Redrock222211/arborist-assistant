import 'dart:typed_data';
import 'package:arborist_assistant/models/site.dart';
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../pages/drawing_page.dart'; // To get DrawingElement
import 'package:latlong2/latlong.dart';

class PdfExportService {
  static Future<Uint8List> exportToPDF(
      List<DrawingElement> elements, Site site) async {
    final pdf = pw.Document();

    final font = await PdfGoogleFonts.openSansRegular();
    final boldFont = await PdfGoogleFonts.openSansBold();

    pdf.addPage(
      pw.MultiPage(
        header: (pw.Context context) =>
            _buildHeader(context, site, boldFont),
        footer: (pw.Context context) => _buildFooter(context, font),
        build: (pw.Context context) {
          return [
            pw.Header(
              level: 0,
              child: pw.Text('Site Plan',
                  style: pw.TextStyle(font: boldFont, fontSize: 24)),
            ),
            // The drawing canvas will go here.
            // This is a placeholder for now.
            pw.Container(
              height: 400,
              width: double.infinity,
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: PdfColors.black),
              ),
              child: pw.CustomPaint(
                painter: (canvas, size) {
                  _drawElements(canvas, size, elements);
                },
              ),
            ),
            pw.SizedBox(height: 20),
            _buildLegend(font, boldFont),
          ];
        },
      ),
    );

    return pdf.save();
  }

  static pw.Widget _buildHeader(
      pw.Context context, Site site, pw.Font boldFont) {
    return pw.Container(
      alignment: pw.Alignment.centerLeft,
      margin: const pw.EdgeInsets.only(bottom: 20.0),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(site.name,
              style: pw.TextStyle(font: boldFont, fontSize: 18)),
          pw.Text(site.address),
          pw.Text('Date: ${DateTime.now().toLocal().toString().split(' ')[0]}'),
        ],
      ),
    );
  }

  static pw.Widget _buildFooter(pw.Context context, pw.Font font) {
    return pw.Container(
      alignment: pw.Alignment.centerRight,
      margin: const pw.EdgeInsets.only(top: 10.0),
      child: pw.Text(
        'Page ${context.pageNumber} of ${context.pagesCount}',
        style: pw.Theme.of(context)
            .defaultTextStyle
            .copyWith(color: PdfColors.grey, font: font),
      ),
    );
  }
}

pw.Widget _buildLegend(pw.Font font, pw.Font boldFont) {
  return pw.Container(
    decoration: pw.BoxDecoration(
      border: pw.Border.all(color: PdfColors.grey),
      borderRadius: pw.BorderRadius.all(pw.Radius.circular(5)),
    ),
    padding: pw.EdgeInsets.all(10),
    child: pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text('Legend', style: pw.TextStyle(font: boldFont, fontSize: 16)),
        pw.SizedBox(height: 10),
        _buildLegendItem(
            'Proposed Encroachment', PdfColors.yellow, true, font),
        _buildLegendItem('TPZ (Tree Protection Zone)', PdfColors.blue, false, font),
        _buildLegendItem('SRZ (Structural Root Zone)', PdfColors.red, false, font),
        pw.SizedBox(height: 10),
        _buildLegendItem('Low Retention Value', PdfColors.green, true, font),
        _buildLegendItem('Medium Retention Value', PdfColors.orange, true, font),
        _buildLegendItem('High Retention Value', PdfColors.red, true, font),
      ],
    ),
  );
}

pw.Widget _buildLegendItem(
    String text, PdfColor color, bool isSolid, pw.Font font) {
  return pw.Row(
    children: [
      pw.Container(
        width: 20,
        height: 20,
        decoration: pw.BoxDecoration(
          color: isSolid ? color : null,
          border: pw.Border.all(color: color),
          shape: pw.BoxShape.circle,
        ),
      ),
      pw.SizedBox(width: 10),
      pw.Text(text, style: pw.TextStyle(font: font)),
    ],
  );
}

void _drawElements(
    PdfGraphics canvas, PdfPoint size, List<DrawingElement> elements) {
  if (elements.isEmpty) {
    return;
  }

  // 1. Find the bounding box of all LatLng points
  double minLat = double.infinity,
      maxLat = double.negativeInfinity,
      minLng = double.infinity,
      maxLng = double.negativeInfinity;

  for (final element in elements) {
    final points = element.latLngPoints ?? [];
    if (element.latLng != null) points.add(element.latLng!);
    if (element.endLatLng != null) points.add(element.endLatLng!);

    for (final p in points) {
      if (p.latitude < minLat) minLat = p.latitude;
      if (p.latitude > maxLat) maxLat = p.latitude;
      if (p.longitude < minLng) minLng = p.longitude;
      if (p.longitude > maxLng) maxLng = p.longitude;
    }
  }

  // Handle case where there are no points or points are identical
  if (minLat == double.infinity) return;
  if (maxLat == minLat) maxLat += 0.0001;
  if (maxLng == minLng) maxLng += 0.0001;

  // 2. Create a function to transform LatLng to PDF coordinates
  PdfPoint transform(LatLng p) {
    final double x =
        (p.longitude - minLng) / (maxLng - minLng) * size.x;
    final double y =
        size.y - (p.latitude - minLat) / (maxLat - minLat) * size.y;
    return PdfPoint(x, y);
  }

  // 3. Draw each element
  for (final element in elements) {
    canvas
      ..setColor(PdfColor.fromInt(element.color.value))
      ..setLineWidth(element.lineWidth ?? 1.0)
      ..setStrokeColor(PdfColor.fromInt(element.color.value));

    switch (element.type) {
      case 'line':
      case 'dimension':
      case 'arrow':
        if (element.latLng != null && element.endLatLng != null) {
          final p1 = transform(element.latLng!);
          final p2 = transform(element.endLatLng!);
          canvas
            ..moveTo(p1.x, p1.y)
            ..lineTo(p2.x, p2.y)
            ..strokePath();
        }
        break;
      case 'circle':
        if (element.latLng != null && element.radius != null) {
          final center = transform(element.latLng!);
          // This is an approximation of radius. A more accurate conversion
          // would be needed for precise scaling of meters to PDF points.
          final radius = element.radius! * (size.x / (maxLng - minLng)) * 0.00001;
          canvas.drawEllipse(center.x - radius, center.y - radius, radius * 2, radius * 2);
          canvas.strokePath();
        }
        break;
      case 'polygon':
      case 'rectangle':
      case 'encroachment':
      case 'paving':
      case 'planting':
        if (element.latLngPoints != null && element.latLngPoints!.isNotEmpty) {
          final points = element.latLngPoints!.map(transform).toList();
          canvas.moveTo(points.first.x, points.first.y);
          for (int i = 1; i < points.length; i++) {
            canvas.lineTo(points[i].x, points[i].y);
          }
          canvas.closePath();

          if (element.fillStyle == 'solid') {
            canvas
              ..setFillColor(PdfColor.fromInt(element.color.value))
              ..fillPath();
          } else {
             canvas.strokePath();
          }
        }
        break;
      // 'text' and 'tree' elements are not drawn on the canvas, but could be added here.
    }
  }
}
