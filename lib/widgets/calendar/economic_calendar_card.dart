import 'package:flutter/material.dart';

import '../../models/market_models.dart';
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
                const Expanded(
                  child: Text(
                    'Kalender Ekonomi',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
                  ),
                ),
                Text(instrument, style: TextStyle(color: muted, fontSize: 11)),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              'Event ekonomi dapat membuat harga bergerak lebih cepat. Ini informasi risiko, bukan sinyal trading.',
              style: TextStyle(color: muted, fontSize: 11.5, height: 1.4),
            ),
            const SizedBox(height: 14),
            if (isLoading && events.isEmpty)
              const Center(child: CircularProgressIndicator())
            else if (hasError && events.isEmpty)
              Center(
                child: Column(
                  children: [
                    const Text('Kalender ekonomi belum dapat dimuat.'),
                    if (onRetry != null)
                      TextButton(
                        onPressed: onRetry,
                        child: const Text('Coba lagi'),
                      ),
                  ],
                ),
              )
            else if (visibleEvents.isEmpty)
              Text(
                'Tidak ada event ekonomi relevan yang akan datang.',
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
