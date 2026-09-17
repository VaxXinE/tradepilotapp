// Smoke test dasar: memastikan TradePilotApp bisa di-build tanpa exception
// dan menampilkan splash screen (state awal sebelum AuthProvider selesai
// mengecek sesi tersimpan).

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:upgrader/upgrader.dart';

import 'package:tradepilotapp/main.dart';

void main() {
  testWidgets('TradePilotApp builds and shows splash state', (
    WidgetTester tester,
  ) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    try {
      SharedPreferences.setMockInitialValues({});
      final preferences = await SharedPreferences.getInstance();
      await tester.pumpWidget(TradePilotApp(preferences: preferences));

      // Sebelum AuthProvider selesai restore sesi, splash screen tampil
      // dengan indicator loading.
      expect(find.text('Trade Pilot'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      final upgradeGate = tester.widget<UpgradeAlert>(
        find.byType(UpgradeAlert),
      );
      expect(upgradeGate.barrierDismissible, isFalse);
      expect(upgradeGate.showIgnore, isFalse);
      expect(upgradeGate.showLater, isFalse);
      expect(upgradeGate.shouldPopScope!(), isFalse);

      await tester.pump(const Duration(milliseconds: 1));
    } finally {
      debugDefaultTargetPlatformOverride = null;
    }
  });
}
