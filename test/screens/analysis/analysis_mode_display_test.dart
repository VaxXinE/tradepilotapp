import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:trade_pilot_api_client/trade_pilot_api_client.dart';
import 'package:tradepilotapp/core/localization/locale_controller.dart';
import 'package:tradepilotapp/core/theme/app_colors.dart';
import 'package:tradepilotapp/models/market_models.dart';
import 'package:tradepilotapp/providers/analysis_provider.dart';
import 'package:tradepilotapp/providers/auth_provider.dart';
import 'package:tradepilotapp/providers/market_provider.dart';
import 'package:tradepilotapp/providers/progression_provider.dart';
import 'package:tradepilotapp/repositories/market_repository.dart';
import 'package:tradepilotapp/screens/analysis/analysis_detail_screen.dart';

import '../../helpers/localized_test_app.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('analysis detail hides legacy mode labels', (tester) async {
    await _pumpDetail(tester, _analysis(AnalysisModeEnum.beginner));

    expect(find.text('Beginner Mode'), findsNothing);
    expect(find.text('Bearish bias'), findsOneWidget);

    // Technical detail follows the expanded reading order from the web.
    await _reveal(
      tester,
      find.byKey(const ValueKey('analysis-technical-indicators')),
      find.byType(Scrollable).first,
    );
    expect(find.byKey(const ValueKey('signal-scale-bar')), findsNWidgets(5));
    final segments = find.descendant(
      of: find.byKey(const ValueKey('signal-scale-bar')),
      matching: find.byType(ColoredBox),
    );
    expect(segments, findsNWidgets(25));
    for (final segment in segments.evaluate()) {
      expect(tester.getSize(find.byWidget(segment.widget)).height, 8);
    }
    expect(
      find.byKey(const ValueKey('indicator-signal-RSI (14)')),
      findsOneWidget,
    );
    await tester.ensureVisible(find.text('Oscillator · 1h'));
    await tester.pumpAndSettle();
    final buyDot = tester.widget<Container>(
      find.byKey(const ValueKey('indicator-signal-RSI (14)')),
    );
    final sellDot = tester.widget<Container>(
      find.byKey(const ValueKey('indicator-signal-MACD (12,26)')),
    );
    expect((buyDot.decoration! as BoxDecoration).color, AppColors.bullishLight);
    expect(
      (sellDot.decoration! as BoxDecoration).color,
      AppColors.bearishLight,
    );
    await tester.ensureVisible(find.text('Moving Averages'));
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('indicator-signal-EMA (9)')),
      findsOneWidget,
    );
    await _reveal(
      tester,
      find.text('What does it mean?'),
      find.byType(Scrollable).first,
    );

    await _pumpDetail(tester, _analysis(AnalysisModeEnum.pro));

    expect(find.text('Pro Mode'), findsNothing);
    expect(find.text('Bearish bias'), findsOneWidget);
    expect(find.text('What does it mean?'), findsNothing);
  });

  testWidgets('market condition uses a localized semantic chip', (
    tester,
  ) async {
    await _pumpDetail(
      tester,
      _analysis(AnalysisModeEnum.beginner, marketCondition: 'trending_up'),
    );

    expect(find.text('Uptrend'), findsOneWidget);
    expect(find.text('trending_up'), findsNothing);
    await tester.scrollUntilVisible(
      find.text('Medium Risk'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Medium Risk'), findsOneWidget);
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('analysis-result-header')),
        matching: find.byKey(const ValueKey('analysis-risk-chip')),
      ),
      findsOneWidget,
    );
    expect(find.text('medium'), findsNothing);
    expect(find.byTooltip('Reanalyze'), findsNothing);
  });

  testWidgets('header uses the resolved analysis outcome', (tester) async {
    await _pumpDetail(
      tester,
      _analysis(
        AnalysisModeEnum.beginner,
        outcomeStatus: AnalysisOutcomeStatusEnum.slHit,
      ),
    );

    expect(find.text('Stop Loss Hit'), findsWidgets);
    expect(find.text('Awaiting result'), findsNothing);
  });

  testWidgets('market context summary follows the indicator counts', (
    tester,
  ) async {
    await _pumpDetail(
      tester,
      _analysis(
        AnalysisModeEnum.beginner,
        techBuyCount: 3,
        techSellCount: 8,
        techNeutralCount: 0,
      ),
    );
    final card = find.byKey(const ValueKey('analysis-market-snapshot'));
    await _reveal(tester, card, find.byType(Scrollable).first);

    expect(find.text('MARKET CONTEXT SUMMARY'), findsOneWidget);
    expect(find.text('Leaning Bearish'), findsOneWidget);
    expect(find.text('(SELL)'), findsOneWidget);
    expect(
      find.textContaining('8 of 11 indicators are leaning bearish'),
      findsOneWidget,
    );
  });

  testWidgets('adaptive plan uses the web card heading', (tester) async {
    await _pumpDetail(
      tester,
      _analysis(AnalysisModeEnum.beginner, tradePlan: _tradePlan()),
    );
    await _reveal(
      tester,
      find.text('Adaptive Trading Plan'),
      find.byType(Scrollable).first,
    );

    expect(find.text('Adaptive Trading Plan'), findsOneWidget);
    expect(
      find.text('Simulate entries, lot sizes, and risk from this analysis.'),
      findsOneWidget,
    );
    expect(find.text('Position Size Recommendation'), findsNothing);
  });

  testWidgets('adaptive details opens as a scrollable modal', (tester) async {
    await _pumpDetail(
      tester,
      _analysis(
        AnalysisModeEnum.beginner,
        tradePlan: _tradePlan(),
        failureConditions: 'Close above invalidation.',
        opportunity: 'Price may continue lower.',
        risk: 'A technical rebound may invalidate the setup.',
      ),
    );
    await tester.pumpAndSettle();
    final details = find.byKey(const ValueKey('adaptive-plan-details'));
    await _reveal(tester, details, find.byType(Scrollable).first);
    await tester.tap(details);
    await tester.pumpAndSettle();

    expect(
      find.text(
        'See what the saved analysis found and how Adaptive responded. '
        'Live indicators do not update this plan automatically.',
      ),
      findsOneWidget,
    );
    expect(find.text('Why this analysis'), findsOneWidget);
    expect(find.text('Print / save PDF'), findsOneWidget);
  });

  testWidgets('adaptive details counts the saved invalidation rules', (
    tester,
  ) async {
    await _pumpDetail(
      tester,
      _analysis(
        AnalysisModeEnum.beginner,
        tradePlan: _tradePlan(),
        failureConditions: '• Break support 4100\n• Close above EMA9',
      ),
    );
    final details = find.byKey(const ValueKey('adaptive-plan-details'));
    await _reveal(tester, details, find.byType(Scrollable).first);

    expect(
      find.descendant(of: details, matching: find.text('2')),
      findsOneWidget,
    );
  });

  testWidgets(
    'adaptive details reads Pro invalidation from invalidationConditions',
    (tester) async {
      await _pumpDetail(
        tester,
        _analysis(
          AnalysisModeEnum.pro,
          tradePlan: _tradePlan(),
          invalidationConditions: '• Break support 4100\n• Close above EMA9',
        ),
      );
      final details = find.byKey(const ValueKey('adaptive-plan-details'));
      await _reveal(tester, details, find.byType(Scrollable).first);

      expect(
        find.descendant(of: details, matching: find.text('2')),
        findsOneWidget,
      );

      await tester.tap(details);
      await tester.pumpAndSettle();

      expect(find.text('This analysis becomes invalid if:'), findsOneWidget);
      expect(find.textContaining('Break support 4100'), findsOneWidget);
    },
  );

  testWidgets('analysis summary remains usable with large text', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 700);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await _pumpDetail(
      tester,
      _analysis(
        AnalysisModeEnum.pro,
        marketCondition: 'trending_up',
        tradePlan: _tradePlan(),
      ),
      onNewAnalysis: () {},
      textScaler: const TextScaler.linear(2),
    );

    expect(tester.takeException(), isNull);
    expect(find.text('XAU/USD'), findsWidgets);
    await _reveal(tester, find.text('Uptrend'), find.byType(Scrollable).first);
    expect(find.text('Uptrend'), findsOneWidget);
    await _reveal(
      tester,
      find.text('Suggested Levels'),
      find.byType(Scrollable).first,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('the price chart is available without expanding anything', (
    tester,
  ) async {
    await _pumpDetail(tester, _analysis(AnalysisModeEnum.beginner));

    await tester.scrollUntilVisible(
      find.text('Price Chart'),
      400,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();

    // No disclosure tap is needed to reach the chart.
    expect(find.text('Price Chart'), findsOneWidget);

    // It also must not be the collapsed evidence section that renders it.
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('analysis-market-evidence')),
        matching: find.text('Price Chart'),
      ),
      findsNothing,
    );
  });

  testWidgets('suggested levels can copy a side and open its guide', (
    tester,
  ) async {
    await _pumpDetail(
      tester,
      _analysis(AnalysisModeEnum.beginner, tradePlan: _tradePlan()),
    );
    final scrollable = find.byType(Scrollable).first;
    await _reveal(
      tester,
      find.byKey(const ValueKey('suggested-levels-card')),
      scrollable,
    );

    expect(find.text('Suggested side: Buy'), findsOneWidget);
    expect(find.text('Buy Scenario'), findsOneWidget);
    expect(find.text('Sell Scenario'), findsOneWidget);

    String? copiedText;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, (call) async {
          if (call.method == 'Clipboard.setData') {
            copiedText =
                (call.arguments as Map<Object?, Object?>)['text'] as String?;
          }
          return null;
        });
    addTearDown(
      () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(SystemChannels.platform, null),
    );
    await tester.tap(find.byKey(const ValueKey('copy-Buy Scenario-levels')));
    await tester.pump();
    expect(copiedText, contains('Entry zone: 4400'));
    expect(copiedText, contains('Stop Loss: 4380'));

    await tester.tap(find.byKey(const ValueKey('suggested-levels-learn')));
    for (var attempt = 0; attempt < 20; attempt++) {
      await tester.pump(const Duration(milliseconds: 100));
      if (find.text('Using the Standard Plan').evaluate().isNotEmpty) break;
    }
    expect(find.text('Using the Standard Plan'), findsOneWidget);
    expect(find.text('Meaning and purpose'), findsOneWidget);
  });

  testWidgets(
    'chart, levels, fundamental, and technical follow reading order',
    (tester) async {
      await _pumpDetail(
        tester,
        _analysis(
          AnalysisModeEnum.beginner,
          tradePlan: _tradePlan(),
          failureConditions: 'Invalidation details',
          mainScenario: 'Primary scenario details',
          fundamentalContext: _fundamentalContext(),
        ),
      );
      final scrollable = find.byType(Scrollable).first;

      await _reveal(tester, find.text('Price Chart'), scrollable);
      final chartOffset = tester
          .state<ScrollableState>(scrollable)
          .position
          .pixels;

      await _reveal(tester, find.text('Suggested Levels'), scrollable);
      final levelsOffset = tester
          .state<ScrollableState>(scrollable)
          .position
          .pixels;

      await _reveal(
        tester,
        find.byKey(const ValueKey('analysis-fundamental-context')),
        scrollable,
      );
      final fundamentalOffset = tester
          .state<ScrollableState>(scrollable)
          .position
          .pixels;

      await _reveal(
        tester,
        find.byKey(const ValueKey('analysis-market-snapshot')),
        scrollable,
      );
      final marketOffset = tester
          .state<ScrollableState>(scrollable)
          .position
          .pixels;

      await _reveal(tester, find.text('Adaptive Trading Plan'), scrollable);
      final adaptiveOffset = tester
          .state<ScrollableState>(scrollable)
          .position
          .pixels;

      await _reveal(
        tester,
        find.byKey(const ValueKey('analysis-technical-indicators')),
        scrollable,
      );
      final technicalOffset = tester
          .state<ScrollableState>(scrollable)
          .position
          .pixels;

      await _reveal(
        tester,
        find.byKey(const ValueKey('analysis-level-alert-card')),
        scrollable,
      );
      final alertsOffset = tester
          .state<ScrollableState>(scrollable)
          .position
          .pixels;

      await _reveal(tester, find.text('Notes & journal'), scrollable);
      final toolsOffset = tester
          .state<ScrollableState>(scrollable)
          .position
          .pixels;

      expect(levelsOffset, greaterThan(chartOffset));
      expect(fundamentalOffset, greaterThan(levelsOffset));
      expect(marketOffset, greaterThan(fundamentalOffset));
      expect(adaptiveOffset, greaterThan(marketOffset));
      expect(technicalOffset, greaterThan(adaptiveOffset));
      expect(alertsOffset, greaterThan(technicalOffset));
      expect(toolsOffset, greaterThan(alertsOffset));
    },
  );

  testWidgets('fundamental tabs reveal the selected snapshot data', (
    tester,
  ) async {
    await _pumpDetail(
      tester,
      _analysis(
        AnalysisModeEnum.beginner,
        fundamentalContext: _fundamentalContext(),
      ),
    );
    final scrollable = find.byType(Scrollable).first;
    final newsButton = find.byKey(const ValueKey('fundamental-news'));
    await _reveal(tester, newsButton, scrollable);

    expect(find.text('Test headline'), findsNothing);
    await tester.tap(newsButton);
    await tester.pumpAndSettle();
    expect(find.text('Test headline'), findsOneWidget);

    final calendarButton = find.byKey(const ValueKey('fundamental-calendar'));
    await tester.tap(calendarButton);
    await tester.pumpAndSettle();
    expect(find.text('Test headline'), findsNothing);
    expect(
      find.text('There are no relevant upcoming economic events.'),
      findsOneWidget,
    );

    final learnButton = find.byKey(const ValueKey('fundamental-learn'));
    await _reveal(tester, learnButton, scrollable);
    expect(learnButton, findsOneWidget);
  });

  // Invalidation, Opportunity/Risk, Scenarios, Pro details, dan Execution
  // insight tidak lagi dirender (lihat komentar di reading order pada
  // analysis_detail_screen.dart) karena tidak ada padanannya di web, jadi
  // test yang mengecek card-card ini juga dinonaktifkan.
  // testWidgets('invalidation, opportunity, and risk are collapsed by default', (
  //   tester,
  // ) async {
  //   final analysis = _analysis(
  //     AnalysisModeEnum.beginner,
  //     failureConditions: 'Invalidation details',
  //     opportunity: 'Opportunity details',
  //     risk: 'Risk details',
  //   );
  //   await _pumpDetail(tester, analysis);
  //
  //   for (final entry in const [
  //     (ValueKey('analysis-invalidation'), 'Invalidation details'),
  //     (ValueKey('analysis-opportunity'), 'Opportunity details'),
  //     (ValueKey('analysis-risk'), 'Risk details'),
  //   ]) {
  //     final card = find.byKey(entry.$1);
  //     await _reveal(tester, card, find.byType(Scrollable).first);
  //     expect(find.text(entry.$2), findsNothing);
  //     await tester.tap(card);
  //     await tester.pumpAndSettle();
  //     expect(find.text(entry.$2), findsOneWidget);
  //   }
  // });
  //
  // testWidgets('execution insight matches the three web scenarios', (
  //   tester,
  // ) async {
  //   await _pumpDetail(tester, _analysis(AnalysisModeEnum.beginner));
  //
  //   final insight = find.byKey(const ValueKey('analysis-execution-insight'));
  //   await _reveal(tester, insight, find.byType(Scrollable).first);
  //   expect(find.text('If Scenario A continues'), findsNothing);
  //
  //   await tester.tap(insight);
  //   await tester.pumpAndSettle();
  //
  //   expect(find.text('If Scenario A continues'), findsOneWidget);
  //   expect(find.textContaining('nearest resistance area'), findsOneWidget);
  //   expect(find.text('If Scenario B plays out'), findsOneWidget);
  //   expect(find.text('If waiting is the better choice'), findsOneWidget);
  // });
  //
  // testWidgets('analysis scenarios share one collapsed card', (tester) async {
  //   await _pumpDetail(
  //     tester,
  //     _analysis(
  //       AnalysisModeEnum.beginner,
  //       mainScenario: 'Primary scenario details',
  //       alternativeScenario: 'Alternative scenario details',
  //     ),
  //   );
  //
  //   final scenarios = find.byKey(const ValueKey('analysis-scenarios'));
  //   await _reveal(tester, scenarios, find.byType(Scrollable).first);
  //   expect(find.text('Primary scenario details'), findsNothing);
  //
  //   await tester.tap(scenarios);
  //   await tester.pumpAndSettle();
  //
  //   expect(find.text('Primary scenario details'), findsOneWidget);
  //   expect(find.text('Alternative scenario details'), findsOneWidget);
  //   expect(find.text('Scenario C — Wait / No Position'), findsOneWidget);
  // });
  //
  // testWidgets('pro analysis factors share one collapsed card', (tester) async {
  //   await _pumpDetail(
  //     tester,
  //     _analysis(
  //       AnalysisModeEnum.pro,
  //       technicalDrivers: 'Technical factor details',
  //       fundamentalDrivers: 'Fundamental factor details',
  //       marketContext: 'Market context details',
  //     ),
  //   );
  //
  //   expect(
  //     find.byKey(const ValueKey('analysis-evidence-summary')),
  //     findsNothing,
  //   );
  //
  //   final details = find.byKey(const ValueKey('analysis-pro-details'));
  //   final scrollable = find.byType(Scrollable).first;
  //   await _reveal(
  //     tester,
  //     find.byKey(const ValueKey('analysis-scenarios')),
  //     scrollable,
  //   );
  //   final scenariosOffset = tester
  //       .state<ScrollableState>(scrollable)
  //       .position
  //       .pixels;
  //   await _reveal(tester, details, scrollable);
  //   final detailsOffset = tester
  //       .state<ScrollableState>(scrollable)
  //       .position
  //       .pixels;
  //   expect(detailsOffset, greaterThan(scenariosOffset));
  //   expect(find.text('Technical factor details'), findsNothing);
  //
  //   await tester.tap(details);
  //   await tester.pumpAndSettle();
  //
  //   expect(find.text('Technical factor details'), findsOneWidget);
  //   expect(find.text('Fundamental factor details'), findsOneWidget);
  //   expect(find.text('Market context details'), findsOneWidget);
  // });

  testWidgets('confidence reason is visible in the directional bias card', (
    tester,
  ) async {
    await _pumpDetail(
      tester,
      _analysis(
        AnalysisModeEnum.beginner,
        whyReason: 'Confidence reason details',
      ),
    );

    final reason = find.byKey(const ValueKey('analysis-confidence-reason'));
    final header = find.byKey(const ValueKey('analysis-result-header'));
    expect(find.descendant(of: header, matching: reason), findsOneWidget);
    expect(find.text('Confidence reason details'), findsOneWidget);
    expect(find.text('Cited sources'), findsNothing);
  });

  testWidgets('full reasoning uses analysis evidence and supports copying', (
    tester,
  ) async {
    final analysis = _analysis(
      AnalysisModeEnum.beginner,
      whyReason: 'Confidence reason details',
      technicalDrivers: 'Moving averages remain bearish.',
      fundamentalDrivers: 'No major catalyst in the current window.',
      risk: 'A strong rebound can invalidate the bearish bias.',
      failureConditions: 'Break support 4100\nPrice closes above EMA9',
      fundamentalContext: _fundamentalContext(),
      fundamentalCitations: FundamentalCitations(
        (builder) => builder
          ..newsTitles.add('Test headline')
          ..calendarEvents.add('FOMC Minutes'),
      ),
    );
    await _pumpDetail(tester, analysis);

    final button = find.byKey(const ValueKey('analysis-full-reasoning-button'));
    await tester.drag(find.byType(Scrollable).first, const Offset(0, -600));
    await tester.pumpAndSettle();
    await tester.tap(button);
    await tester.pumpAndSettle();

    expect(find.text('Analysis basis: XAU/USD · 1h'), findsOneWidget);
    expect(
      find.textContaining(
        'Moving averages remain bearish.',
        findRichText: true,
      ),
      findsOneWidget,
    );
    expect(
      find.textContaining(
        'No major catalyst in the current window.',
        findRichText: true,
      ),
      findsOneWidget,
    );
    expect(
      find.textContaining(
        'A strong rebound can invalidate the bearish bias.',
        findRichText: true,
      ),
      findsOneWidget,
    );
    expect(find.text('Test headline'), findsOneWidget);
    expect(find.text('FOMC Minutes'), findsOneWidget);
    expect(find.text('Break support 4100'), findsOneWidget);

    String? copiedText;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, (call) async {
          if (call.method == 'Clipboard.setData') {
            copiedText =
                (call.arguments as Map<Object?, Object?>)['text'] as String?;
          }
          return null;
        });
    addTearDown(
      () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(SystemChannels.platform, null),
    );
    await tester.tap(find.byKey(const ValueKey('copy-full-reasoning-text')));
    await tester.pump();
    expect(copiedText, contains('Moving averages remain bearish.'));
    expect(find.byKey(const ValueKey('copy-reasoning-popup')), findsOneWidget);
    expect(find.text('Full reasoning copied'), findsOneWidget);

    Uint8List? copiedImage;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('id.tradepilot.app/clipboard'),
          (call) async {
            copiedImage = call.arguments as Uint8List;
            return null;
          },
        );
    addTearDown(
      () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
            const MethodChannel('id.tradepilot.app/clipboard'),
            null,
          ),
    );
    await tester.tap(find.byKey(const ValueKey('copy-full-reasoning-image')));
    await tester.pump();
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 100)),
    );
    await tester.pump();
    expect(copiedImage, isNotNull);
    expect(copiedImage, isNotEmpty);
    expect(find.text('Image copied'), findsOneWidget);
  });

  testWidgets('active alert levels are collapsed until requested', (
    tester,
  ) async {
    final alerts = AlertStatus(
      (builder) => builder
        ..enabled = true
        ..armedCount = 1
        ..levels.add(
          AlertLevelRow(
            (row) => row
              ..level = AlertLevelRowLevelEnum.entry
              ..side = AlertLevelRowSideEnum.buy
              ..price = '4410'
              ..direction = AlertLevelRowDirectionEnum.above,
          ),
        ),
    );
    await _pumpDetail(
      tester,
      _analysis(AnalysisModeEnum.pro, tradePlan: _tradePlan()),
      alertStatus: alerts,
    );

    final levels = find.byKey(const ValueKey('analysis-alert-levels'));
    await _reveal(tester, levels, find.byType(Scrollable).first);
    expect(find.text('@ 4410'), findsNothing);

    await tester.tap(levels);
    await tester.pumpAndSettle();

    expect(find.text('@ 4410'), findsOneWidget);
    expect(find.text('Monitored'), findsOneWidget);
  });

  testWidgets('analysis detail shows the journal linked by the server', (
    tester,
  ) async {
    await _pumpDetail(
      tester,
      _analysis(AnalysisModeEnum.beginner),
      journal: {
        'id': 7,
        'analysisId': 1,
        'instrument': 'XAU/USD',
        'side': 'sell',
        'outcome': 'win',
        'mood': 'calm',
        'note': 'Entry sesuai rencana',
        'tradedAt': '2026-09-08T08:00:00.000Z',
        'createdAt': '2026-09-08T08:00:00.000Z',
        'updatedAt': '2026-09-08T08:00:00.000Z',
      },
    );

    await tester.scrollUntilVisible(
      find.text('My trade journal'),
      500,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.textContaining('Entry sesuai rencana'), findsOneWidget);
  });

  testWidgets(
    'timeframe switch auto-triggers a new analysis after a short debounce, '
    'collapsing rapid taps to the last selection',
    (tester) async {
      Analysis? created;
      final provider = await _pumpDetail(
        tester,
        _analysis(AnalysisModeEnum.beginner),
        onAnalysisCreated: (value) => created = value,
      );

      // Menyamai web: tap timeframe lain langsung memicu, tanpa tombol
      // konfirmasi terpisah. Dua tap cepat berturutan (4h lalu 1D) hanya
      // boleh memicu satu request — untuk pilihan terakhir (1D) — bukan dua.
      await tester.tap(find.byKey(const Key('timeframe-option-4h')));
      await tester.pump();
      await tester.tap(find.byKey(const Key('timeframe-option-1D')));
      await tester.pump();
      expect(provider.requestedTimeframes, isEmpty);

      await tester.pump(const Duration(milliseconds: 700));
      await tester.pumpAndSettle();

      expect(provider.requestedTimeframes, [
        CreateAnalysisBodyTimeframeEnum.n1d,
      ]);
      expect(created?.timeframe, '1D');
    },
  );

  testWidgets('timeframe buttons keep a single width across selection', (
    tester,
  ) async {
    // Callback tanpa navigasi supaya pohon widget yang sama tetap dites
    // setelah debounce ganti timeframe menembak di akhir test ini.
    await _pumpDetail(
      tester,
      _analysis(AnalysisModeEnum.beginner),
      onAnalysisCreated: (_) {},
    );

    double widthOf(String timeframe) =>
        tester.getSize(find.byKey(Key('timeframe-option-$timeframe'))).width;

    const timeframes = ['1m', '5m', '15m', '30m', '1h', '4h', '1D', '1W'];
    final widths = {for (final tf in timeframes) widthOf(tf)};

    // Kisi berkolom tetap: label panjang atau pendek tidak mengubah lebar,
    // jadi kedua baris tetap rata.
    expect(widths, hasLength(1));

    // '1h' adalah timeframe analisis ini. Memilih yang lain tidak boleh
    // menggeser tata letak — itulah sebabnya centang dihilangkan.
    await tester.tap(find.byKey(const Key('timeframe-option-15m')));
    await tester.pump();

    for (final tf in timeframes) {
      expect(widthOf(tf), widths.single);
    }

    // Selesaikan debounce yang tertunda supaya tidak ada Timer bocor saat
    // test ini berakhir.
    await tester.pump(const Duration(milliseconds: 700));
    await tester.pumpAndSettle();
  });

  testWidgets('compare risk opens the map and analyzes the chosen timeframe', (
    tester,
  ) async {
    final provider = await _pumpDetail(
      tester,
      _analysis(AnalysisModeEnum.beginner),
      onAnalysisCreated: (_) {},
    );

    expect(find.text('Compare Risk'), findsOneWidget);
    await tester.tap(find.byKey(const Key('timeframe-risk-map-button')));
    await tester.pump();
    await tester.runAsync(() => Future<void>.delayed(Duration.zero));
    await tester.pumpAndSettle();

    expect(find.text('Timeframe Risk Map'), findsOneWidget);
    expect(find.text('Overall: Wait'), findsOneWidget);
    await tester.tap(find.text('Use & Analyze 4h'));
    await tester.pump(const Duration(milliseconds: 700));
    await tester.pumpAndSettle();

    expect(provider.requestedTimeframes, [CreateAnalysisBodyTimeframeEnum.n4h]);
  });

  testWidgets('new analysis button opens the analysis flow', (tester) async {
    var opened = false;
    await _pumpDetail(
      tester,
      _analysis(AnalysisModeEnum.beginner),
      onNewAnalysis: () => opened = true,
    );

    await tester.tap(find.byKey(const Key('detail-new-analysis-button')));

    expect(opened, isTrue);
  });
}

