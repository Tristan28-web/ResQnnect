import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';
import '../core/constants.dart';
import 'dashboard_screen.dart';
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

      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const DashboardScreen()),
          (route) => false,
        );
      }
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
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message)),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('An unexpected error occurred.')),
        );
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
      } else {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const DashboardScreen()),
          (route) => false,
        );
      }
    }
  }

  void _guestLogin() async {
    setState(() => _isLoading = true);
    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      await authService.signInAnonymously();

      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const DashboardScreen()),
          (route) => false,
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        final errorStr = e.toString();
        if (errorStr.contains('admin-restricted-operation') || 
            errorStr.contains('operation-not-allowed')) {
          _showGuestLoginDisabledDialog();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Guest Login Failed: $errorStr'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  void _showGuestLoginDisabledDialog() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? AppColors.retroDarkCard : Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: AppColors.retroDarkBorder, width: 2),
        ),
        title: Row(
          children: [
            const Icon(Icons.lock_outline, color: Color(0xFFEF4444)),
            const SizedBox(width: 10),
            Text('Guest Login Unavailable',
              style: TextStyle(
                color: isDark ? Colors.white : AppColors.retroDarkBorder,
                fontWeight: FontWeight.w900,
                fontSize: 16,
              ),
            ),
          ],
        ),
        content: Text(
          'Anonymous sign-in is not yet enabled for this app.\n\n'
          'To fix this:\n'
          '1. Go to Firebase Console\n'
          '2. Navigate to Authentication → Sign-in method\n'
          '3. Enable "Anonymous" provider\n\n'
          'Alternatively, you can register as a Citizen or use Google Sign-In.',
          style: TextStyle(
            color: isDark ? Colors.white70 : const Color(0xFF4B5563),
            fontSize: 13,
            height: 1.5,
          ),
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.retroMint,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
                side: const BorderSide(color: AppColors.retroDarkBorder, width: 1.4),
              ),
            ),
            onPressed: () => Navigator.pop(context),
            child: const Text('CLOSE', style: TextStyle(fontWeight: FontWeight.w900)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 20),
              Center(
                child: Container(
                  width: 100,
                  height: 100,
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppColors.retroDarkBorder,
                      width: 2.0,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: isDark ? Colors.black45 : AppColors.retroMintDark,
                        offset: const Offset(3, 3),
                        blurRadius: 0,
                      ),
                    ],
                  ),
                  child: ClipOval(
                    child: Image.asset(
                      AppConstants.logoAsset,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) => const Icon(
                        Icons.shield_rounded,
                        size: 50,
                        color: AppColors.retroMint,
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 18),
              Text(
                'RESQNNECT GIS',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.5,
                  color: isDark ? Colors.white : AppColors.retroDarkBorder,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                'Incident Mapping & Predictive Logic System',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: isDark ? Colors.white60 : const Color(0xFF6B7280),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 32),

              // Form Box
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.retroDarkCard : Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: isDark ? const Color(0xFF3E4556) : AppColors.retroDarkBorder,
                    width: 1.8,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: isDark ? Colors.black45 : AppColors.retroDarkBorder.withOpacity(0.12),
                      offset: const Offset(3, 3),
                      blurRadius: 0,
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    TextField(
                      controller: _emailController,
                      style: TextStyle(color: isDark ? Colors.white : AppColors.retroDarkBorder, fontWeight: FontWeight.w600),
                      decoration: InputDecoration(
                        labelText: 'Email Address',
                        labelStyle: TextStyle(color: isDark ? Colors.white60 : const Color(0xFF6B7280), fontSize: 13),
                        prefixIcon: const Icon(Icons.email_rounded, color: AppColors.retroMint, size: 20),
                        filled: true,
                        fillColor: isDark ? const Color(0xFF262C38) : const Color(0xFFF9FAFB),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide(
                            color: isDark ? const Color(0xFF3E4556) : AppColors.retroDarkBorder,
                            width: 1.4,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: const BorderSide(color: AppColors.retroMint, width: 2.0),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      controller: _passwordController,
                      obscureText: true,
                      style: TextStyle(color: isDark ? Colors.white : AppColors.retroDarkBorder, fontWeight: FontWeight.w600),
                      decoration: InputDecoration(
                        labelText: 'Password',
                        labelStyle: TextStyle(color: isDark ? Colors.white60 : const Color(0xFF6B7280), fontSize: 13),
                        prefixIcon: const Icon(Icons.lock_rounded, color: AppColors.retroMint, size: 20),
                        filled: true,
                        fillColor: isDark ? const Color(0xFF262C38) : const Color(0xFFF9FAFB),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide(
                            color: isDark ? const Color(0xFF3E4556) : AppColors.retroDarkBorder,
                            width: 1.4,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: const BorderSide(color: AppColors.retroMint, width: 2.0),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: _isLoading ? null : _login,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.retroMint,
                        foregroundColor: Colors.white,
                        minimumSize: const Size(double.infinity, 50),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                          side: const BorderSide(color: AppColors.retroDarkBorder, width: 1.6),
                        ),
                      ),
                      child: _isLoading 
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                            ) 
                          : const Text('LOGIN TO GIS', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1.0)),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(child: Divider(color: isDark ? Colors.white24 : AppColors.retroDarkBorder.withOpacity(0.2))),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Text(
                      'OR CONTINUE WITH',
                      style: TextStyle(
                        color: isDark ? Colors.white54 : const Color(0xFF6B7280),
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.0,
                      ),
                    ),
                  ),
                  Expanded(child: Divider(color: isDark ? Colors.white24 : AppColors.retroDarkBorder.withOpacity(0.2))),
                ],
              ),
              const SizedBox(height: 20),

              // Retro Social / Secondary Buttons
              GestureDetector(
                onTap: _isLoading ? null : _guestLogin,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.retroDarkCard : AppColors.retroPeach,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isDark ? const Color(0xFF3E4556) : AppColors.retroDarkBorder,
                      width: 1.6,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: isDark ? Colors.black38 : AppColors.retroDarkBorder.withOpacity(0.08),
                        offset: const Offset(2, 2),
                        blurRadius: 0,
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      'CONTINUE AS GUEST',
                      style: TextStyle(
                        color: isDark ? Colors.white : AppColors.retroDarkBorder,
                        fontWeight: FontWeight.w900,
                        fontSize: 12,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              GestureDetector(
                onTap: _isLoading ? null : _googleLogin,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.retroDarkCard : Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isDark ? const Color(0xFF3E4556) : AppColors.retroDarkBorder,
                      width: 1.6,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: isDark ? Colors.black38 : AppColors.retroDarkBorder.withOpacity(0.08),
                        offset: const Offset(2, 2),
                        blurRadius: 0,
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Image.network(
                        'https://upload.wikimedia.org/wikipedia/commons/thumb/c/c1/Google_"G"_logo.svg/1200px-Google_"G"_logo.svg.png',
                        height: 18,
                        errorBuilder: (_, error, stackTrace) => const Icon(Icons.g_mobiledata, size: 22),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Continue with Google',
                        style: TextStyle(
                          color: isDark ? Colors.white : AppColors.retroDarkBorder,
                          fontWeight: FontWeight.w800,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Need a citizen account? ',
                    style: TextStyle(
                      color: isDark ? Colors.white60 : const Color(0xFF6B7280),
                      fontSize: 12,
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const RegisterScreen()),
                      );
                    },
                    child: const Text(
                      'Register Here',
                      style: TextStyle(
                        color: AppColors.retroMint,
                        fontWeight: FontWeight.w900,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }
}
