import 'generated/app_localizations.dart';
import 'generated/app_localizations_en.dart';

/// Localized strings for layers that have no `BuildContext`.
///
/// Provider, service, dan repository menghasilkan pesan yang berakhir di layar,
/// tetapi tidak bisa memanggil `context.l10n`. Sebelumnya mereka menuliskan
/// literal bahasa Indonesia, sehingga mode English tetap memunculkan pesan
/// Indonesia.
///
/// `MaterialApp.builder` menjaga nilai di sini tetap mengikuti locale aktif,
/// jadi pesan dari provider memakai bahasa yang sama dengan teks layar.
///
/// Pada test, panggil [update] untuk memilih bahasa yang diharapkan.
class AppMessages {
  AppMessages._();

  static AppLocalizations _current = AppLocalizationsEn();

  /// Bahasa aktif. Default-nya English, sama seperti default `LocaleController`.
  static AppLocalizations get l10n => _current;

  static void update(AppLocalizations value) => _current = value;
}
