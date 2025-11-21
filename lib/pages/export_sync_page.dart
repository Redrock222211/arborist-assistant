import 'package:flutter/material.dart';
import '../models/site.dart';
import '../models/tree_entry.dart';
import '../models/report_type.dart';
import '../services/tree_storage_service.dart';
import 'package:csv/csv.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:share_plus/share_plus.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';
import '../services/tree_sync_service.dart';
import '../services/branding_service.dart';
import '../services/map_export_service.dart';
import '../services/enhanced_export_service.dart';
import '../services/notification_service.dart';
import 'package:intl/intl.dart';

class ExportSyncPage extends StatefulWidget {
  final Site site;
  const ExportSyncPage({super.key, required this.site});

  @override
  State<ExportSyncPage> createState() => _ExportSyncPageState();
}

class _ExportSyncPageState extends State<ExportSyncPage> {
  List<TreeEntry> _trees = [];
  Set<int> _selectedIndexes = {};
  bool _selectAll = false;
  String _syncStatus = 'Up to date';
  bool _syncing = false;
  String _selectedExportType = 'Word Template';
  bool _isBatchProcessing = false;
  int _batchProgress = 0;
  
  // Template management
  String _selectedTemplate = 'Standard';
  final List<String> _availableTemplates = [
    'Standard',
    'Professional',
    'Municipal',
    'VTA Report',
    'Risk Assessment',
    'Maintenance Schedule',
  ];
  
  // Auto-scheduling
  bool _enableAutoExport = false;
  String _autoExportFrequency = 'Weekly';
  final List<String> _frequencies = ['Daily', 'Weekly', 'Monthly', 'Quarterly'];
  
  final List<String> _exportTypes = [
    'Word Template', // Uses your DOCX template
    'Tree Data (CSV)',
    'Site Map Image',
    'PDF Report',
  ];

  @override
  void initState() {
    super.initState();
    _loadTrees();
  }

  void _loadTrees() {
    setState(() {
      _trees = TreeStorageService.getTreesForSite(widget.site.id);
      _selectedIndexes.clear();
      _selectAll = false;
    });
  }

  void _toggleSelectAll() {
    setState(() {
      _selectAll = !_selectAll;
      if (_selectAll) {
        _selectedIndexes = Set.from(List.generate(_trees.length, (i) => i));
      } else {
        _selectedIndexes.clear();
      }
    });
  }

  void _toggleSelect(int idx) {
    setState(() {
      if (_selectedIndexes.contains(idx)) {
        _selectedIndexes.remove(idx);
      } else {
        _selectedIndexes.add(idx);
      }
      _selectAll = _selectedIndexes.length == _trees.length;
    });
  }

