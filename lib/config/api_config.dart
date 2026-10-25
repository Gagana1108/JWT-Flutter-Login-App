import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;

class ApiConfig {
  /// Base API URL.
  /// Uses http://localhost:8080 for Web, Windows, macOS, Linux, and iOS simulator.
  /// Uses http://10.0.2.2:8080 for Android Emulator.
  static String get baseUrl {
    if (kIsWeb) {
      return 'http://localhost:8080';
    }
    if (Platform.isAndroid) {
      return 'http://10.0.2.2:8080';
    }
    return 'http://localhost:8080';
  }

  // Auth endpoints
  static String get registerUrl => '$baseUrl/api/v1/auth/register';
  static String get loginUrl => '$baseUrl/api/v1/auth/login';
  static String get logoutUrl => '$baseUrl/api/v1/auth/logout';

  // User endpoints
  static String get userProfileUrl => '$baseUrl/api/v1/user/profile';

  // Admin endpoints
  static String get adminUsersUrl => '$baseUrl/api/v1/admin/users';
  static String adminUserRoleUrl(int id) => '$baseUrl/api/v1/admin/users/$id/role';

  static const Duration timeout = Duration(seconds: 15);
}
