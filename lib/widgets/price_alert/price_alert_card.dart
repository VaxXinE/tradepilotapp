import 'package:flutter/material.dart';
import 'package:trade_pilot_api_client/trade_pilot_api_client.dart';

import '../../l10n/l10n.dart';
import 'price_alert_tile.dart';

class PriceAlertCard extends StatelessWidget {
  const PriceAlertCard({
    super.key,
    required this.alerts,
    this.isLoading = false,
    this.hasError = false,
    this.onRetry,
    this.isDeleting,
    this.onDelete,
  });

  final List<UserPriceAlert> alerts;
  final bool isLoading;
  final bool hasError;
  final VoidCallback? onRetry;
  final bool Function(int id)? isDeleting;
  final void Function(int id)? onDelete;

  @override
  Widget build(BuildContext context) {
    final muted = Theme.of(context).colorScheme.onSurfaceVariant;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.notifications_active_outlined, size: 19),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    context.l10n.myPriceAlertsTitle,
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
              context.l10n.priceAlertDisclaimer,
              style: TextStyle(color: muted, fontSize: 11.5, height: 1.4),
            ),
            const SizedBox(height: 14),
            if (isLoading && alerts.isEmpty)
              const Center(child: CircularProgressIndicator())
            else if (hasError && alerts.isEmpty)
              Center(
                child: Column(
                  children: [
                    Text(context.l10n.priceAlertsLoadFailed),
                    if (onRetry != null)
                      TextButton(
                        onPressed: onRetry,
                        child: Text(context.l10n.tryAgain),
                      ),
                  ],
                ),
              )
            else if (alerts.isEmpty)
              Text(context.l10n.noPriceAlerts, style: TextStyle(color: muted))
            else
              for (var index = 0; index < alerts.length; index++) ...[
                PriceAlertTile(
                  alert: alerts[index],
                  isDeleting: isDeleting?.call(alerts[index].id) ?? false,
                  onDelete: onDelete == null
                      ? null
                      : () => onDelete!(alerts[index].id),
                ),
                if (index != alerts.length - 1) const Divider(height: 24),
              ],
          ],
        ),
      ),
    );
  }
}
