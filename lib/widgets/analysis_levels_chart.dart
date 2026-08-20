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

        Wrap(
          spacing: 12,
          runSpacing: 8,
          children: [
            if (cutoffIndex != null)
              _LegendItem(
                color: muted,
                label: 'AI membuat analisis',
                dashed: true,
              ),
            for (final level in levels)
              _LegendItem(
                color: level.color,
                label: level.label,
                dashed: level.dashed,
              ),
          ],
        ),

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

    const takeProfit = Color(0xFF16A34A);

    final result = <_PriceLevel>[];

    final entry = _parsePriceLevel(side.entryZone);

    final sl = _parsePriceLevel(side.stopLoss);

    final tp1 = _parsePriceLevel(side.takeProfit1);

    final tp2 = _parsePriceLevel(side.takeProfit2);

    if (entry != null) {
      result.add(
        _PriceLevel(
          label: '${isBuy ? 'BUY' : 'SELL'} Entry',
          price: entry,
          color: primary,
          dashed: true,
        ),
      );
    }

    if (sl != null) {
      result.add(
        _PriceLevel(label: 'Stop Loss', price: sl, color: error, dashed: false),
      );
    }

    if (tp1 != null) {
      result.add(
        const _PriceLevel(
          label: 'TP1',
          price: 0,
          color: takeProfit,
          dashed: false,
        ).copyWith(price: tp1),
      );
    }

    if (tp2 != null) {
      result.add(
        const _PriceLevel(
          label: 'TP2',
          price: 0,
          color: takeProfit,
          dashed: false,
        ).copyWith(price: tp2),
      );
    }

    return result;
  }

  double? _parsePriceLevel(String raw) {
    final matches = RegExp(r'\d+(?:[.,]\d+)?').allMatches(raw).toList();

    if (matches.isEmpty) {
      return null;
    }

    final values = <double>[];

    for (final match in matches) {
      final value = double.tryParse(match.group(0)!.replaceAll(',', '.'));

      if (value != null && value.isFinite && value > 0) {
        values.add(value);
      }
    }

    if (values.isEmpty) {
      return null;
    }

    if (values.length == 1) {
      return values.first;
    }

    return (values[0] + values[1]) / 2;
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
    required this.color,
    required this.dashed,
  });

  final String label;
  final double price;
  final Color color;
  final bool dashed;

  _PriceLevel copyWith({double? price}) {
    return _PriceLevel(
      label: label,
      price: price ?? this.price,
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
