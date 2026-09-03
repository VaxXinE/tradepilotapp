import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:trade_pilot_api_client/trade_pilot_api_client.dart';
import 'package:tradepilotapp/providers/analysis_provider.dart';
import 'package:tradepilotapp/providers/auth_provider.dart';
import 'package:tradepilotapp/screens/analytics/analytics_screen.dart';
import 'package:tradepilotapp/screens/daily_summary/daily_summary_screen.dart';
import 'package:tradepilotapp/screens/journal/trade_journal_screen.dart';
import 'package:tradepilotapp/screens/trader_mirror/trader_mirror_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const storageChannel = MethodChannel(
    'plugins.it_nomads.com/flutter_secure_storage',
  );

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(storageChannel, (_) async => null);
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(storageChannel, null);
  });

  testWidgets('analytics renders server truth and local scope disclosure', (
    tester,
  ) async {
    final auth = await _auth(tester);
    auth.client.dio.httpClientAdapter = _P3Adapter();
    final analysis = AnalysisProvider(auth)
      ..history = [_analysis()]
      ..historyTotal = 3;
    addTearDown(analysis.dispose);

    await _pump(tester, auth, const AnalyticsScreen(), analysis: analysis);
    expect(find.text('12'), findsOneWidget);
    expect(find.textContaining('Hanya menghitung 1 dari 3'), findsOneWidget);
  });

  testWidgets('daily summary and mirror expose safe empty/gated states', (
    tester,
  ) async {
    final auth = await _auth(tester);
    auth.client.dio.httpClientAdapter = _P3Adapter();
    final analysis = AnalysisProvider(auth);
    addTearDown(analysis.dispose);

    await _pump(tester, auth, const DailySummaryScreen());
    expect(find.text('Belum ada ringkasan untuk hari ini.'), findsOneWidget);
    expect(find.textContaining('Asia/Jakarta'), findsOneWidget);

    await _pump(tester, auth, const TraderMirrorScreen(), analysis: analysis);
    expect(
      find.text('Belum cukup data untuk membuat sorotan.'),
      findsOneWidget,
    );
    expect(find.textContaining('Perlu 5 data'), findsWidgets);
  });

  testWidgets('journal loads empty state and creates a server-backed entry', (
    tester,
  ) async {
    final auth = await _auth(tester);
    final adapter = _P3Adapter();
    auth.client.dio.httpClientAdapter = adapter;

    await _pump(tester, auth, const TradeJournalScreen());
    expect(find.text('Belum ada entri jurnal.'), findsOneWidget);

    await tester.tap(find.text('Tambah'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('journal-instrument-field')),
      'XAU/USD',
    );
    await tester.tap(find.widgetWithText(FilledButton, 'Simpan'));
    await tester.pump();
    await tester.runAsync(() => Future<void>.delayed(Duration.zero));
    await tester.pumpAndSettle();

    expect(adapter.journalCreates, 1);
    expect(find.text('Entri jurnal gagal disimpan.'), findsNothing);
    expect(find.textContaining('XAU/USD · BUY'), findsOneWidget);
  });
}

Future<void> _pump(
  WidgetTester tester,
  AuthProvider auth,
  Widget home, {
  AnalysisProvider? analysis,
}) async {
  await tester.pumpWidget(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: auth),
        if (analysis != null) ChangeNotifierProvider.value(value: analysis),
      ],
      child: MaterialApp(home: home),
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 10));
}

Future<AuthProvider> _auth(WidgetTester tester) async {
  final auth = AuthProvider();
  await tester.runAsync(() => Future<void>.delayed(Duration.zero));
  return auth
    ..status = AuthStatus.authenticated
    ..user = User(
      (builder) => builder
        ..id = 1
        ..email = 'user@example.com'
        ..displayName = 'User'
        ..role = UserRoleEnum.user
        ..selectedMode = UserSelectedModeEnum.beginner
        ..themePreference = UserThemePreferenceEnum.dark
        ..onboardingCompleted = true,
    );
}

Analysis _analysis() => Analysis(
  (builder) => builder
    ..id = 1
    ..userId = 1
    ..instrument = 'XAU/USD'
    ..timeframe = '1h'
    ..mode = AnalysisModeEnum.beginner
    ..validUntil = DateTime.utc(2026, 8, 24)
    ..createdAt = DateTime.utc(2026, 8, 23),
);

class _P3Adapter implements HttpClientAdapter {
  int journalCreates = 0;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    final Object body;
    if (options.path.endsWith('/analyses/personal-analytics')) {
      body = {
        'totalAllTime': 12,
        'totalThisMonth': 4,
        'totalThisWeek': 2,
        'topInstruments': [
          {'instrument': 'XAU/USD', 'count': 8},
        ],
        'dominantMode': 'beginner',
        'accuracyRate': null,
        'feedbackCount': 1,
        'weeklyData': [],
      };
    } else if (options.path.endsWith('/me/daily-summary')) {
      body = {
        'settings': {
          'enabled': true,
          'time': '08:00',
          'timezone': 'Asia/Jakarta',
          'pushDailySummary': true,
          'lastSentDate': null,
        },
        'today': null,
      };
    } else if (options.path.endsWith('/mirror/insights')) {
      final gated = {
        'gated': true,
        'reason': 'need_more_data',
        'need': 5,
        'have': 0,
      };
      body = {
        'insights': {
          'windowDays': 30,
          'totalResolved': 0,
          'overallGated': true,
          'sessions': gated,
          'instruments': gated,
          'timing': gated,
          'postLoss': gated,
          'exitDiscipline': gated,
        },
        'highlights': [],
        'timezone': 'Asia/Jakarta',
      };
    } else if (options.path.endsWith('/journal') && options.method == 'POST') {
      journalCreates++;
      body = standardSerializers.serializeWith(
        JournalEntry.serializer,
        JournalEntry(
          (builder) => builder
            ..id = 9
            ..instrument = 'XAU/USD'
            ..side = JournalEntrySideEnum.buy
            ..outcome = JournalEntryOutcomeEnum.open
            ..tradedAt = DateTime.utc(2026, 8, 23, 8)
            ..createdAt = DateTime.utc(2026, 8, 23, 8)
            ..updatedAt = DateTime.utc(2026, 8, 23, 8),
        ),
      )!;
    } else if (options.path.endsWith('/journal')) {
      body = {'entries': []};
    } else {
      body = {'message': 'ok'};
    }
    return ResponseBody.fromString(
      jsonEncode(body),
      200,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}
