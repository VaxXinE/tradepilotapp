import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:trade_pilot_api_client/trade_pilot_api_client.dart';

import '../models/market_models.dart';

class AnalysisLevelsChart extends StatelessWidget {
  const AnalysisLevelsChart({
    super.key,
    required this.candles,
    required this.analysisCreatedAt,
    this.tradePlan,
    this.isLoading = false,
  });

  final List<MarketCandle> candles;
  final TradePlan? tradePlan;
  final DateTime analysisCreatedAt;

  final bool isLoading;

  static const int _maxCandles = 120;

  @override
  Widget build(BuildContext context) {
    if (isLoading && candles.isEmpty) {
      return const SizedBox(
        height: 240,
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (candles.length < 2) {
      return SizedBox(
        height: 180,
        child: Center(
          child: Text(
            'Data chart belum tersedia.',
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              fontSize: 12.5,
            ),
          ),
        ),
      );
    }

    final visible = candles.length > _maxCandles
        ? candles.sublist(candles.length - _maxCandles)
        : candles;

    final levels = _buildLevels(context, tradePlan);

    var minY = visible.first.low;
    var maxY = visible.first.high;

    for (final candle in visible.skip(1)) {
      minY = math.min(minY, candle.low);

      maxY = math.max(maxY, candle.high);
    }

    for (final level in levels) {
      minY = math.min(minY, level.price);

      maxY = math.max(maxY, level.price);
    }

    final range = maxY - minY;

    final padding = range > 0
        ? range * 0.08
        : math.max(maxY.abs() * 0.002, 0.01);

    final spots = <FlSpot>[
      for (var i = 0; i < visible.length; i++)
        FlSpot(i.toDouble(), visible[i].close),
    ];

    final cutoffIndex = _findCutoffIndex(visible, analysisCreatedAt);

    final primary = Theme.of(context).colorScheme.primary;

    final muted = Theme.of(context).colorScheme.onSurfaceVariant;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: 240,
          child: LineChart(
            LineChartData(
              minX: 0,
              maxX: (visible.length - 1).toDouble(),
              minY: minY - padding,
              maxY: maxY + padding,
              gridData: FlGridData(
                drawVerticalLine: false,
                horizontalInterval: range > 0 ? range / 4 : null,
                getDrawingHorizontalLine: (_) {
                  return FlLine(
                    color: muted.withValues(alpha: 0.12),
                    strokeWidth: 1,
                  );
                },
              ),
              borderData: FlBorderData(show: false),
              titlesData: const FlTitlesData(show: false),
              lineTouchData: LineTouchData(
                enabled: true,
                touchTooltipData: LineTouchTooltipData(
                  getTooltipItems: (touched) {
                    return touched.map((spot) {
                      var index = spot.x.round();

                      if (index < 0) {
                        index = 0;
                      }

                      if (index >= visible.length) {
                        index = visible.length - 1;
                      }

                      final candle = visible[index];

                      return LineTooltipItem(
                        '${_formatPrice(candle.close)}\n'
                        '${DateFormat('d MMM HH:mm').format(candle.date.toLocal())}',
                        TextStyle(
                          color: Theme.of(context).colorScheme.onSurface,
                          fontSize: 10.5,
                          fontWeight: FontWeight.w600,
                        ),
                      );
                    }).toList();
                  },
                ),
              ),
              extraLinesData: ExtraLinesData(
                horizontalLines: [
                  for (final level in levels)
                    HorizontalLine(
                      y: level.price,
                      color: level.color,
                      strokeWidth: 1.5,
                      dashArray: level.dashed ? [6, 4] : null,

                      // Sama seperti axisLabelVisible di web.
                      label: HorizontalLineLabel(
                        show: true,
                        alignment: Alignment.topRight,
                        padding: const EdgeInsets.only(right: 6, bottom: 3),
                        style: TextStyle(
                          color: level.color,
                          fontSize: 9.5,
                          fontWeight: FontWeight.w800,
                          backgroundColor: Theme.of(
                            context,
                          ).colorScheme.surface.withValues(alpha: 0.88),
                        ),
                        labelResolver: (_) {
                          return '${level.label} ${_formatPrice(level.price)}';
                        },
                      ),
                    ),
                ],
                verticalLines: [
                  if (cutoffIndex != null)
                    VerticalLine(
                      x: cutoffIndex.toDouble(),
                      color: muted.withValues(alpha: 0.8),
                      strokeWidth: 1,
                      dashArray: [5, 4],
                    ),
                ],
              ),
              lineBarsData: [
                LineChartBarData(
                  spots: spots,
                  isCurved: true,
                  color: primary,
                  barWidth: 2,
                  dotData: const FlDotData(show: false),
                  belowBarData: BarAreaData(
                    show: true,
                    color: primary.withValues(alpha: 0.06),
                  ),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 10),

        if (cutoffIndex != null)
          _LegendItem(color: muted, label: 'AI membuat analisis', dashed: true),

        if (levels.isNotEmpty) ...[
          const SizedBox(height: 12),

          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Theme.of(
                context,
              ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.35),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                for (var i = 0; i < levels.length; i++) ...[
                  _LevelValueRow(level: levels[i]),

                  if (i != levels.length - 1) const Divider(height: 16),
                ],
              ],
            ),
          ),
        ],

        if (tradePlan?.preferredSide == TradePlanPreferredSideEnum.wait) ...[
          const SizedBox(height: 10),
          Text(
            'AI menyarankan menunggu konfirmasi. '
            'Level Buy/Sell tidak ditampilkan pada chart agar tidak terlihat seperti rekomendasi entry aktif.',
            style: TextStyle(color: muted, fontSize: 10.5, height: 1.4),
          ),
        ],
      ],
    );
  }

  int? _findCutoffIndex(List<MarketCandle> candles, DateTime createdAt) {
    final target = createdAt.toUtc();

    for (var i = 0; i < candles.length; i++) {
      if (!candles[i].date.toUtc().isBefore(target)) {
        return i;
      }
    }

    if (target.isAfter(candles.last.date.toUtc())) {
      return candles.length - 1;
    }

    return null;
  }

  List<_PriceLevel> _buildLevels(BuildContext context, TradePlan? plan) {
    if (plan == null || plan.preferredSide == TradePlanPreferredSideEnum.wait) {
      return const [];
    }

    final isBuy = plan.preferredSide == TradePlanPreferredSideEnum.buy;

    final side = isBuy ? plan.buy : plan.sell;

    final primary = Theme.of(context).colorScheme.primary;

    final error = Theme.of(context).colorScheme.error;

    final takeProfit = Theme.of(context).colorScheme.tertiary;

    final result = <_PriceLevel>[];

    final entry = _parsePriceLevel(side.entryZone);

    final stopLoss = _parsePriceLevel(side.stopLoss);

    final tp1 = _parsePriceLevel(side.takeProfit1);

    final tp2 = _parsePriceLevel(side.takeProfit2);

    if (entry != null) {
      result.add(
        _PriceLevel(
          label: 'Reference Entry',
          price: entry,
          displayValue: side.entryZone,
          color: primary,
          dashed: true,
        ),
      );
    }

    if (stopLoss != null) {
      result.add(
        _PriceLevel(
          label: 'Risk Reference',
          price: stopLoss,
          displayValue: side.stopLoss,
          color: error,
          dashed: false,
        ),
      );
    }

    if (tp1 != null) {
      result.add(
        _PriceLevel(
          label: 'Target Reference 1',
          price: tp1,
          displayValue: side.takeProfit1,
          color: takeProfit,
          dashed: false,
        ),
      );
    }

    if (tp2 != null) {
      result.add(
        _PriceLevel(
          label: 'Target Reference 2',
          price: tp2,
          displayValue: side.takeProfit2,
          color: takeProfit,
          dashed: false,
        ),
      );
    }

    return result;
  }

  double? _parsePriceLevel(String raw) {
    final matches = RegExp(r'\d[\d.,]*').allMatches(raw);

    final values = <double>[];

    for (final match in matches) {
      final rawNumber = match.group(0);

      if (rawNumber == null) {
        continue;
      }

      final parsed = _parseFlexibleNumber(rawNumber);

      if (parsed != null && parsed.isFinite && parsed > 0) {
        values.add(parsed);
      }
    }

    if (values.isEmpty) {
      return null;
    }

    if (values.length == 1) {
      return values.first;
    }

    // Entry/SL berupa range:
    //
    // 3341.25 - 3345.00
    //
    // garis divisualisasikan pada midpoint.
    return (values[0] + values[1]) / 2;
  }

  double? _parseFlexibleNumber(String raw) {
    var value = raw
        .trim()
        .replaceAll(RegExp(r'\s'), '')
        .replaceAll(RegExp(r'[.,]+$'), '');

    final lastComma = value.lastIndexOf(',');

    final lastDot = value.lastIndexOf('.');

    // Contoh:
    // 3,341.25
    // 3.341,25
    if (lastComma >= 0 && lastDot >= 0) {
      if (lastDot > lastComma) {
        // 3,341.25
        value = value.replaceAll(',', '');
      } else {
        // 3.341,25
        value = value.replaceAll('.', '');

        value = value.replaceAll(',', '.');
      }
    } else if (lastComma >= 0) {
      final digitsAfter = value.length - lastComma - 1;

      if (digitsAfter == 3 && lastComma <= 3) {
        // 3,341 → 3341
        value = value.replaceAll(',', '');
      } else {
        // 1,0857 → 1.0857
        value = value.replaceAll(',', '.');
      }
    }

    return double.tryParse(value);
  }

  String _formatPrice(double value) {
    if (value >= 1000) {
      return value.toStringAsFixed(2);
    }

    if (value >= 100) {
      return value.toStringAsFixed(2);
    }

    if (value >= 1) {
      return value.toStringAsFixed(4);
    }

    return value.toStringAsFixed(6);
  }
}

