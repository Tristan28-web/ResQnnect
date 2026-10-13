import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/firestore_service.dart';
import '../models/user_model.dart';
import '../core/constants.dart';
import '../core/navigation_utils.dart';
import 'package:intl/intl.dart';
import '../widgets/profile_image.dart';
import 'dart:convert';
import '../models/identity_verification_model.dart';
import '../services/face/face_engine.dart';

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
          onPressed: () => AppNavigation.popOrHome(context),
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
          const SizedBox(height: 14),
          _IdentityEvidence(userId: user.userId, isDark: isDark),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () async {
                    final reason = await _askRejectReason(context);
                    if (reason == null) return;
                    await firestoreService.updateUserVerification(user.userId, false, reason: reason);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Submission rejected. The citizen must resubmit.'),
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


Future<String?> _askRejectReason(BuildContext context) {
  final controller = TextEditingController();
  const quick = [
    'ID is blurry / unreadable',
    'Face does not match the ID',
    'ID is expired or invalid',
    'Selfie is unclear',
  ];
  return showDialog<String>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Reject submission', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 6,
            children: quick
                .map((q) => ActionChip(
                      label: Text(q, style: const TextStyle(fontSize: 10)),
                      onPressed: () => controller.text = q,
                    ))
                .toList(),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: controller,
            maxLines: 2,
            decoration: const InputDecoration(hintText: 'Reason shown to the citizen'),
          ),
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('CANCEL')),
        TextButton(
          onPressed: () => Navigator.pop(
            ctx,
            controller.text.trim().isEmpty ? 'Please resubmit clearer photos.' : controller.text.trim(),
          ),
          child: const Text('REJECT', style: TextStyle(color: Color(0xFFDC2626), fontWeight: FontWeight.w900)),
        ),
      ],
    ),
  );
}

/// ID photo + live selfie + automatic match result for one pending citizen.
class _IdentityEvidence extends StatelessWidget {
  final String userId;
  final bool isDark;
  const _IdentityEvidence({required this.userId, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final firestore = Provider.of<FirestoreService>(context, listen: false);
    return FutureBuilder<IdentityVerificationModel?>(
      future: firestore.getIdentityVerification(userId),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.all(12),
            child: Center(
              child: SizedBox(
                height: 18,
                width: 18,
                child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.retroMint),
              ),
            ),
          );
        }
        final v = snap.data;
        if (v == null) {
          return const Text(
            'No ID submission found.',
            style: TextStyle(color: Color(0xFFDC2626), fontSize: 11, fontWeight: FontWeight.w700),
          );
        }

        final level = FaceMatchThresholds.levelOf(v.faceMatchScore);
        final (String label, Color color) = switch (level) {
          FaceMatchLevel.strong => ('STRONG MATCH', const Color(0xFF16A34A)),
          FaceMatchLevel.review => ('REVIEW CAREFULLY', const Color(0xFFD97706)),
          FaceMatchLevel.mismatch => ('LIKELY MISMATCH', const Color(0xFFDC2626)),
          FaceMatchLevel.unavailable => ('COMPARE MANUALLY', const Color(0xFF6B7280)),
        };

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(child: _photo(context, 'ID: ${v.idType}', v.idImageBase64)),
                const SizedBox(width: 10),
                Expanded(child: _photo(context, 'LIVE SELFIE', v.selfieBase64)),
              ],
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                _chip(
                  v.faceMatchScore != null
                      ? '$label · ${(v.faceMatchScore! * 100).toStringAsFixed(0)}%'
                      : label,
                  color,
                ),
                _chip(
                  v.livenessPassed ? 'LIVENESS PASSED' : 'LIVENESS NOT VERIFIED',
                  v.livenessPassed ? const Color(0xFF16A34A) : const Color(0xFFD97706),
                ),
                if (!v.faceFoundOnId) _chip('NO PORTRAIT DETECTED ON ID', const Color(0xFFD97706)),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              "The score is computed on the citizen's device and is advisory. Always confirm the faces and ID details yourself.",
              style: TextStyle(color: isDark ? Colors.white38 : const Color(0xFF9CA3AF), fontSize: 9),
            ),
          ],
        );
      },
    );
  }

  Widget _chip(String text, Color color) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: color.withOpacity(0.12),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color, width: 1.1),
        ),
        child: Text(
          text,
          style: TextStyle(color: color, fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 0.4),
        ),
      );

  Widget _photo(BuildContext context, String caption, String base64Str) {
    final bytes = base64Str.isEmpty ? null : base64Decode(base64Str);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: bytes == null
              ? null
              : () => showDialog(
                    context: context,
                    builder: (_) => Dialog(
                      backgroundColor: Colors.black,
                      insetPadding: const EdgeInsets.all(12),
                      child: InteractiveViewer(child: Image.memory(bytes)),
                    ),
                  ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: bytes == null
                ? Container(
                    height: 110,
                    color: Colors.black12,
                    child: const Center(child: Icon(Icons.image_not_supported_rounded)),
                  )
                : Image.memory(bytes, height: 110, width: double.infinity, fit: BoxFit.cover),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          caption,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: isDark ? Colors.white60 : const Color(0xFF6B7280),
            fontSize: 9,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}
