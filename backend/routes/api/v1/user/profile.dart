import 'package:backend/src/models/user.dart';
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
    final user = context.read<User>();
    return JsonResponse.ok(
      message: 'User profile retrieved successfully!',
      data: {
        'user': user.toJson(),
      },
    );
  } catch (e) {
    return JsonResponse.unauthorized('User session invalid or expired.');
  }
}
