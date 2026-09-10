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

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            // Retro Top Bar with Tag and Skip Button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.retroDarkCard : Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isDark ? const Color(0xFF3E4556) : AppColors.retroDarkBorder,
                        width: 1.4,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 7,
                          height: 7,
                          decoration: const BoxDecoration(
                            color: Color(0xFF22C55E),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'LGU CATANDUANES GIS',
                          style: TextStyle(
                            color: isDark ? Colors.white : AppColors.retroDarkBorder,
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.8,
                          ),
                        ),
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: _completeOnboarding,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.retroDarkCard : AppColors.retroLilac,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: isDark ? const Color(0xFF3E4556) : AppColors.retroDarkBorder,
                          width: 1.4,
                        ),
                      ),
                      child: Text(
                        'SKIP',
                        style: TextStyle(
                          color: isDark ? Colors.white70 : AppColors.retroDarkBorder,
                          fontWeight: FontWeight.w900,
                          fontSize: 11,
                          letterSpacing: 0.6,
                        ),
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
                  _buildIntroStep(isDark),
                  _buildTermsStep(isDark),
                  _buildPermissionsStep(isDark),
                ],
              ),
            ),
            _buildFooter(isDark),
          ],
        ),
      ),
    );
  }

  // --- RETRO INTRO STEP ---
  Widget _buildIntroStep(bool isDark) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF2B2421) : AppColors.retroPeach,
              borderRadius: BorderRadius.circular(26),
              border: Border.all(
                color: isDark ? const Color(0xFF4A3C38) : AppColors.retroDarkBorder,
                width: 2.0,
              ),
              boxShadow: [
                BoxShadow(
                  color: isDark ? Colors.black45 : AppColors.retroMintDark,
                  offset: const Offset(4, 4),
                  blurRadius: 0,
                ),
              ],
            ),
            child: Column(
              children: [
                Container(
                  width: 100,
                  height: 100,
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppColors.retroDarkBorder,
                      width: 2.0,
                    ),
                  ),
                  child: ClipOval(
                    child: Image.asset(
                      AppConstants.logoAsset,
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  'Catanduanes GIS',
                  style: TextStyle(
                    color: isDark ? Colors.white : AppColors.retroDarkBorder,
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.retroLilac,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.retroDarkBorder, width: 1.2),
                  ),
                  child: const Text(
                    'INCIDENT MAPPING & PREDICTIVE LOGIC',
                    style: TextStyle(
                      color: AppColors.retroDarkBorder,
                      fontSize: 9,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.6,
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  'Centralized municipal portal for real-time incident reporting, GPS coordinate pinning, and predictive disaster tracking across Catanduanes island.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: isDark ? Colors.white70 : const Color(0xFF4B5563),
                    fontSize: 12,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          // Feature highlights
          Row(
            children: [
              Expanded(
                child: _buildFeaturePill(
                  icon: Icons.pin_drop_rounded,
                  label: 'GPS Pinning',
                  color: AppColors.retroPeach,
                  iconColor: const Color(0xFFEF4444),
                  isDark: isDark,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildFeaturePill(
                  icon: Icons.whatshot_rounded,
                  label: 'Hotspots AI',
                  color: AppColors.retroLilac,
                  iconColor: const Color(0xFFF97316),
                  isDark: isDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildFeaturePill(
                  icon: Icons.shield_rounded,
                  label: 'LGU Dispatch',
                  color: const Color(0xFFDCFCE7),
                  iconColor: const Color(0xFF16A34A),
                  isDark: isDark,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildFeaturePill(
                  icon: Icons.assessment_rounded,
                  label: 'Audit Reports',
                  color: const Color(0xFFDBEAFE),
                  iconColor: const Color(0xFF2563EB),
                  isDark: isDark,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFeaturePill({
    required IconData icon,
    required String label,
    required Color color,
    required Color iconColor,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.retroDarkCard : Colors.white,
        borderRadius: BorderRadius.circular(18),
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
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF262C38) : color,
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.retroDarkBorder, width: 1.2),
            ),
            child: Icon(icon, size: 16, color: isDark ? Colors.white : iconColor),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                color: isDark ? Colors.white : AppColors.retroDarkBorder,
                fontSize: 11,
                fontWeight: FontWeight.w900,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  // --- RETRO TERMS STEP ---
  Widget _buildTermsStep(bool isDark) {
    final terms = [
      {
        'num': '1',
        'title': 'Truthful Incident Reporting',
        'desc': 'You agree to submit authentic reports and accurate evidence to assist LGU command units.',
        'color': AppColors.retroPeach,
      },
      {
        'num': '2',
        'title': 'Geolocation & Map Pinning',
        'desc': 'The system pins your coordinate locations to route emergency responders efficiently.',
        'color': AppColors.retroLilac,
      },
      {
        'num': '3',
        'title': 'Data Privacy Compliance',
        'desc': 'All citizen data is safeguarded under RA 10173 (Data Privacy Act of 2012).',
        'color': const Color(0xFFDCFCE7),
      },
      {
        'num': '4',
        'title': 'LGU Multi-Agency Dispatch',
        'desc': 'Reports are triaged by authorized PNP, BFP, and CDRRMO emergency personnel.',
        'color': const Color(0xFFDBEAFE),
      },
    ];

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'TERMS & DATA CONSENT',
            style: TextStyle(
              color: isDark ? Colors.white : AppColors.retroDarkBorder,
              fontSize: 18,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Please review our provincial disaster management principles.',
            style: TextStyle(
              color: isDark ? Colors.white60 : const Color(0xFF6B7280),
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 16),
          ...terms.map((item) {
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: isDark ? AppColors.retroDarkCard : Colors.white,
                borderRadius: BorderRadius.circular(18),
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
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF262C38) : (item['color'] as Color),
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.retroDarkBorder, width: 1.4),
                    ),
                    child: Center(
                      child: Text(
                        item['num'] as String,
                        style: TextStyle(
                          color: isDark ? Colors.white : AppColors.retroDarkBorder,
                          fontWeight: FontWeight.w900,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item['title'] as String,
                          style: TextStyle(
                            color: isDark ? Colors.white : AppColors.retroDarkBorder,
                            fontSize: 13,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          item['desc'] as String,
                          style: TextStyle(
                            color: isDark ? Colors.white60 : const Color(0xFF6B7280),
                            fontSize: 11,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFFDCFCE7),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.retroDarkBorder, width: 1.4),
            ),
            child: const Row(
              children: [
                Icon(Icons.check_circle_rounded, color: Color(0xFF16A34A), size: 18),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'I agree to the LGU terms and disaster data protocol.',
                    style: TextStyle(
                      color: Color(0xFF15803D),
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- RETRO PERMISSIONS STEP ---
  Widget _buildPermissionsStep(bool isDark) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'DEVICE PERMISSIONS',
            style: TextStyle(
              color: isDark ? Colors.white : AppColors.retroDarkBorder,
              fontSize: 18,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Enable these permissions for live interactive GIS navigation.',
            style: TextStyle(
              color: isDark ? Colors.white60 : const Color(0xFF6B7280),
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 16),
          _buildRetroPermissionCard(
            icon: Icons.location_on_rounded,
            title: 'GPS Location Access',
            subtitle: 'Enables precise coordinate pinning on Catanduanes maps.',
            isGranted: _locationAllowed,
            accentColor: AppColors.retroPeach,
            iconColor: const Color(0xFFEF4444),
            onTap: _requestLocationPermission,
            isDark: isDark,
          ),
          const SizedBox(height: 12),
          _buildRetroPermissionCard(
            icon: Icons.notifications_active_rounded,
            title: 'Push Notifications',
            subtitle: 'Receive real-time LGU disaster alerts & responder dispatch updates.',
            isGranted: _notificationsAllowed,
            accentColor: AppColors.retroLilac,
            iconColor: const Color(0xFF7C3AED),
            onTap: _requestNotificationPermission,
            isDark: isDark,
          ),
          const SizedBox(height: 12),
          _buildRetroPermissionCard(
            icon: Icons.camera_alt_rounded,
            title: 'Camera Access (Optional)',
            subtitle: 'Capture and attach photo evidence to your incident reports.',
            isGranted: _cameraAllowed,
            accentColor: const Color(0xFFDCFCE7),
            iconColor: const Color(0xFF16A34A),
            onTap: _requestCameraPermission,
            isDark: isDark,
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: isDark ? AppColors.retroDarkCard : Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isDark ? const Color(0xFF3E4556) : AppColors.retroDarkBorder,
                width: 1.4,
              ),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline_rounded, color: AppColors.retroMint, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Permissions can be granted inside the app anytime.',
                    style: TextStyle(
                      color: isDark ? Colors.white70 : AppColors.retroDarkBorder,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRetroPermissionCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool isGranted,
    required Color accentColor,
    required Color iconColor,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    final statusBg = isGranted ? const Color(0xFFDCFCE7) : AppColors.retroPeach;
    final statusText = isGranted ? const Color(0xFF16A34A) : const Color(0xFFD97706);
    final statusLabel = isGranted ? 'ALLOWED' : 'TAP TO ENABLE';

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? AppColors.retroDarkCard : Colors.white,
          borderRadius: BorderRadius.circular(20),
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
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF262C38) : accentColor,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.retroDarkBorder, width: 1.4),
              ),
              child: Center(
                child: Icon(icon, color: isDark ? Colors.white : iconColor, size: 22),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: isDark ? Colors.white : AppColors.retroDarkBorder,
                      fontWeight: FontWeight.w900,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: isDark ? Colors.white60 : const Color(0xFF6B7280),
                      fontSize: 11,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: statusBg,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.retroDarkBorder, width: 1.2),
              ),
              child: Text(
                statusLabel,
                style: TextStyle(
                  color: statusText,
                  fontSize: 9,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.5,
                ),
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

  // --- RETRO FOOTER ---
  Widget _buildFooter(bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Retro Indicator Pills
          Row(
            children: List.generate(3, (index) {
              final isActive = _currentPage == index;
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 3),
                width: isActive ? 28 : 10,
                height: 10,
                decoration: BoxDecoration(
                  color: isActive
                      ? AppColors.retroMint
                      : (isDark ? const Color(0xFF2E3544) : const Color(0xFFE5E7EB)),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: isActive
                        ? AppColors.retroDarkBorder
                        : (isDark ? Colors.white12 : AppColors.retroDarkBorder.withOpacity(0.3)),
                    width: 1.2,
                  ),
                ),
              );
            }),
          ),
          GestureDetector(
            onTap: _onNextPressed,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.retroMint,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: AppColors.retroDarkBorder,
                  width: 1.8,
                ),
                boxShadow: [
                  BoxShadow(
                    color: isDark ? Colors.black45 : AppColors.retroDarkBorder.withOpacity(0.15),
                    offset: const Offset(3, 3),
                    blurRadius: 0,
                  ),
                ],
              ),
              child: Text(
                _currentPage == 2 ? 'GET STARTED' : 'CONTINUE',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: 12,
                  letterSpacing: 0.8,
                ),
              ),
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
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_complete', true);
    
    if (mounted) {
      Navigator.pushReplacementNamed(context, '/login');
    }
  }
}
