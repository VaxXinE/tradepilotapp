import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:trade_pilot_api_client/trade_pilot_api_client.dart';

import '../core/theme/app_colors.dart';

class AnalysisCard extends StatelessWidget {
  const AnalysisCard({super.key, required this.analysis, required this.onTap});

  final Analysis analysis;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final muted = isDark ? AppColors.darkMutedForeground : AppColors.lightMutedForeground;
    final border = isDark ? AppColors.darkBorder : AppColors.lightBorder;

    final isExpired = analysis.validUntil.isBefore(DateTime.now());
    final bias = (analysis.tradingBias ?? '').toLowerCase();
    final biasColor = bias.contains('bull')
        ? (isDark ? AppColors.bullishDark : AppColors.bullishLight)
        : bias.contains('bear')
            ? (isDark ? AppColors.bearishDark : AppColors.bearishLight)
            : (isDark ? AppColors.neutralDark : AppColors.neutralLight);
    final biasLabel = bias.contains('bull')
        ? 'Bullish'
        : bias.contains('bear')
            ? 'Bearish'
            : 'Netral';

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppColors.radius),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                width: 4,
                height: 44,
                decoration: BoxDecoration(color: biasColor, borderRadius: BorderRadius.circular(4)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            analysis.instrument,
                            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: biasColor.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            biasLabel,
                            style: TextStyle(color: biasColor, fontSize: 11, fontWeight: FontWeight.w700),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Text(analysis.timeframe, style: TextStyle(color: muted, fontSize: 12.5)),
                        const SizedBox(width: 8),
                        Container(width: 3, height: 3, decoration: BoxDecoration(color: muted, shape: BoxShape.circle)),
                        const SizedBox(width: 8),
                        Text(
                          DateFormat('d MMM, HH:mm').format(analysis.createdAt),
                          style: TextStyle(color: muted, fontSize: 12.5),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  if (analysis.confidenceMin != null && analysis.confidenceMax != null)
                    Text(
                      '${analysis.confidenceMin}-${analysis.confidenceMax}%',
                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                    ),
                  const SizedBox(height: 2),
                  Text(
                    isExpired ? 'Kedaluwarsa' : 'Berlaku',
                    style: TextStyle(
                      fontSize: 10.5,
                      color: isExpired ? (isDark ? AppColors.bearishDark : AppColors.bearishLight) : muted,
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 4),
              Icon(Icons.chevron_right_rounded, color: border, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}
