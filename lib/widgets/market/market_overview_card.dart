import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/theme/app_colors.dart';
import '../../l10n/l10n.dart';
import '../../models/market_models.dart';

class MarketOverviewCard extends StatelessWidget {
  const MarketOverviewCard({
    super.key,
    required this.quote,
    required this.isLoading,
    required this.error,
    required this.updatedAt,
    required this.onRetry,
    required this.onOpen,
  });

  final LiveMarketQuote? quote;
  final bool isLoading;
  final String? error;
  final DateTime? updatedAt;
  final VoidCallback onRetry;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final currentQuote = quote;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: currentQuote == null
            ? _EmptyState(isLoading: isLoading, error: error, onRetry: onRetry)
            : _QuoteState(
                quote: currentQuote,
                isLoading: isLoading,
                hasError: error != null,
                updatedAt: updatedAt,
                onRetry: onRetry,
                onOpen: onOpen,
              ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({
    required this.isLoading,
    required this.error,
    required this.onRetry,
  });

  final bool isLoading;
  final String? error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const SizedBox(
        height: 132,
        child: Center(child: CircularProgressIndicator()),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          context.l10n.marketOverview,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 12),
        Text(error ?? context.l10n.priceDataUnavailable),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          onPressed: onRetry,
          icon: const Icon(Icons.refresh_rounded),
          label: Text(context.l10n.tryAgain),
        ),
      ],
    );
  }
}

class _QuoteState extends StatelessWidget {
  const _QuoteState({
    required this.quote,
    required this.isLoading,
    required this.hasError,
    required this.updatedAt,
    required this.onRetry,
    required this.onOpen,
  });

  final LiveMarketQuote quote;
  final bool isLoading;
  final bool hasError;
  final DateTime? updatedAt;
  final VoidCallback onRetry;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final changeColor = quote.changePercent >= 0
        ? (isDark ? AppColors.bullishDark : AppColors.bullishLight)
        : (isDark ? AppColors.bearishDark : AppColors.bearishLight);
    final muted = Theme.of(context).colorScheme.onSurfaceVariant;

    return InkWell(
      onTap: onOpen,
      borderRadius: BorderRadius.circular(AppColors.radius),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  context.l10n.marketOverview,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              if (isLoading)
                const SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              else
                const Icon(Icons.arrow_forward_rounded, size: 18),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            quote.instrument,
            style: TextStyle(color: muted, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 4),
          Text(
            _formatPrice(quote.instrument, quote.price),
            style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(
                quote.changePercent >= 0
                    ? Icons.trending_up_rounded
                    : Icons.trending_down_rounded,
                color: changeColor,
                size: 19,
              ),
              const SizedBox(width: 5),
              Text(
                '${quote.changePercent >= 0 ? '+' : ''}'
                '${quote.changePercent.toStringAsFixed(2)}%',
                style: TextStyle(
                  color: changeColor,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (hasError)
            Row(
              children: [
                Expanded(
                  child: Text(
                    context.l10n.latestDataUnavailable,
                    style: TextStyle(color: muted, fontSize: 11),
                  ),
                ),
                TextButton(
                  onPressed: onRetry,
                  child: Text(context.l10n.tryAgain),
                ),
              ],
            )
          else
            Text(
              _updatedText(context.l10n, updatedAt),
              style: TextStyle(color: muted, fontSize: 10.5),
            ),
        ],
      ),
    );
  }
}

String _updatedText(AppLocalizations l10n, DateTime? time) {
  if (time == null) {
    return l10n.waitingForUpdate;
  }

  final elapsedSeconds = DateTime.now().difference(time).inSeconds;
  final seconds = elapsedSeconds < 0 ? 0 : elapsedSeconds;
  if (seconds < 5) {
    return l10n.updatedJustNow;
  }

  if (seconds < 60) {
    return l10n.updatedSecondsAgo(seconds);
  }

  return l10n.updatedAt(DateFormat('HH:mm:ss').format(time.toLocal()));
}

String _formatPrice(String instrument, double value) {
  if (instrument == 'USD/IDR') {
    return NumberFormat('#,##0').format(value);
  }

  if (value >= 100) {
    return NumberFormat('#,##0.00').format(value);
  }

  if (value >= 1) {
    return value.toStringAsFixed(4);
  }

  return value.toStringAsFixed(6);
}
