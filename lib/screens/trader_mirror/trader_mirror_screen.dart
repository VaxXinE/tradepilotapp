import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:trade_pilot_api_client/trade_pilot_api_client.dart';

import '../../core/mindset/mindset_engine.dart';
import '../../providers/analysis_provider.dart';
import '../../providers/auth_provider.dart';

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
        setState(() => _error = 'Trader Mirror belum dapat dimuat.');
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
        appBar: AppBar(title: const Text('Trader Mirror')),
        body: const Center(
          child: Text('Sesi berubah. Buka kembali halaman ini.'),
        ),
      );
    }
    final analysis = context.watch<AnalysisProvider>();
    final reflections = const MindsetEngine().evaluate(analysis.history);
    final data = _data;
    return Scaffold(
      appBar: AppBar(title: const Text('Trader Mirror')),
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
                      child: const Text('Coba lagi'),
                    ),
                  ),
                ],
              )
            : ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  const Text(
                    'Cermin kebiasaan ini bersifat retrospektif dan tidak memberikan instruksi trading.',
                  ),
                  const SizedBox(height: 16),
                  if (data!.highlights.isEmpty)
                    const Card(
                      child: Padding(
                        padding: EdgeInsets.all(16),
                        child: Text('Belum cukup data untuk membuat sorotan.'),
                      ),
                    )
                  else
                    ...data.highlights.map(
                      (highlight) => Card(
                        child: ListTile(
                          leading: const Icon(Icons.auto_awesome_outlined),
                          title: Text(highlight.idText),
                        ),
                      ),
                    ),
                  const SizedBox(height: 18),
                  Text(
                    'Cakupan ${data.insights.windowDays} hari · ${data.insights.totalResolved} evaluasi selesai',
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 8),
                  _GateRow(
                    label: 'Sesi pasar',
                    insight: data.insights.sessions,
                  ),
                  _GateRow(
                    label: 'Konsentrasi instrumen',
                    insight: data.insights.instruments,
                  ),
                  _GateRow(
                    label: 'Waktu analisis',
                    insight: data.insights.timing,
                  ),
                  _GateRow(
                    label: 'Pola setelah outcome negatif',
                    insight: data.insights.postLoss,
                  ),
                  _GateRow(
                    label: 'Disiplin evaluasi',
                    insight: data.insights.exitDiscipline,
                  ),
                  const SizedBox(height: 22),
                  const Text(
                    'Refleksi proses',
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900),
                  ),
                  Text(
                    'Berdasarkan ${analysis.history.length} analisis yang sedang dimuat di perangkat.',
                    style: const TextStyle(fontSize: 12),
                  ),
                  const SizedBox(height: 8),
                  if (reflections.isEmpty)
                    const Card(
                      child: Padding(
                        padding: EdgeInsets.all(16),
                        child: Text(
                          'Butuh sedikitnya 3 analisis untuk refleksi yang cukup hati-hati.',
                        ),
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
    return ListTile(
      dense: true,
      leading: Icon(
        insight.gated ? Icons.lock_clock_outlined : Icons.check_circle_outline,
      ),
      title: Text(label),
      subtitle: Text(
        insight.gated
            ? 'Perlu ${insight.need ?? 'lebih banyak'} data; tersedia ${insight.have ?? 0}.'
            : 'Data cukup. Sorotan terverifikasi ditampilkan di atas.',
      ),
    );
  }
}
