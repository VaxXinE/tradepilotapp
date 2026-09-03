import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:trade_pilot_api_client/trade_pilot_api_client.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/theme/app_colors.dart';
import '../../l10n/l10n.dart';
import '../../models/market_models.dart';
import '../../providers/analysis_provider.dart';
import '../../providers/market_provider.dart';
import '../../widgets/analysis_levels_chart.dart';
import '../../widgets/analysis_note_card.dart';
import '../../widgets/price_alert/price_alert_sheet.dart';
import '../journal/trade_journal_screen.dart';

const _analysisTimeframes = ['1m', '5m', '15m', '30m', '1h', '4h', '1D', '1W'];

const _tradingViewSymbols = <String, String>{
  'XAU/USD': 'OANDA:XAUUSD',
  'XAG/USD': 'OANDA:XAGUSD',
  'BRENT': 'BLACKBULL:BRENT',
  'HSI': 'VANTAGE:HK50',
  'NIKKEI': 'SPREADEX:NIKKEI',
  'DJIA': 'TVC:DJI',
  'NASDAQ': 'TVC:NDX',
  'DXY': 'TVC:DXY',
  'USD/IDR': 'FX_IDC:USDIDR',
  'BTC/USD': 'BINANCE:BTCUSDT',
  'ETH/USD': 'BINANCE:ETHUSDT',
  'SOL/USD': 'BINANCE:SOLUSDT',
  'BNB/USD': 'BINANCE:BNBUSDT',
  'XRP/USD': 'BINANCE:XRPUSDT',
};

String _tradingViewSymbol(String instrument) {
  final normalized = instrument.trim().toUpperCase();
  return _tradingViewSymbols[normalized] ??
      'OANDA:${normalized.replaceAll(RegExp(r'[\s/]+'), '')}';
}

CreateAnalysisBodyTimeframeEnum _timeframeEnum(String value) => switch (value) {
  '1m' => CreateAnalysisBodyTimeframeEnum.n1m,
  '5m' => CreateAnalysisBodyTimeframeEnum.n5m,
  '15m' => CreateAnalysisBodyTimeframeEnum.n15m,
  '30m' => CreateAnalysisBodyTimeframeEnum.n30m,
  '4h' => CreateAnalysisBodyTimeframeEnum.n4h,
  '1D' => CreateAnalysisBodyTimeframeEnum.n1d,
  '1W' => CreateAnalysisBodyTimeframeEnum.n1w,
  _ => CreateAnalysisBodyTimeframeEnum.n1h,
};

class AnalysisDetailScreen extends StatefulWidget {
  const AnalysisDetailScreen({
    super.key,
    required this.analysisId,
    this.preloaded,
  });

  final int analysisId;
  final Analysis? preloaded;

  @override
  State<AnalysisDetailScreen> createState() => _AnalysisDetailScreenState();
}

class _AnalysisDetailScreenState extends State<AnalysisDetailScreen> {
  Analysis? _analysis;

  List<MarketCandle> _candles = const [];
  BeginnerTechnicalSnapshot? _technical;
  RefreshFundamentalsResponse? _fundamentalRefresh;

  bool _loading = true;
  bool _submittingFeedback = false;
  bool _detailRequestInFlight = false;
  bool _marketRequestInFlight = false;
  bool _marketLoading = false;
  bool _reanalyzing = false;
  bool _refreshingFundamentals = false;
  String? _selectedTimeframe;

  String? _marketError;

  Timer? _pollTimer;

