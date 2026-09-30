import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tradepilotapp/services/live_chat_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel(LiveChatService.channelName);
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;

  tearDown(() => messenger.setMockMethodCallHandler(channel, null));

  test('open forwards the language to the native side', () async {
    MethodCall? received;
    messenger.setMockMethodCallHandler(channel, (call) async {
      received = call;
      return null;
    });

    final opened = await const LiveChatService().open(language: 'en');

    expect(opened, isTrue);
    expect(received?.method, 'open');
    expect(received?.arguments, {'language': 'en'});
  });

  test('open reports failure when the native call throws', () async {
    messenger.setMockMethodCallHandler(channel, (call) async {
      throw PlatformException(code: 'no_presenter');
    });

    expect(await const LiveChatService().open(), isFalse);
  });

  test('open reports failure when no native handler is registered', () async {
    expect(await const LiveChatService().open(), isFalse);
  });

  test(
    'identify and reset call through and tolerate a missing handler',
    () async {
      final methods = <String>[];
      messenger.setMockMethodCallHandler(channel, (call) async {
        methods.add(call.method);
        return null;
      });

      await const LiveChatService().identify('jwt');
      await const LiveChatService().reset();
      expect(methods, ['identify', 'reset']);

      messenger.setMockMethodCallHandler(channel, null);
      await const LiveChatService().identify('jwt');
      await const LiveChatService().reset();
    },
  );
}
