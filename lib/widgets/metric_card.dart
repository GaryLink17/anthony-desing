import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../theme/theme_helper.dart';

/// Widget reutilizable para mostrar métricas en el dashboard
class MetricCard extends StatelessWidget {
  final IconData icon;
  final Color iconBg;
  final Color iconColor;
  final String value;
  final String label;
  final String delta;
  final bool deltaPositive;

  const MetricCard({
    super.key,
    required this.icon,
    required this.iconBg,
    required this.iconColor,
    required this.value,
    required this.label,
    required this.delta,
    required this.deltaPositive,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: ThemeHelper.getCardColor(context),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: ThemeHelper.getBorderColor(context), width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 17, color: iconColor),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w500,
              color: ThemeHelper.getTextColor(context),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(fontSize: 11, color: ThemeHelper.getTextLightColor(context)),
          ),
          const SizedBox(height: 4),
          Text(
            delta,
            style: TextStyle(
              fontSize: 10,
              color: deltaPositive
                  ? ThemeHelper.getSuccessTextColor(context)
                  : ThemeHelper.getWarningTextColor(context),
            ),
          ),
        ],
      ),
    );
  }
}
