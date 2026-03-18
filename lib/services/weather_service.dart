import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/weather_model.dart';

class WeatherService {
  // Cadiz City Coordinates (Default)
  static const double defaultLat = 10.9575;
  static const double defaultLon = 123.3086;

  static const String baseUrl = 'https://api.open-meteo.com/v1/forecast';

  Future<WeatherModel> getWeatherData({double? latitude, double? longitude}) async {
    final lat = latitude ?? defaultLat;
    final lon = longitude ?? defaultLon;

    final url = Uri.parse(
      '$baseUrl?latitude=$lat&longitude=$lon&current=temperature_2m,relative_humidity_2m,is_day,weather_code,wind_speed_10m&timezone=Asia%2FManila'
    );

    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return WeatherModel.fromJson(data);
      } else {
        throw Exception('Failed to load weather data');
      }
    } catch (e) {
      print('Weather Service Error: $e');
      rethrow;
    }
  }
}
