import 'dart:convert';
import 'package:backend/src/models/auth_response.dart';
import 'package:backend/src/services/auth_service.dart';
import 'package:backend/src/services/user_repository.dart';
import 'package:backend/src/utils/json_response.dart';
import 'package:backend/src/utils/validators.dart';
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

    final email = (body['email'] as String?)?.trim().toLowerCase() ?? '';
    final password = (body['password'] as String?) ?? '';

    final Map<String, String> fieldErrors = {};

    if (!Validators.isValidEmail(email)) {
      fieldErrors['email'] = 'Please enter a valid email address.';
    }

    if (password.isEmpty) {
      fieldErrors['password'] = 'Password is required.';
    }

    if (fieldErrors.isNotEmpty) {
      return JsonResponse.badRequest(
        'Invalid login input.',
        errors: fieldErrors,
      );
    }

    final userRepository = context.read<UserRepository>();
    final authService = context.read<AuthService>();

    final user = await userRepository.findByEmail(email);
    if (user == null || user.passwordHash == null) {
      return JsonResponse.unauthorized('Invalid email or password.');
    }

    final isValidPassword = authService.verifyPassword(password, user.passwordHash!);
    if (!isValidPassword) {
      return JsonResponse.unauthorized('Invalid email or password.');
    }

    final tokens = await authService.issueTokens(user);
    final authResponse = AuthResponse(user: user, tokens: tokens);

    return JsonResponse.ok(
      message: 'Login successful!',
      data: authResponse.toJson(),
    );
  } catch (e) {
    return JsonResponse.internalServerError('Failed to process login: ${e.toString()}');
  }
}
