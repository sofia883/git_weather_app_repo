import 'package:flutter/material.dart';

import 'package:shared_preferences/shared_preferences.dart';


class SettingsPage extends StatefulWidget {
  final void Function(bool) onTemperatureUnitChanged;

  const SettingsPage({
    Key? key,
    required this.onTemperatureUnitChanged,
  }) : super(key: key);

  @override
  SettingsPageState createState() => SettingsPageState();
}

class SettingsPageState extends State<SettingsPage> {
  late bool _isCelsius;

  @override
  void initState() {
    super.initState();
    _loadTemperatureUnit();
  }

  Future<void> _loadTemperatureUnit() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      _isCelsius = prefs.getBool('isCelsius') ?? true;
    });
  }

  Future<void> _saveTemperatureUnit(bool value) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isCelsius', value);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Settings'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              'Temperature Unit',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _isCelsius = true;
                      _saveTemperatureUnit(_isCelsius);
                      widget.onTemperatureUnitChanged(_isCelsius);
                    });
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _isCelsius ? Colors.orange : Colors.white,
                  ),
                  child: Text('Celsius',style: TextStyle(color: Colors.black),),
                ),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _isCelsius = false;
                      _saveTemperatureUnit(_isCelsius);
                      widget.onTemperatureUnitChanged(_isCelsius);
                    });
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: !_isCelsius ? Colors.orange : Colors.white,
                  ),
                  child: Text('Fahrenheit',style: TextStyle(color: Colors.black),),
                ),
              ],
            ),
            // Other settings options...
          ],
        ),
      ),
    );
  }
}
