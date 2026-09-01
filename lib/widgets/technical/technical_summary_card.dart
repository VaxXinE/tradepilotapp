import 'package:flutter/material.dart';

import '../../models/technical_summary.dart';
import '../../l10n/l10n.dart';
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
    final l10n = context.l10n;
    final muted = Theme.of(context).colorScheme.onSurfaceVariant;
    final data = summary;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.speed_rounded, size: 19),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    l10n.technicalSummary,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              l10n.indicatorEducationDisclaimer,
              style: TextStyle(color: muted, fontSize: 11.5, height: 1.4),
            ),
            const SizedBox(height: 14),
            if (isLoading && data == null)
              const Center(child: CircularProgressIndicator())
            else if (hasError && data == null)
              Center(
                child: Column(
                  children: [
                    Text(l10n.technicalSummaryLoadFailed),
                    if (onRetry != null)
                      TextButton(
                        onPressed: onRetry,
                        child: Text(l10n.tryAgain),
                      ),
                  ],
                ),
              )
            else if (data == null)
              Text(
                l10n.technicalSummaryUnavailable,
                style: TextStyle(color: muted),
              )
            else
              _TechnicalSummaryBody(data: data, l10n: l10n),
          ],
        ),
      ),
    );
  }
}

class _TechnicalSummaryBody extends StatelessWidget {
  const _TechnicalSummaryBody({required this.data, required this.l10n});

  final TechnicalSummary data;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final muted = Theme.of(context).colorScheme.onSurfaceVariant;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _IndicatorRow(
          label: l10n.trend,
          child: ContextIndicator(trend: data.trend),
        ),
        const Divider(height: 24),
        _IndicatorRow(
          label: l10n.momentum,
          child: IndicatorBadge(level: data.momentum),
        ),
        const Divider(height: 24),
        _IndicatorRow(
          label: l10n.risk,
          child: IndicatorBadge(level: data.riskLevel),
        ),
        const SizedBox(height: 14),
        Text(
          l10n.whatDoesItMean,
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
