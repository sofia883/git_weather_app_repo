import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ProfilePage extends StatefulWidget {
  final VoidCallback? onProfileUpdated;

  const ProfilePage({Key? key, this.onProfileUpdated}) : super(key: key);

  @override
  ProfilePageState createState() => ProfilePageState();
}

class ProfilePageState extends State<ProfilePage> {
  // ... (rest of your code)TextEditingController _usernameController = TextEditingController();
  TextEditingController _surnameController = TextEditingController();
  TextEditingController _usernameController = TextEditingController();
  TextEditingController _emailController = TextEditingController();
  TextEditingController _passwordController = TextEditingController();
  TextEditingController _confirmPasswordController = TextEditingController();

  late String _username = '';
  late String _surname = '';
  late String _email = '';
  late String _password = '';
  late DateTime _loginTime = DateTime.now();

  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    _getUserData();
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _surnameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _getUserData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      _username = prefs.getString('username') ?? 'No username';
      _surname = prefs.getString('surname') ?? 'No surname';
      _email = prefs.getString('email') ?? 'No email';
      _password = prefs.getString('password') ?? 'No password';
      _loginTime = DateTime.parse(prefs.getString('loginTime') ?? '');
      _usernameController.text = _username;
      _surnameController.text = _surname;
      _emailController.text = _email;
      _passwordController.text = _password;
    });
  }

  Future<void> _saveUserData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();

    if (_passwordController.text != _confirmPasswordController.text) {
      // Show error to the user
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Passwords do not match'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      await prefs.setString('username', _usernameController.text);
      await prefs.setString('surname', _surnameController.text);
      await prefs.setString('email', _emailController.text);
      await prefs.setString('password', _passwordController.text);
      await prefs.setString('loginTime', DateTime.now().toString());

      setState(() {
        _username = _usernameController.text;
        _surname = _surnameController.text;
        _email = _emailController.text;
        _password = _passwordController.text;
        _isEditing = false;
      });

      if (widget.onProfileUpdated != null) {
        widget.onProfileUpdated!(); // Notify the parent about profile updates
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Profile updated successfully'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to save profile: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile Page'),
        actions: [
          IconButton(
            onPressed: () async {
              if (_isEditing) {
                await _saveUserData();

                setState(() {
                  // Navigator.pop(context);
                  _isEditing = !_isEditing;
                });
              }
              setState(() {
                _isEditing = !_isEditing;
              });
            },
            icon: _isEditing ? Icon(Icons.check) : Icon(Icons.edit),
          )
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Avatar and user details section
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => FullScreenAvatar(
                            image: 'assets/images/dp.jpg',
                          ),
                        ),
                      );
                    },
                    child: Hero(
                      tag: 'avatarTag',
                      child: CircleAvatar(
                        backgroundImage: AssetImage('assets/images/dp.jpg'),
                        radius: 60,
                        backgroundColor: Colors.black,
                      ),
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        GestureDetector(
                          onTap: () {
                            if (_isEditing) {
                              setState(() {
                                _isEditing = false;
                              });
                            }
                          },
                          child: Text(
                            '$_username $_surname',
                            style: TextStyle(
                              fontSize: 24,
                              color: _isEditing ? Colors.blue : Colors.black,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          _email,
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.black,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              Divider(
                height: 50,
              ),
              // Input fields for editing
              _buildTextField(
                controller: _usernameController,
                labelText: 'Username',
                enabled: _isEditing,
              ),
              SizedBox(height: 12),
              _buildTextField(
                controller: _surnameController,
                labelText: 'Surname',
                enabled: _isEditing,
              ),
              SizedBox(height: 12),
              _buildTextField(
                controller: _emailController,
                labelText: 'Email',
                enabled: _isEditing,
              ),
              SizedBox(height: 12),
              _buildTextField(
                controller: _passwordController,
                labelText: 'Password',
                enabled: _isEditing,
                obscureText: true,
              ),
              SizedBox(height: 12),
              _buildTextField(
                controller: _confirmPasswordController,
                labelText: 'Confirm Password',
                enabled: _isEditing,
                obscureText: true,
              ),
              SizedBox(height: 12),
              // Display login time
              Row(
                children: [
                  Text(
                    'Login Time: ${DateFormat('hh:mm a').format(_loginTime)}',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 16),
              // Save button when editing
              if (_isEditing)
                ElevatedButton(
                  onPressed: () async {
                    await _saveUserData();
                  },
                  child: Text('Save'),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String labelText,
    bool enabled = false,
    bool obscureText = false,
  }) {
    return TextFormField(
      controller: controller,
      readOnly: !enabled,
      style: TextStyle(
        color: Colors.black,
        fontSize: 18,
      ),
      decoration: InputDecoration(
        labelText: labelText,
        enabledBorder: UnderlineInputBorder(
          borderSide: BorderSide(
            color: Colors.blueGrey,
          ),
        ),
        focusedBorder: enabled
            ? UnderlineInputBorder(
                borderSide: BorderSide(color: Colors.orange),
              )
            : InputBorder.none,
      ),
      enabled: enabled,
      obscureText: obscureText,
    );
  }
}

class FullScreenAvatar extends StatelessWidget {
  final String image;

  const FullScreenAvatar({required this.image});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GestureDetector(
        onTap: () {
          Navigator.pop(context);
        },
        child: Center(
          child: Hero(
            tag: 'avatarTag',
            child: CircleAvatar(
              backgroundImage: AssetImage(image),
              radius: 200, // Adjust the radius as needed
              backgroundColor: Colors.blue,
            ),
          ),
        ),
      ),
    );
  }
}
