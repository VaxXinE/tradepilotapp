import 'package:flutter_test/flutter_test.dart';
import 'package:tradepilotapp/core/topup/topup_return_link.dart';

void main() {
  TopupReturnLink? parse(String url) =>
      TopupReturnLink.tryParse(Uri.parse(url));

  test('reads the outcome and the top-up id', () {
    final link = parse(
      'id.tradepilot.app://topup/result?status=approved&id=42',
    );
    expect(link?.status, TopupReturnStatus.approved);
    expect(link?.topupId, 42);
  });

  test('accepts the aliases the web page may use', () {
    expect(
      parse('id.tradepilot.app://topup/result?status=success')?.status,
      TopupReturnStatus.approved,
    );
    expect(
      parse('id.tradepilot.app://topup/result?status=cancel')?.status,
      TopupReturnStatus.cancelled,
    );
    expect(
      parse('id.tradepilot.app://topup/result?status=rejected')?.status,
      TopupReturnStatus.failed,
    );
    expect(
      parse('id.tradepilot.app://topup/result?status=pending')?.status,
      TopupReturnStatus.processing,
    );
    expect(
      parse('id.tradepilot.app://topup/result?status=APPROVED')?.status,
      TopupReturnStatus.approved,
    );
  });

  test('drops a missing or invalid id but keeps the status', () {
    expect(
      parse('id.tradepilot.app://topup/result?status=failed')?.topupId,
      isNull,
    );
    expect(
      parse('id.tradepilot.app://topup/result?status=failed&id=abc')?.topupId,
      isNull,
    );
    expect(
      parse('id.tradepilot.app://topup/result?status=failed&id=-3')?.topupId,
      isNull,
    );
  });

  test('ignores links that are not top-up returns', () {
    expect(
      parse('id.tradepilot.app://auth/callback?code=x&status=approved'),
      isNull,
    );
    expect(parse('https://tradepilot.id/topup?status=approved'), isNull);
    expect(parse('other.app://topup/result?status=approved'), isNull);
    expect(parse('id.tradepilot.app://topup/result'), isNull);
    expect(parse('id.tradepilot.app://topup/result?status=hacked'), isNull);
  });
}
