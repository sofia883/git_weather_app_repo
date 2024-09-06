import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:weather_app/weather_screen.dart';

void main() {
  group('WeatherScreen', () {
    testWidgets('WeatherScreen initializes correctly',
        (WidgetTester tester) async {
      await tester.pumpWidget(MaterialApp(home: WeatherScreen()));

      // Verify that WeatherScreen widget is present
      expect(find.byType(WeatherScreen), findsOneWidget);

      // Verify that initial loading state is shown
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('Search bar appears when search icon is tapped',
        (WidgetTester tester) async {
      await tester.pumpWidget(MaterialApp(home: WeatherScreen()));

      // Initially, search bar should not be visible
      expect(find.byType(TextField), findsNothing);

      // Find and tap the search icon
      final searchIcon = find.byIcon(Icons.search);
      expect(searchIcon, findsOneWidget);
      await tester.tap(searchIcon);
      await tester.pump();

      // After tapping, search bar should be visible
      expect(find.byType(TextField), findsOneWidget);
    });

    testWidgets('Theme toggle changes theme', (WidgetTester tester) async {
      await tester.pumpWidget(MaterialApp(home: WeatherScreen()));

      // Find the theme toggle button
      final themeToggle = find.byType(GestureDetector).first;

      // Get the initial theme
      final initialTheme =
          Theme.of(tester.element(find.byType(WeatherScreen))).brightness;

      // Tap the theme toggle
      await tester.tap(themeToggle);
      await tester.pumpAndSettle();

      // Get the new theme
      final newTheme =
          Theme.of(tester.element(find.byType(WeatherScreen))).brightness;

      // Verify that the theme has changed
      expect(newTheme, isNot(equals(initialTheme)));
    });

    // Add more widget tests as needed
  });

  group('WeatherScreenState', () {
    test('getCurrentWeather fetches data correctly', () async {
      final state = WeatherScreenState();

      // Mock the http call
      // Note: You'll need to add the http_mock package to your pubspec.yaml
      // and import it at the top of this file
      // import 'package:http/testing.dart';
      // import 'package:http/http.dart' as http;

      // final mockClient = MockClient((request) async {
      //   return http.Response('{"location": {"name": "London", "country": "UK"}, "current": {}}', 200);
      // });

      // Replace the http client in your WeatherScreenState with the mock client
      // state.client = mockClient;

      final result = await state.getCurrentWeather('London');

      expect(result, isA<Map<String, dynamic>>());
      expect(result['location']['name'], equals('London'));
    });

    // Add more unit tests for other methods in WeatherScreenState
  });
}
