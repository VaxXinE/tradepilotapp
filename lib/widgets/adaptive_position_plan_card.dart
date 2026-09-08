import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:trade_pilot_api_client/trade_pilot_api_client.dart';

import '../core/analysis/adaptive_position_plan.dart';
import '../models/market_models.dart';
import '../providers/auth_provider.dart';

class AdaptivePositionPlanCard extends StatefulWidget {
  const AdaptivePositionPlanCard({
    required this.analysis,
    required this.candles,
    super.key,
  });

  final Analysis analysis;
  final List<MarketCandle> candles;

  @override
  State<AdaptivePositionPlanCard> createState() =>
      _AdaptivePositionPlanCardState();
}

class _AdaptivePositionPlanCardState extends State<AdaptivePositionPlanCard> {
  final _margin = TextEditingController();
  final _loss = TextEditingController();
  StandardTradingRuleInstrument? _rule;
  AdaptiveAccountTier _tier = AdaptiveAccountTier.mini;
  AdaptiveRiskStyle _style = AdaptiveRiskStyle.conservative;
  AdaptiveRecommendation? _recommendation;
  bool _loading = false;
  String? _loadError;
  String _activeSide = 'buy';

  @override
  void dispose() {
    _margin.dispose();
    _loss.dispose();
    super.dispose();
  }

