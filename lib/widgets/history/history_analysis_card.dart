import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:trade_pilot_api_client/trade_pilot_api_client.dart';

import '../../core/theme/app_colors.dart';
import '../../l10n/l10n.dart';

class HistoryAnalysisCard extends StatelessWidget {
  const HistoryAnalysisCard({
    super.key,
    required this.analysis,
    required this.onTap,
    this.onReanalyze,
  });

  final Analysis analysis;
  final VoidCallback onTap;
  final VoidCallback? onReanalyze;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dark = theme.brightness == Brightness.dark;
    final muted = dark
        ? AppColors.darkMutedForeground
        : AppColors.lightMutedForeground;
    final marketCondition = analysis.marketCondition?.trim();
    final createdAt = analysis.createdAt.toLocal();
    final locale = Localizations.localeOf(context).toLanguageTag();
    final createdAtLabel = DateFormat(
      'dd MMM yyyy HH:mm',
      locale,
    ).format(createdAt);
    final valid = analysis.validUntil.isAfter(DateTime.now());

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: 7,
                runSpacing: 7,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Text(
                    analysis.instrument,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  _CompactChip(
                    label: analysis.timeframe,
                    color: muted,
                    filled: false,
                  ),
                  _OutcomeBadge(status: analysis.outcomeStatus),
                  if (analysis.hasNote == true)
                    Tooltip(
                      message: context.l10n.hasJournalNote,
                      child: Icon(
                        Icons.menu_book_rounded,
                        size: 18,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  _CompactChip(
                    label: valid ? context.l10n.valid : context.l10n.expired,
                    color: valid ? theme.colorScheme.primary : muted,
                    filled: valid,
                  ),
                  if (onReanalyze != null)
                    TextButton(
                      onPressed: onReanalyze,
                      style: TextButton.styleFrom(
                        minimumSize: const Size(0, 32),
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        backgroundColor: theme.colorScheme.primary.withValues(
                          alpha: .1,
                        ),
                      ),
                      child: Text(
                        context.l10n.historyReanalyze,
                        style: const TextStyle(fontSize: 11),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 7),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  if (marketCondition?.isNotEmpty == true)
                    _CompactChip(
                      label: _marketConditionLabel(context, marketCondition!),
                      color: _marketConditionColor(dark, marketCondition),
                    ),
                  if (analysis.techBuyCount != null &&
                      analysis.techSellCount != null)
                    _MarketContextChip(
                      buy: analysis.techBuyCount!,
                      sell: analysis.techSellCount!,
                    ),
                  SizedBox(
                    width: double.infinity,
                    child: Row(
                      children: [
                        Icon(Icons.schedule_rounded, size: 13, color: muted),
                        const SizedBox(width: 3),
                        Expanded(
                          child: Text(
                            createdAtLabel,
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: muted,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  static String _marketConditionLabel(BuildContext context, String value) {
    switch (value.trim().toLowerCase()) {
      case 'trending_up':
      case 'uptrend':
        return context.l10n.trendingUp;
      case 'trending_down':
      case 'downtrend':
        return context.l10n.trendingDown;
      case 'sideways':
      case 'ranging':
        return context.l10n.historyMarketRanging;
      case 'volatile':
        return context.l10n.volatileMarket;
      case 'trending':
        return context.l10n.trendingMarket;
      default:
        final normalized = value.trim().replaceAll('_', ' ');
        return normalized.isEmpty
            ? normalized
            : '${normalized[0].toUpperCase()}${normalized.substring(1)}';
    }
  }

  static Color _marketConditionColor(bool dark, String value) {
    switch (value.trim().toLowerCase()) {
      case 'trending_up':
      case 'uptrend':
        return dark ? AppColors.bullishDark : AppColors.bullishLight;
      case 'trending_down':
      case 'downtrend':
        return dark ? AppColors.bearishDark : AppColors.bearishLight;
      case 'volatile':
        return const Color(0xFFF97316);
      default:
        return dark ? AppColors.neutralDark : AppColors.neutralLight;
    }
  }
}

class _OutcomeBadge extends StatelessWidget {
  const _OutcomeBadge({required this.status});

  final AnalysisOutcomeStatusEnum? status;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dark = theme.brightness == Brightness.dark;
    final positive =
        status == AnalysisOutcomeStatusEnum.tp1Hit ||
        status == AnalysisOutcomeStatusEnum.tp2Hit;
    final negative = status == AnalysisOutcomeStatusEnum.slHit;
    final color = positive
        ? (dark ? AppColors.bullishDark : AppColors.bullishLight)
        : negative
        ? (dark ? AppColors.bearishDark : AppColors.bearishLight)
        : status == AnalysisOutcomeStatusEnum.pending
        ? theme.colorScheme.primary
        : theme.colorScheme.onSurfaceVariant;

    return _CompactChip(
      icon: status == AnalysisOutcomeStatusEnum.slHit
          ? Icons.cancel_outlined
          : Icons.hourglass_empty_rounded,
      label: _label(context, status),
      color: color,
    );
  }

  static String _label(
    BuildContext context,
    AnalysisOutcomeStatusEnum? status,
  ) {
    switch (status) {
      case AnalysisOutcomeStatusEnum.pending:
        return context.l10n.historyOutcomePending;
      case AnalysisOutcomeStatusEnum.tp1Hit:
        return context.l10n.historyOutcomeTp1;
      case AnalysisOutcomeStatusEnum.tp2Hit:
        return context.l10n.historyOutcomeTp2;
      case AnalysisOutcomeStatusEnum.slHit:
        return context.l10n.historyOutcomeSl;
      case AnalysisOutcomeStatusEnum.expired:
        return context.l10n.expired;
      case AnalysisOutcomeStatusEnum.invalidated:
        return context.l10n.historyMetricInvalid;
      case null:
        return context.l10n.notYetEvaluated;
    }

    return context.l10n.notYetEvaluated;
  }
}

class _CompactChip extends StatelessWidget {
  const _CompactChip({
    required this.label,
    required this.color,
    this.icon,
    this.filled = true,
  });

  final IconData? icon;
  final String label;
  final Color color;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: filled ? color.withValues(alpha: 0.12) : Colors.transparent,
        borderRadius: BorderRadius.circular(6),
        border: filled ? null : Border.all(color: color.withValues(alpha: .25)),
        boxShadow: filled
            ? AppColors.signalGlow(color, enabled: isDark)
            : const [],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 12, color: color),
            const SizedBox(width: 3),
          ],
          Flexible(
            child: Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 10,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MarketContextChip extends StatelessWidget {
  const _MarketContextChip({required this.buy, required this.sell});

  final int buy;
  final int sell;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final bullish = buy > sell * 1.5;
    final bearish = sell > buy * 1.5;
    final color = bullish
        ? (dark ? AppColors.bullishDark : AppColors.bullishLight)
        : bearish
        ? (dark ? AppColors.bearishDark : AppColors.bearishLight)
        : (dark ? AppColors.neutralDark : AppColors.neutralLight);
    return _CompactChip(
      icon: bullish
          ? Icons.trending_up_rounded
          : bearish
          ? Icons.trending_down_rounded
          : Icons.remove_rounded,
      label: bullish
          ? context.l10n.marketContextLeaningBullish
          : bearish
          ? context.l10n.marketContextLeaningBearish
          : context.l10n.marketContextLeaningNeutral,
      color: color,
    );
  }
}
