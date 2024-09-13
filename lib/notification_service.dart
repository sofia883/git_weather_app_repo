import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:workmanager/workmanager.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:geolocator/geolocator.dart';

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

    // Initialize Workmanager for background tasks
    await Workmanager().initialize(callbackDispatcher);
    await Workmanager().registerPeriodicTask(
      "weatherCheck",
      "checkWeather",
      frequency: Duration(minutes: 15),
      inputData: {'lastRun': DateTime.now().toIso8601String()},
      existingWorkPolicy: ExistingWorkPolicy.replace,
    );
  }

  static Future<void> showNotification({
    required int id,
    required String title,
    required String body,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    bool notificationsEnabled = prefs.getBool('notificationsEnabled') ?? true;

    if (notificationsEnabled) {
      const AndroidNotificationDetails androidPlatformChannelSpecifics =
          AndroidNotificationDetails(
        'weather_alerts',
        'Weather Alerts',
        channelDescription: 'Notifications for weather alerts',
        importance: Importance.max,
        priority: Priority.high,
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
  }

  // The checkAndNotify method will also ensure that notifications are only sent when enabled
  static Future<void> checkAndNotify(String currentWeather) async {
    final prefs = await SharedPreferences.getInstance();
    bool notificationsEnabled = prefs.getBool('notificationsEnabled') ?? true;

    if (notificationsEnabled) {
      List<String> savedPreferences =
          prefs.getStringList('savedPreferences') ?? [];
      String? lastNotifiedDescription =
          prefs.getString('lastNotifiedDescription');

      if (savedPreferences.contains(currentWeather) &&
          currentWeather != lastNotifiedDescription) {
        await showNotification(
          id: DateTime.now().millisecond,
          title: 'Weather Alert',
          body:
              'Current weather condition "$currentWeather" matches your saved preference!',
        );
        await prefs.setString('lastNotifiedDescription', currentWeather);
      }
    }
  }

  static Future<void> checkNewPreference(String newPreference) async {
    print('hello');
    Position position = await Geolocator.getCurrentPosition();
    String currentWeather =
        await getCurrentWeather(position.latitude, position.longitude);
    print('c ${currentWeather}');
    print('n${newPreference}');

    if (currentWeather == newPreference) {
      await showNotification(
        id: DateTime.now().millisecond,
        title: 'Weather Alert',
        body:
            'New preference "$newPreference" matches the current weather condition!',
      );
    }
  }

  static Future<String> getCurrentWeather(double lat, double lon) async {
    final apiKey = 'a99e2b4ee1217d2cafe222279d444d4c';
    final url =
        'https://api.openweathermap.org/data/2.5/weather?lat=$lat&lon=$lon&appid=$apiKey';

    final response = await http.get(Uri.parse(url));
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return data['weather'][0]['description'];
    } else {
      throw Exception('Failed to load weather data');
    }
  }

  @pragma('vm:entry-point')
  static void callbackDispatcher() {
    Workmanager().executeTask((task, inputData) async {
      switch (task) {
        case "checkWeather":
          SharedPreferences prefs = await SharedPreferences.getInstance();
          bool notificationsEnabled =
              prefs.getBool('notificationsEnabled') ?? true;

          if (notificationsEnabled) {
            try {
              Position position = await Geolocator.getCurrentPosition();
              String currentWeather =
                  await NotificationService.getCurrentWeather(
                      position.latitude, position.longitude);
              await NotificationService.checkAndNotify(currentWeather);
            } catch (e) {
              print('Error in background task: $e');
            }
          }
          break;
      }
      return Future.value(true);
    });
  }
}
