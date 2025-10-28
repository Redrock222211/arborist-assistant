import 'package:hive/hive.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
part 'tree_entry.g.dart';

@HiveType(typeId: 0)
class TreeEntry {
  @HiveField(0)
  final String id;
  @HiveField(1)
  final String species;
  @HiveField(2)
  final double dsh;
  @HiveField(3)
  final double height;
  @HiveField(4)
  final String condition;
  @HiveField(5)
  final String comments;
  @HiveField(6)
  final bool permitRequired;
  @HiveField(7)
  final double latitude;
  @HiveField(8)
  final double longitude;
  @HiveField(9)
  final double srz;
  @HiveField(10)
  final double nrz;
  @HiveField(11)
  final String ageClass;
  @HiveField(12)
  final String retentionValue;
  @HiveField(13)
  final String riskRating;
  @HiveField(14)
  final String locationDescription;
  @HiveField(15)
  final String habitatValue;
  @HiveField(16)
  final String recommendedWorks;
  @HiveField(17)
  final String healthForm;
  @HiveField(18)
  final String diseasesPresent;
  @HiveField(19)
  final double canopySpread;
  @HiveField(20)
  final double clearanceToStructures;
  @HiveField(21)
  final String origin;
  @HiveField(22)
  final String pastManagement;
  @HiveField(23)
  final String pestPresence;
  @HiveField(24)
  final String notes;
  @HiveField(25)
  final String siteId; // NEW: associate tree with a site
  // ISA/VTA fields
  @HiveField(26)
  final String targetOccupancy;
  @HiveField(27)
  final List<String> defectsObserved;
  @HiveField(28)
  final String likelihoodOfFailure;
  @HiveField(29)
  final String likelihoodOfImpact;
  @HiveField(30)
  final String consequenceOfFailure;
  @HiveField(31)
  final String overallRiskRating;
  @HiveField(32)
  final String vtaNotes;
  @HiveField(33)
  final List<String> vtaDefects;
  @HiveField(34)
  final DateTime? inspectionDate;
  @HiveField(35)
  final String inspectorName;
  @HiveField(36)
  final String voiceNotes;
  @HiveField(37)
  final String voiceNoteAudioPath;
  @HiveField(38)
  final String voiceAudioUrl;
  @HiveField(39)
  final List<String> imageUrls;
  @HiveField(40)
  final List<String> imageLocalPaths;
  @HiveField(41)
  final String syncStatus;
  
  // GROUP 3: Location & Site Context (Phase 1)
  @HiveField(43)
  final String siteType;
  @HiveField(44)
  final String landUseZone;
  @HiveField(45)
  final String soilType;
  @HiveField(46)
  final String soilCompaction;
  @HiveField(47)
  final String drainage;
  @HiveField(48)
  final String siteSlope;
  @HiveField(49)
  final String aspect;
  @HiveField(50)
  final double proximityToBuildings;
  @HiveField(51)
  final String proximityToServices;
  
  // GROUP 5: Tree Health Assessment (Phase 1)
  @HiveField(52)
  final String vigorRating;
  @HiveField(53)
  final String foliageDensity;
  @HiveField(54)
  final String foliageColor;
  @HiveField(55)
  final double diebackPercent;
  @HiveField(56)
  final List<String> stressIndicators;
  @HiveField(57)
  final String growthRate;
  @HiveField(58)
  final String seasonalCondition;
  
  // GROUP 6: Tree Structure (Phase 1)
  @HiveField(59)
  final String crownForm;
  @HiveField(60)
  final String crownDensity;
  @HiveField(61)
  final String branchStructure;
  @HiveField(62)
  final String trunkForm;
  @HiveField(63)
  final String trunkLean;
  @HiveField(64)
  final String leanDirection;
  @HiveField(65)
  final String rootPlateCondition;
  @HiveField(66)
  final bool buttressRoots;
  @HiveField(67)
  final bool surfaceRoots;
  @HiveField(68)
  final bool includedBark;
  @HiveField(69)
  final String includedBarkLocation;
  @HiveField(70)
  final List<String> structuralDefects;
  @HiveField(71)
  final String structuralRating;
  
  // GROUP 10: Protection Zones (Phase 1 - enhanced)
  @HiveField(72)
  final double tpzArea;
  @HiveField(73)
  final bool encroachmentPresent;
  @HiveField(74)
  final List<String> encroachmentType;
  @HiveField(75)
  final String protectionMeasures;
  
  // GROUP 7: VTA (Visual Tree Assessment) - Phase 2
  @HiveField(77)
  final bool cavityPresent;
  @HiveField(78)
  final String cavitySize;
  @HiveField(79)
  final String cavityLocation;
  @HiveField(80)
  final String decayExtent;
  @HiveField(81)
  final String decayType;
  @HiveField(82)
  final bool fungalFruitingBodies;
  @HiveField(83)
  final String fungalSpecies;
  @HiveField(84)
  final double barkDamagePercent;
  @HiveField(85)
  final List<String> barkDamageType;
  @HiveField(86)
  final bool cracksSplits;
  @HiveField(87)
  final String cracksSplitsLocation;
  @HiveField(88)
  final double deadWoodPercent;
  @HiveField(89)
  final bool girdlingRoots;
  @HiveField(90)
  final String girdlingRootsSeverity;
  @HiveField(91)
  final bool rootDamage;
  @HiveField(92)
  final String rootDamageDescription;
  @HiveField(93)
  final bool mechanicalDamage;
  @HiveField(94)
  final String mechanicalDamageDescription;
  
  // GROUP 8: QTRA (Quantified Tree Risk Assessment) - Phase 2
  @HiveField(95)
  final String qtraTargetType;
  @HiveField(96)
  final String qtraTargetValue;
  @HiveField(97)
  final String qtraOccupancyRate;
  @HiveField(98)
  final String qtraImpactPotential;
  @HiveField(99)
  final double qtraProbabilityOfFailure;
  @HiveField(100)
  final double qtraProbabilityOfImpact;
  @HiveField(101)
  final double qtraRiskOfHarm;
  @HiveField(102)
  final String qtraRiskRating;
  
  // GROUP 11: Tree Impact Assessment - Phase 3
  @HiveField(103)
  final String developmentType;
  @HiveField(104)
  final double constructionZoneDistance;
  @HiveField(105)
  final double rootZoneEncroachmentPercent;
  @HiveField(106)
  final double canopyEncroachmentPercent;
  @HiveField(107)
  final String excavationImpact;
  @HiveField(108)
  final bool serviceInstallationImpact;
  @HiveField(109)
  final String serviceInstallationDescription;
  @HiveField(110)
  final bool demolitionImpact;
  @HiveField(111)
  final String demolitionDescription;
  @HiveField(112)
  final bool accessRouteImpact;
  @HiveField(113)
  final String accessRouteDescription;
  @HiveField(114)
  final String impactRating;
  @HiveField(115)
  final String mitigationMeasures;
  
  // GROUP 12: Development Compliance - Phase 3
  @HiveField(116)
  final bool planningPermitRequired;
  @HiveField(117)
  final String planningPermitNumber;
  @HiveField(118)
  final String planningPermitStatus;
  @HiveField(119)
  final String planningOverlay;
  @HiveField(120)
  final bool heritageOverlay;
  @HiveField(121)
  final bool significantLandscapeOverlay;
  @HiveField(122)
  final bool vegetationProtectionOverlay;
  @HiveField(123)
  final bool localLawProtected;
  @HiveField(124)
  final String localLawReference;
  @HiveField(125)
  final bool as4970Compliant;
  @HiveField(126)
  final bool arboristReportRequired;
  @HiveField(127)
  final bool councilNotification;
  @HiveField(128)
  final bool neighborNotification;
  
  // GROUP 13: Retention & Removal - Phase 3
  @HiveField(129)
  final String retentionRecommendation;
  @HiveField(130)
  final String retentionJustification;
  @HiveField(131)
  final String removalJustification;
  @HiveField(132)
  final String significance;
  @HiveField(133)
  final bool replantingRequired;
  @HiveField(134)
  final double replacementRatio;
  @HiveField(135)
  final String offsetRequirements;
  
  // GROUP 14: Management & Works - Phase 3
  @HiveField(136)
  final List<String> pruningType;
  @HiveField(137)
  final String pruningSpecification;
  @HiveField(138)
  final String worksPriority;
  @HiveField(139)
  final String worksTimeframe;
  @HiveField(140)
  final String estimatedCostRange;
  @HiveField(141)
  final List<String> accessRequirements;
  @HiveField(142)
  final bool arboristSupervisionRequired;
  @HiveField(143)
  final String treeProtectionMeasures;
  @HiveField(144)
  final bool postWorksMonitoring;
  @HiveField(145)
  final String postWorksMonitoringFrequency;
  @HiveField(146)
  final DateTime? worksCompletionDate;
  @HiveField(147)
  final bool worksCompliance;
  
