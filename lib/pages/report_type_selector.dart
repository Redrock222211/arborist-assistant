import 'package:flutter/material.dart';
import '../models/report_type.dart';
import '../models/site.dart';
import '../widgets/report_specific_tree_form.dart';

class ReportTypeSelector extends StatelessWidget {
  final Site site;
  
  const ReportTypeSelector({Key? key, required this.site}) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Select Report Type'),
        backgroundColor: Colors.green,
      ),
      body: ListView(
        padding: EdgeInsets.all(16),
        children: [
          Text(
            'Choose the type of report you want to create:',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 16),
          
          // Report type cards
          _buildReportCard(
            context,
            ReportType.paa,
            Icons.nature,
            Colors.green,
          ),
          
          _buildReportCard(
            context,
            ReportType.aia,
            Icons.construction,
            Colors.orange,
          ),
          
          _buildReportCard(
            context,
            ReportType.tra,
            Icons.warning,
            Colors.red,
          ),
          
          _buildReportCard(
            context,
            ReportType.tpmp,
            Icons.shield,
            Colors.blue,
          ),
          
          _buildReportCard(
            context,
            ReportType.removal,
            Icons.cancel,
            Colors.deepOrange,
          ),
          
          _buildReportCard(
            context,
            ReportType.witness,
            Icons.gavel,
            Colors.purple,
          ),
          
          _buildReportCard(
            context,
            ReportType.condition,
            Icons.healing,
            Colors.teal,
          ),
          
          _buildReportCard(
            context,
            ReportType.postDev,
            Icons.timeline,
            Colors.indigo,
          ),
          
          _buildReportCard(
            context,
            ReportType.vegetation,
            Icons.eco,
            Colors.lightGreen,
          ),
        ],
      ),
    );
  }
  
  Widget _buildReportCard(
    BuildContext context,
    ReportType reportType,
    IconData icon,
    Color color,
  ) {
    return Card(
      margin: EdgeInsets.only(bottom: 12),
      elevation: 2,
      child: InkWell(
        onTap: () {
          // Navigate to the specific form for this report type
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ReportSpecificTreeForm(
                siteId: site.id,
                reportType: reportType,
                onSubmit: (tree) {
                  // Tree saved, navigate back
                  Navigator.pop(context);
                },
              ),
            ),
          );
        },
        borderRadius: BorderRadius.circular(4),
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 32),
              ),
              SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      reportType.code,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: color,
                      ),
                    ),
                    Text(
                      reportType.title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      reportType.description,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                    SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: [
                        _buildFeatureChip('AS4970 Compliant'),
                        if (reportType == ReportType.tra)
                          _buildFeatureChip('Risk Matrix'),
                        if (reportType == ReportType.aia)
                          _buildFeatureChip('Impact Analysis'),
                        if (reportType == ReportType.tpmp)
                          _buildFeatureChip('Protection Zones'),
                      ],
                    ),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildFeatureChip(String label) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 10, color: Colors.grey[700]),
      ),
    );
  }
}
