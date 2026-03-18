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
      backgroundColor: AppConstants.primaryRed,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              AppConstants.logoAsset,
              height: 120,
              color: Colors.white, // Tinting white for the red background
              errorBuilder: (context, error, stackTrace) => const Icon(
                Icons.security,
                size: 100,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'ResQnnect',
              style: TextStyle(
                color: Colors.white,
                fontSize: 32,
                fontWeight: FontWeight.bold,
                letterSpacing: 4,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'CADIZ CITY',
              style: TextStyle(
                color: Colors.white.withOpacity(0.8),
                fontSize: 14,
                letterSpacing: 8,
              ),
            ),
            const SizedBox(height: 60),
            const CircularProgressIndicator(
              color: Colors.white,
            ),
          ],
        ),
      ),
    );
  }
}
