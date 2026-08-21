import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:trade_pilot_api_client/trade_pilot_api_client.dart';

import '../../../core/market/market_sessions.dart';
import '../../../core/theme/app_colors.dart';
import '../../../models/market_models.dart';
import '../../../providers/analysis_provider.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/market_provider.dart';
import '../../../providers/watchlist_provider.dart';
import '../../../widgets/error_banner.dart';
import '../../../widgets/market_mini_chart.dart';
import '../../analysis/analysis_detail_screen.dart';
import '../../../widgets/price_alert_sheet.dart';

// =============================================================================
// TIMEFRAMES
// =============================================================================

const _timeframes = ['1m', '5m', '15m', '30m', '1h', '4h', '1D', '1W'];

CreateAnalysisBodyTimeframeEnum _analysisTimeframe(String timeframe) {
  switch (timeframe) {
    case '1m':
      return CreateAnalysisBodyTimeframeEnum.n1m;

    case '5m':
      return CreateAnalysisBodyTimeframeEnum.n5m;

    case '15m':
      return CreateAnalysisBodyTimeframeEnum.n15m;

    case '30m':
      return CreateAnalysisBodyTimeframeEnum.n30m;

    case '1h':
      return CreateAnalysisBodyTimeframeEnum.n1h;

    case '4h':
      return CreateAnalysisBodyTimeframeEnum.n4h;

    case '1D':
      return CreateAnalysisBodyTimeframeEnum.n1d;

    case '1W':
      return CreateAnalysisBodyTimeframeEnum.n1w;

    default:
      return CreateAnalysisBodyTimeframeEnum.n1h;
  }
}

// =============================================================================
// ANALYZE TAB
// =============================================================================

class AnalyzeTab extends StatefulWidget {
  const AnalyzeTab({super.key});

  @override
  State<AnalyzeTab> createState() => _AnalyzeTabState();
}

