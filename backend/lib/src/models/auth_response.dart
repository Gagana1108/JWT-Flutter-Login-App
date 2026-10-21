import 'package:backend/src/models/user.dart';

class AuthTokens {
  final String accessToken;
  final String refreshToken;
  final String tokenType;
  final int expiresInSeconds;

  AuthTokens({
    required this.accessToken,
    required this.refreshToken,
    this.tokenType = 'Bearer',
    required this.expiresInSeconds,
  });

  Map<String, dynamic> toJson() {
    return {
      'access_token': accessToken,
      'refresh_token': refreshToken,
      'token_type': tokenType,
      'expires_in': expiresInSeconds,
    };
  }
}

class AuthResponse {
  final User user;
  final AuthTokens tokens;

  AuthResponse({
    required this.user,
    required this.tokens,
  });

  Map<String, dynamic> toJson() {
    return {
      'user': user.toJson(),
      'tokens': tokens.toJson(),
    };
  }
}
