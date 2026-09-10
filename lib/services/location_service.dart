import 'dart:convert';
import 'dart:math';
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

  // Catanduanes 11 Municipalities Reference Coordinates
  static const Map<String, List<double>> _catanduanesMunicipalities = {
    'Virac': [13.5840, 124.2330],
    'San Andres': [13.6000, 124.1000],
    'Bato': [13.6000, 124.2800],
    'Baras': [13.6700, 124.3700],
    'Gigmoto': [13.7800, 124.3900],
    'San Miguel': [13.6500, 124.2700],
    'Viga': [13.8800, 124.3100],
    'Panganiban': [13.9000, 124.3000],
    'Bagamanoc': [13.9400, 124.2900],
    'Caramoran': [13.9800, 124.1000],
    'Pandan': [14.0500, 124.1700],
  };

  // Known Philippine Cities for instant offline resolution
  static const Map<String, List<double>> _philippineKnownCities = {
    'Cadiz City, Negros Occidental': [10.9574, 123.2978],
    'Sagay City, Negros Occidental': [10.8970, 123.4244],
    'Bacolod City, Negros Occidental': [10.6765, 122.9509],
    'Talisay City, Negros Occidental': [10.7411, 122.9691],
    'Silay City, Negros Occidental': [10.7963, 122.9754],
    'Victorias City, Negros Occidental': [10.8988, 123.0818],
    'San Carlos City, Negros Occidental': [10.4855, 123.4190],
    'Cebu City, Cebu': [10.3157, 123.8854],
    'Mandaue City, Cebu': [10.3333, 123.9333],
    'Lapu-Lapu City, Cebu': [10.3117, 123.9536],
    'Iloilo City, Iloilo': [10.7202, 122.5621],
    'Roxas City, Capiz': [11.5853, 122.7511],
    'Kalibo, Aklan': [11.7072, 122.3638],
    'Tacloban City, Leyte': [11.2433, 125.0039],
    'Naga City, Camarines Sur': [13.6218, 123.1948],
    'Legazpi City, Albay': [13.1391, 123.7438],
    'Sorsogon City, Sorsogon': [12.9742, 124.0058],
    'Daet, Camarines Norte': [14.1167, 122.9500],
    'Manila, Metro Manila': [14.5995, 120.9842],
    'Quezon City, Metro Manila': [14.6760, 121.0437],
    'Davao City, Davao del Sur': [7.1907, 125.4553],
    'Cagayan de Oro, Misamis Oriental': [8.4542, 124.6319],
    'Zamboanga City': [6.9214, 122.0790],
  };

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
        _currentLocationName = 'GPS Off (Catanduanes)';
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
        _currentLocationName = 'Catanduanes (GPS Standby)';
      }
    } catch (e) {
      debugPrint('Location detection error: $e');
      _currentLocationName = 'Catanduanes, PH';
    } finally {
      _isLoading = false;
      notifyListeners();
    }

    return _currentPosition;
  }

  Future<String> _resolveLocationName(double lat, double lng) async {
    // 1. Check nearest municipality in Catanduanes
    String nearestMuni = 'Virac';
    double minCatanduanesDist = double.infinity;

    for (var entry in _catanduanesMunicipalities.entries) {
      final mLat = entry.value[0];
      final mLng = entry.value[1];
      final d = _calculateDistanceKm(lat, lng, mLat, mLng);
      if (d < minCatanduanesDist) {
        minCatanduanesDist = d;
        nearestMuni = entry.key;
      }
    }

    // If within ~55km of Catanduanes Island
    if (minCatanduanesDist <= 55.0) {
      return '$nearestMuni, Catanduanes';
    }

    // 2. Dynamic reverse geocoding via BigDataCloud client API
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

    // 3. Fallback to OpenStreetMap Nominatim reverse geocode
    try {
      final uri = Uri.parse(
        'https://nominatim.openstreetmap.org/reverse?lat=$lat&lon=$lng&format=json',
      );
      final response = await http.get(
        uri,
        headers: {'User-Agent': 'ResQnnect-GIS/1.0'},
      ).timeout(const Duration(seconds: 3));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final address = data['address'] as Map<String, dynamic>? ?? {};
        final city = address['city'] ?? address['town'] ?? address['municipality'] ?? address['county'];
        final state = address['state'] ?? address['region'];
        if (city != null && state != null) {
          return '$city, $state';
        } else if (city != null) {
          return '$city';
        }
      }
    } catch (_) {}

    // 4. Instant offline fallback to nearest known Philippine city
    String nearestCity = 'Cadiz City, Negros Occidental';
    double minKnownDist = double.infinity;
    for (var entry in _philippineKnownCities.entries) {
      final d = _calculateDistanceKm(lat, lng, entry.value[0], entry.value[1]);
      if (d < minKnownDist) {
        minKnownDist = d;
        nearestCity = entry.key;
      }
    }

    if (minKnownDist <= 60.0) {
      return nearestCity;
    }

    return 'Philippines (Detected)';
  }

  double _calculateDistanceKm(double lat1, double lon1, double lat2, double lon2) {
    const p = 0.017453292519943295; // Math.PI / 180
    final a = 0.5 -
        cos((lat2 - lat1) * p) / 2 +
        cos(lat1 * p) * cos(lat2 * p) * (1 - cos((lon2 - lon1) * p)) / 2;
    return 12742 * asin(sqrt(a)); // 2 * R * asin...
  }
}
