import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:trade_pilot_api_client/trade_pilot_api_client.dart';
import 'package:tradepilotapp/core/localization/locale_controller.dart';
import 'package:tradepilotapp/providers/auth_provider.dart';
import 'package:tradepilotapp/providers/progression_provider.dart';
import 'package:tradepilotapp/screens/mindset/mindset_screen.dart';

import '../../helpers/localized_test_app.dart';

void main() {
  const storageChannel = MethodChannel(
    'plugins.it_nomads.com/flutter_secure_storage',
  );
  setUp(() {
    // rootBundle caches the guide futures; a cached future from a previous
    // test's fake-async zone would leave this test's screen blank.
    rootBundle.evict('assets/guide_core.json');
    rootBundle.evict('assets/guide_more.json');
    SharedPreferences.setMockInitialValues({});
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(storageChannel, (_) async => null);
  });
  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(storageChannel, null);
  });

  Future<_EvidenceAdapter> open(
    WidgetTester tester, {
    bool failFirst = false,
  }) async {
    final preferences = await SharedPreferences.getInstance();
    final locale = LocaleController(preferences);
    addTearDown(locale.dispose);
    final auth = AuthProvider();
    await tester.runAsync(() => Future<void>.delayed(Duration.zero));
    final adapter = _EvidenceAdapter(failFirst: failFirst);
    auth.client.dio.httpClientAdapter = adapter;
    final progression = ProgressionProvider(auth);
    addTearDown(progression.dispose);

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<AuthProvider>.value(value: auth),
          ChangeNotifierProvider<LocaleController>.value(value: locale),
          ChangeNotifierProvider<ProgressionProvider>.value(value: progression),
        ],
        child: localizedTestApp(
          home: const MindsetScreen(
            embedded: true,
            initialGuideId: ProgressionEvidenceStartInputGuideIdEnum.howAiWorks,
          ),
        ),
      ),
    );
    await _settle(tester);
    return adapter;
  }

  testWidgets('the article says why completion is not available yet', (
    tester,
  ) async {
    final adapter = await open(tester);

    expect(adapter.starts, 1);
    expect(
      find.textContaining('Keep reading — this button unlocks in'),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey('guide-completion-retry')), findsNothing);
  });

  testWidgets('a failed start explains itself and can be retried', (
    tester,
  ) async {
    final adapter = await open(tester, failFirst: true);

    expect(find.textContaining('prepare reading progress'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('guide-completion-retry')));
    await _settle(tester);

    expect(adapter.starts, 2);
    expect(
      find.textContaining('Keep reading — this button unlocks in'),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey('guide-completion-retry')), findsNothing);
  });
}

/// The article ticks a 1s timer while it counts down, so it never "settles";
/// the guide asset and the HTTP adapter complete on real async time.
Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 20; i++) {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 20)),
    );
    await tester.pump(const Duration(milliseconds: 100));
  }
}

class _EvidenceAdapter implements HttpClientAdapter {
  _EvidenceAdapter({required this.failFirst});

  final bool failFirst;
  int starts = 0;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    if (options.path == '/progression/evidence') {
      starts++;
      if (failFirst && starts == 1) return ResponseBody.fromString('', 500);
      return ResponseBody.fromString(
        jsonEncode({
          'token': 't' * 40,
          'source': 'guide_completion',
          'subject': 'how-ai-works',
          'minimumCompleteAt': DateTime.now()
              .add(const Duration(seconds: 45))
              .toUtc()
              .toIso8601String(),
        }),
        200,
        headers: {
          Headers.contentTypeHeader: [Headers.jsonContentType],
        },
      );
    }
    return ResponseBody.fromString('', 404);
  }

  @override
  void close({bool force = false}) {}
}
