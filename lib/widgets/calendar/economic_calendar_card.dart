import 'package:flutter/material.dart';

import '../../models/market_models.dart';
import '../../l10n/l10n.dart';
import 'economic_event_tile.dart';

class EconomicCalendarCard extends StatelessWidget {
  const EconomicCalendarCard({
    super.key,
    required this.instrument,
    required this.events,
    this.isLoading = false,
    this.hasError = false,
    this.onRetry,
  });

  final String instrument;
  final List<EconomicCalendarEvent> events;
  final bool isLoading;
  final bool hasError;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final muted = Theme.of(context).colorScheme.onSurfaceVariant;
    final visibleEvents = events.take(6).toList();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.calendar_month_outlined, size: 19),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    l10n.economicCalendar,
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
              l10n.economicEventRiskDisclaimer,
              style: TextStyle(color: muted, fontSize: 11.5, height: 1.4),
            ),
            const SizedBox(height: 14),
            if (isLoading && events.isEmpty)
              const Center(child: CircularProgressIndicator())
            else if (hasError && events.isEmpty)
              Center(
                child: Column(
                  children: [
                    Text(l10n.economicCalendarLoadFailed),
                    if (onRetry != null)
                      TextButton(
                        onPressed: onRetry,
                        child: Text(l10n.tryAgain),
                      ),
                  ],
                ),
              )
            else if (visibleEvents.isEmpty)
              Text(
                l10n.noUpcomingEconomicEvents,
                style: TextStyle(color: muted),
              )
            else
              for (var index = 0; index < visibleEvents.length; index++) ...[
                EconomicEventTile(
                  event: visibleEvents[index],
                  instrument: instrument,
                ),
                if (index != visibleEvents.length - 1)
                  const Divider(height: 24),
              ],
          ],
        ),
      ),
    );
  }
}