  @override
  void initState() {
    super.initState();

    _analysis = widget.preloaded;

    _load();
    _startOutcomePolling();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final analysis = _analysis;

      if (!mounted || analysis == null) {
        return;
      }

      unawaited(_loadMarketData(analysis));
    });
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _pollTimer = null;

    super.dispose();
  }

  // ===========================================================================
  // OUTCOME POLLING
  // ===========================================================================

  void _startOutcomePolling() {
    _pollTimer?.cancel();

    _pollTimer = Timer.periodic(const Duration(seconds: 10), (_) {
      if (_analysis?.outcomeStatus == AnalysisOutcomeStatusEnum.pending) {
        unawaited(_load(silent: true));
      }
    });
  }

  void _stopOutcomePollingIfResolved(Analysis analysis) {
    final status = analysis.outcomeStatus;

    if (status == null || status == AnalysisOutcomeStatusEnum.pending) {
      return;
    }

    _pollTimer?.cancel();
    _pollTimer = null;
  }

  // ===========================================================================
  // LOAD ANALYSIS
  // ===========================================================================

  Future<void> _load({bool silent = false}) async {
    if (_detailRequestInFlight) {
      return;
    }

    _detailRequestInFlight = true;

    try {
      final provider = context.read<AnalysisProvider>();

      final previous = _analysis;

      final result = await provider.getAnalysis(
        widget.analysisId,
        silent: silent,
      );

      if (!mounted) {
        return;
      }

      if (result != null) {
        _stopOutcomePollingIfResolved(result);
      }

      setState(() {
        if (result != null) {
          _analysis = result;
        }

        _loading = false;
      });

      if (result != null &&
          (_candles.isEmpty ||
              previous?.instrument != result.instrument ||
              previous?.timeframe != result.timeframe)) {
        unawaited(_loadMarketData(result));
      }
    } finally {
      _detailRequestInFlight = false;
    }
  }

  // ===========================================================================
  // MARKET DATA
  // ===========================================================================

  Future<void> _loadMarketData(Analysis analysis, {bool force = false}) async {
    if (_marketRequestInFlight) {
      return;
    }

    _marketRequestInFlight = true;

    if (mounted) {
      setState(() {
        _marketLoading = true;
        _marketError = null;
      });
    }

    try {
      final provider = context.read<MarketProvider>();

      final results = await Future.wait<Object?>([
        provider.getCandlesFor(
          analysis.instrument,
          analysis.timeframe,
          force: force,
        ),
        provider.getTechnicalFor(
          analysis.instrument,
          analysis.timeframe,
          force: force,
        ),
      ]);
      final candles = results[0] as List<MarketCandle>;
      final technical = results[1] as BeginnerTechnicalSnapshot?;

      // Price alert membutuhkan quote live,
      // tetapi kegagalan quote tidak boleh
      // membuat seluruh detail error.
      unawaited(provider.loadQuotes(force: force, silent: true));

      if (!mounted) {
        return;
      }

      setState(() {
        _candles = candles;
        _technical = technical;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }

      setState(() {
        _marketError = 'Chart market belum tersedia.';
      });
    } finally {
      _marketRequestInFlight = false;

      if (mounted) {
        setState(() {
          _marketLoading = false;
        });
      }
    }
  }

  Future<void> _reanalyze([String? timeframe]) async {
    final analysis = _analysis;
    if (analysis == null || _reanalyzing) return;
    final selected = timeframe ?? analysis.timeframe;
    setState(() {
      _reanalyzing = true;
      _selectedTimeframe = selected;
    });
    final created = await context.read<AnalysisProvider>().createAnalysis(
      instrument: analysis.instrument,
      timeframe: _timeframeEnum(selected),
      mode: analysis.mode == AnalysisModeEnum.pro
          ? CreateAnalysisBodyModeEnum.pro
          : CreateAnalysisBodyModeEnum.beginner,
      userInputContext: analysis.userInputContext,
    );
    if (!mounted) return;
    setState(() => _reanalyzing = false);
    if (created == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Analisis baru gagal dibuat.')),
      );
      return;
    }
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) =>
            AnalysisDetailScreen(analysisId: created.id, preloaded: created),
      ),
    );
  }

  Future<void> _refreshFundamentals() async {
    if (_refreshingFundamentals) return;
    setState(() => _refreshingFundamentals = true);
    final result = await context.read<AnalysisProvider>().refreshFundamentals(
      widget.analysisId,
    );
    if (!mounted) return;
    setState(() {
      _fundamentalRefresh = result;
      _refreshingFundamentals = false;
    });
    if (result != null) await _load(silent: true);
  }

  Future<void> _openExternalUrl(String rawUrl) async {
    final uri = Uri.tryParse(rawUrl);
    if (uri == null || !{'https', 'http'}.contains(uri.scheme)) return;
    var opened = false;
    try {
      opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      opened = false;
    }
    if (!opened && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tautan tidak dapat dibuka.')),
      );
    }
  }

  Future<void> _refresh() async {
    await _load();

    final analysis = _analysis;

    if (analysis != null) {
      await _loadMarketData(analysis, force: true);
    }
  }

  // ===========================================================================
  // PRICE ALERT
  // ===========================================================================

  Future<void> _openPriceAlert() async {
    final analysis = _analysis;

    if (analysis == null) {
      return;
    }

    final market = context.read<MarketProvider>();

    await market.loadQuotes(force: true, silent: true);

    if (!mounted) {
      return;
    }

    final quote = market.quoteFor(analysis.instrument);

    if (quote == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Harga live belum tersedia untuk instrumen ini, '
            'jadi price alert belum dapat dibuat.',
          ),
        ),
      );

      return;
    }

    final created = await showPriceAlertSheet(
      context: context,
      instrument: analysis.instrument,
      currentPrice: quote.price,
    );

    if (created == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Price alert berhasil dibuat.')),
      );
    }
  }

  // ===========================================================================
  // FEEDBACK
  // ===========================================================================

  Future<void> _openFeedback(FeedbackBodyFeedbackTypeEnum type) async {
    var outcome = FeedbackBodyOutcomeEnum.unknown;
    final noteController = TextEditingController();
    final result = await showDialog<(FeedbackBodyOutcomeEnum, String?)>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Feedback analisis'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Bagaimana hasil analisis ini?'),
              const SizedBox(height: 10),
              Wrap(
                spacing: 7,
                children: [
                  for (final item in const [
                    (FeedbackBodyOutcomeEnum.correct, 'Benar'),
                    (FeedbackBodyOutcomeEnum.wrong, 'Salah'),
                    (FeedbackBodyOutcomeEnum.unknown, 'Belum tahu'),
                  ])
                    ChoiceChip(
                      label: Text(item.$2),
                      selected: outcome == item.$1,
                      onSelected: (_) =>
                          setDialogState(() => outcome = item.$1),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              TextField(
                controller: noteController,
                maxLength: 1000,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Catatan feedback (opsional)',
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Batal'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, (
                outcome,
                noteController.text.trim().isEmpty
                    ? null
                    : noteController.text.trim(),
              )),
              child: const Text('Kirim'),
            ),
          ],
        ),
      ),
    );
    noteController.dispose();
    if (result != null && mounted) {
      await _sendFeedback(type, outcome: result.$1, note: result.$2);
    }
  }

  Future<void> _sendFeedback(
    FeedbackBodyFeedbackTypeEnum type, {
    FeedbackBodyOutcomeEnum? outcome,
    String? note,
  }) async {
    if (_submittingFeedback) {
      return;
    }

    setState(() {
      _submittingFeedback = true;
    });

    final ok = await context.read<AnalysisProvider>().submitFeedback(
      analysisId: widget.analysisId,
      type: type,
      outcome: outcome,
      note: note,
    );

    if (!mounted) {
      return;
    }

    setState(() {
      _submittingFeedback = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          ok ? 'Terima kasih atas feedback kamu!' : 'Gagal mengirim feedback.',
        ),
      ),
    );
  }

  Future<bool> _saveNote(String note) async {
    final current = _analysis;
    if (current == null) return false;
    final provider = context.read<AnalysisProvider>();
    final updated = await provider.saveAnalysisNote(
      analysis: current,
      note: note,
    );
    if (!mounted) return false;
    if (updated != null) {
      setState(() => _analysis = updated);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            updated.hasNote == true ? 'Catatan tersimpan.' : 'Catatan dihapus.',
          ),
        ),
      );
      return true;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(provider.errorMessage ?? 'Catatan gagal disimpan.'),
      ),
    );
    return false;
  }

  // ===========================================================================
  // BUILD
  // ===========================================================================

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final muted = isDark
        ? AppColors.darkMutedForeground
        : AppColors.lightMutedForeground;

    if (_loading && _analysis == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final analysis = _analysis;

    if (analysis == null) {
      return Scaffold(
        appBar: AppBar(),
        body: Center(
          child: Text(
            'Analisis tidak ditemukan',
            style: TextStyle(color: muted),
          ),
        ),
      );
    }

    final bias = (analysis.tradingBias ?? '').toLowerCase();

    final isPro = analysis.mode == AnalysisModeEnum.pro;
    final isBullish =
        bias.contains('bull') || bias == 'buy' || bias == 'strong_buy';
    final isBearish =
        bias.contains('bear') || bias == 'sell' || bias == 'strong_sell';

    final biasColor = isBullish
        ? (isDark ? AppColors.bullishDark : AppColors.bullishLight)
        : isBearish
        ? (isDark ? AppColors.bearishDark : AppColors.bearishLight)
        : (isDark ? AppColors.neutralDark : AppColors.neutralLight);

    final biasLabel = isPro
        ? (isBullish
              ? 'Bullish'
              : isBearish
              ? 'Bearish'
              : 'Neutral')
        : (isBullish
              ? 'Cenderung Naik'
              : isBearish
              ? 'Cenderung Turun'
              : 'Tunggu Dulu');

    final isExpired = analysis.validUntil.isBefore(DateTime.now());
    final mainScenario = isPro ? analysis.baseCase : analysis.mainScenario;
    final alternativeScenario = isPro
        ? (isBearish ? analysis.bullishScenario : analysis.bearishScenario)
        : analysis.alternativeScenario;
    final invalidation = isPro
        ? analysis.invalidationConditions
        : analysis.failureConditions;

    return Scaffold(
      appBar: AppBar(
        title: Text(analysis.instrument),
        actions: [
          IconButton(
            tooltip: 'Analisis ulang',
            onPressed: _reanalyzing ? null : _reanalyze,
            icon: _reanalyzing
                ? const SizedBox.square(
                    dimension: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.refresh_rounded),
          ),
          IconButton(
            tooltip: 'Buat Price Alert',
            onPressed: _openPriceAlert,
            icon: const Icon(Icons.notifications_active_outlined),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          children: [
            _HeaderCard(
              analysis: analysis,
              biasColor: biasColor,
              biasLabel: biasLabel,
              isExpired: isExpired,
              muted: muted,
              isPro: isPro,
            ),

            const SizedBox(height: 14),

            _TimeframeCard(
              current: analysis.timeframe,
              selected: _selectedTimeframe,
              loading: _reanalyzing,
              onSelect: (value) => setState(() => _selectedTimeframe = value),
              onAnalyze: () =>
                  _reanalyze(_selectedTimeframe ?? analysis.timeframe),
            ),

            if (!isPro) ...[
              const SizedBox(height: 14),
              _BeginnerMeaningCard(
                analysis: analysis,
                biasLabel: biasLabel,
                biasColor: biasColor,
              ),
            ],

            if (analysis.outcomeStatus != null) ...[
              const SizedBox(height: 14),
              _OutcomeCard(analysis: analysis),
            ],

            const SizedBox(height: 14),

            _RiskCard(analysis: analysis, isPro: isPro),

            if ((isPro ? analysis.uncertaintyNotes : analysis.whyReason)
                    ?.trim()
                    .isNotEmpty ==
                true) ...[
              const SizedBox(height: 14),
              _ConfidenceReasonCard(
                analysis: analysis,
                reason: (isPro
                    ? analysis.uncertaintyNotes!
                    : analysis.whyReason!),
                onOpenUrl: _openExternalUrl,
              ),
            ],

            const SizedBox(height: 14),

            _MarketSnapshotCard(analysis: analysis),

            const SizedBox(height: 14),

            _ChartCard(
              analysis: analysis,
              candles: _candles,
              isLoading: _marketLoading,
              error: _marketError,
              onOpenTradingView: () => _openExternalUrl(
                Uri.https('www.tradingview.com', '/chart/', {
                  'symbol': _tradingViewSymbol(analysis.instrument),
                }).toString(),
              ),
            ),

            if (analysis.fundamentalContext != null) ...[
              const SizedBox(height: 14),
              _FundamentalSnapshotCard(
                analysis: analysis,
                refreshed: _fundamentalRefresh,
                refreshing: _refreshingFundamentals,
                onRefresh: _refreshFundamentals,
                onOpenUrl: _openExternalUrl,
              ),
            ],

            if (analysis.tradePlan != null) ...[
              const SizedBox(height: 20),
              const Text(
                'Rencana Trading',
                style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
              ),
              const SizedBox(height: 5),
              Text(
                'Gunakan level berikut sebagai struktur risiko, bukan jaminan harga akan bergerak sesuai skenario.',
                style: TextStyle(color: muted, fontSize: 11.5, height: 1.4),
              ),
              const SizedBox(height: 12),
              _TradePlanCard(plan: analysis.tradePlan!, isDark: isDark),
            ],

            const SizedBox(height: 22),

            OutlinedButton.icon(
              onPressed: _openPriceAlert,
              icon: const Icon(Icons.notifications_active_outlined),
              label: const Text('Buat Price Alert'),
            ),

            const SizedBox(height: 14),

            OutlinedButton.icon(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => TradeJournalScreen(analysis: analysis),
                ),
              ),
              icon: const Icon(Icons.menu_book_outlined),
              label: const Text('Catat trade ini'),
            ),

            const SizedBox(height: 14),

            Consumer<AnalysisProvider>(
              builder: (context, provider, _) => AnalysisNoteCard(
                note: analysis.userNote,
                isSaving: provider.isSavingNote(analysis.id),
                onSave: _saveNote,
              ),
            ),

            if (_technical != null) ...[
              const SizedBox(height: 14),
              _TechnicalIndicatorsCard(
                technical: _technical!,
                timeframe: analysis.timeframe,
                showRawSignals: isPro,
              ),
            ],

            if (analysis.userInputContext?.trim().isNotEmpty == true) ...[
              const SizedBox(height: 14),
              _SectionCard(
                title: 'Konteks yang kamu berikan',
                body: analysis.userInputContext!,
                icon: Icons.chat_bubble_outline,
              ),
            ],

            if (invalidation?.trim().isNotEmpty == true) ...[
              const SizedBox(height: 14),
              _SectionCard(
                title: 'Analisis ini batal jika',
                body: invalidation!,
                icon: Icons.report_gmailerrorred_outlined,
                isWarning: true,
              ),
            ],

            if (analysis.opportunity?.trim().isNotEmpty == true ||
                analysis.risk?.trim().isNotEmpty == true) ...[
              const SizedBox(height: 14),
              _OpportunityRiskCard(analysis: analysis),
            ],

            if (mainScenario?.trim().isNotEmpty == true) ...[
              const SizedBox(height: 14),
              _SectionCard(
                title: 'Skenario A — Utama',
                body: mainScenario!,
                icon: Icons.route_outlined,
              ),
            ],

            if (alternativeScenario?.trim().isNotEmpty == true) ...[
              const SizedBox(height: 12),
              _SectionCard(
                title: 'Skenario B — Alternatif',
                body: alternativeScenario!,
                icon: Icons.alt_route_rounded,
              ),
            ],

            const SizedBox(height: 12),
            const _SectionCard(
              title: 'Skenario C — Tunggu / Tanpa Posisi',
              body:
                  'Jika konfirmasi belum kuat atau kondisi pembatal mendekat, menunggu setup yang lebih bersih adalah pilihan paling konservatif.',
              icon: Icons.hourglass_empty_rounded,
            ),

            if (isPro) ...[
              if (analysis.keyDriversTechnical?.trim().isNotEmpty == true) ...[
                const SizedBox(height: 12),
                _SectionCard(
                  title: 'Penggerak Teknikal',
                  body: analysis.keyDriversTechnical!,
                  icon: Icons.query_stats_rounded,
                ),
              ],
              if (analysis.keyDriversFundamental?.trim().isNotEmpty ==
                  true) ...[
                const SizedBox(height: 12),
                _SectionCard(
                  title: 'Penggerak Fundamental',
                  body: analysis.keyDriversFundamental!,
                  icon: Icons.newspaper_outlined,
                ),
              ],
              if (analysis.marketContext?.trim().isNotEmpty == true) ...[
                const SizedBox(height: 12),
                _SectionCard(
                  title: 'Konteks Pasar',
                  body: analysis.marketContext!,
                  icon: Icons.public_rounded,
                ),
              ],
            ],

            const SizedBox(height: 12),
            _ExecutionInsightCard(analysis: analysis),

            const SizedBox(height: 24),

            const Text(
              'Apakah analisis ini membantu?',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
            ),

            const SizedBox(height: 10),

            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _submittingFeedback
                        ? null
                        : () {
                            _openFeedback(FeedbackBodyFeedbackTypeEnum.useful);
                          },
                    icon: const Icon(Icons.thumb_up_alt_outlined, size: 18),
                    label: const Text('Membantu'),
                  ),
                ),

                const SizedBox(width: 10),

                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _submittingFeedback
                        ? null
                        : () {
                            _openFeedback(
                              FeedbackBodyFeedbackTypeEnum.notUseful,
                            );
                          },
                    icon: const Icon(Icons.thumb_down_alt_outlined, size: 18),
                    label: const Text('Kurang Membantu'),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 14),

            Text(
              'Trade Pilot adalah alat bantu analisis. '
              'Selalu batasi risiko dan hindari membuka posisi hanya berdasarkan satu indikator.',
              textAlign: TextAlign.center,
              style: TextStyle(color: muted, fontSize: 10.5, height: 1.4),
            ),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

// =============================================================================
// HEADER
// =============================================================================

class _TimeframeCard extends StatelessWidget {
  const _TimeframeCard({
    required this.current,
    required this.selected,
    required this.loading,
    required this.onSelect,
    required this.onAnalyze,
  });

  final String current;
  final String? selected;
  final bool loading;
  final ValueChanged<String> onSelect;
  final VoidCallback onAnalyze;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Ganti Timeframe',
              style: TextStyle(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 4),
            Text(
              'Instrumen sama, timeframe berbeda — buat analisis baru tanpa keluar dari halaman ini.',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                fontSize: 11,
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _analysisTimeframes
                  .map((timeframe) {
                    final active = (selected ?? current) == timeframe;
                    return ChoiceChip(
                      label: Text(timeframe),
                      selected: active,
                      onSelected: loading ? null : (_) => onSelect(timeframe),
                    );
                  })
                  .toList(growable: false),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: loading ? null : onAnalyze,
                child: loading
                    ? const SizedBox.square(
                        dimension: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Analisis timeframe ini'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HeaderCard extends StatelessWidget {
  const _HeaderCard({
    required this.analysis,
    required this.biasColor,
    required this.biasLabel,
    required this.isExpired,
    required this.muted,
    required this.isPro,
  });

  final Analysis analysis;
  final Color biasColor;
  final String biasLabel;
  final bool isExpired;
  final Color muted;
  final bool isPro;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: biasColor.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    biasLabel,
                    style: TextStyle(
                      color: biasColor,
                      fontWeight: FontWeight.w800,
                      fontSize: 12.5,
                    ),
                  ),
                ),

                const Spacer(),

                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 9,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    isPro ? context.l10n.proMode : context.l10n.beginnerMode,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                      fontWeight: FontWeight.w800,
                      fontSize: 11,
                    ),
                  ),
                ),

                const SizedBox(width: 8),

                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 9,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: muted.withValues(alpha: 0.3)),
                  ),
                  child: Text(
                    analysis.timeframe,
                    style: TextStyle(
                      color: muted,
                      fontWeight: FontWeight.w700,
                      fontSize: 11,
                    ),
                  ),
                ),
              ],
            ),

            if (analysis.marketCondition?.trim().isNotEmpty == true) ...[
              const SizedBox(height: 12),
              Text(
                analysis.marketCondition!,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],

            if (analysis.confidenceMin != null &&
                analysis.confidenceMax != null) ...[
              const SizedBox(height: 14),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Keyakinan AI',
                    style: TextStyle(color: muted, fontSize: 12),
                  ),
                  Text(
                    '${analysis.confidenceMin}% – '
                    '${analysis.confidenceMax}%',
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                ],
              ),

              const SizedBox(height: 6),

              ClipRRect(
                borderRadius: BorderRadius.circular(999),
                child: LinearProgressIndicator(
                  value: ((analysis.confidenceMax ?? 0) / 100)
                      .clamp(0, 1)
                      .toDouble(),
                  minHeight: 7,
                  backgroundColor: muted.withValues(alpha: 0.12),
                  valueColor: AlwaysStoppedAnimation(biasColor),
                ),
              ),
            ],

            const SizedBox(height: 14),

            Row(
              children: [
                Icon(
                  Icons.schedule_rounded,
                  size: 15,
                  color: isExpired
                      ? Theme.of(context).colorScheme.error
                      : muted,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    isExpired
                        ? 'Masa berlaku analisis sudah berakhir'
                        : 'Berlaku sampai '
                              '${DateFormat('d MMM yyyy, HH:mm').format(analysis.validUntil.toLocal())}',
                    style: TextStyle(
                      color: isExpired
                          ? Theme.of(context).colorScheme.error
                          : muted,
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 6),

            Text(
              'Dibuat ${DateFormat('d MMM yyyy, HH:mm').format(analysis.createdAt.toLocal())}',
              style: TextStyle(color: muted, fontSize: 10.5),
            ),
          ],
        ),
      ),
    );
  }
}

