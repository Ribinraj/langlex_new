import 'package:dio/dio.dart';
import 'package:langlex_new_app/core/api_exception.dart';
import 'package:langlex_new_app/core/network_services.dart';
import 'package:langlex_new_app/core/urls.dart';
import 'package:langlex_new_app/features/learning/models/learning_models.dart';

class LearningRepository {
  LearningRepository(this._dio);

  final Dio _dio;

  Future<LearningCatalog> fetchCatalog() async {
    try {
      final responses = await Future.wait([
        _get(Endpoints.languages),
        _get(Endpoints.courses),
        _get(Endpoints.content),
        _get(Endpoints.alphabets),
        _get(Endpoints.quizzes),
        _get(Endpoints.phonics),
        _get(Endpoints.stories),
        _get(Endpoints.plans),
        _get(Endpoints.learningSetup, skipAuth: false),
        _get('${Endpoints.dailyGoal}?date=${_todayDate()}', skipAuth: false),
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
        dailyGoal: _mapFromResponse(responses[9], 'daily_goal'),
      );
    } on DioException catch (error) {
      throw ApiException.fromDio(error);
    }
  }

  Future<Response<Map<String, dynamic>>> _get(
    String endpoint, {
    bool skipAuth = true,
  }) {
    return _dio.get<Map<String, dynamic>>(
      endpoint,
      options: Options(extra: {DioClient.skipAuthKey: skipAuth}),
    );
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

  Future<DailyGoal> recordDailyProgress({
    required String activityType,
    required String activityKey,
    int? estimatedMinutes,
  }) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        Endpoints.dailyGoalProgress,
        data: {
          'activity_date': _todayDate(),
          'activity_type': activityType,
          'activity_key': activityKey,
          'estimated_minutes': estimatedMinutes,
        },
      );

      return DailyGoal.fromJson(_mapFromResponse(response, 'daily_goal'));
    } on DioException catch (error) {
      throw ApiException.fromDio(error);
    }
  }

  Future<ContentProgress> getContentProgress({
    required String contentType,
    required String contentKey,
  }) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        Endpoints.contentProgress,
        queryParameters: {
          'content_type': contentType,
          'content_key': contentKey,
        },
      );
      return ContentProgress.fromJson(_mapFromResponse(response, 'progress'));
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
      final response = await _dio.put<Map<String, dynamic>>(
        Endpoints.contentProgress,
        data: {
          'content_type': contentType,
          'content_key': contentKey,
          'status': status,
          'position': position,
          'total_items': totalItems,
          'score': score,
        },
      );
      return ContentProgress.fromJson(_mapFromResponse(response, 'progress'));
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
  }) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        Endpoints.contentProgressItem,
        data: {
          'content_type': contentType,
          'content_key': contentKey,
          'item_key': itemKey,
          'position': position,
          'total_items': totalItems,
          'status': status,
          'is_correct': isCorrect,
        },
      );
      return ContentProgress.fromJson(_mapFromResponse(response, 'progress'));
    } on DioException catch (error) {
      throw ApiException.fromDio(error);
    }
  }

  Future<ContentProgress> restartContentProgress({
    required String contentType,
    required String contentKey,
  }) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        Endpoints.contentProgressRestart,
        data: {
          'content_type': contentType,
          'content_key': contentKey,
          'position': 0,
          'total_items': 0,
        },
      );
      return ContentProgress.fromJson(_mapFromResponse(response, 'progress'));
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

  String _todayDate() {
    final now = DateTime.now();
    final month = now.month.toString().padLeft(2, '0');
    final day = now.day.toString().padLeft(2, '0');
    return '${now.year}-$month-$day';
  }
}
