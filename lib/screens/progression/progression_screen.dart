import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:trade_pilot_api_client/trade_pilot_api_client.dart';

import '../../core/localization/locale_controller.dart';
import '../../l10n/l10n.dart';
import '../../providers/auth_provider.dart';
import '../../providers/progression_provider.dart';
import '../../widgets/progression/progression_emblem.dart';

class ProgressionScreen extends StatefulWidget {
  const ProgressionScreen({super.key});

  @override
  State<ProgressionScreen> createState() => _ProgressionScreenState();
}

class _ProgressionScreenState extends State<ProgressionScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      unawaited(context.read<AuthProvider>().telemetry.pageView('/progression'));
      unawaited(context.read<ProgressionProvider>().refresh());
    });
  }

  @override
  Widget build(BuildContext context) {
    final progression = context.watch<ProgressionProvider>();
    final summary = progression.summary;
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(context.l10n.progressionTitle),
              Text(
                context.l10n.progressionSubtitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
        body: summary == null
            ? _LoadState(progression: progression)
            : Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                    child: _ProgressionHero(summary: summary),
                  ),
                  TabBar(
                    tabs: [
                      Tab(
                        icon: const Icon(Icons.insights_outlined),
                        text: context.l10n.progressionOverview,
                      ),
                      Tab(
                        icon: const Icon(Icons.emoji_events_outlined),
                        text: context.l10n.progressionAchievements,
                      ),
                      Tab(
                        icon: const Icon(Icons.history_rounded),
                        text: context.l10n.progressionHistory,
                      ),
                    ],
                  ),
                  Expanded(
                    child: TabBarView(
                      children: [
                        _OverviewTab(progression: progression),
                        _CatalogTab(progression: progression),
                        _HistoryTab(progression: progression),
                      ],
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

class _LoadState extends StatelessWidget {
  const _LoadState({required this.progression});
  final ProgressionProvider progression;

  @override
  Widget build(BuildContext context) {
    if (progression.isLoading) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 14),
            Text(context.l10n.progressionLoading),
          ],
        ),
      );
    }
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off_outlined, size: 38),
            const SizedBox(height: 12),
            Text(context.l10n.progressionLoadFailed),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: progression.refresh,
              child: Text(context.l10n.tryAgain),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProgressionHero extends StatelessWidget {
  const _ProgressionHero({required this.summary});
  final ProgressionSummary summary;

  @override
  Widget build(BuildContext context) {
    final range = summary.nextLevelXp - summary.currentLevelXp;
    final progress = range <= 0
        ? 1.0
        : ((summary.totalXp - summary.currentLevelXp) / range).clamp(0.0, 1.0);
    final rank = _rankName(summary.rank, _isId(context));
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF241B0B), Color(0xFF11100E)],
        ),
        border: Border.all(color: const Color(0x66F5C219)),
      ),
      child: Row(
        children: [
          ProgressionEmblem(
            level: summary.level,
            masteryLevel: summary.masteryLevel,
            size: 88,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  rank,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Text(
                  summary.masteryLevel > 0
                      ? context.l10n.progressionMastery(summary.masteryLevel)
                      : context.l10n.progressionLevel(summary.level),
                  style: const TextStyle(
                    color: Color(0xFFF5C219),
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${summary.totalXp} XP',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 11,
                      ),
                    ),
                    Text(
                      '${summary.nextLevelXp} XP',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 5),
                LinearProgressIndicator(
                  value: progress,
                  minHeight: 7,
                  borderRadius: BorderRadius.circular(99),
                  backgroundColor: Colors.white12,
                  color: const Color(0xFFF5C219),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    _Streak(
                      label: context.l10n.progressionCurrentStreak,
                      value: summary.currentStreak,
                    ),
                    const SizedBox(width: 12),
                    _Streak(
                      label: context.l10n.progressionLongestStreak,
                      value: summary.longestStreak,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Streak extends StatelessWidget {
  const _Streak({required this.label, required this.value});
  final String label;
  final int value;

  @override
  Widget build(BuildContext context) => Expanded(
    child: Row(
      children: [
        const Icon(
          Icons.local_fire_department_rounded,
          size: 16,
          color: Color(0xFFF59E0B),
        ),
        const SizedBox(width: 4),
        Flexible(
          child: Text(
            '$value · $label',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: Colors.white70, fontSize: 10),
          ),
        ),
      ],
    ),
  );
}

class _OverviewTab extends StatelessWidget {
  const _OverviewTab({required this.progression});
  final ProgressionProvider progression;

  @override
  Widget build(BuildContext context) {
    final achievements =
        progression.catalog?.achievements.toList() ??
        <ProgressionAchievement>[];
    final unlocked = achievements.where((item) => item.unlocked).toList();
    final entries =
        progression.history?.entries.toList() ?? <ProgressionLedgerEntry>[];
    return _RefreshList(
      onRefresh: progression.refresh,
      children: [
        _SectionHeader(
          icon: Icons.emoji_events_outlined,
          title: context.l10n.progressionAchievements,
          trailing: '${unlocked.length} / ${achievements.length}',
        ),
        if (unlocked.isEmpty)
          _EmptyCard(text: context.l10n.progressionNoAchievements)
        else
          ...unlocked.take(3).map((item) => _AchievementCard(item: item)),
        const SizedBox(height: 12),
        _SectionHeader(
          icon: Icons.history_rounded,
          title: context.l10n.progressionHistory,
        ),
        if (entries.isEmpty)
          _EmptyCard(text: context.l10n.progressionNoHistory)
        else
          ...entries.take(5).map((item) => _HistoryCard(item: item)),
        const SizedBox(height: 12),
        Text(
          context.l10n.progressionPrivate,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }
}

class _CatalogTab extends StatelessWidget {
  const _CatalogTab({required this.progression});
  final ProgressionProvider progression;

  @override
  Widget build(BuildContext context) {
    final achievements =
        progression.catalog?.achievements.toList() ??
        <ProgressionAchievement>[];
    return _RefreshList(
      onRefresh: progression.refresh,
      children: achievements.isEmpty
          ? [_EmptyCard(text: context.l10n.progressionNoAchievements)]
          : achievements.map((item) => _AchievementCard(item: item)).toList(),
    );
  }
}

class _HistoryTab extends StatelessWidget {
  const _HistoryTab({required this.progression});
  final ProgressionProvider progression;

  @override
  Widget build(BuildContext context) {
    final entries =
        progression.history?.entries.toList() ?? <ProgressionLedgerEntry>[];
    return _RefreshList(
      onRefresh: progression.refresh,
      children: entries.isEmpty
          ? [_EmptyCard(text: context.l10n.progressionNoHistory)]
          : entries.map((item) => _HistoryCard(item: item)).toList(),
    );
  }
}

class _RefreshList extends StatelessWidget {
  const _RefreshList({required this.onRefresh, required this.children});
  final Future<void> Function() onRefresh;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => RefreshIndicator(
    onRefresh: onRefresh,
    child: ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      children: children,
    ),
  );
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.icon,
    required this.title,
    this.trailing,
  });
  final IconData icon;
  final String title;
  final String? trailing;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Row(
      children: [
        Icon(icon, size: 19, color: Theme.of(context).colorScheme.primary),
        const SizedBox(width: 8),
        Text(title, style: const TextStyle(fontWeight: FontWeight.w900)),
        const Spacer(),
        if (trailing != null)
          Text(trailing!, style: Theme.of(context).textTheme.bodySmall),
      ],
    ),
  );
}

class _AchievementCard extends StatelessWidget {
  const _AchievementCard({required this.item});
  final ProgressionAchievement item;

  @override
  Widget build(BuildContext context) {
    final id = _isId(context);
    return Card(
      color: item.unlocked
          ? Theme.of(context).colorScheme.primary.withValues(alpha: .06)
          : null,
      child: ListTile(
        leading: CircleAvatar(
          child: Icon(
            item.unlocked
                ? _achievementIcon(item.key)
                : Icons.lock_outline_rounded,
          ),
        ),
        title: Text(
          _achievementTitle(item.key, id),
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
        subtitle: Text(
          [
            _achievementDescription(item.key, id),
            if (item.unlockedAt != null)
              context.l10n.progressionUnlocked(
                DateFormat('dd MMM yyyy').format(item.unlockedAt!.toLocal()),
              ),
          ].join('\n'),
        ),
        trailing: item.unlocked
            ? const Icon(Icons.verified_rounded, color: Color(0xFF10B981))
            : Text(
                context.l10n.progressionLocked,
                style: Theme.of(context).textTheme.labelSmall,
              ),
      ),
    );
  }
}

class _HistoryCard extends StatelessWidget {
  const _HistoryCard({required this.item});
  final ProgressionLedgerEntry item;

  @override
  Widget build(BuildContext context) {
    final id = _isId(context);
    return Card(
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: const Color(0xFF10B981).withValues(alpha: .12),
          child: Text(
            '+${item.xp}',
            style: const TextStyle(
              color: Color(0xFF10B981),
              fontSize: 11,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        title: Text(
          context.l10n.progressionActivity(
            item.xp,
            _sourceName(item.source_, id),
          ),
        ),
        subtitle: Text(
          DateFormat('dd MMM yyyy • HH:mm').format(item.createdAt.toLocal()),
        ),
      ),
    );
  }
}

class _EmptyCard extends StatelessWidget {
  const _EmptyCard({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(22),
      child: Center(child: Text(text, textAlign: TextAlign.center)),
    ),
  );
}

bool _isId(BuildContext context) =>
    context.watch<LocaleController>().locale.languageCode == 'id';

String _rankName(String value, bool id) {
  final rank = value.toLowerCase().replaceFirst(RegExp(r'_\d+$'), '');
  const names = {
    'seedling': ['Seedling', 'Pemula'],
    'observer': ['Observer', 'Pengamat'],
    'planner': ['Planner', 'Perencana'],
    'guardian': ['Guardian', 'Penjaga'],
    'navigator': ['Navigator', 'Navigator'],
    'strategist': ['Strategist', 'Ahli Strategi'],
    'sentinel': ['Sentinel', 'Sentinel'],
    'vanguard': ['Vanguard', 'Garda Depan'],
    'steward': ['Steward', 'Pengelola'],
    'apex': ['Apex', 'Puncak'],
    'master': ['Master', 'Master'],
  };
  return names[rank]?[id ? 1 : 0] ?? value;
}

IconData _achievementIcon(String key) {
  if (key.startsWith('guide')) return Icons.menu_book_rounded;
  if (key.startsWith('wait')) return Icons.self_improvement_rounded;
  if (key.startsWith('journal') || key == 'first_reflection') {
    return Icons.star_rounded;
  }
  if (key.startsWith('streak')) return Icons.calendar_month_rounded;
  if (key.startsWith('checklist') || key.startsWith('evaluation')) {
    return Icons.shield_rounded;
  }
  return Icons.emoji_events_rounded;
}

String _sourceName(String source, bool id) => switch (source) {
  'pre_analysis_checklist' =>
    id
        ? 'menyelesaikan checklist pra-analisis'
        : 'completing a pre-analysis checklist',
  'guide_completion' =>
    id ? 'membaca panduan edukasi' : 'reading a guide article',
  'risk_warning_wait' =>
    id ? 'mengindahkan peringatan risiko' : 'acting on a risk warning',
  'quality_journal' =>
    id ? 'menulis jurnal berkualitas' : 'writing a quality journal',
  'analysis_evaluation' =>
    id ? 'mengevaluasi hasil trade' : 'evaluating a trade outcome',
  _ => source.replaceAll('_', ' '),
};

String _achievementTitle(String key, bool id) {
  const names = {
    'first_reflection': ['First Reflection', 'Refleksi Pertama'],
    'journal_5': ['Journaler', 'Jurnalis'],
    'journal_20': ['Dedicated Journaler', 'Jurnalis Dedikasi'],
    'journal_50': ['Master Journaler', 'Master Jurnal'],
    'evaluation_1': ['First Evaluation', 'Evaluasi Pertama'],
    'evaluation_10': ['Evaluator', 'Evaluator'],
    'evaluation_50': ['Master Evaluator', 'Master Evaluasi'],
    'checklist_1': ['Preparation', 'Persiapan'],
    'checklist_10': ['Checklist Routine', 'Rutinitas Checklist'],
    'checklist_50': ['Checklist Master', 'Master Checklist'],
    'guide_1': ['Student', 'Pelajar'],
    'guide_5': ['Scholar', 'Sarjana'],
    'guide_10': ['Professor', 'Profesor'],
    'wait_1': ['Patience', 'Kesabaran'],
    'wait_10': ['Zen Master', 'Zen Master'],
    'streak_3': ['Momentum', 'Momentum'],
    'streak_7': ['Routine', 'Rutinitas'],
    'streak_30': ['Dedication', 'Dedikasi'],
    'level_10': ['Bronze Pilot', 'Pilot Perunggu'],
    'level_25': ['Silver Pilot', 'Pilot Perak'],
    'level_50': ['Gold Pilot', 'Pilot Emas'],
    'level_75': ['Platinum Pilot', 'Pilot Platinum'],
    'level_100': ['Obsidian Pilot', 'Pilot Obsidian'],
    'mastery_1': ['Mastery', 'Mastery'],
    'consistent_1000': ['Unshakable', 'Tak Tergoyahkan'],
  };
  return names[key]?[id ? 1 : 0] ?? key.replaceAll('_', ' ');
}

String _achievementDescription(String key, bool id) {
  if (key == 'first_reflection') {
    return id
        ? 'Tulis jurnal pertamamu.'
        : 'Complete your first journal entry.';
  }
  if (key == 'mastery_1') {
    return id ? 'Capai Mastery Level 1.' : 'Reach Mastery Level 1.';
  }
  if (key == 'consistent_1000') {
    return id ? 'Kumpulkan total 1000 XP.' : 'Earn a total of 1000 XP.';
  }
  final parts = key.split('_');
  final count = parts.last;
  return switch (parts.first) {
    'journal' =>
      id ? 'Tulis $count entri jurnal.' : 'Write $count journal entries.',
    'evaluation' =>
      id ? 'Evaluasi $count hasil trade.' : 'Evaluate $count trade outcomes.',
    'checklist' =>
      id
          ? 'Selesaikan $count checklist pra-analisis.'
          : 'Complete $count pre-analysis checklists.',
    'guide' =>
      id ? 'Baca $count artikel panduan.' : 'Read $count guide articles.',
    'wait' =>
      id
          ? 'Tahan diri (wait) $count kali saat risiko tinggi.'
          : 'Wait safely $count times during high risk.',
    'streak' =>
      id
          ? 'Beraktivitas $count hari berturut-turut.'
          : 'Achieve a $count-day streak.',
    'level' => id ? 'Capai Level $count.' : 'Reach Level $count.',
    _ => key.replaceAll('_', ' '),
  };
}