  // GROUP 15: Tree Valuation - Phase 3
  @HiveField(148)
  final String valuationMethod;
  @HiveField(149)
  final double baseValue;
  @HiveField(150)
  final double conditionFactor;
  @HiveField(151)
  final double locationFactor;
  @HiveField(152)
  final double contributionFactor;
  @HiveField(153)
  final double totalValuation;
  @HiveField(154)
  final DateTime? valuationDate;
  @HiveField(155)
  final String valuerName;
  
  // GROUP 16: Ecological Value - Phase 3
  @HiveField(156)
  final String wildlifeHabitatValue;
  @HiveField(157)
  final bool hollowBearingTree;
  @HiveField(158)
  final bool nestingSites;
  @HiveField(159)
  final String nestingSpecies;
  @HiveField(160)
  final List<String> habitatFeatures;
  @HiveField(161)
  final String biodiversityValue;
  @HiveField(162)
  final bool indigenousSignificance;
  @HiveField(163)
  final String indigenousSignificanceDetails;
  @HiveField(164)
  final bool culturalHeritage;
  @HiveField(165)
  final String culturalHeritageDetails;
  @HiveField(166)
  final String amenityValue;
  @HiveField(167)
  final String shadeProvision;
  
  // GROUP 17: Regulatory & Compliance - Phase 3
  @HiveField(168)
  final bool stateSignificant;
  @HiveField(169)
  final bool heritageListed;
  @HiveField(170)
  final String heritageReference;
  @HiveField(171)
  final bool significantTreeRegister;
  @HiveField(172)
  final bool bushfireManagementOverlay;
  @HiveField(173)
  final bool environmentalSignificanceOverlay;
  @HiveField(174)
  final bool waterwayProtection;
  @HiveField(175)
  final bool threatenedSpeciesHabitat;
  @HiveField(176)
  final bool insuranceNotificationRequired;
  @HiveField(177)
  final String legalLiabilityAssessment;
  @HiveField(178)
  final String complianceNotes;
  
  // GROUP 18: Monitoring & Scheduling - Phase 3
  @HiveField(179)
  final DateTime? nextInspectionDate;
  @HiveField(180)
  final String inspectionFrequency;
  @HiveField(181)
  final bool monitoringRequired;
  @HiveField(182)
  final List<String> monitoringFocus;
  @HiveField(183)
  final String alertLevel;
  @HiveField(184)
  final String followUpActions;
  @HiveField(185)
  final DateTime? complianceCheckDate;
  
  // GROUP 19: Advanced Diagnostics - Phase 3
  @HiveField(186)
  final bool resistographTest;
  @HiveField(187)
  final DateTime? resistographDate;
  @HiveField(188)
  final String resistographResults;
  @HiveField(189)
  final bool sonicTomography;
  @HiveField(190)
  final DateTime? sonicTomographyDate;
  @HiveField(191)
  final String sonicTomographyResults;
  @HiveField(192)
  final bool pullingTest;
  @HiveField(193)
  final DateTime? pullingTestDate;
  @HiveField(194)
  final String pullingTestResults;
  @HiveField(195)
  final bool rootCollarExcavation;
  @HiveField(196)
  final String rootCollarFindings;
  @HiveField(197)
  final bool soilTesting;
  @HiveField(198)
  final String soilTestingResults;
  @HiveField(199)
  final String pathologyReport;
  @HiveField(200)
  final List<String> diagnosticImages;
  @HiveField(201)
  final String specialistConsultant;
  @HiveField(202)
  final String diagnosticSummary;
  
  @HiveField(203)
  final Map<String, bool> exportGroups;
  // Export groups control which sections are visible and exported

