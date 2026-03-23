import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

enum HazardType {
  roadHazard,
  naturalDisaster,
  other
}

class HazardModel {
  final String hazardId;
  final HazardType type;
  final String description;
  final String? imageUrl;
  final String? imageBase64;
  final double latitude;
  final double longitude;
  final DateTime timestamp;
  final String reportedBy;
  final String status; // 'pending', 'confirmed', 'resolved'

  HazardModel({
    required this.hazardId,
    required this.type,
    required this.description,
    this.imageUrl,
    this.imageBase64,
    required this.latitude,
    required this.longitude,
    required this.timestamp,
    required this.reportedBy,
    required this.status,
  });

  factory HazardModel.fromMap(Map<String, dynamic> data) {
    return HazardModel(
      hazardId: data['hazard_id'] ?? '',
      type: _parseType(data['type']),
      description: data['description'] ?? '',
      imageUrl: data['image_url'],
      imageBase64: data['image_base64'],
      latitude: (data['latitude'] as num).toDouble(),
      longitude: (data['longitude'] as num).toDouble(),
      timestamp: (data['timestamp'] as Timestamp).toDate(),
      reportedBy: data['reported_by'] ?? '',
      status: data['status'] ?? 'pending',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'hazard_id': hazardId,
      'type': type.name,
      'description': description,
      'image_url': imageUrl,
      'image_base64': imageBase64,
      'latitude': latitude,
      'longitude': longitude,
      'timestamp': Timestamp.fromDate(timestamp),
      'reported_by': reportedBy,
      'status': status,
    };
  }

  static HazardType _parseType(String? typeStr) {
    return HazardType.values.firstWhere(
      (e) => e.name == typeStr,
      orElse: () => HazardType.other,
    );
  }
}