class _PriceLevel {
  const _PriceLevel({
    required this.label,
    required this.price,
    required this.displayValue,
    required this.color,
    required this.dashed,
  });

  final String label;
  final double price;
  final String displayValue;
  final Color color;
  final bool dashed;

  _PriceLevel copyWith({double? price}) {
    return _PriceLevel(
      label: label,
      price: price ?? this.price,
      displayValue: displayValue,
      color: color,
      dashed: dashed,
    );
  }
}

class _LegendItem extends StatelessWidget {
  const _LegendItem({
    required this.color,
    required this.label,
    required this.dashed,
  });

  final Color color;
  final String label;
  final bool dashed;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 16,
          height: 2,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 5),
        Text(
          label,
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
            fontSize: 10,
          ),
        ),
      ],
    );
  }
}

class _LevelValueRow extends StatelessWidget {
  const _LevelValueRow({required this.level});

  final _PriceLevel level;

  @override
  Widget build(BuildContext context) {
    final muted = Theme.of(context).colorScheme.onSurfaceVariant;

    return Row(
      children: [
        Container(
          width: 18,
          height: 3,
          decoration: BoxDecoration(
            color: level.color,
            borderRadius: BorderRadius.circular(999),
          ),
        ),

        const SizedBox(width: 8),

        Expanded(
          child: Text(
            level.label,
            style: TextStyle(
              color: muted,
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),

        const SizedBox(width: 10),

        Flexible(
          child: Text(
            level.displayValue,
            textAlign: TextAlign.right,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w900),
          ),
        ),
      ],
    );
  }
}
