import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geocoding/geocoding.dart';
import '../services/vicmap_service.dart';
import '../models/site.dart';
import '../services/site_storage_service.dart';
import '../services/simple_permit_service.dart';
import '../services/address_autocomplete_service.dart';
import '../services/web_geocoding_service.dart';
import '../data/victorian_overlay_database.dart';

class SimpleAddSiteDialog extends StatefulWidget {
  final Function(Site) onSiteCreated;
  final List<Site> existingSites;

  const SimpleAddSiteDialog({
    super.key,
    required this.onSiteCreated,
    required this.existingSites,
  });

  @override
  State<SimpleAddSiteDialog> createState() => _SimpleAddSiteDialogState();
}

class _SimpleAddSiteDialogState extends State<SimpleAddSiteDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _addressController = TextEditingController();
  final _notesController = TextEditingController();
  
  Map<String, dynamic>? _permitResult;
  List<Map<String, dynamic>> overlays = [];
  
  List<Widget> _buildOverlayWidgets() {
    final raw = (_permitResult?['overlays'] as List?)?.whereType<Map<String, dynamic>>().toList();
    if (raw == null || raw.isEmpty) {
      return const [];
    }

    return raw.map((overlay) {
      final code = overlay['code']?.toString() ?? overlay['name']?.toString() ?? 'Unknown';
      final description = _getOverlayDescription(code);
      final impact = _getOverlayImpact(code);
      final overlayTitle = _getOverlayTitle(code);

      Color bgColor;
      Color borderColor;
      Color accentColor;

      switch (impact) {
        case 'high':
          bgColor = Colors.red.shade50;
          borderColor = Colors.red.shade300;
          accentColor = Colors.red.shade700;
          break;
        case 'medium':
          bgColor = Colors.orange.shade50;
          borderColor = Colors.orange.shade300;
          accentColor = Colors.orange.shade700;
          break;
        default:
          bgColor = Colors.blue.shade50;
          borderColor = Colors.blue.shade300;
          accentColor = Colors.blue.shade700;
      }

      return Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: borderColor, width: 1.5),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  impact == 'high'
                      ? Icons.warning_amber_rounded
                      : impact == 'medium'
                          ? Icons.info_outline
                          : Icons.check_circle_outline,
                  size: 18,
                  color: accentColor,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '$code - $overlayTitle',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: impact == 'high'
                          ? Colors.red.shade900
                          : impact == 'medium'
                              ? Colors.orange.shade900
                              : Colors.blue.shade900,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              description,
              style: TextStyle(fontSize: 12, color: Colors.grey[800], height: 1.4),
            ),
          ],
        ),
      );
    }).toList();
  }

  List<Widget> _buildPermitDataPreview() {
    final permitData = (_permitResult?['permit_data'] as Map?)?.cast<String, dynamic>();
    if (permitData == null || permitData.isEmpty) {
      return const [];
    }

    return permitData.entries.take(3).map((entry) {
      return Text(
        '• ${entry.key.replaceAll('_', ' ')}: ${entry.value}',
        style: const TextStyle(fontSize: 12),
      );
    }).toList();
  }
  final _suburbController = TextEditingController();
  final _postcodeController = TextEditingController();

  // New: geolocation + permits state
  double? _latitude;
  double? _longitude;
  Map<String, dynamic>? _permitResult;
  bool _checkingPermits = false;
  bool _useVicmapLive = false; // toggle for live planning API
  final MapController _mapController = MapController();
  List<String> _addressSuggestions = [];
  bool _showAddressSuggestions = false;
  Timer? _addressDebounce;

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    _suburbController.dispose();
    _postcodeController.dispose();
    _addressDebounce?.cancel();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _attemptInitialGeolocation();
  }

  Future<void> _attemptInitialGeolocation() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.deniedForever ||
          permission == LocationPermission.denied) {
        return;
      }
      final pos = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.best);
      setState(() {
        _latitude = pos.latitude;
        _longitude = pos.longitude;
      });
      // Reverse geocode to prefill if fields are empty
      if ((_addressController.text.isEmpty || _suburbController.text.isEmpty) &&
          _latitude != null && _longitude != null) {
        final placemarks = await AddressAutocompleteService.getAddressFromCoordinates(_latitude!, _longitude!);
        if (placemarks.isNotEmpty) {
          final p = placemarks.first;
          setState(() {
            _addressController.text = [p.subThoroughfare, p.thoroughfare].where((e) => (e ?? '').isNotEmpty).join(' ').trim();
            _suburbController.text = p.locality ?? _suburbController.text;
            _postcodeController.text = p.postalCode ?? _postcodeController.text;
          });
        }
      }
      try { _mapController.move(LatLng(_latitude!, _longitude!), 16); } catch (_) {}
    } catch (_) {
      // ignore; fallback is address geocode
    }
  }

  // Run permits choosing Vicmap live or Simple service, with graceful fallback
  Future<Map<String, dynamic>> _runPermits(double lat, double lng) async {
    try {
      if (_useVicmapLive) {
        // VicmapService returns PlanningResult; convert to serializable map for storage
        final result = await VicmapService.getPlanningAtPoint(lng, lat);
        return {
          'success': !result.hasError,
          'lga': result.lga,
          'zones': result.zones.map((z) => z.toJson()).toList(),
          'overlays': result.overlays.map((o) => o.toJson()).toList(),
          'timestamp': result.timestamp.toIso8601String(),
          if (result.error != null) 'error': result.error,
          'data_source': 'Vicmap Live',
        };
      }
      // Default simple service
      return await SimplePermitService.getPermitData(lat, lng);
    } catch (_) {
      // Fallback to simple service
      return await SimplePermitService.getPermitData(lat, lng);
    }
  }

  // Basic retry helper with 2 attempts
  Future<T> _retry<T>(Future<T> Function() action) async {
    try {
      return await action();
    } catch (_) {
      await Future.delayed(const Duration(milliseconds: 300));
      return await action();
    }
  }

  // Get detailed overlay description from comprehensive database
  String _getOverlayDescription(String code) {
    final overlayInfo = VictorianOverlayDatabase.getOverlayInfo(code);
    
    if (overlayInfo != null) {
      return overlayInfo['description'] ?? 'Planning overlay - Check council requirements';
    }
    
    // Fallback for unknown overlays
    return 'Planning overlay - PERMIT may be required for tree work. Check council planning department for specific requirements. Arborist report recommended.';
  }
  
  // Get short title for overlay from database
  String _getOverlayTitle(String code) {
    final overlayInfo = VictorianOverlayDatabase.getOverlayInfo(code);
    return overlayInfo?['name'] ?? 'Planning Overlay';
  }
  
  // Get impact level from database
  String _getOverlayImpact(String code) {
    final overlayInfo = VictorianOverlayDatabase.getOverlayInfo(code);
    return overlayInfo?['impact'] ?? 'low';
  }
  
  // Build LGA-specific tree protection rules widget
  Widget _buildLGARules(String lgaName) {
    final rules = VictorianOverlayDatabase.getLGARules(lgaName);
    
    if (rules == null) {
      return const SizedBox.shrink();
    }
    
    final strictness = rules['strictness'] ?? 'Unknown';
    final Color strictnessColor = strictness == 'Extreme' || strictness == 'Very High' ? Colors.red :
                                   strictness == 'High' ? Colors.orange :
                                   strictness == 'Medium-High' ? Colors.orange.shade300 :
                                   strictness == 'Medium' ? Colors.blue :
                                   Colors.green;
    
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: strictnessColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: strictnessColor.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.gavel, size: 16, color: strictnessColor),
              const SizedBox(width: 6),
              Text(
                'Local Law Tree Protection',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: strictnessColor),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: strictnessColor,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  strictness,
                  style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Threshold: ${rules['threshold_height']} height OR ${rules['threshold_circumference']} circumference',
            style: TextStyle(fontSize: 11, color: Colors.grey[800]),
          ),
          const SizedBox(height: 4),
          Text(
            'Permit: ${rules['permit_required']}',
            style: TextStyle(fontSize: 11, color: Colors.grey[800]),
          ),
          if (rules['replacement_required'] != null) ...[
            const SizedBox(height: 4),
            Text(
              'Replacement: ${rules['replacement_required']}',
              style: TextStyle(fontSize: 11, color: Colors.grey[800]),
            ),
          ],
          if (rules['fees'] != null) ...[
            const SizedBox(height: 4),
            Text(
              'Fees: ${rules['fees']}',
              style: TextStyle(fontSize: 11, color: Colors.grey[700]),
            ),
          ],
        ],
      ),
    );
  }

  void _createSite() async {
    if (_formKey.currentState!.validate()) {
      // Ensure we have coordinates even if permits were not run
      if ((_latitude == null || _longitude == null)) {
        final fullAddress = '${_addressController.text}, ${_suburbController.text} ${_postcodeController.text}, VIC, Australia';
        Map<String, double>? coords = await _retry<Map<String, double>?>(() => AddressAutocompleteService.getCoordinatesForAddress(fullAddress));
        // Web fallback to Nominatim
        if ((coords == null || coords['latitude'] == null) && kIsWeb) {
          coords = await WebGeocodingService.geocodeAddress(fullAddress);
        }
        if (coords != null) {
          _latitude = coords['latitude'];
          _longitude = coords['longitude'];
        }
      }
      // Block save if still no coordinates
      if (_latitude == null || _longitude == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please confirm a map location (tap the mini map) or enter a valid address.')),
        );
        return;
      }

      // Save lat/lng if available; save vicPlanData only if permits were run
      final vicPlanToSave = _permitResult; // null unless user ran a permits action
      final site = Site(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: _nameController.text.trim(),
        address: '${_addressController.text}, ${_suburbController.text} ${_postcodeController.text}, VIC, Australia',
        notes: 'Created with simple dialog',
        createdAt: DateTime.now(),
        latitude: _latitude,
        longitude: _longitude,
        vicPlanData: vicPlanToSave,
      );

      await SiteStorageService.addSite(site);
      widget.onSiteCreated(site);

      // If permits weren't run but we have coordinates, run permits in background and update site
      if (_permitResult == null && _latitude != null && _longitude != null) {
        // Fire and forget
        // ignore: unawaited_futures
        Future(() async {
          try {
            final permits = await _runPermits(_latitude!, _longitude!);
            final updated = Site(
              id: site.id,
              name: site.name,
              address: site.address,
              notes: site.notes,
              createdAt: site.createdAt,
              syncStatus: site.syncStatus,
              latitude: site.latitude,
              longitude: site.longitude,
              vicPlanData: permits,
            );
            await SiteStorageService.updateSite(site.id, updated);
            // Optional: toast on background completion is tricky after dialog pop; keep silent to avoid context issues
          } catch (_) {}
        });
      }

      Navigator.of(context).pop();
    }
  }

  Future<void> _findMyLocationAndPermits() async {
    try {
      setState(() => _checkingPermits = true);
      // Request permission if needed
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.deniedForever ||
          permission == LocationPermission.denied) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Location permission denied')),
        );
        setState(() => _checkingPermits = false);
        return;
      }

      final pos = await _retry<Position>(() => Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high));
      _latitude = pos.latitude;
      _longitude = pos.longitude;

      // Reverse geocode to fill address fields
      final placemarks = await _retry<List<Placemark>>(() => AddressAutocompleteService.getAddressFromCoordinates(_latitude!, _longitude!));
      if (placemarks.isNotEmpty) {
        final p = placemarks.first;
        setState(() {
          _addressController.text = [p.subThoroughfare, p.thoroughfare].where((e) => (e ?? '').isNotEmpty).join(' ').trim();
          _suburbController.text = p.locality ?? '';
          _postcodeController.text = p.postalCode ?? '';
        });
      }

      // Run permits using selected source with fallback
      final permits = await _runPermits(_latitude!, _longitude!);
      setState(() {
        _permitResult = permits;
        _checkingPermits = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Location found and permits checked')),
      );
    } catch (e) {
      setState(() => _checkingPermits = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to find location or check permits: $e')),
      );
    }
  }

  Future<void> _confirmAddressAndPermits() async {
    try {
      final fullAddress = '${_addressController.text}, ${_suburbController.text} ${_postcodeController.text}, VIC, Australia';
      if (fullAddress.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please enter an address first')),
        );
        return;
      }
      setState(() => _checkingPermits = true);
      final coords = await AddressAutocompleteService.getCoordinatesForAddress(fullAddress);
      if (coords == null) {
        setState(() => _checkingPermits = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not geocode address')),
        );
        return;
      }
      _latitude = coords['latitude'];
      _longitude = coords['longitude'];

      final permits = await SimplePermitService.getPermitData(_latitude!, _longitude!);
      setState(() {
        _permitResult = permits;
        _checkingPermits = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Address confirmed and permits checked')),
      );
    } catch (e) {
      setState(() => _checkingPermits = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to confirm address or check permits: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenHeight < 700 || screenWidth < 400;
    final dialogInsets = isSmallScreen ? 12.0 : 24.0;
    final maxDialogHeight = screenHeight * (isSmallScreen ? 0.95 : 0.8);
    final dialogWidth = screenWidth > 600
        ? 520.0
        : (screenWidth - dialogInsets * 2).clamp(320.0, 520.0);

    return Dialog(
      insetPadding: EdgeInsets.symmetric(
        horizontal: dialogInsets,
        vertical: dialogInsets,
      ),
      child: SafeArea(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: dialogWidth,
            maxHeight: maxDialogHeight,
          ),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final contentWidth = constraints.maxWidth.isFinite ? constraints.maxWidth : dialogWidth;

              return Padding(
                padding: EdgeInsets.all(isSmallScreen ? 12 : 20),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header
                      Row(
                        children: [
                          Icon(Icons.add_location, color: Colors.green[700], size: 28),
                          const SizedBox(width: 12),
                          Text(
                            'Create New Site',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.green[700],
                            ),
                          ),
                          const Spacer(),
                          IconButton(
                            onPressed: () => Navigator.of(context).pop(),
                            icon: const Icon(Icons.close),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // Location & Permits Actions
                      _buildLocationActions(contentWidth),
                      const SizedBox(height: 16),

                      // Form Fields
                      Expanded(
                        child: SingleChildScrollView(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Site Name
                              TextFormField(
                                controller: _nameController,
                                decoration: const InputDecoration(
                                  labelText: 'Site Name *',
                                  hintText: 'Enter a descriptive name for this site',
                                  border: OutlineInputBorder(),
                                ),
                                validator: (value) {
                                  if (value == null || value.trim().isEmpty) {
                                    return 'Site name is required';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 16),

                              // Address Fields with autocomplete suggestions
                              _buildAddressSection(contentWidth),

                              const SizedBox(height: 12),

                              if (_latitude != null && _longitude != null)
                                Row(
                                  children: [
                                    const Icon(Icons.place, size: 16, color: Colors.grey),
                                    const SizedBox(width: 6),
                                    Text(
                                      'Resolved: (${_latitude!.toStringAsFixed(5)}, ${_longitude!.toStringAsFixed(5)})',
                                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                                    ),
                                  ],
                                ),

                              const SizedBox(height: 12),

                              // Mini map preview with tap-to-set location
                              SizedBox(
                                height: isSmallScreen ? 150 : 200,
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: FlutterMap(
                                    mapController: _mapController,
                                    options: MapOptions(
                                      initialCenter: LatLng(_latitude ?? -37.8136, _longitude ?? 144.9631),
                                      initialZoom: 14,
                                      onTap: (tapPos, latlng) async {
                                        setState(() {
                                          _latitude = latlng.latitude;
                                          _longitude = latlng.longitude;
                                        });
                                      },
                                    ),
                                    children: [
                                      TileLayer(
                                        urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                                        userAgentPackageName: 'com.arborist.assistant',
                                      ),
                                      if (_latitude != null && _longitude != null)
                                        MarkerLayer(markers: [
                                          Marker(
                                            point: LatLng(_latitude!, _longitude!),
                                            width: 30,
                                            height: 30,
                                            child: const Icon(Icons.location_on, color: Colors.red, size: 30),
                                          ),
                                        ]),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(height: 24),

                              // Permits summary panel (if available)
                              if (_permitResult != null) ...[
                                Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: Colors.green.withOpacity(0.06),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: Colors.green.withOpacity(0.3)),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Icon(Icons.verified, color: Colors.green[700]),
                                          const SizedBox(width: 8),
                                          Text('Permits & Planning Summary', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green[800])),
                                          const Spacer(),
                                          if (_latitude != null && _longitude != null)
                                            Text('(${_latitude!.toStringAsFixed(5)}, ${_longitude!.toStringAsFixed(5)})', style: const TextStyle(fontSize: 12)),
                                        ],
                                      ),
                                      const SizedBox(height: 8),
                                      Text('LGA: ${_permitResult!['lga'] ?? 'Unknown'}', 
                                        style: const TextStyle(fontWeight: FontWeight.w500)),
                                      
                                      // Show LGA-specific tree protection rules
                                      if (_permitResult!['lga'] != null) ...[
                                        const SizedBox(height: 8),
                                        _buildLGARules(_permitResult!['lga']),
                                      ],
                                      
                                      const SizedBox(height: 12),
                                      
                                      // Display overlays with detailed info
                                      if (overlays != null && overlays.isNotEmpty) ...[
                                        Text('Planning Overlays:', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green[800])),
                                        const SizedBox(height: 8),
                                        ...overlays.map((overlay) {
                                          final code = overlay['code']?.toString() ?? overlay['name']?.toString() ?? 'Unknown';
                                          final description = _getOverlayDescription(code);
                                          final impact = _getOverlayImpact(code);
                                          final overlayTitle = _getOverlayTitle(code);
                                          
                                          return Container(
                                            margin: const EdgeInsets.only(bottom: 10),
                                            padding: const EdgeInsets.all(10),
                                            decoration: BoxDecoration(
                                              color: impact == 'high' ? Colors.red.shade50 :
                                                     impact == 'medium' ? Colors.orange.shade50 : Colors.blue.shade50,
                                              borderRadius: BorderRadius.circular(6),
                                              border: Border.all(
                                                color: impact == 'high' ? Colors.red.shade300 :
                                                       impact == 'medium' ? Colors.orange.shade300 : Colors.blue.shade300,
                                                width: 1.5,
                                              ),
                                            ),
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Row(
                                                  children: [
                                                    Icon(
                                                      impact == 'high' ? Icons.warning_amber_rounded :
                                                      impact == 'medium' ? Icons.info_outline : Icons.check_circle_outline,
                                                      size: 18,
                                                      color: impact == 'high' ? Colors.red.shade700 :
                                                             impact == 'medium' ? Colors.orange.shade700 : Colors.blue.shade700,
                                                    ),
                                                    const SizedBox(width: 8),
                                                    Expanded(
                                                      child: Text(
                                                        '$code - $overlayTitle',
                                                        style: TextStyle(
                                                          fontWeight: FontWeight.bold,
                                                          fontSize: 14,
                                                          color: impact == 'high' ? Colors.red.shade900 :
                                                                 impact == 'medium' ? Colors.orange.shade900 : Colors.blue.shade900,
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                                const SizedBox(height: 6),
                                                Text(
                                                  description,
                                                  style: TextStyle(fontSize: 12, color: Colors.grey[800], height: 1.4),
                                                ),
                                              ],
                                            ),
                                          );
                                        }).toList(),
                                      ] else
                                        Text('No planning overlays detected', style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                                      
                                      const SizedBox(height: 8),
                                      if (_permitResult?['permit_data'] != null)
                                        ...((_permitResult!['permit_data'] as Map).cast<String, dynamic>()).entries.take(3).map((e) =>
                                          Text('• ${e.key.replaceAll('_', ' ')}: ${e.value}', style: const TextStyle(fontSize: 12))),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 24),
                              ],

                              // Info Text
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Colors.blue.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: Colors.blue.withValues(alpha: 0.3)),
                                ),
                                child: Row(
                                  children: [
                                    Icon(Icons.info, color: Colors.blue[700]),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        'This is a simplified version. Planning data features will be added back once basic functionality is confirmed working.',
                                        style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              const SizedBox(height: 16),

                              // Action Buttons
                              _buildFooterActions(contentWidth),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            },
          ),
        ),
      ),
    );
  }

  Widget _buildLocationActions(double contentWidth) {
    final stackVertically = contentWidth < 460;

    Widget buildVicmapToggle() {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('Vicmap live', style: TextStyle(fontSize: 13)),
          Switch(
            value: _useVicmapLive,
            onChanged: (v) => setState(() => _useVicmapLive = v),
          ),
        ],
      );
    }

    List<Widget> buildStatusBadges() {
      final badges = <Widget>[];
      if (_checkingPermits) {
        badges.add(const SizedBox(
          width: 18,
          height: 18,
          child: CircularProgressIndicator(strokeWidth: 2),
        ));
      }
      if (_permitResult != null && !_checkingPermits) {
        badges.add(Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.green.withOpacity(0.1),
            border: Border.all(color: Colors.green.shade300),
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Text('Permits checked', style: TextStyle(color: Colors.green, fontSize: 12)),
        ));
      }
      return badges;
    }

    final locationButton = ElevatedButton.icon(
      onPressed: _checkingPermits ? null : _findMyLocationAndPermits,
      icon: const Icon(Icons.my_location, size: 18),
      label: const Text('Find location & permits', style: TextStyle(fontSize: 13)),
    );
    final confirmButton = OutlinedButton.icon(
      onPressed: _checkingPermits ? null : _confirmAddressAndPermits,
      icon: const Icon(Icons.check_circle_outline, size: 18),
      label: const Text('Confirm & permits', style: TextStyle(fontSize: 13)),
    );
    final statusBadges = buildStatusBadges();

    if (stackVertically) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          locationButton,
          const SizedBox(height: 8),
          confirmButton,
          const SizedBox(height: 12),
          buildVicmapToggle(),
          if (statusBadges.isNotEmpty) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: statusBadges,
            ),
          ],
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(child: locationButton),
            const SizedBox(width: 12),
            Expanded(child: confirmButton),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            buildVicmapToggle(),
            const SizedBox(width: 12),
            Expanded(
              child: Wrap(
                alignment: WrapAlignment.end,
                spacing: 8,
                runSpacing: 8,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: statusBadges,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildAddressSection(double contentWidth) {
    final isNarrow = contentWidth < 600;

    Widget buildSuggestionsList() {
      if (!_showAddressSuggestions) {
        return const SizedBox.shrink();
      }
      return Container(
        constraints: const BoxConstraints(maxHeight: 160),
        margin: const EdgeInsets.only(top: 4),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(4),
        ),
        child: ListView.builder(
          shrinkWrap: true,
          itemCount: _addressSuggestions.length,
          itemBuilder: (context, idx) {
            final s = _addressSuggestions[idx];
            return ListTile(
              dense: true,
              title: Text(s, style: const TextStyle(fontSize: 13)),
              onTap: () async {
                setState(() {
                  _addressController.text = s;
                  _showAddressSuggestions = false;
                });
                Map<String, double>? coords = await AddressAutocompleteService.getCoordinatesForAddress('$s, VIC, Australia');
                if ((coords == null || coords['latitude'] == null) && kIsWeb) {
                  coords = await WebGeocodingService.geocodeAddress('$s, VIC, Australia');
                }
                final lat = coords?['latitude'];
                final lng = coords?['longitude'];
                if (lat != null && lng != null) {
                  setState(() {
                    _latitude = lat;
                    _longitude = lng;
                  });
                  try {
                    _mapController.move(LatLng(_latitude!, _longitude!), 16);
                  } catch (_) {}
                }
              },
            );
          },
        ),
      );
    }

    Widget buildAddressField() {
      return TextFormField(
        controller: _addressController,
        decoration: const InputDecoration(
          labelText: 'Street Address *',
          hintText: '123 Main Street',
          border: OutlineInputBorder(),
        ),
        onChanged: (v) async {
          final q = v.trim();
          if (q.length >= 2) {
            final list = await AddressAutocompleteService.getAddressSuggestions(q);
            setState(() {
              _addressSuggestions = list;
              _showAddressSuggestions = list.isNotEmpty;
            });
          } else {
            setState(() => _showAddressSuggestions = false);
          }
          _addressDebounce?.cancel();
          _addressDebounce = Timer(const Duration(milliseconds: 500), () async {
            final full = '${_addressController.text}, ${_suburbController.text} ${_postcodeController.text}, VIC, Australia';
            Map<String, double>? coords = await AddressAutocompleteService.getCoordinatesForAddress(full);
            if ((coords == null || coords['latitude'] == null) && kIsWeb) {
              coords = await WebGeocodingService.geocodeAddress(full);
            }
            final lat = coords?['latitude'];
            final lng = coords?['longitude'];
            if (lat != null && lng != null) {
              setState(() {
                _latitude = lat;
                _longitude = lng;
              });
              try {
                _mapController.move(LatLng(_latitude!, _longitude!), 16);
              } catch (_) {}
            }
          });
        },
        validator: (value) {
          if (value == null || value.trim().isEmpty) {
            return 'Street address is required';
          }
          return null;
        },
      );
    }

    Widget buildSuburbField() {
      return TextFormField(
        controller: _suburbController,
        decoration: const InputDecoration(
          labelText: 'Suburb *',
          hintText: 'Melbourne',
          border: OutlineInputBorder(),
        ),
        validator: (value) {
          if (value == null || value.trim().isEmpty) {
            return 'Suburb is required';
          }
          return null;
        },
      );
    }

    Widget buildPostcodeField() {
      return TextFormField(
        controller: _postcodeController,
        decoration: const InputDecoration(
          labelText: 'Postcode *',
          hintText: '3000',
          border: OutlineInputBorder(),
        ),
        validator: (value) {
          if (value == null || value.trim().isEmpty) {
            return 'Postcode is required';
          }
          final v = value.trim();
          if (!RegExp(r'^\d{4}$').hasMatch(v)) {
            return 'Enter a 4-digit postcode';
          }
          return null;
        },
      );
    }

    if (isNarrow) {
      return Column(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              buildAddressField(),
              buildSuggestionsList(),
            ],
          ),
          const SizedBox(height: 16),
          buildSuburbField(),
          const SizedBox(height: 16),
          buildPostcodeField(),
        ],
      );
    }

    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              buildAddressField(),
              buildSuggestionsList(),
            ],
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              buildSuburbField(),
              const SizedBox(height: 16),
              buildPostcodeField(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFooterActions(double contentWidth) {
    final isNarrow = contentWidth < 600;

    Widget buildCancelButton() {
      return TextButton(
        onPressed: () => Navigator.of(context).pop(),
        child: Text(
          'Cancel',
          style: TextStyle(fontSize: 14, color: Colors.grey.shade700),
        ),
      );
    }

    Widget buildCreateButton() {
      return ElevatedButton(
        onPressed: _checkingPermits ? null : _createSite,
        child: const Text('Create Site', style: TextStyle(fontSize: 14)),
      );
    }

    if (isNarrow) {
      return Column(
        children: [
          buildCancelButton(),
          const SizedBox(height: 12),
          buildCreateButton(),
        ],
      );
    }

    return Row(
      children: [
        buildCancelButton(),
        const SizedBox(width: 12),
        Expanded(child: buildCreateButton()),
      ],
    );
  }
}
