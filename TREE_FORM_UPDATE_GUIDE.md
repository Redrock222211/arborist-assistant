# Tree Form Full Update - Implementation Guide

## 🎯 WHAT WE'RE DOING

Replacing the current Card-based UI with 20 collapsible groups using TreeFormGroups helper.

## 📋 IMPLEMENTATION STEPS

### Step 1: Add Content Builder Methods (Before build method)

Add these 20 methods before the `@override Widget build(BuildContext context)` line:

```dart
// ========== CONTENT BUILDERS FOR 20 GROUPS ==========

List<Widget> _buildPhotosContent() {
  return [
    if (_isUploadingPhotos)
      Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: LinearProgressIndicator(value: _uploadProgress / 100),
      ),
    if (_photoPaths.isNotEmpty)
      GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          crossAxisSpacing: 8,
          mainAxisSpacing: 8,
        ),
        itemCount: _photoPaths.length,
        itemBuilder: (context, index) {
          return Stack(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: _buildWebCompatibleImage(_photoPaths[index]),
              ),
              Positioned(
                top: 4,
                right: 4,
                child: GestureDetector(
                  onTap: () => setState(() => _photoPaths.removeAt(index)),
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.close, color: Colors.white, size: 16),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    if (_photoPaths.isNotEmpty) const SizedBox(height: 12),
    Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: _takePhoto,
            icon: const Icon(Icons.camera_alt),
            label: const Text('Take Photo'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green.shade100,
              foregroundColor: Colors.green.shade800,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: _pickPhotos,
            icon: const Icon(Icons.photo_library),
            label: const Text('Pick Photos'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue.shade100,
              foregroundColor: Colors.blue.shade800,
            ),
          ),
        ),
      ],
    ),
  ];
}

List<Widget> _buildVoiceNotesContent() {
  return [
    if (_voiceNotePaths.isNotEmpty)
      ...(_voiceNotePaths.asMap().entries.map((entry) {
        final index = entry.key;
        final path = entry.value;
        return ListTile(
          leading: const Icon(Icons.play_circle, color: Colors.purple),
          title: Text('Voice Note ${index + 1}'),
          subtitle: const Text('Tap to play'),
          trailing: IconButton(
            icon: const Icon(Icons.delete, color: Colors.red),
            onPressed: () => setState(() => _voiceNotePaths.removeAt(index)),
          ),
          onTap: () => _playVoiceNote(path),
        );
      })),
    if (_voiceNotePaths.isNotEmpty) const SizedBox(height: 12),
    ElevatedButton.icon(
      onPressed: _isRecording ? _stopRecording : _startRecording,
      icon: Icon(_isRecording ? Icons.stop : Icons.mic),
      label: Text(_isRecording ? 'Stop Recording' : 'Start Recording'),
      style: ElevatedButton.styleFrom(
        backgroundColor: _isRecording ? Colors.red.shade100 : Colors.purple.shade100,
        foregroundColor: _isRecording ? Colors.red.shade800 : Colors.purple.shade800,
      ),
    ),
  ];
}

List<Widget> _buildLocationContent() {
  return [
    if (_latitude != 0 && _longitude != 0) ...[
      Text('Latitude: ${_latitude.toStringAsFixed(6)}'),
      Text('Longitude: ${_longitude.toStringAsFixed(6)}'),
      const SizedBox(height: 8),
    ],
    ElevatedButton.icon(
      onPressed: _isLoadingLocation ? null : _getCurrentLocation,
      icon: const Icon(Icons.my_location),
      label: const Text('Get Current Location'),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.red.shade100,
        foregroundColor: Colors.red.shade800,
      ),
    ),
    const SizedBox(height: 16),
    Text('Site Context', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
    const SizedBox(height: 12),
    // Phase 1 fields will be added here
    Text('Additional site context fields coming soon', style: TextStyle(color: Colors.grey)),
  ];
}

// Continue for all 20 groups...
```

### Step 2: Replace ListView children in build method

Find this code (around line 850):
```dart
child: ListView(
  padding: const EdgeInsets.all(16),
  children: [
    // All the Card widgets...
```

Replace with:
```dart
child: ListView(
  padding: const EdgeInsets.all(16),
  children: TreeFormGroups.buildAllGroups(
    exportGroups: _exportGroups,
    expandedGroups: _expandedGroups,
    onGroupToggle: (key, value) {
      setState(() => _exportGroups[key] = value);
    },
    onExpandToggle: (key) {
      setState(() => _expandedGroups[key] = !_expandedGroups[key]!);
    },
    groupContent: {
      'photos': _buildPhotosContent(),
      'voice_notes': _buildVoiceNotesContent(),
      'location': _buildLocationContent(),
      'basic_data': _buildBasicDataContent(),
      'health': _buildHealthContent(),
      'structure': _buildStructureContent(),
      'vta': _buildVTAContent(),
      'qtra': _buildQTRAContent(),
      'isa_risk': _buildISARiskContent(),
      'protection_zones': _buildProtectionZonesContent(),
      'impact_assessment': _buildPlaceholder('Tree Impact Assessment'),
      'development': _buildPlaceholder('Development Compliance'),
      'retention_removal': _buildPlaceholder('Retention & Removal'),
      'management': _buildPlaceholder('Management & Works'),
      'valuation': _buildPlaceholder('Tree Valuation'),
      'ecological': _buildPlaceholder('Ecological Value'),
      'regulatory': _buildPlaceholder('Regulatory & Compliance'),
      'monitoring': _buildPlaceholder('Monitoring & Scheduling'),
      'diagnostics': _buildPlaceholder('Advanced Diagnostics'),
      'inspector_details': _buildInspectorContent(),
    },
  ),
),
```

## ⚡ QUICK IMPLEMENTATION

Due to the large file size (1600+ lines), I'll create a new tree_form.dart file with all the changes.

This will take about 10-15 minutes to complete properly.

**Ready to proceed?**
