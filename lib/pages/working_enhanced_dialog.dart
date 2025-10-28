import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/site.dart';
import '../services/site_storage_service.dart';
import '../services/real_planning_service.dart';
import '../services/planning_dictionary_service.dart';

class WorkingEnhancedDialog extends StatefulWidget {
  final Function(Site) onSiteCreated;
  final List<Site> existingSites;

  const WorkingEnhancedDialog({
    super.key,
    required this.onSiteCreated,
    required this.existingSites,
  });

  @override
  State<WorkingEnhancedDialog> createState() => _WorkingEnhancedDialogState();
}

class _WorkingEnhancedDialogState extends State<WorkingEnhancedDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _addressController = TextEditingController();
  final _suburbController = TextEditingController();
  final _postcodeController = TextEditingController();
  final _descriptionController = TextEditingController();
  
  Map<String, dynamic>? _planningData;
  bool _isLoadingPermits = false;
  bool _isLoadingLocation = false;

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    _suburbController.dispose();
    _postcodeController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  /// Geocode an address to get coordinates
  Future<Map<String, double>?> _geocodeAddress(String address) async {
    try {
      final response = await http.get(
        Uri.parse('https://nominatim.openstreetmap.org/search?q=${Uri.encodeComponent(address)}&format=json&limit=1'),
        headers: {'User-Agent': 'ArboristAssistant/1.0'},
      );
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body) as List;
        if (data.isNotEmpty) {
          final result = data.first as Map<String, dynamic>;
          return {
            'lat': double.parse(result['lat']),
            'lon': double.parse(result['lon']),
          };
        }
      }
      return null;
    } catch (e) {
      print('Error geocoding address: $e');
      return null;
    }
  }

  /// Load planning data for a location
  Future<void> _loadPlanningData() async {
    if (_suburbController.text.trim().isEmpty || _postcodeController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter suburb and postcode first')),
      );
      return;
    }

    setState(() {
      _isLoadingPermits = true;
    });

    try {
      final fullAddress = '${_addressController.text}, ${_suburbController.text} ${_postcodeController.text}, VIC, Australia';
      final geocodedData = await _geocodeAddress(fullAddress);
      
      if (geocodedData != null) {
        final planningData = await RealPlanningService.getRealPlanningData(
          geocodedData['lat']!,
          geocodedData['lon']!,
        );
        
        if (planningData != null) {
          setState(() {
            _planningData = {
              'address': fullAddress,
              'coordinates': '${geocodedData['lat']!.toStringAsFixed(6)}, ${geocodedData['lon']!.toStringAsFixed(6)}',
              'timestamp': DateTime.now().toIso8601String(),
              'lga': planningData['lga'] ?? 'Unknown',
              'permit_data': planningData['permit_data'] ?? {},
              'overlays': planningData['overlays'] ?? [],
              'lga_laws': planningData['lga_laws'] ?? {},
              'local_tree_laws': planningData['local_tree_laws'] ?? {},
              'data_source': 'Vicmap Planning API',
            };
          });
          
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Planning data loaded successfully!')),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No planning data found for this location')),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not geocode the address')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading planning data: $e')),
      );
    } finally {
      setState(() {
        _isLoadingPermits = false;
      });
    }
  }

  /// Find location using suburb and postcode
  Future<void> _findLocation() async {
    if (_suburbController.text.trim().isEmpty || _postcodeController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter suburb and postcode first')),
      );
      return;
    }

    setState(() {
      _isLoadingLocation = true;
    });

    try {
      final address = '${_suburbController.text} ${_postcodeController.text}, VIC, Australia';
      final geocodedData = await _geocodeAddress(address);
      
      if (geocodedData != null) {
        setState(() {
          _planningData = {
            'coordinates': '${geocodedData['lat']!.toStringAsFixed(6)}, ${geocodedData['lon']!.toStringAsFixed(6)}',
            'timestamp': DateTime.now().toIso8601String(),
          };
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Location found! Now load planning data with Permits button')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not find location for this suburb/postcode')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error finding location: $e')),
      );
    } finally {
      setState(() {
        _isLoadingLocation = false;
      });
    }
  }

  void _createSite() {
    if (_formKey.currentState!.validate()) {
      final site = Site(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: _nameController.text.trim(),
        address: '${_addressController.text}, ${_suburbController.text} ${_postcodeController.text}, VIC, Australia',
        notes: _descriptionController.text.trim(),
        createdAt: DateTime.now(),
        vicPlanData: _planningData,
      );

      SiteStorageService.addSite(site);
      widget.onSiteCreated(site);
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.all(16),
      child: Container(
        width: double.maxFinite,
        height: MediaQuery.of(context).size.height * 0.9,
        padding: const EdgeInsets.all(24),
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
                    'Add New Site',
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

                      // Address Fields
                      Row(
                        children: [
                          Expanded(
                            flex: 2,
                            child: TextFormField(
                              controller: _addressController,
                              decoration: const InputDecoration(
                                labelText: 'Street Address *',
                                hintText: '123 Main Street',
                                border: OutlineInputBorder(),
                              ),
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Street address is required';
                                }
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: TextFormField(
                              controller: _suburbController,
                              decoration: const InputDecoration(
                                labelText: 'Suburb *',
                                hintText: 'Epping',
                                border: OutlineInputBorder(),
                              ),
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Suburb is required';
                                }
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: TextFormField(
                              controller: _postcodeController,
                              decoration: const InputDecoration(
                                labelText: 'Postcode *',
                                hintText: '3076',
                                border: OutlineInputBorder(),
                              ),
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Postcode is required';
                                }
                                return null;
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Description
                      TextFormField(
                        controller: _descriptionController,
                        decoration: const InputDecoration(
                          labelText: 'Description',
                          hintText: 'Optional description of the site',
                          border: OutlineInputBorder(),
                        ),
                        maxLines: 3,
                      ),
                      const SizedBox(height: 24),

                      // Action Buttons
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: _isLoadingLocation ? null : _findLocation,
                              icon: _isLoadingLocation 
                                ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                                : const Icon(Icons.my_location),
                              label: Text(_isLoadingLocation ? 'Finding...' : 'Find Location'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blue[600],
                                foregroundColor: Colors.white,
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: _isLoadingPermits ? null : _loadPlanningData,
                              icon: _isLoadingPermits 
                                ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                                : const Icon(Icons.description),
                              label: Text(_isLoadingPermits ? 'Loading...' : 'Permits'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.orange[600],
                                foregroundColor: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // Location Information
                      if (_planningData?['coordinates'] != null) ...[
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.green.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
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
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.green[700],
                                      ),
                                    ),
                                    if (_planningData?['lga'] != null) ...[
                                      const SizedBox(height: 8),
                                      Text(
                                        'LGA: ${_planningData!['lga']}',
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

                      // Planning Data Section
                      if (_planningData?['lga'] != null) ...[
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.blue.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.blue.withValues(alpha: 0.3)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(Icons.info, color: Colors.blue[700]),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Real Planning Data from Vicmap LIVE',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 18,
                                      color: Colors.blue[700],
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: Colors.green,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: const Text(
                                      'LIVE',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 20),

                              // LGA Information
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: Colors.blue.withValues(alpha: 0.2)),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Icon(Icons.business, color: Colors.blue[700]),
                                        const SizedBox(width: 8),
                                        Text(
                                          '${_planningData!['lga']} Council Information',
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.blue[700],
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 12),
                                    Text(
                                      'Local Government Area: ${_planningData!['lga']}',
                                      style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                                    ),
                                    const SizedBox(height: 16),
                                    
                                    // Warning Box
                                    Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: Colors.orange.withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
                                      ),
                                      child: Row(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Icon(Icons.warning, color: Colors.orange[700]),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  'IMPORTANT: Tree permit requirements vary by LGA and specific property.',
                                                  style: TextStyle(
                                                    fontSize: 14,
                                                    fontWeight: FontWeight.bold,
                                                    color: Colors.orange[700],
                                                  ),
                                                ),
                                                const SizedBox(height: 8),
                                                Text(
                                                  'For accurate permit requirements, contact ${_planningData!['lga']} Council directly.',
                                                  style: TextStyle(fontSize: 13, color: Colors.grey[700]),
                                                ),
                                                const SizedBox(height: 4),
                                                Text(
                                                  'Visit the council website or planning department for current tree protection laws.',
                                                  style: TextStyle(fontSize: 13, color: Colors.grey[700]),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 16),

                              // Data Source Info
                              Row(
                                children: [
                                  Icon(Icons.refresh, color: Colors.grey[600], size: 16),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Data source: ${_planningData!['data_source']} Retrieved: ${_planningData!['timestamp']}',
                                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),

                              // VicPlan Button
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton.icon(
                                  onPressed: () {
                                    // Open VicPlan in new tab
                                    // This would typically open a URL
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('VicPlan integration coming soon!')),
                                    );
                                  },
                                  icon: const Icon(Icons.description),
                                  label: const Text('View Full Details on VicPlan'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.blue[600],
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.all(16),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                      ],

                      const Spacer(),

                      // Action Buttons
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () => Navigator.of(context).pop(),
                              child: const Padding(
                                padding: EdgeInsets.all(16),
                                child: Text('Cancel'),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: _createSite,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green[600],
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.all(16),
                              ),
                              child: const Text('Add Site'),
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
      ),
    );
  }
}
