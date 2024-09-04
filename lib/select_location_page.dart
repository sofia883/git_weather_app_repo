import 'package:flutter/material.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
// import 'package:csc_picker/csc_picker.dart';

class MySelectionPage extends StatefulWidget {
  final void Function(String) onCitySelected;
  final VoidCallback refreshCallBack;
  final VoidCallback navigateToWeatherScreen;

  const MySelectionPage({
    required this.onCitySelected,
    required this.refreshCallBack,
    required this.navigateToWeatherScreen,
    Key? key,
  }) : super(key: key);

  @override
  _MySelectionPageState createState() => _MySelectionPageState();
}

class _MySelectionPageState extends State<MySelectionPage> {
  String selectedCity = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Select City'),
      ),
      body: Column(
        children: [
          TypeAheadFormField(
            textFieldConfiguration: TextFieldConfiguration(
              decoration: InputDecoration(
                labelText: 'Search City',
                border: OutlineInputBorder(),
              ),
            ),
            suggestionsCallback: (pattern) async {
              // You can implement a search mechanism here based on 'pattern'
              // and return a list of suggestions (city names)
              return [
                'City 1, Country A',
                'City 2, Country B',
                // Add your suggestions based on the search pattern
              ];
            },
            itemBuilder: (context, suggestion) {
              return ListTile(
                title: Text(suggestion),
              );
            },
            onSuggestionSelected: (suggestion) {
              setState(() {
                selectedCity = suggestion;
                widget.onCitySelected(selectedCity);
              });
            },
          ),
          ElevatedButton(
            onPressed: () {
              widget.refreshCallBack();
              widget.navigateToWeatherScreen();
            },
            child: Text('Save'),
          ),
        ],
      ),
    );
  }
}
