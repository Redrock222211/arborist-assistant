import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:io';
import '../models/site.dart';
import '../models/site_file.dart';
import '../models/tree_entry.dart';
import '../services/site_file_service.dart';
import '../services/tree_storage_service.dart';
import 'package:intl/intl.dart';
import 'package:csv/csv.dart';
import 'dart:convert';
import '../utils/platform_download.dart';

class SiteFilesPage extends StatefulWidget {
  final Site site;
  const SiteFilesPage({super.key, required this.site});

  @override
  State<SiteFilesPage> createState() => _SiteFilesPageState();
}

class _SiteFilesPageState extends State<SiteFilesPage> {
  List<SiteFile> _files = [];
  List<SiteFile> _filteredFiles = [];
  String _searchQuery = '';
  String _selectedCategory = 'All';
  bool _isLoading = false;
  bool _isUploading = false;
  
  // CSV Export
  List<TreeEntry> _trees = [];
  String _csvData = '';
  bool _showCsvPreview = false;

  @override
  void initState() {
    super.initState();
    _loadFiles();
    _loadTrees();
    _generateCsvData();
  }

  Future<void> _loadFiles() async {
    setState(() => _isLoading = true);
    try {
      await SiteFileService.init();
      final files = await SiteFileService.getFilesForSite(widget.site.id);
      setState(() {
        _files = files;
        _filterFiles();
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading files: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _filterFiles() {
    setState(() {
      _filteredFiles = _files.where((file) {
        final matchesSearch = _searchQuery.isEmpty ||
            file.originalName.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            file.description.toLowerCase().contains(_searchQuery.toLowerCase());
        final matchesCategory = _selectedCategory == 'All' || file.category == _selectedCategory;
        return matchesSearch && matchesCategory;
      }).toList();
    });
  }

  // CSV Export Methods
  void _loadTrees() {
    final trees = TreeStorageService.getTreesForSite(widget.site.id);
    setState(() {
      _trees = trees;
    });
  }

  void _generateCsvData() {
    if (_trees.isEmpty) {
      setState(() {
        _csvData = 'No trees found';
      });
      return;
    }

    // Create CSV headers
    final headers = [
      'Tree ID',
      'Species',
      'DSH (cm)',
      'Height (m)',
      'Condition',
      'SRZ (m)',
      'NRZ (m)',
      'Latitude',
      'Longitude',
      'Comments',
      'Date Added',
    ];

    // Create CSV rows
    final rows = _trees.map((tree) => [
      tree.id,
      tree.species,
      tree.dsh.toString(),
      tree.height.toString(),
      tree.condition,
      tree.srz.toString(),
      tree.nrz.toString(),
      tree.latitude.toString(),
      tree.longitude.toString(),
      tree.comments ?? '',
      tree.inspectionDate != null 
          ? DateFormat('dd/MM/yyyy HH:mm').format(tree.inspectionDate!)
          : 'Not recorded',
    ]).toList();

    // Combine headers and rows
    final csvData = [headers, ...rows];
    
    // Convert to CSV string
    final csvString = const ListToCsvConverter().convert(csvData);
    
    setState(() {
      _csvData = csvString;
    });
  }

  Future<void> _downloadCsv() async {
    if (_csvData.isEmpty || _csvData == 'No trees found') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No CSV data to download')),
      );
      return;
    }

    try {
      // For web, create a downloadable file
      final bytes = utf8.encode(_csvData);
      await downloadFile(bytes, 'export.file', 'text/csv');
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('CSV downloaded successfully!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error downloading CSV: $e')),
      );
    }
  }

