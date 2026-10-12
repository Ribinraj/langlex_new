import 'package:langlex_new_app/features/progress/progress_store.dart';
import 'package:dio/dio.dart';
import 'package:langlex_new_app/core/api_exception.dart';
import 'package:langlex_new_app/core/network_services.dart';
import 'package:langlex_new_app/core/urls.dart';
import 'package:langlex_new_app/features/learning/models/learning_models.dart';

class LearningRepository {
  LearningRepository(this._dio);

  final Dio _dio;
  late final ProgressStore progress = ProgressStore(_dio);
  final _legacySoundCategories = <String, List<Map<String, dynamic>>>{};
  final _legacyQuizQuestions = <String, List<Map<String, dynamic>>>{};

  // A set is a topic, never an arbitrary API page of question rows.
  Future<CatalogPage<Map<String, dynamic>>> fetchQuizTopics({
    required String language,
    String search = '',
    int page = 1,
    int limit = 12,
  }) async {
    if (page == 1 && search.trim().isEmpty) {
      _legacyQuizQuestions.remove(language);
    }
    var legacy = _legacyQuizQuestions[language];
    if (legacy == null) {
      final result = await fetchPage<Map<String, dynamic>>(
        Endpoints.quizzes,
        (row) => row,
        page: page,
        limit: limit,
        filters: {'language': language, 'search': search, 'view': 'sets'},
      );
      if (result.items.isEmpty ||
          result.items.every((row) => row.containsKey('question_count'))) {
        return result;
      }
      // The deployed legacy API ignores view=sets. Group its bounded pages in
      // the client too, so old servers cannot bring back duplicate quiz cards.
      legacy = await _fetchQuizRows(language: language);
      _legacyQuizQuestions[language] = legacy;
    }
    final topics = <String, Map<String, dynamic>>{};
    final matches = <String>{};
    final query = search.trim().toLowerCase();
    for (final row in legacy) {
      final topic = row['topic']?.toString() ?? '';
      final entry = topics.putIfAbsent(
        topic,
        () => {
          'id': row['id'],
          'topic': topic,
          'language': language,
          'question_count': 0,
        },
      );
      entry['question_count'] = (entry['question_count'] as int) + 1;
      if (query.isEmpty ||
          topic.toLowerCase().contains(query) ||
          (row['Question']?.toString() ?? '').toLowerCase().contains(query)) {
        matches.add(topic);
      }
    }
    final items = topics.entries
        .where((entry) => matches.contains(entry.key))
        .map((entry) => entry.value)
        .toList();
    return CatalogPage(
      items: items.skip((page - 1) * limit).take(limit).toList(),
      page: page,
      limit: limit,
      total: items.length,
    );
  }

  Future<List<QuizQuestion>> fetchQuizTopicQuestions({
    required String language,
    required String topic,
  }) async {
    if (topic.trim().isEmpty) return const [];
    final cached = _legacyQuizQuestions[language];
    final rows = cached != null
        ? cached.where((row) => row['topic']?.toString() == topic).toList()
        : await _fetchQuizRows(language: language, topic: topic);
    return rows.map(QuizQuestion.fromJson).toList();
  }

  Future<List<Map<String, dynamic>>> _fetchQuizRows({
    required String language,
    String? topic,
  }) async {
    final rows = <Map<String, dynamic>>[];
    final seenIds = <String>{};
    for (var page = 1; ; page++) {
      final result = await fetchPage<Map<String, dynamic>>(
        Endpoints.quizzes,
        (row) => row,
        page: page,
        limit: 100,
        filters: {'language': language, 'topic': ?topic},
      );
      for (final row in result.items) {
        if (!seenIds.add('${row['id']}')) {
          throw const FormatException(
            'Quiz pagination repeated a question page.',
          );
        }
        // Different database IDs remain separate questions, even when their
        // content is identical. Only a repeated API row is a pagination error.
        rows.add(row);
      }
      if (!result.hasMore || result.items.isEmpty) break;
    }
    return rows;
  }

