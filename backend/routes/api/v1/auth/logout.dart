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
    if (bodyText.trim().isNotEmpty) {
      try {
        final body = jsonDecode(bodyText) as Map<String, dynamic>;
        final refreshToken = (body['refresh_token'] as String?)?.trim() ?? '';
        if (refreshToken.isNotEmpty) {
          final authService = context.read<AuthService>();
          await authService.logout(refreshToken);
        }
      } catch (_) {
        // Continue logout even if JSON body parsing fails
      }
    }

    return JsonResponse.ok(
      message: 'Logged out successfully.',
    );
  } catch (e) {
    return JsonResponse.internalServerError('Logout processing error: ${e.toString()}');
  }
}
