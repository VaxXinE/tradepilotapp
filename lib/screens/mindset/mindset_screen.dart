import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:trade_pilot_api_client/trade_pilot_api_client.dart';

import '../../core/localization/locale_controller.dart';
import '../../l10n/l10n.dart';
import '../../providers/auth_provider.dart';
import '../../providers/progression_provider.dart';
import '../../widgets/responsive_page.dart';

class MindsetScreen extends StatefulWidget {
  const MindsetScreen({this.initialGuideId, this.embedded = false, super.key});

  final ProgressionEvidenceStartInputGuideIdEnum? initialGuideId;

  /// Ketika dipakai sebagai tab di dalam app shell, header dan footer
  /// aplikasi sudah disediakan oleh shell sehingga AppBar tidak dipakai.
  final bool embedded;

  @override
  State<MindsetScreen> createState() => _MindsetScreenState();
}

class _MindsetScreenState extends State<MindsetScreen> {
  String _query = '';
  String? _selectedCategory;
  bool _openedInitialGuide = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final guideId = widget.initialGuideId;
    if (_openedInitialGuide || guideId == null) return;
    _openedInitialGuide = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      for (final module in _modules) {
        if (module.guideId != guideId) continue;
        final id = context.read<LocaleController>().locale.languageCode == 'id';
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => _MindsetModuleScreen(
              module: module,
              id: id,
              initiallyCompleted: context
                  .read<ProgressionProvider>()
                  .completedGuideIds
                  .contains(module.guideKey),
            ),
          ),
        );
        break;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final id = context.watch<LocaleController>().locale.languageCode == 'id';
    final filtered = _modules.where((module) {
      final query = _query.trim().toLowerCase();
      if (query.isEmpty) return true;
      return '${id ? module.titleId : module.titleEn} '
              '${id ? module.summaryId : module.summaryEn}'
          .toLowerCase()
          .contains(query);
    }).toList();
    final allCategories = _modules.map((module) => module.category).toSet();
    final visible = _selectedCategory == null
        ? filtered
        : filtered
              .where((module) => module.category == _selectedCategory)
              .toList();
    final categories = visible.map((module) => module.category).toSet();
    final l10n = context.l10n;
    final completedGuideIds = context
        .watch<ProgressionProvider?>()
        ?.completedGuideIds;
    final quickStart = [
      _modules.firstWhere(
        (module) =>
            module.guideId ==
            ProgressionEvidenceStartInputGuideIdEnum.analysisWorkflow,
      ),
      _modules.firstWhere(
        (module) => module.titleEn == 'Using History & Performance',
      ),
      _modules.firstWhere(
        (module) =>
            module.guideId ==
            ProgressionEvidenceStartInputGuideIdEnum.adaptivePositionPlan,
      ),
    ];

    void openModule(_MindsetModule module) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => _MindsetModuleScreen(
            module: module,
            id: id,
            initiallyCompleted:
                completedGuideIds?.contains(module.guideKey) == true,
          ),
        ),
      );
    }

    return Scaffold(
      appBar: widget.embedded ? null : AppBar(title: Text(l10n.guide)),
      body: ListView(
        key: ValueKey('guide-${_selectedCategory ?? 'all'}-${_query.isEmpty}'),
        padding: responsivePagePadding(context),
        children: [
          if (widget.embedded) ...[
            Text(
              l10n.guide,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 2),
            Text(
              l10n.guideSubtitle,
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 14),
          ],
          TextField(
            onChanged: (value) => setState(() => _query = value),
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.search_rounded),
              hintText: l10n.guideSearchHint,
            ),
          ),
          const SizedBox(height: 12),
          if (_query.trim().isEmpty && _selectedCategory == null) ...[
            Text(
              l10n.guideQuickStart,
              style: Theme.of(
                context,
              ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 2),
            Text(
              l10n.guideQuickStartHint,
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 8),
            for (var index = 0; index < quickStart.length; index++) ...[
              Card(
                clipBehavior: Clip.antiAlias,
                child: ListTile(
                  key: ValueKey(
                    'guide-quick-start-${quickStart[index].guideKey ?? index}',
                  ),
                  leading: CircleAvatar(child: Text('${index + 1}')),
                  title: Text(
                    id ? quickStart[index].titleId : quickStart[index].titleEn,
                  ),
                  trailing:
                      completedGuideIds?.contains(quickStart[index].guideKey) ==
                          true
                      ? const Icon(
                          Icons.check_circle_rounded,
                          color: Colors.green,
                        )
                      : const Icon(Icons.chevron_right_rounded),
                  onTap: () => openModule(quickStart[index]),
                ),
              ),
              const SizedBox(height: 6),
            ],
            const SizedBox(height: 6),
          ],
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(l10n.all),
                    selected: _selectedCategory == null,
                    onSelected: (_) => setState(() => _selectedCategory = null),
                  ),
                ),
                for (final category in allCategories)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      avatar: Icon(_categoryIcon(category), size: 16),
                      label: Text(_categoryName(category, id)),
                      selected: _selectedCategory == category,
                      onSelected: (_) =>
                          setState(() => _selectedCategory = category),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          if (visible.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 40),
              child: Text(
                l10n.guideNoResults,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          for (final category in categories) ...[
            Padding(
              padding: const EdgeInsets.only(top: 4, bottom: 8),
              child: Text(
                _categoryName(category, id),
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
              ),
            ),
            for (final module in visible.where(
              (item) => item.category == category,
            )) ...[
              Card(
                clipBehavior: Clip.antiAlias,
                child: ListTile(
                  leading: Icon(_categoryIcon(category)),
                  title: Text(id ? module.titleId : module.titleEn),
                  subtitle: Text(id ? module.summaryId : module.summaryEn),
                  trailing: completedGuideIds?.contains(module.guideKey) == true
                      ? const Icon(
                          Icons.check_circle_rounded,
                          color: Colors.green,
                        )
                      : const Icon(Icons.chevron_right_rounded),
                  onTap: () => openModule(module),
                ),
              ),
              const SizedBox(height: 8),
            ],
          ],
          Padding(
            padding: const EdgeInsets.all(12),
            child: Text(
              l10n.mindsetDisclaimer,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  String _categoryName(String category, bool id) => switch (category) {
    'getting-started' =>
      id ? 'Panduan Awal & Fitur' : 'Getting Started & Features',
    'analysis-manual' => id ? 'Manual Analisis' : 'Analysis Manual',
    'glossary' => id ? 'Glosarium' : 'Glossary',
    'privacy' => id ? 'Data & Privasi' : 'Data & Privacy',
    _ => id ? 'Psikologi & Disiplin' : 'Psychology & Discipline',
  };

  IconData _categoryIcon(String category) => switch (category) {
    'getting-started' => Icons.lightbulb_outline_rounded,
    'analysis-manual' => Icons.candlestick_chart_rounded,
    'glossary' => Icons.menu_book_outlined,
    'privacy' => Icons.shield_outlined,
    _ => Icons.psychology_alt_outlined,
  };
}

class _MindsetModuleScreen extends StatefulWidget {
  const _MindsetModuleScreen({
    required this.module,
    required this.id,
    required this.initiallyCompleted,
  });
  final _MindsetModule module;
  final bool id;
  final bool initiallyCompleted;

  @override
  State<_MindsetModuleScreen> createState() => _MindsetModuleScreenState();
}

class _MindsetModuleScreenState extends State<_MindsetModuleScreen> {
  ProgressionEvidenceSession? _evidence;
  Timer? _timer;
  bool _isStarting = false;
  bool _isCompleting = false;
  bool _completed = false;

  @override
  void initState() {
    super.initState();
    _completed = widget.initiallyCompleted;
    if (widget.module.guideId != null && !_completed) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _startEvidence());
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _startEvidence() async {
    setState(() => _isStarting = true);
    try {
      final response = await context
          .read<AuthProvider>()
          .client
          .progression
          .startProgressionEvidence(
            progressionEvidenceStartInput: ProgressionEvidenceStartInput(
              (b) => b
                ..source_ =
                    ProgressionEvidenceStartInputSource_Enum.guideCompletion
                ..guideId = widget.module.guideId,
            ),
          );
      if (!mounted) return;
      setState(() => _evidence = response.data);
      _timer = Timer.periodic(const Duration(seconds: 1), (_) {
        if (mounted) setState(() {});
      });
    } catch (_) {
      // Artikel tetap bisa dibaca ketika XP sudah pernah diklaim/tidak tersedia.
    } finally {
      if (mounted) setState(() => _isStarting = false);
    }
  }

  Future<void> _complete() async {
    final evidence = _evidence;
    if (evidence == null || !_canComplete || _isCompleting) return;
    setState(() => _isCompleting = true);
    try {
      final award =
          (await context
                  .read<AuthProvider>()
                  .client
                  .progression
                  .recordProgressionActivity(
                    progressionActivityInput: ProgressionActivityInput(
                      (b) => b.token = evidence.token,
                    ),
                  ))
              .data;
      if (!mounted) return;
      setState(() => _completed = true);
      if (award?.awarded == true) {
        unawaited(context.read<ProgressionProvider>().refresh(silent: true));
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            award?.awarded == true
                ? context.l10n.xpAwarded(award!.xp, context.l10n.guide)
                : context.l10n.guideComplete,
          ),
        ),
      );
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n.guideProgressFailed)),
        );
      }
    } finally {
      if (mounted) setState(() => _isCompleting = false);
    }
  }

  bool get _canComplete =>
      _evidence != null &&
      !DateTime.now().isBefore(_evidence!.minimumCompleteAt);

  @override
  Widget build(BuildContext context) {
    final module = widget.module;
    final id = widget.id;
    final points = id ? module.pointsId : module.pointsEn;
    return Scaffold(
      appBar: AppBar(title: Text(id ? module.titleId : module.titleEn)),
      body: ListView(
        padding: responsivePagePadding(context, horizontal: 20),
        children: [
          Text(
            id ? module.bodyId : module.bodyEn,
            style: const TextStyle(fontSize: 16, height: 1.55),
          ),
          const SizedBox(height: 18),
          ...points.map(
            (point) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.only(top: 6),
                    child: Icon(Icons.circle, size: 7),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(point, style: const TextStyle(height: 1.45)),
                  ),
                ],
              ),
            ),
          ),
          if (module.guideId != null) ...[
            const SizedBox(height: 18),
            FilledButton.icon(
              onPressed: _completed || !_canComplete || _isCompleting
                  ? null
                  : _complete,
              icon: _isStarting || _isCompleting
                  ? const SizedBox.square(
                      dimension: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.check_circle_outline_rounded),
              label: Text(context.l10n.guideComplete),
            ),
            if (!_canComplete && !_completed) ...[
              const SizedBox(height: 8),
              Text(
                context.l10n.guideReading,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ],
        ],
      ),
    );
  }
}

