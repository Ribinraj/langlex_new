import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:langlex_new_app/core/local_storage.dart';
import 'package:langlex_new_app/core/urls.dart';

class DioClient {
  static const skipAuthKey = 'skipAuth';

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
              debugPrint('│ Body: ${options.data}');
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
            debugPrint('│ Response: ${response.data}');
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
            debugPrint('│ Response: ${error.response?.data}');
            debugPrint('└───────────────────────────────────────');
          }

          final statusCode = error.response?.statusCode;
          final skipAuth = error.requestOptions.extra[skipAuthKey] == true;

          if (statusCode == 401 && !skipAuth) {
            await LocalStorage.clearAuthSession();
          }

          handler.next(error);
        },
      ),
    );

    return dio;
  }

  static String _authHeader(String token) {
    final trimmed = token.trim();
    if (trimmed.toLowerCase().startsWith('bearer ')) return trimmed;
    return 'Bearer $trimmed';
  }
}
