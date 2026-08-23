import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:trade_pilot_api_client/trade_pilot_api_client.dart';

import '../../core/theme/app_colors.dart';

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
        'Risiko ${analysis.riskLevel!.trim()}',
      if (analysis.marketCondition?.trim().isNotEmpty == true)
        analysis.marketCondition!.trim(),
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
                      message: 'Memiliki catatan jurnal',
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
                '${analysis.timeframe} • ${_modeLabel(analysis.mode)} • '
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
                    label: _biasLabel(analysis.tradingBias),
                    color: _biasColor(dark, analysis.tradingBias),
                  ),
                  _InfoChip(
                    icon: Icons.speed_rounded,
                    label: 'Keyakinan $confidence',
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

  static String _modeLabel(AnalysisModeEnum mode) {
    return mode == AnalysisModeEnum.pro ? 'Pro' : 'Pemula';
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

  static String _biasLabel(String? value) {
    switch (value?.trim().toLowerCase()) {
      case 'bearish_strong':
      case 'strong_sell':
        return 'Bearish kuat';
      case 'bearish':
      case 'sell':
        return 'Bearish';
      case 'bullish':
      case 'buy':
        return 'Bullish';
      case 'bullish_strong':
      case 'strong_buy':
        return 'Bullish kuat';
      case 'neutral':
        return 'Netral';
      default:
        return 'Bias belum tersedia';
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
      label: _label(status),
      color: color,
    );
  }

  static String _label(AnalysisOutcomeStatusEnum? status) {
    switch (status) {
      case AnalysisOutcomeStatusEnum.pending:
        return 'Menunggu evaluasi';
      case AnalysisOutcomeStatusEnum.tp1Hit:
        return 'Target referensi 1 tercapai';
      case AnalysisOutcomeStatusEnum.tp2Hit:
        return 'Target referensi 2 tercapai';
      case AnalysisOutcomeStatusEnum.slHit:
        return 'Batas risiko tersentuh';
      case AnalysisOutcomeStatusEnum.expired:
        return 'Masa analisis berakhir';
      case AnalysisOutcomeStatusEnum.invalidated:
        return 'Analisis tidak dapat dievaluasi';
      case null:
        return 'Belum dievaluasi';
    }

    return 'Belum dievaluasi';
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
