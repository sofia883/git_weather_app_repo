import 'package:flutter/material.dart';
import 'package:weather_app/user_login_screen.dart';
import 'package:weather_app/welcome_page.dart';
import 'package:weather_app/weather_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'notification_service.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'dart:async';


void main() async {


  runApp(MyApp());
}
class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Weather App',
      // theme: ThemeData(
      //   primarySwatch: Colors.blue,
      // ),
      home: FutureBuilder(
        future: checkFirstTimeLogin(),
        builder: (context, AsyncSnapshot<bool> snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            return snapshot.data! ? MainScreen() : LoginPage();
          } else {
            return Scaffold(
              body: Center(
                child: CircularProgressIndicator(),
              ),
            );
          }
        },
      ),
    );
  }

  Future<bool> checkFirstTimeLogin() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getBool('isLoggedIn') ?? false;
  }
}

class MainScreen extends StatefulWidget {
  @override
  _MainScreenState createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;
  final List<Widget> _screens = [
    WeatherScreen(),
    WelcomePage(),
    // Add more screens as needed
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: _screens,
      ),
    bottomNavigationBar: BottomNavigationBar(
        items: [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
          // Add more items as needed
        ],
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
      ),
    );
  }
}

class HourlyForecastGraph extends StatelessWidget {
  final List<double> temperatures;
  final List<String> hours;

  HourlyForecastGraph({required this.temperatures, required this.hours});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 200,
      child: LineChart(
        LineChartData(
          gridData: FlGridData(show: false),
          titlesData: FlTitlesData(
            bottomTitles: AxisTitles(),
            leftTitles: AxisTitles(axisNameSize: 23),
          ),
          borderData: FlBorderData(show: false),
          minX: 0,
          maxX: temperatures.length.toDouble() - 1,
          minY: temperatures.reduce((a, b) => a < b ? a : b),
          maxY: temperatures.reduce((a, b) => a > b ? a : b),
          lineBarsData: [
            LineChartBarData(
              spots: temperatures.asMap().entries.map((e) {
                return FlSpot(e.key.toDouble(), e.value);
              }).toList(),
              isCurved: true,
              color: Colors.blue,
              dotData: FlDotData(show: false),
              belowBarData: BarAreaData(show: false),
            ),
          ],
        ),
      ),
    );
  }
}
