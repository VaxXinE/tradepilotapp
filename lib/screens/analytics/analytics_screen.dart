import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:trade_pilot_api_client/trade_pilot_api_client.dart';

import '../../core/analytics/analysis_analytics.dart';
import '../../providers/analysis_provider.dart';
import '../../providers/auth_provider.dart';
import '../../l10n/l10n.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  PersonalAnalytics? _server;
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
    setState(() => _loading = true);
    try {
      final response = await auth.client.analyses.getPersonalAnalytics();
      if (!mounted || auth.user?.id != userId) return;
      setState(() {
        _server = response.data;
        _error = null;
      });
    } catch (_) {
      if (mounted && auth.user?.id == userId) {
        setState(() => _error = context.l10n.analyticsLoadFailed);
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
        appBar: AppBar(title: const Text('Analytics')),
        body: Center(child: Text(context.l10n.sessionChangedReopen)),
      );
    }
    final analysis = context.watch<AnalysisProvider>();
    final local = AnalysisAnalytics.from(
      analysis.history,
      serverTotal: analysis.historyTotal,
    );
    return Scaffold(
      appBar: AppBar(title: const Text('Analytics')),
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const Text(
              'Ringkasan Aktivitas',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 4),
            Text(context.l10n.analyticsDisclaimer),
            const SizedBox(height: 14),
            if (_loading && _server == null)
              const Center(child: CircularProgressIndicator())
            else if (_error != null && _server == null) ...[
              Text(_error!),
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton(
                  onPressed: _load,
                  child: Text(context.l10n.tryAgain),
                ),
              ),
            ] else if (_server case final data?) ...[
              _MetricGrid(
                values: {
                  context.l10n.metricAllAnalyses: '${data.totalAllTime}',
                  context.l10n.metricThisMonth: '${data.totalThisMonth}',
                  context.l10n.metricThisWeek: '${data.totalThisWeek}',
                  context.l10n.metricFeedbackGiven: '${data.feedbackCount}',
                  context.l10n.metricDominantMode: data.dominantMode ?? '—',
                  context.l10n.metricOutcomeAccuracy: data.accuracyRate == null
                      ? '—'
                      : '${(data.accuracyRate! * 100).round()}%',
                },
              ),
              if (data.topInstruments.isNotEmpty) ...[
                const SizedBox(height: 14),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          context.l10n.instrumentRanking,
                          style: const TextStyle(fontWeight: FontWeight.w800),
                        ),
                        const SizedBox(height: 8),
                        ...data.topInstruments.map(
                          (item) => ListTile(
                            dense: true,
                            contentPadding: EdgeInsets.zero,
                            leading: const Icon(Icons.query_stats_rounded),
                            title: Text(item.instrument),
                            trailing: Text(
                              context.l10n.countAnalyses(item.count),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
              if (data.weeklyData.isNotEmpty) ...[
                const SizedBox(height: 14),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Aktivitas mingguan',
                          style: TextStyle(fontWeight: FontWeight.w800),
                        ),
                        const SizedBox(height: 12),
                        ...data.weeklyData.map(
                          (item) => Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: Row(
                              children: [
                                SizedBox(width: 92, child: Text(item.week)),
                                Expanded(
                                  child: LinearProgressIndicator(
                                    value: item.count == 0
                                        ? 0
                                        : item.count /
                                              data.weeklyData
                                                  .map((entry) => entry.count)
                                                  .reduce(
                                                    (a, b) => a > b ? a : b,
                                                  ),
                                  ),
                                ),
                                SizedBox(
                                  width: 36,
                                  child: Text(
                                    '${item.count}',
                                    textAlign: TextAlign.end,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ],
            const SizedBox(height: 22),
            Text(
              context.l10n.loadedResults,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 4),
            Text(
              local.isPartial
                  ? context.l10n.analyticsPartialScope(
                      local.total,
                      analysis.historyTotal,
                    )
                  : context.l10n.analyticsFullScope(local.total),
              style: const TextStyle(fontSize: 12),
            ),
            const SizedBox(height: 12),
            _MetricGrid(
              values: {
                context.l10n.metricEvaluated: '${local.evaluated}',
                context.l10n.metricPending: '${local.pending}',
                context.l10n.metricPositiveOutcomes:
                    '${local.positiveOutcomes}',
                context.l10n.metricNegativeOutcomes:
                    '${local.negativeOutcomes}',
                context.l10n.metricHasNote: '${local.journaled}',
                context.l10n.metricAverageConfidence:
                    local.averageConfidence == null
                    ? '—'
                    : '${local.averageConfidence!.toStringAsFixed(1)}%',
                context.l10n.metricTopTimeframe: local.topTimeframe ?? '—',
                context.l10n.metricTopInstrument: local.topInstrument ?? '—',
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _MetricGrid extends StatelessWidget {
  const _MetricGrid({required this.values});
  final Map<String, String> values;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth >= 600
            ? (constraints.maxWidth - 24) / 3
            : (constraints.maxWidth - 12) / 2;
        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: values.entries
              .map(
                (entry) => SizedBox(
                  width: width,
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            entry.value,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(entry.key, style: const TextStyle(fontSize: 12)),
                        ],
                      ),
                    ),
                  ),
                ),
              )
              .toList(),
        );
      },
    );
  }
}
