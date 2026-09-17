import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:trade_pilot_api_client/trade_pilot_api_client.dart';

import '../../l10n/l10n.dart';
import '../../providers/auth_provider.dart';

const _supportedInstruments = {'XAU/USD', 'BRENT', 'HSI', 'NIKKEI'};

bool supportsRiskMap(String instrument) =>
    _supportedInstruments.contains(instrument.trim().toUpperCase());

class RiskToolsSection extends StatelessWidget {
  const RiskToolsSection({
    required this.instrument,
    required this.selectedTimeframe,
    required this.onSelectTimeframe,
    super.key,
  });

  final String instrument;
  final String selectedTimeframe;
  final ValueChanged<String> onSelectTimeframe;

  @override
  Widget build(BuildContext context) {
    if (!supportsRiskMap(instrument)) {
      return const SizedBox.shrink();
    }
    return Column(
      children: [
        const SizedBox(height: 14),
        RiskMapCard(
          instrument: instrument,
          selectedTimeframe: selectedTimeframe,
          onSelectTimeframe: onSelectTimeframe,
        ),
        const SizedBox(height: 10),
        _StandardRulesCard(instrument: instrument),
      ],
    );
  }
}

class RiskMapCard extends StatefulWidget {
  const RiskMapCard({
    required this.instrument,
    required this.selectedTimeframe,
    required this.onSelectTimeframe,
    this.initiallyExpanded = false,
    super.key,
  });

  final String instrument;
  final String selectedTimeframe;
  final ValueChanged<String> onSelectTimeframe;
  final bool initiallyExpanded;

  @override
  State<RiskMapCard> createState() => _RiskMapCardState();
}

class _RiskMapCardState extends State<RiskMapCard> {
  TimeframeRiskMap? _map;
  bool _loading = false;
  bool _failed = false;

  @override
  void didUpdateWidget(covariant RiskMapCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.instrument != widget.instrument) {
      _map = null;
      _failed = false;
    }
  }

  Future<void> _load() async {
    if (_loading) return;
    setState(() {
      _loading = true;
      _failed = false;
    });
    try {
      final response = await context
          .read<AuthProvider>()
          .client
          .analyses
          .getTimeframeRiskMap(instrument: widget.instrument);
      if (!mounted || response.data == null) return;
      setState(() => _map = response.data);
    } catch (_) {
      if (mounted) setState(() => _failed = true);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) => Card(
    clipBehavior: Clip.antiAlias,
    child: ExpansionTile(
      initiallyExpanded: widget.initiallyExpanded,
      leading: const Icon(Icons.monitor_heart_outlined),
      title: Text(
        context.l10n.riskMapTitle,
        style: const TextStyle(fontWeight: FontWeight.w800),
      ),
      subtitle: Text(context.l10n.riskMapDescription),
      onExpansionChanged: (open) {
        if (open && _map == null) unawaited(_load());
      },
      children: [
        const Divider(height: 1),
        Padding(
          padding: const EdgeInsets.all(14),
          child: _riskContent(context),
        ),
      ],
    ),
  );

  @override
  void initState() {
    super.initState();
    if (widget.initiallyExpanded) {
      WidgetsBinding.instance.addPostFrameCallback((_) => unawaited(_load()));
    }
  }

  Widget _riskContent(BuildContext context) {
    if (_loading) {
      return _LoadingLabel(text: context.l10n.riskMapLoading);
    }
    if (_failed || _map == null) {
      return _Retry(text: context.l10n.riskMapError, onPressed: _load);
    }
    final map = _map!;
    final overallWait = map.overall.state.name == 'wait';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: overallWait
                ? const Color(0xFFF59E0B).withValues(alpha: .10)
                : Theme.of(context).colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                overallWait
                    ? context.l10n.riskMapOverallWait
                    : context.l10n.riskMapOverallCompare,
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 3),
              Text(
                _overallReason(context, map.overall.reasonCode),
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        ...map.timeframes.map(
          (risk) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: _RiskRow(
              risk: risk,
              selected: widget.selectedTimeframe == _timeframe(risk.timeframe),
              onSelected: widget.onSelectTimeframe,
            ),
          ),
        ),
        Text(
          context.l10n.riskMapRelativeNote,
          textAlign: TextAlign.center,
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(fontStyle: FontStyle.italic),
        ),
      ],
    );
  }
}

class _RiskRow extends StatelessWidget {
  const _RiskRow({
    required this.risk,
    required this.selected,
    required this.onSelected,
  });

