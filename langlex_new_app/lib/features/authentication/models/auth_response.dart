import 'package:langlex_new_app/features/authentication/models/app_user.dart';

class AuthResponse {
  const AuthResponse({required this.token, required this.user});

  final String token;
  final AppUser user;

  factory AuthResponse.fromJson(Map<String, dynamic> json) {
    return AuthResponse(
      token: json['token']?.toString() ?? '',
      user: AppUser.fromJson(
        json['user'] as Map<String, dynamic>? ?? <String, dynamic>{},
      ),
    );
  }
}
