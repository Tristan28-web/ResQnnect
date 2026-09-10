import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../core/constants.dart';
import '../models/user_model.dart';
import 'citizen_dashboard.dart';
import 'admin_dashboard.dart';
import 'responder_dashboard.dart';
import 'profile_screen.dart';
import 'alerts_screen.dart';
import 'incident_mapping_screen.dart';
import 'predictive_analysis_screen.dart';
import 'lgu_user_management_screen.dart';
import '../core/theme.dart';
import '../widgets/profile_image.dart';
import '../services/location_service.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<UserModel?>(context);
    final authService = Provider.of<AuthService>(context, listen: false);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    String role = user?.role ?? AppConstants.roleCitizen;
    final email = authService.currentUserEmail?.toLowerCase() ?? '';
    
    if (email == 'admin@catanduanes.gov.ph' || email == 'admin@cadiz.gov.ph' || email.contains('admin')) {
      role = AppConstants.roleAdmin;
    } else if (email.contains('responder') || email.contains('respondent') || email == 'john@resqnnect.com' || email.contains('rescue') || email.contains('pnp') || email.contains('bfp')) {
      role = AppConstants.roleResponder;
    }

    return Scaffold(
      backgroundColor: isDark ? AppConstants.backgroundBlack : AppConstants.retroCream,
      body: SafeArea(
        child: Column(
          children: [
            _buildRetroHeader(context, role, user, authService, isDark),
            Expanded(
              child: _buildBody(role),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _buildRetroBottomNav(context, role, isDark),
    );
  }

  Widget _buildRetroHeader(BuildContext context, String role, UserModel? user, AuthService authService, bool isDark) {
    final textColor = isDark ? Colors.white : AppConstants.retroDarkBorder;
    final borderColor = isDark ? Colors.white.withOpacity(0.15) : AppConstants.retroDarkBorder;
    final surfaceColor = isDark ? AppConstants.retroDarkCard : Colors.white;

    String displayName = user?.name.isNotEmpty == true 
        ? user!.name 
        : (role == AppConstants.roleAdmin ? 'GIS Admin' : (role == AppConstants.roleResponder ? 'Field Responder' : 'Citizen'));

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Left: Avatar + Name + Location Subtitle (Matching Retro UI Header)
          Row(
            children: [
              GestureDetector(
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfileScreen())),
                child: Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: surfaceColor,
                    shape: BoxShape.circle,
                    border: Border.all(color: borderColor, width: 1.5),
                    boxShadow: [
                      BoxShadow(
                        color: isDark ? Colors.black26 : borderColor.withOpacity(0.12),
                        offset: const Offset(2, 2),
                        blurRadius: 0,
                      )
                    ],
                  ),
                  child: ClipOval(
                    child: ProfileImage(
                      source: user?.profileImage,
                      radius: 23,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    displayName,
                    style: TextStyle(
                      color: textColor,
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.2,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Consumer<LocationService>(
                    builder: (context, locService, _) {
                      return GestureDetector(
                        onTap: () => locService.refreshLocation(),
                        child: Row(
                          children: [
                            Icon(Icons.location_on_rounded, size: 12, color: AppConstants.retroMint),
                            const SizedBox(width: 3),
                            Text(
                              locService.currentLocationName,
                              style: TextStyle(
                                color: isDark ? Colors.white60 : textColor.withOpacity(0.6),
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ],
              ),
            ],
          ),

          // Right: Theme Toggle & Logo Crest
          Row(
            children: [
              Consumer<ThemeProvider>(
                builder: (context, themeProvider, child) {
                  return GestureDetector(
                    onTap: () => themeProvider.toggleTheme(),
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: surfaceColor,
                        shape: BoxShape.circle,
                        border: Border.all(color: borderColor, width: 1.5),
                        boxShadow: [
                          BoxShadow(
                            color: isDark ? Colors.black26 : borderColor.withOpacity(0.1),
                            offset: const Offset(2, 2),
                            blurRadius: 0,
                          )
                        ],
                      ),
                      child: Icon(
                        themeProvider.isDarkMode ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
                        color: textColor,
                        size: 20,
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(width: 10),
              SizedBox(
                width: 38,
                height: 38,
                child: Image.asset(
                  AppConstants.logoAsset,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) => Icon(Icons.shield_rounded, color: AppConstants.primaryRed, size: 20),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBody(String role) {
    switch (_selectedIndex) {
      case 1:
        // Module 02 & 03: GIS Incident Mapping & Pinning
        return const IncidentMappingScreen();
      case 2:
        // Module 06 & 09: Predictive Analysis & Forecasting
        return const PredictiveAnalysisScreen();
      case 3:
        // Module 08: Notifications and Alerts
        return const AlertsScreen();
      case 4:
        // Module 10: User Management / Profile
        if (role == AppConstants.roleAdmin) {
          return const LGUUserManagementScreen();
        }
        return const ProfileScreen();
      case 0:
      default:
        // Module 07: Dashboard (Central LGU Command Overview)
        if (role == AppConstants.roleAdmin) return const AdminDashboard();
        if (role == AppConstants.roleResponder) return const ResponderDashboard();
        return const CitizenDashboard();
    }
  }

  // --- Retro Pill Floating Navigation Bar (Safe from Android system buttons on any device) ---
  Widget _buildRetroBottomNav(BuildContext context, String role, bool isDark) {
    final isAdmin = role == AppConstants.roleAdmin;
    final bottomInset = MediaQuery.of(context).viewPadding.bottom;

    final navItems = [
      {'icon': Icons.home_rounded, 'label': 'Home'},
      {'icon': Icons.location_on_rounded, 'label': 'Map'},
      {'icon': Icons.auto_awesome_rounded, 'label': 'AI'},
      {'icon': Icons.notifications_rounded, 'label': 'Alerts'},
      {'icon': isAdmin ? Icons.admin_panel_settings_rounded : Icons.person_rounded, 'label': 'Users'},
    ];

    return SafeArea(
      top: false,
      left: false,
      right: false,
      bottom: true,
      child: Container(
        margin: EdgeInsets.fromLTRB(20, 0, 20, bottomInset > 0 ? 6 : 16),
        height: 64,
        decoration: BoxDecoration(
          color: AppConstants.retroMint, // Solid Signature Mint/Teal
          borderRadius: BorderRadius.circular(32),
          border: Border.all(color: AppConstants.retroDarkBorder, width: 1.8),
          boxShadow: [
            BoxShadow(
              color: isDark ? Colors.black45 : AppConstants.retroDarkBorder.withOpacity(0.25),
              offset: const Offset(3, 4),
              blurRadius: 0, // Crisp neo-brutalist offset shadow
            ),
          ],
        ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: List.generate(navItems.length, (index) {
          final isSelected = _selectedIndex == index;
          final item = navItems[index];

          return GestureDetector(
            onTap: () => setState(() => _selectedIndex = index),
            behavior: HitTestBehavior.opaque,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: isSelected 
                  ? const EdgeInsets.symmetric(horizontal: 16, vertical: 8)
                  : const EdgeInsets.all(8),
              decoration: isSelected
                  ? BoxDecoration(
                      color: isDark ? const Color(0xFF1E222D) : Colors.white,
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(color: AppConstants.retroDarkBorder, width: 1.5),
                      boxShadow: [
                        BoxShadow(
                          color: AppConstants.retroDarkBorder.withOpacity(0.2),
                          offset: const Offset(2, 2),
                          blurRadius: 0,
                        ),
                      ],
                    )
                  : null,
              child: Icon(
                item['icon'] as IconData,
                size: 22,
                color: isSelected 
                    ? (isDark ? Colors.white : AppConstants.retroDarkBorder)
                    : Colors.white.withOpacity(0.95),
              ),
            ),
          );
        }),
      ),
    ),
  );
}
}
