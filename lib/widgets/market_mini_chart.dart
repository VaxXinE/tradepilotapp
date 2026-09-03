import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';
import '../l10n/l10n.dart';
import '../models/market_models.dart';

class MarketMiniChart extends StatelessWidget {
  const MarketMiniChart({
    super.key,
    required this.candles,
    this.technical,
    this.currentPrice,
    this.error,
    this.isLoading = false,
  });

  final List<MarketCandle> candles;
  final BeginnerTechnicalSnapshot? technical;
  final double? currentPrice;
  final String? error;
  final bool isLoading;

  static const int _maxVisibleCandles = 100;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    if (isLoading && candles.isEmpty) {
      return const SizedBox(
        height: 240,
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (candles.isEmpty) {
      return SizedBox(
        height: 180,
        child: Center(
          child: Text(
            error ?? l10n.chartDataUnavailable,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      );
    }

    final visible = candles.length > _maxVisibleCandles
        ? candles.sublist(candles.length - _maxVisibleCandles)
        : candles;
    final support = visible.map((item) => item.low).reduce(math.min);
    final resistance = visible.map((item) => item.high).reduce(math.max);
    final latest = currentPrice ?? visible.last.close;
    final bullish = technical?.bullish ?? latest >= visible.first.open;
    final bearish = technical?.bearish ?? latest < visible.first.open;
    final rangePercent = latest == 0
        ? 0.0
        : ((resistance - support) / latest).abs() * 100;
    final risk = rangePercent >= 5
        ? l10n.high
        : rangePercent >= 2
        ? l10n.medium
        : l10n.low;
    final colors = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              '${l10n.trend}: ${bullish
                  ? l10n.bullishBias
                  : bearish
                  ? l10n.bearishBias
                  : l10n.neutral}',
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
            const Spacer(),
            Tooltip(
              message: l10n.historicalLevelsDisclaimer,
              child: Icon(
                Icons.help_outline_rounded,
                size: 18,
                color: colors.onSurfaceVariant,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 240,
          child: LayoutBuilder(
            builder: (context, constraints) => CandlestickPlot(
              candles: visible,
              levels: [
                MarketChartLevel(
                  value: resistance,
                  label: 'Resistance',
                  color: colors.onSurfaceVariant.withValues(alpha: 0.82),
                ),
                MarketChartLevel(
                  value: support,
                  label: 'Support',
                  color: colors.onSurfaceVariant.withValues(alpha: 0.62),
                ),
                MarketChartLevel(
                  value: latest,
                  label: l10n.currentPrice(''),
                  color: colors.primary,
                ),
              ],
              width: constraints.maxWidth,
              height: constraints.maxHeight,
            ),
          ),
        ),
        if (error != null) ...[
          const SizedBox(height: 8),
          Text(error!, style: TextStyle(color: colors.error, fontSize: 12)),
        ],
        const SizedBox(height: 10),
        Text(
          l10n.candlestickHelp,
          style: TextStyle(color: colors.onSurfaceVariant, fontSize: 11),
        ),
        const SizedBox(height: 4),
        Text(
          l10n.movementRisk(risk),
          style: TextStyle(color: colors.onSurfaceVariant, fontSize: 11),
        ),
      ],
    );
  }
}

class MarketChartLevel {
  const MarketChartLevel({
    required this.value,
    required this.label,
    required this.color,
    this.dashed = false,
  });

  final double value;
  final String label;
  final Color color;
  final bool dashed;
}

class CandlestickPlot extends StatefulWidget {
  const CandlestickPlot({
    super.key,
    required this.candles,
    required this.levels,
    required this.width,
    required this.height,
    this.cutoffIndex,
  });

  final List<MarketCandle> candles;
  final List<MarketChartLevel> levels;
  final double width;
  final double height;
  final int? cutoffIndex;

  @override
  State<CandlestickPlot> createState() => _CandlestickPlotState();
}

class _CandlestickPlotState extends State<CandlestickPlot> {
  int? _selectedIndex;

