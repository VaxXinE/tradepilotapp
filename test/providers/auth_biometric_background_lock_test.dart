import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tradepilotapp/providers/auth_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const storageChannel = MethodChannel(
    'plugins.it_nomads.com/flutter_secure_storage',
  );

  var lockEnabled = true;
  var now = DateTime.utc(2026, 9, 30, 10);

  setUp(() {
    lockEnabled = true;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(storageChannel, (call) async {
          if (call.method == 'read' &&
              (call.arguments as Map)['key'] == 'trade_pilot_biometric_lock') {
            return lockEnabled ? 'true' : null;
          }
          return null;
        });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(storageChannel, null);
  });

  Future<AuthProvider> authenticated() async {
    final auth = AuthProvider();
    await pumpEventQueue();
    auth
      ..status = AuthStatus.authenticated
      ..isLocked = false
      ..clock = () => now;
    return auth;
  }

  test('locks after the grace period in the background', () async {
    final auth = await authenticated();

    await auth.noteAppBackgrounded();
    now = now.add(AuthProvider.lockGracePeriod);
    auth.lockIfBackgroundedTooLong();

    expect(auth.isLocked, isTrue);
  });

  test('stays unlocked on a quick return', () async {
    final auth = await authenticated();

    await auth.noteAppBackgrounded();
    now = now.add(AuthProvider.lockGracePeriod - const Duration(seconds: 1));
    auth.lockIfBackgroundedTooLong();

    expect(auth.isLocked, isFalse);
  });

  test('never locks when the biometric lock is off', () async {
    lockEnabled = false;
    final auth = await authenticated();

    await auth.noteAppBackgrounded();
    now = now.add(const Duration(hours: 1));
    auth.lockIfBackgroundedTooLong();

    expect(auth.isLocked, isFalse);
  });

  test('a resume without a matching background never locks', () async {
    final auth = await authenticated();

    auth.lockIfBackgroundedTooLong();

    expect(auth.isLocked, isFalse);
  });
}
