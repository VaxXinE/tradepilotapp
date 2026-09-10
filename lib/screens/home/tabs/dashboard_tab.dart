import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:trade_pilot_api_client/trade_pilot_api_client.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/config/sponsor_config.dart';
import '../../../core/theme/app_colors.dart';
import '../../../l10n/l10n.dart';
import '../../../models/market_models.dart';
import '../../../providers/analysis_provider.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/market_provider.dart';
import '../../../providers/notifications_provider.dart';
import '../../../providers/watchlist_provider.dart';
import '../../../widgets/analysis_card.dart';
import '../../../widgets/app_footer.dart';
import '../../../widgets/calendar/economic_calendar_card.dart';
import '../../../widgets/market/market_overview_card.dart';
import '../../../widgets/market/market_session_card.dart';
import '../../../widgets/news_feed_card.dart';
import '../../../widgets/price_alert/price_alert_sheet.dart';
import '../../../widgets/watchlist/instrument_picker_sheet.dart';
import '../../../widgets/watchlist/watchlist_item_card.dart';
import '../../analysis/analysis_detail_screen.dart';

class DashboardTab extends StatefulWidget {
  const DashboardTab({
    super.key,
    required this.onOpenAnalyze,
    required this.onOpenHistory,
  });

  final void Function(String? instrument) onOpenAnalyze;

  final VoidCallback onOpenHistory;

  @override
  State<DashboardTab> createState() => _DashboardTabState();
}

