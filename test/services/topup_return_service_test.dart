import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:tradepilotapp/core/topup/topup_return_link.dart';
import 'package:tradepilotapp/services/topup_return_service.dart';

void main() {
  test('reports a link opened before the listener started', () async {
    final seen = <TopupReturnLink>[];
    final service = TopupReturnService(
      onReturn: seen.add,
      linkStream: const Stream<Uri>.empty(),
      initialLink: () async =>
          Uri.parse('id.tradepilot.app://topup/result?status=approved&id=7'),
    );
    addTearDown(service.dispose);

    await service.start();

    expect(seen.single.status, TopupReturnStatus.approved);
    expect(seen.single.topupId, 7);
  });

  test('reports later links and ignores unrelated ones', () async {
    final controller = StreamController<Uri>();
    addTearDown(controller.close);
    final seen = <TopupReturnLink>[];
    final service = TopupReturnService(
      onReturn: seen.add,
      linkStream: controller.stream,
      initialLink: () async => null,
    );
    addTearDown(service.dispose);
    await service.start();

    controller
      ..add(Uri.parse('id.tradepilot.app://auth/callback?code=abc'))
      ..add(Uri.parse('id.tradepilot.app://topup/result?status=cancelled'))
      ..add(Uri.parse('https://tradepilot.id/topup'));
    await pumpEventQueue();

    expect(seen.map((link) => link.status), [TopupReturnStatus.cancelled]);
  });

  test(
    'stops reporting after dispose and tolerates a failing platform',
    () async {
      final controller = StreamController<Uri>();
      addTearDown(controller.close);
      final seen = <TopupReturnLink>[];
      final service = TopupReturnService(
        onReturn: seen.add,
        linkStream: controller.stream,
        initialLink: () async => throw StateError('no platform'),
      );

      await service.start();
      await service.dispose();
      controller.add(
        Uri.parse('id.tradepilot.app://topup/result?status=failed'),
      );
      await pumpEventQueue();

      expect(seen, isEmpty);
    },
  );
}
