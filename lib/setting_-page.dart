import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'profile_page.dart'; // Make sure to create this file

class SettingsPage extends StatefulWidget {
  final void Function(bool) onTemperatureUnitChanged;

  const SettingsPage({
    Key? key,
    required this.onTemperatureUnitChanged,
  }) : super(key: key);

  @override
  SettingsPageState createState() => SettingsPageState();
}

class SettingsPageState extends State<SettingsPage> {
  late bool _isCelsius;

  @override
  void initState() {
    super.initState();
    _loadTemperatureUnit();
  }

  Future<void> _loadTemperatureUnit() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      _isCelsius = prefs.getBool('isCelsius') ?? true;
    });
  }

  Future<void> _saveTemperatureUnit(bool value) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isCelsius', value);
  }

  void _navigateToProfilePage() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => ProfilePage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Settings'),
        actions: [
          IconButton(
            icon: Icon(Icons.favorite_border),
            onPressed: () {},
          ),
          IconButton(
            icon: Icon(Icons.share),
            onPressed: () {},
          ),
          IconButton(
            icon: Icon(Icons.more_vert),
            onPressed: () {},
          ),
        ],
      ),
      body: ListView(
        children: [
          _buildProfileSection(),
          _buildSettingsOption('Preferences', Icons.tune),
          _buildSettingsOption('Account', Icons.person),
          _buildSettingsOption('Help Center', Icons.help),
          _buildSettingsOption('Ask an Expert', Icons.lightbulb_outline),
          SwitchListTile(
            title: Text('Temperature Unit'),
            subtitle: Text(_isCelsius ? 'Celsius' : 'Fahrenheit'),
            value: _isCelsius,
            onChanged: (value) {
              setState(() {
                _isCelsius = value;
                _saveTemperatureUnit(_isCelsius);
                widget.onTemperatureUnitChanged(_isCelsius);
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildProfileSection() {
    return Container(
      padding: EdgeInsets.all(16),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Column(
            children: [
              CircleAvatar(
                radius: 50,
                backgroundImage: AssetImage('assets/profile_image.jpg'),
              ),
              SizedBox(height: 16),
              Text(
                'QUINN O\'NEIL',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              Text('Hinge Member'),
            ],
          ),
          Positioned(
            right: 0,
            top: 0,
            child: IconButton(
              icon: Icon(Icons.edit),
              onPressed: _navigateToProfilePage,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsOption(String title, IconData icon) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      trailing: Icon(Icons.arrow_forward_ios),
      onTap: () {
        // Handle option tap
      },
    );
  }
}
