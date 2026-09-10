import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/firestore_service.dart';
import '../models/user_model.dart';
import '../core/constants.dart';
import 'package:intl/intl.dart';
import '../widgets/profile_image.dart';

class AdminVerificationScreen extends StatelessWidget {
  const AdminVerificationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final firestoreService = Provider.of<FirestoreService>(context, listen: false);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: isDark ? AppColors.retroDarkCard : Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: isDark ? const Color(0xFF3E4556) : AppColors.retroDarkBorder, width: 1.5),
            ),
            child: Icon(Icons.arrow_back_ios_new_rounded, size: 14, color: isDark ? Colors.white : AppColors.retroDarkBorder),
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'CITIZEN VERIFICATION',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.3,
            color: isDark ? Colors.white : AppColors.retroDarkBorder,
          ),
        ),
      ),
      body: StreamBuilder<List<UserModel>>(
        stream: firestoreService.getUnverifiedCitizens(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: AppColors.retroMint));
          }

          final unverifiedList = snapshot.data ?? [];

          return SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildRetroProtocolBanner(unverifiedList.length, isDark),
                const SizedBox(height: 18),

                if (unverifiedList.isEmpty)
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 40),
                      child: Column(
                        children: [
                          Container(
                            width: 68,
                            height: 68,
                            decoration: BoxDecoration(
                              color: const Color(0xFFDCFCE7),
                              shape: BoxShape.circle,
                              border: Border.all(color: AppColors.retroDarkBorder, width: 1.8),
                              boxShadow: const [
                                BoxShadow(
                                  color: AppColors.retroDarkBorder,
                                  offset: Offset(3, 3),
                                  blurRadius: 0,
                                ),
                              ],
                            ),
                            child: const Icon(Icons.verified_user_rounded, size: 34, color: Color(0xFF16A34A)),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'NO PENDING VERIFICATIONS',
                            style: TextStyle(
                              color: isDark ? Colors.white : AppColors.retroDarkBorder,
                              fontSize: 14,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.8,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'All registered citizen accounts have been processed for GIS reporting.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: isDark ? Colors.white54 : const Color(0xFF6B7280),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  ...unverifiedList.map((user) => _buildRetroUserCard(context, user, firestoreService, isDark)),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildRetroProtocolBanner(int count, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2B2421) : AppColors.retroPeach,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? const Color(0xFF4A3C38) : AppColors.retroDarkBorder,
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
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isDark ? Colors.black38 : Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: isDark ? Colors.white24 : AppColors.retroDarkBorder,
                width: 1.4,
              ),
            ),
            child: const Icon(Icons.admin_panel_settings_rounded, color: Color(0xFFD97706), size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'CITIZEN VERIFICATION QUEUE',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.0,
                        color: isDark ? Colors.white70 : AppColors.retroDarkBorder,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(
                        color: count > 0 ? const Color(0xFFFEE2E2) : const Color(0xFFDCFCE7),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: count > 0 ? const Color(0xFFDC2626) : const Color(0xFF16A34A),
                          width: 1.0,
                        ),
                      ),
                      child: Text(
                        '$count PENDING',
                        style: TextStyle(
                          color: count > 0 ? const Color(0xFFDC2626) : const Color(0xFF16A34A),
                          fontSize: 8,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'Verify legitimate citizen accounts to prevent prank reports and protect GIS data.',
                  style: TextStyle(
                    color: isDark ? Colors.white60 : const Color(0xFF4B5563),
                    fontSize: 11,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRetroUserCard(BuildContext context, UserModel user, FirestoreService firestoreService, bool isDark) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.retroDarkCard : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? const Color(0xFF3E4556) : AppColors.retroDarkBorder,
          width: 1.8,
        ),
        boxShadow: [
          BoxShadow(
            color: isDark ? Colors.black45 : AppColors.retroDarkBorder.withOpacity(0.12),
            offset: const Offset(3.5, 3.5),
            blurRadius: 0,
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.retroDarkBorder, width: 1.8),
                ),
                child: ClipOval(
                  child: ProfileImage(
                    radius: 25,
                    source: user.profileImage,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user.name.isNotEmpty ? user.name : 'Citizen User',
                      style: TextStyle(
                        color: isDark ? Colors.white : AppColors.retroDarkBorder,
                        fontWeight: FontWeight.w900,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      user.email,
                      style: TextStyle(
                        color: isDark ? Colors.white60 : const Color(0xFF6B7280),
                        fontSize: 11,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Registered: ${DateFormat('MMM dd, yyyy').format(user.createdAt)}',
                      style: TextStyle(
                        color: isDark ? Colors.white38 : const Color(0xFF9CA3AF),
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.retroPeach,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.retroDarkBorder, width: 1.2),
                ),
                child: const Text(
                  'PENDING',
                  style: TextStyle(
                    color: Color(0xFFD97706),
                    fontSize: 9,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () async {
                    await firestoreService.updateUserVerification(user.userId, false);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Citizen registration rejected.'),
                          backgroundColor: Color(0xFFDC2626),
                        ),
                      );
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEE2E2),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.retroDarkBorder, width: 1.4),
                      boxShadow: [
                        BoxShadow(
                          color: isDark ? Colors.black54 : AppColors.retroDarkBorder,
                          offset: const Offset(2, 2),
                          blurRadius: 0,
                        ),
                      ],
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.close_rounded, size: 16, color: Color(0xFFDC2626)),
                        SizedBox(width: 4),
                        Text(
                          'REJECT',
                          style: TextStyle(
                            color: Color(0xFFDC2626),
                            fontSize: 11,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: GestureDetector(
                  onTap: () async {
                    await firestoreService.updateUserVerification(user.userId, true);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Citizen verified successfully!'),
                          backgroundColor: Color(0xFF16A34A),
                        ),
                      );
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: AppColors.retroMint,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.retroDarkBorder, width: 1.4),
                      boxShadow: [
                        BoxShadow(
                          color: isDark ? Colors.black54 : AppColors.retroDarkBorder,
                          offset: const Offset(2, 2),
                          blurRadius: 0,
                        ),
                      ],
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.check_rounded, size: 16, color: Colors.white),
                        SizedBox(width: 4),
                        Text(
                          'VERIFY',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