  // Enhanced template management
  Widget _buildTemplateSelector() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.description, color: Colors.blue[700]),
                const SizedBox(width: 8),
                Text(
                  'Report Template',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _selectedTemplate,
              decoration: const InputDecoration(
                labelText: 'Select Template',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.description),
              ),
              items: _availableTemplates.map((template) => 
                DropdownMenuItem(
                  value: template, 
                  child: Row(
                    children: [
                      Icon(_getTemplateIcon(template), size: 20),
                      const SizedBox(width: 8),
                      Text(template),
                    ],
                  ),
                )
              ).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedTemplate = value!;
                });
              },
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Template: $_selectedTemplate',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _getTemplateDescription(_selectedTemplate),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getTemplateIcon(String template) {
    switch (template) {
      case 'Standard':
        return Icons.article;
      case 'Professional':
        return Icons.work;
      case 'Municipal':
        return Icons.location_city;
      case 'VTA Report':
        return Icons.assessment;
      case 'Risk Assessment':
        return Icons.warning;
      case 'Maintenance Schedule':
        return Icons.schedule;
      default:
        return Icons.description;
    }
  }

  String _getTemplateDescription(String template) {
    switch (template) {
      case 'Standard':
        return 'Basic tree assessment report with essential data and recommendations.';
      case 'Professional':
        return 'Comprehensive report with detailed analysis, photos, and professional formatting.';
      case 'Municipal':
        return 'Government-compliant report with regulatory requirements and compliance checks.';
      case 'VTA Report':
        return 'Visual Tree Assessment report following ISA/VTA methodology standards.';
      case 'Risk Assessment':
        return 'Focused risk analysis with safety recommendations and priority actions.';
      case 'Maintenance Schedule':
        return 'Maintenance planning report with schedules, costs, and resource requirements.';
      default:
        return 'Standard template for general use.';
    }
  }

  // Enhanced auto-scheduling with better UI
  Widget _buildAutoScheduling() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.schedule, color: Colors.green[700]),
                const SizedBox(width: 8),
                Text(
                  'Auto Export',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                Switch(
                  value: _enableAutoExport,
                  onChanged: (value) {
                    setState(() {
                      _enableAutoExport = value;
                    });
                  },
                ),
              ],
            ),
            if (_enableAutoExport) ...[
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _autoExportFrequency,
                decoration: const InputDecoration(
                  labelText: 'Export Frequency',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.repeat),
                ),
                items: _frequencies.map((frequency) => 
                  DropdownMenuItem(
                    value: frequency, 
                    child: Row(
                      children: [
                        Icon(_getFrequencyIcon(frequency), size: 20),
                        const SizedBox(width: 8),
                        Text(frequency),
                      ],
                    ),
                  )
                ).toList(),
                onChanged: (value) {
                  setState(() {
                    _autoExportFrequency = value!;
                  });
                },
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.event, color: Colors.green[700], size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Next export: ${_getNextExportDate()}',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          Text(
                            '${_selectedTemplate} template will be used',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  IconData _getFrequencyIcon(String frequency) {
    switch (frequency) {
      case 'Daily':
        return Icons.today;
      case 'Weekly':
        return Icons.view_week;
      case 'Monthly':
        return Icons.calendar_month;
      case 'Quarterly':
        return Icons.calendar_view_month;
      default:
        return Icons.repeat;
    }
  }

  String _getNextExportDate() {
    final now = DateTime.now();
    DateTime nextExport;
    
    switch (_autoExportFrequency) {
      case 'Daily':
        nextExport = now.add(const Duration(days: 1));
        break;
      case 'Weekly':
        nextExport = now.add(const Duration(days: 7));
        break;
      case 'Monthly':
        nextExport = DateTime(now.year, now.month + 1, now.day);
        break;
      case 'Quarterly':
        nextExport = DateTime(now.year, now.month + 3, now.day);
        break;
      default:
        nextExport = now.add(const Duration(days: 7));
    }
    
    return DateFormat('MMM dd, yyyy').format(nextExport);
  }

  Future<void> _exportAsCsv() async {
    final selected = _selectedIndexes.map((i) => _trees[i]).toList();
    if (selected.isEmpty) return;
    final headers = [
      'Tree ID', 'Tag', 'Species', 'DBH', 'Height', 'Condition', 'Permit Required', 'Latitude', 'Longitude',
      'SRZ', 'TPZ', 'Age Class', 'Retention Value', 'Risk Rating', 'Location', 'Habitat Value', 'Recommended Works',
      'Health Form', 'Diseases Present', 'Canopy Spread', 'Clearance to Structures', 'Origin', 'Significance',
      'Past Management', 'Pest Presence', 'Notes', 'Retention Justification', 'Removal Justification',
      'Target/Occupancy', 'Defects Observed', 'Likelihood of Failure', 'Likelihood of Impact', 'Consequence of Failure',
      'Overall Risk Rating', 'VTA Notes', 'VTA Defects', 'Inspection Date', 'Inspector Name'
    ];
    final rows = [headers];
    for (final t in selected) {
      rows.add([
        t.id, t.id, t.species, t.dsh.toString(), t.height.toString(), t.condition, t.permitRequired ? 'Yes' : 'No', t.latitude.toString(), t.longitude.toString(),
        t.srz.toString(), t.nrz.toString(), t.ageClass, t.retentionValue, t.riskRating, t.locationDescription, t.habitatValue, t.recommendedWorks,
        t.healthForm, t.diseasesPresent, t.canopySpread.toString(), t.clearanceToStructures.toString(), t.origin, '',
        t.pastManagement, t.pestPresence, t.notes, '', '',
        t.targetOccupancy, t.defectsObserved.join('; '), t.likelihoodOfFailure, t.likelihoodOfImpact, t.consequenceOfFailure,
        t.overallRiskRating, t.vtaNotes, t.vtaDefects.join('; '),
        t.inspectionDate != null ? t.inspectionDate!.toIso8601String() : '', t.inspectorName
      ]);
    }
    final csvStr = const ListToCsvConverter().convert(rows);
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/site_${widget.site.name.replaceAll(' ', '_')}_trees.csv');
    await file.writeAsString(csvStr);
    await Share.shareXFiles([XFile(file.path)], text: 'Tree data export for site: ${widget.site.name}');
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('CSV exported and ready to share.')));
  }

  Future<void> _exportAsPdfReport(List<TreeEntry> selectedTrees) async {
    // Show dialog to select report type
    final reportType = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Report Type'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.assessment),
              title: const Text('Preliminary Arboricultural Assessment'),
              subtitle: const Text('For multiple trees - initial site assessment'),
              onTap: () => Navigator.of(context).pop('preliminary'),
            ),
            ListTile(
              leading: const Icon(Icons.forest),
              title: const Text('Tree Management Plan'),
              subtitle: const Text('Comprehensive management strategy'),
              onTap: () => Navigator.of(context).pop('management'),
            ),
            ListTile(
              leading: const Icon(Icons.park),
              title: const Text('Single Tree Report (ISA/VTA)'),
              subtitle: const Text('Detailed individual tree assessment'),
              onTap: () => Navigator.of(context).pop('single'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );

    if (reportType == null) return;

    switch (reportType) {
      case 'preliminary':
        await _exportPreliminaryAssessment(selectedTrees);
        break;
      case 'management':
        await _exportTreeManagementPlan(selectedTrees);
        break;
      case 'single':
        if (selectedTrees.length == 1) {
          await _exportSingleTreeReport(selectedTrees.first);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Single Tree Report requires exactly one tree selection')),
          );
        }
        break;
    }
  }

  Future<void> _showPreview() async {
    final selected = _selectedIndexes.map((i) => _trees[i]).toList();
    if (selected.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select at least one tree to preview')),
      );
      return;
    }

    String previewContent = '';
    String previewTitle = '';

    switch (_selectedExportType) {
      case 'Tree Data (CSV)':
        previewTitle = 'CSV Preview';
        previewContent = _generateCsvPreview(selected);
        break;
      case 'Word Template':
        previewTitle = 'Word Document Preview';
        previewContent = _generateWordPreview(selected);
        break;
      case 'PDF Report':
        previewTitle = 'PDF Report Preview';
        previewContent = _generatePdfPreview(selected);
        break;
      case 'Site Map Image':
        previewTitle = 'Site Map Preview';
        previewContent = 'Site map will be generated with:\n• ${selected.length} trees marked\n• SRZ/TPZ zones displayed\n• Legend and scale\n• Site information';
        break;
      default:
        previewTitle = 'Preview';
        previewContent = 'Preview not available for this export type';
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(previewTitle),
        content: SizedBox(
          width: double.maxFinite,
          height: 400,
          child: SingleChildScrollView(
            child: SelectableText(
              previewContent,
              style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _exportData();
            },
            child: const Text('Export Now'),
          ),
        ],
      ),
    );
  }

  String _generateCsvPreview(List<TreeEntry> trees) {
    final headers = [
      'Tree ID', 'Species', 'DSH', 'Height', 'Condition', 'Permit Required', 'Latitude', 'Longitude',
      'SRZ', 'NRZ', 'Age Class', 'Retention Value', 'Risk Rating', 'Location', 'Habitat Value', 'Recommended Works',
      'Health', 'Diseases Present', 'Canopy Spread', 'Clearance to Structures', 'Origin', 'Past Management', 
      'Pest Presence', 'Notes', 'Target/Occupancy', 'Defects Observed', 'Likelihood of Failure', 
      'Likelihood of Impact', 'Consequence of Failure', 'Overall Risk Rating', 'VTA Notes', 'VTA Defects', 
      'Inspection Date', 'Inspector Name'
    ];
    
    final rows = [headers];
    for (final t in trees.take(3)) { // Show first 3 trees in preview
      rows.add([
        t.id, t.species, t.dsh.toString(), t.height.toString(), t.condition, t.permitRequired ? 'Yes' : 'No', 
        t.latitude.toString(), t.longitude.toString(), t.srz.toString(), t.nrz.toString(), t.ageClass, 
        t.retentionValue, t.riskRating, t.locationDescription, t.habitatValue, t.recommendedWorks,
        t.healthForm, t.diseasesPresent, t.canopySpread.toString(), t.clearanceToStructures.toString(), 
        t.origin, t.pastManagement, t.pestPresence, t.notes, t.targetOccupancy, 
        t.defectsObserved.join('; '), t.likelihoodOfFailure, t.likelihoodOfImpact, t.consequenceOfFailure,
        t.overallRiskRating, t.vtaNotes, t.vtaDefects.join('; '),
        t.inspectionDate != null ? t.inspectionDate!.toIso8601String() : '', t.inspectorName
      ]);
    }
    
    if (trees.length > 3) {
      rows.add(['...', '...', '...', '...', '...', '...', '...', '...', '...', '...', '...', '...', '...', '...', '...', '...', '...', '...', '...', '...', '...', '...', '...', '...', '...', '...', '...', '...', '...', '...', '...', '...', '...', '...']);
      rows.add(['(Showing first 3 of ${trees.length} trees)']);
    }
    
    return const ListToCsvConverter().convert(rows);
  }

  String _generateWordPreview(List<TreeEntry> trees) {
    StringBuffer buffer = StringBuffer();
    buffer.writeln('ARBORICULTURAL ASSESSMENT REPORT');
    buffer.writeln('================================');
    buffer.writeln();
    buffer.writeln('Site: ${widget.site.name}');
    buffer.writeln('Date: ${DateTime.now().toString().split(' ')[0]}');
    buffer.writeln('Trees Assessed: ${trees.length}');
    buffer.writeln();
    buffer.writeln('TREE SUMMARY:');
    buffer.writeln('-------------');
    
    for (final tree in trees.take(3)) {
      buffer.writeln('Tree ID: ${tree.id}');
      buffer.writeln('Species: ${tree.species}');
      buffer.writeln('DSH: ${tree.dsh} m');
      buffer.writeln('Height: ${tree.height} m');
      buffer.writeln('Condition: ${tree.condition}');
      buffer.writeln('SRZ: ${tree.srz} m');
      buffer.writeln('NRZ: ${tree.nrz} m');
      buffer.writeln('Risk Rating: ${tree.riskRating}');
      buffer.writeln('Health: ${tree.healthForm}');
      buffer.writeln('Location: ${tree.locationDescription}');
      buffer.writeln('Notes: ${tree.notes}');
      buffer.writeln();
    }
    
    if (trees.length > 3) {
      buffer.writeln('... (${trees.length - 3} more trees)');
    }
    
    return buffer.toString();
  }

  String _generatePdfPreview(List<TreeEntry> trees) {
    StringBuffer buffer = StringBuffer();
    buffer.writeln('PROFESSIONAL ARBORICULTURAL REPORT PREVIEW');
    buffer.writeln('==========================================');
    buffer.writeln();
    buffer.writeln('This PDF will include:');
    buffer.writeln('• Professional cover page with site details');
    buffer.writeln('• Executive summary and recommendations');
    buffer.writeln('• Detailed tree assessment data');
    buffer.writeln('• Risk assessment and management recommendations');
    buffer.writeln('• Site map with tree locations');
    buffer.writeln('• Individual tree photographs (if available)');
    buffer.writeln('• Compliance with ISA/VTA standards');
    buffer.writeln();
    buffer.writeln('Trees to be included: ${trees.length}');
    buffer.writeln('Report type: ${_getReportTypeDescription()}');
    buffer.writeln();
    buffer.writeln('SAMPLE TREE DATA:');
    buffer.writeln('-----------------');
    
    if (trees.isNotEmpty) {
      final tree = trees.first;
      buffer.writeln('Tree ID: ${tree.id}');
      buffer.writeln('Species: ${tree.species}');
      buffer.writeln('DSH: ${tree.dsh} m');
      buffer.writeln('Height: ${tree.height} m');
      buffer.writeln('SRZ: ${tree.srz} m');
      buffer.writeln('NRZ: ${tree.nrz} m');
      buffer.writeln('Risk Rating: ${tree.riskRating}');
      buffer.writeln('Health: ${tree.healthForm}');
    }
    
    return buffer.toString();
  }

  Future<void> _exportData() async {
    final selected = _selectedIndexes.map((i) => _trees[i]).toList();
    if (selected.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select at least one tree to export'),
          duration: Duration(seconds: 1),
        ),
      );
      return;
    }
    
    // Always export Word template since we removed the dropdown
    await _exportProfessionalReport();
  }

  Future<void> _exportPreliminaryAssessment(List<TreeEntry> selectedTrees) async {
    final pdf = pw.Document();
    final branding = BrandingService.loadBranding();
    // final user = FirebaseAuth.instance.currentUser; // Firebase not configured
    final user = null;
    
    // Cover page with site map background
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Container(
            decoration: pw.BoxDecoration(
              color: PdfColors.white,
            ),
            child: pw.Stack(
              children: [
                // Background map (placeholder for now)
                pw.Container(
                  width: double.infinity,
                  height: double.infinity,
                  decoration: pw.BoxDecoration(
                    color: PdfColors.grey200,
                  ),
                  child: pw.Center(
                    child: pw.Text(
                      'Site Map Background',
                      style: pw.TextStyle(
                        color: PdfColors.grey400,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
                // Title overlay
                pw.Center(
                  child: pw.Column(
                    mainAxisAlignment: pw.MainAxisAlignment.center,
                    children: [
                      pw.Text(
                        'Preliminary',
                        style: pw.TextStyle(
                          fontSize: 32,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.black,
                        ),
                      ),
                      pw.SizedBox(height: 8),
                      pw.Text(
                        'Arboricultural',
                        style: pw.TextStyle(
                          fontSize: 32,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.black,
                        ),
                      ),
                      pw.SizedBox(height: 8),
                      pw.Text(
                        'Assessment',
                        style: pw.TextStyle(
                          fontSize: 32,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.black,
                        ),
                      ),
                      pw.SizedBox(height: 40),
                      pw.Text(
                        widget.site.name,
                        style: pw.TextStyle(
                          fontSize: 18,
                          color: PdfColors.black,
                        ),
                      ),
                      pw.SizedBox(height: 20),
                      pw.Text(
                        'Date: ${DateTime.now().toString().split(' ')[0]}',
                        style: pw.TextStyle(
                          fontSize: 14,
                          color: PdfColors.black,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );

    // Table of Contents
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                'Contents',
                style: pw.TextStyle(
                  fontSize: 24,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 20),
              _buildTableOfContents(),
            ],
          );
        },
      ),
    );

    // 1. Summary
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                '1 Summary',
                style: pw.TextStyle(
                  fontSize: 20,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 16),
              pw.Text(
                'This preliminary arboricultural assessment was conducted on ${widget.site.name} on ${DateTime.now().toString().split(' ')[0]}. '
                'A total of ${selectedTrees.length} trees were assessed for their health, structure, and retention value. '
                'The assessment includes detailed tree data, risk evaluation, and recommendations for tree protection and management.',
                style: pw.TextStyle(fontSize: 12),
              ),
              pw.SizedBox(height: 16),
              pw.Text(
                'Key Findings:',
                style: pw.TextStyle(
                  fontSize: 14,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 8),
              pw.Text(
                '• ${selectedTrees.where((t) => t.retentionValue == 'High').length} trees identified as high retention value\n'
                '• ${selectedTrees.where((t) => t.permitRequired).length} trees require permits for removal\n'
                '• ${selectedTrees.where((t) => t.overallRiskRating == 'High').length} trees rated as high risk\n'
                '• ${selectedTrees.where((t) => t.condition == 'Good').length} trees in good condition',
                style: pw.TextStyle(fontSize: 12),
              ),
            ],
          );
        },
      ),
    );

    // 2. Assignment
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                '2 Assignment',
                style: pw.TextStyle(
                  fontSize: 20,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 16),
              pw.Text(
                '2.1 Author / Consulting Arborist',
                style: pw.TextStyle(
                  fontSize: 16,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 8),
              pw.Text(
                '${user?.displayName ?? 'Consulting Arborist'}\n'
                '${user?.email ?? 'Email: [Consulting Arborist Email]'}\n'
                'Qualifications: [Qualifications]',
                style: pw.TextStyle(fontSize: 12),
              ),
              pw.SizedBox(height: 16),
              pw.Text(
                '2.2 Client',
                style: pw.TextStyle(
                  fontSize: 16,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 8),
              pw.Text(
                '[Client Name]\n'
                '[Client Address]\n'
                '[Client Contact]',
                style: pw.TextStyle(fontSize: 12),
              ),
              pw.SizedBox(height: 16),
              pw.Text(
                '2.3 Brief',
                style: pw.TextStyle(
                  fontSize: 16,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 8),
              pw.Text(
                'To conduct a preliminary arboricultural assessment of all trees on the subject site, '
                'including health and structural assessment, retention value evaluation, and recommendations '
                'for tree protection and management.',
                style: pw.TextStyle(fontSize: 12),
              ),
            ],
          );
        },
      ),
    );

    // 3. Data collection
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                '3 Data collection',
                style: pw.TextStyle(
                  fontSize: 20,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 16),
              pw.Text(
                '3.1 Site Visit',
                style: pw.TextStyle(
                  fontSize: 16,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 8),
              pw.Text(
                'Site visit conducted on ${DateTime.now().toString().split(' ')[0]}.\n'
                'Weather conditions: [Weather]\n'
                'Site access: [Access details]',
                style: pw.TextStyle(fontSize: 12),
              ),
              pw.SizedBox(height: 16),
              pw.Text(
                '3.2 Method of data collection',
                style: pw.TextStyle(
                  fontSize: 16,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 8),
              pw.Text(
                '• Visual tree assessment from ground level\n'
                '• Diameter at breast height (DBH) measurements\n'
                '• Height estimation using clinometer\n'
                '• GPS location recording\n'
                '• Photographic documentation\n'
                '• Risk assessment using VTA methodology',
                style: pw.TextStyle(fontSize: 12),
              ),
            ],
          );
        },
      ),
    );

    // 4. Site description
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                '4 Site description',
                style: pw.TextStyle(
                  fontSize: 20,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 16),
              pw.Text(
                'Site Name: ${widget.site.name}\n'
                'Address: ${widget.site.address}\n'
                'Site Notes: ${widget.site.notes}',
                style: pw.TextStyle(fontSize: 12),
              ),
              pw.SizedBox(height: 16),
              pw.Text(
                'Site Characteristics:',
                style: pw.TextStyle(
                  fontSize: 14,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 8),
              pw.Text(
                '• Total trees assessed: ${selectedTrees.length}\n'
                '• Site area: [Area in hectares]\n'
                '• Soil type: [Soil description]\n'
                '• Drainage: [Drainage conditions]\n'
                '• Existing development: [Development details]',
                style: pw.TextStyle(fontSize: 12),
              ),
            ],
          );
        },
      ),
    );

    // 5. Tree data
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                '5 Tree data',
                style: pw.TextStyle(
                  fontSize: 20,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 16),
              pw.Table(
                border: pw.TableBorder.all(),
                columnWidths: {
                  0: pw.FixedColumnWidth(40),
                  1: pw.FixedColumnWidth(80),
                  2: pw.FixedColumnWidth(60),
                  3: pw.FixedColumnWidth(60),
                  4: pw.FixedColumnWidth(60),
                  5: pw.FixedColumnWidth(60),
                  6: pw.FixedColumnWidth(60),
                },
                children: [
                  // Header row
                  pw.TableRow(
                    children: [
                      pw.Padding(
                        padding: pw.EdgeInsets.all(4),
                        child: pw.Text('ID', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
                      ),
                      pw.Padding(
                        padding: pw.EdgeInsets.all(4),
                        child: pw.Text('Species', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
                      ),
                      pw.Padding(
                        padding: pw.EdgeInsets.all(4),
                        child: pw.Text('DBH', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
                      ),
                      pw.Padding(
                        padding: pw.EdgeInsets.all(4),
                        child: pw.Text('Height', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
                      ),
                      pw.Padding(
                        padding: pw.EdgeInsets.all(4),
                        child: pw.Text('Condition', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
                      ),
                      pw.Padding(
                        padding: pw.EdgeInsets.all(4),
                        child: pw.Text('Retention', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
                      ),
                      pw.Padding(
                        padding: pw.EdgeInsets.all(4),
                        child: pw.Text('Risk', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
                      ),
                    ],
                  ),
                  // Data rows
                  ...selectedTrees.map((tree) => pw.TableRow(
                    children: [
                      pw.Padding(
                        padding: pw.EdgeInsets.all(4),
                        child: pw.Text(tree.id.toString(), style: pw.TextStyle(fontSize: 9)),
                      ),
                      pw.Padding(
                        padding: pw.EdgeInsets.all(4),
                        child: pw.Text(tree.species ?? '', style: pw.TextStyle(fontSize: 9)),
                      ),
                      pw.Padding(
                        padding: pw.EdgeInsets.all(4),
                        child: pw.Text('${tree.dsh ?? ''} cm', style: pw.TextStyle(fontSize: 9)),
                      ),
                      pw.Padding(
                        padding: pw.EdgeInsets.all(4),
                        child: pw.Text('${tree.height ?? ''} m', style: pw.TextStyle(fontSize: 9)),
                      ),
                      pw.Padding(
                        padding: pw.EdgeInsets.all(4),
                        child: pw.Text(tree.condition ?? '', style: pw.TextStyle(fontSize: 9)),
                      ),
                      pw.Padding(
                        padding: pw.EdgeInsets.all(4),
                        child: pw.Text(tree.retentionValue ?? '', style: pw.TextStyle(fontSize: 9)),
                      ),
                      pw.Padding(
                        padding: pw.EdgeInsets.all(4),
                        child: pw.Text(tree.overallRiskRating ?? '', style: pw.TextStyle(fontSize: 9)),
                      ),
                    ],
                  )).toList(),
                ],
              ),
            ],
          );
        },
      ),
    );

    // Continue with remaining sections...
    _addRemainingSections(pdf, selectedTrees);

    // Save and share the PDF
    final output = await getTemporaryDirectory();
    final file = File('${output.path}/preliminary_assessment_${widget.site.name.replaceAll(' ', '_')}.pdf');
    await file.writeAsBytes(await pdf.save());
    
    await Share.shareXFiles(
      [XFile(file.path)],
      text: 'Preliminary Arboricultural Assessment - ${widget.site.name}',
    );
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Preliminary Assessment PDF exported successfully')),
    );
  }

  Future<void> _exportTreeManagementPlan(List<TreeEntry> selectedTrees) async {
    final pdf = pw.Document();
    // final user = FirebaseAuth.instance.currentUser; // Firebase not configured
    final user = null;
    
    // Cover page
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Container(
            decoration: pw.BoxDecoration(
              color: PdfColors.white,
            ),
            child: pw.Stack(
              children: [
                // Background map
                pw.Container(
                  width: double.infinity,
                  height: double.infinity,
                  decoration: pw.BoxDecoration(
                    color: PdfColors.grey200,
                  ),
                  child: pw.Center(
                    child: pw.Text(
                      'Site Map Background',
                      style: pw.TextStyle(
                        color: PdfColors.grey400,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
                // Title overlay
                pw.Center(
                  child: pw.Column(
                    mainAxisAlignment: pw.MainAxisAlignment.center,
                    children: [
                      pw.Text(
                        'Tree',
                        style: pw.TextStyle(
                          fontSize: 32,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.black,
                        ),
                      ),
                      pw.SizedBox(height: 8),
                      pw.Text(
                        'Management',
                        style: pw.TextStyle(
                          fontSize: 32,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.black,
                        ),
                      ),
                      pw.SizedBox(height: 8),
                      pw.Text(
                        'Plan',
                        style: pw.TextStyle(
                          fontSize: 32,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.black,
                        ),
                      ),
                      pw.SizedBox(height: 40),
                      pw.Text(
                        widget.site.name,
                        style: pw.TextStyle(
                          fontSize: 18,
                          color: PdfColors.black,
                        ),
                      ),
                      pw.SizedBox(height: 20),
                      pw.Text(
                        'Date: ${DateTime.now().toString().split(' ')[0]}',
                        style: pw.TextStyle(
                          fontSize: 14,
                          color: PdfColors.black,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );

    // Executive Summary
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                'Executive Summary',
                style: pw.TextStyle(
                  fontSize: 24,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 16),
              pw.Text(
                'This Tree Management Plan provides a comprehensive framework for the ongoing care, '
                'maintenance, and protection of trees on ${widget.site.name}. The plan addresses '
                'immediate management needs and establishes long-term strategies for tree health and safety.',
                style: pw.TextStyle(fontSize: 12),
              ),
              pw.SizedBox(height: 16),
              pw.Text(
                'Key Management Objectives:',
                style: pw.TextStyle(
                  fontSize: 14,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 8),
              pw.Text(
                '• Maintain tree health and structural integrity\n'
                '• Minimize risk to people and property\n'
                '• Preserve high-value trees\n'
                '• Implement appropriate maintenance schedules\n'
                '• Ensure compliance with relevant regulations',
                style: pw.TextStyle(fontSize: 12),
              ),
            ],
          );
        },
      ),
    );

    // Tree Inventory and Assessment
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                'Tree Inventory and Assessment',
                style: pw.TextStyle(
                  fontSize: 20,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 16),
              pw.Table(
                border: pw.TableBorder.all(),
                columnWidths: {
                  0: pw.FixedColumnWidth(40),
                  1: pw.FixedColumnWidth(80),
                  2: pw.FixedColumnWidth(60),
                  3: pw.FixedColumnWidth(60),
                  4: pw.FixedColumnWidth(60),
                  5: pw.FixedColumnWidth(60),
                  6: pw.FixedColumnWidth(60),
                },
                children: [
                  // Header row
                  pw.TableRow(
                    children: [
                      pw.Padding(
                        padding: pw.EdgeInsets.all(4),
                        child: pw.Text('ID', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
                      ),
                      pw.Padding(
                        padding: pw.EdgeInsets.all(4),
                        child: pw.Text('Species', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
                      ),
                      pw.Padding(
                        padding: pw.EdgeInsets.all(4),
                        child: pw.Text('DBH', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
                      ),
                      pw.Padding(
                        padding: pw.EdgeInsets.all(4),
                        child: pw.Text('Height', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
                      ),
                      pw.Padding(
                        padding: pw.EdgeInsets.all(4),
                        child: pw.Text('Condition', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
                      ),
                      pw.Padding(
                        padding: pw.EdgeInsets.all(4),
                        child: pw.Text('Priority', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
                      ),
                      pw.Padding(
                        padding: pw.EdgeInsets.all(4),
                        child: pw.Text('Next Action', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
                      ),
                    ],
                  ),
                  // Data rows
                  ...selectedTrees.map((tree) => pw.TableRow(
                    children: [
                      pw.Padding(
                        padding: pw.EdgeInsets.all(4),
                        child: pw.Text(tree.id.toString(), style: pw.TextStyle(fontSize: 9)),
                      ),
                      pw.Padding(
                        padding: pw.EdgeInsets.all(4),
                        child: pw.Text(tree.species ?? '', style: pw.TextStyle(fontSize: 9)),
                      ),
                      pw.Padding(
                        padding: pw.EdgeInsets.all(4),
                        child: pw.Text('${tree.dsh ?? ''} cm', style: pw.TextStyle(fontSize: 9)),
                      ),
                      pw.Padding(
                        padding: pw.EdgeInsets.all(4),
                        child: pw.Text('${tree.height ?? ''} m', style: pw.TextStyle(fontSize: 9)),
                      ),
                      pw.Padding(
                        padding: pw.EdgeInsets.all(4),
                        child: pw.Text(tree.condition ?? '', style: pw.TextStyle(fontSize: 9)),
                      ),
                      pw.Padding(
                        padding: pw.EdgeInsets.all(4),
                        child: pw.Text(_getManagementPriority(tree), style: pw.TextStyle(fontSize: 9)),
                      ),
                      pw.Padding(
                        padding: pw.EdgeInsets.all(4),
                        child: pw.Text(_getNextAction(tree), style: pw.TextStyle(fontSize: 9)),
                      ),
                    ],
                  )).toList(),
                ],
              ),
            ],
          );
        },
      ),
    );

    // Management Recommendations
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                'Management Recommendations',
                style: pw.TextStyle(
                  fontSize: 20,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 16),
              pw.Text(
                'Immediate Actions (0-3 months):',
                style: pw.TextStyle(
                  fontSize: 16,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 8),
              pw.Text(
                '• Remove deadwood from high-risk trees\n'
                '• Implement tree protection measures\n'
                '• Schedule detailed inspections for priority trees\n'
                '• Establish monitoring protocols',
                style: pw.TextStyle(fontSize: 12),
              ),
              pw.SizedBox(height: 16),
              pw.Text(
                'Short-term Actions (3-12 months):',
                style: pw.TextStyle(
                  fontSize: 16,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 8),
              pw.Text(
                '• Complete structural pruning programs\n'
                '• Implement soil improvement measures\n'
                '• Conduct root investigations where needed\n'
                '• Develop species-specific care protocols',
                style: pw.TextStyle(fontSize: 12),
              ),
              pw.SizedBox(height: 16),
              pw.Text(
                'Long-term Actions (1-5 years):',
                style: pw.TextStyle(
                  fontSize: 16,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 8),
              pw.Text(
                '• Establish regular maintenance cycles\n'
                '• Plan for tree replacement where necessary\n'
                '• Monitor and adjust management strategies\n'
                '• Document management outcomes',
                style: pw.TextStyle(fontSize: 12),
              ),
            ],
          );
        },
      ),
    );

    // Save and share the PDF
    final output = await getTemporaryDirectory();
    final file = File('${output.path}/tree_management_plan_${widget.site.name.replaceAll(' ', '_')}.pdf');
    await file.writeAsBytes(await pdf.save());
    
    await Share.shareXFiles(
      [XFile(file.path)],
      text: 'Tree Management Plan - ${widget.site.name}',
    );
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Tree Management Plan PDF exported successfully')),
    );
  }

  Future<void> _exportSingleTreeReport(TreeEntry tree) async {
    final pdf = pw.Document();
    // final user = FirebaseAuth.instance.currentUser; // Firebase not configured
    final user = null;
    
    // Cover page
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Container(
            decoration: pw.BoxDecoration(
              color: PdfColors.white,
            ),
            child: pw.Stack(
              children: [
                // Background map
                pw.Container(
                  width: double.infinity,
                  height: double.infinity,
                  decoration: pw.BoxDecoration(
                    color: PdfColors.grey200,
                  ),
                  child: pw.Center(
                    child: pw.Text(
                      'Tree Location Map',
                      style: pw.TextStyle(
                        color: PdfColors.grey400,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
                // Title overlay
                pw.Center(
                  child: pw.Column(
                    mainAxisAlignment: pw.MainAxisAlignment.center,
                    children: [
                      pw.Text(
                        'Single Tree',
                        style: pw.TextStyle(
                          fontSize: 32,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.black,
                        ),
                      ),
                      pw.SizedBox(height: 8),
                      pw.Text(
                        'Assessment',
                        style: pw.TextStyle(
                          fontSize: 32,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.black,
                        ),
                      ),
                      pw.SizedBox(height: 40),
                      pw.Text(
                        'Tree ID: ${tree.id}',
                        style: pw.TextStyle(
                          fontSize: 18,
                          color: PdfColors.black,
                        ),
                      ),
                      pw.SizedBox(height: 8),
                      pw.Text(
                        'Species: ${tree.species ?? 'Unknown'}',
                        style: pw.TextStyle(
                          fontSize: 16,
                          color: PdfColors.black,
                        ),
                      ),
                      pw.SizedBox(height: 20),
                      pw.Text(
                        'Date: ${DateTime.now().toString().split(' ')[0]}',
                        style: pw.TextStyle(
                          fontSize: 14,
                          color: PdfColors.black,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );

    // Tree Details
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                'Tree Details',
                style: pw.TextStyle(
                  fontSize: 20,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 16),
              pw.Table(
                border: pw.TableBorder.all(),
                children: [
                  pw.TableRow(
                    children: [
                      pw.Padding(
                        padding: pw.EdgeInsets.all(8),
                        child: pw.Text('Tree ID', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                      ),
                      pw.Padding(
                        padding: pw.EdgeInsets.all(8),
                        child: pw.Text(tree.id.toString()),
                      ),
                    ],
                  ),
                  pw.TableRow(
                    children: [
                      pw.Padding(
                        padding: pw.EdgeInsets.all(8),
                        child: pw.Text('Species', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                      ),
                      pw.Padding(
                        padding: pw.EdgeInsets.all(8),
                        child: pw.Text(tree.species ?? 'Unknown'),
                      ),
                    ],
                  ),
                  pw.TableRow(
                    children: [
                      pw.Padding(
                        padding: pw.EdgeInsets.all(8),
                        child: pw.Text('DSH', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                      ),
                      pw.Padding(
                        padding: pw.EdgeInsets.all(8),
                        child: pw.Text('${tree.dsh ?? ''} cm'),
                      ),
                    ],
                  ),
                  pw.TableRow(
                    children: [
                      pw.Padding(
                        padding: pw.EdgeInsets.all(8),
                        child: pw.Text('Height', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                      ),
                      pw.Padding(
                        padding: pw.EdgeInsets.all(8),
                        child: pw.Text('${tree.height ?? ''} m'),
                      ),
                    ],
                  ),
                  pw.TableRow(
                    children: [
                      pw.Padding(
                        padding: pw.EdgeInsets.all(8),
                        child: pw.Text('Condition', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                      ),
                      pw.Padding(
                        padding: pw.EdgeInsets.all(8),
                        child: pw.Text(tree.condition ?? ''),
                      ),
                    ],
                  ),
                  pw.TableRow(
                    children: [
                      pw.Padding(
                        padding: pw.EdgeInsets.all(8),
                        child: pw.Text('Retention Value', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                      ),
                      pw.Padding(
                        padding: pw.EdgeInsets.all(8),
                        child: pw.Text(tree.retentionValue ?? ''),
                      ),
                    ],
                  ),
                  pw.TableRow(
                    children: [
                      pw.Padding(
                        padding: pw.EdgeInsets.all(8),
                        child: pw.Text('Risk Rating', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                      ),
                      pw.Padding(
                        padding: pw.EdgeInsets.all(8),
                        child: pw.Text(tree.overallRiskRating ?? ''),
                      ),
                    ],
                  ),
                  pw.TableRow(
                    children: [
                      pw.Padding(
                        padding: pw.EdgeInsets.all(8),
                        child: pw.Text('Location', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                      ),
                      pw.Padding(
                        padding: pw.EdgeInsets.all(8),
                        child: pw.Text('${tree.latitude}, ${tree.longitude}'),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );

    // Risk Assessment
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                'Risk Assessment',
                style: pw.TextStyle(
                  fontSize: 20,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 16),
              pw.Text(
                'VTA (Visual Tree Assessment) Results:',
                style: pw.TextStyle(
                  fontSize: 16,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 8),
              pw.Text(
                'Likelihood of Failure: ${tree.likelihoodOfFailure ?? 'Not assessed'}\n'
                'Likelihood of Impacting Target: ${tree.likelihoodOfImpact ?? 'Not assessed'}\n'
                'Consequence of Failure: ${tree.consequenceOfFailure ?? 'Not assessed'}\n'
                'Overall Risk Rating: ${tree.overallRiskRating ?? 'Not assessed'}',
                style: pw.TextStyle(fontSize: 12),
              ),
              pw.SizedBox(height: 16),
              pw.Text(
                'Defects Observed:',
                style: pw.TextStyle(
                  fontSize: 14,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 8),
              pw.Text(
                tree.defectsObserved.isNotEmpty ? tree.defectsObserved.join(', ') : 'None observed',
                style: pw.TextStyle(fontSize: 12),
              ),
              pw.SizedBox(height: 16),
              pw.Text(
                'VTA Notes:',
                style: pw.TextStyle(
                  fontSize: 14,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 8),
              pw.Text(
                tree.vtaNotes ?? 'No VTA notes recorded',
                style: pw.TextStyle(fontSize: 12),
              ),
            ],
          );
        },
      ),
    );

    // Recommendations
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                'Recommendations',
                style: pw.TextStyle(
                  fontSize: 20,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 16),
              pw.Text(
                'Immediate Actions:',
                style: pw.TextStyle(
                  fontSize: 16,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 8),
              pw.Text(
                tree.recommendedWorks ?? 'No immediate actions required',
                style: pw.TextStyle(fontSize: 12),
              ),
              pw.SizedBox(height: 16),
              pw.Text(
                'Long-term Management:',
                style: pw.TextStyle(
                  fontSize: 16,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 8),
              pw.Text(
                '• Regular monitoring and assessment\n'
                '• Implement appropriate maintenance schedule\n'
                '• Consider tree protection measures if required\n'
                '• Document any changes in condition',
                style: pw.TextStyle(fontSize: 12),
              ),
            ],
          );
        },
      ),
    );

    // Save and share the PDF
    final output = await getTemporaryDirectory();
    final file = File('${output.path}/single_tree_report_${tree.id}_${widget.site.name.replaceAll(' ', '_')}.pdf');
    await file.writeAsBytes(await pdf.save());
    
    await Share.shareXFiles(
      [XFile(file.path)],
      text: 'Single Tree Assessment - ${tree.id}',
    );
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Single Tree Report PDF exported successfully')),
    );
  }

  // Helper methods for Tree Management Plan
  String _getManagementPriority(TreeEntry tree) {
    if (tree.overallRiskRating == 'High') return 'High';
    if (tree.retentionValue == 'High') return 'High';
    if (tree.condition == 'Poor') return 'Medium';
    return 'Low';
  }

  String _getNextAction(TreeEntry tree) {
    if (tree.overallRiskRating == 'High') return 'Immediate inspection';
    if (tree.condition == 'Poor') return 'Health assessment';
    if (tree.retentionValue == 'High') return 'Protection measures';
    return 'Regular monitoring';
  }

  // Helper method for Table of Contents
  pw.Widget _buildTableOfContents() {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        _buildTocEntry('1 Summary', 3),
        _buildTocEntry('2 Assignment', 3),
        _buildTocSubEntry('2.1 Author / Consulting Arborist', 3),
        _buildTocSubEntry('2.2 Client', 3),
        _buildTocSubEntry('2.3 Brief', 3),
        _buildTocEntry('3 Data collection', 4),
        _buildTocSubEntry('3.1 Site Visit', 4),
        _buildTocSubEntry('3.2 Method of data collection', 4),
        _buildTocEntry('4 Site description', 5),
        _buildTocEntry('5 Tree data', 8),
        _buildTocSubEntry('5.1 Photographic evidence', 10),
        _buildTocEntry('6 Site map', 12),
        _buildTocEntry('7 Discussion', 13),
        _buildTocSubEntry('7.1 Tree Protection zone', 13),
        _buildTocSubEntry('7.2 Structural root zone', 13),
        _buildTocSubEntry('7.3 Designing Around Trees', 13),
        _buildTocEntry('8 Conclusion', 16),
        _buildTocSubEntry('8.1 Tree retention value', 16),
        _buildTocSubEntry('8.2 Permit requirements', 17),
        _buildTocEntry('9 Recommendations', 21),
        _buildTocSubEntry('9.1 Tree retention', 21),
        _buildTocSubEntry('9.2 Tree removal', 21),
        _buildTocSubEntry('9.3 Tree Protection Measures', 22),
        _buildTocEntry('10 Limitation of Liability', 24),
        _buildTocEntry('11 References', 24),
        _buildTocEntry('12 Definition of terms', 25),
      ],
    );
  }

  pw.Widget _buildTocEntry(String title, int page) {
    return pw.Padding(
      padding: pw.EdgeInsets.only(bottom: 4),
      child: pw.Row(
        children: [
          pw.Expanded(
            child: pw.Text(
              title,
              style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold),
            ),
          ),
          pw.Text(
            'Page $page',
            style: pw.TextStyle(fontSize: 12),
          ),
        ],
      ),
    );
  }

  pw.Widget _buildTocSubEntry(String title, int page) {
    return pw.Padding(
      padding: pw.EdgeInsets.only(bottom: 2, left: 20),
      child: pw.Row(
        children: [
          pw.Expanded(
            child: pw.Text(
              title,
              style: pw.TextStyle(fontSize: 11),
            ),
          ),
          pw.Text(
            'Page $page',
            style: pw.TextStyle(fontSize: 11),
          ),
        ],
      ),
    );
  }

  String _getReportTypeDescription() {
    final reportType = widget.site.reportTypeEnum;
    return '📄 ${reportType.title}\n\nGenerates a professional Microsoft Word report using the ${reportType.code} template. All tree data, site information, and assessments will be automatically populated. AI-generated content will be included if enabled in settings.\n\nTemplate: ${reportType.templateFilename}';
  }

  void _addRemainingSections(pw.Document pdf, List<TreeEntry> selectedTrees) {
    // 6. Site map
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                '6 Site map',
                style: pw.TextStyle(
                  fontSize: 20,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 16),
              pw.Container(
                width: double.infinity,
                height: 400,
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(),
                  color: PdfColors.grey200,
                ),
                child: pw.Center(
                  child: pw.Text(
                    'Site Map with Tree Locations\n(To be generated from map data)',
                    style: pw.TextStyle(
                      color: PdfColors.grey600,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );

    // 7. Discussion
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                '7 Discussion',
                style: pw.TextStyle(
                  fontSize: 20,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 16),
              pw.Text(
                '7.1 Tree Protection zone',
                style: pw.TextStyle(
                  fontSize: 16,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 8),
              pw.Text(
                'Tree Protection Zones (TPZ) have been calculated for all trees based on their DBH. '
                'These zones must be protected during any construction activities to prevent damage to tree roots.',
                style: pw.TextStyle(fontSize: 12),
              ),
              pw.SizedBox(height: 16),
              pw.Text(
                '7.2 Structural root zone',
                style: pw.TextStyle(
                  fontSize: 16,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 8),
              pw.Text(
                'Structural Root Zones (SRZ) represent the critical root area that provides structural support. '
                'No excavation or construction should occur within these zones.',
                style: pw.TextStyle(fontSize: 12),
              ),
              pw.SizedBox(height: 16),
              pw.Text(
                '7.3 Designing Around Trees',
                style: pw.TextStyle(
                  fontSize: 16,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 8),
              pw.Text(
                'Where possible, design should accommodate existing trees. '
                'Consideration should be given to root protection, canopy clearance, and future growth requirements.',
                style: pw.TextStyle(fontSize: 12),
              ),
            ],
          );
        },
      ),
    );

    // 8. Conclusion
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                '8 Conclusion',
                style: pw.TextStyle(
                  fontSize: 20,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 16),
              pw.Text(
                '8.1 Tree retention value',
                style: pw.TextStyle(
                  fontSize: 16,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 8),
              pw.Text(
                'High retention value: ${selectedTrees.where((t) => t.retentionValue == 'High').length} trees\n'
                'Moderate retention value: ${selectedTrees.where((t) => t.retentionValue == 'Moderate').length} trees\n'
                'Low retention value: ${selectedTrees.where((t) => t.retentionValue == 'Low').length} trees',
                style: pw.TextStyle(fontSize: 12),
              ),
              pw.SizedBox(height: 16),
              pw.Text(
                '8.2 Permit requirements',
                style: pw.TextStyle(
                  fontSize: 16,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 8),
              pw.Text(
                'Trees requiring permits: ${selectedTrees.where((t) => t.permitRequired).length}\n'
                'Local law considerations apply to trees with DBH > 30cm\n'
                'Significant Landscape Overlay considerations may apply',
                style: pw.TextStyle(fontSize: 12),
              ),
            ],
          );
        },
      ),
    );

    // 9. Recommendations
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                '9 Recommendations',
                style: pw.TextStyle(
                  fontSize: 20,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 16),
              pw.Text(
                '9.1 Tree retention',
                style: pw.TextStyle(
                  fontSize: 16,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 8),
              pw.Text(
                '• Retain all trees with high retention value\n'
                '• Implement tree protection measures for retained trees\n'
                '• Consider tree health monitoring program',
                style: pw.TextStyle(fontSize: 12),
              ),
              pw.SizedBox(height: 16),
              pw.Text(
                '9.2 Tree removal',
                style: pw.TextStyle(
                  fontSize: 16,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 8),
              pw.Text(
                '• Remove trees with low retention value and high risk\n'
                '• Obtain necessary permits before removal\n'
                '• Consider replacement planting where appropriate',
                style: pw.TextStyle(fontSize: 12),
              ),
              pw.SizedBox(height: 16),
              pw.Text(
                '9.3 Tree Protection Measures',
                style: pw.TextStyle(
                  fontSize: 16,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 8),
              pw.Text(
                '• Install tree protection fencing around TPZ\n'
                '• Post tree protection signage\n'
                '• Implement ground protection measures\n'
                '• Prohibit storage and construction within TPZ',
                style: pw.TextStyle(fontSize: 12),
              ),
            ],
          );
        },
      ),
    );

    // 10. Limitation of Liability
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                '10 Limitation of Liability',
                style: pw.TextStyle(
                  fontSize: 20,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 16),
              pw.Text(
                'This assessment is based on visual inspection only. Hidden defects may not be apparent. '
                'The assessment does not include root investigation or detailed structural analysis. '
                'Recommendations should be reviewed by qualified professionals before implementation.',
                style: pw.TextStyle(fontSize: 12),
              ),
            ],
          );
        },
      ),
    );

    // 11. References
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                '11 References',
                style: pw.TextStyle(
                  fontSize: 20,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 16),
              pw.Text(
                '• AS 4970-2009 Protection of trees on development sites\n'
                '• Local Planning Scheme\n'
                '• Tree Protection Guidelines\n'
                '• VTA (Visual Tree Assessment) methodology',
                style: pw.TextStyle(fontSize: 12),
              ),
            ],
          );
        },
      ),
    );

    // 12. Definition of terms
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                '12 Definition of terms',
                style: pw.TextStyle(
                  fontSize: 20,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 16),
              pw.Text(
                '12.1 Tree health\n'
                'Overall condition of the tree including foliage, bark, and general vigor.',
                style: pw.TextStyle(fontSize: 12),
              ),
              pw.SizedBox(height: 8),
              pw.Text(
                '12.2 Structure\n'
                'Physical integrity of the tree including trunk, branches, and root system.',
                style: pw.TextStyle(fontSize: 12),
              ),
              pw.SizedBox(height: 8),
              pw.Text(
                '12.3 Useful Life Expectancy (ULE)\n'
                'Expected remaining lifespan of the tree under current conditions.',
                style: pw.TextStyle(fontSize: 12),
              ),
              pw.SizedBox(height: 8),
              pw.Text(
                '12.4 Tree Retention Value\n'
                'Assessment of the tree\'s importance based on species, size, condition, and location.',
                style: pw.TextStyle(fontSize: 12),
              ),
              pw.SizedBox(height: 8),
              pw.Text(
                '12.5 TPZ (Tree Protection Zone)\n'
                'Area around tree roots that must be protected during construction.',
                style: pw.TextStyle(fontSize: 12),
              ),
              pw.SizedBox(height: 8),
              pw.Text(
                '12.6 SRZ (Structural Root Zone)\n'
                'Critical root area providing structural support to the tree.',
                style: pw.TextStyle(fontSize: 12),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _exportAsDocx() async {
    // TODO: Fix DOCX template API
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('DOCX export temporarily disabled')),
    );
  }

  Future<void> _syncNow() async {
    setState(() {
      _syncing = true;
      _syncStatus = 'Syncing...';
    });
    try {
      await TreeSyncService.syncAll(widget.site.id);
      setState(() {
        _syncStatus = 'Up to date';
      });
    } catch (e) {
      setState(() {
        _syncStatus = 'Sync error';
      });
    } finally {
      setState(() {
        _syncing = false;
      });
    }
  }

  Future<void> _exportSiteMap() async {
    try {
      final imagePath = await MapExportService.exportSiteMapAsPng(
        widget.site,
        showSRZ: true,
        showNRZ: true,
        showTreeNumbers: true,
        satelliteView: false,
      );
      
      if (imagePath != null) {
        await MapExportService.shareMapImage(imagePath);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Site map exported successfully')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No trees found to create site map')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error exporting site map: $e')),
      );
    }
  }

  Future<void> _exportIndividualTreeMaps() async {
    try {
      final trees = TreeStorageService.getTreesForSite(widget.site.id);
      if (trees.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No trees found in site')),
        );
        return;
      }

      // Show progress dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 16),
              Text('Creating ${trees.length} individual tree maps...'),
            ],
          ),
        ),
      );

      final paths = await MapExportService.exportAllTreeMaps(
        widget.site,
        showSRZ: true,
        showNRZ: true,
        satelliteView: false,
      );

      Navigator.of(context).pop(); // Close progress dialog

      if (paths.isNotEmpty) {
        await MapExportService.shareMapImage(paths.first);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Created ${paths.length} individual tree maps')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to create individual tree maps')),
        );
      }
    } catch (e) {
      Navigator.of(context).pop(); // Close progress dialog if still open
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error creating individual tree maps: $e')),
      );
    }
  }

  Future<void> _exportSatelliteMap() async {
    try {
      final imagePath = await MapExportService.exportSiteMapAsPng(
        widget.site,
        showSRZ: true,
        showNRZ: true,
        showTreeNumbers: true,
        satelliteView: true,
      );
      
      if (imagePath != null) {
        await MapExportService.shareMapImage(imagePath);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Satellite map exported successfully')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No trees found to create satellite map')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error exporting satellite map: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            children: [
              // Sync Controls
              Row(
                children: [
                  const Icon(Icons.description, color: Colors.blue),
                  const SizedBox(width: 8),
                  const Text('Word Report Export', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const Spacer(),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.sync),
                    label: Text(_syncing ? 'Syncing...' : 'Sync Now'),
                    onPressed: _syncing ? null : _syncNow,
                  ),
                  const SizedBox(width: 16),
                  Text(_syncStatus, style: TextStyle(color: _syncStatus == 'Up to date' ? Colors.green : (_syncStatus == 'Sync error' ? Colors.red : Colors.orange))),
                ],
              ),
              const SizedBox(height: 16),
              // Export Controls
              Row(
                children: [
                  Checkbox(
                    value: _selectAll,
                    onChanged: (v) => _toggleSelectAll(),
                  ),
                  const Text('Select All'),
                  const Spacer(),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.preview),
                    label: const Text('Preview'),
                    onPressed: _showPreview,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue.shade100,
                      foregroundColor: Colors.blue.shade800,
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.download),
                    label: const Text('Export'),
                    onPressed: _exportData,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green.shade100,
                      foregroundColor: Colors.green.shade800,
                    ),
                  ),
                  const Spacer(),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.download),
                    label: const Text('Export Word Report'),
                    onPressed: _selectedIndexes.isEmpty ? null : _exportData,
                  ),
                ],
              ),
              // Report Type Description
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  _getReportTypeDescription(),
                  style: TextStyle(fontSize: 12, color: Colors.blue.shade800),
                ),
              ),
              const SizedBox(height: 16),
              
              // Auto-scheduling Section
              _buildAutoScheduling(),
              const SizedBox(height: 16),
              
              // Batch Processing Progress
              if (_isBatchProcessing) ...[
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.sync, color: Colors.blue),
                            const SizedBox(width: 8),
                            Text(
                              'Batch Processing',
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const Spacer(),
                            Text('$_batchProgress%'),
                          ],
                        ),
                        const SizedBox(height: 12),
                        LinearProgressIndicator(
                          value: _batchProgress / 100,
                          backgroundColor: Colors.grey[300],
                          valueColor: const AlwaysStoppedAnimation<Color>(Colors.blue),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Processing ${_selectedIndexes.length} trees...',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],
              
              // Map Export Section
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.map, color: Colors.green.shade700),
                        const SizedBox(width: 8),
                        Text(
                          'Map Exports',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.green.shade700,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            icon: const Icon(Icons.map_outlined),
                            label: const Text('Site Map'),
                            onPressed: _exportSiteMap,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green.shade100,
                              foregroundColor: Colors.green.shade800,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: ElevatedButton.icon(
                            icon: const Icon(Icons.forest),
                            label: const Text('Individual Trees'),
                            onPressed: _exportIndividualTreeMaps,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green.shade100,
                              foregroundColor: Colors.green.shade800,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: ElevatedButton.icon(
                            icon: const Icon(Icons.satellite),
                            label: const Text('Satellite View'),
                            onPressed: _exportSatelliteMap,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green.shade100,
                              foregroundColor: Colors.green.shade800,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Export maps as PNG images for reports. Site Map shows all trees, Individual Trees creates separate maps for each tree.',
                      style: TextStyle(fontSize: 11, color: Colors.green.shade600),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.separated(
            itemCount: _trees.length,
            separatorBuilder: (context, index) => const Divider(),
            itemBuilder: (context, idx) {
              final tree = _trees[idx];
              return ListTile(
                leading: Checkbox(
                  value: _selectedIndexes.contains(idx),
                  onChanged: (v) => _toggleSelect(idx),
                ),
                title: Text(tree.id),
                subtitle: Text('Species: ${tree.species}, DSH: ${tree.dsh} cm, Height: ${tree.height} m'),
              );
            },
          ),
        ),
        const Divider(height: 1),
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Text('Professional PDF reports include comprehensive tree data, risk assessment, and recommendations. Single Tree Report requires exactly one tree selection.'),
        ),
      ],
    );
  }

  // Enhanced Export Methods
  Future<void> _showWordTemplateDialog() async {
    final templates = EnhancedExportService.getWordTemplates();
    final selectedTemplate = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Word Template'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: templates.length,
            itemBuilder: (context, index) {
              return ListTile(
                title: Text(templates[index]),
                onTap: () => Navigator.of(context).pop(templates[index]),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );

    if (selectedTemplate != null) {
      try {
        NotificationService.showLoadingDialog(context, 'Generating Word document...');
        await EnhancedExportService.exportAsWordDocument(widget.site, selectedTemplate);
        Navigator.of(context).pop(); // Close loading dialog
        NotificationService.showSuccess(context, 'Word document generated successfully');
      } catch (e) {
        Navigator.of(context).pop(); // Close loading dialog
        NotificationService.showError(context, 'Failed to generate Word document: $e');
      }
    }
  }

  Future<void> _showPdfTemplateDialog() async {
    final templates = EnhancedExportService.getPdfTemplates();
    final selectedTemplate = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select PDF Template'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: templates.length,
            itemBuilder: (context, index) {
              return ListTile(
                title: Text(templates[index]),
                onTap: () => Navigator.of(context).pop(templates[index]),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );

    if (selectedTemplate != null) {
      try {
        NotificationService.showLoadingDialog(context, 'Generating PDF...');
        await EnhancedExportService.exportAsPdf(widget.site, selectedTemplate);
        Navigator.of(context).pop(); // Close loading dialog
        NotificationService.showSuccess(context, 'PDF generated successfully');
      } catch (e) {
        Navigator.of(context).pop(); // Close loading dialog
        NotificationService.showError(context, 'Failed to generate PDF: $e');
      }
    }
  }



  Future<void> _exportComprehensiveReport() async {
    try {
      NotificationService.showLoadingDialog(context, 'Generating comprehensive report...');
      await EnhancedExportService.exportComprehensiveReport(widget.site);
      Navigator.of(context).pop(); // Close loading dialog
      NotificationService.showSuccess(context, 'Comprehensive report generated successfully');
    } catch (e) {
      Navigator.of(context).pop(); // Close loading dialog
      NotificationService.showError(context, 'Failed to generate comprehensive report: $e');
    }
  }

  /// Export complete package: DOCX Report + CSV Data + Site Map Image
  Future<void> _exportCompletePackage() async {
    try {
      NotificationService.showLoadingDialog(context, 'Creating complete report package...\n\n• Professional DOCX Report\n• Tree Data CSV\n• Site Map Image');
      
      // Generate all three exports
      await Future.wait([
        EnhancedExportService.exportSiteReport(widget.site), // DOCX using template
        _exportAsCsv(), // CSV data
        _exportSiteMap(), // Map image
      ]);
      
      Navigator.of(context).pop(); // Close loading dialog
      NotificationService.showSuccess(
        context, 
        'Complete package exported!\n\n✓ DOCX Report (${widget.site.reportTypeEnum.title})\n✓ Tree Data CSV\n✓ Site Map Image'
      );
    } catch (e) {
      Navigator.of(context).pop(); // Close loading dialog
      NotificationService.showError(context, 'Failed to create complete package: $e');
    }
  }

  /// Export professional DOCX report using appropriate template
  Future<void> _exportProfessionalReport() async {
    try {
      final reportType = widget.site.reportTypeEnum;
      NotificationService.showLoadingDialog(
        context, 
        'Generating ${reportType.code} Report...\n\n${reportType.title}\n\nUsing professional DOCX template'
      );
      
      await EnhancedExportService.exportSiteReport(widget.site);
      
      Navigator.of(context).pop(); // Close loading dialog
      NotificationService.showSuccess(
        context, 
        'Professional report generated!\n\n${reportType.code} - ${reportType.title}\n\nTemplate: ${reportType.templateFilename}'
      );
    } catch (e) {
      Navigator.of(context).pop(); // Close loading dialog
      NotificationService.showError(context, 'Failed to generate professional report: $e');
    }
  }
}
