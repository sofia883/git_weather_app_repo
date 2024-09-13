import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:math';
import 'dart:io'; // For SocketException
import 'dart:async'; // For TimeoutException
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
import 'notification_service.dart';
import 'package:app_settings/app_settings.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

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
  String _currentDescription = '';
  bool _hasNetworkError = false;
  bool _isLocationPermissionDenied = false;
  bool _isLocationServiceEnabled = false;

  bool _isCurrentLocationFetched = false;
  double? lastKnownLatitude;
  double? lastKnownLongitude;
  StreamSubscription<ServiceStatus>? _locationServiceStatusSubscription;

  @override
  void initState() {
    super.initState();

    _initializeApp();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _locationServiceStatusSubscription?.cancel();
    super.dispose();
  }

  Future<void> _initializeApp() async {
    setState(() {
      isLoading = true;
      errorMessage = '';
      _hasNetworkError = false;
    });

    try {
      await _checkConnectivity();
      await _checkLocationService();
      await _handleLocationPermission();
      await _loadSavedPreferences();
    } catch (e) {
      _handleError(e);
    } finally {
      // _loadSavedPreferences();
      setState(() {
        isLoading = false;
      });
    }
  }

  void _listenForLocationServiceChanges() {
    _locationServiceStatusSubscription =
        Geolocator.getServiceStatusStream().listen((ServiceStatus status) {
      if (status == ServiceStatus.disabled) {
        _handleLocationServiceDisabled();
      } else if (status == ServiceStatus.enabled) {
        _handleLocationServiceEnabled();
      }
    });
  }

  void _showLocationServiceDisabledDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Location Services Disabled'),
          content: Text('Please enable location services to use this feature.'),
          actions: <Widget>[
            TextButton(
              child: Text('Open Settings'),
              onPressed: () async {
                Navigator.of(context).pop();
                await Geolocator.openLocationSettings();
                // Check if location service is enabled after returning from settings
                bool serviceEnabled =
                    await Geolocator.isLocationServiceEnabled();
                if (serviceEnabled) {
                  _handleCurrentLocationRequest();
                }
              },
            ),
            TextButton(
              child: Text('Search Manually'),
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

  void _handleLocationServiceDisabled() {
    setState(() {
      _isLocationServiceEnabled = false;
    });
    if (isCurrentLocation) {
      _showLocationServiceDisabledDialog();
    }
  }

  void _handleLocationServiceEnabled() {
    setState(() {
      _isLocationServiceEnabled = true;
    });
    if (isCurrentLocation) {
      _handleCurrentLocationRequest();
    }
  }

  Future<void> _handleCurrentLocationRequest() async {
    setState(() {
      isLoading = true;
    });

    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      setState(() {
        isLoading = false;
      });
      _showLocationServiceDialog();
      return;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        setState(() {
          isLoading = false;
        });
        _showLocationPermissionDialog(true);
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      setState(() {
        isLoading = false;
      });
      _showLocationPermissionDialog(false);
      return;
    }

    // If we have permission, get the current location
    await _getCurrentLocation();
    setState(() {
      isLoading = false;
    });
  }

  void _showLocationServiceDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Location Services Disabled'),
          content: Text('Please enable location services to use this feature.'),
          actions: <Widget>[
            TextButton(
              child: Text('Open Settings'),
              onPressed: () async {
                Navigator.of(context).pop();
                await Geolocator.openLocationSettings();
                // Check if location service is enabled after returning from settings
                bool serviceEnabled =
                    await Geolocator.isLocationServiceEnabled();
                if (serviceEnabled) {
                  _handleCurrentLocationRequest();
                }
              },
            ),
            TextButton(
              child: Text('Search Manually'),
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

  void _showLocationPermissionDialog(bool canAskAgain) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Location Permission Required'),
          content:
              Text('Please allow location access to get current weather data.'),
          actions: <Widget>[
            if (canAskAgain)
              TextButton(
                child: Text('Allow'),
                onPressed: () {
                  Navigator.of(context).pop();
                  _handleCurrentLocationRequest();
                },
              ),
            TextButton(
              child: Text(canAskAgain ? 'Deny' : 'Open Settings'),
              onPressed: () async {
                Navigator.of(context).pop();
                if (!canAskAgain) {
                  await Geolocator.openAppSettings();
                  // Check permission after returning from settings
                  LocationPermission permission =
                      await Geolocator.checkPermission();
                  if (permission == LocationPermission.always ||
                      permission == LocationPermission.whileInUse) {
                    _handleCurrentLocationRequest();
                  }
                }
              },
            ),
            TextButton(
              child: Text('Search Manually'),
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

  Future<void> _getCurrentLocation() async {
    try {
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      lastKnownLatitude = position.latitude;
      lastKnownLongitude = position.longitude;
      await _fetchWeatherForCurrentLocation(
          position.latitude, position.longitude);
      setState(() {
        isCurrentLocation = true;
      });
    } catch (e) {
      throw Exception('Error getting location: $e');
    }
  }

 
  Future<void> _checkConnectivity() async {
    var connectivityResult = await (Connectivity().checkConnectivity());
    if (connectivityResult == ConnectivityResult.none) {
      throw SocketException('No internet connection');
    }
  }

  Future<void> _handleLocationPermission() async {
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        _showLocationPermissionDialog(true);
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      _showLocationPermissionDialog(false);
      return;
    }

    // If we have permission, try to get the current location
    await _getCurrentLocation();
  }


  void _handleError(dynamic error) {
    setState(() {
      isLoading = false;
      if (error is SocketException || error is TimeoutException) {
        _hasNetworkError = true;
        errorMessage =
            'No internet connection. Please check your network settings.';
      } else if (error.toString().contains('Location')) {
        _isLocationPermissionDenied = true;
        errorMessage = error.toString();
      } else {
        errorMessage = 'An unexpected error occurred. Please try again.';
      }
    });
    _showNetworkErrorDialog();
  }

  Future<void> _checkLocationService() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    setState(() {
      _isLocationServiceEnabled = serviceEnabled;
    });
  }

  Future<void> _initializeWeather() async {
    setState(() {
      isLoading = true;
      errorMessage = '';
      _hasNetworkError = false;
    });

    try {

      await _checkConnectivity();
      if (widget.location != null && widget.location!.isNotEmpty) {
        await _initializeWeatherForLocation(widget.location!);
      } else if (_savedPreferences.isNotEmpty) {
        await _initializeWeatherForLocation(_savedPreferences.first);
      } else {
        // If no saved location, attempt to get current location
        await _handleCurrentLocationRequest();
      }
    } catch (e) {
      _handleError(e);
    } finally {
      setState(() {
        isLoading = false;
      });
    }
   
  }

  Future<void> _refreshCurrentLocationWeather() async {
    try {
      setState(() {
        isLoading = true;
      });
      // Assuming you have a method to fetch weather for the last known location
      await _fetchWeatherForCurrentLocation(
          lastKnownLatitude!, lastKnownLongitude!);
    } catch (e) {
      _handleError(e);
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

 
  Widget _buildNetworkErrorWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            errorMessage,
            style: TextStyle(fontSize: 18, color: Colors.red),
          ),
          SizedBox(height: 20),
          ElevatedButton(
            onPressed: _showNetworkErrorDialog,
            child: Text('Check Network Connection'),
          ),
        ],
      ),
    );
  }

  Widget _buildLocationPermissionDeniedWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            errorMessage,
            style: TextStyle(fontSize: 18, color: Colors.red),
          ),
          SizedBox(height: 20),
          ElevatedButton(
            onPressed: () async {
              await Geolocator.openAppSettings();
              _initializeWeather();
            },
            child: Text('Open Location Settings'),
          ),
          ElevatedButton(
            onPressed: () async {
              _showSearchBar();
            },
            child: Text('Search Manually'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: Text('Cancel'),
          ),
        ],
      ),
    );
  }

  Future<void> _loadSavedPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _savedPreferences = prefs.getStringList('savedPreferences') ?? [];
    });
    // NotificationService.checkAndNotify(_currentDes);
  }

  void _handleOtherErrors(dynamic e) {
    // Handle other types of errors (e.g., location, data parsing, etc.)
    setState(() {
      errorMessage = 'Something went wrong. Please try again.';
    });
  }

  void _showSearchBarOption() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Location Permission Denied'),
          content: Text('Would you like to search for the location manually?'),
          actions: <Widget>[
            TextButton(
              child: Text('Yes'),
              onPressed: () {
                Navigator.of(context).pop();
                _showSearchBar();
              },
            ),
            TextButton(
              child: Text('Allow location'),
              onPressed: () async {
                Navigator.of(context).pop();
                await Geolocator.openAppSettings();
              },
            ),
            TextButton(
              child: Text('No'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _fetchWeatherForCurrentLocation(double lat, double lon) async {
    try {
      final weatherData = await _fetchWeatherData('lat=$lat&lon=$lon');
      setState(() {
        weather = Future.value(weatherData);
        cityName =
            weatherData['city']['name'] + ', ' + weatherData['city']['country'];
      });
    } catch (e) {
      _handleNetworkError(e);
    }
  }

  Future<void> _initializeWeatherForLocation(String location) async {
    setState(() {
      cityName = location;
      isCurrentLocation = false;
    });
    await _fetchWeatherData(location);
  }

  // Future<void> _initializeWeatherForLocation(String location) async {
  //   try {
  //     var weatherData = await _fetchWeatherData('q=$location');
  //     setState(() {
  //       cityName = location;
  //       weather = Future.value(weatherData);
  //     });
  //   } catch (e) {
  //     _handleNetworkError(e);
  //   }
  // }

  Future<Map<String, dynamic>> _fetchWeatherData(String query) async {
    var connectivityResult = await (Connectivity().checkConnectivity());
    if (connectivityResult == ConnectivityResult.none) {
      throw TimeoutException('No internet connection');
    }

    try {
      final response = await http
          .get(
            Uri.parse(
              'https://api.openweathermap.org/data/2.5/forecast?$query&APPID=$openWeatherAPIKey',
            ),
          )
          .timeout(Duration(seconds: 5));

      if (response.statusCode != 200) {
        throw Exception('Failed to load weather data: ${response.statusCode}');
      }
      return jsonDecode(response.body);
    } on TimeoutException catch (_) {
      throw TimeoutException('Failed to load weather data: Connection timeout');
    } on SocketException catch (_) {
      throw SocketException(
          'Failed to load weather data: No internet connection');
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
      var connectivityResult = await (Connectivity().checkConnectivity());
      if (connectivityResult == ConnectivityResult.none) {
        throw TimeoutException('No internet connection');
      }

      final response = await http
          .get(
            Uri.parse(
              'https://api.openweathermap.org/geo/1.0/direct?q=$query&limit=5&appid=$openWeatherAPIKey',
            ),
          )
          .timeout(Duration(seconds: 10));

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
      _handleNetworkError(e);
    }
  }

  void _handleNetworkError(dynamic error) {
    setState(() {
      _hasNetworkError = true;
      _isSearching = false; // Ensure search bar is hidden
      if (error is TimeoutException) {
        errorMessage =
            'Connection timed out. Please check your internet connection.';
      } else if (error is SocketException) {
        errorMessage =
            'No internet connection. Please check your network settings.';
      } else {
        errorMessage = 'An error occurred. Please try again later.';
      }
    });
    _showNetworkErrorDialog();
  }

  void _showNetworkErrorDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Network Error'),
          content: Text(
              'To access current data, please check your internet connection.'),
          actions: <Widget>[
            TextButton(
              child: Text('Open Network Settings'),
              onPressed: () {
                Navigator.of(context).pop();
                AppSettings.openAppSettings(type: AppSettingsType.wifi);
              },
            ),
            TextButton(
              child: Text('Try Again'),
              onPressed: () {
                Navigator.of(context).pop();
                _initializeWeather();
              },
            ),
            TextButton(
              child: Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _loadIsCurrentLocation() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      isCurrentLocation = prefs.getBool('isCurrentLocation') ?? false;
    });
  }

  Future<void> _saveIsCurrentLocation(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isCurrentLocation', value);
  }

  void _showSearchBar() {
    setState(() {
      _isSearching = true;
    });
  }

// Update the _handleCurrentLocationRequest method

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
      print("Fetched weather data: $data");
      return data;
    } catch (e) {
      print("Error fetching weather by coordinates: $e");
      throw Exception('Failed to load weather data');
    }
  }

  // ... rest of the existing code ...

  Future<String> getWeatherConditionForCurrentLocation(
      double lat, double lon) async {
    try {
      // Fetch weather data based on coordinates
      final weatherData = await getWeatherByCoordinates(lat, lon);

      // Extract the weather condition description
      String weatherDescription =
          weatherData['list'][0]['weather'][0]['description'];
      print(weatherDescription);

      // Optionally, you can also fetch other details like temperature, humidity, etc.
      // Example:
      // double temperature = weatherData['list'][0]['main']['temp'];

      // Combine the description or return it
      return weatherDescription;
    } catch (e) {
      print("Error fetching weather for current location: $e");
      return 'Failed to fetch weather condition';
    }
  }

  Future<void> _checkLocationPermission() async {
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
        return _loadSavedPreferences().then((_) {
          _initializeWeather();
        });
      }
    }

    if (permission == LocationPermission.deniedForever) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Location permissions are permanently denied')),
      );
      return _loadSavedPreferences().then((_) {
        _initializeWeather();
      });
    }
    // NotificationService.checkAndNotify(_currentDes);
  }

  void _handleTemperatureUnitChanged(bool isCelsius) async {
    setState(() {
      _isCelsius = isCelsius;
    });

    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isCelsius', isCelsius);

    // Reload weather for the current location
  }

  void selectCity(String selectedCity) async {
    setState(() {
      cityName = selectedCity;
      weather = getCurrentWeather(selectedCity.split(',')[0]);
      searchResults = [];
      _isSearching = false;
      _searchController.clear();
      isCurrentLocation = false;
    });
    await _saveIsCurrentLocation(false);
    _showSaveLocationSnackbar(selectedCity);
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
        // _initializeWeather();
        // _loadSavedPreferences().then((_) {
        //   _initializeWeather();
        // });

        // _handleLocationPermission();
        _handleCurrentLocationRequest();

        // _initializeWeather();

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

  void _checkDescriptionChange(Map<String, dynamic> weatherData) {
    final newDescription = weatherData['list'][0]['weather'][0]['description'];
    // final newDescription = 'Tornado';

    if (newDescription != _currentDescription && isCurrentLocation) {
      NotificationService.checkAndNotify(
        newDescription,
      );
    }
  }

  Widget _buildCurrentWeather(Map<String, dynamic> currentWeatherData) {
    final tempK = currentWeatherData['main']['temp']?.toDouble() ?? 0.0;
    final currentTemp = convertTemperature(tempK, _isCelsius).round();
    _currentDescription =
        currentWeatherData['weather'][0]['description'] ?? 'Unknown';

    print('Current weather description: $_currentDescription');
    print('Is current location: $isCurrentLocation');
    print('Saved preferences: $_savedPreferences');

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
                      style: GoogleFonts.acme(
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
          _currentDescription,
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
    final now = DateTime.now();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 6.0),
          child: Container(
            height: 120,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: min(24, list.length), // Increased to show 24 hours
              itemBuilder: (context, index) {
                final hourlyWeather = list[index];
                final temp = convertTemperature(
                    hourlyWeather['main']['temp'], _isCelsius);
                final forecastTime = DateTime.fromMillisecondsSinceEpoch(
                    hourlyWeather['dt'] * 1000);
                final weatherIcon = WeatherUtils.getWeatherIcon(
                    hourlyWeather['weather'][0]['main']);

                // Check if current time is within this hour
                final isCurrentHour = now.isAfter(forecastTime) &&
                    now.isBefore(forecastTime.add(Duration(hours: 3)));

                // Determine text color based on whether it's the current hour
                final textColor = isCurrentHour
                    ? Colors.red
                    : (_isDarkMode ? Colors.white : Colors.black);

                // Use device's locale to determine 12/24 hour format
                final is24HourFormat =
                    MediaQuery.of(context).alwaysUse24HourFormat;
                final timeFormat = is24HourFormat ? 'HH:mm' : 'h:mm a';

                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12.0),
                  child: Column(
                    children: [
                      Text(
                        DateFormat(timeFormat).format(forecastTime),
                        style: TextStyle(fontSize: 14, color: textColor),
                      ),
                      SizedBox(height: 8),
                      BoxedIcon(
                        weatherIcon,
                        size: 30,
                        color: textColor,
                      ),
                      SizedBox(height: 8),
                      Text(
                        '${temp.round()}°',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: textColor,
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

  Widget _buildDailyForecast(List forecastList, bool highlightToday) {
    final now = DateTime.now();

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(
          min(7, (forecastList.length / 8).floor()),
          (index) {
            final int calculatedIndex = index * 8;
            if (calculatedIndex >= forecastList.length) {
              return Container();
            }

            final futureWeather = forecastList[calculatedIndex];
            // Convert the temperature to double before passing it to convertTemperature
            final temp = convertTemperature(
                    (futureWeather['main']['temp'] as num).toDouble(),
                    _isCelsius)
                .round();
            final date =
                DateTime.fromMillisecondsSinceEpoch(futureWeather['dt'] * 1000);

            // Check if this forecast is for today
            final isToday = date.year == now.year &&
                date.month == now.month &&
                date.day == now.day;

            return Padding(
              padding: const EdgeInsets.all(22.0),
              child: Column(
                children: [
                  BoxedIcon(
                    WeatherUtils.getWeatherIcon(
                        futureWeather['weather'][0]['main']),
                    size: 30,
                    color: isToday && highlightToday
                        ? Colors.red
                        : AppColors.getTextColor(_isDarkMode),
                  ),
                  Text(
                    '$temp°',
                    style: GoogleFonts.berkshireSwash(
                      textStyle: TextStyle(
                        fontSize: 20,
                        color: isToday && highlightToday
                            ? Colors.red
                            : AppColors.getTextColor(_isDarkMode),
                      ),
                    ),
                  ),
                  Text(
                    isToday ? 'Today' : DateFormat('E').format(date),
                    style: TextStyle(
                      fontSize: 14,
                      color: isToday && highlightToday
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

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: _isDarkMode ? _darkTheme : _lightTheme,
      home: ScaffoldMessenger(
        key: _scaffoldMessengerKey,
        child: Scaffold(
          backgroundColor: AppColors.getbgColor(_isDarkMode),
          body: SafeArea(
            child: isLoading
                ? Center(child: CircularProgressIndicator())
                : _hasNetworkError
                    ? _buildNetworkErrorWidget()
                    : _isLocationPermissionDenied
                        ? _buildLocationPermissionDeniedWidget()
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
                                            height:
                                                60, // Adjust height as needed
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
                                                      color:
                                                          const Color.fromARGB(
                                                              255,
                                                              105,
                                                              106,
                                                              107),
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
                                // Your existing weather display widget
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

                                    final weatherDescription =
                                        currentWeatherData['weather'][0]
                                            ['description'];

                                    if (currentWeatherData == null) {
                                      return Center(
                                          child: Text(
                                              'No weather data available'));
                                    }
                                    _checkDescriptionChange(data);
                                    // Cast numeric values correctly
// final forecastList = snapshot.data?['hourly'] as List<dynamic>?;
                                    final forecastList =
                                        data['list'] as List<dynamic>? ?? [];
                                    return Padding(
                                      padding: const EdgeInsets.all(8.0),
                                      child: SingleChildScrollView(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.center,
                                          children: [
                                            ElevatedButton(
                                              onPressed: () async {
                                                NotificationService
                                                    .checkAndNotify(
                                                  weatherDescription,
                                                );
                                                await NotificationService
                                                    .showNotification(
                                                  id: 0, // Use a simple static ID for testing
                                                  title: 'Test Notification',
                                                  body:
                                                      'This is a test notification.',
                                                );
                                              },
                                              child: Text(
                                                  'Send Test Notification'),
                                            ),

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
                                                            forecastList,
                                                            true), // Today forecast
                                                        _buildHourlyForecast(
                                                            forecastList), // Hourly forecast
                                                        _buildDailyForecast(
                                                            forecastList,
                                                            false), // Next 4 days forecast
                                                      ],
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    );
                                  },
                                )),
                              // if (!_isLocationServiceEnabled &&
                              //     isCurrentLocation)
                              //   Padding(
                              //     padding: const EdgeInsets.all(8.0),
                              //     child: Text(
                              //       'Location services are disabled. Tap here to enable.',
                              //       style: TextStyle(color: Colors.red),
                              //     ),
                              //   ),
                            ],
                          ),
          ),
        ),
      ),
    );
  }

  final GlobalKey<ScaffoldMessengerState> _scaffoldMessengerKey =
      GlobalKey<ScaffoldMessengerState>();
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
