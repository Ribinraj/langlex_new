import 'package:dio/dio.dart';
import 'package:langlex_new_app/core/api_exception.dart';
import 'package:langlex_new_app/core/local_storage.dart';
import 'package:langlex_new_app/core/network_services.dart';
import 'package:langlex_new_app/core/push_notification_service.dart';
import 'package:langlex_new_app/core/urls.dart';
import 'package:langlex_new_app/features/authentication/models/app_user.dart';
import 'package:langlex_new_app/features/authentication/models/auth_response.dart';

class AuthRepository {
  AuthRepository(this._dio);

  final Dio _dio;
  static const defaultOtpResendSeconds = 30;

  Future<bool> checkUser({required String mobileNumber}) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        Endpoints.checkUser,
        data: {'mobile_number': mobileNumber},
        options: Options(extra: {DioClient.skipAuthKey: true}),
      );

      return response.data?['isExistingUser'] == true;
    } on DioException catch (error) {
      throw ApiException.fromDio(error);
    }
  }

  Future<int> register({
    required String fullName,
    required String mobileNumber,
    required String school,
    required String city,
    required String state,
    String? email,
  }) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        Endpoints.register,
        data: {
          'full_name': fullName,
          'mobile_number': mobileNumber,
          'email': (email?.trim().isEmpty ?? true) ? null : email!.trim(),
          'school': school,
          'city': city,
          'state': state,
        },
        options: Options(extra: {DioClient.skipAuthKey: true}),
      );
      return _resendSecondsFromResponse(response.data);
    } on DioException catch (error) {
      throw ApiException.fromDio(error);
    }
  }

  Future<int> sendOtp({required String mobileNumber}) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        Endpoints.sendOtp,
        data: {'mobile_number': mobileNumber},
        options: Options(extra: {DioClient.skipAuthKey: true}),
      );
      return _resendSecondsFromResponse(response.data);
    } on DioException catch (error) {
      throw ApiException.fromDio(error);
    }
  }

  Future<int> resendOtp({required String mobileNumber}) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        Endpoints.resendOtp,
        data: {'mobile_number': mobileNumber},
        options: Options(extra: {DioClient.skipAuthKey: true}),
      );
      return _resendSecondsFromResponse(response.data);
    } on DioException catch (error) {
      throw ApiException.fromDio(error);
    }
  }

  Future<AppUser> verifyOtp({
    required String mobileNumber,
    required String otp,
  }) async {
    try {
      final pushToken = await PushNotificationService.instance.getPushToken();
      final response = await _dio.post<Map<String, dynamic>>(
        Endpoints.verifyOtp,
        data: {
          'mobile_number': mobileNumber,
          'otp': otp,
          'push_token': pushToken,
        },
        options: Options(extra: {DioClient.skipAuthKey: true}),
      );

      final authResponse = AuthResponse.fromJson(response.data ?? {});
      await LocalStorage.saveAuthSession(authResponse);
      return authResponse.user;
    } on DioException catch (error) {
      throw ApiException.fromDio(error);
    }
  }

  Future<AppUser> restoreSession() async {
    final hasSession = await LocalStorage.hasSession();
    if (!hasSession) {
      throw const ApiException('No saved session', statusCode: 401);
    }

    return getCurrentUser();
  }

  Future<AppUser> getCurrentUser() async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        Endpoints.currentUser,
      );
      final user = AppUser.fromJson(
        response.data?['user'] as Map<String, dynamic>? ?? {},
      );
      await LocalStorage.saveUser(user);
      return user;
    } on DioException catch (error) {
      throw ApiException.fromDio(error);
    }
  }

  Future<AppUser> updateProfile({
    required String fullName,
    String? email,
    String? school,
    String? city,
    String? state,
  }) async {
    try {
      final response = await _dio.put<Map<String, dynamic>>(
        Endpoints.updateProfile,
        data: {
          'full_name': fullName.trim(),
          'email': _nullable(email),
          'school': _nullable(school),
          'city': _nullable(city),
          'state': _nullable(state),
        },
      );

      final user = AppUser.fromJson(
        response.data?['user'] as Map<String, dynamic>? ?? {},
      );
      await LocalStorage.saveUser(user);
      return user;
    } on DioException catch (error) {
      throw ApiException.fromDio(error);
    }
  }

  Future<void> logout() async {
    try {
      await _dio.post<Map<String, dynamic>>(Endpoints.logout);
    } on DioException {
      // Local logout still completes when the server token is already invalid.
    } finally {
      await LocalStorage.clearAuthSession();
    }
  }

  String? _nullable(String? value) {
    final text = value?.trim() ?? '';
    return text.isEmpty ? null : text;
  }

  int _resendSecondsFromResponse(Map<String, dynamic>? data) {
    final value = data?['resend_after_seconds'];
    if (value is num) return value.round().clamp(1, 300).toInt();
    if (value is String) {
      final parsed = int.tryParse(value);
      if (parsed != null) return parsed.clamp(1, 300).toInt();
    }
    return defaultOtpResendSeconds;
  }
}
