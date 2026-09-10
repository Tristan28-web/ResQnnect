import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../models/user_model.dart';
import '../core/constants.dart';
import 'dart:convert';
import 'edit_profile_screen.dart';
import 'login_screen.dart';
import '../widgets/profile_image.dart';
import '../services/firestore_service.dart';
import 'sos_gesture_settings_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context, listen: false);
    final user = Provider.of<UserModel?>(context);

    String role = user?.role ?? AppConstants.roleCitizen;
    final email = authService.currentUserEmail?.toLowerCase() ?? '';
    
    if (email == 'admin@catanduanes.gov.ph' || email == 'admin@cadiz.gov.ph' || email.contains('admin')) {
      role = AppConstants.roleAdmin;
    } else if (email.contains('responder') || email.contains('respondent') || email == 'john@resqnnect.com' || email.contains('rescue') || email.contains('pnp') || email.contains('bfp')) {
      role = AppConstants.roleResponder;
    }

    String title = 'CITIZEN PROFILE';
    if (role == AppConstants.roleAdmin) title = 'ADMIN CONSOLE';
    if (role == AppConstants.roleResponder) title = 'RESPONDER PROFILE';

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          title,
          style: TextStyle(
            color: isDark ? Colors.white : Colors.black87,
            fontWeight: FontWeight.bold,
            fontSize: 16,
            letterSpacing: 1.2,
          ),
        ),
        centerTitle: true,
        iconTheme: IconThemeData(color: isDark ? Colors.white : Colors.black87),
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            _buildProfileHeader(context, user, role),
            const SizedBox(height: 32),
            if (role == AppConstants.roleCitizen) ...[
              _buildSettingsSection(context, isDark),
              const SizedBox(height: 20),
            ],
            _buildSignOutButton(context, authService),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingsSection(BuildContext context, bool isDark) {
    return Container(
      decoration: BoxDecoration(
        gradient: isDark ? const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1E2841), Color(0xFF161E31)],
        ) : null,
        color: isDark ? null : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.05)),
        boxShadow: isDark ? [const BoxShadow(color: Colors.black45, blurRadius: 10, offset: Offset(0, 4))] : [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            spreadRadius: 2,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Column(
        children: [
          ListTile(
            leading: const Icon(Icons.gesture, color: AppConstants.primaryRed),
            title: const Text('SOS Gesture Settings', style: TextStyle(fontWeight: FontWeight.bold)),
            subtitle: const Text('Configure volume/power button triggers'),
            trailing: Icon(Icons.chevron_right, color: isDark ? Colors.white24 : Colors.black26),
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SOSGestureSettingsScreen())),
          ),
        ],
      ),
    );
  }

  void _navigateToEdit(BuildContext context, UserModel? user, String role) {
    if (user == null) return;
    
    Navigator.push(
      context, 
      MaterialPageRoute(builder: (_) => EditProfileScreen(user: user))
    );
  }

  Widget _buildProfileHeader(BuildContext context, UserModel? user, String role) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    String roleLabel = 'VERIFIED CITIZEN';
    Color roleColor = Colors.greenAccent[400]!;

    if (role == AppConstants.roleAdmin) {
      roleLabel = 'SYSTEM ADMINISTRATOR';
      roleColor = AppConstants.primaryRed;
    } else if (role == AppConstants.roleResponder) {
      roleLabel = 'ACTIVE RESPONDER';
      roleColor = Colors.blueAccent;
    }

    return Column(
      children: [
        Stack(
          children: [
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppConstants.primaryRed.withOpacity(0.5),
                  width: 2,
                ),
              ),
              child: CircleAvatar(
                radius: 50,
                backgroundColor: isDark ? AppConstants.surfaceDark : Colors.grey[200],
                child: ProfileImage(
                  source: user?.profileImage,
                  radius: 50,
                  placeholderIcon: Icons.person,
                ),
              ),
            ),
            Positioned(
              bottom: 0,
              right: 0,
              child: GestureDetector(
                onTap: () => _navigateToEdit(context, user, role),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: const BoxDecoration(
                    color: AppConstants.primaryRed,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.edit, size: 14, color: Colors.white),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Text(
          (user?.name != null && user!.name.isNotEmpty)
              ? user.name
              : (role == AppConstants.roleAdmin
                    ? 'Admin User'
                    : (role == AppConstants.roleResponder 
                         ? 'Active Responder' 
                         : 'Citizen User')),
          style: TextStyle(color: isDark ? Colors.white : Colors.black87, fontSize: 24, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        Text(
          role == AppConstants.roleAdmin 
              ? 'RESQ-ADMIN-001' 
              : (role == AppConstants.roleResponder 
                   ? 'RESQ-RSP-001' 
                   : 'RESQ-ID-9921'),
          style: const TextStyle(
            color: AppConstants.primaryRed,
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
        if (user?.phone != null && user!.phone.isNotEmpty) ...[
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.phone_outlined, color: isDark ? Colors.white38 : Colors.black38, size: 14),
              const SizedBox(width: 8),
              Text(
                user.phone,
                style: TextStyle(color: isDark ? Colors.white70 : Colors.black87, fontSize: 13, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ],
        const SizedBox(height: 16),
        GestureDetector(
          onTap: () => _navigateToEdit(context, user, role),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            decoration: BoxDecoration(
              color: roleColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: roleColor.withOpacity(0.3)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.verified, color: roleColor, size: 14),
                const SizedBox(width: 6),
                Text(
                  roleLabel,
                  style: TextStyle(
                    color: roleColor,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSignOutButton(BuildContext context, AuthService authService) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        gradient: isDark ? const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1E2841), Color(0xFF161E31)],
        ) : null,
        color: isDark ? null : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.05)),
        boxShadow: isDark ? [const BoxShadow(color: Colors.black45, blurRadius: 10, offset: Offset(0, 4))] : [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            spreadRadius: 2,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: ListTile(
        leading: const Icon(Icons.exit_to_app, color: Colors.redAccent),
        title: const Text(
          'Sign Out',
          style: TextStyle(color: Colors.redAccent, fontSize: 16),
        ),
        trailing: Icon(Icons.chevron_right, color: isDark ? Colors.white24 : Colors.black26),
        onTap: () async {
          final confirm = await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
              backgroundColor: isDark ? const Color(0xFF1E2333) : Colors.white,
              title: Text('Sign Out', style: TextStyle(color: isDark ? Colors.white : Colors.black87)),
              content: Text('Are you sure you want to log out?', style: TextStyle(color: isDark ? Colors.white70 : Colors.black54)),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: Text('CANCEL', style: TextStyle(color: isDark ? Colors.white38 : Colors.black54)),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: const Text('LOGOUT', style: TextStyle(color: AppConstants.primaryRed, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          );

          if (confirm == true) {
            await authService.logout();
            if (context.mounted) {
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => LoginScreen()),
                (route) => false,
              );
            }
          }
        },
      ),
    );
  }
}
