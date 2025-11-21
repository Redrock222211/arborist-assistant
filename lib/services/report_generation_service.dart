import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:archive/archive.dart';
import 'package:docx_template/docx_template.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../models/site.dart';
import '../models/tree_entry.dart';
import '../models/report_type.dart';
import '../utils/platform_download_stub.dart'
    if (dart.library.html) '../utils/platform_download_web.dart'
    if (dart.library.io) '../utils/platform_download_io.dart';
import 'ai_report_service.dart';
import 'advanced_docx_service.dart';
import 'direct_docx_service.dart';
import 'map_export_service.dart';

/// Service for generating professional DOCX reports using templates
class ReportGenerationService {
  static const String _templatesPath = 'assets/ArboristsByNature_Windsurf_AS4970_2025/';

  /// Generate a report for a site using the appropriate template
  static Future<Uint8List> generateReport({
    required Site site,
    required List<TreeEntry> trees,
    ReportType? reportType,
  }) async {
    try {
      // Use site's report type if not specified
      final type = reportType ?? site.reportTypeEnum;
      print('📝 Loading template for: ${type.code}');
      
      // Load the template
      final templatePath = '$_templatesPath${type.templateFilename}';
      print('📂 Template path: $templatePath');
      
      ByteData templateBytes;
      try {
        templateBytes = await rootBundle.load(templatePath);
        print('✅ Template loaded: ${templateBytes.lengthInBytes} bytes');
      } catch (e) {
        print('❌ Failed to load template: $e');
        print('❌ Attempted path: $templatePath');
        // Return a minimal valid DOCX structure if template fails
        return _createMinimalDocx('Template loading failed: ${e.toString()}');
      }
      
      // Get template as Uint8List
      final bytes = templateBytes.buffer.asUint8List();
      print('✅ Template bytes ready: ${bytes.length} bytes');
      
      // Normalize template placeholders to docx_template format
      final normalizedBytes = await _normalizeTemplatePlaceholders(bytes);

      // Prepare base data for template
      final data = await _prepareTemplateData(site, trees, type);
      print('✅ Template data prepared: ${data.length} fields');
      
      // Generate AI content if enabled
      final aiEnabled = await AIReportService.isOpenAIEnabled();
      if (aiEnabled) {
        try {
          print('🤖 Generating AI report sections...');
          final aiSections = await AIReportService.generateReportSections(
            site: site,
            trees: trees,
            reportType: type,
          );
          // Add each AI section individually to avoid unmodifiable collection issues
          aiSections.forEach((key, value) {
            data[key] = value;
          });
          print('✅ AI sections added to template data');
        } catch (e) {
          print('⚠️  AI generation failed, using default text: $e');
        }
      }
      
      // Debug: Print sample of available fields
      print('📋 Sample template data fields:');
      int fieldCount = 0;
      data.forEach((key, value) {
        if (fieldCount < 10 && value is! List && value is! Uint8List) {
          print('  - $key: ${value?.toString() ?? "(empty)"}');
          fieldCount++;
        }
      });
      print('  ... and ${data.length - fieldCount} more fields');
      
      print('🔄 Using DirectDocxService for template processing...');
      
      // Prepare images if available
      final images = <String, Uint8List>{};
      if (trees.isNotEmpty) {
        // Add images from first tree if available
        final firstTree = trees.first;
        if (firstTree.imageLocalPaths.isNotEmpty) {
          final imageTypes = ['canopy', 'base', 'context', 'defects'];
          for (int i = 0; i < imageTypes.length && i < firstTree.imageLocalPaths.length; i++) {
            final imagePath = firstTree.imageLocalPaths[i];
            if (imagePath.isNotEmpty) {
              try {
                final bytes = await _loadImageBytes(imagePath);
                if (bytes != null && bytes.isNotEmpty) {
                  images['insert_image_tree1_${imageTypes[i]}'] = bytes;
                  print('✅ Added image: tree1_${imageTypes[i]}');
                } else {
                  print('⚠️ Could not load image: $imagePath');
                }
              } catch (e) {
                print('⚠️ Could not load image: $e');
              }
            }
          }
        }
      }
      
      // Add site map if available (from data)
      if (data['site_map_image'] != null && data['site_map_image'] is Uint8List) {
        images['site_map_image'] = data['site_map_image'] as Uint8List;
        images['insert_site_map'] = data['site_map_image'] as Uint8List;
      }
      
      // Use DirectDocxService to process the template
      final processedBytes = await DirectDocxService.generateFromTemplate(
        templateBytes: normalizedBytes,
        data: data,
        images: images,
      );
      
      print('✅ Document processed: ${processedBytes.length} bytes');
      return processedBytes;
    } catch (e, stackTrace) {
      print('❌ ERROR in generateReport: $e');
      print('Stack trace: $stackTrace');
      rethrow;
    }
  }

