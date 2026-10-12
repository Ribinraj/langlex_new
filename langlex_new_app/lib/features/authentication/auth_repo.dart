import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:langlex_new_app/core/api_exception.dart';
import 'package:langlex_new_app/core/local_storage.dart';
import 'package:langlex_new_app/core/network_services.dart';
import 'package:langlex_new_app/core/push_notification_service.dart';
import 'package:langlex_new_app/core/urls.dart';
import 'package:langlex_new_app/features/authentication/models/app_user.dart';
import 'package:langlex_new_app/features/authentication/models/auth_response.dart';

enum SocialLoginProvider { google }

class SocialRegistrationDraft {
  const SocialRegistrationDraft({
    required this.provider,
    this.fullName,
    this.email,
  });

  final SocialLoginProvider provider;
  final String? fullName;
  final String? email;
}

abstract class SocialLoginResult {
  const SocialLoginResult();
}

class SocialLoginAuthenticated extends SocialLoginResult {
  const SocialLoginAuthenticated(this.user);

  final AppUser user;
}

class SocialLoginNeedsRegistration extends SocialLoginResult {
  const SocialLoginNeedsRegistration(this.draft);

  final SocialRegistrationDraft draft;
}

class OtpChallenge {
  const OtpChallenge({
    this.resendAfterSeconds = 30,
    this.displayCode,
    this.expiresAt,
  });
  final int resendAfterSeconds;
  final String? displayCode;
  final DateTime? expiresAt;
  factory OtpChallenge.fromJson(Map<String, dynamic>? data) {
    final seconds = int.tryParse('${data?['resend_after_seconds']}') ?? 30;
    final code = data?['display_otp']?.toString();
    return OtpChallenge(
      resendAfterSeconds: seconds.clamp(0, 300),
      displayCode: code != null && RegExp(r'^\d{6}$').hasMatch(code)
          ? code
          : null,
      expiresAt: DateTime.tryParse(
        '${data?['expires_at'] ?? data?['otp_expires_at']}',
      ),
    );
  }
}

class SocialLoginNeedsOtp extends SocialLoginResult {
  const SocialLoginNeedsOtp({
    required this.mobileNumber,
    required this.challenge,
  });

  final String mobileNumber;
  final OtpChallenge challenge;
}

class AuthRepository {
  AuthRepository(this._dio) {
    PushNotificationService.instance.setTokenRefreshHandler(
      _syncPushTokenSilently,
    );
  }

  final Dio _dio;
  static const defaultOtpResendSeconds = 30;
  static Future<void>? _googleInitializeFuture;

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

  Future<OtpChallenge> register({
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
      return OtpChallenge.fromJson(response.data);
    } on DioException catch (error) {
      throw ApiException.fromDio(error);
    }
  }

