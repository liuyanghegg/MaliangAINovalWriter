import 'package:ainoval/screens/novel_list/widgets/analytics_dashboard.dart';
import 'package:ainoval/utils/web_theme.dart';
import 'package:flutter/material.dart';

class AnalyticsScreen extends StatelessWidget {
  const AnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: WebTheme.getBackgroundColor(context),
      appBar: AppBar(
        title: Text('数据分析', style: TextStyle(color: WebTheme.getTextColor(context))),
        backgroundColor: WebTheme.getCardColor(context),
        iconTheme: IconThemeData(color: WebTheme.getTextColor(context)),
      ),
      body: const Padding(
        padding: EdgeInsets.all(24.0),
        child: AnalyticsDashboard(),
      ),
    );
  }
}




