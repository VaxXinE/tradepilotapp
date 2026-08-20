import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/analysis_provider.dart';
import '../../providers/auth_provider.dart';
import 'tabs/analyze_tab.dart';
import 'tabs/dashboard_tab.dart';
import 'tabs/history_tab.dart';
import 'tabs/profile_tab.dart';

/// Shell utama aplikasi.
///
/// IndexedStack tetap dipakai agar state masing-masing tab tidak hilang.
///
/// Karena IndexedStack mempertahankan child, initState pada setiap tab hanya
/// dipanggil sekali. Karena itu sinkronisasi server dikelola dari HomeShell.
class HomeShell extends StatefulWidget {
  const HomeShell({
    super.key,
  });

  @override
  State<HomeShell> createState() =>
      _HomeShellState();
}

class _HomeShellState extends State<HomeShell>
    with WidgetsBindingObserver {
  static const Duration _pollInterval =
      Duration(seconds: 15);

  int _index = 0;

  Timer? _syncTimer;

  final _tabs = const [
    DashboardTab(),
    AnalyzeTab(),
    HistoryTab(),
    ProfileTab(),
  ];

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addObserver(this);

    WidgetsBinding.instance.addPostFrameCallback(
      (_) {
        if (!mounted) {
          return;
        }

        _startPolling();
      },
    );
  }

  @override
  void dispose() {
    _stopPolling();

    WidgetsBinding.instance.removeObserver(this);

    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // APP LIFECYCLE
  // ---------------------------------------------------------------------------

  @override
  void didChangeAppLifecycleState(
    AppLifecycleState state,
  ) {
    switch (state) {
      case AppLifecycleState.resumed:
        // Begitu user balik ke aplikasi, ambil data terbaru.
        _syncCurrentTab();

        _startPolling();
        break;

      case AppLifecycleState.inactive:
      case AppLifecycleState.paused:
      case AppLifecycleState.detached:
      case AppLifecycleState.hidden:
        // Jangan polling saat app berada di background.
        _stopPolling();
        break;
    }
  }

  // ---------------------------------------------------------------------------
  // POLLING
  // ---------------------------------------------------------------------------

  void _startPolling() {
    _syncTimer?.cancel();

    _syncTimer = Timer.periodic(
      _pollInterval,
      (_) {
        _syncCurrentTab();
      },
    );
  }

  void _stopPolling() {
    _syncTimer?.cancel();
    _syncTimer = null;
  }

  // ---------------------------------------------------------------------------
  // SYNC
  // ---------------------------------------------------------------------------

  void _syncCurrentTab({
    bool showLoading = false,
  }) {
    _syncTab(
      _index,
      showLoading: showLoading,
    );
  }

  void _syncTab(
    int index, {
    bool showLoading = false,
  }) {
    if (!mounted) {
      return;
    }

    final authProvider =
        context.read<AuthProvider>();

    if (authProvider.status !=
        AuthStatus.authenticated) {
      return;
    }

    final analysisProvider =
        context.read<AnalysisProvider>();

    switch (index) {
      // Dashboard membutuhkan:
      //
      // - history/recent analyses
      // - summary
      // - quota
      case 0:
        unawaited(
          analysisProvider.refreshCoreData(
            silent: !showLoading,
          ),
        );
        break;

      // Analyze cukup menjaga quota fresh.
      case 1:
        unawaited(
          analysisProvider.loadQuota(),
        );
        break;

      // History hanya membutuhkan list analyses.
      case 2:
        unawaited(
          analysisProvider.loadHistory(
            refresh: true,
            silent: !showLoading,
          ),
        );
        break;

      // Profile tidak membutuhkan polling analysis.
      case 3:
        break;
    }
  }

  // ---------------------------------------------------------------------------
  // TAB NAVIGATION
  // ---------------------------------------------------------------------------

  void _onTabSelected(
    int index,
  ) {
    if (_index != index) {
      setState(
        () {
          _index = index;
        },
      );
    }

    // Selalu revalidate tab yang dipilih.
    //
    // Bahkan kalau user menekan tab aktif lagi,
    // state akan disinkronkan.
    _syncTab(index);
  }

  // ---------------------------------------------------------------------------
  // BUILD
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _index,
        children: _tabs,
      ),
      bottomNavigationBar:
          BottomNavigationBar(
        currentIndex: _index,
        onTap: _onTabSelected,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(
              Icons.space_dashboard_rounded,
            ),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(
              Icons.auto_awesome_rounded,
            ),
            label: 'Analisis',
          ),
          BottomNavigationBarItem(
            icon: Icon(
              Icons.history_rounded,
            ),
            label: 'Riwayat',
          ),
          BottomNavigationBarItem(
            icon: Icon(
              Icons.person_rounded,
            ),
            label: 'Profil',
          ),
        ],
      ),
    );
  }
}