Future<void> _reveal(
  WidgetTester tester,
  Finder target,
  Finder scrollable,
) async {
  for (var attempt = 0; attempt < 20 && target.evaluate().isEmpty; attempt++) {
    await tester.drag(scrollable, const Offset(0, -400));
    await tester.pump();
  }
  expect(target, findsOneWidget);
  await tester.ensureVisible(target);
  await tester.pumpAndSettle();
}

Future<_FakeAnalysisProvider> _pumpDetail(
  WidgetTester tester,
  Analysis analysis, {
  Map<String, Object?>? journal,
  ValueChanged<Analysis>? onAnalysisCreated,
  VoidCallback? onNewAnalysis,
  AlertStatus? alertStatus,
  TextScaler? textScaler,
}) async {
  final auth = AuthProvider();
  await tester.runAsync(() => Future<void>.delayed(Duration.zero));
  auth.client.dio.httpClientAdapter = _JournalAdapter(journal);
  final analysisProvider = _FakeAnalysisProvider(
    auth,
    analysis,
    alertStatus: alertStatus,
  );
  final marketProvider = _FakeMarketProvider(auth);
  final preferences = await SharedPreferences.getInstance();
  final localeController = LocaleController(preferences);
  final progressionProvider = ProgressionProvider(auth);
  addTearDown(analysisProvider.dispose);
  addTearDown(marketProvider.dispose);
  addTearDown(localeController.dispose);
  addTearDown(progressionProvider.dispose);

  await tester.pumpWidget(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthProvider>.value(value: auth),
        ChangeNotifierProvider<AnalysisProvider>.value(value: analysisProvider),
        ChangeNotifierProvider<MarketProvider>.value(value: marketProvider),
        ChangeNotifierProvider<LocaleController>.value(value: localeController),
        ChangeNotifierProvider<ProgressionProvider>.value(
          value: progressionProvider,
        ),
      ],
      child: localizedTestApp(
        home: Builder(
          builder: (context) => MediaQuery(
            data: MediaQuery.of(context).copyWith(textScaler: textScaler),
            child: AnalysisDetailScreen(
              key: ValueKey(analysis.id),
              analysisId: analysis.id,
              preloaded: analysis,
              onAnalysisCreated: onAnalysisCreated,
              onNewAnalysis: onNewAnalysis,
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return analysisProvider;
}

class _JournalAdapter implements HttpClientAdapter {
  _JournalAdapter(this.journal);

  final Map<String, Object?>? journal;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    if (options.path == '/risk-map/timeframes') {
      return ResponseBody.fromString(
        jsonEncode({
          'instrument': 'XAU/USD',
          'generatedAt': '2026-09-28T12:00:00.000Z',
          'timeframes': [
            {
              'timeframe': '1h',
              'status': 'available',
              'riskScore': 37,
              'riskCategory': 'moderate',
              'reasonCodes': ['SIGNAL_CONFLICT'],
              'metrics': {
                'buySignals': 3,
                'sellSignals': 3,
                'neutralSignals': 2,
                'rsi14': 50.0,
                'change20Pct': 0.1,
                'bollingerWidthPct': 1.5,
              },
              'dataQuality': 'good',
              'confidence': 'medium',
              'recommendation': 'caution',
            },
            {
              'timeframe': '4h',
              'status': 'available',
              'riskScore': 18,
              'riskCategory': 'low',
              'reasonCodes': ['SIGNALS_RELATIVELY_ALIGNED'],
              'metrics': {
                'buySignals': 6,
                'sellSignals': 1,
                'neutralSignals': 1,
                'rsi14': 52.0,
                'change20Pct': 0.4,
                'bollingerWidthPct': 1.2,
              },
              'dataQuality': 'good',
              'confidence': 'high',
              'recommendation': 'eligible',
            },
          ],
          'overall': {
            'state': 'wait',
            'reasonCode': 'RISK_OR_CONFLICT_PRESENT',
          },
        }),
        200,
        headers: {
          Headers.contentTypeHeader: [Headers.jsonContentType],
        },
      );
    }
    if (options.path.startsWith('/journal/for-analysis/')) {
      if (journal == null) return ResponseBody.fromString('', 404);
      return ResponseBody.fromString(
        jsonEncode(journal),
        200,
        headers: {
          Headers.contentTypeHeader: ['application/json'],
        },
      );
    }
    return ResponseBody.fromString('', 404);
  }

  @override
  void close({bool force = false}) {}
}

Analysis _analysis(
  AnalysisModeEnum mode, {
  int? id,
  String timeframe = '1h',
  String? failureConditions,
  String? invalidationConditions,
  String? opportunity,
  String? risk,
  String? mainScenario,
  String? alternativeScenario,
  String? technicalDrivers,
  String? fundamentalDrivers,
  String? marketContext,
  String? whyReason,
  String? marketCondition,
  TradePlan? tradePlan,
  FundamentalContext? fundamentalContext,
  FundamentalCitations? fundamentalCitations,
  int? techBuyCount,
  int? techSellCount,
  int? techNeutralCount,
  AnalysisOutcomeStatusEnum? outcomeStatus,
}) => $Analysis(
  (builder) => builder
    ..id = id ?? (mode == AnalysisModeEnum.pro ? 2 : 1)
    ..userId = 1
    ..instrument = 'XAU/USD'
    ..timeframe = timeframe
    ..mode = mode
    ..tradingBias = 'bearish'
    ..riskLevel = 'medium'
    ..failureConditions = failureConditions
    ..invalidationConditions = invalidationConditions
    ..opportunity = opportunity
    ..risk = risk
    ..mainScenario = mainScenario
    ..alternativeScenario = alternativeScenario
    ..keyDriversTechnical = technicalDrivers
    ..keyDriversFundamental = fundamentalDrivers
    ..marketContext = marketContext
    ..whyReason = whyReason
    ..marketCondition = marketCondition
    ..tradePlan = tradePlan?.toBuilder()
    ..fundamentalContext = fundamentalContext?.toBuilder()
    ..fundamentalCitations = fundamentalCitations?.toBuilder()
    ..techBuyCount = techBuyCount
    ..techSellCount = techSellCount
    ..techNeutralCount = techNeutralCount
    ..outcomeStatus = outcomeStatus
    ..validUntil = DateTime.utc(2030)
    ..createdAt = DateTime.utc(2026),
);

FundamentalContext _fundamentalContext() => FundamentalContext(
  (builder) => builder
    ..newsItems.add(
      FundamentalNewsItem(
        (item) => item
          ..id = 'news-1'
          ..title = 'Test headline'
          ..summary = 'Test summary'
          ..source_ = 'Test Source'
          ..url = 'https://example.com/news-1'
          ..publishedAt = DateTime.utc(2026),
      ),
    ),
);

TradePlan _tradePlan() => TradePlan(
  (plan) => plan
    ..preferredSide = TradePlanPreferredSideEnum.buy
    ..buy.replace(_tradeSide('4400'))
    ..sell.replace(_tradeSide('4420')),
);

TradeSide _tradeSide(String entry) => TradeSide(
  (side) => side
    ..entryZone = entry
    ..stopLoss = '4380'
    ..takeProfit1 = '4440'
    ..takeProfit2 = '4460'
    ..riskRewardRatio = '1:2'
    ..rationale = 'Test',
);

class _FakeAnalysisProvider extends AnalysisProvider {
  _FakeAnalysisProvider(super.auth, this.analysis, {this.alertStatus});

  final Analysis analysis;
  final AlertStatus? alertStatus;
  final List<CreateAnalysisBodyTimeframeEnum> requestedTimeframes = [];

  @override
  Future<Analysis?> getAnalysis(int id, {bool silent = false}) async =>
      analysis;

  @override
  Future<AlertStatus?> getAnalysisAlerts(int id) async => alertStatus;

  @override
  Future<Analysis?> createAnalysis({
    required String instrument,
    required CreateAnalysisBodyTimeframeEnum timeframe,
    required CreateAnalysisBodyModeEnum mode,
    String? userInputContext,
  }) async {
    requestedTimeframes.add(timeframe);
    final value = switch (timeframe) {
      CreateAnalysisBodyTimeframeEnum.n1m => '1m',
      CreateAnalysisBodyTimeframeEnum.n5m => '5m',
      CreateAnalysisBodyTimeframeEnum.n15m => '15m',
      CreateAnalysisBodyTimeframeEnum.n30m => '30m',
      CreateAnalysisBodyTimeframeEnum.n4h => '4h',
      CreateAnalysisBodyTimeframeEnum.n1d => '1D',
      CreateAnalysisBodyTimeframeEnum.n1w => '1W',
      _ => '1h',
    };
    return _analysis(
      mode == CreateAnalysisBodyModeEnum.pro
          ? AnalysisModeEnum.pro
          : AnalysisModeEnum.beginner,
      id: analysis.id + 1,
      timeframe: value,
    );
  }
}

class _FakeMarketProvider extends MarketProvider {
  _FakeMarketProvider(AuthProvider auth) : super(auth, MarketRepository(Dio()));

  @override
  Future<List<MarketCandle>> getCandlesFor(
    String instrument,
    String timeframe, {
    bool force = false,
  }) async => const [];

  @override
  Future<BeginnerTechnicalSnapshot?> getTechnicalFor(
    String instrument,
    String timeframe, {
    bool force = false,
  }) async => const BeginnerTechnicalSnapshot(
    lastClose: 100,
    change1dPercent: 0,
    rsi: 50,
    rsiSignal: 'Buy',
    macdAction: 'Sell',
    buyCount: 1,
    neutralCount: 1,
    sellCount: 1,
    overallSignal: 'Neutral',
    oscillatorBuyCount: 1,
    oscillatorNeutralCount: 1,
    oscillatorSellCount: 1,
    movingAverageBuyCount: 1,
    movingAverageNeutralCount: 1,
    movingAverageSellCount: 1,
    movingAverages: [
      TechnicalMovingAverage(period: 9, type: 'EMA', value: 100, signal: 'Buy'),
    ],
  );

  @override
  Future<void> loadQuotes({bool force = false, bool silent = false}) async {}
}
