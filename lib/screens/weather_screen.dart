import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../services/weather_service.dart';
import '../models/weather_model.dart';
import '../services/location_service.dart';
import '../core/constants.dart';

class WeatherScreen extends StatelessWidget {
  const WeatherScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final weatherService = Provider.of<WeatherService>(context, listen: false);
    final locationService = Provider.of<LocationService>(context, listen: false);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('WEATHER MONITORING', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: FutureBuilder(
        future: locationService.getCurrentLocation().then((position) {
          return weatherService.getWeatherData(
            latitude: position?.latitude,
            longitude: position?.longitude,
          ).then((weather) => {'weather': weather, 'hasLoc': position != null});
        }),
        builder: (context, AsyncSnapshot<Map<String, dynamic>> snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: AppConstants.primaryRed));
          }
          if (snapshot.hasError || !snapshot.hasData) {
            return _buildErrorState();
          }

          final weather = snapshot.data!['weather'] as WeatherModel;
          final hasLoc = snapshot.data!['hasLoc'] as bool;

          return SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                _buildCurrentWeather(weather, hasLoc),
                const SizedBox(height: 48),
                _buildWeatherGrid(weather),
                const SizedBox(height: 48),
                _buildSafetyRecommendation(weather),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildCurrentWeather(WeatherModel weather, bool hasLoc) {
    return Builder(builder: (context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      children: [
        Text(
          hasLoc ? 'Current Location' : 'Catanduanes, Philippines',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black87, letterSpacing: 0.5),
        ),
        Text(
          DateFormat('EEEE, MMMM d').format(DateTime.now()),
          style: TextStyle(color: isDark ? Colors.white38 : Colors.black38, fontSize: 14),
        ),
        const SizedBox(height: 40),
        _getLargeWeatherIcon(weather.weatherCode),
        const SizedBox(height: 24),
        Text(
          '${weather.temperature.round()}°C',
          style: TextStyle(fontSize: 80, fontWeight: FontWeight.w900, color: isDark ? Colors.white : Colors.black87, letterSpacing: -2),
        ),
        Text(
          weather.description.toUpperCase(),
          style: TextStyle(fontSize: 16, color: isDark ? Colors.white54 : Colors.black54, fontWeight: FontWeight.bold, letterSpacing: 2),
        ),
      ],
    );
    });
  }

  Widget _buildWeatherGrid(WeatherModel weather) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      childAspectRatio: 1.5,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      children: [
        _buildDetailCard('Humidity', '${weather.humidity.round()}%', Icons.water_drop_outlined, Colors.blue),
        _buildDetailCard('Wind Speed', '${weather.windSpeed.round()} km/h', Icons.air, Colors.green),
        _buildDetailCard('Day/Night', weather.isDay ? 'Daytime' : 'Nighttime', Icons.wb_sunny_outlined, Colors.orange),
        _buildDetailCard('Weather Code', '#${weather.weatherCode}', Icons.qr_code_2_rounded, Colors.purple),
      ],
    );
  }

  Widget _buildDetailCard(String label, String value, IconData icon, Color color) {
    return Builder(builder: (context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: isDark ? const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1E2841), Color(0xFF161E31)],
        ) : null,
        color: isDark ? null : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.05)),
        boxShadow: isDark 
            ? [const BoxShadow(color: Colors.black45, blurRadius: 10, offset: Offset(0, 4))] 
            : [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color.withOpacity(0.7), size: 20),
          const SizedBox(height: 8),
          Text(value, style: TextStyle(color: isDark ? Colors.white : Colors.black87, fontSize: 18, fontWeight: FontWeight.bold)),
          Text(label, style: TextStyle(color: isDark ? Colors.white38 : Colors.black38, fontSize: 12)),
        ],
      ),
    );
    });
  }

  Widget _buildSafetyRecommendation(WeatherModel weather) {
    final bool isRisk = weather.weatherCode >= 80;
    return Builder(builder: (context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isRisk ? AppConstants.primaryRed.withOpacity(0.1) : Colors.green.withOpacity(0.05),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: isRisk ? AppConstants.primaryRed.withOpacity(0.3) : Colors.green.withOpacity(0.1)),
      ),
      child: Column(
        children: [
          Icon(isRisk ? Icons.warning_amber_rounded : Icons.gpp_good_outlined, color: isRisk ? AppConstants.primaryRed : Colors.green, size: 32),
          const SizedBox(height: 16),
          Text(
            isRisk ? 'SAFETY ALERT' : 'WEATHER IS CALM',
            style: TextStyle(color: isRisk ? AppConstants.primaryRed : Colors.green, fontWeight: FontWeight.bold, letterSpacing: 1),
          ),
          const SizedBox(height: 8),
          Text(
            isRisk 
              ? 'Heavy rain or thunderstorms detected. Stay indoors and avoid flood-prone areas in Catanduanes.'
              : 'Conditions are favorable for outdoor activities. No immediate weather threats detected.',
            textAlign: TextAlign.center,
            style: TextStyle(color: isDark ? Colors.white70 : Colors.black54, fontSize: 14),
          ),
        ],
      ),
    );
    });
  }

  Widget _getLargeWeatherIcon(int code) {
    IconData icon;
    Color color = Colors.white;

    if (code == 0) {
      icon = Icons.wb_sunny_rounded;
      color = Colors.orangeAccent;
    } else if (code <= 3) {
      icon = Icons.wb_cloudy_rounded;
      color = Colors.white70;
    } else if (code <= 48) {
      icon = Icons.cloud_queue_rounded;
    } else if (code <= 65) {
      icon = Icons.umbrella_rounded;
      color = Colors.blueAccent;
    } else if (code <= 82) {
      icon = Icons.beach_access_rounded;
      color = Colors.blue;
    } else {
      icon = Icons.thunderstorm_rounded;
      color = Colors.deepPurpleAccent;
    }

    return Icon(icon, color: color, size: 100);
  }

  Widget _buildErrorState() {
    return Builder(builder: (context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.cloud_off_rounded, color: isDark ? Colors.white24 : Colors.black26, size: 64),
          const SizedBox(height: 16),
          Text('Weather data synchronization failed', style: TextStyle(color: isDark ? Colors.white54 : Colors.black54)),
          TextButton(onPressed: () {}, child: const Text('RETRY', style: TextStyle(color: AppConstants.primaryRed))),
        ],
      ),
    );
    });
  }
}
