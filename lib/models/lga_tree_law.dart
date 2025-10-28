class LgaTreeLaw {
  final String lgaName;
  final String councilFullName;
  final String websiteUrl;
  final String localLawsPageUrl;
  final String planningPageUrl;
  final String phone;
  final String contactEmail;
  final String localLawNumber;
  final String localLawYear;
  final String sizeThresholdCircumference;
  final String sizeThresholdHeight;
  final String indigenousTreesProtected;
  final String pruningThresholdPercent;
  final String permitFeeStandard;
  final String permitFeeConcession;
  final String processingDaysMin;
  final String processingDaysMax;
  final String exemptionDeadDying;
  final String exemptionEmergency;
  final String exemptionFirePrevention;
  final String exemptionFruitTrees;
  final String otherExemptions;
  final String replacementRatio;
  final String arboristReportRequired;
  final String penaltiesMin;
  final String penaltiesMax;
  final String notes;
  final String verificationStatus;
  final String verifiedDate;
  final String verifiedBy;
  final String sourceUrl1;
  final String sourceUrl2;

  LgaTreeLaw({
    required this.lgaName,
    required this.councilFullName,
    required this.websiteUrl,
    required this.localLawsPageUrl,
    required this.planningPageUrl,
    required this.phone,
    required this.contactEmail,
    required this.localLawNumber,
    required this.localLawYear,
    required this.sizeThresholdCircumference,
    required this.sizeThresholdHeight,
    required this.indigenousTreesProtected,
    required this.pruningThresholdPercent,
    required this.permitFeeStandard,
    required this.permitFeeConcession,
    required this.processingDaysMin,
    required this.processingDaysMax,
    required this.exemptionDeadDying,
    required this.exemptionEmergency,
    required this.exemptionFirePrevention,
    required this.exemptionFruitTrees,
    required this.otherExemptions,
    required this.replacementRatio,
    required this.arboristReportRequired,
    required this.penaltiesMin,
    required this.penaltiesMax,
    required this.notes,
    required this.verificationStatus,
    required this.verifiedDate,
    required this.verifiedBy,
    required this.sourceUrl1,
    required this.sourceUrl2,
  });

  factory LgaTreeLaw.fromCsvRow(List<String> row) {
    return LgaTreeLaw(
      lgaName: row[0],
      councilFullName: row[1],
      websiteUrl: row[2],
      localLawsPageUrl: row[3],
      planningPageUrl: row[4],
      phone: row[5],
      contactEmail: row[6],
      localLawNumber: row[7],
      localLawYear: row[8],
      sizeThresholdCircumference: row[9],
      sizeThresholdHeight: row[10],
      indigenousTreesProtected: row[11],
      pruningThresholdPercent: row[12],
      permitFeeStandard: row[13],
      permitFeeConcession: row[14],
      processingDaysMin: row[15],
      processingDaysMax: row[16],
      exemptionDeadDying: row[17],
      exemptionEmergency: row[18],
      exemptionFirePrevention: row[19],
      exemptionFruitTrees: row[20],
      otherExemptions: row[21],
      replacementRatio: row[22],
      arboristReportRequired: row[23],
      penaltiesMin: row[24],
      penaltiesMax: row[25],
      notes: row[26],
      verificationStatus: row[27],
      verifiedDate: row[28],
      verifiedBy: row[29],
      sourceUrl1: row.length > 30 ? row[30] : '',
      sourceUrl2: row.length > 31 ? row[31] : '',
    );
  }

  bool get isVerified => verificationStatus == 'VERIFIED';
  
  bool get hasLocalLaw {
    // Check if there's an actual local law (not just explanatory text)
    if (localLawNumber.isEmpty) return false;
    
    // Exclude entries that indicate no local law exists
    final noLawIndicators = [
      'no private tree local law',
      'no specific',
      'planning scheme',
      'planning permit',
      'planning controls',
    ];
    
    final lowerCaseLaw = localLawNumber.toLowerCase();
    if (noLawIndicators.any((indicator) => lowerCaseLaw.contains(indicator))) {
      return false;
    }
    
    // Must have at least a size threshold to be considered a real local law
    return sizeThresholdCircumference.isNotEmpty || sizeThresholdHeight.isNotEmpty;
  }
  
  String get displayThreshold {
    if (sizeThresholdCircumference.isEmpty && sizeThresholdHeight.isEmpty) {
      return 'No specific threshold';
    }
    final parts = <String>[];
    if (sizeThresholdCircumference.isNotEmpty) {
      parts.add('Circumference: $sizeThresholdCircumference');
    }
    if (sizeThresholdHeight.isNotEmpty) {
      parts.add('Height: $sizeThresholdHeight');
    }
    return parts.join(' OR ');
  }
}
