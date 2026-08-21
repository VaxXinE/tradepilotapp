import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../models/market_context.dart';

/// Small colored badge showing a [MarketTrend] — bullish / bearish / netral.
class ContextIndicator extends StatelessWidget {
  const ContextIndicator({super.key, required this.trend});

  final MarketTrend trend;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final color = switch (trend) {
      MarketTrend.bullish =>
        isDark ? AppColors.bullishDark : AppColors.bullishLight,
      MarketTrend.bearish =>
        isDark ? AppColors.bearishDark : AppColors.bearishLight,
      MarketTrend.neutral =>
        isDark ? AppColors.neutralDark : AppColors.neutralLight,
    };

    final icon = switch (trend) {
      MarketTrend.bullish => Icons.trending_up_rounded,
      MarketTrend.bearish => Icons.trending_down_rounded,
      MarketTrend.neutral => Icons.trending_flat_rounded,
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: color),
          const SizedBox(width: 6),
          Text(
            trend.label,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}
