import 'package:flutter/material.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'welcome_page.dart';

class AppleLoginPage extends StatefulWidget {
  const AppleLoginPage({Key? key}) : super(key: key);

  @override
  _AppleLoginPageState createState() => _AppleLoginPageState();
}

class _AppleLoginPageState extends State<AppleLoginPage> {
  bool _isLoading = false;

  Future<void> _handleAppleSignIn() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final credential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
      );

      // Here you can process the credential data
      print('User ID: ${credential.userIdentifier}');
      print('Email: ${credential.email}');
      print('Full Name: ${credential.givenName} ${credential.familyName}');

      // Navigate to Welcome Page
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => WelcomePage()),
      );
    } catch (error) {
      print('Apple Sign-In Error: $error');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Sign-in failed. Please try again.')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Apple Login'),
      ),
      body: Center(
        child: _isLoading
            ? CircularProgressIndicator()
            : SignInWithAppleButton(
                onPressed: _handleAppleSignIn,
              ),
      ),
    );
  }
}
