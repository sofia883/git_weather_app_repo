import 'package:flutter/material.dart';
import 'package:weather_app/weather_screen.dart';
import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';

class WelcomePage extends StatefulWidget {
  const WelcomePage({Key? key}) : super(key: key);

  @override
  State<WelcomePage> createState() => WelcomePageState();
}

class WelcomePageState extends State<WelcomePage> {
  bool isLoading = true;
  late String username = ''; // Track loading state

  @override
  void initState() {
    super.initState();
    _getUserData();
  }

  Future<void> _getUserData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    // Retrieve the username from SharedPreferences
    setState(() {
      username = prefs.getString('username') ?? ''; // Get the stored username
    });
    // Simulate a delay
    Future.delayed(const Duration(seconds: 2), () {
      // Navigate to the next screen
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const WeatherScreen()),
      );
    }).then((value) {
      // After the delay, set loading to false
      setState(() {
        isLoading = false;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              // color: Colo,
              image: DecorationImage(
                fit: BoxFit.fill,
                image: AssetImage(
                    'assets/images/white.jpg'), // Set your background image
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(
              top: 700,
            ),
            child: Align(
              alignment: Alignment.topCenter,
              child: AnimatedSwitcher(
                duration: Duration(seconds: 1),
                child: isLoading
                    ? Text(
                        'Welcome! $username',
                        style: TextStyle(
                          fontSize: 24.0,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      )
                    : SizedBox(), // Hide the text after 5 seconds
              ),
            ),
          ),
        ],
      ),
    );
  }
}
