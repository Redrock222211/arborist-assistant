import 'package:flutter/material.dart';
import 'dart:async';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../models/tree_entry.dart';
import '../models/site.dart';
import '../widgets/tree_form.dart';
import 'report_type_selector.dart';
import '../services/tree_storage_service.dart';
import 'dart:ui' as ui;
import 'dart:typed_data';
import 'dart:math';
import 'package:flutter/rendering.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:share_plus/share_plus.dart';
import 'package:hive/hive.dart';
import 'package:just_audio/just_audio.dart';
import 'package:geolocator/geolocator.dart';
import '../widgets/tree_image_gallery.dart';
import '../services/app_state_service.dart';
import '../pages/isa_report_page.dart';
import '../services/notification_service.dart';
import '../pages/tree_list_page.dart';

class MapPage extends StatefulWidget {
  final Site site;
  final double? initialLatitude;
  final double? initialLongitude;
  final Site? selectedSite;
  
  const MapPage({
    super.key, 
    required this.site,
    this.initialLatitude,
    this.initialLongitude,
    this.selectedSite,
  });

  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  final List<TreeEntry> _treeEntries = [];
  final List<Marker> _markers = [];
  final List<CircleMarker> _srzCircles = [];
  final List<CircleMarker> _nrzCircles = [];

  bool _showSRZ = false;
  bool _showNRZ = false;
  bool _addTreeMode = false;
  bool _viewTreeMode = false;
  bool _satelliteView = true;
  bool _mapReady = false;
  bool _locating = false;
  bool _trackingGPS = false;  // GPS tracking mode
  Position? _currentPosition;  // Current GPS position
  StreamSubscription<Position>? _positionStream;  // GPS position stream
  Timer? _updateTimer;

  // Search and filter
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _filterCondition = 'All';
  String _filterSpecies = 'All';
  double _filterMinHeight = 0;
  double _filterMaxHeight = 100;

  final MapController _mapController = MapController();
  int _mapRefreshCounter = 0;
  StreamSubscription<MapEvent>? _mapMoveSub;

  // Default center (generic coordinates)
  LatLng _center = LatLng(0.0, 0.0);
  double _zoom = 15.0;

  // Available filter options
  final List<String> _conditionOptions = ['All', 'Excellent', 'Good', 'Fair', 'Poor', 'Critical'];
  final List<String> _speciesOptions = ['All'];

  @override
  void initState() {
    super.initState();
    _loadMapPosition();
    _loadTrees();
    _loadCircleVisibility();
    _updateSpeciesOptions();
    _checkLocationPermission();  // Check GPS permission on init

    // Persist map view on move end
    _mapMoveSub = _mapController.mapEventStream.listen((event) {
      if (event is MapEventMoveEnd) {
        try {
          //           final center = _mapController.center;
          //           final zoom = _mapController.zoom;
          //           AppStateService.saveMapPosition(center, zoom);
        } catch (_) {}
      }
    });
  }

  @override
  void didUpdateWidget(MapPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.site.id != widget.site.id) {
      _loadMapPosition(); // Reload map position for new site
      _loadTrees();
      _updateSpeciesOptions();
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Don't call _loadTrees() here to avoid duplicate calls
    // Trees will be loaded when the page is first created
  }

  @override
  void dispose() {
    _searchController.dispose();
    _updateTimer?.cancel();
    _mapMoveSub?.cancel();
    _positionStream?.cancel();  // Cancel GPS tracking
    super.dispose();
  }

  void _updateSpeciesOptions() {
    final species = _treeEntries.map((t) => t.species).where((s) => s.isNotEmpty).toSet().toList();
    species.sort();
    setState(() {
      _speciesOptions.clear();
      _speciesOptions.add('All');
      _speciesOptions.addAll(species);
    });
  }



  // Enhanced search and filter methods
  List<TreeEntry> get _filteredTrees {
    return _treeEntries.where((tree) {
      // Search filter
      if (_searchQuery.isNotEmpty) {
        final query = _searchQuery.toLowerCase();
        final matchesSearch = tree.id.toLowerCase().contains(query) ||
            (tree.species?.toLowerCase().contains(query) ?? false) ||
            tree.condition.toLowerCase().contains(query);
        if (!matchesSearch) return false;
      }

      // Condition filter
      if (_filterCondition != 'All' && tree.condition != _filterCondition) {
        return false;
      }

      // Species filter
      if (_filterSpecies != 'All' && tree.species != _filterSpecies) {
        return false;
      }

      // Height filter
      if (tree.height < _filterMinHeight || tree.height > _filterMaxHeight) {
        return false;
      }

      return true;
    }).toList();
  }

  // Marker cache removed to ensure fresh tree data on updates
  
  void _updateMarkers() {
    final filteredTrees = _filteredTrees;
    final newMarkers = <Marker>[];
    
    for (final tree in filteredTrees) {
      if (tree.latitude != 0 && tree.longitude != 0) {
        // Create a new marker each time to ensure fresh tree data
        // This ensures that when tree properties change, the marker reflects the updates
        final marker = Marker(
          point: LatLng(tree.latitude, tree.longitude),
          width: 32, // Smaller size for better performance
          height: 32,
          child: GestureDetector(
            onTap: () => _showTreeInfo(tree),
            child: Container(
              decoration: BoxDecoration(
                color: _getConditionColor(tree.condition),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.3),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Icon(
                _getTreeIcon(tree.condition),
                color: Colors.white,
                size: 16,
              ),
            ),
          ),
        );
        
        newMarkers.add(marker);
      }
    }

    // Always update markers to ensure fresh data
    setState(() {
      _markers.clear();
      _markers.addAll(newMarkers);
    });
  }
  

  
  // Get appropriate icon based on tree condition
  IconData _getTreeIcon(String condition) {
    switch (condition.toLowerCase()) {
      case 'excellent':
        return Icons.eco;
      case 'good':
        return Icons.forest;
      case 'fair':
        return Icons.park;
      case 'poor':
        return Icons.warning;
      case 'critical':
        return Icons.error;
      default:
        return Icons.park;
    }
  }

