// lib/core/auth_api.dart
import 'package:dio/dio.dart';

import '../models/app_user.dart';
import '../models/auth_result.dart';
import 'api_exceptions.dart';

class AuthApi {
  final Dio _dio;
  AuthApi(this._dio);

  Future<AuthResult> login(String username, String password) => guard(() async {
    final response = await _dio.post(
      '/auth/login',
      data: {'username': username, 'password': password},
    );
    return AuthResult.fromJson(response.data as Map<String, dynamic>);
  });

  Future<AppUser> register({
    required String username,
    required String password,
    required String fullName,
    String? email,
  }) => guard(() async {
    final response = await _dio.post(
      '/auth/register',
      data: {
        'username': username,
        'password': password,
        'fullName': fullName,
        if (email != null && email.isNotEmpty) 'email': email,
      },
    );
    return AppUser.fromJson(response.data as Map<String, dynamic>);
  });

  Future<AppUser> me() => guard(() async {
    final response = await _dio.get('/auth/me');
    return AppUser.fromJson(response.data as Map<String, dynamic>);
  });

  Future<AuthResult> refresh(String refreshToken) => guard(() async {
    final response = await _dio.post(
      '/auth/refresh',
      data: {'refreshToken': refreshToken},
    );
    return AuthResult.fromJson(response.data as Map<String, dynamic>);
  });

  /// Logout. Если refreshToken == null — отправляем пустое тело.
  /// Сервер корректно обработает отсутствие токена.
  Future<void> logout(String? refreshToken) => guard(() async {
    await _dio.post('/auth/logout', data: {'refreshToken': refreshToken});
  });
}
