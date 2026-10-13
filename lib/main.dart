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
import 'screens/identity_verification_screen.dart';
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

  // Custom ErrorWidget so any unexpected UI render error displays clearly rather than blank screen
  ErrorWidget.builder = (FlutterErrorDetails details) {
    return Material(
      color: const Color(0xFF14171F),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: SingleChildScrollView(
            child: Text(
              'Startup / Render Exception:\n\n${details.exceptionAsString()}\n\nStack:\n${details.stack}',
              style: const TextStyle(color: Colors.amberAccent, fontSize: 12, fontFamily: 'monospace'),
            ),
          ),
        ),
      ),
    );
  };

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    debugPrint('Firebase initialization with options failed: $e');
    try {
      // Native fallback on Android/iOS if options differ from google-services.json
      await Firebase.initializeApp();
    } catch (e2) {
      debugPrint('Firebase native fallback failed: $e2');
    }
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
        ChangeNotifierProvider<LocationService>(create: (_) => LocationService()),
        // Provide the Firebase User stream globally
        StreamProvider<User?>(
          create: (context) => Provider.of<AuthService>(context, listen: false).userStream,
          initialData: null,
          catchError: (_, __) => null,
        ),
      ],
      child: Consumer2<ThemeProvider, User?>(
        builder: (context, themeProvider, firebaseUser, child) {
          UserModel? initialModel;
          if (firebaseUser != null) {
            final userEmail = firebaseUser.email?.toLowerCase();
            if (userEmail == 'admin@catanduanes.gov.ph' ||
                userEmail == 'admin@cadiz.gov.ph' ||
                userEmail?.contains('admin') == true) {
              initialModel = UserModel(
                userId: firebaseUser.uid,
                name: firebaseUser.displayName ?? 'GeoSafe Admin',
                email: userEmail ?? 'admin@geosafe.gov.ph',
                phone: '',
                profileImage: '',
                role: AppConstants.roleAdmin,
                isVerified: true,
                createdAt: DateTime.now(),
              );
            } else {
              initialModel = UserModel(
                userId: firebaseUser.uid,
                name: firebaseUser.displayName ?? 'GeoSafe User',
                email: userEmail ?? '',
                phone: '',
                profileImage: firebaseUser.photoURL ?? '',
                role: AppConstants.roleCitizen,
                isVerified: false, // citizens must pass ID + face verification
                createdAt: DateTime.now(),
              );
            }
          }

          return MultiProvider(
            providers: [
              // Identity Provider: Merges Firestore data with Admin Fallback logic
              StreamProvider<UserModel?>(
                key: ValueKey(firebaseUser?.uid),
                create: (context) {
                  if (firebaseUser == null) return Stream.value(null);
                  
                  final firestore = Provider.of<FirestoreService>(context, listen: false);
                  
                  // We wrap the stream to emit the initialModel immediately while Firestore is loading
                  return firestore.getUserStream(firebaseUser.uid).map((doc) {
                    // Update the model once the real Firestore document arrives (contains real role/verified status)
                    if (doc != null) {
                      final isPrivileged = doc.role == AppConstants.roleAdmin ||
                          doc.email.contains('admin');
                      if (isPrivileged && doc.profileImage.isNotEmpty) {
                        // Reset admin profile image to empty string as requested
                        firestore.updateUserModel(doc.copyWith(profileImage: ''));
                        return doc.copyWith(profileImage: '');
                      }
                      return doc;
                    }
                    return initialModel; 
                  });
                },
                // Only admins get an instant fallback. A citizen waits for the real
                // Firestore document so verification status is never guessed.
                initialData: initialModel?.role == AppConstants.roleAdmin ? initialModel : null,
                catchError: (_, __) => null,
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

    // Anonymous (guest) sessions are no longer allowed: every citizen must be
    // ID-verified. Drop leftover guest sessions from older app versions.
    if (firebaseUser.isAnonymous) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Provider.of<AuthService>(context, listen: false).logout();
      });
      return const SplashScreen();
    }

    final userEmail = firebaseUser.email?.toLowerCase();
    final isAdminAccount = userModel?.role == AppConstants.roleAdmin ||
        userEmail == 'admin@catanduanes.gov.ph' ||
        userEmail == 'admin@cadiz.gov.ph' ||
        (userEmail?.contains('admin') == true);

    if (isAdminAccount) return const DashboardScreen();

    // Citizen: wait for the real Firestore profile before deciding anything.
    if (userModel == null) return const SplashScreen();

    if (userModel.isVerified) return const DashboardScreen();

    // Not verified yet: submitted → wait for LGU review, otherwise (never
    // submitted, or rejected) → ID + face verification.
    return userModel.verificationStatus == 'pending'
        ? const PendingVerificationScreen()
        : const IdentityVerificationScreen();
  }
}
