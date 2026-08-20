// Smoke test dasar: memastikan TradePilotApp bisa di-build tanpa exception
// dan menampilkan splash screen (state awal sebelum AuthProvider selesai
// mengecek sesi tersimpan).

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:tradepilotapp/main.dart';

void main() {
  testWidgets('TradePilotApp builds and shows splash state', (WidgetTester tester) async {
    await tester.pumpWidget(const TradePilotApp());

    // Sebelum AuthProvider selesai restore sesi, splash screen tampil
    // dengan indicator loading.
    expect(find.text('Trade Pilot'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });
}
