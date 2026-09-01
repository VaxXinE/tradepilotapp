import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../models/market_context.dart';

/// Small colored pill showing a [MarketLevel] (Rendah/Sedang/Tinggi) —
/// used for momentum, volatility, and risk readouts.
class IndicatorBadge extends StatelessWidget {
  const IndicatorBadge({super.key, required this.level});

  final MarketLevel level;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final color = level == MarketLevel.high
        ? (isDark ? AppColors.darkAccent : AppColors.lightAccent)
        : (isDark ? AppColors.neutralDark : AppColors.neutralLight);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        level.label,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}
