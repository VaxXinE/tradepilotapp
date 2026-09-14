import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tradepilotapp/l10n/app_messages.dart';
import 'package:tradepilotapp/l10n/generated/app_localizations.dart';
import 'package:tradepilotapp/l10n/generated/app_localizations_en.dart';
import 'package:tradepilotapp/l10n/generated/app_localizations_id.dart';

import '../helpers/localized_test_app.dart';

void main() {
  tearDown(() => AppMessages.update(AppLocalizationsEn()));

  test('defaults to English, matching the default app locale', () {
    expect(
      AppMessages.l10n.errSessionExpiredRelogin,
      'Your session has ended. Please sign in again.',
    );
  });

  test('follows the language it is updated to', () {
    AppMessages.update(AppLocalizationsId());
    expect(
      AppMessages.l10n.errSessionExpiredRelogin,
      'Sesi login sudah berakhir. Silakan login kembali.',
    );

    AppMessages.update(AppLocalizationsEn());
    expect(
      AppMessages.l10n.errSessionExpiredRelogin,
      'Your session has ended. Please sign in again.',
    );
  });

  testWidgets('an app builder keeps it in sync with the active locale', (
    tester,
  ) async {
    // This mirrors what MaterialApp.builder does in main.dart: without it,
    // provider messages stay in one language while the screens switch.
    Widget app(Locale locale) => MaterialApp(
      locale: locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      builder: (context, child) {
        AppMessages.update(AppLocalizations.of(context));
        return child ?? const SizedBox.shrink();
      },
      home: const SizedBox.shrink(),
    );

    await tester.pumpWidget(app(const Locale('id')));
    expect(AppMessages.l10n.errNoConnection, startsWith('Tidak bisa'));

    await tester.pumpWidget(app(const Locale('en')));
    expect(AppMessages.l10n.errNoConnection, startsWith('Could not reach'));
  });

  testWidgets('every provider message resolves in both languages', (
    tester,
  ) async {
    // A missing translation would surface as an identical string in both
    // locales; these are the messages providers hand straight to the UI.
    String read(AppLocalizations l10n) => [
      l10n.errSessionExpiredRelogin,
      l10n.errNoConnection,
      l10n.errServerProblem,
      l10n.errGeneric,
      l10n.errInstrumentRequired,
      l10n.errBalanceLoadFailed,
      l10n.errTopupSubmitFailed,
      l10n.errNotificationsLoadFailed,
      l10n.errPushRegisterFailed,
      l10n.appErrMaxLossExceedsFunds,
      l10n.mindsetJournalBody,
    ].join('|');

    final english = read(AppLocalizationsEn());
    final indonesian = read(AppLocalizationsId());

    expect(english, isNot(equals(indonesian)));
    for (final part in english.split('|')) {
      expect(part.trim(), isNotEmpty);
    }
    for (final part in indonesian.split('|')) {
      expect(part.trim(), isNotEmpty);
    }
  });

  testWidgets('the shared test app renders English', (tester) async {
    await tester.pumpWidget(
      localizedTestApp(
        home: Builder(
          builder: (context) =>
              Text(AppLocalizations.of(context).errSessionExpired),
        ),
      ),
    );

    expect(find.text('Your session has ended.'), findsOneWidget);
  });
}
