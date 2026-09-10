import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/analysis_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/market_provider.dart';
import '../../providers/notifications_provider.dart';
import '../../providers/progression_provider.dart';
import '../../providers/watchlist_provider.dart';
import '../../core/theme/theme_controller.dart';
import '../../l10n/l10n.dart';
import '../../widgets/app_shell_chrome.dart';
import '../../widgets/language_menu_button.dart';
import '../notifications/notifications_screen.dart';
import 'tabs/analyze_tab.dart';
import 'tabs/dashboard_tab.dart';
import 'tabs/history_tab.dart';
import 'tabs/profile_tab.dart';
import '../mindset/mindset_screen.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> with WidgetsBindingObserver {
  static const Duration _analysisPollInterval = Duration(seconds: 15);
  static const _tabPaths = ['/', '/analyze', '/history', '/guide', '/profile'];

  /// Indeks view yang punya tab pada navigasi bawah. Profil (4) tetap tanpa
  /// tab dan dibuka lewat avatar header, sama seperti web.
  static const _navIds = {0, 1, 2, 3};

  int _index = 0;
  int _analyzeTabRevision = 0;

  Timer? _analysisSyncTimer;

  // ===========================================================================
  // LIFECYCLE
  // ===========================================================================

  @override
  void initState() {
    super.initState();

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

      unawaited(context.read<AuthProvider>().telemetry.pageView(_tabPaths[0]));

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
      // GUIDE
      // ---------------------------------------------------------------------

      case 3:
        break;

      // ---------------------------------------------------------------------
      // PROFILE
      // ---------------------------------------------------------------------

      case 4:
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

        unawaited(context.read<ProgressionProvider>().refresh(silent: true));

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
      // GUIDE
      // ---------------------------------------------------------------------

      case 3:
        break;

      // ---------------------------------------------------------------------
      // PROFILE
      // ---------------------------------------------------------------------

      case 4:
        unawaited(context.read<ProgressionProvider>().refresh(silent: true));
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

    _openNewAnalysis();
  }

  void _openHistoryFromDashboard() {
    _onTabSelected(2);
  }

  void _openNotifications() {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const NotificationsScreen()));
  }

  Future<void> _toggleTheme() async {
    final theme = context.read<ThemeController>();
    final enabled = !theme.isDarkMode;
    await theme.setDarkMode(enabled);
    if (!mounted) return;
    await context.read<AuthProvider>().updateTheme(enabled);
  }

  void _openAnalyzeFromHistory(String instrument, String timeframe) {
    unawaited(
      context.read<MarketProvider>().selectInstrument(
        instrument,
        timeframe: timeframe,
      ),
    );
    _openNewAnalysis();
  }

  void _openNewAnalysis() {
    final trackPageView = _index != 1;
    setState(() {
      _analyzeTabRevision++;
      _index = 1;
    });
    if (trackPageView) {
      unawaited(context.read<AuthProvider>().telemetry.pageView(_tabPaths[1]));
    }
    _syncTab(1);
  }

  // ===========================================================================
  // TAB NAVIGATION
  // ===========================================================================

  void _onTabSelected(int index) {
    if (_index != index) {
      setState(() {
        _index = index;
      });
      unawaited(
        context.read<AuthProvider>().telemetry.pageView(_tabPaths[index]),
      );
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
    final auth = context.watch<AuthProvider>();
    final market = context.watch<MarketProvider>();
    final notifications = context.watch<NotificationsProvider>();
    final themeController = context.watch<ThemeController>();
    final user = auth.user;
    final tabs = [
      DashboardTab(
        onOpenAnalyze: _openAnalyzeFromDashboard,
        onOpenHistory: _openHistoryFromDashboard,
      ),
      AnalyzeTab(
        key: ValueKey(_analyzeTabRevision),
        onNewAnalysis: _openNewAnalysis,
      ),
      HistoryTab(
        onReanalyze: _openAnalyzeFromHistory,
        onNewAnalysis: _openNewAnalysis,
      ),
      const MindsetScreen(embedded: true),
      const ProfileTab(),
    ];

    return Scaffold(
      body: Column(
        children: [
          TradePilotAppHeader(
            displayName: user?.displayName ?? l10n.trader,
            avatarUrl: user?.avatarUrl,
            unreadCount: notifications.unreadCount,
            languageButton: const LanguageMenuButton(),
            isDarkMode: themeController.isDarkMode,
            onToggleTheme: _toggleTheme,
            onOpenNotifications: _openNotifications,
            onOpenProfile: () => _onTabSelected(4),
            onOpenHome: () => _onTabSelected(0),
            profileActive: _index == 4,
            onBack: _navIds.contains(_index) ? null : () => _onTabSelected(1),
            notificationsLabel: l10n.notifications,
            profileLabel: l10n.profile,
            themeLabel: l10n.darkTheme,
            logoLabel: l10n.tradePilotLogo,
            backLabel: l10n.back,
          ),
          LiveMarketTicker(quotes: market.quotes.values),
          Expanded(
            child: IndexedStack(index: _index, children: tabs),
          ),
        ],
      ),
      bottomNavigationBar: AppBottomNav(
        activeId: _index,
        onSelected: _onTabSelected,
        items: [
          AppNavItem(id: 0, icon: Icons.home_rounded, label: l10n.dashboard),
          AppNavItem(
            id: 1,
            icon: Icons.trending_up_rounded,
            label: l10n.analysis,
          ),
          AppNavItem(id: 2, icon: Icons.schedule_rounded, label: l10n.history),
          AppNavItem(
            id: 3,
            icon: Icons.menu_book_rounded,
            label: l10n.guideNavLabel,
          ),
        ],
      ),
    );
  }
}
