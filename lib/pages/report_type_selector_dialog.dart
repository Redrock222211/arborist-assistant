import 'package:flutter/material.dart';
import '../models/report_type.dart';

class ReportTypeSelectorDialog extends StatelessWidget {
  const ReportTypeSelectorDialog({super.key});

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final maxDialogHeight = screenHeight * 0.85; // Use 85% of screen height
    
    return Dialog(
      child: Container(
        constraints: BoxConstraints(maxWidth: 600, maxHeight: maxDialogHeight),
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.green.shade700,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(4),
                  topRight: Radius.circular(4),
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.assignment, color: Colors.white, size: 28),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Select Report Purpose',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Choose the type of assessment you\'re conducting',
                          style: TextStyle(color: Colors.white70, fontSize: 12),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 2,
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
            
            // Report type list
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: ReportType.values.length,
                itemBuilder: (context, index) {
                  final reportType = ReportType.values[index];
                  return _buildReportTypeCard(context, reportType);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReportTypeCard(BuildContext context, ReportType reportType) {
    IconData icon;
    Color color;
    
    switch (reportType) {
      case ReportType.paa:
        icon = Icons.search;
        color = Colors.blue;
        break;
      case ReportType.aia:
        icon = Icons.construction;
        color = Colors.orange;
        break;
      case ReportType.tpmp:
        icon = Icons.shield;
        color = Colors.green;
        break;
      case ReportType.tra:
        icon = Icons.warning;
        color = Colors.red;
        break;
      case ReportType.condition:
        icon = Icons.health_and_safety;
        color = Colors.teal;
        break;
      case ReportType.removal:
        icon = Icons.delete_forever;
        color = Colors.deepOrange;
        break;
      case ReportType.witness:
        icon = Icons.gavel;
        color = Colors.purple;
        break;
      case ReportType.postDev:
        icon = Icons.update;
        color = Colors.indigo;
        break;
      case ReportType.vegetation:
        icon = Icons.nature;
        color = Colors.lightGreen;
        break;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => Navigator.of(context).pop(reportType),
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Icon
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 28),
              ),
              const SizedBox(width: 16),
              
              // Text
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: color.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            reportType.code,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: color,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            reportType.title,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      reportType.description,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                        height: 1.3,
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 2,
                    ),
                  ],
                ),
              ),
              
              // Arrow
              Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey[400]),
            ],
          ),
        ),
      ),
    );
  }
}