  final TimeframeRisk risk;
  final bool selected;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    final timeframe = _timeframe(risk.timeframe);
    final unavailable =
        risk.status != TimeframeRiskStatusEnum.available ||
        risk.riskCategory == TimeframeRiskRiskCategoryEnum.unavailable;
    final color = _riskColor(risk.riskCategory);
    return Container(
      padding: const EdgeInsets.all(11),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: selected
              ? Theme.of(context).colorScheme.primary
              : color.withValues(alpha: .35),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      timeframe,
                      style: const TextStyle(fontWeight: FontWeight.w900),
                    ),
                    const SizedBox(width: 8),
                    _RiskBadge(
                      text: unavailable
                          ? context.l10n.riskUnavailable
                          : _riskLabel(context, risk.riskCategory),
                      color: color,
                    ),
                  ],
                ),
                const SizedBox(height: 5),
                Text(
                  unavailable
                      ? context.l10n.riskUnavailable
                      : '${risk.riskScore}/100 · ${_recommendation(context, risk.recommendation)}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                if (!unavailable && risk.reasonCodes.isNotEmpty) ...[
                  const SizedBox(height: 3),
                  Text(
                    risk.reasonCodes
                        .map((code) => _reason(context, code))
                        .join(' · '),
                    style: Theme.of(context).textTheme.labelSmall,
                  ),
                ],
              ],
            ),
          ),
          if (!unavailable)
            TextButton(
              onPressed: selected ? null : () => onSelected(timeframe),
              child: Text(
                selected
                    ? context.l10n.riskSelected
                    : context.l10n.useTimeframe(timeframe),
              ),
            ),
        ],
      ),
    );
  }
}

class _StandardRulesCard extends StatefulWidget {
  const _StandardRulesCard({required this.instrument});
  final String instrument;

  @override
  State<_StandardRulesCard> createState() => _StandardRulesCardState();
}

class _StandardRulesCardState extends State<_StandardRulesCard> {
  StandardTradingRules? _rules;
  bool _loading = false;
  bool _failed = false;