  Future<OtpChallenge> sendOtp({required String mobileNumber}) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        Endpoints.sendOtp,
        data: {'mobile_number': mobileNumber},
        options: Options(extra: {DioClient.skipAuthKey: true}),
      );
      return OtpChallenge.fromJson(response.data);
    } on DioException catch (error) {
      throw ApiException.fromDio(error);
    }
  }

  Future<OtpChallenge> resendOtp({required String mobileNumber}) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        Endpoints.resendOtp,
        data: {'mobile_number': mobileNumber},
        options: Options(extra: {DioClient.skipAuthKey: true}),
      );
      return OtpChallenge.fromJson(response.data);
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
      await registerCurrentPushToken();
      return authResponse.user;
    } on DioException catch (error) {
      throw ApiException.fromDio(error);
    }
  }

  Future<SocialLoginResult> signInWithGoogle() async {
    try {
      await _ensureGoogleInitialized();
      final googleUser = await GoogleSignIn.instance.authenticate();
      final googleIdToken = googleUser.authentication.idToken;
      if (googleIdToken == null || googleIdToken.isEmpty) {
        throw const ApiException('Google did not return a login token.');
      }
      _debugLogGoogleAuth('Google account', {
        'id': googleUser.id,
        'email': googleUser.email,
        'display_name': googleUser.displayName,
        'photo_url': googleUser.photoUrl,
        'google_id_token': _maskToken(googleIdToken),
      });

      final credential = GoogleAuthProvider.credential(idToken: googleIdToken);
      final userCredential = await FirebaseAuth.instance.signInWithCredential(
        credential,
      );
      final firebaseIdToken = await _currentFirebaseIdToken();
      _debugLogGoogleAuth('Firebase credential', {
        'uid': userCredential.user?.uid,
        'email': userCredential.user?.email,
        'display_name': userCredential.user?.displayName,
        'is_new_user': userCredential.additionalUserInfo?.isNewUser,
        'provider_id': userCredential.credential?.providerId,
        'firebase_id_token': _maskToken(firebaseIdToken),
      });
      return _socialLogin(firebaseIdToken);
    } on ApiException {
      rethrow;
    } on GoogleSignInException catch (error) {
      _debugLogGoogleAuth('GoogleSignInException', {
        'code': error.code.toString(),
        'description': error.description,
      });
      throw ApiException(error.description ?? 'Google login failed.');
    } on FirebaseAuthException catch (error) {
      _debugLogGoogleAuth('FirebaseAuthException', {
        'code': error.code,
        'message': error.message,
      });
      throw ApiException(error.message ?? 'Firebase Google login failed.');
    } catch (error) {
      _debugLogGoogleAuth('Unexpected error', error.toString());
      throw const ApiException('Google login failed. Please try again.');
    }
  }

  Future<OtpChallenge> completeSocialRegistration({
    required String fullName,
    required String mobileNumber,
    required String school,
    required String city,
    required String state,
    String? email,
  }) async {
    try {
      final firebaseIdToken = await _currentFirebaseIdToken();
      final response = await _dio.post<Map<String, dynamic>>(
        Endpoints.socialRegister,
        data: {
          'id_token': firebaseIdToken,
          'full_name': fullName,
          'mobile_number': mobileNumber,
          'email': (email?.trim().isEmpty ?? true) ? null : email!.trim(),
          'school': school,
          'city': city,
          'state': state,
        },
        options: Options(extra: {DioClient.skipAuthKey: true}),
      );
      _debugLogGoogleAuth(
        'Backend social-register response',
        _sanitizeForLog(response.data),
      );
      return OtpChallenge.fromJson(response.data);
    } on ApiException {
      rethrow;
    } on DioException catch (error) {
      throw ApiException.fromDio(error);
    } on FirebaseAuthException catch (error) {
      throw ApiException(error.message ?? 'Could not verify social login.');
    } catch (_) {
      throw const ApiException('Social registration failed. Please try again.');
    }
  }

  Future<AppUser> restoreSession() async {
    final hasSession = await LocalStorage.hasSession();
    if (!hasSession) {
      throw const ApiException('No saved session', statusCode: 401);
    }

    await registerCurrentPushToken();
    return getCurrentUser();
  }

  Future<void> registerCurrentPushToken() async {
    final pushToken = await PushNotificationService.instance.getPushToken();
    if (pushToken.isEmpty) return;
    await _syncPushTokenSilently(pushToken);
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
      await FirebaseAuth.instance.signOut();
      try {
        await _ensureGoogleInitialized();
        await GoogleSignIn.instance.signOut();
      } catch (_) {
        // Firebase sign-out and local session clearing are enough for logout.
      }
      await LocalStorage.clearAuthSession();
    }
  }

  Future<SocialLoginResult> _socialLogin(String firebaseIdToken) async {
    final pushToken = await PushNotificationService.instance.getPushToken();
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        Endpoints.socialLogin,
        data: {'id_token': firebaseIdToken, 'push_token': pushToken},
        options: Options(extra: {DioClient.skipAuthKey: true}),
      );
      final data = response.data ?? {};
      _debugLogGoogleAuth(
        'Backend social-login response',
        _sanitizeForLog(data),
      );

      if (data['requires_registration'] == true) {
        return SocialLoginNeedsRegistration(
          SocialRegistrationDraft(
            provider: _providerFromJson(data['provider']),
            fullName: _nullable(data['full_name']?.toString()),
            email: _nullable(data['email']?.toString()),
          ),
        );
      }

      if (data['requires_mobile_verification'] == true) {
        return SocialLoginNeedsOtp(
          mobileNumber: data['mobile_number']?.toString() ?? '',
          challenge: OtpChallenge.fromJson(data),
        );
      }

      final authResponse = AuthResponse.fromJson(data);
      await LocalStorage.saveAuthSession(authResponse);
      await registerCurrentPushToken();
      return SocialLoginAuthenticated(authResponse.user);
    } on DioException catch (error) {
      throw ApiException.fromDio(error);
    }
  }

  Future<void> _ensureGoogleInitialized() {
    return _googleInitializeFuture ??= GoogleSignIn.instance.initialize();
  }

  Future<String> _currentFirebaseIdToken() async {
    final firebaseUser = FirebaseAuth.instance.currentUser;
    if (firebaseUser == null) {
      throw const ApiException('Firebase login session was not found.');
    }
    final token = await firebaseUser.getIdToken(true);
    if (token == null || token.isEmpty) {
      throw const ApiException('Firebase did not return a login token.');
    }
    return token;
  }

  SocialLoginProvider _providerFromJson(dynamic value) {
    return SocialLoginProvider.google;
  }

  void _debugLogGoogleAuth(String label, Object? value) {
    if (!kDebugMode) return;
    debugPrint('[GoogleAuth] $label: $value');
  }

  Object? _sanitizeForLog(Object? value) {
    if (value is Map) {
      return value.map((key, item) {
        final textKey = key.toString().toLowerCase();
        final shouldMask =
            textKey.contains('otp') ||
            textKey == 'token' ||
            textKey.endsWith('_token') ||
            textKey.contains('access_token') ||
            textKey.contains('refresh_token') ||
            textKey.contains('id_token');
        return MapEntry(key, shouldMask ? '[redacted]' : _sanitizeForLog(item));
      });
    }

    if (value is List) {
      return value.map(_sanitizeForLog).toList();
    }

    return value;
  }

  String _maskToken(String? token) {
    final value = token?.trim() ?? '';
    if (value.isEmpty) return '';
    if (value.length <= 16) return '${value.substring(0, 4)}...';
    return '${value.substring(0, 8)}...${value.substring(value.length - 8)}';
  }

  Future<void> _syncPushTokenSilently(String pushToken) async {
    if (pushToken.trim().isEmpty) return;
    final accessToken = await LocalStorage.getAccessToken();
    if (accessToken.isEmpty) return;

    try {
      await _dio.post<Map<String, dynamic>>(
        Endpoints.updatePushToken,
        data: {'push_token': pushToken},
      );
    } on DioException catch (error) {
      debugPrint('Could not sync push token: ${error.message}');
    }
  }

  String? _nullable(String? value) {
    final text = value?.trim() ?? '';
    return text.isEmpty ? null : text;
  }
}
