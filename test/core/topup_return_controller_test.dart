import 'package:flutter_test/flutter_test.dart';
import 'package:tradepilotapp/core/topup/topup_return_controller.dart';
import 'package:tradepilotapp/core/topup/topup_return_link.dart';

void main() {
  test('keeps a top-up result until it is taken, once', () {
    final controller = TopupReturnController();
    var notified = 0;
    controller.addListener(() => notified++);

    controller.report(
      Uri.parse('id.tradepilot.app://topup/result?status=approved&id=9'),
    );

    expect(notified, 1);
    expect(controller.pending?.status, TopupReturnStatus.approved);
    expect(controller.take()?.topupId, 9);
    expect(controller.pending, isNull);
    expect(controller.take(), isNull);
  });

  test('ignores URLs that are not top-up results', () {
    final controller = TopupReturnController();
    var notified = 0;
    controller.addListener(() => notified++);

    controller
      ..report(Uri.parse('id.tradepilot.app://auth/callback?code=x'))
      ..report(Uri.parse('https://tradepilot.id/topup?status=approved'));

    expect(notified, 0);
    expect(controller.pending, isNull);
  });
}