  Future<void> _load() async {
    if (_loading || _rules != null) return;
    setState(() {
      _loading = true;
      _failed = false;
    });
    try {
      final response = await context
          .read<AuthProvider>()
          .client
          .tradingRules
          .getStandardTradingRules();
      if (!mounted || response.data == null) return;
      setState(() => _rules = response.data);
    } catch (_) {
      if (mounted) setState(() => _failed = true);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) => Card(
    clipBehavior: Clip.antiAlias,
    child: ExpansionTile(
      leading: const Icon(Icons.verified_user_outlined),
      title: Text(
        context.l10n.standardRulesTitle,
        style: const TextStyle(fontWeight: FontWeight.w800),
      ),
      subtitle: Text(context.l10n.standardRulesDescription),
      onExpansionChanged: (open) {
        if (open) unawaited(_load());
      },
      children: [
        const Divider(height: 1),
        Padding(
          padding: const EdgeInsets.all(14),
          child: _rulesContent(context),
        ),
      ],
    ),
  );

  Widget _rulesContent(BuildContext context) {
    if (_loading) {
      return _LoadingLabel(text: context.l10n.standardRulesLoading);
    }
    final rules = _rules;
    final instrument = rules == null
        ? null
        : _findRule(rules, widget.instrument);
    if (_failed || rules == null || instrument == null) {
      return _Retry(text: context.l10n.standardRulesError, onPressed: _load);
    }
    final account = rules.account;
    final fee = instrument.facilityFeeUsdPerLotPerSide;
    final rows = <(String, String)>[
      (context.l10n.fixedConversionRate, rules.fixedRate.label),
      (
        context.l10n.contractSize,
        '${_number(instrument.contractSize)} ${_contractUnit(instrument.contractUnit)}',
      ),
      (
        context.l10n.tradingSession,
        '${instrument.tradingDays} · ${instrument.tradingHours.summer} / ${instrument.tradingHours.winter}',
      ),
      (
        context.l10n.initialMargin,
        '${_usd(instrument.initialMarginUsdPerLot)} / ${_number(account.minimumLot)} lot',
      ),
      (
        context.l10n.facilityFee,
        fee == null
            ? '—'
            : '${_usd(fee)} / lot / side + VAT ${_number(instrument.vatPercent)}%',
      ),
      (
        context.l10n.rollover,
        '${_usd(instrument.rolloverUsdPerLotPerNight)} / lot / night + VAT ${_number(instrument.vatPercent)}%',
      ),
      (
        context.l10n.spread,
        '${instrument.minimumSpread}–${instrument.maximumSpread}',
      ),
      (context.l10n.hecticSpread, instrument.hecticSpread),
      (context.l10n.minimumMovement, instrument.minimumPriceMovement),
      (context.l10n.limitStopRange, instrument.limitStopRange),
      (
        context.l10n.priceSource,
        '${instrument.priceSource} · ${instrument.priceGuidance}',
      ),
      (context.l10n.settlement, instrument.deliveryBy),
    ];
    final id = Localizations.localeOf(context).languageCode == 'id';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          '${instrument.code} · ${instrument.product} · ${context.l10n.ruleVersion} ${rules.version} · ${rules.effectiveDate}',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _RuleMetric(
                label: context.l10n.allowedLotRange,
                value:
                    '${_number(account.minimumLot)}–${_number(account.maximumLot)} lot',
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _RuleMetric(
                label: context.l10n.minimumDeposit,
                value: _usd(account.minimumDepositUsd),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ...rows.map((row) => _RuleRow(label: row.$1, value: row.$2)),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(11),
          decoration: BoxDecoration(
            color: const Color(0xFFF59E0B).withValues(alpha: .08),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: const Color(0xFFF59E0B).withValues(alpha: .30),
            ),
          ),
          child: Text(
            '${context.l10n.marginControls}: ${account.maintenanceMarginPercent}% / ${account.marginCallBelowPercent}% / ${account.marginCallRestorePercent}% / ${account.autoLiquidationAtOrBelowPercent}%',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          '${context.l10n.sourceDocument}: ${rules.sourceDocument}',
          style: Theme.of(context).textTheme.labelSmall,
        ),
        Text(
          '${context.l10n.profitLossFormula}: ${rules.transactionFormula}',
          style: Theme.of(context).textTheme.labelSmall,
        ),
        const SizedBox(height: 8),
        Text(
          id ? rules.disclaimer.id : rules.disclaimer.en,
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: 5),
        Text(
          id
              ? rules.relationshipDisclosure.id
              : rules.relationshipDisclosure.en,
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }
}

class _RuleMetric extends StatelessWidget {
  const _RuleMetric({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Container(
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
        Text(value, style: const TextStyle(fontWeight: FontWeight.w800)),
      ],
    ),
  );
}

class _RuleRow extends StatelessWidget {
  const _RuleRow({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 5),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Text(label, style: Theme.of(context).textTheme.bodySmall),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
          ),
        ),
      ],
    ),
  );
}

class _RiskBadge extends StatelessWidget {
  const _RiskBadge({required this.text, required this.color});
  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
    decoration: BoxDecoration(
      color: color.withValues(alpha: .12),
      borderRadius: BorderRadius.circular(99),
    ),
    child: Text(
      text,
      style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w800),
    ),
  );
}

class _LoadingLabel extends StatelessWidget {
  const _LoadingLabel({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      const SizedBox.square(
        dimension: 18,
        child: CircularProgressIndicator(strokeWidth: 2),
      ),
      const SizedBox(width: 10),
      Text(text),
    ],
  );
}

class _Retry extends StatelessWidget {
  const _Retry({required this.text, required this.onPressed});
  final String text;
  final Future<void> Function() onPressed;

  @override
  Widget build(BuildContext context) => Column(
    children: [
      Text(text, textAlign: TextAlign.center),
      const SizedBox(height: 8),
      OutlinedButton(onPressed: onPressed, child: Text(context.l10n.tryAgain)),
    ],
  );
}

StandardTradingRuleInstrument? _findRule(
  StandardTradingRules rules,
  String instrument,
) {
  final code = switch (instrument) {
    'XAU/USD' => StandardTradingRuleInstrumentCodeEnum.XUL10,
    'BRENT' => StandardTradingRuleInstrumentCodeEnum.BCO10_BBJ,
    'HSI' => StandardTradingRuleInstrumentCodeEnum.HKK50_BBJ,
    'NIKKEI' => StandardTradingRuleInstrumentCodeEnum.JPK50_BBJ,
    _ => null,
  };
  if (code == null) return null;
  for (final rule in rules.instruments) {
    if (rule.code == code) return rule;
  }
  return null;
}

