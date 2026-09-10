import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../models/user_model.dart';
import '../core/constants.dart';
import 'edit_profile_screen.dart';
import 'login_screen.dart';
import '../widgets/profile_image.dart';
import '../services/location_service.dart';

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
            color: isDark ? Colors.white : AppColors.retroDarkBorder,
            fontWeight: FontWeight.w900,
            fontSize: 15,
            letterSpacing: 1.2,
          ),
        ),
        centerTitle: true,
        iconTheme: IconThemeData(color: isDark ? Colors.white : AppColors.retroDarkBorder),
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(
          children: [
            _buildProfileHeader(context, user, role),
            const SizedBox(height: 24),
            _buildAccountInfoCard(context, user, email, role),
            const SizedBox(height: 24),
            _buildSignOutButton(context, authService),
            const SizedBox(height: 100),
          ],
        ),
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

  // --- RETRO PROFILE HEADER ---
  Widget _buildProfileHeader(BuildContext context, UserModel? user, String role) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    String roleLabel = 'VERIFIED CITIZEN';
    Color roleBg = const Color(0xFFDCFCE7);
    Color roleText = const Color(0xFF16A34A);

    if (role == AppConstants.roleAdmin) {
      roleLabel = 'SYSTEM ADMINISTRATOR';
      roleBg = AppColors.retroLilac;
      roleText = const Color(0xFF6D28D9);
    } else if (role == AppConstants.roleResponder) {
      roleLabel = 'ACTIVE RESPONDER';
      roleBg = AppColors.retroPeach;
      roleText = const Color(0xFFEA580C);
    }

    final idTag = role == AppConstants.roleAdmin 
        ? 'GIS-ADMIN-001' 
        : (role == AppConstants.roleResponder 
             ? 'GIS-RSP-001' 
             : 'GIS-ID-9921');

    return Container(
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
          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: 96,
                height: 96,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isDark ? const Color(0xFF262C38) : Colors.white,
                  border: Border.all(
                    color: isDark ? const Color(0xFF4A3C38) : AppColors.retroDarkBorder,
                    width: 2.2,
                  ),
                ),
                child: ClipOval(
                  child: ProfileImage(
                    source: user?.profileImage,
                    radius: 46,
                    placeholderIcon: Icons.person_rounded,
                  ),
                ),
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: GestureDetector(
                  onTap: () => _navigateToEdit(context, user, role),
                  child: Container(
                    padding: const EdgeInsets.all(7),
                    decoration: BoxDecoration(
                      color: AppColors.retroMint,
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.retroDarkBorder, width: 1.6),
                    ),
                    child: const Icon(Icons.edit_rounded, size: 14, color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            (user?.name != null && user!.name.isNotEmpty)
                ? user.name
                : (role == AppConstants.roleAdmin
                      ? 'Admin User'
                      : (role == AppConstants.roleResponder 
                           ? 'Active Responder' 
                           : 'Citizen User')),
            style: TextStyle(
              color: isDark ? Colors.white : AppColors.retroDarkBorder,
              fontSize: 22,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.4,
            ),
          ),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
            decoration: BoxDecoration(
              color: isDark ? Colors.black38 : Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: isDark ? Colors.white24 : AppColors.retroDarkBorder,
                width: 1.2,
              ),
            ),
            child: Text(
              idTag,
              style: TextStyle(
                color: isDark ? Colors.white70 : AppColors.retroDarkBorder,
                fontSize: 11,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.8,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: roleBg,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.retroDarkBorder, width: 1.4),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.verified_rounded, color: roleText, size: 14),
                const SizedBox(width: 6),
                Text(
                  roleLabel,
                  style: TextStyle(
                    color: roleText,
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.8,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- RETRO ACCOUNT INFO CARD ---
  Widget _buildAccountInfoCard(BuildContext context, UserModel? user, String email, String role) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final locationService = Provider.of<LocationService>(context);

    return Container(
      width: double.infinity,
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'ACCOUNT CREDENTIALS & LOCATION',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.3,
              color: isDark ? Colors.white60 : const Color(0xFF6B7280),
            ),
          ),
          const SizedBox(height: 16),
          _buildInfoRow(
            icon: Icons.email_rounded,
            label: 'Email',
            value: email.isNotEmpty ? email : (user?.email ?? 'Not set'),
            isDark: isDark,
          ),
          const SizedBox(height: 12),
          _buildInfoRow(
            icon: Icons.phone_rounded,
            label: 'Phone',
            value: (user?.phone != null && user!.phone.isNotEmpty) ? user.phone : '0917-555-0199',
            isDark: isDark,
          ),
          const SizedBox(height: 12),
          _buildInfoRow(
            icon: Icons.place_rounded,
            label: 'Current Location',
            value: locationService.currentLocationName,
            isDark: isDark,
          ),
          const SizedBox(height: 12),
          _buildInfoRow(
            icon: Icons.wifi_tethering_rounded,
            label: 'GIS Link',
            value: 'Connected to Cloud Firestore',
            isDark: isDark,
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
    required bool isDark,
  }) {
    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF262C38) : AppColors.retroLilac,
            shape: BoxShape.circle,
            border: Border.all(
              color: isDark ? const Color(0xFF3E4556) : AppColors.retroDarkBorder,
              width: 1.4,
            ),
          ),
          child: Center(
            child: Icon(icon, size: 18, color: isDark ? Colors.white70 : AppColors.retroDarkBorder),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: isDark ? Colors.white38 : const Color(0xFF6B7280),
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: TextStyle(
                  color: isDark ? Colors.white : AppColors.retroDarkBorder,
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }

  // --- RETRO SIGN OUT BUTTON ---
  Widget _buildSignOutButton(BuildContext context, AuthService authService) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: () async {
        final confirm = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            backgroundColor: isDark ? AppColors.retroDarkCard : Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(22),
              side: const BorderSide(color: AppColors.retroDarkBorder, width: 2),
            ),
            title: const Text(
              'Sign Out',
              style: TextStyle(fontWeight: FontWeight.w900, color: AppColors.retroDarkBorder),
            ),
            content: Text(
              'Are you sure you want to log out of GIS?',
              style: TextStyle(color: isDark ? Colors.white70 : Colors.black87, fontSize: 13),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text(
                  'CANCEL',
                  style: TextStyle(
                    color: isDark ? Colors.white54 : const Color(0xFF6B7280),
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFEF4444),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: const BorderSide(color: AppColors.retroDarkBorder, width: 1.4),
                  ),
                ),
                onPressed: () => Navigator.pop(context, true),
                child: const Text('LOGOUT', style: TextStyle(fontWeight: FontWeight.w900)),
              ),
            ],
          ),
        );

        if (confirm == true) {
          await authService.logout();
          if (context.mounted) {
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (_) => const LoginScreen()),
              (route) => false,
            );
          }
        }
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF3B2020) : const Color(0xFFFEE2E2),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isDark ? const Color(0xFF7F1D1D) : AppColors.retroDarkBorder,
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
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.logout_rounded, color: Color(0xFFDC2626), size: 20),
            SizedBox(width: 8),
            Text(
              'Sign Out Account',
              style: TextStyle(
                color: Color(0xFFDC2626),
                fontSize: 14,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