  void _showSearchDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Search Trees'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                labelText: 'Search by ID, species, or condition',
                prefixIcon: Icon(Icons.search),
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                  _updateMarkers();
                });
              },
            ),
            const SizedBox(height: 16),
            Text('Found ${_filteredTrees.length} trees'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              _searchController.clear();
              setState(() {
                _searchQuery = '';
                _updateMarkers();
              });
              Navigator.pop(context);
            },
            child: const Text('Clear'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Filter Trees'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Condition filter
              DropdownButtonFormField<String>(
                value: _filterCondition,
                decoration: const InputDecoration(
                  labelText: 'Condition',
                  prefixIcon: Icon(Icons.health_and_safety),
                ),
                items: _conditionOptions.map((condition) => 
                  DropdownMenuItem(value: condition, child: Text(condition))
                ).toList(),
                onChanged: (value) {
                  setDialogState(() {
                    _filterCondition = value!;
                  });
                  setState(() {
                    _filterCondition = value!;
                    _updateMarkers();
                  });
                },
              ),
              const SizedBox(height: 16),
              
              // Species filter
              DropdownButtonFormField<String>(
                value: _filterSpecies,
                decoration: const InputDecoration(
                  labelText: 'Species',
                  prefixIcon: Icon(Icons.eco),
                ),
                items: _speciesOptions.map((species) => 
                  DropdownMenuItem(value: species, child: Text(species))
                ).toList(),
                onChanged: (value) {
                  setDialogState(() {
                    _filterSpecies = value!;
                  });
                  setState(() {
                    _filterSpecies = value!;
                    _updateMarkers();
                  });
                },
              ),
              const SizedBox(height: 16),
              
              // Height range filter
              Text('Height Range: ${_filterMinHeight.toInt()} - ${_filterMaxHeight.toInt()}m'),
              RangeSlider(
                values: RangeValues(_filterMinHeight, _filterMaxHeight),
                min: 0,
                max: 100,
                divisions: 100,
                labels: RangeLabels(
                  _filterMinHeight.toInt().toString(),
                  _filterMaxHeight.toInt().toString(),
                ),
                onChanged: (values) {
                  setDialogState(() {
                    _filterMinHeight = values.start;
                    _filterMaxHeight = values.end;
                  });
                  setState(() {
                    _filterMinHeight = values.start;
                    _filterMaxHeight = values.end;
                    _updateMarkers();
                  });
                },
              ),
              const SizedBox(height: 16),
              
              Text('Showing ${_filteredTrees.length} of ${_treeEntries.length} trees'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                setState(() {
                  _filterCondition = 'All';
                  _filterSpecies = 'All';
                  _filterMinHeight = 0;
                  _filterMaxHeight = 100;
                  _updateMarkers();
                });
                Navigator.pop(context);
              },
              child: const Text('Reset'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ],
        ),
      ),
    );
  }

  void _showTreeInfo(TreeEntry entry) {
    final audioPlayer = AudioPlayer();
    void _deleteImage(int idx) async {
      final isCloud = idx >= entry.imageLocalPaths.length;
      final newPhotoPaths = List<String>.from(entry.imageLocalPaths);
      final newPhotoUrls = List<String>.from(entry.imageUrls);
      if (isCloud) {
        newPhotoUrls.removeAt(idx - entry.imageLocalPaths.length);
      } else {
        newPhotoPaths.removeAt(idx);
      }
      // Save updated entry
      final box = Hive.box<TreeEntry>(TreeStorageService.boxName);
      final key = box.keys.firstWhere((k) => box.get(k) == entry, orElse: () => null);
      if (key != null) {
        final updated = TreeEntry(
          id: entry.id,
          species: entry.species,
          dsh: entry.dsh,
          height: entry.height,
          condition: entry.condition,
          comments: entry.comments,
          permitRequired: entry.permitRequired,
          latitude: entry.latitude,
          longitude: entry.longitude,
          srz: entry.srz,
          nrz: entry.nrz,
          ageClass: entry.ageClass,
          retentionValue: entry.retentionValue,
          riskRating: entry.riskRating,
          locationDescription: entry.locationDescription,
          habitatValue: entry.habitatValue,
          recommendedWorks: entry.recommendedWorks,
          healthForm: entry.healthForm,
          diseasesPresent: entry.diseasesPresent,
          canopySpread: entry.canopySpread,
          clearanceToStructures: entry.clearanceToStructures,
          origin: entry.origin,
          // significance: entry.significance, // Removed field
          pastManagement: entry.pastManagement,
          pestPresence: entry.pestPresence,
          notes: entry.notes,
          // retentionJustification: entry.retentionJustification, // Removed field
          // removalJustification: entry.removalJustification, // Removed field
          // treeTag: entry.treeTag, // Removed field
          siteId: entry.siteId,
          targetOccupancy: entry.targetOccupancy,
          defectsObserved: entry.defectsObserved,
          likelihoodOfFailure: entry.likelihoodOfFailure,
          likelihoodOfImpact: entry.likelihoodOfImpact,
          consequenceOfFailure: entry.consequenceOfFailure,
          overallRiskRating: entry.overallRiskRating,
          vtaNotes: entry.vtaNotes,
          vtaDefects: entry.vtaDefects,
          inspectionDate: entry.inspectionDate,
          inspectorName: entry.inspectorName,
          voiceNotes: entry.voiceNotes,
          voiceNoteAudioPath: entry.voiceNoteAudioPath,
          voiceAudioUrl: entry.voiceAudioUrl,
          imageLocalPaths: newPhotoPaths,
          imageUrls: newPhotoUrls,
        );
        await TreeStorageService.updateTree(key, updated);
        _loadTrees();
      }
      if (mounted) setState(() {});
    }
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                                     Text(entry.id, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.edit, color: Colors.blue),
                    onPressed: () async {
                      Navigator.of(context).pop();
                      await showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        builder: (context) {
                          return Padding(
                            padding: EdgeInsets.only(
                              bottom: MediaQuery.of(context).viewInsets.bottom,
                              left: 16,
                              right: 16,
                              top: 16,
                            ),
                            child: TreeForm(
                              siteId: widget.site.id,
                              initialEntry: entry,
                              reportType: widget.site.reportType,
                              onSubmit: (updatedEntry) async {
                                final box = Hive.box<TreeEntry>(TreeStorageService.boxName);
                                final key = box.keys.firstWhere((k) => box.get(k) == entry, orElse: () => null);
                                if (key != null) {
                                  await TreeStorageService.updateTree(key, updatedEntry);
                                  _loadTrees();
                                }
                                Navigator.of(context).pop();
                              },
                            ),
                          );
                        },
                      );
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () async {
                      final box = Hive.box<TreeEntry>(TreeStorageService.boxName);
                      final key = box.keys.firstWhere((k) => box.get(k) == entry, orElse: () => null);
                      if (key != null) {
                        await TreeStorageService.deleteTree(key);
                        _loadTrees();
                      }
                      Navigator.of(context).pop();
                    },
                  ),
                ],
              ),
              const Divider(),
              if ((entry.imageLocalPaths.isNotEmpty || entry.imageUrls.isNotEmpty))
                SizedBox(
                  height: 80,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: [
                      ...entry.imageLocalPaths.asMap().entries.map((e) => GestureDetector(
                            onTap: () => showDialog(
                              context: context,
                              builder: (context) => TreeImageGallery(
                                images: [...entry.imageLocalPaths, ...entry.imageUrls],
                                onDelete: _deleteImage,
                                initialIndex: e.key,
                              ),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(4),
                              child: Image.file(File(e.value), width: 64, height: 64, fit: BoxFit.cover),
                            ),
                          )),
                      ...entry.imageUrls.asMap().entries.map((e) => GestureDetector(
                            onTap: () => showDialog(
                              context: context,
                              builder: (context) => TreeImageGallery(
                                images: [...entry.imageLocalPaths, ...entry.imageUrls],
                                onDelete: _deleteImage,
                                initialIndex: entry.imageLocalPaths.length + e.key,
                              ),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(4),
                              child: Image.network(e.value, width: 64, height: 64, fit: BoxFit.cover),
                            ),
                          )),
                    ],
                  ),
                ),
              if ((entry.imageLocalPaths.isNotEmpty || entry.imageUrls.isNotEmpty))
                const SizedBox(height: 8),
              Text('Species: ${entry.species}'),
              Text('DSH: ${entry.dsh} cm'),
              Text('Height: ${entry.height} m'),
              if (entry.condition.isNotEmpty) Text('Condition: ${entry.condition}'),
              if (entry.comments.isNotEmpty) Text('Comments: ${entry.comments}'),
              if (entry.permitRequired) const Text('Permit Required: Yes'),
              if (entry.srz > 0) Text('SRZ: ${entry.srz} m', style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
              if (entry.nrz > 0) Text('NRZ: ${entry.nrz} m', style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
              if (entry.voiceNotes.isNotEmpty || (entry.voiceNoteAudioPath.isNotEmpty && File(entry.voiceNoteAudioPath).existsSync()))
                Padding(
                  padding: const EdgeInsets.only(top: 12.0),
                  child: Row(
                    children: [
                      if (entry.voiceNotes.isNotEmpty)
                        Expanded(child: Text('Voice Note: ${entry.voiceNotes}', style: const TextStyle(fontStyle: FontStyle.italic))),
                      if (entry.voiceNoteAudioPath.isNotEmpty && File(entry.voiceNoteAudioPath).existsSync())
                        IconButton(
                          icon: const Icon(Icons.play_arrow, color: Colors.deepPurple),
                          tooltip: 'Play Voice Note',
                          onPressed: () async {
                            await audioPlayer.setFilePath(entry.voiceNoteAudioPath);
                            await audioPlayer.play();
                          },
                        ),
                    ],
                  ),
                ),
            ],
          ),
        );
      },
    ).whenComplete(() => audioPlayer.dispose());
  }

  // Convert meters to pixels based on current zoom level
  double _metersToPixels(double meters) {
    try {
      if (_mapController.camera.zoom != null) {
        final zoom = _mapController.camera.zoom!;
        // Accurate scaling formula for true size representation
        // At zoom level 16, 1 meter = 1 pixel (standard OpenStreetMap scale)
        // This ensures SRZ and NRZ circles show true scale
        final pixelRadius = meters * pow(2, zoom - 16);
        
        // Ensure minimum visibility while maintaining scale accuracy
        if (pixelRadius < 5.0) {
          return 5.0; // Minimum 5 pixels for visibility
        } else if (pixelRadius > 200.0) {
          return 200.0; // Maximum 200 pixels to prevent overwhelming the map
        }
        return pixelRadius;
      } else {
        // If controller is not ready, use a default zoom level (16)
        final pixelRadius = meters; // 1:1 scale at zoom 16
        return pixelRadius > 5.0 ? pixelRadius : 5.0;
      }
    } catch (e) {
      // If controller is not ready, use a default zoom level (16)
      final pixelRadius = meters; // 1:1 scale at zoom 16
      return pixelRadius > 5.0 ? pixelRadius : 5.0;
    }
  }

  // Cache for SRZ and NRZ circles
  final Map<String, CircleMarker> _srzCircleCache = {};
  final Map<String, CircleMarker> _nrzCircleCache = {};
  
  // Hash pattern for SRZ and NRZ
  final Paint _srzHashPaint = Paint()
    ..color = Colors.red.withValues(alpha: 0.6)
    ..strokeWidth = 1.0
    ..style = PaintingStyle.stroke;
    
  final Paint _nrzHashPaint = Paint()
    ..color = Colors.green.withValues(alpha: 0.6)
    ..strokeWidth = 1.0
    ..style = PaintingStyle.stroke;
  
  void _updateCircleSizes() {
    // Debounce updates to prevent excessive rebuilds
    _updateTimer?.cancel();
    _updateTimer = Timer(const Duration(milliseconds: 100), () { // Increased debounce for better performance
      if (!mounted) return;
      
      // Only update circles if the map controller is ready and we have trees
      if (_treeEntries.isEmpty) return;
      
      try {
        if (_mapController.camera.zoom == null) {
          return; // Controller not ready yet
        }
      } catch (e) {
        return; // Controller not ready yet
      }
      
      final newSrzCircles = <CircleMarker>[];
      final newNrzCircles = <CircleMarker>[];
      
      for (final entry in _filteredTrees) { // Only show for filtered trees for better performance
        if (entry.latitude != 0 && entry.longitude != 0) {
                      if (_showSRZ && entry.srz > 0) {
              final cacheKey = 'srz_${entry.id}_${entry.srz}_${_mapController.camera.zoom?.toStringAsFixed(1)}';
              CircleMarker srzCircle;
              
              if (_srzCircleCache.containsKey(cacheKey)) {
                srzCircle = _srzCircleCache[cacheKey]!;
              } else {
                // SRZ is already in meters, use directly
                srzCircle = CircleMarker(
                  point: LatLng(entry.latitude, entry.longitude),
                  color: Colors.red.withValues(alpha: 0.0), // Transparent fill for hatching effect
                  borderStrokeWidth: 3.0, // Thicker border
                  borderColor: Colors.red,
                  radius: entry.srz, // Use meters directly
                  useRadiusInMeter: true, // This ensures proper meter scaling
                );
                _srzCircleCache[cacheKey] = srzCircle;
              }
              newSrzCircles.add(srzCircle);
            }
            
            // TPZ (Tree Protection Zone) - was labeled as NRZ
            if (_showNRZ && entry.nrz > 0) {
              final cacheKey = 'tpz_${entry.id}_${entry.nrz}_${_mapController.camera.zoom?.toStringAsFixed(1)}';
              CircleMarker tpzCircle;
              
              if (_nrzCircleCache.containsKey(cacheKey)) {
                tpzCircle = _nrzCircleCache[cacheKey]!;
              } else {
                // TPZ (nrz) is already in meters, use directly
                tpzCircle = CircleMarker(
                  point: LatLng(entry.latitude, entry.longitude),
                  color: Colors.green.withValues(alpha: 0.0), // Transparent fill for hatching effect
                  borderStrokeWidth: 3.0, // Thicker border
                  borderColor: Colors.green,
                  radius: entry.nrz, // Use meters directly
                  useRadiusInMeter: true, // This ensures proper meter scaling
                );
                _nrzCircleCache[cacheKey] = tpzCircle;
              }
              newNrzCircles.add(tpzCircle);
            }
        }
      }
      
      // Only update if circles actually changed
      if (!_areCircleListsEqual(_srzCircles, newSrzCircles) || 
          !_areCircleListsEqual(_nrzCircles, newNrzCircles)) {
        setState(() {
          _srzCircles.clear();
          _srzCircles.addAll(newSrzCircles);
          _nrzCircles.clear();
          _nrzCircles.addAll(newNrzCircles);
        });
      }
    });
  }
  
  // Helper method to check if circle lists are equal
  bool _areCircleListsEqual(List<CircleMarker> list1, List<CircleMarker> list2) {
    if (list1.length != list2.length) return false;
    for (int i = 0; i < list1.length; i++) {
      if (list1[i].point != list2[i].point || list1[i].radius != list2[i].radius) return false;
    }
    return true;
  }

  // Get current location and center map
  Future<void> _getCurrentLocation() async {
    try {
      if (mounted) setState(() => _locating = true);
      // Check if location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Location services are disabled')),
        );
        if (mounted) setState(() => _locating = false);
        return;
      }

      // Check location permission
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Location permission denied')),
          );
          if (mounted) setState(() => _locating = false);
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Location permissions are permanently denied')),
        );
        if (mounted) setState(() => _locating = false);
        return;
      }

      // Try to get a quick position with a short time limit
      Position? position;
      try {
        position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.medium,
          timeLimit: const Duration(seconds: 5),
        );
      } on TimeoutException {
        position = await Geolocator.getLastKnownPosition();
      }
      position ??= await Geolocator.getLastKnownPosition();

      if (position != null) {
        final target = LatLng(position.latitude, position.longitude);
        const double targetZoom = 18.0;
        // Update cached center/zoom for consistency with other map rebuilds
        if (mounted) {
          setState(() {
            _center = target;
            _zoom = targetZoom;
          });
        }
        _mapController.move(target, targetZoom);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Moved to your location: ${position.latitude.toStringAsFixed(4)}, ${position.longitude.toStringAsFixed(4)}')),
        );
      } else {
        // Robust fallback chain: site coords -> saved map -> Melbourne
        LatLng fallbackCenter;
        double fallbackZoom = 16.0;
        if (widget.site.latitude != null && widget.site.longitude != null &&
            widget.site.latitude != 0.0 && widget.site.longitude != 0.0) {
          fallbackCenter = LatLng(widget.site.latitude!, widget.site.longitude!);
        } else if (AppStateService.getMapPosition() != null) {
          final saved = AppStateService.getMapPosition()!;
          fallbackCenter = saved['center'] as LatLng;
          fallbackZoom = (saved['zoom'] as double?) ?? 15.0;
        } else {
          fallbackCenter = const LatLng(-37.8136, 144.9631); // Melbourne
          fallbackZoom = 12.0;
        }
        _mapController.move(fallbackCenter, fallbackZoom);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not get your GPS. Centered using fallback.')),
        );
      }
      if (mounted) setState(() => _locating = false);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error getting location: $e')),
      );
      if (mounted) setState(() => _locating = false);
    }
  }

  // Check location permission on startup
  Future<void> _checkLocationPermission() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        // Don't request automatically, let user trigger it
        return;
      }
    } catch (e) {
      print('Error checking location permission: $e');
    }
  }

  // Toggle GPS tracking mode
  Future<void> _toggleGPSTracking() async {
    if (_trackingGPS) {
      // Stop tracking
      _positionStream?.cancel();
      setState(() {
        _trackingGPS = false;
      });
      NotificationService.showInfo(context, 'GPS tracking stopped');
    } else {
      // Start tracking
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

        setState(() {
          _trackingGPS = true;
        });

        // Start position stream
        _positionStream = Geolocator.getPositionStream(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.high,
            distanceFilter: 10,  // Update every 10 meters
          ),
        ).listen((Position position) {
          setState(() {
            _currentPosition = position;
          });
          // Move map to follow user
          _mapController.move(
            LatLng(position.latitude, position.longitude),
            18.0,  // Zoom in close for tracking
          );
        });

        NotificationService.showSuccess(context, 'GPS tracking started');
      } catch (e) {
        setState(() {
          _trackingGPS = false;
        });
        NotificationService.showError(context, 'Failed to start GPS tracking: $e');
      }
    }
  }

  // Add tree at current GPS location
  Future<void> _addTreeAtGPSLocation() async {
    try {
      setState(() => _locating = true);
      
      // Check if location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        NotificationService.showError(context, 'Location services are disabled');
        setState(() => _locating = false);
        return;
      }

      // Check location permission
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          NotificationService.showError(context, 'Location permission denied');
          setState(() => _locating = false);
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        NotificationService.showError(context, 'Location permissions are permanently denied');
        setState(() => _locating = false);
        return;
      }

      // Get current position
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      );

      setState(() => _locating = false);

      // Add tree at GPS location
      _addTreeAtLocation(LatLng(position.latitude, position.longitude));
      
      NotificationService.showSuccess(
        context, 
        'Adding tree at GPS location: ${position.latitude.toStringAsFixed(6)}, ${position.longitude.toStringAsFixed(6)}'
      );
    } catch (e) {
      setState(() => _locating = false);
      NotificationService.showError(context, 'Failed to get GPS location: $e');
    }
  }

  void _loadMapPosition() {
    print('DEBUG: _loadMapPosition called');
    print('DEBUG: widget.initialLatitude: ${widget.initialLatitude}');
    print('DEBUG: widget.initialLongitude: ${widget.initialLongitude}');
    print('DEBUG: widget.site.latitude: ${widget.site.latitude}');
    print('DEBUG: widget.site.longitude: ${widget.site.longitude}');
    print('DEBUG: widget.site.vicPlanData: ${widget.site.vicPlanData}');
    
    // Priority 1: Use initial coordinates if provided (for new sites)
    if (widget.initialLatitude != null && widget.initialLongitude != null && 
        widget.initialLatitude != 0.0 && widget.initialLongitude != 0.0) {
      setState(() {
        _center = LatLng(widget.initialLatitude!, widget.initialLongitude!);
        _zoom = 16.0; // Closer zoom for specific site
      });
      print('DEBUG: Map centered on initial coordinates: ${widget.initialLatitude}, ${widget.initialLongitude}');
    }
    // Priority 2: If the site has coordinates, center the map there
    else if (widget.site.latitude != null && widget.site.longitude != null && 
             widget.site.latitude != 0.0 && widget.site.longitude != 0.0) {
      setState(() {
        _center = LatLng(widget.site.latitude!, widget.site.longitude!);
        _zoom = 16.0; // Closer zoom for specific site
      });
      print('DEBUG: Map centered on site coordinates: ${widget.site.latitude}, ${widget.site.longitude}');
    }
    // Priority 3: Check vicPlanData for coordinates (new sites created with planning data)
    else if (widget.site.vicPlanData != null && 
             widget.site.vicPlanData!['coordinates'] != null) {
      try {
        final coordsStr = widget.site.vicPlanData!['coordinates'] as String;
        final parts = coordsStr.split(',');
        if (parts.length == 2) {
          final lat = double.parse(parts[0].trim());
          final lon = double.parse(parts[1].trim());
          setState(() {
            _center = LatLng(lat, lon);
            _zoom = 16.0; // Closer zoom for specific site
          });
          print('DEBUG: Map centered on vicPlanData coordinates: $lat, $lon');
        }
      } catch (e) {
        print('DEBUG: Error parsing vicPlanData coordinates: $e');
      }
    } else {
      // Fall back to saved map position
      final savedPosition = AppStateService.getMapPosition();
      if (savedPosition != null) {
        setState(() {
          _center = savedPosition['center'] as LatLng;
          _zoom = savedPosition['zoom'] as double;
        });
        print('DEBUG: Using saved map position: ${_center.latitude}, ${_center.longitude}');
      } else {
        // Fallback to Melbourne coordinates if nothing else works
        setState(() {
          _center = const LatLng(-37.8136, 144.9631); // Melbourne CBD
          _zoom = 12.0;
        });
        print('DEBUG: No site coordinates or saved position, using Melbourne fallback: ${_center.latitude}, ${_center.longitude}');
      }
    }
    
    // Final validation: ensure we never have 0,0 coordinates
    if (_center.latitude == 0.0 && _center.longitude == 0.0) {
      setState(() {
        _center = const LatLng(-37.8136, 144.9631); // Melbourne CBD
        _zoom = 12.0;
      });
      print('DEBUG: Invalid coordinates detected, using Melbourne fallback: ${_center.latitude}, ${_center.longitude}');
    }
    
    print('DEBUG: Final map center: ${_center.latitude}, ${_center.longitude}, zoom: $_zoom');
  }

  void _saveMapPosition() {
    if (_mapController.camera.zoom != null) {
      AppStateService.saveMapPosition(_center, _mapController.camera.zoom!);
    }
  }

  void _loadCircleVisibility() {
    final visibility = AppStateService.getCircleVisibility();
    setState(() {
      // Default to ON so SRZ/NRZ are visible on the main map unless user turns them off
      _showSRZ = visibility['showSRZ'] ?? true;
      _showNRZ = visibility['showNRZ'] ?? true;
    });
  }

  void _saveCircleVisibility() {
    AppStateService.saveCircleVisibility(_showSRZ, _showNRZ);
  }

  void _loadTrees() {
    setState(() {
      _treeEntries.clear();
      _treeEntries.addAll(TreeStorageService.getTreesForSite(widget.site.id));
      // Increment refresh counter to force map rebuild
      _mapRefreshCounter++;
      // Don't add circles here - let _updateCircleSizes handle it
    });
    
    // Force a complete refresh of the map
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        // Update species options, markers and circles after loading trees
        _updateSpeciesOptions();
        _updateMarkers();
        _updateCircleSizes();
      }
    });
  }
  
  // Efficient map refresh method
  void _refreshMap() {
    // Clear caches to force regeneration
    _srzCircleCache.clear();
    _nrzCircleCache.clear();
    
    // Update markers and circles without calling _loadTrees()
    _updateMarkers();
    _updateCircleSizes();
  }
  
  // Center map precisely on site location
  void _centerMapOnSite() {
    if (widget.site.latitude != null && widget.site.longitude != null) {
      final siteLocation = LatLng(widget.site.latitude!, widget.site.longitude!);
      
      // Animate to site location with precise positioning
      _mapController.move(siteLocation, 16.0);
      
      // Update center state
      setState(() {
        _center = siteLocation;
        _zoom = 16.0; // Optimal zoom for tree work
      });
      
      // Refresh the map to ensure all elements are properly positioned
      _refreshMap();
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Map centered on site: ${widget.site.name}'),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  void _clearMap() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear All Trees'),
        content: const Text('Are you sure you want to remove all trees from this site? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(context).pop();
              
              try {
                // Clear all trees for this site
                await TreeStorageService.clearAllForSite(widget.site.id);
                
                // Clear local state
                setState(() {
                  _treeEntries.clear();
                  _filteredTrees.clear();
                  _markers.clear();
                  _srzCircles.clear();
                  _nrzCircles.clear();
                });
                
                // Clear caches
                _srzCircleCache.clear();
                _nrzCircleCache.clear();
                
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('All trees cleared from site')),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Error clearing trees: $e')),
                );
              }
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Clear All'),
          ),
        ],
      ),
    );
  }

  void _showTreeDetails(TreeEntry tree) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            // Handle bar
            Container(
              margin: const EdgeInsets.only(top: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header with tree ID and condition
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: _getConditionColor(tree.condition).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            tree.condition,
                            style: TextStyle(
                              color: _getConditionColor(tree.condition),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const Spacer(),
                        Text(
                          'Tree ${tree.id}',
                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    
                    // Tree details
                    _buildDetailRow('Species', tree.species),
                    _buildDetailRow('DSH', '${tree.dsh} cm'),
                    _buildDetailRow('Height', '${tree.height} m'),
                    _buildDetailRow('SRZ', '${tree.srz} m'),
                    _buildDetailRow('NRZ', '${tree.nrz} m'),
                    _buildDetailRow('Risk Rating', tree.overallRiskRating),
                    _buildDetailRow('Retention Value', tree.retentionValue),
                    _buildDetailRow('Permit Required', tree.permitRequired ? 'Yes' : 'No'),
                    
                    if (tree.notes.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      Text(
                        'Notes',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(tree.notes),
                    ],
                    
                    const SizedBox(height: 20),
                    
                    // Action buttons
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () => _editTree(tree),
                            icon: const Icon(Icons.edit),
                            label: const Text('Edit'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue,
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () => _viewTreeReport(tree),
                            icon: const Icon(Icons.assessment),
                            label: const Text('Report'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.grey,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  void _editTree(TreeEntry tree) {
    Navigator.pop(context); // Close bottom sheet
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TreeForm(
          siteId: widget.site.id,
          initialEntry: tree,
          reportType: widget.site.reportType,
          onSubmit: (updatedTree) async {
            final box = Hive.box<TreeEntry>(TreeStorageService.boxName);
            final key = box.keys.firstWhere(
              (k) => box.get(k)?.id == tree.id,
              orElse: () => null,
            );
            if (key != null) {
              await TreeStorageService.updateTree(key, updatedTree);
            }
            _loadTrees(); // Refresh map
            Navigator.pop(context);
          },
        ),
      ),
    );
  }

  void _viewTreeReport(TreeEntry tree) {
    Navigator.pop(context); // Close bottom sheet
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => IsaReportPage(
          site: widget.site,
          tree: tree,
        ),
      ),
    );
  }

  Color _getConditionColor(String condition) {
    switch (condition) {
      case 'Excellent':
        return Colors.green;
      case 'Good':
        return Colors.lightGreen;
      case 'Fair':
        return Colors.yellow;
      case 'Poor':
        return Colors.orange;
      case 'Critical':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  void _addTreeEntry(LatLng point) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            left: 16,
            right: 16,
            top: 16,
          ),
          child: TreeForm(
            siteId: widget.site.id,
            initialEntry: null, // This will trigger auto-numbering
            reportType: widget.site.reportType,
            onSubmit: (entry) async {
              // Set the coordinates from the tap point
              final updatedEntry = TreeEntry(
                id: entry.id,
                species: entry.species,
                dsh: entry.dsh,
                height: entry.height,
                condition: entry.condition,
                comments: entry.comments,
                permitRequired: entry.permitRequired,
                latitude: point.latitude,
                longitude: point.longitude,
                srz: entry.srz,
                nrz: entry.nrz,
                ageClass: entry.ageClass,
                retentionValue: entry.retentionValue,
                riskRating: entry.riskRating,
                locationDescription: entry.locationDescription,
                habitatValue: entry.habitatValue,
                recommendedWorks: entry.recommendedWorks,
                healthForm: entry.healthForm,
                diseasesPresent: entry.diseasesPresent,
                canopySpread: entry.canopySpread,
                clearanceToStructures: entry.clearanceToStructures,
                origin: entry.origin,
                pastManagement: entry.pastManagement,
                pestPresence: entry.pestPresence,
                notes: entry.notes,
                siteId: entry.siteId,
                targetOccupancy: entry.targetOccupancy,
                defectsObserved: entry.defectsObserved,
                likelihoodOfFailure: entry.likelihoodOfFailure,
                likelihoodOfImpact: entry.likelihoodOfImpact,
                consequenceOfFailure: entry.consequenceOfFailure,
                overallRiskRating: entry.overallRiskRating,
                vtaNotes: entry.vtaNotes,
                vtaDefects: entry.vtaDefects,
                inspectionDate: entry.inspectionDate,
                inspectorName: entry.inspectorName,
                voiceNotes: entry.voiceNotes,
                voiceNoteAudioPath: entry.voiceNoteAudioPath,
                voiceAudioUrl: entry.voiceAudioUrl,
                imageLocalPaths: entry.imageLocalPaths,
                imageUrls: entry.imageUrls,
              );
              await TreeStorageService.addTree(updatedEntry);
              _loadTrees();
              Navigator.of(context).pop();
            },
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Map - ${widget.site.name}'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: Icon(_satelliteView ? Icons.map : Icons.satellite),
            onPressed: () => _toggleSatelliteView(),
            tooltip: _satelliteView ? 'Switch to Map View' : 'Switch to Satellite View',
          ),
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () => _showFilterDialog(),
            tooltip: 'Filter Trees',
          ),
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () => _showSearchDialog(),
            tooltip: 'Search Trees',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => _refreshMap(),
            tooltip: 'Refresh Map',
          ),
        ],
      ),
      body: Stack(
        children: [
          Column(
            children: [
              // Search and filter bar
              _buildSearchAndFilterBar(),
              
              // Map
              Expanded(
                child: Container(
                  color: Colors.grey[200], // Add background color to see if container is working
                  child: FlutterMap(
                  key: ValueKey('map_$_mapRefreshCounter'),
                  mapController: _mapController,
                  options: MapOptions(
                    initialCenter: _center,
                    initialZoom: _zoom,
                    onMapReady: () {
                      setState(() {
                        _mapReady = true;
                      });
                      print('DEBUG: Map ready with center: ${_center.latitude}, ${_center.longitude}, zoom: $_zoom');
                      print('DEBUG: Map controller state: ${_mapController.camera.center}, zoom: ${_mapController.camera.zoom}');
                      print('DEBUG: Map widget center: ${_center.latitude}, ${_center.longitude}');
                    },
                    onTap: (_addTreeMode || _viewTreeMode) ? _handleMapTap : null,
                    maxZoom: 20.0,
                    minZoom: 10.0,
                  ),
                  children: [
                    // Satellite layer (when satellite view is enabled)
                    if (_satelliteView)
                      TileLayer(
                        urlTemplate: 'https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}',
                        userAgentPackageName: 'com.example.app',
                        tileProvider: NetworkTileProvider(),
                        maxZoom: 20,
                        minZoom: 10,
                        keepBuffer: 5,
                        tms: false,
                        errorTileCallback: (tile, error, stackTrace) {
                          print('DEBUG: Satellite tile error at ${tile.coordinates}: $error');
                        },
                      ),
                    // OpenStreetMap layer (when satellite view is disabled)
                    if (!_satelliteView)
                      TileLayer(
                        urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                        userAgentPackageName: 'com.example.app',
                        tileProvider: NetworkTileProvider(),
                        maxZoom: 20,
                        minZoom: 10,
                        keepBuffer: 5,
                        tms: false,
                        errorTileCallback: (tile, error, stackTrace) {
                          print('DEBUG: Map tile error at ${tile.coordinates}: $error');
                        },
                      ),
                    // Site marker
                    MarkerLayer(
                      markers: [
                        Marker(
                          point: LatLng(_center.latitude, _center.longitude),
                          width: 40,
                          height: 40,
                          child: GestureDetector(
                            onTap: () => _showSiteInfo(),
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.blue,
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white, width: 2),
                              ),
                              child: const Icon(
                                Icons.location_on,
                                color: Colors.white,
                                size: 24,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    // Tree markers
                    MarkerLayer(markers: _markers),
                    // SRZ circles
                    if (_showSRZ) CircleLayer(circles: _srzCircles),
                    // NRZ circles
                    if (_showNRZ) CircleLayer(circles: _nrzCircles),
                    
                    // Scale indicator for true size reference
                    // ScaleLayerWidget removed - not available in current flutter_map version
                    
                    // Current GPS position marker
                    if (_currentPosition != null)
                      MarkerLayer(
                        markers: [
                          Marker(
                            point: LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
                            width: 30,
                            height: 30,
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.blue.withValues(alpha: 0.3),
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.blue, width: 3),
                              ),
                              child: const Icon(
                                Icons.my_location,
                                color: Colors.blue,
                                size: 16,
                              ),
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
                  ),
                ),
            ],
          ),
          
          // GPS Control Buttons (offset from floating action buttons)
          Positioned(
            left: 16,
            bottom: 200,
            child: Column(
              children: [
                // GPS Tracking Button
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.2),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(8),
                      onTap: _toggleGPSTracking,
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Icon(
                          _trackingGPS ? Icons.gps_fixed : Icons.gps_not_fixed,
                          color: _trackingGPS ? Colors.blue : Colors.grey[600],
                          size: 24,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                // Center on Current Location Button
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.2),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(8),
                      onTap: _getCurrentLocation,
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Icon(
                          Icons.my_location,
                          color: Colors.purple[600],
                          size: 24,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // GPS Tracking Status Indicator - moved to top
          if (_trackingGPS)
            Positioned(
              top: 60,
              right: 16,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.blue,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.2),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Icon(Icons.gps_fixed, color: Colors.white, size: 16),
                    SizedBox(width: 4),
                    Text(
                      'GPS Tracking',
                      style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ),
          
          // Add tree mode indicator overlay
          if (_addTreeMode)
            Positioned(
              top: 100,
              left: 20,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.9),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.2),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.add_location, color: Colors.white, size: 20),
                    const SizedBox(width: 8),
                    const Text(
                      'Click anywhere on the map to add a tree',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
      floatingActionButton: SafeArea(
        top: false,
        left: false,
        right: false,
        minimum: const EdgeInsets.only(bottom: 16, right: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.end,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
          // Removed redundant buttons - keeping only essential ones
          FloatingActionButton(
            heroTag: 'addTreeMode',
            onPressed: () => _toggleAddTreeMode(),
            backgroundColor: _addTreeMode ? Colors.red : Colors.green,
            foregroundColor: Colors.white,
            child: Icon(_addTreeMode ? Icons.close : Icons.add_location),
            tooltip: _addTreeMode ? 'Exit Add Tree Mode' : 'Enter Add Tree Mode',
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              FloatingActionButton.small(
                heroTag: 'addTreeGPS',
                onPressed: _locating ? null : _addTreeAtGPSLocation,
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                child: const Icon(Icons.add_location_alt, size: 18),
                tooltip: 'Add tree at current GPS location',
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (_addTreeMode) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.green,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text(
                'Click on map to add tree',
                style: TextStyle(color: Colors.white, fontSize: 12),
              ),
            ),
            const SizedBox(height: 8),
          ],
          const SizedBox(height: 8),
          // SRZ/TPZ toggle buttons
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              FloatingActionButton.small(
                heroTag: 'toggleSRZ',
                onPressed: () => _toggleSRZ(),
                backgroundColor: _showSRZ ? Colors.red : Colors.grey,
                foregroundColor: Colors.white,
                child: const Text('SRZ', style: TextStyle(fontSize: 10)),
                tooltip: 'Toggle SRZ (Structural Root Zone)',
              ),
              const SizedBox(width: 8),
              FloatingActionButton.small(
                heroTag: 'toggleTPZ',
                onPressed: () => _toggleNRZ(),
                backgroundColor: _showNRZ ? Colors.green : Colors.grey,
                foregroundColor: Colors.white,
                child: const Text('TPZ', style: TextStyle(fontSize: 10)),
                tooltip: 'Toggle TPZ (Tree Protection Zone)',
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (_locating)
            Positioned(
              top: 90,
              right: 16,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    SizedBox(
                      height: 16,
                      width: 16,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    ),
                    SizedBox(width: 8),
                    Text('Locating…', style: TextStyle(color: Colors.white)),
                  ],
                ),
              ),
            ),
        ],
        ),
      ),
    );
  }

  Widget _buildLegendItem({
    required IconData icon,
    required Color color,
    required String label,
    required bool isOutline,
  }) {
    return Row(
      children: [
        Container(
          width: 20,
          height: 20,
          decoration: BoxDecoration(
            color: isOutline ? Colors.transparent : color,
            shape: BoxShape.circle,
            border: Border.all(
              color: color,
              width: isOutline ? 2 : 0,
            ),
          ),
          child: isOutline
              ? null
              : Icon(
                  icon,
                  size: 12,
                  color: Colors.white,
                ),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
          ),
        ),
      ],
    );
  }
  
  // Export functions removed – exports now handled by dedicated export flows
  
  Widget _buildSearchAndFilterBar() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search trees...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.grey[200],
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
            ),
          ),
          const SizedBox(width: 8),
          PopupMenuButton<String>(
            onSelected: (value) {
              setState(() {
                _filterCondition = value;
              });
            },
            itemBuilder: (context) => _conditionOptions.map((condition) {
              return PopupMenuItem(
                value: condition,
                child: Text(condition),
              );
            }).toList(),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(_filterCondition),
                  const Icon(Icons.arrow_drop_down),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),
          // SRZ Toggle Button
          GestureDetector(
            onTap: () {
              setState(() {
                _showSRZ = !_showSRZ;
                _saveCircleVisibility();
                _updateCircleSizes();
              });
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: _showSRZ ? Colors.red.withValues(alpha: 0.2) : Colors.grey[200],
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: _showSRZ ? Colors.red : Colors.grey[400]!,
                  width: _showSRZ ? 2 : 1,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.radio_button_checked,
                    color: _showSRZ ? Colors.red : Colors.grey[600],
                    size: 16,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'SRZ',
                    style: TextStyle(
                      color: _showSRZ ? Colors.red[700] : Colors.grey[600],
                      fontWeight: _showSRZ ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),
          // NRZ Toggle Button
          GestureDetector(
            onTap: () {
              setState(() {
                _showNRZ = !_showNRZ;
                _saveCircleVisibility();
                _updateCircleSizes();
              });
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: _showNRZ ? Colors.green.withValues(alpha: 0.2) : Colors.grey[200],
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: _showNRZ ? Colors.green : Colors.grey[400]!,
                  width: _showNRZ ? 2 : 1,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.radio_button_checked,
                    color: _showNRZ ? Colors.green : Colors.grey[600],
                    size: 16,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'NRZ',
                    style: TextStyle(
                      color: _showNRZ ? Colors.green[700] : Colors.grey[600],
                      fontWeight: _showNRZ ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Add missing methods
  void _addTreeFromMap() {
    // Navigate to Report Type Selector
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ReportTypeSelector(site: widget.site),
      ),
    ).then((_) {
      // Reload trees when returning
      _loadTrees();
    });
  }

  void _handleMapTap(TapPosition tapPosition, LatLng point) {
    if (_addTreeMode) {
      // Add tree at the tapped location
      _addTreeAtLocation(point);
    } else if (_viewTreeMode) {
      // View trees at the tapped location
      _viewTreesAtLocation(point);
    }
  }

  void _toggleAddTreeMode() {
    setState(() {
      _addTreeMode = !_addTreeMode;
      if (_addTreeMode) {
        _viewTreeMode = false; // Disable other mode
      }
    });
    
    if (_addTreeMode) {
      NotificationService.showInfo(context, 'Click anywhere on the map to add a tree');
    } else {
      NotificationService.showInfo(context, 'Add tree mode disabled');
    }
  }

  void _toggleViewTreeMode() {
    setState(() {
      _viewTreeMode = !_viewTreeMode;
      if (_viewTreeMode) {
        _addTreeMode = false; // Disable other mode
      }
    });
    
    if (_viewTreeMode) {
      NotificationService.showInfo(context, 'Click anywhere on the map to view trees');
    } else {
      NotificationService.showInfo(context, 'View tree mode disabled');
    }
  }

  void _toggleSatelliteView() {
    setState(() {
      _satelliteView = !_satelliteView;
    });
    
    if (_satelliteView) {
      NotificationService.showInfo(context, 'Switched to Satellite View');
    } else {
      NotificationService.showInfo(context, 'Switched to Map View');
    }
  }

  void _addTreeAtLocation(LatLng point) {
    // Create a pre-filled tree entry with coordinates
    final preFilledTree = TreeEntry(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      siteId: widget.site.id,
      species: '',
      dsh: 0.0,
      height: 0.0,
      condition: 'Good',
      comments: 'Tree added by clicking on map at coordinates: ${point.latitude.toStringAsFixed(6)}, ${point.longitude.toStringAsFixed(6)}',
      permitRequired: false,
      latitude: point.latitude,
      longitude: point.longitude,
      locationDescription: 'Added from map',
      notes: 'Tree added by clicking on map at coordinates: ${point.latitude.toStringAsFixed(6)}, ${point.longitude.toStringAsFixed(6)}',
    );

    // Navigate to tree form with pre-filled coordinates
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TreeForm(
          siteId: widget.site.id,
          initialEntry: preFilledTree,
          reportType: widget.site.reportType,
          onSubmit: (tree) async {
            await TreeStorageService.addTree(tree);
            _loadTrees(); // Refresh the map
            Navigator.pop(context);
            NotificationService.showSuccess(context, 'Tree added successfully at ${point.latitude.toStringAsFixed(6)}, ${point.longitude.toStringAsFixed(6)}!');
            
            // Exit add tree mode after successful addition
            setState(() {
              _addTreeMode = false;
            });
          },
        ),
      ),
    );
  }

  void _viewTreesAtLocation(LatLng point) {
    // Find trees near the tapped location (within 10 meters)
    const double searchRadius = 0.0001; // Approximately 10 meters
    final nearbyTrees = _treeEntries.where((tree) {
      final treeLat = tree.latitude ?? 0.0;
      final treeLng = tree.longitude ?? 0.0;
      final latDiff = (treeLat - point.latitude).abs();
      final lngDiff = (treeLng - point.longitude).abs();
      return latDiff <= searchRadius && lngDiff <= searchRadius;
    }).toList();

    if (nearbyTrees.isEmpty) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('No Trees Found'),
          content: Text('No trees found at coordinates: ${point.latitude.toStringAsFixed(6)}, ${point.longitude.toStringAsFixed(6)}'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ],
        ),
      );
    } else {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Trees at Location (${nearbyTrees.length})'),
          content: SizedBox(
            width: double.maxFinite,
            height: 300,
            child: ListView.builder(
              itemCount: nearbyTrees.length,
              itemBuilder: (context, index) {
                final tree = nearbyTrees[index];
                return ListTile(
                  leading: Icon(
                    Icons.forest,
                    color: _getTreeColor(tree.condition),
                  ),
                  title: Text(tree.species.isNotEmpty ? tree.species : 'Unknown Species'),
                  subtitle: Text('Condition: ${tree.condition} | Height: ${tree.height}m | DSH: ${tree.dsh}cm'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit),
                        onPressed: () {
                          Navigator.pop(context);
                          _editTree(tree);
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.info),
                        onPressed: () {
                          Navigator.pop(context);
                          _showTreeDetails(tree);
                        },
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ],
        ),
      );
    }
  }

  Color _getTreeColor(String condition) {
    switch (condition.toLowerCase()) {
      case 'excellent':
        return Colors.green;
      case 'good':
        return Colors.lightGreen;
      case 'fair':
        return Colors.yellow;
      case 'poor':
        return Colors.orange;
      case 'critical':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  void _toggleSRZ() {
    setState(() {
      _showSRZ = !_showSRZ;
    });
    AppStateService.saveCircleVisibility(_showSRZ, _showNRZ);
  }

  void _toggleNRZ() {
    setState(() {
      _showNRZ = !_showNRZ;
    });
    AppStateService.saveCircleVisibility(_showSRZ, _showNRZ);
  }

  void _showSiteInfo() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(widget.site.name),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Address: ${widget.site.address}'),
            const SizedBox(height: 8),
            Text('Total Trees: ${_treeEntries.length}'),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      _addTreeFromMap();
                    },
                    icon: const Icon(Icons.add),
                    label: const Text('Add Tree'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => TreeListPage(site: widget.site),
                        ),
                      );
                    },
                    icon: const Icon(Icons.list),
                    label: const Text('View Trees'),
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

}