// =============================================================================
// BEGINNER EXPLANATION
// =============================================================================

class _BeginnerMeaningCard extends StatelessWidget {
  const _BeginnerMeaningCard({
    required this.analysis,
    required this.biasLabel,
    required this.biasColor,
  });

  final Analysis analysis;
  final String biasLabel;
  final Color biasColor;

  @override
  Widget build(BuildContext context) {
    final muted = Theme.of(context).colorScheme.onSurfaceVariant;
    final bias = (analysis.tradingBias ?? '').toLowerCase();
    final direction = bias.contains('bull') || bias == 'buy'
        ? 'lebih condong naik'
        : bias.contains('bear') || bias == 'sell'
        ? 'lebih condong turun'
        : 'belum mempunyai arah dominan';

    final preferred = analysis.tradePlan?.preferredSide;

    late final String action;

    if (preferred == TradePlanPreferredSideEnum.buy) {
      action =
          'Struktur analisis lebih mendukung skenario Buy, '
          'tetapi entry tetap harus menunggu area dan kondisi yang dijelaskan di rencana trading.';
    } else if (preferred == TradePlanPreferredSideEnum.sell) {
      action =
          'Struktur analisis lebih mendukung skenario Sell, '
          'tetapi entry tetap harus mengikuti area dan batas risiko yang sudah ditentukan.';
    } else {
      action =
          'AI belum melihat entry yang cukup kuat. '
          'Untuk pemula, menunggu konfirmasi adalah keputusan yang valid.';
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.school_outlined, size: 19),
                SizedBox(width: 8),
                Text(
                  'Apa artinya?',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900),
                ),
              ],
            ),

            const SizedBox(height: 12),

            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  margin: const EdgeInsets.only(top: 5),
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: biasColor,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 9),
                Expanded(
                  child: Text(
                    'Bias $biasLabel berarti AI melihat kecenderungan market '
                    '$direction.',
                    style: const TextStyle(fontSize: 12.5, height: 1.45),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 10),

            Text(
              action,
              style: TextStyle(color: muted, fontSize: 12.5, height: 1.45),
            ),
          ],
        ),
      ),
    );
  }
}