  static Content _buildDocxContent(Map<String, dynamic> data) {
    final content = Content();
    data.forEach((key, value) {
      _insertContent(content, key, value);
    });
    return content;
  }

  static void _insertContent(Content parent, String key, dynamic value) {
    if (value == null) {
      parent.add(TextContent(key, ''));
      return;
    }

    if (value is Uint8List) {
      parent.add(ImageContent(key, value));
      return;
    }

    if (value is List<Map<String, dynamic>>) {
      parent.add(_buildTableContent(key, value));
      return;
    }

    if (value is List) {
      parent.add(TextContent(key, value.map(_valueToString).join(', ')));
      return;
    }

    if (value is Map<String, dynamic>) {
      parent.add(_buildTableContent(key, [value]));
      return;
    }

    parent.add(TextContent(key, _valueToString(value)));
  }

  static TableContent _buildTableContent(String key, List<Map<String, dynamic>> rowsData) {
    final rows = <RowContent>[];
    for (final rowData in rowsData) {
      final row = RowContent();
      rowData.forEach((cellKey, cellValue) {
        if (cellValue is Uint8List) {
          row.add(ImageContent(cellKey, cellValue));
        } else if (cellValue is List<Map<String, dynamic>>) {
          row.add(_buildTableContent(cellKey, cellValue));
        } else if (cellValue is List) {
          row.add(TextContent(cellKey, cellValue.map(_valueToString).join(', ')));
        } else {
          row.add(TextContent(cellKey, _valueToString(cellValue)));
        }
      });
      rows.add(row);
    }
    return TableContent(key, rows);
  }

  static String _valueToString(dynamic value) {
    if (value == null) return '';
    if (value is bool) return value ? 'Yes' : 'No';
    if (value is num) return value.toString();
    if (value is DateTime) return DateFormat('dd/MM/yyyy').format(value);
    return value.toString();
  }

  static Future<Uint8List?> _loadImageBytes(String source) async {
    try {
      if (source.isEmpty) {
        return null;
      }

      if (source.startsWith('data:')) {
        final base64Section = source.contains(',') ? source.split(',').last : '';
        if (base64Section.isEmpty) {
          return null;
        }
        return base64Decode(base64Section);
      }

      if (source.startsWith('http')) {
        final response = await http.get(Uri.parse(source));
        if (response.statusCode == 200) {
          return response.bodyBytes;
        }
        print('⚠️  HTTP image request failed (${response.statusCode}) for $source');
        return null;
      }

      if (!kIsWeb) {
        final file = File(source);
        if (await file.exists()) {
          return await file.readAsBytes();
        }
        print('⚠️  Local image file missing: $source');
        return null;
      }

      if (source.startsWith('blob:')) {
        print('⚠️  Blob URLs cannot be reloaded after page refresh: $source');
        return null;
      }

      print('⚠️  Unsupported image source: $source');
      return null;
    } catch (e) {
      print('⚠️  Error resolving image bytes for $source: $e');
      return null;
    }
  }

  /// Extract simple scalar values for secondary template processing.
  static Map<String, dynamic> _extractSimpleValues(Map<String, dynamic> data) {
    final result = <String, dynamic>{};
    data.forEach((key, value) {
      if (value == null) return;
      if (value is Uint8List) return;
      if (value is Map) return;
      if (value is List) return;
      result[key] = _valueToString(value);
    });
    return result;
  }

