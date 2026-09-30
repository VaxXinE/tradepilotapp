import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:trade_pilot_api_client/trade_pilot_api_client.dart';

import '../core/analysis/adaptive_position_plan.dart';
import 'analysis_levels_chart.dart';
import '../models/market_models.dart';
import '../services/adaptive_plan_report.dart';
import '../providers/auth_provider.dart';
import '../l10n/l10n.dart';

class AdaptivePositionPlanCard extends StatefulWidget {
  const AdaptivePositionPlanCard({
    required this.analysis,
    required this.candles,
    required this.onLearn,
    super.key,
  });

  final Analysis analysis;
  final List<MarketCandle> candles;
  final VoidCallback onLearn;

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
  void initState() {
    super.initState();
    _margin.addListener(_onMoneyChanged);
    _loss.addListener(_onMoneyChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) unawaited(_loadRule());
    });
  }

  @override
  void dispose() {
    _margin.removeListener(_onMoneyChanged);
    _loss.removeListener(_onMoneyChanged);
    _margin.dispose();
    _loss.dispose();
    super.dispose();
  }

  void _onMoneyChanged() {
    if (mounted) setState(() => _recommendation = null);
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
        if (_rule == null) _loadError = context.l10n.instrumentRulesUnavailable;
      });
    } catch (_) {
      if (mounted) {
        setState(() => _loadError = context.l10n.tradingRulesLoadFailed);
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

  Future<void> _showDetails() => showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _AdaptiveDetailsSheet(
      analysis: widget.analysis,
      candles: widget.candles,
      rule: _rule,
      tier: _tier,
      style: _style,
      recommendation: _recommendation,
      onLearn: widget.onLearn,
    ),
  );

  @override
  Widget build(BuildContext context) {
    if (!supportsAdaptivePositionPlan(widget.analysis.instrument) ||
        widget.analysis.tradePlan == null) {
      return const SizedBox.shrink();
    }
    return Card(
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.all(18),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.calculate_outlined,
                  color: Theme.of(context).colorScheme.primary,
                  size: 22,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        context.l10n.adaptiveTradingPlan,
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        context.l10n.adaptiveTradingPlanSubtitle,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Padding(padding: const EdgeInsets.all(18), child: _content()),
        ],
      ),
    );
  }

  Widget _content() {
    if (_loading) {
      return Column(
        children: [
          const Padding(
            padding: EdgeInsets.all(16),
            child: Center(child: CircularProgressIndicator()),
          ),
          const SizedBox(height: 12),
          _detailsTile(),
        ],
      );
    }
    if (_loadError != null || _rule == null) {
      return Column(
        children: [
          Text(_loadError ?? context.l10n.tradingRulesUnavailable),
          const SizedBox(height: 8),
          OutlinedButton(
            onPressed: _loadRule,
            child: Text(context.l10n.tryAgain),
          ),
          const SizedBox(height: 18),
          _detailsTile(),
        ],
      );
    }
    final capacity = _theoreticalCapacity(_rule!, _tier, _number(_margin.text));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          context.l10n.fixedAccountRulesProfile,
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 10),
        _OptionRow<AdaptiveAccountTier>(
          options: [
            for (final tier in AdaptiveAccountTier.values)
              (tier, _title(tier.name)),
          ],
          selected: _tier,
          onSelected: (tier) => setState(() {
            _tier = tier;
            _recommendation = null;
          }),
        ),
        const SizedBox(height: 18),
        _MoneyRow(
          fieldKey: const ValueKey('adaptive-trading-capital'),
          label: context.l10n.tradingCapital,
          controller: _margin,
        ),
        const SizedBox(height: 12),
        _MoneyRow(
          fieldKey: const ValueKey('adaptive-loss-limit'),
          label: context.l10n.lossLimit,
          controller: _loss,
        ),
        const SizedBox(height: 20),
        Text(
          context.l10n.riskStyle.toUpperCase(),
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 10),
        _OptionRow<AdaptiveRiskStyle>(
          options: [
            (
              AdaptiveRiskStyle.conservative,
              context.l10n.riskStyleConservative,
            ),
            (AdaptiveRiskStyle.balanced, context.l10n.riskStyleBalanced),
            (AdaptiveRiskStyle.aggressive, context.l10n.riskStyleAggressive),
          ],
          selected: _style,
          onSelected: (style) => setState(() {
            _style = style;
            _recommendation = null;
          }),
        ),
        const SizedBox(height: 20),
        Text(
          context.l10n.adaptiveIntradayOnly,
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
            height: 1.5,
          ),
        ),
        if (capacity != null) ...[
          const SizedBox(height: 12),
          Text(
            context.l10n.theoreticalMarginCapacity,
            style: const TextStyle(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 4),
          Text(
            context.l10n.theoreticalMarginCapacityValue(_decimal(capacity)),
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              height: 1.5,
            ),
          ),
        ],
        const SizedBox(height: 12),
        Text(
          context.l10n.analysisCandleSnapshotFetched(
            DateFormat.yMd().add_jms().format(
              widget.analysis.createdAt.toLocal(),
            ),
          ),
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 18),
        Align(
          alignment: Alignment.centerLeft,
          child: FilledButton.icon(
            key: const ValueKey('create-adaptive-recommendation'),
            onPressed: _calculate,
            icon: const Icon(Icons.shield_outlined),
            label: Text(context.l10n.createRecommendation),
          ),
        ),
        if (_recommendation != null) ...[
          const SizedBox(height: 18),
          _Result(
            recommendation: _recommendation!,
            instrument: widget.analysis.instrument,
            riskStyle: _style,
            availableFunds: _number(_margin.text) ?? 0,
            maximumLoss: _number(_loss.text) ?? 0,
            activeSide: _activeSide,
            onSideChanged: (side) => setState(() => _activeSide = side),
          ),
        ],
        const SizedBox(height: 18),
        const Divider(),
        const SizedBox(height: 10),
        _detailsTile(),
      ],
    );
  }

  Widget _detailsTile() => _DetailsTile(
    title: context.l10n.understandDetails,
    count: _invalidationRuleCount(
      widget.analysis.mode == AnalysisModeEnum.pro
          ? widget.analysis.invalidationConditions
          : widget.analysis.failureConditions,
    ),
    onTap: _showDetails,
  );
}

