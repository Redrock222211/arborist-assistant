// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'tree_entry.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class TreeEntryAdapter extends TypeAdapter<TreeEntry> {
  @override
  final int typeId = 0;

  @override
  TreeEntry read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return TreeEntry(
      id: fields[0] as String,
      species: fields[1] as String,
      dsh: fields[2] as double,
      height: fields[3] as double,
      condition: fields[4] as String,
      comments: fields[5] as String,
      permitRequired: fields[6] as bool,
      latitude: fields[7] as double,
      longitude: fields[8] as double,
      srz: fields[9] as double,
      nrz: fields[10] as double,
      ageClass: fields[11] as String,
      retentionValue: fields[12] as String,
      riskRating: fields[13] as String,
      locationDescription: fields[14] as String,
      habitatValue: fields[15] as String,
      recommendedWorks: fields[16] as String,
      healthForm: fields[17] as String,
      diseasesPresent: fields[18] as String,
      canopySpread: fields[19] as double,
      clearanceToStructures: fields[20] as double,
      origin: fields[21] as String,
      pastManagement: fields[22] as String,
      pestPresence: fields[23] as String,
      notes: fields[24] as String,
      siteId: fields[25] as String,
      targetOccupancy: fields[26] as String,
      defectsObserved: (fields[27] as List).cast<String>(),
      likelihoodOfFailure: fields[28] as String,
      likelihoodOfImpact: fields[29] as String,
      consequenceOfFailure: fields[30] as String,
      overallRiskRating: fields[31] as String,
      vtaNotes: fields[32] as String,
      vtaDefects: (fields[33] as List).cast<String>(),
      inspectionDate: fields[34] as DateTime?,
      inspectorName: fields[35] as String,
      voiceNotes: fields[36] as String,
      voiceNoteAudioPath: fields[37] as String,
      voiceAudioUrl: fields[38] as String,
      imageUrls: (fields[39] as List).cast<String>(),
      imageLocalPaths: (fields[40] as List).cast<String>(),
      syncStatus: fields[41] as String,
      siteType: fields[43] as String,
      landUseZone: fields[44] as String,
      soilType: fields[45] as String,
      soilCompaction: fields[46] as String,
      drainage: fields[47] as String,
      siteSlope: fields[48] as String,
      aspect: fields[49] as String,
      proximityToBuildings: fields[50] as double,
      proximityToServices: fields[51] as String,
      vigorRating: fields[52] as String,
      foliageDensity: fields[53] as String,
      foliageColor: fields[54] as String,
      diebackPercent: fields[55] as double,
      stressIndicators: (fields[56] as List).cast<String>(),
      growthRate: fields[57] as String,
      seasonalCondition: fields[58] as String,
      crownForm: fields[59] as String,
      crownDensity: fields[60] as String,
      branchStructure: fields[61] as String,
      trunkForm: fields[62] as String,
      trunkLean: fields[63] as String,
      leanDirection: fields[64] as String,
      rootPlateCondition: fields[65] as String,
      buttressRoots: fields[66] as bool,
      surfaceRoots: fields[67] as bool,
      includedBark: fields[68] as bool,
      includedBarkLocation: fields[69] as String,
      structuralDefects: (fields[70] as List).cast<String>(),
      structuralRating: fields[71] as String,
      tpzArea: fields[72] as double,
      encroachmentPresent: fields[73] as bool,
      encroachmentType: (fields[74] as List).cast<String>(),
      protectionMeasures: fields[75] as String,
      cavityPresent: fields[77] as bool,
      cavitySize: fields[78] as String,
      cavityLocation: fields[79] as String,
      decayExtent: fields[80] as String,
      decayType: fields[81] as String,
      fungalFruitingBodies: fields[82] as bool,
      fungalSpecies: fields[83] as String,
      barkDamagePercent: fields[84] as double,
      barkDamageType: (fields[85] as List).cast<String>(),
      cracksSplits: fields[86] as bool,
      cracksSplitsLocation: fields[87] as String,
      deadWoodPercent: fields[88] as double,
      girdlingRoots: fields[89] as bool,
      girdlingRootsSeverity: fields[90] as String,
      rootDamage: fields[91] as bool,
      rootDamageDescription: fields[92] as String,
      mechanicalDamage: fields[93] as bool,
      mechanicalDamageDescription: fields[94] as String,
      qtraTargetType: fields[95] as String,
      qtraTargetValue: fields[96] as String,
      qtraOccupancyRate: fields[97] as String,
      qtraImpactPotential: fields[98] as String,
      qtraProbabilityOfFailure: fields[99] as double,
      qtraProbabilityOfImpact: fields[100] as double,
      qtraRiskOfHarm: fields[101] as double,
      qtraRiskRating: fields[102] as String,
      developmentType: fields[103] as String,
      constructionZoneDistance: fields[104] as double,
      rootZoneEncroachmentPercent: fields[105] as double,
      canopyEncroachmentPercent: fields[106] as double,
      excavationImpact: fields[107] as String,
      serviceInstallationImpact: fields[108] as bool,
      serviceInstallationDescription: fields[109] as String,
      demolitionImpact: fields[110] as bool,
      demolitionDescription: fields[111] as String,
      accessRouteImpact: fields[112] as bool,
      accessRouteDescription: fields[113] as String,
      impactRating: fields[114] as String,
      mitigationMeasures: fields[115] as String,
      planningPermitRequired: fields[116] as bool,
      planningPermitNumber: fields[117] as String,
      planningPermitStatus: fields[118] as String,
      planningOverlay: fields[119] as String,
      heritageOverlay: fields[120] as bool,
      significantLandscapeOverlay: fields[121] as bool,
      vegetationProtectionOverlay: fields[122] as bool,
      localLawProtected: fields[123] as bool,
      localLawReference: fields[124] as String,
      as4970Compliant: fields[125] as bool,
      arboristReportRequired: fields[126] as bool,
      councilNotification: fields[127] as bool,
      neighborNotification: fields[128] as bool,
      retentionRecommendation: fields[129] as String,
      retentionJustification: fields[130] as String,
      removalJustification: fields[131] as String,
      significance: fields[132] as String,
      replantingRequired: fields[133] as bool,
      replacementRatio: fields[134] as double,
      offsetRequirements: fields[135] as String,
      pruningType: (fields[136] as List).cast<String>(),
      pruningSpecification: fields[137] as String,
      worksPriority: fields[138] as String,
      worksTimeframe: fields[139] as String,
      estimatedCostRange: fields[140] as String,
      accessRequirements: (fields[141] as List).cast<String>(),
      arboristSupervisionRequired: fields[142] as bool,
      treeProtectionMeasures: fields[143] as String,
      postWorksMonitoring: fields[144] as bool,
      postWorksMonitoringFrequency: fields[145] as String,
      worksCompletionDate: fields[146] as DateTime?,
      worksCompliance: fields[147] as bool,
      valuationMethod: fields[148] as String,
      baseValue: fields[149] as double,
      conditionFactor: fields[150] as double,
      locationFactor: fields[151] as double,
      contributionFactor: fields[152] as double,
      totalValuation: fields[153] as double,
      valuationDate: fields[154] as DateTime?,
      valuerName: fields[155] as String,
      wildlifeHabitatValue: fields[156] as String,
      hollowBearingTree: fields[157] as bool,
      nestingSites: fields[158] as bool,
      nestingSpecies: fields[159] as String,
      habitatFeatures: (fields[160] as List).cast<String>(),
      biodiversityValue: fields[161] as String,
      indigenousSignificance: fields[162] as bool,
      indigenousSignificanceDetails: fields[163] as String,
      culturalHeritage: fields[164] as bool,
      culturalHeritageDetails: fields[165] as String,
      amenityValue: fields[166] as String,
      shadeProvision: fields[167] as String,
      stateSignificant: fields[168] as bool,
      heritageListed: fields[169] as bool,
      heritageReference: fields[170] as String,
      significantTreeRegister: fields[171] as bool,
      bushfireManagementOverlay: fields[172] as bool,
      environmentalSignificanceOverlay: fields[173] as bool,
      waterwayProtection: fields[174] as bool,
      threatenedSpeciesHabitat: fields[175] as bool,
      insuranceNotificationRequired: fields[176] as bool,
      legalLiabilityAssessment: fields[177] as String,
      complianceNotes: fields[178] as String,
      nextInspectionDate: fields[179] as DateTime?,
      inspectionFrequency: fields[180] as String,
      monitoringRequired: fields[181] as bool,
      monitoringFocus: (fields[182] as List).cast<String>(),
      alertLevel: fields[183] as String,
      followUpActions: fields[184] as String,
      complianceCheckDate: fields[185] as DateTime?,
      resistographTest: fields[186] as bool,
      resistographDate: fields[187] as DateTime?,
      resistographResults: fields[188] as String,
      sonicTomography: fields[189] as bool,
      sonicTomographyDate: fields[190] as DateTime?,
      sonicTomographyResults: fields[191] as String,
      pullingTest: fields[192] as bool,
      pullingTestDate: fields[193] as DateTime?,
      pullingTestResults: fields[194] as String,
      rootCollarExcavation: fields[195] as bool,
      rootCollarFindings: fields[196] as String,
      soilTesting: fields[197] as bool,
      soilTestingResults: fields[198] as String,
      pathologyReport: fields[199] as String,
      diagnosticImages: (fields[200] as List).cast<String>(),
      specialistConsultant: fields[201] as String,
      diagnosticSummary: fields[202] as String,
      exportGroups: (fields[203] as Map?)?.cast<String, bool>(),
    );
  }

  @override
  void write(BinaryWriter writer, TreeEntry obj) {
    writer
      ..writeByte(202)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.species)
      ..writeByte(2)
      ..write(obj.dsh)
      ..writeByte(3)
      ..write(obj.height)
      ..writeByte(4)
      ..write(obj.condition)
      ..writeByte(5)
      ..write(obj.comments)
      ..writeByte(6)
      ..write(obj.permitRequired)
      ..writeByte(7)
      ..write(obj.latitude)
      ..writeByte(8)
      ..write(obj.longitude)
      ..writeByte(9)
      ..write(obj.srz)
      ..writeByte(10)
      ..write(obj.nrz)
      ..writeByte(11)
      ..write(obj.ageClass)
      ..writeByte(12)
      ..write(obj.retentionValue)
      ..writeByte(13)
      ..write(obj.riskRating)
      ..writeByte(14)
      ..write(obj.locationDescription)
      ..writeByte(15)
      ..write(obj.habitatValue)
      ..writeByte(16)
      ..write(obj.recommendedWorks)
      ..writeByte(17)
      ..write(obj.healthForm)
      ..writeByte(18)
      ..write(obj.diseasesPresent)
      ..writeByte(19)
      ..write(obj.canopySpread)
      ..writeByte(20)
      ..write(obj.clearanceToStructures)
      ..writeByte(21)
      ..write(obj.origin)
      ..writeByte(22)
      ..write(obj.pastManagement)
      ..writeByte(23)
      ..write(obj.pestPresence)
      ..writeByte(24)
      ..write(obj.notes)
      ..writeByte(25)
      ..write(obj.siteId)
      ..writeByte(26)
      ..write(obj.targetOccupancy)
      ..writeByte(27)
      ..write(obj.defectsObserved)
      ..writeByte(28)
      ..write(obj.likelihoodOfFailure)
      ..writeByte(29)
      ..write(obj.likelihoodOfImpact)
      ..writeByte(30)
      ..write(obj.consequenceOfFailure)
      ..writeByte(31)
      ..write(obj.overallRiskRating)
      ..writeByte(32)
      ..write(obj.vtaNotes)
      ..writeByte(33)
      ..write(obj.vtaDefects)
      ..writeByte(34)
      ..write(obj.inspectionDate)
      ..writeByte(35)
      ..write(obj.inspectorName)
      ..writeByte(36)
      ..write(obj.voiceNotes)
      ..writeByte(37)
      ..write(obj.voiceNoteAudioPath)
      ..writeByte(38)
      ..write(obj.voiceAudioUrl)
      ..writeByte(39)
      ..write(obj.imageUrls)
      ..writeByte(40)
      ..write(obj.imageLocalPaths)
      ..writeByte(41)
      ..write(obj.syncStatus)
      ..writeByte(43)
      ..write(obj.siteType)
      ..writeByte(44)
      ..write(obj.landUseZone)
      ..writeByte(45)
      ..write(obj.soilType)
      ..writeByte(46)
      ..write(obj.soilCompaction)
      ..writeByte(47)
      ..write(obj.drainage)
      ..writeByte(48)
      ..write(obj.siteSlope)
      ..writeByte(49)
      ..write(obj.aspect)
      ..writeByte(50)
      ..write(obj.proximityToBuildings)
      ..writeByte(51)
      ..write(obj.proximityToServices)
      ..writeByte(52)
      ..write(obj.vigorRating)
      ..writeByte(53)
      ..write(obj.foliageDensity)
      ..writeByte(54)
      ..write(obj.foliageColor)
      ..writeByte(55)
      ..write(obj.diebackPercent)
      ..writeByte(56)
      ..write(obj.stressIndicators)
      ..writeByte(57)
      ..write(obj.growthRate)
      ..writeByte(58)
      ..write(obj.seasonalCondition)
      ..writeByte(59)
      ..write(obj.crownForm)
      ..writeByte(60)
      ..write(obj.crownDensity)
      ..writeByte(61)
      ..write(obj.branchStructure)
      ..writeByte(62)
      ..write(obj.trunkForm)
      ..writeByte(63)
      ..write(obj.trunkLean)
      ..writeByte(64)
      ..write(obj.leanDirection)
      ..writeByte(65)
      ..write(obj.rootPlateCondition)
      ..writeByte(66)
      ..write(obj.buttressRoots)
      ..writeByte(67)
      ..write(obj.surfaceRoots)
      ..writeByte(68)
      ..write(obj.includedBark)
      ..writeByte(69)
      ..write(obj.includedBarkLocation)
      ..writeByte(70)
      ..write(obj.structuralDefects)
      ..writeByte(71)
      ..write(obj.structuralRating)
      ..writeByte(72)
      ..write(obj.tpzArea)
      ..writeByte(73)
      ..write(obj.encroachmentPresent)
      ..writeByte(74)
      ..write(obj.encroachmentType)
      ..writeByte(75)
      ..write(obj.protectionMeasures)
      ..writeByte(77)
      ..write(obj.cavityPresent)
      ..writeByte(78)
      ..write(obj.cavitySize)
      ..writeByte(79)
      ..write(obj.cavityLocation)
      ..writeByte(80)
      ..write(obj.decayExtent)
      ..writeByte(81)
      ..write(obj.decayType)
      ..writeByte(82)
      ..write(obj.fungalFruitingBodies)
      ..writeByte(83)
      ..write(obj.fungalSpecies)
      ..writeByte(84)
      ..write(obj.barkDamagePercent)
      ..writeByte(85)
      ..write(obj.barkDamageType)
      ..writeByte(86)
      ..write(obj.cracksSplits)
      ..writeByte(87)
      ..write(obj.cracksSplitsLocation)
      ..writeByte(88)
      ..write(obj.deadWoodPercent)
      ..writeByte(89)
      ..write(obj.girdlingRoots)
      ..writeByte(90)
      ..write(obj.girdlingRootsSeverity)
      ..writeByte(91)
      ..write(obj.rootDamage)
      ..writeByte(92)
      ..write(obj.rootDamageDescription)
      ..writeByte(93)
      ..write(obj.mechanicalDamage)
      ..writeByte(94)
      ..write(obj.mechanicalDamageDescription)
      ..writeByte(95)
      ..write(obj.qtraTargetType)
      ..writeByte(96)
      ..write(obj.qtraTargetValue)
      ..writeByte(97)
      ..write(obj.qtraOccupancyRate)
      ..writeByte(98)
      ..write(obj.qtraImpactPotential)
      ..writeByte(99)
      ..write(obj.qtraProbabilityOfFailure)
      ..writeByte(100)
      ..write(obj.qtraProbabilityOfImpact)
      ..writeByte(101)
      ..write(obj.qtraRiskOfHarm)
      ..writeByte(102)
      ..write(obj.qtraRiskRating)
      ..writeByte(103)
      ..write(obj.developmentType)
      ..writeByte(104)
      ..write(obj.constructionZoneDistance)
      ..writeByte(105)
      ..write(obj.rootZoneEncroachmentPercent)
      ..writeByte(106)
      ..write(obj.canopyEncroachmentPercent)
      ..writeByte(107)
      ..write(obj.excavationImpact)
      ..writeByte(108)
      ..write(obj.serviceInstallationImpact)
      ..writeByte(109)
      ..write(obj.serviceInstallationDescription)
      ..writeByte(110)
      ..write(obj.demolitionImpact)
      ..writeByte(111)
      ..write(obj.demolitionDescription)
      ..writeByte(112)
      ..write(obj.accessRouteImpact)
      ..writeByte(113)
      ..write(obj.accessRouteDescription)
      ..writeByte(114)
      ..write(obj.impactRating)
      ..writeByte(115)
      ..write(obj.mitigationMeasures)
      ..writeByte(116)
      ..write(obj.planningPermitRequired)
      ..writeByte(117)
      ..write(obj.planningPermitNumber)
      ..writeByte(118)
      ..write(obj.planningPermitStatus)
      ..writeByte(119)
      ..write(obj.planningOverlay)
      ..writeByte(120)
      ..write(obj.heritageOverlay)
      ..writeByte(121)
      ..write(obj.significantLandscapeOverlay)
      ..writeByte(122)
      ..write(obj.vegetationProtectionOverlay)
      ..writeByte(123)
      ..write(obj.localLawProtected)
      ..writeByte(124)
      ..write(obj.localLawReference)
      ..writeByte(125)
      ..write(obj.as4970Compliant)
      ..writeByte(126)
      ..write(obj.arboristReportRequired)
      ..writeByte(127)
      ..write(obj.councilNotification)
      ..writeByte(128)
      ..write(obj.neighborNotification)
      ..writeByte(129)
      ..write(obj.retentionRecommendation)
      ..writeByte(130)
      ..write(obj.retentionJustification)
      ..writeByte(131)
      ..write(obj.removalJustification)
      ..writeByte(132)
      ..write(obj.significance)
      ..writeByte(133)
      ..write(obj.replantingRequired)
      ..writeByte(134)
      ..write(obj.replacementRatio)
      ..writeByte(135)
      ..write(obj.offsetRequirements)
      ..writeByte(136)
      ..write(obj.pruningType)
      ..writeByte(137)
      ..write(obj.pruningSpecification)
      ..writeByte(138)
      ..write(obj.worksPriority)
      ..writeByte(139)
      ..write(obj.worksTimeframe)
      ..writeByte(140)
      ..write(obj.estimatedCostRange)
      ..writeByte(141)
      ..write(obj.accessRequirements)
      ..writeByte(142)
      ..write(obj.arboristSupervisionRequired)
      ..writeByte(143)
      ..write(obj.treeProtectionMeasures)
      ..writeByte(144)
      ..write(obj.postWorksMonitoring)
      ..writeByte(145)
      ..write(obj.postWorksMonitoringFrequency)
      ..writeByte(146)
      ..write(obj.worksCompletionDate)
      ..writeByte(147)
      ..write(obj.worksCompliance)
      ..writeByte(148)
      ..write(obj.valuationMethod)
      ..writeByte(149)
      ..write(obj.baseValue)
      ..writeByte(150)
      ..write(obj.conditionFactor)
      ..writeByte(151)
      ..write(obj.locationFactor)
      ..writeByte(152)
      ..write(obj.contributionFactor)
      ..writeByte(153)
      ..write(obj.totalValuation)
      ..writeByte(154)
      ..write(obj.valuationDate)
      ..writeByte(155)
      ..write(obj.valuerName)
      ..writeByte(156)
      ..write(obj.wildlifeHabitatValue)
      ..writeByte(157)
      ..write(obj.hollowBearingTree)
      ..writeByte(158)
      ..write(obj.nestingSites)
      ..writeByte(159)
      ..write(obj.nestingSpecies)
      ..writeByte(160)
      ..write(obj.habitatFeatures)
      ..writeByte(161)
      ..write(obj.biodiversityValue)
      ..writeByte(162)
      ..write(obj.indigenousSignificance)
      ..writeByte(163)
      ..write(obj.indigenousSignificanceDetails)
      ..writeByte(164)
      ..write(obj.culturalHeritage)
      ..writeByte(165)
      ..write(obj.culturalHeritageDetails)
      ..writeByte(166)
      ..write(obj.amenityValue)
      ..writeByte(167)
      ..write(obj.shadeProvision)
      ..writeByte(168)
      ..write(obj.stateSignificant)
      ..writeByte(169)
      ..write(obj.heritageListed)
      ..writeByte(170)
      ..write(obj.heritageReference)
      ..writeByte(171)
      ..write(obj.significantTreeRegister)
      ..writeByte(172)
      ..write(obj.bushfireManagementOverlay)
      ..writeByte(173)
      ..write(obj.environmentalSignificanceOverlay)
      ..writeByte(174)
      ..write(obj.waterwayProtection)
      ..writeByte(175)
      ..write(obj.threatenedSpeciesHabitat)
      ..writeByte(176)
      ..write(obj.insuranceNotificationRequired)
      ..writeByte(177)
      ..write(obj.legalLiabilityAssessment)
      ..writeByte(178)
      ..write(obj.complianceNotes)
      ..writeByte(179)
      ..write(obj.nextInspectionDate)
      ..writeByte(180)
      ..write(obj.inspectionFrequency)
      ..writeByte(181)
      ..write(obj.monitoringRequired)
      ..writeByte(182)
      ..write(obj.monitoringFocus)
      ..writeByte(183)
      ..write(obj.alertLevel)
      ..writeByte(184)
      ..write(obj.followUpActions)
      ..writeByte(185)
      ..write(obj.complianceCheckDate)
      ..writeByte(186)
      ..write(obj.resistographTest)
      ..writeByte(187)
      ..write(obj.resistographDate)
      ..writeByte(188)
      ..write(obj.resistographResults)
      ..writeByte(189)
      ..write(obj.sonicTomography)
      ..writeByte(190)
      ..write(obj.sonicTomographyDate)
      ..writeByte(191)
      ..write(obj.sonicTomographyResults)
      ..writeByte(192)
      ..write(obj.pullingTest)
      ..writeByte(193)
      ..write(obj.pullingTestDate)
      ..writeByte(194)
      ..write(obj.pullingTestResults)
      ..writeByte(195)
      ..write(obj.rootCollarExcavation)
      ..writeByte(196)
      ..write(obj.rootCollarFindings)
      ..writeByte(197)
      ..write(obj.soilTesting)
      ..writeByte(198)
      ..write(obj.soilTestingResults)
      ..writeByte(199)
      ..write(obj.pathologyReport)
      ..writeByte(200)
      ..write(obj.diagnosticImages)
      ..writeByte(201)
      ..write(obj.specialistConsultant)
      ..writeByte(202)
      ..write(obj.diagnosticSummary)
      ..writeByte(203)
      ..write(obj.exportGroups);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TreeEntryAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
