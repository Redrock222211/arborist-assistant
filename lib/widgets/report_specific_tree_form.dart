import 'package:flutter/material.dart';
import '../models/tree_entry.dart';
import '../models/report_type.dart';
import '../services/tree_storage_service.dart';
import '../services/notification_service.dart';
import 'tree_form_groups.dart';

/// Report-specific tree form that shows different fields based on report type
class ReportSpecificTreeForm extends StatefulWidget {
  final String siteId;
  final ReportType reportType;
  final TreeEntry? initialEntry;
  final Function(TreeEntry) onSubmit;

  const ReportSpecificTreeForm({
    Key? key,
    required this.siteId,
    required this.reportType,
    this.initialEntry,
    required this.onSubmit,
  }) : super(key: key);

  @override
  State<ReportSpecificTreeForm> createState() => _ReportSpecificTreeFormState();
}

class _ReportSpecificTreeFormState extends State<ReportSpecificTreeForm> {
  final _formKey = GlobalKey<FormState>();
  late Map<String, TextEditingController> _controllers;
  late Map<String, dynamic> _formData;
  
  @override
  void initState() {
    super.initState();
    _controllers = {};
    _formData = {};
    _initializeForm();
  }
  
  void _initializeForm() {
    // Initialize with existing data or defaults
    if (widget.initialEntry != null) {
      _loadExistingData(widget.initialEntry!);
    } else {
      _setDefaults();
    }
  }
  
  void _loadExistingData(TreeEntry entry) {
    _formData = {
      'tree_id': entry.id,
      'species_botanical': entry.species,
      'species_common': entry.species, // TODO: Add common name lookup
      'dsh': entry.dsh,
      'height': entry.height,
      'canopy_spread': entry.canopySpread,
      'age_class': entry.ageClass,
      'health_rating': entry.vigorRating,
      'structure_rating': entry.structuralRating,
      'condition': entry.condition,
      'retention_value': entry.retentionValue,
      'risk_rating': entry.riskRating,
      'likelihood_of_failure': entry.likelihoodOfFailure,
      'likelihood_of_impact': entry.likelihoodOfImpact,
      'consequence_of_failure': entry.consequenceOfFailure,
      'recommendation': entry.recommendedWorks,
      'monitoring_frequency': entry.inspectionFrequency,
      'site_context': entry.siteType,
      'soil_description': entry.soilType,
      'drainage_description': entry.drainage,
      'adjacent_land_use': entry.landUseZone,
      'overlay_controls': entry.planningOverlay,
      'permit_required': entry.permitRequired,
      'latitude': entry.latitude,
      'longitude': entry.longitude,
    };
  }
  
