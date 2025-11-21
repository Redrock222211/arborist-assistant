/// Report-specific field configurations for each report type
class ReportSpecificFields {
  static Map<String, List<FieldConfig>> getFieldsForReport(String reportCode) {
    switch (reportCode) {
      case 'PAA': // Preliminary Arboricultural Assessment
        return {
          'Basic Assessment': [
            FieldConfig('species_botanical', 'Botanical Name', FieldType.text, required: true),
            FieldConfig('species_common', 'Common Name', FieldType.text),
            FieldConfig('dsh', 'DSH (cm)', FieldType.number, required: true),
            FieldConfig('height', 'Height (m)', FieldType.number, required: true),
            FieldConfig('canopy_spread', 'Canopy Spread (m)', FieldType.number),
            FieldConfig('age_class', 'Age Class', FieldType.dropdown, 
              options: ['Young', 'Semi-mature', 'Mature', 'Over-mature']),
          ],
          'Health & Condition': [
            FieldConfig('health_rating', 'Health Rating', FieldType.dropdown,
              options: ['Excellent', 'Good', 'Fair', 'Poor', 'Dead'], required: true),
            FieldConfig('structure_rating', 'Structure Rating', FieldType.dropdown,
              options: ['Excellent', 'Good', 'Fair', 'Poor', 'Hazardous']),
            FieldConfig('vigor_rating', 'Vigor', FieldType.dropdown,
              options: ['High', 'Normal', 'Low', 'Declining']),
            FieldConfig('condition', 'Overall Condition', FieldType.dropdown,
              options: ['Excellent', 'Good', 'Fair', 'Poor', 'Critical'], required: true),
          ],
          'Site Context': [
            FieldConfig('site_context', 'Site Type', FieldType.text),
            FieldConfig('soil_description', 'Soil Description', FieldType.text),
            FieldConfig('drainage_description', 'Drainage', FieldType.dropdown,
              options: ['Well-drained', 'Moderate', 'Poor', 'Waterlogged']),
            FieldConfig('adjacent_land_use', 'Adjacent Land Use', FieldType.text),
          ],
          'Protection Zones': [
            FieldConfig('calculate_zones', 'Auto-calculate TPZ/SRZ', FieldType.checkbox, defaultValue: true),
            FieldConfig('tpz_override', 'TPZ Override (m)', FieldType.number),
            FieldConfig('srz_override', 'SRZ Override (m)', FieldType.number),
          ],
          'Recommendations': [
            FieldConfig('retention_value', 'Retention Value', FieldType.dropdown,
              options: ['High', 'Moderate', 'Low', 'Remove'], required: true),
            FieldConfig('recommendation', 'Recommendations', FieldType.textarea),
            FieldConfig('monitoring_frequency', 'Monitoring', FieldType.dropdown,
              options: ['Monthly', 'Quarterly', 'Bi-annual', 'Annual', 'As required']),
          ],
        };
        
      case 'AIA': // Arboricultural Impact Assessment
        return {
          ..._getBasicFields(),
          ..._getHealthFields(),
          'Development Impact': [
            FieldConfig('development_type', 'Development Type', FieldType.text, required: true),
            FieldConfig('construction_zone_distance', 'Distance to Construction (m)', FieldType.number),
            FieldConfig('root_zone_encroachment', 'TPZ Encroachment (%)', FieldType.number),
            FieldConfig('canopy_encroachment', 'Canopy Encroachment (%)', FieldType.number),
            FieldConfig('excavation_impact', 'Excavation Impact', FieldType.dropdown,
              options: ['None', 'Minor', 'Moderate', 'Major', 'Severe']),
          ],
          'Impact Mitigation': [
            FieldConfig('tree_protection_measures', 'Protection Measures', FieldType.textarea),
            FieldConfig('supervision_required', 'Arborist Supervision', FieldType.checkbox),
            FieldConfig('supervision_distance', 'Supervision Distance', FieldType.text),
            FieldConfig('mitigation_measures', 'Mitigation Measures', FieldType.textarea),
          ],
          'Compliance': [
            FieldConfig('as4970_compliant', 'AS4970 Compliant', FieldType.checkbox),
            FieldConfig('permit_required', 'Permit Required', FieldType.checkbox),
            FieldConfig('overlay_controls', 'Planning Overlays', FieldType.text),
          ],
        };
        
      case 'TRA': // Tree Risk Assessment
        return {
          ..._getBasicFields(),
          ..._getHealthFields(),
          'Target Assessment': [
            FieldConfig('target_type', 'Target Type', FieldType.dropdown,
              options: ['People', 'Property', 'Vehicle', 'Infrastructure'], required: true),
            FieldConfig('target_occupancy', 'Occupancy Rate', FieldType.dropdown,
              options: ['Constant', 'Frequent', 'Occasional', 'Rare']),
            FieldConfig('target_value', 'Target Value', FieldType.dropdown,
              options: ['Very High', 'High', 'Moderate', 'Low']),
          ],
          'Risk Matrix': [
            FieldConfig('likelihood_of_failure', 'Likelihood of Failure', FieldType.dropdown,
              options: ['Imminent', 'Probable', 'Possible', 'Improbable'], required: true),
            FieldConfig('likelihood_of_impact', 'Likelihood of Impact', FieldType.dropdown,
              options: ['Very High', 'High', 'Medium', 'Low', 'Very Low'], required: true),
            FieldConfig('consequence_of_failure', 'Consequence', FieldType.dropdown,
              options: ['Severe', 'Significant', 'Minor', 'Negligible'], required: true),
            FieldConfig('risk_rating', 'Overall Risk', FieldType.dropdown,
              options: ['Extreme', 'High', 'Moderate', 'Low'], required: true),
          ],
          'Defects Observed': [
            FieldConfig('cavity_present', 'Cavity Present', FieldType.checkbox),
            FieldConfig('cavity_size', 'Cavity Size/Location', FieldType.text),
            FieldConfig('decay_present', 'Decay Present', FieldType.checkbox),
            FieldConfig('decay_extent', 'Decay Extent', FieldType.text),
            FieldConfig('structural_defects', 'Structural Defects', FieldType.multiselect,
              options: ['Included bark', 'Co-dominant stems', 'Poor branch attachment', 
                       'Lean', 'Root damage', 'Cracks', 'Dead wood']),
          ],
          'Risk Mitigation': [
            FieldConfig('recommendation', 'Risk Mitigation', FieldType.textarea, required: true),
            FieldConfig('priority', 'Priority', FieldType.dropdown,
              options: ['Immediate', 'Urgent', 'Routine', 'Monitor']),
            FieldConfig('reinspection_period', 'Re-inspection', FieldType.dropdown,
              options: ['1 month', '3 months', '6 months', '12 months', '24 months']),
          ],
        };
        
      case 'TPMP': // Tree Protection Management Plan
        return {
          ..._getBasicFields(),
          'Protection Zones': [
            FieldConfig('tpz_radius', 'TPZ Radius (m)', FieldType.number, required: true),
            FieldConfig('srz_radius', 'SRZ Radius (m)', FieldType.number, required: true),
            FieldConfig('encroachment_present', 'Encroachment Present', FieldType.checkbox),
            FieldConfig('encroachment_percentage', 'Encroachment %', FieldType.number),
            FieldConfig('encroachment_type', 'Encroachment Type', FieldType.multiselect,
              options: ['Excavation', 'Fill', 'Structures', 'Services', 'Access']),
          ],
          'Protection Measures': [
            FieldConfig('fencing_type', 'Fencing Type', FieldType.dropdown,
              options: ['Chain mesh', 'Solid hoarding', 'Concrete barriers'], required: true),
            FieldConfig('ground_protection', 'Ground Protection', FieldType.dropdown,
              options: ['Mulch', 'Rumble boards', 'Steel plates', 'None']),
            FieldConfig('trunk_protection', 'Trunk Protection', FieldType.checkbox),
            FieldConfig('root_protection', 'Root Protection Measures', FieldType.textarea),
          ],
          'Monitoring': [
            FieldConfig('monitoring_frequency', 'Monitoring Frequency', FieldType.dropdown,
              options: ['Weekly', 'Fortnightly', 'Monthly', 'Quarterly'], required: true),
            FieldConfig('monitoring_focus', 'Monitoring Focus', FieldType.textarea),
            FieldConfig('hold_points', 'Hold Points', FieldType.textarea),
            FieldConfig('arborist_supervision', 'Arborist Supervision Required', FieldType.checkbox),
          ],
          'Compliance': [
            FieldConfig('as4970_compliant', 'AS4970 Compliant', FieldType.checkbox, required: true),
            FieldConfig('project_arborist', 'Project Arborist', FieldType.text),
            FieldConfig('site_manager_contact', 'Site Manager', FieldType.text),
            FieldConfig('emergency_contact', 'Emergency Contact', FieldType.text),
          ],
        };
        
      case 'TRP': // Tree Removal Permit
        return {
          ..._getBasicFields(),
          ..._getHealthFields(),
          'Removal Justification': [
            FieldConfig('removal_reason', 'Removal Reason', FieldType.dropdown,
              options: ['Dead/Dying', 'Hazardous', 'Disease', 'Development', 
                       'Infrastructure Damage', 'Inappropriate Species'], required: true),
            FieldConfig('removal_justification', 'Detailed Justification', FieldType.textarea, required: true),
            FieldConfig('alternatives_considered', 'Alternatives Considered', FieldType.textarea),
          ],
          'Replacement': [
            FieldConfig('replacement_required', 'Replacement Required', FieldType.checkbox),
            FieldConfig('replacement_ratio', 'Replacement Ratio', FieldType.text, defaultValue: '2:1'),
            FieldConfig('replacement_species', 'Replacement Species', FieldType.text),
            FieldConfig('replacement_location', 'Replacement Location', FieldType.text),
          ],
          'Compliance': [
            FieldConfig('permit_required', 'Council Permit Required', FieldType.checkbox, defaultValue: true),
            FieldConfig('heritage_listed', 'Heritage Listed', FieldType.checkbox),
            FieldConfig('significant_tree', 'Significant Tree', FieldType.checkbox),
            FieldConfig('neighbor_notification', 'Neighbor Notification', FieldType.checkbox),
          ],
        };
        
      case 'EWR': // Expert Witness Report
        return {
          ..._getBasicFields(),
          'Detailed Assessment': [
            ...(_getHealthFields()['Health & Condition'] ?? []),
            FieldConfig('assessment_limitations', 'Assessment Limitations', FieldType.textarea),
            FieldConfig('assessment_methodology', 'Methodology', FieldType.textarea, required: true),
          ],
          'Legal Context': [
            FieldConfig('case_reference', 'Case Reference', FieldType.text),
            FieldConfig('instructing_party', 'Instructing Party', FieldType.text),
            FieldConfig('opposing_party', 'Opposing Party', FieldType.text),
            FieldConfig('dispute_nature', 'Nature of Dispute', FieldType.textarea),
          ],
          'Expert Opinion': [
            FieldConfig('expert_opinion', 'Expert Opinion', FieldType.textarea, required: true),
            FieldConfig('supporting_evidence', 'Supporting Evidence', FieldType.textarea),
            FieldConfig('conclusion', 'Conclusion', FieldType.textarea, required: true),
            FieldConfig('declaration', 'Expert Declaration', FieldType.checkbox, required: true),
          ],
        };
        
      case 'THC': // Tree Health & Condition
        return {
          ..._getBasicFields(),
          'Health Assessment': [
            FieldConfig('vigor_rating', 'Vigor', FieldType.dropdown,
              options: ['High', 'Normal', 'Low', 'Declining'], required: true),
            FieldConfig('foliage_density', 'Foliage Density', FieldType.dropdown,
              options: ['Dense', 'Normal', 'Sparse', 'Very Sparse']),
            FieldConfig('foliage_color', 'Foliage Color', FieldType.dropdown,
              options: ['Normal', 'Pale', 'Chlorotic', 'Necrotic']),
            FieldConfig('dieback_percentage', 'Dieback %', FieldType.number),
          ],
          'Pests & Diseases': [
            FieldConfig('pest_presence', 'Pests Present', FieldType.text),
            FieldConfig('pest_severity', 'Pest Severity', FieldType.dropdown,
              options: ['None', 'Minor', 'Moderate', 'Severe']),
            FieldConfig('disease_present', 'Diseases Present', FieldType.text),
            FieldConfig('disease_severity', 'Disease Severity', FieldType.dropdown,
              options: ['None', 'Minor', 'Moderate', 'Severe']),
            FieldConfig('fungal_bodies', 'Fungal Fruiting Bodies', FieldType.checkbox),
            FieldConfig('fungal_species', 'Fungal Species', FieldType.text),
          ],
          'Environmental Stress': [
            FieldConfig('drought_stress', 'Drought Stress', FieldType.checkbox),
            FieldConfig('waterlogging', 'Waterlogging', FieldType.checkbox),
            FieldConfig('soil_compaction', 'Soil Compaction', FieldType.dropdown,
              options: ['None', 'Minor', 'Moderate', 'Severe']),
            FieldConfig('nutrient_deficiency', 'Nutrient Deficiency', FieldType.text),
          ],
          'Treatment': [
            FieldConfig('treatment_required', 'Treatment Required', FieldType.checkbox),
            FieldConfig('treatment_type', 'Treatment Type', FieldType.textarea),
            FieldConfig('treatment_urgency', 'Urgency', FieldType.dropdown,
              options: ['Immediate', 'Urgent', 'Routine', 'Monitor']),
          ],
        };
        
      case 'PDM': // Post-Development Monitoring
        return {
          ..._getBasicFields(),
          'Development Details': [
            FieldConfig('development_stage', 'Development Stage', FieldType.dropdown,
              options: ['Pre-construction', 'During construction', 'Post-construction'], required: true),
            FieldConfig('works_completed', 'Works Completed', FieldType.textarea),
            FieldConfig('compliance_status', 'Compliance Status', FieldType.dropdown,
              options: ['Compliant', 'Minor non-compliance', 'Major non-compliance']),
          ],
          'Tree Response': [
            FieldConfig('stress_indicators', 'Stress Indicators', FieldType.multiselect,
              options: ['Wilting', 'Leaf drop', 'Dieback', 'Epicormic growth', 'None']),
            FieldConfig('recovery_status', 'Recovery Status', FieldType.dropdown,
              options: ['Recovering well', 'Slow recovery', 'No recovery', 'Declining']),
            FieldConfig('growth_rate', 'Growth Rate', FieldType.dropdown,
              options: ['Normal', 'Reduced', 'Minimal', 'None']),
          ],
          'Protection Compliance': [
            FieldConfig('tpz_maintained', 'TPZ Maintained', FieldType.checkbox),
            FieldConfig('protection_breaches', 'Protection Breaches', FieldType.textarea),
            FieldConfig('remedial_action', 'Remedial Action Required', FieldType.textarea),
          ],
          'Ongoing Monitoring': [
            FieldConfig('next_inspection', 'Next Inspection', FieldType.date),
            FieldConfig('monitoring_period', 'Monitoring Period', FieldType.dropdown,
              options: ['3 months', '6 months', '12 months', '24 months']),
            FieldConfig('monitoring_focus', 'Monitoring Focus', FieldType.textarea),
          ],
        };
        
      case 'VEA': // Vegetation & Ecological Assessment
        return {
          ..._getBasicFields(),
          'Ecological Value': [
            FieldConfig('ecological_community', 'Ecological Community', FieldType.text),
            FieldConfig('conservation_status', 'Conservation Status', FieldType.dropdown,
              options: ['Not listed', 'Vulnerable', 'Endangered', 'Critically Endangered']),
            FieldConfig('habitat_value', 'Habitat Value', FieldType.dropdown,
              options: ['Very High', 'High', 'Moderate', 'Low', 'None'], required: true),
            FieldConfig('indigenous_species', 'Indigenous Species', FieldType.checkbox),
          ],
          'Wildlife Habitat': [
            FieldConfig('hollow_bearing', 'Hollow-bearing Tree', FieldType.checkbox),
            FieldConfig('hollow_size', 'Hollow Size/Type', FieldType.text),
            FieldConfig('nesting_sites', 'Nesting Sites Present', FieldType.checkbox),
            FieldConfig('fauna_observed', 'Fauna Observed', FieldType.textarea),
            FieldConfig('habitat_features', 'Habitat Features', FieldType.multiselect,
              options: ['Hollows', 'Nests', 'Dreys', 'Bark habitat', 'Flowering resource', 'Fruiting resource']),
          ],
          'Biodiversity': [
            FieldConfig('biodiversity_value', 'Biodiversity Value', FieldType.dropdown,
              options: ['Very High', 'High', 'Moderate', 'Low']),
            FieldConfig('connectivity_value', 'Connectivity Value', FieldType.dropdown,
              options: ['Key corridor', 'Contributing', 'Isolated']),
            FieldConfig('seed_source', 'Seed Source Value', FieldType.checkbox),
          ],
          'Management': [
            FieldConfig('retention_priority', 'Retention Priority', FieldType.dropdown,
              options: ['Essential', 'High', 'Moderate', 'Low'], required: true),
            FieldConfig('offset_required', 'Offset Required', FieldType.checkbox),
            FieldConfig('offset_ratio', 'Offset Ratio', FieldType.text),
            FieldConfig('management_recommendations', 'Management Recommendations', FieldType.textarea),
          ],
        };
        
      default:
        return _getBasicFields();
    }
  }
  
