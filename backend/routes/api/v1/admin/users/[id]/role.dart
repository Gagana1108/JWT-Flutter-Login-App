import 'dart:convert';
import 'package:backend/src/models/user.dart';
import 'package:backend/src/services/user_repository.dart';
import 'package:backend/src/utils/json_response.dart';
import 'package:dart_frog/dart_frog.dart';

Future<Response> onRequest(RequestContext context, String id) async {
  if (context.request.method != HttpMethod.patch) {
    return JsonResponse.error(
      statusCode: 405,
      message: 'Method not allowed. Use PATCH.',
    );
  }

  final targetUserId = int.tryParse(id);
  if (targetUserId == null) {
    return JsonResponse.badRequest('Invalid user ID provided in route URL.');
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

    final newRole = (body['role'] as String?)?.trim().toLowerCase() ?? '';
    if (newRole != 'admin' && newRole != 'user') {
      return JsonResponse.badRequest(
        'Invalid role specified. Role must be either "admin" or "user".',
        errors: {
          'role': 'Allowed values are "admin" or "user".',
        },
      );
    }

    final currentUser = context.read<User>();
    if (currentUser.id == targetUserId && newRole != 'admin') {
      return JsonResponse.badRequest(
        'Administrators cannot revoke their own admin privileges.',
      );
    }

    final userRepository = context.read<UserRepository>();
    final existingTargetUser = await userRepository.findById(targetUserId);

    if (existingTargetUser == null) {
      return JsonResponse.notFound(
        'Target user with ID #$targetUserId does not exist.',
      );
    }

    final updatedUser = await userRepository.updateUserRole(
      id: targetUserId,
      role: newRole,
    );

    return JsonResponse.ok(
      message: 'User role updated successfully to "$newRole"!',
      data: {
        'user': updatedUser?.toJson(),
      },
    );
  } catch (e) {
    return JsonResponse.internalServerError('Failed to update user role: $e');
  }
}