  static List<String> _prepareTreeRow(TreeEntry tree) {
    return [
      tree.id,
      tree.species,
      tree.dsh.toString(),
      tree.height.toString(),
      tree.condition,
      tree.riskRating,
      tree.permitRequired ? 'Yes' : 'No',
      tree.locationDescription,
      tree.recommendedWorks,
      tree.inspectionDate != null ? DateFormat('dd/MM/yyyy').format(tree.inspectionDate!) : '',
      tree.inspectorName,
    ];
  }

  static void _addIndexedTreeFields(Map<String, dynamic> data, List<TreeEntry> trees) {
    for (var i = 0; i < trees.length; i++) {
      final tree = trees[i];
      final prefix = 'tree_${i + 1}_';
      data['${prefix}id'] = tree.id;
      data['${prefix}species'] = tree.species;
      data['${prefix}dsh'] = tree.dsh.toString();
      data['${prefix}height'] = tree.height.toString();
      data['${prefix}condition'] = tree.condition;
      data['${prefix}risk_rating'] = tree.riskRating;
      data['${prefix}permit_required'] = tree.permitRequired ? 'Yes' : 'No';
      data['${prefix}recommended_works'] = tree.recommendedWorks;
      data['${prefix}location'] = tree.locationDescription;
      data['${prefix}inspection_date'] =
          tree.inspectionDate != null ? DateFormat('dd/MM/yyyy').format(tree.inspectionDate!) : '';
      data['${prefix}inspector'] = tree.inspectorName;
    }
    data['tree_count'] = trees.length;
  }

  /// Convert legacy ${placeholder} syntax to {{placeholder}} for docx_template compatibility.
  static Future<Uint8List> _normalizeTemplatePlaceholders(Uint8List templateBytes) async {
    final decoded = ZipDecoder().decodeBytes(templateBytes);
    final placeholderPattern = RegExp(r'\$\{([A-Za-z0-9_]+)\}');

    bool modified = false;
    final rebuilt = Archive();

    for (final file in decoded.files) {
      if (!file.isFile) {
        rebuilt.addFile(file);
        continue;
      }

      final data = file.content as List<int>;
      List<int> updatedBytes = data;

      if (file.name.startsWith('word/') && file.name.endsWith('.xml')) {
        final original = utf8.decode(data);
        final updated = original.replaceAllMapped(
          placeholderPattern,
          (match) => '{{${match[1]}}}',
        );
        if (updated != original) {
          modified = true;
          updatedBytes = utf8.encode(updated);
        }
      }

      rebuilt.addFile(ArchiveFile(file.name, updatedBytes.length, updatedBytes));
    }

    if (!modified) {
      return templateBytes;
    }

    final encoded = ZipEncoder().encode(rebuilt);
    return Uint8List.fromList(encoded!);
  }

  /// Export a generated report as a file
  static Future<String> exportReport({
    required Site site,
    required List<TreeEntry> trees,
    ReportType? reportType,
  }) async {
    final bytes = await generateReport(
      site: site,
      trees: trees,
      reportType: reportType,
    );
    
    final type = reportType ?? site.reportTypeEnum;
    final dateFormat = DateFormat('yyyyMMdd_HHmmss');
    final timestamp = dateFormat.format(DateTime.now());
    final fileName = '${site.name.replaceAll(' ', '_')}_${type.code}_$timestamp.docx';
    
    // Save to temporary directory
    final directory = await getTemporaryDirectory();
    final file = File('${directory.path}/$fileName');
    await file.writeAsBytes(bytes);
    
    return file.path;
  }

  /// Create a minimal valid DOCX file with error message
  static Uint8List _createMinimalDocx(String errorMessage) {
    // This creates a minimal valid DOCX structure
    final archive = Archive();
    
    // Add minimal document.xml
    final docContent = '''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<w:document xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main">
  <w:body>
    <w:p>
      <w:r>
        <w:t>Error: $errorMessage</w:t>
      </w:r>
    </w:p>
  </w:body>
</w:document>''';
    
    archive.addFile(ArchiveFile('word/document.xml', docContent.length, docContent.codeUnits));
    
    // Add minimal content types
    final contentTypes = '''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types">
  <Default Extension="rels" ContentType="application/vnd.openxmlformats-package.relationships+xml"/>
  <Default Extension="xml" ContentType="application/xml"/>
  <Override PartName="/word/document.xml" ContentType="application/vnd.openxmlformats-officedocument.wordprocessingml.document.main+xml"/>
</Types>''';
    
    archive.addFile(ArchiveFile('[Content_Types].xml', contentTypes.length, contentTypes.codeUnits));
    
    // Add minimal relationships
    final rels = '''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">
  <Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/officeDocument" Target="word/document.xml"/>
</Relationships>''';
    
    archive.addFile(ArchiveFile('_rels/.rels', rels.length, rels.codeUnits));
    
    // Encode to ZIP
    final encoder = ZipEncoder();
    return Uint8List.fromList(encoder.encode(archive)!);
  }

