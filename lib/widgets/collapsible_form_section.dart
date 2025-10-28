import 'package:flutter/material.dart';

/// A collapsible form section with a checkbox to control visibility and export
class CollapsibleFormSection extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color iconColor;
  final bool isEnabled;
  final bool isExpanded;
  final Function(bool?) onEnabledChanged;
  final VoidCallback onToggleExpanded;
  final List<Widget> children;
  final String? subtitle;

  const CollapsibleFormSection({
    Key? key,
    required this.title,
    required this.icon,
    required this.iconColor,
    required this.isEnabled,
    required this.isExpanded,
    required this.onEnabledChanged,
    required this.onToggleExpanded,
    required this.children,
    this.subtitle,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: isEnabled ? 2 : 1,
      child: Column(
        children: [
          // Header with checkbox and expand/collapse
          Material(
            color: isEnabled ? Colors.white : Colors.grey.shade100,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
            child: InkWell(
              onTap: isEnabled ? onToggleExpanded : null,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: Row(
                  children: [
                    // Checkbox to enable/disable section
                    Checkbox(
                      value: isEnabled,
                      onChanged: onEnabledChanged,
                      activeColor: iconColor,
                    ),
                    
                    // Icon
                    Icon(
                      icon,
                      color: isEnabled ? iconColor : Colors.grey,
                      size: 24,
                    ),
                    const SizedBox(width: 12),
                    
                    // Title and subtitle
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: isEnabled ? Colors.black87 : Colors.grey,
                            ),
                          ),
                          if (subtitle != null)
                            Text(
                              subtitle!,
                              style: TextStyle(
                                fontSize: 12,
                                color: isEnabled ? Colors.grey.shade600 : Colors.grey.shade400,
                              ),
                            ),
                        ],
                      ),
                    ),
                    
                    // Export indicator
                    if (isEnabled)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.green.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.green.shade300),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.check_circle, size: 14, color: Colors.green.shade700),
                            const SizedBox(width: 4),
                            Text(
                              'Export',
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.green.shade700,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    if (!isEnabled)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.cancel, size: 14, color: Colors.grey.shade600),
                            const SizedBox(width: 4),
                            Text(
                              'Hidden',
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    
                    const SizedBox(width: 8),
                    
                    // Expand/collapse arrow
                    if (isEnabled)
                      Icon(
                        isExpanded ? Icons.expand_less : Icons.expand_more,
                        color: Colors.grey.shade600,
                      ),
                  ],
                ),
              ),
            ),
          ),
          
          // Collapsible content
          if (isEnabled && isExpanded)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: children,
              ),
            ),
        ],
      ),
    );
  }
}
