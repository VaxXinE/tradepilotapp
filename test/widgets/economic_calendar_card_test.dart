import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tradepilotapp/models/market_models.dart';
import 'package:tradepilotapp/widgets/calendar/economic_calendar_card.dart';
import 'package:tradepilotapp/widgets/calendar/impact_level_badge.dart';

import '../helpers/localized_test_app.dart';

void main() {
  testWidgets('renders event metrics, impact, and instrument explanation', (
    tester,
  ) async {
    await tester.pumpWidget(
      _app(EconomicCalendarCard(instrument: 'XAU/USD', events: [_event])),
    );

    expect(find.text('FOMC Interest Rate Decision'), findsOneWidget);
    expect(find.text('High Impact'), findsOneWidget);
    expect(find.text('Forecast: 5.25%'), findsOneWidget);
    expect(find.text('Actual: 5.50%'), findsOneWidget);
    expect(find.textContaining('affects Gold'), findsOneWidget);
  });

  testWidgets('renders an empty calendar state', (tester) async {
    await tester.pumpWidget(
      _app(const EconomicCalendarCard(instrument: 'EUR/USD', events: [])),
    );

    expect(
      find.text('There are no relevant upcoming economic events.'),
      findsOneWidget,
    );
  });

  testWidgets('maps medium impact to a single reusable badge', (tester) async {
    await tester.pumpWidget(
      _app(const ImpactLevelBadge(level: EconomicImpactLevel.medium)),
    );

    expect(find.text('Medium Impact'), findsOneWidget);
  });
}

Widget _app(Widget child) => localizedTestApp(
  home: Scaffold(body: SingleChildScrollView(child: child)),
);

final _event = EconomicCalendarEvent(
  time: '19:00',
  currency: 'USD',
  impact: 'high',
  event: 'FOMC Interest Rate Decision',
  previous: '5.00%',
  forecast: '5.25%',
  actual: '5.50%',
  date: '2026-08-21T12:00:00Z',
  epochMs: DateTime.utc(2026, 8, 21, 12).millisecondsSinceEpoch,
  whyTraderCare: '',
);
