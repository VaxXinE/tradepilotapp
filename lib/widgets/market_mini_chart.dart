import 'dart:math' as math;

import 'package:flutter/material.dart';

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
            error ?? 'Data chart belum tersedia.',
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
        ? 'Tinggi'
        : rangePercent >= 2
        ? 'Sedang'
        : 'Rendah';
    final colors = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Tren: ${bullish
                  ? 'Cenderung bullish'
                  : bearish
                  ? 'Cenderung bearish'
                  : 'Netral'}',
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
            const Spacer(),
            Tooltip(
              message:
                  'Level pada chart adalah referensi historis, bukan rekomendasi transaksi.',
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
            builder: (context, constraints) => _CandlePlot(
              candles: visible,
              support: support,
              resistance: resistance,
              currentPrice: latest,
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
          'Candlestick: hijau = harga naik, merah = harga turun.',
          style: TextStyle(color: colors.onSurfaceVariant, fontSize: 11),
        ),
        const SizedBox(height: 4),
        Text(
          'Risiko pergerakan: $risk. Support dan resistance adalah level referensi dari data yang terlihat.',
          style: TextStyle(color: colors.onSurfaceVariant, fontSize: 11),
        ),
      ],
    );
  }
}

class _CandlePlot extends StatelessWidget {
  const _CandlePlot({
    required this.candles,
    required this.support,
    required this.resistance,
    required this.currentPrice,
    required this.width,
    required this.height,
  });

  final List<MarketCandle> candles;
  final double support;
  final double resistance;
  final double currentPrice;
  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final chartWidth = math.max(width - 98, 1.0);
    final plotMin = math.min(support, currentPrice);
    final plotMax = math.max(resistance, currentPrice);
    final range = math.max(plotMax - plotMin, 0.000001);
    final slotWidth = chartWidth / candles.length;
    final bodyWidth = math.max(math.min(slotWidth * 0.58, 8.0), 2.0);
    double topFor(double value) =>
        ((plotMax - value) / range * (height - 32)) + 8;

    return ClipRect(
      child: Stack(
        children: [
          _ReferenceLine(
            top: topFor(resistance),
            label: 'Resistance ${_formatPrice(resistance)}',
            color: colors.tertiary,
          ),
          _ReferenceLine(
            top: topFor(support),
            label: 'Support ${_formatPrice(support)}',
            color: colors.secondary,
          ),
          _ReferenceLine(
            top: topFor(currentPrice),
            label: 'Saat ini ${_formatPrice(currentPrice)}',
            color: colors.primary,
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
                bullishColor: colors.primary,
                bearishColor: colors.error,
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

class _ReferenceLine extends StatelessWidget {
  const _ReferenceLine({
    required this.top,
    required this.label,
    required this.color,
  });

  final double top;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: top,
      left: 0,
      right: 0,
      child: Row(
        children: [
          Expanded(child: Divider(height: 1, color: color)),
          const SizedBox(width: 4),
          SizedBox(
            width: 94,
            child: Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 9,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
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
