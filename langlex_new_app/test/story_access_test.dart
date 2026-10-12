import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:langlex_new_app/features/learning/learning_repo.dart';
import 'package:langlex_new_app/features/learning/models/learning_models.dart';

void main() {
  test(
    'locked story keeps its preview and reloads full passages after upgrade',
    () async {
      final preview = StoryItem.fromJson({
        'id': 42,
        'title': 'A story',
        'language': 'English',
        'grade': 'Nursery',
        'show_plan': 'Premium',
        'locked': true,
        'reading_minutes': 7,
        'text': '',
        'sections': [],
      });
      expect(preview.isLocked, isTrue);
      expect(preview.minutes, 7);
      final dio = Dio(BaseOptions(baseUrl: 'https://example.test/api/'));
      final calls = <RequestOptions>[];
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (request, handler) {
            calls.add(request);
            handler.resolve(
              Response(
                requestOptions: request,
                statusCode: 200,
                data: {
                  'story': {
                    'id': 42,
                    'title': 'A story',
                    'language': 'English',
                    'grade': 'Nursery',
                    'show_plan': 'Premium',
                    'locked': false,
                    'text': 'Part one. Part two.',
                    'sections': [
                      {'text': 'Part one.'},
                      {'text': 'Part two.'},
                    ],
                  },
                },
              ),
            );
          },
        ),
      );
      final repository = LearningRepository(dio);
      final readable = await repository.openStory(preview);
      expect(calls.single.path, 'stories/42');
      expect(calls.single.queryParameters['language'], 'English');
      expect(readable.isLocked, isFalse);
      expect(readable.sections.length, 2);
      expect(readable.text, contains('Part two'));
      expect(await repository.openStory(readable), same(readable));
      expect(calls.length, 1);
    },
  );

  test('failed unlock never opens an empty story', () async {
    final dio = Dio(BaseOptions(baseUrl: 'https://example.test/api/'));
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (request, handler) {
          handler.reject(
            DioException(
              requestOptions: request,
              type: DioExceptionType.badResponse,
              response: Response(
                requestOptions: request,
                statusCode: 403,
                data: {'message': 'Premium required'},
              ),
            ),
          );
        },
      ),
    );
    final preview = StoryItem.fromJson({
      'id': 42,
      'locked': true,
      'show_plan': 'Premium',
    });
    await expectLater(
      LearningRepository(dio).openStory(preview),
      throwsException,
    );
    expect(preview.isLocked, isTrue);
  });
}
