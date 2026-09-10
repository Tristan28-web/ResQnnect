import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
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
        _currentLocationName = _resolveLocationName(position.latitude, position.longitude);
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

  String _resolveLocationName(double lat, double lng) {
    // Check nearest municipality in Catanduanes
    String nearestMuni = 'Virac';
    double minDistanceKm = double.infinity;

    for (var entry in _catanduanesMunicipalities.entries) {
      final mLat = entry.value[0];
      final mLng = entry.value[1];
      final d = _calculateDistanceKm(lat, lng, mLat, mLng);
      if (d < minDistanceKm) {
        minDistanceKm = d;
        nearestMuni = entry.key;
      }
    }

    // If within ~50km of Catanduanes Island
    if (minDistanceKm <= 55.0) {
      return '$nearestMuni, Catanduanes';
    }

    // If on emulator/device located elsewhere, format as clean localized coordinates
    final latDir = lat >= 0 ? 'N' : 'S';
    final lngDir = lng >= 0 ? 'E' : 'W';
    return '${lat.abs().toStringAsFixed(2)}°$latDir, ${lng.abs().toStringAsFixed(2)}°$lngDir (GPS)';
  }

  double _calculateDistanceKm(double lat1, double lon1, double lat2, double lon2) {
    const p = 0.017453292519943295; // Math.PI / 180
    final a = 0.5 -
        cos((lat2 - lat1) * p) / 2 +
        cos(lat1 * p) * cos(lat2 * p) * (1 - cos((lon2 - lon1) * p)) / 2;
    return 12742 * asin(sqrt(a)); // 2 * R * asin...
  }
}
