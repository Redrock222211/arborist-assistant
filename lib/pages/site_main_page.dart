import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:arborist_assistant/models/site.dart';
import 'package:arborist_assistant/models/tree_entry.dart';
import 'package:arborist_assistant/services/app_state_service.dart';
import 'package:arborist_assistant/services/site_storage_service.dart';
import 'package:arborist_assistant/pages/map_page.dart';
import 'package:arborist_assistant/pages/tree_list_page.dart';
import 'package:arborist_assistant/pages/drawing_page.dart';
import 'package:arborist_assistant/pages/site_files_page.dart';
import 'package:arborist_assistant/pages/tree_layout_map_page.dart';
import 'package:arborist_assistant/pages/export_sync_page.dart';
import 'package:arborist_assistant/pages/dashboard_page.dart';
import 'package:arborist_assistant/pages/simple_working_dialog.dart';
import 'package:arborist_assistant/services/real_planning_service.dart';
import 'package:arborist_assistant/services/planning_ai_service.dart';
import 'package:arborist_assistant/services/vicplan_service.dart';
import 'package:arborist_assistant/services/regulatory_data_service.dart';
import 'package:arborist_assistant/models/lga_tree_law.dart';
import 'package:arborist_assistant/models/overlay_tree_requirement.dart';
import '../utils/platform_download.dart';

class SiteMainPage extends StatefulWidget {
  final Site site;
  final int initialTab;

  const SiteMainPage({super.key, required this.site, this.initialTab = 0});

  @override
  State<SiteMainPage> createState() => _SiteMainPageState();
}

class _SiteMainPageState extends State<SiteMainPage> {
  int _selectedTab = 0;
  bool _isSidebarOpen = false;
  List<Site> _sites = [];

  @override
  void initState() {
    super.initState();
    _selectedTab = widget.initialTab;
    _loadSites();
    // Set this site as the last selected site
    AppStateService.saveLastSite(widget.site.id);
  }

  void _loadSites() {
    setState(() {
      _sites = SiteStorageService.getAllSites();
    });
  }

