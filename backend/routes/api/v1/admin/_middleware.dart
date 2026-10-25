import 'package:backend/src/models/user.dart';
import 'package:backend/src/services/auth_service.dart';
import 'package:backend/src/services/user_repository.dart';
import 'package:backend/src/utils/json_response.dart';
import 'package:dart_frog/dart_frog.dart';

Handler middleware(Handler handler) {
  return (context) async {
    if (context.request.method == HttpMethod.options) {
      return handler(context);
    }

    final authHeader = context.request.headers['authorization'] ??
        context.request.headers['Authorization'];

    if (authHeader == null || !authHeader.startsWith('Bearer ')) {
      return JsonResponse.unauthorized(
        'Access denied. Missing or invalid Authorization Bearer header.',
      );
    }

    final token = authHeader.substring(7).trim();
    if (token.isEmpty) {
      return JsonResponse.unauthorized('Access denied. Empty token provided.');
    }

    final authService = context.read<AuthService>();
    final userRepository = context.read<UserRepository>();

    try {
      final payload = authService.verifyAccessToken(token);
      final userIdStr = payload['sub'] as String?;

      if (userIdStr == null) {
        return JsonResponse.unauthorized('Invalid token payload structure.');
      }

      final userId = int.tryParse(userIdStr);
      if (userId == null) {
        return JsonResponse.unauthorized('Invalid user ID in token payload.');
      }

      // Fetch latest user state from database to verify active role
      final user = await userRepository.findById(userId);
      if (user == null) {
        return JsonResponse.unauthorized('Authenticated user account no longer exists.');
      }

      // RBAC Enforcement: Verify admin role
      if (user.role != 'admin') {
        return JsonResponse.forbidden(
          'Access denied. Administrator privileges are required to access this resource.',
        );
      }

      return await handler(context.provide<User>(() => user));
    } on AuthException catch (e) {
      return JsonResponse.unauthorized(e.message);
    } catch (e) {
      return JsonResponse.unauthorized('Authentication verification failed.');
    }
  };
}
