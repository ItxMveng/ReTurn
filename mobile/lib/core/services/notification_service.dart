import 'dart:io';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

// Top-level handler required by FCM for background messages
@pragma('vm:entry-point')
Future<void> _firebaseBackgroundHandler(RemoteMessage message) async {
  // No Firebase.initializeApp needed here — already done in main()
  await NotificationService.showLocal(message);
}

class NotificationService {
  NotificationService._();

  static final _fcm = FirebaseMessaging.instance;
  static final _local = FlutterLocalNotificationsPlugin();

  static const _androidChannel = AndroidNotificationChannel(
    'docretour_alerts',
    'ReTurn Alertes',
    description: 'Notifications de documents trouvés et messages reçus',
    importance: Importance.high,
    playSound: true,
  );

  /// Must be called once at app startup (before runApp or just after).
  static Future<void> init() async {
    // 1. Request permission (iOS 13+ / Android 13+)
    await _fcm.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );

    // 2. Configure local notifications channel (Android 8+)
    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const darwinInit = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    await _local.initialize(
      const InitializationSettings(android: androidInit, iOS: darwinInit),
      onDidReceiveNotificationResponse: _onLocalTap,
    );

    if (!kIsWeb && Platform.isAndroid) {
      await _local
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(_androidChannel);
    }

    // 3. Register background handler
    FirebaseMessaging.onBackgroundMessage(_firebaseBackgroundHandler);

    // 4. Foreground handler — show local notification while app is open
    //    Suppress if user is already in the relevant chat
    FirebaseMessaging.onMessage.listen((msg) {
      final data = msg.data;
      final matchId = data['match_id'] as String? ?? '';
      final type = data['type'] as String? ?? '';
      // If it's a chat message and user is in that chat, skip notification
      if (type == 'new_message' && matchId == _activeChatMatchId) return;
      showLocal(msg);
    });

    // 5. iOS: show foreground notifications as alerts
    await _fcm.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );
  }

  /// Show a local notification from a RemoteMessage.
  static Future<void> showLocal(RemoteMessage message) async {
    final notif = message.notification;
    if (notif == null) return;

    final title = notif.title ?? 'ReTurn';
    final body = notif.body ?? '';
    final data = message.data;

    await _local.show(
      message.hashCode,
      title,
      body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          _androidChannel.id,
          _androidChannel.name,
          channelDescription: _androidChannel.description,
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      payload: _buildPayload(data),
    );
  }

  static String _buildPayload(Map<String, dynamic> data) {
    final type = data['type'] as String? ?? '';
    final id = data['match_id'] as String? ?? '';
    return '$type|$id';
  }

  static void _onLocalTap(NotificationResponse response) {
    // Navigation handled globally via onMessageOpenedApp — local taps use the
    // same payload format so the router can deep-link.
    final payload = response.payload ?? '';
    _routeFromPayload(payload);
  }

  static void _routeFromPayload(String payload) {
    // Imported by main.dart via the global navigator key — no BuildContext needed.
    final parts = payload.split('|');
    if (parts.isEmpty) return;
    final type = parts[0];
    final id = parts.length > 1 ? parts[1] : '';
    if (id.isEmpty) return;

    if (type == 'match_found') {
      _pendingRoute = '/matches/$id';
    } else if (type == 'new_message') {
      _pendingRoute = '/matches/$id/chat';
    }
  }

  // One pending route that main.dart/GoRouter reads after first frame
  static String? _pendingRoute;
  // Active chat match ID — set by ChatScreen to suppress notifications
  static String? _activeChatMatchId;

  static void setActiveChatMatchId(String? id) {
    _activeChatMatchId = id;
  }

  static String? consumePendingRoute() {
    final r = _pendingRoute;
    _pendingRoute = null;
    return r;
  }

  /// Call after login to register this device's FCM token with the backend.
  static Future<String?> getToken() async {
    try {
      return await _fcm.getToken();
    } catch (_) {
      return null;
    }
  }

  /// Listen for token refreshes and re-register with backend.
  static Stream<String> get onTokenRefresh => _fcm.onTokenRefresh;
}
