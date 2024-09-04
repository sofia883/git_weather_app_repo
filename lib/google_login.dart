import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'welcome_page.dart';

class GoogleLoginPage extends StatelessWidget {
  GoogleLoginPage({Key? key}) : super(key: key);

  final GoogleSignIn _googleSignIn = GoogleSignIn(scopes: ['email']);
  
  // Define TextEditingController for user data
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  Future<void> _saveUserData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String username = _usernameController.text;
    String email = _emailController.text;
    String password = _passwordController.text;

    await prefs.setString('username', username);
    await prefs.setString('email', email);
    await prefs.setString('password', password);
    await prefs.setString('loginTime', DateTime.now().toString());
  }

  Future<void> _handleGoogleSignIn(BuildContext context) async {
    try {
      GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser != null) {
        // Optionally, you can save the Google user data using _saveUserData method
        _saveUserData();
        
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const WelcomePage(),
          ),
        );
      }
    } catch (error) {
      print('Google Sign-In Error: $error');
      // Handle sign-in error if any
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Google Login'),
      ),
      body: Center(
        child: ElevatedButton(
          onPressed: () {
            _handleGoogleSignIn(context);
          },
          child: Text('Sign in with Google'),
        ),
      ),
    );
  }
}
