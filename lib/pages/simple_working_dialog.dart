import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:math' as math;
import 'dart:html' as html;

import '../models/site.dart';
import '../services/site_storage_service.dart';
import '../services/real_planning_service.dart';
import '../services/vicplan_service.dart';
import '../services/planning_ai_service.dart';
import '../services/regulatory_data_service.dart';
import '../models/lga_tree_law.dart';
import 'site_main_page.dart';

class SimpleWorkingDialog extends StatefulWidget {
  final Function(Site) onSiteCreated;
  const SimpleWorkingDialog({Key? key, required this.onSiteCreated}) : super(key: key);

  @override
  State<SimpleWorkingDialog> createState() => _SimpleWorkingDialogState();
}

class _SimpleWorkingDialogState extends State<SimpleWorkingDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _addressController = TextEditingController();

  bool _isLoadingLocation = false;
  bool _isLoadingPermits = false;
  Map<String, dynamic>? _planningData;
  LgaTreeLaw? _verifiedTreeLaw;
  final RegulatoryDataService _regulatoryService = RegulatoryDataService.instance;
  bool _showAIExplanation = false; // Collapsed by default

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  // ---------- Pure geocoding helpers (no guesses) ----------
  Future<Map<String, double>?> _geocodeAddress(String address) async {
    try {
      final res = await http.get(
        Uri.parse('https://nominatim.openstreetmap.org/search?q=${Uri.encodeComponent(address)}&format=json&limit=1'),
        headers: {'User-Agent': 'ArboristAssistant/1.0'},
      );
      if (res.statusCode == 200) {
        final data = json.decode(res.body) as List;
        if (data.isNotEmpty) {
          final m = data.first as Map<String, dynamic>;
          return {'lat': double.parse(m['lat']), 'lon': double.parse(m['lon'])};
        }
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  Future<String?> _reverseGeocodeAddress(double lat, double lon) async {
    try {
      final res = await http.get(
        Uri.parse('https://nominatim.openstreetmap.org/reverse?lat=$lat&lon=$lon&format=json&addressdetails=1'),
        headers: {'User-Agent': 'ArboristAssistant/1.0'},
      );
      if (res.statusCode == 200) {
        final data = json.decode(res.body) as Map<String, dynamic>;
        final a = data['address'] as Map<String, dynamic>?;
        if (a != null) {
          final house = a['house_number']?.toString() ?? '';
          final road = a['road']?.toString() ?? '';
          final suburb = a['suburb']?.toString() ?? a['city']?.toString() ?? a['town']?.toString() ?? '';
          final postcode = a['postcode']?.toString() ?? '';
          final parts = <String>[];
          if (house.isNotEmpty) parts.add(house);
          if (road.isNotEmpty) parts.add(road);
          if (suburb.isNotEmpty) parts.add(suburb);
          if (postcode.isNotEmpty) parts.add(postcode);
          if (parts.isNotEmpty) return parts.join(', ');
        }
        return data['display_name'] as String?;
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  // ---------- Location ----------
  Future<void> _findLocation() async {
    setState(() => _isLoadingLocation = true);
    try {
      if (!await Geolocator.isLocationServiceEnabled()) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Location services are disabled.')));
        return;
      }
      var perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
        if (perm == LocationPermission.denied) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Location permission denied.')));
          return;
        }
      }
      if (perm == LocationPermission.deniedForever) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Location permission permanently denied.')));
        return;
      }

      final readings = <Position>[];
      for (int i = 0; i < 5; i++) {
        try {
          final p = await Geolocator.getCurrentPosition(
            desiredAccuracy: LocationAccuracy.bestForNavigation,
            timeLimit: const Duration(milliseconds: 30000),
          );
          readings.add(p);
          await Future.delayed(const Duration(milliseconds: 800));
        } catch (_) {}
      }
      if (readings.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Could not get location.')));
        return;
      }
      final use = readings.where((p) => p.accuracy <= 10).toList();
      final chosen = use.isNotEmpty ? use : readings;

      double wSum = 0, latW = 0, lonW = 0;
      for (final p in chosen) {
        final w = 1 / (p.accuracy + 1);
        wSum += w; latW += p.latitude * w; lonW += p.longitude * w;
      }
      final lat = latW / wSum, lon = lonW / wSum;

      final addr = await _reverseGeocodeAddress(lat, lon);
      setState(() {
        _addressController.text = addr?.trim().isNotEmpty == true
            ? addr!.trim()
            : 'GPS Location: ${lat.toStringAsFixed(6)}, ${lon.toStringAsFixed(6)}';
        _planningData = null;
      });
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Location found. Tap Permits to load planning data.')));
    } finally {
      setState(() => _isLoadingLocation = false);
    }
  }

  // ---------- Minimal normalisers (no invented data) ----------
  List<Map<String, dynamic>> _normOverlays(List<dynamic> raw) {
    return raw.map<Map<String, dynamic>>((e) {
      final a = Map<String, dynamic>.from(e as Map);
      String pick(List<String> ks) => ks.map((k) => a[k]).firstWhere((v) => v != null, orElse: () => '').toString();
      final code = pick(['overlay','OVERLAY','OVERLAY_CODE','scheme_code']);
      final desc = pick(['description','OVERLAY_DESC','DESCRIPTION']);
      final scheme = pick(['scheme_name','SCHEME_NAME','PLANNING_SCHEME_NAME']);
      return {
        'code': code,
        'description': desc.isNotEmpty ? desc : scheme,
        'raw': a,
      };
    }).toList();
  }

  List<Map<String, dynamic>> _normZones(List<dynamic> raw) {
    return raw.map<Map<String, dynamic>>((e) {
      final a = Map<String, dynamic>.from(e as Map);
      String pick(List<String> ks) => ks.map((k) => a[k]).firstWhere((v) => v != null, orElse: () => '').toString();
      final code = pick(['zone','ZONE_CODE','ZONE','ZONEID','code']);
      final desc = pick(['description','ZONE_DESC','DESCRIPTION']);
      final scheme = pick(['scheme_name','SCHEME_NAME','PLANNING_SCHEME_NAME']);
      final lga = pick(['LGA_NAME','lga_name','LGA']);
      return {
        'code': code,
        'description': desc.isNotEmpty ? desc : scheme,
        'lga': lga,
        'raw': a,
      };
    }).toList();
  }

  // ---------- Load REAL planning data only ----------
  Future<void> _loadPlanningData() async {
    if (_addressController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter an address first')));
      return;
    }

    setState(() => _isLoadingPermits = true);
    try {
      final full = '${_addressController.text.trim()}, VIC, Australia';
      final geo = await _geocodeAddress(full);
      if (geo == null) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Could not geocode the address')));
        return;
      }

      final resp = await RealPlanningService.getPlanningAtPoint(
        latitude: geo['lat']!,
        longitude: geo['lon']!,
      );

      // Extract LGA from response - it comes directly in the lga field as a Map with 'LGA' key
      String lgaName = 'Unknown';
      if (resp['lga'] != null) {
        final lgaData = resp['lga'];
        if (lgaData is Map) {
          lgaName = (lgaData['LGA'] ?? lgaData['lga'] ?? lgaData['LGA_NAME'] ?? lgaData['lga_name'] ?? '').toString();
        } else {
          lgaName = lgaData.toString();
        }
      }
      
      // If still unknown, try to get from overlays (MapServer includes LGA field)
      if (lgaName == 'Unknown' || lgaName.isEmpty) {
        final overlaysRaw = (resp['overlays'] as List?) ?? const [];
        if (overlaysRaw.isNotEmpty && overlaysRaw.first is Map) {
          final firstOverlay = overlaysRaw.first as Map;
          lgaName = (firstOverlay['LGA'] ?? firstOverlay['lga'] ?? '').toString();
        }
      }
      final overlays = _normOverlays((resp['overlays'] as List?) ?? const []);
      final zones = _normZones((resp['zones'] as List?) ?? const []);

      // Get LGA key for tree protection laws
      final lgaKey = lgaName.toLowerCase()
          .replaceAll('city of ', '')
          .replaceAll('shire of ', '')
          .replaceAll('rural city of ', '')
          .replaceAll(' ', '_');
      
      // Get tree protection laws for this LGA
      final lgaInfo = VicPlanService.getLgaInfo(lgaKey);
      final treeProtection = lgaInfo?['treeProtection'] ?? 'Contact council for tree protection requirements';
      final vicplanUrl = lgaInfo?['vicplanUrl'] ?? 'https://www.planning.vic.gov.au';
      
      // FORCE AI initialization before generating
      print('🔧 Ensuring AI service is initialized...');
      await PlanningAIService.initialize();
      
      // Generate AI permit summary if available
      String aiSummary = '';
      String lgaLocalLaws = '';
      if (overlays.isNotEmpty || zones.isNotEmpty) {
        try {
          print('🤖 Generating AI summary for site planning data...');
          aiSummary = await PlanningAIService.generatePermitSummary(
            lga: lgaName,
            overlays: overlays,
            zones: zones,
          ).timeout(const Duration(seconds: 20));
          print('✅ AI summary generated for site');
        } catch (e) {
          print('⚠️ AI summary generation failed: $e');
        }
      }
      
      // Generate LGA-specific local laws
      print('🏛️ Attempting to generate LGA local laws for: $lgaName');
      try {
        lgaLocalLaws = await PlanningAIService.generateLGALocalLaws(
          lga: lgaName,
        ).timeout(const Duration(seconds: 15));
        print('✅ LGA local laws result: ${lgaLocalLaws.substring(0, lgaLocalLaws.length > 100 ? 100 : lgaLocalLaws.length)}...');
      } catch (e) {
        print('⚠️ LGA local laws generation failed: $e');
        lgaLocalLaws = 'Contact $lgaName council for Local Law tree protection requirements.';
      }

      // Load verified regulatory data from CSV
      try {
        await _regulatoryService.loadData();
        if (lgaName.isNotEmpty && lgaName != 'Unknown') {
          _verifiedTreeLaw = _regulatoryService.getLgaTreeLaw(lgaName);
        }
      } catch (e) {
        print('⚠️ Could not load regulatory data: $e');
      }

      setState(() {
        _planningData = {
          'address': full,
          'coordinates': '${geo['lat']!.toStringAsFixed(6)}, ${geo['lon']!.toStringAsFixed(6)}',
          'timestamp': DateTime.now().toIso8601String(),
          'lga': lgaName.isNotEmpty ? lgaName : 'Unknown',
          'lgaKey': lgaKey,
          'treeProtection': treeProtection,
          'lgaLocalLaws': lgaLocalLaws,
          'vicplanUrl': vicplanUrl,
          'overlays': overlays,
          'zones': zones,
          'aiSummary': aiSummary,
          'data_source': 'Vicmap Planning (Overlays=2, Zones=3) + Vicmap_Admin LGA (9)',
          'raw': resp['raw'] ?? {},
        };
      });

      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Planning data loaded.')));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error loading planning data: $e')));
    } finally {
      setState(() => _isLoadingPermits = false);
    }
  }

  // ---------- Helper functions for overlay explanations ----------
  String _getOverlayTreeExplanation(String code) {
    switch (code) {
      case 'VPO': return 'Vegetation Protection Overlay';
      case 'DCPO': return 'Development Contributions Plan Overlay';
      case 'ESO': return 'Environmental Significance Overlay';
      case 'HO': return 'Heritage Overlay';
      case 'DDO': return 'Design and Development Overlay';
      case 'SLO': return 'Significant Landscape Overlay';
      case 'BMO': return 'Bushfire Management Overlay';
      default: return 'Planning Overlay';
    }
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 11),
            ),
          ),
        ],
      ),
    );
  }

  String _getOverlayTreeRequirements(String code) {
    switch (code) {
      case 'VPO': return 'Native vegetation and significant trees protected. Planning permit required for tree removal.';
      case 'DCPO': return 'Development contributions may apply. Check council for tree protection requirements.';
      case 'ESO': return 'Environmental values protected. Tree work may require environmental assessment.';
      case 'HO': return 'Heritage trees protected. Special permits required for any tree work.';
      case 'DDO': return 'Design controls may include tree protection. Check specific guidelines.';
      case 'SLO': return 'Landscape character important. Tree removal may affect landscape values.';
      case 'BMO': return 'Bushfire risk area. Tree removal may be required for safety.';
      default: return 'Check council for specific tree protection requirements.';
    }
  }

  String _getOverlayDescription(String code) {
    // Use AI-powered detailed summaries from VicPlanService
    return VicPlanService.getOverlaySummary(code);
  }

  String _getZoneDescription(String code) {
    // Use AI-powered detailed summaries from VicPlanService
    return VicPlanService.getOverlaySummary(code);
  }

  void _createSite() {
    if (_formKey.currentState!.validate()) {
      final address = _addressController.text.trim().isNotEmpty
          ? '${_addressController.text.trim()}, VIC, Australia'
          : 'Address not specified, VIC, Australia';

      // Extract coordinates if planning data is available
      double? latitude;
      double? longitude;
      if (_planningData != null && _planningData!['coordinates'] != null) {
        try {
          final coordsStr = _planningData!['coordinates'] as String;
          final parts = coordsStr.split(',');
          if (parts.length == 2) {
            latitude = double.parse(parts[0].trim());
            longitude = double.parse(parts[1].trim());
          }
        } catch (e) {
          print('Error parsing coordinates: $e');
        }
      }

      final site = Site(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: _nameController.text.trim(),
        address: address,
        notes: 'Created from accurate Vicmap data only',
        createdAt: DateTime.now(),
        latitude: latitude,
        longitude: longitude,
        vicPlanData: _planningData,
      );

      SiteStorageService.addSite(site);
      widget.onSiteCreated(site);
      Navigator.of(context).pop();
      
      // Show post-creation guidance dialog
      _showPostCreationDialog(context, site);
    }
  }
  
  void _showPostCreationDialog(BuildContext context, Site site) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green[700], size: 28),
            const SizedBox(width: 12),
            const Text('Site Created!'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${site.name} has been created successfully.'),
            const SizedBox(height: 16),
            const Text('What would you like to do next?', style: TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        actions: [
          TextButton.icon(
            icon: const Icon(Icons.info),
            label: const Text('View Permit Requirements'),
            onPressed: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => SiteMainPage(site: site, initialTab: 3), // Details tab
                ),
              );
            },
          ),
          TextButton.icon(
            icon: const Icon(Icons.eco),
            label: const Text('Add Trees'),
            onPressed: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => SiteMainPage(site: site, initialTab: 1), // Trees tab
                ),
              );
            },
          ),
          TextButton.icon(
            icon: const Icon(Icons.map),
            label: const Text('View Map'),
            onPressed: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => SiteMainPage(site: site, initialTab: 0), // Map tab
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  // ---------- UI ----------
  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        width: 600,
        height: MediaQuery.of(context).size.height * 0.9,
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.add_location, color: Colors.green[700], size: 28),
                  const SizedBox(width: 12),
                  Text(
                    'Add New Site',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.green[700]),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextFormField(
                        controller: _nameController,
                        decoration: const InputDecoration(
                          labelText: 'Site Name *',
                          hintText: 'Enter site name',
                          border: OutlineInputBorder(),
                        ),
                        validator: (v) => (v == null || v.trim().isEmpty) ? 'Site name is required' : null,
                      ),
                      const SizedBox(height: 16),

                      TextFormField(
                        controller: _addressController,
                        decoration: const InputDecoration(
                          labelText: 'Address *',
                          hintText: 'Enter full address (e.g., 123 Main Street, Melbourne VIC 3000)',
                          border: OutlineInputBorder(),
                        ),
                        maxLines: 2,
                        validator: (v) => (v == null || v.trim().isEmpty) ? 'Address is required' : null,
                      ),
                      const SizedBox(height: 16),

                      // Permit loading hint
                      if (_addressController.text.isNotEmpty && _planningData == null && !_isLoadingPermits)
                        Container(
                          padding: const EdgeInsets.all(12),
                          margin: const EdgeInsets.only(bottom: 16),
                          decoration: BoxDecoration(
                            color: Colors.orange[50],
                            border: Border.all(color: Colors.orange[300]!, width: 2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.info, color: Colors.orange[700], size: 20),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  '💡 Tap "Load Permits" to get planning data and tree protection requirements',
                                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.orange[900]),
                                ),
                              ),
                            ],
                          ),
                        ),

                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: _isLoadingLocation ? null : _findLocation,
                              icon: _isLoadingLocation
                                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                                  : const Icon(Icons.my_location),
                              label: Text(_isLoadingLocation ? 'Finding...' : 'Find My Location'),
                              style: ElevatedButton.styleFrom(backgroundColor: Colors.blue[600], foregroundColor: Colors.white),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            flex: 2,
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 300),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(4),
                                boxShadow: _addressController.text.isNotEmpty && _planningData == null && !_isLoadingPermits
                                    ? [
                                        BoxShadow(
                                          color: Colors.orange.withOpacity(0.5),
                                          blurRadius: 8,
                                          spreadRadius: 2,
                                        ),
                                      ]
                                    : [],
                              ),
                              child: ElevatedButton.icon(
                                onPressed: _isLoadingPermits ? null : _loadPlanningData,
                                icon: _isLoadingPermits
                                    ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                                    : const Icon(Icons.gavel),
                                label: Text(_isLoadingPermits ? 'Loading...' : 'Load Permits'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.orange[600],
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () {
                                setState(() { 
                                  _addressController.clear(); 
                                  _planningData = null; 
                                });
                                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Address cleared')));
                              },
                              icon: const Icon(Icons.clear),
                              label: const Text('Clear'),
                              style: ElevatedButton.styleFrom(backgroundColor: Colors.grey[600], foregroundColor: Colors.white),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      if (_planningData?['coordinates'] != null) ...[
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.green.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.green.withOpacity(0.3)),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.check_circle, color: Colors.green[700]),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Location: ${_planningData!['coordinates']}',
                                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.green[700]),
                                    ),
                                    if (_planningData!['address'] != null) ...[
                                      const SizedBox(height: 8),
                                      Text(
                                        'Address: ${_planningData!['address']}',
                                        style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],

                      if (_planningData != null) ...[
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.blue.withOpacity(0.05),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.blue.withOpacity(0.3)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(Icons.info, color: Colors.blue[700], size: 20),
                                  const SizedBox(width: 8),
                                  Text(
                                    'PLANNING SUMMARY',
                                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.blue[700]),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              
                              _InfoRow(label: 'LGA', value: _planningData!['lga'] ?? 'Unknown'),
                              const SizedBox(height: 16),
                              
                              // VERIFIED Local Laws (from CSV)
                              if (_verifiedTreeLaw != null && _verifiedTreeLaw!.hasLocalLaw) ...[
                                Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: Colors.green.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: Colors.green[700]!, width: 3),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Icon(Icons.verified, color: Colors.green[700], size: 20),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Text(
                                              'Local Law Requirements (Verified)',
                                              style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.green[900]),
                                            ),
                                          ),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                            decoration: BoxDecoration(
                                              color: Colors.green[600],
                                              borderRadius: BorderRadius.circular(12),
                                            ),
                                            child: const Text(
                                              'VERIFIED',
                                              style: TextStyle(fontSize: 9, color: Colors.white, fontWeight: FontWeight.bold),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const Divider(height: 20, thickness: 2),
                                      _buildInfoRow('Council', _verifiedTreeLaw!.councilFullName),
                                      _buildInfoRow('Local Law', '${_verifiedTreeLaw!.localLawNumber} (${_verifiedTreeLaw!.localLawYear})'),
                                      _buildInfoRow('Size Threshold', _verifiedTreeLaw!.displayThreshold),
                                      if (_verifiedTreeLaw!.permitFeeStandard.isNotEmpty)
                                        _buildInfoRow('Permit Fee', '\$${_verifiedTreeLaw!.permitFeeStandard}'),
                                      if (_verifiedTreeLaw!.processingDaysMin.isNotEmpty)
                                        _buildInfoRow('Processing', '${_verifiedTreeLaw!.processingDaysMin}-${_verifiedTreeLaw!.processingDaysMax} days'),
                                      if (_verifiedTreeLaw!.phone.isNotEmpty)
                                        _buildInfoRow('Phone', _verifiedTreeLaw!.phone),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 16),
                              ],
                              
                              // LGA Local Laws (AI Explanation - Supplementary) - Collapsible
                              if (_planningData!['lgaLocalLaws'] != null && _planningData!['lgaLocalLaws'].toString().isNotEmpty) ...[
                                Container(
                                  margin: const EdgeInsets.only(bottom: 16),
                                  decoration: BoxDecoration(
                                    color: Colors.indigo.withOpacity(0.05),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: Colors.indigo.withOpacity(0.2)),
                                  ),
                                  child: Column(
                                    children: [
                                      InkWell(
                                        onTap: () {
                                          setState(() {
                                            _showAIExplanation = !_showAIExplanation;
                                          });
                                        },
                                        child: Padding(
                                          padding: const EdgeInsets.all(12),
                                          child: Row(
                                            children: [
                                              Icon(
                                                _showAIExplanation ? Icons.expand_less : Icons.expand_more,
                                                color: Colors.indigo[700],
                                                size: 20,
                                              ),
                                              const SizedBox(width: 8),
                                              Icon(Icons.psychology, color: Colors.indigo[700], size: 16),
                                              const SizedBox(width: 8),
                                              Expanded(
                                                child: Text(
                                                  _showAIExplanation ? 'Hide AI Explanation' : 'Show AI Explanation (Supplementary)',
                                                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.indigo[700]),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                      if (_showAIExplanation) ...[
                                        const Divider(height: 1),
                                        Padding(
                                          padding: const EdgeInsets.all(12),
                                          child: Text(
                                            _planningData!['lgaLocalLaws'],
                                            style: TextStyle(fontSize: 11, color: Colors.grey[700], height: 1.5),
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              ],

                              // Zones
                              _CardSection(
                                title: 'Zones (${(_planningData!['zones'] as List).length})',
                                icon: Icons.map,
                                color: Colors.teal,
                                child: Column(
                                  children: (_planningData!['zones'] as List)
                                      .map<Widget>((z) {
                                        final m = Map<String, dynamic>.from(z as Map);
                                        final code = m['code'] ?? 'ZONE';
                                        final description = m['description'] ?? '';
                                        
                                        return Container(
                                          margin: const EdgeInsets.only(bottom: 12),
                                          padding: const EdgeInsets.all(12),
                                          decoration: BoxDecoration(
                                            color: Colors.white,
                                            borderRadius: BorderRadius.circular(6),
                                            border: Border.all(color: Colors.teal.withOpacity(0.2)),
                                          ),
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Row(
                                                children: [
                                                  Container(
                                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                                    decoration: BoxDecoration(
                                                      color: Colors.teal[600],
                                                      borderRadius: BorderRadius.circular(12),
                                                    ),
                                                    child: Text(
                                                      code,
                                                      style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                                                    ),
                                                  ),
                                                  const SizedBox(width: 12),
                                                  Expanded(
                                                    child: Text(
                                                      description,
                                                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.grey[800]),
                                                      softWrap: true,
                                                      overflow: TextOverflow.visible,
                                                      maxLines: null,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              const SizedBox(height: 8),
                                              code == 'GRZ' || code == 'NRZ' || code == 'RGZ' || code == 'MUZ' || code == 'IN1Z' || code == 'C1Z' || code == 'PZ' || code == 'PUZ'
                                                ? Text(
                                                    _getZoneDescription(code),
                                                    style: TextStyle(fontSize: 11, color: Colors.grey[700], height: 1.4),
                                                    softWrap: true,
                                                    overflow: TextOverflow.visible,
                                                  )
                                                : GestureDetector(
                                                    onTap: () {
                                                      if (kIsWeb) {
                                                        // ignore: undefined_prefixed_name
                                                        html.window.open('https://www.planning.vic.gov.au/planning-schemes/zones', '_blank');
                                                      }
                                                    },
                                                    child: Row(
                                                      children: [
                                                        Expanded(
                                                          child: Text(
                                                            _getZoneDescription(code),
                                                            style: TextStyle(fontSize: 11, color: Colors.grey[700], height: 1.4),
                                                            softWrap: true,
                                                            overflow: TextOverflow.visible,
                                                          ),
                                                        ),
                                                        Icon(Icons.link, color: Colors.blue[600], size: 14),
                                                      ],
                                                    ),
                                                  ),
                                            ],
                                          ),
                                        );
                                      })
                                      .toList(),
                                ),
                              ),
                              const SizedBox(height: 12),

                              // Overlays
                              _CardSection(
                                title: 'Overlays (${(_planningData!['overlays'] as List).length})',
                                icon: Icons.layers,
                                color: Colors.orange,
                                child: Column(
                                  children: (_planningData!['overlays'] as List)
                                      .map<Widget>((o) {
                                        final m = Map<String, dynamic>.from(o as Map);
                                        final code = m['code'] ?? 'OVERLAY';
                                        final description = m['description'] ?? '';
                                        
                                        return Container(
                                          margin: const EdgeInsets.only(bottom: 12),
                                          padding: const EdgeInsets.all(12),
                                          decoration: BoxDecoration(
                                            color: Colors.white,
                                            borderRadius: BorderRadius.circular(6),
                                            border: Border.all(color: Colors.orange.withOpacity(0.2)),
                                          ),
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Row(
                                                children: [
                                                  Container(
                                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                                    decoration: BoxDecoration(
                                                      color: Colors.orange[600],
                                                      borderRadius: BorderRadius.circular(12),
                                                    ),
                                                    child: Text(
                                                      code,
                                                      style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                                                    ),
                                                  ),
                                                  const SizedBox(width: 12),
                                                  Expanded(
                                                    child: Text(
                                                      description,
                                                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.grey[800]),
                                                      softWrap: true,
                                                      overflow: TextOverflow.visible,
                                                      maxLines: null,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              const SizedBox(height: 8),
                                              code == 'VPO' || code == 'DCPO' || code == 'ESO' || code == 'HO' || code == 'DDO' || code == 'SLO' || code == 'BMO'
                                                ? Text(
                                                    _getOverlayDescription(code),
                                                    style: TextStyle(fontSize: 11, color: Colors.grey[700], height: 1.4),
                                                    softWrap: true,
                                                    overflow: TextOverflow.visible,
                                                  )
                                                : GestureDetector(
                                                    onTap: () {
                                                      if (kIsWeb) {
                                                        // ignore: undefined_prefixed_name
                                                        html.window.open('https://www.planning.vic.gov.au/planning-schemes/overlays', '_blank');
                                                      }
                                                    },
                                                    child: Row(
                                                      children: [
                                                        Expanded(
                                                          child: Text(
                                                            _getOverlayDescription(code),
                                                            style: TextStyle(fontSize: 11, color: Colors.grey[700], height: 1.4),
                                                            softWrap: true,
                                                            overflow: TextOverflow.visible,
                                                          ),
                                                        ),
                                                        Icon(Icons.link, color: Colors.blue[600], size: 14),
                                                      ],
                                                    ),
                                                  ),
                                            ],
                                          ),
                                        );
                                      })
                                      .toList(),
                                ),
                              ),
                              const SizedBox(height: 12),

                              // BMO Banner
                              if (_planningData!['overlays'] != null) ...[
                                Builder(builder: (context) {
                                  final overlaysList = (_planningData!['overlays'] as List)
                                      .cast<Map<String, dynamic>>();
                                  final bmoOverlays = overlaysList.where((m) {
                                    final code = (m['code'] ?? '').toString().toUpperCase();
                                    final desc = (m['description'] ?? '').toString().toUpperCase();
                                    return code.contains('BMO') || desc.contains('BUSHFIRE MANAGEMENT');
                                  }).toList();

                                  if (bmoOverlays.isEmpty) return const SizedBox.shrink();

                                  return Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: Colors.orange.withOpacity(0.10),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(color: Colors.orange.withOpacity(0.25)),
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(Icons.local_fire_department, color: Colors.orange[700], size: 18),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            'Bushfire Management Overlay present: '
                                            '${bmoOverlays.map((m) => (m["code"] ?? "BMO").toString()).join(", ")}',
                                            style: TextStyle(fontSize: 13, color: Colors.orange[800]),
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                }),
                                const SizedBox(height: 12),
                              ],


                              Row(
                                children: [
                                  Icon(Icons.refresh, color: Colors.grey[600], size: 16),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      'Data source: ${_planningData!['data_source']} • Retrieved: ${_planningData!['timestamp']}',
                                      style: TextStyle(fontSize: 10, color: Colors.grey[600]),
                                      softWrap: true,
                                      overflow: TextOverflow.visible,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
                    ],
                  ),
                ),
              ),

              // Create Site
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _createSite,
                  icon: const Icon(Icons.add),
                  label: const Text('Create Site'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green[600],
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------- Small UI helpers ----------
class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  const _InfoRow({required this.label, required this.value});
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          '$label: ',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue[700]),
        ),
        Expanded(
          child: Text(value, style: TextStyle(color: Colors.grey[800])),
        ),
      ],
    );
  }
}

class _CardSection extends StatelessWidget {
  final String title;
  final IconData icon;
  final MaterialColor color;
  final Widget child;
  const _CardSection({required this.title, required this.icon, required this.color, required this.child});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.06),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color[700]),
              const SizedBox(width: 8),
              Text(title, style: TextStyle(fontWeight: FontWeight.bold, color: color[800])),
            ],
          ),
          const SizedBox(height: 8),
          child,
        ],
      ),
    );
  }
}




