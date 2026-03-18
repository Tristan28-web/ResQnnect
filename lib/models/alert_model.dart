import 'package:cloud_firestore/cloud_firestore.dart';

class AlertModel {
  final String alertId;
  final String title;
  final String description;
  final String disasterType;
  final DateTime createdAt;

  AlertModel({
    required this.alertId,
    required this.title,
    required this.description,
    required this.disasterType,
    required this.createdAt,
  });

  factory AlertModel.fromMap(Map<String, dynamic> data) {
    return AlertModel(
      alertId: data['alert_id'] ?? '',
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      disasterType: data['disaster_type'] ?? '',
      createdAt: (data['created_at'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'alert_id': alertId,
      'title': title,
      'description': description,
      'disaster_type': disasterType,
      'created_at': Timestamp.fromDate(createdAt),
    };
  }
}
