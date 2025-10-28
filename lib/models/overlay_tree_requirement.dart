class OverlayTreeRequirement {
  final String overlayCode;
  final String scheduleNumber;
  final String lgaName;
  final String overlayFullName;
  final String purposeSummary;
  final String treeSizeThresholdDbhCm;
  final String treeSizeThresholdHeightM;
  final String treeSizeThresholdCircumferenceM;
  final String indigenousTreesProtected;
  final String significantTreesProtected;
  final String pruningPermitRequired;
  final String pruningThresholdDescription;
  final String removalPermitRequired;
  final String exemptionDeadDying;
  final String exemptionEmergency;
  final String exemptionFirePrevention10m;
  final String exemptionNoxiousWeeds;
  final String otherExemptions;
  final String arboristReportRequired;
  final String offsetRequired;
  final String offsetRatio;
  final String replacementPlantingRequired;
  final String typicalPermitFee;
  final String typicalProcessingDays;
  final String penaltiesDescription;
  final String councilReferral;
  final String delwpReferral;
  final String notes;
  final String verificationStatus;
  final String verifiedDate;
  final String verifiedBy;
  final String sourceVppUrl;
  final String sourceCouncilScheduleUrl;

  OverlayTreeRequirement({
    required this.overlayCode,
    required this.scheduleNumber,
    required this.lgaName,
    required this.overlayFullName,
    required this.purposeSummary,
    required this.treeSizeThresholdDbhCm,
    required this.treeSizeThresholdHeightM,
    required this.treeSizeThresholdCircumferenceM,
    required this.indigenousTreesProtected,
    required this.significantTreesProtected,
    required this.pruningPermitRequired,
    required this.pruningThresholdDescription,
    required this.removalPermitRequired,
    required this.exemptionDeadDying,
    required this.exemptionEmergency,
    required this.exemptionFirePrevention10m,
    required this.exemptionNoxiousWeeds,
    required this.otherExemptions,
    required this.arboristReportRequired,
    required this.offsetRequired,
    required this.offsetRatio,
    required this.replacementPlantingRequired,
    required this.typicalPermitFee,
    required this.typicalProcessingDays,
    required this.penaltiesDescription,
    required this.councilReferral,
    required this.delwpReferral,
    required this.notes,
    required this.verificationStatus,
    required this.verifiedDate,
    required this.verifiedBy,
    required this.sourceVppUrl,
    required this.sourceCouncilScheduleUrl,
  });

  factory OverlayTreeRequirement.fromCsvRow(List<String> row) {
    return OverlayTreeRequirement(
      overlayCode: row[0],
      scheduleNumber: row[1],
      lgaName: row[2],
      overlayFullName: row[3],
      purposeSummary: row[4],
      treeSizeThresholdDbhCm: row[5],
      treeSizeThresholdHeightM: row[6],
      treeSizeThresholdCircumferenceM: row[7],
      indigenousTreesProtected: row[8],
      significantTreesProtected: row[9],
      pruningPermitRequired: row[10],
      pruningThresholdDescription: row[11],
      removalPermitRequired: row[12],
      exemptionDeadDying: row[13],
      exemptionEmergency: row[14],
      exemptionFirePrevention10m: row[15],
      exemptionNoxiousWeeds: row[16],
      otherExemptions: row[17],
      arboristReportRequired: row[18],
      offsetRequired: row[19],
      offsetRatio: row[20],
      replacementPlantingRequired: row[21],
      typicalPermitFee: row[22],
      typicalProcessingDays: row[23],
      penaltiesDescription: row[24],
      councilReferral: row[25],
      delwpReferral: row[26],
      notes: row[27],
      verificationStatus: row[28],
      verifiedDate: row[29],
      verifiedBy: row[30],
      sourceVppUrl: row.length > 31 ? row[31] : '',
      sourceCouncilScheduleUrl: row.length > 32 ? row[32] : '',
    );
  }

  bool get isVerified => verificationStatus == 'VERIFIED';
  
  String get overlayScheduleCode => '$overlayCode$scheduleNumber';
  
  String get displayThreshold {
    final parts = <String>[];
    if (treeSizeThresholdDbhCm.isNotEmpty) {
      parts.add('DBH ≥ ${treeSizeThresholdDbhCm}cm');
    }
    if (treeSizeThresholdHeightM.isNotEmpty) {
      parts.add('Height ≥ ${treeSizeThresholdHeightM}m');
    }
    if (treeSizeThresholdCircumferenceM.isNotEmpty) {
      parts.add('Circumference ≥ ${treeSizeThresholdCircumferenceM}m');
    }
    return parts.isEmpty ? 'See overlay schedule' : parts.join(' OR ');
  }
}
