import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';
import '../utils/api_constants.dart';

class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  
  late Dio _dio;

  // Uses centralized URL from ApiConstants
  static const String baseUrl = ApiConstants.serverBaseUrl;

  ApiService._internal() {
    _dio = Dio(BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 60),
      receiveTimeout: const Duration(seconds: 60),
      headers: {
        'Content-Type': 'application/json',
      },
    ));

    _dio.interceptors.add(QueuedInterceptorsWrapper(
      onRequest: (options, handler) async {
        // Ensure all relative paths are prefixed with /api
        if (!options.path.startsWith('http') && !options.path.startsWith('/api')) {
          options.path = options.path.startsWith('/') 
              ? '/api${options.path}' 
              : '/api/${options.path}';
        }

        final prefs = await SharedPreferences.getInstance();
        final token = prefs.getString(ApiConstants.authTokenKey);
        if (token != null && token.isNotEmpty) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        return handler.next(options);
      },
      onError: (DioException e, handler) async {
        debugPrint('API Error [${e.response?.statusCode}]: ${e.requestOptions.path} - ${e.message}');
        if (e.response?.data != null) {
          debugPrint('API Error Data: ${e.response?.data}');
        }

        // Auto-refresh access token on 401 Unauthorized for protected endpoints
        if (e.response?.statusCode == 401 && !_isAuthExcludedPath(e.requestOptions.path)) {
          final newToken = await refreshAccessToken();
          if (newToken != null && newToken.isNotEmpty) {
            e.requestOptions.headers['Authorization'] = 'Bearer $newToken';
            try {
              final retryResponse = await _dio.fetch(e.requestOptions);
              return handler.resolve(retryResponse);
            } on DioException catch (retryError) {
              return handler.next(retryError);
            }
          }
        }

        return handler.next(e);
      },
    ));
  }

  bool _isAuthExcludedPath(String path) {
    final authPaths = [
      ApiConstants.authLogin,
      ApiConstants.authSignup,
      ApiConstants.authGoogleLogin,
      ApiConstants.authRefreshToken,
      ApiConstants.authSendResetOtp,
      ApiConstants.authVerifyResetOtp,
      ApiConstants.authResetPasswordWithOtp,
    ];
    return authPaths.any((p) => path.contains(p));
  }

  Dio get dio => _dio;

  Future<void> setTokens({required String accessToken, required String refreshToken}) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(ApiConstants.authTokenKey, accessToken);
    if (refreshToken.isNotEmpty) {
      await prefs.setString(ApiConstants.refreshTokenKey, refreshToken);
    }
  }

  Future<void> setToken(String token, {String? refreshToken}) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(ApiConstants.authTokenKey, token);
    if (refreshToken != null && refreshToken.isNotEmpty) {
      await prefs.setString(ApiConstants.refreshTokenKey, refreshToken);
    }
  }

  Future<void> setRefreshToken(String refreshToken) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(ApiConstants.refreshTokenKey, refreshToken);
  }

  Future<void> clearToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(ApiConstants.authTokenKey);
    await prefs.remove(ApiConstants.refreshTokenKey);
  }

  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(ApiConstants.authTokenKey);
  }

  Future<String?> getRefreshToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(ApiConstants.refreshTokenKey);
  }

  /// Refreshes the access token using the stored refresh token via a dedicated Dio instance
  Future<String?> refreshAccessToken() async {
    try {
      final refreshToken = await getRefreshToken();
      if (refreshToken == null || refreshToken.isEmpty) {
        debugPrint('⚠️ [ApiService] No refresh token found to refresh session');
        return null;
      }

      debugPrint('🔄 [ApiService] Refreshing access token via API...');
      final refreshDio = Dio(BaseOptions(
        baseUrl: baseUrl,
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 15),
        headers: {'Content-Type': 'application/json'},
      ));

      final response = await refreshDio.post(
        ApiConstants.authRefreshToken.startsWith('/')
            ? '/api${ApiConstants.authRefreshToken}'
            : '/api/${ApiConstants.authRefreshToken}',
        data: {'refreshToken': refreshToken},
      );

      if (response.statusCode == 200 && response.data != null) {
        final newAccessToken = response.data['accessToken'] ?? response.data['token'];
        final newRefreshToken = response.data['refreshToken'];

        if (newAccessToken != null) {
          await setToken(
            newAccessToken.toString(),
            refreshToken: newRefreshToken?.toString() ?? refreshToken,
          );
          debugPrint('✅ [ApiService] Access token refreshed successfully');
          return newAccessToken.toString();
        }
      }
    } catch (e) {
      debugPrint('❌ [ApiService] Token refresh failed: $e');
      // If refresh token is invalid or expired, clear tokens
      await clearToken();
    }
    return null;
  }
}
