import 'dart:async';
import 'package:dio/dio.dart';
import '../../../core/utils/app_logger.dart';
import '../../../core/services/api_service.dart';
import '../models/user_model.dart';

class AuthRepository {
  final ApiService _apiService = ApiService();

  // Sign Up with Email and Password
  Future<UserModel?> signUp({
    required String name,
    required String phone,
    required String email,
    required String password,
  }) async {
    try {
      AppLogger.i('Starting account registration -> Email: $email', tag: 'AUTH_REPO');
      
      final response = await _apiService.dio.post('/auth/signup', data: {
        'name': name,
        'phone': phone,
        'email': email,
        'password': password,
      });

      if (response.statusCode == 201) {
        final token = response.data['token'];
        final userJson = response.data['user'];
        
        await _apiService.setToken(token);
        AppLogger.s('Registration successful', tag: 'AUTH_REPO');
        
        return UserModel(
          uid: userJson['uid'],
          name: userJson['name'],
          phone: userJson['phone'],
          role: userJson['role'] ?? 'bachelor',
          isPaid: false,
          createdAt: DateTime.parse(userJson['created_at']),
        );
      }
      return null;
    } on DioException catch (e) {
      AppLogger.e('DioException (SignUp): ${e.message}', e, null, 'AUTH_REPO');
      if (e.response?.data != null && e.response?.data['error'] != null) {
        throw e.response?.data['error'];
      }
      throw 'Registration failed. Please check your connection.';
    } catch (e, stack) {
      AppLogger.e('Registration failed: $e', e, stack, 'AUTH_REPO');
      throw e.toString();
    }
  }

  // Login with Email and Password
  Future<UserModel?> login({
    required String email,
    required String password,
  }) async {
    try {
      AppLogger.i('Attempting login -> Email: $email', tag: 'AUTH_REPO');
      
      final response = await _apiService.dio.post('/auth/login', data: {
        'email': email,
        'password': password,
      });

      if (response.statusCode == 200) {
        final token = response.data['token'];
        final userJson = response.data['user'];
        
        await _apiService.setToken(token);
        AppLogger.s('Login successful', tag: 'AUTH_REPO');
        
        return UserModel(
          uid: userJson['uid'],
          name: userJson['name'],
          phone: userJson['phone'],
          role: userJson['role'] ?? 'bachelor',
          isPaid: userJson['status'] == 'active', 
          createdAt: DateTime.parse(userJson['created_at']),
        );
      }
      return null;
    } on DioException catch (e) {
      AppLogger.e('DioException (Login): ${e.message}', e, null, 'AUTH_REPO');
      if (e.response?.statusCode == 401 || e.response?.statusCode == 404) {
        throw 'Invalid email or password. Please try again.';
      }
      if (e.response?.data != null && e.response?.data['error'] != null) {
        throw e.response?.data['error'];
      }
      throw 'Login failed. Please check your connection.';
    } catch (e, stack) {
      AppLogger.e('Login failed: $e', e, stack, 'AUTH_REPO');
      throw e.toString();
    }
  }

  Future<void> sendPasswordResetEmail(String email) async {
     throw 'Not implemented on REST API yet';
  }

  // Save user details to API
  Future<void> saveUserData(UserModel user) async {
    try {
      AppLogger.i('Saving user data to API: ${user.uid}', tag: 'AUTH_REPO');
      await _apiService.dio.put('/auth/profile', data: user.toMap());
    } catch (e, stack) {
      AppLogger.e('Failed to save user data: $e', e, stack, 'AUTH_REPO');
    }
  }

  // Fetch current user data from API
  Future<UserModel?> getUserData(String uid) async {
    try {
      // In our Node backend, the profile route fetches using the token
      final response = await _apiService.dio.get('/auth/profile');
      if (response.statusCode == 200 && response.data != null) {
        final data = Map<String, dynamic>.from(response.data);
        return UserModel.fromMap(data, data['uid']?.toString() ?? '');
      }
      return null;
    } catch (e) {
      AppLogger.e('Error fetching user data: $e', e, null, 'AUTH_REPO');
      return null;
    }
  }

  Future<bool> isLoggedIn() async {
    final token = await _apiService.getToken();
    return token != null && token.isNotEmpty;
  }

  // Sign out
  Future<void> logout() async {
    try {
      AppLogger.i('Logging out...', tag: 'AUTH_REPO');
      await _apiService.clearToken();
      AppLogger.s('Logout completed', tag: 'AUTH_REPO');
    } catch (e, stack) {
      AppLogger.e('Error logging out: $e', e, stack, 'AUTH_REPO');
    }
  }

  // Delete Current User Account
  Future<void> deleteCurrentAccount(String uid) async {
    try {
      AppLogger.i('Attempting to delete account for UID: $uid', tag: 'AUTH_REPO');
      await _apiService.dio.delete('/auth/profile');
    } catch (e, stack) {
      AppLogger.e('Failed to delete account: $e', e, stack, 'AUTH_REPO');
      throw 'Failed to delete account: $e';
    }
  }
}