class _DashboardTabState extends State<DashboardTab> {
  AnalysisOutcomesSummary? _outcomes;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadOutcomes());
  }

  Future<void> _loadOutcomes() async {
    try {
      final response = await context
          .read<AuthProvider>()
          .client
          .analyses
          .getAnalysisOutcomesSummary();
      if (mounted) setState(() => _outcomes = response.data);
    } catch (_) {
      // Statistik tambahan tidak boleh menghalangi dashboard utama.
    }
  }

  Future<void> _openWatchlistManager() async {
    final watchlist = context.read<WatchlistProvider>();

    await watchlist.loadWatchlist();

    if (!mounted) {
      return;
    }

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) {
        return const _WatchlistManagerSheet();
      },
    );
  }

  // ===========================================================================
  // LOAD
  // ===========================================================================

  Future<void> _refresh() async {
    final analysis = context.read<AnalysisProvider>();

    final market = context.read<MarketProvider>();

    final watchlist = context.read<WatchlistProvider>();

    final notifications = context.read<NotificationsProvider>();

    await Future.wait([
      analysis.refreshCoreData(silent: false),
      watchlist.loadWatchlist(),
      market.loadQuotes(force: true),
      notifications.load(silent: true),
      _loadOutcomes(),
    ]);
  }

  // ===========================================================================
  // PRICE ALERT
  // ===========================================================================

  Future<void> _openAlert(String instrument, LiveMarketQuote quote) async {
    final created = await showPriceAlertSheet(
      context: context,
      instrument: instrument,
      currentPrice: quote.price,
    );

    if (!mounted) {
      return;
    }

    if (created == true) {
      unawaited(
        context.read<AuthProvider>().telemetry.track(
          AnalyticsEventBodyEventTypeEnum.alertArmed,
          path: '/',
          metadata: {'instrument': instrument},
        ),
      );
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.priceAlertCreated(instrument))),
      );
    }
  }

  Future<void> _openSponsorTikTok() async {
    unawaited(
      context.read<AuthProvider>().telemetry.recordOutboundClick(
        placement: OutboundClickBodyPlacementEnum.dashboardTiktok,
        target: OutboundClickBodyTargetEnum.tiktok,
        languageCode: Localizations.localeOf(context).languageCode,
      ),
    );
    final uri = Uri.parse(sponsorTikTokUrl);
    try {
      if (await launchUrl(uri, mode: LaunchMode.externalApplication)) return;
    } catch (_) {
      // Telemetry dan browser eksternal tidak boleh merusak dashboard.
    }
    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(context.l10n.linkOpenFailed)));
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

    final auth = context.watch<AuthProvider>();

    final analysisProvider = context.watch<AnalysisProvider>();

    final market = context.watch<MarketProvider>();

    final watchlist = context.watch<WatchlistProvider>();

    final l10n = context.l10n;

    final user = auth.user;

    final summary = analysisProvider.summary;

    final recentAnalyses = analysisProvider.history.take(5).toList();

    final isLoadingAnalysisData =
        (analysisProvider.isLoadingSummary ||
            analysisProvider.isLoadingHistory) &&
        summary == null &&
        analysisProvider.history.isEmpty;

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          children: [
            // ---------------------------------------------------------------
            // GREETING
            // ---------------------------------------------------------------
            _DashboardGreeting(
              displayName: user?.displayName.trim().isNotEmpty == true
                  ? user!.displayName.trim()
                  : l10n.trader,
              isPro: user?.selectedMode == UserSelectedModeEnum.pro,
              muted: muted,
              onAnalyze: () => widget.onOpenAnalyze(null),
            ),

            const SizedBox(height: 18),

            if (user?.onboardingCompleted != true) ...[
              _OnboardingCard(
                onDone: () => context.read<AuthProvider>().completeOnboarding(),
              ),
              const SizedBox(height: 16),
            ],

            MarketOverviewCard(
              quote: market.selectedQuote,
              isLoading: market.isLoadingQuotes,
              error: market.marketError,
              updatedAt: market.quotesUpdatedAt,
              onRetry: () {
                unawaited(market.loadQuotes(force: true));
              },
              onOpen: () {
                widget.onOpenAnalyze(market.selectedInstrument);
              },
            ),

            const SizedBox(height: 16),

            // Primary task stays near the top; market context remains below.
            _BeginnerHeroCard(
              onAnalyze: () {
                widget.onOpenAnalyze(null);
              },
            ),

            const SizedBox(height: 16),

            MarketSessionCard(instrument: market.selectedInstrument),

            const SizedBox(height: 16),

            if (isLoadingAnalysisData)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 28),
                child: Center(child: CircularProgressIndicator()),
              )
            else ...[
              DashboardStats(summary: summary),
              const SizedBox(height: 14),
              if (_outcomes case final outcomes?) ...[
                _OutcomeSummaryCard(outcomes: outcomes),
                const SizedBox(height: 14),
              ],
              if (analysisProvider.quota != null)
                _QuotaCard(quota: analysisProvider.quota!),
              const SizedBox(height: 16),
            ],

            EconomicCalendarCard(
              instrument: market.selectedInstrument,
              events: market.selectedCalendar,
              isLoading: market.isLoadingSelectedMarket,
              hasError: market.marketError != null,
              onRetry: () =>
                  unawaited(market.loadSelectedMarketData(force: true)),
            ),

            const SizedBox(height: 16),

            const NewsFeedCard(),

            if (showSponsor) ...[
              const SizedBox(height: 16),
              Card(
                child: ListTile(
                  leading: const Icon(Icons.live_tv_outlined),
                  title: Text(l10n.liveAnalysisTitle),
                  subtitle: Text(l10n.liveAnalysisSponsorSubtitle),
                  trailing: const Icon(Icons.open_in_new_rounded),
                  onTap: _openSponsorTikTok,
                ),
              ),
            ],

            const SizedBox(height: 16),

            // ---------------------------------------------------------------
            // WATCHLIST / LIVE MARKET
            // ---------------------------------------------------------------
            _WatchlistMarketCard(
              market: market,
              watchlist: watchlist,
              onOpenInstrument: widget.onOpenAnalyze,
              onCreateAlert: _openAlert,
              onManageWatchlist: _openWatchlistManager,
            ),

            const SizedBox(height: 16),

            _AllMarketsCard(
              quotes: market.quotes.values.toList(),
              onOpenInstrument: widget.onOpenAnalyze,
            ),

            const SizedBox(height: 20),

            if (!isLoadingAnalysisData) ...[
              // -------------------------------------------------------------
              // RECENT ANALYSIS HEADER
              // -------------------------------------------------------------
              Row(
                children: [
                  Expanded(
                    child: Text(
                      l10n.latestAnalyses,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: widget.onOpenHistory,
                    child: Text(l10n.viewAll),
                  ),
                ],
              ),

              const SizedBox(height: 8),

              if (recentAnalyses.isEmpty)
                _EmptyRecent(
                  muted: muted,
                  onAnalyze: () {
                    widget.onOpenAnalyze(null);
                  },
                )
              else
                ...recentAnalyses.map((analysis) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: AnalysisCard(
                      analysis: analysis,
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => AnalysisDetailScreen(
                              analysisId: analysis.id,
                              preloaded: analysis,
                              onNewAnalysis: () {
                                Navigator.of(context).pop();
                                widget.onOpenAnalyze(null);
                              },
                            ),
                          ),
                        );
                      },
                    ),
                  );
                }),
            ],

            const SizedBox(height: 20),

            Text(
              l10n.decisionDisclaimer,
              textAlign: TextAlign.center,
              style: TextStyle(color: muted, fontSize: 12, height: 1.4),
            ),

            const AppFooter(),
          ],
        ),
      ),
    );
  }
}

