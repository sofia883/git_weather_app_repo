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
      frequency: Duration(seconds: 15),
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

  static Future<void> checkAndNotify(String currentWeather) async {
    final prefs = await SharedPreferences.getInstance();
    bool notificationsEnabled = prefs.getBool('notificationsEnabled') ?? true;

    if (notificationsEnabled) {
      List<String> savedAlerts = prefs.getStringList('savedAlerts') ?? [];
      String? lastNotifiedWeather = prefs.getString('lastNotifiedWeather');

      // Check if current weather matches any saved alert
      if (savedAlerts.contains(currentWeather) &&
          currentWeather != lastNotifiedWeather) {
        await showNotification(
          id: DateTime.now().millisecond,
          title: 'Weather Alert',
          body:
              '"$currentWeather" detected in your area. Stay informed and take precautions!',
        );
        await prefs.setString('lastNotifiedWeather', currentWeather);
      }
    }
  }

  static Future<void> addNewAlert(String newAlert) async {
    final prefs = await SharedPreferences.getInstance();
    List<String> savedAlerts = prefs.getStringList('savedAlerts') ?? [];

    if (!savedAlerts.contains(newAlert)) {
      savedAlerts.add(newAlert);
      await prefs.setStringList('savedAlerts', savedAlerts);

      // Check if the new alert matches current weather
      String currentWeather = await getCurrentWeatherDescription();
      if (currentWeather == newAlert) {
        await showNotification(
          id: DateTime.now().millisecond,
          title: 'New Weather Alert Match',
          body:
              'Your new alert "$newAlert" matches the current weather. Stay informed!',
        );
      }
    }
  }

  static Future<String> getCurrentWeatherDescription() async {
    Position position = await Geolocator.getCurrentPosition();
    return await getCurrentWeather(position.latitude, position.longitude);
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

  static Future<void> checkCurrentLocationWeather() async {
    String currentWeather = await getCurrentWeatherDescription();
    await checkAndNotify(currentWeather);
  }

  @pragma('vm:entry-point')
  static void callbackDispatcher() {
    Workmanager().executeTask((task, inputData) async {
      switch (task) {
        case "checkWeather":
          await checkCurrentLocationWeather();
          break;
      }
      return Future.value(true);
    });
  }
}
