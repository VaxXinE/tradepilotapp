import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:trade_pilot_api_client/trade_pilot_api_client.dart';
import 'package:tradepilotapp/l10n/l10n.dart';
import 'package:tradepilotapp/providers/auth_provider.dart';
import 'package:tradepilotapp/providers/credit_provider.dart';
import 'package:tradepilotapp/repositories/topup_repository.dart';
import 'package:tradepilotapp/screens/topup/topup_screen.dart';

/// A valid 1x1 PNG, so `Image.memory` in the proof preview decodes it.
final _pngBytes = Uint8List.fromList([
  0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, 0x00, 0x00, 0x00, 0x0D, //
  0x49, 0x48, 0x44, 0x52, 0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01,
  0x08, 0x06, 0x00, 0x00, 0x00, 0x1F, 0x15, 0xC4, 0x89, 0x00, 0x00, 0x00,
  0x0A, 0x49, 0x44, 0x41, 0x54, 0x78, 0x9C, 0x63, 0x00, 0x01, 0x00, 0x00,
  0x05, 0x00, 0x01, 0x0D, 0x0A, 0x2D, 0xB4, 0x00, 0x00, 0x00, 0x00, 0x49,
  0x45, 0x4E, 0x44, 0xAE, 0x42, 0x60, 0x82,
]);

