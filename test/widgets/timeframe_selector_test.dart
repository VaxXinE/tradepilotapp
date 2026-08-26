import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tradepilotapp/widgets/chart/timeframe_selector.dart';

void main() {
  testWidgets('selects another timeframe and disables input while loading', (
    tester,
  ) async {
    String? selected;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: TimeframeSelector(
            timeframes: const ['1h', '4h'],
            selected: '1h',
            onSelected: (value) => selected = value,
          ),
        ),
      ),
    );
    expect(
      tester
          .widget<ChoiceChip>(find.byKey(const ValueKey('timeframe-1h')))
          .onSelected,
      isNotNull,
    );
    await tester.tap(find.byKey(const ValueKey('timeframe-4h')));
    expect(selected, '4h');

    selected = null;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: TimeframeSelector(
            timeframes: const ['1h', '4h'],
            selected: '1h',
            isLoading: true,
            onSelected: (value) => selected = value,
          ),
        ),
      ),
    );
    await tester.tap(find.byKey(const ValueKey('timeframe-4h')));
    expect(selected, isNull);
  });
}