String _timeframe(TimeframeRiskTimeframeEnum value) => switch (value) {
  TimeframeRiskTimeframeEnum.n15m => '15m',
  TimeframeRiskTimeframeEnum.n1h => '1h',
  TimeframeRiskTimeframeEnum.n4h => '4h',
  TimeframeRiskTimeframeEnum.n1d => '1D',
  TimeframeRiskTimeframeEnum.n1w => '1W',
  _ => value.name,
};

Color _riskColor(TimeframeRiskRiskCategoryEnum value) => switch (value) {
  TimeframeRiskRiskCategoryEnum.low => const Color(0xFF10B981),
  TimeframeRiskRiskCategoryEnum.moderate => const Color(0xFFF59E0B),
  TimeframeRiskRiskCategoryEnum.high => const Color(0xFFEF4444),
  _ => const Color(0xFF8A8580),
};

String _riskLabel(BuildContext context, TimeframeRiskRiskCategoryEnum value) =>
    switch (value) {
      TimeframeRiskRiskCategoryEnum.low => context.l10n.riskLow,
      TimeframeRiskRiskCategoryEnum.moderate => context.l10n.riskModerate,
      TimeframeRiskRiskCategoryEnum.high => context.l10n.riskHigh,
      _ => context.l10n.riskUnavailable,
    };

String _recommendation(
  BuildContext context,
  TimeframeRiskRecommendationEnum value,
) => switch (value) {
  TimeframeRiskRecommendationEnum.eligible => context.l10n.riskEligible,
  TimeframeRiskRecommendationEnum.caution => context.l10n.riskCaution,
  _ => context.l10n.riskWait,
};

String _overallReason(BuildContext context, String code) {
  final id = Localizations.localeOf(context).languageCode == 'id';
  return switch (code) {
    'INSUFFICIENT_TIMEFRAME_DATA' =>
      id
          ? 'Data beberapa timeframe belum cukup. Data kosong bukan berarti risiko rendah.'
          : 'Some timeframes lack enough data. Missing data is never low risk.',
    'NO_ACTIONABLE_SIGNAL' =>
      id
          ? 'Belum ada satu timeframe yang otomatis paling unggul.'
          : 'No single timeframe is automatically best.',
    'RISK_OR_CONFLICT_PRESENT' =>
      id
          ? 'Ada risiko tinggi atau konflik sinyal; menunggu adalah pilihan paling defensif.'
          : 'High risk or conflicting signals are present; waiting is the most defensive choice.',
    _ => context.l10n.riskMapDescription,
  };
}

String _reason(BuildContext context, String code) {
  final id = Localizations.localeOf(context).languageCode == 'id';
  const labels = {
    'SIGNAL_CONFLICT': [
      'Technical signals conflict',
      'Sinyal teknikal bertentangan',
    ],
    'EXTENDED_MOMENTUM': [
      'Price movement is extended',
      'Pergerakan harga sudah memanjang',
    ],
    'RSI_EXTREME': ['RSI is at an extreme', 'RSI berada di area ekstrem'],
    'HIGH_VOLATILITY': [
      'Relative volatility is high',
      'Volatilitas relatif tinggi',
    ],
    'SIGNALS_RELATIVELY_ALIGNED': [
      'Signals are relatively aligned',
      'Sinyal relatif selaras',
    ],
    'DATA_UNAVAILABLE': [
      'Market data is unavailable',
      'Data pasar belum tersedia',
    ],
    'DATA_STALE': ['Market data is stale', 'Data pasar sudah usang'],
    'INSUFFICIENT_HISTORY': [
      'Price history is insufficient',
      'Riwayat harga belum cukup',
    ],
  };
  return labels[code]?[id ? 1 : 0] ?? code.replaceAll('_', ' ').toLowerCase();
}

String _contractUnit(StandardTradingRuleInstrumentContractUnitEnum unit) =>
    switch (unit) {
      StandardTradingRuleInstrumentContractUnitEnum.troyOunce => 'troy ounce',
      StandardTradingRuleInstrumentContractUnitEnum.barrel => 'barrel',
      StandardTradingRuleInstrumentContractUnitEnum.uSDSlashPoint =>
        'USD/point',
      _ => unit.name,
    };

String _usd(num value) => 'USD ${_number(value)}';

String _number(num value) => value % 1 == 0
    ? value.toInt().toString()
    : value
          .toStringAsFixed(2)
          .replaceFirst(RegExp(r'0+$'), '')
          .replaceFirst(RegExp(r'\.$'), '');
