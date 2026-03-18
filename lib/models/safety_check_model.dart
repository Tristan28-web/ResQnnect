import 'package:cloud_firestore/cloud_firestore.dart';

class SafetyCheckEvent {
  final String eventId;
  final String title;
  final DateTime createdAt;
  final bool isActive;

  SafetyCheckEvent({
    required this.eventId,
    required this.title,
    required this.createdAt,
    required this.isActive,
  });

  factory SafetyCheckEvent.fromMap(Map<String, dynamic> data) {
    return SafetyCheckEvent(
      eventId: data['event_id'] ?? '',
      title: data['title'] ?? '',
      createdAt: (data['created_at'] as Timestamp).toDate(),
      isActive: data['is_active'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'event_id': eventId,
      'title': title,
      'created_at': Timestamp.fromDate(createdAt),
      'is_active': isActive,
    };
  }
}

class SafetyResponse {
  final String responseId;
  final String eventId;
  final String userId;
  final String userName;
  final String status; // 'safe', 'needs_help'
  final double latitude;
  final double longitude;
  final DateTime timestamp;

  SafetyResponse({
    required this.responseId,
    required this.eventId,
    required this.userId,
    required this.userName,
    required this.status,
    required this.latitude,
    required this.longitude,
    required this.timestamp,
  });

  factory SafetyResponse.fromMap(Map<String, dynamic> data) {
    return SafetyResponse(
      responseId: data['response_id'] ?? '',
      eventId: data['event_id'] ?? '',
      userId: data['user_id'] ?? '',
      userName: data['user_name'] ?? 'Citizen',
      status: data['status'] ?? 'safe',
      latitude: (data['latitude'] as num).toDouble(),
      longitude: (data['longitude'] as num).toDouble(),
      timestamp: (data['timestamp'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'response_id': responseId,
      'event_id': eventId,
      'user_id': userId,
      'user_name': userName,
      'status': status,
      'latitude': latitude,
      'longitude': longitude,
      'timestamp': Timestamp.fromDate(timestamp),
    };
  }
}
