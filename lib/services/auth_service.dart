import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../models/user_model.dart';
import '../core/constants.dart';
import 'google_sign_in_switcher.dart'; // Import the safe switcher

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  
  // Use dynamic to stay platform-neutral
  late final dynamic _googleSignIn;

  AuthService() {
    // We use the switcher to get the instance safely
    _googleSignIn = getGoogleSignInInstance();
  }

  // Stream of auth changes
  Stream<User?> get userStream => _auth.authStateChanges();

  // Register
  Future<UserCredential> register(String email, String password, String name, String phone) async {
    try {
      UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      User? user = result.user;
      
      if (user != null) {
        UserModel userModel = UserModel(
          userId: user.uid,
          name: name,
          email: email,
          phone: phone,
          profileImage: '',
          role: 'citizen',
          isActive: true,
          isVerified: false, // All new users need verification
          createdAt: DateTime.now(),
        );

        
        await _db.collection(AppConstants.usersCollection).doc(user.uid).set(userModel.toMap());
      }
      
      return result;
    } on FirebaseAuthException catch (e) {
      print('Firebase Auth Error: ${e.code} - ${e.message}');
      rethrow;
    } catch (e) {
      print('Register error: $e');
      rethrow;
    }
  }


  // Fixed Login: No longer forces logout if Firestore profile is missing
  Future<UserCredential> login(String email, String password) async {
    try {
      UserCredential creds = await _auth.signInWithEmailAndPassword(
        email: email, 
        password: password
      );

      // Ensure profile exists in Firestore
      await _syncUserProfile(creds.user);

      return creds;
    } on FirebaseAuthException catch (e) {
      print('Firebase Auth Error: ${e.code} - ${e.message}');
      rethrow;
    } catch (e) {
      print('Login error: $e');
      rethrow;
    }
  }

  // Google Sign-In
  Future<UserCredential?> signInWithGoogle() async {
    try {
      if (kIsWeb) {
        // Use Firebase Auth's native web support
        GoogleAuthProvider googleProvider = GoogleAuthProvider();
        final UserCredential userCredential = await _auth.signInWithPopup(googleProvider);
        await _syncUserProfile(userCredential.user);
        return userCredential;
      } else {
        // Using dynamic here to bypass compilation errors that occur on some web environments
        // when the compiler sees mobile-specific calls that the plugin might have hidden for web.
        final dynamic gUser = await (_googleSignIn as dynamic).signIn();
        if (gUser == null) return null;

        final dynamic gAuth = await gUser.authentication;
        
        final AuthCredential credential = GoogleAuthProvider.credential(
          idToken: gAuth.idToken,
        );

        final UserCredential userCredential = await _auth.signInWithCredential(credential);
        await _syncUserProfile(userCredential.user);
        
        return userCredential;
      }
    } catch (e) {
      print('Google Sign-In error: $e');
      return null;
    }
  }

  // Guest/Anonymous Login
  Future<UserCredential?> signInAnonymously() async {
    try {
      final UserCredential userCredential = await _auth.signInAnonymously();
      
      // Fire-and-forget profile sync so it doesn't block login completion
      _syncUserProfile(userCredential.user).catchError((e) {
        print('Background Profile Sync Error (Guest): $e');
      });
      
      return userCredential;
    } catch (e) {
      print('Anonymous Sign-In error: $e');
      rethrow; // Rethrow so UI can show message
    }
  }

  // Helper to sync user profile to Firestore
  Future<void> _syncUserProfile(User? user) async {
    if (user != null) {
      final userDoc = await _db.collection(AppConstants.usersCollection).doc(user.uid).get();
      
      String targetRole = AppConstants.roleCitizen;
      bool targetVerified = false;

      // Determine what the role SHOULD be based on email
      if (user.isAnonymous) {
        targetRole = AppConstants.roleCitizen;
        targetVerified = true; // Guests can use basic features immediately
      } else if (user.email == 'admin@catanduanes.gov.ph' || user.email == 'admin@cadiz.gov.ph' || user.email?.contains('admin') == true) {
        targetRole = AppConstants.roleAdmin;
        targetVerified = true;
      }

      if (!userDoc.exists) {
        UserModel userModel = UserModel(
          userId: user.uid,
          name: user.isAnonymous 
              ? 'Guest Account' 
              : (user.displayName ?? (targetRole == AppConstants.roleAdmin ? 'GIS Admin' : 'GIS User')),
          email: user.email ?? 'guest@gis.local',
          phone: '',
          profileImage: targetRole == AppConstants.roleAdmin ? '' : (user.photoURL ?? ''),
          role: targetRole,
          isActive: true,
          isVerified: targetVerified, 
          createdAt: DateTime.now(),
        );
        await _db.collection(AppConstants.usersCollection).doc(user.uid).set(userModel.toMap());
      } else {
        // If user already exists but role should be upgraded (e.g. they became admin)
        final currentData = userDoc.data()!;
        final currentRole = currentData['role'] ?? AppConstants.roleCitizen;
        
        // Auto-upgrade if email matches special pattern and they are currently a citizen
        if (targetRole != AppConstants.roleCitizen && currentRole == AppConstants.roleCitizen) {
          try {
            await _db.collection(AppConstants.usersCollection).doc(user.uid).update({
              'role': targetRole,
              'is_verified': true,
            });
          } catch (e) {
            print('Note: Could not auto-upgrade role in Firestore: $e');
          }
        }

        // Auto-clear admin profile image if present to enforce empty profile
        final isPrivileged = targetRole == AppConstants.roleAdmin;
        if (isPrivileged && (currentData['profile_image'] ?? '').toString().isNotEmpty) {
          try {
            await _db.collection(AppConstants.usersCollection).doc(user.uid).update({
              'profile_image': '',
            });
          } catch (_) {}
        }
      }
    }
  }


  // Logout
  Future<void> logout() async {
    try {
      if (!kIsWeb && _googleSignIn != null) {
        await _googleSignIn.signOut();
      }
    } catch (_) {}
    await _auth.signOut();
  }

  // Get current user email from Auth
  String? get currentUserEmail => _auth.currentUser?.email;

  // Get current user data

  Future<UserModel?> getCurrentUserData() async {
    User? user = _auth.currentUser;
    if (user != null) {
      DocumentSnapshot doc = await _db.collection(AppConstants.usersCollection).doc(user.uid).get();
      if (doc.exists) {
        return UserModel.fromMap(doc.data() as Map<String, dynamic>);
      }
    }
    return null;
  }
}
