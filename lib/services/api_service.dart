import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:login_jwt/config/api_config.dart';
import 'package:login_jwt/services/storage_service.dart';

class ApiException implements Exception {
  final String message;
  final int statusCode;
  final Map<String, dynamic>? errors;

  ApiException(this.message, {this.statusCode = 400, this.errors});

  @override
  String toString() => message;
}

class ApiService {
  final StorageService storageService;

  ApiService(this.storageService);

  Map<String, String> _buildHeaders({String? token, bool requiresAuth = false}) {
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    if (requiresAuth) {
      final activeToken = token ?? storageService.getAccessToken();
      if (activeToken != null && activeToken.isNotEmpty) {
        headers['Authorization'] = 'Bearer $activeToken';
      }
    }
    return headers;
  }

  Future<dynamic> post(
    String url, {
    Map<String, dynamic>? body,
    bool requiresAuth = false,
  }) async {
    final uri = Uri.parse(url);
    final headers = _buildHeaders(requiresAuth: requiresAuth);

    try {
      final response = await http
          .post(
            uri,
            headers: headers,
            body: body != null ? jsonEncode(body) : null,
          )
          .timeout(ApiConfig.timeout);

      return await _handleResponse(
        response,
        requiresAuth: requiresAuth,
      );
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(
        'Network error: Unable to connect to server ($e). Please check backend connection.',
        statusCode: 0,
      );
    }
  }

  Future<dynamic> get(
    String url, {
    bool requiresAuth = true,
  }) async {
    final uri = Uri.parse(url);
    final headers = _buildHeaders(requiresAuth: requiresAuth);

    try {
      final response = await http
          .get(uri, headers: headers)
          .timeout(ApiConfig.timeout);

      return await _handleResponse(
        response,
        requiresAuth: requiresAuth,
      );
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(
        'Network error: Unable to connect to server ($e). Please check backend connection.',
        statusCode: 0,
      );
    }
  }

  Future<dynamic> patch(
    String url, {
    Map<String, dynamic>? body,
    bool requiresAuth = true,
  }) async {
    final uri = Uri.parse(url);
    final headers = _buildHeaders(requiresAuth: requiresAuth);

    try {
      final response = await http
          .patch(
            uri,
            headers: headers,
            body: body != null ? jsonEncode(body) : null,
          )
          .timeout(ApiConfig.timeout);

      return await _handleResponse(
        response,
        requiresAuth: requiresAuth,
      );
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(
        'Network error: Unable to connect to server ($e). Please check backend connection.',
        statusCode: 0,
      );
    }
  }

  Future<dynamic> _handleResponse(
    http.Response response, {
    bool requiresAuth = false,
  }) async {
    final statusCode = response.statusCode;
    Map<String, dynamic> responseData = {};

    try {
      if (response.body.isNotEmpty) {
        responseData = jsonDecode(response.body) as Map<String, dynamic>;
      }
    } catch (_) {
      throw ApiException(
        'Server returned invalid response format.',
        statusCode: statusCode,
      );
    }

    if (statusCode == 200 || statusCode == 201) {
      return responseData;
    }

    if (statusCode == 400) {
      throw ApiException(
        responseData['message'] as String? ??
            'Bad request. Please check the submitted data.',
        statusCode: 400,
      );
    }

    if (statusCode == 401) {
      await storageService.clearAuth();
      throw ApiException(
        'Session expired. Please log in again.',
        statusCode: 401,
      );
    }

    if (statusCode == 403) {
      throw ApiException(
        responseData['message'] as String? ??
            'Access denied. You do not have permission to perform this action.',
        statusCode: 403,
      );
    }

    if (statusCode == 409) {
      throw ApiException(
        responseData['message'] as String? ??
            'Email or username already exists.',
        statusCode: 409,
      );
    }

    if (statusCode == 500) {
      throw ApiException(
        responseData['message'] as String? ??
            'Internal server error. Please try again later.',
        statusCode: 500,
      );
    }

    if (statusCode == 503) {
      throw ApiException(
        responseData['message'] as String? ??
            'Service temporarily unavailable. Please try again later.',
        statusCode: 503,
      );
    }

    final message = responseData['message'] as String? ??
        'An error occurred (HTTP $statusCode).';
    final errors = responseData['errors'] as Map<String, dynamic>?;

    throw ApiException(message, statusCode: statusCode, errors: errors);
  }
}