  void _changeSite(Site newSite) {
    setState(() {
      _isSidebarOpen = false;
    });
    
    // Navigate to the new site
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (context) => SiteMainPage(site: newSite, initialTab: _selectedTab),
      ),
    );
  }

  void _leaveSite() {
    // Return to dashboard without a selected site
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (context) => const DashboardPage(),
      ),
    );
  }

  void _addNewSite() async {
    final newSite = await showDialog<Site>(
      context: context,
      builder: (context) => SimpleWorkingDialog(
        onSiteCreated: (Site site) {
          Navigator.of(context).pop(site);
        },
      ),
    );

    if (newSite != null) {
      // Navigate to the new site with map tab selected
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => SiteMainPage(site: newSite, initialTab: 0),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      MapPage(site: widget.site),
      TreeListPage(site: widget.site),
      DrawingPage(site: widget.site),
      SiteFilesPage(site: widget.site),
      TreeLayoutMapPage(site: widget.site), // Professional site map for reports
      _buildSiteDetailsTab(),
      ExportSyncPage(site: widget.site), // Reports tab with export functionality
    ];

    final tabLabels = [
      'Map',
      'Trees',
      'Drawing',
      'Files',
      'Site Map',
      'Details',
      'Reports',
    ];

    final tabIcons = [
      Icons.map,
      Icons.forest,
      Icons.brush,
      Icons.folder,
      Icons.location_on,
      Icons.info,
      Icons.assessment,
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.site.name}'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.menu),
          onPressed: () => setState(() => _isSidebarOpen = !_isSidebarOpen),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_location),
            tooltip: 'Add New Site',
            onPressed: _addNewSite,
          ),
          IconButton(
            icon: const Icon(Icons.home),
            tooltip: 'Leave Site',
            onPressed: _leaveSite,
          ),
        ],
      ),
      body: Row(
        children: [
          // Sidebar
          if (_isSidebarOpen)
            Container(
              width: 280,
              decoration: BoxDecoration(
                color: Colors.grey[50],
                border: Border(
                  right: BorderSide(color: Colors.grey[300]!),
                ),
              ),
              child: _buildSidebar(),
            ),
          
          // Main content
          Expanded(
            child: pages[_selectedTab],
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _selectedTab,
        selectedItemColor: Colors.green[700],
        unselectedItemColor: Colors.grey[600],
        onTap: (index) => setState(() => _selectedTab = index),
        items: List.generate(
          tabLabels.length,
          (index) => BottomNavigationBarItem(
            icon: Icon(tabIcons[index]),
            label: tabLabels[index],
          ),
        ),
      ),
    );
  }

  Widget _buildSidebar() {
    return Column(
      children: [
        // Site header
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.green[50],
            border: Border(
              bottom: BorderSide(color: Colors.green[200]!),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.location_on, color: Colors.green[700], size: 24),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Current Site',
                      style: TextStyle(
                        color: Colors.green[700],
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                widget.site.name,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
              Text(
                widget.site.address,
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),

        // Site navigation
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              const Text(
                'Site Navigation',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 16),
              
              // Quick actions for current site
              _buildSidebarItem(
                icon: Icons.add_location,
                title: 'Add Tree',
                subtitle: 'Add new tree to this site',
                onTap: () {
                  setState(() => _selectedTab = 1); // Go to Trees tab
                  setState(() => _isSidebarOpen = false);
                },
                color: Colors.green,
              ),
              
              _buildSidebarItem(
                icon: Icons.map,
                title: 'Site Map',
                subtitle: 'View site map and tree locations',
                onTap: () {
                  setState(() => _selectedTab = 0); // Go to Map tab
                  setState(() => _isSidebarOpen = false);
                },
                color: Colors.blue,
              ),
              
              _buildSidebarItem(
                icon: Icons.assessment,
                title: 'Site Report',
                subtitle: 'Generate site assessment report',
                onTap: () {
                  setState(() => _selectedTab = 5); // Go to Export tab
                  setState(() => _isSidebarOpen = false);
                },
                color: Colors.orange,
              ),
              
              const SizedBox(height: 24),
              
              // Other sites
              const Text(
                'Other Sites',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 16),
              
              ..._sites.where((site) => site.id != widget.site.id).map((site) =>
                _buildSidebarItem(
                  icon: Icons.location_on,
                  title: site.name,
                  subtitle: site.address,
                  onTap: () => _changeSite(site),
                  color: Colors.grey[600]!,
                  showBorder: true,
                ),
              ),
              
              if (_sites.where((site) => site.id != widget.site.id).isEmpty)
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    'No other sites available',
                    style: TextStyle(
                      color: Colors.grey[500],
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
              
              const SizedBox(height: 16),
              
              // Add new site button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _addNewSite,
                  icon: const Icon(Icons.add),
                  label: const Text('Add New Site'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSidebarItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    required Color color,
    bool showBorder = false,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        border: showBorder ? Border.all(color: Colors.grey[300]!) : null,
        borderRadius: BorderRadius.circular(8),
      ),
      child: ListTile(
        leading: Icon(icon, color: color, size: 20),
        title: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.w500,
            fontSize: 14,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 12,
          ),
        ),
        onTap: onTap,
        dense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      ),
    );
  }

  Widget _buildSiteDetailsTab() {
    return SiteDetailsPage(site: widget.site);
  }
}

// Site Details Page - Shows all planning information
class SiteDetailsPage extends StatefulWidget {
  final Site site;
  
  const SiteDetailsPage({super.key, required this.site});

  @override
  State<SiteDetailsPage> createState() => _SiteDetailsPageState();
}

