import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:trade_pilot_api_client/trade_pilot_api_client.dart';

import '../../core/mindset/mindset_engine.dart';
import '../../providers/analysis_provider.dart';
import '../../providers/auth_provider.dart';
import '../../l10n/l10n.dart';
import '../../widgets/responsive_page.dart';

class TraderMirrorScreen extends StatefulWidget {
  const TraderMirrorScreen({super.key});

  @override
  State<TraderMirrorScreen> createState() => _TraderMirrorScreenState();
}

class _TraderMirrorScreenState extends State<TraderMirrorScreen> {
  TraderMirrorResponse? _data;
  bool _loading = true;
  String? _error;
  int? _ownerUserId;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final auth = context.read<AuthProvider>();
    final userId = auth.user?.id;
    _ownerUserId ??= userId;
    try {
      final response = await auth.client.traderMirror.getTraderMirrorInsights();
      if (!mounted || auth.user?.id != userId) return;
      setState(() {
        _data = response.data;
        _error = null;
      });
    } catch (_) {
      if (mounted && auth.user?.id == userId) {
        setState(() => _error = context.l10n.traderMirrorLoadFailed);
      }
    } finally {
      if (mounted && auth.user?.id == userId) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUserId = context.watch<AuthProvider>().user?.id;
    if (_ownerUserId != null && currentUserId != _ownerUserId) {
      return Scaffold(
        appBar: AppBar(title: Text(context.l10n.traderMirror)),
        body: Center(child: Text(context.l10n.sessionChangedReopen)),
      );
    }
    final analysis = context.watch<AnalysisProvider>();
    final reflections = const MindsetEngine().evaluate(analysis.history);
    final data = _data;
    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.traderMirror)),
      body: RefreshIndicator(
        onRefresh: _load,
        child: _loading && data == null
            ? ListView(
                children: const [
                  SizedBox(height: 240),
                  Center(child: CircularProgressIndicator()),
                ],
              )
            : _error != null && data == null
            ? ListView(
                children: [
                  const SizedBox(height: 180),
                  Center(child: Text(_error!)),
                  Center(
                    child: TextButton(
                      onPressed: _load,
                      child: Text(context.l10n.tryAgain),
                    ),
                  ),
                ],
              )
            : ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: responsivePagePadding(context),
                children: [
                  Text(context.l10n.traderMirrorDisclaimer),
                  const SizedBox(height: 16),
                  if (data!.highlights.isEmpty)
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Text(context.l10n.traderMirrorNoHighlights),
                      ),
                    )
                  else
                    ...data.highlights.map(
                      (highlight) => Card(
                        child: ListTile(
                          leading: const Icon(Icons.auto_awesome_outlined),
                          title: Text(
                            Localizations.localeOf(context).languageCode == 'id'
                                ? highlight.idText
                                : highlight.en,
                          ),
                        ),
                      ),
                    ),
                  const SizedBox(height: 18),
                  Text(
                    context.l10n.traderMirrorCoverage(
                      data.insights.windowDays,
                      data.insights.totalResolved,
                    ),
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 8),
                  _GateRow(
                    label: context.l10n.traderMirrorSessions,
                    insight: data.insights.sessions,
                  ),
                  _GateRow(
                    label: context.l10n.traderMirrorInstruments,
                    insight: data.insights.instruments,
                  ),
                  _GateRow(
                    label: context.l10n.traderMirrorTiming,
                    insight: data.insights.timing,
                  ),
                  _GateRow(
                    label: context.l10n.traderMirrorPostLoss,
                    insight: data.insights.postLoss,
                  ),
                  _GateRow(
                    label: context.l10n.traderMirrorEvaluationDiscipline,
                    insight: data.insights.exitDiscipline,
                  ),
                  const SizedBox(height: 22),
                  Text(
                    context.l10n.traderMirrorProcessReflection,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  Text(
                    context.l10n.traderMirrorBasedOn(analysis.history.length),
                    style: const TextStyle(fontSize: 12),
                  ),
                  const SizedBox(height: 8),
                  if (reflections.isEmpty)
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Text(context.l10n.traderMirrorNeedMore),
                      ),
                    )
                  else
                    ...reflections.map(
                      (insight) => Card(
                        child: ListTile(
                          leading: const Icon(Icons.self_improvement_outlined),
                          title: Text(insight.title),
                          subtitle: Text(insight.message),
                        ),
                      ),
                    ),
                ],
              ),
      ),
    );
  }
}

class _GateRow extends StatelessWidget {
  const _GateRow({required this.label, required this.insight});
  final String label;
  final MirrorGatedInsight insight;

  @override
  Widget build(BuildContext context) {
    final data = insight.data;
    return Card(
      child: ExpansionTile(
        leading: Icon(
          insight.gated
              ? Icons.lock_clock_outlined
              : Icons.check_circle_outline,
        ),
        title: Text(label),
        subtitle: Text(
          insight.gated
              ? context.l10n.traderMirrorGated(
                  '${insight.need ?? context.l10n.traderMirrorNeedMoreGeneric}',
                  insight.have ?? 0,
                )
              : context.l10n.traderMirrorUngated,
        ),
        children: insight.gated || data == null
            ? const []
            : data.entries
                  .map(
                    (entry) => ListTile(
                      dense: true,
                      title: Text(_label(entry.key)),
                      subtitle: Text(_summary(context, entry.value?.value)),
                    ),
                  )
                  .toList(),
      ),
    );
  }

  static String _label(String value) {
    final normalized = value.replaceAll('_', ' ');
    return normalized.isEmpty
        ? normalized
        : '${normalized[0].toUpperCase()}${normalized.substring(1)}';
  }

  static String _summary(BuildContext context, Object? value) {
    if (value is Map) {
      final key = value['key'];
      final rate = value['winRate'];
      final total = value['total'];
      if (key != null && rate is num) {
        return '$key · ${(rate * 100).round()}% · '
            '${context.l10n.traderMirrorSamples((total as num?)?.round() ?? 0)}';
      }
      return value.entries
          .map((entry) => '${_label('${entry.key}')}: ${entry.value}')
          .join(' · ');
    }
    return value?.toString() ?? '—';
  }
}