int _invalidationRuleCount(String? value) {
  final text = value?.trim();
  if (text == null || text.isEmpty) return 0;
  return text
      .split(RegExp(r'(?:\r?\n)+|[•●]\s*'))
      .where((item) => item.trim().isNotEmpty)
      .length;
}

class _MoneyRow extends StatelessWidget {
  const _MoneyRow({
    required this.fieldKey,
    required this.controller,
    required this.label,
  });
  final Key fieldKey;
  final TextEditingController controller;
  final String label;

  @override
  Widget build(BuildContext context) {
    final field = TextField(
      key: fieldKey,
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r'^\d*[.,]?\d{0,2}')),
      ],
      decoration: const InputDecoration(prefixText: r'$ ', hintText: '0'),
    );
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 310 ||
            MediaQuery.textScalerOf(context).scale(1) > 1.3) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(fontWeight: FontWeight.w700)),
              const SizedBox(height: 7),
              field,
            ],
          );
        }
        return Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(flex: 2, child: field),
          ],
        );
      },
    );
  }
}

class _OptionRow<T> extends StatelessWidget {
  const _OptionRow({
    required this.options,
    required this.selected,
    required this.onSelected,
  });

  final List<(T, String)> options;
  final T selected;
  final ValueChanged<T> onSelected;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      for (var index = 0; index < options.length; index++) ...[
        if (index > 0) const SizedBox(width: 8),
        Expanded(
          child: Semantics(
            button: true,
            selected: selected == options[index].$1,
            child: InkWell(
              borderRadius: BorderRadius.circular(10),
              onTap: () => onSelected(options[index].$1),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                constraints: const BoxConstraints(minHeight: 54),
                alignment: Alignment.center,
                padding: const EdgeInsets.symmetric(horizontal: 8),
                decoration: BoxDecoration(
                  color: selected == options[index].$1
                      ? Theme.of(
                          context,
                        ).colorScheme.primary.withValues(alpha: 0.16)
                      : null,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: selected == options[index].$1
                        ? Theme.of(context).colorScheme.primary
                        : Theme.of(context).colorScheme.outlineVariant,
                    width: selected == options[index].$1 ? 1.5 : 1,
                  ),
                ),
                child: Text(
                  options[index].$2,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
            ),
          ),
        ),
      ],
    ],
  );
}

class _DetailsTile extends StatelessWidget {
  const _DetailsTile({
    required this.title,
    required this.count,
    required this.onTap,
  });

  final String title;
  final int count;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(12),
      border: Border.all(
        color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.7),
      ),
      color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.07),
    ),
    child: InkWell(
      key: const ValueKey('adaptive-plan-details'),
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
        child: Row(
          children: [
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.primary,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            if (count > 0) ...[
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text('$count'),
              ),
              const SizedBox(width: 12),
            ],
            Icon(
              Icons.chevron_right_rounded,
              color: Theme.of(context).colorScheme.primary,
            ),
          ],
        ),
      ),
    ),
  );
}

class _AdaptiveDetailsSheet extends StatelessWidget {
  const _AdaptiveDetailsSheet({
    required this.analysis,
    required this.candles,
    required this.rule,
    required this.tier,
    required this.style,
    required this.recommendation,
    required this.onLearn,
  });

  final Analysis analysis;
  final List<MarketCandle> candles;
  final StandardTradingRuleInstrument? rule;
  final AdaptiveAccountTier tier;
  final AdaptiveRiskStyle style;
  final AdaptiveRecommendation? recommendation;
  final VoidCallback onLearn;

