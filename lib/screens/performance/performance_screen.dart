import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:trade_pilot_api_client/trade_pilot_api_client.dart';

import '../../providers/auth_provider.dart';

class PerformanceScreen extends StatefulWidget {
  const PerformanceScreen({super.key});

  @override
  State<PerformanceScreen> createState() => _PerformanceScreenState();
}

class _PerformanceScreenState extends State<PerformanceScreen> {
  int _window = 30;
  PerformanceSummary? _summary;
  bool _loading = true;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(
        context.read<AuthProvider>().telemetry.pageView('/performance'),
      );
      unawaited(_load());
    });
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _failed = false;
    });
    try {
      final response = await context
          .read<AuthProvider>()
          .client
          .performance
          .getPerformanceSummary(window: _window);
      if (mounted) setState(() => _summary = response.data);
    } catch (_) {
      if (mounted) setState(() => _failed = true);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _selectWindow(int value) {
    if (value == _window) return;
    setState(() {
      _window = value;
      _summary = null;
    });
    unawaited(_load());
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Kinerja AI Publik'),
      actions: [
        IconButton(
          tooltip: 'Metodologi',
          onPressed: _showMethodology,
          icon: const Icon(Icons.info_outline_rounded),
        ),
      ],
    ),
    body: RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'Rekam jejak anonim seluruh analisis AI Trade Pilot. Ini bukan statistik akun pribadi.',
            style: TextStyle(fontSize: 12.5),
          ),
          const SizedBox(height: 12),
          SegmentedButton<int>(
            segments: const [
              ButtonSegment(value: 30, label: Text('30 hari')),
              ButtonSegment(value: 90, label: Text('90 hari')),
            ],
            selected: {_window},
            onSelectionChanged: (value) => _selectWindow(value.first),
          ),
          const SizedBox(height: 14),
          if (_loading)
            const Padding(
              padding: EdgeInsets.all(48),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (_failed || _summary == null)
            _ErrorCard(onRetry: _load)
          else
            ..._summaryWidgets(_summary!),
        ],
      ),
    ),
  );

  List<Widget> _summaryWidgets(PerformanceSummary summary) {
    if (summary.overall.total < summary.minSamples.overall) {
      return [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              'Data belum cukup untuk ditampilkan secara bertanggung jawab. '
              'Butuh ${summary.minSamples.overall} hasil; saat ini ${summary.overall.total}.',
            ),
          ),
        ),
      ];
    }
    return [
      _HonestyBanner(banner: summary.banner),
      const SizedBox(height: 10),
      _OverallCard(summary: summary),
      const SizedBox(height: 10),
      _SegmentCard(
        title: 'Per instrumen',
        icon: Icons.show_chart,
        segment: summary.byInstrument,
      ),
      const SizedBox(height: 10),
      _SegmentCard(
        title: 'Per sesi pasar',
        icon: Icons.schedule,
        segment: summary.bySession,
      ),
      const SizedBox(height: 10),
      _SegmentCard(
        title: 'Per kondisi pasar',
        icon: Icons.calendar_today_outlined,
        segment: summary.byCondition,
      ),
      const SizedBox(height: 10),
      _SegmentCard(
        title: 'Per volatilitas',
        icon: Icons.monitor_heart_outlined,
        segment: summary.byVolatility,
      ),
      const SizedBox(height: 10),
      _SegmentCard(
        title: 'Aktivitas berita',
        icon: Icons.newspaper_outlined,
        segment: summary.byNewsActivity,
      ),
    ];
  }

  Future<void> _showMethodology() => showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (context) => const SafeArea(
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(20, 4, 20, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Metodologi kinerja',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
            ),
            SizedBox(height: 14),
            _Method(
              'Apa yang dihitung',
              'Hanya analisis yang hasilnya sudah terselesaikan. Data pengguna dianonimkan dan digabung.',
            ),
            _Method(
              'Win rate dan hit rate',
              'Win rate membandingkan menang dengan kalah pada trade yang terpicu. Hit rate juga memasukkan analisis kedaluwarsa.',
            ),
            _Method(
              'Batas sampel',
              'Segmen dengan sampel kecil disembunyikan agar tidak menyesatkan atau membocorkan aktivitas kelompok kecil.',
            ),
            _Method(
              'Yang tidak termasuk',
              'Angka tidak memperhitungkan ukuran posisi, spread, slippage, biaya, pajak, atau keputusan eksekusi pengguna.',
            ),
            Text(
              'Kinerja masa lalu tidak menjamin hasil berikutnya.',
              style: TextStyle(fontWeight: FontWeight.w800),
            ),
          ],
        ),
      ),
    ),
  );
}

class _HonestyBanner extends StatelessWidget {
  const _HonestyBanner({required this.banner});
  final PerformanceBanner banner;

