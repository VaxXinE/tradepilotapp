import 'package:flutter/material.dart';

import '../../models/market_context.dart';
import '../../l10n/l10n.dart';
import 'context_indicator.dart';

class MarketContextCard extends StatelessWidget {
  const MarketContextCard({
    super.key,
    required this.instrument,
    required this.marketContext,
    this.isLoading = false,
    this.hasError = false,
    this.onRetry,
  });

  final String instrument;
  final MarketContext? marketContext;
  final bool isLoading;
  final bool hasError;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final muted = Theme.of(context).colorScheme.onSurfaceVariant;
    final data = marketContext;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.insights_outlined, size: 19),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    l10n.marketContext,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                Text(instrument, style: TextStyle(color: muted, fontSize: 11)),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              l10n.marketEducationDisclaimer,
              style: TextStyle(color: muted, fontSize: 11.5, height: 1.4),
            ),
            const SizedBox(height: 14),
            if (isLoading && data == null)
              const Center(child: CircularProgressIndicator())
            else if (hasError && data == null)
              Center(
                child: Column(
                  children: [
                    Text(l10n.marketContextLoadFailed),
                    if (onRetry != null)
                      TextButton(
                        onPressed: onRetry,
                        child: Text(l10n.tryAgain),
                      ),
                  ],
                ),
              )
            else if (data == null)
              Text(l10n.insufficientMarketData, style: TextStyle(color: muted))
            else
              _MarketContextBody(data: data, l10n: l10n),
          ],
        ),
      ),
    );
  }
}

class _MarketContextBody extends StatelessWidget {
  const _MarketContextBody({required this.data, required this.l10n});

  final MarketContext data;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final muted = Theme.of(context).colorScheme.onSurfaceVariant;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            ContextIndicator(trend: data.trend),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                data.condition,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Text(
          l10n.why,
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
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              child: Text(
                l10n.riskLevel,
                style: TextStyle(color: muted, fontSize: 11),
              ),
            ),
            Text(
              data.riskLevel.label,
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800),
            ),
          ],
        ),
      ],
    );
  }
}
