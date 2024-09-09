import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin
      _flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

  static Future<void> initialize() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    final InitializationSettings initializationSettings =
        InitializationSettings(
      android: initializationSettingsAndroid,
    );

    await _flutterLocalNotificationsPlugin.initialize(initializationSettings);
  }

  static Future<void> showNotification({
    required int id,
    required String title,
    required String body,
  }) async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'your_channel_id',
      'your_channel_name',
      channelDescription: 'your_channel_description',
      importance: Importance.max,
      priority: Priority.high,
      ticker: 'ticker',
    );

    const NotificationDetails platformChannelSpecifics =
        NotificationDetails(android: androidPlatformChannelSpecifics);

    await _flutterLocalNotificationsPlugin.show(
      id,
      title,
      body,
      platformChannelSpecifics,
    );
  }

  Future<String?> _getSavedDescription() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('currentDescription');
  }

  static Future<void> checkAndNotify(String newDescription) async {
    final prefs = await SharedPreferences.getInstance();
    List<String> savedPreferences =
        prefs.getStringList('savedPreferences') ?? [];

    int notificationId =
        (DateTime.now().millisecondsSinceEpoch % 2147483647).toInt();

    if (savedPreferences.contains(newDescription)) {
      await showNotification(
        id: notificationId,
        title: 'Weather Alert',
        body: 'The condition "$newDescription" is in your saved preferences!',
      );
      print('Notification sent: $newDescription matches saved preferences');
    } else {
      await showNotification(
        id: notificationId,
        title: 'Weather Alert',
        body:
            'The condition "$newDescription" is not in your saved preferences.',
      );
      print(
          'Notification sent: $newDescription does not match saved preferences');
    }
  }
}