  Future<void> _loadRule() async {
    if (_loading || _rule != null) return;
    setState(() {
      _loading = true;
      _loadError = null;
    });
    try {
      final response = await context
          .read<AuthProvider>()
          .client
          .tradingRules
          .getStandardTradingRules();
      if (!mounted || response.data == null) return;
      setState(() {
        _rule = adaptiveRuleFor(response.data!, widget.analysis.instrument);
        if (_rule == null) _loadError = 'Aturan instrumen tidak tersedia.';
      });
    } catch (_) {
      if (mounted) {
        setState(() => _loadError = 'Aturan trading belum dapat dimuat.');
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _calculate() {
    final rule = _rule;
    if (rule == null) return;
    final movement = RegExp(
      r'\d+(?:\.\d+)?',
    ).firstMatch(rule.minimumPriceMovement)?.group(0);
    final candidates = adaptiveChartCandidates(
      widget.candles,
      widget.analysis.tradePlan!,
      double.tryParse(movement ?? '') ?? .01,
    );
    final result = buildAdaptiveRecommendation(
      analysis: widget.analysis,
      standardRule: rule,
      availableMargin: _number(_margin.text),
      maximumLoss: _number(_loss.text),
      existingExposure: 0,
      accountTier: _tier,
      riskStyle: _style,
      checkpointPrices: candidates,
    );
    setState(() {
      _recommendation = result;
      if (result.preferredSide == 'sell') _activeSide = 'sell';
      if (result.preferredSide == 'buy') _activeSide = 'buy';
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!supportsAdaptivePositionPlan(widget.analysis.instrument) ||
        widget.analysis.tradePlan == null) {
      return const SizedBox.shrink();
    }
    return Card(
      clipBehavior: Clip.antiAlias,
      child: ExpansionTile(
        leading: const Icon(Icons.calculate_outlined),
        title: const Text(
          'Adaptive Position Plan',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        subtitle: const Text(
          'Ubah Standard Plan menjadi ukuran posisi sesuai dana dan batas rugi.',
        ),
        onExpansionChanged: (open) {
          if (open) unawaited(_loadRule());
        },
        children: [
          const Divider(height: 1),
          Padding(padding: const EdgeInsets.all(14), child: _content()),
        ],
      ),
    );
  }

  Widget _content() {
    if (_loading) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    if (_loadError != null || _rule == null) {
      return Column(
        children: [
          Text(_loadError ?? 'Aturan trading tidak tersedia.'),
          const SizedBox(height: 8),
          OutlinedButton(onPressed: _loadRule, child: const Text('Coba lagi')),
        ],
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _Notice(
          'Kalkulator ini tidak mengubah level AI dan tidak mengirim order. '
          'Isi dana bebas yang sudah dikurangi margin posisi lain.',
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _MoneyField(
                controller: _margin,
                label: 'Dana trading tersedia',
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _MoneyField(
                controller: _loss,
                label: 'Batas rugi maksimum',
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        const Text('Tier akun', style: TextStyle(fontWeight: FontWeight.w700)),
        const SizedBox(height: 6),
        SegmentedButton<AdaptiveAccountTier>(
          segments: AdaptiveAccountTier.values
              .map(
                (tier) =>
                    ButtonSegment(value: tier, label: Text(_title(tier.name))),
              )
              .toList(),
          selected: {_tier},
          onSelectionChanged: (value) => setState(() {
            _tier = value.first;
            _recommendation = null;
          }),
        ),
        const SizedBox(height: 12),
        const Text(
          'Gaya risiko',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 6),
        SegmentedButton<AdaptiveRiskStyle>(
          segments: const [
            ButtonSegment(
              value: AdaptiveRiskStyle.conservative,
              label: Text('Konservatif'),
            ),
            ButtonSegment(
              value: AdaptiveRiskStyle.balanced,
              label: Text('Seimbang'),
            ),
            ButtonSegment(
              value: AdaptiveRiskStyle.aggressive,
              label: Text('Agresif'),
            ),
          ],
          selected: {_style},
          onSelectionChanged: (value) => setState(() {
            _style = value.first;
            _recommendation = null;
          }),
        ),
        const SizedBox(height: 14),
        FilledButton.icon(
          onPressed: _calculate,
          icon: const Icon(Icons.calculate_outlined),
          label: const Text('Buat rencana posisi'),
        ),
        if (_recommendation != null) ...[
          const SizedBox(height: 14),
          _Result(
            recommendation: _recommendation!,
            activeSide: _activeSide,
            onSideChanged: (side) => setState(() => _activeSide = side),
          ),
        ],
      ],
    );
  }
}

class _MoneyField extends StatelessWidget {
  const _MoneyField({required this.controller, required this.label});
  final TextEditingController controller;
  final String label;

  @override
  Widget build(BuildContext context) => TextField(
    controller: controller,
    keyboardType: const TextInputType.numberWithOptions(decimal: true),
    decoration: InputDecoration(labelText: label, prefixText: r'$ '),
  );
}

class _Result extends StatelessWidget {
  const _Result({
    required this.recommendation,
    required this.activeSide,
    required this.onSideChanged,
  });
  final AdaptiveRecommendation recommendation;
  final String activeSide;
  final ValueChanged<String> onSideChanged;

  @override
  Widget build(BuildContext context) {
    if (!recommendation.valid) {
      return _Notice(recommendation.errors.join('\n'), warning: true);
    }
    final buy = recommendation.buy;
    final sell = recommendation.sell;
    final shownSide = activeSide == 'sell' && sell != null
        ? 'sell'
        : buy != null
        ? 'buy'
        : 'sell';
    final side = shownSide == 'sell' ? sell : buy;
    if (side == null) return const SizedBox.shrink();
    final posture = switch (recommendation.posture) {
      AdaptivePosture.scalingAllowed => 'Scaling diizinkan',
      AdaptivePosture.entryOnly => 'Entry awal saja',
      AdaptivePosture.notRecommended => 'Tidak direkomendasikan',
    };
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primary.withValues(alpha: .08),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              const Icon(Icons.shield_outlined, size: 19),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '$posture · risiko terpakai ${_money(recommendation.usableRisk)} '
                  '· buffer ${_money(recommendation.unusedRisk)}',
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        SegmentedButton<String>(
          segments: [
            ButtonSegment(
              value: 'buy',
              label: const Text('Buy'),
              enabled: buy != null,
            ),
            ButtonSegment(
              value: 'sell',
              label: const Text('Sell'),
              enabled: sell != null,
            ),
          ],
          selected: {shownSide},
          onSelectionChanged: (value) => onSideChanged(value.first),
        ),
        const SizedBox(height: 10),
        _MetricGrid(side: side),
        const SizedBox(height: 10),
        ...side.layers.indexed.map(
          (item) => _LayerTile(index: item.$1, layer: item.$2),
        ),
        const SizedBox(height: 8),
        const Text(
          'Day trading only. Estimasi tidak memasukkan spread, slippage, fee, '
          'VAT, rollover, atau auto-liquidation broker.',
          style: TextStyle(fontSize: 10.5, fontStyle: FontStyle.italic),
        ),
      ],
    );
  }
}

class _MetricGrid extends StatelessWidget {
  const _MetricGrid({required this.side});
  final AdaptiveSidePlan side;

  @override
  Widget build(BuildContext context) => Wrap(
    spacing: 8,
    runSpacing: 8,
    children: [
      _Metric('Entry', _decimal(side.entry)),
      _Metric('Final SL', _decimal(side.stopLoss), color: Colors.redAccent),
      _Metric('Total lot', _decimal(side.totalLots)),
      _Metric('Margin', _money(side.marginRequired)),
      _Metric('Rugi ke SL', _money(side.estimatedLoss)),
      if (side.takeProfit1 != null)
        _Metric(
          'TP1 / profit',
          '${_decimal(side.takeProfit1!)}\n+${_money(side.profitToTp1)}',
          color: Colors.green,
        ),
      if (side.takeProfit2 != null)
        _Metric(
          'TP2 / profit',
          '${_decimal(side.takeProfit2!)}\n+${_money(side.profitToTp2)}',
          color: Colors.green,
        ),
    ],
  );
}

class _Metric extends StatelessWidget {
  const _Metric(this.label, this.value, {this.color});
  final String label;
  final String value;
  final Color? color;

  @override
  Widget build(BuildContext context) => Container(
    width: (MediaQuery.sizeOf(context).width - 70) / 2,
    padding: const EdgeInsets.all(10),
    decoration: BoxDecoration(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(10),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: Theme.of(context).textTheme.labelSmall),
        const SizedBox(height: 3),
        Text(
          value,
          style: TextStyle(fontWeight: FontWeight.w800, color: color),
        ),
      ],
    ),
  );
}

class _LayerTile extends StatelessWidget {
  const _LayerTile({required this.index, required this.layer});
  final int index;
  final AdaptiveLayer layer;

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 7),
    padding: const EdgeInsets.all(11),
    decoration: BoxDecoration(
      border: Border.all(color: Theme.of(context).dividerColor),
      borderRadius: BorderRadius.circular(11),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Posisi ${index + 1}${index == 0 ? ' · Entry awal' : ' · Checkpoint manual'}',
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 5),
        Text('${_decimal(layer.price)} · ${_decimal(layer.lot)} lot'),
        const SizedBox(height: 3),
        Text(
          'Kumulatif: ${_decimal(layer.cumulativeLots)} lot · '
          'margin ${_money(layer.cumulativeMargin)} · '
          'risiko ${_money(layer.cumulativeRisk)}',
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    ),
  );
}

class _Notice extends StatelessWidget {
  const _Notice(this.text, {this.warning = false});
  final String text;
  final bool warning;

  @override
  Widget build(BuildContext context) {
    final color = warning ? Colors.redAccent : const Color(0xFFF59E0B);
    return Container(
      padding: const EdgeInsets.all(11),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .09),
        border: Border.all(color: color.withValues(alpha: .35)),
        borderRadius: BorderRadius.circular(11),
      ),
      child: Text(text, style: const TextStyle(fontSize: 11.5, height: 1.4)),
    );
  }
}

double? _number(String value) =>
    double.tryParse(value.trim().replaceAll(',', '.'));
String _title(String value) => '${value[0].toUpperCase()}${value.substring(1)}';
String _money(double? value) => value == null
    ? '—'
    : NumberFormat.currency(symbol: r'$', decimalDigits: 2).format(value);
String _decimal(double value) => NumberFormat('0.####').format(value);