  @override
  Widget build(BuildContext context) {
    final movement = RegExp(
      r'\d+(?:\.\d+)?',
    ).firstMatch(rule?.minimumPriceMovement ?? '')?.group(0);
    final candidates = adaptiveChartCandidates(
      candles,
      analysis.tradePlan!,
      double.tryParse(movement ?? '') ?? .01,
    );
    final sources = <String>{
      ...?analysis.fundamentalCitations?.newsTitles,
      ...?analysis.fundamentalCitations?.calendarEvents,
    };
    final preferred =
        recommendation?.preferredSide ??
        (analysis.tradePlan?.preferredSide.name ?? 'wait');
    // Pro and Beginner store invalidation rules in different API fields.
    final isPro = analysis.mode == AnalysisModeEnum.pro;
    final invalidationConditions = isPro
        ? analysis.invalidationConditions
        : analysis.failureConditions;

    return FractionallySizedBox(
      heightFactor: .94,
      child: Material(
        color: Theme.of(context).colorScheme.surface,
        clipBehavior: Clip.antiAlias,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 12, 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          context.l10n.understandDetails,
                          style: const TextStyle(
                            fontSize: 21,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          context.l10n.understandDetailsSubtitle,
                          style: TextStyle(
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurfaceVariant,
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: MaterialLocalizations.of(
                      context,
                    ).closeButtonTooltip,
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                children: [
                  _sectionTitle(context.l10n.whyThisAnalysis),
                  if (_has(invalidationConditions)) ...[
                    _WarningBlock(
                      title: context.l10n.analysisInvalidWhen,
                      body: invalidationConditions!.trim(),
                    ),
                    const SizedBox(height: 16),
                  ],
                  if (_has(analysis.opportunity)) ...[
                    _DetailSection(
                      title: context.l10n.opportunity,
                      body: analysis.opportunity!.trim(),
                    ),
                    const SizedBox(height: 16),
                  ],
                  if (_has(analysis.risk)) ...[
                    _DetailSection(
                      title: context.l10n.risk,
                      body: analysis.risk!.trim(),
                      titleColor: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(height: 16),
                  ],
                  _DetailsExpansion(
                    title: context.l10n.scenariosSupportingFactors,
                    children: [
                      _sectionTitle(context.l10n.scenarios),
                      _optionalDetail(
                        context,
                        context.l10n.scenarioMain,
                        analysis.mainScenario,
                      ),
                      _optionalDetail(
                        context,
                        context.l10n.scenarioAlternative,
                        analysis.alternativeScenario,
                      ),
                      _DetailSection(
                        title: context.l10n.scenarioWait,
                        body: context.l10n.executionScenarioCBody,
                      ),
                      _optionalDetail(
                        context,
                        context.l10n.technicalDrivers,
                        analysis.keyDriversTechnical,
                      ),
                      _optionalDetail(
                        context,
                        context.l10n.fundamentalDrivers,
                        analysis.keyDriversFundamental,
                      ),
                      if (sources.isNotEmpty) _SourceChips(sources: sources),
                      _optionalDetail(
                        context,
                        context.l10n.marketContext,
                        analysis.marketContext,
                      ),
                    ],
                  ),
                  const SizedBox(height: 22),
                  const Divider(),
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: Theme.of(context).colorScheme.outlineVariant,
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Analysis chart · ${analysis.instrument} · ${analysis.timeframe}',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 12),
                        AnalysisLevelsChart(
                          candles: candles,
                          tradePlan: analysis.tradePlan,
                          tradingBias: analysis.tradingBias,
                        ),
                        const SizedBox(height: 10),
                        Text(
                          context.l10n.adaptivePlanDisclaimer,
                          style: TextStyle(
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurfaceVariant,
                            fontSize: 12,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  _sectionTitle(context.l10n.wherePlanComesFrom),
                  _InfoBox(
                    text: context.l10n.planCandidateSummary(
                      candidates['buy']?.length ?? 0,
                      candidates['sell']?.length ?? 0,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    context.l10n.adaptivePlanFootnote,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 14),
                  _DetailsExpansion(
                    title: context.l10n.sourceLayeredPlan,
                    children: [
                      Text(
                        context.l10n.sourceLayeredPlanBody,
                        style: const TextStyle(height: 1.55),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Adaptive response: ${preferred.toUpperCase()}',
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                    ],
                  ),
                  const SizedBox(height: 22),
                  const Divider(),
                  const SizedBox(height: 14),
                  _sectionTitle(context.l10n.fixedAccountRulesProfile),
                  Text(
                    context.l10n.fixedAccountProfileSummary(
                      _tierMinimumLot(tier),
                      _tierMargin(rule, tier),
                    ),
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _InfoBox(
                    text: context.l10n.adaptiveSupportedInstruments,
                    emphasized: true,
                  ),
                  const SizedBox(height: 16),
                  _DetailSection(
                    title: context.l10n.tradingCapital,
                    body: context.l10n.tradingCapitalHelp,
                  ),
                  const SizedBox(height: 14),
                  _DetailSection(
                    title: context.l10n.lossLimit,
                    body: context.l10n.lossLimitHelp,
                  ),
                  const SizedBox(height: 20),
                  const Divider(),
                  const SizedBox(height: 14),
                  _sectionTitle(context.l10n.riskStyle),
                  Text(
                    _riskStyleLabel(context, style),
                    style: const TextStyle(fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    context.l10n.riskStyleHelp,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      height: 1.55,
                    ),
                  ),
                  const SizedBox(height: 18),
                  TextButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      onLearn();
                    },
                    icon: const Icon(Icons.menu_book_outlined),
                    label: Text(context.l10n.learn),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: FilledButton.icon(
                  onPressed: () => unawaited(
                    _printReport(
                      context,
                      candidates: candidates,
                      sources: sources,
                      preferred: preferred,
                      invalidationConditions: invalidationConditions,
                    ),
                  ),
                  icon: const Icon(Icons.print_outlined),
                  label: Text(context.l10n.printSavePdf),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionTitle(String text) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Text(
      text,
      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
    ),
  );

  Widget _optionalDetail(BuildContext context, String title, String? body) =>
      _has(body)
      ? Padding(
          padding: const EdgeInsets.only(bottom: 14),
          child: _DetailSection(title: title, body: body!.trim()),
        )
      : const SizedBox.shrink();

  /// Same content as the sheet above, laid out as a document for the system
  /// print / "Save as PDF" sheet. The web builds this HTML in the browser
  /// (`buildConfidencePrintHtml`), so there is no URL to open from the app.
  AdaptivePlanReport _buildReport(
    BuildContext context, {
    required Map<String, List<double>> candidates,
    required Set<String> sources,
    required String preferred,
    required String? invalidationConditions,
  }) {
    final l10n = context.l10n;
    final locale = Localizations.localeOf(context);
    ReportBlock? detail(String title, String? body) => _has(body)
        ? ReportBlock.paragraph('**$title**\n${body!.trim()}')
        : null;
    List<ReportBlock> blocks(Iterable<ReportBlock?> items) =>
        items.whereType<ReportBlock>().toList();

    return AdaptivePlanReport(
      title: l10n.understandDetails,
      instrument: analysis.instrument,
      timeframe: analysis.timeframe,
      analyzedAt: DateFormat.yMMMd(
        locale.toString(),
      ).add_Hm().format(analysis.createdAt.toLocal()),
      summary: l10n.understandDetailsSubtitle,
      briefLabel: l10n.reportBriefingTitle,
      sections: [
        ReportSection(
          l10n.whyThisAnalysis,
          blocks([
            if (_has(invalidationConditions))
              ReportBlock.paragraph(
                '**${l10n.analysisInvalidWhen}**\n${invalidationConditions!.trim()}',
              ),
            detail(l10n.opportunity, analysis.opportunity),
            detail(l10n.risk, analysis.risk),
          ]),
        ),
        ReportSection(
          l10n.scenarios,
          blocks([
            detail(l10n.scenarioMain, analysis.mainScenario),
            detail(l10n.scenarioAlternative, analysis.alternativeScenario),
            ReportBlock.paragraph(
              '**${l10n.scenarioWait}**\n${l10n.executionScenarioCBody}',
            ),
            detail(l10n.technicalDrivers, analysis.keyDriversTechnical),
            detail(l10n.fundamentalDrivers, analysis.keyDriversFundamental),
            detail(l10n.marketContext, analysis.marketContext),
          ]),
        ),
        ReportSection(l10n.wherePlanComesFrom, [
          ReportBlock.paragraph(
            l10n.planCandidateSummary(
              candidates['buy']?.length ?? 0,
              candidates['sell']?.length ?? 0,
            ),
          ),
          ReportBlock.paragraph(l10n.adaptivePlanFootnote),
          ReportBlock.paragraph(
            '**${l10n.sourceLayeredPlan}**\n${l10n.sourceLayeredPlanBody}\n'
            'Adaptive response: ${preferred.toUpperCase()}',
          ),
        ]),
        ReportSection(l10n.fixedAccountRulesProfile, [
          ReportBlock.paragraph(
            l10n.fixedAccountProfileSummary(
              _tierMinimumLot(tier),
              _tierMargin(rule, tier),
            ),
          ),
          ReportBlock.paragraph(l10n.adaptiveSupportedInstruments),
          ReportBlock.paragraph(
            '**${l10n.tradingCapital}**\n${l10n.tradingCapitalHelp}',
          ),
          ReportBlock.paragraph('**${l10n.lossLimit}**\n${l10n.lossLimitHelp}'),
        ]),
        ReportSection(l10n.riskStyle, [
          ReportBlock.paragraph(
            '**${_riskStyleLabel(context, style)}**\n${l10n.riskStyleHelp}',
          ),
        ]),
      ],
      sourcesTitle: l10n.reportSourcesTitle,
      sources: sources.toList(),
      disclaimer: l10n.adaptivePlanDisclaimer,
      referenceId: 'Analysis #${analysis.id}',
    );
  }

  Future<void> _printReport(
    BuildContext context, {
    required Map<String, List<double>> candidates,
    required Set<String> sources,
    required String preferred,
    required String? invalidationConditions,
  }) async {
    final messenger = ScaffoldMessenger.of(context);
    final failedMessage = context.l10n.printableReportOpenFailed;
    try {
      await printAdaptivePlanReport(
        _buildReport(
          context,
          candidates: candidates,
          sources: sources,
          preferred: preferred,
          invalidationConditions: invalidationConditions,
        ),
      );
    } catch (_) {
      messenger.showSnackBar(SnackBar(content: Text(failedMessage)));
    }
  }
}

class _WarningBlock extends StatelessWidget {
  const _WarningBlock({required this.title, required this.body});
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: Theme.of(context).colorScheme.error.withValues(alpha: .1),
      border: Border.all(color: Theme.of(context).colorScheme.error),
      borderRadius: BorderRadius.circular(10),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontWeight: FontWeight.w900)),
        const SizedBox(height: 8),
        Text(body, style: const TextStyle(height: 1.5)),
      ],
    ),
  );
}

class _DetailSection extends StatelessWidget {
  const _DetailSection({
    required this.title,
    required this.body,
    this.titleColor,
  });
  final String title;
  final String body;
  final Color? titleColor;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        title,
        style: TextStyle(fontWeight: FontWeight.w900, color: titleColor),
      ),
      const SizedBox(height: 6),
      Text(body, style: const TextStyle(height: 1.55)),
    ],
  );
}

class _DetailsExpansion extends StatelessWidget {
  const _DetailsExpansion({required this.title, required this.children});
  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(
      border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
      borderRadius: BorderRadius.circular(10),
    ),
    child: ExpansionTile(
      tilePadding: const EdgeInsets.symmetric(horizontal: 14),
      childrenPadding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
      shape: const Border(),
      collapsedShape: const Border(),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w900)),
      children: children,
    ),
  );
}