  /// Share a generated report
  static Future<void> shareReport({
    required Site site,
    required List<TreeEntry> trees,
    ReportType? reportType,
  }) async {
    try {
      print('🔍 Starting DOCX report generation...');
      print('📄 Site: ${site.name}');
      print('📊 Trees: ${trees.length}');
      
      final type = reportType ?? site.reportTypeEnum;
      print('📋 Report Type: ${type.code} - ${type.title}');
      print('📁 Template: ${type.templateFilename}');
      
      final bytes = await generateReport(
        site: site,
        trees: trees,
        reportType: reportType,
      );
      
      print('✅ DOCX generated: ${bytes.length} bytes');
      
      final dateFormat = DateFormat('yyyyMMdd_HHmmss');
      final timestamp = dateFormat.format(DateTime.now());
      final fileName = '${site.name.replaceAll(' ', '_')}_${type.code}_$timestamp.docx';
      
      if (kIsWeb) {
        // Web: Use browser download
        print('🌐 Downloading on web...');
        await downloadFile(
          bytes,
          fileName,
          'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
        );
        print('✅ Web download initiated');
      } else {
        // Mobile/Desktop: Use share
        print('📱 Sharing on mobile/desktop...');
        final directory = await getTemporaryDirectory();
        final file = File('${directory.path}/$fileName');
        await file.writeAsBytes(bytes);
        
        await Share.shareXFiles(
          [XFile(file.path)],
          text: '${type.title} - ${site.name}',
        );
        print('✅ Share dialog opened');
      }
    } catch (e, stackTrace) {
      print('❌ ERROR in shareReport: $e');
      print('Stack trace: $stackTrace');
      rethrow;
    }
  }

