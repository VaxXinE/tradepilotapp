import 'package:flutter/material.dart';

import '../../core/market/market_sessions.dart';
import '../../core/theme/app_colors.dart';

class MarketSessionCard extends StatelessWidget {
  const MarketSessionCard({super.key, required this.instrument, this.now});

  final String instrument;
  final DateTime? now;

  @override
  Widget build(BuildContext context) {
    final status = getMarketSessionStatus(now: now);
    final isCrypto = isCryptoMarketInstrument(instrument);
    final isActive = isCrypto || status.openSessions.isNotEmpty;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final statusColor = isActive
        ? (isDark ? AppColors.bullishDark : AppColors.bullishLight)
        : (isDark ? AppColors.neutralDark : AppColors.neutralLight);
    final muted = Theme.of(context).colorScheme.onSurfaceVariant;

    final title = isCrypto
        ? 'Market Crypto 24/7'
        : status.openSessions.isEmpty
        ? 'Market ditutup'
        : status.openSessions.map(marketSessionLabel).join(' + ');

    final liquidity = isCrypto
        ? 'BERVARIASI'
        : status.isOverlap
        ? 'TINGGI'
        : isActive
        ? 'SEDANG'
        : 'RENDAH';

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Sesi Market',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    isActive
                        ? Icons.trending_up_rounded
                        : Icons.schedule_rounded,
                    color: statusColor,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        isActive ? 'AKTIF' : 'TUTUP',
                        style: TextStyle(
                          color: statusColor,
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _InfoRow(label: 'Likuiditas', value: liquidity),
            if (!isCrypto && status.next != null) ...[
              const SizedBox(height: 9),
              _InfoRow(
                label: 'Berikutnya',
                value: _transitionText(status.next!),
              ),
            ],
            if (status.isOverlap && !isCrypto) ...[
              const SizedBox(height: 10),
              Text(
                'Overlap sesi biasanya memiliki aktivitas pasar lebih tinggi.',
                style: TextStyle(color: muted, fontSize: 10.5, height: 1.35),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              fontSize: 11,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800),
          ),
        ),
      ],
    );
  }
}

String _transitionText(MarketSessionTransition transition) {
  final action = transition.type == 'open' ? 'buka' : 'tutup';
  return '${marketSessionLabel(transition.session)} $action dalam '
      '${formatMarketDuration(transition.until)}';
}