class _InfoBox extends StatelessWidget {
  const _InfoBox({required this.text, this.emphasized = false});
  final String text;
  final bool emphasized;

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: emphasized
          ? Theme.of(context).colorScheme.primary.withValues(alpha: .08)
          : Theme.of(context).colorScheme.surfaceContainerHighest,
      border: Border.all(
        color: emphasized
            ? Theme.of(context).colorScheme.primary.withValues(alpha: .6)
            : Theme.of(context).colorScheme.outlineVariant,
      ),
      borderRadius: BorderRadius.circular(10),
    ),
    child: Text(
      text,
      style: TextStyle(
        height: 1.5,
        fontWeight: emphasized ? FontWeight.w700 : null,
      ),
    ),
  );
}

class _SourceChips extends StatelessWidget {
  const _SourceChips({required this.sources});
  final Set<String> sources;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 14),
    child: Wrap(
      spacing: 7,
      runSpacing: 7,
      children: [
        for (final source in sources)
          Chip(
            avatar: const Icon(Icons.article_outlined, size: 16),
            label: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 220),
              child: Text(source, maxLines: 1, overflow: TextOverflow.ellipsis),
            ),
          ),
      ],
    ),
  );
}

bool _has(String? value) => value?.trim().isNotEmpty == true;

String _tierMinimumLot(AdaptiveAccountTier tier) => switch (tier) {
  AdaptiveAccountTier.micro => '0.01',
  AdaptiveAccountTier.mini => '0.10',
  AdaptiveAccountTier.regular => '1.00',
};

