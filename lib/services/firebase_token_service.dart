import 'dart:io';
import 'package:firebase_messaging/firebase_messaging.dart';
import '../utils/logger.dart';

class FirebaseTokenService {
  static final FirebaseMessaging _firebaseMessaging =
      FirebaseMessaging.instance;

  static Future<String?> getFCMToken() async {
    try {
      final settings = await _firebaseMessaging.getNotificationSettings();

      if (settings.authorizationStatus != AuthorizationStatus.authorized &&
          settings.authorizationStatus != AuthorizationStatus.provisional) {
        logError('Notification permission not granted');
        return null;
      }

      // 2️⃣ iOS: wait for APNs token
      if (Platform.isIOS) {
        String? apnsToken = await _firebaseMessaging.getAPNSToken();

        int retry = 0;
        while (apnsToken == null && retry < 5) {
          await Future.delayed(const Duration(seconds: 1));
          apnsToken = await _firebaseMessaging.getAPNSToken();
          retry++;
        }

        if (apnsToken == null) {
          logError('APNs token not available');
          return null;
        }

        logInfo('APNs token ready');
      }

      // 3️⃣ Now safely get FCM token
      final token = await _firebaseMessaging.getToken();

      logInfo(
        'FCM Token retrieved: ${token != null ? '${token.substring(0, 20)}...' : 'null'}',
      );

      return token;
    } catch (e, stackTrace) {
      logError(
        'Failed to get FCM token',
        error: e,
        stackTrace: stackTrace,
      );
      return null;
    }
  }

  static Future<String?> refreshFCMToken() async {
    try {
      await _firebaseMessaging.deleteToken();
      return await getFCMToken();
    } catch (e, stackTrace) {
      logError(
        'Failed to refresh FCM token',
        error: e,
        stackTrace: stackTrace,
      );
      return null;
    }
  }
}
