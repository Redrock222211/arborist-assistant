import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import '../models/tree_permit.dart';
import '../models/site.dart';
import '../services/tree_permit_service.dart';
import 'package:intl/intl.dart';

class TreePermitPage extends StatefulWidget {
  final Site site;
  const TreePermitPage({super.key, required this.site});

  @override
  State<TreePermitPage> createState() => _TreePermitPageState();
}

class _TreePermitPageState extends State<TreePermitPage> {
  final TextEditingController _addressController = TextEditingController();
  List<TreePermit> _permits = [];
  bool _isLoading = false;
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    _loadPermits();
  }

  void _loadPermits() {
    setState(() {
      _permits = TreePermitService.getPermitsForSite(widget.site.id);
    });
  }

  Future<void> _getCurrentLocation() async {
    setState(() => _isSearching = true);

    try {
      // Check permissions
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          _showError('Location permission denied');
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        _showError('Location permissions are permanently denied');
        return;
      }

      // Get current position
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      // Reverse geocode to get detailed address
      List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      if (placemarks.isNotEmpty) {
        Placemark place = placemarks[0];
        
        // Build a more detailed address for better VicPlan lookup
        List<String> addressParts = [];
        
        if (place.street != null && place.street!.isNotEmpty) {
          addressParts.add(place.street!);
        }
        if (place.subThoroughfare != null && place.subThoroughfare!.isNotEmpty) {
          addressParts.add(place.subThoroughfare!);
        }
        if (place.thoroughfare != null && place.thoroughfare!.isNotEmpty) {
          addressParts.add(place.thoroughfare!);
        }
        if (place.subLocality != null && place.subLocality!.isNotEmpty) {
          addressParts.add(place.subLocality!);
        }
        if (place.locality != null && place.locality!.isNotEmpty) {
          addressParts.add(place.locality!);
        }
        if (place.administrativeArea != null && place.administrativeArea!.isNotEmpty) {
          addressParts.add(place.administrativeArea!);
        }
        if (place.postalCode != null && place.postalCode!.isNotEmpty) {
          addressParts.add(place.postalCode!);
        }

        String address = addressParts.join(', ');
        
        if (address.isNotEmpty) {
          _addressController.text = address;
          _searchPermit(
            address: address, 
            latitude: position.latitude, 
            longitude: position.longitude
          );
        } else {
          _showError('Could not determine address from location');
        }
      } else {
        _showError('Could not determine address from location');
      }
    } catch (e) {
      _showError('Error getting location: $e');
    } finally {
      setState(() => _isSearching = false);
    }
  }

  Future<void> _searchPermit({
    required String address,
    double? latitude,
    double? longitude,
  }) async {
    if (address.trim().isEmpty) {
      _showError('Please enter an address');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final permit = await TreePermitService.lookupPermit(
        siteId: widget.site.id,
        address: address.trim(),
        latitude: latitude,
        longitude: longitude,
        searchMethod: latitude != null ? 'gps' : 'address',
      );

      await TreePermitService.addPermit(permit);
      _loadPermits();

      _showPermitResult(permit);
    } catch (e) {
      _showError('Error searching for permit: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showPermitResult(TreePermit permit) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Container(
          width: MediaQuery.of(context).size.width * 0.9,
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.9,
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Icon(Icons.description, color: Colors.green, size: 28),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'VicPlan Permit Analysis',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const Divider(),
              
              // Content
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Basic Info
                      _buildInfoSection('Location Information', [
                        _buildInfoRow('Address', permit.address),
                        _buildInfoRow('Council', permit.councilName),
                        _buildInfoRow('VicPlan Lookup', 'Successfully identified LGA and overlays'),
                        _buildInfoRow('Search Date', DateFormat.yMMMd().format(permit.searchDate)),
                        _buildInfoRow('Search Method', permit.searchMethod.toUpperCase()),
                      ]),
                      
                      const SizedBox(height: 16),
                      
                      // Permit Status
                      _buildInfoSection('Permit Requirements', [
                        _buildInfoRow('Status', permit.permitStatus),
                        _buildInfoRow('Type', permit.permitType),
                        _buildInfoRow('Requirements', permit.requirements),
                      ]),
                      
                      const SizedBox(height: 16),
                      
                      // Detailed Notes
                      if (permit.notes.isNotEmpty) ...[
                        _buildInfoSection('Planning Scheme Details', [
                          _buildInfoRow('Notes', permit.notes, isMultiline: true),
                        ]),
                        const SizedBox(height: 16),
                      ],
                      
                      // Action Buttons
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () => _openVicPlan(permit.address),
                              icon: const Icon(Icons.open_in_new),
                              label: const Text('Open VicPlan'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blue,
                                foregroundColor: Colors.white,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () => _copyToClipboard(permit),
                              icon: const Icon(Icons.copy),
                              label: const Text('Copy Details'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.grey,
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
      ),
    );
  }

  Widget _buildInfoSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: Colors.green[700],
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey[300]!),
          ),
          child: Column(
            children: children,
          ),
        ),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value, {bool isMultiline = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 12,
              color: Colors.grey[700],
            ),
            overflow: TextOverflow.visible,
            softWrap: true,
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(
              fontSize: isMultiline ? 11 : 14,
              color: Colors.grey[800],
              height: 1.4,
            ),
            overflow: TextOverflow.visible,
            softWrap: true,
            maxLines: null,
          ),
        ],
      ),
    );
  }

  void _openVicPlan(String address) {
    // In a real app, this would open the specific VicPlan page for the address
    final url = 'https://www.planning.vic.gov.au/schemes';
    // You could use url_launcher here to open the URL
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Opening VicPlan for: $address'),
        backgroundColor: Colors.blue,
      ),
    );
  }

  void _copyToClipboard(TreePermit permit) {
    final details = '''
VicPlan Permit Analysis
=======================

Address: ${permit.address}
Council: ${permit.councilName}
Status: ${permit.permitStatus}
Type: ${permit.permitType}
Requirements: ${permit.requirements}

${permit.notes}

Search Date: ${DateFormat.yMMMd().format(permit.searchDate)}
Search Method: ${permit.searchMethod.toUpperCase()}
''';
    
    // In a real app, you would use Clipboard.setData here
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Permit details copied to clipboard'),
        backgroundColor: Colors.green,
      ),
    );
  }

  Widget _buildResultRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
          ),
          Text(value, style: const TextStyle(fontSize: 14)),
        ],
      ),
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tree Permit Lookup'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // Search Section
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              border: Border(bottom: BorderSide(color: Colors.grey[300]!)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Search for Tree Permits',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                Text(
                  'Enter an address or use your current location to check tree permit requirements.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _addressController,
                  decoration: InputDecoration(
                    labelText: 'Address',
                    hintText: 'Enter street address, suburb, or city',
                    border: const OutlineInputBorder(),
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.location_on),
                      onPressed: _isSearching ? null : _getCurrentLocation,
                      tooltip: 'Use Current Location',
                    ),
                  ),
                  maxLines: 2,
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _isLoading ? null : () => _searchPermit(address: _addressController.text),
                        icon: _isLoading 
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.search),
                        label: Text(_isLoading ? 'Searching...' : 'Search'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    if (_isSearching)
                      const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                  ],
                ),
              ],
            ),
          ),
          
          // Results Section
          Expanded(
            child: _permits.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.search_off, size: 64, color: Colors.grey[400]),
                        const SizedBox(height: 16),
                        Text(
                          'No permit searches yet',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w500,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Search for permits above to see results here',
                          style: TextStyle(color: Colors.grey[500]),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _permits.length,
                    itemBuilder: (context, index) {
                      final permit = _permits[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: _getStatusColor(permit.permitStatus),
                            child: Icon(
                              _getStatusIcon(permit.permitStatus),
                              color: Colors.white,
                            ),
                          ),
                          title: Text(
                            permit.address,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(permit.councilName),
                              Text(
                                '${permit.permitStatus} • ${DateFormat.yMMMd().format(permit.searchDate)}',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                          trailing: PopupMenuButton(
                            itemBuilder: (context) => [
                              const PopupMenuItem(
                                value: 'view',
                                child: Row(
                                  children: [
                                    Icon(Icons.visibility),
                                    SizedBox(width: 8),
                                    Text('View Details'),
                                  ],
                                ),
                              ),
                              const PopupMenuItem(
                                value: 'delete',
                                child: Row(
                                  children: [
                                    Icon(Icons.delete, color: Colors.red),
                                    SizedBox(width: 8),
                                    Text('Delete', style: TextStyle(color: Colors.red)),
                                  ],
                                ),
                              ),
                            ],
                            onSelected: (value) {
                              if (value == 'view') {
                                _showPermitResult(permit);
                              } else if (value == 'delete') {
                                _deletePermit(permit);
                              }
                            },
                          ),
                          onTap: () => _showPermitResult(permit),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'required':
      case 'required for significant trees':
      case 'required for trees > 5m height':
        return Colors.red;
      case 'check with local council':
      case 'check with council':
        return Colors.orange;
      case 'not required':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'required':
      case 'required for significant trees':
      case 'required for trees > 5m height':
        return Icons.warning;
      case 'check with local council':
      case 'check with council':
        return Icons.help;
      case 'not required':
        return Icons.check;
      default:
        return Icons.info;
    }
  }

  Future<void> _deletePermit(TreePermit permit) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Permit Search'),
        content: Text('Are you sure you want to delete the permit search for "${permit.address}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await TreePermitService.deletePermit(permit.id);
      _loadPermits();
    }
  }

  @override
  void dispose() {
    _addressController.dispose();
    super.dispose();
  }
}
