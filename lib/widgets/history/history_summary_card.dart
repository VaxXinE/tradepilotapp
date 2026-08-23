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
              isPartial
                  ? 'Ringkasan hasil yang sedang dimuat'
                  : 'Ringkasan riwayat yang ditampilkan',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 11),
            Wrap(
              spacing: 18,
              runSpacing: 10,
              children: [
                _Metric(label: 'Terlihat', value: '${statistics.total}'),
                _Metric(label: 'Dievaluasi', value: '$evaluated'),
                _Metric(label: 'Menunggu', value: '${statistics.pendingCount}'),
                _Metric(
                  label: 'Outcome positif',
                  value: '${statistics.successCount}',
                ),
                _Metric(
                  label: 'Rata-rata keyakinan',
                  value: statistics.total == 0
                      ? '—'
                      : '${statistics.averageConfidence.round()}%',
                ),
              ],
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
  const _Metric({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SizedBox(
      width: 112,
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
