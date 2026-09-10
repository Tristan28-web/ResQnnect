import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../core/constants.dart';
import '../models/user_model.dart';
import 'dart:convert';
import 'citizen_dashboard.dart';
import 'admin_dashboard.dart';
import 'responder_dashboard.dart';
import 'profile_screen.dart';
import 'alerts_screen.dart';
import 'incident_mapping_screen.dart';
import 'predictive_analysis_screen.dart';
import 'lgu_user_management_screen.dart';
import '../core/localization.dart';
import '../core/theme.dart';
import 'login_screen.dart';
import '../widgets/profile_image.dart';

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
    
    String role = user?.role ?? AppConstants.roleCitizen;
    final email = authService.currentUserEmail?.toLowerCase() ?? '';
    
    if (email == 'admin@catanduanes.gov.ph' || email == 'admin@cadiz.gov.ph' || email.contains('admin')) {
      role = AppConstants.roleAdmin;
    } else if (email.contains('responder') || email.contains('respondent') || email == 'john@resqnnect.com' || email.contains('rescue') || email.contains('pnp') || email.contains('bfp')) {
      role = AppConstants.roleResponder;
    }

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            _buildPremiumHeader(context, role, user, authService),
            Expanded(
              child: _buildBody(role),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomNav(role),
    );
  }

  Widget _buildPremiumHeader(BuildContext context, String role, UserModel? user, AuthService authService) {
    String titleText = AppConstants.appName;
    Color iconBgColor = AppConstants.primaryRed.withOpacity(0.15); // Dark Red Tint
    IconData statusIcon = Icons.security;

    if (role == AppConstants.roleAdmin) {
      statusIcon = Icons.admin_panel_settings_rounded;
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Image.asset(
                AppConstants.logoAsset,
                height: 48, // Increased size
                width: 48,  // Increased size
                errorBuilder: (context, error, stackTrace) => Icon(statusIcon, color: AppConstants.primaryRed, size: 24),
              ),
              const SizedBox(width: 16),
              Text(
                titleText,
                style: TextStyle(
                  color: Theme.of(context).textTheme.titleLarge?.color,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          Row(
            children: [
              Consumer<ThemeProvider>(
                builder: (context, themeProvider, child) {
                  return _buildHeaderButton(
                    themeProvider.isDarkMode ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
                    onTap: () => themeProvider.toggleTheme(),
                  );
                },
              ),
              const SizedBox(width: 12),
              _buildProfileButton(context, user, role),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderButton(IconData icon, {required VoidCallback onTap}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.05),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: isDark ? Colors.white : Colors.black87, size: 24),
      ),
    );
  }

  Widget _buildProfileButton(BuildContext context, UserModel? user, String role) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isAdmin = role == AppConstants.roleAdmin;
    
    return GestureDetector(
      onTap: isAdmin ? () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfileScreen())) : null,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.05),
          shape: BoxShape.circle,
          border: Border.all(color: isDark ? Colors.white10 : Colors.black12, width: 1),
        ),
        child: ProfileImage(
          source: user?.profileImage,
          radius: 22,
        ),
      ),
    );
  }

  Widget _buildBody(String role) {
    switch (_selectedIndex) {
      case 1:
        // Module 2 & 3: GIS Incident Mapping & Pinning
        return const IncidentMappingScreen();
      case 2:
        // Module 6 & 9: Predictive Analysis & Forecasting
        return const PredictiveAnalysisScreen();
      case 3:
        // Module 8: Notifications and Alerts
        return const AlertsScreen();
      case 4:
        // Module 10: User Management / Profile
        if (role == AppConstants.roleAdmin) {
          return const LGUUserManagementScreen();
        }
        return const ProfileScreen();
      case 0:
      default:
        // Module 7: Dashboard (Central LGU Command Overview)
        if (role == AppConstants.roleAdmin) return const AdminDashboard();
        if (role == AppConstants.roleResponder) return const ResponderDashboard();
        return const CitizenDashboard();
    }
  }

  Widget _buildBottomNav(String role) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isAdmin = role == AppConstants.roleAdmin;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E2841) : Colors.white,
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: isDark ? Colors.white10 : Colors.black12, width: 0.8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.4 : 0.08),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(30),
        child: BottomNavigationBar(
          currentIndex: _selectedIndex.clamp(0, 4),
          onTap: (index) => setState(() => _selectedIndex = index),
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.transparent,
          elevation: 0,
          showSelectedLabels: true,
          showUnselectedLabels: true,
          selectedItemColor: AppConstants.primaryRed,
          unselectedItemColor: isDark ? Colors.white38 : Colors.black38,
          selectedLabelStyle: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
          unselectedLabelStyle: const TextStyle(fontSize: 10),
          iconSize: 22,
          items: [
            const BottomNavigationBarItem(
              icon: Icon(Icons.dashboard_rounded),
              activeIcon: Icon(Icons.dashboard_rounded, color: AppConstants.primaryRed),
              label: 'Dashboard',
            ),
            const BottomNavigationBarItem(
              icon: Icon(Icons.pin_drop_rounded),
              activeIcon: Icon(Icons.pin_drop_rounded, color: AppConstants.primaryRed),
              label: 'GIS Map',
            ),
            const BottomNavigationBarItem(
              icon: Icon(Icons.insights_rounded),
              activeIcon: Icon(Icons.insights_rounded, color: AppConstants.primaryRed),
              label: 'Predictive AI',
            ),
            const BottomNavigationBarItem(
              icon: Icon(Icons.notifications_active_rounded),
              activeIcon: Icon(Icons.notifications_active_rounded, color: AppConstants.primaryRed),
              label: 'Alerts',
            ),
            BottomNavigationBarItem(
              icon: Icon(isAdmin ? Icons.admin_panel_settings_rounded : Icons.person_rounded),
              activeIcon: Icon(isAdmin ? Icons.admin_panel_settings_rounded : Icons.person_rounded, color: AppConstants.primaryRed),
              label: isAdmin ? 'Users' : 'Profile',
            ),
          ],
        ),
      ),
    );
  }

  void _showLogoutDialog(BuildContext context, AuthService authService) async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF1A1A1A) : Colors.white,
        title: Text('Sign Out', style: TextStyle(color: isDark ? Colors.white : Colors.black87)),
        content: Text('Are you sure you want to log out of GIS?', style: TextStyle(color: isDark ? Colors.white70 : Colors.black54)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('CANCEL', style: TextStyle(color: isDark ? Colors.white38 : Colors.black38)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('LOGOUT', style: TextStyle(color: AppConstants.primaryRed, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await authService.logout();
        if (context.mounted) {
          // Force immediate redirection and clear navigation stack
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
    }
  }
}


