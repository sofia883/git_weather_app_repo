import 'package:flutter/material.dart';
// import 'package:weather_icons/weather_icons.dart';
import 'package:shared_preferences/shared_preferences.dart';
// import 'methods.dart';
import 'weather_screen.dart';
import 'notification_service.dart';

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
    'Few clouds (11-25%)',
    'Scattered clouds (25-50%)',
    'Broken clouds (51-84%)',
    'Overcast clouds (85-100%)'
  ];
  String? _selectedCondition;
  List<String> _savedPreferences = [];
  bool _showAllSavedPreferences = false;
  List<String> _savedLocations = [];

  @override
  void initState() {
    super.initState();
    _loadSavedPreferences();
    _loadSavedLocations();
    NotificationService.initialize(); // Initialize notification service
  }

  void _addPreference(String condition) {
    if (!_savedPreferences.contains(condition)) {
      setState(() {
        _savedPreferences.add(condition);
        _savePreferences();
      });
      _showSaveConfirmationSnackbar();
      NotificationService.checkAndNotify(
          condition); // Call this method when a new preference is saved
    } else {
      _showDuplicatePreferenceSnackbar();
    }
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Saved Locations:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            _savedLocations.isNotEmpty
                ? Column(
                    children: _savedLocations.map((location) {
                      return ListTile(
                        title: Text(location),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: Icon(Icons.visibility, color: Colors.blue),
                              onPressed: () {
                                widget.onLocationSelected(location);
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        WeatherScreen(location: location),
                                  ),
                                );
                              },
                            ),
                            IconButton(
                              icon: Icon(Icons.delete),
                              onPressed: () => _confirmRemoveLocation(location),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  )
                : Text('No saved locations'),
            SizedBox(height: 20),
            Text(
              'Saved Weather Preferences:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            _savedPreferences.isNotEmpty
                ? Column(
                    children: _getDisplayedSavedPreferences()
                        .map((condition) => Container(
                              margin: const EdgeInsets.only(bottom: 8.0),
                              decoration: BoxDecoration(
                                color: Colors.black,
                                borderRadius: BorderRadius.circular(8.0),
                              ),
                              child: ListTile(
                                title: Text(condition),
                                trailing: IconButton(
                                  icon: Icon(Icons.delete),
                                  onPressed: () {
                                    _confirmRemovePreference(condition);
                                  },
                                ),
                              ),
                            ))
                        .toList(),
                  )
                : Center(child: Text('No saved preferences')),
            SizedBox(height: 10),
            if (_savedPreferences.length > 4)
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
            SizedBox(height: 20),
            Text(
              'Set Weather Alerts:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            DropdownButton<String>(
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
                      SizedBox(width: 8),
                      Text(condition),
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
            ),
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
    );
  }

  List<String> _getDisplayedSavedPreferences() {
    if (_showAllSavedPreferences || _savedPreferences.length <= 4) {
      return _savedPreferences;
    }
    return _savedPreferences.take(4).toList();
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
