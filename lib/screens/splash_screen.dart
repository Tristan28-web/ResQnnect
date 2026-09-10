import 'package:flutter/material.dart';
import 'dart:async';
import '../core/constants.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    // Simulate initial loading
    Timer(const Duration(seconds: 3), () {
      // Logic for navigation handled in main.dart wrapper
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F141C),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              AppConstants.logoAsset,
              height: 150,
              errorBuilder: (context, error, stackTrace) => const Icon(
                Icons.security,
                size: 100,
                color: AppConstants.primaryRed,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'GIS',
              style: TextStyle(
                color: Colors.white,
                fontSize: 36,
                fontWeight: FontWeight.w900,
                letterSpacing: 6,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'PROVINCE OF CATANDUANES',
              style: TextStyle(
                color: Colors.white.withOpacity(0.85),
                fontSize: 13,
                fontWeight: FontWeight.w600,
                letterSpacing: 4,
              ),
            ),
            const SizedBox(height: 60),
            const CircularProgressIndicator(
              color: AppConstants.primaryRed,
            ),
          ],
        ),
      ),
    );
  }
}
