import 'package:flutter/material.dart';

import '../../core/history/history_statistics.dart';

class HistorySummaryCard extends StatelessWidget {
  const HistorySummaryCard({
    super.key,
    required this.statistics,
    required this.isPartial,
  });

  final HistoryStatistics statistics;
  final bool isPartial;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final evaluated = statistics.successCount + statistics.failedCount;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isPartial ? 'Ringkasan sementara' : 'Ringkasan riwayat',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 11),
            LayoutBuilder(
              builder: (context, constraints) {
                final width = (constraints.maxWidth - 16) / 3;
                return Wrap(
                  spacing: 8,
                  runSpacing: 10,
                  children: [
                    _Metric(
                      width: width,
                      label: 'Terlihat',
                      value: '${statistics.total}',
                    ),
                    _Metric(
                      width: width,
                      label: 'Dievaluasi',
                      value: '$evaluated',
                    ),
                    _Metric(
                      width: width,
                      label: 'Menunggu',
                      value: '${statistics.pendingCount}',
                    ),
                    _Metric(
                      width: width,
                      label: 'Positif',
                      value: '${statistics.successCount}',
                    ),
                    _Metric(
                      width: width,
                      label: 'Keyakinan rata-rata',
                      value: statistics.total == 0
                          ? '—'
                          : '${statistics.averageConfidence.round()}%',
                    ),
                  ],
                );
              },
            ),
            if (evaluated > 0) ...[
              const SizedBox(height: 10),
              Text(
                '${statistics.successRate.round()}% outcome positif dari '
                'analisis yang sudah dievaluasi.',
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