// Custom painter for hash patterns
enum HashPattern { crisscross, vertical, horizontal }

class HashPatternPainter extends CustomPainter {
  final Color color;
  final double strokeWidth;
  final HashPattern pattern;
  
  HashPatternPainter({
    required this.color,
    required this.strokeWidth,
    required this.pattern,
  });
  
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;
    
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    
    switch (pattern) {
      case HashPattern.crisscross:
        // Draw crisscross pattern (red for SRZ)
        _drawCrisscrossPattern(canvas, center, radius, paint);
        break;
      case HashPattern.vertical:
        // Draw vertical hash pattern (green for NRZ)
        _drawVerticalHashPattern(canvas, center, radius, paint);
        break;
      case HashPattern.horizontal:
        // Draw horizontal hash pattern
        _drawHorizontalHashPattern(canvas, center, radius, paint);
        break;
    }
  }
  
  void _drawCrisscrossPattern(Canvas canvas, Offset center, double radius, Paint paint) {
    // Draw diagonal lines for crisscross effect
    final spacing = radius / 8; // 8 lines across the radius
    
    for (int i = -4; i <= 4; i++) {
      final offset = i * spacing;
      
      // Top-left to bottom-right diagonal
      final start1 = Offset(center.dx - radius + offset, center.dy - radius);
      final end1 = Offset(center.dx + radius, center.dy + radius - offset);
      canvas.drawLine(start1, end1, paint);
      
      // Top-right to bottom-left diagonal
      final start2 = Offset(center.dx + radius - offset, center.dy - radius);
      final end2 = Offset(center.dx - radius, center.dy + radius - offset);
      canvas.drawLine(start2, end2, paint);
    }
  }
  
  void _drawVerticalHashPattern(Canvas canvas, Offset center, double radius, Paint paint) {
    // Draw vertical hash lines
    final spacing = radius / 6; // 6 lines across the radius
    
    for (int i = -3; i <= 3; i++) {
      final x = center.dx + (i * spacing);
      final start = Offset(x, center.dy - radius);
      final end = Offset(x, center.dy + radius);
      canvas.drawLine(start, end, paint);
    }
  }
  
  void _drawHorizontalHashPattern(Canvas canvas, Offset center, double radius, Paint paint) {
    // Draw horizontal hash lines
    final spacing = radius / 6; // 6 lines across the radius
    
    for (int i = -3; i <= 3; i++) {
      final y = center.dy + (i * spacing);
      final start = Offset(center.dx - radius, y);
      final end = Offset(center.dx + radius, y);
      canvas.drawLine(start, end, paint);
    }
  }
  
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
