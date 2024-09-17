import 'package:flutter/material.dart';
// import 'package:weather_icons/weather_icons.dart';
import 'package:shared_preferences/shared_preferences.dart';
// import 'methods.dart';
import 'weather_screen.dart';
import 'notification_service.dart';
import 'package:geolocator/geolocator.dart';

class PreferencesPage extends StatefulWidget {
  final Function(String) onLocationSelected;

  PreferencesPage({required this.onLocationSelected});

  @override
  _PreferencesPageState createState() => _PreferencesPageState();
}

class _PreferencesPageState extends State<PreferencesPage> {
  List<String> _weatherConditions = [
    'Thunderstorm with light rain',
    'Thunderstorm with rain',
    'Thunderstorm with heavy rain',
    'Light thunderstorm',
    'Thunderstorm',
    'Heavy thunderstorm',
    'Ragged thunderstorm',
    'Thunderstorm with light drizzle',
    'Thunderstorm with drizzle',
    'Thunderstorm with heavy drizzle',
    'Light intensity drizzle',
    'Drizzle',
    'Heavy intensity drizzle',
    'Light intensity drizzle rain',
    'Drizzle rain',
    'Heavy intensity drizzle rain',
    'Shower rain and drizzle',
    'Heavy shower rain and drizzle',
    'Shower drizzle',
    'Light rain',
    'Moderate rain',
    'Heavy intensity rain',
    'Very heavy rain',
    'Extreme rain',
    'hello',
    'Freezing rain',
    'Light intensity shower rain',
    'Shower rain',
    'Heavy intensity shower rain',
    'Ragged shower rain',
    'Light snow',
    'Snow',
    'Heavy snow',
    'Sleet',
    'Light shower sleet',
    'Shower sleet',
    'Light rain and snow',
    'Rain and snow',
    'Light shower snow',
    'Shower snow',
    'Heavy shower snow',
    'Mist',
    'Smoke',
    'Haze',
    'Sand/dust whirls',
    'Fog',
    'Sand',
    'Dust',
    'Volcanic ash',
    'Squalls',
    'Tornado',
    'clear sky',
    'few clouds',
    'Scattered clouds (25-50%)',
    'broken clouds',
    'overcast clouds'
  ];
  String? _selectedCondition;
  String newPreference = '';
  List<String> _savedPreferences = [];
  bool _showAllSavedPreferences = false;

  bool _showAllSavedLocations = false;
  List<String> _savedLocations = [];
  bool isCurrentLocation = false;
  @override
  void initState() {
    super.initState();
    _loadSavedPreferences();
    _loadSavedLocations();
    NotificationService.initialize();
    _loadIsCurrentLocation(); // Initialize notification service
  }

