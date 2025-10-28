import 'package:flutter/material.dart';
import '../models/site.dart';
import '../models/tree_entry.dart';
import '../models/site_file.dart';
import '../services/site_file_service.dart';
import '../services/notification_service.dart';
import 'package:intl/intl.dart';

class IsaReportPage extends StatefulWidget {
  final Site site;
  final TreeEntry? tree;

  const IsaReportPage({super.key, required this.site, this.tree});

  @override
  State<IsaReportPage> createState() => _IsaReportPageState();
}

class _IsaReportPageState extends State<IsaReportPage> {
  final _formKey = GlobalKey<FormState>();
  
  // Basic Information
  final _clientNameController = TextEditingController();
  final _projectNameController = TextEditingController();
  final _siteAddressController = TextEditingController();
  final _assessorNameController = TextEditingController();
  final _assessmentDateController = TextEditingController();
  
  // Tree Information
  final _treeIdController = TextEditingController();
  final _speciesController = TextEditingController();
  final _dshController = TextEditingController();
  final _heightController = TextEditingController();
  final _crownSpreadController = TextEditingController();
  final _ageEstimateController = TextEditingController();
  
  // Site Conditions
  String _siteType = 'Residential';
  String _soilType = 'Loam';
  String _drainage = 'Good';
  String _exposure = 'Full Sun';
  String _competition = 'Low';
  
  // Tree Health
  String _overallHealth = 'Good';
  final _healthNotesController = TextEditingController();
  final _diseasesController = TextEditingController();
  final _pestsController = TextEditingController();
  
  // Structural Assessment
  String _trunkCondition = 'Good';
  String _branchStructure = 'Good';
  String _rootCondition = 'Good';
  final _structuralNotesController = TextEditingController();
  
  // Risk Assessment
  String _likelihoodOfFailure = 'Low';
  String _likelihoodOfImpact = 'Low';
  String _consequenceOfFailure = 'Low';
  String _overallRisk = 'Low';
  final _riskNotesController = TextEditingController();
  
  // Recommendations
  final _recommendationsController = TextEditingController();
  final _priorityController = TextEditingController();
  final _timelineController = TextEditingController();
  final _costEstimateController = TextEditingController();
  
  // Photos
  final List<String> _photoPaths = [];
  
  @override
  void initState() {
    super.initState();
    _initializeForm();
  }
  
  void _initializeForm() {
    _siteAddressController.text = widget.site.address;
    _assessmentDateController.text = DateFormat('yyyy-MM-dd').format(DateTime.now());
    
    if (widget.tree != null) {
      _treeIdController.text = widget.tree!.id;
      _speciesController.text = widget.tree!.species;
      _dshController.text = widget.tree!.dsh.toString();
      _heightController.text = widget.tree!.height.toString();
      _overallHealth = widget.tree!.condition;
      _likelihoodOfFailure = widget.tree!.likelihoodOfFailure;
      _likelihoodOfImpact = widget.tree!.likelihoodOfImpact;
      _consequenceOfFailure = widget.tree!.consequenceOfFailure;
      _overallRisk = widget.tree!.overallRiskRating;
    }
  }
  
  @override
  void dispose() {
    _clientNameController.dispose();
    _projectNameController.dispose();
    _siteAddressController.dispose();
    _assessorNameController.dispose();
    _assessmentDateController.dispose();
    _treeIdController.dispose();
    _speciesController.dispose();
    _dshController.dispose();
    _heightController.dispose();
    _crownSpreadController.dispose();
    _ageEstimateController.dispose();
    _healthNotesController.dispose();
    _diseasesController.dispose();
    _pestsController.dispose();
    _structuralNotesController.dispose();
    _riskNotesController.dispose();
    _recommendationsController.dispose();
    _priorityController.dispose();
    _timelineController.dispose();
    _costEstimateController.dispose();
    super.dispose();
  }
  
  void _updateOverallRisk() {
    final failure = _likelihoodOfFailureOptions.indexOf(_likelihoodOfFailure);
    final impact = _likelihoodOfImpactOptions.indexOf(_likelihoodOfImpact);
    final consequence = _consequenceOfFailureOptions.indexOf(_consequenceOfFailure);
    final riskScore = failure + impact + consequence;
    
    setState(() {
      if (riskScore <= 2) {
        _overallRisk = 'Low';
      } else if (riskScore <= 4) {
        _overallRisk = 'Moderate';
      } else if (riskScore <= 6) {
        _overallRisk = 'High';
      } else {
        _overallRisk = 'Extreme';
      }
    });
  }
  
  final List<String> _siteTypeOptions = [
    'Residential', 'Commercial', 'Municipal', 'Park', 'Forest', 'Other'
  ];
  
  final List<String> _soilTypeOptions = [
    'Clay', 'Loam', 'Sandy', 'Rocky', 'Poor', 'Unknown'
  ];
  
  final List<String> _drainageOptions = [
    'Poor', 'Fair', 'Good', 'Excellent'
  ];
  