// =============================================================================
// NOTIFICATION ICON
// =============================================================================

class _DashboardGreeting extends StatelessWidget {
  const _DashboardGreeting({
    required this.displayName,
    required this.isPro,
    required this.muted,
    required this.onAnalyze,
  });

  final String displayName;
  final bool isPro;
  final Color muted;
  final VoidCallback onAnalyze;

  @override
  Widget build(BuildContext context) {
    final greeting = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 6,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text(
              context.l10n.welcomeBack.toUpperCase(),
              style: TextStyle(
                color: muted,
                fontSize: 12,
                letterSpacing: 1,
                fontWeight: FontWeight.w600,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.secondary,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                isPro ? 'PRO' : context.l10n.beginner.toUpperCase(),
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSecondary,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.7,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          displayName,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.4,
          ),
        ),
      ],
    );
    final action = FilledButton.icon(
      key: const Key('dashboard-new-analysis'),
      onPressed: onAnalyze,
      style: FilledButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 14),
        minimumSize: const Size(0, 48),
        textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
      ),
      icon: const Icon(Icons.add_rounded, size: 18),
      label: Text(context.l10n.analysis),
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final stack =
            constraints.maxWidth < 340 ||
            MediaQuery.textScalerOf(context).scale(1) > 1.3;
        if (stack) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [greeting, const SizedBox(height: 12), action],
          );
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(child: greeting),
            const SizedBox(width: 10),
            action,
          ],
        );
      },
    );
  }
}

class _OnboardingCard extends StatelessWidget {
  const _OnboardingCard({required this.onDone});
  final Future<bool> Function() onDone;

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.l10n.getStarted,
            style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
          ),
          const SizedBox(height: 8),
          Text(context.l10n.onboardingSteps),
          const SizedBox(height: 12),
          FilledButton(
            onPressed: () => onDone(),
            child: Text(context.l10n.gotIt),
          ),
        ],
      ),
    ),
  );
}

