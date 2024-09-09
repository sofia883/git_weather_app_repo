import 'package:flutter/material.dart';
import 'preferences.dart'; // Import your PreferencesPage here
import 'package:weather_icons/weather_icons.dart';
import 'package:fl_chart/fl_chart.dart';
import 'dart:math';

class WeatherUtils extends StatelessWidget {
  final bool isDarkMode;
  final Function(String) onSelected;
  final Function(String) onLocationSelected;

  const WeatherUtils({
    Key? key,
    required this.isDarkMode,
    required this.onSelected,
    required this.onLocationSelected,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      icon: Icon(
        Icons.more_vert,
        color: isDarkMode ? Colors.white : Colors.black,
      ),
      onSelected: (value) {
        if (value == 'preferences') {
          Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) =>
                    PreferencesPage(onLocationSelected: (location) {
                      Navigator.pop(context); // Close the PreferencesPage
                      onLocationSelected(
                          location); // Update weather for selected location
                    })),
          );
        } else {
          onSelected(value);
        }
      },
      itemBuilder: (context) => [
        PopupMenuItem(
          value: 'search',
          child: ListTile(
            leading: Icon(Icons.search),
            title: Text('Search'),
          ),
        ),
        PopupMenuItem(
          value: 'current_location',
          child: ListTile(
            leading: Icon(Icons.my_location),
            title: Text('Current Location'),
          ),
        ),
        PopupMenuItem(
          value: 'preferences',
          child: ListTile(
            leading: Icon(Icons.settings),
            title: Text('Preferences'),
          ),
        ),
        PopupMenuItem(
          value: 'profile',
          child: ListTile(
            leading: Icon(Icons.person),
            title: Text('Profile'),
          ),
        ),
        PopupMenuItem(
          value: 'settings',
          child: ListTile(
            leading: Icon(Icons.settings),
            title: Text('Settings'),
          ),
        ),
        PopupMenuItem(
          value: 'Mode',
          child: ListTile(
            leading: Icon(isDarkMode ? Icons.light_mode : Icons.dark_mode),
            title: Text(isDarkMode ? 'Light Mode' : 'Dark Mode'),
          ),
        ),
        PopupMenuItem(
          value: 'logout',
          child: ListTile(
            leading: Icon(Icons.logout),
            title: Text('Logout'),
          ),
        ),
      ],
    );
  }

  static IconData getWeatherIcon(String mainCondition) {
    print("Getting icon for condition: $mainCondition"); // Add this debug print
    switch (mainCondition.toLowerCase()) {
      case 'sunny':
      case 'clear':
        return WeatherIcons.day_sunny;
      case 'partly cloudy':
        return WeatherIcons.day_cloudy;
      case 'cloudy':
      case 'overcast':
        return WeatherIcons.cloudy;
      case 'rain':
      case 'light rain':
      case 'moderate rain':
      case 'heavy rain':
        return WeatherIcons.rain;
      case 'drizzle':
        return WeatherIcons.showers;
      case 'thunderstorm':
        return WeatherIcons.thunderstorm;
      case 'snow':
      case 'light snow':
      case 'moderate snow':
      case 'heavy snow':
        return WeatherIcons.snow;
      case 'mist':
      case 'fog':
      case 'haze':
        return WeatherIcons.fog;
      default:
        print(
            "Unhandled weather condition: $mainCondition"); // Add this debug print
        return WeatherIcons.day_sunny; // Default icon
    }
  }
}

// class HourlyForecastGraph extends StatelessWidget {
//   final List<double> temperatures;
//   final List<String> hours;

//   HourlyForecastGraph({required this.temperatures, required this.hours});

//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       height: 300,
//       child: LineChart(
//         LineChartData(
//           gridData: FlGridData(show: false),
//           titlesData: FlTitlesData(
//             bottomTitles: AxisTitles(
//               sideTitles: SideTitles(
//                 showTitles: true,
//                 getTitlesWidget: (value, meta) {
//                   final int index = value.toInt();
//                   if (index >= 0 && index < hours.length) {
//                     return Text(hours[index]);
//                   } else {
//                     return Text('');
//                   }
//                 },
//               ),
//             ),
//             leftTitles: AxisTitles(
//               sideTitles: SideTitles(
//                 showTitles: true,
//                 getTitlesWidget: (value, meta) {
//                   return Text('${value.toInt()}°C');
//                 },
//               ),
//             ),
//           ),
//           borderData: FlBorderData(show: false),
//           minX: 0,
//           maxX: temperatures.length.toDouble() - 1,
//           minY: temperatures.reduce((a, b) => a < b ? a : b) - 2, // Add buffer
//           maxY: temperatures.reduce((a, b) => a > b ? a : b) + 2, // Add buffer
//           lineBarsData: [
//             LineChartBarData(
//               spots: temperatures.asMap().entries.map((e) {
//                 return FlSpot(e.key.toDouble(), e.value);
//               }).toList(),
//               isCurved: true,
//               color: Colors.blue,
//               dotData: FlDotData(show: false),
//               belowBarData: BarAreaData(show: false),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }
// //import 'dart:math';




