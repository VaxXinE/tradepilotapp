import 'package:flutter/material.dart';

import '../../models/technical_summary.dart';
import '../context/context_indicator.dart';
import 'indicator_badge.dart';

class TechnicalSummaryCard extends StatelessWidget {
  const TechnicalSummaryCard({
    super.key,
    required this.summary,
    this.isLoading = false,
    this.hasError = false,
    this.onRetry,
  });

  final TechnicalSummary? summary;
  final bool isLoading;
  final bool hasError;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final muted = Theme.of(context).colorScheme.onSurfaceVariant;
    final data = summary;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.speed_rounded, size: 19),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Ringkasan Teknikal',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              'Kami sederhanakan indikator agar mudah dipahami. Bukan '
              'sinyal atau rekomendasi trading.',
              style: TextStyle(color: muted, fontSize: 11.5, height: 1.4),
            ),
            const SizedBox(height: 14),
            if (isLoading && data == null)
              const Center(child: CircularProgressIndicator())
            else if (hasError && data == null)
              Center(
                child: Column(
                  children: [
                    const Text('Ringkasan teknikal belum dapat dimuat.'),
                    if (onRetry != null)
                      TextButton(
                        onPressed: onRetry,
                        child: const Text('Coba lagi'),
                      ),
                  ],
                ),
              )
            else if (data == null)
              Text(
                'Ringkasan teknikal belum tersedia untuk market ini.',
                style: TextStyle(color: muted),
              )
            else
              _TechnicalSummaryBody(data: data),
          ],
        ),
      ),
    );
  }
}

class _TechnicalSummaryBody extends StatelessWidget {
  const _TechnicalSummaryBody({required this.data});

  final TechnicalSummary data;

  @override
  Widget build(BuildContext context) {
    final muted = Theme.of(context).colorScheme.onSurfaceVariant;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _IndicatorRow(
          label: 'Trend',
          child: ContextIndicator(trend: data.trend),
        ),
        const Divider(height: 24),
        _IndicatorRow(
          label: 'Momentum',
          child: IndicatorBadge(level: data.momentum),
        ),
        const Divider(height: 24),
        _IndicatorRow(
          label: 'Risiko',
          child: IndicatorBadge(level: data.riskLevel),
        ),
        const SizedBox(height: 14),
        Text(
          'Apa artinya?',
          style: TextStyle(
            color: muted,
            fontSize: 10.5,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          data.explanation,
          style: const TextStyle(fontSize: 12.5, height: 1.45),
        ),
      ],
    );
  }
}

class _IndicatorRow extends StatelessWidget {
  const _IndicatorRow({required this.label, required this.child});

  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600),
          ),
        ),
        child,
      ],
    );
  }
}
