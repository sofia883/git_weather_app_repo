import 'package:flutter/material.dart';
import 'user_login_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LogoutHandler {
  static void handleLogout(BuildContext context) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    // Clear user-related data or session data
    // Remove any other relevant data you stored upon login
    await prefs.remove('username');
    await prefs.remove('surname');
    await prefs.remove('email');
    await prefs.setBool('isLoggedIn', false); // Set isLoggedIn to false

    // Navigate to the login page after logout
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => LoginPage()),
    );
  }

  static void showLogoutConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Log Out'),
          content: Text('Are you sure you want to log out?'),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                handleLogout(context);
              },
              child: Text('Log Out'),
            ),
          ],
        );
      },
    );
  }
}
