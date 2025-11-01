import 'dart:io';
import 'dart:typed_data';
import '../utils/platform_download.dart';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../models/site.dart';
import '../models/tree_entry.dart';
import '../services/tree_storage_service.dart';
import '../services/map_export_service.dart';
import 'package:intl/intl.dart';

class EnhancedExportService {
  static const List<String> _wordTemplates = [
    'Tree Assessment Report',
    'Site Survey Report',
    'Risk Assessment Report',
    'Management Plan',
    'Permit Application',
    'VTA Report',
  ];

  static const List<String> _pdfTemplates = [
    'Site Map with Trees',
    'Individual Tree Maps',
    'Tree Inventory Report',
    'Risk Assessment Summary',
    'Management Recommendations',
  ];

  static List<String> getWordTemplates() => _wordTemplates;
  static List<String> getPdfTemplates() => _pdfTemplates;

  /// Export site data as Word document using selected template
  static Future<void> exportAsWordDocument(Site site, String template) async {
    try {
      final trees = TreeStorageService.getTreesForSite(site.id);
      if (trees.isEmpty) {
        throw Exception('No trees found in site');
      }

      String content = _generateWordContent(site, trees, template);
      
      if (kIsWeb) {
        // Web: trigger download
        final fileName = '${site.name.replaceAll(' ', '_')}_${template.replaceAll(' ', '_')}_${DateTime.now().millisecondsSinceEpoch}.doc';
        _downloadTextAsFile(content, fileName);
      } else {
        // Mobile/Desktop: save as .docx file
        try {
          final directory = await getTemporaryDirectory();
          final fileName = '${site.name.replaceAll(' ', '_')}_${template.replaceAll(' ', '_')}_${DateTime.now().millisecondsSinceEpoch}.docx';
          final file = File('${directory.path}/$fileName');
          await file.writeAsString(content);
          
          await Share.shareXFiles([XFile(file.path)], text: 'Arborist Report: $template');
        } catch (e) {
          // Fallback to web download if path_provider fails
          final fileName = '${site.name.replaceAll(' ', '_')}_${template.replaceAll(' ', '_')}_${DateTime.now().millisecondsSinceEpoch}.doc';
          _downloadTextAsFile(content, fileName);
        }
      }
    } catch (e) {
      throw Exception('Failed to export Word document: $e');
    }
  }

  /// Export site data as PDF using selected template
  static Future<void> exportAsPdf(Site site, String template) async {
    try {
      final trees = TreeStorageService.getTreesForSite(site.id);
      if (trees.isEmpty) {
        throw Exception('No trees found in site');
      }

      if (kIsWeb) {
        // Web: trigger download
        final fileName = '${site.name.replaceAll(' ', '_')}_${template.replaceAll(' ', '_')}_${DateTime.now().millisecondsSinceEpoch}.pdf';
        final content = _generatePdfContent(site, trees, template);
        _downloadTextAsFile(content, fileName);
      } else {
        // Mobile/Desktop: generate PDF
        try {
          final directory = await getTemporaryDirectory();
          final fileName = '${site.name.replaceAll(' ', '_')}_${template.replaceAll(' ', '_')}_${DateTime.now().millisecondsSinceEpoch}.pdf';
          final file = File('${directory.path}/$fileName');
          
          String content = _generatePdfContent(site, trees, template);
          await file.writeAsString(content);
          
          await Share.shareXFiles([XFile(file.path)], text: 'Arborist Report: $template');
        } catch (e) {
          // Fallback to web download if path_provider fails
          final fileName = '${site.name.replaceAll(' ', '_')}_${template.replaceAll(' ', '_')}_${DateTime.now().millisecondsSinceEpoch}.pdf';
          final content = _generatePdfContent(site, trees, template);
          _downloadTextAsFile(content, fileName);
        }
      }
    } catch (e) {
      throw Exception('Failed to export PDF: $e');
    }
  }

