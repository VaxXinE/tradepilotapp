import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:trade_pilot_api_client/trade_pilot_api_client.dart';
import 'package:tradepilotapp/providers/analysis_provider.dart';
import 'package:tradepilotapp/providers/auth_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const storageChannel = MethodChannel(
    'plugins.it_nomads.com/flutter_secure_storage',
  );

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(storageChannel, (_) async => null);
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(storageChannel, null);
  });

  test('save and clear note synchronize history hasNote', () async {
    final auth = await _auth(1);
    auth.client.dio.httpClientAdapter = _NoteAdapter();
    final provider = AnalysisProvider(auth)..history = [_analysis()];
    addTearDown(provider.dispose);

    final saved = await provider.saveAnalysisNote(
      analysis: provider.history.first,
      note: '  pelajaran privat  ',
    );
    expect(saved?.userNote, '  pelajaran privat  ');
    expect(provider.history.first.hasNote, isTrue);

    final cleared = await provider.saveAnalysisNote(
      analysis: provider.history.first,
      note: '   ',
    );
    expect(cleared?.userNote, isNull);
    expect(provider.history.first.hasNote, isFalse);
  });

  test('rejects oversized note before network', () async {
    final auth = await _auth(1);
    final adapter = _NoteAdapter();
    auth.client.dio.httpClientAdapter = adapter;
    final provider = AnalysisProvider(auth);
    addTearDown(provider.dispose);

    expect(
      await provider.saveAnalysisNote(analysis: _analysis(), note: 'x' * 5001),
      isNull,
    );
    expect(adapter.requests, 0);
  });

  test('stale user response cannot enter the next account cache', () async {
    final auth = await _auth(1);
    final adapter = _NoteAdapter(deferred: true);
    auth.client.dio.httpClientAdapter = adapter;
    final provider = AnalysisProvider(auth)..history = [_analysis()];
    addTearDown(provider.dispose);

    final request = provider.saveAnalysisNote(
      analysis: provider.history.first,
      note: 'private user A',
    );
    await pumpEventQueue();
    auth
      ..user = _user(2)
      ..notifyListeners();
    adapter.complete('private user A');

    expect(await request, isNull);
    expect(provider.history, isEmpty);
  });
}

Future<AuthProvider> _auth(int id) async {
  final auth = AuthProvider();
  await pumpEventQueue();
  return auth
    ..status = AuthStatus.authenticated
    ..user = _user(id);
}

User _user(int id) => User(
  (builder) => builder
    ..id = id
    ..email = 'u$id@example.com'
    ..displayName = 'User $id'
    ..role = UserRoleEnum.user
    ..selectedMode = UserSelectedModeEnum.beginner
    ..themePreference = UserThemePreferenceEnum.dark
    ..onboardingCompleted = true,
);

Analysis _analysis() => Analysis(
  (builder) => builder
    ..id = 7
    ..userId = 1
    ..instrument = 'XAU/USD'
    ..timeframe = '1h'
    ..mode = AnalysisModeEnum.beginner
    ..validUntil = DateTime.utc(2026, 8, 25)
    ..createdAt = DateTime.utc(2026, 8, 23),
);

class _NoteAdapter implements HttpClientAdapter {
  _NoteAdapter({this.deferred = false});
  final bool deferred;
  final Completer<ResponseBody> _completer = Completer<ResponseBody>();
  int requests = 0;

  void complete(String note) {
    _completer.complete(_response(note));
  }

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests++;
    if (deferred) return _completer.future;
    final note = (options.data as Map<String, dynamic>)['note'] as String;
    return _response(note);
  }

  ResponseBody _response(String note) => ResponseBody.fromString(
    jsonEncode({
      'note': note.trim().isEmpty ? '' : note,
      'updatedAt': '2026-08-23T00:00:00.000Z',
    }),
    200,
    headers: {
      Headers.contentTypeHeader: [Headers.jsonContentType],
    },
  );

  @override
  void close({bool force = false}) {}
}
