import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class LocationService extends ChangeNotifier {
  String _currentLocationName = 'Locating...';
  Position? _currentPosition;
  bool _isLoading = false;

  String get currentLocationName => _currentLocationName;
  Position? get currentPosition => _currentPosition;
  bool get isLoading => _isLoading;

  LocationService() {
    refreshLocation();
  }

  Future<Position?> getCurrentLocation() async {
    return await refreshLocation();
  }

  Future<Position?> refreshLocation() async {
    _isLoading = true;
    notifyListeners();

    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _currentLocationName = 'GPS Disabled';
        _isLoading = false;
        notifyListeners();
        return null;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          _currentLocationName = 'Location Denied';
          _isLoading = false;
          notifyListeners();
          return null;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        _currentLocationName = 'Location Restricted';
        _isLoading = false;
        notifyListeners();
        return null;
      }

      final prefs = await SharedPreferences.getInstance();
      final highAcc = prefs.getBool('config_high_acc_loc') ?? true;
      final accuracy = highAcc ? LocationAccuracy.high : LocationAccuracy.medium;

      Position? position;
      try {
        position = await Geolocator.getCurrentPosition(
          desiredAccuracy: accuracy,
          timeLimit: const Duration(seconds: 8),
        );
      } catch (_) {
        position = await Geolocator.getLastKnownPosition();
      }

      if (position != null) {
        _currentPosition = position;
        _currentLocationName = await _resolveLocationName(position.latitude, position.longitude);
      } else {
        _currentLocationName = 'Locating User...';
      }
    } catch (e) {
      debugPrint('Location detection error: $e');
      _currentLocationName = 'Acquiring Location...';
    } finally {
      _isLoading = false;
      notifyListeners();
    }

    return _currentPosition;
  }

  /// Expose public reverse geocoding for UI widgets and coordinate resolution
  Future<String> reverseGeocode(double lat, double lng) => _resolveLocationName(lat, lng);

  Future<String> _resolveLocationName(double lat, double lng) async {
    // 1. Dynamic reverse geocoding via BigDataCloud client API
    try {
      final uri = Uri.parse(
        'https://api.bigdatacloud.net/data/reverse-geocode-client?latitude=$lat&longitude=$lng&localityLanguage=en',
      );
      final response = await http.get(uri).timeout(const Duration(seconds: 4));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final city = (data['city'] ?? data['locality'] ?? '').toString().trim();
        final state = (data['principalSubdivision'] ?? '').toString().trim();
        if (city.isNotEmpty && state.isNotEmpty) {
          return '$city, $state';
        } else if (city.isNotEmpty) {
          return city;
        } else if (state.isNotEmpty) {
          return state;
        }
      }
    } catch (_) {}

    // 2. Fallback to OpenStreetMap Nominatim reverse geocode
    try {
      final uri = Uri.parse(
        'https://nominatim.openstreetmap.org/reverse?lat=$lat&lon=$lng&format=json',
      );
      final response = await http.get(
        uri,
        headers: {'User-Agent': 'GIS-App/1.0'},
      ).timeout(const Duration(seconds: 3));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final address = data['address'] as Map<String, dynamic>? ?? {};
        final city = address['city'] ?? address['town'] ?? address['municipality'] ?? address['suburb'] ?? address['county'];
        final state = address['state'] ?? address['region'];
        if (city != null && state != null) {
          return '$city, $state';
        } else if (city != null) {
          return '$city';
        } else if (state != null) {
          return '$state';
        }
      }
    } catch (_) {}

    // 3. Fallback strictly to the user's real GPS coordinates
    return '${lat.toStringAsFixed(4)}°, ${lng.toStringAsFixed(4)}°';
  }
}
