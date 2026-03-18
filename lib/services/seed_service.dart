import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';
import '../models/alert_model.dart';
import '../models/incident_model.dart';
import '../models/sos_model.dart';
import '../core/constants.dart';

class SeedService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<void> seedAll() async {
    await seedAuthUsers();
    await seedAlerts();
    await seedIncidents();
    await seedSOS();
  }

  Future<void> seedAuthUsers() async {
    final authUsers = [
      {
        'email': 'admin@cadiz.gov.ph',
        'password': 'password123',
        'name': 'Cadiz City Admin',
        'phone': '09123456789',
        'role': 'admin',
      },
      {
        'email': 'respondent@cadiz.gov.ph',
        'password': 'password123',
        'name': 'City Respondent',
        'phone': '09987654321',
        'role': 'responder',
      },
    ];

    // Save the currently signed-in user so we can restore them
    final previousUser = _auth.currentUser;

    for (var u in authUsers) {
      try {
        // Try to CREATE the user in Firebase Auth
        UserCredential result = await _auth.createUserWithEmailAndPassword(
          email: u['email']!,
          password: u['password']!,
        );

        // Write to Firestore
        await _writeUserToFirestore(result.user!.uid, u);
        print('✅ Created and seeded user: ${u['email']}');

      } on FirebaseAuthException catch (e) {
        if (e.code == 'email-already-in-use') {
          print('ℹ️ User already exists: ${u['email']} — updating Firestore record...');
          // Sign in as this user to get UID and update their Firestore record
          try {
            final creds = await _auth.signInWithEmailAndPassword(
              email: u['email']!,
              password: u['password']!,
            );
            await _writeUserToFirestore(creds.user!.uid, u);
            print('✅ Updated Firestore for: ${u['email']}');
          } catch (signInErr) {
            print('❌ Could not sign in to update ${u['email']}: $signInErr');
          }
        } else {
          print('❌ Error creating ${u['email']}: ${e.message}');
        }
      }
    }

    // Re-sign in as the original user if they existed, otherwise sign out
    if (previousUser != null) {
      print('ℹ️ Seed complete. Admin account is now active session.');
    } else {
      await _auth.signOut();
    }
  }

  Future<void> _writeUserToFirestore(String uid, Map<String, String> u) async {
    final userModel = UserModel(
      userId: uid,
      name: u['name']!,
      email: u['email']!,
      phone: u['phone']!,
      profileImage: '',
      role: u['role']!,
      isActive: true,
      isVerified: true,
      createdAt: DateTime.now(),
    );
    await _db.collection(AppConstants.usersCollection).doc(uid).set(
      userModel.toMap(),
      SetOptions(merge: false), // Overwrite completely to fix any stale data
    );
  }


  Future<void> seedAlerts() async {
    final alerts = [
      AlertModel(
        alertId: 'alert_01',
        title: 'Heavy Rainfall Warning',
        description: 'Expect heavy rains in Cadiz City for the next 6 hours. Stay indoors.',
        disasterType: 'Weather',
        createdAt: DateTime.now(),
      ),
      AlertModel(
        alertId: 'alert_02',
        title: 'Nationwide Earthquake Drill',
        description: 'Participation in the quarterly earthquake drill is encouraged at 2 PM today.',
        disasterType: 'Drill',
        createdAt: DateTime.now().subtract(const Duration(hours: 5)),
      ),
    ];

    for (var alert in alerts) {
      await _db.collection(AppConstants.alertsCollection).doc(alert.alertId).set(alert.toMap());
    }
    print('Alerts seeded');
  }

  Future<void> seedIncidents() async {
    final incidents = [
      IncidentModel(
        incidentId: 'inc_01',
        userId: 'admin_01',
        description: 'Minor flooding observed near the city plaza.',
        imageUrl: 'https://via.placeholder.com/300',
        location: 'City Plaza, Cadiz',
        status: 'pending',
        timestamp: DateTime.now(),
      ),
      IncidentModel(
        incidentId: 'inc_02',
        userId: 'admin_01',
        description: 'Downed power line due to strong winds.',
        imageUrl: 'https://via.placeholder.com/300',
        location: 'Brgy 5, Cadiz',
        status: 'resolved',
        timestamp: DateTime.now().subtract(const Duration(days: 1)),
      ),
    ];

    for (var incident in incidents) {
      await _db.collection(AppConstants.incidentsCollection).doc(incident.incidentId).set(incident.toMap());
    }
    print('Incidents seeded');
  }

  Future<void> seedSOS() async {
    final sosRequests = [
      SOSRequestModel(
        sosId: 'sos_01',
        userId: 'responder_01',
        location: '10.9576, 123.3090',
        timestamp: DateTime.now(),
        status: 'active',
      ),
    ];

    for (var sos in sosRequests) {
      await _db.collection(AppConstants.sosCollection).doc(sos.sosId).set(sos.toMap());
    }
    print('SOS requests seeded');
  }
}