String _tierMargin(
  StandardTradingRuleInstrument? rule,
  AdaptiveAccountTier tier,
) {
  if (rule == null) return '—';
  final multiplier = switch (tier) {
    AdaptiveAccountTier.micro => .1,
    AdaptiveAccountTier.mini => 1,
    AdaptiveAccountTier.regular => 10,
  };
  return _money(rule.initialMarginUsdPerLot.toDouble() * multiplier);
}

double? _theoreticalCapacity(
  StandardTradingRuleInstrument rule,
  AdaptiveAccountTier tier,
  double? funds,
) {
  if (funds == null || funds <= 0) return null;
  final multiplier = switch (tier) {
    AdaptiveAccountTier.micro => .1,
    AdaptiveAccountTier.mini => 1.0,
    AdaptiveAccountTier.regular => 10.0,
  };
  final minimumLot = switch (tier) {
    AdaptiveAccountTier.micro => .01,
    AdaptiveAccountTier.mini => .1,
    AdaptiveAccountTier.regular => 1.0,
  };
  final maximumLot = switch (tier) {
    AdaptiveAccountTier.micro => .09,
    AdaptiveAccountTier.mini => .9,
    AdaptiveAccountTier.regular => 50.0,
  };
  final marginAtMinimum = rule.initialMarginUsdPerLot * multiplier;
  if (marginAtMinimum <= 0) return null;
  final capacity = (funds / marginAtMinimum).floor() * minimumLot;
  return capacity > maximumLot ? maximumLot : capacity;
}

String _riskStyleLabel(BuildContext context, AdaptiveRiskStyle style) =>
    switch (style) {
      AdaptiveRiskStyle.conservative => context.l10n.riskStyleConservative,
      AdaptiveRiskStyle.balanced => context.l10n.riskStyleBalanced,
      AdaptiveRiskStyle.aggressive => context.l10n.riskStyleAggressive,
    };

