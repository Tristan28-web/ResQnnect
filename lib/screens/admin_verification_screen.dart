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
      backgroundColor: isDark ? AppConstants.backgroundBlack : Colors.grey.shade100,
      appBar: AppBar(
        title: const Text('CITIZEN VERIFICATION', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
        centerTitle: true,
      ),
      body: StreamBuilder<List<UserModel>>(
        stream: firestoreService.getUnverifiedCitizens(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: AppConstants.primaryRed));
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.verified_user_rounded, size: 80, color: isDark ? Colors.white.withOpacity(0.05) : Colors.green.withOpacity(0.2)),
                  const SizedBox(height: 24),
                  // Bug #2 fix: use theme-aware color instead of Colors.white38
                  Text(
                    'No pending verifications',
                    style: TextStyle(color: isDark ? Colors.white38 : Colors.black54, fontSize: 16),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(20),
            itemCount: snapshot.data!.length,
            itemBuilder: (context, index) {
              final user = snapshot.data![index];
              return _buildUserCard(context, user, firestoreService, isDark);
            },
          );
        },
      ),
    );
  }

  Widget _buildUserCard(BuildContext context, UserModel user, FirestoreService firestoreService, bool isDark) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? null : Colors.white,
        gradient: isDark
            ? const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF1E2841), Color(0xFF161E31)],
              )
            : null,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.06)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(isDark ? 0.45 : 0.06), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        children: [
          Row(
            children: [
              ProfileImage(
                radius: 30,
                source: user.profileImage,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(user.name, style: TextStyle(color: isDark ? Colors.white : Colors.black87, fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(height: 4),
                    Text(user.email, style: TextStyle(color: isDark ? Colors.white54 : Colors.black54, fontSize: 12)),
                    const SizedBox(height: 4),
                    Text(
                      'Registered: ${DateFormat('MMM dd, yyyy').format(user.createdAt ?? DateTime.now())}',
                      style: TextStyle(color: isDark ? Colors.white38 : Colors.black38, fontSize: 11),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () async {
                    await firestoreService.updateUserVerification(user.userId, false);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Citizen rejected.'), backgroundColor: Colors.red),
                    );
                  },
                  icon: const Icon(Icons.close, size: 16, color: Colors.red),
                  label: const Text('REJECT', style: TextStyle(color: Colors.red, fontSize: 12)),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.red),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () async {
                    await firestoreService.updateUserVerification(user.userId, true);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Citizen verified!'), backgroundColor: Colors.green),
                    );
                  },
                  icon: const Icon(Icons.check, size: 16),
                  label: const Text('VERIFY', style: TextStyle(fontSize: 12)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
