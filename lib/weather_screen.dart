import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:math';
import 'package:weather_app/api_key.dart';
import 'package:geolocator/geolocator.dart';

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

  @override
  void initState() {
    super.initState();
    _initializeWeather();
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
        cityName = 'London';
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
      return jsonDecode(res.body);
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
        cityName = data['city']['name'];
      });
      return data;
    } catch (e) {
      print("Error fetching weather by coordinates: $e");
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
          searchResults = cities
              .map((city) => "${city['name']}, ${city['country']}")
              .toList();
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
      cityName = selectedCity.split(',')[0];
      weather = getCurrentWeather(cityName);
      searchResults = [];
      _isSearching = false;
      _searchController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: _isSearching
            ? TextField(
                controller: _searchController,
                autofocus: true,
                style: TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Search for a city...',
                  hintStyle: TextStyle(color: Colors.white60),
                  border: InputBorder.none,
                ),
                onChanged: (value) {
                  searchLocation(value);
                },
              )
            : Text(cityName, style: TextStyle(color: Colors.white)),
        actions: [
          IconButton(
            icon: Icon(_isSearching ? Icons.close : Icons.search,
                color: Colors.white),
            onPressed: () {
              setState(() {
                _isSearching = !_isSearching;
                if (!_isSearching) {
                  _searchController.clear();
                  searchResults = [];
                }
              });
            },
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
                      title: Text(searchResults[index],
                          style: TextStyle(color: Colors.white)),
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
                      return Center(
                          child:
                              CircularProgressIndicator(color: Colors.white));
                    }
                    if (snapshot.hasError) {
                      return Center(
                          child: Text('Error: ${snapshot.error}',
                              style: TextStyle(color: Colors.white)));
                    }
                    if (!snapshot.hasData) {
                      return Center(
                          child: Text('No data available',
                              style: TextStyle(color: Colors.white)));
                    }

                    final data = snapshot.data!;
                    final list = data['list'] as List;
                    final currentWeatherData = list.isNotEmpty ? list[0] : null;

                    if (currentWeatherData == null) {
                      return Center(
                          child: Text('No weather data available',
                              style: TextStyle(color: Colors.white)));
                    }

                    final currentTemp =
                        (currentWeatherData['main']['temp'] - 273.15).round();
                    final weatherDescription =
                        currentWeatherData['weather'][0]['description'];

                    return Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(height: 32),
                          Center(
                            child: Text(
                              '$currentTemp°',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 72,
                                  fontWeight: FontWeight.bold),
                            ),
                          ),
                          Center(
                            child: Text(
                              weatherDescription,
                              style: TextStyle(
                                  color: Colors.white70, fontSize: 18),
                            ),
                          ),
                          SizedBox(height: 32),
                          Text(
                            'Next 7 Days',
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.bold),
                          ),
                          SizedBox(height: 8),
                          SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              children: List.generate(min(7, list.length ~/ 8),
                                  (index) {
                                final futureWeather = list[index * 8];
                                final temp =
                                    (futureWeather['main']['temp'] - 273.15)
                                        .round();
                                return Padding(
                                  padding: const EdgeInsets.only(right: 16.0),
                                  child: Column(
                                    children: [
                                      Text('$temp°',
                                          style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 18)),
                                      Icon(Icons.cloud, color: Colors.white),
                                      Text(
                                        DateFormat('E').format(DateTime.now()
                                            .add(Duration(days: index + 1))),
                                        style: TextStyle(color: Colors.white70),
                                      ),
                                    ],
                                  ),
                                );
                              }),
                            ),
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
  }
}