const _signedUrl =
    'https://storage.googleapis.com/tradepilot/topups/proof.jpg'
    '?X-Goog-Signature=deadbeefcafe';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const storageChannel = MethodChannel(
    'plugins.it_nomads.com/flutter_secure_storage',
  );

  setUp(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(storageChannel, (_) async => null);
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(storageChannel, null);
  });

  testWidgets('shows balance, QRIS rate and top-up history', (tester) async {
    final harness = await _pump(tester);

    expect(find.text('Credit balance'), findsOneWidget);
    expect(find.text('10'), findsOneWidget);
    expect(find.textContaining('Rp5.000 per credit'), findsOneWidget);
    expect(find.text('Top-up history'), findsOneWidget);

    // Status of every row, plus the admin review note.
    expect(find.text('Pending'), findsWidgets);
    expect(find.text('Approved'), findsOneWidget);
    expect(find.text('Rejected'), findsOneWidget);
    expect(
      find.textContaining('Admin note: Transfer not found'),
      findsOneWidget,
    );
    expect(find.textContaining('10 credit added'), findsOneWidget);

    harness.dispose();
  });

  testWidgets('previews the credits an amount buys', (tester) async {
    final harness = await _pump(tester);

    await _type(tester, _amountField, '50000');

    expect(find.text('You will receive 10 credit'), findsOneWidget);

    harness.dispose();
  });

  testWidgets('requires proof before submitting', (tester) async {
    final harness = await _pump(tester);

    await _type(tester, _amountField, '50000');
    await _openPaymentStep(tester);

    final qris = tester.widget<Image>(
      find.byKey(const ValueKey('topup-qris-image')),
    );
    expect(
      (qris.image as AssetImage).assetName,
      'assets/images/trade_pilot_qris.jpeg',
    );
    expect(find.text('Payment proof (required)'), findsOneWidget);
    expect(
      tester
          .widget<FilledButton>(
            find.widgetWithText(FilledButton, 'Submit top-up request'),
          )
          .onPressed,
      isNull,
    );
    expect(
      harness.adapter.requests.where((options) => options.path == '/topups'),
      isEmpty,
    );

    harness.dispose();
  });

  testWidgets('sends the object path, never the signed URL', (tester) async {
    final harness = await _pump(tester, picker: _FakePicker());

    await _type(tester, _amountField, '50000');
    await _openPaymentStep(tester);

    await _tap(tester, 'Attach proof');
    expect(find.text('Proof attached'), findsOneWidget);

    await _tap(tester, 'Submit top-up request');

    expect(
      find.text('Top-up approved. 10 credit has been added to your balance.'),
      findsOneWidget,
    );

    final post = harness.adapter.requests.firstWhere(
      (options) => options.path == '/topups',
    );
    final body = Map<String, dynamic>.from(post.data as Map);

    expect(body['proofObjectPath'], 'topups/proof.jpg');
    expect(jsonEncode(body), isNot(contains('X-Goog-Signature')));
    expect(jsonEncode(body), isNot(contains('storage.googleapis.com')));

    // The upload happened before the top-up, and only once.
    expect(
      harness.adapter.requests.map((options) => options.method).toList(),
      containsAllInOrder(['POST', 'PUT', 'POST']),
    );

    harness.dispose();
  });

  testWidgets('a failed proof upload does not create a top-up', (tester) async {
    final harness = await _pump(tester, picker: _FakePicker());
    harness.adapter.failUpload = true;

    await _type(tester, _amountField, '50000');
    await _openPaymentStep(tester);

    await _tap(tester, 'Attach proof');

    await _tap(tester, 'Submit top-up request');

    expect(
      find.text(
        'Payment proof could not be uploaded. The request was not submitted.',
      ),
      findsOneWidget,
    );
    expect(
      harness.adapter.requests.where((options) => options.path == '/topups'),
      isEmpty,
    );

    // The picked proof survives so the user can just retry.
    expect(find.text('Proof attached'), findsOneWidget);

    harness.dispose();
  });

  testWidgets('rejects an oversized proof before uploading', (tester) async {
    final harness = await _pump(
      tester,
      picker: _FakePicker(bytes: Uint8List(5 * 1024 * 1024 + 1)),
    );

    await _type(tester, _amountField, '50000');
    await _openPaymentStep(tester);

    await _tap(tester, 'Attach proof');

    expect(
      find.text('Use a JPG, PNG, WebP, or GIF image up to 5 MB.'),
      findsOneWidget,
    );
    expect(find.text('Proof attached'), findsNothing);
    expect(
      harness.adapter.requests.where((options) => options.method == 'PUT'),
      isEmpty,
    );

    harness.dispose();
  });

  testWidgets('rejects a non-image proof before uploading', (tester) async {
    final harness = await _pump(
      tester,
      picker: _FakePicker(name: 'statement.pdf', mimeType: 'application/pdf'),
    );

    await _type(tester, _amountField, '50000');
    await _openPaymentStep(tester);

    await _tap(tester, 'Attach proof');

    expect(
      find.text('Use a JPG, PNG, WebP, or GIF image up to 5 MB.'),
      findsOneWidget,
    );
    expect(
      harness.adapter.requests.where((options) => options.method == 'PUT'),
      isEmpty,
    );

    harness.dispose();
  });

  testWidgets('double tap on submit only posts once', (tester) async {
    final harness = await _pump(tester, picker: _FakePicker());

    await _type(tester, _amountField, '50000');
    await _openPaymentStep(tester);
    await _tap(tester, 'Attach proof');

    final submit = find.text('Submit top-up request');
    await tester.ensureVisible(submit);
    await tester.pumpAndSettle();
    await tester.tap(submit);
    await tester.tap(submit, warnIfMissed: false);
    await tester.pumpAndSettle();

    expect(
      harness.adapter.requests.where((options) => options.path == '/topups'),
      hasLength(1),
    );

    harness.dispose();
  });

  testWidgets('validates the amount against the backend rate', (tester) async {
    final harness = await _pump(tester);

    await _tap(tester, 'Continue to payment');
    expect(find.text('Enter the amount you paid.'), findsOneWidget);

    await _type(tester, _amountField, '1000');
    await _tap(tester, 'Continue to payment');
    expect(find.textContaining('Minimum top-up is Rp5.000'), findsOneWidget);

    expect(
      harness.adapter.requests.where((options) => options.path == '/topups'),
      isEmpty,
    );

    harness.dispose();
  });

  testWidgets('shows an empty state when there is no history', (tester) async {
    final harness = await _pump(tester, historyRows: const []);

    expect(
      find.text('You have not made any top-up requests yet.'),
      findsOneWidget,
    );

    harness.dispose();
  });

  testWidgets('offers a retry when history fails to load', (tester) async {
    final harness = await _pump(tester, failHistory: true);

    // A 5xx is reported generically, and the server's own words never reach
    // the screen.
    expect(find.textContaining('The server is having trouble'), findsOneWidget);
    expect(find.textContaining('boom'), findsNothing);
    expect(find.text('Try again'), findsWidgets);

    harness.adapter.failHistory = false;
    await tester.ensureVisible(find.text('Try again').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Try again').last);
    await tester.pumpAndSettle();

    expect(find.textContaining('The server is having trouble'), findsNothing);
    expect(find.text('Approved'), findsOneWidget);

    harness.dispose();
  });

  testWidgets('paginates the history', (tester) async {
    final harness = await _pump(tester, totalOverride: 25);

    await _tap(tester, 'Load more');

    final pages = harness.adapter.requests
        .where((options) => options.path == '/topups/mine')
        .map((options) => options.queryParameters['page'])
        .toList();
    expect(pages, containsAllInOrder([1, 2]));

    harness.dispose();
  });
}