class _Result extends StatelessWidget {
  const _Result({
    required this.recommendation,
    required this.instrument,
    required this.riskStyle,
    required this.availableFunds,
    required this.maximumLoss,
    required this.activeSide,
    required this.onSideChanged,
  });
  final AdaptiveRecommendation recommendation;
  final String instrument;
  final AdaptiveRiskStyle riskStyle;
  final double availableFunds;
  final double maximumLoss;
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
    final isSell = shownSide == 'sell';
    final accent = isSell ? const Color(0xFFFF4D5E) : const Color(0xFF00D8A2);
    final first = side.layers.first;
    // A directionless result is reference data, not an actionable plan.
    final isConditional =
        recommendation.preferredSide != 'buy' &&
        recommendation.preferredSide != 'sell';
    return Column(
      key: const ValueKey('adaptive-recommendation-result'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (isConditional) ...[
          Text(
            context.l10n.waitLabel.toUpperCase(),
            style: TextStyle(
              color: Theme.of(context).colorScheme.primary,
              fontSize: 22,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            context.l10n.adaptiveWaitDecisionBody,
            style: const TextStyle(height: 1.5),
          ),
          const SizedBox(height: 14),
          _CompactMetric(context.l10n.hardLossMaximum, _money(maximumLoss)),
          const SizedBox(height: 18),
          _EntryDirectionUnconfirmedNotice(
            key: const ValueKey('adaptive-conditional-notice'),
          ),
        ] else ...[
          Text(
            isSell
                ? context.l10n.priceFallScenario
                : context.l10n.priceRiseScenario,
            style: TextStyle(
              color: accent,
              fontSize: 22,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            context.l10n.scenarioFitsRisk(
              isSell ? context.l10n.sell : context.l10n.buy,
            ),
            style: const TextStyle(height: 1.5),
          ),
          const SizedBox(height: 12),
          Text(
            context.l10n.watchEntry(_decimal(side.entry)),
            style: const TextStyle(fontWeight: FontWeight.w800, height: 1.4),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: _CompactMetric(
                  context.l10n.minimumRiskAtStop,
                  _money(first.cumulativeRisk),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _CompactMetric(
                  context.l10n.brokerFundsAtStop,
                  _money(first.cumulativeFundsAtStop),
                ),
              ),
            ],
          ),
        ],
        const SizedBox(height: 22),
        Text(
          context.l10n.reviewOneDirection,
          style: const TextStyle(fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 8),
        _OptionRow<String>(
          options: [
            if (buy != null) ('buy', context.l10n.priceRiseScenario),
            if (sell != null) ('sell', context.l10n.priceFallScenario),
          ],
          selected: shownSide,
          onSelected: onSideChanged,
        ),
        const SizedBox(height: 14),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          alignment: WrapAlignment.spaceBetween,
          children: [
            Chip(
              label: Text(
                isConditional
                    ? context.l10n.conditionalScenarioNotActionable
                    : context.l10n.planReadyToReview,
              ),
              side: BorderSide(
                color: isConditional
                    ? const Color(0xFFF59E0B)
                    : Theme.of(context).colorScheme.primary,
              ),
            ),
            OutlinedButton.icon(
              onPressed: isConditional ? null : () => _copyPlan(context, side),
              icon: const Icon(Icons.copy_rounded, size: 18),
              label: Text(context.l10n.copyPositionPlan),
            ),
          ],
        ),
        const SizedBox(height: 10),
        _ScenarioPlanCard(
          side: side,
          accent: accent,
          isConditional: isConditional,
          riskStyle: riskStyle,
          recommendation: recommendation,
          availableFunds: availableFunds,
          maximumLoss: maximumLoss,
          onCopy: () => _copyPlan(context, side),
        ),
        const SizedBox(height: 14),
        _DetailsExpansion(
          title: context.l10n.howUseRecommendation,
          children: [
            Text(
              context.l10n.howUseRecommendationBody,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                height: 1.6,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Text(
          context.l10n.manualExecutionDisclaimer,
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
            height: 1.5,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          context.l10n.adaptivePlanFootnote,
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
            height: 1.5,
          ),
        ),
      ],
    );
  }

  Future<void> _copyPlan(BuildContext context, AdaptiveSidePlan side) async {
    final l10n = context.l10n;
    final style = switch (riskStyle) {
      AdaptiveRiskStyle.conservative => l10n.riskStyleConservative,
      AdaptiveRiskStyle.balanced => l10n.riskStyleBalanced,
      AdaptiveRiskStyle.aggressive => l10n.riskStyleAggressive,
    };
    final lines = <String>[
      l10n.positionSizeRecommendation,
      '${l10n.instrument}: $instrument',
      '${l10n.positionDirection}: ${side.side.toUpperCase()}',
      '${l10n.riskStyle}: $style',
      '',
      ...side.layers.indexed.map(
        (item) =>
            '${item.$1 + 1}. ${_decimal(item.$2.price)} · '
            '${_decimal(item.$2.lot)} lot',
      ),
      'SL: ${_decimal(side.stopLoss)}',
      if (side.takeProfit1 != null) 'TP1: ${_decimal(side.takeProfit1!)}',
      if (side.takeProfit2 != null) 'TP2: ${_decimal(side.takeProfit2!)}',
      '${l10n.totalLots}: ${_decimal(side.totalLots)} lot',
      '${l10n.marginRequired}: ${_money(side.marginRequired)}',
      '${l10n.estimatedCycleLoss}: ${_money(side.estimatedLoss)}',
      l10n.adaptiveCopyManualContext,
    ];
    try {
      await Clipboard.setData(ClipboardData(text: lines.join('\n')));
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(l10n.positionPlanCopied)));
      }
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(l10n.positionPlanCopyFailed)));
      }
    }
  }
}

class _CompactMetric extends StatelessWidget {
  const _CompactMetric(this.label, this.value);
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        label,
        style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
      ),
      Text(value, style: const TextStyle(fontWeight: FontWeight.w900)),
    ],
  );
}

class _ScenarioPlanCard extends StatelessWidget {
  const _ScenarioPlanCard({
    required this.side,
    required this.accent,
    required this.riskStyle,
    required this.recommendation,
    required this.availableFunds,
    required this.maximumLoss,
    required this.onCopy,
    this.isConditional = false,
  });

  final AdaptiveSidePlan side;
  final Color accent;
  final AdaptiveRiskStyle riskStyle;
  final AdaptiveRecommendation recommendation;
  final double availableFunds;
  final double maximumLoss;
  final VoidCallback onCopy;
  final bool isConditional;

