import 'package:backend/src/models/user.dart';

class AuthTokens {
  final String accessToken;
  final String tokenType;
  final int expiresInSeconds;

  AuthTokens({
    required this.accessToken,
    this.tokenType = 'Bearer',
    required this.expiresInSeconds,
  });

  Map<String, dynamic> toJson() {
    return {
      'access_token': accessToken,
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