  TreeEntry({
    required this.id,
    required this.species,
    required this.dsh,
    required this.height,
    required this.condition,
    required this.comments,
    required this.permitRequired,
    required this.latitude,
    required this.longitude,
    this.srz = 0,
    this.nrz = 0,
    this.ageClass = '',
    this.retentionValue = '',
    this.riskRating = '',
    this.locationDescription = '',
    this.habitatValue = '',
    this.recommendedWorks = '',
    this.healthForm = '',
    this.diseasesPresent = '',
    this.canopySpread = 0,
    this.clearanceToStructures = 0,
    this.origin = '',
    this.pastManagement = '',
    this.pestPresence = '',
    this.notes = '',
    required this.siteId,
    this.targetOccupancy = '',
    this.defectsObserved = const [],
    this.likelihoodOfFailure = '',
    this.likelihoodOfImpact = '',
    this.consequenceOfFailure = '',
    this.overallRiskRating = '',
    this.vtaNotes = '',
    this.vtaDefects = const [],
    this.inspectionDate,
    this.inspectorName = '',
    this.voiceNotes = '',
    this.voiceNoteAudioPath = '',
    this.voiceAudioUrl = '',
    this.imageUrls = const [],
    this.imageLocalPaths = const [],
    this.syncStatus = 'local',
    // Phase 1 fields
    this.siteType = '',
    this.landUseZone = '',
    this.soilType = '',
    this.soilCompaction = '',
    this.drainage = '',
    this.siteSlope = '',
    this.aspect = '',
    this.proximityToBuildings = 0,
    this.proximityToServices = '',
    this.vigorRating = '',
    this.foliageDensity = '',
    this.foliageColor = '',
    this.diebackPercent = 0,
    this.stressIndicators = const [],
    this.growthRate = '',
    this.seasonalCondition = '',
    this.crownForm = '',
    this.crownDensity = '',
    this.branchStructure = '',
    this.trunkForm = '',
    this.trunkLean = '',
    this.leanDirection = '',
    this.rootPlateCondition = '',
    this.buttressRoots = false,
    this.surfaceRoots = false,
    this.includedBark = false,
    this.includedBarkLocation = '',
    this.structuralDefects = const [],
    this.structuralRating = '',
    this.tpzArea = 0,
    this.encroachmentPresent = false,
    this.encroachmentType = const [],
    this.protectionMeasures = '',
    // Phase 2 - VTA fields
    this.cavityPresent = false,
    this.cavitySize = '',
    this.cavityLocation = '',
    this.decayExtent = '',
    this.decayType = '',
    this.fungalFruitingBodies = false,
    this.fungalSpecies = '',
    this.barkDamagePercent = 0,
    this.barkDamageType = const [],
    this.cracksSplits = false,
    this.cracksSplitsLocation = '',
    this.deadWoodPercent = 0,
    this.girdlingRoots = false,
    this.girdlingRootsSeverity = '',
    this.rootDamage = false,
    this.rootDamageDescription = '',
    this.mechanicalDamage = false,
    this.mechanicalDamageDescription = '',
    // Phase 2 - QTRA fields
    this.qtraTargetType = '',
    this.qtraTargetValue = '',
    this.qtraOccupancyRate = '',
    this.qtraImpactPotential = '',
    this.qtraProbabilityOfFailure = 0,
    this.qtraProbabilityOfImpact = 0,
    this.qtraRiskOfHarm = 0,
    this.qtraRiskRating = '',
    // Phase 3 - Impact Assessment
    this.developmentType = '',
    this.constructionZoneDistance = 0,
    this.rootZoneEncroachmentPercent = 0,
    this.canopyEncroachmentPercent = 0,
    this.excavationImpact = '',
    this.serviceInstallationImpact = false,
    this.serviceInstallationDescription = '',
    this.demolitionImpact = false,
    this.demolitionDescription = '',
    this.accessRouteImpact = false,
    this.accessRouteDescription = '',
    this.impactRating = '',
    this.mitigationMeasures = '',
    // Phase 3 - Development Compliance
    this.planningPermitRequired = false,
    this.planningPermitNumber = '',
    this.planningPermitStatus = '',
    this.planningOverlay = '',
    this.heritageOverlay = false,
    this.significantLandscapeOverlay = false,
    this.vegetationProtectionOverlay = false,
    this.localLawProtected = false,
    this.localLawReference = '',
    this.as4970Compliant = false,
    this.arboristReportRequired = false,
    this.councilNotification = false,
    this.neighborNotification = false,
    // Phase 3 - Retention & Removal
    this.retentionRecommendation = '',
    this.retentionJustification = '',
    this.removalJustification = '',
    this.significance = '',
    this.replantingRequired = false,
    this.replacementRatio = 0,
    this.offsetRequirements = '',
    // Phase 3 - Management & Works
    this.pruningType = const [],
    this.pruningSpecification = '',
    this.worksPriority = '',
    this.worksTimeframe = '',
    this.estimatedCostRange = '',
    this.accessRequirements = const [],
    this.arboristSupervisionRequired = false,
    this.treeProtectionMeasures = '',
    this.postWorksMonitoring = false,
    this.postWorksMonitoringFrequency = '',
    this.worksCompletionDate,
    this.worksCompliance = false,
    // Phase 3 - Tree Valuation
    this.valuationMethod = '',
    this.baseValue = 0,
    this.conditionFactor = 0,
    this.locationFactor = 0,
    this.contributionFactor = 0,
    this.totalValuation = 0,
    this.valuationDate,
    this.valuerName = '',
    // Phase 3 - Ecological Value
    this.wildlifeHabitatValue = '',
    this.hollowBearingTree = false,
    this.nestingSites = false,
    this.nestingSpecies = '',
    this.habitatFeatures = const [],
    this.biodiversityValue = '',
    this.indigenousSignificance = false,
    this.indigenousSignificanceDetails = '',
    this.culturalHeritage = false,
    this.culturalHeritageDetails = '',
    this.amenityValue = '',
    this.shadeProvision = '',
    // Phase 3 - Regulatory & Compliance
    this.stateSignificant = false,
    this.heritageListed = false,
    this.heritageReference = '',
    this.significantTreeRegister = false,
    this.bushfireManagementOverlay = false,
    this.environmentalSignificanceOverlay = false,
    this.waterwayProtection = false,
    this.threatenedSpeciesHabitat = false,
    this.insuranceNotificationRequired = false,
    this.legalLiabilityAssessment = '',
    this.complianceNotes = '',
    // Phase 3 - Monitoring & Scheduling
    this.nextInspectionDate,
    this.inspectionFrequency = '',
    this.monitoringRequired = false,
    this.monitoringFocus = const [],
    this.alertLevel = '',
    this.followUpActions = '',
    this.complianceCheckDate,
    // Phase 3 - Advanced Diagnostics
    this.resistographTest = false,
    this.resistographDate,
    this.resistographResults = '',
    this.sonicTomography = false,
    this.sonicTomographyDate,
    this.sonicTomographyResults = '',
    this.pullingTest = false,
    this.pullingTestDate,
    this.pullingTestResults = '',
    this.rootCollarExcavation = false,
    this.rootCollarFindings = '',
    this.soilTesting = false,
    this.soilTestingResults = '',
    this.pathologyReport = '',
    this.diagnosticImages = const [],
    this.specialistConsultant = '',
    this.diagnosticSummary = '',
    Map<String, bool>? exportGroups,
  }) : exportGroups = exportGroups ?? {
    // Core Assessment (Always visible by default)
    'photos': true,
    'voice_notes': true,
    'location': true,
    'basic_data': true,
    'health': true,
    'structure': true,
    'vta': true,
    'qtra': true,
    'isa_risk': true,
    'protection_zones': true,
    
    // Impact & Development
    'impact_assessment': true,
    'development': true,
    'retention_removal': true,
    'management': true,
    
    // Valuation & Reporting
    'valuation': false,  // Optional - only for valuation reports
    'ecological': true,
    'regulatory': true,
    'monitoring': true,
    
    // Advanced (Optional)
    'diagnostics': false,  // Only when advanced testing done
    'inspector_details': true,
  };

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'species': species,
      'dsh': dsh,
      'height': height,
      'condition': condition,
      'comments': comments,
      'permitRequired': permitRequired,
      'latitude': latitude,
      'longitude': longitude,
      'srz': srz,
      'nrz': nrz,
      'ageClass': ageClass,
      'retentionValue': retentionValue,
      'riskRating': riskRating,
      'locationDescription': locationDescription,
      'habitatValue': habitatValue,
      'recommendedWorks': recommendedWorks,
      'healthForm': healthForm,
      'diseasesPresent': diseasesPresent,
      'canopySpread': canopySpread,
      'clearanceToStructures': clearanceToStructures,
      'origin': origin,
      'pastManagement': pastManagement,
      'pestPresence': pestPresence,
      'notes': notes,
      'siteId': siteId,
      'targetOccupancy': targetOccupancy,
      'defectsObserved': defectsObserved,
      'likelihoodOfFailure': likelihoodOfFailure,
      'likelihoodOfImpact': likelihoodOfImpact,
      'consequenceOfFailure': consequenceOfFailure,
      'overallRiskRating': overallRiskRating,
      'vtaNotes': vtaNotes,
      'vtaDefects': vtaDefects,
      'inspectionDate': inspectionDate?.toIso8601String(),
      'inspectorName': inspectorName,
      'voiceNotes': voiceNotes,
      'voiceNoteAudioPath': voiceNoteAudioPath,
      'voiceAudioUrl': voiceAudioUrl,
      'imageUrls': imageUrls,
      'imageLocalPaths': imageLocalPaths,
      'syncStatus': syncStatus,
      // Phase 1 fields
      'siteType': siteType,
      'landUseZone': landUseZone,
      'soilType': soilType,
      'soilCompaction': soilCompaction,
      'drainage': drainage,
      'siteSlope': siteSlope,
      'aspect': aspect,
      'proximityToBuildings': proximityToBuildings,
      'proximityToServices': proximityToServices,
      'vigorRating': vigorRating,
      'foliageDensity': foliageDensity,
      'foliageColor': foliageColor,
      'diebackPercent': diebackPercent,
      'stressIndicators': stressIndicators,
      'growthRate': growthRate,
      'seasonalCondition': seasonalCondition,
      'crownForm': crownForm,
      'crownDensity': crownDensity,
      'branchStructure': branchStructure,
      'trunkForm': trunkForm,
      'trunkLean': trunkLean,
      'leanDirection': leanDirection,
      'rootPlateCondition': rootPlateCondition,
      'buttressRoots': buttressRoots,
      'surfaceRoots': surfaceRoots,
      'includedBark': includedBark,
      'includedBarkLocation': includedBarkLocation,
      'structuralDefects': structuralDefects,
      'structuralRating': structuralRating,
      'tpzArea': tpzArea,
      'encroachmentPresent': encroachmentPresent,
      'encroachmentType': encroachmentType,
      'protectionMeasures': protectionMeasures,
      // Phase 2 - VTA
      'cavityPresent': cavityPresent,
      'cavitySize': cavitySize,
      'cavityLocation': cavityLocation,
      'decayExtent': decayExtent,
      'decayType': decayType,
      'fungalFruitingBodies': fungalFruitingBodies,
      'fungalSpecies': fungalSpecies,
      'barkDamagePercent': barkDamagePercent,
      'barkDamageType': barkDamageType,
      'cracksSplits': cracksSplits,
      'cracksSplitsLocation': cracksSplitsLocation,
      'deadWoodPercent': deadWoodPercent,
      'girdlingRoots': girdlingRoots,
      'girdlingRootsSeverity': girdlingRootsSeverity,
      'rootDamage': rootDamage,
      'rootDamageDescription': rootDamageDescription,
      'mechanicalDamage': mechanicalDamage,
      'mechanicalDamageDescription': mechanicalDamageDescription,
      // Phase 2 - QTRA
      'qtraTargetType': qtraTargetType,
      'qtraTargetValue': qtraTargetValue,
      'qtraOccupancyRate': qtraOccupancyRate,
      'qtraImpactPotential': qtraImpactPotential,
      'qtraProbabilityOfFailure': qtraProbabilityOfFailure,
      'qtraProbabilityOfImpact': qtraProbabilityOfImpact,
      'qtraRiskOfHarm': qtraRiskOfHarm,
      'qtraRiskRating': qtraRiskRating,
      // Phase 3 - Impact
      'developmentType': developmentType,
      'constructionZoneDistance': constructionZoneDistance,
      'rootZoneEncroachmentPercent': rootZoneEncroachmentPercent,
      'canopyEncroachmentPercent': canopyEncroachmentPercent,
      'excavationImpact': excavationImpact,
      'serviceInstallationImpact': serviceInstallationImpact,
      'serviceInstallationDescription': serviceInstallationDescription,
      'demolitionImpact': demolitionImpact,
      'demolitionDescription': demolitionDescription,
      'accessRouteImpact': accessRouteImpact,
      'accessRouteDescription': accessRouteDescription,
      'impactRating': impactRating,
      'mitigationMeasures': mitigationMeasures,
      // Phase 3 - Development
      'planningPermitRequired': planningPermitRequired,
      'planningPermitNumber': planningPermitNumber,
      'planningPermitStatus': planningPermitStatus,
      'planningOverlay': planningOverlay,
      'heritageOverlay': heritageOverlay,
      'significantLandscapeOverlay': significantLandscapeOverlay,
      'vegetationProtectionOverlay': vegetationProtectionOverlay,
      'localLawProtected': localLawProtected,
      'localLawReference': localLawReference,
      'as4970Compliant': as4970Compliant,
      'arboristReportRequired': arboristReportRequired,
      'councilNotification': councilNotification,
      'neighborNotification': neighborNotification,
      // Phase 3 - Retention
      'retentionRecommendation': retentionRecommendation,
      'retentionJustification': retentionJustification,
      'removalJustification': removalJustification,
      'significance': significance,
      'replantingRequired': replantingRequired,
      'replacementRatio': replacementRatio,
      'offsetRequirements': offsetRequirements,
      // Phase 3 - Management
      'pruningType': pruningType,
      'pruningSpecification': pruningSpecification,
      'worksPriority': worksPriority,
      'worksTimeframe': worksTimeframe,
      'estimatedCostRange': estimatedCostRange,
      'accessRequirements': accessRequirements,
      'arboristSupervisionRequired': arboristSupervisionRequired,
      'treeProtectionMeasures': treeProtectionMeasures,
      'postWorksMonitoring': postWorksMonitoring,
      'postWorksMonitoringFrequency': postWorksMonitoringFrequency,
      'worksCompletionDate': worksCompletionDate?.toIso8601String(),
      'worksCompliance': worksCompliance,
      // Phase 3 - Valuation
      'valuationMethod': valuationMethod,
      'baseValue': baseValue,
      'conditionFactor': conditionFactor,
      'locationFactor': locationFactor,
      'contributionFactor': contributionFactor,
      'totalValuation': totalValuation,
      'valuationDate': valuationDate?.toIso8601String(),
      'valuerName': valuerName,
      // Phase 3 - Ecological
      'wildlifeHabitatValue': wildlifeHabitatValue,
      'hollowBearingTree': hollowBearingTree,
      'nestingSites': nestingSites,
      'nestingSpecies': nestingSpecies,
      'habitatFeatures': habitatFeatures,
      'biodiversityValue': biodiversityValue,
      'indigenousSignificance': indigenousSignificance,
      'indigenousSignificanceDetails': indigenousSignificanceDetails,
      'culturalHeritage': culturalHeritage,
      'culturalHeritageDetails': culturalHeritageDetails,
      'amenityValue': amenityValue,
      'shadeProvision': shadeProvision,
      // Phase 3 - Regulatory
      'stateSignificant': stateSignificant,
      'heritageListed': heritageListed,
      'heritageReference': heritageReference,
      'significantTreeRegister': significantTreeRegister,
      'bushfireManagementOverlay': bushfireManagementOverlay,
      'environmentalSignificanceOverlay': environmentalSignificanceOverlay,
      'waterwayProtection': waterwayProtection,
      'threatenedSpeciesHabitat': threatenedSpeciesHabitat,
      'insuranceNotificationRequired': insuranceNotificationRequired,
      'legalLiabilityAssessment': legalLiabilityAssessment,
      'complianceNotes': complianceNotes,
      // Phase 3 - Monitoring
      'nextInspectionDate': nextInspectionDate?.toIso8601String(),
      'inspectionFrequency': inspectionFrequency,
      'monitoringRequired': monitoringRequired,
      'monitoringFocus': monitoringFocus,
      'alertLevel': alertLevel,
      'followUpActions': followUpActions,
      'complianceCheckDate': complianceCheckDate?.toIso8601String(),
      // Phase 3 - Diagnostics
      'resistographTest': resistographTest,
      'resistographDate': resistographDate?.toIso8601String(),
      'resistographResults': resistographResults,
      'sonicTomography': sonicTomography,
      'sonicTomographyDate': sonicTomographyDate?.toIso8601String(),
      'sonicTomographyResults': sonicTomographyResults,
      'pullingTest': pullingTest,
      'pullingTestDate': pullingTestDate?.toIso8601String(),
      'pullingTestResults': pullingTestResults,
      'rootCollarExcavation': rootCollarExcavation,
      'rootCollarFindings': rootCollarFindings,
      'soilTesting': soilTesting,
      'soilTestingResults': soilTestingResults,
      'pathologyReport': pathologyReport,
      'diagnosticImages': diagnosticImages,
      'specialistConsultant': specialistConsultant,
      'diagnosticSummary': diagnosticSummary,
    };
  }

  factory TreeEntry.fromMap(Map<String, dynamic> map) {
    return TreeEntry(
      id: map['id'] ?? '',
      species: map['species'] ?? '',
      dsh: (map['dsh'] ?? 0).toDouble(),
      height: (map['height'] ?? 0).toDouble(),
      condition: map['condition'] ?? '',
      comments: map['comments'] ?? '',
      permitRequired: map['permitRequired'] ?? false,
      latitude: (map['latitude'] ?? 0).toDouble(),
      longitude: (map['longitude'] ?? 0).toDouble(),
      srz: (map['srz'] ?? 0).toDouble(),
      nrz: (map['nrz'] ?? 0).toDouble(),
      ageClass: map['ageClass'] ?? '',
      retentionValue: map['retentionValue'] ?? '',
      riskRating: map['riskRating'] ?? '',
      locationDescription: map['locationDescription'] ?? '',
      habitatValue: map['habitatValue'] ?? '',
      recommendedWorks: map['recommendedWorks'] ?? '',
      healthForm: map['healthForm'] ?? '',
      diseasesPresent: map['diseasesPresent'] ?? '',
      canopySpread: (map['canopySpread'] ?? 0).toDouble(),
      clearanceToStructures: (map['clearanceToStructures'] ?? 0).toDouble(),
      origin: map['origin'] ?? '',
      pastManagement: map['pastManagement'] ?? '',
      pestPresence: map['pestPresence'] ?? '',
      notes: map['notes'] ?? '',
      siteId: map['siteId'] ?? '',
      targetOccupancy: map['targetOccupancy'] ?? '',
      defectsObserved: List<String>.from(map['defectsObserved'] ?? []),
      likelihoodOfFailure: map['likelihoodOfFailure'] ?? '',
      likelihoodOfImpact: map['likelihoodOfImpact'] ?? '',
      consequenceOfFailure: map['consequenceOfFailure'] ?? '',
      overallRiskRating: map['overallRiskRating'] ?? '',
      vtaNotes: map['vtaNotes'] ?? '',
      vtaDefects: List<String>.from(map['vtaDefects'] ?? []),
      inspectionDate: map['inspectionDate'] != null ? DateTime.tryParse(map['inspectionDate']) : null,
      inspectorName: map['inspectorName'] ?? '',
      voiceNotes: map['voiceNotes'] ?? '',
      voiceNoteAudioPath: map['voiceNoteAudioPath'] ?? '',
      voiceAudioUrl: map['voiceAudioUrl'] ?? '',
      imageUrls: List<String>.from(map['imageUrls'] ?? []),
      imageLocalPaths: List<String>.from(map['imageLocalPaths'] ?? []),
      syncStatus: map['syncStatus'] ?? 'local',
      // Phase 1 fields
      siteType: map['siteType'] ?? '',
      landUseZone: map['landUseZone'] ?? '',
      soilType: map['soilType'] ?? '',
      soilCompaction: map['soilCompaction'] ?? '',
      drainage: map['drainage'] ?? '',
      siteSlope: map['siteSlope'] ?? '',
      aspect: map['aspect'] ?? '',
      proximityToBuildings: (map['proximityToBuildings'] ?? 0).toDouble(),
      proximityToServices: map['proximityToServices'] ?? '',
      vigorRating: map['vigorRating'] ?? '',
      foliageDensity: map['foliageDensity'] ?? '',
      foliageColor: map['foliageColor'] ?? '',
      diebackPercent: (map['diebackPercent'] ?? 0).toDouble(),
      stressIndicators: List<String>.from(map['stressIndicators'] ?? []),
      growthRate: map['growthRate'] ?? '',
      seasonalCondition: map['seasonalCondition'] ?? '',
      crownForm: map['crownForm'] ?? '',
      crownDensity: map['crownDensity'] ?? '',
      branchStructure: map['branchStructure'] ?? '',
      trunkForm: map['trunkForm'] ?? '',
      trunkLean: map['trunkLean'] ?? '',
      leanDirection: map['leanDirection'] ?? '',
      rootPlateCondition: map['rootPlateCondition'] ?? '',
      buttressRoots: map['buttressRoots'] ?? false,
      surfaceRoots: map['surfaceRoots'] ?? false,
      includedBark: map['includedBark'] ?? false,
      includedBarkLocation: map['includedBarkLocation'] ?? '',
      structuralDefects: List<String>.from(map['structuralDefects'] ?? []),
      structuralRating: map['structuralRating'] ?? '',
      tpzArea: (map['tpzArea'] ?? 0).toDouble(),
      encroachmentPresent: map['encroachmentPresent'] ?? false,
      encroachmentType: List<String>.from(map['encroachmentType'] ?? []),
      protectionMeasures: map['protectionMeasures'] ?? '',
      // Phase 2 - VTA
      cavityPresent: map['cavityPresent'] ?? false,
      cavitySize: map['cavitySize'] ?? '',
      cavityLocation: map['cavityLocation'] ?? '',
      decayExtent: map['decayExtent'] ?? '',
      decayType: map['decayType'] ?? '',
      fungalFruitingBodies: map['fungalFruitingBodies'] ?? false,
      fungalSpecies: map['fungalSpecies'] ?? '',
      barkDamagePercent: (map['barkDamagePercent'] ?? 0).toDouble(),
      barkDamageType: List<String>.from(map['barkDamageType'] ?? []),
      cracksSplits: map['cracksSplits'] ?? false,
      cracksSplitsLocation: map['cracksSplitsLocation'] ?? '',
      deadWoodPercent: (map['deadWoodPercent'] ?? 0).toDouble(),
      girdlingRoots: map['girdlingRoots'] ?? false,
      girdlingRootsSeverity: map['girdlingRootsSeverity'] ?? '',
      rootDamage: map['rootDamage'] ?? false,
      rootDamageDescription: map['rootDamageDescription'] ?? '',
      mechanicalDamage: map['mechanicalDamage'] ?? false,
      mechanicalDamageDescription: map['mechanicalDamageDescription'] ?? '',
      // Phase 2 - QTRA
      qtraTargetType: map['qtraTargetType'] ?? '',
      qtraTargetValue: map['qtraTargetValue'] ?? '',
      qtraOccupancyRate: map['qtraOccupancyRate'] ?? '',
      qtraImpactPotential: map['qtraImpactPotential'] ?? '',
      qtraProbabilityOfFailure: (map['qtraProbabilityOfFailure'] ?? 0).toDouble(),
      qtraProbabilityOfImpact: (map['qtraProbabilityOfImpact'] ?? 0).toDouble(),
      qtraRiskOfHarm: (map['qtraRiskOfHarm'] ?? 0).toDouble(),
      qtraRiskRating: map['qtraRiskRating'] ?? '',
      // Phase 3 - Impact
      developmentType: map['developmentType'] ?? '',
      constructionZoneDistance: (map['constructionZoneDistance'] ?? 0).toDouble(),
      rootZoneEncroachmentPercent: (map['rootZoneEncroachmentPercent'] ?? 0).toDouble(),
      canopyEncroachmentPercent: (map['canopyEncroachmentPercent'] ?? 0).toDouble(),
      excavationImpact: map['excavationImpact'] ?? '',
      serviceInstallationImpact: map['serviceInstallationImpact'] ?? false,
      serviceInstallationDescription: map['serviceInstallationDescription'] ?? '',
      demolitionImpact: map['demolitionImpact'] ?? false,
      demolitionDescription: map['demolitionDescription'] ?? '',
      accessRouteImpact: map['accessRouteImpact'] ?? false,
      accessRouteDescription: map['accessRouteDescription'] ?? '',
      impactRating: map['impactRating'] ?? '',
      mitigationMeasures: map['mitigationMeasures'] ?? '',
      // Phase 3 - Development
      planningPermitRequired: map['planningPermitRequired'] ?? false,
      planningPermitNumber: map['planningPermitNumber'] ?? '',
      planningPermitStatus: map['planningPermitStatus'] ?? '',
      planningOverlay: map['planningOverlay'] ?? '',
      heritageOverlay: map['heritageOverlay'] ?? false,
      significantLandscapeOverlay: map['significantLandscapeOverlay'] ?? false,
      vegetationProtectionOverlay: map['vegetationProtectionOverlay'] ?? false,
      localLawProtected: map['localLawProtected'] ?? false,
      localLawReference: map['localLawReference'] ?? '',
      as4970Compliant: map['as4970Compliant'] ?? false,
      arboristReportRequired: map['arboristReportRequired'] ?? false,
      councilNotification: map['councilNotification'] ?? false,
      neighborNotification: map['neighborNotification'] ?? false,
      // Phase 3 - Retention
      retentionRecommendation: map['retentionRecommendation'] ?? '',
      retentionJustification: map['retentionJustification'] ?? '',
      removalJustification: map['removalJustification'] ?? '',
      significance: map['significance'] ?? '',
      replantingRequired: map['replantingRequired'] ?? false,
      replacementRatio: (map['replacementRatio'] ?? 0).toDouble(),
      offsetRequirements: map['offsetRequirements'] ?? '',
      // Phase 3 - Management
      pruningType: List<String>.from(map['pruningType'] ?? []),
      pruningSpecification: map['pruningSpecification'] ?? '',
      worksPriority: map['worksPriority'] ?? '',
      worksTimeframe: map['worksTimeframe'] ?? '',
      estimatedCostRange: map['estimatedCostRange'] ?? '',
      accessRequirements: List<String>.from(map['accessRequirements'] ?? []),
      arboristSupervisionRequired: map['arboristSupervisionRequired'] ?? false,
      treeProtectionMeasures: map['treeProtectionMeasures'] ?? '',
      postWorksMonitoring: map['postWorksMonitoring'] ?? false,
      postWorksMonitoringFrequency: map['postWorksMonitoringFrequency'] ?? '',
      worksCompletionDate: map['worksCompletionDate'] != null ? DateTime.tryParse(map['worksCompletionDate']) : null,
      worksCompliance: map['worksCompliance'] ?? false,
      // Phase 3 - Valuation
      valuationMethod: map['valuationMethod'] ?? '',
      baseValue: (map['baseValue'] ?? 0).toDouble(),
      conditionFactor: (map['conditionFactor'] ?? 0).toDouble(),
      locationFactor: (map['locationFactor'] ?? 0).toDouble(),
      contributionFactor: (map['contributionFactor'] ?? 0).toDouble(),
      totalValuation: (map['totalValuation'] ?? 0).toDouble(),
      valuationDate: map['valuationDate'] != null ? DateTime.tryParse(map['valuationDate']) : null,
      valuerName: map['valuerName'] ?? '',
      // Phase 3 - Ecological
      wildlifeHabitatValue: map['wildlifeHabitatValue'] ?? '',
      hollowBearingTree: map['hollowBearingTree'] ?? false,
      nestingSites: map['nestingSites'] ?? false,
      nestingSpecies: map['nestingSpecies'] ?? '',
      habitatFeatures: List<String>.from(map['habitatFeatures'] ?? []),
      biodiversityValue: map['biodiversityValue'] ?? '',
      indigenousSignificance: map['indigenousSignificance'] ?? false,
      indigenousSignificanceDetails: map['indigenousSignificanceDetails'] ?? '',
      culturalHeritage: map['culturalHeritage'] ?? false,
      culturalHeritageDetails: map['culturalHeritageDetails'] ?? '',
      amenityValue: map['amenityValue'] ?? '',
      shadeProvision: map['shadeProvision'] ?? '',
      // Phase 3 - Regulatory
      stateSignificant: map['stateSignificant'] ?? false,
      heritageListed: map['heritageListed'] ?? false,
      heritageReference: map['heritageReference'] ?? '',
      significantTreeRegister: map['significantTreeRegister'] ?? false,
      bushfireManagementOverlay: map['bushfireManagementOverlay'] ?? false,
      environmentalSignificanceOverlay: map['environmentalSignificanceOverlay'] ?? false,
      waterwayProtection: map['waterwayProtection'] ?? false,
      threatenedSpeciesHabitat: map['threatenedSpeciesHabitat'] ?? false,
      insuranceNotificationRequired: map['insuranceNotificationRequired'] ?? false,
      legalLiabilityAssessment: map['legalLiabilityAssessment'] ?? '',
      complianceNotes: map['complianceNotes'] ?? '',
      // Phase 3 - Monitoring
      nextInspectionDate: map['nextInspectionDate'] != null ? DateTime.tryParse(map['nextInspectionDate']) : null,
      inspectionFrequency: map['inspectionFrequency'] ?? '',
      monitoringRequired: map['monitoringRequired'] ?? false,
      monitoringFocus: List<String>.from(map['monitoringFocus'] ?? []),
      alertLevel: map['alertLevel'] ?? '',
      followUpActions: map['followUpActions'] ?? '',
      complianceCheckDate: map['complianceCheckDate'] != null ? DateTime.tryParse(map['complianceCheckDate']) : null,
      // Phase 3 - Diagnostics
      resistographTest: map['resistographTest'] ?? false,
      resistographDate: map['resistographDate'] != null ? DateTime.tryParse(map['resistographDate']) : null,
      resistographResults: map['resistographResults'] ?? '',
      sonicTomography: map['sonicTomography'] ?? false,
      sonicTomographyDate: map['sonicTomographyDate'] != null ? DateTime.tryParse(map['sonicTomographyDate']) : null,
      sonicTomographyResults: map['sonicTomographyResults'] ?? '',
      pullingTest: map['pullingTest'] ?? false,
      pullingTestDate: map['pullingTestDate'] != null ? DateTime.tryParse(map['pullingTestDate']) : null,
      pullingTestResults: map['pullingTestResults'] ?? '',
      rootCollarExcavation: map['rootCollarExcavation'] ?? false,
      rootCollarFindings: map['rootCollarFindings'] ?? '',
      soilTesting: map['soilTesting'] ?? false,
      soilTestingResults: map['soilTestingResults'] ?? '',
      pathologyReport: map['pathologyReport'] ?? '',
      diagnosticImages: List<String>.from(map['diagnosticImages'] ?? []),
      specialistConsultant: map['specialistConsultant'] ?? '',
      diagnosticSummary: map['diagnosticSummary'] ?? '',
      exportGroups: map['exportGroups'] != null ? Map<String, bool>.from(map['exportGroups']) : null,
    );
  }

  /// Convert TreeEntry to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'id': id,
      'species': species,
      'dsh': dsh,
      'height': height,
      'condition': condition,
      'comments': comments,
      'permitRequired': permitRequired,
      'latitude': latitude,
      'longitude': longitude,
      'srz': srz,
      'nrz': nrz,
      'ageClass': ageClass,
      'retentionValue': retentionValue,
      'riskRating': riskRating,
      'locationDescription': locationDescription,
      'habitatValue': habitatValue,
      'recommendedWorks': recommendedWorks,
      'healthForm': healthForm,
      'diseasesPresent': diseasesPresent,
      'canopySpread': canopySpread,
      'clearanceToStructures': clearanceToStructures,
      'origin': origin,
      'pastManagement': pastManagement,
      'pestPresence': pestPresence,
      'notes': notes,
      'siteId': siteId,
      'targetOccupancy': targetOccupancy,
      'defectsObserved': defectsObserved,
      'likelihoodOfFailure': likelihoodOfFailure,
      'likelihoodOfImpact': likelihoodOfFailure,
      'consequenceOfFailure': consequenceOfFailure,
      'overallRiskRating': overallRiskRating,
      'vtaNotes': vtaNotes,
      'vtaDefects': vtaDefects,
      'inspectionDate': inspectionDate != null ? Timestamp.fromDate(inspectionDate!) : null,
      'inspectorName': inspectorName,
      'voiceNotes': voiceNotes,
      'voiceNoteAudioPath': voiceNoteAudioPath,
      'voiceAudioUrl': voiceAudioUrl,
      'imageUrls': imageUrls,
      'imageLocalPaths': imageLocalPaths,
      'syncStatus': syncStatus,
      // Phase 1 fields
      'siteType': siteType,
      'landUseZone': landUseZone,
      'soilType': soilType,
      'soilCompaction': soilCompaction,
      'drainage': drainage,
      'siteSlope': siteSlope,
      'aspect': aspect,
      'proximityToBuildings': proximityToBuildings,
      'proximityToServices': proximityToServices,
      'vigorRating': vigorRating,
      'foliageDensity': foliageDensity,
      'foliageColor': foliageColor,
      'diebackPercent': diebackPercent,
      'stressIndicators': stressIndicators,
      'growthRate': growthRate,
      'seasonalCondition': seasonalCondition,
      'crownForm': crownForm,
      'crownDensity': crownDensity,
      'branchStructure': branchStructure,
      'trunkForm': trunkForm,
      'trunkLean': trunkLean,
      'leanDirection': leanDirection,
      'rootPlateCondition': rootPlateCondition,
      'buttressRoots': buttressRoots,
      'surfaceRoots': surfaceRoots,
      'includedBark': includedBark,
      'includedBarkLocation': includedBarkLocation,
      'structuralDefects': structuralDefects,
      'structuralRating': structuralRating,
      'tpzArea': tpzArea,
      'encroachmentPresent': encroachmentPresent,
      'encroachmentType': encroachmentType,
      'protectionMeasures': protectionMeasures,
      // Phase 2 - VTA
      'cavityPresent': cavityPresent,
      'cavitySize': cavitySize,
      'cavityLocation': cavityLocation,
      'decayExtent': decayExtent,
      'decayType': decayType,
      'fungalFruitingBodies': fungalFruitingBodies,
      'fungalSpecies': fungalSpecies,
      'barkDamagePercent': barkDamagePercent,
      'barkDamageType': barkDamageType,
      'cracksSplits': cracksSplits,
      'cracksSplitsLocation': cracksSplitsLocation,
      'deadWoodPercent': deadWoodPercent,
      'girdlingRoots': girdlingRoots,
      'girdlingRootsSeverity': girdlingRootsSeverity,
      'rootDamage': rootDamage,
      'rootDamageDescription': rootDamageDescription,
      'mechanicalDamage': mechanicalDamage,
      'mechanicalDamageDescription': mechanicalDamageDescription,
      // Phase 2 - QTRA
      'qtraTargetType': qtraTargetType,
      'qtraTargetValue': qtraTargetValue,
      'qtraOccupancyRate': qtraOccupancyRate,
      'qtraImpactPotential': qtraImpactPotential,
      'qtraProbabilityOfFailure': qtraProbabilityOfFailure,
      'qtraProbabilityOfImpact': qtraProbabilityOfImpact,
      'qtraRiskOfHarm': qtraRiskOfHarm,
      'qtraRiskRating': qtraRiskRating,
      // Phase 3 - Impact
      'developmentType': developmentType,
      'constructionZoneDistance': constructionZoneDistance,
      'rootZoneEncroachmentPercent': rootZoneEncroachmentPercent,
      'canopyEncroachmentPercent': canopyEncroachmentPercent,
      'excavationImpact': excavationImpact,
      'serviceInstallationImpact': serviceInstallationImpact,
      'serviceInstallationDescription': serviceInstallationDescription,
      'demolitionImpact': demolitionImpact,
      'demolitionDescription': demolitionDescription,
      'accessRouteImpact': accessRouteImpact,
      'accessRouteDescription': accessRouteDescription,
      'impactRating': impactRating,
      'mitigationMeasures': mitigationMeasures,
      // Phase 3 - Development
      'planningPermitRequired': planningPermitRequired,
      'planningPermitNumber': planningPermitNumber,
      'planningPermitStatus': planningPermitStatus,
      'planningOverlay': planningOverlay,
      'heritageOverlay': heritageOverlay,
      'significantLandscapeOverlay': significantLandscapeOverlay,
      'vegetationProtectionOverlay': vegetationProtectionOverlay,
      'localLawProtected': localLawProtected,
      'localLawReference': localLawReference,
      'as4970Compliant': as4970Compliant,
      'arboristReportRequired': arboristReportRequired,
      'councilNotification': councilNotification,
      'neighborNotification': neighborNotification,
      // Phase 3 - Retention
      'retentionRecommendation': retentionRecommendation,
      'retentionJustification': retentionJustification,
      'removalJustification': removalJustification,
      'significance': significance,
      'replantingRequired': replantingRequired,
      'replacementRatio': replacementRatio,
      'offsetRequirements': offsetRequirements,
      // Phase 3 - Management
      'pruningType': pruningType,
      'pruningSpecification': pruningSpecification,
      'worksPriority': worksPriority,
      'worksTimeframe': worksTimeframe,
      'estimatedCostRange': estimatedCostRange,
      'accessRequirements': accessRequirements,
      'arboristSupervisionRequired': arboristSupervisionRequired,
      'treeProtectionMeasures': treeProtectionMeasures,
      'postWorksMonitoring': postWorksMonitoring,
      'postWorksMonitoringFrequency': postWorksMonitoringFrequency,
      'worksCompletionDate': worksCompletionDate != null ? Timestamp.fromDate(worksCompletionDate!) : null,
      'worksCompliance': worksCompliance,
      // Phase 3 - Valuation
      'valuationMethod': valuationMethod,
      'baseValue': baseValue,
      'conditionFactor': conditionFactor,
      'locationFactor': locationFactor,
      'contributionFactor': contributionFactor,
      'totalValuation': totalValuation,
      'valuationDate': valuationDate != null ? Timestamp.fromDate(valuationDate!) : null,
      'valuerName': valuerName,
      // Phase 3 - Ecological
      'wildlifeHabitatValue': wildlifeHabitatValue,
      'hollowBearingTree': hollowBearingTree,
      'nestingSites': nestingSites,
      'nestingSpecies': nestingSpecies,
      'habitatFeatures': habitatFeatures,
      'biodiversityValue': biodiversityValue,
      'indigenousSignificance': indigenousSignificance,
      'indigenousSignificanceDetails': indigenousSignificanceDetails,
      'culturalHeritage': culturalHeritage,
      'culturalHeritageDetails': culturalHeritageDetails,
      'amenityValue': amenityValue,
      'shadeProvision': shadeProvision,
      // Phase 3 - Regulatory
      'stateSignificant': stateSignificant,
      'heritageListed': heritageListed,
      'heritageReference': heritageReference,
      'significantTreeRegister': significantTreeRegister,
      'bushfireManagementOverlay': bushfireManagementOverlay,
      'environmentalSignificanceOverlay': environmentalSignificanceOverlay,
      'waterwayProtection': waterwayProtection,
      'threatenedSpeciesHabitat': threatenedSpeciesHabitat,
      'insuranceNotificationRequired': insuranceNotificationRequired,
      'legalLiabilityAssessment': legalLiabilityAssessment,
      'complianceNotes': complianceNotes,
      // Phase 3 - Monitoring
      'nextInspectionDate': nextInspectionDate != null ? Timestamp.fromDate(nextInspectionDate!) : null,
      'inspectionFrequency': inspectionFrequency,
      'monitoringRequired': monitoringRequired,
      'monitoringFocus': monitoringFocus,
      'alertLevel': alertLevel,
      'followUpActions': followUpActions,
      'complianceCheckDate': complianceCheckDate != null ? Timestamp.fromDate(complianceCheckDate!) : null,
      // Phase 3 - Diagnostics
      'resistographTest': resistographTest,
      'resistographDate': resistographDate != null ? Timestamp.fromDate(resistographDate!) : null,
      'resistographResults': resistographResults,
      'sonicTomography': sonicTomography,
      'sonicTomographyDate': sonicTomographyDate != null ? Timestamp.fromDate(sonicTomographyDate!) : null,
      'sonicTomographyResults': sonicTomographyResults,
      'pullingTest': pullingTest,
      'pullingTestDate': pullingTestDate != null ? Timestamp.fromDate(pullingTestDate!) : null,
      'pullingTestResults': pullingTestResults,
      'rootCollarExcavation': rootCollarExcavation,
      'rootCollarFindings': rootCollarFindings,
      'soilTesting': soilTesting,
      'soilTestingResults': soilTestingResults,
      'pathologyReport': pathologyReport,
      'diagnosticImages': diagnosticImages,
      'specialistConsultant': specialistConsultant,
      'diagnosticSummary': diagnosticSummary,
      'exportGroups': exportGroups,
    };
  }

  /// Create TreeEntry from Firestore document
  factory TreeEntry.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return TreeEntry(
      id: data['id'] ?? doc.id,
      species: data['species'] ?? '',
      dsh: (data['dsh'] ?? 0).toDouble(),
      height: (data['height'] ?? 0).toDouble(),
      condition: data['condition'] ?? '',
      comments: data['comments'] ?? '',
      permitRequired: data['permitRequired'] ?? false,
      latitude: (data['latitude'] ?? 0).toDouble(),
      longitude: (data['longitude'] ?? 0).toDouble(),
      srz: (data['srz'] ?? 0).toDouble(),
      nrz: (data['nrz'] ?? 0).toDouble(),
      ageClass: data['ageClass'] ?? '',
      retentionValue: data['retentionValue'] ?? '',
      riskRating: data['riskRating'] ?? '',
      locationDescription: data['locationDescription'] ?? '',
      habitatValue: data['habitatValue'] ?? '',
      recommendedWorks: data['recommendedWorks'] ?? '',
      healthForm: data['healthForm'] ?? '',
      diseasesPresent: data['diseasesPresent'] ?? '',
      canopySpread: (data['canopySpread'] ?? 0).toDouble(),
      clearanceToStructures: (data['clearanceToStructures'] ?? 0).toDouble(),
      origin: data['origin'] ?? '',
      pastManagement: data['pastManagement'] ?? '',
      pestPresence: data['pestPresence'] ?? '',
      notes: data['notes'] ?? '',
      siteId: data['siteId'] ?? '',
      targetOccupancy: data['targetOccupancy'] ?? '',
      defectsObserved: List<String>.from(data['defectsObserved'] ?? []),
      likelihoodOfFailure: data['likelihoodOfFailure'] ?? '',
      likelihoodOfImpact: data['likelihoodOfImpact'] ?? '',
      consequenceOfFailure: data['consequenceOfFailure'] ?? '',
      overallRiskRating: data['overallRiskRating'] ?? '',
      vtaNotes: data['vtaNotes'] ?? '',
      vtaDefects: List<String>.from(data['vtaDefects'] ?? []),
      inspectionDate: data['inspectionDate'] != null ? (data['inspectionDate'] as Timestamp).toDate() : null,
      inspectorName: data['inspectorName'] ?? '',
      voiceNotes: data['voiceNotes'] ?? '',
      voiceNoteAudioPath: data['voiceNoteAudioPath'] ?? '',
      voiceAudioUrl: data['voiceAudioUrl'] ?? '',
      imageUrls: List<String>.from(data['imageUrls'] ?? []),
      imageLocalPaths: List<String>.from(data['imageLocalPaths'] ?? []),
      syncStatus: data['syncStatus'] ?? 'local',
      // Phase 1 fields
      siteType: data['siteType'] ?? '',
      landUseZone: data['landUseZone'] ?? '',
      soilType: data['soilType'] ?? '',
      soilCompaction: data['soilCompaction'] ?? '',
      drainage: data['drainage'] ?? '',
      siteSlope: data['siteSlope'] ?? '',
      aspect: data['aspect'] ?? '',
      proximityToBuildings: (data['proximityToBuildings'] ?? 0).toDouble(),
      proximityToServices: data['proximityToServices'] ?? '',
      vigorRating: data['vigorRating'] ?? '',
      foliageDensity: data['foliageDensity'] ?? '',
      foliageColor: data['foliageColor'] ?? '',
      diebackPercent: (data['diebackPercent'] ?? 0).toDouble(),
      stressIndicators: List<String>.from(data['stressIndicators'] ?? []),
      growthRate: data['growthRate'] ?? '',
      seasonalCondition: data['seasonalCondition'] ?? '',
      crownForm: data['crownForm'] ?? '',
      crownDensity: data['crownDensity'] ?? '',
      branchStructure: data['branchStructure'] ?? '',
      trunkForm: data['trunkForm'] ?? '',
      trunkLean: data['trunkLean'] ?? '',
      leanDirection: data['leanDirection'] ?? '',
      rootPlateCondition: data['rootPlateCondition'] ?? '',
      buttressRoots: data['buttressRoots'] ?? false,
      surfaceRoots: data['surfaceRoots'] ?? false,
      includedBark: data['includedBark'] ?? false,
      includedBarkLocation: data['includedBarkLocation'] ?? '',
      structuralDefects: List<String>.from(data['structuralDefects'] ?? []),
      structuralRating: data['structuralRating'] ?? '',
      tpzArea: (data['tpzArea'] ?? 0).toDouble(),
      encroachmentPresent: data['encroachmentPresent'] ?? false,
      encroachmentType: List<String>.from(data['encroachmentType'] ?? []),
      protectionMeasures: data['protectionMeasures'] ?? '',
      // Phase 2 - VTA
      cavityPresent: data['cavityPresent'] ?? false,
      cavitySize: data['cavitySize'] ?? '',
      cavityLocation: data['cavityLocation'] ?? '',
      decayExtent: data['decayExtent'] ?? '',
      decayType: data['decayType'] ?? '',
      fungalFruitingBodies: data['fungalFruitingBodies'] ?? false,
      fungalSpecies: data['fungalSpecies'] ?? '',
      barkDamagePercent: (data['barkDamagePercent'] ?? 0).toDouble(),
      barkDamageType: List<String>.from(data['barkDamageType'] ?? []),
      cracksSplits: data['cracksSplits'] ?? false,
      cracksSplitsLocation: data['cracksSplitsLocation'] ?? '',
      deadWoodPercent: (data['deadWoodPercent'] ?? 0).toDouble(),
      girdlingRoots: data['girdlingRoots'] ?? false,
      girdlingRootsSeverity: data['girdlingRootsSeverity'] ?? '',
      rootDamage: data['rootDamage'] ?? false,
      rootDamageDescription: data['rootDamageDescription'] ?? '',
      mechanicalDamage: data['mechanicalDamage'] ?? false,
      mechanicalDamageDescription: data['mechanicalDamageDescription'] ?? '',
      // Phase 2 - QTRA
      qtraTargetType: data['qtraTargetType'] ?? '',
      qtraTargetValue: data['qtraTargetValue'] ?? '',
      qtraOccupancyRate: data['qtraOccupancyRate'] ?? '',
      qtraImpactPotential: data['qtraImpactPotential'] ?? '',
      qtraProbabilityOfFailure: (data['qtraProbabilityOfFailure'] ?? 0).toDouble(),
      qtraProbabilityOfImpact: (data['qtraProbabilityOfImpact'] ?? 0).toDouble(),
      qtraRiskOfHarm: (data['qtraRiskOfHarm'] ?? 0).toDouble(),
      qtraRiskRating: data['qtraRiskRating'] ?? '',
      // Phase 3 - Impact
      developmentType: data['developmentType'] ?? '',
      constructionZoneDistance: (data['constructionZoneDistance'] ?? 0).toDouble(),
      rootZoneEncroachmentPercent: (data['rootZoneEncroachmentPercent'] ?? 0).toDouble(),
      canopyEncroachmentPercent: (data['canopyEncroachmentPercent'] ?? 0).toDouble(),
      excavationImpact: data['excavationImpact'] ?? '',
      serviceInstallationImpact: data['serviceInstallationImpact'] ?? false,
      serviceInstallationDescription: data['serviceInstallationDescription'] ?? '',
      demolitionImpact: data['demolitionImpact'] ?? false,
      demolitionDescription: data['demolitionDescription'] ?? '',
      accessRouteImpact: data['accessRouteImpact'] ?? false,
      accessRouteDescription: data['accessRouteDescription'] ?? '',
      impactRating: data['impactRating'] ?? '',
      mitigationMeasures: data['mitigationMeasures'] ?? '',
      // Phase 3 - Development
      planningPermitRequired: data['planningPermitRequired'] ?? false,
      planningPermitNumber: data['planningPermitNumber'] ?? '',
      planningPermitStatus: data['planningPermitStatus'] ?? '',
      planningOverlay: data['planningOverlay'] ?? '',
      heritageOverlay: data['heritageOverlay'] ?? false,
      significantLandscapeOverlay: data['significantLandscapeOverlay'] ?? false,
      vegetationProtectionOverlay: data['vegetationProtectionOverlay'] ?? false,
      localLawProtected: data['localLawProtected'] ?? false,
      localLawReference: data['localLawReference'] ?? '',
      as4970Compliant: data['as4970Compliant'] ?? false,
      arboristReportRequired: data['arboristReportRequired'] ?? false,
      councilNotification: data['councilNotification'] ?? false,
      neighborNotification: data['neighborNotification'] ?? false,
      // Phase 3 - Retention
      retentionRecommendation: data['retentionRecommendation'] ?? '',
      retentionJustification: data['retentionJustification'] ?? '',
      removalJustification: data['removalJustification'] ?? '',
      significance: data['significance'] ?? '',
      replantingRequired: data['replantingRequired'] ?? false,
      replacementRatio: (data['replacementRatio'] ?? 0).toDouble(),
      offsetRequirements: data['offsetRequirements'] ?? '',
      // Phase 3 - Management
      pruningType: List<String>.from(data['pruningType'] ?? []),
      pruningSpecification: data['pruningSpecification'] ?? '',
      worksPriority: data['worksPriority'] ?? '',
      worksTimeframe: data['worksTimeframe'] ?? '',
      estimatedCostRange: data['estimatedCostRange'] ?? '',
      accessRequirements: List<String>.from(data['accessRequirements'] ?? []),
      arboristSupervisionRequired: data['arboristSupervisionRequired'] ?? false,
      treeProtectionMeasures: data['treeProtectionMeasures'] ?? '',
      postWorksMonitoring: data['postWorksMonitoring'] ?? false,
      postWorksMonitoringFrequency: data['postWorksMonitoringFrequency'] ?? '',
      worksCompletionDate: data['worksCompletionDate'] != null ? (data['worksCompletionDate'] as Timestamp).toDate() : null,
      worksCompliance: data['worksCompliance'] ?? false,
      // Phase 3 - Valuation
      valuationMethod: data['valuationMethod'] ?? '',
      baseValue: (data['baseValue'] ?? 0).toDouble(),
      conditionFactor: (data['conditionFactor'] ?? 0).toDouble(),
      locationFactor: (data['locationFactor'] ?? 0).toDouble(),
      contributionFactor: (data['contributionFactor'] ?? 0).toDouble(),
      totalValuation: (data['totalValuation'] ?? 0).toDouble(),
      valuationDate: data['valuationDate'] != null ? (data['valuationDate'] as Timestamp).toDate() : null,
      valuerName: data['valuerName'] ?? '',
      // Phase 3 - Ecological
      wildlifeHabitatValue: data['wildlifeHabitatValue'] ?? '',
      hollowBearingTree: data['hollowBearingTree'] ?? false,
      nestingSites: data['nestingSites'] ?? false,
      nestingSpecies: data['nestingSpecies'] ?? '',
      habitatFeatures: List<String>.from(data['habitatFeatures'] ?? []),
      biodiversityValue: data['biodiversityValue'] ?? '',
      indigenousSignificance: data['indigenousSignificance'] ?? false,
      indigenousSignificanceDetails: data['indigenousSignificanceDetails'] ?? '',
      culturalHeritage: data['culturalHeritage'] ?? false,
      culturalHeritageDetails: data['culturalHeritageDetails'] ?? '',
      amenityValue: data['amenityValue'] ?? '',
      shadeProvision: data['shadeProvision'] ?? '',
      // Phase 3 - Regulatory
      stateSignificant: data['stateSignificant'] ?? false,
      heritageListed: data['heritageListed'] ?? false,
      heritageReference: data['heritageReference'] ?? '',
      significantTreeRegister: data['significantTreeRegister'] ?? false,
      bushfireManagementOverlay: data['bushfireManagementOverlay'] ?? false,
      environmentalSignificanceOverlay: data['environmentalSignificanceOverlay'] ?? false,
      waterwayProtection: data['waterwayProtection'] ?? false,
      threatenedSpeciesHabitat: data['threatenedSpeciesHabitat'] ?? false,
      insuranceNotificationRequired: data['insuranceNotificationRequired'] ?? false,
      legalLiabilityAssessment: data['legalLiabilityAssessment'] ?? '',
      complianceNotes: data['complianceNotes'] ?? '',
      // Phase 3 - Monitoring
      nextInspectionDate: data['nextInspectionDate'] != null ? (data['nextInspectionDate'] as Timestamp).toDate() : null,
      inspectionFrequency: data['inspectionFrequency'] ?? '',
      monitoringRequired: data['monitoringRequired'] ?? false,
      monitoringFocus: List<String>.from(data['monitoringFocus'] ?? []),
      alertLevel: data['alertLevel'] ?? '',
      followUpActions: data['followUpActions'] ?? '',
      complianceCheckDate: data['complianceCheckDate'] != null ? (data['complianceCheckDate'] as Timestamp).toDate() : null,
      // Phase 3 - Diagnostics
      resistographTest: data['resistographTest'] ?? false,
      resistographDate: data['resistographDate'] != null ? (data['resistographDate'] as Timestamp).toDate() : null,
      resistographResults: data['resistographResults'] ?? '',
      sonicTomography: data['sonicTomography'] ?? false,
      sonicTomographyDate: data['sonicTomographyDate'] != null ? (data['sonicTomographyDate'] as Timestamp).toDate() : null,
      sonicTomographyResults: data['sonicTomographyResults'] ?? '',
      pullingTest: data['pullingTest'] ?? false,
      pullingTestDate: data['pullingTestDate'] != null ? (data['pullingTestDate'] as Timestamp).toDate() : null,
      pullingTestResults: data['pullingTestResults'] ?? '',
      rootCollarExcavation: data['rootCollarExcavation'] ?? false,
      rootCollarFindings: data['rootCollarFindings'] ?? '',
      soilTesting: data['soilTesting'] ?? false,
      soilTestingResults: data['soilTestingResults'] ?? '',
      pathologyReport: data['pathologyReport'] ?? '',
      diagnosticImages: List<String>.from(data['diagnosticImages'] ?? []),
      specialistConsultant: data['specialistConsultant'] ?? '',
      diagnosticSummary: data['diagnosticSummary'] ?? '',
      exportGroups: data['exportGroups'] != null ? Map<String, bool>.from(data['exportGroups']) : null,
    );
  }
}
