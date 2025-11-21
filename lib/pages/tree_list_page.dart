import 'package:flutter/material.dart';
import '../models/tree_entry.dart';
import '../models/site.dart';
import '../models/report_type.dart';
import '../widgets/tree_form.dart';
import 'report_type_selector.dart';
import '../services/tree_storage_service.dart';

enum TreeSortOption {
  species,
  dbhAsc,
  dbhDesc,
  heightAsc,
  heightDesc,
  permitRequired,
}

class TreeListPage extends StatefulWidget {
  final Site site;
  const TreeListPage({super.key, required this.site});

  @override
  State<TreeListPage> createState() => _TreeListPageState();
}

class _TreeListPageState extends State<TreeListPage> {
  List<MapEntry<dynamic, TreeEntry>> _treeEntriesWithKeys = [];
  List<MapEntry<dynamic, TreeEntry>> _filteredEntries = [];
  TreeSortOption _sortOption = TreeSortOption.species;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
    _loadTrees();
  }

  @override
  void didUpdateWidget(TreeListPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.site.id != widget.site.id) {
      _loadTrees();
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    setState(() {
      _searchQuery = _searchController.text;
      _applyFilter();
    });
  }

  void _loadTrees() {
    setState(() {
      _treeEntriesWithKeys = TreeStorageService.getTreeEntriesWithKeysForSite(widget.site.id);
      _applySort();
      _applyFilter();
    });
  }

  void _applySort() {
    switch (_sortOption) {
      case TreeSortOption.species:
        _treeEntriesWithKeys.sort((a, b) => a.value.species.toLowerCase().compareTo(b.value.species.toLowerCase()));
        break;
      case TreeSortOption.dbhAsc:
        _treeEntriesWithKeys.sort((a, b) => a.value.dsh.compareTo(b.value.dsh));
        break;
      case TreeSortOption.dbhDesc:
        _treeEntriesWithKeys.sort((a, b) => b.value.dsh.compareTo(a.value.dsh));
        break;
      case TreeSortOption.heightAsc:
        _treeEntriesWithKeys.sort((a, b) => a.value.height.compareTo(b.value.height));
        break;
      case TreeSortOption.heightDesc:
        _treeEntriesWithKeys.sort((a, b) => b.value.height.compareTo(a.value.height));
        break;
      case TreeSortOption.permitRequired:
        _treeEntriesWithKeys.sort((a, b) => b.value.permitRequired.toString().compareTo(a.value.permitRequired.toString()));
        break;
    }
  }

  void _applyFilter() {
    if (_searchQuery.isEmpty) {
      _filteredEntries = List.from(_treeEntriesWithKeys);
    } else {
      final query = _searchQuery.toLowerCase();
      _filteredEntries = _treeEntriesWithKeys.where((entry) {
        final tree = entry.value;
        return tree.id.toLowerCase().contains(query) ||
            tree.species.toLowerCase().contains(query) ||
            tree.condition.toLowerCase().contains(query) ||
            tree.comments.toLowerCase().contains(query) ||
            tree.dsh.toString().contains(query) ||
            tree.height.toString().contains(query) ||
            (tree.permitRequired ? 'yes' : 'no').contains(query);
      }).toList();
    }
  }

  Widget _highlightMatch(String text, String query) {
    if (query.isEmpty) return Text(text);
    final lowerText = text.toLowerCase();
    final lowerQuery = query.toLowerCase();
    final spans = <TextSpan>[];
    int start = 0;
    int index;
    do {
      index = lowerText.indexOf(lowerQuery, start);
      if (index < 0) {
        spans.add(TextSpan(text: text.substring(start)));
        break;
      }
      if (index > start) {
        spans.add(TextSpan(text: text.substring(start, index)));
      }
      spans.add(TextSpan(
        text: text.substring(index, index + lowerQuery.length),
        style: const TextStyle(backgroundColor: Colors.yellow),
      ));
      start = index + lowerQuery.length;
    } while (start < text.length);
    return RichText(text: TextSpan(style: const TextStyle(color: Colors.black), children: spans));
  }

  void _editTree(TreeEntry entry, dynamic key) async {
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
              await TreeStorageService.updateTree(key, updatedEntry);
              Navigator.of(context).pop();
              _loadTrees();
            },
          ),
        );
      },
    );
  }

  void _addTree() async {
    // Navigate to Report Type Selector instead of directly showing form
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ReportTypeSelector(site: widget.site),
      ),
    );
    // Reload trees when returning from the selector
    _loadTrees();
  }

  void _deleteTree(dynamic key) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Tree'),
        content: const Text('Are you sure you want to delete this tree entry?'),
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
      await TreeStorageService.deleteTree(key);
      _loadTrees();
    }
  }

  void _showReportDialog(TreeEntry entry) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('ISA/VTA Report'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Tree ID: ${entry.id}'),
              Text('Species: ${entry.species}'),
              Text('DSH: ${entry.dsh} cm'),
              Text('Height: ${entry.height} m'),
              Text('Condition: ${entry.condition}'),
              Text('Location: ${entry.locationDescription}'),
              const Divider(),
              Text('--- ISA Risk Assessment ---'),
              Text('Target/Occupancy: ${entry.targetOccupancy}'),
              Text('Defects Observed: ${entry.defectsObserved.join(", ")}'),
              Text('Likelihood of Failure: ${entry.likelihoodOfFailure}'),
              Text('Likelihood of Impact: ${entry.likelihoodOfImpact}'),
              Text('Consequence of Failure: ${entry.consequenceOfFailure}'),
              Text('Overall Risk Rating: ${entry.overallRiskRating}'),
              const Divider(),
              Text('--- VTA ---'),
              Text('VTA Notes: ${entry.vtaNotes}'),
              Text('VTA Defects: ${entry.vtaDefects.join(", ")}'),
              Text('Inspection Date: ${entry.inspectionDate != null ? entry.inspectionDate!.toLocal().toString().split(' ')[0] : ''}'),
              Text('Inspector: ${entry.inspectorName}'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
          // TODO: Add export to PDF/CSV here
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    const Text('Sort by:'),
                    const SizedBox(width: 8),
                    DropdownButton<TreeSortOption>(
                      value: _sortOption,
                      onChanged: (option) {
                        if (option != null) {
                          setState(() {
                            _sortOption = option;
                            _applySort();
                            _applyFilter();
                          });
                        }
                      },
                      items: const [
                        DropdownMenuItem(
                          value: TreeSortOption.species,
                          child: Text('Species (A-Z)'),
                        ),
                        DropdownMenuItem(
                          value: TreeSortOption.dbhAsc,
                          child: Text('DBH (asc)'),
                        ),
                        DropdownMenuItem(
                          value: TreeSortOption.dbhDesc,
                          child: Text('DBH (desc)'),
                        ),
                        DropdownMenuItem(
                          value: TreeSortOption.heightAsc,
                          child: Text('Height (asc)'),
                        ),
                        DropdownMenuItem(
                          value: TreeSortOption.heightDesc,
                          child: Text('Height (desc)'),
                        ),
                        DropdownMenuItem(
                          value: TreeSortOption.permitRequired,
                          child: Text('Permit Required'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: TextField(
                controller: _searchController,
                decoration: const InputDecoration(
                  labelText: 'Search trees...',
                  prefixIcon: Icon(Icons.search),
                  border: OutlineInputBorder(),
                ),
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: _filteredEntries.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.forest, size: 80, color: Colors.green[300]),
                          const SizedBox(height: 24),
                          Text(
                            'No Trees Yet',
                            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Colors.grey[700],
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Get started by adding your first tree!',
                            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              color: Colors.grey[600],
                            ),
                          ),
                          const SizedBox(height: 32),
                          ElevatedButton.icon(
                            onPressed: _addTree,
                            icon: const Icon(Icons.add),
                            label: const Text('Add First Tree'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                              textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                          ),
                          const SizedBox(height: 24),
                          Container(
                            padding: const EdgeInsets.all(16),
                            margin: const EdgeInsets.symmetric(horizontal: 32),
                            decoration: BoxDecoration(
                              color: Colors.blue.shade50,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.blue.shade200),
                            ),
                            child: Column(
                              children: [
                                Icon(Icons.lightbulb, color: Colors.blue.shade700, size: 32),
                                const SizedBox(height: 8),
                                Text(
                                  'Quick Tip',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                    color: Colors.blue.shade900,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Tree forms are customized based on your site\'s report type.\n\nYou selected: ${widget.site.reportTypeEnum.title}',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.blue.shade800,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.separated(
                itemCount: _filteredEntries.length,
                separatorBuilder: (context, index) => const Divider(),
                itemBuilder: (context, index) {
                  final entry = _filteredEntries[index].value;
                  final key = _filteredEntries[index].key;
                  Icon syncIcon;
                  Color? syncColor;
                  String syncTooltip;
                  switch (entry.syncStatus) {
                    case 'synced':
                      syncIcon = const Icon(Icons.check_circle, color: Colors.green, size: 20);
                      syncColor = Colors.green;
                      syncTooltip = 'Synced to cloud';
                      break;
                    case 'error':
                      syncIcon = const Icon(Icons.error, color: Colors.red, size: 20);
                      syncColor = Colors.red;
                      syncTooltip = 'Sync error';
                      break;
                    default:
                      syncIcon = const Icon(Icons.cloud_off, color: Colors.orange, size: 20);
                      syncColor = Colors.orange;
                      syncTooltip = 'Local only (not synced)';
                  }
                  return ListTile(
                    leading: Tooltip(
                      message: syncTooltip,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          syncIcon,
                          const SizedBox(width: 4),
                          const Icon(Icons.nature, color: Colors.green),
                        ],
                      ),
                    ),
                    title: _highlightMatch('${entry.species} (${entry.id})', _searchQuery),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _highlightMatch('DSH: ${entry.dsh} cm, Height: ${entry.height} m', _searchQuery),
                        if (entry.condition.isNotEmpty)
                          _highlightMatch('Condition: ${entry.condition}', _searchQuery),
                        if (entry.comments.isNotEmpty)
                          _highlightMatch('Comments: ${entry.comments}', _searchQuery),
                      ],
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (entry.permitRequired)
                          const Icon(Icons.warning, color: Colors.orange),
                        IconButton(
                          icon: const Icon(Icons.edit, color: Colors.blue),
                          onPressed: () => _editTree(entry, key),
                          tooltip: 'Edit',
                        ),
                        IconButton(
                          icon: const Icon(Icons.picture_as_pdf, color: Colors.deepPurple),
                          onPressed: () => _showReportDialog(entry),
                          tooltip: 'Generate ISA/VTA Report',
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () => _deleteTree(key),
                          tooltip: 'Delete',
                        ),
                      ],
                    ),
                    onTap: () => _editTree(entry, key),
                    tileColor: syncColor?.withOpacity(0.05),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    horizontalTitleGap: 8,
                    minLeadingWidth: 36,
                    minVerticalPadding: 8,
                    dense: true,
                    visualDensity: VisualDensity.compact,
                    titleTextStyle: Theme.of(context).textTheme.bodyLarge,
                    subtitleTextStyle: Theme.of(context).textTheme.bodySmall,
                    // Tooltip for sync status
                    leadingAndTrailingTextStyle: Theme.of(context).textTheme.bodySmall,
                  );
                },
              ),
            ),
          ],
        ),
      ],
    );
  }
}