  @override
  Widget build(BuildContext context) {
    final isSell = side.side == 'sell';
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(12),
        border: Border(left: BorderSide(color: accent, width: 5)),
      ),
      padding: const EdgeInsets.fromLTRB(16, 18, 12, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            isSell
                ? context.l10n.priceFallScenario
                : context.l10n.priceRiseScenario,
            style: TextStyle(
              color: accent,
              fontSize: 17,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 14),
          _Panel(
            children: [
              Text(
                context.l10n.answerAtGlance,
                style: const TextStyle(fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 8),
              _ValueCard(
                isConditional
                    ? context.l10n.conditionalScenarioNotActionable
                    : context.l10n.planReadyToReview,
                borderColor: isConditional
                    ? const Color(0xFFF59E0B)
                    : Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(height: 10),
              Text(
                isConditional
                    ? context.l10n.referenceNumbersOnly
                    : context.l10n.objectiveScenario,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 8),
              Chip(label: Text(_riskStyleLabel(context, riskStyle))),
              const Divider(height: 28),
              Text(
                context.l10n.entryLotPerPosition,
                style: const TextStyle(fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 6),
              for (final item in side.layers.indexed)
                _EntryRow(index: item.$1, layer: item.$2),
              const SizedBox(height: 6),
              Text(
                context.l10n.allEntriesFill(
                  side.layers.length,
                  _decimal(side.totalLots),
                ),
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 12),
              _ValueCard(
                context.l10n.oneFinalStopLoss,
                value: _decimal(side.stopLoss),
                valueColor: const Color(0xFFFF4D5E),
              ),
              const SizedBox(height: 10),
              _ValueCard(
                context.l10n.estimatedMaximumLoss,
                value: _money(side.estimatedLoss),
              ),
              const Divider(height: 28),
              Text(
                context.l10n.riskContext,
                style: const TextStyle(fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 10),
              _ValueCard(
                context.l10n.usableRiskBudget,
                value: _money(recommendation.usableRisk),
                detail: maximumLoss > 0
                    ? '${(recommendation.usableRisk / maximumLoss * 100).round()}%'
                    : null,
              ),
              const SizedBox(height: 10),
              _ValueCard(
                context.l10n.reservedLossCeiling,
                value: _money(recommendation.unusedRisk),
              ),
              const Divider(height: 28),
              Text(
                context.l10n.profitTargets,
                style: const TextStyle(fontWeight: FontWeight.w900),
              ),
              if (side.takeProfit1 != null) ...[
                const SizedBox(height: 10),
                _ValueCard(
                  'Take Profit 1',
                  value: _decimal(side.takeProfit1!),
                  detail: context.l10n.estimatedProfit(
                    _money(side.profitToTp1),
                  ),
                  detailColor: const Color(0xFF00D8A2),
                ),
              ],
              if (side.takeProfit2 != null) ...[
                const SizedBox(height: 10),
                _ValueCard(
                  'Take Profit 2',
                  value: _decimal(side.takeProfit2!),
                  detail: context.l10n.estimatedProfit(
                    _money(side.profitToTp2),
                  ),
                  detailColor: const Color(0xFF00D8A2),
                ),
              ],
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerRight,
                child: OutlinedButton.icon(
                  onPressed: isConditional ? null : onCopy,
                  icon: const Icon(Icons.copy_rounded),
                  label: Text(context.l10n.copyPositionPlan),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            context.l10n.extraPositionsManual,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 12),
          _PlanDetails(side: side, availableFunds: availableFunds),
        ],
      ),
    );
  }
}

class _Panel extends StatelessWidget {
  const _Panel({required this.children});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
      borderRadius: BorderRadius.circular(10),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: children,
    ),
  );
}

class _EntryRow extends StatelessWidget {
  const _EntryRow({required this.index, required this.layer});
  final int index;
  final AdaptiveLayer layer;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 7),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Text(
            '${index + 1}. ${index == 0 ? context.l10n.initialEntry : context.l10n.additionalPosition}',
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
        ),
        const SizedBox(width: 10),
        Text(
          '${_decimal(layer.price)} · ${_decimal(layer.lot)} lot',
          textAlign: TextAlign.right,
          style: const TextStyle(fontWeight: FontWeight.w900),
        ),
      ],
    ),
  );
}

class _ValueCard extends StatelessWidget {
  const _ValueCard(
    this.label, {
    this.value,
    this.detail,
    this.borderColor,
    this.valueColor,
    this.detailColor,
  });
  final String label;
  final String? value;
  final String? detail;
  final Color? borderColor;
  final Color? valueColor;
  final Color? detailColor;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: Theme.of(context).colorScheme.surfaceContainerHigh,
      borderRadius: BorderRadius.circular(8),
      border: borderColor == null ? null : Border.all(color: borderColor!),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.w700)),
        if (value != null) ...[
          const SizedBox(height: 4),
          Text(
            value!,
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w900,
              color: valueColor,
            ),
          ),
        ],
        if (detail != null) ...[
          const SizedBox(height: 4),
          Text(detail!, style: TextStyle(color: detailColor)),
        ],
      ],
    ),
  );
}

class _PlanDetails extends StatelessWidget {
  const _PlanDetails({required this.side, required this.availableFunds});
  final AdaptiveSidePlan side;
  final double availableFunds;

  @override
  Widget build(BuildContext context) => _DetailsExpansion(
    title: context.l10n.viewPlanDetails,
    children: [
      Text(
        context.l10n.extraLayersManual,
        style: TextStyle(
          color: Theme.of(context).colorScheme.onSurfaceVariant,
          height: 1.5,
        ),
      ),
      const SizedBox(height: 14),
      _Panel(
        children: [
          Text(
            context.l10n.ifEntriesFill,
            style: const TextStyle(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 8),
          _FillSummary(
            title: context.l10n.firstEntryOnly,
            positions: 1,
            layer: side.layers.first,
          ),
          const SizedBox(height: 10),
          _FillSummary(
            title: context.l10n.allPlannedEntries,
            positions: side.layers.length,
            layer: side.layers.last,
          ),
          const SizedBox(height: 12),
          Text(
            context.l10n.grossEstimateDisclaimer,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              height: 1.5,
            ),
          ),
          const Divider(height: 26),
          Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: '${context.l10n.whyLossCeilingUnused}: ',
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
                TextSpan(text: context.l10n.lossCeilingUnusedBody),
              ],
            ),
          ),
        ],
      ),
      const SizedBox(height: 12),
      _DetailsExpansion(
        title: context.l10n.showExplanation,
        children: [
          Text(
            context.l10n.layerExplanation,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 14),
          for (final item in side.layers.indexed)
            _LayerDetails(
              index: item.$1,
              layer: item.$2,
              previous: item.$1 == 0 ? null : side.layers[item.$1 - 1],
              availableFunds: availableFunds,
            ),
          const Divider(height: 28),
          Text(
            context.l10n.moreCalculationDetails,
            style: const TextStyle(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 8),
          _MetricRows({
            context.l10n.weightedAverageEntry: _decimal(
              _weightedAverage(side.layers),
            ),
            context.l10n.marginUsedSoFar: _money(side.marginRequired),
            context.l10n.dayMarginPlusLoss: _money(side.fundsAtStop),
          }),
        ],
      ),
    ],
  );
}

