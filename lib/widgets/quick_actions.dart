import 'package:flutter/material.dart';
import '../models/site.dart';

class QuickActions extends StatelessWidget {
  final Site site;
  final VoidCallback onAddTree;
  final VoidCallback onViewMap;
  final VoidCallback onExportData;
  final VoidCallback onViewFiles;

  const QuickActions({
    super.key,
    required this.site,
    required this.onAddTree,
    required this.onViewMap,
    required this.onExportData,
    required this.onViewFiles,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.flash_on, color: Colors.orange.shade600),
                const SizedBox(width: 8),
                Text(
                  'Quick Actions',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                _buildQuickActionButton(
                  context,
                  icon: Icons.add_location_alt,
                  label: 'Add Tree',
                  color: Colors.green,
                  onTap: onAddTree,
                ),
                _buildQuickActionButton(
                  context,
                  icon: Icons.map,
                  label: 'View Map',
                  color: Colors.blue,
                  onTap: onViewMap,
                ),
                _buildQuickActionButton(
                  context,
                  icon: Icons.folder,
                  label: 'Files',
                  color: Colors.purple,
                  onTap: onViewFiles,
                ),
                _buildQuickActionButton(
                  context,
                  icon: Icons.download,
                  label: 'Export',
                  color: Colors.orange,
                  onTap: onExportData,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActionButton(
    BuildContext context, {
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 80,
        height: 80,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
