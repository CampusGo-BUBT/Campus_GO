import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'api_client.dart';

// Background/terminated state এ message আসলে এই top-level function চলে।
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // OS নিজেই notification দেখায়
}

class NotificationService {
  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  static final FlutterLocalNotificationsPlugin _local =
      FlutterLocalNotificationsPlugin();

  static const _channel = AndroidNotificationChannel(
    'campusgo_default',
    'CampusGo Notifications',
    description: 'Job, Tutor, Book, Notice, Group update',
    importance: Importance.high,
  );

  /// Login এর পর একবার call করো।
  static Future<void> init() async {
    await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosInit = DarwinInitializationSettings();
    await _local.initialize(
      const InitializationSettings(android: androidInit, iOS: iosInit),
    );
    await _local
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(_channel);

    // Foreground message → local notification
    FirebaseMessaging.onMessage.listen(_showLocalNotification);

    await _messaging.subscribeToTopic('all_updates');
    await _saveTokenForCurrentUser();
    _messaging.onTokenRefresh.listen((_) => _saveTokenForCurrentUser());
  }

  static Future<void> _showLocalNotification(RemoteMessage message) async {
    final notif = message.notification;
    if (notif == null) return;
    await _local.show(
      notif.hashCode,
      notif.title,
      notif.body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          _channel.id,
          _channel.name,
          channelDescription: _channel.description,
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: const DarwinNotificationDetails(),
      ),
    );
  }

  static Future<void> _saveTokenForCurrentUser() async {
    final token = await _messaging.getToken();
    if (token == null) return;
    try {
      await ApiClient.instance.patch('/auth/user/token/',
          body: {'fcmToken': token});
    } catch (_) {
      // not logged in or backend unreachable - try again next refresh
    }
  }

  /// Logout এর আগে call করো।
  static Future<void> clearToken() async {
    try {
      await _messaging.unsubscribeFromTopic('all_updates');
      await ApiClient.instance.patch('/auth/user/token/',
          body: {'fcmToken': ''});
    } catch (_) {
      // ignore
    }
  }
}
