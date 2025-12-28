import 'package:flutter/material.dart';
import 'package:ainoval/utils/web_theme.dart';

class AnalyticsCard extends StatelessWidget {
  final String title;
  final String value;
  final double? changeValue;
  final bool? isUpTrend;
  final Widget? child;
  final String? className;

  const AnalyticsCard({
    super.key,
    required this.title,
    required this.value,
    this.changeValue,
    this.isUpTrend,
    this.child,
    this.className,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: WebTheme.getCardColor(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: WebTheme.getBorderColor(context).withOpacity(0.5),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(context),
          const SizedBox(height: 16),
          _buildContent(context),
          if (child != null) ...[
            const SizedBox(height: 16),
            child!,
          ],
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (title.isNotEmpty)
          Flexible(
            child: Text(
              title,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: WebTheme.getSecondaryTextColor(context),
                letterSpacing: 0.5,
              ).copyWith(
                fontFamily: 'Inter',
              ),
            ),
          ),
        if (changeValue != null && isUpTrend != null)
          _buildTrendIndicator(context),
      ],
    );
  }

  Widget _buildTrendIndicator(BuildContext context) {
    final isUp = isUpTrend ?? true;
    final color = isUp ? Colors.green[600] : Colors.red[600];
    final backgroundColor = isUp ? Colors.green[50] : Colors.red[50];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isUp ? Icons.trending_up : Icons.trending_down,
            size: 12,
            color: color,
          ),
          const SizedBox(width: 4),
          Text(
            '${changeValue!.abs().toStringAsFixed(1)}%',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (value.isNotEmpty)
          Text(
            value,
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.w600,
              color: WebTheme.getTextColor(context),
              height: 1.0,
            ).copyWith(
              fontFamily: 'Inter',
            ),
          ),
      ],
    );
  }
}

class AnalyticsOverviewCard extends StatelessWidget {
  final String title;
  final String value;
  final double? changeValue;
  final bool? isUpTrend;
  final IconData icon;
  final String subtitle;

  const AnalyticsOverviewCard({
    super.key,
    required this.title,
    required this.value,
    this.changeValue,
    this.isUpTrend,
    required this.icon,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return AnalyticsCard(
      title: title,
      value: value,
      changeValue: changeValue,
      isUpTrend: isUpTrend,
      child: IntrinsicHeight(
        child: Row(
          children: [
            Icon(
              icon,
              size: 16,
              color: WebTheme.getSecondaryTextColor(context),
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                subtitle,
                style: TextStyle(
                  fontSize: 14,
                  color: WebTheme.getSecondaryTextColor(context),
                ),
                overflow: TextOverflow.ellipsis,
                maxLines: 2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class AnalyticsInsightCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final Color iconColor;
  final Color backgroundColor;

  const AnalyticsInsightCard({
    super.key,
    required this.icon,
    required this.title,
    required this.description,
    required this.iconColor,
    required this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: backgroundColor.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: WebTheme.getBorderColor(context).withOpacity(0.5),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              size: 24,
              color: iconColor,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: WebTheme.getTextColor(context),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            description,
            style: TextStyle(
              fontSize: 14,
              color: WebTheme.getSecondaryTextColor(context),
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}
