import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:rxdart/rxdart.dart';
import '../core/constants.dart';
import '../models/user_model.dart';
import '../models/incident_model.dart';
import '../models/alert_model.dart';
import '../models/sos_model.dart';
import '../models/map_location_model.dart';
import '../models/safety_check_model.dart';
import '../models/hazard_model.dart';
import 'offline_vault_service.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Stream single user
  Stream<UserModel?> getUserStream(String userId) {
    return _db.collection(AppConstants.usersCollection).doc(userId).snapshots().map((doc) {
      if (!doc.exists) return null;
      return UserModel.fromMap(doc.data()!);
    });
  }

  Future<void> updateUserModel(UserModel user) async {
    await _db.collection(AppConstants.usersCollection).doc(user.userId).set(user.toMap(), SetOptions(merge: true));
  }

  // Report Incident
  Future<void> reportIncident(IncidentModel incident) async {
    await _db.collection(AppConstants.incidentsCollection).doc(incident.incidentId).set(incident.toMap());
  }

  // Get Incidents (Stream)
  Stream<List<IncidentModel>> getIncidents() {
    return _db.collection(AppConstants.incidentsCollection)
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => IncidentModel.fromMap(doc.data()))
            .toList());
  }

  Future<void> updateIncidentStatus(String incidentId, String status) async {
    await _db.collection(AppConstants.incidentsCollection).doc(incidentId).update({
      'status': status,
    });
  }

  Future<void> updateIncidentStatusWithNotes(String incidentId, String status, {String? notes}) async {
    final Map<String, dynamic> data = {'status': status};
    if (notes != null && notes.isNotEmpty) {
      data['resolution_notes'] = notes;
    }
    await _db.collection(AppConstants.incidentsCollection).doc(incidentId).update(data);
  }

  Future<void> assignIncident(String incidentId, String responderId) async {
    await _db.collection(AppConstants.incidentsCollection).doc(incidentId).update({
      'assigned_to': responderId,
      'status': 'dispatched',
    });
  }

  Stream<int> getIncidentCountByUser(String userId) {
    return _db
        .collection(AppConstants.incidentsCollection)
        .where('user_id', isEqualTo: userId)
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  // Get Alerts (Stream)
  Stream<List<AlertModel>> getAlerts() {
    return _db.collection(AppConstants.alertsCollection)
        .orderBy('created_at', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => AlertModel.fromMap(doc.data()))
            .toList());
  }

  Stream<int> getAlertCount() {
    return _db
        .collection(AppConstants.alertsCollection)
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  // Send SOS alert
  Future<void> sendSOS(SOSRequestModel sos) async {
    await _db.collection(AppConstants.sosCollection).doc(sos.sosId).set(sos.toMap());
  }

  // Manage Responders (Admin)
  Stream<List<UserModel>> getResponders() {
    return _db
        .collection(AppConstants.usersCollection)
        .where('role', isEqualTo: AppConstants.roleResponder)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => UserModel.fromMap(doc.data())).toList());
  }

  Stream<int> getResponderCount() {
    return _db
        .collection(AppConstants.usersCollection)
        .where('role', isEqualTo: AppConstants.roleResponder)
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  Stream<int> getVerifiedCitizenCount() {
    return _db
        .collection(AppConstants.usersCollection)
        .where('role', isEqualTo: AppConstants.roleCitizen)
        .where('is_verified', isEqualTo: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  Stream<int> getUnverifiedCitizenCount() {
    return getUnverifiedCitizens().map((list) => list.length);
  }

  Stream<List<UserModel>> getUnverifiedCitizens() {
    return _db
        .collection(AppConstants.usersCollection)
        .where('role', isEqualTo: AppConstants.roleCitizen)
        .where('is_verified', isEqualTo: false)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => UserModel.fromMap(doc.data()))
            .where((u) => u.isActive)
            .toList());
  }

  Future<void> verifyUser(String userId) async {
    await _db.collection(AppConstants.usersCollection).doc(userId).update({
      'is_verified': true,
      'is_active': true,
    });
  }

  Future<void> rejectCitizen(String userId) async {
    try {
      await _db.collection(AppConstants.usersCollection).doc(userId).delete();
    } catch (_) {
      await _db.collection(AppConstants.usersCollection).doc(userId).update({
        'is_active': false,
        'is_verified': false,
        'verification_status': 'rejected',
      });
    }
  }

  Future<void> updateUserVerification(String userId, bool isVerified) async {
    if (isVerified) {
      await verifyUser(userId);
    } else {
      await rejectCitizen(userId);
    }
  }

  Future<void> deleteUser(String userId) async {
    await _db.collection(AppConstants.usersCollection).doc(userId).delete();
  }

  Future<void> toggleResponderActive(String userId, bool currentStatus) async {
    final newStatus = !currentStatus;
    final Map<String, dynamic> updates = {'is_active': newStatus};
    
    // If going active, update clock in time
    if (newStatus) {
      updates['last_clock_in'] = FieldValue.serverTimestamp();
    }
    
    await _db.collection(AppConstants.usersCollection).doc(userId).update(updates);
  }

  Future<void> updateUserData(UserModel user) async {
    await _db.collection(AppConstants.usersCollection).doc(user.userId).update(user.toMap());
  }

  Future<void> updateResponderProfile(UserModel user) async {
    await _db.collection(AppConstants.usersCollection).doc(user.userId).update(user.toMap());
  }

  // --- LGU User Management (Module 10) ---
  Stream<List<UserModel>> getAllUsers() {
    return _db
        .collection(AppConstants.usersCollection)
        .orderBy('created_at', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => UserModel.fromMap(doc.data())).toList());
  }

  Future<void> updateUserRole(String userId, String role) async {
    await _db.collection(AppConstants.usersCollection).doc(userId).update({
      'role': role,
    });
  }

  Future<void> toggleUserStatus(String userId, bool currentStatus) async {
    await _db.collection(AppConstants.usersCollection).doc(userId).update({
      'is_active': !currentStatus,
    });
  }

  // Get SOS Requests (Stream)
  Stream<List<SOSRequestModel>> getSOSRequests() {
    return _db.collection(AppConstants.sosCollection)
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => SOSRequestModel.fromMap(doc.data()))
            .toList());
  }

  Future<void> updateSOSStatus(String sosId, String status) async {
    await _db.collection(AppConstants.sosCollection).doc(sosId).update({
      'status': status,
    });
  }

  Future<void> assignSOS(String sosId, String responderId) async {
    await _db.collection(AppConstants.sosCollection).doc(sosId).update({
      'assigned_to': responderId,
      'status': 'dispatched',
    });
  }

  Stream<Map<String, dynamic>?> getAssignedMission(String responderId) {
    if (responderId.isEmpty) return Stream.value(null);

    final incidentStream = _db
        .collection(AppConstants.incidentsCollection)
        .where('assigned_to', isEqualTo: responderId)
        .snapshots();

    final sosStream = _db
        .collection(AppConstants.sosCollection)
        .where('assigned_to', isEqualTo: responderId)
        .snapshots();

    return CombineLatestStream.combine2<QuerySnapshot, QuerySnapshot, Map<String, dynamic>?>(
      incidentStream,
      sosStream,
      (incidentSnap, sosSnap) {
        // Find first unresolved incident
        final activeIncident = incidentSnap.docs.where((doc) {
          final Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
          return data['status'] != 'resolved';
        }).toList();

        if (activeIncident.isNotEmpty) {
          final data = activeIncident.first.data() as Map<String, dynamic>;
          data['id'] = activeIncident.first.id;
          data['mission_type'] = 'INCIDENT';
          return data;
        }
        
        // Find first unresolved SOS
        final activeSOS = sosSnap.docs.where((doc) {
          final Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
          return data['status'] != 'resolved';
        }).toList();

        if (activeSOS.isNotEmpty) {
          final data = activeSOS.first.data() as Map<String, dynamic>;
          data['id'] = activeSOS.first.id;
          data['mission_type'] = 'SOS';
          data['description'] = data['description'] ?? 'Emergency SOS Alert';
          return data;
        }
        
        return null;
      },
    ).asBroadcastStream();
  }

  // Send System Alert
  Future<void> sendAlert(AlertModel alert) async {
    await _db.collection(AppConstants.alertsCollection).doc(alert.alertId).set(alert.toMap());
  }

  // ─── Map Locations (Admin-pinned) ───────────────────────────────────────────

  Stream<List<MapLocationModel>> getMapLocations() {
    return _db
        .collection('map_locations')
        .orderBy('created_at', descending: false)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => MapLocationModel.fromMap(doc.data()))
            .toList());
  }

  Stream<int> getMapLocationCount() {
    return _db
        .collection('map_locations')
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  Future<void> addMapLocation(MapLocationModel location) async {
    await _db.collection('map_locations').doc(location.locationId).set(location.toMap());
  }

  Future<void> deleteMapLocation(String locationId) async {
    await _db.collection('map_locations').doc(locationId).delete();
  }

  Future<void> updateMapLocation(MapLocationModel location) async {
    await _db.collection('map_locations').doc(location.locationId).update(location.toMap());
  }

  // --- Safety Check-in Methods ---

  Future<void> triggerSafetyCheck(String title) async {
    final eventId = DateTime.now().millisecondsSinceEpoch.toString();
    
    // First, deactivate any previous active checks
    final activeChecks = await _db.collection('safety_checks').where('is_active', isEqualTo: true).get();
    for (var doc in activeChecks.docs) {
      await doc.reference.update({'is_active': false});
    }

    final event = SafetyCheckEvent(
      eventId: eventId,
      title: title,
      createdAt: DateTime.now(),
      isActive: true,
    );

    await _db.collection('safety_checks').doc(eventId).set(event.toMap());
  }

  Stream<SafetyCheckEvent?> getActiveSafetyCheck() {
    return _db
        .collection('safety_checks')
        .where('is_active', isEqualTo: true)
        .limit(1)
        .snapshots()
        .map((snapshot) {
      if (snapshot.docs.isEmpty) return null;
      return SafetyCheckEvent.fromMap(snapshot.docs.first.data());
    });
  }

  Future<void> submitSafetyResponse(SafetyResponse response) async {
    await _db.collection('safety_responses').doc('${response.eventId}_${response.userId}').set(response.toMap());
  }

  Stream<List<SafetyResponse>> getSafetyResponses(String eventId) {
    return _db
        .collection('safety_responses')
        .where('event_id', isEqualTo: eventId)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => SafetyResponse.fromMap(doc.data())).toList());
  }

  Future<void> deactivateSafetyCheck(String eventId) async {
    await _db.collection('safety_checks').doc(eventId).update({'is_active': false});
  }

  Stream<bool> hasUserResponded(String eventId, String userId) {
    return _db
        .collection('safety_responses')
        .doc('${eventId}_${userId}')
        .snapshots()
        .map((doc) => doc.exists);
  }

  // --- Hazard Reporting Methods ---

  Future<void> addHazard(HazardModel hazard) async {
    await _db.collection('hazards').doc(hazard.hazardId).set(hazard.toMap());
  }

  Future<void> reportHazard(HazardModel hazard) async => addHazard(hazard);

  Future<void> resolveHazard(String hazardId) async {
    await _db.collection('hazards').doc(hazardId).delete();
  }

  Future<void> deleteHazard(String hazardId) async {
    await _db.collection('hazards').doc(hazardId).delete();
  }

  Stream<List<HazardModel>> getHazards() {
    return _db
        .collection('hazards')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => HazardModel.fromMap(doc.data())).toList());
  }

  // --- Offline Sync Logic ---

  Future<void> syncOfflineVault() async {
    final offlineService = OfflineVaultService();
    
    // Fetch and cache Safe Zones
    final snapshot = await _db.collection('map_locations').where('type', isEqualTo: 'safeZone').get();
    final zones = snapshot.docs.map((doc) => MapLocationModel.fromMap(doc.data())).toList();
    await offlineService.cacheSafeZones(zones);
    
    // Optionally fetch guides from Firestore if you have a collection, 
    // otherwise it uses defaults in the service.
  }
}