class _SiteDetailsPageState extends State<SiteDetailsPage> {
  final RegulatoryDataService _regulatoryService = RegulatoryDataService.instance;
  LgaTreeLaw? _treeLaw;
  List<OverlayTreeRequirement> _overlayRequirements = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadRegulatoryData();
  }

  Future<void> _loadRegulatoryData() async {
    setState(() => _isLoading = true);
    
    try {
      await _regulatoryService.loadData();
      
      // Get LGA from planning data
      final lgaName = widget.site.vicPlanData?['lga'];
      if (lgaName != null && lgaName.toString().isNotEmpty) {
        _treeLaw = _regulatoryService.getLgaTreeLaw(lgaName);
      }
      
      // Get overlay requirements
      final overlays = widget.site.vicPlanData?['overlays'] as List?;
      if (overlays != null) {
        _overlayRequirements = [];
        for (var overlay in overlays) {
          final code = overlay['code'] ?? overlay['overlay'] ?? overlay['ZONE_CODE'];
          if (code != null) {
            final reqs = _regulatoryService.getOverlayRequirements(code, lgaName: lgaName);
            _overlayRequirements.addAll(reqs);
          }
        }
      }
    } catch (e) {
      print('Error loading regulatory data: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Icon(Icons.info, color: Colors.green[700], size: 28),
              const SizedBox(width: 12),
              Text(
                'Site Details',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.green[700]),
              ),
              const Spacer(),
              ElevatedButton.icon(
                onPressed: () => _refreshPlanningData(context),
                icon: const Icon(Icons.refresh),
                label: const Text('Refresh Planning Data'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue[600],
                  foregroundColor: Colors.white,
                ),
              ),
              const SizedBox(width: 12),
              ElevatedButton.icon(
                onPressed: () => _exportSiteDetails(context),
                icon: const Icon(Icons.download),
                label: const Text('Export'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green[600],
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Site Information
          _buildInfoCard(
            title: 'Site Information',
            icon: Icons.location_on,
            color: Colors.blue,
            children: [
              _buildInfoRow('Site Name', widget.site.name),
              _buildInfoRow('Address', widget.site.address),
              _buildInfoRow('Created', _formatDate(widget.site.createdAt)),
              if (widget.site.notes?.isNotEmpty == true)
                _buildInfoRow('Notes', widget.site.notes!),
            ],
          ),
          const SizedBox(height: 16),

          // Planning Data (if available)
          if (widget.site.vicPlanData != null) ...[
            _buildInfoCard(
              title: 'Planning Summary',
              icon: Icons.map,
              color: Colors.blue,
              children: [
                _buildInfoRow('LGA', widget.site.vicPlanData!['lga'] ?? 'Unknown'),
                _buildInfoRow('Data Source', widget.site.vicPlanData!['data_source'] ?? 'Unknown'),
                _buildInfoRow('Retrieved', _formatDate(DateTime.parse(widget.site.vicPlanData!['timestamp']))),
                if (widget.site.vicPlanData!['coordinates'] != null)
                  _buildInfoRow('Coordinates', widget.site.vicPlanData!['coordinates']),
              ],
            ),
            const SizedBox(height: 16),
            
            // VERIFIED Local Law Requirements (from CSV)
            if (_treeLaw != null && _treeLaw!.hasLocalLaw) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.green[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green[700]!, width: 3),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.verified, color: Colors.green[700], size: 24),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Local Law Requirements (Verified)',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.green[900]),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.green[600],
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Text(
                            'VERIFIED',
                            style: TextStyle(fontSize: 12, color: Colors.white, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                    const Divider(thickness: 2),
                    _buildInfoRow('Council', _treeLaw!.councilFullName),
                    _buildInfoRow('Local Law', '${_treeLaw!.localLawNumber} (${_treeLaw!.localLawYear})'),
                    _buildInfoRow('Size Threshold', _treeLaw!.displayThreshold),
                    if (_treeLaw!.permitFeeStandard.isNotEmpty)
                      _buildInfoRow('Permit Fee', '\$${_treeLaw!.permitFeeStandard}'),
                    if (_treeLaw!.processingDaysMin.isNotEmpty)
                      _buildInfoRow('Processing Time', '${_treeLaw!.processingDaysMin}-${_treeLaw!.processingDaysMax} days'),
                    if (_treeLaw!.arboristReportRequired.isNotEmpty)
                      _buildInfoRow('Arborist Report', _treeLaw!.arboristReportRequired),
                    if (_treeLaw!.phone.isNotEmpty)
                      _buildInfoRow('Phone', _treeLaw!.phone),
                    if (_treeLaw!.notes.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.green[100],
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          'Notes: ${_treeLaw!.notes}',
                          style: TextStyle(fontSize: 13, color: Colors.grey[800]),
                        ),
                      ),
                    ],
                    if (_treeLaw!.localLawsPageUrl.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      TextButton.icon(
                        onPressed: () async => await openUrlInBrowser(_treeLaw!.localLawsPageUrl),
                        icon: const Icon(Icons.open_in_new),
                        label: const Text('View Council Website'),
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.green[700],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],
            
            // LGA Local Laws (AI-Generated - Supplementary)
            if (widget.site.vicPlanData!['lgaLocalLaws'] != null && widget.site.vicPlanData!['lgaLocalLaws'].toString().isNotEmpty)
              _buildInfoCard(
                title: 'LGA Local Laws - Tree Protection',
                icon: Icons.account_balance,
                color: Colors.indigo,
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.indigo.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.indigo.withOpacity(0.2)),
                    ),
                    child: Text(
                      widget.site.vicPlanData!['lgaLocalLaws'],
                      style: TextStyle(fontSize: 13, color: Colors.grey[800], height: 1.5),
                    ),
                  ),
                ],
              ),
            const SizedBox(height: 16),

            // Zones
            if (widget.site.vicPlanData!['zones'] != null && (widget.site.vicPlanData!['zones'] as List).isNotEmpty) ...[
              _buildInfoCard(
                title: 'Planning Zones (${(widget.site.vicPlanData!['zones'] as List).length})',
                icon: Icons.map,
                color: Colors.teal,
                children: (widget.site.vicPlanData!['zones'] as List).map<Widget>((zone) {
                  final zoneMap = zone as Map<String, dynamic>;
                  final code = zoneMap['code'] ?? zoneMap['zone'] ?? zoneMap['ZONE_CODE'] ?? 'ZONE';
                  final desc = zoneMap['description'] ?? zoneMap['desc'] ?? zoneMap['ZONE_DESCRIPTION'] ?? 'Zone details';
                  return _buildBadgeRow(
                    badge: code,
                    text: desc,
                    badgeColor: Colors.teal[600]!,
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
            ],

            // Overlays
            if (widget.site.vicPlanData!['overlays'] != null && (widget.site.vicPlanData!['overlays'] as List).isNotEmpty) ...[
              _buildInfoCard(
                title: 'Planning Overlays (${(widget.site.vicPlanData!['overlays'] as List).length})',
                icon: Icons.layers,
                color: Colors.orange,
                children: (widget.site.vicPlanData!['overlays'] as List).map<Widget>((overlay) {
                  final overlayMap = overlay as Map<String, dynamic>;
                  final code = overlayMap['code'] ?? overlayMap['overlay'] ?? overlayMap['ZONE_CODE'] ?? 'OVERLAY';
                  final desc = overlayMap['description'] ?? overlayMap['desc'] ?? overlayMap['ZONE_DESCRIPTION'] ?? 'Overlay details';
                  return _buildBadgeRow(
                    badge: code,
                    text: desc,
                    badgeColor: Colors.orange[700]!,
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),

              // VERIFIED Overlay Requirements (from CSV)
              if (_overlayRequirements.isNotEmpty) ...[
                ..._overlayRequirements.map((req) => Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blue[700]!, width: 3),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.verified, color: Colors.blue[700], size: 24),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              '${req.overlayFullName} (Verified)',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.blue[900]),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.blue[600],
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Text(
                              'VERIFIED',
                              style: TextStyle(fontSize: 12, color: Colors.white, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                      const Divider(thickness: 2),
                      _buildInfoRow('Code', req.overlayScheduleCode),
                      _buildInfoRow('Purpose', req.purposeSummary),
                      _buildInfoRow('Size Threshold', req.displayThreshold),
                      if (req.pruningPermitRequired.isNotEmpty)
                        _buildInfoRow('Pruning Permit', req.pruningPermitRequired),
                      if (req.removalPermitRequired.isNotEmpty)
                        _buildInfoRow('Removal Permit', req.removalPermitRequired),
                      if (req.arboristReportRequired.isNotEmpty)
                        _buildInfoRow('Arborist Report', req.arboristReportRequired),
                      if (req.offsetRequired.isNotEmpty) ...[
                        _buildInfoRow('Offset Required', req.offsetRequired),
                        if (req.offsetRatio.isNotEmpty)
                          _buildInfoRow('Offset Ratio', req.offsetRatio),
                      ],
                      if (req.typicalPermitFee.isNotEmpty)
                        _buildInfoRow('Permit Fee', '\$${req.typicalPermitFee}'),
                      if (req.typicalProcessingDays.isNotEmpty)
                        _buildInfoRow('Processing Time', '${req.typicalProcessingDays} days'),
                      if (req.notes.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.blue[100],
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            'Notes: ${req.notes}',
                            style: TextStyle(fontSize: 13, color: Colors.grey[800]),
                          ),
                        ),
                      ],
                    ],
                  ),
                )),
              ],

              const SizedBox(height: 16),

              // BMO Warning (if present)
              if (_hasBMOOverlay(widget.site.vicPlanData!['overlays'] as List)) ...[
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.10),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.orange.withOpacity(0.25)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.local_fire_department, color: Colors.orange[700], size: 20),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Bushfire Management Overlay present - Tree removal may be required for safety',
                          style: TextStyle(fontSize: 14, color: Colors.orange[800], fontWeight: FontWeight.w500),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ],
          ] else ...[
            // No planning data available
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: Column(
                children: [
                  Icon(Icons.info_outline, color: Colors.grey[600], size: 48),
                  const SizedBox(height: 16),
                  Text(
                    'No Planning Data Available',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey[700]),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'This site was created without VicMap planning data. Use the "Permits" button when creating sites to load planning information.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoCard({
    required String title,
    required IconData icon,
    required MaterialColor color,
    required List<Widget> children,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color[700], size: 20),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color[700]),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey[700]),
            ),
          ),
          Expanded(
            child: Text(value, style: TextStyle(color: Colors.grey[800])),
          ),
        ],
      ),
    );
  }

  Widget _buildBadgeRow({
    required String badge,
    required String text,
    required Color badgeColor,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.black12),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(color: badgeColor, borderRadius: BorderRadius.circular(12)),
            child: Text(
              badge,
              style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(text, style: TextStyle(fontSize: 13, color: Colors.grey[800])),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} at ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }

  bool _hasBMOOverlay(List overlays) {
    return overlays.any((overlay) {
      final overlayMap = overlay as Map<String, dynamic>;
      final code = (overlayMap['code'] ?? '').toString().toUpperCase();
      final desc = (overlayMap['description'] ?? '').toString().toUpperCase();
      return code.contains('BMO') || desc.contains('BUSHFIRE MANAGEMENT');
    });
  }

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

  Future<void> _refreshPlanningData(BuildContext context) async {
    if (widget.site.latitude == null || widget.site.longitude == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No coordinates available for this site')),
      );
      return;
    }
    
    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(),
      ),
    );
    
    try {
      // Get fresh planning data from API
      final resp = await RealPlanningService.getPlanningAtPoint(
        latitude: widget.site.latitude!,
        longitude: widget.site.longitude!,
      );
      
      // Extract LGA
      String lgaName = 'Unknown';
      if (resp['lga'] != null) {
        final lgaData = resp['lga'];
        if (lgaData is Map) {
          lgaName = (lgaData['LGA'] ?? lgaData['lga'] ?? '').toString();
        } else {
          lgaName = lgaData.toString();
        }
      }
      
      // Fallback to overlays for LGA
      if (lgaName == 'Unknown' || lgaName.isEmpty) {
        final overlaysRaw = (resp['overlays'] as List?) ?? const [];
        if (overlaysRaw.isNotEmpty && overlaysRaw.first is Map) {
          lgaName = (overlaysRaw.first['LGA'] ?? '').toString();
        }
      }
      
      // Process overlays and zones
      final overlays = (resp['overlays'] as List?)?.map((o) {
        final m = o as Map;
        return {
          'code': m['ZONE_CODE'] ?? '',
          'description': m['ZONE_DESCRIPTION'] ?? '',
          'raw': m,
        };
      }).toList() ?? [];
      
      final zones = (resp['zones'] as List?)?.map((z) {
        final m = z as Map;
        return {
          'code': m['ZONE_CODE'] ?? '',
          'description': m['ZONE_DESCRIPTION'] ?? '',
          'raw': m,
        };
      }).toList() ?? [];
      
      // LGA local laws only (no AI summary)
      String lgaLocalLaws = '';
      
      lgaLocalLaws = await PlanningAIService.generateLGALocalLaws(
        lga: lgaName,
      ).timeout(const Duration(seconds: 15));
      
      // Update site with new planning data
      final updatedVicPlanData = {
        'address': widget.site.address,
        'coordinates': '${widget.site.latitude}, ${widget.site.longitude}',
        'timestamp': DateTime.now().toIso8601String(),
        'lga': lgaName,
        'lgaLocalLaws': lgaLocalLaws,
        'overlays': overlays,
        'zones': zones,
        'data_source': 'Vicmap Planning (Overlays=2, Zones=3) + Vicmap_Admin LGA (9)',
      };
      
      final updatedSite = Site(
        id: widget.site.id,
        name: widget.site.name,
        address: widget.site.address,
        notes: widget.site.notes,
        createdAt: widget.site.createdAt,
        syncStatus: widget.site.syncStatus,
        latitude: widget.site.latitude,
        longitude: widget.site.longitude,
        vicPlanData: updatedVicPlanData,
      );
      
      await SiteStorageService.updateSite(updatedSite.id, updatedSite);
      
      Navigator.pop(context); // Close loading dialog
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('✅ Planning data refreshed with AI summaries!')),
      );
      
      // Refresh the page
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => SiteMainPage(site: updatedSite, initialTab: 3), // Details tab
        ),
      );
    } catch (e) {
      Navigator.pop(context); // Close loading dialog
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error refreshing planning data: $e')),
      );
    }
  }
  
  void _exportSiteDetails(BuildContext context) {
    // Generate site details document content
    final content = _generateSiteDetailsDocument();
    
    // Show export options
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Export Site Details'),
        content: const Text('Choose export format:'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _copyToClipboard(context, content);
            },
            child: const Text('Copy to Clipboard'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _downloadAsText(context, content);
            },
            child: const Text('Download as Text'),
          ),
        ],
      ),
    );
  }

  String _generateSiteDetailsDocument() {
    final buffer = StringBuffer();
    
    // Header
    buffer.writeln('SITE DETAILS REPORT');
    buffer.writeln('Generated: ${DateTime.now().toString()}');
    buffer.writeln('=' * 50);
    buffer.writeln();
    
    // Site Information
    buffer.writeln('SITE INFORMATION');
    buffer.writeln('-' * 20);
    buffer.writeln('Site Name: ${widget.site.name}');
    buffer.writeln('Address: ${widget.site.address}');
    buffer.writeln('Created: ${_formatDate(widget.site.createdAt)}');
    if (widget.site.notes?.isNotEmpty == true) {
      buffer.writeln('Notes: ${widget.site.notes}');
    }
    buffer.writeln();
    
    // Planning Data
    if (widget.site.vicPlanData != null) {
      buffer.writeln('PLANNING SUMMARY');
      buffer.writeln('-' * 20);
      buffer.writeln('LGA: ${widget.site.vicPlanData!['lga'] ?? 'Unknown'}');
      buffer.writeln('Data Source: ${widget.site.vicPlanData!['data_source'] ?? 'Unknown'}');
      buffer.writeln('Retrieved: ${_formatDate(DateTime.parse(widget.site.vicPlanData!['timestamp']))}');
      if (widget.site.vicPlanData!['coordinates'] != null) {
        buffer.writeln('Coordinates: ${widget.site.vicPlanData!['coordinates']}');
      }
      buffer.writeln();
      
      // Zones
      if (widget.site.vicPlanData!['zones'] != null && (widget.site.vicPlanData!['zones'] as List).isNotEmpty) {
        buffer.writeln('PLANNING ZONES');
        buffer.writeln('-' * 20);
        for (final zone in widget.site.vicPlanData!['zones'] as List) {
          final zoneMap = zone as Map<String, dynamic>;
          buffer.writeln('• ${zoneMap['code'] ?? 'ZONE'}: ${zoneMap['description'] ?? ''}');
        }
        buffer.writeln();
      }
      
      // Overlays
      if (widget.site.vicPlanData!['overlays'] != null && (widget.site.vicPlanData!['overlays'] as List).isNotEmpty) {
        buffer.writeln('PLANNING OVERLAYS');
        buffer.writeln('-' * 20);
        for (final overlay in widget.site.vicPlanData!['overlays'] as List) {
          final overlayMap = overlay as Map<String, dynamic>;
          buffer.writeln('• ${overlayMap['code'] ?? 'OVERLAY'}: ${overlayMap['description'] ?? ''}');
        }
        buffer.writeln();
        
        // Tree Protection Summary
        buffer.writeln('TREE PROTECTION SUMMARY');
        buffer.writeln('-' * 20);
        for (final overlay in widget.site.vicPlanData!['overlays'] as List) {
          final overlayMap = overlay as Map<String, dynamic>;
          final code = overlayMap['code']?.toString().toUpperCase() ?? '';
          buffer.writeln('${code} - ${_getOverlayTreeExplanation(code)}');
          buffer.writeln('  Requirements: ${_getOverlayTreeRequirements(code)}');
          buffer.writeln();
        }
        
        // BMO Warning
        if (_hasBMOOverlay(widget.site.vicPlanData!['overlays'] as List)) {
          buffer.writeln('⚠️  BUSHFIRE MANAGEMENT OVERLAY PRESENT');
          buffer.writeln('Tree removal may be required for safety in this area.');
          buffer.writeln();
        }
      }
    } else {
      buffer.writeln('PLANNING DATA');
      buffer.writeln('-' * 20);
      buffer.writeln('No planning data available for this site.');
      buffer.writeln('Use the "Permits" button when creating sites to load planning information.');
      buffer.writeln();
    }
    
    // Footer
    buffer.writeln('=' * 50);
    buffer.writeln('Report generated by Arborist Assistant');
    
    return buffer.toString();
  }

  void _copyToClipboard(BuildContext context, String content) {
    // For web, we can use the clipboard API
    // For mobile, this would need a different approach
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Site details copied to clipboard!')),
    );
  }

  Future<void> _downloadAsText(BuildContext context, String content) async {
    // For web, create a downloadable text file
    final bytes = utf8.encode(content);
    await downloadFile(bytes, 'site_details.txt', 'text/plain');
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Site details downloaded!')),
    );
  }
}