  Future<CatalogPage<Map<String, dynamic>>> fetchSoundCategories({
    required String language,
    int page = 1,
    int limit = 20,
  }) async {
    CatalogPage<Map<String, dynamic>> categoryPage(
      List<Map<String, dynamic>> items,
    ) => CatalogPage(
      items: items.skip((page - 1) * limit).take(limit).toList(),
      page: page,
      limit: limit,
      total: items.length,
    );

    // Reuse the completed legacy grouping while scrolling, but refresh it when
    // the user reopens the catalog. New servers page categories directly.
    final cached = page > 1 ? _legacySoundCategories[language] : null;
    if (cached != null) return categoryPage(cached);
    _legacySoundCategories.remove(language);
    final result = await fetchPage<Map<String, dynamic>>(
      Endpoints.phonics,
      (row) => row,
      page: page,
      limit: limit,
      filters: {'language': language, 'view': 'courses'},
    );
    if (result.items.isEmpty ||
        result.items.every(
          (row) => row.containsKey('title') && row.containsKey('sound_count'),
        )) {
      return result;
    }

    // Older deployed APIs ignore view=courses and return one row per word.
    // Never treat these rows as category cards: their absent title would cause
    // every Start button to request the entire language from its first word.
    final categories = <String, Map<String, dynamic>>{};
    final seenIds = <String>{};
    for (var sourcePage = 1; ; sourcePage++) {
      final words = await fetchPage<Map<String, dynamic>>(
        Endpoints.phonics,
        (row) => row,
        page: sourcePage,
        limit: 100,
        filters: {'language': language},
      );
      for (final word in words.items) {
        final title = word['coursename']?.toString().trim() ?? '';
        if (title.isEmpty || !seenIds.add('${word['id']}')) continue;
        final category = categories.putIfAbsent(
          title,
          () => {
            'id': word['id'],
            'title': title,
            'language': language,
            'sound_count': 0,
          },
        );
        category['sound_count'] = (category['sound_count'] as int) + 1;
      }
      if (!words.hasMore || words.items.isEmpty) break;
    }
    final grouped = categories.values.toList();
    _legacySoundCategories[language] = grouped;
    return categoryPage(grouped);
  }

  Future<LearningCatalog> fetchCatalog() async {
    try {
      final setupResponse = await _get(
        Endpoints.learningSetup,
        skipAuth: false,
      );
      final setup = _mapFromResponse(setupResponse, 'learning_setup');
      final language =
          (setup?['active_language'] ?? setup?['learning_language'])
              ?.toString() ??
          'English';
      final level = setup?['level']?.toString() ?? 'Nursery';
      if ((setup?['selected_languages'] as List? ?? const []).length != 3) {
        final initial = await Future.wait([
          _get(Endpoints.languages),
          _get(Endpoints.plans),
        ]);
        return LearningCatalog.fromApi(
          languages: _listFromResponse(initial[0], 'languages'),
          plans: _listFromResponse(initial[1], 'plans'),
          setup: setup,
          courses: const [],
          content: const [],
          alphabets: const [],
          quizzes: const [],
          phonics: const [],
          stories: const [],
        );
      }

      final responses = await Future.wait([
        _get(Endpoints.languages),
        _get(
          Endpoints.courses,
          query: {'language': language, 'level': level, 'limit': 12},
        ),
        _get(
          Endpoints.content,
          query: {'language': language, 'level': level, 'limit': 20},
        ),
        _get(
          Endpoints.alphabets,
          query: {'language': language, 'limit': 12, 'view': 'letters'},
        ),
        _get(Endpoints.quizzes, query: {'language': language, 'limit': 10}),
        _get(Endpoints.phonics, query: {'language': language, 'limit': 1}),
        _get(
          Endpoints.stories,
          query: {'language': language, 'level': level, 'limit': 6},
        ),
        _get(Endpoints.plans),
        Future.value(setupResponse),
      ]);

      return LearningCatalog.fromApi(
        languages: _listFromResponse(responses[0], 'languages'),
        courses: _listFromResponse(responses[1], 'courses'),
        content: _listFromResponse(responses[2], 'content'),
        alphabets: _listFromResponse(responses[3], 'alphabets'),
        quizzes: _listFromResponse(responses[4], 'quizzes'),
        phonics: _listFromResponse(responses[5], 'phonics'),
        stories: _listFromResponse(responses[6], 'stories'),
        plans: _listFromResponse(responses[7], 'plans'),
        setup: _mapFromResponse(responses[8], 'learning_setup'),
        totals: {
          for (final entry in {
            'courses': 1,
            'content': 2,
            'alphabets': 3,
            'quizzes': 4,
            'phonics': 5,
            'stories': 6,
          }.entries)
            entry.key:
                (responses[entry.value].data?['pagination']?['total'] as num?)
                    ?.toInt() ??
                0,
        },
      );
    } on DioException catch (error) {
      throw ApiException.fromDio(error);
    }
  }

  Future<Response<Map<String, dynamic>>> _get(
    String endpoint, {
    bool skipAuth = false,
    Map<String, dynamic>? query,
  }) {
    return _dio.get<Map<String, dynamic>>(
      endpoint,
      queryParameters: query,
      options: Options(extra: {DioClient.skipAuthKey: skipAuth}),
    );
  }

  Future<CatalogPage<T>> fetchPage<T>(
    String resource,
    T Function(Map<String, dynamic>) parse, {
    int page = 1,
    int limit = 20,
    Map<String, dynamic> filters = const {},
  }) async {
    try {
      final response = await _get(
        resource,
        query: {...filters, 'page': page, 'limit': limit},
      );
      final rows = _listFromResponse(response, resource);
      final paging = response.data?['pagination'] as Map? ?? const {};
      return CatalogPage<T>(
        items: rows
            .whereType<Map>()
            .map((row) => parse(Map<String, dynamic>.from(row)))
            .toList(),
        page: (paging['page'] as num?)?.toInt() ?? page,
        limit: (paging['limit'] as num?)?.toInt() ?? limit,
        total: (paging['total'] as num?)?.toInt() ?? rows.length,
      );
    } on DioException catch (error) {
      throw ApiException.fromDio(error);
    }
  }

