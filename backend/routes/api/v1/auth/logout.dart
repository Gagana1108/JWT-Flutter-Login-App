import 'package:backend/src/utils/json_response.dart';
import 'package:dart_frog/dart_frog.dart';

Future<Response> onRequest(RequestContext context) async {
  if (context.request.method != HttpMethod.post) {
    return JsonResponse.error(
      statusCode: 405,
      message: 'Method not allowed. Use POST.',
    );
  }

  return JsonResponse.ok(
    message: 'Logged out successfully.',
  );
}
