import 'package:flutter/material.dart';
import '../models/site.dart';
import '../services/site_storage_service.dart';

class MinimalDialog extends StatefulWidget {
  final Function(Site) onSiteCreated;
  final List<Site> existingSites;

  const MinimalDialog({
    super.key,
    required this.onSiteCreated,
    required this.existingSites,
  });

  @override
  State<MinimalDialog> createState() => _MinimalDialogState();
}

class _MinimalDialogState extends State<MinimalDialog> {
  final _nameController = TextEditingController();
  final _addressController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  void _createSite() {
    if (_nameController.text.trim().isNotEmpty && _addressController.text.trim().isNotEmpty) {
      final site = Site(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: _nameController.text.trim(),
        address: _addressController.text.trim(),
        notes: 'Created with minimal dialog',
        createdAt: DateTime.now(),
      );

      SiteStorageService.addSite(site);
      widget.onSiteCreated(site);
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add New Site'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _nameController,
            decoration: const InputDecoration(
              labelText: 'Site Name',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _addressController,
            decoration: const InputDecoration(
              labelText: 'Address',
              border: OutlineInputBorder(),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _createSite,
          child: const Text('Create'),
        ),
      ],
    );
  }
}
