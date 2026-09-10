import 'package:cloud_firestore/cloud_firestore.dart';

enum MapLocationType { command, medical, emergencyPost, safeZone }

class MapLocationModel {
  final String locationId;
  final String label;
  final String description;
  final double latitude;
  final double longitude;
  final MapLocationType type;
  final String addedBy;
  final DateTime createdAt;

  MapLocationModel({
    required this.locationId,
    required this.label,
    required this.description,
    required this.latitude,
    required this.longitude,
    required this.type,
    required this.addedBy,
    required this.createdAt,
  });

  factory MapLocationModel.fromMap(Map<String, dynamic> data) {
    DateTime parseDate(dynamic val) {
      if (val is Timestamp) return val.toDate();
      if (val is String) return DateTime.parse(val);
      return DateTime.now();
    }

    final rawType = data['type'] ?? 'safeZone';
    return MapLocationModel(
      locationId: data['location_id'] ?? '',
      label: data['label'] ?? '',
      description: data['description'] ?? '',
      latitude: (data['latitude'] as num).toDouble(),
      longitude: (data['longitude'] as num).toDouble(),
      type: (rawType == 'responder' || rawType == 'emergencyPost')
          ? MapLocationType.emergencyPost
          : MapLocationType.values.firstWhere(
              (e) => e.name == rawType,
              orElse: () => MapLocationType.safeZone,
            ),
      addedBy: data['added_by'] ?? '',
      createdAt: parseDate(data['created_at']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'location_id': locationId,
      'label': label,
      'description': description,
      'latitude': latitude,
      'longitude': longitude,
      'type': type.name,
      'added_by': addedBy,
      'created_at': createdAt.toIso8601String(), // Store as string for JSON compatibility
    };
  }
}
