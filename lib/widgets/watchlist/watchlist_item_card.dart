import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:trade_pilot_api_client/trade_pilot_api_client.dart';

class WatchlistItemCard extends StatelessWidget {
  const WatchlistItemCard({
    super.key,
    required this.item,
    required this.onRemove,
  });

  final WatchlistItem item;
  final Future<void> Function(String instrument) onRemove;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final lastAnalysisAt = item.mostRecentAnalysisAt;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.star_rounded, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    item.instrument,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: () => onRemove(item.instrument),
                  child: const Text('Hapus'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Ditambahkan: ${_formatDate(item.addedAt)}',
              style: TextStyle(color: colors.onSurfaceVariant),
            ),
            const SizedBox(height: 4),
            Text(
              item.mostRecentAnalysisId == null || lastAnalysisAt == null
                  ? 'Belum ada analisis'
                  : 'Analisis terakhir: ${_formatDate(lastAnalysisAt)}',
              style: TextStyle(color: colors.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime value) {
    return DateFormat('dd MMM yyyy').format(value.toLocal());
  }
}
