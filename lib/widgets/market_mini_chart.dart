import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/market_models.dart';

class MarketMiniChart extends StatelessWidget {
  const MarketMiniChart({
    super.key,
    required this.candles,
    required this.accentColor,
    this.isLoading = false,
  });

  final List<MarketCandle> candles;
  final Color accentColor;
  final bool isLoading;

  static const int _maxVisibleCandles = 80;

  @override
  Widget build(BuildContext context) {
    if (isLoading && candles.isEmpty) {
      return const SizedBox(
        height: 180,
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (candles.length < 2) {
      return SizedBox(
        height: 180,
        child: Center(
          child: Text(
            'Data chart belum tersedia',
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              fontSize: 12.5,
            ),
          ),
        ),
      );
    }

    final visible = candles.length > _maxVisibleCandles
        ? candles.sublist(candles.length - _maxVisibleCandles)
        : candles;

    final spots = <FlSpot>[
      for (var i = 0; i < visible.length; i++)
        FlSpot(i.toDouble(), visible[i].close),
    ];

    var minPrice = visible.first.low;
    var maxPrice = visible.first.high;

    for (final candle in visible.skip(1)) {
      minPrice = math.min(minPrice, candle.low);

      maxPrice = math.max(maxPrice, candle.high);
    }

    final range = maxPrice - minPrice;

    final padding = range > 0
        ? range * 0.08
        : math.max(maxPrice.abs() * 0.002, 0.01);

    final textColor = Theme.of(context).colorScheme.onSurface;

    return SizedBox(
      height: 180,
      child: LineChart(
        LineChartData(
          minX: 0,
          maxX: (visible.length - 1).toDouble(),
          minY: minPrice - padding,
          maxY: maxPrice + padding,
          gridData: const FlGridData(show: false),
          titlesData: const FlTitlesData(show: false),
          borderData: FlBorderData(show: false),
          lineTouchData: LineTouchData(
            enabled: true,
            touchTooltipData: LineTouchTooltipData(
              getTooltipItems: (touchedSpots) {
                return touchedSpots.map((spot) {
                  var index = spot.x.round();

                  if (index < 0) {
                    index = 0;
                  }

                  if (index >= visible.length) {
                    index = visible.length - 1;
                  }

                  final candle = visible[index];

                  final date = DateFormat(
                    'd MMM HH:mm',
                  ).format(candle.date.toLocal());

                  return LineTooltipItem(
                    '${_formatPrice(candle.close)}\n$date',
                    TextStyle(
                      color: textColor,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  );
                }).toList();
              },
            ),
          ),
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              barWidth: 2.2,
              color: accentColor,
              dotData: const FlDotData(show: false),
              belowBarData: BarAreaData(
                show: true,
                color: accentColor.withValues(alpha: 0.08),
              ),
            ),
          ],
        ),
      ),
    );
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
