import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:tradepilotapp/services/adaptive_plan_share.dart';

AdaptivePlanShareData _data({int positions = 2}) => AdaptivePlanShareData(
  title: 'Adaptive Plan summary',
  instrument: 'XAU/USD',
  timeframe: '1h',
  analyzedAt: 'Analyzed: Sep 30, 2026, 10:00',
  generatedLabel: 'Image created: Sep 30, 2026, 10:05',
  sideLabel: 'Price-rise scenario (Buy)',
  status: 'Plan ready to review',
  actionable: true,
  statusDetail:
      'Your selected tier and risk style, shown as an objective scenario.',
  account: 'Micro',
  style: 'Conservative style',
  positionsTitle: 'Entry point & lot per position',
  positions: [
    for (var i = 0; i < positions; i++)
      (label: 'Position ${i + 1}', value: '${2320 - i * 10} · 0.01 lot'),
  ],
  metrics: [
    (label: 'Total lots', value: '0.02 lot', detail: null),
    (label: 'TP1', value: '2400', detail: 'Estimated profit: +\$80'),
  ],
  notes: ['A reference from the saved analysis, not an order.'],
);

bool _isPng(Uint8List bytes) =>
    bytes.length > 8 &&
    bytes[0] == 0x89 &&
    bytes[1] == 0x50 &&
    bytes[2] == 0x4E;

void main() {
  testWidgets('renders a PNG that grows with the number of positions', (
    tester,
  ) async {
    final short = await tester.runAsync(
      () => renderAdaptivePlanSharePng(_data(positions: 1)),
    );
    final long = await tester.runAsync(
      () => renderAdaptivePlanSharePng(_data(positions: 7)),
    );

    expect(_isPng(short!), isTrue);
    expect(_isPng(long!), isTrue);
    expect(long.length, greaterThan(short.length));
  });
}
