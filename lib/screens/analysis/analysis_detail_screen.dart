import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:trade_pilot_api_client/trade_pilot_api_client.dart';

import '../../core/theme/app_colors.dart';
import '../../models/market_models.dart';
import '../../providers/analysis_provider.dart';
import '../../providers/market_provider.dart';
import '../../widgets/analysis_levels_chart.dart';
import '../../widgets/price_alert_sheet.dart';

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

  bool _loading = true;
  bool _submittingFeedback = false;
  bool _detailRequestInFlight = false;
  bool _marketRequestInFlight = false;
  bool _marketLoading = false;

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

      final candles = await provider.getCandlesFor(
        analysis.instrument,
        analysis.timeframe,
        force: force,
      );

      // Price alert membutuhkan quote live,
      // tetapi kegagalan quote tidak boleh
      // membuat seluruh detail error.
      unawaited(provider.loadQuotes(force: force, silent: true));

      if (!mounted) {
        return;
      }

      setState(() {
        _candles = candles;
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

  Future<void> _sendFeedback(FeedbackBodyFeedbackTypeEnum type) async {
    if (_submittingFeedback) {
      return;
    }

    setState(() {
      _submittingFeedback = true;
    });

    final ok = await context.read<AnalysisProvider>().submitFeedback(
      analysisId: widget.analysisId,
      type: type,
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

    final biasColor =
        bias.contains('bull') || bias == 'buy' || bias == 'strong_buy'
        ? (isDark ? AppColors.bullishDark : AppColors.bullishLight)
        : bias.contains('bear') || bias == 'sell' || bias == 'strong_sell'
        ? (isDark ? AppColors.bearishDark : AppColors.bearishLight)
        : (isDark ? AppColors.neutralDark : AppColors.neutralLight);

    final biasLabel =
        bias.contains('bull') || bias == 'buy' || bias == 'strong_buy'
        ? 'Bullish'
        : bias.contains('bear') || bias == 'sell' || bias == 'strong_sell'
        ? 'Bearish'
        : 'Netral';

    final isExpired = analysis.validUntil.isBefore(DateTime.now());

    return Scaffold(
      appBar: AppBar(
        title: Text(analysis.instrument),
        actions: [
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
            ),

            const SizedBox(height: 14),

            _BeginnerMeaningCard(
              analysis: analysis,
              biasLabel: biasLabel,
              biasColor: biasColor,
            ),

            if (analysis.outcomeStatus != null) ...[
              const SizedBox(height: 14),
              _OutcomeCard(analysis: analysis),
            ],

            const SizedBox(height: 14),

            _RiskCard(analysis: analysis),

            const SizedBox(height: 14),

            _MarketSnapshotCard(analysis: analysis),

            const SizedBox(height: 14),

            _ChartCard(
              analysis: analysis,
              candles: _candles,
              isLoading: _marketLoading,
              error: _marketError,
            ),

            if (analysis.mainScenario?.trim().isNotEmpty == true) ...[
              const SizedBox(height: 14),
              _SectionCard(
                title: 'Skenario Utama',
                body: analysis.mainScenario!,
                icon: Icons.route_outlined,
              ),
            ],

            if (analysis.alternativeScenario?.trim().isNotEmpty == true) ...[
              const SizedBox(height: 12),
              _SectionCard(
                title: 'Skenario Alternatif',
                body: analysis.alternativeScenario!,
                icon: Icons.alt_route_rounded,
              ),
            ],

            if (analysis.whyReason?.trim().isNotEmpty == true) ...[
              const SizedBox(height: 12),
              _SectionCard(
                title: 'Kenapa AI melihat kondisi ini?',
                body: analysis.whyReason!,
                icon: Icons.psychology_outlined,
              ),
            ],

            if ((analysis.failureConditions ?? analysis.invalidationConditions)
                    ?.trim()
                    .isNotEmpty ==
                true) ...[
              const SizedBox(height: 12),
              _SectionCard(
                title: 'Kapan analisis ini tidak lagi valid?',
                body:
                    (analysis.failureConditions ??
                    analysis.invalidationConditions)!,
                icon: Icons.warning_amber_rounded,
                isWarning: true,
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

            if (analysis.fundamentalContext != null) ...[
              const SizedBox(height: 14),
              _FundamentalSnapshotCard(analysis: analysis),
            ],

            const SizedBox(height: 22),

            OutlinedButton.icon(
              onPressed: _openPriceAlert,
              icon: const Icon(Icons.notifications_active_outlined),
              label: const Text('Buat Price Alert'),
            ),

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
                            _sendFeedback(FeedbackBodyFeedbackTypeEnum.useful);
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
                            _sendFeedback(
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

class _HeaderCard extends StatelessWidget {
  const _HeaderCard({
    required this.analysis,
    required this.biasColor,
    required this.biasLabel,
    required this.isExpired,
    required this.muted,
  });

  final Analysis analysis;
  final Color biasColor;
  final String biasLabel;
  final bool isExpired;
  final Color muted;

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
                    '${biasLabel == 'Bullish'
                        ? 'lebih condong naik'
                        : biasLabel == 'Bearish'
                        ? 'lebih condong turun'
                        : 'belum mempunyai arah dominan'}.',
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
  const _RiskCard({required this.analysis});

  final Analysis analysis;

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
      guidance =
          'Pergerakan dapat lebih agresif. Untuk pemula, hindari ukuran posisi besar dan jangan mengabaikan Stop Loss.';
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
      if (analysis.uncertaintyNotes?.trim().isNotEmpty == true)
        analysis.uncertaintyNotes!.trim(),
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

            if (analysis.keyDriversTechnical?.trim().isNotEmpty == true) ...[
              const SizedBox(height: 14),
              _SnapshotText(
                title: 'Faktor Teknikal',
                value: analysis.keyDriversTechnical!,
              ),
            ],

            if (analysis.marketContext?.trim().isNotEmpty == true) ...[
              const SizedBox(height: 12),
              _SnapshotText(
                title: 'Market Context',
                value: analysis.marketContext!,
              ),
            ],

            if (analysis.keyDriversFundamental?.trim().isNotEmpty == true) ...[
              const SizedBox(height: 12),
              _SnapshotText(
                title: 'Faktor Fundamental',
                value: analysis.keyDriversFundamental!,
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

class _SnapshotText extends StatelessWidget {
  const _SnapshotText({required this.title, required this.value});

  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    final muted = Theme.of(context).colorScheme.onSurfaceVariant;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 4),
        Text(value, style: TextStyle(color: muted, fontSize: 12, height: 1.45)),
      ],
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
  });

  final Analysis analysis;
  final List<MarketCandle> candles;

  final bool isLoading;
  final String? error;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.show_chart_rounded, size: 19),
                SizedBox(width: 8),
                Text(
                  'Chart & Reference Level',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900),
                ),
              ],
            ),

            const SizedBox(height: 5),

            Text(
              '${analysis.instrument} • ${analysis.timeframe}',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                fontSize: 11,
              ),
            ),

            const SizedBox(height: 14),

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
                analysisCreatedAt: analysis.createdAt,
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
  const _FundamentalSnapshotCard({required this.analysis});

  final Analysis analysis;

  @override
  Widget build(BuildContext context) {
    final contextData = analysis.fundamentalContext;

    if (contextData == null) {
      return const SizedBox.shrink();
    }

    final news = contextData.newsItems.take(3).toList();

    final events = contextData.calendarEvents.take(3).toList();

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
            const Row(
              children: [
                Icon(Icons.newspaper_outlined, size: 19),
                SizedBox(width: 8),
                Text(
                  'Fundamental yang Dilihat AI',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900),
                ),
              ],
            ),

            const SizedBox(height: 5),

            Text(
              'Ini adalah snapshot berita dan kalender saat analisis dibuat.',
              style: TextStyle(color: muted, fontSize: 11),
            ),

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
  });

  final String title;
  final String meta;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final muted = Theme.of(context).colorScheme.onSurfaceVariant;

    return Row(
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
      ],
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
