import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:async';
import 'dart:convert';
import '../models/tree_entry.dart';
import '../services/app_state_service.dart';
import '../services/notification_service.dart';
import '../services/tree_storage_service.dart';
import '../services/site_file_service.dart';
import '../widgets/collapsible_form_section.dart';
import '../data/victorian_tree_species.dart';
import 'package:geolocator/geolocator.dart';
import 'package:just_audio/just_audio.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'collapsible_form_section.dart';
import 'tree_form_groups.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:record/record.dart';
import 'package:image_picker/image_picker.dart';

class ResponsiveHelper {
  static double getScaleFactor(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width < 600) return 0.8; // Small phones
    if (width < 800) return 0.9; // Large phones
    if (width < 1200) return 1.0; // Tablets
    return 1.2; // Desktop
  }
  
  static double getScaledValue(BuildContext context, double value) {
    return value * getScaleFactor(context);
  }
  
  static EdgeInsets getScaledPadding(BuildContext context, EdgeInsets padding) {
    final scale = getScaleFactor(context);
    return EdgeInsets.only(
      left: padding.left * scale,
      right: padding.right * scale,
      top: padding.top * scale,
      bottom: padding.bottom * scale,
    );
  }
  
  static double getScaledFontSize(BuildContext context, double fontSize) {
    return fontSize * getScaleFactor(context);
  }
}

class TreeForm extends StatefulWidget {
  final String siteId;
  final TreeEntry? initialEntry;
  final Function(TreeEntry) onSubmit;
  final String? reportType;

  const TreeForm({
    super.key,
    required this.siteId,
    this.initialEntry,
    required this.onSubmit,
    this.reportType,
  });

  @override
  State<TreeForm> createState() => _TreeFormState();
}

class _TreeFormState extends State<TreeForm> {
  final _formKey = GlobalKey<FormState>();
  final _audioPlayer = AudioPlayer();
  final _audioRecorder = AudioRecorder();
  final _speechToText = stt.SpeechToText();
  
  // Voice recording state
  bool _isRecording = false;
  bool _hasRecording = false;
  bool _isTranscribing = false;
  String _transcriptionText = '';
  String? _recordingPath;
  bool _speechEnabled = false;
  
  // Image state
  List<String> _imageLocalPaths = [];
  List<String> _imageUrls = [];
  
  // Form controllers
  final _speciesController = TextEditingController();
  final _speciesSearchController = TextEditingController();
  
  // Tree species data - Now using comprehensive Victorian species database (400+ species!)
  static final List<Map<String, String>> _treeSpecies = VictorianTreeSpecies.getAllSpecies();
  
  // Filtered species for search
  List<Map<String, String>> _filteredSpecies = [];
  String _searchQuery = '';
  final _dshController = TextEditingController();
  final _heightController = TextEditingController();
  final _commentsController = TextEditingController();
  final _voiceNotesController = TextEditingController();
  final _ageClassController = TextEditingController();
  final _retentionValueController = TextEditingController();
  final _riskRatingController = TextEditingController();
  final _locationDescriptionController = TextEditingController();
  final _habitatValueController = TextEditingController();
  final _recommendedWorksController = TextEditingController();
  final _healthFormController = TextEditingController();
  final _diseasesPresentController = TextEditingController();
  final _canopySpreadController = TextEditingController();
  final _clearanceToStructuresController = TextEditingController();
  final _originController = TextEditingController();
  final _pastManagementController = TextEditingController();
  final _pestPresenceController = TextEditingController();
  final _notesController = TextEditingController();
  final _targetOccupancyController = TextEditingController();
  final _likelihoodOfFailureController = TextEditingController();
  final _likelihoodOfImpactController = TextEditingController();
  final _consequenceOfFailureController = TextEditingController();
  final _overallRiskRatingController = TextEditingController();
  final _vtaNotesController = TextEditingController();
  final _inspectorNameController = TextEditingController();
  
  // Phase 1 controllers - Group 5: Health
  final _vigorRatingController = TextEditingController();
  final _foliageDensityController = TextEditingController();
  final _foliageColorController = TextEditingController();
  final _diebackPercentController = TextEditingController();
  final _growthRateController = TextEditingController();
  final _seasonalConditionController = TextEditingController();
  
  // Phase 1 controllers - Group 6: Structure
  final _crownFormController = TextEditingController();
  final _crownDensityController = TextEditingController();
  final _branchStructureController = TextEditingController();
  final _trunkFormController = TextEditingController();
  final _trunkLeanController = TextEditingController();
  final _leanDirectionController = TextEditingController();
  final _rootPlateConditionController = TextEditingController();
  final _includedBarkLocationController = TextEditingController();
  final _structuralRatingController = TextEditingController();
  
  // Phase 2 controllers - Group 7: VTA
  final _cavitySizeController = TextEditingController();
  final _cavityLocationController = TextEditingController();
  final _decayExtentController = TextEditingController();
  final _decayTypeController = TextEditingController();
  final _fungalSpeciesController = TextEditingController();
  final _barkDamagePercentController = TextEditingController();
  final _cracksSplitsLocationController = TextEditingController();
  final _deadWoodPercentController = TextEditingController();
  final _girdlingRootsSeverityController = TextEditingController();
  final _rootDamageDescriptionController = TextEditingController();
  final _mechanicalDamageDescriptionController = TextEditingController();
  
  // Phase 2 controllers - Group 8: QTRA
  final _qtraTargetTypeController = TextEditingController();
  final _qtraTargetValueController = TextEditingController();
  final _qtraOccupancyRateController = TextEditingController();
  final _qtraImpactPotentialController = TextEditingController();
  final _qtraProbabilityOfFailureController = TextEditingController();
  final _qtraProbabilityOfImpactController = TextEditingController();
  
  // Phase 3 controllers - Group 11: Impact
  final _developmentTypeController = TextEditingController();
  final _constructionZoneDistanceController = TextEditingController();
  final _rootZoneEncroachmentController = TextEditingController();
  final _canopyEncroachmentController = TextEditingController();
  final _excavationImpactController = TextEditingController();
  final _serviceInstallationDescriptionController = TextEditingController();
  final _demolitionDescriptionController = TextEditingController();
  final _accessRouteDescriptionController = TextEditingController();
  final _impactRatingController = TextEditingController();
  final _mitigationMeasuresController = TextEditingController();
  
  // Phase 3 controllers - Group 12: Development
  final _planningPermitNumberController = TextEditingController();
  final _planningPermitStatusController = TextEditingController();
  final _planningOverlayController = TextEditingController();
  final _localLawReferenceController = TextEditingController();
  
  // Phase 3 controllers - Group 13: Retention
  final _retentionRecommendationController = TextEditingController();
  final _retentionJustificationController = TextEditingController();
  final _removalJustificationController = TextEditingController();
  final _significanceController = TextEditingController();
  final _replacementRatioController = TextEditingController();
  final _offsetRequirementsController = TextEditingController();
  
  // Phase 3 controllers - Group 14: Management
  final _pruningSpecificationController = TextEditingController();
  final _worksPriorityController = TextEditingController();
  final _worksTimeframeController = TextEditingController();
  final _estimatedCostRangeController = TextEditingController();
  final _treeProtectionMeasuresController = TextEditingController();
  final _postWorksMonitoringFrequencyController = TextEditingController();
  
  // Phase 3 controllers - Group 15: Valuation
  final _valuationMethodController = TextEditingController();
  final _baseValueController = TextEditingController();
  final _conditionFactorController = TextEditingController();
  final _locationFactorController = TextEditingController();
  final _contributionFactorController = TextEditingController();
  final _valuerNameController = TextEditingController();
  
  // Phase 3 controllers - Group 16: Ecological
  final _wildlifeHabitatValueController = TextEditingController();
  final _nestingSpeciesController = TextEditingController();
  final _biodiversityValueController = TextEditingController();
  final _indigenousSignificanceDetailsController = TextEditingController();
  final _culturalHeritageDetailsController = TextEditingController();
  final _amenityValueController = TextEditingController();
  final _shadeProvisionController = TextEditingController();
  
  // Phase 3 controllers - Group 17: Regulatory
  final _heritageReferenceController = TextEditingController();
  final _legalLiabilityAssessmentController = TextEditingController();
  final _complianceNotesController = TextEditingController();
  
  // Phase 3 controllers - Group 18: Monitoring
  final _inspectionFrequencyController = TextEditingController();
  final _alertLevelController = TextEditingController();
  final _followUpActionsController = TextEditingController();
  
  // Phase 3 controllers - Group 19: Diagnostics
  final _resistographResultsController = TextEditingController();
  final _sonicTomographyResultsController = TextEditingController();
  final _pullingTestResultsController = TextEditingController();
  final _rootCollarFindingsController = TextEditingController();
  final _soilTestingResultsController = TextEditingController();
  final _pathologyReportController = TextEditingController();
  final _specialistConsultantController = TextEditingController();
  final _diagnosticSummaryController = TextEditingController();
  
  // Enhanced fields
  String _condition = 'Good';
  bool _permitRequired = false;
  double _latitude = 0.0;
  double _longitude = 0.0;
  double _srz = 0.0;
  double _nrz = 0.0;
  List<String> _defectsObserved = [];
  List<String> _vtaDefects = [];
  List<String> _stressIndicators = [];
  List<String> _structuralDefects = [];
  
  // Phase 1 boolean fields
  bool _buttressRoots = false;
  bool _surfaceRoots = false;
  bool _includedBark = false;
  
  // Phase 2 boolean fields - VTA
  bool _cavityPresent = false;
  bool _fungalFruitingBodies = false;
  bool _cracksSplits = false;
  bool _girdlingRoots = false;
  bool _rootDamage = false;
  bool _mechanicalDamage = false;
  List<String> _barkDamageType = [];
  
  // Phase 2 state - QTRA
  double _qtraRiskOfHarm = 0;
  String _qtraRiskRating = '';
  
  // Phase 3 boolean fields - Impact
  bool _serviceInstallationImpact = false;
  bool _demolitionImpact = false;
  bool _accessRouteImpact = false;
  
  // Phase 3 boolean fields - Development
  bool _planningPermitRequired = false;
  bool _heritageOverlay = false;
  bool _significantLandscapeOverlay = false;
  bool _vegetationProtectionOverlay = false;
  bool _localLawProtected = false;
  bool _as4970Compliant = false;
  bool _arboristReportRequired = false;
  bool _councilNotification = false;
  bool _neighborNotification = false;
  
  // Phase 3 boolean fields - Retention
  bool _replantingRequired = false;
  
  // Phase 3 boolean fields - Management
  List<String> _pruningType = [];
  List<String> _accessRequirements = [];
  bool _arboristSupervisionRequired = false;
  bool _postWorksMonitoring = false;
  bool _worksCompliance = false;
  DateTime? _worksCompletionDate;
  
  // Phase 3 state - Valuation
  double _totalValuation = 0;
  DateTime? _valuationDate;
  
  // Helper method to determine which groups are relevant for each report type
  List<String> _getRelevantGroupsForReportType() {
    final reportType = widget.reportType ?? 'PAA';
    
    switch (reportType) {
      case 'PAA': // Preliminary Assessment
        return ['photos', 'location', 'basic_data', 'health', 'structure'];
      
      case 'AIA': // Impact Assessment  
        return ['photos', 'location', 'basic_data', 'health', 'structure', 'protection_zones', 'impact_assessment', 'retention_removal'];
      
      case 'TPMP': // Tree Protection Plan
        return ['photos', 'location', 'basic_data', 'protection_zones', 'impact_assessment', 'management'];
      
      case 'TRA': // Tree Risk Assessment
        return ['photos', 'location', 'basic_data', 'health', 'structure', 'vta', 'qtra', 'isa_risk', 'management'];
      
      case 'Condition': // Condition Assessment
        return ['photos', 'voice_notes', 'location', 'basic_data', 'health', 'structure', 'vta', 'management'];
      
      case 'Removal': // Removal Application
        return ['photos', 'location', 'basic_data', 'health', 'structure', 'development', 'retention_removal', 'valuation'];
      
      case 'Witness': // Expert Witness Report
        return ['photos', 'voice_notes', 'location', 'basic_data', 'health', 'structure', 'vta', 'qtra', 'isa_risk', 'impact_assessment', 'development', 'retention_removal', 'valuation', 'management'];
      
      case 'PostDev': // Post-Development Monitoring
        return ['photos', 'location', 'basic_data', 'health', 'structure', 'protection_zones', 'management'];
      
      case 'Vegetation': // Vegetation Assessment
        return ['photos', 'location', 'basic_data', 'health', 'habitat', 'development', 'valuation'];
      
      default: // Show all groups for unknown types
        return ['photos', 'voice_notes', 'location', 'basic_data', 'health', 'structure', 'vta', 'qtra', 'isa_risk', 'protection_zones', 'impact_assessment', 'development', 'retention_removal', 'management', 'habitat', 'valuation'];
    }
  }