// // class QuadrantHourlyForecast extends StatefulWidget {
// //   final List<dynamic> forecasts;
// //   final double radius;

// //   QuadrantHourlyForecast({
// //     Key? key,
// //     required this.forecasts,
// //     this.radius = 150,
// //   }) : super(key: key);

// //   @override
// //   _QuadrantHourlyForecastState createState() => _QuadrantHourlyForecastState();
// // }

// // class _QuadrantHourlyForecastState extends State<QuadrantHourlyForecast> {
// //   double _rotation = 0;

// //   @override
// //   Widget build(BuildContext context) {
// //     return Positioned(
// //       top: 0,
// //       right: 0,
// //       child: SizedBox(
// //         width: widget.radius,
// //         height: widget.radius,
// //         child: GestureDetector(
// //           onPanUpdate: (details) {
// //             setState(() {
// //               _rotation += details.delta.dx * 0.01;
// //             });
// //           },
// //           child: ClipRect(
// //             child: Transform.rotate(
// //               angle: _rotation,
// //               child: CustomPaint(
// //                 size: Size(widget.radius * 2, widget.radius * 2),
// //                 painter: QuadrantForecastPainter(
// //                   forecasts: widget.forecasts,
// //                   radius: widget.radius,
// //                 ),
// //               ),
// //             ),
// //           ),
// //         ),
// //       ),
// //     );
// //   }
// // }

// // class QuadrantForecastPainter extends CustomPainter {
// //   final List<dynamic> forecasts;
// //   final double radius;

// //   QuadrantForecastPainter({
// //     required this.forecasts,
// //     required this.radius,
// //   });

// //   @override
// //   void paint(Canvas canvas, Size size) {
// //     final center = Offset(size.width / 2, size.height / 2);
// //     final itemAngle = pi / 2 / (forecasts.length - 1);

// //     for (int i = 0; i < forecasts.length; i++) {
// //       final forecast = forecasts[i];
// //       final angle = itemAngle * i - pi / 2;
// //       final offset = Offset(
// //         center.dx + radius * cos(angle),
// //         center.dy + radius * sin(angle),
// //       );

// //       // Extract data from forecast
// //       final temp = forecast['main']['temp'] - 273.15; // Convert Kelvin to Celsius
// //       final time = DateTime.fromMillisecondsSinceEpoch(forecast['dt'] * 1000);
// //       final condition = forecast['weather'][0]['main'];

// //       // Draw circle
// //       final paint = Paint()
// //         ..color = Colors.white.withOpacity(0.7)
// //         ..style = PaintingStyle.fill;
// //       canvas.drawCircle(offset, 20, paint);

// //       // Draw temperature
// //       _drawText(canvas, '${temp.round()}°', offset, 12, Colors.black);

// //       // Draw weather icon
// //       _drawIcon(canvas, _getWeatherIcon(condition), offset, 16, Colors.black);

// //       // Draw time
// //       _drawText(canvas, '${time.hour}:00', offset + Offset(0, 30), 10, Colors.black);
// //     }
// //   }

// //   void _drawText(Canvas canvas, String text, Offset offset, double fontSize, Color color) {
// //     final textPainter = TextPainter(
// //       text: TextSpan(text: text, style: TextStyle(fontSize: fontSize, color: color)),
// //       textDirection: TextDirection.ltr,
// //     );
// //     textPainter.layout();
// //     textPainter.paint(canvas, offset - Offset(textPainter.width / 2, textPainter.height / 2));
// //   }

// //   void _drawIcon(Canvas canvas, IconData iconData, Offset offset, double size, Color color) {
// //     final textPainter = TextPainter(
// //       text: TextSpan(
// //         text: String.fromCharCode(iconData.codePoint),
// //         style: TextStyle(fontSize: size, fontFamily: iconData.fontFamily, color: color),
// //       ),
// //       textDirection: TextDirection.ltr,
// //     );
// //     textPainter.layout();
// //     textPainter.paint(canvas, offset - Offset(textPainter.width / 2, textPainter.height / 2));
// //   }

// //   IconData _getWeatherIcon(String condition) {
// //     switch (condition.toLowerCase()) {
// //       case 'clear':
// //         return Icons.wb_sunny;
// //       case 'clouds':
// //         return Icons.cloud;
// //       case 'rain':
// //         return Icons.umbrella;
// //       case 'snow':
// //         return Icons.ac_unit;
// //       default:
// //         return Icons.error;
// //     }
// //   }

// //   @override
// //   bool shouldRepaint(CustomPainter oldDelegate) => true;
// // }