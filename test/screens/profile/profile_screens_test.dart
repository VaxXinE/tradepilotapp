import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:trade_pilot_api_client/trade_pilot_api_client.dart';
import 'package:tradepilotapp/core/theme/theme_controller.dart';
import 'package:tradepilotapp/providers/auth_provider.dart';
import 'package:tradepilotapp/screens/home/tabs/profile_tab.dart';
import 'package:tradepilotapp/screens/profile/change_password_screen.dart';
import 'package:tradepilotapp/services/native_push_service.dart';

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

  testWidgets('profile renders account sections and notification entry', (
    tester,
  ) async {
    final auth = AuthProvider();
    await tester.runAsync(() => Future<void>.delayed(Duration.zero));
    _authenticate(auth);
    final push = NativePushService(auth);
    final theme = ThemeController(await SharedPreferences.getInstance());
    addTearDown(push.dispose);

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: auth),
          ChangeNotifierProvider.value(value: push),
          ChangeNotifierProvider.value(value: theme),
        ],
        child: const MaterialApp(home: ProfileTab()),
      ),
    );

    expect(find.text('User Profile'), findsOneWidget);
    expect(find.text('user@example.com'), findsOneWidget);
    expect(find.text('Informasi Profil'), findsOneWidget);
    expect(find.text('Mode analisis'), findsOneWidget);
    expect(find.text('Tema gelap'), findsOneWidget);
    expect(
      tester
          .widget<SwitchListTile>(
            find.widgetWithText(SwitchListTile, 'Tema gelap'),
          )
          .value,
      isTrue,
    );
    expect(find.textContaining('Saat ini: Pemula'), findsOneWidget);
    expect(find.text('Ganti Password'), findsOneWidget);
    expect(find.text('Pengaturan Notifikasi'), findsOneWidget);
  });

  testWidgets('change password rejects confirmation mismatch locally', (
    tester,
  ) async {
    final auth = AuthProvider();
    await tester.runAsync(() => Future<void>.delayed(Duration.zero));
    _authenticate(auth);
    final adapter = _CountingAdapter();
    auth.client.dio.httpClientAdapter = adapter;

    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: auth,
        child: const MaterialApp(home: ChangePasswordScreen()),
      ),
    );

    await tester.enterText(find.byType(TextFormField).at(0), 'current-pass');
    await tester.enterText(find.byType(TextFormField).at(1), 'new-password');
    await tester.enterText(find.byType(TextFormField).at(2), 'different-pass');
    await tester.tap(find.text('Simpan'));
    await tester.pump();

    expect(find.text('Konfirmasi password tidak cocok'), findsOneWidget);
    expect(adapter.calls, 0);
  });

  testWidgets('logout clears the session when Firebase is unavailable', (
    tester,
  ) async {
    final auth = AuthProvider();
    await tester.runAsync(() => Future<void>.delayed(Duration.zero));
    _authenticate(auth);
    auth.client.dio.httpClientAdapter = _LogoutAdapter();
    final push = NativePushService(auth);
    final theme = ThemeController(await SharedPreferences.getInstance());
    addTearDown(push.dispose);

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: auth),
          ChangeNotifierProvider.value(value: push),
          ChangeNotifierProvider.value(value: theme),
        ],
        child: const MaterialApp(home: ProfileTab()),
      ),
    );
    final logoutButton = find.widgetWithText(OutlinedButton, 'Keluar');
    await tester.ensureVisible(logoutButton);
    await tester.pump();
    await tester.tap(logoutButton);
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(TextButton, 'Keluar'));
    await tester.pumpAndSettle();

    expect(auth.status, AuthStatus.unauthenticated);
    expect(auth.user, isNull);
  });
}

void _authenticate(AuthProvider auth) {
  auth
    ..status = AuthStatus.authenticated
    ..user = User(
      (builder) => builder
        ..id = 1
        ..email = 'user@example.com'
        ..displayName = 'User Profile'
        ..role = UserRoleEnum.user
        ..selectedMode = UserSelectedModeEnum.beginner
        ..themePreference = UserThemePreferenceEnum.dark
        ..securityQuestion = 'Nama hewan pertama?'
        ..onboardingCompleted = true,
    );
}

class _CountingAdapter implements HttpClientAdapter {
  int calls = 0;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) {
    calls++;
    throw StateError('Request tidak seharusnya dikirim');
  }

  @override
  void close({bool force = false}) {}
}

class _LogoutAdapter implements HttpClientAdapter {
  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    return ResponseBody.fromString(
      '{"message":"ok"}',
      200,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}