  Future<void> _syncPhotosToSiteFiles(TreeEntry tree) async {
    if (_photoPaths.isEmpty) {
      return;
    }

    try {
      await SiteFileService.init();
    } catch (_) {}

    final sanitizedSpecies = (tree.species.isNotEmpty ? tree.species : 'Tree')
        .replaceAll(RegExp(r'[^a-zA-Z0-9 _-]'), '')
        .trim();
    final folderPath = '/Photos/Tree ${tree.id}${sanitizedSpecies.isNotEmpty ? ' - $sanitizedSpecies' : ''}';

    for (int i = 0; i < _photoPaths.length; i++) {
      final source = _photoPaths[i];
      final bytes = await _resolvePhotoBytes(source);
      if (bytes == null || bytes.isEmpty) {
        continue;
      }

      final extension = _inferPhotoExtension(source) ?? 'jpg';
      final fileName = 'Tree_${tree.id}_${i + 1}.$extension';

      final exists = await SiteFileService.fileExists(widget.siteId, fileName);
      if (exists) {
        continue;
      }

      await SiteFileService.saveFileFromBytes(
        widget.siteId,
        bytes,
        fileName,
        extension,
        uploadedBy: 'Tree Form',
        category: 'Photos',
        folderPath: folderPath,
      );
    }
  }

  Future<Uint8List?> _resolvePhotoBytes(String source) async {
    try {
      if (source.startsWith('data:')) {
        final base64Section = source.contains(',') ? source.split(',').last : '';
        if (base64Section.isEmpty) {
          return null;
        }
        return Uint8List.fromList(base64Decode(base64Section));
      }

      if (!kIsWeb) {
        final file = File(source);
        if (await file.exists()) {
          return await file.readAsBytes();
        }
      }
    } catch (_) {}
    return null;
  }

  String? _inferPhotoExtension(String source) {
    if (source.startsWith('data:')) {
      final start = source.indexOf('image/');
      final end = source.indexOf(';');
      if (start != -1 && end != -1 && end > start) {
        return source.substring(start + 6, end);
      }
      return 'jpg';
    }

    final dotIndex = source.lastIndexOf('.');
    if (dotIndex != -1 && dotIndex < source.length - 1) {
      return source.substring(dotIndex + 1).toLowerCase();
    }
    return null;
  }
  
  // Phase 3 boolean fields - Ecological
  bool _hollowBearingTree = false;
  bool _nestingSites = false;
  List<String> _habitatFeatures = [];
  bool _indigenousSignificance = false;
  bool _culturalHeritage = false;
  
  // Phase 3 boolean fields - Regulatory
  bool _stateSignificant = false;
  bool _heritageListed = false;
  bool _significantTreeRegister = false;
  bool _bushfireManagementOverlay = false;
  bool _environmentalSignificanceOverlay = false;
  bool _waterwayProtection = false;
  bool _threatenedSpeciesHabitat = false;
  bool _insuranceNotificationRequired = false;
  
  // Phase 3 state - Monitoring
  DateTime? _nextInspectionDate;
  bool _monitoringRequired = false;
  List<String> _monitoringFocus = [];
  DateTime? _complianceCheckDate;
  
  // Phase 3 boolean fields - Diagnostics
  bool _resistographTest = false;
  DateTime? _resistographDate;
  bool _sonicTomography = false;
  DateTime? _sonicTomographyDate;
  bool _pullingTest = false;
  DateTime? _pullingTestDate;
  bool _rootCollarExcavation = false;
  bool _soilTesting = false;
  List<String> _diagnosticImages = [];
  
  // Mobile-first features
  // bool _isRecording = false; // Already declared above
  bool _isOffline = false;
  bool _isLoadingLocation = false;
  List<String> _photoPaths = [];
  List<String> _voiceNotePaths = [];
  Timer? _connectivityTimer;
  
  // Enhanced photo management
  final ImagePicker _imagePicker = ImagePicker();
  bool _isUploadingPhotos = false;
  int _uploadProgress = 0;
  
  // Export groups and expansion state for 20 collapsible sections
  Map<String, bool> _exportGroups = {};
  Map<String, bool> _expandedGroups = {};

  @override
  void initState() {
    super.initState();
    _initializeForm();
    _checkConnectivity();
    _initSpeech();
    _startConnectivityMonitoring();
    
    // Initialize species search - start with empty list
    _filteredSpecies = [];
    _speciesSearchController.addListener(() {
      _filterTreeSpecies(_speciesSearchController.text);
    });
  }

