import 'package:dio/dio.dart';
import 'package:langlex_new_app/core/api_exception.dart';
import 'package:langlex_new_app/core/urls.dart';
import 'package:langlex_new_app/features/notifications/models/app_notification.dart';

class NotificationRepository {
  NotificationRepository(this._dio);

  final Dio _dio;

  Future<NotificationInbox> fetchNotifications() async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        Endpoints.notifications,
      );
      final rows = response.data?['notifications'];
      return NotificationInbox(
        notifications: rows is List
            ? rows
                  .whereType<Map>()
                  .map(
                    (row) => AppNotification.fromJson(
                      Map<String, dynamic>.from(row),
                    ),
                  )
                  .toList()
            : const [],
        unreadCount: _asInt(response.data?['unread_count']),
      );
    } on DioException catch (error) {
      throw ApiException.fromDio(error);
    }
  }

  Future<int> getUnreadCount() async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        Endpoints.notificationUnreadCount,
      );
      return _asInt(response.data?['unread_count']);
    } on DioException catch (error) {
      throw ApiException.fromDio(error);
    }
  }

  Future<int> markRead(int id) async {
    try {
      final response = await _dio.patch<Map<String, dynamic>>(
        Endpoints.markNotificationRead(id),
      );
      return _asInt(response.data?['unread_count']);
    } on DioException catch (error) {
      throw ApiException.fromDio(error);
    }
  }

  Future<void> markAllRead() async {
    try {
      await _dio.patch<Map<String, dynamic>>(
        Endpoints.markAllNotificationsRead,
      );
    } on DioException catch (error) {
      throw ApiException.fromDio(error);
    }
  }
}

class NotificationInbox {
  const NotificationInbox({
    required this.notifications,
    required this.unreadCount,
  });

  final List<AppNotification> notifications;
  final int unreadCount;
}

int _asInt(dynamic value) {
  if (value is int) return value;
  return int.tryParse(value?.toString() ?? '') ?? 0;
}