class _MindsetModule {
  const _MindsetModule({
    required this.titleEn,
    required this.titleId,
    required this.summaryEn,
    required this.summaryId,
    required this.bodyEn,
    required this.bodyId,
    required this.pointsEn,
    required this.pointsId,
    this.category = 'psychology',
    this.guideId,
  });
  final String titleEn;
  final String titleId;
  final String summaryEn;
  final String summaryId;
  final String bodyEn;
  final String bodyId;
  final List<String> pointsEn;
  final List<String> pointsId;
  final String category;
  final ProgressionEvidenceStartInputGuideIdEnum? guideId;

  String? get guideKey => guideId?.name
      .replaceAllMapped(
        RegExp(r'([a-z0-9])([A-Z])'),
        (match) => '${match[1]}-${match[2]}',
      )
      .toLowerCase();
}

const _modules = [
  _MindsetModule(
    category: 'getting-started',
    guideId: ProgressionEvidenceStartInputGuideIdEnum.howAiWorks,
    titleEn: 'How the AI Analysis Works',
    titleId: 'Cara Kerja Analisis AI',
    summaryEn: 'How technical and fundamental evidence becomes a trade plan.',
    summaryId: 'Cara bukti teknikal dan fundamental menjadi trade plan.',
    bodyEn:
        'TradePilot scans technical indicators and combines them with current news and economic-calendar data. It returns a structured scenario, not a guaranteed signal.',
    bodyId:
        'TradePilot memindai indikator teknikal lalu menggabungkannya dengan berita terkini dan kalender ekonomi. Hasilnya adalah skenario terstruktur, bukan sinyal yang dijamin.',
    pointsEn: [
      'Review the bias and reasoning.',
      'Check entry, stop-loss, and take-profit together.',
      'Confirm the chart before acting.',
    ],
    pointsId: [
      'Tinjau bias dan alasannya.',
      'Baca entry, stop-loss, dan take-profit sebagai satu paket.',
      'Konfirmasi chart sebelum bertindak.',
    ],
  ),
  _MindsetModule(
    category: 'getting-started',
    guideId: ProgressionEvidenceStartInputGuideIdEnum.featureMap,
    titleEn: 'What Each TradePilot Feature Does',
    titleId: 'Fungsi Setiap Fitur TradePilot',
    summaryEn: 'Analyze, History, Journal, Mirror, alerts, and briefings.',
    summaryId: 'Analisis, Riwayat, Jurnal, Cermin, alert, dan ringkasan.',
    bodyEn:
        'Analyze creates a fresh scenario; History reviews old analyses; Journal records trades you took; Trader Mirror reveals behavior patterns; alerts watch levels; Daily Briefing summarizes context.',
    bodyId:
        'Analisis membuat skenario baru; Riwayat meninjau analisis lama; Jurnal mencatat trade yang diambil; Cermin Trader menunjukkan pola perilaku; alert memantau level; Ringkasan Harian merangkum konteks.',
    pointsEn: [
      'Use each feature for its stated job.',
      'Separate an AI plan from your execution.',
      'Past performance never guarantees the next result.',
    ],
    pointsId: [
      'Gunakan setiap fitur sesuai fungsinya.',
      'Pisahkan plan AI dari eksekusi kamu.',
      'Performa lama tidak menjamin hasil berikutnya.',
    ],
  ),
  _MindsetModule(
    category: 'getting-started',
    guideId: ProgressionEvidenceStartInputGuideIdEnum.readingAnalysis,
    titleEn: 'Reading an Analysis Output',
    titleId: 'Membaca Hasil Analisis',
    summaryEn: 'Bias, confidence, entry, SL, TP, and invalidation.',
    summaryId: 'Bias, confidence, entry, SL, TP, dan invalidation.',
    bodyEn:
        'The bias gauge combines available evidence. Entry is a zone, SL limits risk, TP provides staged targets, and invalidation tells you when the original scenario no longer applies.',
    bodyId:
        'Gauge bias menggabungkan bukti yang tersedia. Entry adalah zona, SL membatasi risiko, TP memberi target bertahap, dan invalidation menjelaskan kapan skenario awal tidak berlaku.',
    pointsEn: [
      'Read invalidation before levels.',
      'Confidence is not win probability.',
      'Never follow an entry blindly.',
    ],
    pointsId: [
      'Baca invalidation sebelum level.',
      'Confidence bukan probabilitas menang.',
      'Jangan mengikuti entry secara buta.',
    ],
  ),
  _MindsetModule(
    category: 'getting-started',
    titleEn: 'Using History & Performance',
    titleId: 'Menggunakan Riwayat & Performa',
    summaryEn: 'Review outcomes, filters, presets, and meaningful samples.',
    summaryId: 'Tinjau outcome, filter, preset, dan jumlah sampel yang layak.',
    bodyEn:
        'Summary turns completed analyses into performance views by instrument and timeframe. History keeps the original records behind those numbers.',
    bodyId:
        'Ringkasan mengubah analisis yang selesai menjadi gambaran performa per instrumen dan timeframe. Riwayat menyimpan catatan asli di balik angka tersebut.',
    pointsEn: [
      'Use search, filters, and presets to repeat a focused review.',
      'Other Instruments groups non-primary markets without renaming the original records.',
      'TP outcomes are wins, SL is a loss, and expired is reported separately.',
      'Treat small samples cautiously; historical performance is not a prediction.',
    ],
    pointsId: [
      'Gunakan pencarian, filter, dan preset untuk mengulang review terfokus.',
      'Instrumen Lainnya mengelompokkan market non-utama tanpa mengganti nama catatan aslinya.',
      'Outcome TP adalah win, SL adalah loss, dan expired dilaporkan terpisah.',
      'Waspadai sampel kecil; performa historis bukan prediksi.',
    ],
  ),
  _MindsetModule(
    category: 'getting-started',
    guideId: ProgressionEvidenceStartInputGuideIdEnum.validityConfidence,
    titleEn: 'Confidence, Validity, and Invalidation',
    titleId: 'Confidence, Masa Berlaku, dan Invalidation',
    summaryEn: 'Understand evidence strength and when a scenario expires.',
    summaryId: 'Pahami kekuatan bukti dan kapan skenario berakhir.',
    bodyEn:
        'Confidence describes support from available evidence. Validity is the intended time window. Invalidation is a market condition that cancels the scenario even before that window expires.',
    bodyId:
        'Confidence menunjukkan dukungan bukti yang tersedia. Validity adalah masa pemakaian. Invalidation adalah kondisi market yang membatalkan skenario meski waktunya belum habis.',
    pointsEn: [
      'Valid does not mean certain.',
      'Re-analyze after expiry.',
      'Stop using a scenario once invalidated.',
    ],
    pointsId: [
      'Valid tidak berarti pasti.',
      'Analisis ulang setelah expired.',
      'Hentikan pemakaian skenario setelah invalid.',
    ],
  ),
  _MindsetModule(
    category: 'getting-started',
    guideId: ProgressionEvidenceStartInputGuideIdEnum.adaptivePlan,
    titleEn: 'Standard Plan and Position Size Recommendation',
    titleId: 'Standard Plan dan Rekomendasi Ukuran Posisi',
    summaryEn:
        'The difference between market levels and account-aware checkpoints.',
    summaryId: 'Perbedaan level market dan checkpoint sesuai kondisi akun.',
    bodyEn:
        'Standard Plan presents analysis levels directly. Position Size Recommendation converts a supported analysis into account-aware position checkpoints and limits for supported instruments.',
    bodyId:
        'Standard Plan menampilkan level analisis langsung. Rekomendasi Ukuran Posisi mengubah analisis yang didukung menjadi checkpoint posisi dan batas sesuai kondisi akun untuk instrumen tertentu.',
    pointsEn: [
      'Enter actual available funds.',
      'Every layer is a manual decision.',
      'Never add only because price moves against you.',
    ],
    pointsId: [
      'Masukkan dana tersedia yang sebenarnya.',
      'Setiap layer adalah keputusan manual.',
      'Jangan tambah posisi hanya karena harga bergerak melawan.',
    ],
  ),
  _MindsetModule(
    category: 'getting-started',
    guideId: ProgressionEvidenceStartInputGuideIdEnum.personalProgression,
    titleEn: 'Levels, Ranks, Mastery & Badges',
    titleId: 'Level, Rank, Mastery & Achievement Badge',
    summaryEn: 'Progression rewards preparation, reflection, and discipline.',
    summaryId: 'Progression menghargai persiapan, refleksi, dan disiplin.',
    bodyEn:
        'Private progression measures verified process activities—not profit, account size, win rate, trade count, or analysis volume.',
    bodyId:
        'Progression pribadi mengukur aktivitas proses yang terverifikasi—bukan profit, modal, win rate, jumlah trade, atau banyaknya analisis.',
    pointsEn: [
      'XP can come from checklists, guides, evaluations, journals, streaks, and waiting.',
      'Duplicate claims do not repeatedly award XP.',
      'There is no public leaderboard.',
    ],
    pointsId: [
      'XP bisa berasal dari checklist, panduan, evaluasi, jurnal, streak, dan keputusan menunggu.',
      'Klaim duplikat tidak memberi XP berulang.',
      'Tidak ada leaderboard publik.',
    ],
  ),
  _MindsetModule(
    category: 'analysis-manual',
    guideId: ProgressionEvidenceStartInputGuideIdEnum.analysisWorkflow,
    titleEn: 'From Instrument Selection to a Usable Analysis',
    titleId: 'Dari Memilih Instrumen sampai Memakai Hasil',
    summaryEn: 'A safe workflow for creating and reviewing an analysis.',
    summaryId: 'Alur aman membuat dan meninjau analisis.',
    bodyEn:
        'Choose the correct instrument and timeframe, add optional context, then read reasoning and invalidation before levels. A result is time-bound and must be refreshed after material change.',
    bodyId:
        'Pilih instrumen dan timeframe yang benar, tambahkan konteks bila perlu, lalu baca alasan dan invalidation sebelum level. Hasil berbatas waktu dan perlu diperbarui setelah perubahan penting.',
    pointsEn: [
      'Match timeframe to holding horizon.',
      'Confirm the quoted price.',
      'Do not mix levels from different analyses.',
    ],
    pointsId: [
      'Sesuaikan timeframe dengan durasi posisi.',
      'Pastikan harga acuannya benar.',
      'Jangan campur level dari analisis berbeda.',
    ],
  ),
  _MindsetModule(
    category: 'analysis-manual',
    guideId: ProgressionEvidenceStartInputGuideIdEnum.biasConfidenceValidity,
    titleEn: 'Bias, Signal Strength, Confidence & Validity',
    titleId: 'Bias, Signal Strength, Confidence, Validity & Invalidation',
    summaryEn: 'These fields answer different questions.',
    summaryId: 'Setiap field menjawab pertanyaan yang berbeda.',
    bodyEn:
        'Bias is direction, signal strength is directional clarity, confidence is evidence support, validity is the usable window, and invalidation is the condition that cancels the scenario.',
    bodyId:
        'Bias adalah arah, signal strength adalah kejelasan arah, confidence adalah dukungan bukti, validity adalah masa pakai, dan invalidation adalah kondisi pembatal skenario.',
    pointsEn: [
      'Do not turn confidence into a win guarantee.',
      'Mixed evidence can justify Wait.',
      'Freshness matters.',
    ],
    pointsId: [
      'Jangan menganggap confidence sebagai jaminan menang.',
      'Bukti campuran dapat berarti Tunggu.',
      'Kesegaran data penting.',
    ],
  ),
  _MindsetModule(
    category: 'analysis-manual',
    guideId: ProgressionEvidenceStartInputGuideIdEnum.levelsChart,
    titleEn: 'Entry, Stop Loss, Take Profit, R:R & Chart',
    titleId: 'Entry, Stop Loss, Take Profit, R:R, Support, Resistance & Chart',
    summaryEn: 'Read every price level as part of one scenario.',
    summaryId: 'Baca setiap level harga sebagai satu skenario.',
    bodyEn:
        'Entry marks a planned zone, SL defines the risk boundary, TP stages exits, and R:R compares potential risk and reward. Support and resistance are zones—not guaranteed reversal points.',
    bodyId:
        'Entry menandai zona rencana, SL menentukan batas risiko, TP membagi target keluar, dan R:R membandingkan potensi risiko serta hasil. Support dan resistance adalah zona—bukan titik balik pasti.',
    pointsEn: [
      'Check spread and slippage.',
      'Do not chase a missed entry.',
      'Use chart overlays as context, not orders.',
    ],
    pointsId: [
      'Periksa spread dan slippage.',
      'Jangan kejar entry yang terlewat.',
      'Gunakan garis chart sebagai konteks, bukan order.',
    ],
  ),
  _MindsetModule(
    category: 'analysis-manual',
    guideId: ProgressionEvidenceStartInputGuideIdEnum.timeframeRiskMap,
    titleEn: 'Comparing Risk Across Timeframes',
    titleId: 'Membandingkan Risiko Antar-Timeframe',
    summaryEn: 'Relative risk compares available snapshots.',
    summaryId: 'Risiko relatif membandingkan snapshot yang tersedia.',
    bodyEn:
        'The Timeframe Risk Map compares technical risk for the same supported instrument. Lower relative risk only means more orderly than the compared options—not safe or guaranteed.',
    bodyId:
        'Timeframe Risk Map membandingkan risiko teknikal instrumen yang sama. Risiko relatif lebih rendah hanya berarti lebih tertata dibanding opsi lain—bukan aman atau dijamin.',
    pointsEn: [
      'Match timeframe to your horizon.',
      'Insufficient data is not low risk.',
      'Switching timeframe requires a fresh analysis.',
    ],
    pointsId: [
      'Sesuaikan timeframe dengan horizon kamu.',
      'Data tidak cukup bukan risiko rendah.',
      'Pergantian timeframe memerlukan analisis baru.',
    ],
  ),
  _MindsetModule(
    category: 'analysis-manual',
    guideId: ProgressionEvidenceStartInputGuideIdEnum.technicalFundamental,
    titleEn: 'Technical and Fundamental Context',
    titleId: 'Konteks Teknikal dan Fundamental',
    summaryEn: 'How indicators, news, and events are synthesized.',
    summaryId: 'Cara indikator, berita, dan event disintesis.',
    bodyEn:
        'Technical context covers price, trend, momentum, volatility, and indicators. Fundamental context adds news and events. No single indicator or headline decides the result.',
    bodyId:
        'Konteks teknikal mencakup harga, tren, momentum, volatilitas, dan indikator. Konteks fundamental menambahkan berita dan event. Tidak ada satu indikator atau headline yang menentukan hasil sendiri.',
    pointsEn: [
      'Read indicator values with their Buy/Sell/Neutral interpretation.',
      'Open cited sources.',
      'Treat high-impact events as volatility risk.',
    ],
    pointsId: [
      'Baca nilai indikator bersama interpretasi Beli/Jual/Netral.',
      'Buka sumber sitasi.',
      'Anggap event berdampak tinggi sebagai risiko volatilitas.',
    ],
  ),
  _MindsetModule(
    category: 'analysis-manual',
    guideId: ProgressionEvidenceStartInputGuideIdEnum.standardPlan,
    titleEn: 'Using the Standard Plan',
    titleId: 'Menggunakan Standard Plan',
    summaryEn: 'Use Buy, Sell, or Wait as a complete plan.',
    summaryId: 'Gunakan Buy, Sell, atau Tunggu sebagai plan utuh.',
    bodyEn:
        'The Standard Plan presents Buy and Sell scenarios with a preferred side. Wait means current evidence does not support immediate execution; missing levels are intentionally not invented.',
    bodyId:
        'Standard Plan menampilkan skenario Buy dan Sell dengan sisi pilihan. Tunggu berarti bukti saat ini belum mendukung eksekusi; level yang kosong sengaja tidak diada-adakan.',
    pointsEn: [
      'Start from the preferred side and rationale.',
      'Confirm validity and entry.',
      'Size from your own risk limit.',
    ],
    pointsId: [
      'Mulai dari sisi pilihan dan alasan.',
      'Pastikan validity dan entry.',
      'Tentukan ukuran dari batas risiko pribadi.',
    ],
  ),
  _MindsetModule(
    category: 'analysis-manual',
    guideId: ProgressionEvidenceStartInputGuideIdEnum.adaptivePositionPlan,
    titleEn: 'Using the Position Size Recommendation',
    titleId: 'Menggunakan Rekomendasi Ukuran Posisi',
    summaryEn: 'Account-aware position checkpoints and safeguards.',
    summaryId: 'Checkpoint posisi dan safeguard sesuai kondisi akun.',
    bodyEn:
        'Position Size Recommendation combines actual account type, available funds, risk style, analysis direction, confidence, levels, and supported account constraints. It never places orders.',
    bodyId:
        'Rekomendasi Ukuran Posisi menggabungkan jenis akun, dana tersedia, gaya risiko, arah, confidence, level, dan batas akun yang didukung. Fitur ini tidak pernah memasang order.',
    pointsEn: [
      'Eligible does not mean required.',
      'Reassess every layer.',
      'Rejected or capped output is a risk control.',
    ],
    pointsId: [
      'Eligible bukan berarti wajib.',
      'Nilai ulang setiap layer.',
      'Hasil rejected atau capped adalah kontrol risiko.',
    ],
  ),
  _MindsetModule(
    category: 'analysis-manual',
    guideId: ProgressionEvidenceStartInputGuideIdEnum.accountRules,
    titleEn: 'Reading Account and Standard Trading Rules',
    titleId: 'Membaca Aturan Akun dan Standard Trading Rules',
    summaryEn: 'Contract, margin, fees, rollover, spread, and limits.',
    summaryId: 'Kontrak, margin, fee, rollover, spread, dan batas.',
    bodyEn:
        'Rules summarize product constraints such as contract size, margin, fees, spread, rollover, minimum movement, order distance, lot range, and minimum deposit for a named version.',
    bodyId:
        'Aturan merangkum batas produk seperti ukuran kontrak, margin, fee, spread, rollover, pergerakan minimum, jarak order, rentang lot, dan deposit minimum untuk versi tertentu.',
    pointsEn: [
      'Margin call is not a suggested stop loss.',
      'Costs change net outcomes.',
      'Confirm current broker terms before execution.',
    ],
    pointsId: [
      'Margin call bukan saran stop loss.',
      'Biaya mengubah hasil bersih.',
      'Konfirmasi aturan broker terbaru sebelum eksekusi.',
    ],
  ),
  _MindsetModule(
    category: 'glossary',
    guideId: ProgressionEvidenceStartInputGuideIdEnum.terms,
    titleEn: 'Common Trading Terms',
    titleId: 'Istilah Trading Umum',
    summaryEn: 'A quick reference for terms used throughout TradePilot.',
    summaryId: 'Referensi singkat istilah yang dipakai di TradePilot.',
    bodyEn:
        'Bullish expects rising prices; bearish expects falling prices; neutral means mixed evidence. SL limits loss, TP realizes a target, and R:R compares potential risk with potential reward.',
    bodyId:
        'Bullish berarti ekspektasi harga naik; bearish berarti turun; netral berarti bukti campuran. SL membatasi rugi, TP merealisasikan target, dan R:R membandingkan potensi risiko dengan hasil.',
    pointsEn: [
      'Timeframe is the candle interval.',
      'Support and resistance are zones.',
      'Spread, fees, rollover, and slippage affect realized results.',
    ],
    pointsId: [
      'Timeframe adalah interval candle.',
      'Support dan resistance adalah zona.',
      'Spread, fee, rollover, dan slippage memengaruhi hasil nyata.',
    ],
  ),
  _MindsetModule(
    category: 'privacy',
    titleEn: 'How Your Data Is Handled',
    titleId: 'Penanganan Data Kamu',
    summaryEn: 'What is stored and how to keep your account safe.',
    summaryId: 'Data yang disimpan dan cara menjaga keamanan akun.',
    bodyEn:
        'TradePilot stores account, analysis, journal, preference, and activity data needed to provide the service. Passwords and API secrets must never be placed in notes or journal fields.',
    bodyId:
        'TradePilot menyimpan data akun, analisis, jurnal, preferensi, dan aktivitas yang dibutuhkan untuk layanan. Password dan API secret tidak boleh dimasukkan ke catatan atau jurnal.',
    pointsEn: [
      'Use a unique password and biometric lock.',
      'Treat exported or shared screenshots as sensitive.',
      'Use Delete Account when you want permanent removal.',
    ],
    pointsId: [
      'Gunakan password unik dan kunci biometrik.',
      'Anggap screenshot yang dibagikan sebagai data sensitif.',
      'Gunakan Hapus Akun bila ingin penghapusan permanen.',
    ],
  ),
  _MindsetModule(
    titleEn: 'FOMO — Trading Late on a Move',
    titleId: 'FOMO — Telat Masuk Saat Harga Sudah Jalan',
    summaryEn:
        'Why chasing breakouts hurts and how to wait for second chances.',
    summaryId:
        'Kenapa mengejar breakout sering merugikan dan cara menunggu peluang kedua.',
    bodyEn:
        'FOMO is the urge to enter after a move has started because you fear missing the rest. When a move already feels obvious, the impulse may be close to exhaustion.',
    bodyId:
        'FOMO adalah dorongan masuk setelah harga bergerak karena takut ketinggalan. Saat pergerakan sudah terasa sangat jelas, impulsnya bisa hampir selesai.',
    pointsEn: [
      'Accept that missing moves is normal.',
      'Wait for a pullback to clear structure.',
      'If it never comes, let the trade go.',
    ],
    pointsId: [
      'Terima bahwa melewatkan pergerakan itu normal.',
      'Tunggu pullback ke struktur yang jelas.',
      'Jika tidak datang, lepaskan trade tersebut.',
    ],
  ),
  _MindsetModule(
    titleEn: 'Revenge Trading — Trying to Win It Back',
    titleId: 'Revenge Trading — Memaksa Balik Modal',
    summaryEn: 'Recognize the most expensive emotion, then stop.',
    summaryId: 'Kenali salah satu emosi termahal dalam trading, lalu berhenti.',
    bodyEn:
        'Revenge trading means opening a trade after a loss to recover money rather than because the setup matches your plan.',
    bodyId:
        'Revenge trading berarti membuka posisi setelah rugi untuk mengembalikan uang, bukan karena setup sesuai rencana.',
    pointsEn: [
      'After two losses, take a 30-minute break.',
      'After three daily losses, stop for the day.',
      'Never raise size to win it back.',
    ],
    pointsId: [
      'Setelah dua rugi, istirahat 30 menit.',
      'Setelah tiga rugi sehari, berhenti untuk hari itu.',
      'Jangan menaikkan ukuran untuk balas kerugian.',
    ],
  ),
  _MindsetModule(
    titleEn: 'Loss Aversion — Holding Losers Too Long',
    titleId: 'Loss Aversion — Menahan Kerugian Terlalu Lama',
    summaryEn: 'Why losses feel stronger than equivalent gains.',
    summaryId: 'Mengapa rugi terasa lebih kuat daripada untung yang setara.',
    bodyEn:
        'Loss aversion often makes traders close winners early and keep losers open in hope. A planned small loss can then become a large one.',
    bodyId:
        'Loss aversion sering membuat trader menutup profit terlalu cepat dan menahan rugi dengan harapan. Kerugian kecil yang direncanakan akhirnya membesar.',
    pointsEn: [
      'Set the stop before entry.',
      'Treat the stop as a rule.',
      'Use smaller size if accepting the loss is difficult.',
    ],
    pointsId: [
      'Tentukan stop sebelum entry.',
      'Perlakukan stop sebagai aturan.',
      'Gunakan ukuran lebih kecil jika sulit menerima rugi.',
    ],
  ),
  _MindsetModule(
    titleEn: "Anchoring — 'It Was Cheaper Yesterday'",
    titleId: "Anchoring — 'Kemarin Lebih Murah'",
    summaryEn: 'Your entry price matters less than current evidence.',
    summaryId: 'Harga entry tidak lebih penting dari bukti pasar saat ini.',
    bodyEn:
        'Anchoring means holding onto a reference price and ignoring new information. The market does not know your entry price.',
    bodyId:
        'Anchoring berarti terpaku pada harga referensi dan mengabaikan informasi baru. Pasar tidak mengetahui harga entry kamu.',
    pointsEn: [
      'Reassess current evidence.',
      'Ask whether you would open the same trade now.',
      'Exit when the original thesis is invalid.',
    ],
    pointsId: [
      'Nilai ulang bukti terbaru.',
      'Tanya apakah kamu akan membuka trade yang sama sekarang.',
      'Keluar saat tesis awal tidak berlaku.',
    ],
  ),
  _MindsetModule(
    titleEn: 'Risk First — Position Sizing Mindset',
    titleId: 'Risiko Dulu — Mindset Ukuran Posisi',
    summaryEn: 'Discipline starts with position size.',
    summaryId: 'Disiplin dimulai dari ukuran posisi.',
    bodyEn:
        'Think first about how much you can lose, then entry, then target. Position size must follow the risk limit—not the desired profit.',
    bodyId:
        'Pikirkan dulu berapa maksimal kerugian, lalu entry, kemudian target. Ukuran posisi mengikuti batas risiko, bukan target profit.',
    pointsEn: [
      'Define account risk per trade.',
      'Calculate size from entry and stop.',
      'Skip setups that require excessive risk.',
    ],
    pointsId: [
      'Tentukan risiko akun per trade.',
      'Hitung ukuran dari entry dan stop.',
      'Lewati setup yang membutuhkan risiko berlebihan.',
    ],
  ),
  _MindsetModule(
    titleEn: "Plan vs Prediction — You Don't Need to Be Right",
    titleId: 'Rencana vs Prediksi — Tidak Harus Selalu Benar',
    summaryEn: 'Good risk management matters more than prediction.',
    summaryId: 'Manajemen risiko yang baik lebih penting daripada prediksi.',
    bodyEn:
        'Trading is not only predicting direction. It is managing the position consistently when you are right and when you are wrong.',
    bodyId:
        'Trading bukan hanya memprediksi arah. Trading adalah mengelola posisi secara konsisten saat benar maupun salah.',
    pointsEn: [
      'Define scenarios before entry.',
      'Let winners exceed planned losses.',
      'Judge process, not one outcome.',
    ],
    pointsId: [
      'Tentukan skenario sebelum entry.',
      'Biarkan profit melebihi rugi terencana.',
      'Nilai proses, bukan satu outcome.',
    ],
  ),
  _MindsetModule(
    titleEn: 'Journaling — Your Most Valuable Tool',
    titleId: 'Journaling — Alat Refleksi Terpenting',
    summaryEn: "What you don't measure, you can't improve.",
    summaryId: 'Yang tidak diukur sulit diperbaiki.',
    bodyEn:
        'Record the instrument, timeframe, entry and exit reason, emotions, and what you would change. Patterns become visible over time.',
    bodyId:
        'Catat instrumen, timeframe, alasan masuk dan keluar, emosi, serta hal yang akan diubah. Pola akan terlihat seiring waktu.',
    pointsEn: [
      'Journal every executed trade.',
      'Separate planned and impulse trades.',
      'Review patterns weekly.',
    ],
    pointsId: [
      'Jurnalkan setiap trade.',
      'Pisahkan trade terencana dan impulsif.',
      'Tinjau pola setiap minggu.',
    ],
  ),
  _MindsetModule(
    titleEn: 'Patience — Doing Nothing Is a Trade',
    titleId: 'Sabar — Diam Juga Sebuah Keputusan',
    summaryEn: 'Staying in cash is a valid position.',
    summaryId: 'Tetap memegang cash adalah posisi yang valid.',
    bodyEn:
        'High-quality setups are uncommon. Trading every market condition exposes the account to noise where the edge is weak.',
    bodyId:
        'Setup berkualitas tinggi tidak sering muncul. Trading di setiap kondisi membuat akun terpapar noise saat edge lemah.',
    pointsEn: [
      'Wait for conditions in your plan.',
      'Do not confuse activity with progress.',
      'A skipped weak setup protects capital.',
    ],
    pointsId: [
      'Tunggu kondisi yang sesuai rencana.',
      'Jangan samakan sibuk dengan kemajuan.',
      'Melewatkan setup lemah melindungi modal.',
    ],
  ),
];
