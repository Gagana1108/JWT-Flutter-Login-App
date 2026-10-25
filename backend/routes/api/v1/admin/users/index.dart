import 'package:backend/src/services/user_repository.dart';
import 'package:backend/src/utils/json_response.dart';
import 'package:dart_frog/dart_frog.dart';

Future<Response> onRequest(RequestContext context) async {
  if (context.request.method != HttpMethod.get) {
    return JsonResponse.error(
      statusCode: 405,
      message: 'Method not allowed. Use GET.',
    );
  }

  try {
    final userRepository = context.read<UserRepository>();
    final users = await userRepository.getAllUsers();

    return JsonResponse.ok(
      message: 'Users retrieved successfully!',
      data: {
        'users': users.map((u) => u.toJson()).toList(),
      },
    );
  } catch (e) {
    return JsonResponse.internalServerError('Failed to fetch user list: $e');
  }
}
