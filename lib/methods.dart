import 'package:flutter/material.dart';
import 'preferences.dart'; // Import your PreferencesPage here
import 'package:weather_icons/weather_icons.dart';

class Methods extends StatelessWidget {
  final bool isDarkMode;
  final Function(String) onSelected;
  final Function(String) onLocationSelected;

  const Methods({
    Key? key,
    required this.isDarkMode,
    required this.onSelected,
    required this.onLocationSelected,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      icon: Icon(
        Icons.more_vert,
        color: isDarkMode ? Colors.white : Colors.black,
      ),
      onSelected: (value) {
        if (value == 'preferences') {
          Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) =>
                    PreferencesPage(onLocationSelected: (location) {
                      Navigator.pop(context); // Close the PreferencesPage
                      onLocationSelected(
                          location); // Update weather for selected location
                    })),
          );
        } else {
          onSelected(value);
        }
      },
      itemBuilder: (context) => [
        PopupMenuItem(
          value: 'search',
          child: ListTile(
            leading: Icon(Icons.search),
            title: Text('Search'),
          ),
        ),
        PopupMenuItem(
          value: 'current_location',
          child: ListTile(
            leading: Icon(Icons.my_location),
            title: Text('Current Location'),
          ),
        ),
        PopupMenuItem(
          value: 'preferences',
          child: ListTile(
            leading: Icon(Icons.settings),
            title: Text('Preferences'),
          ),
        ),
        PopupMenuItem(
          value: 'profile',
          child: ListTile(
            leading: Icon(Icons.person),
            title: Text('Profile'),
          ),
        ),
        PopupMenuItem(
          value: 'settings',
          child: ListTile(
            leading: Icon(Icons.settings),
            title: Text('Settings'),
          ),
        ),
        PopupMenuItem(
          value: 'Mode',
          child: ListTile(
            leading: Icon(isDarkMode ? Icons.light_mode : Icons.dark_mode),
            title: Text(isDarkMode ? 'Light Mode' : 'Dark Mode'),
          ),
        ),
        PopupMenuItem(
          value: 'logout',
          child: ListTile(
            leading: Icon(Icons.logout),
            title: Text('Logout'),
          ),
        ),
      ],
    );
  }

  static IconData getWeatherIcon(String mainCondition) {
    switch (mainCondition.toLowerCase()) {
      case 'clear':
        return WeatherIcons.day_sunny;
      case 'clouds':
        return WeatherIcons.cloudy;
      case 'rain':
        return WeatherIcons.rain;
      case 'drizzle':
        return WeatherIcons.showers;
      case 'thunderstorm':
        return WeatherIcons.thunderstorm;
      case 'snow':
        return WeatherIcons.snow;
      case 'mist':
      case 'smoke':
      case 'haze':
      case 'dust':
      case 'fog':
        return WeatherIcons.fog;
      default:
        return WeatherIcons.day_sunny; // Default icon
    }
  }
}
