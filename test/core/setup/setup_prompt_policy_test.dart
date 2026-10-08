import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tradepilotapp/core/setup/setup_prompt_policy.dart';
import 'package:tradepilotapp/services/setup_prompt_service.dart';

void main() {
  final now = DateTime.utc(2026, 10, 8, 9);

  group('SetupPromptPolicy', () {
    test('does not ask a new user', () {
      expect(
        SetupPromptPolicy.shouldAsk(const SetupPromptState(), 0, now),
        false,
      );
      expect(
        SetupPromptPolicy.shouldAsk(
          const SetupPromptState(),
          SetupPromptPolicy.minAnalyses - 1,
          now,
        ),
        false,
      );
    });

    test('asks once the user has used the app for a while', () {
      expect(
        SetupPromptPolicy.shouldAsk(
          const SetupPromptState(),
          SetupPromptPolicy.minAnalyses,
          now,
        ),
        true,
      );
    });

    test('waits a week before asking again', () {
      final state = SetupPromptState(
        askCount: 1,
        lastAskedAt: now.subtract(const Duration(days: 6)),
      );
      expect(SetupPromptPolicy.shouldAsk(state, 10, now), false);
      expect(
        SetupPromptPolicy.shouldAsk(
          SetupPromptState(
            askCount: 1,
            lastAskedAt: now.subtract(const Duration(days: 7)),
          ),
          10,
          now,
        ),
        true,
      );
    });

    test('never asks more than the lifetime cap', () {
      final state = SetupPromptState(
        askCount: SetupPromptPolicy.maxAsks,
        lastAskedAt: now.subtract(const Duration(days: 365)),
      );
      expect(SetupPromptPolicy.shouldAsk(state, 100, now), false);
    });
  });

  group('SetupPromptService', () {
    setUp(() => SharedPreferences.setMockInitialValues({}));

    test('remembers asks across restarts', () async {
      var clock = now;
      final first = SetupPromptService(
        await SharedPreferences.getInstance(),
        clock: () => clock,
      );
      expect(first.isDue(SetupPromptPolicy.minAnalyses), true);

      await first.recordAsked();
      expect(first.isDue(SetupPromptPolicy.minAnalyses), false);

      clock = now.add(const Duration(days: 8));
      final restarted = SetupPromptService(
        await SharedPreferences.getInstance(),
        clock: () => clock,
      );
      expect(restarted.state.askCount, 1);
      expect(restarted.isDue(SetupPromptPolicy.minAnalyses), true);
    });
  });
}
