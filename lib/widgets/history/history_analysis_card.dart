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
  });

  final Analysis analysis;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dark = theme.brightness == Brightness.dark;
    final muted = dark
        ? AppColors.darkMutedForeground
        : AppColors.lightMutedForeground;
    final confidence = _confidenceLabel(analysis);
    final details = [
      if (analysis.riskLevel?.trim().isNotEmpty == true)
        context.l10n.riskValue(_riskLabel(context, analysis.riskLevel!)),
      if (analysis.marketCondition?.trim().isNotEmpty == true)
        _marketConditionLabel(context, analysis.marketCondition!),
    ];

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      analysis.instrument,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  if (analysis.hasNote == true)
                    Tooltip(
                      message: context.l10n.hasJournalNote,
                      child: Icon(
                        Icons.menu_book_rounded,
                        size: 18,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  const SizedBox(width: 4),
                  Icon(Icons.chevron_right_rounded, color: muted),
                ],
              ),
              const SizedBox(height: 3),
              Text(
                '${analysis.timeframe} • ${_modeLabel(context, analysis.mode)} • '
                '${DateFormat('d MMM yyyy, HH:mm').format(analysis.createdAt.toLocal())}',
                style: theme.textTheme.bodySmall?.copyWith(color: muted),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 7,
                runSpacing: 7,
                children: [
                  _InfoChip(
                    icon: Icons.swap_vert_rounded,
                    label: _biasLabel(context, analysis.tradingBias),
                    color: _biasColor(dark, analysis.tradingBias),
                  ),
                  _InfoChip(
                    icon: Icons.speed_rounded,
                    label: context.l10n.confidenceValue(confidence),
                    color: theme.colorScheme.primary,
                  ),
                  _OutcomeBadge(status: analysis.outcomeStatus),
                ],
              ),
              if (details.isNotEmpty) ...[
                const SizedBox(height: 9),
                Text(
                  details.join(' • '),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(color: muted),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  static String _modeLabel(BuildContext context, AnalysisModeEnum mode) {
    return mode == AnalysisModeEnum.pro
        ? context.l10n.pro
        : context.l10n.beginner;
  }

  static String _confidenceLabel(Analysis analysis) {
    final minimum = analysis.confidenceMin;
    final maximum = analysis.confidenceMax;
    if (minimum == null && maximum == null) {
      return '—';
    }
    if (minimum == null || maximum == null || minimum == maximum) {
      return '${minimum ?? maximum}%';
    }
    return '$minimum–$maximum%';
  }

  static String _biasLabel(BuildContext context, String? value) {
    switch (value?.trim().toLowerCase()) {
      case 'bearish_strong':
      case 'strong_sell':
        return context.l10n.strongBearish;
      case 'bearish':
      case 'sell':
        return 'Bearish';
      case 'bullish':
      case 'buy':
        return 'Bullish';
      case 'bullish_strong':
      case 'strong_buy':
        return context.l10n.strongBullish;
      case 'neutral':
        return context.l10n.neutral;
      default:
        return context.l10n.biasUnavailable;
    }
  }

  static String _riskLabel(BuildContext context, String value) {
    switch (value.trim().toLowerCase()) {
      case 'low':
        return context.l10n.low.toLowerCase();
      case 'medium':
        return context.l10n.medium.toLowerCase();
      case 'high':
        return context.l10n.high.toLowerCase();
      default:
        return value.trim().replaceAll('_', ' ');
    }
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
        return context.l10n.movingSideways;
      case 'trending':
        return context.l10n.trendingMarket;
      default:
        final normalized = value.trim().replaceAll('_', ' ');
        return normalized.isEmpty
            ? normalized
            : '${normalized[0].toUpperCase()}${normalized.substring(1)}';
    }
  }

  static Color _biasColor(bool dark, String? value) {
    final normalized = value?.toLowerCase() ?? '';
    if (normalized.contains('bullish') ||
        normalized == 'buy' ||
        normalized == 'strong_buy') {
      return dark ? AppColors.bullishDark : AppColors.bullishLight;
    }
    if (normalized.contains('bearish') ||
        normalized == 'sell' ||
        normalized == 'strong_sell') {
      return dark ? AppColors.bearishDark : AppColors.bearishLight;
    }
    return dark ? AppColors.neutralDark : AppColors.neutralLight;
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
    final negative =
        status == AnalysisOutcomeStatusEnum.slHit ||
        status == AnalysisOutcomeStatusEnum.expired ||
        status == AnalysisOutcomeStatusEnum.invalidated;
    final color = positive
        ? (dark ? AppColors.bullishDark : AppColors.bullishLight)
        : negative
        ? (dark ? AppColors.bearishDark : AppColors.bearishLight)
        : theme.colorScheme.primary;

    return _InfoChip(
      icon: Icons.fact_check_outlined,
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
        return context.l10n.evaluationPending;
      case AnalysisOutcomeStatusEnum.tp1Hit:
        return context.l10n.referenceTargetOneHit;
      case AnalysisOutcomeStatusEnum.tp2Hit:
        return context.l10n.referenceTargetTwoHit;
      case AnalysisOutcomeStatusEnum.slHit:
        return context.l10n.riskLimitHit;
      case AnalysisOutcomeStatusEnum.expired:
        return context.l10n.analysisPeriodEnded;
      case AnalysisOutcomeStatusEnum.invalidated:
        return context.l10n.analysisCannotBeEvaluated;
      case null:
        return context.l10n.notYetEvaluated;
    }

    return context.l10n.notYetEvaluated;
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({
    required this.icon,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.11),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 10.5,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}
