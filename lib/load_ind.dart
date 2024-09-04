// import 'dart:convert';
// // import 'dart:ui';
// import 'package:flutter/foundation.dart';
// import 'package:flutter/material.dart';
// import 'package:intl/intl.dart';
// import 'package:http/http.dart' as http;
// import 'package:weather_app/additional_info_item.dart';
// // import 'package:weather_app/hourly_forecast_item.dart';
// import 'package:weather_app/api_key.dart';
// import 'select_location_page.dart';
// import 'side_menu.dart';
// // import 'csc.dart';

// class LoadInd extends StatefulWidget {
//   const LoadInd({super.key});

//   @override
//   State<LoadInd> createState() => _WeatherScrState();
// }

// class _WeatherScrState extends State<LoadInd> {
//   late Future<Map<String, dynamic>> weather;
//   double kelvinToCelsius(double kelvin) {
//     return kelvin - 273.15;
//   }

//   void navigateToWeatherScreen() {
//     Navigator.of(context).pop();
//   }

//   String cityName = 'Faridabad';
//   void updateCityName(String location) {
//     setState(() {
//       if (kDebugMode) {
//         print(cityName);
//       }
//       cityName = location;

//       if (kDebugMode) {
//         print(cityName);
//       }
//     });
//   }

//   Future<void> refreshWeather() async {
//     setState(() {
//       weather = getCurrentWeather();
//     });
//   }

//   Future<Map<String, dynamic>> getCurrentWeather() async {
//     try {
//       final res = await http.get(
//         Uri.parse(
//           'https://api.openweathermap.org/data/2.5/forecast?q=$cityName&APPID=$openWeatherAPIKey',
//         ),
//       );

//       final data = jsonDecode(res.body);
//       if (kDebugMode) {
//         print(data['cod']);
//       }
//       if (data['cod'] != '200') {
//         // return data;

//         throw 'An unexpected error occurred';
//       }

//       return data;
//     } catch (exception) {
//       throw ('e');
//     }
//   }

//   @override
//   void initState() {
//     super.initState();
//     weather = getCurrentWeather();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Center(
//         child: SingleChildScrollView(
//             child: FutureBuilder(
//                 future: weather,
//                 builder: (context, snapshot) {
//                   if (snapshot.connectionState == ConnectionState.waiting) {
//                     return const CircularProgressIndicator();
//                   }

//                   if (snapshot.hasError) {
//                     return Text(snapshot.error.toString());
//                   }

//                   final data = snapshot.data!;
//                   if (kDebugMode) {
//                     print(data);
//                   }

//                   final currentWeatherData = data['list'][0];
//                   final currentTemp = currentWeatherData['main']['temp'];
//                   double celsiusTemperature = kelvinToCelsius(currentTemp);
//                   final currentPressure =
//                       currentWeatherData['main']['pressure'];
//                   final currentWindSpeed = currentWeatherData['wind']['speed'];
//                   final currentHumidity =
//                       currentWeatherData['main']['humidity'];
//                   // final currentSky = currentWeatherData['weather'][0]['main'];

//                   final currentTime =
//                       DateFormat.jm().format(DateTime.now()); // Format the time
//                   final currentDay = DateFormat('EEEE')
//                       .format(DateTime.now());
//                        // Format the day
//                 })));
//   }
// }