  void _copyCsvToClipboard() {
    if (_csvData.isEmpty || _csvData == 'No trees found') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No CSV data to copy')),
      );
      return;
    }

    // For web, we can't directly copy to clipboard, so show a dialog with the data
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('CSV Data'),
        content: SizedBox(
          width: 600,
          height: 400,
          child: SingleChildScrollView(
            child: SelectableText(_csvData),
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
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('CSV data displayed. You can copy it manually.')),
    );
  }

  Future<void> _saveCsvToFiles() async {
    if (_csvData.isEmpty || _csvData == 'No trees found') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No CSV data to save')),
      );
      return;
    }

    try {
      // Create a CSV file and save it to the site files
      final fileName = '${widget.site.name}_Trees_${DateFormat('yyyyMMdd_HHmm').format(DateTime.now())}.csv';
      final bytes = utf8.encode(_csvData);
      
      // Save to site files using SiteFileService
      await SiteFileService.saveFileFromBytes(
        widget.site.id,
        bytes,
        fileName,
        'csv',
      );
      
      // Refresh the file list
      _loadFiles();
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('CSV saved to site files: $fileName')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error saving CSV to files: $e')),
      );
    }
  }

  Future<void> _uploadFile() async {
    setState(() => _isUploading = true);
    try {
      final file = await SiteFileService.pickAndUploadFile(
        widget.site.id,
        'User', // TODO: Get actual user name
      );
      if (file != null) {
        await _loadFiles();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('File uploaded: ${file.originalName}')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error uploading file: $e')),
      );
    } finally {
      setState(() => _isUploading = false);
    }
  }

  Future<void> _deleteFile(SiteFile file) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete File'),
        content: Text('Are you sure you want to delete "${file.originalName}"? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await SiteFileService.deleteFile(file.id);
        await _loadFiles();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('File deleted: ${file.originalName}')),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error deleting file: $e')),
        );
      }
    }
  }

  void _showFileDetails(SiteFile file) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(file.originalName),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDetailRow('File Type', file.fileType),
              _buildDetailRow('File Size', SiteFileService.formatFileSize(file.fileSize)),
              _buildDetailRow('Upload Date', DateFormat('MMM dd, yyyy HH:mm').format(file.uploadDate)),
              _buildDetailRow('Uploaded By', file.uploadedBy),
              _buildDetailRow('Category', file.category),
              if (file.description.isNotEmpty)
                _buildDetailRow('Description', file.description),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.of(context).pop();
                        SiteFileService.downloadFile(file);
                      },
                      icon: const Icon(Icons.download),
                      label: const Text('Download'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.of(context).pop();
                        SiteFileService.shareFile(file);
                      },
                      icon: const Icon(Icons.share),
                      label: const Text('Share'),
                    ),
                  ),
                ],
              ),
            ],
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

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  IconData _getFileIcon(String fileType) {
    switch (fileType.toLowerCase()) {
      case 'pdf document':
        return Icons.picture_as_pdf;
      case 'word document':
        return Icons.description;
      case 'excel spreadsheet':
        return Icons.table_chart;
      case 'image':
        return Icons.image;
      case 'autocad drawing':
        return Icons.architecture;
      case 'text file':
        return Icons.text_snippet;
      case 'csv file':
        return Icons.table_view;
      default:
        return Icons.insert_drive_file;
    }
  }

  Color _getFileColor(String fileType) {
    switch (fileType.toLowerCase()) {
      case 'pdf document':
        return Colors.red;
      case 'word document':
        return Colors.blue;
      case 'excel spreadsheet':
        return Colors.green;
      case 'image':
        return Colors.purple;
      case 'autocad drawing':
        return Colors.orange;
      case 'text file':
        return Colors.grey;
      case 'csv file':
        return Colors.teal;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Files - ${widget.site.name}'),
        actions: [
          IconButton(
            onPressed: _loadFiles,
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: Column(
        children: [
          // Search and Filter Bar
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              border: Border(bottom: BorderSide(color: Colors.grey.shade300)),
            ),
            child: Column(
              children: [
                // Search Bar
                TextField(
                  decoration: InputDecoration(
                    hintText: 'Search files...',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value;
                      _filterFiles();
                    });
                  },
                ),
                const SizedBox(height: 12),
                // Category Filter
                Row(
                  children: [
                    const Text('Category: ', style: TextStyle(fontWeight: FontWeight.bold)),
                    Expanded(
                      child: DropdownButton<String>(
                        value: _selectedCategory,
                        isExpanded: true,
                        items: ['All', ...SiteFileService.getFileCategories()]
                            .map((category) => DropdownMenuItem(
                                  value: category,
                                  child: Text(category),
                                ))
                            .toList(),
                        onChanged: (value) {
                          setState(() {
                            _selectedCategory = value!;
                            _filterFiles();
                          });
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // CSV Export Section
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              border: Border(bottom: BorderSide(color: Colors.blue.shade200)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.table_chart, color: Colors.blue.shade700),
                    const SizedBox(width: 8),
                    Text(
                      'Live Tree Data CSV Export',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue.shade700,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '${_trees.length} trees',
                      style: TextStyle(
                        color: Colors.blue.shade600,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    ElevatedButton.icon(
                      onPressed: _generateCsvData,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Refresh Data'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue.shade600,
                        foregroundColor: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton.icon(
                      onPressed: _downloadCsv,
                      icon: const Icon(Icons.download),
                      label: const Text('Download CSV'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green.shade600,
                        foregroundColor: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton.icon(
                      onPressed: _saveCsvToFiles,
                      icon: const Icon(Icons.save),
                      label: const Text('Save to Files'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue.shade600,
                        foregroundColor: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton.icon(
                      onPressed: _copyCsvToClipboard,
                      icon: const Icon(Icons.copy),
                      label: const Text('View Data'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange.shade600,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ],
                ),
                if (_csvData.isNotEmpty && _csvData != 'No trees found')
                  Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Row(
                      children: [
                        Icon(Icons.info, color: Colors.blue.shade600, size: 16),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'CSV data ready for export. ${_trees.length} trees included with SRZ/NRZ calculations.',
                            style: TextStyle(
                              color: Colors.blue.shade600,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          // File List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredFiles.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.folder_open,
                              size: 64,
                              color: Colors.grey.shade400,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              _searchQuery.isNotEmpty || _selectedCategory != 'All'
                                  ? 'No files match your search criteria'
                                  : 'No files uploaded yet',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey.shade600,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Tap the upload button to add files',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey.shade500,
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        itemCount: _filteredFiles.length,
                        itemBuilder: (context, index) {
                          final file = _filteredFiles[index];
                          return Card(
                            margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: _getFileColor(file.fileType),
                                child: Icon(
                                  _getFileIcon(file.fileType),
                                  color: Colors.white,
                                ),
                              ),
                              title: Text(
                                file.originalName,
                                style: const TextStyle(fontWeight: FontWeight.w500),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('${file.fileType} • ${SiteFileService.formatFileSize(file.fileSize)}'),
                                  Text(
                                    'Uploaded ${DateFormat('MMM dd, yyyy').format(file.uploadDate)} by ${file.uploadedBy}',
                                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                                  ),
                                  if (file.description.isNotEmpty)
                                    Text(
                                      file.description,
                                      style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                ],
                              ),
                              trailing: PopupMenuButton<String>(
                                onSelected: (value) async {
                                  switch (value) {
                                    case 'download':
                                      await SiteFileService.downloadFile(file);
                                      break;
                                    case 'share':
                                      await SiteFileService.shareFile(file);
                                      break;
                                    case 'edit':
                                      _showEditFileDialog(file);
                                      break;
                                    case 'delete':
                                      await _deleteFile(file);
                                      break;
                                  }
                                },
                                itemBuilder: (context) => [
                                  const PopupMenuItem(
                                    value: 'download',
                                    child: Row(
                                      children: [
                                        Icon(Icons.download),
                                        SizedBox(width: 8),
                                        Text('Download'),
                                      ],
                                    ),
                                  ),
                                  const PopupMenuItem(
                                    value: 'share',
                                    child: Row(
                                      children: [
                                        Icon(Icons.share),
                                        SizedBox(width: 8),
                                        Text('Share'),
                                      ],
                                    ),
                                  ),
                                  const PopupMenuItem(
                                    value: 'edit',
                                    child: Row(
                                      children: [
                                        Icon(Icons.edit),
                                        SizedBox(width: 8),
                                        Text('Edit Details'),
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
                              ),
                              onTap: () => _showFileDetails(file),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _isUploading ? null : _uploadFile,
        icon: _isUploading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
              )
            : const Icon(Icons.upload_file),
        label: Text(_isUploading ? 'Uploading...' : 'Upload File'),
      ),
    );
  }

  void _showEditFileDialog(SiteFile file) {
    final descriptionController = TextEditingController(text: file.description);
    String selectedCategory = file.category;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit File Details'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: descriptionController,
              decoration: const InputDecoration(
                labelText: 'Description',
                hintText: 'Enter file description...',
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: selectedCategory,
              decoration: const InputDecoration(
                labelText: 'Category',
              ),
              items: SiteFileService.getFileCategories()
                  .map((category) => DropdownMenuItem(
                        value: category,
                        child: Text(category),
                      ))
                  .toList(),
              onChanged: (value) {
                selectedCategory = value!;
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                await SiteFileService.updateFileDescription(file.id, descriptionController.text);
                await SiteFileService.updateFileCategory(file.id, selectedCategory);
                await _loadFiles();
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('File details updated')),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Error updating file: $e')),
                );
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}