// =============================================================================
// RISK
// =============================================================================

class _RiskCard extends StatelessWidget {
  const _RiskCard({required this.analysis, required this.isPro});

  final Analysis analysis;
  final bool isPro;

  @override
  Widget build(BuildContext context) {
    final risk = (analysis.riskLevel ?? '').trim().toLowerCase();

    final isDark = Theme.of(context).brightness == Brightness.dark;

    late final Color color;
    late final String label;
    late final String guidance;

    if (risk.contains('high') || risk.contains('tinggi')) {
      color = isDark ? AppColors.bearishDark : AppColors.bearishLight;
      label = 'Risiko Tinggi';
      guidance = isPro
          ? 'Volatilitas tinggi. Batasi eksposur dan gunakan level invalidasi sebagai batas risiko.'
          : 'Pergerakan dapat lebih agresif. Hindari ukuran posisi besar dan jangan mengabaikan Stop Loss.';
    } else if (risk.contains('low') || risk.contains('rendah')) {
      color = isDark ? AppColors.bullishDark : AppColors.bullishLight;
      label = 'Risiko Relatif Rendah';
      guidance =
          'Kondisi terlihat lebih stabil, tetapi risiko tetap ada. Tetap gunakan batas kerugian.';
    } else {
      color = isDark ? AppColors.darkPrimary : AppColors.lightPrimary;
      label = analysis.riskLevel?.trim().isNotEmpty == true
          ? analysis.riskLevel!
          : 'Risiko Sedang';
      guidance =
          'Ada peluang sekaligus ketidakpastian. Tunggu setup yang jelas dan gunakan ukuran posisi yang terukur.';
    }

    final details = [
      if (analysis.risk?.trim().isNotEmpty == true) analysis.risk!.trim(),
    ];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.shield_outlined, color: color, size: 20),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: TextStyle(
                    color: color,
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 10),

