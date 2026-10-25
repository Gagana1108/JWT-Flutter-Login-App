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
        _successMessage = 'Profile loaded successfully!';
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

  List<UserModel> _adminUserList = [];
  List<UserModel> get adminUserList => _adminUserList;

  Future<bool> updateProfile(String newName) async {
    _isLoading = true;
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();

    try {
      final response = await apiService.patch(
        ApiConfig.userProfileUrl,
        body: {'name': newName},
        requiresAuth: true,
      );

      final data = response['data'] as Map<String, dynamic>;
      final user = UserModel.fromJson(data['user'] as Map<String, dynamic>);

      await storageService.saveUser(user);
      _currentUser = user;
      _successMessage = 'Profile name updated successfully!';
      _isLoading = false;
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      _errorMessage = e.message;
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _errorMessage = 'Failed to update profile: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> fetchAdminUsers() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await apiService.get(
        ApiConfig.adminUsersUrl,
        requiresAuth: true,
      );

      final data = response['data'] as Map<String, dynamic>;
      final usersList = (data['users'] as List<dynamic>)
          .map((json) => UserModel.fromJson(json as Map<String, dynamic>))
          .toList();

      _adminUserList = usersList;
      _isLoading = false;
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      _errorMessage = e.message;
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _errorMessage = 'Failed to fetch user list: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateUserRole(int userId, String newRole) async {
    _isLoading = true;
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();

    try {
      final response = await apiService.patch(
        ApiConfig.adminUserRoleUrl(userId),
        body: {'role': newRole},
        requiresAuth: true,
      );

      final data = response['data'] as Map<String, dynamic>;
      final updatedUser = UserModel.fromJson(data['user'] as Map<String, dynamic>);

      // Update in admin user list
      final index = _adminUserList.indexWhere((u) => u.id == userId);
      if (index != -1) {
        _adminUserList[index] = updatedUser;
      }

      // If updating current logged in user
      if (_currentUser?.id == userId) {
        _currentUser = updatedUser;
        await storageService.saveUser(updatedUser);
      }

      _successMessage = 'User role updated to $newRole successfully!';
      _isLoading = false;
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      _errorMessage = e.message;
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _errorMessage = 'Failed to update user role: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    _isLoading = true;
    notifyListeners();

    try {
      await apiService.post(
        ApiConfig.logoutUrl,
        body: {},
      );
    } catch (_) {
      // Ignore network errors during logout
    } finally {
      await storageService.clearAuth();
      _currentUser = null;
      _adminUserList = [];
      _status = AuthStatus.unauthenticated;
      _isLoading = false;
      _errorMessage = null;
      _successMessage = 'Logged out successfully.';
      notifyListeners();
    }
  }
}
