import 'package:intl/intl.dart';

import '../models/tree_entry.dart';

class TreeCsvExporter {
  /// Generate a CSV string for the provided trees.
  ///
  /// When [includePhotos] is false, photo-related columns are omitted.
  static String generate({
    required List<TreeEntry> trees,
    bool includePhotos = true,
    bool forceAllGroups = false,
  }) {
    if (trees.isEmpty) {
      return 'No trees found';
    }

    final exportGroups = Map<String, bool>.from(trees.first.exportGroups);
    final headers = <String>['Tree_ID'];
    final rows = <List<String>>[];

    bool isEnabled(String group, {bool defaultValue = true}) {
      if (forceAllGroups) {
        return true;
      }
      return exportGroups[group] ?? defaultValue;
    }

    void addHeaders(Iterable<String> values) => headers.addAll(values);

    final dateFormat = DateFormat('dd/MM/yyyy HH:mm');

    String escape(String input) {
      if (input.contains(',') || input.contains('"') || input.contains('\n')) {
        return '"${input.replaceAll('"', '""')}"';
      }
      return input;
    }

    String csvValue(dynamic value, {String placeholder = 'Not recorded'}) {
      if (value == null) {
        return escape(placeholder);
      }

      if (value is bool) {
        return escape(value ? 'Yes' : 'No');
      }

      if (value is DateTime) {
        return escape(dateFormat.format(value));
      }

      if (value is Iterable) {
        final items = value
            .where((element) => element != null && element.toString().trim().isNotEmpty)
            .map((element) => element.toString().trim())
            .toList();
        if (items.isEmpty) {
          return escape(placeholder);
        }
        return csvValue(items.join('; '), placeholder: placeholder);
      }

      final stringValue = value.toString().trim();
      if (stringValue.isEmpty) {
        return escape(placeholder);
      }

      return escape(stringValue);
    }

    addHeaders(['Tree_Number']);

    if (includePhotos && isEnabled('photos')) {
      addHeaders(['Image_Local_Paths', 'Image_URLs', 'Photo_Count']);
    }

    if (isEnabled('voice_notes')) {
      addHeaders(['Voice_Notes', 'Voice_Audio_Path', 'Voice_Audio_URL']);
    }

    if (isEnabled('basic_data')) {
      addHeaders([
        'Species',
        'DSH_cm',
        'Height_m',
        'Age_Class',
        'Condition',
        'Canopy_Spread_m',
        'Clearance_To_Structures_m',
        'Origin',
        'Past_Management',
        'Permit_Required',
        'Comments',
      ]);
    }

    if (isEnabled('location')) {
      addHeaders([
        'Location_Description',
        'Latitude',
        'Longitude',
        'Site_Type',
        'Land_Use_Zone',
        'Soil_Type',
        'Soil_Compaction',
        'Drainage',
        'Site_Slope',
        'Aspect',
        'Proximity_To_Buildings_m',
        'Proximity_To_Services',
      ]);
    }

    if (isEnabled('health')) {
      addHeaders([
        'Vigor_Rating',
        'Foliage_Density',
        'Foliage_Color',
        'Dieback_Percent',
        'Stress_Indicators',
        'Growth_Rate',
        'Seasonal_Condition',
        'Health_Form',
        'Pest_Presence',
      ]);
    }

    if (isEnabled('structure')) {
      addHeaders([
        'Crown_Form',
        'Crown_Density',
        'Branch_Structure',
        'Trunk_Form',
        'Trunk_Lean',
        'Lean_Direction',
        'Root_Plate_Condition',
        'Buttress_Roots',
        'Surface_Roots',
        'Included_Bark',
        'Included_Bark_Location',
        'Structural_Defects',
        'Structural_Rating',
      ]);
    }

    if (isEnabled('protection_zones')) {
      addHeaders(['TPZ_Area_m2', 'SRZ_m', 'NRZ_m']);
    }

    if (isEnabled('vta')) {
      addHeaders([
        'Cavity_Present',
        'Cavity_Size',
        'Cavity_Location',
        'Decay_Extent',
        'Decay_Type',
        'Fungal_Fruiting_Bodies',
        'Fungal_Species',
        'Bark_Damage_%',
        'Bark_Damage_Type',
        'Cracks_Splits',
        'Cracks_Location',
        'Dead_Wood_%',
        'Girdling_Roots',
        'Girdling_Severity',
        'Root_Damage',
        'Root_Damage_Description',
        'Mechanical_Damage',
        'Mechanical_Damage_Description',
        'VTA_Notes',
        'VTA_Defects',
        'Diseases_Present',
      ]);
    }

    if (isEnabled('isa_risk')) {
      addHeaders([
        'Target_Occupancy',
        'Defects_Observed',
        'Likelihood_Failure',
        'Likelihood_Impact',
        'Consequence_Failure',
        'Overall_Risk_Rating',
        'Risk_Rating',
      ]);
    }

    if (isEnabled('development')) {
      addHeaders([
        'Planning_Permit_Required',
        'Planning_Permit_Number',
        'Planning_Permit_Status',
        'Planning_Overlay',
        'Heritage_Overlay',
        'Significant_Landscape_Overlay',
        'Vegetation_Protection_Overlay',
        'Local_Law_Protected',
        'Local_Law_Reference',
        'AS4970_Compliant',
        'Arborist_Report_Required',
        'Council_Notification',
        'Neighbor_Notification',
      ]);
    }

    if (isEnabled('retention_removal')) {
      addHeaders([
        'Retention_Value',
        'Retention_Recommendation',
        'Retention_Justification',
        'Removal_Justification',
        'Significance',
        'Replanting_Required',
        'Replacement_Ratio',
        'Offset_Requirements',
      ]);
    }

    if (isEnabled('management')) {
      addHeaders([
        'Recommended_Works',
        'Pruning_Type',
        'Pruning_Specification',
        'Works_Priority',
        'Works_Timeframe',
        'Estimated_Cost',
        'Access_Requirements',
        'Arborist_Supervision_Required',
        'Tree_Protection_Measures',
        'Post_Works_Monitoring',
        'Post_Works_Monitoring_Frequency',
        'Works_Completion_Date',
        'Works_Compliance',
      ]);
    }

    if (isEnabled('qtra')) {
      addHeaders([
        'QTRA_Target_Type',
        'QTRA_Target_Value',
        'QTRA_Occupancy_Rate',
        'QTRA_Impact_Potential',
        'QTRA_Probability_Failure',
        'QTRA_Probability_Impact',
        'QTRA_Risk_Of_Harm',
        'QTRA_Risk_Rating',
      ]);
    }

    if (isEnabled('impact_assessment')) {
      addHeaders([
        'Development_Type',
        'Construction_Distance_m',
        'Root_Encroachment_%',
        'Canopy_Encroachment_%',
        'Excavation_Impact',
        'Service_Installation_Impact',
        'Service_Installation_Description',
        'Demolition_Impact',
        'Demolition_Description',
        'Access_Route_Impact',
        'Access_Route_Description',
        'Impact_Rating',
        'Mitigation_Measures',
      ]);
    }

    if (isEnabled('valuation', defaultValue: false)) {
      addHeaders([
        'Valuation_Method',
        'Base_Value',
        'Condition_Factor',
        'Location_Factor',
        'Contribution_Factor',
        'Total_Valuation',
        'Valuation_Date',
        'Valuer_Name',
      ]);
    }

    if (isEnabled('ecological')) {
      addHeaders([
        'Wildlife_Habitat_Value',
        'Hollow_Bearing_Tree',
        'Nesting_Sites',
        'Nesting_Species',
        'Habitat_Features',
        'Biodiversity_Value',
        'Indigenous_Significance',
        'Indigenous_Significance_Details',
        'Cultural_Heritage',
        'Cultural_Heritage_Details',
        'Amenity_Value',
        'Shade_Provision',
      ]);
    }

    if (isEnabled('regulatory')) {
      addHeaders([
        'State_Significant',
        'Heritage_Listed',
        'Heritage_Reference',
        'Significant_Tree_Register',
        'Bushfire_Management_Overlay',
        'Environmental_Significance_Overlay',
        'Waterway_Protection',
        'Threatened_Species_Habitat',
        'Insurance_Notification_Required',
        'Legal_Liability_Assessment',
        'Compliance_Notes',
      ]);
    }

    if (isEnabled('monitoring')) {
      addHeaders([
        'Next_Inspection_Date',
        'Inspection_Frequency',
        'Monitoring_Required',
        'Monitoring_Focus',
        'Alert_Level',
        'Follow_Up_Actions',
        'Compliance_Check_Date',
      ]);
    }

    if (isEnabled('diagnostics', defaultValue: false)) {
      addHeaders([
        'Resistograph_Test',
        'Resistograph_Date',
        'Resistograph_Results',
        'Sonic_Tomography',
        'Sonic_Tomography_Date',
        'Sonic_Tomography_Results',
        'Pulling_Test',
        'Pulling_Test_Date',
        'Pulling_Test_Results',
        'Root_Collar_Excavation',
        'Root_Collar_Findings',
        'Soil_Testing',
        'Soil_Testing_Results',
        'Pathology_Report',
        'Diagnostic_Images',
        'Specialist_Consultant',
        'Diagnostic_Summary',
      ]);
    }

    if (isEnabled('inspector_details')) {
      addHeaders(['Inspector_Name', 'Inspection_Date', 'Sync_Status', 'Notes']);
    }

    for (var i = 0; i < trees.length; i++) {
      final tree = trees[i];
      final treeNumber = 'T${i + 1}';
      final row = <String>[csvValue(tree.id, placeholder: 'Tree ID missing'), csvValue(treeNumber)];

      if (includePhotos && isEnabled('photos')) {
        row
          ..add(csvValue(tree.imageLocalPaths.join(';')))
          ..add(csvValue(tree.imageUrls.join(';')))
          ..add(csvValue(tree.imageLocalPaths.length));
      }

      if (isEnabled('voice_notes')) {
        row
          ..add(csvValue(tree.voiceNotes))
          ..add(csvValue(tree.voiceNoteAudioPath))
          ..add(csvValue(tree.voiceAudioUrl));
      }

      if (isEnabled('basic_data')) {
        row
          ..add(csvValue(tree.species))
          ..add(csvValue(tree.dsh))
          ..add(csvValue(tree.height))
          ..add(csvValue(tree.ageClass))
          ..add(csvValue(tree.condition))
          ..add(csvValue(tree.canopySpread))
          ..add(csvValue(tree.clearanceToStructures))
          ..add(csvValue(tree.origin))
          ..add(csvValue(tree.pastManagement))
          ..add(csvValue(tree.permitRequired))
          ..add(csvValue(tree.comments));
      }

      if (isEnabled('location')) {
        row
          ..add(csvValue(tree.locationDescription))
          ..add(csvValue(tree.latitude))
          ..add(csvValue(tree.longitude))
          ..add(csvValue(tree.siteType))
          ..add(csvValue(tree.landUseZone))
          ..add(csvValue(tree.soilType))
          ..add(csvValue(tree.soilCompaction))
          ..add(csvValue(tree.drainage))
          ..add(csvValue(tree.siteSlope))
          ..add(csvValue(tree.aspect))
          ..add(csvValue(tree.proximityToBuildings))
          ..add(csvValue(tree.proximityToServices));
      }

      if (isEnabled('health')) {
        row
          ..add(csvValue(tree.vigorRating))
          ..add(csvValue(tree.foliageDensity))
          ..add(csvValue(tree.foliageColor))
          ..add(csvValue(tree.diebackPercent))
          ..add(csvValue(tree.stressIndicators.join(';')))
          ..add(csvValue(tree.growthRate))
          ..add(csvValue(tree.seasonalCondition))
          ..add(csvValue(tree.healthForm))
          ..add(csvValue(tree.pestPresence));
      }

      if (isEnabled('structure')) {
        row
          ..add(csvValue(tree.crownForm))
          ..add(csvValue(tree.crownDensity))
          ..add(csvValue(tree.branchStructure))
          ..add(csvValue(tree.trunkForm))
          ..add(csvValue(tree.trunkLean))
          ..add(csvValue(tree.leanDirection))
          ..add(csvValue(tree.rootPlateCondition))
          ..add(csvValue(tree.buttressRoots))
          ..add(csvValue(tree.surfaceRoots))
          ..add(csvValue(tree.includedBark))
          ..add(csvValue(tree.includedBarkLocation))
          ..add(csvValue(tree.structuralDefects.join(';')))
          ..add(csvValue(tree.structuralRating));
      }

      if (isEnabled('protection_zones')) {
        row
          ..add(csvValue(tree.tpzArea))
          ..add(csvValue(tree.srz))
          ..add(csvValue(tree.nrz));
      }

      if (isEnabled('vta')) {
        row
          ..add(csvValue(tree.cavityPresent))
          ..add(csvValue(tree.cavitySize))
          ..add(csvValue(tree.cavityLocation))
          ..add(csvValue(tree.decayExtent))
          ..add(csvValue(tree.decayType))
          ..add(csvValue(tree.fungalFruitingBodies))
          ..add(csvValue(tree.fungalSpecies))
          ..add(csvValue(tree.barkDamagePercent))
          ..add(csvValue(tree.barkDamageType.join(';')))
          ..add(csvValue(tree.cracksSplits))
          ..add(csvValue(tree.cracksSplitsLocation))
          ..add(csvValue(tree.deadWoodPercent))
          ..add(csvValue(tree.girdlingRoots))
          ..add(csvValue(tree.girdlingRootsSeverity))
          ..add(csvValue(tree.rootDamage))
          ..add(csvValue(tree.rootDamageDescription))
          ..add(csvValue(tree.mechanicalDamage))
          ..add(csvValue(tree.mechanicalDamageDescription))
          ..add(csvValue(tree.vtaNotes))
          ..add(csvValue(tree.vtaDefects.join(';')))
          ..add(csvValue(tree.diseasesPresent));
      }

      if (isEnabled('isa_risk')) {
        row
          ..add(csvValue(tree.targetOccupancy))
          ..add(csvValue(tree.defectsObserved.join(';')))
          ..add(csvValue(tree.likelihoodOfFailure))
          ..add(csvValue(tree.likelihoodOfImpact))
          ..add(csvValue(tree.consequenceOfFailure))
          ..add(csvValue(tree.overallRiskRating))
          ..add(csvValue(tree.riskRating));
      }

      if (isEnabled('development')) {
        row
          ..add(csvValue(tree.planningPermitRequired))
          ..add(csvValue(tree.planningPermitNumber))
          ..add(csvValue(tree.planningPermitStatus))
          ..add(csvValue(tree.planningOverlay))
          ..add(csvValue(tree.heritageOverlay))
          ..add(csvValue(tree.significantLandscapeOverlay))
          ..add(csvValue(tree.vegetationProtectionOverlay))
          ..add(csvValue(tree.localLawProtected))
          ..add(csvValue(tree.localLawReference))
          ..add(csvValue(tree.as4970Compliant))
          ..add(csvValue(tree.arboristReportRequired))
          ..add(csvValue(tree.councilNotification))
          ..add(csvValue(tree.neighborNotification));
      }

      if (isEnabled('retention_removal')) {
        row
          ..add(csvValue(tree.retentionValue))
          ..add(csvValue(tree.retentionRecommendation))
          ..add(csvValue(tree.retentionJustification))
          ..add(csvValue(tree.removalJustification))
          ..add(csvValue(tree.significance))
          ..add(csvValue(tree.replantingRequired))
          ..add(csvValue(tree.replacementRatio))
          ..add(csvValue(tree.offsetRequirements));
      }

      if (isEnabled('management')) {
        row
          ..add(csvValue(tree.recommendedWorks))
          ..add(csvValue(tree.pruningType.join(';')))
          ..add(csvValue(tree.pruningSpecification))
          ..add(csvValue(tree.worksPriority))
          ..add(csvValue(tree.worksTimeframe))
          ..add(csvValue(tree.estimatedCostRange))
          ..add(csvValue(tree.accessRequirements.join(';')))
          ..add(csvValue(tree.arboristSupervisionRequired))
          ..add(csvValue(tree.treeProtectionMeasures))
          ..add(csvValue(tree.postWorksMonitoring))
          ..add(csvValue(tree.postWorksMonitoringFrequency))
          ..add(csvValue(tree.worksCompletionDate))
          ..add(csvValue(tree.worksCompliance));
      }

      if (isEnabled('qtra')) {
        row
          ..add(csvValue(tree.qtraTargetType))
          ..add(csvValue(tree.qtraTargetValue))
          ..add(csvValue(tree.qtraOccupancyRate))
          ..add(csvValue(tree.qtraImpactPotential))
          ..add(csvValue(tree.qtraProbabilityOfFailure))
          ..add(csvValue(tree.qtraProbabilityOfImpact))
          ..add(csvValue(tree.qtraRiskOfHarm))
          ..add(csvValue(tree.qtraRiskRating));
      }

      if (isEnabled('impact_assessment')) {
        row
          ..add(csvValue(tree.developmentType))
          ..add(csvValue(tree.constructionZoneDistance))
          ..add(csvValue(tree.rootZoneEncroachmentPercent))
          ..add(csvValue(tree.canopyEncroachmentPercent))
          ..add(csvValue(tree.excavationImpact))
          ..add(csvValue(tree.serviceInstallationImpact))
          ..add(csvValue(tree.serviceInstallationDescription))
          ..add(csvValue(tree.demolitionImpact))
          ..add(csvValue(tree.demolitionDescription))
          ..add(csvValue(tree.accessRouteImpact))
          ..add(csvValue(tree.accessRouteDescription))
          ..add(csvValue(tree.impactRating))
          ..add(csvValue(tree.mitigationMeasures));
      }

      if (isEnabled('valuation', defaultValue: false)) {
        row
          ..add(csvValue(tree.valuationMethod))
          ..add(csvValue(tree.baseValue))
          ..add(csvValue(tree.conditionFactor))
          ..add(csvValue(tree.locationFactor))
          ..add(csvValue(tree.contributionFactor))
          ..add(csvValue(tree.totalValuation))
          ..add(csvValue(tree.valuationDate))
          ..add(csvValue(tree.valuerName));
      }

      if (isEnabled('ecological')) {
        row
          ..add(csvValue(tree.wildlifeHabitatValue))
          ..add(csvValue(tree.hollowBearingTree))
          ..add(csvValue(tree.nestingSites))
          ..add(csvValue(tree.nestingSpecies))
          ..add(csvValue(tree.habitatFeatures.join(';')))
          ..add(csvValue(tree.biodiversityValue))
          ..add(csvValue(tree.indigenousSignificance))
          ..add(csvValue(tree.indigenousSignificanceDetails))
          ..add(csvValue(tree.culturalHeritage))
          ..add(csvValue(tree.culturalHeritageDetails))
          ..add(csvValue(tree.amenityValue))
          ..add(csvValue(tree.shadeProvision));
      }

      if (isEnabled('regulatory')) {
        row
          ..add(csvValue(tree.stateSignificant))
          ..add(csvValue(tree.heritageListed))
          ..add(csvValue(tree.heritageReference))
          ..add(csvValue(tree.significantTreeRegister))
          ..add(csvValue(tree.bushfireManagementOverlay))
          ..add(csvValue(tree.environmentalSignificanceOverlay))
          ..add(csvValue(tree.waterwayProtection))
          ..add(csvValue(tree.threatenedSpeciesHabitat))
          ..add(csvValue(tree.insuranceNotificationRequired))
          ..add(csvValue(tree.legalLiabilityAssessment))
          ..add(csvValue(tree.complianceNotes));
      }

      if (isEnabled('monitoring')) {
        row
          ..add(csvValue(tree.nextInspectionDate))
          ..add(csvValue(tree.inspectionFrequency))
          ..add(csvValue(tree.monitoringRequired))
          ..add(csvValue(tree.monitoringFocus.join(';')))
          ..add(csvValue(tree.alertLevel))
          ..add(csvValue(tree.followUpActions))
          ..add(csvValue(tree.complianceCheckDate));
      }

      if (isEnabled('diagnostics', defaultValue: false)) {
        row
          ..add(csvValue(tree.resistographTest))
          ..add(csvValue(tree.resistographDate))
          ..add(csvValue(tree.resistographResults))
          ..add(csvValue(tree.sonicTomography))
          ..add(csvValue(tree.sonicTomographyDate))
          ..add(csvValue(tree.sonicTomographyResults))
          ..add(csvValue(tree.pullingTest))
          ..add(csvValue(tree.pullingTestDate))
          ..add(csvValue(tree.pullingTestResults))
          ..add(csvValue(tree.rootCollarExcavation))
          ..add(csvValue(tree.rootCollarFindings))
          ..add(csvValue(tree.soilTesting))
          ..add(csvValue(tree.soilTestingResults))
          ..add(csvValue(tree.pathologyReport))
          ..add(csvValue(tree.diagnosticImages.join(';')))
          ..add(csvValue(tree.specialistConsultant))
          ..add(csvValue(tree.diagnosticSummary));
      }

      if (isEnabled('inspector_details')) {
        row
          ..add(csvValue(tree.inspectorName))
          ..add(csvValue(tree.inspectionDate))
          ..add(csvValue(tree.syncStatus))
          ..add(csvValue(tree.notes));
      }

      rows.add(row);
    }

    final buffer = StringBuffer()
      ..writeln(headers.join(','));

    for (final row in rows) {
      buffer.writeln(row.join(','));
    }

    return buffer.toString();
  }
}