  Future<LearningSetup> saveLearningSetup(
    LearningSetup setup, {
    required LearningCatalog catalog,
  }) async {
    try {
      final response = await _dio.put<Map<String, dynamic>>(
        Endpoints.learningSetup,
        data: setup.toJson(),
      );
      return LearningSetup.fromJson(
        _mapFromResponse(response, 'learning_setup'),
        languages: catalog.languages,
        plans: catalog.plans,
      );
    } on DioException catch (error) {
      throw ApiException.fromDio(error);
    }
  }

  Future<StoryItem> openStory(StoryItem story) async {
    if (!story.isLocked) return story;
    try {
      final response = await _get(
        '${Endpoints.stories}/${story.id}',
        query: {'language': story.language},
      );
      final data = _mapFromResponse(response, 'story');
      if (data == null) throw const FormatException('Story is unavailable.');
      return StoryItem.fromJson(data);
    } on DioException catch (error) {
      throw ApiException.fromDio(error);
    }
  }

  Future<List<SubscriptionPlan>> fetchPlans() async {
    final response = await _get(Endpoints.plans);
    return (response.data?['plans'] as List? ?? const [])
        .whereType<Map>()
        .map((row) => SubscriptionPlan.fromJson(Map<String, dynamic>.from(row)))
        .toList();
  }

  Future<bool> hasPremiumAccess() async {
    final response = await _dio.get<Map<String, dynamic>>(
      Endpoints.mySubscription,
    );
    final subscription = response.data?['subscription'] as Map?;
    final expiry = DateTime.tryParse('${subscription?['expires_at']}');
    final started = DateTime.tryParse('${subscription?['started_at']}');
    return subscription?['status'] == 'active' &&
        started != null &&
        !started.isAfter(DateTime.now()) &&
        '${subscription?['type']}'.toLowerCase() == 'premium' &&
        (expiry == null || expiry.isAfter(DateTime.now()));
  }

  Future<ContentProgress> getContentProgress({
    required String contentType,
    required String contentKey,
  }) async {
    try {
      final data = await progress.readSession(contentType, contentKey);
      return ContentProgress.fromJson(data);
    } on DioException catch (error) {
      throw ApiException.fromDio(error);
    }
  }

  Future<ContentProgress> saveContentProgress({
    required String contentType,
    required String contentKey,
    required int position,
    required int totalItems,
    String status = 'in_progress',
    int score = 0,
  }) async {
    try {
      final data = await progress.submit(Endpoints.contentProgress, 'PUT', {
        'content_type': contentType,
        'content_key': contentKey,
        'status': status,
        'position': position,
        'total_items': totalItems,
        'score': score,
      });
      return ContentProgress.fromJson(data);
    } on DioException catch (error) {
      throw ApiException.fromDio(error);
    }
  }

  Future<ContentProgress> recordContentItem({
    required String contentType,
    required String contentKey,
    required String itemKey,
    required int position,
    required int totalItems,
    String status = 'in_progress',
    bool? isCorrect,
    String? answer,
  }) async {
    try {
      final data = await progress
          .submit(Endpoints.contentProgressItem, 'POST', {
            'content_type': contentType,
            'content_key': contentKey,
            'item_key': itemKey,
            'position': position,
            'total_items': totalItems,
            'status': status,
            'is_correct': isCorrect,
            'answer': ?answer,
          });
      return ContentProgress.fromJson(data);
    } on DioException catch (error) {
      throw ApiException.fromDio(error);
    }
  }

  Future<ContentProgress> restartContentProgress({
    required String contentType,
    required String contentKey,
  }) async {
    try {
      final data = await progress
          .submit(Endpoints.contentProgressRestart, 'POST', {
            'content_type': contentType,
            'content_key': contentKey,
            'position': 0,
            'total_items': 0,
          });
      return ContentProgress.fromJson(data);
    } on DioException catch (error) {
      throw ApiException.fromDio(error);
    }
  }

  List<dynamic> _listFromResponse(
    Response<Map<String, dynamic>> response,
    String key,
  ) {
    final value = response.data?[key];
    return value is List ? value : const [];
  }

  Map<String, dynamic>? _mapFromResponse(
    Response<Map<String, dynamic>> response,
    String key,
  ) {
    final value = response.data?[key];
    if (value is Map<String, dynamic>) return value;
    if (value is Map) return Map<String, dynamic>.from(value);
    return null;
  }
}

class CatalogPage<T> {
  const CatalogPage({
    required this.items,
    required this.page,
    required this.limit,
    required this.total,
  });
  final List<T> items;
  final int page;
  final int limit;
  final int total;
  bool get hasMore => page * limit < total;
  int get pages => (total / limit).ceil();
}
