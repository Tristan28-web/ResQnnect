import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'core/theme.dart';
import 'core/constants.dart';
import 'services/auth_service.dart';
import 'services/firestore_service.dart';
import 'screens/dashboard_screen.dart';
import 'screens/login_screen.dart';
import 'screens/splash_screen.dart';
import 'screens/pending_verification_screen.dart';
import 'firebase_options.dart';
import 'core/localization.dart';
import 'models/user_model.dart';

import 'services/location_service.dart';
import 'services/weather_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    print('Firebase initialization failed: $e');
  }
  
  runApp(const ResQnnectApp());
}

class ResQnnectApp extends StatefulWidget {
  const ResQnnectApp({super.key});

  @override
  State<ResQnnectApp> createState() => _ResQnnectAppState();
}

class _ResQnnectAppState extends State<ResQnnectApp> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.detached) {
      // Force logout when app is destroyed/closed
      final authService = AuthService();
      authService.logout();
    }
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<ThemeProvider>(create: (_) => ThemeProvider()),
        ChangeNotifierProvider<LanguageProvider>(create: (_) => LanguageProvider()),
        Provider<AuthService>(create: (_) => AuthService()),
        Provider<FirestoreService>(create: (_) => FirestoreService()),
        Provider<WeatherService>(create: (_) => WeatherService()),
        Provider<LocationService>(create: (_) => LocationService()),
        // Provide the Firebase User stream globally
        StreamProvider<User?>(
          create: (context) => Provider.of<AuthService>(context, listen: false).userStream,
          initialData: null,
        ),
      ],
      child: Consumer2<ThemeProvider, User?>(
        builder: (context, themeProvider, firebaseUser, child) {
          return MultiProvider(
            providers: [
              // Identity Provider: Merges Firestore data with Admin Fallback logic
              StreamProvider<UserModel?>(
                key: ValueKey(firebaseUser?.uid),
                create: (context) {
                  if (firebaseUser == null) return Stream.value(null);
                  
                  final firestore = Provider.of<FirestoreService>(context, listen: false);
                  final auth = Provider.of<AuthService>(context, listen: false);
                  
                  return firestore.getUserStream(firebaseUser.uid).map((doc) {
                    if (doc != null) return doc;
                    
                    if (auth.currentUserEmail == 'admin@cadiz.gov.ph') {
                      return UserModel(
                        userId: firebaseUser.uid,
                        name: 'Admin User',
                        email: 'admin@cadiz.gov.ph',
                        phone: '',
                        profileImage: '',
                        role: AppConstants.roleAdmin,
                        createdAt: DateTime.now(),
                      );
                    }
                    return null;
                  });
                },
                initialData: null,
              ),
            ],
            child: MaterialApp(
              title: AppConstants.appName,
              theme: themeProvider.currentTheme,
              debugShowCheckedModeBanner: false,
              home: const AuthWrapper(),
            ),
          );
        },
      ),
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final firebaseUser = Provider.of<User?>(context);
    final userModel = Provider.of<UserModel?>(context);
    final authService = Provider.of<AuthService>(context, listen: false);

    if (firebaseUser == null) {
      return const LoginScreen();
    }

    // While waiting for either firestore doc or admin fallback to resolve
    if (userModel == null) {
      return const SplashScreen();
    }

    // Determine authorization
    bool isAuthorized = userModel.isVerified ||
        userModel.role == AppConstants.roleAdmin ||
        userModel.role == AppConstants.roleResponder ||
        authService.currentUserEmail == 'admin@cadiz.gov.ph' ||
        (authService.currentUserEmail?.contains('responder') == true) ||
        (authService.currentUserEmail?.contains('respondent') == true);

    return isAuthorized
        ? const DashboardScreen()
        : const PendingVerificationScreen();
  }
}
