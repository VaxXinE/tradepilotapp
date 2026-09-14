import 'package:flutter/material.dart';
import 'package:trade_pilot_api_client/trade_pilot_api_client.dart';

import '../l10n/l10n.dart';
import '../providers/analysis_provider.dart';

String analysisUsageLabel(BuildContext context, AnalysisQuota? quota) {
  if (quota == null) return context.l10n.analysisUsageUnavailable;
  if (quota.unlimited ||
      (quota.hourly.remaining > 0 && quota.daily.remaining > 0)) {
    return context.l10n.analysisUsesFreeQuota;
  }
  if (quota.credits.balance > 0) return context.l10n.analysisUsesOneCredit;
  return context.l10n.analysisUsageUnavailable;
}

/// Returns `true` only when the daily-limit CTA asks to open Top Up Credit.
Future<bool> showAnalysisQuotaDialog(
  BuildContext context,
  AnalysisQuotaLimit limit,
) async {
  final l10n = context.l10n;
  final (title, message) = switch (limit.scope) {
    'hour' => (l10n.analysisQuotaHourTitle, l10n.analysisQuotaHourMessage),
    'day' => (l10n.analysisQuotaDayTitle, l10n.analysisQuotaDayMessage),
    'concurrent' => (
      l10n.analysisQuotaConcurrentTitle,
      l10n.analysisQuotaConcurrentMessage,
    ),
    _ => (l10n.analysisQuotaUnknownTitle, l10n.analysisQuotaUnknownMessage),
  };
  final used = limit.used;
  final quotaLimit = limit.limit;
  final retryAfter = limit.retryAfter;

  return await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: Text(title),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(message),
              if (used != null && quotaLimit != null && quotaLimit > 0) ...[
                const SizedBox(height: 16),
                LinearProgressIndicator(
                  value: (used / quotaLimit).clamp(0, 1).toDouble(),
                ),
                const SizedBox(height: 6),
                Text(l10n.analysisQuotaUsage(used, quotaLimit)),
              ],
              if (retryAfter != null) ...[
                const SizedBox(height: 12),
                Text(
                  l10n.analysisRetryAfter(
                    retryAfter.inSeconds < 60
                        ? l10n.analysisSeconds(retryAfter.inSeconds)
                        : l10n.analysisMinutes(
                            (retryAfter.inSeconds / 60).ceil(),
                          ),
                  ),
                ),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: Text(l10n.close),
            ),
            if (limit.scope == 'day')
              FilledButton(
                onPressed: () => Navigator.pop(dialogContext, true),
                child: Text(l10n.topUpCredit),
              ),
          ],
        ),
      ) ??
      false;
}