  /// Prepare data map for template merge
  static Future<Map<String, dynamic>> _prepareTemplateData(
    Site site,
    List<TreeEntry> trees,
    ReportType reportType,
  ) async {
    final now = DateTime.now();
    final dateFormat = DateFormat('dd MMMM yyyy');
    final shortDateFormat = DateFormat('dd/MM/yyyy');
    
    // Try to get site map image
    Uint8List? siteMapImage;
    try {
      print('📸 Capturing site map image...');
      siteMapImage = await MapExportService.captureSiteMapImage(
        site,
        showSRZ: true,
        showNRZ: true,
      );
      if (siteMapImage != null) {
        print('✅ Site map image captured: ${siteMapImage.length} bytes');
      }
    } catch (e) {
      print('⚠️  Could not capture site map: $e');
    }
    
    // Base data available in all templates (explicitly mutable)
    final data = Map<String, dynamic>.from(<String, dynamic>{
      // Site information - matching template placeholders
      'site_name': site.name,
      'project_name': site.name,  // Templates use this
      'site_address': site.address,
      'site_notes': site.notes,
      'site_latitude': site.latitude?.toStringAsFixed(6) ?? '',
      'site_longitude': site.longitude?.toStringAsFixed(6) ?? '',
      
      // Report metadata - matching template format
      'report_date': dateFormat.format(now),
      'signature_date': dateFormat.format(now),
      'report_date_short': shortDateFormat.format(now),
      'report_type': reportType.title,
      'report_code': reportType.code,
      
      // Inspector/Assessor information (from first tree or defaults)
      'assessor_name': trees.isNotEmpty && trees.first.inspectorName.isNotEmpty ? 
        trees.first.inspectorName : 'Senior Arborist',
      'assessor_qualifications': 'Diploma of Arboriculture (AQF5)',
      'inspector_name': trees.isNotEmpty && trees.first.inspectorName.isNotEmpty ? 
        trees.first.inspectorName : 'Senior Arborist',
      
      // Site context (from first tree or defaults)
      'site_context': trees.isNotEmpty && trees.first.siteType.isNotEmpty ? 
        trees.first.siteType : 'Urban residential environment',
      'adjacent_land_use': trees.isNotEmpty && trees.first.landUseZone.isNotEmpty ? 
        trees.first.landUseZone : 'Residential zone',
      'soil_description': trees.isNotEmpty && trees.first.soilType.isNotEmpty ? 
        trees.first.soilType : 'Clay loam, well-drained',
      'drainage_description': trees.isNotEmpty && trees.first.drainage.isNotEmpty ? 
        trees.first.drainage : 'Good drainage observed',
      
      // LGA and compliance
      'lga': 'Local Government Area',  // TODO: Get from site location
      'overlay_controls': trees.isNotEmpty && trees.first.planningOverlay.isNotEmpty ? 
        trees.first.planningOverlay : 'No overlays identified',
      
      // Assessment methodology
      'method_summary': 'Trees were assessed using Visual Tree Assessment (VTA) methodology in accordance with AS 4970-2009',
      'scope_of_assessment': 'Health, structure and risk assessment of all trees within the site boundary',
      'limitations': 'Assessment was limited to visual inspection from ground level. No invasive or aerial inspection was undertaken',
      'observations': 'See individual tree assessments for detailed observations',
      
      // Tree statistics
      'total_trees': trees.length,
      'trees_assessed': trees.length,

      // Tree list for table insertion
      'trees': List<Map<String, dynamic>>.from(trees.map((tree) => _prepareTreeData(tree))),
      'tree_rows': List<List<String>>.from(trees.map(_prepareTreeRow)),
    });
    
    // Expose first tree fields at top level for templates that reference
    // Add first tree data to template (for backward compatibility)
    if (trees.isNotEmpty) {
      final firstTreeData = _prepareTreeData(trees.first);
      firstTreeData.forEach((key, value) {
        data.putIfAbsent(key, () => value);
      });
    }
    
    // Add ALL trees to a list for data tables
    final treesList = <Map<String, dynamic>>[];
    for (var i = 0; i < trees.length; i++) {
      final treeData = _prepareTreeData(trees[i]);
      treeData['tree_number'] = 'Tree ${i + 1}';  // Simple sequential numbering
      treesList.add(treeData);
    }
    data['trees_list'] = treesList;
    data['trees'] = treesList;  // Alternative placeholder name

    _addIndexedTreeFields(data, trees);

    // Add site map image if available
    if (siteMapImage != null) {
      data['site_map_image'] = siteMapImage;
      data['insert_site_map'] = siteMapImage;  // Alternative placeholder name
    }
    
    // Add tree images for ALL trees
    for (int treeIndex = 0; treeIndex < trees.length; treeIndex++) {
      final tree = trees[treeIndex];
      await _addTreeImages(data, tree, treeIndex + 1);
    }
    
    // Add report-specific calculations
    _addReportSpecificData(data, trees, reportType);
    
    return data;
  }

  /// Add tree images to template data
  static Future<void> _addTreeImages(Map<String, dynamic> data, TreeEntry tree, int treeNumber) async {
    // Prepare images if available
    final images = <String, Uint8List>{};
    if (tree.imageLocalPaths.isNotEmpty) {
      try {
        // Load up to 4 images for the template placeholders
        final imageTypes = ['canopy', 'base', 'context', 'defects'];
        for (int i = 0; i < imageTypes.length && i < tree.imageLocalPaths.length; i++) {
          final imagePath = tree.imageLocalPaths[i];
          if (imagePath.isNotEmpty) {
            try {
              final bytes = await _loadImageBytes(imagePath);

              if (bytes != null && bytes.isNotEmpty) {
                images['insert_image_tree${treeNumber}_${imageTypes[i]}'] = Uint8List.fromList(bytes);
                print('✅ Added tree image: tree${treeNumber}_${imageTypes[i]}');
              } else {
                print('⚠️  Tree image unavailable for $imagePath');
              }
            } catch (e) {
              print('⚠️  Could not load tree image from $imagePath: $e');
            }
          }
        }
      } catch (e) {
        print('⚠️  Error loading tree images: $e');
      }
    }
    
    // If no local images, create placeholder data
    if (images.isEmpty) {
      if (!data.containsKey('insert_image_tree${treeNumber}_canopy')) {
        // Could add default placeholder images here if needed
        print('ℹ️  No tree images available for tree $treeNumber');
      }
    }
    
    // Add all images to the main data map
    images.forEach((key, value) {
      data[key] = value;
    });
  }

