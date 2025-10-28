import 'package:flutter/material.dart';
import '../models/site.dart';
import '../models/tree_entry.dart';
import '../services/tree_storage_service.dart';
import '../services/tree_sync_service.dart';

class SiteSettingsPanel extends StatefulWidget {
  final Site site;
  final bool showSRZ;
  final bool showTPZ;
  final bool showNumbers;
  final bool autoSync;
  final Function(bool) onToggleSRZ;
  final Function(bool) onToggleTPZ;
  final Function(bool) onToggleNumbers;
  final Function(bool) onToggleAutoSync;
  final VoidCallback onManualSync;
  final String syncStatus;

  const SiteSettingsPanel({
    super.key,
    required this.site,
    required this.showSRZ,
    required this.showTPZ,
    required this.showNumbers,
    required this.autoSync,
    required this.onToggleSRZ,
    required this.onToggleTPZ,
    required this.onToggleNumbers,
    required this.onToggleAutoSync,
    required this.onManualSync,
    required this.syncStatus,
  });

  @override
  State<SiteSettingsPanel> createState() => _SiteSettingsPanelState();
}

class _SiteSettingsPanelState extends State<SiteSettingsPanel> {
  List<TreeEntry> _trees = [];
  String _search = '';
  String _syncStatus = 'Up to date';
  bool _syncing = false;

  @override
  void initState() {
    super.initState();
    _loadTrees();
  }

  void _loadTrees() {
    setState(() {
      _trees = TreeStorageService.getTreesForSite(widget.site.id);
    });
  }

  Future<void> _syncNow() async {
    setState(() {
      _syncing = true;
      _syncStatus = 'Syncing...';
    });
    try {
      await TreeSyncService.syncAll(widget.site.id);
      setState(() {
        _syncStatus = 'Up to date';
      });
    } catch (e) {
      setState(() {
        _syncStatus = 'Sync error';
      });
    } finally {
      setState(() {
        _syncing = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final filteredTrees = _search.isEmpty
        ? _trees
        : _trees.where((t) => t.id.toLowerCase().contains(_search.toLowerCase()) || t.species.toLowerCase().contains(_search.toLowerCase())).toList();
    return Container(
      width: 400,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: const BorderRadius.only(topLeft: Radius.circular(24), bottomLeft: Radius.circular(24)),
        boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 12)],
      ),
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
              child: Row(
                children: [
                  Expanded(
                    child: Text(widget.site.name, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
              child: TextField(
                decoration: const InputDecoration(
                  hintText: 'Search trees...',
                  prefixIcon: Icon(Icons.search),
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
                onChanged: (v) => setState(() => _search = v),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              child: Row(
                children: [
                  Expanded(child: Text('Display Options', style: Theme.of(context).textTheme.titleMedium)),
                ],
              ),
            ),
            SwitchListTile(
              value: widget.showSRZ,
              onChanged: widget.onToggleSRZ,
              title: const Text('Show SRZ'),
              secondary: const Icon(Icons.circle_outlined, color: Colors.red),
            ),
            SwitchListTile(
              value: widget.showTPZ,
              onChanged: widget.onToggleTPZ,
              title: const Text('Show TPZ'),
              secondary: const Icon(Icons.circle_outlined, color: Colors.green),
            ),
            SwitchListTile(
              value: widget.showNumbers,
              onChanged: widget.onToggleNumbers,
              title: const Text('Show Tree Numbers'),
              secondary: const Icon(Icons.confirmation_number),
            ),
            SwitchListTile(
              value: widget.autoSync,
              onChanged: widget.onToggleAutoSync,
              title: const Text('Auto Sync'),
              secondary: const Icon(Icons.sync),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              child: Row(
                children: [
                  ElevatedButton.icon(
                    icon: const Icon(Icons.sync),
                    label: Text(_syncing ? 'Syncing...' : 'Sync Now'),
                    onPressed: _syncing ? null : _syncNow,
                  ),
                  const SizedBox(width: 16),
                  Text(_syncStatus, style: TextStyle(color: _syncStatus == 'Up to date' ? Colors.green : (_syncStatus == 'Sync error' ? Colors.red : Colors.orange))),
                ],
              ),
            ),
            const Divider(),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              child: Text('Trees in Site', style: Theme.of(context).textTheme.titleMedium),
            ),
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: filteredTrees.length,
                separatorBuilder: (context, idx) => const Divider(height: 1),
                itemBuilder: (context, idx) {
                  final t = filteredTrees[idx];
                  return ListTile(
                    dense: true,
                    title: Text(t.id, style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text('Species: ${t.species}, DSH: ${t.dsh} cm'),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (t.srz > 0)
                          const Icon(Icons.circle, color: Colors.red, size: 18),
                        if (t.nrz > 0)
                          const Icon(Icons.circle, color: Colors.green, size: 18),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
