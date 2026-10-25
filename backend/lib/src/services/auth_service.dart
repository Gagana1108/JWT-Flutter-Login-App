import 'package:backend/src/config/env.dart';
import 'package:backend/src/models/auth_response.dart';
import 'package:backend/src/models/user.dart';
import 'package:backend/src/services/token_repository.dart';
import 'package:backend/src/services/user_repository.dart';
import 'package:bcrypt/bcrypt.dart';
import 'package:dart_jsonwebtoken/dart_jsonwebtoken.dart';

class AuthException implements Exception {
  final String message;
  final int statusCode;

  AuthException(this.message, {this.statusCode = 400});

  @override
  String toString() => message;
}

class AuthService {
  final UserRepository userRepository;
  final TokenRepository tokenRepository;

  AuthService({
    required this.userRepository,
    required this.tokenRepository,
  });

  String hashPassword(String password) {
    return BCrypt.hashpw(password, BCrypt.gensalt());
  }

  bool verifyPassword(String password, String hashedPassword) {
    try {
      return BCrypt.checkpw(password, hashedPassword);
    } catch (_) {
      return false;
    }
  }

  String _generateAccessToken(User user) {
    final jwt = JWT(
      {
        'sub': user.id.toString(),
        'email': user.email,
        'name': user.name,
        'role': user.role,
      },
      issuer: 'login_jwt_backend',
    );

    return jwt.sign(
      SecretKey(EnvConfig.jwtSecret),
      expiresIn: Duration(minutes: EnvConfig.accessExpirationMinutes),
    );
  }

  Future<AuthTokens> issueTokens(User user) async {
    final accessToken = _generateAccessToken(user);

    return AuthTokens(
      accessToken: accessToken,
      expiresInSeconds: EnvConfig.accessExpirationMinutes * 60,
    );
  }

  Map<String, dynamic> verifyAccessToken(String token) {
    try {
      final jwt = JWT.verify(token, SecretKey(EnvConfig.jwtSecret));
      return Map<String, dynamic>.from(jwt.payload as Map);
    } on JWTExpiredException {
      throw AuthException('Access token has expired', statusCode: 401);
    } on JWTUndefinedException catch (e) {
      throw AuthException('Invalid access token: ${e.message}', statusCode: 401);
    } catch (e) {
      throw AuthException('Invalid access token signature', statusCode: 401);
    }
  }
}