  /// Prepare individual tree data for template
  static Map<String, dynamic> _prepareTreeData(TreeEntry tree) {
    final dateFormat = DateFormat('dd/MM/yyyy');
    
    return Map<String, dynamic>.from({
      // Basic identification - matching template placeholders exactly
      'tree_id': tree.id,
      'tree_number': tree.id,
      'species': tree.species,
      'species_botanical': tree.species,  // Template uses this exact name
      'species_common': tree.species,  // TODO: Add common name lookup
      
      // Measurements - matching template format
      'dsh': tree.dsh.toString(),
      'dsh_mm': (tree.dsh * 10).toStringAsFixed(0),  // Convert cm to mm for template
      'dbh': tree.dsh.toString(),
      'height': tree.height.toString(),
      'height_m': tree.height.toStringAsFixed(1),
      'canopy_spread': tree.canopySpread.toString(),
      
      // Canopy spread directional (templates expect these)
      'canopy_spread_n': (tree.canopySpread / 4).toStringAsFixed(1),
      'canopy_spread_s': (tree.canopySpread / 4).toStringAsFixed(1),
      'canopy_spread_e': (tree.canopySpread / 4).toStringAsFixed(1),
      'canopy_spread_w': (tree.canopySpread / 4).toStringAsFixed(1),
      
      // Age and condition
      'age_class': tree.ageClass.isNotEmpty ? tree.ageClass : 'Mature',
      'condition': tree.condition,
      'health': tree.healthForm,
      'health_form': tree.healthForm,
      'health_rating': tree.vigorRating.isNotEmpty ? tree.vigorRating : tree.condition,
      'health_summary': '${tree.condition} condition with ${tree.vigorRating.isNotEmpty ? tree.vigorRating : "moderate"} vigor',
      
      // Structure assessment
      'structure_rating': tree.structuralRating.isNotEmpty ? tree.structuralRating : 'Good',
      'structural_summary': tree.structuralDefects.isNotEmpty ? 
        'Structural defects observed: ${tree.structuralDefects.join(", ")}' : 
        'No significant structural defects observed',
      
      // Risk assessment - matching template names
      'risk_rating': tree.riskRating.isNotEmpty ? tree.riskRating : 'Low',
      'overall_risk': tree.overallRiskRating.isNotEmpty ? tree.overallRiskRating : 'Low',
      'likelihood_of_failure': tree.likelihoodOfFailure.isNotEmpty ? tree.likelihoodOfFailure : 'Improbable',
      'likelihood_of_impact': tree.likelihoodOfImpact.isNotEmpty ? tree.likelihoodOfImpact : 'Very Low',
      'consequence_of_failure': tree.consequenceOfFailure.isNotEmpty ? tree.consequenceOfFailure : 'Negligible',
      
      // Protection zones - matching template format
      'srz': tree.srz.toString(),
      'srz_m': tree.srz.toStringAsFixed(1),
      'tpz': tree.nrz.toString(),
      'tpz_m': tree.nrz.toStringAsFixed(1),
      'nrz': tree.nrz.toString(),
      'nrz_m': tree.nrz.toStringAsFixed(1),
      
      // Retention and management
      'retention_value': tree.retentionValue.isNotEmpty ? tree.retentionValue : 'Moderate',
      'habitat_value': tree.habitatValue.isNotEmpty ? tree.habitatValue : 'Low',
      'recommendation': tree.recommendedWorks.isNotEmpty ? tree.recommendedWorks : 'Monitor annually',
      'recommended_works': tree.recommendedWorks,
      'permit_required': tree.permitRequired ? 'Yes' : 'No',
      
      // Monitoring
      'monitoring_frequency': tree.inspectionFrequency.isNotEmpty ? tree.inspectionFrequency : 'Annual',
      'supervision_distance': tree.arboristSupervisionRequired ? 'Within 5m' : 'Not required',
      
      // Location
      'latitude': tree.latitude.toString(),
      'longitude': tree.longitude.toString(),
      'location_description': tree.locationDescription,
      
      // Site context - from TreeEntry site fields
      'site_context': tree.siteType.isNotEmpty ? tree.siteType : 'Urban residential',
      'adjacent_land_use': tree.landUseZone.isNotEmpty ? tree.landUseZone : 'Residential',
      'soil_description': tree.soilType.isNotEmpty ? tree.soilType : 'Clay loam',
      'drainage_description': tree.drainage.isNotEmpty ? tree.drainage : 'Well drained',
      
      // Additional details
      'notes': tree.notes,
      'comments': tree.comments,
      'observations': tree.comments.isNotEmpty ? tree.comments : 'See assessment details',
      'defects': tree.defectsObserved.join(', '),
      'vta_defects': tree.vtaDefects.join(', '),
      'vta_notes': tree.vtaNotes,
      'diseases': tree.diseasesPresent,
      'pests': tree.pestPresence,
      'origin': tree.origin.isNotEmpty ? tree.origin : 'Native',
      'past_management': tree.pastManagement,
      
      // Inspection details - matching template format
      'inspection_date': tree.inspectionDate != null ? dateFormat.format(tree.inspectionDate!) : dateFormat.format(DateTime.now()),
      'inspector_name': tree.inspectorName.isNotEmpty ? tree.inspectorName : 'Arborist',
      'assessor_name': tree.inspectorName.isNotEmpty ? tree.inspectorName : 'Arborist',
      'assessor_qualifications': 'Diploma of Arboriculture (AQF5)',
      
      // Compliance and overlays
      'overlay_controls': tree.planningOverlay.isNotEmpty ? tree.planningOverlay : 'None identified',
      'lga': 'Local Government Area',  // TODO: Get from site data
      
      // Report metadata
      'limitations': 'Visual assessment from ground level only',
      'method_summary': 'Visual Tree Assessment (VTA) methodology',
      'scope_of_assessment': 'Individual tree health and structure assessment',
    });
  }

