# Collapsible Form Groups with Export Control

## Visual Design

Each section has:
1. **Checkbox** - Enable/disable the section (controls visibility AND export)
2. **Icon & Title** - Visual identification
3. **Export Badge** - Shows if section will be exported (green) or hidden (grey)
4. **Expand/Collapse Arrow** - Toggle content visibility

```
┌─────────────────────────────────────────────────────────┐
│ ☑ 📷 Photos & Images              [✓ Export]      ▼    │
├─────────────────────────────────────────────────────────┤
│   [Photo Grid]                                          │
│   [Take Photo] [Pick Photos]                            │
└─────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────┐
│ ☐ 🎤 Voice Notes                  [✗ Hidden]           │
└─────────────────────────────────────────────────────────┘
```

## How to Use in tree_form.dart

### Step 1: Add state variables for each group

```dart
class _TreeFormState extends State<TreeForm> {
  // Export group states (from TreeEntry.exportGroups)
  Map<String, bool> _exportGroups = {
    'photos': true,
    'voice_notes': true,
    'location': true,
    'basic_info': true,
    'assessment': true,
    'vta_risk': true,
    'additional': true,
  };
  
  // Expansion states (UI only, not saved)
  Map<String, bool> _expandedGroups = {
    'photos': true,
    'voice_notes': false,
    'location': true,
    'basic_info': true,
    'assessment': false,
    'vta_risk': false,
    'additional': false,
  };
  
  @override
  void initState() {
    super.initState();
    if (widget.initialEntry != null) {
      _exportGroups = Map.from(widget.initialEntry!.exportGroups);
    }
  }
}
```

### Step 2: Replace Card widgets with CollapsibleFormSection

**Before (old Card):**
```dart
Card(
  child: Padding(
    padding: const EdgeInsets.all(16),
    child: Column(
      children: [
        Text('Photos'),
        // ... photo widgets
      ],
    ),
  ),
),
```

**After (new CollapsibleFormSection):**
```dart
CollapsibleFormSection(
  title: 'Photos & Images',
  subtitle: 'Tree documentation photos',
  icon: Icons.camera_alt,
  iconColor: Colors.green,
  isEnabled: _exportGroups['photos']!,
  isExpanded: _expandedGroups['photos']!,
  onEnabledChanged: (value) {
    setState(() {
      _exportGroups['photos'] = value ?? false;
    });
  },
  onToggleExpanded: () {
    setState(() {
      _expandedGroups['photos'] = !_expandedGroups['photos']!;
    });
  },
  children: [
    // Photo grid
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
          // ... photo item
        },
      ),
    const SizedBox(height: 12),
    Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: _takePhoto,
            icon: const Icon(Icons.camera_alt),
            label: const Text('Take Photo'),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: _pickPhotos,
            icon: const Icon(Icons.photo_library),
            label: const Text('Pick Photos'),
          ),
        ),
      ],
    ),
  ],
),
```

### Step 3: Update all sections

Replace each Card with CollapsibleFormSection:

1. **Photos** - `'photos'` key
2. **Voice Notes** - `'voice_notes'` key
3. **GPS Location** - `'location'` key
4. **Basic Tree Information** - `'basic_info'` key
5. **Tree Assessment & Health** - `'assessment'` key
6. **VTA & Risk Assessment** - `'vta_risk'` key
7. **Additional Information** - `'additional'` key

### Step 4: Save exportGroups when saving tree

```dart
Future<void> _saveTree() async {
  if (!_formKey.currentState!.validate()) return;

  try {
    final tree = TreeEntry(
      id: widget.initialEntry?.id ?? TreeStorageService.getNextTreeId(widget.siteId),
      species: _speciesController.text,
      // ... all other fields ...
      exportGroups: _exportGroups,  // ← Add this line
    );

    widget.onSubmit(tree);
    NotificationService.showSuccess(context, 'Tree saved successfully!');
  } catch (e) {
    NotificationService.showError(context, 'Failed to save tree: $e');
  }
}
```

### Step 5: Use exportGroups in PDF/CSV export

In your export services, filter data based on exportGroups:

```dart
// In pdf_export_service.dart or csv_export_service.dart

Future<void> exportTree(TreeEntry tree) async {
  // Only include sections that are enabled
  
  if (tree.exportGroups['photos'] == true) {
    // Add photos to export
  }
  
  if (tree.exportGroups['basic_info'] == true) {
    // Add basic info to export
  }
  
  if (tree.exportGroups['vta_risk'] == true) {
    // Add VTA/risk data to export
  }
  
  // etc...
}
```

## Complete Example for One Section

```dart
// In tree_form.dart build method:

ListView(
  padding: const EdgeInsets.all(16),
  children: [
    // Photos Section
    CollapsibleFormSection(
      title: 'Photos & Images',
      subtitle: '${_photoPaths.length} photos',
      icon: Icons.camera_alt,
      iconColor: Colors.green,
      isEnabled: _exportGroups['photos']!,
      isExpanded: _expandedGroups['photos']!,
      onEnabledChanged: (value) {
        setState(() => _exportGroups['photos'] = value ?? false);
      },
      onToggleExpanded: () {
        setState(() => _expandedGroups['photos'] = !_expandedGroups['photos']!);
      },
      children: [
        // Your existing photo widgets here
      ],
    ),
    
    // Voice Notes Section
    CollapsibleFormSection(
      title: 'Voice Notes',
      subtitle: '${_voiceNotePaths.length} recordings',
      icon: Icons.mic,
      iconColor: Colors.purple,
      isEnabled: _exportGroups['voice_notes']!,
      isExpanded: _expandedGroups['voice_notes']!,
      onEnabledChanged: (value) {
        setState(() => _exportGroups['voice_notes'] = value ?? false);
      },
      onToggleExpanded: () {
        setState(() => _expandedGroups['voice_notes'] = !_expandedGroups['voice_notes']!);
      },
      children: [
        // Your existing voice note widgets here
      ],
    ),
    
    // ... repeat for all sections
  ],
)
```

## Benefits

✅ **Clean UI** - Collapsed sections reduce scrolling  
✅ **Export Control** - Uncheck to exclude from reports  
✅ **Visual Feedback** - Green "Export" badge shows what's included  
✅ **Flexible** - Show/hide sections based on workflow  
✅ **Professional** - Clients only see relevant data  
✅ **Privacy** - Exclude sensitive sections easily  

## User Workflow

1. **Fill in tree data** - All sections visible by default
2. **Uncheck sections** - Hide sections not needed for this tree
3. **Collapse sections** - Reduce scrolling while keeping data
4. **Export** - Only checked sections appear in PDF/CSV
5. **Different exports** - Toggle sections for different clients

Example: 
- Council report: ✓ Basic Info, ✓ VTA Risk, ✗ Photos, ✗ Financial
- Client quote: ✓ Photos, ✓ Management, ✓ Basic Info, ✗ VTA Risk
- Insurance claim: ✓ Photos, ✓ VTA Risk, ✓ Assessment, ✗ Voice Notes
