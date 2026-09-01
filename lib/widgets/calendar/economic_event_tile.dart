import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../models/market_models.dart';
import '../../l10n/l10n.dart';
import 'impact_level_badge.dart';

class EconomicEventTile extends StatelessWidget {
  const EconomicEventTile({
    super.key,
    required this.event,
    required this.instrument,
  });

  final EconomicCalendarEvent event;
  final String instrument;

  @override
  Widget build(BuildContext context) {
    final muted = Theme.of(context).colorScheme.onSurfaceVariant;
    final date = event.eventDateTime;
    final timeLabel = date == null
        ? '${event.date} ${event.time}'.trim()
        : DateFormat('d MMM • HH:mm').format(date);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            ImpactLevelBadge(level: event.impactLevel),
            const Spacer(),
            Text(
              '${_flag(event.currency)} ${event.currency}',
              style: TextStyle(color: muted, fontWeight: FontWeight.w700),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          event.event,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800),
        ),
        if (timeLabel.isNotEmpty) ...[
          const SizedBox(height: 3),
          Text(timeLabel, style: TextStyle(color: muted, fontSize: 11)),
        ],
        if (event.actual.isNotEmpty ||
            event.forecast.isNotEmpty ||
            event.previous.isNotEmpty) ...[
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              if (event.actual.isNotEmpty)
                _Metric(label: context.l10n.actual, value: event.actual),
              if (event.forecast.isNotEmpty)
                _Metric(label: 'Forecast', value: event.forecast),
              if (event.previous.isNotEmpty)
                _Metric(label: context.l10n.previous, value: event.previous),
            ],
          ),
        ],
        const SizedBox(height: 8),
        Text(
          _relationExplanation(context.l10n, event.currency, instrument),
          style: TextStyle(color: muted, fontSize: 10.5, height: 1.35),
        ),
      ],
    );
  }

  String _relationExplanation(
    AppLocalizations l10n,
    String currency,
    String instrument,
  ) {
    final normalized = instrument.toUpperCase();
    if (normalized == 'XAU/USD' && currency.toUpperCase() == 'USD') {
      return l10n.goldEventExplanation;
    }
    if (normalized.split('/').contains(currency.toUpperCase())) {
      return l10n.currencyEventExplanation(currency, instrument);
    }
    return l10n.genericEventExplanation(instrument);
  }

  String _flag(String currency) => switch (currency.toUpperCase()) {
    'USD' => '🇺🇸',
    'EUR' => '🇪🇺',
    'GBP' => '🇬🇧',
    'JPY' => '🇯🇵',
    'AUD' => '🇦🇺',
    'CHF' => '🇨🇭',
    'CNY' => '🇨🇳',
    'IDR' => '🇮🇩',
    _ => '🌐',
  };
}

class _Metric extends StatelessWidget {
  const _Metric({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
      decoration: BoxDecoration(
        color: colors.surfaceContainerHighest.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(7),
      ),
      child: Text(
        '$label: $value',
        style: TextStyle(
          color: colors.onSurfaceVariant,
          fontSize: 9.5,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