class _AnalyzeTabState extends State<AnalyzeTab> {
  final TextEditingController _contextController = TextEditingController();

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }

      final market = context.read<MarketProvider>();

      unawaited(market.loadSelectedMarketData());

      unawaited(market.loadQuotes());

      unawaited(context.read<WatchlistProvider>().loadWatchlist());
    });
  }

  @override
  void dispose() {
    _contextController.dispose();

    super.dispose();
  }

  // ===========================================================================
  // REFRESH
  // ===========================================================================

  Future<void> _refresh() async {
    final market = context.read<MarketProvider>();

    final analysis = context.read<AnalysisProvider>();

    final watchlist = context.read<WatchlistProvider>();

    await Future.wait([
      market.loadSelectedMarketData(force: true),
      market.loadQuotes(force: true),
      watchlist.loadWatchlist(),
      analysis.loadQuota(),
    ]);
  }

  // ===========================================================================
  // WATCHLIST
  // ===========================================================================

  Future<void> _toggleWatchlist(String instrument) async {
    final watchlist = context.read<WatchlistProvider>();

    if (watchlist.isWatchlisted(instrument)) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('Hapus dari watchlist?'),
          content: Text('Hapus $instrument dari watchlist?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Batal'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Hapus'),
            ),
          ],
        ),
      );

      if (confirmed != true || !mounted) {
        return;
      }
    }

    final ok = await watchlist.toggleInstrument(instrument);

    if (!mounted) {
      return;
    }

    if (!ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(watchlist.error ?? 'Gagal memperbarui watchlist.'),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Watchlist $instrument diperbarui.')),
      );
    }
  }

  // ===========================================================================
  // PRICE ALERT
  // ===========================================================================

  Future<void> _openPriceAlert(
    String instrument,
    LiveMarketQuote? quote,
  ) async {
    if (quote == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Price alert membutuhkan harga live. '
            'Harga live belum tersedia untuk instrumen ini.',
          ),
        ),
      );

      return;
    }

    final created = await showPriceAlertSheet(
      context: context,
      instrument: instrument,
      currentPrice: quote.price,
    );

    if (created == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Price alert $instrument berhasil dibuat.')),
      );
    }
  }

  // ===========================================================================
  // SUBMIT ANALYSIS
  // ===========================================================================

  Future<void> _submit() async {
    final auth = context.read<AuthProvider>();

    final analysisProvider = context.read<AnalysisProvider>();

    final market = context.read<MarketProvider>();

    final userMode = auth.user?.selectedMode == UserSelectedModeEnum.pro
        ? CreateAnalysisBodyModeEnum.pro
        : CreateAnalysisBodyModeEnum.beginner;

    final note = _contextController.text.trim();

    final result = await analysisProvider.createAnalysis(
      instrument: market.selectedInstrument,
      timeframe: _analysisTimeframe(market.selectedTimeframe),
      mode: userMode,
      userInputContext: note.isEmpty ? null : note,
    );

    if (result != null && mounted) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) =>
              AnalysisDetailScreen(analysisId: result.id, preloaded: result),
        ),
      );
    }
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

    final analysis = context.watch<AnalysisProvider>();

    final market = context.watch<MarketProvider>();

    final instrument = market.selectedInstrument;

    final timeframe = market.selectedTimeframe;

    final quote = market.selectedQuote;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Analisis AI'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(999),
                  color: isDark
                      ? AppColors.darkSecondary
                      : AppColors.lightSecondary,
                ),
                child: const Text(
                  'Mode Pemula',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
                ),
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _refresh,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            children: [
              ErrorBanner(message: analysis.errorMessage),

              ErrorBanner(message: market.marketError),

              // ---------------------------------------------------------------
              // BEGINNER INTRO
              // ---------------------------------------------------------------
              _BeginnerIntroCard(muted: muted),

              const SizedBox(height: 20),

              // ---------------------------------------------------------------
              // INSTRUMENT
              // ---------------------------------------------------------------
              const _SectionTitle(
                title: 'Pilih Instrumen',
                subtitle: 'Pilih market yang ingin kamu pahami.',
              ),

              const SizedBox(height: 14),

              for (final entry in MarketProvider.instrumentGroups.entries) ...[
                Text(
                  entry.key,
                  style: TextStyle(
                    color: muted,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),

                const SizedBox(height: 8),

                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: entry.value.map((item) {
                    return _SelectChip(
                      label: item,
                      selected: item == instrument,
                      onTap: () {
                        unawaited(market.selectInstrument(item));
                      },
                    );
                  }).toList(),
                ),

                const SizedBox(height: 14),
              ],

              // ---------------------------------------------------------------
              // TIMEFRAME
              // ---------------------------------------------------------------
              const SizedBox(height: 4),

              const _SectionTitle(
                title: 'Timeframe',
                subtitle: 'Timeframe menentukan sudut pandang analisis pasar.',
              ),

              const SizedBox(height: 12),

              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _timeframes.map((item) {
                  return _SelectChip(
                    label: item,
                    selected: timeframe == item,
                    onTap: () {
                      unawaited(market.selectTimeframe(item));
                    },
                  );
                }).toList(),
              ),

              const SizedBox(height: 22),

              // ---------------------------------------------------------------
              // MARKET OVERVIEW
              // ---------------------------------------------------------------
              _MarketOverviewCard(
                market: market,
                onToggleWatchlist: () {
                  unawaited(_toggleWatchlist(instrument));
                },
              ),

              const SizedBox(height: 14),

              // ---------------------------------------------------------------
              // TECHNICAL SUMMARY
              // ---------------------------------------------------------------
              _TechnicalSummaryCard(
                technical: market.selectedTechnical,
                isLoading: market.isLoadingSelectedMarket,
              ),

              const SizedBox(height: 14),

              // ---------------------------------------------------------------
              // ECONOMIC CALENDAR
              // ---------------------------------------------------------------
              _EconomicCalendarCard(
                instrument: instrument,
                events: market.selectedCalendar,
                isLoading: market.isLoadingSelectedMarket,
              ),

              const SizedBox(height: 14),

              // ---------------------------------------------------------------
              // ALERT
              // ---------------------------------------------------------------
              OutlinedButton.icon(
                onPressed: () {
                  unawaited(_openPriceAlert(instrument, quote));
                },
                icon: const Icon(Icons.notifications_active_outlined),
                label: Text(
                  quote == null
                      ? 'Price Alert Belum Tersedia'
                      : 'Buat Price Alert',
                ),
              ),

              if (quote == null) ...[
                const SizedBox(height: 7),
                Text(
                  'Instrumen ini belum memiliki feed harga live yang bisa dipakai untuk alert.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: muted, fontSize: 11.5),
                ),
              ],

              const SizedBox(height: 22),

              // ---------------------------------------------------------------
              // USER CONTEXT
              // ---------------------------------------------------------------
              const _SectionTitle(
                title: 'Catatan Tambahan',
                subtitle:
                    'Opsional. Ceritakan posisi atau kondisi yang ingin AI pertimbangkan.',
              ),

              const SizedBox(height: 10),

              TextField(
                controller: _contextController,
                maxLines: 3,
                maxLength: 500,
                textInputAction: TextInputAction.newline,
                decoration: const InputDecoration(
                  hintText:
                      'Contoh: Saya belum punya posisi dan ingin menunggu entry yang lebih aman...',
                ),
              ),

              const SizedBox(height: 10),

              // ---------------------------------------------------------------
              // HIGH IMPACT PRE-TRADE WARNING
              // ---------------------------------------------------------------
              if (_findHighImpactSoon(market.selectedCalendar) != null) ...[
                _PreTradeWarning(
                  event: _findHighImpactSoon(market.selectedCalendar)!,
                ),

                const SizedBox(height: 14),
              ],

              // ---------------------------------------------------------------
              // CTA
              // ---------------------------------------------------------------
              ElevatedButton.icon(
                onPressed: analysis.isSubmitting ? null : _submit,
                icon: analysis.isSubmitting
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.auto_awesome_rounded, size: 18),
                label: Text(
                  analysis.isSubmitting
                      ? 'Menganalisis pasar...'
                      : 'Dapatkan Analisis AI',
                ),
              ),

              if (analysis.quota != null && !analysis.quota!.unlimited) ...[
                const SizedBox(height: 10),
                Center(
                  child: Text(
                    '${analysis.quota!.daily.remaining} analisis tersisa hari ini',
                    style: TextStyle(color: muted, fontSize: 12.5),
                  ),
                ),
              ],

              const SizedBox(height: 12),

              Text(
                'Analisis AI adalah alat bantu pengambilan keputusan, bukan jaminan profit. '
                'Selalu pertimbangkan risiko sebelum membuka posisi.',
                textAlign: TextAlign.center,
                style: TextStyle(color: muted, fontSize: 11, height: 1.4),
              ),

              const SizedBox(height: 28),
            ],
          ),
        ),
      ),
    );
  }
}

