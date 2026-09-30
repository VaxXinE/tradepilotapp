import 'package:flutter/material.dart';
import 'package:trade_pilot_api_client/trade_pilot_api_client.dart';

import '../core/theme/app_colors.dart';
import '../models/market_models.dart';
import 'market_mini_chart.dart';
import '../l10n/l10n.dart';

/// Skenario level yang ditampilkan di atas chart — menyamai toggle
/// BUY/SELL/Keduanya pada web, bukan cuma otomatis mengikuti bias.
enum ChartLevelScenario { buy, sell, both }

class AnalysisLevelsChart extends StatefulWidget {
  const AnalysisLevelsChart({
    super.key,
    required this.candles,
    this.tradePlan,
    this.tradingBias,
    this.currentPrice,
    this.isLoading = false,
  });

  final List<MarketCandle> candles;
  final TradePlan? tradePlan;
  final String? tradingBias;
  final double? currentPrice;

  final bool isLoading;

  @override
  State<AnalysisLevelsChart> createState() => _AnalysisLevelsChartState();
}

class _AnalysisLevelsChartState extends State<AnalysisLevelsChart> {
  static const int _maxCandles = 48;

  late ChartLevelScenario _scenario = _defaultScenario(widget.tradingBias);

  static ChartLevelScenario _defaultScenario(String? tradingBias) {
    final bias = (tradingBias ?? '').trim().toLowerCase();
    if (bias.contains('bull') || bias == 'buy' || bias == 'strong_buy') {
      return ChartLevelScenario.buy;
    }
    if (bias.contains('bear') || bias == 'sell' || bias == 'strong_sell') {
      return ChartLevelScenario.sell;
    }
    return ChartLevelScenario.both;
  }

  @override
  void didUpdateWidget(covariant AnalysisLevelsChart oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Timeframe/analisis baru bisa membawa bias baru — ikuti default bias
    // yang baru, kecuali user sudah memilih skenario secara manual untuk
    // analisis yang sama (tradingBias tidak berubah).
    if (oldWidget.tradingBias != widget.tradingBias) {
      _scenario = _defaultScenario(widget.tradingBias);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isLoading && widget.candles.isEmpty) {
      return const SizedBox(
        height: 240,
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (widget.candles.length < 2) {
      return SizedBox(
        height: 180,
        child: Center(
          child: Text(
            context.l10n.chartDataUnavailable,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              fontSize: 12.5,
            ),
          ),
        ),
      );
    }

    final candles = widget.candles;
    final visible = candles.length > _maxCandles
        ? candles.sublist(candles.length - _maxCandles)
        : List<MarketCandle>.of(candles);
    final live = widget.currentPrice;
    if (live != null && live.isFinite && live > 0) {
      final last = visible.last;
      visible[visible.length - 1] = MarketCandle(
        date: last.date,
        open: last.open,
        high: live > last.high ? live : last.high,
        low: live < last.low ? live : last.low,
        close: live,
      );
    }

    final levels = _buildLevels(widget.tradePlan, _scenario);
    final hasLive = live != null && live.isFinite && live > 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.tradePlan != null) ...[
          _ScenarioTabs(
            selected: _scenario,
            onSelected: (value) => setState(() => _scenario = value),
          ),
          const SizedBox(height: 10),
        ],
        SizedBox(
          height: 304,
          child: LayoutBuilder(
            builder: (context, constraints) => CandlestickPlot(
              candles: visible,
              levels: [
                ...levels.map(
                  (level) => MarketChartLevel(
                    value: level.price,
                    label: level.label,
                    color: level.color,
                    dashed: level.dashed,
                  ),
                ),
                if (live != null && hasLive)
                  MarketChartLevel(
                    value: live,
                    label: 'Live',
                    color: AppColors.entry,
                    dashed: true,
                  ),
              ],
              isLive: hasLive,
              width: constraints.maxWidth,
              height: constraints.maxHeight,
            ),
          ),
        ),
      ],
    );
  }

  List<_PriceLevel> _buildLevels(TradePlan? plan, ChartLevelScenario scenario) {
    if (plan == null) {
      return const [];
    }

    final result = <_PriceLevel>[];

    void addSide(String name, TradeSide side) {
      final values = [
        (
          'Entry',
          side.entryZone,
          name == 'BUY' ? AppColors.buyEntry : AppColors.sellEntry,
          true,
        ),
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

    switch (scenario) {
      case ChartLevelScenario.buy:
        addSide('BUY', plan.buy);
      case ChartLevelScenario.sell:
        addSide('SELL', plan.sell);
      case ChartLevelScenario.both:
        addSide('BUY', plan.buy);
        addSide('SELL', plan.sell);
    }

    return result;
  }

  double? _parsePriceLevel(String raw) {
    final cleaned = raw
        .replaceAll(RegExp(r'\b[HMDWhmdw]\d{1,3}\b'), ' ')
        .replaceAll(RegExp(r'\b\d{1,3}[mhdwMHDW]\b'), ' ');
    final matches = RegExp(r'\d[\d.,]*').allMatches(cleaned);

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

class _ScenarioTabs extends StatelessWidget {
  const _ScenarioTabs({required this.selected, required this.onSelected});

  final ChartLevelScenario selected;
  final ValueChanged<ChartLevelScenario> onSelected;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: colors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: colors.outlineVariant),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _ScenarioTab(
            label: context.l10n.buy,
            active: selected == ChartLevelScenario.buy,
            onTap: () => onSelected(ChartLevelScenario.buy),
          ),
          _ScenarioTab(
            label: context.l10n.sell,
            active: selected == ChartLevelScenario.sell,
            onTap: () => onSelected(ChartLevelScenario.sell),
          ),
          _ScenarioTab(
            label: context.l10n.chartScenarioBoth,
            active: selected == ChartLevelScenario.both,
            onTap: () => onSelected(ChartLevelScenario.both),
          ),
        ],
      ),
    );
  }
}

class _ScenarioTab extends StatelessWidget {
  const _ScenarioTab({
    required this.label,
    required this.active,
    required this.onTap,
  });

  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Semantics(
      button: true,
      selected: active,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Container(
          constraints: const BoxConstraints(minHeight: 36),
          padding: const EdgeInsets.symmetric(horizontal: 14),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: active ? colors.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: active ? colors.onPrimary : colors.onSurfaceVariant,
            ),
          ),
        ),
      ),
    );
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
