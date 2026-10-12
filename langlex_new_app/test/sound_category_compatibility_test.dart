import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:langlex_new_app/features/learning/learning_repo.dart';

void main() {
  test('older APIs group words into unique categories before paging', () async {
    final requests = <RequestOptions>[];
    final dio = Dio();
    final rows = List.generate(
      103,
      (i) => {
        'id': i + 1,
        'word': i == 0 ? 'काक' : 'Word $i',
        'coursename': i < 101
            ? 'नाक उच्चारण वाले शब्द'
            : 'दिन उच्चारण वाले शब्द',
        'language': 'Hindi',
      },
    );
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (request, handler) {
          requests.add(request);
          final page = request.queryParameters['page'] as int;
          final limit = request.queryParameters['limit'] as int;
          final course = request.queryParameters['course'];
          final filtered = rows
              .where((row) => course == null || row['coursename'] == course)
              .toList();
          // This simulates the live API ignoring view=courses.
          handler.resolve(
            Response(
              requestOptions: request,
              data: {
                'phonics': filtered
                    .skip((page - 1) * limit)
                    .take(limit)
                    .toList(),
                'pagination': {
                  'page': page,
                  'limit': limit,
                  'total': filtered.length,
                },
              },
            ),
          );
        },
      ),
    );
    final repository = LearningRepository(dio);
    final first = await repository.fetchSoundCategories(
      language: 'Hindi',
      limit: 1,
    );
    expect(first.total, 2);
    expect(first.items.single['title'], 'नाक उच्चारण वाले शब्द');
    expect(first.items.single['sound_count'], 101);
    expect(first.items.single['id'], 1);
    expect(requests.length, 3);
    final second = await repository.fetchSoundCategories(
      language: 'Hindi',
      page: 2,
      limit: 1,
    );
    expect(second.items.single['title'], 'दिन उच्चारण वाले शब्द');
    expect(second.items.single['sound_count'], 2);
    expect(second.items.single['id'], 102);
    expect(second.hasMore, isFalse);
    expect(requests.length, 3);

    final selected = await repository.fetchPage(
      'phonics',
      (row) => row,
      filters: {'language': 'Hindi', 'course': second.items.single['title']},
    );
    expect(selected.items.map((row) => row['id']), [102, 103]);
    expect(selected.items.any((row) => row['word'] == 'काक'), isFalse);
    await repository.fetchSoundCategories(language: 'Hindi', limit: 1);
    expect(requests.length, 7); // Reopening refreshes the legacy catalog.
  });

  test('grouped APIs keep category pagination on the server', () async {
    final requests = <RequestOptions>[];
    final dio = Dio();
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (request, handler) {
          requests.add(request);
          handler.resolve(
            Response(
              requestOptions: request,
              data: {
                'phonics': [
                  {
                    'id': 1,
                    'title': 'नाक उच्चारण वाले शब्द',
                    'sound_count': 49,
                  },
                ],
                'pagination': {'page': 1, 'limit': 20, 'total': 65},
              },
            ),
          );
        },
      ),
    );
    final result = await LearningRepository(
      dio,
    ).fetchSoundCategories(language: 'Hindi');
    expect(result.total, 65);
    expect(result.items.single['sound_count'], 49);
    expect(requests.length, 1);
    expect(requests.single.queryParameters['view'], 'courses');
  });
}