class _AllMarketsCard extends StatelessWidget {
  const _AllMarketsCard({required this.quotes, required this.onOpenInstrument});
  final List<LiveMarketQuote> quotes;
  final void Function(String? instrument) onOpenInstrument;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    if (quotes.isEmpty) return const SizedBox.shrink();
    final itemExtent =
        68 * MediaQuery.textScalerOf(context).scale(1).clamp(1.0, 1.6);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              context.l10n.liveMarkets,
              style: const TextStyle(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: quotes.length.clamp(1, 3) * itemExtent,
              child: Scrollbar(
                child: ListView.builder(
                  key: const Key('live-markets-list'),
                  primary: false,
                  itemExtent: itemExtent,
                  itemCount: quotes.length,
                  itemBuilder: (_, index) {
                    final quote = quotes[index];
                    return ListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      title: Text(quote.instrument),
                      subtitle: Text(
                        _formatPrice(quote.instrument, quote.price),
                      ),
                      trailing: Text(
                        '${quote.changePercent > 0 ? '+' : ''}${quote.changePercent.toStringAsFixed(2)}%',
                        style: TextStyle(
                          color: quote.changePercent > 0
                              ? (isDark
                                    ? AppColors.bullishDark
                                    : AppColors.bullishLight)
                              : quote.changePercent < 0
                              ? (isDark
                                    ? AppColors.bearishDark
                                    : AppColors.bearishLight)
                              : Theme.of(context).colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      onTap: () => onOpenInstrument(quote.instrument),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// =============================================================================
// BEGINNER HERO
// =============================================================================

class _BeginnerHeroCard extends StatelessWidget {
  const _BeginnerHeroCard({required this.onAnalyze});

  final VoidCallback onAnalyze;

  @override
  Widget build(BuildContext context) {
    final muted = Theme.of(context).colorScheme.onSurfaceVariant;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.auto_awesome_rounded, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    context.l10n.wantMarketAnalysis,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 7),

            Text(
              context.l10n.analysisPreparation,
              style: TextStyle(color: muted, fontSize: 12, height: 1.4),
            ),

            const SizedBox(height: 14),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: onAnalyze,
                icon: const Icon(Icons.insights_rounded),
                label: Text(context.l10n.startAnalysis),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// =============================================================================
// WATCHLIST
// =============================================================================

class _WatchlistMarketCard extends StatelessWidget {
  const _WatchlistMarketCard({
    required this.market,
    required this.watchlist,
    required this.onOpenInstrument,
    required this.onCreateAlert,
    required this.onManageWatchlist,
  });

  final MarketProvider market;

  final WatchlistProvider watchlist;

  final VoidCallback onManageWatchlist;

  final void Function(String? instrument) onOpenInstrument;

  final Future<void> Function(String instrument, LiveMarketQuote quote)
  onCreateAlert;

  @override
  Widget build(BuildContext context) {
    final muted = Theme.of(context).colorScheme.onSurfaceVariant;

    final instruments =
        watchlist.items
            .map((item) => item.instrument.trim().toUpperCase())
            .toSet()
            .toList()
          ..sort();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.star_rounded, size: 19),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    context.l10n.marketWatchlist,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                IconButton(
                  tooltip: context.l10n.manageWatchlist,
                  onPressed: onManageWatchlist,
                  icon: const Icon(Icons.add_rounded, size: 20),
                ),

                if (watchlist.isLoading || market.isLoadingQuotes)
                  const SizedBox(
                    width: 15,
                    height: 15,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
              ],
            ),

            const SizedBox(height: 5),

            Text(
              context.l10n.watchlistDescription,
              style: TextStyle(color: muted, fontSize: 12),
            ),

            const SizedBox(height: 14),

            if (instruments.isEmpty)
              _EmptyWatchlist(onAdd: onManageWatchlist)
            else
              SizedBox(
                height:
                    instruments.length.clamp(1, 3) *
                    68 *
                    MediaQuery.textScalerOf(context).scale(1).clamp(1.0, 1.6),
                child: Scrollbar(
                  child: ListView.separated(
                    key: const Key('dashboard-watchlist-list'),
                    primary: false,
                    itemCount: instruments.length,
                    separatorBuilder: (_, _) => const Divider(height: 18),
                    itemBuilder: (_, index) {
                      final instrument = instruments[index];
                      return _WatchlistRow(
                        instrument: instrument,
                        quote: market.quoteFor(instrument),
                        onOpen: () => onOpenInstrument(instrument),
                        onAlert: (quote) => onCreateAlert(instrument, quote),
                      );
                    },
                  ),
                ),
              ),

            if (market.quotesUpdatedAt != null) ...[
              const SizedBox(height: 10),
              Text(
                context.l10n.pricesUpdatedAt(
                  DateFormat(
                    'HH:mm:ss',
                  ).format(market.quotesUpdatedAt!.toLocal()),
                ),
                style: TextStyle(color: muted, fontSize: 12),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _WatchlistRow extends StatelessWidget {
  const _WatchlistRow({
    required this.instrument,
    required this.quote,
    required this.onOpen,
    required this.onAlert,
  });

  final String instrument;

  final LiveMarketQuote? quote;

  final VoidCallback onOpen;

  final void Function(LiveMarketQuote quote) onAlert;

  @override
  Widget build(BuildContext context) {
    final muted = Theme.of(context).colorScheme.onSurfaceVariant;

    final isDark = Theme.of(context).brightness == Brightness.dark;

    final bullish = isDark ? AppColors.bullishDark : AppColors.bullishLight;

    final bearish = isDark ? AppColors.bearishDark : AppColors.bearishLight;

    final change = quote?.changePercent ?? 0;
    final changeColor = change > 0
        ? bullish
        : change < 0
        ? bearish
        : muted;

    return Row(
      children: [
        Expanded(
          child: InkWell(
            onTap: onOpen,
            borderRadius: BorderRadius.circular(10),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 3),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          instrument,
                          style: const TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w800,
                          ),
                        ),

                        const SizedBox(height: 3),

                        if (quote != null)
                          Text(
                            _formatPrice(instrument, quote!.price),
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w900,
                            ),
                          )
                        else
                          Text(
                            context.l10n.livePriceUnavailable,
                            style: TextStyle(color: muted, fontSize: 12),
                          ),
                      ],
                    ),
                  ),

                  if (quote != null)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 7,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: changeColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        '${quote!.changePercent > 0 ? '+' : ''}'
                        '${quote!.changePercent.toStringAsFixed(2)}%',
                        style: TextStyle(
                          color: changeColor,
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),

        const SizedBox(width: 6),

        IconButton(
          tooltip: quote == null
              ? context.l10n.livePriceUnavailable
              : context.l10n.createPriceAlert,
          onPressed: quote == null
              ? null
              : () {
                  onAlert(quote!);
                },
          icon: const Icon(Icons.notifications_active_outlined, size: 19),
        ),

        IconButton(
          tooltip: context.l10n.openAnalysis,
          onPressed: onOpen,
          icon: const Icon(Icons.chevron_right_rounded),
        ),
      ],
    );
  }
}

class _EmptyWatchlist extends StatelessWidget {
  const _EmptyWatchlist({required this.onAdd});

  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final muted = Theme.of(context).colorScheme.onSurfaceVariant;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Theme.of(
          context,
        ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.35),
      ),
      child: Column(
        children: [
          Icon(Icons.star_border_rounded, color: muted, size: 26),

          const SizedBox(height: 7),

          Text(
            context.l10n.watchlistEmpty,
            style: TextStyle(
              color: muted,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),

          const SizedBox(height: 8),

          TextButton(onPressed: onAdd, child: Text(context.l10n.addSymbol)),
        ],
      ),
    );
  }
}

// =============================================================================
// STATS
// =============================================================================

class _OutcomeSummaryCard extends StatelessWidget {
  const _OutcomeSummaryCard({required this.outcomes});

  final AnalysisOutcomesSummary outcomes;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              context.l10n.outcomeSummary,
              style: const TextStyle(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 12),
            LayoutBuilder(
              builder: (context, constraints) {
                final stack =
                    constraints.maxWidth < 330 ||
                    MediaQuery.textScalerOf(context).scale(1) > 1.3;
                final target = _RateTile(
                  label: context.l10n.targetHitRate,
                  rate: outcomes.tpHitRate,
                  count: outcomes.tp1Hit + outcomes.tp2Hit,
                  total: outcomes.scored,
                  color: isDark
                      ? AppColors.bullishDark
                      : AppColors.bullishLight,
                );
                final stop = _RateTile(
                  label: context.l10n.stopHitRate,
                  rate: outcomes.slHitRate,
                  count: outcomes.slHit,
                  total: outcomes.scored,
                  color: Theme.of(context).colorScheme.error,
                );
                if (stack) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [target, const SizedBox(height: 10), stop],
                  );
                }
                return Row(
                  children: [
                    Expanded(child: target),
                    const SizedBox(width: 10),
                    Expanded(child: stop),
                  ],
                );
              },
            ),
            const SizedBox(height: 10),
            Text(
              context.l10n.resolvedSample(outcomes.scored),
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}

class _RateTile extends StatelessWidget {
  const _RateTile({
    required this.label,
    required this.rate,
    required this.count,
    required this.total,
    required this.color,
  });

  final String label;
  final num? rate;
  final int count;
  final int total;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: color.withValues(alpha: .1),
      borderRadius: BorderRadius.circular(12),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(color: color, fontSize: 12)),
        Text(
          rate == null ? '—' : '${(rate! * 100).round()}%',
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.w900,
            fontSize: 20,
          ),
        ),
        Text('$count / $total', style: Theme.of(context).textTheme.bodySmall),
      ],
    ),
  );
}

