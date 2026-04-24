import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _local =
      FlutterLocalNotificationsPlugin();

  Future<void> init() async {

    // Permission request
    await _messaging.requestPermission();

    // Local notification setup
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');

    const settings = InitializationSettings(android: android);

    await _local.initialize(settings);

    // Foreground message handler
    FirebaseMessaging.onMessage.listen((message) {
      showNotification(message.notification?.title ?? "",
          message.notification?.body ?? "");
    });
  }

  void showNotification(String title, String body) {
    const androidDetails = AndroidNotificationDetails(
      'channel_id',
      'Emergency Alerts',
      importance: Importance.max,
      priority: Priority.high,
    );

    const details = NotificationDetails(android: androidDetails);

    _local.show(0, title, body, details);
  }
}