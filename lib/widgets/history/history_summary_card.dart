import 'package:flutter/material.dart';

import '../../core/history/history_statistics.dart';
import '../../l10n/l10n.dart';

enum HistorySummaryMetric { total, valid, expired, sl, tp1, tp2, invalid }

class HistorySummaryCard extends StatelessWidget {
  const HistorySummaryCard({
    super.key,
    required this.statistics,
    this.onMetricTap,
  });

  final HistoryStatistics statistics;
  final ValueChanged<HistorySummaryMetric>? onMetricTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final metrics = [
      (
        HistorySummaryMetric.total,
        Icons.gps_fixed_rounded,
        context.l10n.historyMetricTotal,
        statistics.total,
      ),
      (
        HistorySummaryMetric.valid,
        Icons.schedule_rounded,
        context.l10n.historyMetricValid,
        statistics.activeValidCount,
      ),
      (
        HistorySummaryMetric.expired,
        Icons.schedule_rounded,
        context.l10n.expired,
        statistics.expiredCount,
      ),
      (
        HistorySummaryMetric.sl,
        Icons.trending_down_rounded,
        'SL',
        statistics.riskLimitHitCount,
      ),
      (
        HistorySummaryMetric.tp1,
        Icons.check_circle_outline_rounded,
        'TP1',
        statistics.tp1HitCount,
      ),
      (
        HistorySummaryMetric.tp2,
        Icons.check_circle_outline_rounded,
        'TP2',
        statistics.tp2HitCount,
      ),
      (
        HistorySummaryMetric.invalid,
        Icons.warning_amber_rounded,
        context.l10n.historyMetricInvalid,
        statistics.invalidatedCount,
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final oneColumn = MediaQuery.textScalerOf(context).scale(1) > 1.5;
        final width = oneColumn
            ? constraints.maxWidth
            : (constraints.maxWidth - 8) / 2;
        return Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final metric in metrics)
              _Metric(
                width: width,
                icon: metric.$2,
                label: metric.$3,
                value: '${metric.$4}',
                onTap: onMetricTap == null
                    ? null
                    : () => onMetricTap!(metric.$1),
                color: theme.colorScheme.primary,
              ),
          ],
        );
      },
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric({
    required this.width,
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
    this.onTap,
  });

  final double width;
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SizedBox(
      width: width,
      child: Card(
        margin: EdgeInsets.zero,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(icon, size: 17, color: color),
                const SizedBox(height: 9),
                Text(
                  value,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  label,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