  @override
  Widget build(BuildContext context) {
    final candles = widget.candles;
    final levels = widget.levels;
    final width = widget.width;
    final height = widget.height;
    final colors = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final chartText = isDark
        ? AppColors.chartTextDark
        : AppColors.chartTextLight;
    final chartGrid = isDark
        ? AppColors.chartGridDark
        : AppColors.chartGridLight;
    final railWidth = width < 340 ? 100.0 : 108.0;
    final chartWidth = math.max(width - railWidth - 8, 1.0);
    const axisHeight = 20.0;
    const labelHeight = 22.0;
    var plotMin = candles.map((item) => item.low).reduce(math.min);
    var plotMax = candles.map((item) => item.high).reduce(math.max);
    for (final level in levels) {
      plotMin = math.min(plotMin, level.value);
      plotMax = math.max(plotMax, level.value);
    }
    final rawRange = math.max(plotMax - plotMin, 0.000001);
    plotMin -= rawRange * .06;
    plotMax += rawRange * .06;
    final range = math.max(plotMax - plotMin, 0.000001);
    final slotWidth = chartWidth / candles.length;
    final bodyWidth = math.max(math.min(slotWidth * 0.58, 8.0), 2.0);
    double topFor(double value) =>
        ((plotMax - value) / range * (height - axisHeight - 16)) + 8;

    final lineTops = levels.map((item) => topFor(item.value)).toList();
    final labelTops = _spreadLabelTops(
      lineTops,
      height - axisHeight,
      labelHeight,
    );

    final plot = ClipRect(
      child: Stack(
        children: [
          Positioned(
            top: 0,
            right: 0,
            bottom: axisHeight,
            width: railWidth,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: colors.surfaceContainerHighest.withValues(alpha: .32),
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
          for (var grid = 1; grid < 5; grid++)
            Positioned(
              top: grid * (height - axisHeight) / 5,
              left: 0,
              width: chartWidth,
              child: Divider(
                height: 1,
                color: chartGrid.withValues(alpha: .08),
              ),
            ),
          for (var grid = 1; grid < 4; grid++)
            Positioned(
              left: grid * chartWidth / 4,
              top: 4,
              bottom: axisHeight,
              child: VerticalDivider(
                width: 1,
                color: chartGrid.withValues(alpha: .08),
              ),
            ),
          if (widget.cutoffIndex != null)
            Positioned(
              left:
                  (widget.cutoffIndex!.clamp(0, candles.length - 1) + .5) *
                  slotWidth,
              top: 4,
              bottom: axisHeight,
              child: Container(
                width: 1,
                color: chartText.withValues(alpha: .55),
              ),
            ),
          for (var index = 0; index < candles.length; index++)
            Positioned(
              left: index * slotWidth + (slotWidth - bodyWidth) / 2,
              top: topFor(candles[index].high),
              width: bodyWidth,
              height: math.max(
                topFor(candles[index].low) - topFor(candles[index].high),
                1.0,
              ),
              child: _Candle(
                key: ValueKey(
                  '${candles[index].bullish ? 'bullish' : 'bearish'}-candle-$index',
                ),
                candle: candles[index],
                topFor: topFor,
                plotTop: topFor(candles[index].high),
                bullishColor: AppColors.takeProfit,
                bearishColor: AppColors.stopLoss,
              ),
            ),
          for (var index = 0; index < levels.length; index++) ...[
            Positioned(
              top: lineTops[index],
              left: 0,
              width: chartWidth,
              child: _ChartLine(
                color: levels[index].color,
                dashed: levels[index].dashed,
              ),
            ),
            Positioned(
              top: labelTops[index],
              right: 0,
              width: railWidth,
              child: _LevelBadge(height: labelHeight, level: levels[index]),
            ),
          ],
          Positioned(
            left: 0,
            right: railWidth + 8,
            bottom: 0,
            height: axisHeight,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _AxisLabel(candles.first.date),
                _AxisLabel(candles[candles.length ~/ 2].date),
                _AxisLabel(candles.last.date),
              ],
            ),
          ),
          if (_selectedIndex case final selected?) ...[
            Positioned(
              left: (selected + .5) * slotWidth,
              top: 4,
              bottom: axisHeight,
              child: Container(
                width: 1,
                color: chartText.withValues(alpha: .55),
              ),
            ),
            Positioned(
              left: 0,
              top: topFor(candles[selected].close),
              width: chartWidth,
              child: Divider(
                height: 1,
                thickness: 1,
                color: chartText.withValues(alpha: .4),
              ),
            ),
            Positioned(
              left: math.min(
                math.max((selected + .5) * slotWidth - 62, 4),
                math.max(chartWidth - 128, 4),
              ),
              top: math.max(topFor(candles[selected].high) - 54, 4),
              width: 124,
              child: _CandleTooltip(candle: candles[selected]),
            ),
          ],
        ],
      ),
    );

