import 'dart:convert';
import 'package:backend/src/services/auth_service.dart';
import 'package:backend/src/utils/json_response.dart';
import 'package:dart_frog/dart_frog.dart';

Future<Response> onRequest(RequestContext context) async {
  if (context.request.method != HttpMethod.post) {
    return JsonResponse.error(
      statusCode: 405,
      message: 'Method not allowed. Use POST.',
    );
  }

  try {
    final bodyText = await context.request.body();
    if (bodyText.trim().isEmpty) {
      return JsonResponse.badRequest('Request body cannot be empty.');
    }

    final Map<String, dynamic> body;
    try {
      body = jsonDecode(bodyText) as Map<String, dynamic>;
    } catch (_) {
      return JsonResponse.badRequest('Invalid JSON payload format.');
    }

    final refreshToken = (body['refresh_token'] as String?)?.trim() ?? '';
    if (refreshToken.isEmpty) {
      return JsonResponse.badRequest('refresh_token is required.');
    }

    final authService = context.read<AuthService>();
    final newTokens = await authService.rotateRefreshToken(refreshToken);

    return JsonResponse.ok(
      message: 'Token refreshed successfully!',
      data: newTokens.toJson(),
    );
  } on AuthException catch (e) {
    return JsonResponse.error(
      statusCode: e.statusCode,
      message: e.message,
    );
  } catch (e) {
    return JsonResponse.internalServerError('Token refresh failed: ${e.toString()}');
  }
}