  /// Generate Word document content based on template
  static String _generateWordContent(Site site, List<TreeEntry> trees, String template) {
    final dateFormat = DateFormat('MMMM dd, yyyy');
    final now = DateTime.now();
    
    StringBuffer content = StringBuffer();
    
    // Header
    content.writeln('ARBORIST ASSISTANT REPORT');
    content.writeln('Generated: ${dateFormat.format(now)}');
    content.writeln('Site: ${site.name}');
    content.writeln('Address: ${site.address}');
    content.writeln('');
    
    switch (template) {
      case 'Tree Assessment Report':
        content.writeln('TREE ASSESSMENT REPORT');
        content.writeln('=' * 50);
        content.writeln('');
        content.writeln('Executive Summary');
        content.writeln('This report provides a comprehensive assessment of ${trees.length} trees located at ${site.name}.');
        content.writeln('');
        
        content.writeln('Tree Inventory');
        content.writeln('-' * 20);
        for (final tree in trees) {
          content.writeln('Tree ID: ${tree.id}');
          content.writeln('Species: ${tree.species}');
          content.writeln('DSH: ${tree.dsh} cm');
          content.writeln('Height: ${tree.height} m');
          content.writeln('Condition: ${tree.condition}');
          content.writeln('Risk Rating: ${tree.riskRating}');
          content.writeln('Permit Required: ${tree.permitRequired ? "Yes" : "No"}');
          content.writeln('SRZ: ${tree.srz} m');
          content.writeln('NRZ: ${tree.nrz} m');
          content.writeln('Comments: ${tree.comments}');
          content.writeln('');
        }
        break;
        
      case 'Site Survey Report':
        content.writeln('SITE SURVEY REPORT');
        content.writeln('=' * 50);
        content.writeln('');
        content.writeln('Site Overview');
        content.writeln('Site Name: ${site.name}');
        content.writeln('Address: ${site.address}');
        content.writeln('Survey Date: ${dateFormat.format(now)}');
        content.writeln('Total Trees: ${trees.length}');
        content.writeln('');
        
        content.writeln('Tree Summary');
        content.writeln('-' * 20);
        final speciesCount = <String, int>{};
        for (final tree in trees) {
          speciesCount[tree.species] = (speciesCount[tree.species] ?? 0) + 1;
        }
        speciesCount.forEach((species, count) {
          content.writeln('$species: $count trees');
        });
        content.writeln('');
        break;
        
      case 'Risk Assessment Report':
        content.writeln('RISK ASSESSMENT REPORT');
        content.writeln('=' * 50);
        content.writeln('');
        
        final highRiskTrees = trees.where((t) => t.riskRating == 'High').toList();
        final mediumRiskTrees = trees.where((t) => t.riskRating == 'Medium').toList();
        final lowRiskTrees = trees.where((t) => t.riskRating == 'Low').toList();
        
        content.writeln('Risk Summary');
        content.writeln('High Risk Trees: ${highRiskTrees.length}');
        content.writeln('Medium Risk Trees: ${mediumRiskTrees.length}');
        content.writeln('Low Risk Trees: ${lowRiskTrees.length}');
        content.writeln('');
        
        if (highRiskTrees.isNotEmpty) {
          content.writeln('HIGH RISK TREES - IMMEDIATE ATTENTION REQUIRED');
          content.writeln('-' * 50);
          for (final tree in highRiskTrees) {
            content.writeln('Tree ID: ${tree.id}');
            content.writeln('Species: ${tree.species}');
            content.writeln('Risk Factors: ${tree.defectsObserved}');
            content.writeln('Recommended Action: ${tree.recommendedWorks}');
            content.writeln('');
          }
        }
        break;
        
      case 'Management Plan':
        content.writeln('TREE MANAGEMENT PLAN');
        content.writeln('=' * 50);
        content.writeln('');
        content.writeln('Management Objectives');
        content.writeln('1. Maintain tree health and safety');
        content.writeln('2. Preserve significant trees');
        content.writeln('3. Manage risk appropriately');
        content.writeln('4. Comply with local regulations');
        content.writeln('');
        
        content.writeln('Recommended Actions');
        content.writeln('-' * 20);
        for (final tree in trees) {
          if (tree.recommendedWorks.isNotEmpty) {
            content.writeln('Tree ${tree.id}: ${tree.recommendedWorks}');
          }
        }
        content.writeln('');
        break;
        
      case 'Permit Application':
        content.writeln('TREE PERMIT APPLICATION');
        content.writeln('=' * 50);
        content.writeln('');
        content.writeln('Applicant Details');
        content.writeln('Site: ${site.name}');
        content.writeln('Address: ${site.address}');
        content.writeln('Application Date: ${dateFormat.format(now)}');
        content.writeln('');
        
        final treesRequiringPermits = trees.where((t) => t.permitRequired).toList();
        content.writeln('Trees Requiring Permits: ${treesRequiringPermits.length}');
        content.writeln('');
        
        for (final tree in treesRequiringPermits) {
          content.writeln('Tree ID: ${tree.id}');
          content.writeln('Species: ${tree.species}');
          content.writeln('DSH: ${tree.dsh} cm');
          content.writeln('Reason for Permit: ${tree.comments}');
          content.writeln('');
        }
        break;
        
      case 'VTA Report':
        content.writeln('VISUAL TREE ASSESSMENT (VTA) REPORT');
        content.writeln('=' * 50);
        content.writeln('');
        content.writeln('Assessment Information');
        content.writeln('Site: ${site.name}');
        content.writeln('Assessment Date: ${dateFormat.format(now)}');
        content.writeln('Total Trees Assessed: ${trees.length}');
        content.writeln('');
        
        content.writeln('VTA Assessment Summary');
        content.writeln('-' * 30);
        for (final tree in trees) {
          content.writeln('Tree ID: ${tree.id}');
          content.writeln('Species: ${tree.species}');
          content.writeln('DSH: ${tree.dsh} cm');
          content.writeln('Height: ${tree.height} m');
          content.writeln('VTA Defects: ${tree.vtaDefects.join(', ')}');
          content.writeln('VTA Notes: ${tree.vtaNotes}');
          content.writeln('Overall Risk Rating: ${tree.overallRiskRating}');
          content.writeln('Likelihood of Failure: ${tree.likelihoodOfFailure}');
          content.writeln('Likelihood of Impact: ${tree.likelihoodOfImpact}');
          content.writeln('Consequence of Failure: ${tree.consequenceOfFailure}');
          content.writeln('Recommended Action: ${tree.recommendedWorks}');
          content.writeln('');
        }
        
        // Risk summary
        final highRiskTrees = trees.where((t) => t.overallRiskRating == 'High').toList();
        final mediumRiskTrees = trees.where((t) => t.overallRiskRating == 'Medium').toList();
        final lowRiskTrees = trees.where((t) => t.overallRiskRating == 'Low').toList();
        
        content.writeln('Risk Summary');
        content.writeln('High Risk Trees: ${highRiskTrees.length}');
        content.writeln('Medium Risk Trees: ${mediumRiskTrees.length}');
        content.writeln('Low Risk Trees: ${lowRiskTrees.length}');
        content.writeln('');
        
        if (highRiskTrees.isNotEmpty) {
          content.writeln('HIGH RISK TREES - IMMEDIATE ATTENTION REQUIRED');
          content.writeln('-' * 50);
          for (final tree in highRiskTrees) {
            content.writeln('Tree ${tree.id}: ${tree.recommendedWorks}');
          }
          content.writeln('');
        }
        break;
    }
    
    // Footer
    content.writeln('');
    content.writeln('Report generated by Arborist Assistant');
    content.writeln('Professional Tree Management Software');
    
    return content.toString();
  }

