import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:workmanager/workmanager.dart';

class WeatherAlertPage extends StatefulWidget {
  final String currentWeatherDescription;

  WeatherAlertPage({required this.currentWeatherDescription});

  @override
  _WeatherAlertPageState createState() => _WeatherAlertPageState();
}

class _WeatherAlertPageState extends State<WeatherAlertPage> {
  static List<String> savedAlerts = [];
  List<String> weatherConditions = [
    'Clear sky', 'Few clouds', 'Scattered clouds', 'Broken clouds',
    'Shower rain', 'Rain', 'Thunderstorm', 'Snow', 'Mist',
    'Heavy intensity rain', 'Very heavy rain', 'Extreme rain',
    'Freezing rain', 'Light intensity shower rain',
    'Heavy intensity shower rain', 'Light snow', 'Heavy snow',
    'Sleet', 'Light rain and snow', 'Rain and snow',
    'Light shower snow', 'Shower snow', 'Heavy shower snow'
  ];

  static FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  @override
  void initState() {
    super.initState();
    loadSavedAlerts();
    initializeNotifications();
  }

  static void initializeNotifications() {
    var initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    var initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
    );
    flutterLocalNotificationsPlugin.initialize(initializationSettings);
  }

  static Future<void> loadSavedAlerts() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    savedAlerts = prefs.getStringList('weatherAlerts') ?? [];
  }

  void saveAlert(String alert) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      if (!savedAlerts.contains(alert)) {
        savedAlerts.add(alert);
        prefs.setStringList('weatherAlerts', savedAlerts);
      }
    });
  }

  void removeAlert(String alert) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      savedAlerts.remove(alert);
      prefs.setStringList('weatherAlerts', savedAlerts);
    });
  }

  static Future<void> checkCurrentWeather(String currentWeatherDescription) async {
    await loadSavedAlerts();
    if (savedAlerts.contains(currentWeatherDescription.toLowerCase())) {
      await showNotification(currentWeatherDescription);
    }
  }

  static Future<void> showNotification(String weatherCondition) async {
    var androidPlatformChannelSpecifics = AndroidNotificationDetails(
      'weather_alert_channel',
      'Weather Alerts',
      importance: Importance.max,
      priority: Priority.high,
    );
    var platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
    );
    
    await flutterLocalNotificationsPlugin.show(
      0,
      'Weather Alert',
      'Current weather: $weatherCondition',
      platformChannelSpecifics,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Weather Alerts'),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: weatherConditions.length,
              itemBuilder: (context, index) {
                final condition = weatherConditions[index];
                final isSelected = savedAlerts.contains(condition.toLowerCase());
                return CheckboxListTile(
                  title: Text(condition),
                  value: isSelected,
                  onChanged: (bool? value) {
                    if (value == true) {
                      saveAlert(condition.toLowerCase());
                    } else {
                      removeAlert(condition.toLowerCase());
                    }
                  },
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(
              'Current weather: ${widget.currentWeatherDescription}',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}