import 'package:flutter/material.dart';
import 'package:intl/intl.dart';


class HourlyForecast extends StatelessWidget {
  final List<dynamic> hourlyForecast; // List containing hourly forecast data

  HourlyForecast({Key? key, required this.hourlyForecast}) : super(key: key);
  double kelvinToCelsius(double kelvin) {
    return kelvin - 273.15;
  }

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      scrollDirection: Axis.horizontal,
      itemCount: hourlyForecast.length,
      itemBuilder: (context, index) {
        final hourData = hourlyForecast[index];
        final DateTime dateTime = DateTime.fromMillisecondsSinceEpoch(
          hourData['dt'] * 1000,
        );
        final String dayName = DateFormat.E().format(dateTime);
        final double temperature = hourData['temp'].toDouble();
        double celTemp = kelvinToCelsius(temperature);

        // final String weatherDescription =
        // hourData['weather'][0]['main'].toString();

        // Here, you can replace the IconData with the appropriate weather icon based on weatherDescription
        IconData weatherIcon =
            Icons.ac_unit; // Replace this with the actual weather icon

        return Card(
          elevation: 4,
          margin: EdgeInsets.all(8),
          child: Padding(
            padding: EdgeInsets.all(8),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  dayName,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Icon(weatherIcon), // Display the weather icon
                Text(
                  '${celTemp.toStringAsFixed(1)}°C',
                  style: TextStyle(fontSize: 16),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
