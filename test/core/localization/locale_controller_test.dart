import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tradepilotapp/core/localization/locale_controller.dart';

void main() {
  test('defaults to English and persists a supported language', () async {
    SharedPreferences.setMockInitialValues({});
    final preferences = await SharedPreferences.getInstance();
    final controller = LocaleController(preferences);

    expect(controller.locale.languageCode, 'en');

    await controller.setLanguage('id');

    expect(controller.locale.languageCode, 'id');
    expect(LocaleController(preferences).locale.languageCode, 'id');
  });

  test('ignores unsupported language codes', () async {
    SharedPreferences.setMockInitialValues({});
    final preferences = await SharedPreferences.getInstance();
    final controller = LocaleController(preferences);

    await controller.setLanguage('xx');

    expect(controller.locale.languageCode, 'en');
  });
}
