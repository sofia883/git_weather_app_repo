import 'package:flutter/material.dart';

import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
// class ForecastPage extends StatelessWidget {
class ForecastPage extends StatefulWidget {
  final Future<Map<String, dynamic>> weatherData;


  const ForecastPage({Key? key, required this.weatherData}) : super(key: key);

  @override
  State<ForecastPage> createState() => _ForecastPageState();
}

class _ForecastPageState extends State<ForecastPage> {

    late bool _isCelsius;
   double changedTemp(double temperature) {
    return _isCelsius
        ? kelvinToCelsius(temperature)
        : kelvinToFahrenheit(temperature);
  }

  double kelvinToCelsius(double kelvin) {
    return kelvin - 273.15.toDouble();
  }

  double kelvinToFahrenheit(double kelvin) {
    return (kelvin - 273.15) * 9 / 5 + 32.toDouble();
  }


 Future<void> _loadTemperatureUnit() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      _isCelsius = prefs.getBool('isCelsius') ?? true;
    });
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.orange,
        title: const Text('Next 5 Days Forecast'),
      ),
      body: FutureBuilder(
        future: widget.weatherData,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          // Access the weather data from snapshot.data
          final data = snapshot.data as Map<String, dynamic>;

          // Extract the forecast list for the next 7 days
          final List<dynamic> forecastList = data['list'];

          return ListView.builder(
            itemCount: 7, // Display forecast for next 7 days
            itemBuilder: (context, index) {
              final int forecastIndex = index;
              if (forecastIndex <= forecastList.length) {
                final forecastData = forecastList[forecastIndex];
                final DateTime date =
                    DateTime.now().add(Duration(days: index + 1));
                final double temperature =
                    forecastData['main']['temp'].toDouble();
                final celsiusTemperature = (temperature);
                final String weatherDescription =
                    forecastData['weather'][0]['main'];

                return Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Card(
                    elevation: 30,
                    color: Colors.transparent,
                    child: ListTile(
                      title: Text(
                        DateFormat('EEEE')
                            .format(date), // Display day of the week
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: RichText(
                        text: TextSpan(
                          children: [
                            TextSpan(
                              text: '$weatherDescription, ',
                              style: TextStyle(
                                color: Colors
                                    .black, // Color for weather description
                              ),
                            ),
                            TextSpan(
                              text:
                                  '${celsiusTemperature.toStringAsFixed(1)}°C',
                              style: TextStyle(
                                color: Colors.orange, // Color for temperature
                                fontWeight: FontWeight
                                    .bold, // Optional: Set text weight to bold
                              ),
                            ),
                          ],
                        ),
                      ),
                      // You can add more details or customize the display here
                    ),
                  ),
                );
              } else {
                // If forecast data for this day is not available, you can handle it
                return ListTile(
                  title: Text(
                    'No Data Available',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  // You can provide some message or handle this scenario as needed
                );
              }
            },
          );
        },
      ),
    );
  }
}
