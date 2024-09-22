import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:workmanager/workmanager.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:geolocator/geolocator.dart';
import 'weather_screen.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:workmanager/workmanager.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:geolocator/geolocator.dart';
import 'dart:async';

@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    print("Background task started: $task");
    await NotificationService.checkWeatherAndNotify();
    return Future.value(true);
  });
}

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

    await _flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        // Handle notification tap if necessary
      },
    );

    await Workmanager().initialize(callbackDispatcher, isInDebugMode: true);
    await Workmanager().registerPeriodicTask(
      "weatherCheck",
      "checkWeather",
      frequency: Duration(minutes: 3),
      constraints: Constraints(
        networkType: NetworkType.connected,
      ),
    );
    print("Workmanager initialized and task registered");
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
        payload: 'weather_alert',
      );
    }
  }

  static Future<void> cancelNotification(int id) async {
    await _flutterLocalNotificationsPlugin.cancel(id);
  }

  static Future<void> checkWeatherAndNotify() async {
    print("Checking weather and notifying...");
    await WeatherService
        .getCurrentWeatherDescription(); // This will update the saved weather description
    String currentWeather = await WeatherService.getCurrentWeatherDescription();
    print("Current weather of notification service: $currentWeather");
    final prefs = await SharedPreferences.getInstance();
    bool notificationsEnabled = prefs.getBool('notificationsEnabled') ?? true;

    if (notificationsEnabled) {
      final savedAlerts =
          await _loadSavedPreferences(); // Now you can assign it
      print("Saved alerts: $savedAlerts");

      String? lastNotifiedWeather = prefs.getString('lastNotifiedWeather');

      print("Saved ffalerts: $_loadSavedPreferences()");
      print("Last notified weather: $lastNotifiedWeather");

      bool alertFound = savedAlerts
          .any((alert) => alert.toLowerCase() == currentWeather.toLowerCase());
      print("Alert found: $alertFound");

      if (alertFound &&
          currentWeather.toLowerCase() != lastNotifiedWeather?.toLowerCase()) {
        // Show notification for matching weather condition
        await showNotification(
          id: DateTime.now().millisecond,
          title: 'Weather Alert',
          body:
              '"$currentWeather" detected in your area. Stay informed and take precautions!',
        );
        print("Notification sent for matching weather condition");

        // Update lastNotifiedWeather with the current weather
        await prefs.setString('lastNotifiedWeather', currentWeather);
        print("Updated last notified weather to: $currentWeather");
      } else {
        // Show update notification for non-matching condition
        await showNotification(
          id: DateTime.now().millisecond,
          title: 'Weather Update',
          body:
              'No matching weather conditions in the last 15 minutes. Current weather: $currentWeather',
        );
        print("Notification sent for no matching condition");
      }
    } else {
      print("Notifications are disabled");
    }
  }

  // static Future<String> getCurrentWeatherDescription() async {
  //   Position position = await Geolocator.getCurrentPosition();
  //   return await getCurrentWeather(position.latitude, position.longitude);
  // }

  // static Future<String> getCurrentWeather(double lat, double lon) async {
  //   final apiKey =
  //       'a99e2b4ee1217d2cafe222279d444d4c'; // Replace with your OpenWeatherMap API key
  //   final url =
  //       'https://api.openweathermap.org/data/2.5/weather?lat=$lat&lon=$lon&appid=$apiKey';

  //   final response = await http.get(Uri.parse(url));
  //   if (response.statusCode == 200) {
  //     final data = json.decode(response.body);
  //     return data['weather'][0]['description'];
  //   } else {
  //     throw Exception('Failed to load weather data');
  //   }
  // }

  @pragma('vm:entry-point')
  static void callbackDispatcher() {
    Workmanager().executeTask((task, inputData) async {
      print("Background task executed: $task");
      switch (task) {
        case "checkWeather":
          await checkWeatherAndNotify();
          break;
      }
      return Future.value(true);
    });
  }

  static Future<void> addNewAlert(String newAlert) async {
    print('Add new alert ');

    String currentWeather = await WeatherService.getCurrentWeatherDescription();
    print(currentWeather);
    if (currentWeather.toLowerCase() == newAlert.toLowerCase()) {
      await showNotification(
        id: DateTime.now().millisecond,
        title: 'New Weather Alert Match',
        body:
            'Your new alert "$newAlert" matches the current weather. Stay informed!',
      );
    } else {
      await showNotification(
        id: DateTime.now().millisecond,
        title: 'Weather Notification',
        body: "You'll be notified when ${newAlert} occurs in your area",
      );
    }
  }

  static Future<void> manuallyTriggerCheck() async {
    await checkWeatherAndNotify();
  }

//  static Future<List<String>> getSavedAlerts() async {
//   final prefs = await SharedPreferences.getInstance();
//     List<String> loadedPreferences =
//         prefs.getStringList('savedPreferences') ?? [];
//     setState(() {
//       _savedPreferences = loadedPreferences;
//     });
//     // Print all added preferences to the console
//     print('Loaded saved preferences: $_savedPreferences');
//   // final prefs = await SharedPreferences.getInstance();
//   // return prefs.getStringList('savedAlerts') ?? [];
// }
  static Future<List<String>> _loadSavedPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    List<String> loadedPreferences =
        prefs.getStringList('savedPreferences') ?? [];

    // Print all added preferences to the console
    print('Loaded saved prdddeferences: $loadedPreferences');

    return loadedPreferences;
  }

// Usage

  static Future<void> checkCurrentLocationWeather() async {
    // String currentWeather = await getCurrentWeatherDescription();
    // String currentWeather = 'heavy thunderstorm';

    await checkWeatherAndNotify();
  }
}

class WeatherService {
  static Future<String> getCurrentWeatherDescription() async {
    try {
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      return await getWeatherDescriptionForLocation(
          position.latitude, position.longitude);
    } catch (e) {
      print("Error getting current weather description: $e");
      return 'Unable to fetch weather';
    }
  }

  static Future<String> getWeatherDescriptionForLocation(
      double lat, double lon) async {
    final apiKey = 'a99e2b4ee1217d2cafe222279d444d4c';
    final url =
        'https://api.openweathermap.org/data/2.5/weather?lat=$lat&lon=$lon&appid=$apiKey';

    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['weather'][0]['description'];
      } else {
        throw Exception('Failed to load weather data');
      }
    } catch (e) {
      print("Error fetching weather data: $e");
      return 'Unable to fetch weather';
    }
  }
}
