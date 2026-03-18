import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../core/constants.dart';
import 'login_screen.dart';

class PendingVerificationScreen extends StatelessWidget {
  const PendingVerificationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Container(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: isDark 
                ? [const Color(0xFF1E2841), AppConstants.backgroundBlack]
                : [const Color(0xFFE8F0FE), AppConstants.backgroundWhite],
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.verified_user_outlined,
                size: 80,
                color: Colors.orangeAccent,
              ),
            ),
            const SizedBox(height: 40),
            Text(
              'ACCOUNT PENDING',
              style: TextStyle(
                color: isDark ? Colors.white : Colors.black87,
                fontSize: 24,
                fontWeight: FontWeight.w900,
                letterSpacing: 2,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Your account is currently being reviewed by our administrators. This is to ensure the safety and authenticity of our community.',
              textAlign: TextAlign.center,
              style: TextStyle(color: isDark ? Colors.white54 : Colors.black54, fontSize: 16, height: 1.5),
            ),
            const SizedBox(height: 48),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.05),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: (isDark ? Colors.white : Colors.black).withOpacity(0.1)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, color: Colors.orangeAccent),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      'Verification usually takes 1-2 hours. You will gain full access once approved.',
                      style: TextStyle(color: isDark ? Colors.white70 : Colors.black87, fontSize: 14),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 48),
            ElevatedButton(
              onPressed: () async {
                try {
                  await Provider.of<AuthService>(context, listen: false).logout();
                  if (context.mounted) {
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(builder: (_) => LoginScreen()),
                      (route) => false,
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Logout failed: $e')),
                    );
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppConstants.primaryRed,
                minimumSize: const Size(double.infinity, 56),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: const Text('LOGOUT', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.5, color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }
}
