import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tradepilotapp/core/preferences/mental_checklist_controller.dart';

void main() {
  test('mental checklist is opt-in and persists its setting', () async {
    SharedPreferences.setMockInitialValues({});
    final preferences = await SharedPreferences.getInstance();
    final controller = MentalChecklistController(preferences);

    expect(controller.enabled, isFalse);
    await controller.setEnabled(true);

    expect(controller.enabled, isTrue);
    expect(preferences.getBool('tradepilot.mentalChecklist.enabled'), isTrue);
  });
}
