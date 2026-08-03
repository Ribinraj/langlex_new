import 'dart:async';
import 'dart:convert';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:langlex_new_app/core/local_storage.dart';
import 'package:langlex_new_app/firebase_options.dart';

const String _notificationChannelId = 'langlex_notifications';
const String _notificationChannelName = 'LangLex Notifications';
const String _notificationChannelDescription =
    'Learning reminders and app updates from LangLex.';

const AndroidNotificationChannel _androidChannel = AndroidNotificationChannel(
  _notificationChannelId,
  _notificationChannelName,
  description: _notificationChannelDescription,
  importance: Importance.max,
);

final FlutterLocalNotificationsPlugin _localNotifications =
    FlutterLocalNotificationsPlugin();

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await PushNotificationService.initializeFirebase();
  await PushNotificationService.showBackgroundNotification(message);
}

@pragma('vm:entry-point')
void localNotificationTapBackground(NotificationResponse response) {}

class PushNotificationService {
  PushNotificationService._();

  static final PushNotificationService instance = PushNotificationService._();

  bool _initialized = false;
  bool _localNotificationsInitialized = false;
  StreamSubscription<String>? _tokenRefreshSubscription;
  StreamSubscription<RemoteMessage>? _foregroundMessageSubscription;
  Future<void> Function(String token)? _tokenRefreshHandler;
  void Function(Map<String, dynamic> data)? _onNotificationTap;

  static Future<void> initializeFirebase() async {
    if (Firebase.apps.isNotEmpty) return;
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  }

  static Future<void> showBackgroundNotification(RemoteMessage message) async {
    if (message.notification != null) return;
    await instance._ensureLocalNotificationsInitialized();
    await instance._showLocalNotification(message);
  }

  Future<void> initialize({
    void Function(Map<String, dynamic> data)? onNotificationTap,
  }) async {
    if (kIsWeb) return;
    _onNotificationTap = onNotificationTap ?? _onNotificationTap;

    try {
      await initializeFirebase();
      await _ensureLocalNotificationsInitialized();
      FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

      final messaging = FirebaseMessaging.instance;
      await messaging.setForegroundNotificationPresentationOptions(
        alert: false,
        badge: false,
        sound: false,
      );
      await _requestPermissions(messaging);

      _foregroundMessageSubscription ??= FirebaseMessaging.onMessage.listen(
        _showLocalNotification,
      );

      FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationTap);
      final initialMessage = await messaging.getInitialMessage();
      if (initialMessage != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _handleNotificationTap(initialMessage);
        });
      }

      _tokenRefreshSubscription ??= messaging.onTokenRefresh.listen((
        token,
      ) async {
        await LocalStorage.saveFcmToken(token);
        await _tokenRefreshHandler?.call(token);
      });

      _initialized = true;
    } catch (error) {
      debugPrint('[PushNotificationService] Firebase init failed: $error');
    }
  }

  void setTokenRefreshHandler(Future<void> Function(String token) handler) {
    _tokenRefreshHandler = handler;
  }

  Future<String> getPushToken() async {
    if (kIsWeb) return '';

    try {
      if (!_initialized) {
        await initialize();
      }

      final messaging = FirebaseMessaging.instance;
      await _requestPermissions(messaging);
      final token = await messaging.getToken() ?? '';

      if (token.isNotEmpty) {
        await LocalStorage.saveFcmToken(token);
      }

      return token;
    } catch (error) {
      debugPrint('[PushNotificationService] FCM unavailable: $error');
      return LocalStorage.getFcmToken();
    }
  }

  void _handleNotificationTap(RemoteMessage message) {
    _onNotificationTap?.call(message.data);
  }

  Future<void> _ensureLocalNotificationsInitialized() async {
    if (_localNotificationsInitialized) return;

    const initializationSettings = InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      iOS: DarwinInitializationSettings(
        requestAlertPermission: false,
        requestBadgePermission: false,
        requestSoundPermission: false,
      ),
    );

    await _localNotifications.initialize(
      settings: initializationSettings,
      onDidReceiveNotificationResponse: _handleLocalNotificationTap,
      onDidReceiveBackgroundNotificationResponse:
          localNotificationTapBackground,
    );

    await _localNotifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(_androidChannel);

    _localNotificationsInitialized = true;
  }

  Future<void> _requestPermissions(FirebaseMessaging messaging) async {
    await messaging.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );

    await _localNotifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.requestNotificationsPermission();

    await _localNotifications
        .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >()
        ?.requestPermissions(alert: true, badge: true, sound: true);
  }

  Future<void> _showLocalNotification(RemoteMessage message) async {
    final title = _notificationTitle(message);
    final body = _notificationBody(message);
    if (title.isEmpty && body.isEmpty) return;

    await _localNotifications.show(
      id: _notificationId(message),
      title: title.isEmpty ? 'LangLex' : title,
      body: body,
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          _notificationChannelId,
          _notificationChannelName,
          channelDescription: _notificationChannelDescription,
          importance: Importance.max,
          priority: Priority.high,
          ticker: 'LangLex notification',
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentBanner: true,
          presentList: true,
          presentSound: true,
        ),
      ),
      payload: jsonEncode(message.data),
    );
  }

  void _handleLocalNotificationTap(NotificationResponse response) {
    final payload = response.payload;
    if (payload == null || payload.trim().isEmpty) {
      _onNotificationTap?.call(const {});
      return;
    }

    try {
      final decoded = jsonDecode(payload);
      _onNotificationTap?.call(
        decoded is Map ? Map<String, dynamic>.from(decoded) : const {},
      );
    } catch (_) {
      _onNotificationTap?.call(const {});
    }
  }

  Future<void> dispose() async {
    await _tokenRefreshSubscription?.cancel();
    await _foregroundMessageSubscription?.cancel();
    _tokenRefreshSubscription = null;
    _foregroundMessageSubscription = null;
  }
}

String _notificationTitle(RemoteMessage message) {
  return (message.notification?.title ?? message.data['title'] ?? '')
      .toString()
      .trim();
}

String _notificationBody(RemoteMessage message) {
  return (message.notification?.body ?? message.data['body'] ?? '')
      .toString()
      .trim();
}

int _notificationId(RemoteMessage message) {
  final source = message.messageId ?? DateTime.now().microsecondsSinceEpoch;
  return source.hashCode & 0x7fffffff;
}