  static Map<String, List<FieldConfig>> _getBasicFields() {
    return {
      'Basic Assessment': [
        FieldConfig('species_botanical', 'Botanical Name', FieldType.text, required: true),
        FieldConfig('species_common', 'Common Name', FieldType.text),
        FieldConfig('dsh', 'DSH (cm)', FieldType.number, required: true),
        FieldConfig('height', 'Height (m)', FieldType.number, required: true),
        FieldConfig('canopy_spread', 'Canopy Spread (m)', FieldType.number),
        FieldConfig('age_class', 'Age Class', FieldType.dropdown,
          options: ['Young', 'Semi-mature', 'Mature', 'Over-mature']),
      ],
    };
  }
  
  static Map<String, List<FieldConfig>> _getHealthFields() {
    return {
      'Health & Condition': [
        FieldConfig('health_rating', 'Health Rating', FieldType.dropdown,
          options: ['Excellent', 'Good', 'Fair', 'Poor', 'Dead'], required: true),
        FieldConfig('structure_rating', 'Structure Rating', FieldType.dropdown,
          options: ['Excellent', 'Good', 'Fair', 'Poor', 'Hazardous']),
        FieldConfig('condition', 'Overall Condition', FieldType.dropdown,
          options: ['Excellent', 'Good', 'Fair', 'Poor', 'Critical'], required: true),
      ],
    };
  }
}

class FieldConfig {
  final String key;
  final String label;
  final FieldType type;
  final bool required;
  final List<String>? options;
  final dynamic defaultValue;
  
  FieldConfig(this.key, this.label, this.type, {
    this.required = false,
    this.options,
    this.defaultValue,
  });
}

enum FieldType {
  text,
  textarea,
  number,
  dropdown,
  multiselect,
  checkbox,
  date,
  image,
}
