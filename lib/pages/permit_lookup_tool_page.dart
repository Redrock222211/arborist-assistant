import 'package:flutter/material.dart';
import '../services/regulatory_data_service.dart';
import '../services/vicmap_service.dart';
import '../services/web_geocoding_service.dart';
import '../models/lga_tree_law.dart';
import '../models/overlay_tree_requirement.dart';
import 'dart:convert';
import 'dart:html' as html;
import 'package:geolocator/geolocator.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

class PermitLookupToolPage extends StatefulWidget {
  const PermitLookupToolPage({Key? key}) : super(key: key);

  @override
  State<PermitLookupToolPage> createState() => _PermitLookupToolPageState();
}

class _PermitLookupToolPageState extends State<PermitLookupToolPage> {
  final TextEditingController _addressController = TextEditingController();
  final RegulatoryDataService _regulatoryService = RegulatoryDataService.instance;
  
  bool _isLoading = false;
  bool _isSearching = false;
  String? _address;
  String? _lgaName;
  double? _latitude;
  double? _longitude;
  LgaTreeLaw? _treeLaw;
  List<OverlayTreeRequirement> _overlayRequirements = [];
  List<String> _overlays = [];
  
  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    await _regulatoryService.loadData();
    setState(() => _isLoading = false);
  }

  Future<void> _findMyAddress() async {
    setState(() => _isSearching = true);

    try {
      // Check location permission
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw Exception('Location permission denied');
        }
      }

      if (permission == LocationPermission.deniedForever) {
        throw Exception('Location permissions are permanently denied');
      }

      // Get current position
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      setState(() {
        _latitude = position.latitude;
        _longitude = position.longitude;
      });

      // Reverse geocode to get address
      final address = await WebGeocodingService.reverseGeocodeToAddress(
        position.latitude,
        position.longitude,
      );

      if (address != null) {
        _addressController.text = address;
        setState(() => _address = address);
      }

      // Get planning data
      final planningResult = await VicmapService.getPlanningAtPoint(
        position.longitude,
        position.latitude,
      );

      // Extract LGA and overlays
      _lgaName = planningResult.lga ?? '';
      _overlays = planningResult.overlays.map((o) => o.code).toList();

      // Look up tree law
      if (_lgaName!.isNotEmpty) {
        _treeLaw = _regulatoryService.getLgaTreeLaw(_lgaName!);
      }

      // Look up overlay requirements
      _overlayRequirements = [];
      for (var overlay in _overlays) {
        final reqs = _regulatoryService.getOverlayRequirements(
          overlay,
          lgaName: _lgaName,
        );
        _overlayRequirements.addAll(reqs);
      }

      setState(() {});
      
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error getting location: $e')),
      );
    } finally {
      setState(() => _isSearching = false);
    }
  }

  Future<void> _searchAddress() async {
    final address = _addressController.text.trim();
    if (address.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter an address')),
      );
      return;
    }

    setState(() {
      _isSearching = true;
      _address = address;
    });

    try {
      // Geocode address to get lat/long
      final result = await WebGeocodingService.geocodeAddress(address);
      
      if (result == null) {
        throw Exception('Address not found');
      }

      setState(() {
        _latitude = result['latitude'];
        _longitude = result['longitude'];
      });

      // Get planning data
      final planningResult = await VicmapService.getPlanningAtPoint(
        _longitude!,
        _latitude!,
      );

      // Extract LGA and overlays
      _lgaName = planningResult.lga ?? '';
      _overlays = planningResult.overlays.map((o) => o.code).toList();

      // Look up tree law
      if (_lgaName!.isNotEmpty) {
        _treeLaw = _regulatoryService.getLgaTreeLaw(_lgaName!);
      }

      // Look up overlay requirements
      _overlayRequirements = [];
      for (var overlay in _overlays) {
        final reqs = _regulatoryService.getOverlayRequirements(
          overlay,
          lgaName: _lgaName,
        );
        _overlayRequirements.addAll(reqs);
      }

      setState(() {});
      
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      setState(() => _isSearching = false);
    }
  }

  Future<void> _exportToPdf() async {
    if (_treeLaw == null && _overlayRequirements.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No data to export')),
      );
      return;
    }

    try {
      final pdf = pw.Document();
      
      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          build: (context) => [
            // Header
            pw.Header(
              level: 0,
              child: pw.Text(
                'Tree Permit Requirements',
                style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold, color: PdfColors.green900),
              ),
            ),
            pw.SizedBox(height: 20),
            
            // Address info
            pw.Text('Address: $_address', style: const pw.TextStyle(fontSize: 12)),
            pw.Text('LGA: $_lgaName', style: const pw.TextStyle(fontSize: 12)),
            pw.Text('Coordinates: ${_latitude?.toStringAsFixed(6) ?? 'N/A'}, ${_longitude?.toStringAsFixed(6) ?? 'N/A'}', 
                    style: const pw.TextStyle(fontSize: 12)),
            pw.SizedBox(height: 20),
            
            // Local Law Section
            if (_treeLaw != null && _treeLaw!.hasLocalLaw) ...[
              pw.Header(level: 1, text: 'Local Law Requirements'),
              pw.Container(
                padding: const pw.EdgeInsets.all(12),
                decoration: pw.BoxDecoration(
                  color: PdfColors.green50,
                  border: pw.Border.all(color: PdfColors.green700),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('Council: ${_treeLaw!.councilFullName}', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                    pw.SizedBox(height: 8),
                    pw.Text('Local Law: ${_treeLaw!.localLawNumber} (${_treeLaw!.localLawYear})'),
                    pw.Text('Size Threshold: ${_treeLaw!.displayThreshold}'),
                    if (_treeLaw!.permitFeeStandard.isNotEmpty)
                      pw.Text('Permit Fee: \$${_treeLaw!.permitFeeStandard}'),
                    if (_treeLaw!.processingDaysMin.isNotEmpty)
                      pw.Text('Processing Time: ${_treeLaw!.processingDaysMin}-${_treeLaw!.processingDaysMax} days'),
                    if (_treeLaw!.arboristReportRequired.isNotEmpty)
                      pw.Text('Arborist Report: ${_treeLaw!.arboristReportRequired}'),
                    if (_treeLaw!.notes.isNotEmpty) ...[
                      pw.SizedBox(height: 8),
                      pw.Text('Notes:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                      pw.Text(_treeLaw!.notes, style: const pw.TextStyle(fontSize: 10)),
                    ],
                    if (_treeLaw!.phone.isNotEmpty)
                      pw.Text('Phone: ${_treeLaw!.phone}'),
                  ],
                ),
              ),
              pw.SizedBox(height: 20),
            ],
            
            // Overlay Requirements
            if (_overlayRequirements.isNotEmpty) ...[
              pw.Header(level: 1, text: 'Planning Overlay Requirements'),
              ..._overlayRequirements.map((req) => pw.Container(
                margin: const pw.EdgeInsets.only(bottom: 16),
                padding: const pw.EdgeInsets.all(12),
                decoration: pw.BoxDecoration(
                  color: PdfColors.blue50,
                  border: pw.Border.all(color: PdfColors.blue700),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(req.overlayFullName, style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
                    pw.SizedBox(height: 8),
                    pw.Text('Code: ${req.overlayScheduleCode}'),
                    pw.Text('Purpose: ${req.purposeSummary}'),
                    pw.Text('Size Threshold: ${req.displayThreshold}'),
                    if (req.pruningPermitRequired.isNotEmpty)
                      pw.Text('Pruning Permit: ${req.pruningPermitRequired}'),
                    if (req.removalPermitRequired.isNotEmpty)
                      pw.Text('Removal Permit: ${req.removalPermitRequired}'),
                    if (req.arboristReportRequired.isNotEmpty)
                      pw.Text('Arborist Report: ${req.arboristReportRequired}'),
                    if (req.offsetRequired.isNotEmpty) ...[
                      pw.Text('Offset Required: ${req.offsetRequired}'),
                      if (req.offsetRatio.isNotEmpty)
                        pw.Text('Offset Ratio: ${req.offsetRatio}'),
                    ],
                    if (req.typicalPermitFee.isNotEmpty)
                      pw.Text('Permit Fee: \$${req.typicalPermitFee}'),
                    if (req.notes.isNotEmpty) ...[
                      pw.SizedBox(height: 4),
                      pw.Text('Notes: ${req.notes}', style: const pw.TextStyle(fontSize: 10)),
                    ],
                  ],
                ),
              )),
            ],
          ],
        ),
      );
      
      final bytes = await pdf.save();
      final filename = 'permit_requirements_${DateTime.now().millisecondsSinceEpoch}.pdf';
      
      // Download
      final blob = html.Blob([bytes], 'application/pdf');
      final url = html.Url.createObjectUrlFromBlob(blob);
      final anchor = html.AnchorElement(href: url)
        ..setAttribute('download', filename)
        ..click();
      html.Url.revokeObjectUrl(url);
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('✅ Exported to $filename')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error exporting PDF: $e')),
      );
    }
  }

  void _exportToWord() {
    if (_treeLaw == null && _overlayRequirements.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No data to export')),
      );
      return;
    }

    // Generate HTML document
    final htmlContent = StringBuffer();
    htmlContent.writeln('<!DOCTYPE html>');
    htmlContent.writeln('<html>');
    htmlContent.writeln('<head>');
    htmlContent.writeln('<meta charset="UTF-8">');
    htmlContent.writeln('<title>Permit Requirements - $_address</title>');
    htmlContent.writeln('<style>');
    htmlContent.writeln('body { font-family: Calibri, Arial, sans-serif; margin: 20px; }');
    htmlContent.writeln('h1 { color: #2e7d32; }');
    htmlContent.writeln('h2 { color: #1b5e20; margin-top: 30px; }');
    htmlContent.writeln('.info-row { margin: 8px 0; }');
    htmlContent.writeln('.label { font-weight: bold; display: inline-block; width: 200px; }');
    htmlContent.writeln('.section { margin-top: 20px; padding: 15px; background: #f5f5f5; border-left: 4px solid #2e7d32; }');
    htmlContent.writeln('</style>');
    htmlContent.writeln('</head>');
    htmlContent.writeln('<body>');
    
    htmlContent.writeln('<h1>Tree Permit Requirements</h1>');
    htmlContent.writeln('<div class="info-row"><span class="label">Address:</span> $_address</div>');
    htmlContent.writeln('<div class="info-row"><span class="label">LGA:</span> $_lgaName</div>');
    htmlContent.writeln('<div class="info-row"><span class="label">Coordinates:</span> ${_latitude?.toStringAsFixed(6)}, ${_longitude?.toStringAsFixed(6)}</div>');
    
    // Local Law Section
    if (_treeLaw != null && _treeLaw!.hasLocalLaw) {
      htmlContent.writeln('<h2>Local Law Requirements</h2>');
      htmlContent.writeln('<div class="section">');
      htmlContent.writeln('<div class="info-row"><span class="label">Council:</span> ${_treeLaw!.councilFullName}</div>');
      htmlContent.writeln('<div class="info-row"><span class="label">Local Law:</span> ${_treeLaw!.localLawNumber} (${_treeLaw!.localLawYear})</div>');
      htmlContent.writeln('<div class="info-row"><span class="label">Size Threshold:</span> ${_treeLaw!.displayThreshold}</div>');
      if (_treeLaw!.permitFeeStandard.isNotEmpty) {
        htmlContent.writeln('<div class="info-row"><span class="label">Permit Fee:</span> \$${_treeLaw!.permitFeeStandard}</div>');
      }
      if (_treeLaw!.processingDaysMin.isNotEmpty) {
        htmlContent.writeln('<div class="info-row"><span class="label">Processing Time:</span> ${_treeLaw!.processingDaysMin}-${_treeLaw!.processingDaysMax} days</div>');
      }
      if (_treeLaw!.notes.isNotEmpty) {
        htmlContent.writeln('<div class="info-row"><span class="label">Notes:</span> ${_treeLaw!.notes}</div>');
      }
      htmlContent.writeln('</div>');
    }
    
    // Overlays Section
    if (_overlayRequirements.isNotEmpty) {
      htmlContent.writeln('<h2>Planning Overlay Requirements</h2>');
      for (var req in _overlayRequirements) {
        htmlContent.writeln('<div class="section">');
        htmlContent.writeln('<h3>${req.overlayFullName}</h3>');
        htmlContent.writeln('<div class="info-row"><span class="label">Code:</span> ${req.overlayScheduleCode}</div>');
        htmlContent.writeln('<div class="info-row"><span class="label">Purpose:</span> ${req.purposeSummary}</div>');
        htmlContent.writeln('<div class="info-row"><span class="label">Size Threshold:</span> ${req.displayThreshold}</div>');
        if (req.pruningPermitRequired.isNotEmpty) {
          htmlContent.writeln('<div class="info-row"><span class="label">Pruning Permit:</span> ${req.pruningPermitRequired}</div>');
        }
        if (req.removalPermitRequired.isNotEmpty) {
          htmlContent.writeln('<div class="info-row"><span class="label">Removal Permit:</span> ${req.removalPermitRequired}</div>');
        }
        htmlContent.writeln('</div>');
      }
    }
    
    htmlContent.writeln('</body>');
    htmlContent.writeln('</html>');
    
    final htmlString = htmlContent.toString();
    final filename = 'permit_requirements_${DateTime.now().millisecondsSinceEpoch}.doc';
    
    // Download
    final bytes = utf8.encode(htmlString);
    final blob = html.Blob([bytes], 'application/msword');
    final url = html.Url.createObjectUrlFromBlob(blob);
    final anchor = html.AnchorElement(href: url)
      ..setAttribute('download', filename)
      ..click();
    html.Url.revokeObjectUrl(url);
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Exported to $filename')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Permit Lookup Tool'),
        backgroundColor: Colors.green[700],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Search Section
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Search Address',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          const SizedBox(height: 16),
                          TextField(
                            controller: _addressController,
                            decoration: const InputDecoration(
                              labelText: 'Enter address',
                              hintText: '123 Main St, Melbourne VIC 3000',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.search),
                            ),
                            onSubmitted: (_) => _searchAddress(),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: _isSearching ? null : _searchAddress,
                                  icon: _isSearching
                                      ? const SizedBox(
                                          width: 16,
                                          height: 16,
                                          child: CircularProgressIndicator(strokeWidth: 2),
                                        )
                                      : const Icon(Icons.search),
                                  label: Text(_isSearching ? 'Searching...' : 'Search Address'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.green[700],
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.all(16),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: _isSearching ? null : _findMyAddress,
                                  icon: _isSearching
                                      ? const SizedBox(
                                          width: 16,
                                          height: 16,
                                          child: CircularProgressIndicator(strokeWidth: 2),
                                        )
                                      : const Icon(Icons.my_location),
                                  label: Text(_isSearching ? 'Locating...' : 'Find My Address'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.blue[700],
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.all(16),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  // Results Section
                  if (_address != null) ...[
                    const SizedBox(height: 24),
                    
                    // Export Buttons
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _exportToWord,
                            icon: const Icon(Icons.description),
                            label: const Text('Export to Word'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue[800],
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _exportToPdf,
                            icon: const Icon(Icons.picture_as_pdf),
                            label: const Text('Export to PDF'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red[700],
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // Location Info
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Location Details',
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                            const Divider(),
                            _buildInfoRow('Address', _address!),
                            _buildInfoRow('LGA', _lgaName ?? 'Not found'),
                            if (_latitude != null && _longitude != null)
                              _buildInfoRow(
                                'Coordinates',
                                '${_latitude!.toStringAsFixed(6)}, ${_longitude!.toStringAsFixed(6)}',
                              ),
                            if (_overlays.isNotEmpty)
                              _buildInfoRow('Overlays', _overlays.join(', ')),
                          ],
                        ),
                      ),
                    ),
                    
                    // Local Law Requirements
                    if (_treeLaw != null) ...[
                      const SizedBox(height: 16),
                      _buildTreeLawCard(_treeLaw!),
                    ],
                    
                    // Overlay Requirements
                    if (_overlayRequirements.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      ..._overlayRequirements.map((req) => Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: _buildOverlayCard(req),
                      )),
                    ],
                    
                    // No data message
                    if (_treeLaw == null && _overlayRequirements.isEmpty) ...[
                      const SizedBox(height: 16),
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            children: [
                              Icon(Icons.info_outline, size: 48, color: Colors.orange[700]),
                              const SizedBox(height: 16),
                              const Text(
                                'No regulatory data found for this location',
                                style: TextStyle(fontSize: 16),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ],
                ],
              ),
            ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(
              '$label:',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.grey[800]),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(fontSize: 15, color: Colors.grey[900]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTreeLawCard(LgaTreeLaw law) {
    return Card(
      elevation: 2,
      color: Colors.green[50],
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(color: Colors.green[700]!, width: 2),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.verified, color: Colors.green[700], size: 28),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Local Law Requirements',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            color: Colors.green[900],
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.green[700],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      'VERIFIED',
                      style: TextStyle(fontSize: 12, color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  ),  
                ],
              ),
              const Divider(thickness: 2),
              _buildInfoRow('Council', law.councilFullName),
              if (law.hasLocalLaw) ...[
                _buildInfoRow('Local Law', '${law.localLawNumber} (${law.localLawYear})'),
                _buildInfoRow('Size Threshold', law.displayThreshold),
                if (law.permitFeeStandard.isNotEmpty)
                  _buildInfoRow('Permit Fee', '\$${law.permitFeeStandard}'),
                if (law.processingDaysMin.isNotEmpty)
                  _buildInfoRow(
                    'Processing Time',
                    '${law.processingDaysMin}-${law.processingDaysMax} days',
                  ),
                if (law.arboristReportRequired.isNotEmpty)
                  _buildInfoRow('Arborist Report', law.arboristReportRequired),
                if (law.notes.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    'Notes:',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(law.notes),
                ],
              ] else ...[
                const Text('No specific local law found for private trees'),
              ],
              if (law.phone.isNotEmpty) ...[
                const SizedBox(height: 8),
                _buildInfoRow('Phone', law.phone),
              ],
              if (law.localLawsPageUrl.isNotEmpty) ...[
                const SizedBox(height: 8),
                TextButton.icon(
                  onPressed: () {
                    html.window.open(law.localLawsPageUrl, '_blank');
                  },
                  icon: const Icon(Icons.open_in_new),
                  label: const Text('View Council Information'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOverlayCard(OverlayTreeRequirement req) {
    return Card(
      elevation: 2,
      color: Colors.blue[50],
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(color: Colors.blue[700]!, width: 2),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.verified, color: Colors.blue[700], size: 28),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      req.overlayFullName,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Colors.blue[900],
                          ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.blue[700],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      'VERIFIED',
                      style: TextStyle(fontSize: 12, color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  ),  
                ],
              ),
              const Divider(thickness: 2),
              _buildInfoRow('Code', req.overlayScheduleCode),
              _buildInfoRow('Purpose', req.purposeSummary),
              _buildInfoRow('Size Threshold', req.displayThreshold),
              if (req.pruningPermitRequired.isNotEmpty)
                _buildInfoRow('Pruning Permit', req.pruningPermitRequired),
              if (req.removalPermitRequired.isNotEmpty)
                _buildInfoRow('Removal Permit', req.removalPermitRequired),
              if (req.arboristReportRequired.isNotEmpty)
                _buildInfoRow('Arborist Report', req.arboristReportRequired),
              if (req.offsetRequired.isNotEmpty) ...[
                _buildInfoRow('Offset Required', req.offsetRequired),
                if (req.offsetRatio.isNotEmpty)
                  _buildInfoRow('Offset Ratio', req.offsetRatio),
              ],
              if (req.notes.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  'Notes:',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(req.notes),
              ],
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _addressController.dispose();
    super.dispose();
  }
}