class DashboardStats extends StatelessWidget {
  const DashboardStats({super.key, required this.summary});

  final AnalysesSummary? summary;

  @override
  Widget build(BuildContext context) {
    final total = summary?.totalAnalyses ?? 0;

    final beginner = summary?.beginnerCount ?? 0;

    final minConfidence = summary?.avgConfidenceMin?.toDouble();

    final maxConfidence = summary?.avgConfidenceMax?.toDouble();

    String confidence = '--';

    if (minConfidence != null && maxConfidence != null) {
      confidence =
          '${minConfidence.round()}–'
          '${maxConfidence.round()}%';
    } else if (maxConfidence != null) {
      confidence = '${maxConfidence.round()}%';
    }

    final cards = [
      _StatCard(
        key: const ValueKey('dashboard-stat-total'),
        label: context.l10n.totalAnalyses,
        value: '$total',
        icon: Icons.insert_chart_outlined_rounded,
      ),
      _StatCard(
        key: const ValueKey('dashboard-stat-beginner'),
        label: context.l10n.beginnerMode,
        value: '$beginner',
        icon: Icons.school_outlined,
      ),
      _StatCard(
        key: const ValueKey('dashboard-stat-confidence'),
        label: context.l10n.aiConfidence,
        value: confidence,
        icon: Icons.speed_rounded,
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final textScale = MediaQuery.textScalerOf(context).scale(14) / 14;
        final stackCards = textScale > 1.3;
        final cardWidth = stackCards
            ? constraints.maxWidth
            : (constraints.maxWidth - 16) / 3;

        return Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final card in cards) SizedBox(width: cardWidth, child: card),
          ],
        );
      },
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Glyph/teks memakai nada emas yang terbaca; isian tetap emas web.
    final primaryText = isDark
        ? AppColors.darkPrimaryText
        : AppColors.lightPrimaryText;

    final muted = isDark
        ? AppColors.darkMutedForeground
        : AppColors.lightMutedForeground;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: primaryText, size: 19),

            const SizedBox(height: 9),

            Text(
              value,
              maxLines: 1,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
            ),

            const SizedBox(height: 3),

            Text(
              label,
              maxLines: 2,
              style: TextStyle(fontSize: 12, color: muted),
            ),
          ],
        ),
      ),
    );
  }
}

