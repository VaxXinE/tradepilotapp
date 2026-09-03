import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/analysis_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/market_provider.dart';
import '../../providers/notifications_provider.dart';
import '../../providers/watchlist_provider.dart';
import '../../l10n/l10n.dart';
import 'tabs/analyze_tab.dart';
import 'tabs/dashboard_tab.dart';
import 'tabs/history_tab.dart';
import 'tabs/profile_tab.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> with WidgetsBindingObserver {
  static const Duration _analysisPollInterval = Duration(seconds: 15);

  int _index = 0;

  Timer? _analysisSyncTimer;

  late final List<Widget> _tabs;

  // ===========================================================================
  // LIFECYCLE
  // ===========================================================================

  @override
  void initState() {
    super.initState();

    _tabs = [
      DashboardTab(
        onOpenAnalyze: _openAnalyzeFromDashboard,
        onOpenHistory: _openHistoryFromDashboard,
      ),
      const AnalyzeTab(),
      HistoryTab(onReanalyze: _openAnalyzeFromHistory),
      const ProfileTab(),
    ];

    WidgetsBinding.instance.addObserver(this);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }

      // -------------------------------------------------------------------
      // P2-B:
      // Aktifkan realtime notification ketika HomeShell aktif.
      // -------------------------------------------------------------------

      context.read<NotificationsProvider>().setRealtimeEnabled(true);

      // Initial sync tab.
      _syncCurrentTab(showLoading: true);

      // Background analysis polling.
      _startAnalysisPolling();
    });
  }

  @override
  void dispose() {
    _stopAnalysisPolling();

    WidgetsBinding.instance.removeObserver(this);

    super.dispose();
  }

  // ===========================================================================
  // APP LIFECYCLE
  // ===========================================================================

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      // ---------------------------------------------------------------------
      // APP KEMBALI FOREGROUND
      // ---------------------------------------------------------------------

      case AppLifecycleState.resumed:
        if (!mounted) {
          return;
        }

        // Aktifkan kembali notification SSE.
        context.read<NotificationsProvider>().setRealtimeEnabled(true);

        // Refresh tab yang sedang aktif.
        _syncCurrentTab();

        // Restart analysis polling.
        _startAnalysisPolling();

        break;

      // ---------------------------------------------------------------------
      // APP MENINGGALKAN FOREGROUND
      // ---------------------------------------------------------------------

      case AppLifecycleState.inactive:
      case AppLifecycleState.paused:
      case AppLifecycleState.detached:
      case AppLifecycleState.hidden:
        _stopAnalysisPolling();

        if (!mounted) {
          return;
        }

        // Stop live quote polling.
        context.read<MarketProvider>().setQuotePollingEnabled(false);

        // -------------------------------------------------------------------
        // P2-B:
        // Jangan mempertahankan SSE ketika app background.
        //
        // Native push nantinya yang bertugas memberi notification ketika
        // aplikasi berada di background / terminated.
        // -------------------------------------------------------------------

        context.read<NotificationsProvider>().setRealtimeEnabled(false);

        break;
    }
  }

  // ===========================================================================
  // ANALYSIS POLLING
  // ===========================================================================

  void _startAnalysisPolling() {
    _analysisSyncTimer?.cancel();

    _analysisSyncTimer = Timer.periodic(_analysisPollInterval, (_) {
      _backgroundSyncTick();
    });
  }

  void _stopAnalysisPolling() {
    _analysisSyncTimer?.cancel();

    _analysisSyncTimer = null;
  }

  void _backgroundSyncTick() {
    if (!mounted) {
      return;
    }

    final route = ModalRoute.of(context);

    // -----------------------------------------------------------------------
    // Kalau HomeShell sedang tertutup route lain:
    //
    // Dashboard
    //    ↓
    // AnalysisDetail
    //
    // jangan terus melakukan polling HomeShell di belakang layar.
    // -----------------------------------------------------------------------

    if (route != null && !route.isCurrent) {
      context.read<MarketProvider>().setQuotePollingEnabled(false);

      return;
    }

    final auth = context.read<AuthProvider>();

    if (auth.status != AuthStatus.authenticated) {
      return;
    }

    final analysis = context.read<AnalysisProvider>();

    final market = context.read<MarketProvider>();

    // -----------------------------------------------------------------------
    // Live quote hanya diperlukan Dashboard + Analyze.
    // -----------------------------------------------------------------------

    market.setQuotePollingEnabled(_index == 0 || _index == 1);

    switch (_index) {
      // ---------------------------------------------------------------------
      // DASHBOARD
      // ---------------------------------------------------------------------

      case 0:
        // Hanya refresh history/outcome.
        //
        // Jangan refresh:
        // - summary
        // - quota
        // - watchlist
        //
        // setiap 15 detik.
        unawaited(analysis.loadHistory(refresh: true, silent: true));

        break;

      // ---------------------------------------------------------------------
      // ANALYZE
      // ---------------------------------------------------------------------

      case 1:
        // Analyze market polling ditangani MarketProvider.
        break;

      // ---------------------------------------------------------------------
      // HISTORY
      // ---------------------------------------------------------------------

      case 2:
        // P2-A:
        //
        // Kalau History sedang memakai:
        //
        // search
        // instrument filter
        // timeframe
        // mode
        // date range
        //
        // refresh query yang sedang terlihat,
        // bukan base history.
        unawaited(analysis.refreshVisibleHistory(silent: true));

        break;

      // ---------------------------------------------------------------------
      // PROFILE
      // ---------------------------------------------------------------------

      case 3:
        break;
    }
  }

  // ===========================================================================
  // CURRENT TAB SYNC
  // ===========================================================================

  void _syncCurrentTab({bool showLoading = false}) {
    _syncTab(_index, showLoading: showLoading);
  }

  void _syncTab(int index, {bool showLoading = false}) {
    if (!mounted) {
      return;
    }

    final authProvider = context.read<AuthProvider>();

    if (authProvider.status != AuthStatus.authenticated) {
      context.read<MarketProvider>().setQuotePollingEnabled(false);

      return;
    }

    final analysisProvider = context.read<AnalysisProvider>();

    final marketProvider = context.read<MarketProvider>();
    final watchlistProvider = context.read<WatchlistProvider>();

    // -----------------------------------------------------------------------
    // Quote polling
    // -----------------------------------------------------------------------

    final needsLiveQuotes = index == 0 || index == 1;

    marketProvider.setQuotePollingEnabled(needsLiveQuotes);

    switch (index) {
      // ---------------------------------------------------------------------
      // DASHBOARD
      // ---------------------------------------------------------------------

      case 0:
        unawaited(analysisProvider.refreshCoreData(silent: !showLoading));

        unawaited(watchlistProvider.loadWatchlist());

        break;

      // ---------------------------------------------------------------------
      // ANALYZE
      // ---------------------------------------------------------------------

      case 1:
        unawaited(analysisProvider.loadQuota());

        unawaited(watchlistProvider.loadWatchlist());

        break;

      // ---------------------------------------------------------------------
      // HISTORY
      // ---------------------------------------------------------------------

      case 2:
        // P2-A:
        // menghormati search/filter aktif.
        unawaited(analysisProvider.refreshVisibleHistory(silent: !showLoading));

        break;

      // ---------------------------------------------------------------------
      // PROFILE
      // ---------------------------------------------------------------------

      case 3:
        break;
    }
  }

  // ===========================================================================
  // DASHBOARD NAVIGATION
  // ===========================================================================

  void _openAnalyzeFromDashboard(String? instrument) {
    if (!mounted) {
      return;
    }

    if (instrument != null) {
      final market = context.read<MarketProvider>();

      unawaited(market.selectInstrument(instrument));
    }

    _onTabSelected(1);
  }

  void _openHistoryFromDashboard() {
    _onTabSelected(2);
  }

  void _openAnalyzeFromHistory(String instrument, String timeframe) {
    unawaited(
      context.read<MarketProvider>().selectInstrument(
        instrument,
        timeframe: timeframe,
      ),
    );
    _onTabSelected(1);
  }

  // ===========================================================================
  // TAB NAVIGATION
  // ===========================================================================

  void _onTabSelected(int index) {
    if (_index != index) {
      setState(() {
        _index = index;
      });
    }

    // -----------------------------------------------------------------------
    // Langsung sync ketika tab dipilih.
    //
    // IndexedStack mempertahankan state semua tab,
    // sehingga kita tidak recreate Dashboard/History setiap pindah tab.
    // -----------------------------------------------------------------------

    _syncTab(index);
  }

  // ===========================================================================
  // BUILD
  // ===========================================================================

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      body: IndexedStack(index: _index, children: _tabs),
      bottomNavigationBar: DecoratedBox(
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(
              color: Theme.of(context).colorScheme.outlineVariant,
            ),
          ),
        ),
        child: NavigationBar(
          selectedIndex: _index,
          onDestinationSelected: _onTabSelected,
          destinations: [
            NavigationDestination(
              icon: Icon(Icons.space_dashboard_outlined),
              selectedIcon: Icon(Icons.space_dashboard_rounded),
              label: l10n.dashboard,
            ),
            NavigationDestination(
              icon: Icon(Icons.auto_awesome_outlined),
              selectedIcon: Icon(Icons.auto_awesome_rounded),
              label: l10n.analysis,
            ),
            NavigationDestination(
              icon: Icon(Icons.history_outlined),
              selectedIcon: Icon(Icons.history_rounded),
              label: l10n.history,
            ),
            NavigationDestination(
              icon: Icon(Icons.person_outline_rounded),
              selectedIcon: Icon(Icons.person_rounded),
              label: l10n.profile,
            ),
          ],
        ),
      ),
    );
  }
}
