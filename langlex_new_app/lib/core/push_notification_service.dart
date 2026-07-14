import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:langlex_new_app/core/local_storage.dart';

class PushNotificationService {
  PushNotificationService._();

  static final PushNotificationService instance = PushNotificationService._();

  bool _initialized = false;

  Future<String> getPushToken() async {
    if (kIsWeb) return '';

    try {
      if (!_initialized) {
        await Firebase.initializeApp();
        _initialized = true;
      }

      final messaging = FirebaseMessaging.instance;
      await messaging.requestPermission();
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
}