/// The test viewport is 800x600, so most of this screen starts off-screen.
Future<void> _tap(WidgetTester tester, String label) async {
  final finder = find.text(label);
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

Future<void> _openPaymentStep(WidgetTester tester) async {
  await _tap(tester, 'Continue to payment');
  expect(find.text('Transfer Proof Is Required'), findsOneWidget);
  await _tap(tester, 'Got it');
}

Future<void> _type(WidgetTester tester, Finder field, String text) async {
  await tester.ensureVisible(field);
  await tester.pumpAndSettle();
  await tester.enterText(field, text);
  await tester.pump();
}

final _amountField = find.widgetWithText(TextField, 'Amount (Rupiah)');

class _Harness {
  _Harness(this.adapter, this.credit, this.auth);

  final _TopupAdapter adapter;
  final CreditProvider credit;
  final AuthProvider auth;

  void dispose() => credit.dispose();
}

Future<_Harness> _pump(
  WidgetTester tester, {
  ImagePicker? picker,
  List<Map<String, dynamic>>? historyRows,
  bool failHistory = false,
  int? totalOverride,
}) async {
  final auth = AuthProvider();
  await tester.runAsync(() => Future<void>.delayed(Duration.zero));
  auth
    ..status = AuthStatus.authenticated
    ..user = User(
      (builder) => builder
        ..id = 1
        ..email = 'user@example.com'
        ..displayName = 'User'
        ..role = UserRoleEnum.user
        ..selectedMode = UserSelectedModeEnum.beginner
        ..themePreference = UserThemePreferenceEnum.dark
        ..createdAt = DateTime.utc(2026)
        ..onboardingCompleted = true
        ..hasPassword = true,
    );

  final adapter = _TopupAdapter(
    rows: historyRows ?? _rows(),
    total: totalOverride,
  )..failHistory = failHistory;
  auth.client.dio.httpClientAdapter = adapter;

  final credit = CreditProvider(auth, TopupRepository(auth.client));

  await tester.pumpWidget(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: auth),
        ChangeNotifierProvider.value(value: credit),
      ],
      child: MaterialApp(
        locale: const Locale('en'),
        localizationsDelegates: const [
          ...AppLocalizations.localizationsDelegates,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        home: TopUpScreen(imagePicker: picker),
      ),
    ),
  );
  await tester.pumpAndSettle();

  return _Harness(adapter, credit, auth);
}

List<Map<String, dynamic>> _rows() {
  return [
    _row(id: 3, status: 'pending'),
    _row(id: 2, status: 'approved', reviewNote: 'Verified', creditsGranted: 10),
    _row(id: 1, status: 'rejected', reviewNote: 'Transfer not found'),
  ];
}

Map<String, dynamic> _row({
  required int id,
  required String status,
  String? reviewNote,
  int? creditsGranted,
}) {
  return {
    'id': id,
    'userId': 1,
    'amountRupiah': 50000,
    'creditsRequested': 10,
    'conversionRateSnapshot': 5000,
    'paymentReferenceNote': null,
    'proofObjectPath': null,
    'status': status,
    'reviewedByUserId': status == 'pending' ? null : 2,
    'reviewedAt': status == 'pending' ? null : '2026-09-07T10:00:00.000Z',
    'reviewNote': reviewNote,
    'creditsGranted': creditsGranted,
    'createdAt': DateTime.utc(2026, 9, id).toIso8601String(),
  };
}

/// An [ImagePicker] that returns a fixed in-memory image, so the widget tests
/// exercise the real picker call path without a platform channel.
class _FakePicker extends ImagePicker {
  _FakePicker({
    this.name = 'proof.jpg',
    this.mimeType = 'image/jpeg',
    Uint8List? bytes,
  }) : bytes = bytes ?? _pngBytes;

  final String name;
  final String mimeType;
  final Uint8List bytes;

  @override
  Future<XFile?> pickImage({
    required ImageSource source,
    double? maxWidth,
    double? maxHeight,
    int? imageQuality,
    CameraDevice preferredCameraDevice = CameraDevice.rear,
    bool requestFullMetadata = true,
  }) async {
    return XFile.fromData(bytes, name: name, mimeType: mimeType);
  }
}

class _TopupAdapter implements HttpClientAdapter {
  _TopupAdapter({required this.rows, this.total});

  final List<Map<String, dynamic>> rows;
  final int? total;
  final List<RequestOptions> requests = [];
  bool failHistory = false;
  bool failUpload = false;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);

    if (options.method == 'PUT') {
      if (failUpload) {
        throw DioException.badResponse(
          statusCode: 403,
          requestOptions: options,
          response: Response<dynamic>(
            requestOptions: options,
            statusCode: 403,
            data: 'SignatureDoesNotMatch',
          ),
        );
      }

      return ResponseBody.fromString('', 200);
    }

    switch (options.path) {
      case '/topups/config':
        return _json({
          'rupiahPerCredit': 5000,
          'qrisImageUrl': 'https://cdn.example.com/qris.png',
        }, 200);

      case '/topups/balance':
        return _json({'balance': 10}, 200);

      case '/storage/uploads/request-url':
        return _json({
          'uploadURL': _signedUrl,
          'objectPath': 'topups/proof.jpg',
        }, 200);

      case '/topups':
        final body = Map<String, dynamic>.from(options.data as Map);
        return _json({
          ..._row(id: 99, status: 'approved', creditsGranted: 10),
          'amountRupiah': body['amountRupiah'],
          'paymentReferenceNote': body['paymentReferenceNote'],
          'proofObjectPath': body['proofObjectPath'],
        }, 201);

      case '/topups/mine':
        if (failHistory) {
          return _json({'error': 'boom'}, 500);
        }

        final page = int.tryParse('${options.queryParameters['page']}') ?? 1;

        return _json({
          'requests': page == 1 ? rows : const <Map<String, dynamic>>[],
          'total': total ?? rows.length,
          'page': page,
          'limit': 20,
        }, 200);

      default:
        return _json({'message': 'ok'}, 200);
    }
  }

  ResponseBody _json(Object body, int status) {
    return ResponseBody.fromString(
      jsonEncode(body),
      status,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}
