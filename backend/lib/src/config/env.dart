import 'dart:io';
import 'package:dotenv/dotenv.dart';

class EnvConfig {
  static late final DotEnv _env;
  static bool _initialized = false;

  static void init() {
    if (_initialized) return;
    _env = DotEnv()..load(['.env']);
    _initialized = true;
  }

  static String get(String key, {String fallback = ''}) {
    if (!_initialized) init();
    return _env[key] ?? Platform.environment[key] ?? fallback;
  }

  static String get dbHost => get('DB_HOST', fallback: '127.0.0.1');
  static int get dbPort => int.parse(get('DB_PORT', fallback: '3306'));
  static String get dbName => get('DB_NAME', fallback: 'auth_db');
  static String get dbUser => get('DB_USER', fallback: 'root');
  static String get dbPassword => get('DB_PASSWORD', fallback: 'rootpassword');

  static String get jwtSecret => get(
        'JWT_SECRET',
        fallback: 'super_secret_jwt_key_change_me_in_production_123456789',
      );

  static int get accessExpirationMinutes => int.parse(
        get('JWT_ACCESS_EXPIRATION_MINUTES', fallback: '15'),
      );

  static int get refreshExpirationDays => int.parse(
        get('JWT_REFRESH_EXPIRATION_DAYS', fallback: '7'),
      );
}
