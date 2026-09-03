import 'package:flutter/material.dart';
import 'package:trade_pilot_api_client/trade_pilot_api_client.dart';

import '../core/theme/app_colors.dart';
import '../models/market_models.dart';
import 'market_mini_chart.dart';

class AnalysisLevelsChart extends StatelessWidget {
  const AnalysisLevelsChart({
    super.key,
    required this.candles,
    this.tradePlan,
    this.tradingBias,
    this.isLoading = false,
  });

  final List<MarketCandle> candles;
  final TradePlan? tradePlan;
  final String? tradingBias;

  final bool isLoading;

  static const int _maxCandles = 48;

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

    final levels = _buildLevels(tradePlan, tradingBias);

    return SizedBox(
      height: 304,
      child: LayoutBuilder(
        builder: (context, constraints) => CandlestickPlot(
          candles: visible,
          levels: levels
              .map(
                (level) => MarketChartLevel(
                  value: level.price,
                  label: level.label,
                  color: level.color,
                  dashed: level.dashed,
                ),
              )
              .toList(),
          width: constraints.maxWidth,
          height: constraints.maxHeight,
        ),
      ),
    );
  }

  List<_PriceLevel> _buildLevels(TradePlan? plan, String? tradingBias) {
    if (plan == null) {
      return const [];
    }

    final result = <_PriceLevel>[];

    void addSide(String name, TradeSide side) {
      final values = [
        ('Entry', side.entryZone, AppColors.entry, true),
        ('SL', side.stopLoss, AppColors.stopLoss, false),
        ('TP1', side.takeProfit1, AppColors.takeProfit, false),
        ('TP2', side.takeProfit2, AppColors.takeProfit, false),
      ];
      for (final value in values) {
        final price = _parsePriceLevel(value.$2);
        if (price != null) {
          result.add(
            _PriceLevel(
              label: '$name ${value.$1}',
              price: price,
              color: value.$3,
              dashed: value.$4,
            ),
          );
        }
      }
    }

    final bias = (tradingBias ?? '').trim().toLowerCase();
    final bullish =
        bias.contains('bull') || bias == 'buy' || bias == 'strong_buy';
    final bearish =
        bias.contains('bear') || bias == 'sell' || bias == 'strong_sell';

    if (bullish) {
      addSide('BUY', plan.buy);
    } else if (bearish) {
      addSide('SELL', plan.sell);
    } else {
      addSide('BUY', plan.buy);
      addSide('SELL', plan.sell);
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
}
