import 'package:backend/src/utils/json_response.dart';
import 'package:dart_frog/dart_frog.dart';

Future<Response> onRequest(RequestContext context) async {
  return JsonResponse.error(
    statusCode: 410,
    message: 'Refresh token endpoint is deprecated.',
  );
}
