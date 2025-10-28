import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../services/branding_service.dart';
import '../services/backup_service.dart';
import '../services/notification_service.dart';
import '../services/site_storage_service.dart';
import '../services/tree_storage_service.dart';
import '../services/site_file_service.dart';
import '../services/planning_ai_service.dart';
import '../models/site.dart';
import '../config/ai_config.dart';
import 'package:url_launcher/url_launcher.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  String? _logoPath;
  String _scale = 'auto';
  String _placement = 'topRight';
  
  // AI Configuration
  final _apiKeyController = TextEditingController();
  bool _aiEnabled = false;
  bool _usingCustomKey = false;

  @override
  void initState() {
    super.initState();
    BrandingService.init().then((_) {
      final branding = BrandingService.loadBranding();
      if (branding != null) {
        setState(() {
          _logoPath = branding.logoPath;
          _scale = branding.scale;
          _placement = branding.placement;
        });
      }
    });
    
    // Load AI settings
    _loadAISettings();
  }
  
  Future<void> _loadAISettings() async {
    final key = await AIConfig.getApiKey();
    final enabled = await AIConfig.isEnabled();
    final custom = await AIConfig.isUsingCustomKey();
    
    setState(() {
      _apiKeyController.text = custom ? key : '';
      _aiEnabled = enabled;
      _usingCustomKey = custom;
    });
  }
  
  @override
  void dispose() {
    _apiKeyController.dispose();
    super.dispose();
  }

  Future<void> _pickLogo() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() => _logoPath = picked.path);
    }
  }

  Future<void> _saveSettings() async {
    await BrandingService.saveBranding(
      BrandingSettings(logoPath: _logoPath, scale: _scale, placement: _placement),
    );
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Branding settings saved.')));
  }

  Widget _buildPreview() {
    if (_logoPath == null) {
      return const Center(child: Text('No logo selected.'));
    }
    double size;
    switch (_scale) {
      case 'small':
        size = 48;
        break;
      case 'medium':
        size = 96;
        break;
      case 'large':
        size = 160;
        break;
      default:
        size = 72;
    }
    Alignment align;
    switch (_placement) {
      case 'topLeft':
        align = Alignment.topLeft;
        break;
      case 'topRight':
        align = Alignment.topRight;
        break;
      case 'bottomLeft':
        align = Alignment.bottomLeft;
        break;
      case 'bottomRight':
        align = Alignment.bottomRight;
        break;
      case 'center':
        align = Alignment.center;
        break;
      default:
        align = Alignment.topRight;
    }
    return Container(
      height: 200,
      color: Colors.grey[200],
      child: Stack(
        children: [
          Align(
            alignment: align,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Image.file(File(_logoPath!), width: size, height: size, fit: BoxFit.contain),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings & Branding')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text('Logo', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Row(
            children: [
              ElevatedButton.icon(
                icon: const Icon(Icons.upload),
                label: const Text('Upload Logo'),
                onPressed: _pickLogo,
              ),
              const SizedBox(width: 16),
              if (_logoPath != null)
                Expanded(child: Text(_logoPath!, overflow: TextOverflow.ellipsis)),
            ],
          ),
          const SizedBox(height: 16),
          const Text('Scale', style: TextStyle(fontWeight: FontWeight.bold)),
          DropdownButton<String>(
            value: _scale,
            onChanged: (v) => setState(() => _scale = v ?? 'auto'),
            items: const [
              DropdownMenuItem(value: 'auto', child: Text('Auto')),
              DropdownMenuItem(value: 'small', child: Text('Small')),
              DropdownMenuItem(value: 'medium', child: Text('Medium')),
              DropdownMenuItem(value: 'large', child: Text('Large')),
            ],
          ),
          const SizedBox(height: 16),
          const Text('Placement', style: TextStyle(fontWeight: FontWeight.bold)),
          DropdownButton<String>(
            value: _placement,
            onChanged: (v) => setState(() => _placement = v ?? 'topRight'),
            items: const [
              DropdownMenuItem(value: 'topLeft', child: Text('Top Left')),
              DropdownMenuItem(value: 'topRight', child: Text('Top Right')),
              DropdownMenuItem(value: 'bottomLeft', child: Text('Bottom Left')),
              DropdownMenuItem(value: 'bottomRight', child: Text('Bottom Right')),
              DropdownMenuItem(value: 'center', child: Text('Center')),
            ],
          ),
          const SizedBox(height: 24),
          const Text('Live Preview', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          _buildPreview(),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            icon: const Icon(Icons.save),
            label: const Text('Save Branding Settings'),
            onPressed: _saveSettings,
          ),
          const SizedBox(height: 32),
          _buildAIConfigSection(),
          const SizedBox(height: 16),
          _buildBackupSection(),
          const SizedBox(height: 16),
          _buildDataSection(),
        ],
      ),
    );
  }
  
  Widget _buildAIConfigSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.psychology, color: Colors.purple.shade600),
                const SizedBox(width: 8),
                const Text(
                  'AI Configuration',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                Icon(
                  _aiEnabled ? Icons.check_circle : Icons.cancel,
                  color: _aiEnabled ? Colors.green : Colors.grey,
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              'Use AI to generate intelligent permit summaries from Victorian planning data.',
              style: TextStyle(color: Colors.grey[700]),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _apiKeyController,
              decoration: InputDecoration(
                labelText: 'Google Gemini API Key',
                hintText: 'Enter your API key (optional)',
                border: const OutlineInputBorder(),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.help_outline),
                  onPressed: () => _showAPIKeyHelp(),
                ),
              ),
              obscureText: true,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.save),
                    label: const Text('Save API Key'),
                    onPressed: _saveAISettings,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.purple,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                if (_usingCustomKey)
                  ElevatedButton.icon(
                    icon: const Icon(Icons.restore),
                    label: const Text('Use Default'),
                    onPressed: _clearCustomKey,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey,
                      foregroundColor: Colors.white,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            TextButton.icon(
              icon: const Icon(Icons.open_in_new),
              label: const Text('Get Free API Key'),
              onPressed: () => _openAPIKeyPage(),
            ),
            if (_usingCustomKey)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, size: 16, color: Colors.blue.shade600),
                    const SizedBox(width: 4),
                    Text(
                      'Using your custom API key',
                      style: TextStyle(fontSize: 12, color: Colors.blue.shade600),
                    ),
                  ],
                ),
              ),
            if (!_usingCustomKey && _aiEnabled)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, size: 16, color: Colors.orange.shade600),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        'Using default API key for testing (shared)',
                        style: TextStyle(fontSize: 12, color: Colors.orange.shade600),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
  
  Future<void> _saveAISettings() async {
    final apiKey = _apiKeyController.text.trim();
    if (apiKey.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter an API key')),
      );
      return;
    }
    
    await AIConfig.setApiKey(apiKey);
    await PlanningAIService.initialize();
    await _loadAISettings();
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('✅ AI configuration saved! Permit summaries will use your API key.')),
      );
    }
  }
  
  Future<void> _clearCustomKey() async {
    await AIConfig.clearApiKey();
    await PlanningAIService.initialize();
    await _loadAISettings();
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Reverted to default API key')),
      );
    }
  }
  
  void _showAPIKeyHelp() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('AI-Powered Permit Summaries'),
        content: const SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'What does this do?',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text(
                'Instead of showing generic overlay codes, the app uses AI to interpret Victorian planning data and generate specific permit requirements.',
              ),
              SizedBox(height: 16),
              Text(
                'Example Output:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text(
                'VPO2: Permit required to remove trees DBH > 20cm or prune limbs > 10cm diameter. Exemptions for dead/dying trees with arborist certification.',
                style: TextStyle(fontStyle: FontStyle.italic),
              ),
              SizedBox(height: 16),
              Text(
                'Why add your own key?',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text(
                '• Free tier: 1,500 requests/day\n• No credit card required\n• Your own quota\n• Takes 2 minutes to get',
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
  
  Future<void> _openAPIKeyPage() async {
    final uri = Uri.parse('https://aistudio.google.com/app/apikey');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  Widget _buildBackupSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.backup, color: Colors.blue.shade600),
                const SizedBox(width: 8),
                const Text(
                  'Backup & Restore',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Text(
              'Export your data for backup or transfer to another device.',
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _exportAllData,
                    icon: const Icon(Icons.download),
                    label: const Text('Export All Data'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _showBackupStats,
                    icon: const Icon(Icons.info),
                    label: const Text('Data Stats'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDataSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.storage, color: Colors.blue.shade600),
                const SizedBox(width: 8),
                const Text(
                  'Site Management',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Text(
              'Manage your sites and their data.',
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _manageSites,
              icon: const Icon(Icons.location_on),
              label: const Text('Manage Sites'),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _exportAllData() async {
    try {
      NotificationService.showLoadingDialog(context, 'Exporting data...');
      await BackupService.exportAllData();
      Navigator.of(context).pop(); // Close loading dialog
      NotificationService.showSuccess(context, 'Data exported successfully');
    } catch (e) {
      Navigator.of(context).pop(); // Close loading dialog
      NotificationService.showError(context, 'Failed to export data: $e');
    }
  }

  Future<void> _showBackupStats() async {
    try {
      NotificationService.showLoadingDialog(context, 'Loading stats...');
      final stats = await BackupService.getBackupStats();
      Navigator.of(context).pop(); // Close loading dialog
      
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Data Statistics'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildStatRow('Sites', stats['sites'].toString()),
              _buildStatRow('Trees', stats['trees'].toString()),
              _buildStatRow('Permits', stats['permits'].toString()),
              _buildStatRow('Files', stats['files'].toString()),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
          ],
        ),
      );
    } catch (e) {
      Navigator.of(context).pop(); // Close loading dialog
      NotificationService.showError(context, 'Failed to load stats: $e');
    }
  }

  Widget _buildStatRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Future<void> _manageSites() async {
    final sites = SiteStorageService.getAllSites();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Manage Sites'),
        content: SizedBox(
          width: double.maxFinite,
          height: 400,
          child: ListView.builder(
            itemCount: sites.length,
            itemBuilder: (context, index) {
              final site = sites[index];
              return ListTile(
                leading: const Icon(Icons.location_on),
                title: Text(site.name),
                subtitle: Text(site.address),
                trailing: IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () => _deleteSiteWithConfirmation(site),
                ),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteSiteWithConfirmation(Site site) async {
    // First confirmation
    final firstConfirm = await NotificationService.showConfirmationDialog(
      context,
      title: 'Delete Site',
      message: 'Are you sure you want to delete site "${site.name}"? This will also delete all trees and files associated with this site.',
      confirmText: 'Yes, Delete',
      cancelText: 'Cancel',
      isDestructive: true,
    );

    if (firstConfirm) {
      // Second confirmation
      final secondConfirm = await NotificationService.showConfirmationDialog(
        context,
        title: 'Final Confirmation',
        message: 'This action cannot be undone. Are you absolutely sure you want to delete "${site.name}" and all its data?',
        confirmText: 'Yes, Delete Permanently',
        cancelText: 'Cancel',
        isDestructive: true,
      );

      if (secondConfirm) {
        try {
          NotificationService.showLoadingDialog(context, 'Deleting site...');
          
          // Delete all trees for this site
          await TreeStorageService.clearAllForSite(site.id);
          
          // Delete all files for this site
          final files = await SiteFileService.getFilesForSite(site.id);
          for (final file in files) {
            await SiteFileService.deleteFile(file.id);
          }
          
          // Delete the site
          await SiteStorageService.deleteSite(site.id);
          
          Navigator.of(context).pop(); // Close loading dialog
          Navigator.of(context).pop(); // Close site management dialog
          
          NotificationService.showSuccess(context, 'Site deleted successfully');
          
          // Refresh the settings page
          setState(() {});
        } catch (e) {
          Navigator.of(context).pop(); // Close loading dialog
          NotificationService.showError(context, 'Failed to delete site: $e');
        }
      }
    }
  }
}