// =============================================================================
// BEGINNER INTRO
// =============================================================================

class _BeginnerIntroCard extends StatelessWidget {
  const _BeginnerIntroCard({required this.muted});

  final Color muted;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.school_outlined, size: 22),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Pahami pasar sebelum entry',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    'Trade Pilot akan membantu menjelaskan harga, momentum, '
                    'sesi pasar, dan event penting dengan bahasa yang lebih sederhana.',
                    style: TextStyle(
                      color: muted,
                      fontSize: 12.5,
                      height: 1.45,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// =============================================================================
// MARKET OVERVIEW
// =============================================================================

class _MarketOverviewCard extends StatelessWidget {
  const _MarketOverviewCard({
    required this.market,
    required this.onToggleWatchlist,
  });

  final MarketProvider market;

  final VoidCallback onToggleWatchlist;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final muted = isDark
        ? AppColors.darkMutedForeground
        : AppColors.lightMutedForeground;

    final bullish = isDark ? AppColors.bullishDark : AppColors.bullishLight;

    final bearish = isDark ? AppColors.bearishDark : AppColors.bearishLight;

    final primary = isDark ? AppColors.darkPrimary : AppColors.lightPrimary;

    final watchlist = context.watch<WatchlistProvider>();

    final quote = market.selectedQuote;

    final technical = market.selectedTechnical;

    final fallbackPrice =
        technical?.lastClose ??
        (market.selectedCandles.isNotEmpty
            ? market.selectedCandles.last.close
            : null);

    final price = quote?.price ?? fallbackPrice;

    final change = quote?.changePercent ?? technical?.change1dPercent;

    final changeColor = (change ?? 0) >= 0 ? bullish : bearish;

    final instrument = market.selectedInstrument;

    final watchlisted = watchlist.isWatchlisted(instrument);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            instrument,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(width: 8),
                          _LiveStatusChip(isLive: quote != null),
                        ],
                      ),
                      const SizedBox(height: 5),
                      Text(
                        '${market.selectedTimeframe} • ${quote != null ? 'Harga live' : 'Harga referensi'}',
                        style: TextStyle(color: muted, fontSize: 11.5),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: watchlisted
                      ? 'Hapus dari watchlist'
                      : 'Tambahkan ke watchlist',
                  onPressed: watchlist.isUpdating ? null : onToggleWatchlist,
                  icon: watchlist.isUpdating
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Icon(
                          watchlisted
                              ? Icons.star_rounded
                              : Icons.star_border_rounded,
                          color: watchlisted ? primary : null,
                        ),
                ),
              ],
            ),

            const SizedBox(height: 14),

            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: Text(
                    price == null
                        ? '--'
                        : _formatMarketPrice(instrument, price),
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.7,
                    ),
                  ),
                ),

                if (change != null)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 9,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: changeColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          change >= 0
                              ? Icons.arrow_upward_rounded
                              : Icons.arrow_downward_rounded,
                          color: changeColor,
                          size: 14,
                        ),
                        const SizedBox(width: 2),
                        Text(
                          '${change >= 0 ? '+' : ''}${change.toStringAsFixed(2)}%',
                          style: TextStyle(
                            color: changeColor,
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),

            const SizedBox(height: 12),

            _MarketSessionPill(instrument: instrument),

            const SizedBox(height: 18),

            MarketMiniChart(
              candles: market.selectedCandles,
              accentColor: changeColor,
              isLoading: market.isLoadingSelectedMarket,
            ),

            if (quote != null && market.quotesUpdatedAt != null) ...[
              const SizedBox(height: 8),
              Text(
                'Harga diperbarui ${DateFormat('HH:mm:ss').format(market.quotesUpdatedAt!.toLocal())}',
                style: TextStyle(color: muted, fontSize: 10.5),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// =============================================================================
// LIVE STATUS
// =============================================================================

class _LiveStatusChip extends StatelessWidget {
  const _LiveStatusChip({required this.isLive});

  final bool isLive;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final bullish = isDark ? AppColors.bullishDark : AppColors.bullishLight;

    final neutral = isDark ? AppColors.neutralDark : AppColors.neutralLight;

    final color = isLive ? bullish : neutral;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        color: color.withValues(alpha: 0.1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(shape: BoxShape.circle, color: color),
          ),
          const SizedBox(width: 5),
          Text(
            isLive ? 'LIVE' : 'REFERENCE',
            style: TextStyle(
              color: color,
              fontSize: 9,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// MARKET SESSION
// =============================================================================

class _MarketSessionPill extends StatelessWidget {
  const _MarketSessionPill({required this.instrument});

  final String instrument;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final muted = isDark
        ? AppColors.darkMutedForeground
        : AppColors.lightMutedForeground;

    final bullish = isDark ? AppColors.bullishDark : AppColors.bullishLight;

    if (isCryptoMarketInstrument(instrument)) {
      return _SessionContainer(
        color: bullish,
        title: 'Market Crypto 24/7',
        subtitle: 'Crypto tidak mengikuti sesi forex.',
      );
    }

    final status = getMarketSessionStatus();

    if (status.openSessions.isEmpty) {
      return _SessionContainer(
        color: muted,
        title: status.isWeekendClosed
            ? 'Market ditutup akhir pekan'
            : 'Tidak ada sesi utama yang aktif',
        subtitle: status.next == null ? null : _nextSessionText(status.next!),
      );
    }

    final names = status.openSessions.map(marketSessionLabel).join(' • ');

    return _SessionContainer(
      color: bullish,
      title: names,
      subtitle: status.isOverlap
          ? 'Overlap sesi • likuiditas biasanya lebih tinggi'
          : status.next == null
          ? 'Sesi pasar aktif'
          : _nextSessionText(status.next!),
    );
  }

  String _nextSessionText(MarketSessionTransition transition) {
    final action = transition.type == 'open' ? 'buka' : 'tutup';

    return '${marketSessionLabel(transition.session)} $action dalam '
        '${formatMarketDuration(transition.until)}';
  }
}

class _SessionContainer extends StatelessWidget {
  const _SessionContainer({
    required this.color,
    required this.title,
    required this.subtitle,
  });

  final Color color;
  final String title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(subtitle!, style: const TextStyle(fontSize: 10.5)),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// TECHNICAL BEGINNER SUMMARY
// =============================================================================

class _TechnicalSummaryCard extends StatelessWidget {
  const _TechnicalSummaryCard({
    required this.technical,
    required this.isLoading,
  });

  final BeginnerTechnicalSnapshot? technical;

  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final muted = isDark
        ? AppColors.darkMutedForeground
        : AppColors.lightMutedForeground;

    if (isLoading && technical == null) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    if (technical == null) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            'Ringkasan teknikal belum tersedia untuk market ini.',
            style: TextStyle(color: muted, fontSize: 12.5),
          ),
        ),
      );
    }

    final trend = _trendInterpretation(technical!);

    final momentum = _momentumInterpretation(technical!);

    final confirmation = _macdInterpretation(technical!);

    final explanation = _beginnerExplanation(technical!);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.insights_outlined, size: 19),
                SizedBox(width: 8),
                Text(
                  'Kondisi Teknikal',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
                ),
              ],
            ),

            const SizedBox(height: 5),

            Text(
              'Kami sederhanakan indikator agar lebih mudah dibaca.',
              style: TextStyle(color: muted, fontSize: 11.5),
            ),

            const SizedBox(height: 14),

            _TechnicalRow(
              icon: Icons.trending_up,
              label: 'Arah',
              value: trend.$1,
              color: trend.$2,
            ),

            const Divider(height: 22),

            _TechnicalRow(
              icon: Icons.speed_rounded,
              label: 'Momentum',
              value: momentum.$1,
              color: momentum.$2,
            ),

            const Divider(height: 22),

            _TechnicalRow(
              icon: Icons.fact_check_outlined,
              label: 'Konfirmasi',
              value: confirmation.$1,
              color: confirmation.$2,
            ),

            const SizedBox(height: 16),

            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: isDark ? AppColors.darkMuted : AppColors.lightMuted,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Apa artinya?',
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    explanation,
                    style: TextStyle(color: muted, fontSize: 12, height: 1.45),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 10),

            Text(
              'RSI ${technical!.rsi?.toStringAsFixed(1) ?? '--'} '
              '• Buy ${technical!.buyCount} '
              '• Sell ${technical!.sellCount} '
              '• Netral ${technical!.neutralCount}',
              style: TextStyle(color: muted, fontSize: 10.5),
            ),
          ],
        ),
      ),
    );
  }

  (String, Color) _trendInterpretation(BeginnerTechnicalSnapshot t) {
    final isDark = false;

    // Warna diambil langsung agar tetap
    // konsisten ketika widget dibangun.
    if (t.bullish) {
      return ('Cenderung naik', AppColors.bullishLight);
    }

    if (t.bearish) {
      return ('Cenderung turun', AppColors.bearishLight);
    }

    return (
      'Belum jelas',
      isDark ? AppColors.neutralDark : AppColors.neutralLight,
    );
  }

  (String, Color) _momentumInterpretation(BeginnerTechnicalSnapshot t) {
    final rsi = t.rsi;

    if (rsi == null) {
      return ('Belum tersedia', AppColors.neutralLight);
    }

    if (rsi >= 70) {
      return ('Sudah cukup tinggi', AppColors.neutralLight);
    }

    if (rsi <= 30) {
      return ('Sudah cukup rendah', AppColors.neutralLight);
    }

    if (rsi >= 55) {
      return ('Momentum naik', AppColors.bullishLight);
    }

    if (rsi <= 45) {
      return ('Momentum turun', AppColors.bearishLight);
    }

    return ('Relatif netral', AppColors.neutralLight);
  }

  (String, Color) _macdInterpretation(BeginnerTechnicalSnapshot t) {
    switch (t.macdAction.toLowerCase()) {
      case 'buy':
        return ('Mendukung kenaikan', AppColors.bullishLight);

      case 'sell':
        return ('Mendukung penurunan', AppColors.bearishLight);

      default:
        return ('Belum memberi konfirmasi kuat', AppColors.neutralLight);
    }
  }

  String _beginnerExplanation(BeginnerTechnicalSnapshot t) {
    final rsi = t.rsi;

    if (t.bullish && rsi != null && rsi >= 70) {
      return 'Mayoritas indikator masih cenderung mendukung kenaikan, '
          'tetapi momentum sudah cukup tinggi. Hindari mengejar harga hanya '
          'karena melihat pergerakan naik.';
    }

    if (t.bullish) {
      return 'Lebih banyak indikator saat ini mendukung kenaikan. '
          'Tetap tunggu area entry dan batas risiko dari hasil analisis AI '
          'sebelum mengambil keputusan.';
    }

    if (t.bearish && rsi != null && rsi <= 30) {
      return 'Tekanan turun masih terlihat, tetapi harga sudah cukup tertekan. '
          'Kondisi seperti ini bisa mengalami pantulan sehingga entry terlambat '
          'perlu dihindari.';
    }

    if (t.bearish) {
      return 'Lebih banyak indikator saat ini mendukung penurunan. '
          'Gunakan hasil analisis berikutnya untuk memahami area invalidasi '
          'dan risiko sebelum bertindak.';
    }

    return 'Indikator belum menunjukkan arah yang dominan. '
        'Untuk pemula, kondisi seperti ini biasanya lebih baik dibaca dengan '
        'sabar daripada memaksakan entry.';
  }
}

