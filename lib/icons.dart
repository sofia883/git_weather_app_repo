class WeatherUtils {
  static String getWeatherIcon(String weatherCondition, bool isDayTime) {
    final Map<String, Map<String, String>> weatherIcons = {
      'mostly_clear': {
        'day': 'assets/images/mostly_clear_day.png',
        'night': 'assets/images/mostly_clear_night.png',
      },
      'partly_cloudy': {
        'day': 'assets/images/partly_cloudy_day.png',
        'night': 'assets/images/partly_cloudy_night.png',
      },
      // Add more weather conditions and their corresponding day/night icons
    };

    final selectedIcons = weatherIcons[weatherCondition];
    if (selectedIcons != null) {
      return isDayTime
          ? selectedIcons['day'] ?? ''
          : selectedIcons['night'] ?? '';
    }

    // Return a default image if no matching weather condition is found
    return 'assets/images/sunny.png';
  }
}