            Text(
              guidance,
              style: const TextStyle(fontSize: 12.5, height: 1.45),
            ),

            for (final item in details) ...[
              const SizedBox(height: 8),
              Text(
                item,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  fontSize: 11.5,
                  height: 1.4,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// =============================================================================
// MARKET SNAPSHOT
// =============================================================================

class _MarketSnapshotCard extends StatelessWidget {
  const _MarketSnapshotCard({required this.analysis});

  final Analysis analysis;

  @override
  Widget build(BuildContext context) {
    final muted = Theme.of(context).colorScheme.onSurfaceVariant;

    final buy = analysis.techBuyCount;

    final sell = analysis.techSellCount;

    final neutral = analysis.techNeutralCount;

    final hasCounts = buy != null || sell != null || neutral != null;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.analytics_outlined, size: 19),
                SizedBox(width: 8),
                Text(
                  'Konteks Saat Analisis Dibuat',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900),
                ),
              ],
            ),

            const SizedBox(height: 5),

            Text(
              'Bagian ini adalah snapshot data yang AI gunakan saat membuat analisis.',
              style: TextStyle(color: muted, fontSize: 11),
            ),

            if (hasCounts) ...[
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: _CountTile(
                      label: 'Buy',
                      value: buy ?? 0,
                      icon: Icons.north_east_rounded,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _CountTile(
                      label: 'Sell',
                      value: sell ?? 0,
                      icon: Icons.south_east_rounded,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _CountTile(
                      label: 'Netral',
                      value: neutral ?? 0,
                      icon: Icons.remove_rounded,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _CountTile extends StatelessWidget {
  const _CountTile({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final int value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        color: Theme.of(
          context,
        ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.45),
      ),
      child: Column(
        children: [
          Icon(icon, size: 16),
          const SizedBox(height: 3),
          Text(
            '$value',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
          ),
          Text(label, style: const TextStyle(fontSize: 10)),
        ],
      ),
    );
  }
}

// =============================================================================
// CHART
// =============================================================================

class _ChartCard extends StatelessWidget {
  const _ChartCard({
    required this.analysis,
    required this.candles,
    required this.isLoading,
    required this.error,
    required this.onOpenTradingView,
  });

  final Analysis analysis;
  final List<MarketCandle> candles;

  final bool isLoading;
  final String? error;
  final VoidCallback onOpenTradingView;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: Theme.of(
                      context,
                    ).colorScheme.primary.withValues(alpha: .12),
                    borderRadius: BorderRadius.circular(9),
                  ),
                  child: Icon(
                    Icons.candlestick_chart_rounded,
                    size: 19,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Grafik Harga',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${analysis.instrument} • ${analysis.timeframe}',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: 'Lihat chart lengkap di TradingView',
                  onPressed: onOpenTradingView,
                  icon: const Icon(Icons.open_in_new_rounded, size: 19),
                ),
              ],
            ),
            const SizedBox(height: 16),

            if (error != null && candles.isEmpty)
              Text(
                error!,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  fontSize: 12,
                ),
              )
            else
              AnalysisLevelsChart(
                candles: candles,
                tradePlan: analysis.tradePlan,
                tradingBias: analysis.tradingBias,
                isLoading: isLoading,
              ),
          ],
        ),
      ),
    );
  }
}

// =============================================================================
// FUNDAMENTAL SNAPSHOT
// =============================================================================

class _FundamentalSnapshotCard extends StatelessWidget {
  const _FundamentalSnapshotCard({
    required this.analysis,
    required this.refreshed,
    required this.refreshing,
    required this.onRefresh,
    required this.onOpenUrl,
  });

  final Analysis analysis;
  final RefreshFundamentalsResponse? refreshed;
  final bool refreshing;
  final VoidCallback onRefresh;
  final ValueChanged<String> onOpenUrl;

  @override
  Widget build(BuildContext context) {
    final contextData = analysis.fundamentalContext;

    if (contextData == null) {
      return const SizedBox.shrink();
    }

    final news = contextData.newsItems.take(3).toList();

    final events = contextData.calendarEvents.take(5).toList();

    if (news.isEmpty && events.isEmpty) {
      return const SizedBox.shrink();
    }

    final muted = Theme.of(context).colorScheme.onSurfaceVariant;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.newspaper_outlined, size: 19),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'Konteks Fundamental',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900),
                  ),
                ),
                IconButton(
                  tooltip: 'Refresh fundamental',
                  onPressed: refreshing ? null : onRefresh,
                  icon: refreshing
                      ? const SizedBox.square(
                          dimension: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.refresh_rounded, size: 20),
                ),
              ],
            ),

            const SizedBox(height: 5),

            Text(
              'Berita dan event ekonomi yang dilihat AI saat membuat analisis ini.',
              style: TextStyle(color: muted, fontSize: 11),
            ),

            if (refreshed != null) ...[
              const SizedBox(height: 10),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  refreshed!.drift.missingCitations.isEmpty
                      ? 'Fundamental terbaru masih mendukung seluruh sumber awal.'
                      : '${refreshed!.drift.missingCitations.length} dari ${refreshed!.drift.totalCitations} sumber awal tidak lagi ada di window terbaru.',
                  style: const TextStyle(fontSize: 11.5),
                ),
              ),
            ],

            if (news.isNotEmpty) ...[
              const SizedBox(height: 14),
              const Text(
                'Berita',
                style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 7),
              for (final item in news) ...[
                _FundamentalRow(
                  title: item.title,
                  meta:
                      '${item.source_} • '
                      '${DateFormat('d MMM HH:mm').format(item.publishedAt.toLocal())}',
                  icon: Icons.article_outlined,
                  onTap: () => onOpenUrl(item.url),
                ),
                const SizedBox(height: 9),
              ],
            ],

            if (events.isNotEmpty) ...[
              const SizedBox(height: 6),
              const Text(
                'Kalender Ekonomi',
                style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 7),
              for (final event in events) ...[
                _FundamentalRow(
                  title: event.event,
                  meta:
                      '${event.currency} • '
                      '${event.date} ${event.time} • '
                      '${event.impact}',
                  icon: Icons.calendar_month_outlined,
                ),
                const SizedBox(height: 9),
              ],
            ],
          ],
        ),
      ),
    );
  }
}

class _FundamentalRow extends StatelessWidget {
  const _FundamentalRow({
    required this.title,
    required this.meta,
    required this.icon,
    this.onTap,
  });

  final String title;
  final String meta;
  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final muted = Theme.of(context).colorScheme.onSurfaceVariant;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 16, color: muted),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(meta, style: TextStyle(color: muted, fontSize: 10)),
                ],
              ),
            ),
            if (onTap != null) const Icon(Icons.open_in_new_rounded, size: 15),
          ],
        ),
      ),
    );
  }
}

// =============================================================================
// OUTCOME
// =============================================================================

