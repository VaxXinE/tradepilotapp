import 'package:flutter/material.dart';

import '../../core/history/history_statistics.dart';
import '../../l10n/l10n.dart';

class HistorySummaryCard extends StatelessWidget {
  const HistorySummaryCard({super.key, required this.statistics});

  final HistoryStatistics statistics;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final evaluated = statistics.targetHitCount + statistics.riskLimitHitCount;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              context.l10n.allHistorySummary,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 11),
            LayoutBuilder(
              builder: (context, constraints) {
                final textScale = MediaQuery.textScalerOf(context).scale(1);
                final columns = textScale > 1.3
                    ? 1
                    : constraints.maxWidth < 330
                    ? 2
                    : 3;
                final width =
                    (constraints.maxWidth - (columns - 1) * 8) / columns;
                return Wrap(
                  spacing: 8,
                  runSpacing: 10,
                  children: [
                    _Metric(
                      width: width,
                      label: context.l10n.evaluated,
                      value: '$evaluated',
                    ),
                    _Metric(
                      width: width,
                      label: context.l10n.pending,
                      value: '${statistics.pendingCount}',
                    ),
                    _Metric(
                      width: width,
                      label: context.l10n.targetReached,
                      value: '${statistics.targetHitCount}',
                    ),
                    _Metric(
                      width: width,
                      label: context.l10n.riskLimitTouched,
                      value: '${statistics.riskLimitHitCount}',
                    ),
                    _Metric(
                      width: width,
                      label: context.l10n.periodEnded,
                      value: '${statistics.expiredCount}',
                    ),
                    _Metric(
                      width: width,
                      label: context.l10n.cannotBeEvaluated,
                      value: '${statistics.invalidatedCount}',
                    ),
                  ],
                );
              },
            ),
            if (evaluated > 0) ...[
              const SizedBox(height: 10),
              Text(
                context.l10n.positiveEvaluatedSummary(
                  statistics.targetHitRate.round(),
                ),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric({
    required this.width,
    required this.label,
    required this.value,
  });

  final double width;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SizedBox(
      width: width,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w900,
            ),
          ),
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
