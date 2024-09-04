import 'package:flutter/material.dart';

class TemperatureButtons extends StatefulWidget {
  final void Function(bool) onTemperatureUnitChanged;

  TemperatureButtons({required this.onTemperatureUnitChanged});

  @override
  _TemperatureButtonsState createState() => _TemperatureButtonsState();
}

class _TemperatureButtonsState extends State<TemperatureButtons> {
  bool isCelsius = true;

  void updateTemperature(bool isCelsiusTemp) {
    setState(() {
      isCelsius = isCelsiusTemp;
    });

    widget.onTemperatureUnitChanged(isCelsius);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        ElevatedButton(
          onPressed: () {
            updateTemperature(true); // Update to Celsius
          },
          style: ElevatedButton.styleFrom(
            iconColor: isCelsius
                ? Colors.blue
                : Colors.grey, // Active color for Celsius
          ),
          child: Text('Celsius'),
        ),
        SizedBox(height: 20),
        ElevatedButton(
          onPressed: () {
            updateTemperature(false); // Update to Fahrenheit
          },
          style: ElevatedButton.styleFrom(
            iconColor: !isCelsius
                ? Colors.blue
                : Colors.grey, // Active color for Fahrenheit
          ),
          child: Text('Fahrenheit'),
        ),
      ],
    );
  }
}
