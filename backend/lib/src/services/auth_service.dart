import 'dart:convert';
import 'package:backend/src/config/env.dart';
import 'package:backend/src/models/auth_response.dart';
import 'package:backend/src/models/user.dart';
import 'package:backend/src/services/token_repository.dart';
import 'package:backend/src/services/user_repository.dart';
import 'package:bcrypt/bcrypt.dart';
import 'package:crypto/crypto.dart';
import 'package:dart_jsonwebtoken/dart_jsonwebtoken.dart';
import 'package:uuid/uuid.dart';

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

  String hashToken(String rawToken) {
    return sha256.convert(utf8.encode(rawToken)).toString();
  }

  String _generateAccessToken(User user) {
    final jwt = JWT(
      {
        'sub': user.id.toString(),
        'email': user.email,
        'name': user.name,
      },
      issuer: 'login_jwt_backend',
    );

    return jwt.sign(
      SecretKey(EnvConfig.jwtSecret),
      expiresIn: Duration(minutes: EnvConfig.accessExpirationMinutes),
    );
  }

  Future<String> _generateAndSaveRefreshToken(User user) async {
    final rawRefreshToken = '${const Uuid().v4()}-${const Uuid().v4()}';
    final tokenHash = hashToken(rawRefreshToken);
    final expiresAt = DateTime.now().add(
      Duration(days: EnvConfig.refreshExpirationDays),
    );

    await tokenRepository.saveRefreshToken(
      userId: user.id,
      tokenHash: tokenHash,
      expiresAt: expiresAt,
    );

    return rawRefreshToken;
  }

  Future<AuthTokens> issueTokens(User user) async {
    final accessToken = _generateAccessToken(user);
    final refreshToken = await _generateAndSaveRefreshToken(user);

    return AuthTokens(
      accessToken: accessToken,
      refreshToken: refreshToken,
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

  Future<AuthTokens> rotateRefreshToken(String rawRefreshToken) async {
    final tokenHash = hashToken(rawRefreshToken);
    final storedToken = await tokenRepository.findTokenByHash(tokenHash);

    if (storedToken == null) {
      throw AuthException('Invalid refresh token', statusCode: 401);
    }

    if (storedToken.revoked) {
      // Reuse detected - revoke all tokens for this user for security
      await tokenRepository.revokeAllUserTokens(storedToken.userId);
      throw AuthException(
        'Revoked refresh token presented. Security alert: all user sessions terminated.',
        statusCode: 401,
      );
    }

    if (DateTime.now().isAfter(storedToken.expiresAt)) {
      await tokenRepository.revokeToken(tokenHash);
      throw AuthException('Refresh token has expired', statusCode: 401);
    }

    // Revoke old refresh token (Rotation)
    await tokenRepository.revokeToken(tokenHash);

    // Get user
    final user = await userRepository.findById(storedToken.userId);
    if (user == null) {
      throw AuthException('User associated with token no longer exists', statusCode: 404);
    }

    // Issue new pair of access and refresh tokens
    return issueTokens(user);
  }

  Future<void> logout(String rawRefreshToken) async {
    final tokenHash = hashToken(rawRefreshToken);
    await tokenRepository.revokeToken(tokenHash);
  }
}
