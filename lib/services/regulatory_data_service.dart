import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import '../models/lga_tree_law.dart';
import '../models/overlay_tree_requirement.dart';

class RegulatoryDataService {
  static RegulatoryDataService? _instance;
  static RegulatoryDataService get instance {
    _instance ??= RegulatoryDataService._();
    return _instance!;
  }

  RegulatoryDataService._();

  List<LgaTreeLaw>? _lgaLaws;
  List<OverlayTreeRequirement>? _overlayRequirements;
  bool _isLoaded = false;

  /// Load CSV data from assets (with caching)
  Future<void> loadData() async {
    if (_isLoaded) {
      print('✅ Regulatory data already cached');
      return;
    }

    try {
      print('📋 Loading regulatory data from CSVs...');
      final startTime = DateTime.now();
      
      // Load LGA tree laws
      final lgaCsv = await rootBundle.loadString('data_templates/VICTORIAN_LGA_TREE_LAWS_FINAL_VERIFIED.csv');
      _lgaLaws = _parseLgaCsv(lgaCsv);
      print('✅ Loaded ${_lgaLaws!.length} LGA tree laws');
      
      // Load overlay requirements
      final overlayCsv = await rootBundle.loadString('data_templates/VICTORIAN_OVERLAYS_TREE_REQUIREMENTS_VERIFIED_BATCH4.csv');
      _overlayRequirements = _parseOverlayCsv(overlayCsv);
      print('✅ Loaded ${_overlayRequirements!.length} overlay requirements');
      
      final loadTime = DateTime.now().difference(startTime).inMilliseconds;
      print('⚡ Regulatory data loaded and cached in ${loadTime}ms');
      
      _isLoaded = true;
    } catch (e) {
      print('❌ Error loading regulatory data: $e');
      _lgaLaws = [];
      _overlayRequirements = [];
    }
  }

  List<LgaTreeLaw> _parseLgaCsv(String csvContent) {
    final lines = const LineSplitter().convert(csvContent);
    if (lines.isEmpty) return [];
    
    // Skip header row
    final dataLines = lines.skip(1);
    final laws = <LgaTreeLaw>[];
    
    for (var line in dataLines) {
      if (line.trim().isEmpty) continue;
      try {
        final row = _parseCsvLine(line);
        if (row.isNotEmpty) {
          laws.add(LgaTreeLaw.fromCsvRow(row));
        }
      } catch (e) {
        print('⚠️ Error parsing LGA law row: $e');
      }
    }
    
    return laws;
  }

  List<OverlayTreeRequirement> _parseOverlayCsv(String csvContent) {
    final lines = const LineSplitter().convert(csvContent);
    if (lines.isEmpty) return [];
    
    // Skip header row
    final dataLines = lines.skip(1);
    final requirements = <OverlayTreeRequirement>[];
    
    for (var line in dataLines) {
      if (line.trim().isEmpty) continue;
      try {
        final row = _parseCsvLine(line);
        if (row.isNotEmpty) {
          requirements.add(OverlayTreeRequirement.fromCsvRow(row));
        }
      } catch (e) {
        print('⚠️ Error parsing overlay requirement row: $e');
      }
    }
    
    return requirements;
  }

  /// Parse CSV line handling quoted fields with commas
  List<String> _parseCsvLine(String line) {
    final List<String> fields = [];
    final buffer = StringBuffer();
    bool inQuotes = false;
    
    for (int i = 0; i < line.length; i++) {
      final char = line[i];
      
      if (char == '"') {
        if (inQuotes && i + 1 < line.length && line[i + 1] == '"') {
          // Escaped quote
          buffer.write('"');
          i++; // Skip next quote
        } else {
          inQuotes = !inQuotes;
        }
      } else if (char == ',' && !inQuotes) {
        fields.add(buffer.toString());
        buffer.clear();
      } else {
        buffer.write(char);
      }
    }
    
    // Add last field
    fields.add(buffer.toString());
    
    return fields;
  }

  /// Find tree law by LGA name (case-insensitive)
  LgaTreeLaw? getLgaTreeLaw(String lgaName) {
    if (_lgaLaws == null) return null;
    
    final searchName = lgaName.toLowerCase().trim();
    return _lgaLaws!.firstWhere(
      (law) => law.lgaName.toLowerCase() == searchName,
      orElse: () => _lgaLaws!.firstWhere(
        (law) => law.councilFullName.toLowerCase().contains(searchName),
        orElse: () => LgaTreeLaw(
          lgaName: lgaName,
          councilFullName: '',
          websiteUrl: '',
          localLawsPageUrl: '',
          planningPageUrl: '',
          phone: '',
          contactEmail: '',
          localLawNumber: '',
          localLawYear: '',
          sizeThresholdCircumference: '',
          sizeThresholdHeight: '',
          indigenousTreesProtected: '',
          pruningThresholdPercent: '',
          permitFeeStandard: '',
          permitFeeConcession: '',
          processingDaysMin: '',
          processingDaysMax: '',
          exemptionDeadDying: '',
          exemptionEmergency: '',
          exemptionFirePrevention: '',
          exemptionFruitTrees: '',
          otherExemptions: '',
          replacementRatio: '',
          arboristReportRequired: '',
          penaltiesMin: '',
          penaltiesMax: '',
          notes: 'No data available for this LGA',
          verificationStatus: 'NOT_FOUND',
          verifiedDate: '',
          verifiedBy: '',
          sourceUrl1: '',
          sourceUrl2: '',
        ),
      ),
    );
  }

  /// Find overlay requirements by overlay code and schedule
  List<OverlayTreeRequirement> getOverlayRequirements(String overlayCode, {String? lgaName}) {
    if (_overlayRequirements == null) return [];
    
    // Parse overlay code - e.g. "VPO2" -> "VPO" + "2"
    String baseCode = overlayCode;
    String? scheduleNum;
    
    // Extract trailing numbers as schedule
    final match = RegExp(r'^([A-Z]+)(\d+\.?\d*)$').firstMatch(overlayCode.toUpperCase());
    if (match != null) {
      baseCode = match.group(1)!;
      scheduleNum = match.group(2)!;
      // Add .0 if no decimal
      if (!scheduleNum.contains('.')) {
        scheduleNum = '$scheduleNum.0';
      }
    }
    
    return _overlayRequirements!.where((req) {
      // Match base code
      final codeMatch = req.overlayCode.toUpperCase() == baseCode.toUpperCase();
      
      // Match schedule if provided
      final scheduleMatch = scheduleNum == null || 
                           req.scheduleNumber.isEmpty ||
                           req.scheduleNumber == scheduleNum;
      
      // Match LGA if provided
      final lgaMatch = lgaName == null || 
                       req.lgaName.isEmpty || 
                       req.lgaName.toLowerCase() == lgaName.toLowerCase();
      
      return codeMatch && scheduleMatch && lgaMatch;
    }).toList();
  }

  /// Get all LGA names
  List<String> getAllLgaNames() {
    if (_lgaLaws == null) return [];
    return _lgaLaws!.map((law) => law.lgaName).toList()..sort();
  }

  /// Get all verified LGA laws
  List<LgaTreeLaw> getVerifiedLaws() {
    if (_lgaLaws == null) return [];
    return _lgaLaws!.where((law) => law.isVerified).toList();
  }

  /// Get all verified overlay requirements
  List<OverlayTreeRequirement> getVerifiedOverlays() {
    if (_overlayRequirements == null) return [];
    return _overlayRequirements!.where((req) => req.isVerified).toList();
  }
}