  @override
  Widget build(BuildContext context) {
    final severity = banner.severity.name;
    final color = severity == 'warn'
        ? const Color(0xFFEF4444)
        : severity == 'watch'
        ? const Color(0xFFF59E0B)
        : const Color(0xFF10B981);
    final title = severity == 'warn'
        ? 'Kinerja terbaru menurun'
        : severity == 'watch'
        ? 'Kinerja terbaru perlu dipantau'
        : 'Kinerja terbaru stabil';
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .10),
        border: Border.all(color: color.withValues(alpha: .40)),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.shield_outlined, color: color),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 3),
                Text(
                  '${banner.recentDays} hari terbaru: ${_percent(banner.recentHitRate)} · '
                  'baseline: ${_percent(banner.baselineHitRate)}.',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _OverallCard extends StatelessWidget {
  const _OverallCard({required this.summary});
  final PerformanceSummary summary;

  @override
  Widget build(BuildContext context) {
    final overall = summary.overall;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Ringkasan $_windowLabel',
              style: const TextStyle(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _BigMetric(
                    label: 'Win rate',
                    value: _percent(overall.winRate),
                    color: const Color(0xFF10B981),
                  ),
                ),
                Expanded(
                  child: _BigMetric(
                    label: 'Hit rate',
                    value: _percent(overall.hitRate),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _HitBar(
              wins: overall.wins,
              losses: overall.losses,
              expired: overall.expired,
            ),
            const SizedBox(height: 7),
            Text(
              '${overall.wins} menang · ${overall.losses} kalah · ${overall.expired} kedaluwarsa · ${overall.total} sampel',
              style: Theme.of(context).textTheme.labelSmall,
            ),
            Text(
              'Sejak ${DateFormat('d MMM yyyy').format(summary.windowStart.toLocal())}',
              style: Theme.of(context).textTheme.labelSmall,
            ),
          ],
        ),
      ),
    );
  }

  String get _windowLabel =>
      summary.windowDays == PerformanceSummaryWindowDaysEnum.number90
      ? '90 hari'
      : '30 hari';
}

class _SegmentCard extends StatelessWidget {
  const _SegmentCard({
    required this.title,
    required this.icon,
    required this.segment,
  });
  final String title;
  final IconData icon;
  final PerformanceSegment segment;

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(icon, size: 18),
              const SizedBox(width: 8),
              Text(title, style: const TextStyle(fontWeight: FontWeight.w900)),
            ],
          ),
          const SizedBox(height: 10),
          if (segment.gated)
            Text('Data belum cukup: ${segment.have}/${segment.need} sampel.')
          else
            ...segment.buckets.map(
              (bucket) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            _bucketLabel(bucket.key),
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                        ),
                        Text(
                          _percent(bucket.hitRate),
                          style: const TextStyle(fontWeight: FontWeight.w900),
                        ),
                      ],
                    ),
                    const SizedBox(height: 5),
                    _HitBar(
                      wins: bucket.wins,
                      losses: bucket.losses,
                      expired: bucket.expired,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${bucket.wins} menang · ${bucket.losses} kalah · ${bucket.expired} kedaluwarsa',
                      style: Theme.of(context).textTheme.labelSmall,
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    ),
  );
}

class _HitBar extends StatelessWidget {
  const _HitBar({
    required this.wins,
    required this.losses,
    required this.expired,
  });
  final int wins;
  final int losses;
  final int expired;

  @override
  Widget build(BuildContext context) {
    final total = wins + losses + expired;
    if (total == 0) {
      return Container(height: 8, color: Theme.of(context).dividerColor);
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(99),
      child: Row(
        children: [
          if (wins > 0)
            Expanded(
              flex: wins,
              child: Container(height: 8, color: const Color(0xFF10B981)),
            ),
          if (losses > 0)
            Expanded(
              flex: losses,
              child: Container(height: 8, color: const Color(0xFFEF4444)),
            ),
          if (expired > 0)
            Expanded(
              flex: expired,
              child: Container(height: 8, color: Colors.grey),
            ),
        ],
      ),
    );
  }
}

class _BigMetric extends StatelessWidget {
  const _BigMetric({required this.label, required this.value, this.color});
  final String label;
  final String value;
  final Color? color;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(label, style: Theme.of(context).textTheme.bodySmall),
      Text(
        value,
        style: TextStyle(
          fontSize: 25,
          fontWeight: FontWeight.w900,
          color: color,
        ),
      ),
    ],
  );
}

class _ErrorCard extends StatelessWidget {
  const _ErrorCard({required this.onRetry});
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          const Text('Data kinerja belum dapat dimuat.'),
          TextButton(onPressed: onRetry, child: const Text('Coba lagi')),
        ],
      ),
    ),
  );
}

class _Method extends StatelessWidget {
  const _Method(this.title, this.body);
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 14),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
        const SizedBox(height: 3),
        Text(body),
      ],
    ),
  );
}

String _percent(num? value) =>
    value == null ? '—' : '${(value * 100).round()}%';

String _bucketLabel(String value) => switch (value) {
  'asia' => 'Asia',
  'london' => 'London',
  'newyork' => 'New York',
  'off_session' => 'Di luar sesi utama',
  'trending_up' => 'Tren naik',
  'trending_down' => 'Tren turun',
  'ranging' => 'Ranging',
  'volatile' => 'Volatil',
  'trending' => 'Trending',
  'choppy' => 'Choppy',
  'news_week' => 'Minggu aktif berita',
  'quiet_week' => 'Minggu tenang',
  _ => value,
};
