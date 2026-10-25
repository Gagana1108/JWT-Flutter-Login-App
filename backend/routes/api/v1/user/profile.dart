import 'dart:convert';
import 'package:backend/src/models/user.dart';
import 'package:backend/src/services/user_repository.dart';
import 'package:backend/src/utils/json_response.dart';
import 'package:backend/src/utils/validators.dart';
import 'package:dart_frog/dart_frog.dart';

Future<Response> onRequest(RequestContext context) async {
  final user = context.read<User>();

  if (context.request.method == HttpMethod.get) {
    return JsonResponse.ok(
      message: 'User profile retrieved successfully!',
      data: {
        'user': user.toJson(),
      },
    );
  }

  if (context.request.method == HttpMethod.patch) {
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
      if (!Validators.isValidName(name)) {
        return JsonResponse.badRequest(
          'Validation failed for profile update.',
          errors: {'name': 'Name must be between 2 and 100 characters long.'},
        );
      }

      final userRepository = context.read<UserRepository>();
      final updatedUser = await userRepository.updateUserProfile(
        id: user.id,
        name: name,
      );

      if (updatedUser == null) {
        return JsonResponse.notFound('User profile not found.');
      }

      return JsonResponse.ok(
        message: 'Profile updated successfully!',
        data: {
          'user': updatedUser.toJson(),
        },
      );
    } catch (e) {
      return JsonResponse.internalServerError('Failed to update profile: $e');
    }
  }

  return JsonResponse.error(
    statusCode: 405,
    message: 'Method not allowed. Use GET or PATCH.',
  );
}
