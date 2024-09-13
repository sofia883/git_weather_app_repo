import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'profile_page.dart';
import 'preferences.dart'; // Make sure to create this file

class SettingsPage extends StatefulWidget {
  final void Function(bool) onTemperatureUnitChanged;
  final Function(String) onLocationSelected;
  const SettingsPage({
    Key? key,
    required this.onTemperatureUnitChanged,
    required this.onLocationSelected,
  }) : super(key: key);

  @override
  SettingsPageState createState() => SettingsPageState();
}

class SettingsPageState extends State<SettingsPage> {
  late bool _isCelsius;
  late String _selectedTheme;
  late bool _notificationsEnabled;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      _isCelsius = prefs.getBool('isCelsius') ?? true;
      _selectedTheme = prefs.getString('theme') ?? 'light';
      _notificationsEnabled = prefs.getBool('notificationsEnabled') ?? true;
      String? savedLocation = prefs.getString('lastSelectedLocation');
    });
  }

  Future<void> _saveSettings() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isCelsius', _isCelsius);
    await prefs.setString('theme', _selectedTheme);
    
     await prefs.setBool('notificationsEnabled', _notificationsEnabled); // Save this
  }

  void _navigateToProfilePage() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => ProfilePage()),
    );
  }

  void _navigateToPreferencesPage() {
    Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => PreferencesPage(onLocationSelected: (location) {
            Navigator.pop(context); // Close the PreferencesPage
            widget.onLocationSelected(
                location); // Update weather for selected location
          }),
        ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Settings'),
      ),
      body: ListView(
        children: [
          _buildProfileSection(),
          _buildSettingsOption(
              'Preferences', Icons.tune, _navigateToPreferencesPage),
          _buildTemperatureUnitSetting(),
          _buildThemeSetting(),
          _buildNotificationsSetting(),
        ],
      ),
    );
  }

  Widget _buildSettingsOption(String title, IconData icon, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      trailing: Icon(Icons.arrow_forward_ios),
      onTap: onTap,
    );
  }

  Widget _buildTemperatureUnitSetting() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text('Temperature Unit'),
          ToggleButtons(
            children: [
              Text('°C'),
              Text('°F'),
            ],
            isSelected: [_isCelsius, !_isCelsius],
            onPressed: (index) {
              setState(() {
                _isCelsius = index == 0;
                _saveSettings();
                widget.onTemperatureUnitChanged(_isCelsius);
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildThemeSetting() {
    return ListTile(
      title: Text('Theme'),
      trailing: DropdownButton<String>(
        value: _selectedTheme,
        items: ['light', 'dark', 'system'].map((String value) {
          return DropdownMenuItem<String>(
            value: value,
            child: Text(value.capitalize()),
          );
        }).toList(),
        onChanged: (String? newValue) {
          if (newValue != null) {
            setState(() {
              _selectedTheme = newValue;
              _saveSettings();
            });
          }
        },
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

  Widget _buildNotificationsSetting() {
    return SwitchListTile(
      title: Text('Weather Notifications'),
      value: _notificationsEnabled,
      onChanged: (bool value) {
        setState(() {
          _notificationsEnabled = value;
          _saveSettings(); // Save the updated notification setting
        });
      },
    );
  }
}

extension StringExtension on String {
  String capitalize() {
    return "${this[0].toUpperCase()}${this.substring(1)}";
  }
}
