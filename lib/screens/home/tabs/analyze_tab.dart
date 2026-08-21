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
import '../../../widgets/chart/timeframe_selector.dart';
import '../../../widgets/calendar/economic_calendar_card.dart';
import '../../../widgets/context/market_context_card.dart';
import '../../../widgets/technical/technical_summary_card.dart';
import '../../../widgets/market_mini_chart.dart';
import '../../analysis/analysis_detail_screen.dart';
import '../../../widgets/price_alert/price_alert_sheet.dart';
import '../../price_alert/price_alert_list_screen.dart';

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

    final highImpactSoon = _findHighImpactSoon(market.highImpactEvents);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Analisis AI'),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_active_outlined),
            tooltip: 'Price Alert Saya',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const PriceAlertListScreen()),
              );
            },
          ),
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

              TimeframeSelector(
                timeframes: _timeframes,
                selected: timeframe,
                isLoading: market.isLoadingSelectedMarket,
                onSelected: (item) {
                  unawaited(market.selectTimeframe(item));
                },
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
              // MARKET CONTEXT
              // ---------------------------------------------------------------
              MarketContextCard(
                instrument: instrument,
                marketContext: market.selectedMarketContext,
                isLoading: market.isLoadingSelectedMarket,
                hasError:
                    market.marketError != null &&
                    market.selectedCandles.isEmpty,
                onRetry: () {
                  unawaited(market.loadSelectedMarketData(force: true));
                },
              ),

              const SizedBox(height: 14),

              // ---------------------------------------------------------------
              // TECHNICAL SUMMARY
              // ---------------------------------------------------------------
              TechnicalSummaryCard(
                summary: market.selectedTechnicalSummary,
                isLoading: market.isLoadingSelectedMarket,
                hasError:
                    market.marketError != null &&
                    market.selectedTechnical == null,
                onRetry: () {
                  unawaited(market.loadSelectedMarketData(force: true));
                },
              ),

              const SizedBox(height: 14),

              // ---------------------------------------------------------------
              // ECONOMIC CALENDAR
              // ---------------------------------------------------------------
              EconomicCalendarCard(
                instrument: instrument,
                events: market.selectedCalendar,
                isLoading: market.isLoadingSelectedMarket,
                hasError:
                    market.marketError != null &&
                    market.selectedCalendar.isEmpty,
                onRetry: () {
                  unawaited(market.loadSelectedMarketData(force: true));
                },
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
              if (highImpactSoon != null) ...[
                _PreTradeWarning(event: highImpactSoon),

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
              technical: market.selectedTechnical,
              currentPrice: quote?.price,
              error: market.marketError == null
                  ? null
                  : 'Sebagian data chart belum tersedia.',
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
