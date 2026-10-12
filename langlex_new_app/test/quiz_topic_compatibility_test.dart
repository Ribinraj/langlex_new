import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:langlex_new_app/features/learning/learning_repo.dart';

void main() {
  test(
    'legacy quiz pages preserve repeated database exercises and keep topics whole',
    () async {
      final dio = Dio();
      final requests = <RequestOptions>[];
      final rows = <Map<String, dynamic>>[
        for (var i = 1; i <= 102; i++)
          {
            'id': i,
            'Question': 'Listen and choose',
            'ca': 'A',
            'o1': 'Distractor $i',
            'audio': 'letter-a.mp3',
            'topic': 'Alphabet Letter Recognition',
            'Language': 'English',
          },
        {
          'id': 103,
          'Question': 'Listen and choose',
          'ca': 'B',
          'audio': 'letter-b.mp3',
          'topic': 'Alphabet Letter Recognition',
          'Language': 'English',
        },
        {
          'id': 104,
          'Question': 'Choose the sound for this letter',
          'ca': 'letter-a.mp3',
          'image': 'a.png',
          'topic': 'Alphabet Letter Recognition',
          'Language': 'English',
        },
        {
          'id': 105,
          'Question': 'Name this animal',
          'ca': 'Cat',
          'topic': 'Animals',
          'Language': 'English',
        },
      ];
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (request, handler) {
            requests.add(request);
            final page = request.queryParameters['page'] as int;
            final limit = request.queryParameters['limit'] as int;
            handler.resolve(
              Response(
                requestOptions: request,
                data: {
                  'quizzes': rows.skip((page - 1) * limit).take(limit).toList(),
                  'pagination': {
                    'page': page,
                    'limit': limit,
                    'total': rows.length,
                  },
                },
              ),
            );
          },
        ),
      );
      final repo = LearningRepository(dio);
      final first = await repo.fetchQuizTopics(language: 'English', limit: 1);
      expect(first.total, 2);
      expect(first.items.single['topic'], 'Alphabet Letter Recognition');
      expect(first.items.single['question_count'], 104);
      expect(requests.length, 3);
      final second = await repo.fetchQuizTopics(
        language: 'English',
        page: 2,
        limit: 1,
      );
      expect(second.items.single['topic'], 'Animals');
      expect(second.items.single['question_count'], 1);
      expect(second.hasMore, false);
      final questions = await repo.fetchQuizTopicQuestions(
        language: 'English',
        topic: 'Alphabet Letter Recognition',
      );
      expect(questions.map((q) => q.id), List.generate(104, (i) => i + 1));
      expect(
        questions.take(102).map((q) => q.correctAnswer),
        everyElement('A'),
      );
      expect(questions.skip(102).map((q) => q.correctAnswer), [
        'B',
        'letter-a.mp3',
      ]);
      final searched = await repo.fetchQuizTopics(
        language: 'English',
        search: 'Listen',
      );
      expect(searched.items.single['question_count'], 104);
      expect(requests.length, 3);
    },
  );

  test(
    'new servers load topic summaries without scanning every quiz',
    () async {
      final dio = Dio();
      final requests = <RequestOptions>[];
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (request, handler) {
            requests.add(request);
            expect(request.queryParameters['view'], 'sets');
            expect(request.queryParameters['search'], 'letter');
            handler.resolve(
              Response(
                requestOptions: request,
                data: {
                  'quizzes': [
                    {
                      'id': 693,
                      'topic': 'Alphabet Letter Recognition',
                      'language': 'English',
                      'question_count': 308,
                    },
                  ],
                  'pagination': {'page': 1, 'limit': 12, 'total': 1},
                },
              ),
            );
          },
        ),
      );
      final page = await LearningRepository(
        dio,
      ).fetchQuizTopics(language: 'English', search: 'letter');
      expect(page.items.single['question_count'], 308);
      expect(requests.length, 1);
    },
  );

  test('failed later pages do not cache an incomplete topic', () async {
    var fail = true;
    final dio = Dio();
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (request, handler) {
          final page = request.queryParameters['page'] as int;
          if (page == 2 && fail) {
            handler.reject(DioException(requestOptions: request));
            return;
          }
          handler.resolve(
            Response(
              requestOptions: request,
              data: {
                'quizzes': [
                  {
                    'id': page,
                    'topic': 'Letters',
                    'Question': 'Question $page',
                    'ca': '$page',
                  },
                ],
                'pagination': {'page': page, 'limit': 1, 'total': 2},
              },
            ),
          );
        },
      ),
    );
    final repo = LearningRepository(dio);
    await expectLater(
      repo.fetchQuizTopics(language: 'English'),
      throwsException,
    );
    fail = false;
    final result = await repo.fetchQuizTopics(language: 'English');
    expect(result.items.single['question_count'], 2);
    final questions = await repo.fetchQuizTopicQuestions(
      language: 'English',
      topic: 'Letters',
    );
    expect(questions.map((q) => q.id), [1, 2]);
  });
}
