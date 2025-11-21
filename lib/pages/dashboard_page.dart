import 'package:flutter/material.dart';
import 'package:arborist_assistant/models/user.dart';
import 'package:arborist_assistant/models/site.dart';
import 'package:arborist_assistant/models/tree_entry.dart';
import 'package:arborist_assistant/services/auth_service.dart';
import 'package:arborist_assistant/services/site_storage_service.dart';
import 'package:arborist_assistant/services/tree_storage_service.dart';
import 'package:arborist_assistant/services/notification_service.dart';
import 'package:arborist_assistant/services/real_planning_service.dart';
import 'package:arborist_assistant/services/planning_dictionary_service.dart';
// import 'package:arborist_assistant/pages/enhanced_site_creation_dialog.dart';
import 'package:arborist_assistant/pages/simple_working_dialog.dart';
import 'package:arborist_assistant/pages/permit_lookup_tool_page.dart';
// import 'package:arborist_assistant/pages/site_detail_page.dart';
// import 'package:arborist_assistant/pages/tree_entry_page.dart';
// import 'package:arborist_assistant/pages/sites_map_page.dart';
import 'package:intl/intl.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:arborist_assistant/pages/site_main_page.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  User? currentUser;
  List<Site> sites = [];
  List<TreeEntry> trees = [];
  bool _isLoading = true;
  bool _isLoadingLocation = false;
  Map<String, dynamic>? _vicPlanData;
  
  // Location variables
  double? _latitude;
  double? _longitude;
  String? _lga;
  String? _address;
  
  // Search functionality
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();
  
  // Connection status
  bool _isOnline = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    
    try {
      final user = await AuthService.getCurrentUser();
      final sitesList = await SiteStorageService.getAllSites();
      final treesList = <TreeEntry>[]; // await TreeStorageService.getAllTreeEntries();
      
      setState(() {
        currentUser = user;
        sites = sitesList;
        trees = treesList;
        _isLoading = false;
      });
    } catch (e) {
      NotificationService.showError(context, 'Failed to load data: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _getCurrentLocation() async {
    try {
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      );
      
      setState(() {
        _latitude = position.latitude;
        _longitude = position.longitude;
      });
      
      // Get address from coordinates
      await _reverseGeocode(position.latitude, position.longitude);
      
      // Get planning data
      await _fetchPlanningData();
      
    } catch (e) {
      NotificationService.showError(context, 'Could not get location: $e');
    }
  }

  Future<void> _reverseGeocode(double lat, double lng) async {
    try {
      final response = await http.get(
        Uri.parse('https://nominatim.openstreetmap.org/reverse?format=json&lat=$lat&lon=$lng&zoom=18&addressdetails=1'),
        headers: {'User-Agent': 'ArboristAssistant/1.0'},
      );
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final address = data['display_name'] ?? 'Unknown address';
        
        setState(() {
          _address = address;
        });
      }
    } catch (e) {
      print('Reverse geocoding failed: $e');
    }
  }

  Future<void> _fetchPlanningData() async {
    if (_latitude == null || _longitude == null) return;
    
    try {
      final planningData = await RealPlanningService.getPlanningAtPoint(
        latitude: _latitude!,
        longitude: _longitude!,
      );
      
      setState(() {
        _vicPlanData = planningData;
      });
    } catch (e) {
      print('Failed to fetch planning data: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const Text('Arborist Assistant'),
            const SizedBox(width: 12),
            // Connection status indicator
            Tooltip(
              message: _isOnline ? 'Connected - Data synced' : 'Offline - Changes saved locally',
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _isOnline ? Colors.green.shade400 : Colors.orange.shade400,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _isOnline ? Icons.cloud_done : Icons.cloud_off,
                      size: 14,
                      color: Colors.white,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _isOnline ? 'Online' : 'Offline',
                      style: const TextStyle(fontSize: 11, color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        backgroundColor: Colors.green[700],
        foregroundColor: Colors.white,
        actions: [
          Tooltip(
            message: 'Permit Lookup Tool - Search by address',
            child: IconButton(
              icon: const Icon(Icons.gavel),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const PermitLookupToolPage(),
                  ),
                );
              },
            ),
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadData,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Welcome Section
                    _buildWelcomeSection(currentUser),
                    const SizedBox(height: 24),
                    
                    // Site List
                    _buildSimpleSiteList(),
                    const SizedBox(height: 24),
                    
                    // Quick Actions
                    _buildQuickActionsSection(),
                    const SizedBox(height: 24),
                    
                    // Location Section
                    _buildLocationSection(),
                    const SizedBox(height: 24),
                    
                    // VicPlan Planning Information Display
                    if (_vicPlanData != null && _vicPlanData?['real_data'] == true) ...[
                      
                      // TILE 1: VICPLAN DATA
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
                                Icon(Icons.data_usage, color: Colors.blue[700], size: 24),
                                const SizedBox(width: 12),
                                Text(
                                  'VicPlan Data',
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.blue[700],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),
                            
                            // LGA Information
                            if (_vicPlanData?['lga'] != null) ...[
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
                                        Icon(Icons.location_city, color: Colors.blue[700], size: 20),
                                        const SizedBox(width: 8),
                                        Text(
                                          'Local Government Area',
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
                                      _vicPlanData!['lga'],
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.grey[800],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 16),
                            ],
                            
                            // Overlays Found
                            if (_vicPlanData?['overlays'] != null && 
                                _vicPlanData?['overlays'] is List &&
                                (_vicPlanData?['overlays'] as List).isNotEmpty) ...[
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
                                        Icon(Icons.layers, color: Colors.blue[700], size: 20),
                                        const SizedBox(width: 8),
                                        Text(
                                          'Planning Overlays',
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.blue[700],
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 12),
                                    ...((_vicPlanData?['overlays'] as List).map((overlay) {
                                      final overlayData = overlay is Map<String, dynamic> 
                                          ? overlay as Map<String, dynamic> 
                                          : <String, dynamic>{};
                                      return Padding(
                                        padding: const EdgeInsets.only(bottom: 8),
                                        child: Row(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Container(
                                              width: 80,
                                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                              decoration: BoxDecoration(
                                                color: Colors.blue[100],
                                                borderRadius: BorderRadius.circular(4),
                                              ),
                                              child: Text(
                                                overlayData['code'] ?? 'Unknown',
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.blue[700],
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 12),
                                            Expanded(
                                              child: Text(
                                                overlayData['name'] ?? 'Unknown Overlay',
                                                style: TextStyle(
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.w500,
                                                  color: Colors.grey[700],
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      );
                                    })),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 16),
                            ],
                            
                            // Local Tree Laws
                            if (_vicPlanData?['local_tree_laws'] != null && 
                                _vicPlanData?['local_tree_laws'] is Map<String, dynamic>) ...[
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
                                        Icon(Icons.forest, color: Colors.blue[700], size: 20),
                                        const SizedBox(width: 8),
                                        Text(
                                          'Local Tree Laws',
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.blue[700],
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 12),
                                    ...((_vicPlanData?['local_tree_laws'] as Map<String, dynamic>).entries.map((entry) => 
                                      Padding(
                                        padding: const EdgeInsets.only(left: 8, top: 2),
                                        child: Row(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text('• ', style: TextStyle(color: Colors.blue[700], fontWeight: FontWeight.bold)),
                                            Expanded(
                                              child: Text(
                                                '${entry.key.replaceAll('_', ' ').toUpperCase()}: ${entry.value}',
                                                style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    )),
                                  ],
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      
                      // TILE 2: MATCHED KEYWORDS AND EXPLAINED
                      if (_vicPlanData?['overlays'] != null && 
                          _vicPlanData?['overlays'] is List &&
                          (_vicPlanData?['overlays'] as List).isNotEmpty) ...[
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.orange.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(Icons.search, color: Colors.orange[700], size: 24),
                                  const SizedBox(width: 12),
                                  Text(
                                    'Matched Keywords & Explained',
                                    style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.orange[700],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'Planning dictionary explanations for found overlays:',
                                style: TextStyle(fontSize: 16, color: Colors.grey[800], fontWeight: FontWeight.w500),
                              ),
                              const SizedBox(height: 16),
                              ...((_vicPlanData?['overlays'] as List).map((overlay) {
                                final overlayData = overlay is Map<String, dynamic> 
                                    ? overlay as Map<String, dynamic> 
                                    : <String, dynamic>{};
                                final overlayCode = overlayData['code'] ?? 'Unknown';
                                final dictionaryInfo = PlanningDictionaryService.getOverlayExplanation(overlayCode);
                                
                                return Container(
                                  margin: const EdgeInsets.only(bottom: 16),
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.orange.withValues(alpha: 0.1),
                                        blurRadius: 4,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      // Overlay Header
                                      Row(
                                        children: [
                                          Container(
                                            width: 80,
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                            decoration: BoxDecoration(
                                              color: Colors.orange[100],
                                              borderRadius: BorderRadius.circular(6),
                                            ),
                                            child: Text(
                                              overlayCode,
                                              style: TextStyle(
                                                fontSize: 14,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.orange[700],
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 16),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  dictionaryInfo['name'],
                                                  style: TextStyle(
                                                    fontSize: 16,
                                                    fontWeight: FontWeight.bold,
                                                    color: Colors.grey[800],
                                                  ),
                                                ),
                                                Text(
                                                  'Impact Level: ${dictionaryInfo['impact_level']}',
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    color: Colors.grey[600],
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 12),
                                      
                                      // What It Means
                                      Container(
                                        padding: const EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                          color: Colors.orange.withValues(alpha: 0.1),
                                          borderRadius: BorderRadius.circular(6),
                                          border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
                                        ),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              'What This Means:',
                                              style: TextStyle(
                                                fontSize: 14,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.orange[700],
                                              ),
                                            ),
                                            const SizedBox(height: 6),
                                            Text(
                                              dictionaryInfo['what_it_means'],
                                              style: TextStyle(
                                                fontSize: 13,
                                                color: Colors.grey[700],
                                                height: 1.3,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      
                                      // Tree Removal Requirements
                                      Container(
                                        padding: const EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                          color: Colors.red.withValues(alpha: 0.1),
                                          borderRadius: BorderRadius.circular(6),
                                          border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
                                        ),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              'Tree Removal Requirements:',
                                              style: TextStyle(
                                                fontSize: 14,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.red[700],
                                              ),
                                            ),
                                            const SizedBox(height: 6),
                                            Text(
                                              dictionaryInfo['tree_removal'],
                                              style: TextStyle(
                                                fontSize: 13,
                                                color: Colors.grey[700],
                                                height: 1.3,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              })),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                      ],
                    ],
                    
                    // Disclaimer
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.grey.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey.withValues(alpha: 0.3)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.info, color: Colors.grey[700], size: 20),
                              const SizedBox(width: 8),
                              Text(
                                'Disclaimer',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.grey[700],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'This information is provided as a general guide only. Always verify current requirements with your local council and do your own research. Planning scheme requirements can change and may vary by specific location.',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[700],
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildWelcomeSection(User? currentUser) {
    return Card(
      elevation: 4,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.green.withValues(alpha: 0.1), Colors.green.withValues(alpha: 0.2)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.eco,
                  size: 32,
                  color: Colors.green.shade700,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Flexible(
                        child: Text(
                          'Welcome back, ${currentUser?.name ?? 'Arborist'}!',
                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Colors.green.shade800,
                          ),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                      ),
                      Text(
                        'Ready to manage your trees today?',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.green.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              'Last updated: ${DateFormat('MMM dd, yyyy HH:mm').format(DateTime.now())}',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.green.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSimpleSiteList() {
    // Sort sites by most recent first
    final sortedSites = List<Site>.from(sites)
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    
    // Filter sites based on search query
    final filteredSites = _searchQuery.isEmpty
        ? sortedSites
        : sortedSites.where((site) {
            final query = _searchQuery.toLowerCase();
            return site.name.toLowerCase().contains(query) ||
                   site.address.toLowerCase().contains(query) ||
                   (site.vicPlanData?['lga']?.toString().toLowerCase().contains(query) ?? false);
          }).toList();
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Your Sites',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const Spacer(),
            Text(
              '${filteredSites.length} of ${sites.length}',
              style: TextStyle(color: Colors.grey[600], fontSize: 14),
            ),
          ],
        ),
        const SizedBox(height: 12),
        
        // Search bar
        TextField(
          controller: _searchController,
          decoration: InputDecoration(
            hintText: '🔍 Search sites by name, address, or LGA...',
            prefixIcon: const Icon(Icons.search),
            suffixIcon: _searchQuery.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () {
                      setState(() {
                        _searchController.clear();
                        _searchQuery = '';
                      });
                    },
                  )
                : null,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            filled: true,
            fillColor: Colors.grey[50],
          ),
          onChanged: (value) {
            setState(() {
              _searchQuery = value;
            });
          },
        ),
        const SizedBox(height: 16),
        if (sites.isEmpty)
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.green.shade50, Colors.blue.shade50],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.green.shade300, width: 2),
            ),
            child: Column(
              children: [
                Icon(Icons.add_location_alt, size: 64, color: Colors.green.shade700),
                const SizedBox(height: 16),
                const Text(
                  'No Sites Yet!',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  'Create your first site to start managing trees and permits',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (context) => SimpleWorkingDialog(
                        onSiteCreated: (site) {
                          setState(() {
                            sites.add(site);
                          });
                        },
                      ),
                    );
                  },
                  icon: const Icon(Icons.add_circle, size: 24),
                  label: const Text('Create Your First Site', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green.shade700,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 4,
                  ),
                ),
              ],
            ),
          )
        else if (filteredSites.isEmpty)
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.orange.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
            ),
            child: Column(
              children: [
                Icon(Icons.search_off, size: 48, color: Colors.grey[600]),
                const SizedBox(height: 8),
                Text(
                  'No sites match "$_searchQuery"',
                  style: TextStyle(fontSize: 16, color: Colors.grey[700]),
                ),
              ],
            ),
          )
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: filteredSites.length,
            itemBuilder: (context, index) {
              final site = filteredSites[index];
              final lga = site.vicPlanData?['lga'];
              final hasPermits = site.vicPlanData != null;
              final daysSinceCreated = DateTime.now().difference(site.createdAt).inDays;
              
              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                elevation: 2,
                child: InkWell(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => SiteMainPage(site: site, initialTab: 3), // Details tab
                      ),
                    );
                  },
                  borderRadius: BorderRadius.circular(8),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: [
                        Icon(Icons.location_on, color: Colors.green[700], size: 32),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                site.name,
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                site.address,
                                style: TextStyle(color: Colors.grey[600], fontSize: 13),
                                overflow: TextOverflow.ellipsis,
                                maxLines: 2,
                              ),
                              const SizedBox(height: 8),
                              // Status badges
                              Wrap(
                                spacing: 8,
                                runSpacing: 4,
                                children: [
                                  if (lga != null)
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: Colors.blue[50],
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(color: Colors.blue[200]!),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(Icons.place, size: 12, color: Colors.blue[700]),
                                          const SizedBox(width: 4),
                                          Text(
                                            lga.toString(),
                                            style: TextStyle(fontSize: 11, color: Colors.blue[900], fontWeight: FontWeight.w600),
                                          ),
                                        ],
                                      ),
                                    ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: hasPermits ? Colors.green[50] : Colors.orange[50],
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(color: hasPermits ? Colors.green[200]! : Colors.orange[200]!),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          hasPermits ? Icons.check_circle : Icons.warning,
                                          size: 12,
                                          color: hasPermits ? Colors.green[700] : Colors.orange[700],
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          hasPermits ? 'Permits Loaded' : 'No Permits',
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: hasPermits ? Colors.green[900] : Colors.orange[900],
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: Colors.grey[100],
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      daysSinceCreated == 0
                                          ? 'Today'
                                          : daysSinceCreated == 1
                                              ? 'Yesterday'
                                              : '$daysSinceCreated days ago',
                                      style: TextStyle(fontSize: 10, color: Colors.grey[700]),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        Icon(Icons.arrow_forward_ios, color: Colors.grey[400], size: 18),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
      ],
    );
  }

  Widget _buildQuickActionsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Actions',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        
        // Simple buttons
        Column(
          children: [
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _showAddSiteDialog(),
                icon: const Icon(Icons.add_location),
                label: const Text('Add New Site'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green[600],
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.all(16),
                ),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _showAddTreeDialog(),
                icon: const Icon(Icons.eco),
                label: const Text('Add New Tree'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue[600],
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.all(16),
                ),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const PermitLookupToolPage(),
                    ),
                  );
                },
                icon: const Icon(Icons.gavel),
                label: const Text('Permit Lookup Tool'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange[600],
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.all(16),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildLocationSection() {
    return Container(
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
              Icon(Icons.my_location, color: Colors.blue[700], size: 24),
              const SizedBox(width: 12),
              Text(
                'Current Location',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue[700],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          
          // GPS Coordinates
          if (_latitude != null && _longitude != null) ...[
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
                  Text(
                    'GPS Coordinates:',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue[700],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Latitude: ${_latitude!.toStringAsFixed(6)}',
                    style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                  ),
                  Text(
                    'Longitude: ${_longitude!.toStringAsFixed(6)}',
                    style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],
          
          // Address
          if (_address != null) ...[
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
                  Text(
                    'Address:',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue[700],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _address!,
                    style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],
          
          // LGA
          if (_lga != null) ...[
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
                  Text(
                    'Local Government Area:',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue[700],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _lga!,
                    style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],
          
          // GPS Locate Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _isLoadingLocation ? null : _getCurrentLocation,
              icon: _isLoadingLocation 
                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.my_location),
              label: Text(_isLoadingLocation ? 'Getting Location...' : '📍 Locate Me (GPS)'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green[600],
                foregroundColor: Colors.white,
                padding: const EdgeInsets.all(16),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showAddSiteDialog() {
    showDialog(
      context: context,
      builder: (context) => SimpleWorkingDialog(
        onSiteCreated: (Site site) {
          // Add the new site to the list
          setState(() {
            sites.add(site);
          });
          NotificationService.showSuccess(context, 'Site created successfully!');
        },
      ),
    );
  }

  void _showAddTreeDialog() {
    NotificationService.showInfo(context, 'Add tree functionality coming soon');
  }
}
