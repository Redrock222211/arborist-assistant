import 'package:flutter/material.dart';
import '../models/site.dart';
import '../models/tree_entry.dart';
import '../services/site_storage_service.dart';
import '../services/tree_storage_service.dart';
import '../services/app_state_service.dart';
import '../widgets/app_logo.dart';
import 'package:intl/intl.dart';
import 'tree_permit_page.dart';
import 'site_files_page.dart';
import 'enhanced_site_creation_dialog.dart';

class SiteSelectPage extends StatefulWidget {
  final void Function(Site) onSiteSelected;
  const SiteSelectPage({super.key, required this.onSiteSelected});

  @override
  State<SiteSelectPage> createState() => _SiteSelectPageState();
}

class _SiteSelectPageState extends State<SiteSelectPage> {
  List<Site> _sites = [];
  int _totalTrees = 0;
  List<TreeEntry> _recentTrees = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() {
    setState(() {
      _sites = SiteStorageService.getAllSites();
      _sites.sort((a, b) => b.createdAt.compareTo(a.createdAt)); // Most recent first
      
      // Load tree statistics
      _totalTrees = 0;
      _recentTrees = [];
      
      for (final site in _sites) {
        final trees = TreeStorageService.getTreesForSite(site.id);
        _totalTrees += trees.length;
        _recentTrees.addAll(trees);
      }
      
      // Sort recent trees by creation date and take the last 5
      _recentTrees.sort((a, b) => b.id.compareTo(a.id));
      _recentTrees = _recentTrees.take(5).toList();
    });
  }

  void _addSite() async {
    final newSite = await showDialog<Site>(
      context: context,
      barrierDismissible: false,
      builder: (context) => EnhancedSiteCreationDialog(
        onSiteCreated: (Site site) {
          Navigator.of(context).pop(site);
        },
        existingSites: _sites,
      ),
    );
    
    if (newSite != null) {
      await SiteStorageService.addSite(newSite);
      _loadData();
    }
  }

