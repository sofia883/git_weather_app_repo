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

  @override
  void initState() {
    super.initState();
    if (widget.location != null) {
      _initializeWeatherForLocation(widget.location!);
    } else {
      _initializeWeather();
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _initializeWeather() async {
    setState(() {
      isLoading = true;
      errorMessage = '';
    });
    try {
      await _getCurrentLocation();
    } catch (e) {
      print("Error initializing weather: $e");
      setState(() {
        weather = getCurrentWeather('London');
        cityName = 'London, United Kingdom';
      });
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _initializeWeatherForLocation(String location) async {
    setState(() {
      isLoading = true;
      errorMessage = '';
    });
    try {
      setState(() {
        cityName = location;
        weather = getCurrentWeather(location.split(',')[0]);
      });
    } catch (e) {
      print("Error initializing weather for location: $e");
      setState(() {
        errorMessage = 'Failed to fetch weather data. Please try again.';
      });
    } finally {
      setState(() {
        isLoading = false;
      });
    }
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

  void _handleTemperatureUnitChanged(bool isCelsius) {
    setState(() {
      _isCelsius = isCelsius;
    });
    _initializeWeather(); // Re-initialize weather to apply the unit change
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

  void selectCity(String selectedCity) {
    setState(() {
      cityName = selectedCity;
      weather = getCurrentWeather(cityName.split(',')[0]);
      searchResults = [];
      _isSearching = false;
      _searchController.clear();
    });
    _showSaveLocationSnackbar(selectedCity);
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

  Future<void> _getCurrentLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    // Check if location services are enabled
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      _showLocationServiceDialog();
      return;
    }

    // Check location permission
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Location permission denied')),
        );
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Location permissions are permanently denied')),
      );
      return;
    }

    // Permissions are granted, get the current position
    try {
      Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);
      print("Latitude: ${position.latitude}, Longitude: ${position.longitude}");

      // Fetch weather data for the current location
      await _fetchWeatherForCurrentLocation(
          position.latitude, position.longitude);
    } catch (e) {
      print("Error getting location: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to get current location')),
      );
    }
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
        _getCurrentLocation();
        _initializeWeather();
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

  final GlobalKey<ScaffoldMessengerState> _scaffoldMessengerKey =
      GlobalKey<ScaffoldMessengerState>();

  @override
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: _isDarkMode ? _darkTheme : _lightTheme,
      home: ScaffoldMessenger(
        key: _scaffoldMessengerKey,
        child: Scaffold(
          backgroundColor:
              _isDarkMode ? Color.fromARGB(255, 13, 14, 17) : Colors.white,
          body: SafeArea(
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
                                  padding: const EdgeInsets.all(12.0),
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
                                      child: Methods(
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
                                                  ? Colors.grey.withOpacity(0.2)
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
                                                duration:
                                                    Duration(milliseconds: 200),
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
                                                duration:
                                                    Duration(milliseconds: 200),
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
                                      // _showSaveLocationSnackbar(context,
                                      //     searchResults[index]); // Show snackbar on tap
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
                                  final tempK =
                                      currentWeatherData['main']['temp'];
                                  final currentTemp =
                                      convertTemperature(tempK, _isCelsius)
                                          .round();
                                  final weatherDescription =
                                      currentWeatherData['weather'][0]
                                          ['description'];

                                  return Padding(
                                    padding: const EdgeInsets.all(16.0),
                                    child: SingleChildScrollView(
                                      scrollDirection: Axis.vertical,
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.center,
                                        children: [
                                          SizedBox(height: 20),
                                          Text(
                                            cityName,
                                            style: TextStyle(fontSize: 20),
                                          ),
                                          SizedBox(height: 60),
                                          BoxedIcon(
                                            Methods.getWeatherIcon(
                                                currentWeatherData['weather'][0]
                                                    ['main']),
                                            size:
                                                60, // You can adjust the size as needed
                                            color: _isDarkMode
                                                ? Colors.white
                                                : Colors.black,
                                          ),
                                          Container(
                                            padding: EdgeInsets.all(16.0),
                                            child: RichText(
                                              text: TextSpan(
                                                children: [
                                                  TextSpan(
                                                    text:
                                                        '${currentTemp}', // Numeric part
                                                    style: TextStyle(
                                                      fontSize:
                                                          50.0, // Large font size for the temperature
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      color: Colors.white,
                                                    ),
                                                  ),
                                                  WidgetSpan(
                                                    child: Transform.translate(
                                                      offset: Offset(0,
                                                          -5.0), // Adjust vertical offset to move "°C" up
                                                      child: Text(
                                                        '°C', // Temperature unit
                                                        style: TextStyle(
                                                          fontSize:
                                                              30.0, // Smaller font size for the unit
                                                          color: Colors.white70,
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                          SizedBox(height: 14),
                                          Text(
                                            weatherDescription,
                                            style: TextStyle(fontSize: 18),
                                          ),
                                          SizedBox(height: 40),
                                          Text(
                                            'Wind:',
                                            style: TextStyle(fontSize: 16),
                                          ),
                                          Text(
                                            '${currentWeatherData['wind']['speed']} m/s',
                                            style: TextStyle(fontSize: 16),
                                          ),
                                          SizedBox(height: 130),
                                          Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: List.generate(
                                              min(
                                                  7,
                                                  (list.length / 8)
                                                      .floor()), // Show the next 7 days
                                              (index) {
                                                final int calculatedIndex =
                                                    (index + 1) *
                                                        8; // Start from tomorrow
                                                if (calculatedIndex >=
                                                    list.length) {
                                                  return Container(); // Return an empty container if the index is out of bounds
                                                }

                                                final futureWeather =
                                                    list[calculatedIndex];
                                                final temp = (futureWeather[
                                                            'main']['temp'] -
                                                        273.15)
                                                    .round(); // Convert temperature from Kelvin to Celsius
                                                final date = DateTime
                                                    .fromMillisecondsSinceEpoch(
                                                        futureWeather['dt'] *
                                                            1000);

                                                return Padding(
                                                  padding: const EdgeInsets.all(
                                                      13.0),
                                                  child: Column(
                                                    children: [
                                                      BoxedIcon(
                                                        Methods.getWeatherIcon(
                                                            futureWeather[
                                                                    'weather']
                                                                [0]['main']),
                                                        size: 30,
                                                        color: _isDarkMode
                                                            ? Colors.white
                                                            : Colors.black,
                                                      ),
                                                      Text(
                                                        '$temp°',
                                                        style: TextStyle(
                                                          fontSize: 18,
                                                          fontWeight:
                                                              FontWeight.bold,
                                                        ),
                                                      ),
                                                      Text(
                                                        DateFormat('E')
                                                            .format(date),
                                                        style: TextStyle(
                                                            fontSize: 14),
                                                      ),
                                                    ],
                                                  ),
                                                );
                                              },
                                            ),
                                          )
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                        ],
                      ),
          ),
        ),
      ),
    );
  }
}
