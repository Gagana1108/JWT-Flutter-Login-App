import 'package:dart_frog/dart_frog.dart';

class JsonResponse {
  static Response ok({
    required String message,
    dynamic data,
    Map<String, Object>? headers,
  }) {
    return Response.json(
      body: {
        'success': true,
        'message': message,
        if (data != null) 'data': data,
      },
      headers: headers ?? {},
    );
  }

  static Response created({
    required String message,
    dynamic data,
    Map<String, Object>? headers,
  }) {
    return Response.json(
      statusCode: 201,
      body: {
        'success': true,
        'message': message,
        if (data != null) 'data': data,
      },
      headers: headers ?? {},
    );
  }

  static Response error({
    required int statusCode,
    required String message,
    Map<String, dynamic>? errors,
  }) {
    return Response.json(
      statusCode: statusCode,
      body: {
        'success': false,
        'message': message,
        if (errors != null) 'errors': errors,
      },
    );
  }

  static Response badRequest(String message, {Map<String, dynamic>? errors}) {
    return error(statusCode: 400, message: message, errors: errors);
  }

  static Response unauthorized(String message) {
    return error(statusCode: 401, message: message);
  }

  static Response forbidden(String message) {
    return error(statusCode: 403, message: message);
  }

  static Response notFound(String message) {
    return error(statusCode: 404, message: message);
  }

  static Response conflict(String message) {
    return error(statusCode: 409, message: message);
  }

  static Response internalServerError([
    String message = 'An unexpected server error occurred.',
  ]) {
    return error(statusCode: 500, message: message);
  }
}
