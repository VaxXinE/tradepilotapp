import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:trade_pilot_api_client/trade_pilot_api_client.dart';

/// Menyimpan session token (Bearer) + data user secara aman di device.
/// Setara dengan `AuthContext.tsx` pada app Expo (`artifacts/mobile`)
/// tapi memakai flutter_secure_storage, bukan AsyncStorage.
class TokenStorage {
  TokenStorage()
    : _storage = const FlutterSecureStorage(
        // No `encryptedSharedPreferences` here: the Jetpack Security backend is
        // deprecated and the flag is ignored as of flutter_secure_storage 10.
        // Data written by 9.x is migrated to the AES-GCM cipher storage on first
        // access (`migrateOnAlgorithmChange` defaults to true), so existing
        // sessions survive the upgrade.
        aOptions: AndroidOptions(),
      );

  final FlutterSecureStorage _storage;

  static const _tokenKey = 'trade_pilot_token';
  static const _userKey = 'trade_pilot_user';
  static const _biometricLockKey = 'trade_pilot_biometric_lock';

  /// Written by versions up to 1.0.1, which persisted the user's plaintext
  /// password to power "remember me" and biometric sign-in. Never written
  /// again — only deleted. See [purgeLegacyCredentials].
  static const _legacyPasswordKey = 'remembered_login_password';

  Future<String?> readToken() => _storage.read(key: _tokenKey);

  /// Removes the plaintext password that older builds left on this device.
  ///
  /// A password cannot be revoked the way a session token can, so it is
  /// deleted unconditionally on every launch rather than behind a one-shot
  /// flag: a flag that failed to persist once would strand the secret here
  /// forever. Deleting an absent key is a no-op, so the cost is one storage
  /// call per launch.
  Future<void> purgeLegacyCredentials() async {
    await _storage.delete(key: _legacyPasswordKey);
  }

  Future<bool> readBiometricLockEnabled() async {
    return await _storage.read(key: _biometricLockKey) == 'true';
  }

  Future<void> setBiometricLockEnabled(bool enabled) async {
    if (enabled) {
      await _storage.write(key: _biometricLockKey, value: 'true');
    } else {
      await _storage.delete(key: _biometricLockKey);
    }
  }

  Future<void> saveSession({required String token, required User user}) async {
    await _storage.write(key: _tokenKey, value: token);
    await _storage.write(key: _userKey, value: jsonEncode(_userToMap(user)));
  }

  Future<void> saveUser(User user) async {
    await _storage.write(key: _userKey, value: jsonEncode(_userToMap(user)));
  }

  Future<Map<String, dynamic>?> readUserMap() async {
    final raw = await _storage.read(key: _userKey);
    if (raw == null) return null;
    return jsonDecode(raw) as Map<String, dynamic>;
  }

  /// Ends the session. The biometric-lock preference deliberately survives:
  /// it describes how this person wants the app to behave, not the session
  /// itself, and a security setting that silently switched itself off after a
  /// logout would be worse than useless.
  Future<void> clear() async {
    await _storage.delete(key: _tokenKey);
    await _storage.delete(key: _userKey);
  }

  Map<String, dynamic> _userToMap(User user) => {
    'id': user.id,
    'email': user.email,
    'displayName': user.displayName,
    'avatarUrl': user.avatarUrl,
    'role': user.role.name,
    'selectedMode': user.selectedMode.name,
    'themePreference': user.themePreference.name,
    'securityQuestion': user.securityQuestion,
    'onboardingCompleted': user.onboardingCompleted,
    if (user.createdAt != null) 'createdAt': user.createdAt!.toIso8601String(),
  };
}