  /// Generate PDF content based on template
  static String _generatePdfContent(Site site, List<TreeEntry> trees, String template) {
    // For now, return a simple text representation
    // In a real implementation, this would generate actual PDF content
    return _generateWordContent(site, trees, template);
  }

  /// Show export dialog for web platform
  static void _showWebExportDialog(String title, String content) {
    // This would show a dialog with the content and download option
    // For now, just print to console
    print('Web Export - $title:');
    print(content);
  }

  /// Export site map with enhanced options
  static Future<void> exportSiteMap(Site site, {
    bool showSRZ = true,
    bool showNRZ = true,
    bool showTreeNumbers = true,
    bool satelliteView = false,
    String format = 'PNG',
  }) async {
    try {
      if (kIsWeb) {
        _showWebExportDialog('Site Map Export', 'Site map export not yet implemented for web');
      } else {
        final imagePath = await MapExportService.exportSiteMapAsPng(
          site,
          showSRZ: showSRZ,
          showNRZ: showNRZ,
          showTreeNumbers: showTreeNumbers,
          satelliteView: satelliteView,
        );
        
        if (imagePath != null) {
          await Share.shareXFiles([XFile(imagePath)], text: 'Site Map: ${site.name}');
        }
      }
    } catch (e) {
      throw Exception('Failed to export site map: $e');
    }
  }

