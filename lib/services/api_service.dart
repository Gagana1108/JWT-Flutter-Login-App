import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:login_jwt/config/api_config.dart';
import 'package:login_jwt/models/auth_tokens_model.dart';
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

  Map<String, String> _buildHeaders({String? token}) {
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    final activeToken = token ?? storageService.getAccessToken();
    if (activeToken != null && activeToken.isNotEmpty) {
      headers['Authorization'] = 'Bearer $activeToken';
    }
    return headers;
  }

  Future<dynamic> post(
    String url, {
    Map<String, dynamic>? body,
    bool requiresAuth = false,
  }) async {
    final uri = Uri.parse(url);
    final headers = _buildHeaders();

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
        retryAction: () => post(url, body: body, requiresAuth: requiresAuth),
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
    final headers = _buildHeaders();

    try {
      final response = await http
          .get(uri, headers: headers)
          .timeout(ApiConfig.timeout);

      return await _handleResponse(
        response,
        retryAction: () => get(url, requiresAuth: requiresAuth),
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
    required Future<dynamic> Function() retryAction,
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

    if (statusCode >= 200 && statusCode < 300) {
      return responseData;
    }

    // 401 Unauthorized handling & Auto Token Refresh
    if (statusCode == 401 && requiresAuth) {
      final refreshed = await attemptTokenRefresh();
      if (refreshed) {
        // Retry original request with newly saved access token
        return await retryAction();
      } else {
        await storageService.clearAuth();
        throw ApiException(
          'Session expired. Please log in again.',
          statusCode: 401,
        );
      }
    }

    final message = responseData['message'] as String? ??
        'An error occurred (HTTP $statusCode).';
    final errors = responseData['errors'] as Map<String, dynamic>?;

    throw ApiException(message, statusCode: statusCode, errors: errors);
  }

  Future<bool> attemptTokenRefresh() async {
    // Step 1: Fetch the stored Refresh Token from local storage
    final refreshToken = storageService.getRefreshToken();
    if (refreshToken == null || refreshToken.isEmpty) return false;

    try {
      // Step 2: Send the Refresh Token to the backend server
      final response = await http
          .post(
        Uri.parse(ApiConfig.refreshUrl), // http://10.0.2.2:8080/api/v1/auth/refresh
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'refresh_token': refreshToken}),
      )
          .timeout(ApiConfig.timeout);

      // Step 3: Check if the backend accepted the Refresh Token
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;

        if (data['success'] == true && data['data'] != null) {
          // Step 4: Parse the NEW tokens sent by the backend
          final newTokens = AuthTokensModel.fromJson(
            data['data'] as Map<String, dynamic>,
          );

          // Step 5: Save the NEW Access Token & NEW Refresh Token to phone storage
          await storageService.saveTokens(newTokens);
          return true; // Token refresh succeeded!
        }
      }
    } catch (_) {
      // Network or server error during refresh
    }

    // Step 6: If refresh failed (e.g., Refresh Token expired after 7 days)
    await storageService.clearAuth(); // Wipe all local user data
    return false; // Token refresh failed!
  }
}
