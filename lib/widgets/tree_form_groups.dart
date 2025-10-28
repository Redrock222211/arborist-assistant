import 'package:flutter/material.dart';
import 'collapsible_form_section.dart';

/// Helper class to build all 20 tree form groups
class TreeFormGroups {
  
  /// Build all 20 collapsible form sections
  static List<Widget> buildAllGroups({
    required Map<String, bool> exportGroups,
    required Map<String, bool> expandedGroups,
    required Function(String, bool) onGroupToggle,
    required Function(String) onExpandToggle,
    required Map<String, List<Widget>> groupContent,
  }) {
    return [
      // GROUP 1: Photos & Documentation
      CollapsibleFormSection(
        title: 'Photos & Documentation',
        subtitle: groupContent['photos']?.isEmpty ?? true ? 'No photos' : '${groupContent['photos']?.length ?? 0} items',
        icon: Icons.camera_alt,
        iconColor: Colors.green,
        isEnabled: exportGroups['photos'] ?? true,
        isExpanded: expandedGroups['photos'] ?? true,
        onEnabledChanged: (value) => onGroupToggle('photos', value ?? false),
        onToggleExpanded: () => onExpandToggle('photos'),
        children: groupContent['photos'] ?? [Text('Add photos here')],
      ),
      
      // GROUP 2: Voice Notes & Audio
      CollapsibleFormSection(
        title: 'Voice Notes & Audio',
        subtitle: 'Field recordings and observations',
        icon: Icons.mic,
        iconColor: Colors.purple,
        isEnabled: exportGroups['voice_notes'] ?? true,
        isExpanded: expandedGroups['voice_notes'] ?? false,
        onEnabledChanged: (value) => onGroupToggle('voice_notes', value ?? false),
        onToggleExpanded: () => onExpandToggle('voice_notes'),
        children: groupContent['voice_notes'] ?? [Text('Add voice notes here')],
      ),
      
      // GROUP 3: Location & Site Context
      CollapsibleFormSection(
        title: 'Location & Site Context',
        subtitle: 'GPS, soil, drainage, site conditions',
        icon: Icons.location_on,
        iconColor: Colors.red,
        isEnabled: exportGroups['location'] ?? true,
        isExpanded: expandedGroups['location'] ?? true,
        onEnabledChanged: (value) => onGroupToggle('location', value ?? false),
        onToggleExpanded: () => onExpandToggle('location'),
        children: groupContent['location'] ?? [Text('Add location data here')],
      ),
      
      // GROUP 4: Basic Tree Data
      CollapsibleFormSection(
        title: 'Basic Tree Data',
        subtitle: 'Species, DBH, height, age, crown',
        icon: Icons.park,
        iconColor: Colors.green.shade700,
        isEnabled: exportGroups['basic_data'] ?? true,
        isExpanded: expandedGroups['basic_data'] ?? true,
        onEnabledChanged: (value) => onGroupToggle('basic_data', value ?? false),
        onToggleExpanded: () => onExpandToggle('basic_data'),
        children: groupContent['basic_data'] ?? [Text('Add basic tree data here')],
      ),
      
      // GROUP 5: Tree Health Assessment
      CollapsibleFormSection(
        title: 'Tree Health Assessment',
        subtitle: 'Vigor, diseases, pests, decline indicators',
        icon: Icons.health_and_safety,
        iconColor: Colors.blue,
        isEnabled: exportGroups['health'] ?? true,
        isExpanded: expandedGroups['health'] ?? false,
        onEnabledChanged: (value) => onGroupToggle('health', value ?? false),
        onToggleExpanded: () => onExpandToggle('health'),
        children: groupContent['health'] ?? [Text('Add health assessment here')],
      ),
      
      // GROUP 6: Tree Structure
      CollapsibleFormSection(
        title: 'Tree Structure',
        subtitle: 'Crown, trunk, branches, root plate',
        icon: Icons.account_tree,
        iconColor: Colors.brown,
        isEnabled: exportGroups['structure'] ?? true,
        isExpanded: expandedGroups['structure'] ?? false,
        onEnabledChanged: (value) => onGroupToggle('structure', value ?? false),
        onToggleExpanded: () => onExpandToggle('structure'),
        children: groupContent['structure'] ?? [Text('Add structure assessment here')],
      ),
      
      // GROUP 7: VTA (Visual Tree Assessment)
      CollapsibleFormSection(
        title: 'VTA (Visual Tree Assessment)',
        subtitle: 'Defects, decay, cavities, cracks, fungi',
        icon: Icons.warning_amber,
        iconColor: Colors.orange,
        isEnabled: exportGroups['vta'] ?? true,
        isExpanded: expandedGroups['vta'] ?? false,
        onEnabledChanged: (value) => onGroupToggle('vta', value ?? false),
        onToggleExpanded: () => onExpandToggle('vta'),
        children: groupContent['vta'] ?? [Text('Add VTA assessment here')],
      ),
      
      // GROUP 8: QTRA (Quantified Risk)
      CollapsibleFormSection(
        title: 'QTRA (Quantified Tree Risk)',
        subtitle: 'Target, probability, risk calculation',
        icon: Icons.calculate,
        iconColor: Colors.deepOrange,
        isEnabled: exportGroups['qtra'] ?? true,
        isExpanded: expandedGroups['qtra'] ?? false,
        onEnabledChanged: (value) => onGroupToggle('qtra', value ?? false),
        onToggleExpanded: () => onExpandToggle('qtra'),
        children: groupContent['qtra'] ?? [Text('Add QTRA assessment here')],
      ),
      
      // GROUP 9: ISA Risk Assessment
      CollapsibleFormSection(
        title: 'ISA Risk Assessment',
        subtitle: 'Failure likelihood, impact, consequence',
        icon: Icons.shield,
        iconColor: Colors.red.shade700,
        isEnabled: exportGroups['isa_risk'] ?? true,
        isExpanded: expandedGroups['isa_risk'] ?? false,
        onEnabledChanged: (value) => onGroupToggle('isa_risk', value ?? false),
        onToggleExpanded: () => onExpandToggle('isa_risk'),
        children: groupContent['isa_risk'] ?? [Text('Add ISA risk assessment here')],
      ),
      
      // GROUP 10: Protection Zones
      CollapsibleFormSection(
        title: 'Protection Zones',
        subtitle: 'SRZ, TPZ/NRZ, encroachment',
        icon: Icons.security,
        iconColor: Colors.teal,
        isEnabled: exportGroups['protection_zones'] ?? true,
        isExpanded: expandedGroups['protection_zones'] ?? false,
        onEnabledChanged: (value) => onGroupToggle('protection_zones', value ?? false),
        onToggleExpanded: () => onExpandToggle('protection_zones'),
        children: groupContent['protection_zones'] ?? [Text('Add protection zones here')],
      ),
      
      // GROUP 11: Tree Impact Assessment
      CollapsibleFormSection(
        title: 'Tree Impact Assessment (TIA)',
        subtitle: 'Construction impacts, encroachment',
        icon: Icons.construction,
        iconColor: Colors.amber.shade800,
        isEnabled: exportGroups['impact_assessment'] ?? true,
        isExpanded: expandedGroups['impact_assessment'] ?? false,
        onEnabledChanged: (value) => onGroupToggle('impact_assessment', value ?? false),
        onToggleExpanded: () => onExpandToggle('impact_assessment'),
        children: groupContent['impact_assessment'] ?? [Text('Add impact assessment here')],
      ),
      
      // GROUP 12: Development Compliance
      CollapsibleFormSection(
        title: 'Development Compliance',
        subtitle: 'Permits, planning overlays, AS4970',
        icon: Icons.gavel,
        iconColor: Colors.indigo,
        isEnabled: exportGroups['development'] ?? true,
        isExpanded: expandedGroups['development'] ?? false,
        onEnabledChanged: (value) => onGroupToggle('development', value ?? false),
        onToggleExpanded: () => onExpandToggle('development'),
        children: groupContent['development'] ?? [Text('Add development compliance here')],
      ),
      
      // GROUP 13: Retention & Removal
      CollapsibleFormSection(
        title: 'Retention & Removal',
        subtitle: 'Retention value, removal justification',
        icon: Icons.rule,
        iconColor: Colors.deepPurple,
        isEnabled: exportGroups['retention_removal'] ?? true,
        isExpanded: expandedGroups['retention_removal'] ?? false,
        onEnabledChanged: (value) => onGroupToggle('retention_removal', value ?? false),
        onToggleExpanded: () => onExpandToggle('retention_removal'),
        children: groupContent['retention_removal'] ?? [Text('Add retention/removal assessment here')],
      ),
      
      // GROUP 14: Management & Works
      CollapsibleFormSection(
        title: 'Management & Works',
        subtitle: 'Pruning specs, costs, timeframes',
        icon: Icons.build,
        iconColor: Colors.blueGrey,
        isEnabled: exportGroups['management'] ?? true,
        isExpanded: expandedGroups['management'] ?? false,
        onEnabledChanged: (value) => onGroupToggle('management', value ?? false),
        onToggleExpanded: () => onExpandToggle('management'),
        children: groupContent['management'] ?? [Text('Add management & works here')],
      ),
      
      // GROUP 15: Tree Valuation
      CollapsibleFormSection(
        title: 'Tree Valuation',
        subtitle: 'CTLA, Helliwell, Burnley methods',
        icon: Icons.attach_money,
        iconColor: Colors.green.shade800,
        isEnabled: exportGroups['valuation'] ?? false,
        isExpanded: expandedGroups['valuation'] ?? false,
        onEnabledChanged: (value) => onGroupToggle('valuation', value ?? false),
        onToggleExpanded: () => onExpandToggle('valuation'),
        children: groupContent['valuation'] ?? [Text('Add tree valuation here')],
      ),
      
      // GROUP 16: Ecological Value
      CollapsibleFormSection(
        title: 'Ecological Value',
        subtitle: 'Habitat, biodiversity, indigenous significance',
        icon: Icons.eco,
        iconColor: Colors.lightGreen,
        isEnabled: exportGroups['ecological'] ?? true,
        isExpanded: expandedGroups['ecological'] ?? false,
        onEnabledChanged: (value) => onGroupToggle('ecological', value ?? false),
        onToggleExpanded: () => onExpandToggle('ecological'),
        children: groupContent['ecological'] ?? [Text('Add ecological value here')],
      ),
      
      // GROUP 17: Regulatory & Compliance
      CollapsibleFormSection(
        title: 'Regulatory & Compliance',
        subtitle: 'Heritage, legal, insurance requirements',
        icon: Icons.policy,
        iconColor: Colors.red.shade900,
        isEnabled: exportGroups['regulatory'] ?? true,
        isExpanded: expandedGroups['regulatory'] ?? false,
        onEnabledChanged: (value) => onGroupToggle('regulatory', value ?? false),
        onToggleExpanded: () => onExpandToggle('regulatory'),
        children: groupContent['regulatory'] ?? [Text('Add regulatory compliance here')],
      ),
      
      // GROUP 18: Monitoring & Scheduling
      CollapsibleFormSection(
        title: 'Monitoring & Scheduling',
        subtitle: 'Inspections, follow-ups, alerts',
        icon: Icons.schedule,
        iconColor: Colors.cyan,
        isEnabled: exportGroups['monitoring'] ?? true,
        isExpanded: expandedGroups['monitoring'] ?? false,
        onEnabledChanged: (value) => onGroupToggle('monitoring', value ?? false),
        onToggleExpanded: () => onExpandToggle('monitoring'),
        children: groupContent['monitoring'] ?? [Text('Add monitoring schedule here')],
      ),
      
      // GROUP 19: Advanced Diagnostics
      CollapsibleFormSection(
        title: 'Advanced Diagnostics',
        subtitle: 'Resistograph, tomography, specialist testing',
        icon: Icons.science,
        iconColor: Colors.purple.shade700,
        isEnabled: exportGroups['diagnostics'] ?? false,
        isExpanded: expandedGroups['diagnostics'] ?? false,
        onEnabledChanged: (value) => onGroupToggle('diagnostics', value ?? false),
        onToggleExpanded: () => onExpandToggle('diagnostics'),
        children: groupContent['diagnostics'] ?? [Text('Add advanced diagnostics here')],
      ),
      
      // GROUP 20: Inspector & Report Details
      CollapsibleFormSection(
        title: 'Inspector & Report Details',
        subtitle: 'Inspector info, report metadata',
        icon: Icons.person,
        iconColor: Colors.blueGrey.shade700,
        isEnabled: exportGroups['inspector_details'] ?? true,
        isExpanded: expandedGroups['inspector_details'] ?? false,
        onEnabledChanged: (value) => onGroupToggle('inspector_details', value ?? false),
        onToggleExpanded: () => onExpandToggle('inspector_details'),
        children: groupContent['inspector_details'] ?? [Text('Add inspector details here')],
      ),
    ];
  }
}
