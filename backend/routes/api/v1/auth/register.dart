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

    final name = (body['name'] as String?)?.trim() ?? '';
    final email = (body['email'] as String?)?.trim().toLowerCase() ?? '';
    final password = (body['password'] as String?) ?? '';

    final fieldErrors = <String, String>{};

    if (!Validators.isValidName(name)) {
      fieldErrors['name'] = 'Name must be between 2 and 100 characters long.';
    }

    if (!Validators.isValidEmail(email)) {
      fieldErrors['email'] = 'Please enter a valid email address.';
    }

    final passwordError = Validators.validatePassword(password);
    if (passwordError != null) {
      fieldErrors['password'] = passwordError;
    }

    if (fieldErrors.isNotEmpty) {
      return JsonResponse.badRequest(
        'Validation failed for registration input.',
        errors: fieldErrors,
      );
    }

    final userRepository = context.read<UserRepository>();
    final authService = context.read<AuthService>();

    final existingUser = await userRepository.findByEmail(email);
    if (existingUser != null) {
      return JsonResponse.conflict(
        'An account with this email address already exists.',
      );
    }

    final passwordHash = authService.hashPassword(password);
    final user = await userRepository.createUser(
      name: name,
      email: email,
      passwordHash: passwordHash,
    );

    final tokens = await authService.issueTokens(user);
    final authResponse = AuthResponse(user: user, tokens: tokens);

    return JsonResponse.created(
      message: 'Registration successful!',
      data: authResponse.toJson(),
    );
  } catch (e) {
    if (e.toString().contains('1062')) {
      return JsonResponse.conflict(
        'An account with this email address already exists.',
      );
    }
    return JsonResponse.internalServerError('Failed to process registration: $e');
  }
}
