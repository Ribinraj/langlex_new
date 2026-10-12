import 'dart:convert';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:langlex_new_app/core/local_storage.dart';
import 'package:langlex_new_app/core/network_services.dart';
import 'package:langlex_new_app/features/authentication/auth_repo.dart';
import 'package:langlex_new_app/features/authentication/blocs/auth_bloc/auth_bloc.dart';
import 'package:langlex_new_app/features/authentication/blocs/auth_bloc/auth_state.dart';

class ErrorAdapter implements HttpClientAdapter {
  ErrorAdapter(this.status, this.body);
  final int status;
  final Map<String, dynamic> body;
  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async => ResponseBody.fromString(
    jsonEncode(body),
    status,
    headers: {
      Headers.contentTypeHeader: ['application/json'],
    },
  );
  @override
  void close({bool force = false}) {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await LocalStorage.saveToken('qa-session');
    await LocalStorage.setLoginStatus(true);
  });
  test(
    'blocked account clears session and tells auth UI to return to login',
    () async {
      final dio = DioClient.create()
        ..httpClientAdapter = ErrorAdapter(403, {
          'message': 'Blocked',
          'details': {'code': 'ACCOUNT_BLOCKED'},
        });
      final bloc = AuthBloc(AuthRepository(dio));
      final ended = expectLater(bloc.stream, emits(isA<AuthSessionEnded>()));
      await expectLater(dio.get('user/profile'), throwsA(isA<DioException>()));
      await ended;
      expect(await LocalStorage.hasSession(), false);
      expect(await LocalStorage.getAccessToken(), isEmpty);
      await bloc.close();
      dio.close();
    },
  );
  test('Premium content denial keeps the learner signed in', () async {
    final dio = DioClient.create()
      ..httpClientAdapter = ErrorAdapter(403, {
        'message': 'An active Premium subscription is required.',
      });
    await expectLater(dio.get('quizzes'), throwsA(isA<DioException>()));
    expect(await LocalStorage.hasSession(), true);
    dio.close();
  });
  test(
    'a denied unauthenticated login does not clear another session',
    () async {
      final dio = DioClient.create()
        ..httpClientAdapter = ErrorAdapter(403, {
          'details': {'code': 'ACCOUNT_BLOCKED'},
        });
      await expectLater(
        dio.post(
          'auth/send-otp',
          options: Options(extra: {DioClient.skipAuthKey: true}),
        ),
        throwsA(isA<DioException>()),
      );
      expect(await LocalStorage.hasSession(), true);
      dio.close();
    },
  );
}
