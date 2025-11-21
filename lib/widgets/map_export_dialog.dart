import 'package:flutter/material.dart';

enum MapExportType {
  siteOverview,
  treeAtlas,
  treeAtlasWithData,
}

class MapExportDialog extends StatefulWidget {
  @override
  _MapExportDialogState createState() => _MapExportDialogState();
}

class _MapExportDialogState extends State<MapExportDialog> {
  MapExportType _selectedType = MapExportType.siteOverview;
  
  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Select Map Export Type'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Choose how you want to export the site map:',
            style: TextStyle(fontSize: 14, color: Colors.grey[600]),
          ),
          SizedBox(height: 20),
          
          // Site Overview Option
          RadioListTile<MapExportType>(
            value: MapExportType.siteOverview,
            groupValue: _selectedType,
            onChanged: (value) => setState(() => _selectedType = value!),
            title: Text(
              'Site Overview Map',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text(
              'Single map showing all trees on the site',
              style: TextStyle(fontSize: 12),
            ),
            secondary: Icon(Icons.map, color: Colors.green),
          ),
          
          Divider(),
          
          // Tree Atlas Option
          RadioListTile<MapExportType>(
            value: MapExportType.treeAtlas,
            groupValue: _selectedType,
            onChanged: (value) => setState(() => _selectedType = value!),
            title: Text(
              'Tree Atlas (Maps Only)',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text(
              'Individual map for each tree location',
              style: TextStyle(fontSize: 12),
            ),
            secondary: Icon(Icons.collections, color: Colors.blue),
          ),
          
          Divider(),
          
          // Tree Atlas with Data Option
          RadioListTile<MapExportType>(
            value: MapExportType.treeAtlasWithData,
            groupValue: _selectedType,
            onChanged: (value) => setState(() => _selectedType = value!),
            title: Text(
              'Tree Atlas with Data',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text(
              'Individual maps with tree data and photos',
              style: TextStyle(fontSize: 12),
            ),
            secondary: Icon(Icons.dashboard, color: Colors.orange),
          ),
          
          SizedBox(height: 20),
          
          // Preview section
          Container(
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'What you\'ll get:',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
                SizedBox(height: 8),
                ..._getDescriptionForType(_selectedType).map(
                  (item) => Padding(
                    padding: EdgeInsets.only(left: 8, top: 4),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('• ', style: TextStyle(fontSize: 12)),
                        Expanded(
                          child: Text(
                            item,
                            style: TextStyle(fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(null),
          child: Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () => Navigator.of(context).pop(_selectedType),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green,
          ),
          child: Text('Generate'),
        ),
      ],
    );
  }
  
  List<String> _getDescriptionForType(MapExportType type) {
    switch (type) {
      case MapExportType.siteOverview:
        return [
          'One comprehensive site map',
          'All trees marked with ID numbers',
          'Color-coded by condition',
          'Protection zones visible',
          'Scale bar and north arrow',
        ];
      case MapExportType.treeAtlas:
        return [
          'Individual map page per tree',
          'Focused view of tree location',
          'Tree ID and species shown',
          'Page numbering (1 of N)',
          'Professional atlas layout',
        ];
      case MapExportType.treeAtlasWithData:
        return [
          'Individual map page per tree',
          'Complete tree assessment data',
          'Space for 4 tree photos',
          'All measurements and ratings',
          'Comprehensive documentation',
        ];
    }
  }
}
