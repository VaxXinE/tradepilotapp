import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tradepilotapp/core/theme/app_theme.dart';
import 'package:tradepilotapp/models/market_models.dart';
import 'package:tradepilotapp/widgets/app_shell_chrome.dart';

import '../helpers/localized_test_app.dart';

void main() {
  testWidgets('app header exposes profile and notification actions', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    var profileOpened = false;
    var notificationsOpened = false;

    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(textScaler: TextScaler.linear(1.3)),
        child: MaterialApp(
          theme: AppTheme.light,
          home: Scaffold(
            body: TradePilotAppHeader(
              displayName: 'Trader',
              avatarUrl: null,
              unreadCount: 12,
              languageButton: const SizedBox(width: 40),
              isDarkMode: false,
              onToggleTheme: () {},
              onOpenNotifications: () => notificationsOpened = true,
              onOpenProfile: () => profileOpened = true,
              onOpenHome: () {},
              profileActive: false,
              notificationsLabel: 'Notifications',
              profileLabel: 'Profile',
              themeLabel: 'Dark theme',
              logoLabel: 'TradePilot logo',
              backLabel: 'Back',
            ),
          ),
        ),
      ),
    );

    expect(tester.takeException(), isNull);
    expect(find.text('9+'), findsOneWidget);
    await tester.tap(find.byTooltip('Notifications'));
    await tester.tap(find.byKey(const Key('app-header-profile')));
    expect(notificationsOpened, isTrue);
    expect(profileOpened, isTrue);
  });

  testWidgets('ticker hides without data and renders live quote', (
    tester,
  ) async {
    await tester.pumpWidget(
      localizedTestApp(
        theme: AppTheme.dark,
        home: const Scaffold(body: LiveMarketTicker(quotes: [])),
      ),
    );
    expect(find.byKey(const Key('live-market-ticker')), findsNothing);

    const quote = LiveMarketQuote(
      instrument: 'XAU/USD',
      symbol: 'XAUUSD',
      price: 4375.25,
      changePercent: 1.2,
      direction: 'up',
    );
    await tester.pumpWidget(
      localizedTestApp(
        theme: AppTheme.dark,
        home: const Scaffold(body: LiveMarketTicker(quotes: [quote])),
      ),
    );
    await tester.pump();

    // The marquee renders the same run twice so the loop has no visible seam.
    expect(find.text('XAU/USD'), findsNWidgets(2));
    expect(find.text('4375.25'), findsNWidgets(2));
    expect(find.text('1.20%'), findsNWidgets(2));
    expect(find.text('LIVE QUOTE'), findsNWidgets(2));
  });

  testWidgets('bottom nav includes dashboard beside analysis', (tester) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final taps = <int>[];
    const items = [
      AppNavItem(id: 0, icon: Icons.home_rounded, label: 'Dashboard'),
      AppNavItem(id: 1, icon: Icons.trending_up_rounded, label: 'Analysis'),
      AppNavItem(id: 2, icon: Icons.schedule_rounded, label: 'History'),
      AppNavItem(id: 3, icon: Icons.menu_book_rounded, label: 'Guide'),
    ];

    await tester.pumpWidget(
      localizedTestApp(
        theme: AppTheme.dark,
        home: Scaffold(
          bottomNavigationBar: AppBottomNav(
            items: items,
            // Profile has no tab of its own, so nothing is highlighted.
            activeId: 4,
            onSelected: taps.add,
          ),
        ),
      ),
    );

    expect(tester.takeException(), isNull);
    expect(find.text('Analysis'), findsOneWidget);
    expect(find.text('History'), findsOneWidget);
    expect(find.text('Guide'), findsOneWidget);
    expect(find.text('Dashboard'), findsOneWidget);
    expect(find.text('Profile'), findsNothing);

    final selectedFlags = tester
        .widgetList<Semantics>(find.byType(Semantics))
        .map((widget) => widget.properties.selected)
        .toList();
    expect(selectedFlags, isNot(contains(true)));

    await tester.tap(find.text('History'));
    expect(taps, [2]);
  });

  testWidgets('header shows a back action only outside the main tabs', (
    tester,
  ) async {
    var wentBack = false;

    Widget header({VoidCallback? onBack}) => localizedTestApp(
      theme: AppTheme.light,
      home: Scaffold(
        body: TradePilotAppHeader(
          displayName: 'Trader',
          avatarUrl: null,
          unreadCount: 0,
          languageButton: const SizedBox(width: 40),
          isDarkMode: false,
          onToggleTheme: () {},
          onOpenNotifications: () {},
          onOpenProfile: () {},
          onOpenHome: () {},
          profileActive: onBack != null,
          onBack: onBack,
          notificationsLabel: 'Notifications',
          profileLabel: 'Profile',
          themeLabel: 'Dark theme',
          logoLabel: 'TradePilot logo',
          backLabel: 'Back',
        ),
      ),
    );

    await tester.pumpWidget(header());
    expect(find.byKey(const Key('app-header-back')), findsNothing);

    await tester.pumpWidget(header(onBack: () => wentBack = true));
    await tester.tap(find.byKey(const Key('app-header-back')));
    expect(wentBack, isTrue);
  });
}
