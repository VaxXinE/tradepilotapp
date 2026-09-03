import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:trade_pilot_api_client/trade_pilot_api_client.dart';

import '../../core/analytics/analysis_analytics.dart';
import '../../providers/analysis_provider.dart';
import '../../providers/auth_provider.dart';

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
        setState(() => _error = 'Analytics belum dapat dimuat. Coba lagi.');
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
        body: const Center(
          child: Text('Sesi berubah. Buka kembali halaman ini.'),
        ),
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
            const Text(
              'Statistik ini menjelaskan kebiasaan analisis, bukan hasil profit trading.',
            ),
            const SizedBox(height: 14),
            if (_loading && _server == null)
              const Center(child: CircularProgressIndicator())
            else if (_error != null && _server == null) ...[
              Text(_error!),
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton(
                  onPressed: _load,
                  child: const Text('Coba lagi'),
                ),
              ),
            ] else if (_server case final data?) ...[
              _MetricGrid(
                values: {
                  'Semua analisis': '${data.totalAllTime}',
                  'Bulan ini': '${data.totalThisMonth}',
                  'Minggu ini': '${data.totalThisWeek}',
                  'Feedback diberikan': '${data.feedbackCount}',
                  'Mode dominan': data.dominantMode ?? '—',
                  'Akurasi outcome': data.accuracyRate == null
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
                        const Text(
                          'Peringkat instrumen',
                          style: TextStyle(fontWeight: FontWeight.w800),
                        ),
                        const SizedBox(height: 8),
                        ...data.topInstruments.map(
                          (item) => ListTile(
                            dense: true,
                            contentPadding: EdgeInsets.zero,
                            leading: const Icon(Icons.query_stats_rounded),
                            title: Text(item.instrument),
                            trailing: Text('${item.count} analisis'),
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
            const Text(
              'Hasil yang sedang dimuat',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 4),
            Text(
              local.isPartial
                  ? 'Hanya menghitung ${local.total} dari ${analysis.historyTotal} analisis. Muat lebih banyak di History untuk memperluas ringkasan.'
                  : 'Menghitung semua ${local.total} analisis yang tersedia di perangkat saat ini.',
              style: const TextStyle(fontSize: 12),
            ),
            const SizedBox(height: 12),
            _MetricGrid(
              values: {
                'Dievaluasi': '${local.evaluated}',
                'Menunggu': '${local.pending}',
                'Outcome positif': '${local.positiveOutcomes}',
                'Outcome negatif': '${local.negativeOutcomes}',
                'Punya catatan': '${local.journaled}',
                'Rata-rata keyakinan': local.averageConfidence == null
                    ? '—'
                    : '${local.averageConfidence!.toStringAsFixed(1)}%',
                'Timeframe teratas': local.topTimeframe ?? '—',
                'Instrumen teratas': local.topInstrument ?? '—',
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