class _FillSummary extends StatelessWidget {
  const _FillSummary({
    required this.title,
    required this.positions,
    required this.layer,
  });
  final String title;
  final int positions;
  final AdaptiveLayer layer;

  @override
  Widget build(BuildContext context) => Text.rich(
    TextSpan(
      children: [
        TextSpan(
          text: '$title\n',
          style: const TextStyle(fontWeight: FontWeight.w900),
        ),
        TextSpan(
          text:
              '$positions · ${_decimal(layer.cumulativeLots)} lot · '
              '${_money(layer.cumulativeMargin)} margin · '
              '${_money(layer.cumulativeRisk)} at SL',
        ),
      ],
    ),
  );
}

class _LayerDetails extends StatelessWidget {
  const _LayerDetails({
    required this.index,
    required this.layer,
    required this.previous,
    required this.availableFunds,
  });
  final int index;
  final AdaptiveLayer layer;
  final AdaptiveLayer? previous;
  final double availableFunds;

  @override
  Widget build(BuildContext context) {
    final margin = layer.cumulativeMargin - (previous?.cumulativeMargin ?? 0);
    final risk = layer.cumulativeRisk - (previous?.cumulativeRisk ?? 0);
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  '${index + 1}. ${index == 0 ? context.l10n.initialEntry : context.l10n.additionalPosition}',
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
              ),
              Text(
                '${_decimal(layer.price)} · ${_decimal(layer.lot)} lot',
                style: const TextStyle(fontWeight: FontWeight.w900),
              ),
            ],
          ),
          const SizedBox(height: 8),
          _Panel(
            children: [
              _MetricRows({
                context.l10n.marginThisPosition: _money(margin),
                context.l10n.marginUsedSoFar: _money(layer.cumulativeMargin),
                context.l10n.riskThisPosition: _money(risk),
                context.l10n.riskAtStopSoFar: _money(layer.cumulativeRisk),
                context.l10n.fundsNeededAtStop: _money(
                  layer.cumulativeFundsAtStop,
                ),
                context.l10n.fundsRemaining: _money(
                  availableFunds - layer.cumulativeFundsAtStop,
                ),
                if (layer.profitToTp1 != null)
                  context.l10n.cumulativeProfitTp1:
                      '+${_money(layer.profitToTp1)}',
                if (layer.profitToTp2 != null)
                  context.l10n.cumulativeProfitTp2:
                      '+${_money(layer.profitToTp2)}',
              }),
            ],
          ),
        ],
      ),
    );
  }
}

class _MetricRows extends StatelessWidget {
  const _MetricRows(this.values);
  final Map<String, String> values;

  @override
  Widget build(BuildContext context) => Column(
    children: [
      for (final entry in values.entries)
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 3),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  entry.key,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                entry.value,
                textAlign: TextAlign.right,
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  color: entry.value.startsWith('+')
                      ? const Color(0xFF00D8A2)
                      : null,
                ),
              ),
            ],
          ),
        ),
    ],
  );
}

double _weightedAverage(List<AdaptiveLayer> layers) {
  var previousLots = 0.0;
  var weightedTotal = 0.0;
  for (final layer in layers) {
    final lots = layer.cumulativeLots - previousLots;
    weightedTotal += layer.price * lots;
    previousLots = layer.cumulativeLots;
  }
  return weightedTotal / layers.last.cumulativeLots;
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

class _EntryDirectionUnconfirmedNotice extends StatelessWidget {
  const _EntryDirectionUnconfirmedNotice({super.key});

  @override
  Widget build(BuildContext context) {
    const color = Color(0xFFF59E0B);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .09),
        border: Border.all(color: color.withValues(alpha: .35)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.warning_amber_rounded, color: color, size: 19),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  context.l10n.entryDirectionUnconfirmedTitle,
                  style: const TextStyle(
                    color: color,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            context.l10n.entryDirectionUnconfirmedBody,
            style: const TextStyle(color: color, height: 1.5),
          ),
          const SizedBox(height: 8),
          Text(
            context.l10n.entryDirectionUnconfirmedNextAction,
            style: const TextStyle(
              color: color,
              height: 1.5,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

double? _number(String value) =>
    double.tryParse(value.trim().replaceAll(',', '.'));
String _title(String value) => '${value[0].toUpperCase()}${value.substring(1)}';
String _money(double? value) => value == null
    ? '—'
    : NumberFormat.currency(
        symbol: r'$',
        decimalDigits: value == value.roundToDouble() ? 0 : 2,
      ).format(value);
String _decimal(double value) => NumberFormat('0.####').format(value);