// =============================================================================
// QUOTA
// =============================================================================

class _QuotaCard extends StatelessWidget {
  const _QuotaCard({required this.quota});

  final AnalysisQuota quota;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Bar kuota adalah isian, ikon di sebelahnya adalah glyph.
    final primary = isDark ? AppColors.darkPrimary : AppColors.lightPrimary;
    final primaryText = isDark
        ? AppColors.darkPrimaryText
        : AppColors.lightPrimaryText;

    final muted = isDark
        ? AppColors.darkMutedForeground
        : AppColors.lightMutedForeground;

    if (quota.unlimited) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Icon(Icons.all_inclusive_rounded, color: primaryText),
              const SizedBox(width: 10),
              Text(
                context.l10n.unlimitedAnalysisQuota,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
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
            Text(
              context.l10n.analysisQuota,
              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
            ),

            const SizedBox(height: 10),

            _QuotaBar(
              label: context.l10n.perHour,
              used: quota.hourly.used,
              limit: quota.hourly.limit,
              primary: primary,
              muted: muted,
            ),

            const SizedBox(height: 9),

            _QuotaBar(
              label: context.l10n.perDay,
              used: quota.daily.used,
              limit: quota.daily.limit,
              primary: primary,
              muted: muted,
            ),

            const SizedBox(height: 10),

            Row(
              children: [
                Icon(Icons.toll_rounded, size: 16, color: primaryText),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    context.l10n.creditBalance,
                    style: TextStyle(fontSize: 12, color: muted),
                  ),
                ),
                Text(
                  '${quota.credits.balance}',
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
              ],
            ),
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

