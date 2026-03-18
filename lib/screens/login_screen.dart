import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../core/constants.dart';
import '../models/user_model.dart';
import 'dashboard_screen.dart';
import 'pending_verification_screen.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  void _login() async {
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter email and password.')),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      await authService.login(
        _emailController.text.trim(),
        _passwordController.text.trim(),
      );

      // Navigation is now handled natively by the AuthWrapper in main.dart
      // When login returns, the Firebase auth stream emits, triggering AuthWrapper.
      // Firestore sync happens inside authService.login, ensuring profile exists.
    } on FirebaseAuthException catch (e) {
      String message = 'Login Failed.';
      if (e.code == 'user-not-found' || e.code == 'invalid-credential') {
        message = 'No user found with this email/incorrect credentials.';
      } else if (e.code == 'wrong-password') {
        message = 'Incorrect password.';
      } else if (e.code == 'user-not-found-in-firestore') {
        message = 'Authentication successful, but profile record is missing in database.';
      } else if (e.code == 'invalid-email') {
        message = 'The email address is not valid.';
      } else if (e.code == 'user-disabled') {
        message = 'This user account has been disabled.';
      }
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message)),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('An unexpected error occurred.')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _googleLogin() async {
    setState(() => _isLoading = true);
    final authService = Provider.of<AuthService>(context, listen: false);
    final result = await authService.signInWithGoogle();
    
    if (mounted) {
      setState(() => _isLoading = false);
      if (result == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Google Sign-In Cancelled or Failed.')),
        );
        // Navigation handled natively by AuthWrapper.
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 40),
              Center(
                child: Image.asset(
                  AppConstants.logoAsset,
                  height: 120,
                  errorBuilder: (context, error, stackTrace) => const Icon(
                    Icons.security_rounded,
                    size: 80,
                    color: AppConstants.primaryRed,
                  ),
                ),
              ),

              const SizedBox(height: 20),
              Text(
                'ResQnnect',
                style: Theme.of(context).textTheme.displayLarge?.copyWith(
                  letterSpacing: 4,
                  fontWeight: FontWeight.w900,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Smart Disaster Preparedness & Response',
                textAlign: TextAlign.center,
                style: TextStyle(color: isDark ? Colors.white54 : Colors.black54, letterSpacing: 1),
              ),
              const SizedBox(height: 48),
              TextField(
                controller: _emailController,
                decoration: InputDecoration(
                  labelText: 'Email',
                  prefixIcon: const Icon(Icons.email_outlined, color: AppConstants.primaryRed),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _passwordController,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: 'Password',
                  prefixIcon: const Icon(Icons.lock_outline, color: AppConstants.primaryRed),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _isLoading ? null : _login,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: _isLoading 
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      ) 
                    : const Text('LOGIN', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.2)),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(child: Divider(color: isDark ? Colors.white.withOpacity(0.1) : Colors.black.withOpacity(0.1))),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text('OR', style: TextStyle(color: isDark ? Colors.white54 : Colors.black54, fontSize: 12)),
                  ),
                  Expanded(child: Divider(color: isDark ? Colors.white.withOpacity(0.1) : Colors.black.withOpacity(0.1))),
                ],
              ),
              const SizedBox(height: 32),
              Text(
                'Not an Admin or Responder?',
                textAlign: TextAlign.center,
                style: TextStyle(color: isDark ? Colors.white54 : Colors.black54, fontSize: 13),
              ),
              const SizedBox(height: 4),
              Text(
                'Register as a Citizen',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: isDark ? Colors.white : Colors.black87,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1,
                ),
              ),
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: _isLoading ? null : _googleLogin,
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  side: BorderSide(color: isDark ? Colors.white.withOpacity(0.1) : Colors.black.withOpacity(0.1)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                icon: Image.network(
                  'https://upload.wikimedia.org/wikipedia/commons/thumb/c/c1/Google_\"G\"_logo.svg/1200px-Google_\"G\"_logo.svg.png',
                  height: 20,
                ),
                label: Text('Continue with Google', style: TextStyle(color: isDark ? Colors.white : Colors.black87, fontWeight: FontWeight.w600)),
              ),
              const SizedBox(height: 48),
            ],
          ),
        ),
      ),
    );
  }
}


