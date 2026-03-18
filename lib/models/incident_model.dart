import 'package:cloud_firestore/cloud_firestore.dart';

class IncidentModel {
  final String incidentId;
  final String userId;
  final String description;
  final String? imageUrl; // Keep for remote URLs if any
  final String? imageBase64; // New: Store image data directly
  final String location;
  final String status;
  final DateTime timestamp;

  final String? assignedTo;

  IncidentModel({
    required this.incidentId,
    required this.userId,
    required this.description,
    this.imageUrl,
    this.imageBase64,
    required this.location,
    required this.status,
    required this.timestamp,
    this.assignedTo,
  });

  factory IncidentModel.fromMap(Map<String, dynamic> data) {
    return IncidentModel(
      incidentId: data['incident_id'] ?? '',
      userId: data['user_id'] ?? '',
      description: data['description'] ?? '',
      imageUrl: data['image_url'],
      imageBase64: data['image_base64'],
      location: data['location'] ?? '',
      status: data['status'] ?? 'pending',
      timestamp: (data['timestamp'] as Timestamp).toDate(),
      assignedTo: data['assigned_to'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'incident_id': incidentId,
      'user_id': userId,
      'description': description,
      'image_url': imageUrl,
      'image_base64': imageBase64,
      'location': location,
      'status': status,
      'timestamp': Timestamp.fromDate(timestamp),
      'assigned_to': assignedTo,
    };
  }
}

