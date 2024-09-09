import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:math';
import 'package:weather_app/api_key.dart';
import 'package:geolocator/geolocator.dart';
import 'package:country_picker/country_picker.dart';
import 'package:weather_icons/weather_icons.dart'; // Import the weather_icons package
import 'handle_logout.dart';
import 'setting_-page.dart';
import 'profile_page.dart';
import 'methods.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart' as ph;


class WeatherScreen extends StatefulWidget {
  final String? location;

  const WeatherScreen({Key? key, this.location}) : super(key: key);

  // const WeatherScreen({Key? key}) : super(key: key);

  @override
  State<WeatherScreen> createState() => WeatherScreenState();
}

class WeatherScreenState extends State<WeatherScreen> {
  Future<Map<String, dynamic>>? weather;
  String cityName = 'Current Location';
  List<String> searchResults = [];
  final TextEditingController _searchController = TextEditingController();
  bool _isSearching = false;
  Map<String, String> countryCodeToName = {};
  bool _isDarkMode = true;
  bool _isCelsius = true; // Add this to track temperature unit
  bool isLoading = true;
  String errorMessage = '';
  List<String> _savedPreferences = []; // Add this line
  bool isCurrentLocation = false;
bool isSearchBarVisible = false;

  Map<String, dynamic>? weatherData;

  @override
  void initState() {
    super.initState();
    _loadSavedPreferences().then((_) {
      _initializeWeather(useCurrentLocation: false);
    });
  }
   Future<void> _checkLocationPermission() async {
    var status = await ph.Permission.location.status;
    if (status.isGranted) {
      await _getCurrentLocation();
    } else if (status.isDenied) {
      await _requestLocationPermission();
    } else if (status.isPermanentlyDenied) {
      _showPermanentlyDeniedDialog();
    }
  }

  Future<void> _requestLocationPermission() async {
    var status = await ph.Permission.location.request();
    if (status.isGranted) {
      await _getCurrentLocation();
    } else {
      _showLocationDeniedDialog();
    }
  }

