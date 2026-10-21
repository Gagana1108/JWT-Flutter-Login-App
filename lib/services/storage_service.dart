import 'dart:convert';
import 'package:login_jwt/models/auth_tokens_model.dart';
import 'package:login_jwt/models/user_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

class StorageService {
  static const String _keyAccessToken = 'access_token';
  static const String _keyRefreshToken = 'refresh_token';
  static const String _keyUserData = 'user_data';

  final SharedPreferences _prefs;

  StorageService(this._prefs);

  static Future<StorageService> getInstance() async {
    final prefs = await SharedPreferences.getInstance();
    return StorageService(prefs);
  }

  Future<void> saveTokens(AuthTokensModel tokens) async {
    await _prefs.setString(_keyAccessToken, tokens.accessToken);
    await _prefs.setString(_keyRefreshToken, tokens.refreshToken);
  }

  String? getAccessToken() {
    return _prefs.getString(_keyAccessToken);
  }

  String? getRefreshToken() {
    return _prefs.getString(_keyRefreshToken);
  }

  Future<void> saveUser(UserModel user) async {
    await _prefs.setString(_keyUserData, jsonEncode(user.toJson()));
  }

  UserModel? getUser() {
    final userJsonStr = _prefs.getString(_keyUserData);
    if (userJsonStr == null || userJsonStr.isEmpty) return null;
    try {
      final Map<String, dynamic> userMap = jsonDecode(userJsonStr);
      return UserModel.fromJson(userMap);
    } catch (_) {
      return null;
    }
  }

  Future<void> clearAuth() async {
    await _prefs.remove(_keyAccessToken);
    await _prefs.remove(_keyRefreshToken);
    await _prefs.remove(_keyUserData);
  }
}