  final List<String> _exposureOptions = [
    'Full Shade', 'Partial Shade', 'Partial Sun', 'Full Sun'
  ];
  
  final List<String> _competitionOptions = [
    'Low', 'Moderate', 'High', 'Extreme'
  ];
  
  final List<String> _healthOptions = [
    'Excellent', 'Good', 'Fair', 'Poor', 'Critical'
  ];
  
  final List<String> _conditionOptions = [
    'Excellent', 'Good', 'Fair', 'Poor', 'Critical'
  ];
  
  final List<String> _likelihoodOfFailureOptions = [
    'Very Low', 'Low', 'Moderate', 'High', 'Very High'
  ];
  
  final List<String> _likelihoodOfImpactOptions = [
    'Very Low', 'Low', 'Moderate', 'High', 'Very High'
  ];
  
  final List<String> _consequenceOfFailureOptions = [
    'Very Low', 'Low', 'Moderate', 'High', 'Very High'
  ];
  
  final List<String> _priorityOptions = [
    'Immediate', 'High', 'Medium', 'Low', 'Monitor'
  ];
  
  Future<void> _saveReport() async {
    if (!_formKey.currentState!.validate()) return;
    
    try {
      final reportContent = _generateReportContent();
      final fileName = 'ISA_Report_${widget.site.name.replaceAll(' ', '_')}_${_treeIdController.text}_${DateTime.now().millisecondsSinceEpoch}.txt';
      
      final siteFile = SiteFile(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        siteId: widget.site.id,
        fileName: fileName,
        originalName: fileName,
        filePath: 'web://$fileName',
        fileType: 'Text File',
        fileSize: reportContent.length,
        uploadDate: DateTime.now(),
        uploadedBy: 'Current User',
        category: 'ISA Reports',
        description: 'ISA Tree Assessment Report',
      );
      await SiteFileService.addFile(siteFile);
      
      if (mounted) {
        NotificationService.showSuccess(context, 'ISA Report saved successfully!');
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        NotificationService.showError(context, 'Failed to save report: $e');
      }
    }
  }
  