    void select(Offset position) {
      if (position.dx < 0 || position.dx > chartWidth) return;
      final index = (position.dx / slotWidth).floor().clamp(
        0,
        candles.length - 1,
      );
      if (_selectedIndex != index) setState(() => _selectedIndex = index);
    }

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onLongPressStart: (details) => select(details.localPosition),
      onLongPressMoveUpdate: (details) => select(details.localPosition),
      onLongPressEnd: (_) => setState(() => _selectedIndex = null),
      child: plot,
    );
  }

  List<double> _spreadLabelTops(
    List<double> lineTops,
    double chartHeight,
    double labelHeight,
  ) {
    final result = List<double>.filled(lineTops.length, 0);
    final order = List<int>.generate(lineTops.length, (index) => index)
      ..sort((a, b) => lineTops[a].compareTo(lineTops[b]));
    var next = 0.0;
    for (final index in order) {
      final top = math.max(lineTops[index] - labelHeight / 2, next);
      result[index] = top;
      next = top + labelHeight + 2;
    }
    final overflow = next - 1 - chartHeight;
    if (overflow > 0) {
      for (final index in order) {
        result[index] = math.max(0, result[index] - overflow);
      }
    }
    return result;
  }
}

class _LevelBadge extends StatelessWidget {
  const _LevelBadge({required this.height, required this.level});

  final double height;
  final MarketChartLevel level;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final price = _formatPrice(level.value);

    return Semantics(
      label: '${level.label} $price',
      child: Container(
        height: height,
        padding: const EdgeInsets.fromLTRB(7, 0, 6, 0),
        decoration: BoxDecoration(
          color: Color.alphaBlend(
            level.color.withValues(alpha: .2),
            colors.surfaceContainerHighest,
          ),
          border: Border(left: BorderSide(color: level.color, width: 3)),
          borderRadius: BorderRadius.circular(5),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                level.label.trim(),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: level.color,
                  fontSize: 8.5,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            const SizedBox(width: 3),
            Text(
              price,
              style: TextStyle(
                color: colors.onSurface,
                fontSize: 8.5,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AxisLabel extends StatelessWidget {
  const _AxisLabel(this.date);

  final DateTime date;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Text(
      '${date.day}/${date.month}',
      style: TextStyle(
        color: isDark ? AppColors.chartTextDark : AppColors.chartTextLight,
        fontSize: 9,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}

class _CandleTooltip extends StatelessWidget {
  const _CandleTooltip({required this.candle});

  final MarketCandle candle;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Container(
      key: const ValueKey('chart-price-tooltip'),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: colors.inverseSurface,
        borderRadius: BorderRadius.circular(7),
        boxShadow: const [
          BoxShadow(
            color: AppColors.chartShadow,
            blurRadius: 8,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${candle.date.day}/${candle.date.month}/${candle.date.year}',
            style: TextStyle(
              color: colors.onInverseSurface.withValues(alpha: .72),
              fontSize: 8,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            'O ${_formatPrice(candle.open)}  H ${_formatPrice(candle.high)}\n'
            'L ${_formatPrice(candle.low)}  C ${_formatPrice(candle.close)}',
            style: TextStyle(
              color: colors.onInverseSurface,
              fontSize: 9,
              height: 1.35,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _Candle extends StatelessWidget {
  const _Candle({
    super.key,
    required this.candle,
    required this.topFor,
    required this.plotTop,
    required this.bullishColor,
    required this.bearishColor,
  });

  final MarketCandle candle;
  final double Function(double value) topFor;
  final double plotTop;
  final Color bullishColor;
  final Color bearishColor;

  @override
  Widget build(BuildContext context) {
    final color = candle.bullish ? bullishColor : bearishColor;
    final openTop = topFor(candle.open) - plotTop;
    final closeTop = topFor(candle.close) - plotTop;
    final bodyTop = math.min(openTop, closeTop);
    final bodyHeight = math.max((openTop - closeTop).abs(), 2.0);

    return Semantics(
      label: candle.bullish ? 'Candlestick bullish' : 'Candlestick bearish',
      child: Stack(
        children: [
          Positioned.fill(
            child: Center(child: Container(width: 1, color: color)),
          ),
          Positioned(
            top: bodyTop,
            left: 0,
            right: 0,
            height: bodyHeight,
            child: ColoredBox(color: color),
          ),
        ],
      ),
    );
  }
}

class _ChartLine extends StatelessWidget {
  const _ChartLine({required this.color, required this.dashed});
  final Color color;
  final bool dashed;

  @override
  Widget build(BuildContext context) => dashed
      ? Row(
          children: List.generate(
            24,
            (_) => Expanded(
              child: Container(
                height: 1.5,
                margin: const EdgeInsets.only(right: 3),
                color: color,
              ),
            ),
          ),
        )
      : Divider(height: 1.5, thickness: 1.5, color: color);
}

String _formatPrice(double value) {
  if (value.abs() >= 100) {
    return value.toStringAsFixed(2);
  }
  if (value.abs() >= 1) {
    return value.toStringAsFixed(4);
  }
  return value.toStringAsFixed(6);
}
