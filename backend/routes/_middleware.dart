import 'package:backend/src/config/env.dart';
import 'package:backend/src/db/mysql_client.dart';
import 'package:backend/src/services/auth_service.dart';
import 'package:backend/src/services/token_repository.dart';
import 'package:backend/src/services/user_repository.dart';
import 'package:backend/src/utils/json_response.dart';
import 'package:dart_frog/dart_frog.dart';

final DatabaseClient _dbClient = DatabaseClient();
final UserRepository _userRepository = UserRepository(_dbClient);
final TokenRepository _tokenRepository = TokenRepository(_dbClient);
final AuthService _authService = AuthService(
  userRepository: _userRepository,
  tokenRepository: _tokenRepository,
);

Handler middleware(Handler handler) {
  EnvConfig.init();

  return (context) async {
    // 1. Handle CORS Preflight (OPTIONS)
    if (context.request.method == HttpMethod.options) {
      return Response(
        statusCode: 200,
        headers: _corsHeaders,
      );
    }

    try {
      // 2. Provide dependencies down the context chain
      final response = await handler(
        context
            .provide<DatabaseClient>(() => _dbClient)
            .provide<UserRepository>(() => _userRepository)
            .provide<TokenRepository>(() => _tokenRepository)
            .provide<AuthService>(() => _authService),
      );

      // 3. Attach CORS headers to response
      return response.copyWith(
        headers: {
          ...response.headers,
          ..._corsHeaders,
        },
      );
    } catch (e) {
      return JsonResponse.internalServerError('Server error: ${e.toString()}');
    }
  };
}

const Map<String, String> _corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Methods': 'GET, POST, PUT, DELETE, OPTIONS',
  'Access-Control-Allow-Headers': 'Origin, Content-Type, Authorization, Accept, X-Requested-With',
};