class _OutcomeCard extends StatelessWidget {
  const _OutcomeCard({required this.analysis});

  final Analysis analysis;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final muted = isDark
        ? AppColors.darkMutedForeground
        : AppColors.lightMutedForeground;

    final bullish = isDark ? AppColors.bullishDark : AppColors.bullishLight;

    final bearish = isDark ? AppColors.bearishDark : AppColors.bearishLight;

    final neutral = isDark ? AppColors.neutralDark : AppColors.neutralLight;

    final status = analysis.outcomeStatus;

    late final String label;
    late final String explanation;
    late final IconData icon;
    late final Color color;

    if (status == AnalysisOutcomeStatusEnum.pending) {
      label = 'Menunggu hasil';
      explanation =
          'Market masih berjalan dan sistem sedang mengevaluasi apakah level TP atau SL tersentuh.';
      icon = Icons.schedule_rounded;
      color = neutral;
    } else if (status == AnalysisOutcomeStatusEnum.tp1Hit) {
      label = 'TP1 Tercapai';
      explanation =
          'Harga sudah mencapai target profit pertama dari skenario analysis.';
      icon = Icons.trending_up_rounded;
      color = bullish;
    } else if (status == AnalysisOutcomeStatusEnum.tp2Hit) {
      label = 'TP2 Tercapai';
      explanation =
          'Harga sudah mencapai target profit kedua dari skenario analysis.';
      icon = Icons.rocket_launch_outlined;
      color = bullish;
    } else if (status == AnalysisOutcomeStatusEnum.slHit) {
      label = 'Stop Loss Tersentuh';
      explanation =
          'Harga mencapai batas risiko terlebih dahulu. '
          'Ini contoh kenapa Stop Loss penting dalam setiap setup.';
      icon = Icons.trending_down_rounded;
      color = bearish;
    } else if (status == AnalysisOutcomeStatusEnum.expired) {
      label = 'Kedaluwarsa';
      explanation =
          'Masa berlaku analysis selesai tanpa target utama terkonfirmasi.';
      icon = Icons.timer_off_outlined;
      color = neutral;
    } else if (status == AnalysisOutcomeStatusEnum.invalidated) {
      label = 'Analisis Tidak Valid';
      explanation = 'Setup tidak lagi memenuhi struktur analysis awal.';
      icon = Icons.warning_amber_rounded;
      color = bearish;
    } else {
      label = 'Status belum tersedia';
      explanation = 'Outcome belum dapat dievaluasi.';
      icon = Icons.info_outline;
      color = muted;
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.13),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 20),
            ),

            const SizedBox(width: 12),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      color: color,
                      fontSize: 13.5,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    explanation,
                    style: TextStyle(color: muted, fontSize: 11.5, height: 1.4),
                  ),
                  if (analysis.outcomeResolvedAt != null) ...[
                    const SizedBox(height: 5),
                    Text(
                      DateFormat(
                        'd MMM yyyy, HH:mm',
                      ).format(analysis.outcomeResolvedAt!.toLocal()),
                      style: TextStyle(color: muted, fontSize: 10.5),
                    ),
                  ],
                ],
              ),
            ),

            if (status == AnalysisOutcomeStatusEnum.pending)
              SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2, color: color),
              ),
          ],
        ),
      ),
    );
  }
}

Color _signalColor(BuildContext context, String signal) {
  final value = signal.toLowerCase();
  final dark = Theme.of(context).brightness == Brightness.dark;
  if (value.contains('buy') || value.contains('bull')) {
    return dark ? AppColors.bullishDark : AppColors.bullishLight;
  }
  if (value.contains('sell') || value.contains('bear')) {
    return dark ? AppColors.bearishDark : AppColors.bearishLight;
  }
  return Theme.of(context).colorScheme.onSurfaceVariant;
}

String _number(double? value, {int decimals = 2}) =>
    value == null ? '—' : value.toStringAsFixed(decimals);

String _summarySignal(int buy, int neutral, int sell) {
  if (buy > sell && buy > neutral) return 'Bullish';
  if (sell > buy && sell > neutral) return 'Bearish';
  return 'Neutral';
}

class _ConfidenceReasonCard extends StatelessWidget {
  const _ConfidenceReasonCard({
    required this.analysis,
    required this.reason,
    required this.onOpenUrl,
  });

  final Analysis analysis;
  final String reason;
  final ValueChanged<String> onOpenUrl;

