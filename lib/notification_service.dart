import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:workmanager/workmanager.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:weather_app/api_key.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  static Future<void> initialize() async {
    final AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    final InitializationSettings initializationSettings =
        InitializationSettings(android: initializationSettingsAndroid);
    await flutterLocalNotificationsPlugin.initialize(initializationSettings);

    // Initialize Workmanager
    Workmanager().initialize(callbackDispatcher);
    Workmanager().registerPeriodicTask(
      "weatherCheck",
      "checkWeatherPeriodically",
      frequency: Duration(seconds: 5),
    );
  }

  static Future<void> showNotification({
    required String title,
    required String body,
  }) async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'weather_channel',
      'Weather Notifications',
      importance: Importance.max,
      priority: Priority.high,
    );
    const NotificationDetails platformChannelSpecifics =
        NotificationDetails(android: androidPlatformChannelSpecifics);
    await flutterLocalNotificationsPlugin.show(
      0,
      title,
      body,
      platformChannelSpecifics,
    );
  }

  static Future<void> checkAndNotify(String newDescription) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String> selectedAlerts = prefs.getStringList('weatherAlerts') ?? [];

    if (selectedAlerts.contains(newDescription)) {
      await showNotification(
        title: 'Weather Alert',
        body: 'Current weather condition: $newDescription',
      );
    }
  }
}

void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    switch (task) {
      case "checkWeatherPeriodically":
        await _checkWeatherAndNotify();
        break;
    }
    return Future.value(true);
  });
}

Future<void> _checkWeatherAndNotify() async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  double? lat = prefs.getDouble('lastKnownLatitude');
  double? lon = prefs.getDouble('lastKnownLongitude');

  if (lat == null || lon == null) {
    return; // Can't check weather without location
  }

  final response = await http.get(Uri.parse(
      'https://api.openweathermap.org/data/2.5/weather?lat=$lat&lon=$lon&appid=$openWeatherAPIKey'));

  if (response.statusCode == 200) {
    final weatherData = json.decode(response.body);
    final newDescription = weatherData['weather'][0]['description'];
    await NotificationService.checkAndNotify(newDescription);
  }
}