  /// Add report-specific calculations and summaries
  static void _addReportSpecificData(
    Map<String, dynamic> data,
    List<TreeEntry> trees,
    ReportType reportType,
  ) {
    // Risk distribution
    final highRisk = trees.where((t) => t.overallRiskRating.toLowerCase().contains('high')).length;
    final mediumRisk = trees.where((t) => t.overallRiskRating.toLowerCase().contains('medium') || 
                                           t.overallRiskRating.toLowerCase().contains('moderate')).length;
    final lowRisk = trees.where((t) => t.overallRiskRating.toLowerCase().contains('low')).length;
    
    data['high_risk_count'] = highRisk;
    data['medium_risk_count'] = mediumRisk;
    data['low_risk_count'] = lowRisk;
    
    // Condition distribution
    final excellent = trees.where((t) => t.condition.toLowerCase() == 'excellent').length;
    final good = trees.where((t) => t.condition.toLowerCase() == 'good').length;
    final fair = trees.where((t) => t.condition.toLowerCase() == 'fair').length;
    final poor = trees.where((t) => t.condition.toLowerCase() == 'poor').length;
    final critical = trees.where((t) => t.condition.toLowerCase() == 'critical').length;
    
    data['condition_excellent'] = excellent;
    data['condition_good'] = good;
    data['condition_fair'] = fair;
    data['condition_poor'] = poor;
    data['condition_critical'] = critical;
    
    // Permit requirements
    final permitRequired = trees.where((t) => t.permitRequired).length;
    data['permits_required_count'] = permitRequired;
    
    // Retention values
    final highRetention = trees.where((t) => t.retentionValue.toLowerCase() == 'high').length;
    final mediumRetention = trees.where((t) => t.retentionValue.toLowerCase() == 'medium').length;
    final lowRetention = trees.where((t) => t.retentionValue.toLowerCase() == 'low').length;
    
    data['retention_high'] = highRetention;
    data['retention_medium'] = mediumRetention;
    data['retention_low'] = lowRetention;
    
    // Species diversity
    final speciesMap = <String, int>{};
    for (final tree in trees) {
      speciesMap[tree.species] = (speciesMap[tree.species] ?? 0) + 1;
    }
    data['unique_species'] = speciesMap.length;
    data['species_list'] = List<Map<String, dynamic>>.from(
      speciesMap.entries.map((e) => Map<String, dynamic>.from({
        'species_name': e.key,
        'species_count': e.value,
      }))
    );
    
    // Report-specific data
    switch (reportType) {
      case ReportType.tra:
        // Tree Risk Assessment specific
        final highRiskTrees = trees.where((t) => 
          t.overallRiskRating.toLowerCase().contains('high')).toList();
        data['high_risk_trees'] = List<Map<String, dynamic>>.from(highRiskTrees.map(_prepareTreeData));
        data['immediate_action_required'] = highRiskTrees.length;
        break;
        
      case ReportType.aia:
        // Arboricultural Impact Assessment specific
        final impactedTrees = trees.where((t) => 
          t.recommendedWorks.toLowerCase().contains('remove') ||
          t.recommendedWorks.toLowerCase().contains('impact')).length;
        data['potentially_impacted'] = impactedTrees;
        break;
        
      case ReportType.tpmp:
        // Tree Protection Management Plan specific
        final treesToProtect = trees.where((t) => 
          t.retentionValue.toLowerCase() == 'high').toList();
        data['trees_to_protect'] = List<Map<String, dynamic>>.from(treesToProtect.map(_prepareTreeData));
        break;
        
      case ReportType.removal:
        // Removal permit specific
        final removalTrees = trees.where((t) => t.permitRequired).toList();
        data['removal_trees'] = List<Map<String, dynamic>>.from(removalTrees.map(_prepareTreeData));
        break;
        
      default:
        // No additional data needed for other report types
        break;
    }
    
    // Executive summary suggestions
    data['summary_intro'] = _generateSummaryIntro(trees, reportType);
    data['summary_recommendations'] = _generateRecommendations(trees, reportType);
  }

