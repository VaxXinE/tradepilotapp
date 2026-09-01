import 'package:flutter/material.dart';

import '../../models/market_models.dart';

class ImpactLevelBadge extends StatelessWidget {
  const ImpactLevelBadge({super.key, required this.level});

  final EconomicImpactLevel level;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final (label, color) = switch (level) {
      EconomicImpactLevel.high => ('High Impact', colors.error),
      EconomicImpactLevel.medium => ('Medium Impact', colors.tertiary),
      EconomicImpactLevel.low => ('Low Impact', colors.primary),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 9,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}
