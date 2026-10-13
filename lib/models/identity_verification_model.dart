import 'package:cloud_firestore/cloud_firestore.dart';

/// Philippine government-issued photo IDs accepted for citizen verification.
///
/// Based on the lists used for SIM registration (RA 11934 / NTC), BSP-regulated
/// banks and Pag-IBIG, plus the PhilSys Act (RA 11055 / EO 162). Private IDs
/// (school, company) are deliberately excluded. The list is not exhaustive:
/// the LGU can extend it as needed.
///
/// Widely accepted primary IDs, listed first. (A Sept 2026 DICT proposal would
/// narrow SIM registration to the first three.)
const List<String> kPrimaryIdTypes = [
  'Philippine National ID (PhilSys)',
  'Philippine Passport',
  "Driver's License (LTO)",
  'UMID (SSS / GSIS)',
  'PRC ID',
  'Postal ID (PHLPost)',
];

/// Other government-issued IDs and clearances that carry a photo.
const List<String> kOtherIdTypes = [
  'SSS ID',
  'GSIS eCard',
  'PhilHealth ID',
  'TIN ID (BIR)',
  "Voter's ID (COMELEC)",
  'Senior Citizen ID',
  'PWD ID',
  'OWWA / OFW ID',
  'IBP ID',
  "Seafarer's ID (SIRB)",
  'Government Office / GOCC ID',
  'NBI Clearance (with photo)',
  'Police Clearance (with photo)',
];

const List<String> kAcceptedIdTypes = [...kPrimaryIdTypes, ...kOtherIdTypes];

/// ID + selfie evidence submitted by a citizen during registration.
/// Stored in its own collection (not on the user doc) so the heavy Base64
/// images are never streamed with every profile read.
class IdentityVerificationModel {
  final String userId;
  final String idType;
  final String idImageBase64;
  final String selfieBase64;

  /// Cosine similarity between ID portrait and selfie (null = not computed,
  /// e.g. web build or model missing → admin decides manually).
  final double? faceMatchScore;
  final bool livenessPassed;
  final bool faceFoundOnId;

  /// 'mobilefacenet-tflite' | 'manual-review'
  final String matchEngine;
  final DateTime submittedAt;

  IdentityVerificationModel({
    required this.userId,
    required this.idType,
    required this.idImageBase64,
    required this.selfieBase64,
    required this.faceMatchScore,
    required this.livenessPassed,
    required this.faceFoundOnId,
    required this.matchEngine,
    required this.submittedAt,
  });

  factory IdentityVerificationModel.fromMap(Map<String, dynamic> data) {
    return IdentityVerificationModel(
      userId: data['user_id'] ?? '',
      idType: data['id_type'] ?? '',
      idImageBase64: data['id_image_base64'] ?? '',
      selfieBase64: data['selfie_base64'] ?? '',
      faceMatchScore: (data['face_match_score'] as num?)?.toDouble(),
      livenessPassed: data['liveness_passed'] ?? false,
      faceFoundOnId: data['face_found_on_id'] ?? false,
      matchEngine: data['match_engine'] ?? 'manual-review',
      submittedAt: data['submitted_at'] != null
          ? (data['submitted_at'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() => {
        'user_id': userId,
        'id_type': idType,
        'id_image_base64': idImageBase64,
        'selfie_base64': selfieBase64,
        'face_match_score': faceMatchScore,
        'liveness_passed': livenessPassed,
        'face_found_on_id': faceFoundOnId,
        'match_engine': matchEngine,
        'submitted_at': Timestamp.fromDate(submittedAt),
      };
}
