import 'package:cloud_firestore/cloud_firestore.dart';

class SOSRequestModel {
  final String sosId;
  final String userId;
  final String location;
  final DateTime timestamp;
  final String status;
  final String? description;
  final String? assignedTo;

  SOSRequestModel({
    required this.sosId,
    required this.userId,
    required this.location,
    required this.timestamp,
    required this.status,
    this.description,
    this.assignedTo,
  });

  factory SOSRequestModel.fromMap(Map<String, dynamic> data) {
    return SOSRequestModel(
      sosId: data['sos_id'] ?? '',
      userId: data['user_id'] ?? '',
      location: data['location'] ?? '',
      timestamp: (data['timestamp'] as Timestamp).toDate(),
      status: data['status'] ?? 'active',
      description: data['description'],
      assignedTo: data['assigned_to'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'sos_id': sosId,
      'user_id': userId,
      'location': location,
      'timestamp': Timestamp.fromDate(timestamp),
      'status': status,
      'description': description,
      'assigned_to': assignedTo,
    };
  }
}
