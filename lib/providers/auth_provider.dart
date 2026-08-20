import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:trade_pilot_api_client/trade_pilot_api_client.dart';

import '../core/api/api_config.dart';
import '../core/storage/token_storage.dart';

enum AuthStatus { unknown, authenticated, unauthenticated }

/// State management untuk sesi login, setara dengan `AuthContext.tsx`
/// pada app Expo di repo Trade-Pilot (`artifacts/mobile`).
class AuthProvider extends ChangeNotifier {
  AuthProvider() {
    _client = TradePilotClient(
      baseUrl: ApiConfig.baseUrl,
      getToken: () async => _token,
    );
    _restoreSession();
  }

  final _storage = TokenStorage();
  late final TradePilotClient _client;

  TradePilotClient get client => _client;

  AuthStatus status = AuthStatus.unknown;
  User? user;
  String? _token;
  String? errorMessage;
  bool isBusy = false;

  Future<void> _restoreSession() async {
    final token = await _storage.readToken();
    if (token == null) {
      status = AuthStatus.unauthenticated;
      notifyListeners();
      return;
    }
    _token = token;
    try {
      final response = await _client.auth.getMe();
      user = response.data;
      status = AuthStatus.authenticated;
    } catch (_) {
      // Token kadaluarsa/invalid — bersihkan sesi lokal.
      await _storage.clear();
      _token = null;
      status = AuthStatus.unauthenticated;
    }
    notifyListeners();
  }

  Future<bool> login({required String email, required String password}) {
    return _run(() async {
      final response = await _client.auth.login(
        loginBody: LoginBody((b) => b
          ..email = email.trim().toLowerCase()
          ..password = password),
      );
      await _applyAuthResponse(response.data);
    });
  }

  Future<bool> register({
    required String email,
    required String password,
    required String displayName,
    required String securityQuestion,
    required String securityAnswer,
    required RegisterBodySelectedModeEnum mode,
  }) {
    return _run(() async {
      final response = await _client.auth.register(
        registerBody: RegisterBody((b) => b
          ..email = email.trim().toLowerCase()
          ..password = password
          ..displayName = displayName
          ..securityQuestion = securityQuestion
          ..securityAnswer = securityAnswer
          ..selectedMode = mode),
      );
      await _applyAuthResponse(response.data);
    });
  }

  Future<void> _applyAuthResponse(AuthResponse? data) async {
    if (data == null || data.token == null) {
      throw Exception('Respons server tidak valid.');
    }
    _token = data.token;
    user = data.user;
    await _storage.saveSession(token: data.token!, user: data.user);
    status = AuthStatus.authenticated;
  }

  Future<void> refreshMe() async {
    try {
      final response = await _client.auth.getMe();
      user = response.data;
      if (user != null) await _storage.saveUser(user!);
      notifyListeners();
    } catch (_) {
      // biarkan state lama kalau gagal refresh
    }
  }

  Future<void> logout() async {
    try {
      await _client.auth.logout();
    } catch (_) {
      // tetap logout lokal walau request gagal (mis. tidak ada koneksi)
    }
    await _storage.clear();
    _token = null;
    user = null;
    status = AuthStatus.unauthenticated;
    notifyListeners();
  }

  /// Step 1 lupa password: ambil pertanyaan keamanan berdasar email.
  Future<SecurityQuestionResponse?> getSecurityQuestion(String email) async {
    return _runValue(() async {
      final response = await _client.auth.getForgotPasswordQuestion(
        forgotPasswordQuestionBody:
            ForgotPasswordQuestionBody((b) => b..email = email.trim().toLowerCase()),
      );
      return response.data;
    });
  }

  /// Step 2 lupa password: verifikasi jawaban keamanan.
  Future<ResetTokenResponse?> verifySecurityAnswer({
    required String email,
    required String answer,
  }) async {
    return _runValue(() async {
      final response = await _client.auth.verifySecurityAnswer(
        verifySecurityAnswerBody: VerifySecurityAnswerBody((b) => b
          ..email = email.trim().toLowerCase()
          ..securityAnswer = answer),
      );
      return response.data;
    });
  }

  /// Step 3 lupa password: set password baru pakai reset token.
  Future<bool> resetPassword({
    required String resetToken,
    required String newPassword,
  }) {
    return _run(() async {
      await _client.auth.resetPassword(
        resetPasswordBody: ResetPasswordBody((b) => b
          ..resetToken = resetToken
          ..newPassword = newPassword),
      );
    });
  }

  Future<bool> _run(Future<void> Function() action) async {
    isBusy = true;
    errorMessage = null;
    notifyListeners();
    try {
      await action();
      isBusy = false;
      notifyListeners();
      return true;
    } catch (e) {
      isBusy = false;
      errorMessage = _friendlyError(e);
      notifyListeners();
      return false;
    }
  }

  Future<T?> _runValue<T>(Future<T> Function() action) async {
    isBusy = true;
    errorMessage = null;
    notifyListeners();
    try {
      final result = await action();
      isBusy = false;
      notifyListeners();
      return result;
    } catch (e) {
      isBusy = false;
      errorMessage = _friendlyError(e);
      notifyListeners();
      return null;
    }
  }

  String _friendlyError(Object e) {
    if (e is DioException) {
      final data = e.response?.data;
      if (data is Map && data['message'] is String) {
        return data['message'] as String;
      }
      if (e.type == DioExceptionType.connectionError ||
          e.type == DioExceptionType.connectionTimeout) {
        return 'Tidak bisa terhubung ke server. Periksa koneksi internet kamu.';
      }
      return 'Terjadi kesalahan. Silakan coba lagi.';
    }
    return 'Terjadi kesalahan. Silakan coba lagi.';
  }
}
