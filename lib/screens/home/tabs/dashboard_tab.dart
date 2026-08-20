import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:trade_pilot_api_client/trade_pilot_api_client.dart';

import '../../../core/theme/app_colors.dart';
import '../../../providers/analysis_provider.dart';
import '../../../providers/auth_provider.dart';
import '../../../widgets/analysis_card.dart';
import '../../analysis/analysis_detail_screen.dart';
import '../../notifications/notifications_screen.dart';

class DashboardTab extends StatefulWidget {
  const DashboardTab({super.key});

  @override
  State<DashboardTab> createState() => _DashboardTabState();
}

class _DashboardTabState extends State<DashboardTab> {
  AnalysesSummary? _summary;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    final analysisProvider = context.read<AnalysisProvider>();
    setState(() => _loading = true);
    final summary = await analysisProvider.getSummary();
    await analysisProvider.loadQuota();
    if (!mounted) return;
    setState(() {
      _summary = summary;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final muted = isDark ? AppColors.darkMutedForeground : AppColors.lightMutedForeground;
    final auth = context.watch<AuthProvider>();
    final analysisProvider = context.watch<AnalysisProvider>();
    final user = auth.user;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const NotificationsScreen()),
            ),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(
              'Halo, ${user?.displayName ?? ''} 👋',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 4),
            Text(
              user?.selectedMode == UserSelectedModeEnum.pro ? 'Mode Pro' : 'Mode Pemula',
              style: TextStyle(color: muted),
            ),
            const SizedBox(height: 20),
            if (_loading)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 40),
                child: Center(child: CircularProgressIndicator()),
              )
            else ...[
              _StatsRow(summary: _summary),
              const SizedBox(height: 16),
              if (analysisProvider.quota != null) _QuotaCard(quota: analysisProvider.quota!),
              const SizedBox(height: 24),
              Text('Analisis Terbaru', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
              const SizedBox(height: 12),
              if ((_summary?.recentAnalyses.isEmpty ?? true))
                _EmptyRecent(muted: muted)
              else
                ...(_summary!.recentAnalyses.map(
                  (a) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: AnalysisCard(
                      analysis: a,
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => AnalysisDetailScreen(analysisId: a.id)),
                      ),
                    ),
                  ),
                )),
            ],
          ],
        ),
      ),
    );
  }
}

class _StatsRow extends StatelessWidget {
  const _StatsRow({required this.summary});
  final AnalysesSummary? summary;

  @override
  Widget build(BuildContext context) {
    final total = summary?.totalAnalyses ?? 0;
    final beginner = summary?.beginnerCount ?? 0;
    final pro = summary?.proCount ?? 0;
    return Row(
      children: [
        Expanded(child: _StatCard(label: 'Total Analisis', value: '$total', icon: Icons.insert_chart_outlined_rounded)),
        const SizedBox(width: 10),
        Expanded(child: _StatCard(label: 'Pemula', value: '$beginner', icon: Icons.school_outlined)),
        const SizedBox(width: 10),
        Expanded(child: _StatCard(label: 'Pro', value: '$pro', icon: Icons.workspace_premium_outlined)),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({required this.label, required this.value, required this.icon});
  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = isDark ? AppColors.darkPrimary : AppColors.lightPrimary;
    final muted = isDark ? AppColors.darkMutedForeground : AppColors.lightMutedForeground;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: primary, size: 20),
            const SizedBox(height: 10),
            Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
            const SizedBox(height: 2),
            Text(label, style: TextStyle(fontSize: 11.5, color: muted)),
          ],
        ),
      ),
    );
  }
}

class _QuotaCard extends StatelessWidget {
  const _QuotaCard({required this.quota});
  final AnalysisQuota quota;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = isDark ? AppColors.darkPrimary : AppColors.lightPrimary;
    final muted = isDark ? AppColors.darkMutedForeground : AppColors.lightMutedForeground;

    if (quota.unlimited) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Icon(Icons.all_inclusive_rounded, color: primary),
              const SizedBox(width: 10),
              const Text('Kuota analisis tidak terbatas', style: TextStyle(fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Kuota Analisis', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
            const SizedBox(height: 10),
            _QuotaBar(label: 'Per jam', used: quota.hourly.used, limit: quota.hourly.limit, primary: primary, muted: muted),
            const SizedBox(height: 8),
            _QuotaBar(label: 'Per hari', used: quota.daily.used, limit: quota.daily.limit, primary: primary, muted: muted),
          ],
        ),
      ),
    );
  }
}

class _QuotaBar extends StatelessWidget {
  const _QuotaBar({
    required this.label,
    required this.used,
    required this.limit,
    required this.primary,
    required this.muted,
  });
  final String label;
  final int used;
  final int limit;
  final Color primary;
  final Color muted;

  @override
  Widget build(BuildContext context) {
    final ratio = limit == 0 ? 0.0 : (used / limit).clamp(0, 1).toDouble();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: TextStyle(fontSize: 12, color: muted)),
            Text('$used / $limit', style: TextStyle(fontSize: 12, color: muted)),
          ],
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: LinearProgressIndicator(
            value: ratio,
            minHeight: 6,
            backgroundColor: muted.withValues(alpha: 0.15),
            valueColor: AlwaysStoppedAnimation(primary),
          ),
        ),
      ],
    );
  }
}

class _EmptyRecent extends StatelessWidget {
  const _EmptyRecent({required this.muted});
  final Color muted;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Icon(Icons.insights_outlined, size: 32, color: muted),
            const SizedBox(height: 8),
            Text('Belum ada analisis', style: TextStyle(color: muted)),
          ],
        ),
      ),
    );
  }
}