  /// Generate automatic summary introduction
  static String _generateSummaryIntro(List<TreeEntry> trees, ReportType reportType) {
    final count = trees.length;
    final species = trees.map((t) => t.species).toSet().length;
    
    switch (reportType) {
      case ReportType.paa:
        return 'This preliminary arboricultural assessment identifies $count trees comprising $species species. '
               'The assessment provides an initial evaluation of tree health, condition, and retention values.';
      case ReportType.tra:
        final highRisk = trees.where((t) => t.overallRiskRating.toLowerCase().contains('high')).length;
        return 'This tree risk assessment evaluates $count trees for potential hazards and safety concerns. '
               '${highRisk > 0 ? "$highRisk trees have been identified as high risk requiring immediate attention." : "No high-risk trees were identified."}';
      case ReportType.aia:
        return 'This arboricultural impact assessment examines the potential impacts of the proposed development on $count existing trees. '
               'The assessment identifies trees for retention, removal, and protection measures required during construction.';
      default:
        return 'This report assesses $count trees comprising $species species on the subject site.';
    }
  }

  /// Generate automatic recommendations
  static String _generateRecommendations(List<TreeEntry> trees, ReportType reportType) {
    final highRisk = trees.where((t) => t.overallRiskRating.toLowerCase().contains('high')).toList();
    final poorCondition = trees.where((t) => 
      t.condition.toLowerCase() == 'poor' || t.condition.toLowerCase() == 'critical').toList();
    
    final recommendations = <String>[];
    
    if (highRisk.isNotEmpty) {
      recommendations.add('Immediate action required for ${highRisk.length} high-risk trees.');
    }
    
    if (poorCondition.isNotEmpty) {
      recommendations.add('${poorCondition.length} trees in poor/critical condition require assessment for retention viability.');
    }
    
    recommendations.add('Regular monitoring and maintenance program recommended for all retained trees.');
    
    if (reportType == ReportType.tpmp) {
      recommendations.add('Tree protection zones must be established and maintained throughout construction.');
      recommendations.add('Arborist supervision recommended during works within tree protection zones.');
    }
    
    return recommendations.join(' ');
  }
}
