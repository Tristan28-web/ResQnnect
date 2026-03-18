import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/map_location_model.dart';

class OfflineVaultService {
  static const String _safeZonesKey = 'offline_safe_zones';
  static const String _guidesKey = 'offline_guides';

  // Save Safe Zones locally
  Future<void> cacheSafeZones(List<MapLocationModel> zones) async {
    final prefs = await SharedPreferences.getInstance();
    final data = zones.map((z) => z.toMap()).toList();
    await prefs.setString(_safeZonesKey, jsonEncode(data));
  }

  // Get cached Safe Zones
  Future<List<MapLocationModel>> getCachedSafeZones() async {
    final prefs = await SharedPreferences.getInstance();
    final dataString = prefs.getString(_safeZonesKey);
    if (dataString == null) return [];
    
    final List<dynamic> data = jsonDecode(dataString);
    return data.map((item) => MapLocationModel.fromMap(item)).toList();
  }

  // Save Emergency Guides (Standard data that doesn't change often)
  Future<void> cacheEmergencyGuides(List<Map<String, String>> guides) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_guidesKey, jsonEncode(guides));
  }

  // Get cached Emergency Guides
  Future<List<Map<String, String>>> getCachedGuides() async {
    final prefs = await SharedPreferences.getInstance();
    final dataString = prefs.getString(_guidesKey);
    if (dataString == null) return _defaultGuides;
    
    final List<dynamic> data = jsonDecode(dataString);
    return data.map((item) => Map<String, String>.from(item)).toList();
  }

  static final List<Map<String, String>> _defaultGuides = [
    {
      'title': 'First Aid: Severe Bleeding',
      'instruction': '1. Apply direct pressure.\n2. Keep limb elevated.\n3. Wrap with clean bandage.',
      'icon': 'bloodtype',
    },
    {
      'title': 'During an Earthquake',
      'instruction': '1. Drop to the floor.\n2. Cover your head and neck.\n3. Hold on until shaking stops.',
      'icon': 'vibration',
    },
    {
      'title': 'Flood Safety',
      'instruction': '1. Move to higher ground.\n2. Do NOT walk or drive through water.\n3. Turn off utilities.',
      'icon': 'water_damage',
    },
  ];
}