  void _setDefaults() {
    _formData = {
      'tree_id': 'T${DateTime.now().millisecondsSinceEpoch % 10000}',
      'age_class': 'Mature',
      'condition': 'Good',
      'health_rating': 'Good',
      'structure_rating': 'Good',
      'retention_value': 'Moderate',
      'risk_rating': 'Low',
      'likelihood_of_failure': 'Improbable',
      'likelihood_of_impact': 'Very Low',
      'consequence_of_failure': 'Negligible',
      'monitoring_frequency': 'Annual',
      'drainage_description': 'Well-drained',
      'permit_required': false,
      'calculate_zones': true,
    };
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.reportType.title} - Tree Assessment'),
        backgroundColor: Colors.green,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: EdgeInsets.all(16),
          children: [
            // Report type indicator
            Container(
              padding: EdgeInsets.all(12),
              margin: EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.description, color: Colors.blue),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Report Type: ${widget.reportType.code}',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.blue.shade900,
                          ),
                        ),
                        Text(
                          widget.reportType.description,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.blue.shade700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            
            // Dynamic form sections based on report type
            ..._buildFormSections(),
            
            // Submit button
            SizedBox(height: 24),
            ElevatedButton(
              onPressed: _submitForm,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                padding: EdgeInsets.symmetric(vertical: 16),
              ),
              child: Text(
                'Save Tree Assessment',
                style: TextStyle(fontSize: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  List<Widget> _buildFormSections() {
    switch (widget.reportType.code) {
      case 'PAA': // Preliminary Arboricultural Assessment
        return _buildPAAForm();
      case 'AIA': // Arboricultural Impact Assessment
        return _buildAIAForm();
      case 'TRA': // Tree Risk Assessment
        return _buildTRAForm();
      case 'TPMP': // Tree Protection Management Plan
        return _buildTPMPForm();
      case 'TRP': // Tree Removal Permit
        return _buildTRPForm();
      case 'EWR': // Expert Witness Report
        return _buildEWRForm();
      case 'THC': // Tree Health & Condition
        return _buildTHCForm();
      case 'PDM': // Post-Development Monitoring
        return _buildPDMForm();
      case 'VEA': // Vegetation & Ecological Assessment
        return _buildVEAForm();
      default:
        return _buildPAAForm(); // Default to PAA
    }
  }
  
  // PAA - Preliminary Arboricultural Assessment Form
  List<Widget> _buildPAAForm() {
    return [
      _buildSection('Basic Tree Information', [
        _buildTextField('tree_id', 'Tree ID', required: true),
        _buildTextField('species_botanical', 'Botanical Name', required: true),
        _buildTextField('species_common', 'Common Name'),
        _buildNumberField('dsh', 'DSH (cm)', required: true),
        _buildNumberField('height', 'Height (m)', required: true),
        _buildNumberField('canopy_spread', 'Canopy Spread (m)'),
        _buildDropdown('age_class', 'Age Class', 
          ['Young', 'Semi-mature', 'Mature', 'Over-mature']),
      ]),
      
      _buildSection('Health & Condition', [
        _buildDropdown('health_rating', 'Health Rating',
          ['Excellent', 'Good', 'Fair', 'Poor', 'Dead'], required: true),
        _buildDropdown('structure_rating', 'Structure Rating',
          ['Excellent', 'Good', 'Fair', 'Poor', 'Hazardous']),
        _buildDropdown('condition', 'Overall Condition',
          ['Excellent', 'Good', 'Fair', 'Poor', 'Critical'], required: true),
        _buildTextArea('health_summary', 'Health Summary'),
        _buildTextArea('structural_summary', 'Structural Summary'),
      ]),
      
      _buildSection('Site Context', [
        _buildTextField('site_context', 'Site Type'),
        _buildTextField('soil_description', 'Soil Description'),
        _buildDropdown('drainage_description', 'Drainage',
          ['Well-drained', 'Moderate', 'Poor', 'Waterlogged']),
        _buildTextField('adjacent_land_use', 'Adjacent Land Use'),
        _buildTextField('overlay_controls', 'Planning Overlays'),
      ]),
      
      _buildSection('Protection Zones', [
        _buildCheckbox('calculate_zones', 'Auto-calculate TPZ/SRZ'),
        _buildNumberField('tpz_m', 'TPZ (m)'),
        _buildNumberField('srz_m', 'SRZ (m)'),
        _buildNumberField('nrz_m', 'NRZ (m)'),
      ]),
      
      _buildSection('Recommendations', [
        _buildDropdown('retention_value', 'Retention Value',
          ['High', 'Moderate', 'Low', 'Remove'], required: true),
        _buildTextArea('recommendation', 'Recommendations'),
        _buildDropdown('monitoring_frequency', 'Monitoring',
          ['Monthly', 'Quarterly', 'Bi-annual', 'Annual', 'As required']),
        _buildTextArea('observations', 'Observations'),
      ]),
    ];
  }
  
  // AIA - Arboricultural Impact Assessment Form
  List<Widget> _buildAIAForm() {
    return [
      _buildSection('Basic Tree Information', [
        _buildTextField('tree_id', 'Tree ID', required: true),
        _buildTextField('species_botanical', 'Botanical Name', required: true),
        _buildTextField('species_common', 'Common Name'),
        _buildNumberField('dsh', 'DSH (cm)', required: true),
        _buildNumberField('height', 'Height (m)', required: true),
        _buildNumberField('canopy_spread', 'Canopy Spread (m)'),
      ]),
      
      _buildSection('Development Impact', [
        _buildTextField('development_type', 'Development Type', required: true),
        _buildNumberField('construction_zone_distance', 'Distance to Construction (m)'),
        _buildNumberField('root_zone_encroachment', 'TPZ Encroachment (%)'),
        _buildNumberField('canopy_encroachment', 'Canopy Encroachment (%)'),
        _buildDropdown('excavation_impact', 'Excavation Impact',
          ['None', 'Minor', 'Moderate', 'Major', 'Severe']),
      ]),
      
      _buildSection('Impact Mitigation', [
        _buildTextArea('tree_protection_measures', 'Protection Measures'),
        _buildCheckbox('supervision_required', 'Arborist Supervision Required'),
        _buildTextField('supervision_distance', 'Supervision Distance'),
        _buildTextArea('mitigation_measures', 'Mitigation Measures'),
      ]),
      
      _buildSection('Compliance', [
        _buildCheckbox('as4970_compliant', 'AS4970 Compliant'),
        _buildCheckbox('permit_required', 'Permit Required'),
        _buildTextField('overlay_controls', 'Planning Overlays'),
      ]),
    ];
  }
  
  // TRA - Tree Risk Assessment Form
  List<Widget> _buildTRAForm() {
    return [
      _buildSection('Basic Tree Information', [
        _buildTextField('tree_id', 'Tree ID', required: true),
        _buildTextField('species_botanical', 'Botanical Name', required: true),
        _buildNumberField('dsh', 'DSH (cm)', required: true),
        _buildNumberField('height', 'Height (m)', required: true),
      ]),
      
      _buildSection('Target Assessment', [
        _buildDropdown('target_type', 'Target Type',
          ['People', 'Property', 'Vehicle', 'Infrastructure'], required: true),
        _buildDropdown('target_occupancy', 'Occupancy Rate',
          ['Constant', 'Frequent', 'Occasional', 'Rare']),
        _buildDropdown('target_value', 'Target Value',
          ['Very High', 'High', 'Moderate', 'Low']),
      ]),
      
      _buildSection('Risk Matrix', [
        _buildDropdown('likelihood_of_failure', 'Likelihood of Failure',
          ['Imminent', 'Probable', 'Possible', 'Improbable'], required: true),
        _buildDropdown('likelihood_of_impact', 'Likelihood of Impact',
          ['Very High', 'High', 'Medium', 'Low', 'Very Low'], required: true),
        _buildDropdown('consequence_of_failure', 'Consequence',
          ['Severe', 'Significant', 'Minor', 'Negligible'], required: true),
        _buildDropdown('risk_rating', 'Overall Risk',
          ['Extreme', 'High', 'Moderate', 'Low'], required: true),
      ]),
      
      _buildSection('Defects Observed', [
        _buildCheckbox('cavity_present', 'Cavity Present'),
        _buildTextField('cavity_size', 'Cavity Size/Location'),
        _buildCheckbox('decay_present', 'Decay Present'),
        _buildTextField('decay_extent', 'Decay Extent'),
        _buildMultiSelect('structural_defects', 'Structural Defects', [
          'Included bark',
          'Co-dominant stems',
          'Poor branch attachment',
          'Lean',
          'Root damage',
          'Cracks',
          'Dead wood',
        ]),
      ]),
      
      _buildSection('Risk Mitigation', [
        _buildTextArea('recommendation', 'Risk Mitigation', required: true),
        _buildDropdown('priority', 'Priority',
          ['Immediate', 'Urgent', 'Routine', 'Monitor']),
        _buildDropdown('reinspection_period', 'Re-inspection',
          ['1 month', '3 months', '6 months', '12 months', '24 months']),
      ]),
    ];
  }
  
  // TPMP - Tree Protection Management Plan Form
  List<Widget> _buildTPMPForm() {
    return [
      _buildSection('Basic Tree Information', [
        _buildTextField('tree_id', 'Tree ID', required: true),
        _buildTextField('species_botanical', 'Botanical Name', required: true),
        _buildNumberField('dsh', 'DSH (cm)', required: true),
        _buildNumberField('height', 'Height (m)', required: true),
      ]),
      
      _buildSection('Protection Zones', [
        _buildNumberField('tpz_radius', 'TPZ Radius (m)', required: true),
        _buildNumberField('srz_radius', 'SRZ Radius (m)', required: true),
        _buildCheckbox('encroachment_present', 'Encroachment Present'),
        _buildNumberField('encroachment_percentage', 'Encroachment %'),
        _buildMultiSelect('encroachment_type', 'Encroachment Type', [
          'Excavation',
          'Fill',
          'Structures',
          'Services',
          'Access',
        ]),
      ]),
      
      _buildSection('Protection Measures', [
        _buildDropdown('fencing_type', 'Fencing Type',
          ['Chain mesh', 'Solid hoarding', 'Concrete barriers'], required: true),
        _buildDropdown('ground_protection', 'Ground Protection',
          ['Mulch', 'Rumble boards', 'Steel plates', 'None']),
        _buildCheckbox('trunk_protection', 'Trunk Protection'),
        _buildTextArea('root_protection', 'Root Protection Measures'),
      ]),
      
      _buildSection('Monitoring', [
        _buildDropdown('monitoring_frequency', 'Monitoring Frequency',
          ['Weekly', 'Fortnightly', 'Monthly', 'Quarterly'], required: true),
        _buildTextArea('monitoring_focus', 'Monitoring Focus'),
        _buildTextArea('hold_points', 'Hold Points'),
        _buildCheckbox('arborist_supervision', 'Arborist Supervision Required'),
      ]),
      
      _buildSection('Compliance', [
        _buildCheckbox('as4970_compliant', 'AS4970 Compliant', required: true),
        _buildTextField('project_arborist', 'Project Arborist'),
        _buildTextField('site_manager_contact', 'Site Manager'),
        _buildTextField('emergency_contact', 'Emergency Contact'),
      ]),
    ];
  }
  
  // TRP - Tree Removal Permit Form
  List<Widget> _buildTRPForm() {
    return [
      _buildSection('Basic Tree Information', [
        _buildTextField('tree_id', 'Tree ID', required: true),
        _buildTextField('species_botanical', 'Botanical Name', required: true),
        _buildNumberField('dsh', 'DSH (cm)', required: true),
        _buildNumberField('height', 'Height (m)', required: true),
      ]),
      
      _buildSection('Health & Condition', [
        _buildDropdown('health_rating', 'Health Rating',
          ['Excellent', 'Good', 'Fair', 'Poor', 'Dead'], required: true),
        _buildDropdown('structure_rating', 'Structure Rating',
          ['Excellent', 'Good', 'Fair', 'Poor', 'Hazardous']),
        _buildDropdown('condition', 'Overall Condition',
          ['Excellent', 'Good', 'Fair', 'Poor', 'Critical'], required: true),
      ]),
      
      _buildSection('Removal Justification', [
        _buildDropdown('removal_reason', 'Removal Reason', [
          'Dead/Dying',
          'Hazardous',
          'Disease',
          'Development',
          'Infrastructure Damage',
          'Inappropriate Species',
        ], required: true),
        _buildTextArea('removal_justification', 'Detailed Justification', required: true),
        _buildTextArea('alternatives_considered', 'Alternatives Considered'),
      ]),
      
      _buildSection('Replacement', [
        _buildCheckbox('replacement_required', 'Replacement Required'),
        _buildTextField('replacement_ratio', 'Replacement Ratio', initialValue: '2:1'),
        _buildTextField('replacement_species', 'Replacement Species'),
        _buildTextField('replacement_location', 'Replacement Location'),
      ]),
      
      _buildSection('Compliance', [
        _buildCheckbox('permit_required', 'Council Permit Required', initialValue: true),
        _buildCheckbox('heritage_listed', 'Heritage Listed'),
        _buildCheckbox('significant_tree', 'Significant Tree'),
        _buildCheckbox('neighbor_notification', 'Neighbor Notification'),
      ]),
    ];
  }
  
  // Additional form builders for EWR, THC, PDM, VEA...
  List<Widget> _buildEWRForm() => _buildPAAForm(); // Simplified for now
  List<Widget> _buildTHCForm() => _buildPAAForm(); // Simplified for now
  List<Widget> _buildPDMForm() => _buildPAAForm(); // Simplified for now
  List<Widget> _buildVEAForm() => _buildPAAForm(); // Simplified for now
  
  // Form field builders
  Widget _buildSection(String title, List<Widget> children) {
    return Card(
      margin: EdgeInsets.only(bottom: 16),
      child: ExpansionTile(
        title: Text(
          title,
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        initiallyExpanded: true,
        children: [
          Padding(
            padding: EdgeInsets.all(16),
            child: Column(children: children),
          ),
        ],
      ),
    );
  }
  
  Widget _buildTextField(String key, String label, {bool required = false, String? initialValue}) {
    _controllers[key] ??= TextEditingController(text: _formData[key]?.toString() ?? initialValue ?? '');
    
    return Padding(
      padding: EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: _controllers[key],
        decoration: InputDecoration(
          labelText: label + (required ? ' *' : ''),
          border: OutlineInputBorder(),
        ),
        validator: required ? (value) {
          if (value == null || value.isEmpty) {
            return '$label is required';
          }
          return null;
        } : null,
        onChanged: (value) => _formData[key] = value,
      ),
    );
  }
  
  Widget _buildNumberField(String key, String label, {bool required = false}) {
    _controllers[key] ??= TextEditingController(text: _formData[key]?.toString() ?? '');
    
    return Padding(
      padding: EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: _controllers[key],
        decoration: InputDecoration(
          labelText: label + (required ? ' *' : ''),
          border: OutlineInputBorder(),
        ),
        keyboardType: TextInputType.number,
        validator: required ? (value) {
          if (value == null || value.isEmpty) {
            return '$label is required';
          }
          return null;
        } : null,
        onChanged: (value) => _formData[key] = double.tryParse(value) ?? 0,
      ),
    );
  }
  
  Widget _buildTextArea(String key, String label, {bool required = false}) {
    _controllers[key] ??= TextEditingController(text: _formData[key]?.toString() ?? '');
    
    return Padding(
      padding: EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: _controllers[key],
        decoration: InputDecoration(
          labelText: label + (required ? ' *' : ''),
          border: OutlineInputBorder(),
          alignLabelWithHint: true,
        ),
        maxLines: 3,
        validator: required ? (value) {
          if (value == null || value.isEmpty) {
            return '$label is required';
          }
          return null;
        } : null,
        onChanged: (value) => _formData[key] = value,
      ),
    );
  }
  
  Widget _buildDropdown(String key, String label, List<String> options, {bool required = false}) {
    _formData[key] ??= options.first;
    
    return Padding(
      padding: EdgeInsets.only(bottom: 16),
      child: DropdownButtonFormField<String>(
        value: _formData[key],
        decoration: InputDecoration(
          labelText: label + (required ? ' *' : ''),
          border: OutlineInputBorder(),
        ),
        items: options.map((option) => DropdownMenuItem(
          value: option,
          child: Text(option),
        )).toList(),
        onChanged: (value) => setState(() => _formData[key] = value),
        validator: required ? (value) {
          if (value == null || value.isEmpty) {
            return '$label is required';
          }
          return null;
        } : null,
      ),
    );
  }
  
  Widget _buildCheckbox(String key, String label, {bool initialValue = false, bool required = false}) {
    _formData[key] ??= initialValue;
    
    return Padding(
      padding: EdgeInsets.only(bottom: 16),
      child: CheckboxListTile(
        title: Text(label + (required ? ' *' : '')),
        value: _formData[key] ?? false,
        onChanged: (value) => setState(() => _formData[key] = value),
        controlAffinity: ListTileControlAffinity.leading,
      ),
    );
  }
  
  Widget _buildMultiSelect(String key, String label, List<String> options) {
    _formData[key] ??= <String>[];
    
    return Padding(
      padding: EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
          SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: options.map((option) {
              final isSelected = (_formData[key] as List).contains(option);
              return FilterChip(
                label: Text(option),
                selected: isSelected,
                onSelected: (selected) {
                  setState(() {
                    if (selected) {
                      (_formData[key] as List).add(option);
                    } else {
                      (_formData[key] as List).remove(option);
                    }
                  });
                },
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
  
  void _submitForm() async {
    if (_formKey.currentState!.validate()) {
      // Calculate protection zones if needed
      if (_formData['calculate_zones'] == true) {
        final dsh = _formData['dsh'] ?? 0.0;
        _formData['tpz_m'] = (dsh * 0.12).toStringAsFixed(1);
        _formData['srz_m'] = (dsh * 0.06).toStringAsFixed(1);
        _formData['nrz_m'] = _formData['tpz_m'];
      }
      
      // Create TreeEntry from form data
      final treeEntry = TreeEntry(
        id: _formData['tree_id'] ?? 'T${DateTime.now().millisecondsSinceEpoch}',
        siteId: widget.siteId,
        species: _formData['species_botanical'] ?? '',
        dsh: (_formData['dsh'] ?? 0.0).toDouble(),
        height: (_formData['height'] ?? 0.0).toDouble(),
        canopySpread: (_formData['canopy_spread'] ?? 0.0).toDouble(),
        condition: _formData['condition'] ?? 'Good',
        healthForm: _formData['health_rating'] ?? 'Good',
        structuralRating: _formData['structure_rating'] ?? 'Good',
        vigorRating: _formData['health_rating'] ?? 'Good',
        ageClass: _formData['age_class'] ?? 'Mature',
        retentionValue: _formData['retention_value'] ?? 'Moderate',
        riskRating: _formData['risk_rating'] ?? 'Low',
        likelihoodOfFailure: _formData['likelihood_of_failure'] ?? 'Improbable',
        likelihoodOfImpact: _formData['likelihood_of_impact'] ?? 'Very Low',
        consequenceOfFailure: _formData['consequence_of_failure'] ?? 'Negligible',
        recommendedWorks: _formData['recommendation'] ?? '',
        inspectionFrequency: _formData['monitoring_frequency'] ?? 'Annual',
        siteType: _formData['site_context'] ?? '',
        soilType: _formData['soil_description'] ?? '',
        drainage: _formData['drainage_description'] ?? 'Well-drained',
        landUseZone: _formData['adjacent_land_use'] ?? '',
        planningOverlay: _formData['overlay_controls'] ?? '',
        permitRequired: _formData['permit_required'] ?? false,
        srz: double.tryParse(_formData['srz_m']?.toString() ?? '') ?? 0.0,
        nrz: double.tryParse(_formData['nrz_m']?.toString() ?? '') ?? 0.0,
        latitude: _formData['latitude'] ?? 0.0,
        longitude: _formData['longitude'] ?? 0.0,
        comments: _formData['observations'] ?? '',
        notes: _formData['notes'] ?? '',
        // Add report-specific fields
        developmentType: _formData['development_type'] ?? '',
        constructionZoneDistance: (_formData['construction_zone_distance'] ?? 0.0).toDouble(),
        rootZoneEncroachmentPercent: (_formData['root_zone_encroachment'] ?? 0.0).toDouble(),
        canopyEncroachmentPercent: (_formData['canopy_encroachment'] ?? 0.0).toDouble(),
        excavationImpact: _formData['excavation_impact'] ?? '',
        mitigationMeasures: _formData['mitigation_measures'] ?? '',
        arboristSupervisionRequired: _formData['supervision_required'] ?? false,
        as4970Compliant: _formData['as4970_compliant'] ?? false,
        targetOccupancy: _formData['target_occupancy'] ?? '',
        structuralDefects: List<String>.from(_formData['structural_defects'] ?? []),
        cavityPresent: _formData['cavity_present'] ?? false,
        cavitySize: _formData['cavity_size'] ?? '',
        decayExtent: _formData['decay_extent'] ?? '',
        treeProtectionMeasures: _formData['tree_protection_measures'] ?? '',
        removalJustification: _formData['removal_justification'] ?? '',
        replacementRatio: double.tryParse(_formData['replacement_ratio']?.toString().replaceAll(':', '') ?? '2') ?? 2.0,
        replantingRequired: _formData['replacement_required'] ?? false,
        heritageListed: _formData['heritage_listed'] ?? false,
        significantTreeRegister: _formData['significant_tree'] ?? false,
        neighborNotification: _formData['neighbor_notification'] ?? false,
      );
      
      // Save the tree
      await TreeStorageService.addTree(treeEntry);
      
      // Show success notification
      NotificationService.showSuccess(
        context,
        'Tree saved successfully for ${widget.reportType.title}',
      );
      
      // Call the onSubmit callback
      widget.onSubmit(treeEntry);
      
      // Navigate back
      Navigator.of(context).pop();
    }
  }
  
  @override
  void dispose() {
    _controllers.values.forEach((controller) => controller.dispose());
    super.dispose();
  }
}
