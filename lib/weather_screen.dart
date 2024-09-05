import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:math';
import 'package:weather_app/api_key.dart';
import 'package:geolocator/geolocator.dart';
import 'package:country_picker/country_picker.dart';
import 'package:weather_icons/weather_icons.dart';
import 'handle_logout.dart';
import 'setting_-page.dart';
import 'profile_page.dart';
import 'methods.dart';

class WeatherScreen extends StatefulWidget {
  const WeatherScreen({Key? key}) : super(key: key);

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

  @override
  void initState() {
    super.initState();
    _initializeWeather();
    // _loadCountryNames();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _initializeWeather() async {
    try {
      await _getCurrentLocation();
    } catch (e) {
      print("Error initializing weather: $e");
      setState(() {
        weather = getCurrentWeather('London');
        cityName = 'London, United Kingdom';
      });
    }
  }

  Future<void> _getCurrentLocation() async {
    try {
      Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.low);
      setState(() {
        weather =
            getWeatherByCoordinates(position.latitude, position.longitude);
      });
    } catch (e) {
      print("Error getting location: $e");
      throw e;
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
      setState(() {
        String countryCode = data['city']['country'];
        String countryName = Country.tryParse(countryCode)?.name ?? countryCode;
        cityName = '${data['city']['name']}, $countryName';
      });
      return data;
    } catch (e) {
      print("Error fetching weather by coordinates: $e");
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

  void selectCity(String selectedCity) {
    setState(() {
      cityName = selectedCity; // selectedCity already includes the country
      weather = getCurrentWeather(cityName.split(',')[0]);
      searchResults = [];
      _isSearching = false;
      _searchController.clear();
    });
  }

  ThemeData get _lightTheme {
    return ThemeData.light().copyWith(
      colorScheme: ColorScheme.light(
        primary: Colors.blue,
        secondary: Colors.orange, // This replaces the accentColor
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.black, // Text color
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
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white, // Text color
      ),
      // Add more customizations as needed
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
      case 'light_mode':
      case 'dark_mode':
        setState(() {
          _isDarkMode = value == 'dark_mode';
        });
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

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: _isDarkMode ? _darkTheme : _lightTheme,
      home: Scaffold(
        appBar: AppBar(
          actions: [
            _isSearching
                ? Expanded(
                    child: TextField(
                      controller: _searchController,
                      autofocus: true,
                      style: TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        suffixIcon: IconButton(
                          icon: Icon(_isSearching ? Icons.close : Icons.search,
                              color: Colors.white),
                          onPressed: () {
                            setState(() {
                              _isSearching = !_isSearching;
                              if (!_isSearching) {
                                _searchController.clear();
                                searchResults = [];
                                _initializeWeather();
                              }
                            });
                          },
                        ),
                        hintText: 'Search for a city...',
                        hintStyle: TextStyle(color: Colors.white60),
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
                        padding: const EdgeInsets.only(top: 5.0, left: 8.0),
                        child: CustomPopupMenuButton(
                          isDarkMode: _isDarkMode,
                          onSelected: _handleMenuSelection,
                        ),
                      ),

                      // Spacer to push the theme toggle container to the right
                      SizedBox(
                        width: 292,
                      ),

                      // Theme toggle container aligned to the right
                      Padding(
                        padding: const EdgeInsets.only(top: 5.0, right: 8.0),
                        child: Container(
                          width: 30, // Adjust width as needed
                          height: 60, // Adjust height as needed
                          decoration: BoxDecoration(
                            boxShadow: [
                              BoxShadow(
                                color: _isDarkMode
                                    ? Colors.grey.withOpacity(0.2)
                                    : Colors.black.withOpacity(0.2),
                                spreadRadius: 5,
                                blurRadius: 7,
                                offset: Offset(0, 7),
                              ),
                            ],
                            color: _isDarkMode ? Colors.black : Colors.white,
                            border: Border.all(
                              color: _isDarkMode ? Colors.black : Colors.white,
                              width: 2.0,
                            ),
                            borderRadius: BorderRadius.circular(25),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              GestureDetector(
                                onTap: _isDarkMode ? _toggleTheme : null,
                                child: AnimatedOpacity(
                                  opacity: _isDarkMode ? 1.0 : 0.3,
                                  duration: Duration(milliseconds: 200),
                                  child: Icon(
                                    Icons.sunny,
                                    color: Colors.orange,
                                    size: 20,
                                  ),
                                ),
                              ),
                              GestureDetector(
                                onTap: _isDarkMode ? null : _toggleTheme,
                                child: AnimatedOpacity(
                                  opacity: _isDarkMode ? 0.3 : 1.0,
                                  duration: Duration(milliseconds: 200),
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
          ],
        ),
        body: SafeArea(
          child: Column(
            children: [
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
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return Center(child: CircularProgressIndicator());
                      }
                      if (snapshot.hasError) {
                        return Center(child: Text('Error: ${snapshot.error}'));
                      }
                      if (!snapshot.hasData) {
                        return Center(child: Text('No data available'));
                      }

                      final data = snapshot.data!;
                      final list = data['list'] as List;
                      final currentWeatherData =
                          list.isNotEmpty ? list[0] : null;

                      if (currentWeatherData == null) {
                        return Center(child: Text('No weather data available'));
                      }

                      final currentTemp =
                          (currentWeatherData['main']['temp'] - 273.15).round();
                      final weatherDescription =
                          currentWeatherData['weather'][0]['description'];

                      return Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Container(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              SizedBox(height: 20),
                              Text(
                                cityName,
                                style: TextStyle(fontSize: 20),
                              ),
                              SizedBox(height: 60),
                              BoxedIcon(
                                _getWeatherIcon(
                                    currentWeatherData['weather'][0]['main']),
                                size: 60, // You can adjust the size as needed
                                color:
                                    _isDarkMode ? Colors.white : Colors.black,
                              ),
                              Text(
                                '$currentTemp°',
                                style: TextStyle(
                                    fontSize: 72, fontWeight: FontWeight.bold),
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
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: List.generate(
                                  min(
                                      5,
                                      (list.length / 8)
                                          .floor()), // Show the next 5 days
                                  (index) {
                                    final int calculatedIndex =
                                        (index + 1) * 8; // Start from tomorrow
                                    if (calculatedIndex >= list.length) {
                                      return Container(); // Return an empty container if the index is out of bounds
                                    }

                                    final futureWeather = list[calculatedIndex];
                                    final temp =
                                        (futureWeather['main']['temp'] - 273.15)
                                            .round();
                                    final date =
                                        DateTime.fromMillisecondsSinceEpoch(
                                            futureWeather['dt'] * 1000);

                                    return Padding(
                                      padding: const EdgeInsets.all(13.0),
                                      child: Column(
                                        children: [
                                          BoxedIcon(
                                            _getWeatherIcon(
                                                futureWeather['weather'][0]
                                                    ['main']),
                                            size: 30,
                                            color: _isDarkMode
                                                ? Colors.white
                                                : Colors.black,
                                          ),
                                          Text(
                                            '$temp°',
                                            style: TextStyle(
                                                fontSize: 18,
                                                fontWeight: FontWeight.bold),
                                          ),
                                          Text(
                                            DateFormat('E').format(date),
                                            style: TextStyle(fontSize: 14),
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                ),
                              ),
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
    );
  }

  IconData _getWeatherIcon(String mainCondition) {
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