  String _generateReportContent() {
    return '''
ISA TREE ASSESSMENT REPORT
==========================

BASIC INFORMATION
-----------------
Client Name: ${_clientNameController.text}
Project Name: ${_projectNameController.text}
Site Address: ${_siteAddressController.text}
Assessor Name: ${_assessorNameController.text}
Assessment Date: ${_assessmentDateController.text}

TREE INFORMATION
----------------
Tree ID: ${_treeIdController.text}
Species: ${_speciesController.text}
DBH (cm): ${_dshController.text}
Height (m): ${_heightController.text}
Crown Spread (m): ${_crownSpreadController.text}
Age Estimate: ${_ageEstimateController.text}

SITE CONDITIONS
---------------
Site Type: $_siteType
Soil Type: $_soilType
Drainage: $_drainage
Exposure: $_exposure
Competition: $_competition

TREE HEALTH
-----------
Overall Health: $_overallHealth
Health Notes: ${_healthNotesController.text}
Diseases Present: ${_diseasesController.text}
Pests Present: ${_pestsController.text}

STRUCTURAL ASSESSMENT
--------------------
Trunk Condition: $_trunkCondition
Branch Structure: $_branchStructure
Root Condition: $_rootCondition
Structural Notes: ${_structuralNotesController.text}

RISK ASSESSMENT
--------------
Likelihood of Failure: $_likelihoodOfFailure
Likelihood of Impact: $_likelihoodOfImpact
Consequence of Failure: $_consequenceOfFailure
Overall Risk Rating: $_overallRisk
Risk Notes: ${_riskNotesController.text}

RECOMMENDATIONS
--------------
Recommendations: ${_recommendationsController.text}
Priority: ${_priorityController.text.isEmpty ? 'Medium' : _priorityController.text}
Timeline: ${_timelineController.text}
Cost Estimate: ${_costEstimateController.text}

REPORT GENERATED: ${DateFormat('yyyy-MM-dd HH:mm').format(DateTime.now())}
''';
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('ISA Report - ${widget.tree?.id ?? 'New Tree'}'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _saveReport,
            tooltip: 'Save Report',
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionHeader('Basic Information'),
              _buildTextField(_clientNameController, 'Client Name', required: true),
              _buildTextField(_projectNameController, 'Project Name', required: true),
              _buildTextField(_siteAddressController, 'Site Address', required: true),
              _buildTextField(_assessorNameController, 'Assessor Name', required: true),
              _buildTextField(_assessmentDateController, 'Assessment Date', required: true),
              
              const SizedBox(height: 24),
              _buildSectionHeader('Tree Information'),
              _buildTextField(_treeIdController, 'Tree ID', required: true),
              _buildTextField(_speciesController, 'Species', required: true),
              _buildTextField(_dshController, 'DBH (cm)', required: true, keyboardType: TextInputType.number),
              _buildTextField(_heightController, 'Height (m)', required: true, keyboardType: TextInputType.number),
              _buildTextField(_crownSpreadController, 'Crown Spread (m)', keyboardType: TextInputType.number),
              _buildTextField(_ageEstimateController, 'Age Estimate'),
              
              const SizedBox(height: 24),
              _buildSectionHeader('Site Conditions'),
              _buildDropdown('Site Type', _siteType, _siteTypeOptions, (value) => setState(() => _siteType = value!)),
              _buildDropdown('Soil Type', _soilType, _soilTypeOptions, (value) => setState(() => _soilType = value!)),
              _buildDropdown('Drainage', _drainage, _drainageOptions, (value) => setState(() => _drainage = value!)),
              _buildDropdown('Exposure', _exposure, _exposureOptions, (value) => setState(() => _exposure = value!)),
              _buildDropdown('Competition', _competition, _competitionOptions, (value) => setState(() => _competition = value!)),
              
              const SizedBox(height: 24),
              _buildSectionHeader('Tree Health'),
              _buildDropdown('Overall Health', _overallHealth, _healthOptions, (value) => setState(() => _overallHealth = value!)),
              _buildTextField(_healthNotesController, 'Health Notes', maxLines: 3),
              _buildTextField(_diseasesController, 'Diseases Present', maxLines: 2),
              _buildTextField(_pestsController, 'Pests Present', maxLines: 2),
              
              const SizedBox(height: 24),
              _buildSectionHeader('Structural Assessment'),
              _buildDropdown('Trunk Condition', _trunkCondition, _conditionOptions, (value) => setState(() => _trunkCondition = value!)),
              _buildDropdown('Branch Structure', _branchStructure, _conditionOptions, (value) => setState(() => _branchStructure = value!)),
              _buildDropdown('Root Condition', _rootCondition, _conditionOptions, (value) => setState(() => _rootCondition = value!)),
              _buildTextField(_structuralNotesController, 'Structural Notes', maxLines: 3),
              
              const SizedBox(height: 24),
              _buildSectionHeader('Risk Assessment'),
              _buildDropdown('Likelihood of Failure', _likelihoodOfFailure, _likelihoodOfFailureOptions, (value) {
                setState(() => _likelihoodOfFailure = value!);
                _updateOverallRisk();
              }),
              _buildDropdown('Likelihood of Impact', _likelihoodOfImpact, _likelihoodOfImpactOptions, (value) {
                setState(() => _likelihoodOfImpact = value!);
                _updateOverallRisk();
              }),
              _buildDropdown('Consequence of Failure', _consequenceOfFailure, _consequenceOfFailureOptions, (value) {
                setState(() => _consequenceOfFailure = value!);
                _updateOverallRisk();
              }),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _getRiskColor(_overallRisk).withOpacity(0.1),
                  border: Border.all(color: _getRiskColor(_overallRisk)),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.warning, color: _getRiskColor(_overallRisk)),
                    const SizedBox(width: 8),
                    Text(
                      'Overall Risk: $_overallRisk',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: _getRiskColor(_overallRisk),
                      ),
                    ),
                  ],
                ),
              ),
              _buildTextField(_riskNotesController, 'Risk Notes', maxLines: 3),
              
              const SizedBox(height: 24),
              _buildSectionHeader('Recommendations'),
              _buildTextField(_recommendationsController, 'Recommendations', maxLines: 4, required: true),
              _buildDropdown('Priority', _priorityController.text.isEmpty ? 'Medium' : _priorityController.text, _priorityOptions, (value) {
                setState(() => _priorityController.text = value!);
              }),
              _buildTextField(_timelineController, 'Timeline'),
              _buildTextField(_costEstimateController, 'Cost Estimate'),
              
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _saveReport,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: const Text('Save ISA Report', style: TextStyle(fontSize: 16)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.bold,
          color: Colors.green[700],
        ),
      ),
    );
  }
  
  Widget _buildTextField(
    TextEditingController controller,
    String label, {
    bool required = false,
    int maxLines = 1,
    TextInputType? keyboardType,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          filled: true,
          fillColor: Colors.grey[50],
        ),
        maxLines: maxLines,
        keyboardType: keyboardType,
        validator: required ? (value) {
          if (value == null || value.isEmpty) {
            return '$label is required';
          }
          return null;
        } : null,
      ),
    );
  }
  
  Widget _buildDropdown(
    String label,
    String value,
    List<String> options,
    void Function(String?) onChanged,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: DropdownButtonFormField<String>(
        value: value,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          filled: true,
          fillColor: Colors.grey[50],
        ),
        items: options.map((option) {
          return DropdownMenuItem(
            value: option,
            child: Text(option),
          );
        }).toList(),
        onChanged: onChanged,
      ),
    );
  }
  
  Color _getRiskColor(String risk) {
    switch (risk.toLowerCase()) {
      case 'low':
        return Colors.green;
      case 'moderate':
        return Colors.orange;
      case 'high':
        return Colors.red;
      case 'extreme':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }
}
