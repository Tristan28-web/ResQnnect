import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String userId;
  final String name;
  final String email;
  final String phone;
  final String profileImage;
  final String role; // 'admin', 'citizen'
  final bool isActive;
  final String bloodType;
  final String weight;
  final String allergies;
  final String medications;
  final List<Map<String, String>> emergencyContacts;
  final bool isVerified;
  final DateTime createdAt;
  final DateTime? lastClockIn;

  UserModel({
    required this.userId,
    required this.name,
    required this.email,
    required this.phone,
    required this.profileImage,
    this.role = 'citizen',
    this.isActive = true,
    this.isVerified = false,
    this.bloodType = 'Not set',
    this.weight = 'Not set',
    this.allergies = 'None',
    this.medications = 'None',
    this.emergencyContacts = const [],
    required this.createdAt,
    this.lastClockIn,
  });

  factory UserModel.fromMap(Map<String, dynamic> data) {
    return UserModel(
      userId: data['user_id'] ?? '',
      name: data['name'] ?? '',
      email: data['email'] ?? '',
      phone: data['phone'] ?? '',
      profileImage: data['profile_image'] ?? '',
      role: data['role'] ?? 'citizen',
      isActive: data['is_active'] ?? true,
      isVerified: data['is_verified'] ?? false,
      bloodType: data['blood_type'] ?? 'Not set',
      weight: data['weight'] ?? 'Not set',
      allergies: data['allergies'] ?? 'None',
      medications: data['medications'] ?? 'None',
      emergencyContacts: List<Map<String, dynamic>>.from(data['emergency_contacts'] ?? [])
          .map((e) => Map<String, String>.from(e))
          .toList(),
      createdAt: data['created_at'] != null 
          ? (data['created_at'] as Timestamp).toDate() 
          : DateTime.now(),
      lastClockIn: data['last_clock_in'] != null
          ? (data['last_clock_in'] as Timestamp).toDate()
          : null,
    );
  }

  UserModel copyWith({
    String? name,
    String? phone,
    String? profileImage,
    String? role,
    bool? isActive,
    bool? isVerified,
    String? bloodType,
    String? weight,
    String? allergies,
    String? medications,
    List<Map<String, String>>? emergencyContacts,
    DateTime? lastClockIn,
  }) {
    return UserModel(
      userId: userId,
      name: name ?? this.name,
      email: email,
      phone: phone ?? this.phone,
      profileImage: profileImage ?? this.profileImage,
      role: role ?? this.role,
      isActive: isActive ?? this.isActive,
      isVerified: isVerified ?? this.isVerified,
      bloodType: bloodType ?? this.bloodType,
      weight: weight ?? this.weight,
      allergies: allergies ?? this.allergies,
      medications: medications ?? this.medications,
      emergencyContacts: emergencyContacts ?? this.emergencyContacts,
      createdAt: createdAt,
      lastClockIn: lastClockIn ?? this.lastClockIn,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'user_id': userId,
      'name': name,
      'email': email,
      'phone': phone,
      'profile_image': profileImage,
      'role': role,
      'is_active': isActive,
      'is_verified': isVerified,
      'blood_type': bloodType,
      'weight': weight,
      'allergies': allergies,
      'medications': medications,
      'emergency_contacts': emergencyContacts,
      'created_at': Timestamp.fromDate(createdAt),
      'last_clock_in': lastClockIn != null ? Timestamp.fromDate(lastClockIn!) : null,
    };
  }
}
