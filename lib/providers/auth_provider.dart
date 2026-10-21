import 'package:flutter/material.dart';
import 'package:login_jwt/config/api_config.dart';
import 'package:login_jwt/models/auth_tokens_model.dart';
import 'package:login_jwt/models/user_model.dart';
import 'package:login_jwt/services/api_service.dart';
import 'package:login_jwt/services/storage_service.dart';

enum AuthStatus { initial, authenticated, unauthenticated }

class AuthProvider extends ChangeNotifier {
  final StorageService storageService;
  late final ApiService apiService;

  AuthStatus _status = AuthStatus.initial;
  UserModel? _currentUser;
  bool _isLoading = false;
  String? _errorMessage;
  String? _successMessage;

  AuthProvider(this.storageService) {
    apiService = ApiService(storageService);
    checkAuthStatus();
  }

  AuthStatus get status => _status;
  UserModel? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String? get successMessage => _successMessage;

  void clearMessages() {
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();
  }

  Future<void> checkAuthStatus() async {
    final accessToken = storageService.getAccessToken();
    final cachedUser = storageService.getUser();

    if (accessToken == null || accessToken.isEmpty) {
      _status = AuthStatus.unauthenticated;
      notifyListeners();
      return;
    }

    if (cachedUser != null) {
      _currentUser = cachedUser;
      _status = AuthStatus.authenticated;
      notifyListeners();
    }

    // Validate token with live backend profile request
    await fetchUserProfile(silent: true);
  }

  Future<bool> login(String email, String password) async {
    _isLoading = true;
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();

    try {
      final response = await apiService.post(
        ApiConfig.loginUrl,
        body: {
          'email': email,
          'password': password,
        },
      );

      final data = response['data'] as Map<String, dynamic>;
      final user = UserModel.fromJson(data['user'] as Map<String, dynamic>);
      final tokens = AuthTokensModel.fromJson(data['tokens'] as Map<String, dynamic>);

      await storageService.saveTokens(tokens);
      await storageService.saveUser(user);

      _currentUser = user;
      _status = AuthStatus.authenticated;
      _successMessage = 'Login successful!';
      _isLoading = false;
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      _errorMessage = e.message;
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _errorMessage = 'An unexpected error occurred during login: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> register(String name, String email, String password) async {
    _isLoading = true;
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();

    try {
      final response = await apiService.post(
        ApiConfig.registerUrl,
        body: {
          'name': name,
          'email': email,
          'password': password,
        },
      );

      final data = response['data'] as Map<String, dynamic>;
      final user = UserModel.fromJson(data['user'] as Map<String, dynamic>);
      final tokens = AuthTokensModel.fromJson(data['tokens'] as Map<String, dynamic>);

      await storageService.saveTokens(tokens);
      await storageService.saveUser(user);

      _currentUser = user;
      _status = AuthStatus.authenticated;
      _successMessage = 'Account created successfully!';
      _isLoading = false;
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      _errorMessage = e.message;
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _errorMessage = 'An unexpected error occurred during registration: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> fetchUserProfile({bool silent = false}) async {
    if (!silent) {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();
    }

    try {
      final response = await apiService.get(
        ApiConfig.userProfileUrl,
        requiresAuth: true,
      );

      final data = response['data'] as Map<String, dynamic>;
      final user = UserModel.fromJson(data['user'] as Map<String, dynamic>);

      await storageService.saveUser(user);
      _currentUser = user;
      _status = AuthStatus.authenticated;
      if (!silent) {
        _successMessage = 'Profile updated successfully!';
      }
    } on ApiException catch (e) {
      if (e.statusCode == 401) {
        await storageService.clearAuth();
        _currentUser = null;
        _status = AuthStatus.unauthenticated;
      } else if (!silent) {
        _errorMessage = e.message;
      }
    } catch (e) {
      if (!silent) {
        _errorMessage = 'Failed to load profile: $e';
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> refreshTokensManually() async {
    _isLoading = true;
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();

    final success = await apiService.attemptTokenRefresh();
    if (success) {
      _successMessage = 'Tokens rotated successfully!';
    } else {
      _errorMessage = 'Failed to rotate refresh token. Session expired.';
      _status = AuthStatus.unauthenticated;
      _currentUser = null;
    }

    _isLoading = false;
    notifyListeners();
    return success;
  }

  Future<void> logout() async {
    _isLoading = true;
    notifyListeners();

    try {
      final refreshToken = storageService.getRefreshToken();
      if (refreshToken != null && refreshToken.isNotEmpty) {
        await apiService.post(
          ApiConfig.logoutUrl,
          body: {'refresh_token': refreshToken},
        );
      }
    } catch (_) {
      // Ignore network errors during logout
    } finally {
      await storageService.clearAuth();
      _currentUser = null;
      _status = AuthStatus.unauthenticated;
      _isLoading = false;
      _errorMessage = null;
      _successMessage = 'Logged out successfully.';
      notifyListeners();
    }
  }
}
