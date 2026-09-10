import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:permission_handler/permission_handler.dart';
import '../core/constants.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  bool _locationAllowed = false;
  bool _notificationsAllowed = false;
  bool _cameraAllowed = false;

  @override
  void initState() {
    super.initState();
    _checkInitialPermissions();
  }

  Future<void> _checkInitialPermissions() async {
    final locStatus = await Permission.location.status;
    final notifStatus = await Permission.notification.status;
    final camStatus = await Permission.camera.status;

    if (mounted) {
      setState(() {
        _locationAllowed = locStatus.isGranted;
        _notificationsAllowed = notifStatus.isGranted;
        _cameraAllowed = camStatus.isGranted;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDark ? AppConstants.backgroundBlack : AppConstants.backgroundWhite;
    final textColor = isDark ? Colors.white : Colors.black87;

    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            // Top Bar with Skip Button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'GIS CATANDUANES',
                    style: TextStyle(
                      color: AppConstants.primaryRed,
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.2,
                    ),
                  ),
                  TextButton(
                    onPressed: _completeOnboarding,
                    child: Text(
                      'SKIP',
                      style: TextStyle(
                        color: textColor.withOpacity(0.5),
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const BouncingScrollPhysics(),
                onPageChanged: (int page) {
                  setState(() {
                    _currentPage = page;
                  });
                },
                children: [
                  _buildIntroStep(textColor),
                  _buildTermsStep(textColor),
                  _buildPermissionsStep(textColor),
                ],
              ),
            ),
            _buildFooter(textColor),
          ],
        ),
      ),
    );
  }

  Widget _buildIntroStep(Color textColor) {
    return Padding(
      padding: const EdgeInsets.all(32.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset(
            AppConstants.logoAsset,
            height: 140,
          ),
          const SizedBox(height: 28),
          Text(
            'Welcome to GIS',
            style: TextStyle(
              color: textColor,
              fontSize: 28,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Text(
            'GIS-Powered Incident Mapping and Predictive Logic System for Local Government Unit of Catanduanes.\n\nCentralized platform for real-time incident reporting, GPS pinning, and community hazard tracking.',
            style: TextStyle(
              color: textColor.withOpacity(0.7),
              fontSize: 15,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildTermsStep(Color textColor) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Terms & Consent',
            style: TextStyle(
              color: textColor,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: textColor.withOpacity(0.04),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: textColor.withOpacity(0.08)),
              ),
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Text(
                  '1. Accurate Reporting: By using GIS, you agree to submit truthful incident reports and coordinates to assist LGU dispatchers.\n\n'
                  '2. Geolocation Mapping: The app utilizes GPS positioning to pin incident locations accurately across Catanduanes municipalities.\n\n'
                  '3. Data Privacy: Your personal data is protected under Republic Act 10173 (Data Privacy Act of 2012) and used strictly for disaster risk reduction and emergency response.\n\n'
                  '4. LGU Coordination: Reports are monitored by authorized provincial and municipal emergency command units.',
                  style: TextStyle(
                    color: textColor.withOpacity(0.8),
                    fontSize: 13,
                    height: 1.6,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.green, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'I agree to the Terms of Service and data consent.',
                  style: TextStyle(color: textColor.withOpacity(0.7), fontSize: 13),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPermissionsStep(Color textColor) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Device Permissions',
            style: TextStyle(
              color: textColor,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Enable these permissions for real-time GIS mapping and advisories.',
            style: TextStyle(color: textColor.withOpacity(0.6), fontSize: 13),
          ),
          const SizedBox(height: 24),
          _buildPermissionTile(
            icon: Icons.location_on_rounded,
            title: 'GPS Location',
            subtitle: 'Enables precise incident pinning on Catanduanes maps.',
            status: _locationAllowed ? 'Allowed' : 'Tap to Enable',
            isGranted: _locationAllowed,
            onTap: _requestLocationPermission,
            textColor: textColor,
          ),
          const SizedBox(height: 16),
          _buildPermissionTile(
            icon: Icons.notifications_active_rounded,
            title: 'Push Notifications',
            subtitle: 'Receive real-time LGU disaster alerts and dispatch updates.',
            status: _notificationsAllowed ? 'Allowed' : 'Tap to Enable',
            isGranted: _notificationsAllowed,
            onTap: _requestNotificationPermission,
            textColor: textColor,
          ),
          const SizedBox(height: 16),
          _buildPermissionTile(
            icon: Icons.camera_alt_rounded,
            title: 'Camera Access (Optional)',
            subtitle: 'Allows capturing photo evidence when submitting reports.',
            status: _cameraAllowed ? 'Allowed' : 'Tap to Enable',
            isGranted: _cameraAllowed,
            onTap: _requestCameraPermission,
            textColor: textColor,
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.08),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.green.withOpacity(0.2)),
            ),
            child: Row(
              children: [
                const Icon(Icons.check_circle_outline, color: Colors.green, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'You can proceed immediately. Missing permissions can be granted inside the app anytime.',
                    style: TextStyle(color: textColor.withOpacity(0.8), fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPermissionTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required String status,
    required bool isGranted,
    required VoidCallback onTap,
    required Color textColor,
  }) {
    final statusColor = isGranted ? Colors.green : AppConstants.primaryRed;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: textColor.withOpacity(0.1)),
          borderRadius: BorderRadius.circular(16),
          color: isGranted ? Colors.green.withOpacity(0.04) : null,
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: statusColor, size: 22),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(color: textColor.withOpacity(0.6), fontSize: 11),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.12),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                status,
                style: TextStyle(color: statusColor, fontSize: 11, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _requestLocationPermission() async {
    final status = await Permission.location.request();
    if (status.isGranted) {
      setState(() => _locationAllowed = true);
    }
  }

  Future<void> _requestNotificationPermission() async {
    final status = await Permission.notification.request();
    if (status.isGranted) {
      setState(() => _notificationsAllowed = true);
    }
  }

  Future<void> _requestCameraPermission() async {
    final status = await Permission.camera.request();
    if (status.isGranted) {
      setState(() => _cameraAllowed = true);
    }
  }

  Widget _buildFooter(Color textColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: List.generate(3, (index) {
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 4),
                width: _currentPage == index ? 24 : 8,
                height: 8,
                decoration: BoxDecoration(
                  color: _currentPage == index ? AppConstants.primaryRed : textColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(4),
                ),
              );
            }),
          ),
          ElevatedButton(
            onPressed: _onNextPressed,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppConstants.primaryRed,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              elevation: 4,
            ),
            child: Text(
              _currentPage == 2 ? 'GET STARTED' : 'CONTINUE',
              style: const TextStyle(fontWeight: FontWeight.bold, letterSpacing: 0.8),
            ),
          ),
        ],
      ),
    );
  }

  void _onNextPressed() {
    if (_currentPage < 2) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOut,
      );
    } else {
      _completeOnboarding();
    }
  }

  Future<void> _completeOnboarding() async {
    // Save onboarding complete status
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_complete', true);
    
    if (mounted) {
      Navigator.pushReplacementNamed(context, '/login');
    }
  }
}
