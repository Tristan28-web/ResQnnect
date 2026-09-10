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
import 'package:flutter/services.dart';
import 'screens/report_screen.dart';

import 'services/location_service.dart';
import 'services/weather_service.dart';
import 'screens/onboarding_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    print('Firebase initialization failed: $e');
  }
  
  runApp(const GISApp());
}

class GISApp extends StatefulWidget {
  const GISApp({super.key});

  @override
  State<GISApp> createState() => _GISAppState();
}

class _GISAppState extends State<GISApp> with WidgetsBindingObserver {
  static const MethodChannel _sosChannel = MethodChannel('com.yummyjoy.resqnnect/sos');

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    
    // Listen for high-priority SOS triggers from hardware buttons (Accessibility Service)
    _sosChannel.setMethodCallHandler((call) async {
      if (call.method == 'triggerSOS') {
        _dispatchSOS();
      }
    });
  }

  void _dispatchSOS() {
    // Navigate to Incident Report Screen on emergency trigger
    navigatorKey.currentState?.push(
      MaterialPageRoute(builder: (_) => const ReportScreen()),
    );
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
                  
                  // Proactive Fallback System: 🌩️🛡️🚨✅
                  // Instead of waiting for Firestore (which can take seconds during slow networks), 
                  // we create a high-priority local model to ensure INSTANT dashboard entry.
                  UserModel initialModel;
                  
                  final userEmail = firebaseUser.email?.toLowerCase();
                  
                  if (firebaseUser.isAnonymous) {
                    initialModel = UserModel(
                      userId: firebaseUser.uid,
                      name: 'Guest Account',
                      email: 'guest@gis.local',
                      phone: '',
                      profileImage: '',
                      role: AppConstants.roleCitizen,
                      isVerified: true,
                      createdAt: DateTime.now(),
                    );
                  } else if (userEmail == 'admin@catanduanes.gov.ph' || 
                             userEmail == 'admin@cadiz.gov.ph' || 
                             userEmail?.contains('admin') == true) {
                    initialModel = UserModel(
                      userId: firebaseUser.uid,
                      name: firebaseUser.displayName ?? 'Catanduanes Admin',
                      email: userEmail ?? 'admin@catanduanes.gov.ph',
                      phone: '',
                      profileImage: firebaseUser.photoURL ?? '',
                      role: AppConstants.roleAdmin,
                      isVerified: true,
                      createdAt: DateTime.now(),
                    );
                  } else if (userEmail?.contains('responder') == true || 
                             userEmail?.contains('respondent') == true ||
                             userEmail?.contains('rescue') == true ||
                             userEmail?.contains('pnp') == true ||
                             userEmail?.contains('bfp') == true ||
                             userEmail == 'john@resqnnect.com') {
                    // 🛡️ High-Priority Responder Detection
                    initialModel = UserModel(
                      userId: firebaseUser.uid,
                      name: firebaseUser.displayName ?? 'Catanduanes Responder',
                      email: userEmail ?? '',
                      phone: '',
                      profileImage: firebaseUser.photoURL ?? '',
                      role: AppConstants.roleResponder,
                      isVerified: true,
                      createdAt: DateTime.now(),
                    );
                  } else {
                    // UNIVERSAL FALLBACK for Google and Registered Citizens
                    initialModel = UserModel(
                      userId: firebaseUser.uid,
                      name: firebaseUser.displayName ?? 'GIS User',
                      email: userEmail ?? '',
                      phone: '',
                      profileImage: firebaseUser.photoURL ?? '',
                      role: AppConstants.roleCitizen, // Default to citizen for instant access
                      isVerified: true, // Allow them to see dashboard while Firestore syncs
                      createdAt: DateTime.now(),
                    );
                  }

                  // We wrap the stream to emit the initialModel immediately while Firestore is loading
                  return firestore.getUserStream(firebaseUser.uid).map((doc) {
                    // Update the model once the real Firestore document arrives (contains real role/verified status)
                    if (doc != null) return doc;
                    return initialModel; 
                  });
                },
                initialData: null,
              ),
            ],
            child: MaterialApp(
              title: AppConstants.appName,
              theme: themeProvider.currentTheme,
              debugShowCheckedModeBanner: false,
              navigatorKey: navigatorKey,
              home: const AuthWrapper(),
              routes: {
                '/login': (context) => const LoginScreen(),
                '/onboarding': (context) => const OnboardingScreen(),
              },
            ),
          );
        },
      ),
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  Future<bool> _isOnboardingComplete() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('onboarding_complete') ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final firebaseUser = Provider.of<User?>(context);
    final userModel = Provider.of<UserModel?>(context);
    final authService = Provider.of<AuthService>(context, listen: false);

    if (firebaseUser == null) {
      return FutureBuilder<bool>(
        future: _isOnboardingComplete(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const SplashScreen();
          }
          if (snapshot.data == true) {
            return const LoginScreen();
          } else {
            return const OnboardingScreen();
          }
        },
      );
    }

    // While waiting for Firestore stream to arrive, we use a high-priority local fallback 🛡️🌩️✅
    // to ensure instantaneous redirection to the correct dashboard.
    final userEmail = firebaseUser.email?.toLowerCase();
    
    UserModel effectiveUser = userModel ?? UserModel(
      userId: firebaseUser.uid,
      name: firebaseUser.displayName ?? (userEmail?.contains('admin') == true ? 'Catanduanes Admin' : 'GIS User'),
      email: userEmail ?? 'guest@gis.local',
      role: userEmail == 'admin@catanduanes.gov.ph' || userEmail == 'admin@cadiz.gov.ph' || userEmail?.contains('admin') == true 
          ? AppConstants.roleAdmin 
          : (userEmail?.contains('responder') == true || 
             userEmail?.contains('respondent') == true ||
             userEmail?.contains('rescue') == true ||
             userEmail?.contains('pnp') == true ||
             userEmail?.contains('bfp') == true ||
             userEmail == 'john@resqnnect.com' 
               ? AppConstants.roleResponder 
               : AppConstants.roleCitizen),
      phone: '',
      profileImage: firebaseUser.photoURL ?? '',
      isVerified: true, // Allow instant access while Firestore syncs in background
      createdAt: DateTime.now(),
    );
 
    // Determine authorization using the effective user
    bool isAuthorized = effectiveUser.isVerified ||
        effectiveUser.role == AppConstants.roleAdmin ||
        effectiveUser.role == AppConstants.roleResponder ||
        userEmail == 'admin@catanduanes.gov.ph' ||
        userEmail == 'admin@cadiz.gov.ph' ||
        (userEmail?.contains('responder') == true);
 
    return isAuthorized
        ? const DashboardScreen()
        : const PendingVerificationScreen();
  }
}
