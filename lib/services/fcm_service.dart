
import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

class FCMService {
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  StreamSubscription<RemoteMessage>? _foregroundSubscription;
  StreamSubscription<RemoteMessage>? _openedSubscription;

  Future<void> initialize({
    required void Function(RemoteMessage, String) onMessage,
  }) async {
    final settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    debugPrint(
      'Notification permission: ${settings.authorizationStatus}',
    );

    _foregroundSubscription =
        FirebaseMessaging.onMessage.listen((message) {
      debugPrint('Foreground message: ${message.messageId}');
      onMessage(message, 'onMessage');
    });

    _openedSubscription =
        FirebaseMessaging.onMessageOpenedApp.listen((message) {
      debugPrint('Notification opened from background');
      onMessage(message, 'onMessageOpenedApp');
    });

    final initialMessage = await _messaging.getInitialMessage();

    if (initialMessage != null) {
      debugPrint('Notification opened from terminated state');
      onMessage(initialMessage, 'getInitialMessage');
    }

    await getToken();
  }

  Future<String?> getToken() async {
    try {
      if (!kIsWeb && (Platform.isIOS || Platform.isMacOS)) {
        final apnsToken = await _messaging.getAPNSToken();

        if (apnsToken == null) {
          debugPrint(
            'APNs token unavailable. FCM registration pending.',
          );
          return null;
        }
      }

      final token = await _messaging.getToken();

      debugPrint('FCM token available: ${token != null}');

      return token;
    } catch (e) {
      debugPrint('FCM token error: $e');
      return null;
    }
  }

  void dispose() {
    _foregroundSubscription?.cancel();
    _openedSubscription?.cancel();
  }
}