  void _deleteSite(Site site) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Site'),
        content: Text('Are you sure you want to delete site "${site.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await SiteStorageService.deleteSite(site.id);
      _loadData();
    }
  }

  Widget _buildStatsCard(String title, String value, IconData icon, Color color) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 32, color: color),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              title,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActionCard(String title, IconData icon, Color color, VoidCallback onTap) {
    return Card(
      elevation: 2,
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 28, color: color),
              const SizedBox(height: 8),
              Text(
                title,
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final recentSites = _sites.take(3).toList();
    
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with Logo and Welcome
              Row(
                children: [
                  const AppLogo(size: 60, showText: false, color: Colors.green),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Welcome to',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[600],
                          ),
                        ),
                        const Text(
                          'Arb Assistant',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Colors.green,
                          ),
                        ),
                        Text(
                          'Professional Tree Management',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 24),
              
              // Quick Stats
              const Text(
                'Overview',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildStatsCard(
                      'Active Sites',
                      _sites.length.toString(),
                      Icons.location_on,
                      Colors.blue,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildStatsCard(
                      'Total Trees',
                      _totalTrees.toString(),
                      Icons.nature,
                      Colors.green,
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 24),
              
              // Quick Actions
              const Text(
                'Quick Actions',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildQuickActionCard(
                      'New Site',
                      Icons.add_location,
                      Colors.green,
                      _addSite,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildQuickActionCard(
                      'View All Sites',
                      Icons.list,
                      Colors.blue,
                      () => _showAllSites(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildQuickActionCard(
                      'Tree Permits',
                      Icons.description,
                      Colors.orange,
                      () => _openTreePermits(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildQuickActionCard(
                      'Site Files',
                      Icons.folder,
                      Colors.purple,
                      () => _openFiles(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildQuickActionCard(
                      'Export Data',
                      Icons.download,
                      Colors.blue,
                      () => _showExportOptions(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildQuickActionCard(
                      'Settings',
                      Icons.settings,
                      Colors.grey,
                      () => _openSettings(),
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 24),
              
              // Recent Sites
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Recent Sites',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  if (_sites.length > 3)
                    TextButton(
                      onPressed: _showAllSites,
                      child: const Text('View All'),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              
              if (recentSites.isEmpty)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      children: [
                        Icon(Icons.location_off, size: 64, color: Colors.grey[400]),
                        const SizedBox(height: 16),
                        Text(
                          'No sites yet',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w500,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Create your first site to start collecting tree data',
                          style: TextStyle(color: Colors.grey[500]),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          onPressed: _addSite,
                          icon: const Icon(Icons.add),
                          label: const Text('Create Site'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              else
                ...recentSites.map(
                  (site) => Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: Colors.green,
                        child: Text(
                          site.name.substring(0, 1).toUpperCase(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      title: Text(
                        site.name,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (site.address.isNotEmpty)
                            Text(site.address),
                          Text(
                            'Created ${DateFormat.yMMMd().format(site.createdAt)}',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[500],
                            ),
                          ),
                        ],
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () => _deleteSite(site),
                            tooltip: 'Delete Site',
                          ),
                          const Icon(Icons.arrow_forward_ios, size: 16),
                        ],
                      ),
                      onTap: () async {
                        await AppStateService.saveLastSite(site.id);
                        widget.onSiteSelected(site);
                      },
                    ),
                  ),
                ),
              
              const SizedBox(height: 24),
              
              // Recent Activity
              if (_recentTrees.isNotEmpty) ...[
                const Text(
                  'Recent Tree Entries',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                Card(
                  child: Column(
                    children: _recentTrees.take(3).map(
                      (tree) => ListTile(
                        leading: const CircleAvatar(
                          backgroundColor: Colors.green,
                          child: Icon(Icons.nature, color: Colors.white),
                        ),
                        title: Text(tree.species ?? 'Unknown Species'),
                        subtitle: Text(
                                                     'Tree ${tree.id} • ${tree.dsh ?? 0} cm DSH',
                        ),
                        trailing: Text(
                          tree.condition ?? 'No condition',
                          style: TextStyle(
                            fontSize: 12,
                            color: _getConditionColor(tree.condition),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ).toList(),
                  ),
                ),
                const SizedBox(height: 24),
              ],
              
              // Footer
              Center(
                child: Text(
                  'ARBORESTS BY NATURE',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[400],
                    letterSpacing: 1.2,
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
  
  Color _getConditionColor(String? condition) {
    switch (condition?.toLowerCase()) {
      case 'excellent':
      case 'good':
        return Colors.green;
      case 'fair':
      case 'poor':
        return Colors.orange;
      case 'dead':
      case 'dying':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
  
  void _showAllSites() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.9,
        minChildSize: 0.5,
        builder: (context, scrollController) => Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'All Sites',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                controller: scrollController,
                itemCount: _sites.length,
                itemBuilder: (context, index) {
                  final site = _sites[index];
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Colors.green,
                      child: Text(
                        site.name.substring(0, 1).toUpperCase(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    title: Text(site.name),
                    subtitle: Text(site.address),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () {
                            Navigator.pop(context);
                            _deleteSite(site);
                          },
                        ),
                        const Icon(Icons.arrow_forward_ios, size: 16),
                      ],
                    ),
                    onTap: () {
                      Navigator.pop(context);
                      widget.onSiteSelected(site);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  void _showExportOptions() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Export Options'),
        content: const Text('Export functionality will be available when you select a site and go to the Export/Sync page.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
  
  void _openTreePermits() {
    if (_sites.isEmpty) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('No Sites Available'),
          content: const Text('Please create a site first to use the tree permit lookup feature.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        ),
      );
      return;
    }

    // If only one site, use it directly
    if (_sites.length == 1) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => TreePermitPage(site: _sites.first),
        ),
      );
      return;
    }

    // If multiple sites, show selection dialog
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Site for Permit Lookup'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: _sites.length,
            itemBuilder: (context, index) {
              final site = _sites[index];
              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: Colors.green,
                  child: Text(
                    site.name.substring(0, 1).toUpperCase(),
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
                title: Text(site.name),
                subtitle: Text(site.address),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => TreePermitPage(site: site),
                    ),
                  );
                },
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  void _openFiles() {
    if (_sites.isEmpty) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('No Sites Available'),
          content: const Text('Please create a site first to access its files.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        ),
      );
      return;
    }

    // If only one site, use it directly
    if (_sites.length == 1) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => SiteFilesPage(site: _sites.first),
        ),
      );
      return;
    }

    // If multiple sites, show selection dialog
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Site for Files'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: _sites.length,
            itemBuilder: (context, index) {
              final site = _sites[index];
              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: Colors.purple,
                  child: Text(
                    site.name.substring(0, 1).toUpperCase(),
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
                title: Text(site.name),
                subtitle: Text(site.address),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => SiteFilesPage(site: site),
                    ),
                  );
                },
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  void _openSettings() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Settings'),
        content: const Text('Settings functionality will be available from the main app drawer when you select a site.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}
