import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:trade_pilot_api_client/trade_pilot_api_client.dart';

import '../../core/theme/app_colors.dart';

class PriceAlertTile extends StatelessWidget {
  const PriceAlertTile({
    super.key,
    required this.alert,
    this.isDeleting = false,
    this.onDelete,
  });

  final UserPriceAlert alert;
  final bool isDeleting;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final muted = Theme.of(context).colorScheme.onSurfaceVariant;

    final isAbove =
        alert.triggerDirection == UserPriceAlertTriggerDirectionEnum.above;

    final conditionText = isAbove
        ? 'Naik melewati ${alert.targetPrice}'
        : 'Turun melewati ${alert.targetPrice}';

    final (statusLabel, statusColor) = switch (alert.status) {
      UserPriceAlertStatusEnum.triggered => (
        'Terpicu',
        isDark ? AppColors.bullishDark : AppColors.bullishLight,
      ),
      UserPriceAlertStatusEnum.cancelled => (
        'Dibatalkan',
        isDark ? AppColors.neutralDark : AppColors.neutralLight,
      ),
      _ => ('Aktif', isDark ? AppColors.darkAccent : AppColors.lightAccent),
    };

    final note = alert.note?.trim() ?? '';

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          isAbove ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded,
          size: 18,
          color: isDark ? AppColors.neutralDark : AppColors.neutralLight,
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    alert.instrument,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      statusLabel,
                      style: TextStyle(
                        color: statusColor,
                        fontSize: 9.5,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 3),
              Text(conditionText, style: TextStyle(fontSize: 12, color: muted)),
              if (note.isNotEmpty) ...[
                const SizedBox(height: 3),
                Text(
                  note,
                  style: TextStyle(
                    fontSize: 11.5,
                    color: muted,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
              const SizedBox(height: 3),
              Text(
                DateFormat('d MMM yyyy').format(alert.createdAt.toLocal()),
                style: TextStyle(fontSize: 10.5, color: muted),
              ),
            ],
          ),
        ),
        if (onDelete != null)
          isDeleting
              ? const Padding(
                  padding: EdgeInsets.all(10),
                  child: SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                )
              : IconButton(
                  icon: const Icon(Icons.delete_outline_rounded, size: 20),
                  tooltip: 'Hapus alert',
                  onPressed: onDelete,
                ),
      ],
    );
  }
}
