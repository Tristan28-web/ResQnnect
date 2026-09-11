import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../models/user_model.dart';
import '../core/constants.dart';
import 'edit_profile_screen.dart';
import 'login_screen.dart';
import '../widgets/profile_image.dart';

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
    }

    final isAnonymous = authService.currentUser?.isAnonymous == true ||
        user?.name == 'Guest Account' ||
        user?.email == 'guest@gis.local';

    String title = isAnonymous
        ? 'GUEST PROFILE'
        : (role == AppConstants.roleAdmin ? 'ADMIN CONSOLE' : 'CITIZEN PROFILE');

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
    final isAnonymous = user?.name == 'Guest Account' || user?.email == 'guest@gis.local';

    String roleLabel = isAnonymous ? 'GUEST CITIZEN' : 'VERIFIED CITIZEN';
    Color roleBg = isAnonymous ? AppColors.retroPeach : const Color(0xFFDCFCE7);
    Color roleText = isAnonymous ? const Color(0xFFEA580C) : const Color(0xFF16A34A);

    if (role == AppConstants.roleAdmin) {
      roleLabel = 'SYSTEM ADMINISTRATOR';
      roleBg = AppColors.retroLilac;
      roleText = const Color(0xFF6D28D9);
    }

    final idTag = isAnonymous
        ? 'GIS-GUEST'
        : (role == AppConstants.roleAdmin 
            ? 'GIS-ADMIN-001' 
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
            isAnonymous
                ? 'Guest Account'
                : ((user?.name != null && user!.name.isNotEmpty)
                    ? user.name
                    : (role == AppConstants.roleAdmin
                          ? 'Admin User'
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
