import 'package:cloud_firestore/cloud_firestore.dart';

class IncidentModel {
  final String incidentId;
  final String referenceId; // e.g. INC-001
  final String userId;
  final String incidentType; // Fire, Flood, Crime, Accident, Other
  final String barangay;
  final String description;
  final String? imageUrl; // Remote URL
  final String? imageBase64; // Embedded image
  final String location; // Detailed address or landmark
  final double? latitude;
  final double? longitude;
  final String severity; // low, medium, high, critical
  final String status; // pending / reported, dispatched, responding, resolved, closed
  final DateTime timestamp;
  final String? assignedTo;
  final String? resolutionNotes;

  IncidentModel({
    required this.incidentId,
    String? referenceId,
    required this.userId,
    String? incidentType,
    String? barangay,
    required this.description,
    this.imageUrl,
    this.imageBase64,
    required this.location,
    this.latitude,
    this.longitude,
    this.severity = 'medium',
    required this.status,
    required this.timestamp,
    this.assignedTo,
    this.resolutionNotes,
  })  : referenceId = referenceId ?? _generateRefId(incidentId),
        incidentType = incidentType ?? _inferIncidentType(description),
        barangay = barangay ?? _inferBarangay(location);

  static String _generateRefId(String id) {
    if (id.length > 4) {
      final suffix = id.substring(id.length - 4);
      return 'INC-$suffix';
    }
    return 'INC-001';
  }

  static String _inferIncidentType(String text) {
    final lower = text.toLowerCase();
    if (lower.contains('fire') || lower.contains('sunog') || lower.contains('smoke')) return 'Fire';
    if (lower.contains('flood') || lower.contains('baha') || lower.contains('water') || lower.contains('rain')) return 'Flood';
    if (lower.contains('crime') || lower.contains('theft') || lower.contains('robbery') || lower.contains('hold') || lower.contains('fight')) return 'Crime';
    if (lower.contains('accident') || lower.contains('crash') || lower.contains('collision') || lower.contains('hit')) return 'Accident';
    return 'Other';
  }

  static String _inferBarangay(String loc) {
    if (loc.toLowerCase().contains('san juan')) return 'Brgy. San Juan';
    if (loc.toLowerCase().contains('mabini')) return 'Brgy. Mabini';
    if (loc.toLowerCase().contains('daga')) return 'Brgy. Daga';
    if (loc.toLowerCase().contains('tinampaan')) return 'Brgy. Tinampaan';
    if (loc.toLowerCase().contains('sicaba')) return 'Brgy. Sicaba';
    if (loc.toLowerCase().contains('burgos')) return 'Brgy. Burgos';
    return 'Brgy. Zone 1 (Poblacion)';
  }

  factory IncidentModel.fromMap(Map<String, dynamic> data) {
    final rawTimestamp = data['timestamp'];
    DateTime parsedTime = DateTime.now();
    if (rawTimestamp is Timestamp) {
      parsedTime = rawTimestamp.toDate();
    } else if (rawTimestamp is String) {
      parsedTime = DateTime.tryParse(rawTimestamp) ?? DateTime.now();
    }

    double? lat;
    if (data['latitude'] != null) {
      lat = (data['latitude'] as num).toDouble();
    }
    double? lng;
    if (data['longitude'] != null) {
      lng = (data['longitude'] as num).toDouble();
    }

    // Try parsing lat/lng from location string if formatted like "10.957, 123.321"
    final locStr = data['location']?.toString() ?? '';
    if (lat == null && lng == null && locStr.contains(',')) {
      final parts = locStr.split(',');
      if (parts.length >= 2) {
        lat = double.tryParse(parts[0].trim());
        lng = double.tryParse(parts[1].trim());
      }
    }

    final id = data['incident_id'] ?? '';

    return IncidentModel(
      incidentId: id,
      referenceId: data['reference_id'] ?? _generateRefId(id),
      userId: data['user_id'] ?? '',
      incidentType: data['incident_type'] ?? _inferIncidentType(data['description'] ?? ''),
      barangay: data['barangay'] ?? _inferBarangay(locStr),
      description: data['description'] ?? '',
      imageUrl: data['image_url'],
      imageBase64: data['image_base64'],
      location: locStr,
      latitude: lat,
      longitude: lng,
      severity: data['severity'] ?? 'medium',
      status: data['status'] ?? 'pending',
      timestamp: parsedTime,
      assignedTo: data['assigned_to'],
      resolutionNotes: data['resolution_notes'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'incident_id': incidentId,
      'reference_id': referenceId,
      'user_id': userId,
      'incident_type': incidentType,
      'barangay': barangay,
      'description': description,
      'image_url': imageUrl,
      'image_base64': imageBase64,
      'location': location,
      'latitude': latitude,
      'longitude': longitude,
      'severity': severity,
      'status': status,
      'timestamp': Timestamp.fromDate(timestamp),
      'assigned_to': assignedTo,
      'resolution_notes': resolutionNotes,
    };
  }

  IncidentModel copyWith({
    String? incidentId,
    String? referenceId,
    String? userId,
    String? incidentType,
    String? barangay,
    String? description,
    String? imageUrl,
    String? imageBase64,
    String? location,
    double? latitude,
    double? longitude,
    String? severity,
    String? status,
    DateTime? timestamp,
    String? assignedTo,
    String? resolutionNotes,
  }) {
    return IncidentModel(
      incidentId: incidentId ?? this.incidentId,
      referenceId: referenceId ?? this.referenceId,
      userId: userId ?? this.userId,
      incidentType: incidentType ?? this.incidentType,
      barangay: barangay ?? this.barangay,
      description: description ?? this.description,
      imageUrl: imageUrl ?? this.imageUrl,
      imageBase64: imageBase64 ?? this.imageBase64,
      location: location ?? this.location,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      severity: severity ?? this.severity,
      status: status ?? this.status,
      timestamp: timestamp ?? this.timestamp,
      assignedTo: assignedTo ?? this.assignedTo,
      resolutionNotes: resolutionNotes ?? this.resolutionNotes,
    );
  }
}
