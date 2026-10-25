import 'dart:convert';
import 'package:login_jwt/models/auth_tokens_model.dart';
import 'package:login_jwt/models/user_model.dart';

// Conditionally import the web library using dart.library.js_interop
import 'package:login_jwt/services/web_storage_stub.dart'
    if (dart.library.js_interop) 'package:login_jwt/services/web_storage.dart';

class StorageService {
  static const String _keyAccessToken = 'access_token';
  static const String _keyUserData = 'user_data';

  // In-memory fallback for Native (Android/iOS/Windows) acting as a session
  String? _ramAccessToken;
  UserModel? _ramUser;

  StorageService();

  static Future<StorageService> getInstance() async {
    return StorageService();
  }

  Future<void> saveTokens(AuthTokensModel tokens) async {
    setWebSessionItem(_keyAccessToken, tokens.accessToken);
    _ramAccessToken = tokens.accessToken;
  }

  String? getAccessToken() {
    return getWebSessionItem(_keyAccessToken) ?? _ramAccessToken;
  }

  String? getRefreshToken() {
    return getWebSessionItem('refresh_token');
  }

  Future<void> saveUser(UserModel user) async {
    setWebSessionItem(_keyUserData, jsonEncode(user.toJson()));
    _ramUser = user;
  }

  UserModel? getUser() {
    final userJsonStr = getWebSessionItem(_keyUserData);
    if (userJsonStr != null && userJsonStr.isNotEmpty) {
      try {
        final Map<String, dynamic> userMap = jsonDecode(userJsonStr);
        return UserModel.fromJson(userMap);
      } catch (_) {
        return null;
      }
    }
    return _ramUser;
  }

  Future<void> clearAuth() async {
    removeWebSessionItem(_keyAccessToken);
    removeWebSessionItem(_keyUserData);
    _ramAccessToken = null;
    _ramUser = null;
  }
}