  /// Export comprehensive site report
  static Future<void> exportComprehensiveReport(Site site) async {
    try {
      final trees = TreeStorageService.getTreesForSite(site.id);
      if (trees.isEmpty) {
        throw Exception('No trees found in site');
      }

      // Generate comprehensive report content
      final reportContent = _generateComprehensiveReport(site, trees);
      
      if (kIsWeb) {
        _showWebExportDialog('Comprehensive Report', reportContent);
      } else {
        final directory = await getTemporaryDirectory();
        final fileName = '${site.name.replaceAll(' ', '_')}_Comprehensive_Report_${DateTime.now().millisecondsSinceEpoch}.txt';
        final file = File('${directory.path}/$fileName');
        await file.writeAsString(reportContent);
        
        await Share.shareXFiles([XFile(file.path)], text: 'Comprehensive Report: ${site.name}');
      }
    } catch (e) {
      throw Exception('Failed to export comprehensive report: $e');
    }
  }

  /// Generate comprehensive site report
  static String _generateComprehensiveReport(Site site, List<TreeEntry> trees) {
    final dateFormat = DateFormat('MMMM dd, yyyy');
    final now = DateTime.now();
    
    StringBuffer report = StringBuffer();
    
    report.writeln('COMPREHENSIVE TREE ASSESSMENT REPORT');
    report.writeln('=' * 60);
    report.writeln('');
    report.writeln('Site Information');
    report.writeln('Site Name: ${site.name}');
    report.writeln('Address: ${site.address}');
    report.writeln('Assessment Date: ${dateFormat.format(now)}');
    report.writeln('Total Trees: ${trees.length}');
    report.writeln('');
    
    // Tree inventory
    report.writeln('TREE INVENTORY');
    report.writeln('-' * 30);
    for (final tree in trees) {
      report.writeln('Tree ID: ${tree.id}');
      report.writeln('Species: ${tree.species}');
      report.writeln('DSH: ${tree.dsh} cm');
      report.writeln('Height: ${tree.height} m');
      report.writeln('Condition: ${tree.condition}');
      report.writeln('Risk Rating: ${tree.riskRating}');
      report.writeln('SRZ: ${tree.srz} m');
      report.writeln('NRZ: ${tree.nrz} m');
      report.writeln('Comments: ${tree.comments}');
      report.writeln('Recommended Works: ${tree.recommendedWorks}');
      report.writeln('');
    }
    
    // Summary statistics
    report.writeln('SUMMARY STATISTICS');
    report.writeln('-' * 30);
    final speciesCount = <String, int>{};
    final riskCount = <String, int>{};
    final conditionCount = <String, int>{};
    
    for (final tree in trees) {
      speciesCount[tree.species] = (speciesCount[tree.species] ?? 0) + 1;
      riskCount[tree.riskRating] = (riskCount[tree.riskRating] ?? 0) + 1;
      conditionCount[tree.condition] = (conditionCount[tree.condition] ?? 0) + 1;
    }
    
    report.writeln('Species Distribution:');
    speciesCount.forEach((species, count) {
      report.writeln('  $species: $count trees');
    });
    report.writeln('');
    
    report.writeln('Risk Distribution:');
    riskCount.forEach((risk, count) {
      report.writeln('  $risk: $count trees');
    });
    report.writeln('');
    
    report.writeln('Condition Distribution:');
    conditionCount.forEach((condition, count) {
      report.writeln('  $condition: $count trees');
    });
    report.writeln('');
    
    // Recommendations
    report.writeln('RECOMMENDATIONS');
    report.writeln('-' * 30);
    final highRiskTrees = trees.where((t) => t.riskRating == 'High').toList();
    if (highRiskTrees.isNotEmpty) {
      report.writeln('High Priority Actions:');
      for (final tree in highRiskTrees) {
        report.writeln('  Tree ${tree.id}: ${tree.recommendedWorks}');
      }
      report.writeln('');
    }
    
    report.writeln('General Recommendations:');
    report.writeln('1. Regular monitoring of tree health and condition');
    report.writeln('2. Pruning of dead or damaged branches');
    report.writeln('3. Soil management and mulching');
    report.writeln('4. Professional assessment every 2-3 years');
    report.writeln('');
    
    report.writeln('Report generated by Arborist Assistant');
    report.writeln('Professional Tree Management Software');
    
    return report.toString();
  }

  /// Download text content as a file in web browser
  static void _downloadTextAsFile(String content, String fileName) async {
    if (kIsWeb) {
      final bytes = utf8.encode(content);
      await downloadFile(bytes, "export.pdf", "application/pdf");    }
  }
}