class _TechnicalRow extends StatelessWidget {
  const _TechnicalRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 12.5,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}

// =============================================================================
// ECONOMIC CALENDAR
// =============================================================================

class _EconomicCalendarCard extends StatelessWidget {
  const _EconomicCalendarCard({
    required this.instrument,
    required this.events,
    required this.isLoading,
  });

  final String instrument;

  final List<EconomicCalendarEvent> events;

  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final muted = isDark
        ? AppColors.darkMutedForeground
        : AppColors.lightMutedForeground;

    final visibleEvents = events.take(6).toList();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.calendar_month_outlined, size: 19),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'Kalender Ekonomi',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
                  ),
                ),
                Text(
                  instrument,
                  style: TextStyle(color: muted, fontSize: 10.5),
                ),
              ],
            ),

            const SizedBox(height: 6),

            Text(
              'Berita ekonomi besar dapat membuat harga bergerak lebih cepat dari biasanya.',
              style: TextStyle(color: muted, fontSize: 11.5, height: 1.4),
            ),

            const SizedBox(height: 14),

            if (isLoading && events.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(12),
                  child: CircularProgressIndicator(),
                ),
              )
            else if (visibleEvents.isEmpty)
              Text(
                'Tidak ada event ekonomi relevan yang akan datang.',
                style: TextStyle(color: muted, fontSize: 12),
              )
            else
              for (var i = 0; i < visibleEvents.length; i++) ...[
                _CalendarEventRow(event: visibleEvents[i]),
                if (i != visibleEvents.length - 1) const Divider(height: 22),
              ],
          ],
        ),
      ),
    );
  }
}

