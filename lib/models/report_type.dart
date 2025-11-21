/// Enum representing different types of arboricultural reports
enum ReportType {
  paa,       // Preliminary Arboricultural Assessment
  aia,       // Arboricultural Impact Assessment
  tpmp,      // Tree Protection Management Plan
  tra,       // Tree Risk Assessment
  condition, // Tree Health & Condition Assessment
  removal,   // Tree Removal Permit Application
  witness,   // Expert Witness Report
  postDev,   // Post-Development Monitoring
  vegetation // Vegetation & Ecological Assessment
}

extension ReportTypeExtension on ReportType {
  /// Get the report type code (e.g., 'PAA', 'AIA')
  String get code {
    switch (this) {
      case ReportType.paa:
        return 'PAA';
      case ReportType.aia:
        return 'AIA';
      case ReportType.tpmp:
        return 'TPMP';
      case ReportType.tra:
        return 'TRA';
      case ReportType.condition:
        return 'Condition';
      case ReportType.removal:
        return 'Removal';
      case ReportType.witness:
        return 'Witness';
      case ReportType.postDev:
        return 'PostDev';
      case ReportType.vegetation:
        return 'Vegetation';
    }
  }

  /// Get the full title of the report type
  String get title {
    switch (this) {
      case ReportType.paa:
        return 'Preliminary Arboricultural Assessment';
      case ReportType.aia:
        return 'Arboricultural Impact Assessment';
      case ReportType.tpmp:
        return 'Tree Protection Management Plan';
      case ReportType.tra:
        return 'Tree Risk Assessment';
      case ReportType.condition:
        return 'Tree Health & Condition Assessment';
      case ReportType.removal:
        return 'Tree Removal Permit Application';
      case ReportType.witness:
        return 'Expert Witness Report';
      case ReportType.postDev:
        return 'Post-Development Monitoring';
      case ReportType.vegetation:
        return 'Vegetation & Ecological Assessment';
    }
  }

  /// Get the description of the report type
  String get description {
    switch (this) {
      case ReportType.paa:
        return 'Initial assessment of trees on site for planning purposes';
      case ReportType.aia:
        return 'Assessment of construction impacts on existing trees';
      case ReportType.tpmp:
        return 'Plan for protecting trees during development';
      case ReportType.tra:
        return 'Evaluation of tree-related risks and hazards';
      case ReportType.condition:
        return 'Detailed assessment of tree health and structural condition';
      case ReportType.removal:
        return 'Application for permit to remove protected trees';
      case ReportType.witness:
        return 'Expert evidence report for legal proceedings';
      case ReportType.postDev:
        return 'Monitoring of tree health after development completion';
      case ReportType.vegetation:
        return 'Assessment of vegetation communities and ecological values';
    }
  }

  /// Get the DOCX template filename for this report type
  String get templateFilename {
    switch (this) {
      case ReportType.paa:
        return 'preliminary_arboricultural_assessment.docx';
      case ReportType.aia:
        return 'arboricultural_impact_assessment.docx';
      case ReportType.tpmp:
        return 'tree_protection_management_plan.docx';
      case ReportType.tra:
        return 'tree_risk_assessment.docx';
      case ReportType.condition:
        return 'tree_health_condition_report.docx';
      case ReportType.removal:
        return 'tree_removal_permit_report.docx';
      case ReportType.witness:
        return 'expert_witness_report.docx';
      case ReportType.postDev:
        return 'post_development_monitoring_report.docx';
      case ReportType.vegetation:
        return 'vegetation_ecological_assessment.docx';
    }
  }
}

/// Create ReportType from code string
ReportType reportTypeFromCode(String code) {
  switch (code.toUpperCase()) {
    case 'PAA':
      return ReportType.paa;
    case 'AIA':
      return ReportType.aia;
    case 'TPMP':
      return ReportType.tpmp;
    case 'TRA':
      return ReportType.tra;
    case 'CONDITION':
      return ReportType.condition;
    case 'REMOVAL':
      return ReportType.removal;
    case 'WITNESS':
      return ReportType.witness;
    case 'POSTDEV':
      return ReportType.postDev;
    case 'VEGETATION':
      return ReportType.vegetation;
    default:
      return ReportType.paa; // Default to PAA
  }
}