  @override
  Widget build(BuildContext context) {
    final citations = analysis.fundamentalCitations;
    final news = analysis.fundamentalContext?.newsItems;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.help_outline_rounded, size: 18),
                SizedBox(width: 7),
                Expanded(
                  child: Text(
                    'Kenapa keyakinan tidak lebih tinggi?',
                    style: TextStyle(fontWeight: FontWeight.w900),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 9),
            Text(reason, style: const TextStyle(height: 1.45)),
            if (citations != null &&
                (citations.newsTitles.isNotEmpty ||
                    citations.calendarEvents.isNotEmpty)) ...[
              const SizedBox(height: 12),
              const Text(
                'Sumber yang dirujuk',
                style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 6),
              Wrap(
                spacing: 7,
                runSpacing: 7,
                children: [
                  for (final title in citations.newsTitles)
                    ActionChip(
                      avatar: const Icon(Icons.article_outlined, size: 15),
                      label: Text(title, overflow: TextOverflow.ellipsis),
                      onPressed: () {
                        for (final item
                            in news ?? const <FundamentalNewsItem>[]) {
                          if (item.title == title) {
                            onOpenUrl(item.url);
                            return;
                          }
                        }
                      },
                    ),
                  for (final event in citations.calendarEvents)
                    Chip(
                      avatar: const Icon(Icons.event_outlined, size: 15),
                      label: Text(event, overflow: TextOverflow.ellipsis),
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _TechnicalIndicatorsCard extends StatelessWidget {
  const _TechnicalIndicatorsCard({
    required this.technical,
    required this.timeframe,
    required this.showRawSignals,
  });

  final BeginnerTechnicalSnapshot technical;
  final String timeframe;
  final bool showRawSignals;

  @override
  Widget build(BuildContext context) {
    final movingAverages = [...technical.movingAverages]
      ..sort((a, b) {
        final byType = a.type.compareTo(b.type);
        return byType != 0 ? byType : a.period.compareTo(b.period);
      });
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Indikator Teknikal Live',
              style: TextStyle(fontWeight: FontWeight.w900, fontSize: 15),
            ),
            const SizedBox(height: 3),
            Text(
              'Data terbaru; dapat berbeda dari snapshot saat analisis dibuat.',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                fontSize: 11,
              ),
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _MetricChip(
                  label: 'Harga',
                  value: _number(technical.lastClose),
                ),
                _MetricChip(
                  label: 'Bar terakhir',
                  value: '${technical.change1dPercent.toStringAsFixed(2)}%',
                ),
                _MetricChip(
                  label: '20 bar',
                  value: '${technical.change20dPercent.toStringAsFixed(2)}%',
                ),
              ],
            ),
            const SizedBox(height: 14),
            _SignalSummary(
              title: 'Ringkasan sinyal',
              signal: technical.overallSignal,
              buy: technical.buyCount,
              neutral: technical.neutralCount,
              sell: technical.sellCount,
              showRawSignal: showRawSignals,
            ),
            const SizedBox(height: 8),
            _SignalSummary(
              title: 'Oscillator',
              signal: _summarySignal(
                technical.oscillatorBuyCount,
                technical.oscillatorNeutralCount,
                technical.oscillatorSellCount,
              ),
              buy: technical.oscillatorBuyCount,
              neutral: technical.oscillatorNeutralCount,
              sell: technical.oscillatorSellCount,
              showRawSignal: showRawSignals,
            ),
            const SizedBox(height: 8),
            _SignalSummary(
              title: 'Moving Average',
              signal: _summarySignal(
                technical.movingAverageBuyCount,
                technical.movingAverageNeutralCount,
                technical.movingAverageSellCount,
              ),
              buy: technical.movingAverageBuyCount,
              neutral: technical.movingAverageNeutralCount,
              sell: technical.movingAverageSellCount,
              showRawSignal: showRawSignals,
            ),
            const Divider(height: 28),
            ExpansionTile(
              key: const ValueKey('oscillator-indicators'),
              tilePadding: EdgeInsets.zero,
              childrenPadding: EdgeInsets.zero,
              shape: const Border(),
              collapsedShape: const Border(),
              title: Text(
                'Oscillator — $timeframe',
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
              subtitle: Padding(
                padding: const EdgeInsets.only(top: 10),
                child: _SignalScaleBar(
                  buy: technical.oscillatorBuyCount,
                  neutral: technical.oscillatorNeutralCount,
                  sell: technical.oscillatorSellCount,
                ),
              ),
              children: [
                _IndicatorRow(
                  label: 'RSI (14)',
                  value: _number(technical.rsi),
                  signal: technical.rsiSignal,
                  showSignal: showRawSignals,
                ),
                _IndicatorRow(
                  label: 'MACD (12,26)',
                  value: _number(technical.macdValue, decimals: 4),
                  signal: technical.macdAction,
                  showSignal: showRawSignals,
                ),
                _IndicatorRow(
                  label: 'Stochastic %K',
                  value: _number(technical.stochasticK),
                  signal: technical.stochasticSignal,
                  showSignal: showRawSignals,
                ),
                _IndicatorRow(
                  label: 'Bollinger',
                  value:
                      '${_number(technical.bollingerLower)}–${_number(technical.bollingerUpper)}',
                  signal: technical.bollingerSignal,
                  showSignal: showRawSignals,
                ),
              ],
            ),
            if (movingAverages.isNotEmpty) ...[
              const Divider(height: 28),
              ExpansionTile(
                key: const ValueKey('moving-average-indicators'),
                tilePadding: EdgeInsets.zero,
                childrenPadding: EdgeInsets.zero,
                shape: const Border(),
                collapsedShape: const Border(),
                title: const Text(
                  'Moving Averages',
                  style: TextStyle(fontWeight: FontWeight.w800),
                ),
                subtitle: Padding(
                  padding: const EdgeInsets.only(top: 10),
                  child: _SignalScaleBar(
                    buy: technical.movingAverageBuyCount,
                    neutral: technical.movingAverageNeutralCount,
                    sell: technical.movingAverageSellCount,
                  ),
                ),
                children: [
                  for (final average in movingAverages)
                    _IndicatorRow(
                      label:
                          '${average.type.toUpperCase()} (${average.period})',
                      value: _number(average.value),
                      signal: average.signal,
                      showSignal: showRawSignals,
                    ),
                ],
              ),
            ],
            if (technical.dataPoints > 0) ...[
              const SizedBox(height: 8),
              Text(
                'Data $timeframe • ${technical.dataPoints} candle',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  fontSize: 10.5,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _MetricChip extends StatelessWidget {
  const _MetricChip({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Container(
    constraints: const BoxConstraints(minWidth: 92),
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
    decoration: BoxDecoration(
      border: Border.all(color: Theme.of(context).dividerColor),
      borderRadius: BorderRadius.circular(12),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 10.5)),
        const SizedBox(height: 2),
        Text(value, style: const TextStyle(fontWeight: FontWeight.w800)),
      ],
    ),
  );
}

class _SignalSummary extends StatelessWidget {
  const _SignalSummary({
    required this.title,
    required this.signal,
    required this.buy,
    required this.neutral,
    required this.sell,
    required this.showRawSignal,
  });
  final String title;
  final String signal;
  final int buy;
  final int neutral;
  final int sell;
  final bool showRawSignal;

  @override
  Widget build(BuildContext context) {
    final normalized = signal.toLowerCase();
    final displaySignal = showRawSignal
        ? signal
        : normalized.contains('buy') || normalized.contains('bull')
        ? 'Cenderung Naik'
        : normalized.contains('sell') || normalized.contains('bear')
        ? 'Cenderung Turun'
        : 'Netral / Tunggu';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _signalColor(context, signal).withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _signalColor(context, signal).withValues(alpha: 0.35),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 11)),
          Text(
            displaySignal,
            style: TextStyle(
              color: _signalColor(context, signal),
              fontWeight: FontWeight.w900,
              fontSize: 17,
            ),
          ),
          const SizedBox(height: 10),
          _SignalScaleBar(buy: buy, neutral: neutral, sell: sell),
        ],
      ),
    );
  }
}

class _SignalScaleBar extends StatelessWidget {
  const _SignalScaleBar({
    required this.buy,
    required this.neutral,
    required this.sell,
  });

  final int buy;
  final int neutral;
  final int sell;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final bullish = dark ? AppColors.bullishDark : AppColors.bullishLight;
    final bearish = dark ? AppColors.bearishDark : AppColors.bearishLight;
    final neutralColor = Theme.of(context).colorScheme.onSurfaceVariant;
    final total = buy + neutral + sell;
    final position = total == 0 ? 0.5 : ((buy - sell) / total + 1) / 2;

    return Semantics(
      label: '$sell Bearish, $neutral Netral, $buy Bullish',
      child: Column(
        children: [
          LayoutBuilder(
            builder: (context, constraints) => SizedBox(
              key: const ValueKey('signal-scale-bar'),
              height: 18,
              child: Stack(
                children: [
                  Positioned(
                    left: 0,
                    right: 0,
                    top: 5,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(999),
                      child: SizedBox(
                        height: 8,
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Expanded(child: ColoredBox(color: bearish)),
                            Expanded(
                              child: ColoredBox(
                                color: bearish.withValues(alpha: 0.45),
                              ),
                            ),
                            Expanded(
                              child: ColoredBox(
                                color: neutralColor.withValues(alpha: 0.35),
                              ),
                            ),
                            Expanded(
                              child: ColoredBox(
                                color: bullish.withValues(alpha: 0.45),
                              ),
                            ),
                            Expanded(child: ColoredBox(color: bullish)),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    left: (constraints.maxWidth - 14) * position,
                    top: 2,
                    child: Container(
                      width: 14,
                      height: 14,
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surface,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Theme.of(context).colorScheme.onSurface,
                          width: 2,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Bearish ($sell)',
                style: TextStyle(color: bearish, fontSize: 10.5),
              ),
              Text(
                'Netral ($neutral)',
                style: TextStyle(color: neutralColor, fontSize: 10.5),
              ),
              Text(
                'Bullish ($buy)',
                style: TextStyle(color: bullish, fontSize: 10.5),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _IndicatorRow extends StatelessWidget {
  const _IndicatorRow({
    required this.label,
    required this.value,
    required this.signal,
    required this.showSignal,
  });
  final String label;
  final String value;
  final String signal;
  final bool showSignal;

  @override
  Widget build(BuildContext context) {
    final color = _signalColor(context, signal);
    return Semantics(
      label: '$label, $value, $signal',
      excludeSemantics: true,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 7),
        child: Row(
          children: [
            Container(
              key: ValueKey('indicator-signal-$label'),
              width: 7,
              height: 7,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            const SizedBox(width: 7),
            Expanded(child: Text(label, style: const TextStyle(fontSize: 12))),
            Text(
              value,
              style: TextStyle(color: color, fontWeight: FontWeight.w700),
            ),
            if (showSignal) ...[
              const SizedBox(width: 8),
              Text(
                signal,
                style: TextStyle(
                  color: color,
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _OpportunityRiskCard extends StatelessWidget {
  const _OpportunityRiskCard({required this.analysis});
  final Analysis analysis;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final cards = <Widget>[
        if (analysis.opportunity?.trim().isNotEmpty == true)
          _InfoPanel(
            title: 'Peluang',
            body: analysis.opportunity!,
            color: Theme.of(context).colorScheme.tertiary,
            icon: Icons.adjust_rounded,
          ),
        if (analysis.risk?.trim().isNotEmpty == true)
          _InfoPanel(
            title: 'Risiko',
            body: analysis.risk!,
            color: Theme.of(context).colorScheme.primary,
            icon: Icons.shield_outlined,
          ),
      ];
      if (constraints.maxWidth >= 620 && cards.length == 2) {
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: cards[0]),
            const SizedBox(width: 12),
            Expanded(child: cards[1]),
          ],
        );
      }
      return Column(
        children: [
          for (var index = 0; index < cards.length; index++) ...[
            cards[index],
            if (index < cards.length - 1) const SizedBox(height: 12),
          ],
        ],
      );
    },
  );
}

class _InfoPanel extends StatelessWidget {
  const _InfoPanel({
    required this.title,
    required this.body,
    required this.color,
    required this.icon,
  });
  final String title;
  final String body;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) => Card(
    child: Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border(left: BorderSide(color: color, width: 4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 19),
              const SizedBox(width: 7),
              Text(
                title,
                style: TextStyle(color: color, fontWeight: FontWeight.w900),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(body, style: const TextStyle(height: 1.45)),
        ],
      ),
    ),
  );
}

class _ExecutionInsightCard extends StatelessWidget {
  const _ExecutionInsightCard({required this.analysis});
  final Analysis analysis;

  @override
  Widget build(BuildContext context) => Card(
    child: ExpansionTile(
      leading: const Icon(Icons.lightbulb_outline_rounded),
      title: const Text(
        'Lihat Wawasan Eksekusi',
        style: TextStyle(fontWeight: FontWeight.w800),
      ),
      subtitle: const Text(
        'Cara menyikapi skenario tanpa menganggapnya sebagai perintah transaksi.',
      ),
      childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      children: [
        Text(
          'Tunggu konfirmasi price action, tentukan risiko maksimum sebelum entry, dan batalkan rencana ketika kondisi invalidasi terpenuhi. Jangan mengejar harga di luar area rencana.',
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
            height: 1.45,
          ),
        ),
      ],
    ),
  );
}

// =============================================================================
// GENERIC SECTION
// =============================================================================

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.title,
    required this.body,
    required this.icon,
    this.isWarning = false,
  });

  final String title;
  final String body;
  final IconData icon;

  final bool isWarning;

  @override
  Widget build(BuildContext context) {
    final warningColor = Theme.of(context).colorScheme.error;

    final muted = Theme.of(context).colorScheme.onSurfaceVariant;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 17, color: isWarning ? warningColor : null),
                const SizedBox(width: 7),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 13.5,
                      color: isWarning ? warningColor : null,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 8),

            Text(
              body,
              style: TextStyle(
                color: isWarning ? null : muted,
                fontSize: 13,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// =============================================================================
// TRADE PLAN
// =============================================================================

class _TradePlanCard extends StatelessWidget {
  const _TradePlanCard({required this.plan, required this.isDark});

  final TradePlan plan;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final preferBuy = plan.preferredSide == TradePlanPreferredSideEnum.buy;

    final preferSell = plan.preferredSide == TradePlanPreferredSideEnum.sell;

    final wait = plan.preferredSide == TradePlanPreferredSideEnum.wait;

    return Column(
      children: [
        if (wait) ...[
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: Theme.of(
                context,
              ).colorScheme.primary.withValues(alpha: 0.08),
            ),
            child: const Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.hourglass_top_rounded, size: 18),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Tunggu konfirmasi — AI belum merekomendasikan Buy atau Sell saat ini.',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
        ],

        _SideCard(
          side: plan.buy,
          label: 'Beli',
          color: isDark ? AppColors.bullishDark : AppColors.bullishLight,
          icon: Icons.trending_up_rounded,
          highlighted: preferBuy,
        ),

        const SizedBox(height: 10),

        _SideCard(
          side: plan.sell,
          label: 'Jual',
          color: isDark ? AppColors.bearishDark : AppColors.bearishLight,
          icon: Icons.trending_down_rounded,
          highlighted: preferSell,
        ),
      ],
    );
  }
}

class _SideCard extends StatelessWidget {
  const _SideCard({
    required this.side,
    required this.label,
    required this.color,
    required this.icon,
    required this.highlighted,
  });

  final TradeSide side;
  final String label;
  final Color color;
  final IconData icon;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final muted = isDark
        ? AppColors.darkMutedForeground
        : AppColors.lightMutedForeground;

    final border = isDark ? AppColors.darkBorder : AppColors.lightBorder;

    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppColors.radius),
        side: BorderSide(
          color: highlighted ? color : border,
          width: highlighted ? 1.5 : 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 18, color: color),
                const SizedBox(width: 6),
                Text(
                  label,
                  style: TextStyle(fontWeight: FontWeight.w900, color: color),
                ),

                if (highlighted) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.13),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      'Skenario Utama',
                      style: TextStyle(
                        color: color,
                        fontSize: 9.5,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ],
            ),

            const SizedBox(height: 12),

            _LevelRow(label: 'Zona Entry', value: side.entryZone, muted: muted),

            _LevelRow(
              label: 'Stop Loss',
              value: side.stopLoss,
              muted: muted,
              warning: true,
            ),

            _LevelRow(label: 'TP1', value: side.takeProfit1, muted: muted),

            _LevelRow(label: 'TP2', value: side.takeProfit2, muted: muted),

            _LevelRow(
              label: 'Risk : Reward',
              value: side.riskRewardRatio,
              muted: muted,
            ),

            const SizedBox(height: 10),

            Text(
              side.rationale,
              style: TextStyle(color: muted, fontSize: 11.5, height: 1.45),
            ),
          ],
        ),
      ),
    );
  }
}

class _LevelRow extends StatelessWidget {
  const _LevelRow({
    required this.label,
    required this.value,
    required this.muted,
    this.warning = false,
  });

  final String label;
  final String value;
  final Color muted;

  final bool warning;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(label, style: TextStyle(color: muted, fontSize: 11.5)),
          ),
          const SizedBox(width: 12),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: TextStyle(
                color: warning ? Theme.of(context).colorScheme.error : null,
                fontSize: 11.5,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
