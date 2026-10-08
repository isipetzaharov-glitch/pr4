// lib/models/auth_result.dart
import 'app_user.dart';

class AuthResult {
  final String accessToken;
  final String refreshToken;
  final int expiresIn;
  final AppUser user;

  const AuthResult({
    required this.accessToken,
    required this.refreshToken,
    required this.expiresIn,
    required this.user,
  });

  factory AuthResult.fromJson(Map<String, dynamic> json) => AuthResult(
    accessToken: json['accessToken'] as String? ?? '',
    refreshToken: json['refreshToken'] as String? ?? '',
    expiresIn: (json['expiresIn'] as num?)?.toInt() ?? 900,
    user: AppUser.fromJson(json['user'] as Map<String, dynamic>),
  );
}
