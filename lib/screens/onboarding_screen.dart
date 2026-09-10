import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:app_settings/app_settings.dart';
import '../core/constants.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  bool _notificationsAllowed = false;
  bool _accessibilityInstructionsRead = false;
  bool _flashAllowed = false;
  bool _smsAllowed = false;

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
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
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
              letterSpacing: 2,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Text(
            'The official emergency response and disaster preparedness platform for the Province of Catanduanes. Empowering citizens and responders to stay connected during critical moments.',
            style: TextStyle(
              color: textColor.withOpacity(0.7),
              fontSize: 16,
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
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: textColor.withOpacity(0.05),
                borderRadius: BorderRadius.circular(12),
              ),
              child: SingleChildScrollView(
                child: Text(
                  '1. User Agreement: By using GIS, you agree to provide accurate information during emergencies to ensure efficient dispatch.\n\n'
                  '2. Google Terms: This app utilizes Google Maps and Google Authentication. By proceeding, you agree to Google\'s Terms of Service and Privacy Policy.\n\n'
                  '3. Data Collection: We collect essential contact information (name, phone number, location) to facilitate emergency assistance. This data is handled with strict confidentiality and used only for safety purposes in coordination with Catanduanes authorities.\n\n'
                  '4. Emergency Responsibility: While GIS facilitates connection, the user remains responsible for following local safety guidelines issued by official channels.\n\n'
                  '5. Gesture Controls: Our SOS gesture feature requires accessibility setup to detect emergency triggers accurately even when the screen is locked.',
                  style: TextStyle(
                    color: textColor.withOpacity(0.8),
                    fontSize: 14,
                    height: 1.5,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Icon(Icons.check_circle, color: AppConstants.primaryRed, size: 20),
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
            'Enable these to ensure your safety features work correctly.',
            style: TextStyle(color: textColor.withOpacity(0.6), fontSize: 14),
          ),
          const SizedBox(height: 32),
          _buildPermissionTile(
            icon: Icons.notifications_active,
            title: 'Push Notifications',
            subtitle: 'Receive instant emergency alerts and dispatch updates.',
            status: _notificationsAllowed ? 'Allowed' : 'Not Allowed',
            onTap: _requestNotificationPermission,
            textColor: textColor,
          ),
          const SizedBox(height: 20),
          _buildPermissionTile(
            icon: Icons.gesture,
            title: 'Accessibility Service',
            subtitle: 'Required for the SOS gesture (e.g., volume button trigger).',
            status: _accessibilityInstructionsRead ? 'Ready' : 'Setup Required',
            onTap: _requestAccessibilityPermission,
            textColor: textColor,
          ),
          const SizedBox(height: 20),
          _buildPermissionTile(
            icon: Icons.flashlight_on_rounded,
            title: 'Emergency Flash',
            subtitle: 'Allows the app to flash the camera light during alerts.',
            status: _flashAllowed ? 'Allowed' : 'Not Allowed',
            onTap: _requestFlashPermission,
            textColor: textColor,
          ),
          const SizedBox(height: 20),
          _buildPermissionTile(
            icon: Icons.sms_rounded,
            title: 'Emergency Messaging',
            subtitle: 'Auto-sends SOS alerts and location links to your inner circle.',
            status: _smsAllowed ? 'Allowed' : 'Not Allowed',
            onTap: _requestSMSPermission,
            textColor: textColor,
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppConstants.primaryRed.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppConstants.primaryRed.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, color: AppConstants.primaryRed),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Permissions are essential for real-time safety monitoring in Catanduanes.',
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
    required VoidCallback onTap,
    required Color textColor,
  }) {
    final statusColor = status == 'Allowed' || status == 'Ready' ? Colors.green : AppConstants.primaryRed;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: textColor.withOpacity(0.1)),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppConstants.primaryRed.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: AppConstants.primaryRed),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(color: textColor.withOpacity(0.6), fontSize: 12),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.1),
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

  Future<void> _requestNotificationPermission() async {
    // First try standard request
    final status = await Permission.notification.request();
    if (status.isGranted) {
      setState(() {
        _notificationsAllowed = true;
      });
    } else {
      // If permanently denied or user prefers settings, open directly
      await AppSettings.openAppSettings(type: AppSettingsType.notification);
      // We check again after they return
      final newStatus = await Permission.notification.status;
      if (newStatus.isGranted) {
        setState(() => _notificationsAllowed = true);
      }
    }
  }

  Future<void> _requestAccessibilityPermission() async {
    // Open accessibility settings
    await AppSettings.openAppSettings(type: AppSettingsType.accessibility);
    // Mark as ready since we can't reliably check if they actually enabled it without specialized plugins,
    // but the redirection is what was requested.
     setState(() {
      _accessibilityInstructionsRead = true;
    });
  }

  Future<void> _requestFlashPermission() async {
    final status = await Permission.camera.request();
    if (status.isGranted) {
      setState(() => _flashAllowed = true);
    } else if (status.isPermanentlyDenied) {
      await openAppSettings();
    }
  }

  Future<void> _requestSMSPermission() async {
    final status = await Permission.sms.request();
    if (status.isGranted) {
      setState(() => _smsAllowed = true);
    } else if (status.isPermanentlyDenied) {
      await openAppSettings();
    }
  }

  Widget _buildFooter(Color textColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
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
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: Text(_currentPage == 2 ? 'GET STARTED' : 'CONTINUE'),
          ),
        ],
      ),
    );
  }

  void _onNextPressed() async {
    if (_currentPage < 2) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    } else {
      if (!_notificationsAllowed || !_accessibilityInstructionsRead || !_flashAllowed || !_smsAllowed) {
         ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please allow all permissions (including Messaging) to proceed to secure rescue mode.')),
        );
        return;
      }
      
      // Save onboarding complete status
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('onboarding_complete', true);
      
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/login');
      }
    }
  }
}
