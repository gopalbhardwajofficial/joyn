import 'dart:io';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'api_service.dart';

class NotificationService {
  static bool _isInitialized = false;
  static String? _fcmToken;

  static String? get currentToken => _fcmToken;

  /// Background message entry-point
  @pragma('vm:entry-point')
  static Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
    try {
      await Firebase.initializeApp();
    } catch (_) {}
    debugPrint('🔔 [FCM Background] Message received: ${message.messageId}');
  }

  /// Initialize Firebase Core & Push Notifications Engine
  static Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // 1. Initialize Firebase App safely
      await Firebase.initializeApp();

      // 2. Set Background Message Handler
      FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

      // 3. Request Notification Permissions
      final messaging = FirebaseMessaging.instance;
      final settings = await messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );

      debugPrint('🔔 [FCM] Notification authorization status: ${settings.authorizationStatus}');

      // 4. Retrieve FCM Device Token
      _fcmToken = await messaging.getToken();
      debugPrint('🔔 [FCM] Device Token: $_fcmToken');

      if (_fcmToken != null && _fcmToken!.isNotEmpty) {
        await syncTokenWithBackend(_fcmToken!);
      }

      // 5. Listen to Token Refreshes
      messaging.onTokenRefresh.listen((newToken) {
        _fcmToken = newToken;
        debugPrint('🔔 [FCM] Token refreshed: $newToken');
        syncTokenWithBackend(newToken);
      });

      // 6. Foreground message listener
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        debugPrint('🔔 [FCM Foreground] Title: ${message.notification?.title}, Body: ${message.notification?.body}');
      });

      _isInitialized = true;
    } catch (e) {
      debugPrint('⚠️ [FCM] Notification initialization note (handled gracefully): $e');
    }
  }

  /// Sync FCM Device Token with JOYN Cloud Backend
  static Future<void> syncTokenWithBackend([String? token]) async {
    final t = token ?? _fcmToken;
    if (t == null || t.isEmpty) return;

    try {
      final jwt = await ApiService.getToken();
      if (jwt != null && jwt.isNotEmpty) {
        final deviceType = !kIsWeb && Platform.isIOS ? 'ios' : 'android';
        final res = await ApiService.registerDeviceToken(t, deviceType: deviceType);
        debugPrint('🔔 [FCM] Synced token with backend: ${res['success']}');
      }
    } catch (e) {
      debugPrint('⚠️ [FCM] Token sync with backend deferred: $e');
    }
  }
}

