import 'dart:async';
import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:langlex_new_app/core/local_storage.dart';
import 'package:langlex_new_app/core/urls.dart';
import 'package:langlex_new_app/features/authentication/models/app_user.dart';
import 'package:langlex_new_app/features/progress/progress_store.dart';

String token(int id) =>
    'header.${base64Url.encode(utf8.encode(jsonEncode({'sub': '$id'})))}.signature';
Future<void> login(int id) async {
  await LocalStorage.saveUser(
    AppUser(id: id, mobileNumber: '1234567890', fullName: 'Learner $id'),
  );
  await LocalStorage.saveToken(token(id));
}

const item = {
  'content_type': 'course',
  'content_key': 'course-1',
  'item_key': 'content-2',
};

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Dio dio;
  late ProgressStore store;
  late List<RequestOptions> requests;
  bool offline = false, blocked = false;
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await login(1);
    requests = [];
    offline = false;
    blocked = false;
    dio = Dio();
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (request, handler) {
          requests.add(request);
          if (offline ||
              (blocked &&
                  request.data is Map &&
                  request.data['item_key'] == 'content-2')) {
            handler.reject(
              DioException(
                requestOptions: request,
                type: DioExceptionType.connectionError,
                response: offline
                    ? null
                    : Response(requestOptions: request, statusCode: 403),
              ),
            );
            return;
          }
          final data = request.data as Map? ?? {};
          handler.resolve(
            Response(
              requestOptions: request,
              statusCode: 200,
              data: {
                'progress': request.path == Endpoints.learningProgress
                    ? {
                        'language':
                            request.queryParameters['language'] ?? 'English',
                        'total_items': 10,
                        'completed_items': 2,
                        'topics': [],
                      }
                    : {
                        'metadata': {
                          'session_id':
                              data['next_session_id'] ??
                              data['session_id'] ??
                              'server-session',
                        },
                        'completed_item_keys': [],
                      },
              },
            ),
          );
        },
      ),
    );
    store = ProgressStore(dio);
  });
  tearDown(() => store.dispose());

  test(
    'offline events survive relaunch and retry with exactly the same event id',
    () async {
      offline = true;
      final result = await store.submit(
        Endpoints.contentProgressItem,
        'POST',
        item,
      );
      expect(result['metadata']['pending_sync'], true);
      expect(store.pending, 1);
      final event = requests.single.data['event_id'];
      store.dispose();
      store = ProgressStore(dio);
      offline = false;
      await store.refresh('English');
      expect(requests[1].data['event_id'], event);
      expect(store.pending, 0);
      expect(store.overview!.completed, 2);
      expect(store.overview!.percent, 20);
    },
  );
  test(
    'switching users never flushes another user queue and restores it on return',
    () async {
      offline = true;
      await store.submit(Endpoints.contentProgressItem, 'POST', item);
      await login(2);
      offline = false;
      requests.clear();
      await store.refresh('English');
      expect(requests.every((r) => r.method == 'GET'), true);
      expect(store.pending, 0);
      await login(1);
      await store.refresh('English');
      final mutation = requests.singleWhere((r) => r.method == 'POST');
      expect(mutation.headers['Authorization'], 'Bearer ${token(1)}');
      expect(store.pending, 0);
    },
  );
  test('mismatched token cannot upload stored work', () async {
    await LocalStorage.saveToken(token(2));
    await store.submit(Endpoints.contentProgressItem, 'POST', item);
    expect(requests, isEmpty);
    expect(store.pending, 1);
  });
  test(
    'blocked premium event remains saved without blocking other topics',
    () async {
      blocked = true;
      await store.submit(Endpoints.contentProgressItem, 'POST', item);
      await store.submit(Endpoints.contentProgressItem, 'POST', {
        ...item,
        'item_key': 'content-3',
      });
      expect(store.pending, 1);
      expect(store.needsAttention, 1);
      blocked = false;
      await store.refresh();
      expect(store.pending, 0);
      expect(store.needsAttention, 0);
    },
  );
  test(
    'offline restart retains session identity across relaunch and subsequent practice',
    () async {
      offline = true;
      await store.submit(Endpoints.contentProgressRestart, 'POST', item);
      final session = requests.first.data['next_session_id'];
      store.dispose();
      store = ProgressStore(dio);
      await store.submit(Endpoints.contentProgressItem, 'POST', item);
      final prefs = await SharedPreferences.getInstance();
      final queue =
          jsonDecode(prefs.getString('learning_progress_outbox_1')!) as List;
      expect(queue.last['data']['session_id'], session);
      offline = false;
      await store.refresh('English');
      expect(store.pending, 0);
      await store.submit(Endpoints.contentProgressItem, 'POST', item);
      expect(requests.last.data['session_id'], session);
    },
  );
  test(
    'late response and waiting events cannot leak across accounts',
    () async {
      dio.interceptors.clear();
      final started = Completer<void>(), release = Completer<void>();
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (request, handler) async {
            requests.add(request);
            if (!started.isCompleted) started.complete();
            await release.future;
            handler.resolve(
              Response(
                requestOptions: request,
                statusCode: 200,
                data: {
                  'progress': {
                    'metadata': {'session_id': 'old-user'},
                  },
                },
              ),
            );
          },
        ),
      );
      final first = store.submit(Endpoints.contentProgressItem, 'POST', item);
      await started.future;
      final second = store.submit(Endpoints.contentProgressItem, 'POST', item);
      // Allow submit to capture its owner before changing the stored session.
      await Future<void>.delayed(Duration.zero);
      final rejected = expectLater(second, throwsStateError);
      await login(2);
      await store.bindAccount();
      release.complete();
      await first;
      await rejected;
      expect(requests.length, 1);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('learning_progress_sessions_2'), isNull);
      expect(prefs.getString('learning_progress_outbox_2'), isNull);
    },
  );
  test(
    'language changes requested during a refresh resolve to the latest scope',
    () async {
      await Future.wait([store.refresh('English'), store.refresh('Hindi')]);
      expect(store.overview!.language, 'Hindi');
    },
  );
}
