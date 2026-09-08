import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:trade_pilot_api_client/trade_pilot_api_client.dart';

import '../providers/auth_provider.dart';

class JournalSentimentCard extends StatefulWidget {
  const JournalSentimentCard({required this.instrument, super.key});
  final String instrument;

  @override
  State<JournalSentimentCard> createState() => _JournalSentimentCardState();
}

class _JournalSentimentCardState extends State<JournalSentimentCard> {
  JournalSentiment? _sentiment;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => unawaited(_load()));
  }

  @override
  void didUpdateWidget(covariant JournalSentimentCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.instrument != widget.instrument) {
      _sentiment = null;
      unawaited(_load());
    }
  }

  Future<void> _load() async {
    try {
      final response = await context
          .read<AuthProvider>()
          .client
          .tradeJournal
          .getJournalSentiment(instrument: widget.instrument);
      if (mounted) setState(() => _sentiment = response.data);
    } catch (_) {
      // Widget pelengkap tidak menghalangi alur analisis saat offline.
    }
  }

  @override
  Widget build(BuildContext context) {
    final sentiment = _sentiment;
    if (sentiment == null) return const SizedBox.shrink();
    if (sentiment.gated) {
      return Card(
        child: ListTile(
          leading: const Icon(Icons.groups_outlined),
          title: const Text('Sentimen trader lokal'),
          subtitle: Text(
            'Data disembunyikan sampai minimal ${sentiment.minSampleSize} entri '
            'dari ${sentiment.minDistinctTraders} trader tersedia.',
          ),
        ),
      );
    }
    final buy = sentiment.buyPct ?? 0;
    final sell = sentiment.sellPct ?? 0;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const Icon(Icons.groups_outlined, size: 19),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'Sentimen trader lokal',
                    style: TextStyle(fontWeight: FontWeight.w800),
                  ),
                ),
                Text(
                  '${sentiment.sampleSize ?? 0} entri · ${sentiment.windowDays} hari',
                ),
              ],
            ),
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(99),
              child: Row(
                children: [
                  if (buy > 0)
                    Expanded(
                      flex: buy,
                      child: Container(
                        height: 8,
                        color: const Color(0xFF10B981),
                      ),
                    ),
                  if (sell > 0)
                    Expanded(
                      flex: sell,
                      child: Container(
                        height: 8,
                        color: const Color(0xFFEF4444),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 7),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Buy $buy%',
                  style: const TextStyle(
                    color: Color(0xFF10B981),
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  '$sell% Sell',
                  style: const TextStyle(
                    color: Color(0xFFEF4444),
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 5),
            Text(
              'Agregat anonim jurnal komunitas, bukan sinyal trading.',
              style: Theme.of(context).textTheme.labelSmall,
            ),
          ],
        ),
      ),
    );
  }
}
