import 'dart:async';
import 'package:dio/dio.dart';
import '../../../core/utils/app_logger.dart';
import '../../../core/utils/api_constants.dart';
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
        final token = response.data['token'] ?? response.data['accessToken'];
        final refreshToken = response.data['refreshToken'] ?? '';
        final userJson = response.data['user'];
        
        await _apiService.setTokens(
          accessToken: token.toString(),
          refreshToken: refreshToken.toString(),
        );
        AppLogger.s('Registration successful', tag: 'AUTH_REPO');
        
        return UserModel(
          uid: userJson['uid'],
          name: userJson['name'],
          phone: userJson['phone'] ?? '',
          role: userJson['role'] ?? 'bachelor',
          photoUrl: userJson['profile_image'] ?? userJson['photoUrl'],
          isPaid: true, // 🆓 Free Launch
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
        final token = response.data['token'] ?? response.data['accessToken'];
        final refreshToken = response.data['refreshToken'] ?? '';
        final userJson = response.data['user'];
        
        await _apiService.setTokens(
          accessToken: token.toString(),
          refreshToken: refreshToken.toString(),
        );
        AppLogger.s('Login successful', tag: 'AUTH_REPO');
        
        String? photo = userJson['profile_image'] ?? userJson['photoUrl'];
        if (photo != null && photo.startsWith('http://') && !photo.contains('localhost') && !photo.contains('10.0.2.2')) {
          photo = photo.replaceFirst('http://', 'https://');
        }
        
        return UserModel(
          uid: userJson['uid'],
          name: userJson['name'],
          phone: userJson['phone'] ?? '',
          role: userJson['role'] ?? 'bachelor',
          photoUrl: photo,
          isPaid: true, // 🆓 Free Launch
          createdAt: DateTime.parse(userJson['created_at']),
        );
      }
      return null;
    } on DioException catch (e) {
      AppLogger.e('DioException (Login): ${e.message}', e, null, 'AUTH_REPO');
      if (e.response?.data != null && e.response?.data['error'] != null) {
        throw e.response?.data['error'];
      }
      if (e.response?.statusCode == 401 || e.response?.statusCode == 404) {
        throw 'Invalid email or password. Please try again.';
      }
      throw 'Login failed. Please check your connection.';
    } catch (e, stack) {
      AppLogger.e('Login failed: $e', e, stack, 'AUTH_REPO');
      throw e.toString();
    }
  }

  // Google Sign-In Login & Auto-Registration
  Future<UserModel?> googleLogin({
    required String email,
    required String name,
    String? profileImage,
    required String googleId,
    String? role,
  }) async {
    try {
      AppLogger.i('Attempting Google login -> Email: $email', tag: 'AUTH_REPO');

      final response = await _apiService.dio.post(ApiConstants.authGoogleLogin, data: {
        'email': email,
        'name': name,
        'profileImage': profileImage,
        'googleId': googleId,
        'role': role ?? 'bachelor',
      });

      if (response.statusCode == 200 || response.statusCode == 201) {
        final token = response.data['token'] ?? response.data['accessToken'];
        final refreshToken = response.data['refreshToken'] ?? '';
        final userJson = response.data['user'];

        await _apiService.setTokens(
          accessToken: token.toString(),
          refreshToken: refreshToken.toString(),
        );
        AppLogger.s('Google login successful', tag: 'AUTH_REPO');

        return UserModel(
          uid: userJson['uid'],
          name: userJson['name'] ?? name,
          phone: userJson['phone'] ?? '',
          photoUrl: userJson['profile_image'] ?? profileImage,
          role: userJson['role'] ?? role ?? 'bachelor',
          isPaid: true, // 🆓 Free Launch
          createdAt: userJson['created_at'] != null
              ? DateTime.parse(userJson['created_at'])
              : DateTime.now(),
        );
      }
      return null;
    } on DioException catch (e) {
      AppLogger.e('DioException (GoogleLogin): ${e.message}', e, null, 'AUTH_REPO');
      if (e.response?.data != null && e.response?.data['error'] != null) {
        throw e.response?.data['error'];
      }
      throw 'Google Sign-In failed. Please check your connection.';
    } catch (e, stack) {
      AppLogger.e('Google login failed: $e', e, stack, 'AUTH_REPO');
      throw e.toString();
    }
  }

  // Send Reset OTP to Email
  Future<void> sendResetOtp(String email) async {
    try {
      AppLogger.i('Sending password reset OTP -> Email: $email', tag: 'AUTH_REPO');
      final response = await _apiService.dio.post(ApiConstants.authSendResetOtp, data: {
        'email': email.trim(),
      });
      if (response.statusCode == 200) {
        AppLogger.s('Password reset OTP sent', tag: 'AUTH_REPO');
        return;
      }
      throw 'Failed to send OTP';
    } on DioException catch (e) {
      if (e.response?.data != null && e.response?.data['error'] != null) {
        throw e.response?.data['error'];
      }
      throw 'Failed to send OTP. Please check your connection.';
    } catch (e) {
      throw e.toString();
    }
  }

  // Verify Reset OTP
  Future<void> verifyResetOtp({required String email, required String otp}) async {
    try {
      AppLogger.i('Verifying reset OTP -> Email: $email', tag: 'AUTH_REPO');
      final response = await _apiService.dio.post(ApiConstants.authVerifyResetOtp, data: {
        'email': email.trim(),
        'otp': otp.trim(),
      });
      if (response.statusCode == 200) {
        AppLogger.s('OTP verified successfully', tag: 'AUTH_REPO');
        return;
      }
      throw 'Invalid OTP';
    } on DioException catch (e) {
      if (e.response?.data != null && e.response?.data['error'] != null) {
        throw e.response?.data['error'];
      }
      throw 'Failed to verify OTP. Please try again.';
    } catch (e) {
      throw e.toString();
    }
  }

  // Reset Password with OTP
  Future<void> resetPasswordWithOtp({
    required String email,
    required String otp,
    required String newPassword,
  }) async {
    try {
      AppLogger.i('Resetting password with OTP -> Email: $email', tag: 'AUTH_REPO');
      final response = await _apiService.dio.post(ApiConstants.authResetPasswordWithOtp, data: {
        'email': email.trim(),
        'otp': otp.trim(),
        'newPassword': newPassword,
      });
      if (response.statusCode == 200) {
        AppLogger.s('Password reset completed', tag: 'AUTH_REPO');
        return;
      }
      throw 'Failed to reset password';
    } on DioException catch (e) {
      if (e.response?.data != null && e.response?.data['error'] != null) {
        throw e.response?.data['error'];
      }
      throw 'Failed to reset password. Please check your connection.';
    } catch (e) {
      throw e.toString();
    }
  }

  // Change Password for Logged-In User
  Future<void> changePassword({
    required String oldPassword,
    required String newPassword,
  }) async {
    try {
      AppLogger.i('Changing password for current user...', tag: 'AUTH_REPO');
      final response = await _apiService.dio.put(ApiConstants.authChangePassword, data: {
        'oldPassword': oldPassword,
        'newPassword': newPassword,
      });
      if (response.statusCode == 200) {
        AppLogger.s('Password updated successfully', tag: 'AUTH_REPO');
        return;
      }
      throw 'Failed to update password';
    } on DioException catch (e) {
      if (e.response?.data != null && e.response?.data['error'] != null) {
        throw e.response?.data['error'];
      }
      throw 'Failed to change password. Please verify current password.';
    } catch (e) {
      throw e.toString();
    }
  }

  Future<void> sendPasswordResetEmail(String email) => sendResetOtp(email);

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
        final rawData = Map<String, dynamic>.from(response.data);
        final data = rawData['user'] ?? rawData['data'] ?? rawData;
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
    final refreshToken = await _apiService.getRefreshToken();
    return (token != null && token.isNotEmpty) || (refreshToken != null && refreshToken.isNotEmpty);
  }

  // Refresh auth tokens
  Future<bool> refreshToken() async {
    final newToken = await _apiService.refreshAccessToken();
    return newToken != null && newToken.isNotEmpty;
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