  void _filterTreeSpecies(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredSpecies = []; // Hide dropdown when no search query
      } else {
        _filteredSpecies = _treeSpecies.where((species) {
          final scientific = species['scientific']!.toLowerCase();
          final common = species['common']!.toLowerCase();
          final searchQuery = query.toLowerCase();
          return scientific.contains(searchQuery) || common.contains(searchQuery);
        }).toList();
      }
    });
  }
  
  Future<void> _initSpeech() async {
    _speechEnabled = await _speechToText.initialize();
    setState(() {});
  }
  
  // Voice recording methods
  Future<void> _startRecording() async {
    try {
      if (await _audioRecorder.hasPermission()) {
        final directory = await getApplicationDocumentsDirectory();
        _recordingPath = '${directory.path}/tree_note_${DateTime.now().millisecondsSinceEpoch}.m4a';
        
        await _audioRecorder.start(
          const RecordConfig(),
          path: _recordingPath!,
        );
        
        setState(() {
          _isRecording = true;
        });
        
        NotificationService.showInfo(context, 'Recording started...');
      } else {
        NotificationService.showError(context, 'Microphone permission denied');
      }
    } catch (e) {
      NotificationService.showError(context, 'Failed to start recording: $e');
    }
  }
  
  Future<void> _stopRecording() async {
    try {
      final path = await _audioRecorder.stop();
      if (path != null) {
        setState(() {
          _isRecording = false;
          _hasRecording = true;
          _recordingPath = path;
        });
        
        // Start transcription
        _transcribeAudio();
        
        NotificationService.showSuccess(context, 'Recording saved');
      }
    } catch (e) {
      NotificationService.showError(context, 'Failed to stop recording: $e');
    }
  }
  
  Future<void> _transcribeAudio() async {
    if (!_speechEnabled || _recordingPath == null) return;
    
    setState(() {
      _isTranscribing = true;
    });
    
    try {
      // For web, we'll use the speech-to-text live listening instead
      if (kIsWeb) {
        // Start listening for speech
        await _speechToText.listen(
          onResult: (result) {
            setState(() {
              _transcriptionText = result.recognizedWords;
            });
          },
        );
        
        // Stop after 30 seconds
        Future.delayed(const Duration(seconds: 30), () {
          _speechToText.stop();
          setState(() {
            _isTranscribing = false;
          });
        });
      } else {
        // On mobile, transcribe the recorded audio file
        setState(() {
          _transcriptionText = 'Transcription will appear here after processing...';
          _isTranscribing = false;
        });
      }
    } catch (e) {
      setState(() {
        _isTranscribing = false;
      });
      NotificationService.showError(context, 'Transcription failed: $e');
    }
  }
  
  Future<void> _playRecording() async {
    if (_recordingPath == null) return;
    
    try {
      await _audioPlayer.setFilePath(_recordingPath!);
      await _audioPlayer.play();
      NotificationService.showInfo(context, 'Playing recording...');
    } catch (e) {
      NotificationService.showError(context, 'Failed to play recording: $e');
    }
  }
  
  void _deleteRecording() {
    setState(() {
      _hasRecording = false;
      _recordingPath = null;
      _transcriptionText = '';
    });
    NotificationService.showInfo(context, 'Recording deleted');
  }
  
  void _addTranscriptionToNotes() {
    if (_transcriptionText.isNotEmpty) {
      setState(() {
        _notesController.text = _notesController.text.isEmpty
            ? _transcriptionText
            : '${_notesController.text}\n\n$_transcriptionText';
        _transcriptionText = '';
      });
      NotificationService.showSuccess(context, 'Transcription added to notes');
    }
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    _connectivityTimer?.cancel();
    super.dispose();
  }

  void _startConnectivityMonitoring() {
    _connectivityTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      _checkConnectivity();
    });
  }

  Future<void> _checkConnectivity() async {
    try {
      final connectivityResult = await Connectivity().checkConnectivity();
      setState(() {
        _isOffline = connectivityResult == ConnectivityResult.none;
      });
    } catch (e) {
      setState(() {
        _isOffline = true;
      });
    }
  }

  void _initializeForm() {
    // Initialize export groups with smart defaults:
    // 1. If editing existing tree, use its export groups
    // 2. If new tree on site with preferences, use site preferences
    // 3. Otherwise use default groups
    
    if (widget.initialEntry != null) {
      // Editing existing tree - use its export groups
      _exportGroups = widget.initialEntry!.exportGroups;
    } else if (widget.siteId != null) {
      // New tree - check if site has preferences from previous trees
      final sitePreferences = AppStateService.getExportGroupsForSite(widget.siteId!);
      
      if (sitePreferences != null) {
        // Site has preferences - use them!
        _exportGroups = Map<String, bool>.from(sitePreferences);
      } else {
        // First tree on site - use defaults
        _exportGroups = {
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
          'impact_assessment': true,
          'development': true,
          'retention_removal': true,
          'management': true,
          'valuation': false,
          'ecological': true,
          'regulatory': true,
          'monitoring': true,
          'diagnostics': false,
          'inspector_details': true,
        };
      }
    } else {
      // No site specified - use defaults
      _exportGroups = {
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
        'impact_assessment': true,
        'development': true,
        'retention_removal': true,
        'management': true,
        'valuation': false,
        'ecological': true,
        'regulatory': true,
        'monitoring': true,
        'diagnostics': false,
        'inspector_details': true,
      };
    }
    
    // Initialize expansion states (UI only)
    _expandedGroups = {
      'photos': true,
      'voice_notes': false,
      'location': true,
      'basic_data': true,
      'health': false,
      'structure': false,
      'vta': false,
      'qtra': false,
      'isa_risk': false,
      'protection_zones': false,
      'impact_assessment': false,
      'development': false,
      'retention_removal': false,
      'management': false,
      'valuation': false,
      'ecological': false,
      'regulatory': false,
      'monitoring': false,
      'diagnostics': false,
      'inspector_details': false,
    };
    
    if (widget.initialEntry != null) {
      final entry = widget.initialEntry!;
      _speciesController.text = entry.species;
      _dshController.text = entry.dsh.toString();
      _heightController.text = entry.height.toString();
      _commentsController.text = entry.comments;
      _condition = entry.condition;
      _permitRequired = entry.permitRequired;
      _latitude = entry.latitude;
      _longitude = entry.longitude;
      _srz = entry.srz;
      _nrz = entry.nrz;
      _photoPaths = List.from(entry.imageLocalPaths);
      
      // Initialize additional fields
      _ageClassController.text = entry.ageClass;
      _retentionValueController.text = entry.retentionValue;
      _riskRatingController.text = entry.riskRating;
      _locationDescriptionController.text = entry.locationDescription;
      _habitatValueController.text = entry.habitatValue;
      _recommendedWorksController.text = entry.recommendedWorks;
      _healthFormController.text = entry.healthForm;
      _diseasesPresentController.text = entry.diseasesPresent;
      _canopySpreadController.text = entry.canopySpread.toString();
      _clearanceToStructuresController.text = entry.clearanceToStructures.toString();
      _originController.text = entry.origin;
      _pastManagementController.text = entry.pastManagement;
      _pestPresenceController.text = entry.pestPresence;
      _notesController.text = entry.notes;
      _targetOccupancyController.text = entry.targetOccupancy;
      _likelihoodOfFailureController.text = entry.likelihoodOfFailure;
      _likelihoodOfImpactController.text = entry.likelihoodOfImpact;
      _consequenceOfFailureController.text = entry.consequenceOfFailure;
      _overallRiskRatingController.text = entry.overallRiskRating;
      _vtaNotesController.text = entry.vtaNotes;
      _inspectorNameController.text = entry.inspectorName;
      _defectsObserved = List.from(entry.defectsObserved);
      _vtaDefects = List.from(entry.vtaDefects);
      
      // Phase 1 fields - Group 5: Health
      _vigorRatingController.text = entry.vigorRating;
      _foliageDensityController.text = entry.foliageDensity;
      _foliageColorController.text = entry.foliageColor;
      _diebackPercentController.text = entry.diebackPercent.toString();
      _stressIndicators = List.from(entry.stressIndicators);
      _growthRateController.text = entry.growthRate;
      _seasonalConditionController.text = entry.seasonalCondition;
      
      // Phase 1 fields - Group 6: Structure
      _crownFormController.text = entry.crownForm;
      _crownDensityController.text = entry.crownDensity;
      _branchStructureController.text = entry.branchStructure;
      _trunkFormController.text = entry.trunkForm;
      _trunkLeanController.text = entry.trunkLean;
      _leanDirectionController.text = entry.leanDirection;
      _rootPlateConditionController.text = entry.rootPlateCondition;
      _buttressRoots = entry.buttressRoots;
      _surfaceRoots = entry.surfaceRoots;
      _includedBark = entry.includedBark;
      _includedBarkLocationController.text = entry.includedBarkLocation;
      _structuralDefects = List.from(entry.structuralDefects);
      _structuralRatingController.text = entry.structuralRating;
    } else {
      // Auto-numbering for new trees
      _generateNextTreeId();
    }
  }

  Future<void> _generateNextTreeId() async {
    try {
      // Tree ID will be generated when saving
      final treeNumber = await TreeStorageService.getNextTreeNumber(widget.siteId);
      // Just verify the counter is working
      print('Next tree will be: Tree $treeNumber');
    } catch (e) {
      print('Error generating tree ID: $e');
    }
  }

  // Enhanced GPS functionality
  Future<void> _getCurrentLocation() async {
    setState(() {
      _isLoadingLocation = true;
    });

    try {
      // Check if location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        NotificationService.showError(context, 'Location services are disabled');
        return;
      }

      // Check location permission
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          NotificationService.showError(context, 'Location permission denied');
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        NotificationService.showError(context, 'Location permissions are permanently denied');
        return;
      }

      // Get current position with high accuracy
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      );

      setState(() {
        _latitude = position.latitude;
        _longitude = position.longitude;
        _isLoadingLocation = false;
      });

      // Calculate SRZ and NRZ based on DSH
      _calculateProtectionZones();

      NotificationService.showSuccess(context, 'Location captured successfully!');
    } catch (e) {
      setState(() {
        _isLoadingLocation = false;
      });
      NotificationService.showError(context, 'Failed to get location: $e');
    }
  }

  void _calculateProtectionZones() {
    final dsh = double.tryParse(_dshController.text) ?? 0;
    if (dsh > 0) {
                          setState(() {
                      // DSH is in cm, convert to meters for calculations
                      // NRZ = DSH × 12 (in meters) - larger general protection zone (TPZ)
                      // SRZ = DSH × 2 (in meters) - smaller critical zone around trunk
                      _nrz = (dsh / 100) * 12;  // Convert cm to m, then multiply by 12 (larger zone)
                      _srz = (dsh / 100) * 2;   // Convert cm to m, then multiply by 2 (smaller zone)
                    });
    }
  }

  // Web-compatible image widget
  Widget _buildWebCompatibleImage(String imagePath) {
    try {
      // Check if it's a network URL
      if (imagePath.startsWith('http://') || imagePath.startsWith('https://')) {
        return Image.network(
          imagePath,
          width: double.infinity,
          height: double.infinity,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return _buildImagePlaceholder('Network Image Error');
          },
        );
      }
      
      // Check if it's a blob URL (web)
      if (imagePath.startsWith('blob:') && kIsWeb) {
        return Image.network(
          imagePath,
          width: double.infinity,
          height: double.infinity,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return _buildImagePlaceholder('Blob Image Error');
          },
        );
      }

      // Handle base64 data URIs on web
      if (imagePath.startsWith('data:') && kIsWeb) {
        final uri = Uri.parse(imagePath);
        final data = uri.data;
        if (data != null) {
          try {
            final bytes = data.contentAsBytes();
            return Image.memory(
              bytes,
              width: double.infinity,
              height: double.infinity,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return _buildImagePlaceholder('Data Image Error');
              },
            );
          } catch (e) {
            return _buildImagePlaceholder('Invalid Image Data');
          }
        }
      }

      // For web, we can't use File paths, so show a placeholder
      if (kIsWeb) {
        return _buildImagePlaceholder('Image: ${imagePath.split('/').last}');
      } else {
        // On mobile, use Image.file
        return Image.file(
          File(imagePath),
          width: double.infinity,
          height: double.infinity,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return _buildImagePlaceholder('File Image Error');
          },
        );
      }
    } catch (e) {
      // Fallback for any errors
      return _buildImagePlaceholder('Error: $e');
    }
  }

  Widget _buildImagePlaceholder(String text) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(
        color: Colors.grey[300],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.image, size: 48, color: Colors.grey[600]),
          const SizedBox(height: 8),
          Text(
            text,
            style: TextStyle(color: Colors.grey[600], fontSize: 12),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // Enhanced photo management
  Future<void> _takePhoto() async {
    try {
      final XFile? photo = await _imagePicker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (photo != null) {
        await _storePhotoFromXFile(photo);
      }
    } catch (e) {
      NotificationService.showError(context, 'Failed to take photo: $e');
    }
  }

  Future<void> _pickPhotos() async {
    try {
      final List<XFile> images = await _imagePicker.pickMultiImage(
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (images.isNotEmpty) {
        for (final image in images) {
          await _storePhotoFromXFile(image);
        }
      }
    } catch (e) {
      NotificationService.showError(context, 'Failed to pick photos: $e');
    }
  }

  Future<void> _storePhotoFromXFile(XFile image) async {
    try {
      String storedValue;
      if (kIsWeb) {
        final bytes = await image.readAsBytes();
        final base64Data = base64Encode(bytes);
        storedValue = 'data:${image.mimeType ?? 'image/jpeg'};base64,$base64Data';
      } else {
        storedValue = image.path;
      }

      setState(() {
        _photoPaths.add(storedValue);
      });

      if (!_isOffline && !kIsWeb) {
        _uploadPhoto(image.path);
      }
    } catch (e) {
      NotificationService.showError(context, 'Failed to process photo: $e');
    }
  }

  Future<void> _uploadPhoto(String photoPath) async {
    setState(() {
      _isUploadingPhotos = true;
    });

    try {
      // Simulate upload progress
      for (int i = 0; i <= 100; i += 10) {
        setState(() {
          _uploadProgress = i;
        });
        await Future.delayed(const Duration(milliseconds: 100));
      }
      
      // Here you would actually upload to cloud storage
      print('Photo uploaded: $photoPath');
    } catch (e) {
      NotificationService.showError(context, 'Failed to upload photo: $e');
    } finally {
      setState(() {
        _isUploadingPhotos = false;
        _uploadProgress = 0;
      });
    }
  }


  // Duplicate methods removed - using the ones defined earlier

  Future<void> _saveTree() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      // Use simple sequential numbering
      String treeId = widget.initialEntry?.id ?? '';
      if (treeId.isEmpty) {
        final treeNumber = await TreeStorageService.getNextTreeNumber(widget.siteId);
        treeId = 'Tree $treeNumber';
      }
      final tree = TreeEntry(
        id: treeId,
        species: _speciesController.text,
        dsh: double.parse(_dshController.text),
        height: double.parse(_heightController.text),
        condition: _condition,
        comments: _commentsController.text,
        permitRequired: _permitRequired,
        latitude: _latitude,
        longitude: _longitude,
        srz: _srz,
        nrz: _nrz,
        ageClass: _ageClassController.text,
        retentionValue: _retentionValueController.text,
        riskRating: _riskRatingController.text,
        locationDescription: _locationDescriptionController.text,
        habitatValue: _habitatValueController.text,
        recommendedWorks: _recommendedWorksController.text,
        healthForm: _healthFormController.text,
        diseasesPresent: _diseasesPresentController.text,
        canopySpread: double.tryParse(_canopySpreadController.text) ?? 0.0,
        clearanceToStructures: double.tryParse(_clearanceToStructuresController.text) ?? 0.0,
        origin: _originController.text,
        pastManagement: _pastManagementController.text,
        pestPresence: _pestPresenceController.text,
        notes: _notesController.text,
        targetOccupancy: _targetOccupancyController.text,
        defectsObserved: _defectsObserved,
        likelihoodOfFailure: _likelihoodOfFailureController.text,
        likelihoodOfImpact: _likelihoodOfImpactController.text,
        consequenceOfFailure: _consequenceOfFailureController.text,
        overallRiskRating: _overallRiskRatingController.text,
        vtaNotes: _vtaNotesController.text,
        vtaDefects: _vtaDefects,
        inspectionDate: DateTime.now(),
        inspectorName: _inspectorNameController.text,
        imageLocalPaths: _photoPaths,
        imageUrls: [],
        siteId: widget.siteId,
        // Phase 1 fields - Group 5: Health
        vigorRating: _vigorRatingController.text,
        foliageDensity: _foliageDensityController.text,
        foliageColor: _foliageColorController.text,
        diebackPercent: double.tryParse(_diebackPercentController.text) ?? 0,
        stressIndicators: _stressIndicators,
        growthRate: _growthRateController.text,
        seasonalCondition: _seasonalConditionController.text,
        // Phase 1 fields - Group 6: Structure
        crownForm: _crownFormController.text,
        crownDensity: _crownDensityController.text,
        branchStructure: _branchStructureController.text,
        trunkForm: _trunkFormController.text,
        trunkLean: _trunkLeanController.text,
        leanDirection: _leanDirectionController.text,
        rootPlateCondition: _rootPlateConditionController.text,
        buttressRoots: _buttressRoots,
        surfaceRoots: _surfaceRoots,
        includedBark: _includedBark,
        includedBarkLocation: _includedBarkLocationController.text,
        structuralDefects: _structuralDefects,
        structuralRating: _structuralRatingController.text,
        // Phase 2 - VTA fields
        cavityPresent: _cavityPresent,
        cavitySize: _cavitySizeController.text,
        cavityLocation: _cavityLocationController.text,
        decayExtent: _decayExtentController.text,
        decayType: _decayTypeController.text,
        fungalFruitingBodies: _fungalFruitingBodies,
        fungalSpecies: _fungalSpeciesController.text,
        barkDamagePercent: double.tryParse(_barkDamagePercentController.text) ?? 0,
        barkDamageType: _barkDamageType,
        cracksSplits: _cracksSplits,
        cracksSplitsLocation: _cracksSplitsLocationController.text,
        deadWoodPercent: double.tryParse(_deadWoodPercentController.text) ?? 0,
        girdlingRoots: _girdlingRoots,
        girdlingRootsSeverity: _girdlingRootsSeverityController.text,
        rootDamage: _rootDamage,
        rootDamageDescription: _rootDamageDescriptionController.text,
        mechanicalDamage: _mechanicalDamage,
        mechanicalDamageDescription: _mechanicalDamageDescriptionController.text,
        // Phase 2 - QTRA fields
        qtraTargetType: _qtraTargetTypeController.text,
        qtraTargetValue: _qtraTargetValueController.text,
        qtraOccupancyRate: _qtraOccupancyRateController.text,
        qtraImpactPotential: _qtraImpactPotentialController.text,
        qtraProbabilityOfFailure: double.tryParse(_qtraProbabilityOfFailureController.text) ?? 0,
        qtraProbabilityOfImpact: double.tryParse(_qtraProbabilityOfImpactController.text) ?? 0,
        qtraRiskOfHarm: _qtraRiskOfHarm,
        qtraRiskRating: _qtraRiskRating,
        // Phase 3 - Impact Assessment
        developmentType: _developmentTypeController.text,
        constructionZoneDistance: double.tryParse(_constructionZoneDistanceController.text) ?? 0,
        rootZoneEncroachmentPercent: double.tryParse(_rootZoneEncroachmentController.text) ?? 0,
        canopyEncroachmentPercent: double.tryParse(_canopyEncroachmentController.text) ?? 0,
        excavationImpact: _excavationImpactController.text,
        serviceInstallationImpact: _serviceInstallationImpact,
        serviceInstallationDescription: _serviceInstallationDescriptionController.text,
        demolitionImpact: _demolitionImpact,
        demolitionDescription: _demolitionDescriptionController.text,
        accessRouteImpact: _accessRouteImpact,
        accessRouteDescription: _accessRouteDescriptionController.text,
        impactRating: _impactRatingController.text,
        mitigationMeasures: _mitigationMeasuresController.text,
        // Phase 3 - Development Compliance
        planningPermitRequired: _planningPermitRequired,
        planningPermitNumber: _planningPermitNumberController.text,
        planningPermitStatus: _planningPermitStatusController.text,
        planningOverlay: _planningOverlayController.text,
        heritageOverlay: _heritageOverlay,
        significantLandscapeOverlay: _significantLandscapeOverlay,
        vegetationProtectionOverlay: _vegetationProtectionOverlay,
        localLawProtected: _localLawProtected,
        localLawReference: _localLawReferenceController.text,
        as4970Compliant: _as4970Compliant,
        arboristReportRequired: _arboristReportRequired,
        councilNotification: _councilNotification,
        neighborNotification: _neighborNotification,
        // Phase 3 - Retention & Removal
        retentionRecommendation: _retentionRecommendationController.text,
        retentionJustification: _retentionJustificationController.text,
        removalJustification: _removalJustificationController.text,
        significance: _significanceController.text,
        replantingRequired: _replantingRequired,
        replacementRatio: double.tryParse(_replacementRatioController.text) ?? 0,
        offsetRequirements: _offsetRequirementsController.text,
        // Phase 3 - Management & Works
        pruningType: _pruningType,
        pruningSpecification: _pruningSpecificationController.text,
        worksPriority: _worksPriorityController.text,
        worksTimeframe: _worksTimeframeController.text,
        estimatedCostRange: _estimatedCostRangeController.text,
        accessRequirements: _accessRequirements,
        arboristSupervisionRequired: _arboristSupervisionRequired,
        treeProtectionMeasures: _treeProtectionMeasuresController.text,
        postWorksMonitoring: _postWorksMonitoring,
        postWorksMonitoringFrequency: _postWorksMonitoringFrequencyController.text,
        worksCompletionDate: _worksCompletionDate,
        worksCompliance: _worksCompliance,
        // Phase 3 - Tree Valuation
        valuationMethod: _valuationMethodController.text,
        baseValue: double.tryParse(_baseValueController.text) ?? 0,
        conditionFactor: double.tryParse(_conditionFactorController.text) ?? 0,
        locationFactor: double.tryParse(_locationFactorController.text) ?? 0,
        contributionFactor: double.tryParse(_contributionFactorController.text) ?? 0,
        totalValuation: _totalValuation,
        valuationDate: _valuationDate,
        valuerName: _valuerNameController.text,
        // Phase 3 - Ecological Value
        wildlifeHabitatValue: _wildlifeHabitatValueController.text,
        hollowBearingTree: _hollowBearingTree,
        nestingSites: _nestingSites,
        nestingSpecies: _nestingSpeciesController.text,
        habitatFeatures: _habitatFeatures,
        biodiversityValue: _biodiversityValueController.text,
        indigenousSignificance: _indigenousSignificance,
        indigenousSignificanceDetails: _indigenousSignificanceDetailsController.text,
        culturalHeritage: _culturalHeritage,
        culturalHeritageDetails: _culturalHeritageDetailsController.text,
        amenityValue: _amenityValueController.text,
        shadeProvision: _shadeProvisionController.text,
        // Phase 3 - Regulatory & Compliance
        stateSignificant: _stateSignificant,
        heritageListed: _heritageListed,
        heritageReference: _heritageReferenceController.text,
        significantTreeRegister: _significantTreeRegister,
        bushfireManagementOverlay: _bushfireManagementOverlay,
        environmentalSignificanceOverlay: _environmentalSignificanceOverlay,
        waterwayProtection: _waterwayProtection,
        threatenedSpeciesHabitat: _threatenedSpeciesHabitat,
        insuranceNotificationRequired: _insuranceNotificationRequired,
        legalLiabilityAssessment: _legalLiabilityAssessmentController.text,
        complianceNotes: _complianceNotesController.text,
        // Phase 3 - Monitoring & Scheduling
        nextInspectionDate: _nextInspectionDate,
        inspectionFrequency: _inspectionFrequencyController.text,
        monitoringRequired: _monitoringRequired,
        monitoringFocus: _monitoringFocus,
        alertLevel: _alertLevelController.text,
        followUpActions: _followUpActionsController.text,
        complianceCheckDate: _complianceCheckDate,
        // Phase 3 - Advanced Diagnostics
        resistographTest: _resistographTest,
        resistographDate: _resistographDate,
        resistographResults: _resistographResultsController.text,
        sonicTomography: _sonicTomography,
        sonicTomographyDate: _sonicTomographyDate,
        sonicTomographyResults: _sonicTomographyResultsController.text,
        pullingTest: _pullingTest,
        pullingTestDate: _pullingTestDate,
        pullingTestResults: _pullingTestResultsController.text,
        rootCollarExcavation: _rootCollarExcavation,
        rootCollarFindings: _rootCollarFindingsController.text,
        soilTesting: _soilTesting,
        soilTestingResults: _soilTestingResultsController.text,
        pathologyReport: _pathologyReportController.text,
        diagnosticImages: _diagnosticImages,
        specialistConsultant: _specialistConsultantController.text,
        diagnosticSummary: _diagnosticSummaryController.text,
        exportGroups: _exportGroups,
      );

      // Check if this is the first tree on the site (before saving preferences)
      final isFirstTreeOnSite = widget.initialEntry == null && 
                                 widget.siteId != null && 
                                 !AppStateService.hasSitePreferences(widget.siteId!);
      
      // Save export group preferences for this site
      // This makes the current selections the default for future trees on this site
      if (widget.siteId != null) {
        await AppStateService.saveExportGroupsForSite(widget.siteId!, _exportGroups);
      }
      
      // Don't save here - let the onSubmit callback handle it
      // This prevents duplicate saving
      
      // Save to offline storage if offline
      if (_isOffline) {
        await AppStateService.saveOfflineTree(tree);
      }

      widget.onSubmit(tree);

      // Persist captured photos to Files tab
      await _syncPhotosToSiteFiles(tree);

      // Show success message with site preference info
      if (isFirstTreeOnSite) {
        NotificationService.showSuccess(
          context, 
          '✅ Tree saved! Export preferences set for this site.'
        );
      } else {
        NotificationService.showSuccess(context, 'Tree saved successfully!');
      }
    } catch (e) {
      NotificationService.showError(context, 'Failed to save tree: $e');
    }
  }

  // ========== CONTENT BUILDERS FOR 20 COLLAPSIBLE GROUPS ==========
  
  List<Widget> _buildPhotosContent() {
    return [
      if (_isUploadingPhotos)
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: LinearProgressIndicator(value: _uploadProgress / 100),
        ),
      if (_photoPaths.isNotEmpty)
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
          ),
          itemCount: _photoPaths.length,
          itemBuilder: (context, index) {
            return Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: _buildWebCompatibleImage(_photoPaths[index]),
                ),
                Positioned(
                  top: 4,
                  right: 4,
                  child: GestureDetector(
                    onTap: () => setState(() => _photoPaths.removeAt(index)),
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.close, color: Colors.white, size: 16),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      if (_photoPaths.isNotEmpty) const SizedBox(height: 12),
      Row(
        children: [
          Expanded(
            child: ElevatedButton.icon(
              onPressed: _takePhoto,
              icon: const Icon(Icons.camera_alt),
              label: const Text('Take Photo'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green.shade100,
                foregroundColor: Colors.green.shade800,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: ElevatedButton.icon(
              onPressed: _pickPhotos,
              icon: const Icon(Icons.photo_library),
              label: const Text('Pick Photos'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue.shade100,
                foregroundColor: Colors.blue.shade800,
              ),
            ),
          ),
        ],
      ),
    ];
  }

  List<Widget> _buildVoiceNotesContent() {
    return [
      if (_voiceNotePaths.isNotEmpty)
        ...(_voiceNotePaths.asMap().entries.map((entry) {
          final index = entry.key;
          final path = entry.value;
          return ListTile(
            leading: const Icon(Icons.play_circle, color: Colors.purple),
            title: Text('Voice Note ${index + 1}'),
            subtitle: const Text('Tap to play'),
            trailing: IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: () => setState(() => _voiceNotePaths.removeAt(index)),
            ),
            onTap: () => _playRecording(),
          );
        })),
      if (_voiceNotePaths.isNotEmpty) const SizedBox(height: 12),
      ElevatedButton.icon(
        onPressed: _isRecording ? _stopRecording : _startRecording,
        icon: Icon(_isRecording ? Icons.stop : Icons.mic),
        label: Text(_isRecording ? 'Stop Recording' : 'Start Recording'),
        style: ElevatedButton.styleFrom(
          backgroundColor: _isRecording ? Colors.red.shade100 : Colors.purple.shade100,
          foregroundColor: _isRecording ? Colors.red.shade800 : Colors.purple.shade800,
        ),
      ),
    ];
  }

  List<Widget> _buildLocationContent() {
    return [
      if (_latitude != 0 && _longitude != 0) ...[
        Text('Latitude: ${_latitude.toStringAsFixed(6)}'),
        Text('Longitude: ${_longitude.toStringAsFixed(6)}'),
        Text('SRZ: ${_srz.toStringAsFixed(2)}m  |  NRZ: ${_nrz.toStringAsFixed(2)}m'),
        const SizedBox(height: 12),
      ],
      ElevatedButton.icon(
        onPressed: _isLoadingLocation ? null : _getCurrentLocation,
        icon: const Icon(Icons.my_location),
        label: const Text('Get Current Location'),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.red.shade100,
          foregroundColor: Colors.red.shade800,
        ),
      ),
    ];
  }

  List<Widget> _buildBasicDataContent() {
    return [
      // Species search with autocomplete
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextFormField(
            controller: _speciesController.text.isNotEmpty ? _speciesController : _speciesSearchController,
            decoration: InputDecoration(
              labelText: 'Species',
              hintText: _speciesController.text.isNotEmpty ? null : 'Type to search species...',
              prefixIcon: const Icon(Icons.search),
              border: const OutlineInputBorder(),
              suffixIcon: _speciesController.text.isNotEmpty 
                ? IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () {
                      setState(() {
                        _speciesController.clear();
                        _speciesSearchController.clear();
                        _filteredSpecies = [];
                      });
                    },
                  )
                : null,
            ),
            onChanged: _speciesController.text.isNotEmpty ? null : _filterTreeSpecies,
            readOnly: _speciesController.text.isNotEmpty,
            validator: (value) => (value == null || value.isEmpty) ? 'Please select a species' : null,
          ),
          if (_filteredSpecies.isNotEmpty && _speciesSearchController.text.isNotEmpty)
            Container(
              constraints: const BoxConstraints(maxHeight: 200),
              margin: const EdgeInsets.only(top: 4),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey),
                borderRadius: BorderRadius.circular(4),
                color: Colors.white,
              ),
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: _filteredSpecies.length,
                itemBuilder: (context, index) {
                  final species = _filteredSpecies[index];
                  return ListTile(
                    dense: true,
                    title: Text(species['scientific']!, style: const TextStyle(fontSize: 14)),
                    subtitle: Text(species['common']!, style: const TextStyle(fontSize: 12)),
                    onTap: () {
                      setState(() {
                        _speciesController.text = '${species['scientific']} (${species['common']})';
                        _speciesSearchController.clear();
                        _filteredSpecies = [];
                      });
                    },
                  );
                },
              ),
            ),
        ],
      ),
      const SizedBox(height: 16),
      Row(
        children: [
          Expanded(
            child: TextFormField(
              controller: _dshController,
              decoration: const InputDecoration(labelText: 'DSH (cm)', border: OutlineInputBorder()),
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value == null || value.isEmpty) return 'Required';
                if (double.tryParse(value) == null) return 'Invalid number';
                return null;
              },
              onChanged: (value) => _calculateProtectionZones(),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: TextFormField(
              controller: _heightController,
              decoration: const InputDecoration(labelText: 'Height (m)', border: OutlineInputBorder()),
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value == null || value.isEmpty) return 'Required';
                if (double.tryParse(value) == null) return 'Invalid number';
                return null;
              },
            ),
          ),
        ],
      ),
      const SizedBox(height: 16),
      Row(
        children: [
          Expanded(
            child: TextFormField(
              controller: _canopySpreadController,
              decoration: const InputDecoration(labelText: 'Canopy Spread (m)', border: OutlineInputBorder()),
              keyboardType: TextInputType.number,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: TextFormField(
              controller: _clearanceToStructuresController,
              decoration: const InputDecoration(labelText: 'Clearance (m)', border: OutlineInputBorder()),
              keyboardType: TextInputType.number,
            ),
          ),
        ],
      ),
      const SizedBox(height: 16),
      DropdownButtonFormField<String>(
        value: _condition,
        decoration: const InputDecoration(labelText: 'Condition', border: OutlineInputBorder()),
        items: ['Excellent', 'Good', 'Fair', 'Poor', 'Critical']
            .map((c) => DropdownMenuItem(value: c, child: Text(c)))
            .toList(),
        onChanged: (value) => setState(() => _condition = value!),
      ),
      const SizedBox(height: 16),
      CheckboxListTile(
        title: const Text('Permit Required'),
        value: _permitRequired,
        onChanged: (value) => setState(() => _permitRequired = value!),
      ),
      const SizedBox(height: 16),
      TextFormField(
        controller: _commentsController,
        decoration: const InputDecoration(labelText: 'Comments', border: OutlineInputBorder()),
        maxLines: 3,
      ),
      const SizedBox(height: 16),
      // Notes section with voice recording and transcription
      Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(8),
          color: Colors.grey.shade50,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.notes, color: Colors.green),
                const SizedBox(width: 8),
                const Text(
                  'Notes & Voice Recording',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                if (_isRecording)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: const [
                        Icon(Icons.fiber_manual_record, color: Colors.white, size: 12),
                        SizedBox(width: 4),
                        Text('Recording', style: TextStyle(color: Colors.white, fontSize: 12)),
                      ],
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _notesController,
              decoration: const InputDecoration(
                labelText: 'Notes',
                hintText: 'Enter detailed notes about this tree...',
                border: OutlineInputBorder(),
              ),
              maxLines: 5,
              minLines: 3,
            ),
            const SizedBox(height: 12),
            // Voice recording controls
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isRecording ? _stopRecording : _startRecording,
                    icon: Icon(_isRecording ? Icons.stop : Icons.mic),
                    label: Text(_isRecording ? 'Stop Recording' : 'Start Voice Recording'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _isRecording ? Colors.red : Colors.blue,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
                if (_hasRecording) ...[
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: _playRecording,
                    icon: const Icon(Icons.play_arrow),
                    tooltip: 'Play Recording',
                    color: Colors.green,
                  ),
                  IconButton(
                    onPressed: _deleteRecording,
                    icon: const Icon(Icons.delete),
                    tooltip: 'Delete Recording',
                    color: Colors.red,
                  ),
                ],
              ],
            ),
            if (_isTranscribing)
              const Padding(
                padding: EdgeInsets.only(top: 8),
                child: LinearProgressIndicator(),
              ),
            if (_transcriptionText.isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.transcribe, size: 16, color: Colors.blue),
                        const SizedBox(width: 4),
                        const Text(
                          'Transcription:',
                          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue),
                        ),
                        const Spacer(),
                        TextButton.icon(
                          onPressed: _addTranscriptionToNotes,
                          icon: const Icon(Icons.add, size: 16),
                          label: const Text('Add to Notes'),
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _transcriptionText,
                      style: const TextStyle(fontSize: 14),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    ];
  }

  List<Widget> _buildHealthContent() {
    return [
      DropdownButtonFormField<String>(
        value: _vigorRatingController.text.isEmpty ? null : _vigorRatingController.text,
        decoration: const InputDecoration(labelText: 'Vigor Rating', border: OutlineInputBorder()),
        items: ['High', 'Moderate', 'Low', 'Declining']
            .map((v) => DropdownMenuItem(value: v, child: Text(v)))
            .toList(),
        onChanged: (value) => setState(() => _vigorRatingController.text = value ?? ''),
      ),
      const SizedBox(height: 16),
      Row(
        children: [
          Expanded(
            child: DropdownButtonFormField<String>(
              value: _foliageDensityController.text.isEmpty ? null : _foliageDensityController.text,
              decoration: const InputDecoration(labelText: 'Foliage Density', border: OutlineInputBorder()),
              items: ['Dense', 'Moderate', 'Sparse', 'Very Sparse']
                  .map((v) => DropdownMenuItem(value: v, child: Text(v)))
                  .toList(),
              onChanged: (value) => setState(() => _foliageDensityController.text = value ?? ''),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: DropdownButtonFormField<String>(
              value: _foliageColorController.text.isEmpty ? null : _foliageColorController.text,
              decoration: const InputDecoration(labelText: 'Foliage Color', border: OutlineInputBorder()),
              items: ['Normal', 'Chlorotic', 'Necrotic', 'Discolored']
                  .map((v) => DropdownMenuItem(value: v, child: Text(v)))
                  .toList(),
              onChanged: (value) => setState(() => _foliageColorController.text = value ?? ''),
            ),
          ),
        ],
      ),
      const SizedBox(height: 16),
      Row(
        children: [
          Expanded(
            child: TextFormField(
              controller: _diebackPercentController,
              decoration: const InputDecoration(labelText: 'Dieback %', border: OutlineInputBorder()),
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value != null && value.isNotEmpty) {
                  final num = double.tryParse(value);
                  if (num == null) return 'Must be a number';
                  if (num < 0 || num > 100) return 'Must be 0-100';
                }
                return null;
              },
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: DropdownButtonFormField<String>(
              value: _growthRateController.text.isEmpty ? null : _growthRateController.text,
              decoration: const InputDecoration(labelText: 'Growth Rate', border: OutlineInputBorder()),
              items: ['Vigorous', 'Normal', 'Slow', 'Stunted']
                  .map((v) => DropdownMenuItem(value: v, child: Text(v)))
                  .toList(),
              onChanged: (value) => setState(() => _growthRateController.text = value ?? ''),
            ),
          ),
        ],
      ),
      const SizedBox(height: 16),
      TextFormField(
        controller: _seasonalConditionController,
        decoration: const InputDecoration(labelText: 'Seasonal Condition', border: OutlineInputBorder()),
        maxLines: 2,
      ),
    ];
  }

  List<Widget> _buildStructureContent() {
    return [
      Row(
        children: [
          Expanded(
            child: DropdownButtonFormField<String>(
              value: _crownFormController.text.isEmpty ? null : _crownFormController.text,
              decoration: const InputDecoration(labelText: 'Crown Form', border: OutlineInputBorder()),
              items: ['Columnar', 'Pyramidal', 'Rounded', 'Spreading', 'Weeping', 'Irregular']
                  .map((v) => DropdownMenuItem(value: v, child: Text(v)))
                  .toList(),
              onChanged: (value) => setState(() => _crownFormController.text = value ?? ''),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: DropdownButtonFormField<String>(
              value: _crownDensityController.text.isEmpty ? null : _crownDensityController.text,
              decoration: const InputDecoration(labelText: 'Crown Density', border: OutlineInputBorder()),
              items: ['Dense', 'Moderate', 'Sparse']
                  .map((v) => DropdownMenuItem(value: v, child: Text(v)))
                  .toList(),
              onChanged: (value) => setState(() => _crownDensityController.text = value ?? ''),
            ),
          ),
        ],
      ),
      const SizedBox(height: 16),
      Row(
        children: [
          Expanded(
            child: DropdownButtonFormField<String>(
              value: _trunkFormController.text.isEmpty ? null : _trunkFormController.text,
              decoration: const InputDecoration(labelText: 'Trunk Form', border: OutlineInputBorder()),
              items: ['Single', 'Multi-stem', 'Co-dominant', 'Forked']
                  .map((v) => DropdownMenuItem(value: v, child: Text(v)))
                  .toList(),
              onChanged: (value) => setState(() => _trunkFormController.text = value ?? ''),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: DropdownButtonFormField<String>(
              value: _branchStructureController.text.isEmpty ? null : _branchStructureController.text,
              decoration: const InputDecoration(labelText: 'Branch Structure', border: OutlineInputBorder()),
              items: ['Excellent', 'Good', 'Fair', 'Poor', 'Critical']
                  .map((v) => DropdownMenuItem(value: v, child: Text(v)))
                  .toList(),
              onChanged: (value) => setState(() => _branchStructureController.text = value ?? ''),
            ),
          ),
        ],
      ),
      const SizedBox(height: 16),
      Row(
        children: [
          Expanded(
            child: DropdownButtonFormField<String>(
              value: _trunkLeanController.text.isEmpty ? null : _trunkLeanController.text,
              decoration: const InputDecoration(labelText: 'Trunk Lean', border: OutlineInputBorder()),
              items: ['None', 'Slight <15°', 'Moderate 15-30°', 'Severe >30°']
                  .map((v) => DropdownMenuItem(value: v, child: Text(v)))
                  .toList(),
              onChanged: (value) => setState(() => _trunkLeanController.text = value ?? ''),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: DropdownButtonFormField<String>(
              value: _leanDirectionController.text.isEmpty ? null : _leanDirectionController.text,
              decoration: const InputDecoration(labelText: 'Lean Direction', border: OutlineInputBorder()),
              items: ['N', 'NE', 'E', 'SE', 'S', 'SW', 'W', 'NW']
                  .map((v) => DropdownMenuItem(value: v, child: Text(v)))
                  .toList(),
              onChanged: (value) => setState(() => _leanDirectionController.text = value ?? ''),
            ),
          ),
        ],
      ),
      const SizedBox(height: 16),
      DropdownButtonFormField<String>(
        value: _rootPlateConditionController.text.isEmpty ? null : _rootPlateConditionController.text,
        decoration: const InputDecoration(labelText: 'Root Plate Condition', border: OutlineInputBorder()),
        items: ['Stable', 'Slight Lift', 'Moderate Lift', 'Severe Lift', 'Exposed']
            .map((v) => DropdownMenuItem(value: v, child: Text(v)))
            .toList(),
        onChanged: (value) => setState(() => _rootPlateConditionController.text = value ?? ''),
      ),
      const SizedBox(height: 16),
      CheckboxListTile(
        title: const Text('Buttress Roots Visible'),
        value: _buttressRoots,
        onChanged: (value) => setState(() => _buttressRoots = value!),
      ),
      CheckboxListTile(
        title: const Text('Surface Roots Present'),
        value: _surfaceRoots,
        onChanged: (value) => setState(() => _surfaceRoots = value!),
      ),
      CheckboxListTile(
        title: const Text('Included Bark Present'),
        value: _includedBark,
        onChanged: (value) => setState(() => _includedBark = value!),
      ),
      if (_includedBark) ...[
        const SizedBox(height: 8),
        TextFormField(
          controller: _includedBarkLocationController,
          decoration: const InputDecoration(labelText: 'Included Bark Location', border: OutlineInputBorder()),
        ),
      ],
      const SizedBox(height: 16),
      DropdownButtonFormField<String>(
        value: _structuralRatingController.text.isEmpty ? null : _structuralRatingController.text,
        decoration: const InputDecoration(labelText: 'Overall Structural Rating', border: OutlineInputBorder()),
        items: ['Excellent', 'Good', 'Fair', 'Poor', 'Failed']
            .map((v) => DropdownMenuItem(value: v, child: Text(v)))
            .toList(),
        onChanged: (value) => setState(() => _structuralRatingController.text = value ?? ''),
      ),
    ];
  }

  List<Widget> _buildVTAContent() {
    return [
      CheckboxListTile(
        title: const Text('Cavity Present'),
        value: _cavityPresent,
        onChanged: (value) => setState(() => _cavityPresent = value!),
      ),
      if (_cavityPresent) ...[
        const SizedBox(height: 12),
        DropdownButtonFormField<String>(
          value: _cavitySizeController.text.isEmpty ? null : _cavitySizeController.text,
          decoration: const InputDecoration(labelText: 'Cavity Size', border: OutlineInputBorder()),
          items: ['Small <10cm', 'Medium 10-30cm', 'Large >30cm', 'Very Large >50cm']
              .map((v) => DropdownMenuItem(value: v, child: Text(v)))
              .toList(),
          onChanged: (value) => setState(() => _cavitySizeController.text = value ?? ''),
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<String>(
          value: _cavityLocationController.text.isEmpty ? null : _cavityLocationController.text,
          decoration: const InputDecoration(labelText: 'Cavity Location', border: OutlineInputBorder()),
          items: ['Base', 'Lower Trunk', 'Mid Trunk', 'Upper Trunk', 'Branch Union', 'Branch']
              .map((v) => DropdownMenuItem(value: v, child: Text(v)))
              .toList(),
          onChanged: (value) => setState(() => _cavityLocationController.text = value ?? ''),
        ),
      ],
      const SizedBox(height: 16),
      Row(
        children: [
          Expanded(
            child: DropdownButtonFormField<String>(
              value: _decayExtentController.text.isEmpty ? null : _decayExtentController.text,
              decoration: const InputDecoration(labelText: 'Decay Extent', border: OutlineInputBorder()),
              items: ['None', 'Minor <25%', 'Moderate 25-50%', 'Extensive >50%', 'Severe >75%']
                  .map((v) => DropdownMenuItem(value: v, child: Text(v)))
                  .toList(),
              onChanged: (value) => setState(() => _decayExtentController.text = value ?? ''),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: DropdownButtonFormField<String>(
              value: _decayTypeController.text.isEmpty ? null : _decayTypeController.text,
              decoration: const InputDecoration(labelText: 'Decay Type', border: OutlineInputBorder()),
              items: ['White Rot', 'Brown Rot', 'Soft Rot', 'Unknown']
                  .map((v) => DropdownMenuItem(value: v, child: Text(v)))
                  .toList(),
              onChanged: (value) => setState(() => _decayTypeController.text = value ?? ''),
            ),
          ),
        ],
      ),
      const SizedBox(height: 16),
      CheckboxListTile(
        title: const Text('Fungal Fruiting Bodies Present'),
        value: _fungalFruitingBodies,
        onChanged: (value) => setState(() => _fungalFruitingBodies = value!),
      ),
      if (_fungalFruitingBodies) ...[
        const SizedBox(height: 12),
        TextFormField(
          controller: _fungalSpeciesController,
          decoration: const InputDecoration(
            labelText: 'Fungal Species (if known)',
            border: OutlineInputBorder(),
            hintText: 'e.g., Ganoderma, Armillaria',
          ),
        ),
      ],
      const SizedBox(height: 16),
      TextFormField(
        controller: _barkDamagePercentController,
        decoration: const InputDecoration(labelText: 'Bark Damage %', border: OutlineInputBorder()),
        keyboardType: TextInputType.number,
        validator: (value) {
          if (value != null && value.isNotEmpty) {
            final num = double.tryParse(value);
            if (num == null) return 'Must be a number';
            if (num < 0 || num > 100) return 'Must be 0-100';
          }
          return null;
        },
      ),
      const SizedBox(height: 16),
      CheckboxListTile(
        title: const Text('Cracks/Splits Present'),
        value: _cracksSplits,
        onChanged: (value) => setState(() => _cracksSplits = value!),
      ),
      if (_cracksSplits) ...[
        const SizedBox(height: 12),
        TextFormField(
          controller: _cracksSplitsLocationController,
          decoration: const InputDecoration(
            labelText: 'Cracks/Splits Location & Length',
            border: OutlineInputBorder(),
            hintText: 'e.g., Base, 2m vertical crack',
          ),
          maxLines: 2,
        ),
      ],
      const SizedBox(height: 16),
      TextFormField(
        controller: _deadWoodPercentController,
        decoration: const InputDecoration(labelText: 'Dead Wood %', border: OutlineInputBorder()),
        keyboardType: TextInputType.number,
        validator: (value) {
          if (value != null && value.isNotEmpty) {
            final num = double.tryParse(value);
            if (num == null) return 'Must be a number';
            if (num < 0 || num > 100) return 'Must be 0-100';
          }
          return null;
        },
      ),
      const SizedBox(height: 16),
      CheckboxListTile(
        title: const Text('Girdling Roots Present'),
        value: _girdlingRoots,
        onChanged: (value) => setState(() => _girdlingRoots = value!),
      ),
      if (_girdlingRoots) ...[
        const SizedBox(height: 12),
        DropdownButtonFormField<String>(
          value: _girdlingRootsSeverityController.text.isEmpty ? null : _girdlingRootsSeverityController.text,
          decoration: const InputDecoration(labelText: 'Severity', border: OutlineInputBorder()),
          items: ['Minor', 'Moderate', 'Severe', 'Critical']
              .map((v) => DropdownMenuItem(value: v, child: Text(v)))
              .toList(),
          onChanged: (value) => setState(() => _girdlingRootsSeverityController.text = value ?? ''),
        ),
      ],
      const SizedBox(height: 16),
      CheckboxListTile(
        title: const Text('Root Damage Present'),
        value: _rootDamage,
        onChanged: (value) => setState(() => _rootDamage = value!),
      ),
      if (_rootDamage) ...[
        const SizedBox(height: 12),
        TextFormField(
          controller: _rootDamageDescriptionController,
          decoration: const InputDecoration(
            labelText: 'Root Damage Description',
            border: OutlineInputBorder(),
            hintText: 'Describe type, extent, and location',
          ),
          maxLines: 3,
        ),
      ],
      const SizedBox(height: 16),
      CheckboxListTile(
        title: const Text('Mechanical Damage Present'),
        value: _mechanicalDamage,
        onChanged: (value) => setState(() => _mechanicalDamage = value!),
      ),
      if (_mechanicalDamage) ...[
        const SizedBox(height: 12),
        TextFormField(
          controller: _mechanicalDamageDescriptionController,
          decoration: const InputDecoration(
            labelText: 'Mechanical Damage Description',
            border: OutlineInputBorder(),
            hintText: 'Describe damage source and extent',
          ),
          maxLines: 3,
        ),
      ],
    ];
  }

  List<Widget> _buildQTRAContent() {
    return [
      DropdownButtonFormField<String>(
        value: _qtraTargetTypeController.text.isEmpty ? null : _qtraTargetTypeController.text,
        decoration: const InputDecoration(labelText: 'Target Type', border: OutlineInputBorder()),
        items: ['Pedestrian', 'Vehicle', 'Building', 'Service/Utility', 'Recreation Area', 'Property']
            .map((v) => DropdownMenuItem(value: v, child: Text(v)))
            .toList(),
        onChanged: (value) => setState(() => _qtraTargetTypeController.text = value ?? ''),
      ),
      const SizedBox(height: 16),
      Row(
        children: [
          Expanded(
            child: DropdownButtonFormField<String>(
              value: _qtraTargetValueController.text.isEmpty ? null : _qtraTargetValueController.text,
              decoration: const InputDecoration(labelText: 'Target Value', border: OutlineInputBorder()),
              items: ['Low', 'Medium', 'High', 'Very High']
                  .map((v) => DropdownMenuItem(value: v, child: Text(v)))
                  .toList(),
              onChanged: (value) => setState(() => _qtraTargetValueController.text = value ?? ''),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: DropdownButtonFormField<String>(
              value: _qtraOccupancyRateController.text.isEmpty ? null : _qtraOccupancyRateController.text,
              decoration: const InputDecoration(labelText: 'Occupancy Rate', border: OutlineInputBorder()),
              items: ['Rare', 'Occasional', 'Frequent', 'Constant']
                  .map((v) => DropdownMenuItem(value: v, child: Text(v)))
                  .toList(),
              onChanged: (value) => setState(() => _qtraOccupancyRateController.text = value ?? ''),
            ),
          ),
        ],
      ),
      const SizedBox(height: 16),
      DropdownButtonFormField<String>(
        value: _qtraImpactPotentialController.text.isEmpty ? null : _qtraImpactPotentialController.text,
        decoration: const InputDecoration(labelText: 'Impact Potential', border: OutlineInputBorder()),
        items: ['Whole Tree', 'Part of Tree', 'Branch', 'Limb', 'Twigs Only']
            .map((v) => DropdownMenuItem(value: v, child: Text(v)))
            .toList(),
        onChanged: (value) => setState(() => _qtraImpactPotentialController.text = value ?? ''),
      ),
      const SizedBox(height: 16),
      TextFormField(
        controller: _qtraProbabilityOfFailureController,
        decoration: const InputDecoration(
          labelText: 'Probability of Failure (1 in X years)',
          border: OutlineInputBorder(),
          hintText: 'e.g., 10000 for 1 in 10,000',
        ),
        keyboardType: TextInputType.number,
        onChanged: (value) => _calculateQTRARisk(),
      ),
      const SizedBox(height: 16),
      TextFormField(
        controller: _qtraProbabilityOfImpactController,
        decoration: const InputDecoration(
          labelText: 'Probability of Impact (0-1)',
          border: OutlineInputBorder(),
          hintText: 'e.g., 0.5 for 50%',
        ),
        keyboardType: TextInputType.number,
        onChanged: (value) => _calculateQTRARisk(),
      ),
      const SizedBox(height: 16),
      if (_qtraRiskOfHarm > 0) ...[
        Card(
          color: _qtraRiskRating == 'Unacceptable' ? Colors.red.shade50 :
                 _qtraRiskRating == 'Tolerable' ? Colors.orange.shade50 : Colors.green.shade50,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('QTRA Risk Assessment', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 8),
                Text('Risk of Harm: 1 in ${_qtraRiskOfHarm.toStringAsFixed(0)}'),
                const SizedBox(height: 4),
                Text('Risk Rating: $_qtraRiskRating', 
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: _qtraRiskRating == 'Unacceptable' ? Colors.red :
                           _qtraRiskRating == 'Tolerable' ? Colors.orange : Colors.green,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _qtraRiskRating == 'Unacceptable' ? '⚠️ Immediate action required' :
                  _qtraRiskRating == 'Tolerable' ? '⚡ Action required within timeframe' :
                  '✅ Risk broadly acceptable',
                  style: TextStyle(fontSize: 13, fontStyle: FontStyle.italic),
                ),
              ],
            ),
          ),
        ),
      ],
    ];
  }
  
  void _calculateQTRARisk() {
    final pof = double.tryParse(_qtraProbabilityOfFailureController.text) ?? 0;
    final poi = double.tryParse(_qtraProbabilityOfImpactController.text) ?? 0;
    
    if (pof > 0 && poi > 0) {
      setState(() {
        _qtraRiskOfHarm = pof / poi;
        
        // Determine risk rating based on QTRA thresholds
        if (_qtraRiskOfHarm < 10000) {
          _qtraRiskRating = 'Unacceptable';
        } else if (_qtraRiskOfHarm < 100000) {
          _qtraRiskRating = 'Tolerable';
        } else {
          _qtraRiskRating = 'Acceptable';
        }
      });
    }
  }

  List<Widget> _buildISARiskContent() {
    return [
      DropdownButtonFormField<String>(
        value: _likelihoodOfFailureController.text.isEmpty ? null : _likelihoodOfFailureController.text,
        decoration: const InputDecoration(labelText: 'Likelihood of Failure', border: OutlineInputBorder()),
        items: ['Imminent', 'Probable', 'Possible', 'Improbable']
            .map((v) => DropdownMenuItem(value: v, child: Text(v)))
            .toList(),
        onChanged: (value) => setState(() => _likelihoodOfFailureController.text = value ?? ''),
      ),
      const SizedBox(height: 16),
      DropdownButtonFormField<String>(
        value: _likelihoodOfImpactController.text.isEmpty ? null : _likelihoodOfImpactController.text,
        decoration: const InputDecoration(labelText: 'Likelihood of Impact', border: OutlineInputBorder()),
        items: ['Very High', 'High', 'Medium', 'Low']
            .map((v) => DropdownMenuItem(value: v, child: Text(v)))
            .toList(),
        onChanged: (value) => setState(() => _likelihoodOfImpactController.text = value ?? ''),
      ),
      const SizedBox(height: 16),
      DropdownButtonFormField<String>(
        value: _consequenceOfFailureController.text.isEmpty ? null : _consequenceOfFailureController.text,
        decoration: const InputDecoration(labelText: 'Consequence of Failure', border: OutlineInputBorder()),
        items: ['Severe', 'Significant', 'Minor', 'Negligible']
            .map((v) => DropdownMenuItem(value: v, child: Text(v)))
            .toList(),
        onChanged: (value) => setState(() => _consequenceOfFailureController.text = value ?? ''),
      ),
      const SizedBox(height: 16),
      DropdownButtonFormField<String>(
        value: _overallRiskRatingController.text.isEmpty ? null : _overallRiskRatingController.text,
        decoration: const InputDecoration(labelText: 'Overall Risk Rating', border: OutlineInputBorder()),
        items: ['Extreme', 'High', 'Moderate', 'Low']
            .map((v) => DropdownMenuItem(value: v, child: Text(v)))
            .toList(),
        onChanged: (value) => setState(() => _overallRiskRatingController.text = value ?? ''),
      ),
      const SizedBox(height: 16),
      TextFormField(
        controller: _vtaNotesController,
        decoration: const InputDecoration(labelText: 'VTA Notes', border: OutlineInputBorder()),
        maxLines: 3,
      ),
    ];
  }

  List<Widget> _buildProtectionZonesContent() {
    return [
      if (_srz > 0 || _nrz > 0) ...[
        Card(
          color: Colors.green.shade50,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Protection Zones', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 8),
                Text('SRZ (Structural Root Zone): ${_srz.toStringAsFixed(2)}m'),
                Text('NRZ/TPZ (Tree Protection Zone): ${_nrz.toStringAsFixed(2)}m'),
                Text('TPZ Area: ${(_nrz * _nrz * 3.14159).toStringAsFixed(2)}m²'),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
      ],
      Text('Enter DSH in Basic Tree Data to calculate protection zones automatically',
        style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
    ];
  }

  List<Widget> _buildImpactContent() {
    return [
      DropdownButtonFormField<String>(
        value: _developmentTypeController.text.isEmpty ? null : _developmentTypeController.text,
        decoration: const InputDecoration(labelText: 'Development Type', border: OutlineInputBorder()),
        items: ['Residential', 'Commercial', 'Industrial', 'Infrastructure', 'Subdivision', 'Renovation']
            .map((v) => DropdownMenuItem(value: v, child: Text(v)))
            .toList(),
        onChanged: (value) => setState(() => _developmentTypeController.text = value ?? ''),
      ),
      const SizedBox(height: 16),
      Row(
        children: [
          Expanded(
            child: TextFormField(
              controller: _constructionZoneDistanceController,
              decoration: const InputDecoration(labelText: 'Construction Distance (m)', border: OutlineInputBorder()),
              keyboardType: TextInputType.number,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: TextFormField(
              controller: _rootZoneEncroachmentController,
              decoration: const InputDecoration(labelText: 'Root Zone Encroachment %', border: OutlineInputBorder()),
              keyboardType: TextInputType.number,
            ),
          ),
        ],
      ),
      const SizedBox(height: 16),
      DropdownButtonFormField<String>(
        value: _excavationImpactController.text.isEmpty ? null : _excavationImpactController.text,
        decoration: const InputDecoration(labelText: 'Excavation Impact', border: OutlineInputBorder()),
        items: ['None', 'Minor', 'Moderate', 'Major', 'Severe']
            .map((v) => DropdownMenuItem(value: v, child: Text(v)))
            .toList(),
        onChanged: (value) => setState(() => _excavationImpactController.text = value ?? ''),
      ),
      const SizedBox(height: 16),
      CheckboxListTile(
        title: const Text('Service Installation Impact'),
        value: _serviceInstallationImpact,
        onChanged: (value) => setState(() => _serviceInstallationImpact = value!),
      ),
      if (_serviceInstallationImpact)
        TextFormField(
          controller: _serviceInstallationDescriptionController,
          decoration: const InputDecoration(labelText: 'Service Details', border: OutlineInputBorder()),
          maxLines: 2,
        ),
      const SizedBox(height: 16),
      TextFormField(
        controller: _mitigationMeasuresController,
        decoration: const InputDecoration(labelText: 'Mitigation Measures', border: OutlineInputBorder()),
        maxLines: 3,
      ),
    ];
  }

  List<Widget> _buildDevelopmentContent() {
    return [
      CheckboxListTile(
        title: const Text('Planning Permit Required'),
        value: _planningPermitRequired,
        onChanged: (value) => setState(() => _planningPermitRequired = value!),
      ),
      if (_planningPermitRequired) ...[
        TextFormField(
          controller: _planningPermitNumberController,
          decoration: const InputDecoration(labelText: 'Permit Number', border: OutlineInputBorder()),
        ),
        const SizedBox(height: 16),
        DropdownButtonFormField<String>(
          value: _planningPermitStatusController.text.isEmpty ? null : _planningPermitStatusController.text,
          decoration: const InputDecoration(labelText: 'Permit Status', border: OutlineInputBorder()),
          items: ['Not Applied', 'Applied', 'Approved', 'Refused', 'Appealed']
              .map((v) => DropdownMenuItem(value: v, child: Text(v)))
              .toList(),
          onChanged: (value) => setState(() => _planningPermitStatusController.text = value ?? ''),
        ),
      ],
      const SizedBox(height: 16),
      CheckboxListTile(
        title: const Text('Heritage Overlay'),
        value: _heritageOverlay,
        onChanged: (value) => setState(() => _heritageOverlay = value!),
      ),
      CheckboxListTile(
        title: const Text('Significant Landscape Overlay'),
        value: _significantLandscapeOverlay,
        onChanged: (value) => setState(() => _significantLandscapeOverlay = value!),
      ),
      CheckboxListTile(
        title: const Text('Vegetation Protection Overlay'),
        value: _vegetationProtectionOverlay,
        onChanged: (value) => setState(() => _vegetationProtectionOverlay = value!),
      ),
      CheckboxListTile(
        title: const Text('AS4970 Compliant'),
        value: _as4970Compliant,
        onChanged: (value) => setState(() => _as4970Compliant = value!),
      ),
    ];
  }

  List<Widget> _buildRetentionContent() {
    return [
      DropdownButtonFormField<String>(
        value: _retentionRecommendationController.text.isEmpty ? null : _retentionRecommendationController.text,
        decoration: const InputDecoration(labelText: 'Retention Recommendation', border: OutlineInputBorder()),
        items: ['Retain', 'Retain with Works', 'Remove', 'Monitor']
            .map((v) => DropdownMenuItem(value: v, child: Text(v)))
            .toList(),
        onChanged: (value) => setState(() => _retentionRecommendationController.text = value ?? ''),
      ),
      const SizedBox(height: 16),
      TextFormField(
        controller: _retentionJustificationController,
        decoration: const InputDecoration(labelText: 'Retention Justification', border: OutlineInputBorder()),
        maxLines: 3,
      ),
      const SizedBox(height: 16),
      TextFormField(
        controller: _removalJustificationController,
        decoration: const InputDecoration(labelText: 'Removal Justification', border: OutlineInputBorder()),
        maxLines: 3,
      ),
      const SizedBox(height: 16),
      CheckboxListTile(
        title: const Text('Replanting Required'),
        value: _replantingRequired,
        onChanged: (value) => setState(() => _replantingRequired = value!),
      ),
      if (_replantingRequired)
        TextFormField(
          controller: _replacementRatioController,
          decoration: const InputDecoration(labelText: 'Replacement Ratio (e.g., 2:1)', border: OutlineInputBorder()),
        ),
    ];
  }

  List<Widget> _buildManagementContent() {
    return [
      DropdownButtonFormField<String>(
        value: _worksPriorityController.text.isEmpty ? null : _worksPriorityController.text,
        decoration: const InputDecoration(labelText: 'Works Priority', border: OutlineInputBorder()),
        items: ['Urgent', 'High', 'Medium', 'Low', 'Monitor']
            .map((v) => DropdownMenuItem(value: v, child: Text(v)))
            .toList(),
        onChanged: (value) => setState(() => _worksPriorityController.text = value ?? ''),
      ),
      const SizedBox(height: 16),
      DropdownButtonFormField<String>(
        value: _worksTimeframeController.text.isEmpty ? null : _worksTimeframeController.text,
        decoration: const InputDecoration(labelText: 'Works Timeframe', border: OutlineInputBorder()),
        items: ['Immediate', '1-3 months', '3-6 months', '6-12 months', '1-2 years']
            .map((v) => DropdownMenuItem(value: v, child: Text(v)))
            .toList(),
        onChanged: (value) => setState(() => _worksTimeframeController.text = value ?? ''),
      ),
      const SizedBox(height: 16),
      TextFormField(
        controller: _pruningSpecificationController,
        decoration: const InputDecoration(labelText: 'Pruning Specification (AS4373)', border: OutlineInputBorder()),
        maxLines: 3,
      ),
      const SizedBox(height: 16),
      TextFormField(
        controller: _estimatedCostRangeController,
        decoration: const InputDecoration(labelText: 'Estimated Cost Range', border: OutlineInputBorder()),
      ),
      const SizedBox(height: 16),
      CheckboxListTile(
        title: const Text('Arborist Supervision Required'),
        value: _arboristSupervisionRequired,
        onChanged: (value) => setState(() => _arboristSupervisionRequired = value!),
      ),
    ];
  }

  List<Widget> _buildValuationContent() {
    return [
      DropdownButtonFormField<String>(
        value: _valuationMethodController.text.isEmpty ? null : _valuationMethodController.text,
        decoration: const InputDecoration(labelText: 'Valuation Method', border: OutlineInputBorder()),
        items: ['CTLA', 'Helliwell', 'Burnley', 'CAVAT', 'i-Tree']
            .map((v) => DropdownMenuItem(value: v, child: Text(v)))
            .toList(),
        onChanged: (value) => setState(() => _valuationMethodController.text = value ?? ''),
      ),
      const SizedBox(height: 16),
      TextFormField(
        controller: _baseValueController,
        decoration: const InputDecoration(labelText: 'Base Value (\$)', border: OutlineInputBorder()),
        keyboardType: TextInputType.number,
        onChanged: (value) => _calculateTotalValuation(),
      ),
      const SizedBox(height: 16),
      Row(
        children: [
          Expanded(
            child: TextFormField(
              controller: _conditionFactorController,
              decoration: const InputDecoration(labelText: 'Condition Factor (0-1)', border: OutlineInputBorder()),
              keyboardType: TextInputType.number,
              onChanged: (value) => _calculateTotalValuation(),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: TextFormField(
              controller: _locationFactorController,
              decoration: const InputDecoration(labelText: 'Location Factor (0-1)', border: OutlineInputBorder()),
              keyboardType: TextInputType.number,
              onChanged: (value) => _calculateTotalValuation(),
            ),
          ),
        ],
      ),
      const SizedBox(height: 16),
      if (_totalValuation > 0) ...[
        Card(
          color: Colors.green.shade50,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Total Valuation', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 8),
                Text('\$${_totalValuation.toStringAsFixed(2)}', 
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.green.shade700)),
              ],
            ),
          ),
        ),
      ],
    ];
  }
  
  void _calculateTotalValuation() {
    final base = double.tryParse(_baseValueController.text) ?? 0;
    final condition = double.tryParse(_conditionFactorController.text) ?? 0;
    final location = double.tryParse(_locationFactorController.text) ?? 0;
    
    if (base > 0 && condition > 0 && location > 0) {
      setState(() {
        _totalValuation = base * condition * location;
      });
    }
  }

  List<Widget> _buildEcologicalContent() {
    return [
      DropdownButtonFormField<String>(
        value: _wildlifeHabitatValueController.text.isEmpty ? null : _wildlifeHabitatValueController.text,
        decoration: const InputDecoration(labelText: 'Wildlife Habitat Value', border: OutlineInputBorder()),
        items: ['Very High', 'High', 'Medium', 'Low', 'Negligible']
            .map((v) => DropdownMenuItem(value: v, child: Text(v)))
            .toList(),
        onChanged: (value) => setState(() => _wildlifeHabitatValueController.text = value ?? ''),
      ),
      const SizedBox(height: 16),
      CheckboxListTile(
        title: const Text('Hollow-Bearing Tree'),
        value: _hollowBearingTree,
        onChanged: (value) => setState(() => _hollowBearingTree = value!),
      ),
      CheckboxListTile(
        title: const Text('Nesting Sites Present'),
        value: _nestingSites,
        onChanged: (value) => setState(() => _nestingSites = value!),
      ),
      if (_nestingSites)
        TextFormField(
          controller: _nestingSpeciesController,
          decoration: const InputDecoration(labelText: 'Nesting Species', border: OutlineInputBorder()),
        ),
      const SizedBox(height: 16),
      CheckboxListTile(
        title: const Text('Indigenous Significance'),
        value: _indigenousSignificance,
        onChanged: (value) => setState(() => _indigenousSignificance = value!),
      ),
      if (_indigenousSignificance)
        TextFormField(
          controller: _indigenousSignificanceDetailsController,
          decoration: const InputDecoration(labelText: 'Significance Details', border: OutlineInputBorder()),
          maxLines: 2,
        ),
    ];
  }

  List<Widget> _buildRegulatoryContent() {
    return [
      CheckboxListTile(
        title: const Text('State Significant Tree'),
        value: _stateSignificant,
        onChanged: (value) => setState(() => _stateSignificant = value!),
      ),
      CheckboxListTile(
        title: const Text('Heritage Listed'),
        value: _heritageListed,
        onChanged: (value) => setState(() => _heritageListed = value!),
      ),
      if (_heritageListed)
        TextFormField(
          controller: _heritageReferenceController,
          decoration: const InputDecoration(labelText: 'Heritage Reference', border: OutlineInputBorder()),
        ),
      const SizedBox(height: 16),
      CheckboxListTile(
        title: const Text('Significant Tree Register'),
        value: _significantTreeRegister,
        onChanged: (value) => setState(() => _significantTreeRegister = value!),
      ),
      CheckboxListTile(
        title: const Text('Threatened Species Habitat'),
        value: _threatenedSpeciesHabitat,
        onChanged: (value) => setState(() => _threatenedSpeciesHabitat = value!),
      ),
      CheckboxListTile(
        title: const Text('Insurance Notification Required'),
        value: _insuranceNotificationRequired,
        onChanged: (value) => setState(() => _insuranceNotificationRequired = value!),
      ),
    ];
  }

  List<Widget> _buildMonitoringContent() {
    return [
      DropdownButtonFormField<String>(
        value: _inspectionFrequencyController.text.isEmpty ? null : _inspectionFrequencyController.text,
        decoration: const InputDecoration(labelText: 'Inspection Frequency', border: OutlineInputBorder()),
        items: ['3 months', '6 months', '12 months', '2 years', '5 years']
            .map((v) => DropdownMenuItem(value: v, child: Text(v)))
            .toList(),
        onChanged: (value) => setState(() => _inspectionFrequencyController.text = value ?? ''),
      ),
      const SizedBox(height: 16),
      CheckboxListTile(
        title: const Text('Monitoring Required'),
        value: _monitoringRequired,
        onChanged: (value) => setState(() => _monitoringRequired = value!),
      ),
      const SizedBox(height: 16),
      DropdownButtonFormField<String>(
        value: _alertLevelController.text.isEmpty ? null : _alertLevelController.text,
        decoration: const InputDecoration(labelText: 'Alert Level', border: OutlineInputBorder()),
        items: ['None', 'Watch', 'Caution', 'Urgent', 'Critical']
            .map((v) => DropdownMenuItem(value: v, child: Text(v)))
            .toList(),
        onChanged: (value) => setState(() => _alertLevelController.text = value ?? ''),
      ),
      const SizedBox(height: 16),
      TextFormField(
        controller: _followUpActionsController,
        decoration: const InputDecoration(labelText: 'Follow-up Actions', border: OutlineInputBorder()),
        maxLines: 3,
      ),
    ];
  }

  List<Widget> _buildDiagnosticsContent() {
    return [
      CheckboxListTile(
        title: const Text('Resistograph Test Conducted'),
        value: _resistographTest,
        onChanged: (value) => setState(() => _resistographTest = value!),
      ),
      if (_resistographTest)
        TextFormField(
          controller: _resistographResultsController,
          decoration: const InputDecoration(labelText: 'Resistograph Results', border: OutlineInputBorder()),
          maxLines: 2,
        ),
      const SizedBox(height: 16),
      CheckboxListTile(
        title: const Text('Sonic Tomography Conducted'),
        value: _sonicTomography,
        onChanged: (value) => setState(() => _sonicTomography = value!),
      ),
      if (_sonicTomography)
        TextFormField(
          controller: _sonicTomographyResultsController,
          decoration: const InputDecoration(labelText: 'Tomography Results', border: OutlineInputBorder()),
          maxLines: 2,
        ),
      const SizedBox(height: 16),
      CheckboxListTile(
        title: const Text('Pulling Test Conducted'),
        value: _pullingTest,
        onChanged: (value) => setState(() => _pullingTest = value!),
      ),
      if (_pullingTest)
        TextFormField(
          controller: _pullingTestResultsController,
          decoration: const InputDecoration(labelText: 'Pulling Test Results', border: OutlineInputBorder()),
          maxLines: 2,
        ),
      const SizedBox(height: 16),
      TextFormField(
        controller: _specialistConsultantController,
        decoration: const InputDecoration(labelText: 'Specialist Consultant', border: OutlineInputBorder()),
      ),
      const SizedBox(height: 16),
      TextFormField(
        controller: _diagnosticSummaryController,
        decoration: const InputDecoration(labelText: 'Diagnostic Summary', border: OutlineInputBorder()),
        maxLines: 4,
      ),
    ];
  }

  List<Widget> _buildInspectorContent() {
    return [
      TextFormField(
        controller: _inspectorNameController,
        decoration: const InputDecoration(labelText: 'Inspector Name', border: OutlineInputBorder()),
      ),
      const SizedBox(height: 16),
      Text('Inspection Date: ${DateTime.now().toString().split(' ')[0]}',
        style: const TextStyle(fontSize: 14)),
    ];
  }
  
  // Duplicate _buildPhotosContent removed - using the one defined earlier
  /*List<Widget> _buildPhotosContent() {
    return [
      Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(8),
          color: Colors.grey.shade50,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.photo_camera, color: Colors.blue),
                const SizedBox(width: 8),
                const Text(
                  'Tree Photos',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                Text(
                  '${_imageLocalPaths.length}/4 photos',
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Text(
              'Add up to 4 photos for the report:',
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
            const SizedBox(height: 8),
            // Photo categories for reports
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildPhotoButton('Canopy View', Icons.park, 0),
                _buildPhotoButton('Base/Trunk', Icons.nature, 1),
                _buildPhotoButton('Context/Site', Icons.landscape, 2),
                _buildPhotoButton('Defects/Issues', Icons.warning, 3),
              ],
            ),
            const SizedBox(height: 12),
            // Display selected images
            if (_imageLocalPaths.isNotEmpty) ...[
              const Divider(),
              const SizedBox(height: 8),
              SizedBox(
                height: 100,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _imageLocalPaths.length,
                  itemBuilder: (context, index) {
                    return Container(
                      margin: const EdgeInsets.only(right: 8),
                      width: 100,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: Stack(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: kIsWeb
                                ? Image.network(
                                    _imageLocalPaths[index],
                                    fit: BoxFit.cover,
                                    width: 100,
                                    height: 100,
                                    errorBuilder: (context, error, stackTrace) {
                                      return Container(
                                        color: Colors.grey.shade200,
                                        child: const Icon(Icons.image, color: Colors.grey),
                                      );
                                    },
                                  )
                                : Image.file(
                                    File(_imageLocalPaths[index]),
                                    fit: BoxFit.cover,
                                    width: 100,
                                    height: 100,
                                    errorBuilder: (context, error, stackTrace) {
                                      return Container(
                                        color: Colors.grey.shade200,
                                        child: const Icon(Icons.image, color: Colors.grey),
                                      );
                                    },
                                  ),
                          ),
                          Positioned(
                            top: 4,
                            right: 4,
                            child: GestureDetector(
                              onTap: () => _removeImage(index),
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color: Colors.red,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.close,
                                  size: 16,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ],
        ),
      ),
    ];
  }*/
  
  // Duplicate _buildPhotoButton removed - using the one defined earlier
  /*Widget _buildPhotoButton(String label, IconData icon, int index) {
    final hasPhoto = _imageLocalPaths.length > index;
    return ElevatedButton.icon(
      onPressed: () => _pickImage(index),
      icon: Icon(hasPhoto ? Icons.check_circle : icon, size: 20),
      label: Text(label, style: const TextStyle(fontSize: 12)),
      style: ElevatedButton.styleFrom(
        backgroundColor: hasPhoto ? Colors.green : Colors.blue,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
    );
  }*/
  
  /*Future<void> _pickImage(int index) async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );
      
      if (image != null) {
        setState(() {
          if (index < _imageLocalPaths.length) {
            _imageLocalPaths[index] = image.path;
          } else {
            _imageLocalPaths.add(image.path);
          }
        });
        NotificationService.showSuccess(context, 'Photo added successfully');
      }
    } catch (e) {
      NotificationService.showError(context, 'Failed to pick image: $e');
    }
  }*/
  
  /*void _removeImage(int index) {
    setState(() {
      _imageLocalPaths.removeAt(index);
    });
  }*/
  
  /*List<Widget> _buildVoiceNotesContent() {
    // Return the voice notes section we already built
    return [
      Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(8),
          color: Colors.grey.shade50,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.notes, color: Colors.green),
                const SizedBox(width: 8),
                const Text(
                  'Notes & Voice Recording',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                if (_isRecording)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: const [
                        Icon(Icons.fiber_manual_record, color: Colors.white, size: 12),
                        SizedBox(width: 4),
                        Text('Recording', style: TextStyle(color: Colors.white, fontSize: 12)),
                      ],
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _notesController,
              decoration: const InputDecoration(
                labelText: 'Notes',
                hintText: 'Enter detailed notes about this tree...',
                border: OutlineInputBorder(),
              ),
              maxLines: 5,
              minLines: 3,
            ),
            const SizedBox(height: 12),
            // Voice recording controls
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isRecording ? _stopRecording : _startRecording,
                    icon: Icon(_isRecording ? Icons.stop : Icons.mic),
                    label: Text(_isRecording ? 'Stop Recording' : 'Start Voice Recording'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _isRecording ? Colors.red : Colors.blue,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
                if (_hasRecording) ...[
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: _playRecording,
                    icon: const Icon(Icons.play_arrow),
                    tooltip: 'Play Recording',
                    color: Colors.green,
                  ),
                  IconButton(
                    onPressed: _deleteRecording,
                    icon: const Icon(Icons.delete),
                    tooltip: 'Delete Recording',
                    color: Colors.red,
                  ),
                ],
              ],
            ),
            if (_isTranscribing)
              const Padding(
                padding: EdgeInsets.only(top: 8),
                child: LinearProgressIndicator(),
              ),
            if (_transcriptionText.isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.transcribe, size: 16, color: Colors.blue),
                        const SizedBox(width: 4),
                        const Text(
                          'Transcription:',
                          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue),
                        ),
                        const Spacer(),
                        TextButton.icon(
                          onPressed: _addTranscriptionToNotes,
                          icon: const Icon(Icons.add, size: 16),
                          label: const Text('Add to Notes'),
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _transcriptionText,
                      style: const TextStyle(fontSize: 14),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    ];
  }*/

  List<Widget> _buildPlaceholder(String title) {
    return [
      Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.blue.shade50,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.blue.shade200),
        ),
        child: Column(
          children: [
            Icon(Icons.construction, size: 48, color: Colors.blue.shade300),
            const SizedBox(height: 12),
            Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.blue.shade700,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Fields coming in Phase 2 & 3',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
            ),
          ],
        ),
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.initialEntry != null ? 'Edit Tree' : 'Add New Tree'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        actions: [
          // Offline indicator
          if (_isOffline)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              margin: const EdgeInsets.only(right: 8),
              decoration: BoxDecoration(
                color: Colors.orange,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.cloud_off, color: Colors.white, size: 16),
                  SizedBox(width: 4),
                  Text(
                    'OFFLINE',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: ResponsiveHelper.getScaledPadding(context, const EdgeInsets.all(16)),
          children: [
            // Show info banner if using site preferences
            if (widget.initialEntry == null && 
                widget.siteId != null && 
                widget.siteId!.isNotEmpty &&
                AppStateService.hasSitePreferences(widget.siteId!))
              Container(
                margin: EdgeInsets.only(bottom: ResponsiveHelper.getScaledValue(context, 16)),
                padding: ResponsiveHelper.getScaledPadding(context, const EdgeInsets.all(12)),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  border: Border.all(color: Colors.blue.shade200),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.blue.shade700, size: ResponsiveHelper.getScaledValue(context, 20)),
                    SizedBox(width: ResponsiveHelper.getScaledValue(context, 8)),
                    Expanded(
                      child: Text(
                        'Using export preferences from previous trees on this site',
                        style: TextStyle(
                          color: Colors.blue.shade900,
                          fontSize: ResponsiveHelper.getScaledFontSize(context, 13),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ...TreeFormGroups.buildAllGroups(
              exportGroups: _exportGroups,
              expandedGroups: _expandedGroups,
              onGroupToggle: (key, value) {
                setState(() => _exportGroups[key] = value);
              },
              onExpandToggle: (key) {
                setState(() => _expandedGroups[key] = !_expandedGroups[key]!);
              },
              relevantGroups: _getRelevantGroupsForReportType(), // Filter based on report type
              groupContent: {
                'photos': _buildPhotosContent(),
                'voice_notes': _buildVoiceNotesContent(),
                'location': _buildLocationContent(),
                'basic_data': _buildBasicDataContent(),
                'health': _buildHealthContent(),
                'structure': _buildStructureContent(),
                'vta': _buildVTAContent(),
                'qtra': _buildQTRAContent(),
                'isa_risk': _buildISARiskContent(),
                'protection_zones': _buildProtectionZonesContent(),
                'impact_assessment': _buildImpactContent(),
                'development': _buildDevelopmentContent(),
                'retention_removal': _buildRetentionContent(),
                'management': _buildManagementContent(),
                'valuation': _buildValuationContent(),
                'ecological': _buildEcologicalContent(),
                'regulatory': _buildRegulatoryContent(),
                'monitoring': _buildMonitoringContent(),
                'diagnostics': _buildDiagnosticsContent(),
                'inspector_details': _buildInspectorContent(),
              },
            ),
            SizedBox(height: ResponsiveHelper.getScaledValue(context, 32)),
            // Save button
            ElevatedButton(
              onPressed: _saveTree,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                padding: ResponsiveHelper.getScaledPadding(context, const EdgeInsets.symmetric(vertical: 16)),
              ),
              child: Text(
                'Save Tree',
                style: TextStyle(
                  fontSize: ResponsiveHelper.getScaledFontSize(context, 18), 
                  fontWeight: FontWeight.bold
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