  Future<void> _getCurrentLocation() async {
    try {
      Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);
      await _fetchWeatherData(position.latitude, position.longitude);
    } catch (e) {
      print("Error getting location: $e");
      _showLocationErrorSnackbar();
    }
  }

  Future<void> _fetchWeatherData(double lat, double lon) async {
    try {
      final response = await http.get(Uri.parse(
          'https://api.openweathermap.org/data/2.5/weather?lat=$lat&lon=$lon&appid=$openWeatherAPIKey&units=metric'));
      
      if (response.statusCode == 200) {
        setState(() {
          weatherData = json.decode(response.body);
          isLoading = false;
        });
      } else {
        throw Exception('Failed to load weather data');
      }
    } catch (e) {
      setState(() {
        errorMessage = 'Failed to fetch weather data: $e';
        isLoading = false;
      });
    }
  }

  void _showLocationDeniedDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Location Access Required'),
          content: Text('Please allow location access to get weather information for your current location.'),
          actions: <Widget>[
            TextButton(
              child: Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
                _showSearchBar();
              },
            ),
            TextButton(
              child: Text('Try Again'),
              onPressed: () {
                Navigator.of(context).pop();
                _requestLocationPermission();
              },
            ),
          ],
        );
      },
    );
  }

  void _showPermanentlyDeniedDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Location Permission Required'),
          content: Text('Location permission is permanently denied. Please enable it in your device settings.'),
          actions: <Widget>[
            TextButton(
              child: Text('Open Settings'),
              onPressed: () {
                ph.openAppSettings();
              },
            ),
            TextButton(
              child: Text('Use Search Instead'),
              onPressed: () {
                Navigator.of(context).pop();
                _showSearchBar();
              },
            ),
          ],
        );
      },
    );
  }

  void _showLocationErrorSnackbar() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Failed to get current location. Please try again or use search.')),
    );
    _showSearchBar();
  }

  void _showSearchBar() {
    setState(() {
      isSearchBarVisible = true;
      isLoading = false;
    });
  }


  Future<void> _initializeWeather({bool useCurrentLocation = false}) async {
    setState(() {
      isLoading = true;
      errorMessage = '';
    });

    try {
      if (widget.location != null && widget.location!.isNotEmpty) {
        await _initializeWeatherForLocation(widget.location!);
      } else if (useCurrentLocation) {
        await _getCurrentLocation();
      } else {
        // Start with a default location or last known location
        String? lastLocation = await _getLastKnownLocation();
        if (lastLocation != null) {
          await _initializeWeatherForLocation(lastLocation);
        } else {
          // Use a default location if no last known location
          await _initializeWeatherForLocation('London');
        }

        // Fetch current location in the background if not already using it
        if (!useCurrentLocation) {
          _getCurrentLocation();
        }
      }
    } catch (e) {
      print("Error initializing weather: $e");
      setState(() {
        errorMessage = 'Failed to fetch weather data. Please try again.';
      });
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  
  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadSavedPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _savedPreferences = prefs.getStringList('savedPreferences') ?? [];
      _isDarkMode = prefs.getBool('isDarkMode') ?? true;
      _isCelsius = prefs.getBool('isCelsius') ?? true;
    });
  }

  Future<String?> _getLastKnownLocation() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('lastSelectedLocation');
  }

  Future<void> _initializeWeatherForLocation(String location) async {
    try {
      final weatherData = await getCurrentWeather(location.split(',')[0]);
      setState(() {
        weather = Future.value(weatherData);
        cityName =
            '${weatherData['city']['name']}, ${weatherData['city']['country']}';
      });
    } catch (e) {
      print("Error initializing weather for location: $e");
      setState(() {
        errorMessage = 'Failed to fetch weather data. Please try again.';
      });
    }
  }

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  void testNotification() {
    showNotification('Test Notification', 'This is a test notification');
  }

 
  void _handleTemperatureUnitChanged(bool isCelsius) async {
    setState(() {
      _isCelsius = isCelsius;
    });

    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isCelsius', isCelsius);

    // Reload weather for the current locationq
    if (cityName != 'Current Location') {
      _initializeWeatherForLocation(cityName);
    } else {
      _initializeWeather(useCurrentLocation: true);
    }
  }

  void selectCity(String selectedCity) async {
    setState(() {
      cityName = selectedCity;
      weather = getCurrentWeather(selectedCity.split(',')[0]);
      searchResults = [];
      _isSearching = false;
      _searchController.clear();
      isCurrentLocation =
          false; // Set flag to false when user selects a different city
    });
    _showSaveLocationSnackbar(selectedCity);

    // Save the selected location
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('lastSelectedLocation', selectedCity);
  }

  Future<Map<String, dynamic>> getCurrentWeather(String city) async {
    try {
      final res = await http.get(
        Uri.parse(
          'https://api.openweathermap.org/data/2.5/forecast?q=$city&APPID=$openWeatherAPIKey',
        ),
      );
      if (res.statusCode != 200) {
        throw Exception('Failed to load weather data: ${res.statusCode}');
      }
      final data = jsonDecode(res.body);
      setState(() {
        String countryCode = data['city']['country'];
        String countryName = Country.tryParse(countryCode)?.name ?? countryCode;
        cityName = '${data['city']['name']}, $countryName';
      });
      return data;
    } catch (e) {
      print("Error fetching weather: $e");
      throw Exception('Failed to load weather data');
    }
  }

  Future<void> searchLocation(String query) async {
    if (query.isEmpty) {
      setState(() {
        searchResults = [];
      });
      return;
    }

    try {
      final response = await http.get(
        Uri.parse(
            'https://api.openweathermap.org/geo/1.0/direct?q=$query&limit=5&appid=$openWeatherAPIKey'),
      );
      if (response.statusCode == 200) {
        List<dynamic> cities = json.decode(response.body);
        setState(() {
          searchResults = cities.map((city) {
            String countryCode = city['country'];
            String countryName =
                Country.tryParse(countryCode)?.name ?? countryCode;
            return "${city['name']}, $countryName";
          }).toList();
        });
      } else {
        throw Exception('Failed to load search results');
      }
    } catch (e) {
      print("Error searching location: $e");
      setState(() {
        searchResults = ['Error: Could not load search results'];
      });
    }
  }

  double convertTemperature(double tempK, bool isCelsius) {
    if (isCelsius) {
      return tempK - 273.15;
    } else {
      return (tempK - 273.15) * 9 / 5 + 32;
    }
  }

  void _showSaveLocationSnackbar(String location) {
    _scaffoldMessengerKey.currentState?.showSnackBar(
      SnackBar(
        content: Text('Do you want to save $location to your preferences?'),
        action: SnackBarAction(
          label: 'Save',
          onPressed: () {
            _saveLocation(location);
          },
        ),
      ),
    );
  }

  // Method to save the location using SharedPreferences
  void _saveLocation(String location) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String>? savedLocations = prefs.getStringList('savedLocations') ?? [];
    if (!savedLocations.contains(location)) {
      savedLocations.add(location);
      await prefs.setStringList('savedLocations', savedLocations);
      print('Location saved: $location');
    } else {
      print('Location already saved');
    }
  }

  void _handleLocationSelected(String location) {
    setState(() {
      cityName = location;
      weather = getCurrentWeather(location.split(',')[0]);
    });
  }

  ThemeData get _lightTheme {
    return ThemeData.light().copyWith(
      colorScheme: ColorScheme.light(
        primary: Colors.blue,
        secondary: Colors.orange, // This replaces the accentColor
      ),

      // Add more customizations as needed
    );
  }

  ThemeData get _darkTheme {
    return ThemeData.dark().copyWith(
      colorScheme: ColorScheme.dark(
        primary: Colors.orange,
        secondary: Colors.deepOrange, // This replaces the accentColor
      ),

      // Add more customizations as needed
    );
  }

  Future<void> _fetchWeatherForCurrentLocation(double lat, double lon) async {
    try {
      final weatherData = await getWeatherByCoordinates(lat, lon);
      setState(() {
        weather = Future.value(weatherData);
        cityName =
            weatherData['city']['name'] + ', ' + weatherData['city']['country'];
      });
    } catch (e) {
      print("Error fetching weather for current location: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to fetch weather for current location')),
      );
    }
  }

  Future<Map<String, dynamic>> getWeatherByCoordinates(
      double lat, double lon) async {
    try {
      final res = await http.get(
        Uri.parse(
          'https://api.openweathermap.org/data/2.5/forecast?lat=$lat&lon=$lon&APPID=$openWeatherAPIKey',
        ),
      );
      if (res.statusCode != 200) {
        throw Exception('Failed to load weather data: ${res.statusCode}');
      }
      final data = jsonDecode(res.body);
      print("Fetched weather data: $data"); // Debug print
      return data;
    } catch (e) {
      print("Error fetching weather by coordinates: $e");
      throw Exception('Failed to load weather data');
    }
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
              child: Text('OK'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  void _handleMenuSelection(String value) {
    switch (value) {
      case 'search':
        setState(() {
          _isSearching = !_isSearching;
          if (!_isSearching) {
            _searchController.clear();
            searchResults = [];
          }
        });
        break;
      case 'current_location':
        // _getCurrentLocation();
        _initializeWeather(useCurrentLocation: true);
        break;

        break;
      case 'profile':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => ProfilePage()),
        );
        break;
      case 'settings':
        Navigator.push(
          context,
          MaterialPageRoute(
              builder: (context) => SettingsPage(
                    onLocationSelected: _handleLocationSelected,
                    onTemperatureUnitChanged: _handleTemperatureUnitChanged,
                  )),
        );
        break;

      case 'Mode':
        _toggleTheme();
        break;
      case 'logout':
        LogoutHandler.handleLogout(context);
        break;
    }
  }

  void _toggleTheme() {
    setState(() {
      _isDarkMode = !_isDarkMode;
    });
  }

  Future<void> showNotification(String title, String body) async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'your_channel_id',
      'your_channel_name',
      importance: Importance.max,
      priority: Priority.high,
      showWhen: false,
    );
    const NotificationDetails platformChannelSpecifics =
        NotificationDetails(android: androidPlatformChannelSpecifics);
    await flutterLocalNotificationsPlugin.show(
        0, title, body, platformChannelSpecifics);
  }

  Widget _buildCurrentWeather(Map<String, dynamic> currentWeatherData) {
    final tempK = currentWeatherData['main']['temp'];
    final currentTemp = convertTemperature(tempK, _isCelsius).round();
    final weatherDescription = currentWeatherData['weather'][0]['description'];

    print('Current weather description: $weatherDescription');
    print('Is current location: $isCurrentLocation');
    print('Saved preferences: $_savedPreferences');

    if (_savedPreferences.contains(weatherDescription) && isCurrentLocation) {
      print('Weather condition matched: $weatherDescription');
      WidgetsBinding.instance.addPostFrameCallback((_) {
        showNotification('Weather Alert',
            'Current weather matches your preference: $weatherDescription');
      });
    } else {
      print('No match found for: $weatherDescription');
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          cityName + (isCurrentLocation ? " (Current Location)" : ""),
          style: GoogleFonts.abel(
            textStyle: TextStyle(
                fontSize: 25, color: AppColors.getTextColor(_isDarkMode)),
          ),
        ),
        Row(
          children: [
            SizedBox(
              width: 82.0,
            ),
            Container(
              height: 225,
              child: RichText(
                text: TextSpan(
                  children: [
                    TextSpan(
                      text: '$currentTemp',
                      style: GoogleFonts.abel(
                        textStyle: TextStyle(
                            fontSize: 200,
                            color: AppColors.getTextColor(_isDarkMode)),
                      ),
                    ),
                    WidgetSpan(
                      child: Transform.translate(
                        offset: Offset(-14, -90.0),
                        child: Text(
                          '°${_isCelsius ? 'C' : 'F'}',
                          style: GoogleFonts.abel(
                            textStyle: TextStyle(
                                fontSize: 50,
                                color: AppColors.getTextColor(_isDarkMode)),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: 14),
        Text(
          'broken clouds',
          style: GoogleFonts.abel(
            textStyle: TextStyle(
                fontSize: 45, color: AppColors.getTextColor(_isDarkMode)),
          ),
        ),
        Text(
          'Wind:',
          style: TextStyle(fontSize: 16),
        ),
        Text(
          '${currentWeatherData['wind']['speed']} m/s',
          style: TextStyle(fontSize: 16),
        ),
      ],
    );
  }

  Widget _buildHourlyForecast(List<dynamic> list) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 6.0),
          child: Container(
            height: 120,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount:
                  min(8, list.length), // Show next 24 hours (8 * 3 hours)
              itemBuilder: (context, index) {
                final hourlyWeather = list[index];
                final temp = convertTemperature(
                    hourlyWeather['main']['temp'], _isCelsius);
                final time = DateTime.fromMillisecondsSinceEpoch(
                    hourlyWeather['dt'] * 1000);
                final weatherIcon = WeatherUtils.getWeatherIcon(
                    hourlyWeather['weather'][0]['main']);

                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12.0),
                  child: Column(
                    children: [
                      Text(
                        DateFormat('ha')
                            .format(time), // Format as hour (e.g., 3PM)
                        style: TextStyle(fontSize: 14),
                      ),
                      SizedBox(height: 8),
                      BoxedIcon(
                        weatherIcon,
                        size: 30,
                        color: _isDarkMode ? Colors.white : Colors.black,
                      ),
                      SizedBox(height: 8),
                      Text(
                        '${temp.round()}°',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        )
      ],
    );
  }

  Widget _buildDailyForecast(List forecastList, {bool highlightToday = false}) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal, // Enable horizontal scrolling
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(
          min(7, (forecastList.length / 8).floor()), // Show the next 7 days
          (index) {
            final int calculatedIndex = index * 8; // Start from today
            if (calculatedIndex >= forecastList.length) {
              return Container(); // Return empty container if index is out of bounds
            }

            final futureWeather = forecastList[calculatedIndex];
            final temp = (futureWeather['main']['temp'] - 273.15)
                .round(); // Kelvin to Celsius
            final date =
                DateTime.fromMillisecondsSinceEpoch(futureWeather['dt'] * 1000);

            // Check if it's the first item and highlight only when the "Today" tab is clicked
            final isFirstItem = index == 0 && highlightToday;

            return Padding(
              padding: const EdgeInsets.all(22.0),
              child: Column(
                children: [
                  BoxedIcon(
                      WeatherUtils.getWeatherIcon(
                          futureWeather['weather'][0]['main']),
                      size: 30,
                      color: isFirstItem
                          ? Colors.red
                          : AppColors.getTextColor(_isDarkMode)),
                  Text(
                    '$temp°',
                    style: GoogleFonts.berkshireSwash(
                      textStyle: TextStyle(
                        fontSize: 20,
                        fontWeight:
                            isFirstItem ? FontWeight.bold : FontWeight.normal,
                        color: isFirstItem
                            ? Colors.red
                            : AppColors.getTextColor(_isDarkMode),
                      ),
                    ),
                  ),
                  Text(
                    DateFormat('E').format(date),
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight:
                          isFirstItem ? FontWeight.bold : FontWeight.normal,
                      color: isFirstItem
                          ? Colors.red
                          : AppColors.getTextColor(_isDarkMode),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  final GlobalKey<ScaffoldMessengerState> _scaffoldMessengerKey =
      GlobalKey<ScaffoldMessengerState>();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: _isDarkMode ? _darkTheme : _lightTheme,
      home: ScaffoldMessenger(
        key: _scaffoldMessengerKey,
        child: Scaffold(
          backgroundColor: AppColors.getbgColor(_isDarkMode),
          body: Stack(children: [
            SafeArea(
              child: isLoading
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircularProgressIndicator(),
                          SizedBox(height: 20),
                          Text(
                            'Fetching weather data...',
                            style: TextStyle(
                              fontSize: 18,
                              color: _isDarkMode ? Colors.white : Colors.black,
                            ),
                          ),
                        ],
                      ),
                    )
                  : errorMessage.isNotEmpty
                      ? Center(
                          child: Text(
                            errorMessage,
                            style: TextStyle(
                              fontSize: 18,
                              color: Colors.red,
                            ),
                          ),
                        )
                      : Column(
                          children: [
                            _isSearching
                                ? Padding(
                                    padding: const EdgeInsets.all(6.0),
                                    child: TextField(
                                      controller: _searchController,
                                      autofocus: true,
                                      style: TextStyle(
                                          color: _isDarkMode
                                              ? Colors.white
                                              : Colors.black),
                                      decoration: InputDecoration(
                                        suffixIcon: IconButton(
                                          icon: Icon(
                                              _isSearching
                                                  ? Icons.close
                                                  : Icons.search,
                                              color: _isDarkMode
                                                  ? Colors.white
                                                  : Colors.black),
                                          onPressed: () {
                                            setState(() {
                                              _isSearching = !_isSearching;
                                              if (!_isSearching) {
                                                _searchController.clear();
                                                searchResults = [];
                                                // _initializeWeather(); // If needed
                                              }
                                            });
                                          },
                                        ),
                                        hintText: 'Search for a city...',
                                        hintStyle: TextStyle(
                                            color: _isDarkMode
                                                ? Colors.white60
                                                : Colors.black),
                                        border: InputBorder.none,
                                      ),
                                      onChanged: (value) {
                                        searchLocation(value);
                                      },
                                    ),
                                  )
                                : Row(
                                    children: [
                                      Padding(
                                        padding: const EdgeInsets.only(
                                            top: 5.0, left: 8.0),
                                        child: WeatherUtils(
                                          isDarkMode: _isDarkMode,
                                          onSelected: _handleMenuSelection,
                                          onLocationSelected:
                                              _handleLocationSelected,
                                        ),
                                      ),
                                      Spacer(), // Pushes the theme toggle container to the right
                                      Padding(
                                        padding: const EdgeInsets.only(
                                            top: 5.0, right: 8.0),
                                        child: Container(
                                          width: 30, // Adjust width as needed
                                          height: 60, // Adjust height as needed
                                          decoration: BoxDecoration(
                                            boxShadow: [
                                              BoxShadow(
                                                color: _isDarkMode
                                                    ? Colors.grey
                                                        .withOpacity(0.2)
                                                    : Colors.black
                                                        .withOpacity(0.2),
                                                spreadRadius: 5,
                                                blurRadius: 7,
                                                offset: Offset(0, 7),
                                              ),
                                            ],
                                            color: _isDarkMode
                                                ? Colors.black
                                                : Colors.white,
                                            border: Border.all(
                                              color: _isDarkMode
                                                  ? Colors.black
                                                  : Colors.white,
                                              width: 2.0,
                                            ),
                                            borderRadius:
                                                BorderRadius.circular(25),
                                          ),
                                          child: Column(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceEvenly,
                                            children: [
                                              GestureDetector(
                                                onTap: _isDarkMode
                                                    ? _toggleTheme
                                                    : null,
                                                child: AnimatedOpacity(
                                                  opacity:
                                                      _isDarkMode ? 1.0 : 0.3,
                                                  duration: Duration(
                                                      milliseconds: 200),
                                                  child: Icon(
                                                    Icons.sunny,
                                                    color: Colors.orange,
                                                    size: 20,
                                                  ),
                                                ),
                                              ),
                                              GestureDetector(
                                                onTap: _isDarkMode
                                                    ? null
                                                    : _toggleTheme,
                                                child: AnimatedOpacity(
                                                  opacity:
                                                      _isDarkMode ? 0.3 : 1.0,
                                                  duration: Duration(
                                                      milliseconds: 200),
                                                  child: Icon(
                                                    Icons.dark_mode,
                                                    color: const Color.fromARGB(
                                                        255, 105, 106, 107),
                                                    size: 20,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                            if (_isSearching && searchResults.isNotEmpty)
                              Expanded(
                                child: ListView.builder(
                                  itemCount: searchResults.length,
                                  itemBuilder: (context, index) {
                                    return ListTile(
                                      title: Text(searchResults[index]),
                                      onTap: () {
                                        selectCity(searchResults[index]);
                                      },
                                    );
                                  },
                                ),
                              ),
                            if (!_isSearching)
                              Expanded(
                                  child: FutureBuilder<Map<String, dynamic>>(
                                future: weather,
                                builder: (context, snapshot) {
                                  if (snapshot.connectionState ==
                                      ConnectionState.waiting) {
                                    return Center(
                                        child: CircularProgressIndicator());
                                  }
                                  if (snapshot.hasError) {
                                    return Center(
                                        child:
                                            Text('Error: ${snapshot.error}'));
                                  }
                                  if (!snapshot.hasData) {
                                    return Center(
                                        child: Text('No data available'));
                                  }

                                  final data = snapshot.data!;
                                  final list = data['list'] as List;
                                  final currentWeatherData =
                                      list.isNotEmpty ? list[0] : null;

                                  if (currentWeatherData == null) {
                                    return Center(
                                        child:
                                            Text('No weather data available'));
                                  }

                                  // Cast numeric values correctly
// final forecastList = snapshot.data?['hourly'] as List<dynamic>?;
                                  final forecastList =
                                      data['list'] as List<dynamic>? ?? [];
                                  return Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.center,
                                      children: [
                                        _buildCurrentWeather(
                                            currentWeatherData), // Display current weather
                                        SizedBox(
                                            height:
                                                93.0), // Space between current weather and tabs
                                        // TabBar for "Today", "Hourly", and "Next 4 Days"
                                        DefaultTabController(
                                          length: 3,
                                          child: Column(
                                            children: [
                                              TabBar(
                                                labelColor:
                                                    AppColors.getTextColor(
                                                        _isDarkMode),
                                                unselectedLabelColor:
                                                    Colors.grey,
                                                indicatorColor: Colors.red,
                                                dividerColor: Colors
                                                    .transparent, // Customize tab indicator colorindicator color
                                                tabs: [
                                                  Tab(text: "Today"),
                                                  Tab(
                                                      text:
                                                          "Hourly Temperature"),
                                                  Tab(text: "Next 4 Days"),
                                                ],
                                              ),
                                              SizedBox(
                                                  height:
                                                      10), // Space between tabs and content
                                              // TabBarView for displaying the respective content
                                              Container(
                                                height:
                                                    160, // Set height for forecast content
                                                child: TabBarView(
                                                  children: [
                                                    _buildDailyForecast(
                                                        highlightToday: true,
                                                        forecastList), // Today forecast
                                                    _buildHourlyForecast(
                                                        forecastList), // Hourly forecast
                                                    _buildDailyForecast(
                                                        forecastList), // Next 4 days forecast
                                                  ],
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              )),
                          ],
                        ),
            ),
          ]),
        ),
      ),
    );
  }
}

class QuadrantHourlyForecast extends StatefulWidget {
  final List<dynamic> forecasts;
  final double radius;

  const QuadrantHourlyForecast({
    Key? key,
    required this.forecasts,
    this.radius = 60,
  }) : super(key: key);

  @override
  _QuadrantHourlyForecastState createState() => _QuadrantHourlyForecastState();
}

class _QuadrantHourlyForecastState extends State<QuadrantHourlyForecast> {
  double _rotationAngle = 0.0;

  void _handlePanUpdate(DragUpdateDetails details) {
    setState(() {
      _rotationAngle += details.delta.dx * 0.01;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.bottomRight,
      child: Container(
        width: widget.radius * 1, // Reduced size
        height: widget.radius * 0.8, // Reduced size
        child: GestureDetector(
          onPanUpdate: _handlePanUpdate,
          child: Stack(
            children: [
              CustomPaint(
                size: Size(widget.radius * 2, widget.radius * 2),
                // painter: QuadrantPainter(),
              ),
              ...List.generate(widget.forecasts.length, (index) {
                final forecast = widget.forecasts[index];
                final time =
                    DateTime.fromMillisecondsSinceEpoch(forecast['dt'] * 1000);
                final temp = (forecast['main']['temp'] - 273.15).round();
                final weatherMain = forecast['weather'][0]['main'];

                final angle = index * (pi / 4) - _rotationAngle;
                final x = widget.radius + widget.radius * cos(angle);
                final y = widget.radius + widget.radius * sin(angle);

                return Positioned(
                  left: x - 30, // Adjusted for reduced size
                  top: y - 30, // Adjusted for reduced size
                  child: Transform.rotate(
                    angle: angle + pi / 2,
                    child: Container(
                      width: 80, // Reduced size
                      height: 80, // Reduced size
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(DateFormat('h a').format(time),
                              style:
                                  TextStyle(fontSize: 8)), // Adjusted font size
                          BoxedIcon(WeatherUtils.getWeatherIcon(weatherMain),
                              size: 16), // Adjusted icon size
                          Text('$temp°C',
                              style:
                                  TextStyle(fontSize: 8)), // Adjusted font size
                        ],
                      ),
                    ),
                  ),
                );
              }),
            ],
          ),
        ),
      ),
    );
  }
}

class AppColors {
  static Color getbgColor(bool isDarkMode) {
    return isDarkMode
        ? Color.fromARGB(255, 25, 25, 26)
        : const Color.fromARGB(255, 221, 217, 217);
  }

  static Color getTextColor(bool isDarkMode) {
    return isDarkMode ? Colors.white : Colors.black;
  }

  static Color getIconColor(bool isDarkMode) {
    return isDarkMode ? Colors.white : Colors.black;
  }
}
