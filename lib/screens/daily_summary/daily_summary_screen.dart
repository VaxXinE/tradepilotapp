import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:trade_pilot_api_client/trade_pilot_api_client.dart';

import '../../providers/auth_provider.dart';
import '../analysis/analysis_detail_screen.dart';

class DailySummaryScreen extends StatefulWidget {
  const DailySummaryScreen({super.key});

  @override
  State<DailySummaryScreen> createState() => _DailySummaryScreenState();
}

class _DailySummaryScreenState extends State<DailySummaryScreen> {
  DailySummaryResponse? _data;
  bool _loading = true;
  bool _saving = false;
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
      final response = await auth.client.dailySummary.getDailySummary();
      if (!mounted || auth.user?.id != userId) return;
      setState(() {
        _data = response.data;
        _error = null;
      });
    } catch (_) {
      if (mounted && auth.user?.id == userId) {
        setState(() => _error = 'Ringkasan harian belum dapat dimuat.');
      }
    } finally {
      if (mounted && auth.user?.id == userId) setState(() => _loading = false);
    }
  }

  Future<void> _update({bool? enabled, String? time}) async {
    if (_saving || _data == null) return;
    final auth = context.read<AuthProvider>();
    final userId = auth.user?.id;
    setState(() => _saving = true);
    try {
      final response = await auth.client.dailySummary
          .updateDailySummarySettings(
            dailySummarySettingsUpdate: DailySummarySettingsUpdate(
              (builder) => builder
                ..enabled = enabled
                ..time = time
                ..timezone = _data!.settings.timezone,
            ),
          );
      if (!mounted || auth.user?.id != userId || response.data == null) return;
      setState(() {
        _data = _data!.rebuild(
          (builder) => builder.settings.replace(response.data!),
        );
      });
    } catch (_) {
      if (mounted && auth.user?.id == userId) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Pengaturan ringkasan gagal disimpan.')),
        );
      }
    } finally {
      if (mounted && auth.user?.id == userId) setState(() => _saving = false);
    }
  }

  Future<void> _pickTime() async {
    final value = _data?.settings.time.split(':');
    final selected = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(
        hour: int.tryParse(value?.first ?? '') ?? 8,
        minute: int.tryParse(value?.last ?? '') ?? 0,
      ),
    );
    if (selected != null && mounted) {
      await _update(
        time:
            '${selected.hour.toString().padLeft(2, '0')}:${selected.minute.toString().padLeft(2, '0')}',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUserId = context.watch<AuthProvider>().user?.id;
    if (_ownerUserId != null && currentUserId != _ownerUserId) {
      return Scaffold(
        appBar: AppBar(title: const Text('Ringkasan Harian')),
        body: const Center(
          child: Text('Sesi berubah. Buka kembali halaman ini.'),
        ),
      );
    }
    final data = _data;
    return Scaffold(
      appBar: AppBar(title: const Text('Ringkasan Harian')),
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
                  SwitchListTile.adaptive(
                    value: data!.settings.enabled,
                    onChanged: _saving
                        ? null
                        : (value) => _update(enabled: value),
                    title: const Text('Ringkasan harian'),
                    subtitle: Text('Zona waktu: ${data.settings.timezone}'),
                  ),
                  ListTile(
                    enabled: !_saving && data.settings.enabled,
                    leading: const Icon(Icons.schedule_outlined),
                    title: const Text('Waktu pengiriman'),
                    subtitle: Text(data.settings.time),
                    onTap: _pickTime,
                  ),
                  const Divider(),
                  if (data.today case final today?) ...[
                    Text(
                      today.digestDate,
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 8),
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Text(
                          today.summary,
                          style: const TextStyle(height: 1.5),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    ...today.analyses.map(
                      (analysis) => Card(
                        child: ListTile(
                          title: Text(
                            '${analysis.instrument} · ${analysis.timeframe}',
                          ),
                          subtitle: const Text(
                            'Buka analisis untuk melihat konteks lengkap.',
                          ),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) =>
                                  AnalysisDetailScreen(analysisId: analysis.id),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ] else
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 56),
                      child: Column(
                        children: [
                          Icon(Icons.today_outlined, size: 48),
                          SizedBox(height: 12),
                          Text('Belum ada ringkasan untuk hari ini.'),
                        ],
                      ),
                    ),
                ],
              ),
      ),
    );
  }
}
