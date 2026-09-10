import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/weather_model.dart';

class WeatherService {
  static const String baseUrl = 'https://api.open-meteo.com/v1/forecast';

  Future<WeatherModel> getWeatherData({required double latitude, required double longitude}) async {
    final url = Uri.parse(
      '$baseUrl?latitude=$latitude&longitude=$longitude&current=temperature_2m,relative_humidity_2m,is_day,weather_code,wind_speed_10m&timezone=Asia%2FManila'
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
