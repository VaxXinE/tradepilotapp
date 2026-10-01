import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tradepilotapp/widgets/adaptive_plan_common.dart';

double _lum(Color c) {
  double f(double v) => v <= .03928 ? v / 12.92 : math.pow((v + .055) / 1.055, 2.4).toDouble();
  return .2126 * f(c.r) + .7152 * f(c.g) + .0722 * f(c.b);
}

double _contrast(Color a, Color b) {
  final la = _lum(a), lb = _lum(b);
  return (math.max(la, lb) + .05) / (math.min(la, lb) + .05);
}

void main() {
  // Adaptive text colors must stay readable (WCAG AA = 4.5:1) on each theme's
  // card surface. The bright dark-theme tones fail on white (~1.9:1).
  for (final (brightness, surface) in [
    (Brightness.light, const Color(0xFFFAFAFA)),
    (Brightness.dark, const Color(0xFF101216)),
  ]) {
    testWidgets('adaptive colors are readable in ${brightness.name} mode', (tester) async {
      late BuildContext ctx;
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(brightness: brightness),
          home: Builder(builder: (c) {
            ctx = c;
            return const SizedBox();
          }),
        ),
      );
      for (final (name, color) in [
        ('buy', ctx.adaptiveBuyColor),
        ('sell', ctx.adaptiveSellColor),
        ('amber', ctx.adaptiveAmber),
      ]) {
        expect(
          _contrast(color, surface),
          greaterThanOrEqualTo(4.5),
          reason: '$name on ${brightness.name}',
        );
      }
    });
  }
}
