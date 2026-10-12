import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:langlex_new_app/core/local_storage.dart';
import 'package:langlex_new_app/core/urls.dart';

class DioClient {
  static const skipAuthKey = 'skipAuth';
  static final _sessionEnded = StreamController<String>.broadcast();
  static Stream<String> get sessionEnded => _sessionEnded.stream;
  static bool _endingSession = false;

  static Dio create() {
    final dio = Dio(
      BaseOptions(
        baseUrl: Endpoints.baseUrl,
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 15),
        headers: const {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
      ),
    );

    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final skipAuth = options.extra[skipAuthKey] == true;

          if (!skipAuth) {
            final token = await LocalStorage.getAccessToken();
            if (token.isNotEmpty) {
              options.headers['Authorization'] = _authHeader(token);
            }
          }

          if (kDebugMode) {
            debugPrint('┌── API REQUEST ─────────────────────────');
            debugPrint('│ ${options.method} ${options.baseUrl}${options.path}');
            if (options.queryParameters.isNotEmpty) {
              debugPrint('│ Query: ${options.queryParameters}');
            }
            if (options.data != null) {
              debugPrint('│ Body: ${redact(options.data)}');
            }
            debugPrint('└───────────────────────────────────────');
          }

          handler.next(options);
        },
        onResponse: (response, handler) {
          if (kDebugMode) {
            debugPrint('┌── API RESPONSE ───────────────────────');
            debugPrint(
              '│ ${response.statusCode} ${response.requestOptions.method} '
              '${response.requestOptions.path}',
            );
            debugPrint('│ Response: ${redact(response.data)}');
            debugPrint('└───────────────────────────────────────');
          }
          handler.next(response);
        },
        onError: (error, handler) async {
          if (kDebugMode) {
            debugPrint('┌── API ERROR ──────────────────────────');
            debugPrint(
              '│ ${error.response?.statusCode ?? '-'} '
              '${error.requestOptions.method} ${error.requestOptions.path}',
            );
            debugPrint('│ Message: ${error.message}');
            debugPrint('│ Response: ${redact(error.response?.data)}');
            debugPrint('└───────────────────────────────────────');
          }

          final statusCode = error.response?.statusCode;
          final skipAuth = error.requestOptions.extra[skipAuthKey] == true;

          final body = error.response?.data;
          final blocked =
              statusCode == 403 &&
              body is Map &&
              body['details'] is Map &&
              body['details']['code'] == 'ACCOUNT_BLOCKED';
          if ((statusCode == 401 || blocked) && !skipAuth) {
            if (!_endingSession &&
                (await LocalStorage.getAccessToken()).isNotEmpty) {
              _endingSession = true;
              try {
                await LocalStorage.clearAuthSession();
                _sessionEnded.add(
                  blocked
                      ? 'Your account has been blocked. Please contact support.'
                      : 'Your session has expired. Please sign in again.',
                );
              } finally {
                _endingSession = false;
              }
            }
          }

          handler.next(error);
        },
      ),
    );

    return dio;
  }

  static Object? redact(Object? data) {
    if (data is Map) {
      return data.map(
        (key, value) => MapEntry(
          key,
          RegExp(
                r'otp|token|password',
                caseSensitive: false,
              ).hasMatch(key.toString())
              ? '[redacted]'
              : redact(value),
        ),
      );
    }
    if (data is List) return data.map(redact).toList();
    return data;
  }

  static String _authHeader(String token) {
    final trimmed = token.trim();
    if (trimmed.toLowerCase().startsWith('bearer ')) return trimmed;
    return 'Bearer $trimmed';
  }
}