class _CalendarEventRow extends StatelessWidget {
  const _CalendarEventRow({required this.event});

  final EconomicCalendarEvent event;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final muted = isDark
        ? AppColors.darkMutedForeground
        : AppColors.lightMutedForeground;

    final error = Theme.of(context).colorScheme.error;

    final impactColor = event.isHighImpact ? error : muted;

    final date = event.eventDateTime;

    final timeLabel = date == null
        ? '${event.date} ${event.time}'
        : DateFormat('d MMM • HH:mm').format(date);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(7),
            color: impactColor.withValues(alpha: 0.1),
          ),
          child: Text(
            event.impact.isEmpty ? '•' : event.impact,
            style: TextStyle(
              color: impactColor,
              fontSize: 9,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),

        const SizedBox(width: 9),

        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                event.event,
                style: const TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                '${event.currency} • $timeLabel',
                style: TextStyle(color: muted, fontSize: 10.5),
              ),
              if (event.actual.trim().isNotEmpty ||
                  event.forecast.trim().isNotEmpty ||
                  event.previous.trim().isNotEmpty) ...[
                const SizedBox(height: 7),

                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    if (event.actual.trim().isNotEmpty)
                      _CalendarMetric(label: 'Aktual', value: event.actual),

                    if (event.forecast.trim().isNotEmpty)
                      _CalendarMetric(label: 'Forecast', value: event.forecast),

                    if (event.previous.trim().isNotEmpty)
                      _CalendarMetric(
                        label: 'Sebelumnya',
                        value: event.previous,
                      ),
                  ],
                ),
              ],
              if (event.whyTraderCare.trim().isNotEmpty) ...[
                const SizedBox(height: 5),
                Text(
                  event.whyTraderCare,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: muted, fontSize: 10.5, height: 1.35),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

// =============================================================================
// PRE TRADE WARNING
// =============================================================================

EconomicCalendarEvent? _findHighImpactSoon(List<EconomicCalendarEvent> events) {
  final now = DateTime.now();

  final candidates = events.where((event) {
    if (!event.isHighImpact || event.actual.trim().isNotEmpty) {
      return false;
    }

    final date = event.eventDateTime;

    if (date == null) {
      return false;
    }

    final difference = date.difference(now);

    return !difference.isNegative && difference <= const Duration(minutes: 30);
  }).toList();

  candidates.sort((a, b) {
    final aDate = a.eventDateTime!;

    final bDate = b.eventDateTime!;

    return aDate.compareTo(bDate);
  });

  if (candidates.isEmpty) {
    return null;
  }

  return candidates.first;
}

class _PreTradeWarning extends StatelessWidget {
  const _PreTradeWarning({required this.event});

  final EconomicCalendarEvent event;

  @override
  Widget build(BuildContext context) {
    final error = Theme.of(context).colorScheme.error;

    final eventDate = event.eventDateTime;

    final minutes = eventDate == null
        ? null
        : eventDate.difference(DateTime.now()).inMinutes;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: error.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: error.withValues(alpha: 0.25)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.warning_amber_rounded, color: error),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Event high impact segera berlangsung',
                  style: TextStyle(
                    color: error,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${event.event}'
                  '${minutes == null ? '' : ' • sekitar $minutes menit lagi'}. '
                  'Harga dapat bergerak cepat dan spread dapat melebar.',
                  style: const TextStyle(fontSize: 11.5, height: 1.4),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// COMMON UI
// =============================================================================

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final muted = Theme.of(context).colorScheme.onSurfaceVariant;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
        ),
        const SizedBox(height: 3),
        Text(subtitle, style: TextStyle(color: muted, fontSize: 11.5)),
      ],
    );
  }
}

