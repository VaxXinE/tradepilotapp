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
            else if (events.isEmpty)
              Text(
                l10n.noUpcomingEconomicEvents,
                style: TextStyle(color: muted),
              )
            else ...[
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 430),
                child: Scrollbar(
                  child: ListView.separated(
                    key: const Key('economic-calendar-event-list'),
                    primary: false,
                    shrinkWrap: true,
                    itemCount: events.length,
                    itemBuilder: (_, index) => EconomicEventTile(
                      event: events[index],
                      instrument: instrument,
                    ),
                    separatorBuilder: (_, _) => const Divider(height: 24),
                  ),
                ),
              ),
              if (events.length > 3) ...[
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.swipe_vertical_rounded, size: 15, color: muted),
                    const SizedBox(width: 6),
                    Text(
                      l10n.scrollForMore,
                      style: TextStyle(color: muted, fontSize: 11),
                    ),
                  ],
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }
}
