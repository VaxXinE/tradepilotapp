import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/analysis_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/market_provider.dart';
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
      const HistoryTab(),
      const ProfileTab(),
    ];

    WidgetsBinding.instance.addObserver(this);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }

      _syncCurrentTab(showLoading: true);

      _startAnalysisPolling();
    });
  }

  @override
  void dispose() {
    _stopAnalysisPolling();

    WidgetsBinding.instance.removeObserver(this);

    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.resumed:
        _syncCurrentTab();

        _startAnalysisPolling();

        break;

      case AppLifecycleState.inactive:
      case AppLifecycleState.paused:
      case AppLifecycleState.detached:
      case AppLifecycleState.hidden:
        _stopAnalysisPolling();

        if (mounted) {
          context.read<MarketProvider>().setQuotePollingEnabled(false);
        }

        break;
    }
  }

  // ===========================================================================
  // POLLING
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

    // Home sedang tertutup AnalysisDetail /
    // Notifications / route lain.
    //
    // Jangan terus melakukan polling di belakang layar.
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

    market.setQuotePollingEnabled(_index == 0 || _index == 1);

    switch (_index) {
      case 0:
        // Dashboard:
        // outcome/recent analysis saja yang perlu
        // background refresh 15 detik.
        unawaited(analysis.loadHistory(refresh: true, silent: true));

        break;

      case 2:
        // History
        unawaited(analysis.loadHistory(refresh: true, silent: true));

        break;

      // Analyze punya quote polling sendiri
      // melalui MarketProvider.
      case 1:
      case 3:
        break;
    }
  }

  // ===========================================================================
  // SYNC
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

    final needsLiveQuotes = index == 0 || index == 1;

    marketProvider.setQuotePollingEnabled(needsLiveQuotes);

    switch (index) {
      // Dashboard
      case 0:
        unawaited(analysisProvider.refreshCoreData(silent: !showLoading));

        unawaited(marketProvider.loadWatchlist());

        break;

      // Analyze
      case 1:
        unawaited(analysisProvider.loadQuota());

        unawaited(marketProvider.loadWatchlist());

        break;

      // History
      case 2:
        unawaited(
          analysisProvider.loadHistory(refresh: true, silent: !showLoading),
        );

        break;

      // Profile
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

  // ===========================================================================
  // TAB NAVIGATION
  // ===========================================================================

  void _onTabSelected(int index) {
    if (_index != index) {
      setState(() {
        _index = index;
      });
    }

    _syncTab(index);
  }

  // ===========================================================================
  // BUILD
  // ===========================================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _index, children: _tabs),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _index,
        onTap: _onTabSelected,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.space_dashboard_rounded),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.auto_awesome_rounded),
            label: 'Analisis',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.history_rounded),
            label: 'Riwayat',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_rounded),
            label: 'Profil',
          ),
        ],
      ),
    );
  }
}