class _CalendarMetric extends StatelessWidget {
  const _CalendarMetric({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final muted = Theme.of(context).colorScheme.onSurfaceVariant;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
      decoration: BoxDecoration(
        color: Theme.of(
          context,
        ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(7),
      ),
      child: Text(
        '$label: $value',
        style: TextStyle(
          color: muted,
          fontSize: 9.5,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _SelectChip extends StatelessWidget {
  const _SelectChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final primary = isDark ? AppColors.darkPrimary : AppColors.lightPrimary;

    final border = isDark ? AppColors.darkBorder : AppColors.lightBorder;

    final onPrimary = isDark
        ? AppColors.darkPrimaryForeground
        : AppColors.lightPrimaryForeground;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          color: selected ? primary : Colors.transparent,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: selected ? primary : border),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: selected ? onPrimary : null,
          ),
        ),
      ),
    );
  }
}

// =============================================================================
// FORMATTERS
// =============================================================================

String _formatMarketPrice(String instrument, double value) {
  if (instrument == 'USD/IDR') {
    return NumberFormat('#,##0').format(value);
  }

  if (instrument == 'USD/JPY') {
    return value.toStringAsFixed(2);
  }

  if (value >= 1000) {
    return NumberFormat('#,##0.00').format(value);
  }

  if (value >= 100) {
    return value.toStringAsFixed(2);
  }

  if (value >= 1) {
    return value.toStringAsFixed(4);
  }

  return value.toStringAsFixed(6);
}
