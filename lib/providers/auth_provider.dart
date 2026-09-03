import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:trade_pilot_api_client/trade_pilot_api_client.dart';
import 'package:trade_pilot_api_client/trade_pilot_client.dart';

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
  bool isUpdatingProfile = false;
  bool isChangingPassword = false;
  bool isDeletingAccount = false;
  String? profileError;

  static const int maxDisplayNameLength = 100;

  int _sessionEpoch = 0;
  int _profileRequestId = 0;
  int _passwordRequestId = 0;

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
        loginBody: LoginBody(
          (b) => b
            ..email = email.trim().toLowerCase()
            ..password = password,
        ),
      );
      await _applyAuthResponse(response.data);
    });
  }

  Future<bool> register({
    required String email,
    required String password,
    required String displayName,
    required String securityAnswer,
    required String securityQuestion,
    required RegisterBodySelectedModeEnum mode,
  }) {
    return _run(() async {
      final response = await _client.auth.register(
        registerBody: RegisterBody(
          (b) => b
            ..email = email.trim().toLowerCase()
            ..password = password
            ..displayName = displayName
            ..securityQuestion = securityQuestion
            ..securityAnswer = securityAnswer
            ..selectedMode = mode,
        ),
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
    _sessionEpoch++;
    _profileRequestId++;
    _passwordRequestId++;
    isUpdatingProfile = false;
    isChangingPassword = false;
    isDeletingAccount = false;
    profileError = null;
    await _storage.saveSession(token: data.token!, user: data.user);
    status = AuthStatus.authenticated;
  }

  Future<void> refreshMe() async {
    final epoch = _sessionEpoch;
    final userId = user?.id;
    if (status != AuthStatus.authenticated || userId == null) return;

    try {
      final response = await _client.auth.getMe();

      if (epoch != _sessionEpoch ||
          status != AuthStatus.authenticated ||
          user?.id != userId) {
        return;
      }

      user = response.data;
      notifyListeners();
    } catch (_) {
      // biarkan state lama kalau gagal refresh
    }
  }

  Future<void> logout() async {
    _sessionEpoch++;
    _profileRequestId++;
    _passwordRequestId++;
    isUpdatingProfile = false;
    isChangingPassword = false;
    isDeletingAccount = false;
    profileError = null;

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

  Future<bool> updateDisplayName(String value) async {
    final displayName = value.trim();

    if (displayName.length < 2 || displayName.length > maxDisplayNameLength) {
      profileError =
          'Nama harus terdiri dari 2–$maxDisplayNameLength karakter.';
      notifyListeners();
      return false;
    }

    if (displayName == user?.displayName) {
      profileError = null;
      notifyListeners();
      return true;
    }

    return _updateProfile(
      UpdateProfileBody((builder) => builder.displayName = displayName),
    );
  }

  Future<bool> updateSelectedMode(UserSelectedModeEnum mode) {
    final apiMode = mode == UserSelectedModeEnum.pro
        ? UpdateProfileBodySelectedModeEnum.pro
        : UpdateProfileBodySelectedModeEnum.beginner;

    return _updateProfile(
      UpdateProfileBody((builder) => builder.selectedMode = apiMode),
    );
  }

  Future<bool> updateLanguage(String languageCode) {
    final language = languageCode == 'id'
        ? UpdateProfileBodyLangEnum.id
        : UpdateProfileBodyLangEnum.en;

    return _updateProfile(
      UpdateProfileBody((builder) => builder.lang = language),
    );
  }

  Future<bool> updateTheme(bool dark) {
    return _updateProfile(
      UpdateProfileBody(
        (builder) => builder.themePreference = dark
            ? UpdateProfileBodyThemePreferenceEnum.dark
            : UpdateProfileBodyThemePreferenceEnum.light,
      ),
    );
  }

  Future<bool> completeOnboarding() {
    return _updateProfile(
      UpdateProfileBody((builder) => builder.onboardingCompleted = true),
    );
  }

  Future<bool> updateAvatarPath(String? objectPath) async {
    if (objectPath != null) {
      return _updateProfile(
        UpdateProfileBody((builder) => builder.avatarUrl = objectPath),
      );
    }
    if (status != AuthStatus.authenticated || isUpdatingProfile) return false;
    isUpdatingProfile = true;
    profileError = null;
    notifyListeners();
    try {
      await _client.dio.patch<void>('/auth/profile', data: {'avatarUrl': null});
      await refreshMe();
      return true;
    } catch (error) {
      profileError = _profileFriendlyError(error);
      return false;
    } finally {
      isUpdatingProfile = false;
      notifyListeners();
    }
  }

  Future<bool> _updateProfile(UpdateProfileBody body) async {
    final currentUser = user;
    if (status != AuthStatus.authenticated ||
        currentUser == null ||
        isUpdatingProfile) {
      return false;
    }

    final epoch = _sessionEpoch;
    final userId = currentUser.id;
    final requestId = ++_profileRequestId;

    isUpdatingProfile = true;
    profileError = null;
    notifyListeners();

    try {
      final response = await _client.auth.updateProfile(
        updateProfileBody: body,
      );

      if (!_isCurrentProfileSession(epoch, userId) ||
          requestId != _profileRequestId) {
        return false;
      }

      final updated = response.data;
      if (updated == null) {
        profileError = 'Respons profil dari server tidak valid.';
        return false;
      }

      user = updated;
      return true;
    } catch (error) {
      if (_isCurrentProfileSession(epoch, userId)) {
        profileError = _profileFriendlyError(error);
      }
      return false;
    } finally {
      if (_isCurrentProfileSession(epoch, userId) &&
          requestId == _profileRequestId) {
        isUpdatingProfile = false;
        notifyListeners();
      }
    }
  }

  Future<bool> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    final currentUser = user;
    if (status != AuthStatus.authenticated ||
        currentUser == null ||
        isChangingPassword) {
      return false;
    }

    final epoch = _sessionEpoch;
    final userId = currentUser.id;
    final requestId = ++_passwordRequestId;

    isChangingPassword = true;
    profileError = null;
    notifyListeners();

    try {
      await _client.auth.changePassword(
        changePasswordBody: ChangePasswordBody(
          (builder) => builder
            ..currentPassword = currentPassword
            ..newPassword = newPassword,
        ),
      );

      return _isCurrentProfileSession(epoch, userId) &&
          requestId == _passwordRequestId;
    } catch (error) {
      if (_isCurrentProfileSession(epoch, userId)) {
        profileError = _profileFriendlyError(error, passwordOperation: true);
      }
      return false;
    } finally {
      if (_isCurrentProfileSession(epoch, userId) &&
          requestId == _passwordRequestId) {
        isChangingPassword = false;
        notifyListeners();
      }
    }
  }

  Future<bool> changeSecurityQuestion({
    required String currentPassword,
    required String securityQuestion,
    required String securityAnswer,
  }) async {
    final currentUser = user;
    if (status != AuthStatus.authenticated ||
        currentUser == null ||
        isChangingPassword) {
      return false;
    }

    isChangingPassword = true;
    profileError = null;
    notifyListeners();
    try {
      await _client.auth.changeSecurityQuestion(
        changeSecurityQuestionBody: ChangeSecurityQuestionBody(
          (builder) => builder
            ..currentPassword = currentPassword
            ..securityQuestion = securityQuestion
            ..securityAnswer = securityAnswer,
        ),
      );
      await refreshMe();
      return true;
    } catch (error) {
      profileError = _profileFriendlyError(error, passwordOperation: true);
      return false;
    } finally {
      isChangingPassword = false;
      notifyListeners();
    }
  }

  Future<bool> deleteAccount(String currentPassword) async {
    final currentUser = user;
    if (status != AuthStatus.authenticated ||
        currentUser == null ||
        currentPassword.isEmpty ||
        isDeletingAccount) {
      return false;
    }

    final epoch = _sessionEpoch;
    final userId = currentUser.id;
    isDeletingAccount = true;
    profileError = null;
    notifyListeners();

    try {
      await _client.dio.delete<void>(
        '/auth/account',
        data: {'currentPassword': currentPassword},
      );

      if (!_isCurrentProfileSession(epoch, userId)) return false;

      _sessionEpoch++;
      _profileRequestId++;
      _passwordRequestId++;
      isDeletingAccount = false;
      _token = null;
      user = null;
      status = AuthStatus.unauthenticated;
      try {
        await _storage.clear();
      } catch (_) {
        // Akun sudah terhapus di server; sesi memori tetap wajib ditutup.
      }
      notifyListeners();
      return true;
    } catch (error) {
      if (_isCurrentProfileSession(epoch, userId)) {
        profileError = _deleteAccountFriendlyError(error);
      }
      return false;
    } finally {
      if (_isCurrentProfileSession(epoch, userId) && isDeletingAccount) {
        isDeletingAccount = false;
        notifyListeners();
      }
    }
  }

  bool _isCurrentProfileSession(int epoch, int userId) {
    return epoch == _sessionEpoch &&
        status == AuthStatus.authenticated &&
        user?.id == userId;
  }

  String _profileFriendlyError(Object error, {bool passwordOperation = false}) {
    if (error is DioException) {
      if (error.response?.statusCode == 401) {
        return passwordOperation
            ? 'Password saat ini tidak sesuai.'
            : 'Sesi login berakhir. Silakan masuk kembali.';
      }
      if (error.response?.statusCode == 400 ||
          error.response?.statusCode == 422) {
        return passwordOperation
            ? 'Password belum memenuhi persyaratan keamanan.'
            : 'Data profil belum valid. Periksa kembali isian kamu.';
      }
      if (error.type == DioExceptionType.connectionError ||
          error.type == DioExceptionType.connectionTimeout) {
        return 'Tidak bisa terhubung ke server. Periksa koneksi internet kamu.';
      }
    }

    return passwordOperation
        ? 'Gagal mengubah password. Silakan coba lagi.'
        : 'Gagal memperbarui profil. Silakan coba lagi.';
  }

  String _deleteAccountFriendlyError(Object error) {
    if (error is DioException) {
      if (error.response?.statusCode == 401) {
        return 'Password saat ini tidak sesuai.';
      }
      if (error.response?.statusCode == 429) {
        return 'Terlalu banyak percobaan. Tunggu sebentar lalu coba lagi.';
      }
      if (error.type == DioExceptionType.connectionError ||
          error.type == DioExceptionType.connectionTimeout) {
        return 'Tidak bisa terhubung ke server. Periksa koneksi internet kamu.';
      }
    }
    return 'Gagal menghapus akun. Silakan coba lagi.';
  }

  /// Step 1 lupa password: ambil pertanyaan keamanan berdasar email.
  Future<SecurityQuestionResponse?> getSecurityQuestion(String email) async {
    return _runValue(() async {
      final response = await _client.auth.getForgotPasswordQuestion(
        forgotPasswordQuestionBody: ForgotPasswordQuestionBody(
          (b) => b..email = email.trim().toLowerCase(),
        ),
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
        verifySecurityAnswerBody: VerifySecurityAnswerBody(
          (b) => b
            ..email = email.trim().toLowerCase()
            ..securityAnswer = answer,
        ),
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
        resetPasswordBody: ResetPasswordBody(
          (b) => b
            ..resetToken = resetToken
            ..newPassword = newPassword,
        ),
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

  Future<T?> _runValue<T>(Future<T?> Function() action) async {
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
      if (e.type == DioExceptionType.connectionError ||
          e.type == DioExceptionType.connectionTimeout) {
        return 'Tidak bisa terhubung ke server. Periksa koneksi internet kamu.';
      }
      if (e.response?.statusCode == 401) {
        return 'Email atau password tidak sesuai.';
      }
      if (e.response?.statusCode == 429) {
        return 'Terlalu banyak percobaan. Tunggu sebentar lalu coba lagi.';
      }
      final responseData = e.response?.data;
      final responseMessage = responseData is Map<String, dynamic>
          ? responseData['error']
          : null;
      if ((e.response?.statusCode == 400 || e.response?.statusCode == 409) &&
          responseMessage is String &&
          responseMessage.isNotEmpty) {
        return responseMessage;
      }
      return 'Terjadi kesalahan. Silakan coba lagi.';
    }
    return 'Terjadi kesalahan. Silakan coba lagi.';
  }
}