    return Semantics(
      label: '$label, $used / $limit',
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label, style: TextStyle(fontSize: 12, color: muted)),
              Text(
                '$used / $limit',
                style: TextStyle(fontSize: 12, color: muted),
              ),
            ],
          ),

          const SizedBox(height: 5),

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
      ),
    );
  }
}

// =============================================================================
// EMPTY RECENT
// =============================================================================

class _EmptyRecent extends StatelessWidget {
  const _EmptyRecent({required this.muted, required this.onAnalyze});

  final Color muted;

  final VoidCallback onAnalyze;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: Column(
          children: [
            Icon(Icons.insights_outlined, size: 30, color: muted),

            const SizedBox(height: 8),

            Text(
              context.l10n.noAnalyses,
              style: TextStyle(color: muted, fontWeight: FontWeight.w600),
            ),

            const SizedBox(height: 8),

            TextButton(
              onPressed: onAnalyze,
              child: Text(context.l10n.createFirstAnalysis),
            ),
          ],
        ),
      ),
    );
  }
}

// =============================================================================
// FORMAT
// =============================================================================

String _formatPrice(String instrument, double value) {
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

class _WatchlistManagerSheet extends StatelessWidget {
  const _WatchlistManagerSheet();

  Future<void> _addInstrument(BuildContext context) async {
    final provider = context.read<WatchlistProvider>();
    final existing = provider.items
        .map((item) => item.instrument.trim().toUpperCase())
        .toSet();

    await InstrumentPickerSheet.show(
      context,
      existingInstruments: existing,
      onSelected: (instrument) async {
        final ok = await provider.addInstrument(instrument);
        if (!context.mounted) {
          return;
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              ok
                  ? context.l10n.instrumentAddedToWatchlist(instrument)
                  : provider.error ??
                        context.l10n.instrumentAlreadyInWatchlist(instrument),
            ),
          ),
        );
      },
    );
  }

  Future<void> _removeInstrument(
    BuildContext context,
    String instrument,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(context.l10n.removeFromWatchlist),
        content: Text(context.l10n.removeInstrumentConfirmation(instrument)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(context.l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(context.l10n.remove),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) {
      return;
    }

    final provider = context.read<WatchlistProvider>();
    final ok = await provider.removeInstrument(instrument);
    if (!context.mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          ok
              ? context.l10n.instrumentRemovedFromWatchlist(instrument)
              : provider.error ??
                    context.l10n.removeInstrumentFailed(instrument),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final watchlist = context.watch<WatchlistProvider>();

    final muted = Theme.of(context).colorScheme.onSurfaceVariant;

    return SafeArea(
      child: SizedBox(
        height: MediaQuery.sizeOf(context).height * 0.82,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 12, 12),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          context.l10n.manageWatchlist,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        SizedBox(height: 3),
                        Text(
                          context.l10n.selectMarketsForDashboard,
                          style: const TextStyle(fontSize: 11.5),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: context.l10n.addSymbol,
                    onPressed: watchlist.isUpdating
                        ? null
                        : () => _addInstrument(context),
                    icon: const Icon(Icons.add_rounded),
                  ),
                  IconButton(
                    tooltip: context.l10n.close,
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
            ),

            if (watchlist.isUpdating)
              const LinearProgressIndicator(minHeight: 2),

            Expanded(
              child: watchlist.isLoading && watchlist.items.isEmpty
                  ? const Center(child: CircularProgressIndicator())
                  : watchlist.error != null && watchlist.items.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(watchlist.error!, textAlign: TextAlign.center),
                          const SizedBox(height: 8),
                          TextButton(
                            onPressed: watchlist.loadWatchlist,
                            child: Text(context.l10n.tryAgain),
                          ),
                        ],
                      ),
                    )
                  : watchlist.items.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            context.l10n.watchlistEmpty,
                            style: TextStyle(color: muted),
                          ),
                          const SizedBox(height: 8),
                          FilledButton.icon(
                            onPressed: () => _addInstrument(context),
                            icon: const Icon(Icons.add_rounded),
                            label: Text(context.l10n.addSymbol),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                      itemCount: watchlist.items.length,
                      itemBuilder: (context, index) {
                        final item = watchlist.items[index];
                        return WatchlistItemCard(
                          item: item,
                          onRemove: (instrument) =>
                              _removeInstrument(context, instrument),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
