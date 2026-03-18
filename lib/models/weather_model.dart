class WeatherModel {
  final double temperature;
  final double humidity;
  final double windSpeed;
  final int weatherCode;
  final String description;
  final bool isDay;

  WeatherModel({
    required this.temperature,
    required this.humidity,
    required this.windSpeed,
    required this.weatherCode,
    required this.description,
    required this.isDay,
  });

  factory WeatherModel.fromJson(Map<String, dynamic> json) {
    final current = json['current'];
    final code = current['weather_code'] as int;
    
    return WeatherModel(
      temperature: (current['temperature_2m'] as num).toDouble(),
      humidity: (current['relative_humidity_2m'] as num).toDouble(),
      windSpeed: (current['wind_speed_10m'] as num).toDouble(),
      weatherCode: code,
      description: _getWeatherDescription(code),
      isDay: current['is_day'] == 1,
    );
  }

  static String _getWeatherDescription(int code) {
    switch (code) {
      case 0: return 'Clear Sky';
      case 1: case 2: case 3: return 'Mainly Clear';
      case 45: case 48: return 'Foggy';
      case 51: case 53: case 55: return 'Drizzle';
      case 61: case 63: case 65: return 'Rainy';
      case 71: case 73: case 75: return 'Snowy';
      case 80: case 81: case 82: return 'Rain Showers';
      case 95: case 96: case 99: return 'Thunderstorm';
      default: return 'Mixed Conditions';
    }
  }
}