  Future<void> _loadIsCurrentLocation() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      isCurrentLocation = prefs.getBool('isCurrentLocation') ?? false;
    });
  }

  void _showLocationServiceDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Location Services Disabled'),
          content: Text('Please enable location services to use this feature.'),
          actions: <Widget>[
            TextButton(
              child: Text('Open Settings'),
              onPressed: () {
                Navigator.of(context).pop();
                Geolocator.openLocationSettings();
              },
            ),
            TextButton(
              child: Text('Cancel'),
              onPressed: () {},
            ),
          ],
        );
      },
    );
  }

  void _showLocationPermissionDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Location Permission Required'),
          content:
              Text('Please allow location access to get current weather data.'),
          actions: <Widget>[
            TextButton(
              child: Text('Allow'),
              onPressed: () {
                Navigator.of(context).pop();
                _handleLocationPermission();
              },
            ),
            TextButton(
              child: Text('Deny'),
              onPressed: () {
                // Navigator.of(context).pop();
                // _showSearchBar();
              },
            ),
          ],
        );
      },
    );
  }

  void _addPreference(String condition) async {
    _handleLocationPermission();
    if (!_savedPreferences.contains(condition)) {
      setState(() {
        newPreference = condition;

        _savedPreferences.add(condition);
        _savePreferences();
      });

      final prefs = await SharedPreferences.getInstance();
      bool notificationsEnabled = prefs.getBool('notificationsEnabled') ?? true;

      if (notificationsEnabled) {
        _showSaveConfirmationSnackbar();
        // NotificationService.addNewAlert(condition);
      } else {
        _showNotificationsDisabledSnackbar();
      }
    } else {
      _showDuplicatePreferenceSnackbar();
    }
  }

  void _showNotificationsDisabledSnackbar() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Enable notifications to receive weather alerts'),
        duration: Duration(seconds: 5),
        action: SnackBarAction(
          label: 'Open Settings',
          onPressed: () {
            // Open app settings
            Geolocator.openAppSettings();
          },
        ),
      ),
    );
  }

  Future<void> _handleLocationPermission() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      _showLocationServiceDialog();
      return;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        _showLocationPermissionDialog();
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      _showLocationPermissionDialog();
      return;
    }

    // If permission is granted, check current weather
    // NotificationService.checkCurrentLocationWeather();
  }

  Future<void> _loadSavedLocations() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _savedLocations = prefs.getStringList('savedLocations') ?? [];
    });
  }

  Future<void> _loadSavedPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _savedPreferences = prefs.getStringList('savedPreferences') ?? [];
    });
  }

  Future<void> _savePreferences() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('savedPreferences', _savedPreferences);
  }

  Future<void> _saveLocations() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('savedLocations', _savedLocations);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Preferences'),
        backgroundColor: Colors.black,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Saved Locations:',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              _buildSavedLocations(),
              SizedBox(height: 20),
              Text(
                'Saved Weather Preferences:',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 10),
              _buildSavedPreferences(),
              SizedBox(height: 20),
              Text(
                'Set Weather Alerts:',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 10),
              _buildWeatherAlertDropdown(),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  if (_selectedCondition != null) {
                    _addPreference(_selectedCondition!);
                  }
                },
                child: Text('Save Alert'),
                style: ElevatedButton.styleFrom(
                  iconColor: Colors.black,
                  shadowColor: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSavedLocations() {
    if (_savedLocations.isEmpty) {
      return Text('No saved locations');
    }

    List<String> displayedLocations = _showAllSavedLocations
        ? _savedLocations
        : _savedLocations.take(3).toList();

    return Column(
      children: [
        ...displayedLocations.map((location) => _buildLocationTile(location)),
        if (_savedLocations.length > 3)
          TextButton(
            onPressed: () {
              setState(() {
                _showAllSavedLocations = !_showAllSavedLocations;
              });
            },
            child: Text(
              _showAllSavedLocations ? 'Show Less' : 'See More',
              style: TextStyle(color: Colors.black),
            ),
          ),
      ],
    );
  }

  Widget _buildLocationTile(String location) {
    return ListTile(
      title: Text(location),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: Icon(Icons.delete),
            onPressed: () => _confirmRemoveLocation(location),
          ),
        ],
      ),
      onTap: () {
        widget.onLocationSelected(location);
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => WeatherScreen(location: location),
          ),
        );
      },
    );
  }

  Widget _buildPreferenceTile(String condition) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8.0),
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(8.0),
      ),
      child: ListTile(
        title: Text(condition, style: TextStyle(color: Colors.white)),
        trailing: IconButton(
          icon: Icon(Icons.delete, color: Colors.white),
          onPressed: () => _confirmRemovePreference(condition),
        ),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => WeatherScreen(location: condition),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSavedPreferences() {
    if (_savedPreferences.isEmpty) {
      return Center(child: Text('No saved preferences'));
    }

    List<String> displayedPreferences = _showAllSavedPreferences
        ? _savedPreferences
        : _savedPreferences.take(3).toList();

    return Column(
      children: [
        ...displayedPreferences
            .map((condition) => _buildPreferenceTile(condition)),
        if (_savedPreferences.length > 3)
          TextButton(
            onPressed: () {
              setState(() {
                _showAllSavedPreferences = !_showAllSavedPreferences;
              });
            },
            child: Text(
              _showAllSavedPreferences ? 'Show Less' : 'See More',
              style: TextStyle(color: Colors.black),
            ),
          ),
      ],
    );
  }

  // Widget _buildPreferenceTile(String condition) {
  //   return Container(
  //     margin: const EdgeInsets.only(bottom: 8.0),
  //     decoration: BoxDecoration(
  //       color: Colors.black,
  //       borderRadius: BorderRadius.circular(8.0),
  //     ),
  //     child: ListTile(
  //       title: Text(condition, style: TextStyle(color: Colors.white)),
  //       trailing: IconButton(
  //         icon: Icon(Icons.delete, color: Colors.white),
  //         onPressed: () => _confirmRemovePreference(condition),
  //       ),
  //     ),
  //   );
  // }

  Widget _buildWeatherAlertDropdown() {
    return Container(
      width: 260,
      padding: EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey),
        borderRadius: BorderRadius.circular(18),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          isExpanded: true,
          hint: Text('Select weather condition'),
          value: _selectedCondition,
          onChanged: (value) {
            if (value != null && !_savedPreferences.contains(value)) {
              setState(() {
                _selectedCondition = value;
              });
            }
          },
          items: _weatherConditions.map((condition) {
            bool isSaved = _savedPreferences.contains(condition);
            return DropdownMenuItem<String>(
              value: condition,
              child: Row(
                children: [
                  Expanded(child: Text(condition)),
                  if (isSaved)
                    Padding(
                      padding: const EdgeInsets.only(left: 8.0),
                      child: Text(
                        'Saved',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ),
                ],
              ),
              enabled: !isSaved,
            );
          }).toList(),
          selectedItemBuilder: (BuildContext context) {
            return _weatherConditions.map<Widget>((String item) {
              return Text(item);
            }).toList();
          },
          itemHeight: 48,
          menuMaxHeight: 48.0 * 7,
        ),
      ),
    );
  }

  void _confirmRemovePreference(String condition) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Remove Preference'),
          content: Text(
              'Are you sure you want to remove "$condition" from your saved preferences?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                setState(() {
                  _savedPreferences.remove(condition);
                  _savePreferences();
                });
                Navigator.of(context).pop();
                _showRemovePreferenceSnackbar();
              },
              child: Text('Remove'),
            ),
          ],
        );
      },
    );
  }

  void _confirmRemoveLocation(String location) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Remove Location'),
          content: Text(
              'Are you sure you want to remove "$location" from your saved locations?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                setState(() {
                  _savedLocations.remove(location);
                  _saveLocations();
                });
                Navigator.of(context).pop();
                _showRemoveLocationSnackbar();
              },
              child: Text('Remove'),
            ),
          ],
        );
      },
    );
  }

  void _showSaveConfirmationSnackbar() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
          content: Text('Weather preference saved!'),
          duration: Duration(seconds: 2)),
    );
  }

  void _showDuplicatePreferenceSnackbar() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
          content: Text('This preference is already saved.'),
          duration: Duration(seconds: 2)),
    );
  }

  void _showRemovePreferenceSnackbar() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
          content: Text('Weather preference removed!'),
          duration: Duration(seconds: 2)),
    );
  }

  void _showRemoveLocationSnackbar() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
          content: Text('Location removed!'), duration: Duration(seconds: 2)),
    );
  }
}
