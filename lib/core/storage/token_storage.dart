import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:trade_pilot_api_client/trade_pilot_api_client.dart';

/// Menyimpan session token (Bearer) + data user secara aman di device.
/// Setara dengan `AuthContext.tsx` pada app Expo (`artifacts/mobile`)
/// tapi memakai flutter_secure_storage, bukan AsyncStorage.
class TokenStorage {
  TokenStorage()
      : _storage = const FlutterSecureStorage(
          aOptions: AndroidOptions(encryptedSharedPreferences: true),
        );

  final FlutterSecureStorage _storage;

  static const _tokenKey = 'trade_pilot_token';
  static const _userKey = 'trade_pilot_user';

  Future<String?> readToken() => _storage.read(key: _tokenKey);

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
        'createdAt': user.createdAt.toIso8601String(),
      };
}
