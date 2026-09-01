import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:trade_pilot_api_client/trade_pilot_api_client.dart';

import '../../../core/theme/app_colors.dart';
import '../../../l10n/l10n.dart';
import '../../../models/market_models.dart';
import '../../../providers/analysis_provider.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/market_provider.dart';
import '../../../providers/notifications_provider.dart';
import '../../../providers/watchlist_provider.dart';
import '../../../widgets/analysis_card.dart';
import '../../../widgets/market/market_overview_card.dart';
import '../../../widgets/market/market_session_card.dart';
import '../../../widgets/price_alert/price_alert_sheet.dart';
import '../../price_alert/price_alert_list_screen.dart';
import '../../../widgets/watchlist/instrument_picker_sheet.dart';
import '../../../widgets/watchlist/watchlist_item_card.dart';
import '../../analysis/analysis_detail_screen.dart';
import '../../notifications/notifications_screen.dart';

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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.priceAlertCreated(instrument))),
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

    final auth = context.watch<AuthProvider>();

    final analysisProvider = context.watch<AnalysisProvider>();

    final market = context.watch<MarketProvider>();

    final watchlist = context.watch<WatchlistProvider>();

    final notifications = context.watch<NotificationsProvider>();
    final l10n = context.l10n;

    final user = auth.user;

    final summary = analysisProvider.summary;

    final recentAnalyses = analysisProvider.history.take(5).toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.dashboard),
        actions: [
          IconButton(
            tooltip: l10n.myPriceAlerts,
            icon: const Icon(Icons.price_check_outlined),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const PriceAlertListScreen()),
              );
            },
          ),
          IconButton(
            tooltip: l10n.notifications,
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const NotificationsScreen()),
              );
            },
            icon: _NotificationIcon(unreadCount: notifications.unreadCount),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          children: [
            // ---------------------------------------------------------------
            // GREETING
            // ---------------------------------------------------------------
            Text(
              l10n.welcomeBack,
              style: TextStyle(color: muted, fontSize: 12.5),
            ),

            const SizedBox(height: 3),

            Row(
              children: [
                Expanded(
                  child: Text(
                    user?.displayName.trim().isNotEmpty == true
                        ? user!.displayName.trim()
                        : l10n.trader,
                    style: const TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.6,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.secondary,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    user?.selectedMode == UserSelectedModeEnum.pro
                        ? 'PRO'
                        : l10n.beginner.toUpperCase(),
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSecondary,
                      fontSize: 9.5,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.7,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 18),

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

            MarketSessionCard(instrument: market.selectedInstrument),

            const SizedBox(height: 16),

            // ---------------------------------------------------------------
            // BEGINNER HERO
            // ---------------------------------------------------------------
            _BeginnerHeroCard(
              onAnalyze: () {
                widget.onOpenAnalyze(null);
              },
            ),

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

            const SizedBox(height: 20),

            if ((analysisProvider.isLoadingSummary ||
                    analysisProvider.isLoadingHistory) &&
                summary == null &&
                analysisProvider.history.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 28),
                child: Center(child: CircularProgressIndicator()),
              )
            else ...[
              // -------------------------------------------------------------
              // BEGINNER STATS
              // -------------------------------------------------------------
              _StatsRow(summary: summary),

              const SizedBox(height: 14),

              // -------------------------------------------------------------
              // QUOTA
              // -------------------------------------------------------------
              if (analysisProvider.quota != null)
                _QuotaCard(quota: analysisProvider.quota!),

              const SizedBox(height: 22),

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
// NOTIFICATION ICON
// =============================================================================

class _NotificationIcon extends StatelessWidget {
  const _NotificationIcon({required this.unreadCount});

  final int unreadCount;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        const Icon(Icons.notifications_outlined),

        if (unreadCount > 0)
          Positioned(
            right: -7,
            top: -7,
            child: Container(
              constraints: const BoxConstraints(minWidth: 17, minHeight: 17),
              padding: const EdgeInsets.symmetric(horizontal: 4),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.error,
                borderRadius: BorderRadius.circular(999),
              ),
              alignment: Alignment.center,
              child: Text(
                unreadCount > 99 ? '99+' : '$unreadCount',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 8.5,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
      ],
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
                Icon(Icons.auto_awesome_rounded, size: 20),
                SizedBox(width: 8),
                Text(
                  context.l10n.wantMarketAnalysis,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
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
              style: TextStyle(color: muted, fontSize: 11),
            ),

            const SizedBox(height: 14),

            if (instruments.isEmpty)
              _EmptyWatchlist(onAdd: onManageWatchlist)
            else ...[
              for (var i = 0; i < instruments.length; i++) ...[
                _WatchlistRow(
                  instrument: instruments[i],
                  quote: market.quoteFor(instruments[i]),
                  onOpen: () {
                    onOpenInstrument(instruments[i]);
                  },
                  onAlert: (quote) {
                    onCreateAlert(instruments[i], quote);
                  },
                ),
                if (i != instruments.length - 1) const Divider(height: 18),
              ],
            ],

            if (market.quotesUpdatedAt != null) ...[
              const SizedBox(height: 10),
              Text(
                context.l10n.pricesUpdatedAt(
                  DateFormat(
                    'HH:mm:ss',
                  ).format(market.quotesUpdatedAt!.toLocal()),
                ),
                style: TextStyle(color: muted, fontSize: 9.5),
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

    final changeColor = (quote?.changePercent ?? 0) >= 0 ? bullish : bearish;

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
                            style: TextStyle(color: muted, fontSize: 10.5),
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
                        '${quote!.changePercent >= 0 ? '+' : ''}'
                        '${quote!.changePercent.toStringAsFixed(2)}%',
                        style: TextStyle(
                          color: changeColor,
                          fontSize: 10,
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

class _StatsRow extends StatelessWidget {
  const _StatsRow({required this.summary});

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

    return Row(
      children: [
        Expanded(
          child: _StatCard(
            label: context.l10n.totalAnalyses,
            value: '$total',
            icon: Icons.insert_chart_outlined_rounded,
          ),
        ),

        const SizedBox(width: 8),

        Expanded(
          child: _StatCard(
            label: context.l10n.beginnerMode,
            value: '$beginner',
            icon: Icons.school_outlined,
          ),
        ),

        const SizedBox(width: 8),

        Expanded(
          child: _StatCard(
            label: context.l10n.aiConfidence,
            value: confidence,
            icon: Icons.speed_rounded,
          ),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
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

    final primary = isDark ? AppColors.darkPrimary : AppColors.lightPrimary;

    final muted = isDark
        ? AppColors.darkMutedForeground
        : AppColors.lightMutedForeground;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: primary, size: 19),

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
              style: TextStyle(fontSize: 10, color: muted),
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

    final primary = isDark ? AppColors.darkPrimary : AppColors.lightPrimary;

    final muted = isDark
        ? AppColors.darkMutedForeground
        : AppColors.lightMutedForeground;

    if (quota.unlimited) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Icon(Icons.all_inclusive_rounded, color: primary),
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
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: TextStyle(fontSize: 11.5, color: muted)),
            Text(
              '$used / $limit',
              style: TextStyle(fontSize: 11.5, color: muted),
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
