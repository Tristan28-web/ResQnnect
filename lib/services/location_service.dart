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
      // 1. Attempt hardware GPS detection first
      bool serviceEnabled = false;
      try {
        serviceEnabled = await Geolocator.isLocationServiceEnabled();
      } catch (_) {}

      Position? position;
      if (serviceEnabled) {
        LocationPermission permission = await Geolocator.checkPermission();
        if (permission == LocationPermission.denied) {
          permission = await Geolocator.requestPermission();
        }

        if (permission != LocationPermission.denied && permission != LocationPermission.deniedForever) {
          final prefs = await SharedPreferences.getInstance();
          final highAcc = prefs.getBool('config_high_acc_loc') ?? true;
          final accuracy = highAcc ? LocationAccuracy.high : LocationAccuracy.medium;

          try {
            position = await Geolocator.getCurrentPosition(
              locationSettings: LocationSettings(
                accuracy: accuracy,
                timeLimit: const Duration(seconds: 6),
              ),
            );
          } catch (_) {
            position = await Geolocator.getLastKnownPosition();
          }
        }
      }

      // Check if GPS position is valid real hardware, or if it's an emulator mock (or Cadiz emulator mock coordinate)
      bool isMockOrEmulator = position == null ||
          position.isMocked ||
          (position.latitude >= 10.9500 &&
              position.latitude <= 10.9700 &&
              position.longitude >= 123.2800 &&
              position.longitude <= 123.3100);

      if (isMockOrEmulator) {
        // Fallback automatically to real physical network IP geolocation
        final netPos = await _fetchNetworkIpLocation();
        if (netPos != null) {
          _currentPosition = netPos;
          _currentLocationName = await _resolveLocationName(netPos.latitude, netPos.longitude);
          return _currentPosition;
        }
      }

      if (position != null) {
        _currentPosition = position;
        _currentLocationName = await _resolveLocationName(position.latitude, position.longitude);
      } else {
        // If both GPS and initial IP failed, try secondary IP endpoint
        final fallbackPos = await _fetchNetworkIpLocation();
        if (fallbackPos != null) {
          _currentPosition = fallbackPos;
          _currentLocationName = await _resolveLocationName(fallbackPos.latitude, fallbackPos.longitude);
        } else {
          _currentLocationName = 'Locating User...';
        }
      }
    } catch (e) {
      debugPrint('Location detection error: $e');
      final fallbackPos = await _fetchNetworkIpLocation();
      if (fallbackPos != null) {
        _currentPosition = fallbackPos;
        _currentLocationName = await _resolveLocationName(fallbackPos.latitude, fallbackPos.longitude);
      } else {
        _currentLocationName = 'Acquiring Location...';
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }

    return _currentPosition;
  }

  /// Automatically detects physical user location from network ISP IP (essential for emulators & indoor PCs)
  Future<Position?> _fetchNetworkIpLocation() async {
    // Primary: ipwho.is (fast HTTPS, returns exact city and coordinates)
    try {
      final uri = Uri.parse('https://ipwho.is/');
      final response = await http.get(uri).timeout(const Duration(seconds: 4));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final success = data['success'] as bool? ?? true;
        if (success && data['latitude'] != null && data['longitude'] != null) {
          final lat = (data['latitude'] as num).toDouble();
          final lng = (data['longitude'] as num).toDouble();
          return Position(
            latitude: lat,
            longitude: lng,
            timestamp: DateTime.now(),
            accuracy: 50.0,
            altitude: 0.0,
            altitudeAccuracy: 0.0,
            heading: 0.0,
            headingAccuracy: 0.0,
            speed: 0.0,
            speedAccuracy: 0.0,
          );
        }
      }
    } catch (e) {
      debugPrint('Primary IP Geolocation error: $e');
    }

    // Secondary fallback: freeipapi.com (HTTPS)
    try {
      final uri = Uri.parse('https://freeipapi.com/api/json');
      final response = await http.get(uri).timeout(const Duration(seconds: 4));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        if (data['latitude'] != null && data['longitude'] != null) {
          final lat = (data['latitude'] as num).toDouble();
          final lng = (data['longitude'] as num).toDouble();
          return Position(
            latitude: lat,
            longitude: lng,
            timestamp: DateTime.now(),
            accuracy: 50.0,
            altitude: 0.0,
            altitudeAccuracy: 0.0,
            heading: 0.0,
            headingAccuracy: 0.0,
            speed: 0.0,
            speedAccuracy: 0.0,
          );
        }
      }
    } catch (e) {
      debugPrint('Secondary IP Geolocation error: $e');
    }

    return null;
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
