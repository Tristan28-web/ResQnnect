import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../models/user_model.dart';
import '../services/firestore_service.dart';
import '../core/constants.dart';
import '../widgets/profile_image.dart';

class EditProfileScreen extends StatefulWidget {
  final UserModel user;
  const EditProfileScreen({super.key, required this.user});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  String? _imageBase64;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.user.name);
    _phoneController = TextEditingController(text: widget.user.phone);
    _imageBase64 = widget.user.profileImage;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    try {
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 75,
      );
      
      if (image != null) {
        final bytes = await image.readAsBytes();
        setState(() {
          _imageBase64 = base64Encode(bytes);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error picking photo: $e'),
            backgroundColor: const Color(0xFFEF4444),
          ),
        );
      }
    }
  }

  Future<void> _saveProfile() async {
    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Name cannot be empty'),
          backgroundColor: Color(0xFFEF4444),
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final firestore = Provider.of<FirestoreService>(context, listen: false);
      final finalImage = (_imageBase64 == null || _imageBase64!.isEmpty || _imageBase64 == 'null')
          ? ''
          : _imageBase64!;

      final updatedUser = widget.user.copyWith(
        name: _nameController.text.trim(),
        phone: _phoneController.text.trim(),
        profileImage: finalImage,
      );

      // Also reset Firebase Auth photo URL if clearing
      try {
        final authUser = FirebaseAuth.instance.currentUser;
        if (finalImage.isEmpty) {
          await authUser?.updatePhotoURL(null);
        }
      } catch (_) {}

      await firestore.updateUserModel(updatedUser);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile updated successfully!'),
            backgroundColor: Color(0xFF16A34A),
          ),
        );
        await Future.delayed(const Duration(milliseconds: 400));
        if (mounted) Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating profile: $e'),
            backgroundColor: const Color(0xFFEF4444),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final role = widget.user.role;

    String roleLabel = 'VERIFIED CITIZEN';
    Color roleBg = const Color(0xFFDCFCE7);
    Color roleText = const Color(0xFF16A34A);

    if (role == AppConstants.roleAdmin || widget.user.email.contains('admin')) {
      roleLabel = 'SYSTEM ADMINISTRATOR';
      roleBg = AppColors.retroLilac;
      roleText = const Color(0xFF6D28D9);
    } else if (role == AppConstants.rolePNP || role == AppConstants.roleBFP || role == AppConstants.roleRescue) {
      roleLabel = 'LGU PERSONNEL';
      roleBg = AppColors.retroPeach;
      roleText = const Color(0xFFEA580C);
    }

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: Text(
          'EDIT PROFILE',
          style: TextStyle(
            color: isDark ? Colors.white : AppColors.retroDarkBorder,
            fontWeight: FontWeight.w900,
            fontSize: 15,
            letterSpacing: 1.2,
          ),
        ),
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              decoration: BoxDecoration(
                color: isDark ? AppColors.retroDarkCard : Colors.white,
                shape: BoxShape.circle,
                border: Border.all(
                  color: isDark ? const Color(0xFF3E4556) : AppColors.retroDarkBorder,
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: isDark ? Colors.black26 : AppColors.retroDarkBorder.withOpacity(0.1),
                    offset: const Offset(2, 2),
                    blurRadius: 0,
                  ),
                ],
              ),
              child: Icon(
                Icons.arrow_back_rounded,
                size: 18,
                color: isDark ? Colors.white : AppColors.retroDarkBorder,
              ),
            ),
          ),
        ),
      ),
      body: _isLoading
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(
                    color: AppColors.retroMint,
                    strokeWidth: 3,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'UPDATING PROFILE...',
                    style: TextStyle(
                      color: isDark ? Colors.white70 : AppColors.retroDarkBorder,
                      fontWeight: FontWeight.w900,
                      fontSize: 12,
                      letterSpacing: 1.0,
                    ),
                  ),
                ],
              ),
            )
          : SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // --- RETRO AVATAR HERO CARD ---
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
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
                        // Avatar Preview with Camera trigger badge
                        Stack(
                          clipBehavior: Clip.none,
                          children: [
                            Container(
                              width: 104,
                              height: 104,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: isDark ? const Color(0xFF262C38) : Colors.white,
                                border: Border.all(
                                  color: isDark ? const Color(0xFF4A3C38) : AppColors.retroDarkBorder,
                                  width: 2.4,
                                ),
                              ),
                              child: ClipOval(
                                child: ProfileImage(
                                  source: _imageBase64,
                                  radius: 50,
                                  placeholderIcon: Icons.person_rounded,
                                ),
                              ),
                            ),
                            Positioned(
                              bottom: 0,
                              right: 0,
                              child: GestureDetector(
                                onTap: _pickImage,
                                child: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: AppColors.retroMint,
                                    shape: BoxShape.circle,
                                    border: Border.all(color: AppColors.retroDarkBorder, width: 1.8),
                                    boxShadow: [
                                      BoxShadow(
                                        color: AppColors.retroDarkBorder.withOpacity(0.2),
                                        offset: const Offset(1, 2),
                                        blurRadius: 0,
                                      ),
                                    ],
                                  ),
                                  child: const Icon(
                                    Icons.camera_alt_rounded,
                                    size: 16,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Action Button: Change Photo
                        GestureDetector(
                          onTap: _pickImage,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 9),
                            decoration: BoxDecoration(
                              color: AppColors.retroMint,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: AppColors.retroDarkBorder, width: 1.4),
                              boxShadow: [
                                BoxShadow(
                                  color: isDark ? Colors.black38 : AppColors.retroDarkBorder.withOpacity(0.12),
                                  offset: const Offset(2, 2),
                                  blurRadius: 0,
                                ),
                              ],
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.photo_library_rounded, size: 14, color: Colors.white),
                                SizedBox(width: 6),
                                Text(
                                  'CHANGE PHOTO',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 0.6,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'Tap Change Photo to upload a new profile picture from your gallery.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: isDark ? Colors.white60 : const Color(0xFF6B7280),
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // --- FORM INPUTS CARD ---
                  Container(
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
                          color: isDark ? Colors.black38 : AppColors.retroDarkBorder.withOpacity(0.1),
                          offset: const Offset(3, 3),
                          blurRadius: 0,
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Full Name Field
                        _buildRetroFormField(
                          label: 'FULL NAME',
                          controller: _nameController,
                          icon: Icons.person_rounded,
                          iconBg: AppColors.retroLilac,
                          isDark: isDark,
                          hintText: 'Enter your full name',
                        ),
                        const SizedBox(height: 18),

                        // Phone Number Field
                        _buildRetroFormField(
                          label: 'PHONE NUMBER',
                          controller: _phoneController,
                          icon: Icons.phone_rounded,
                          iconBg: AppColors.retroPeach,
                          isDark: isDark,
                          keyboardType: TextInputType.phone,
                          hintText: 'Enter phone number (e.g. 09123456789)',
                        ),
                        const SizedBox(height: 18),

                        // Email (Read-only)
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'REGISTERED EMAIL',
                              style: TextStyle(
                                color: isDark ? Colors.white60 : const Color(0xFF6B7280),
                                fontSize: 10,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 1.2,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                              decoration: BoxDecoration(
                                color: isDark ? const Color(0xFF171A21) : const Color(0xFFF3F4F6),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: isDark ? Colors.white12 : AppColors.retroDarkBorder.withOpacity(0.2),
                                  width: 1.2,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(6),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFE5E7EB),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(color: AppColors.retroDarkBorder.withOpacity(0.3), width: 1),
                                    ),
                                    child: const Icon(Icons.email_rounded, size: 14, color: AppColors.retroDarkBorder),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      widget.user.email,
                                      style: TextStyle(
                                        color: isDark ? Colors.white70 : const Color(0xFF374151),
                                        fontSize: 13,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 18),

                        // Role Tag
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'VERIFIED STATUS',
                              style: TextStyle(
                                color: isDark ? Colors.white60 : const Color(0xFF6B7280),
                                fontSize: 10,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 1.2,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: roleBg,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: AppColors.retroDarkBorder, width: 1.2),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.verified_rounded, color: roleText, size: 12),
                                  const SizedBox(width: 4),
                                  Text(
                                    roleLabel,
                                    style: TextStyle(
                                      color: roleText,
                                      fontSize: 9,
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: 0.6,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // --- RETRO PRIMARY SAVE BUTTON ---
                  GestureDetector(
                    onTap: _saveProfile,
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      decoration: BoxDecoration(
                        color: AppColors.retroMint,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: AppColors.retroDarkBorder, width: 2.0),
                        boxShadow: [
                          BoxShadow(
                            color: isDark ? Colors.black54 : AppColors.retroDarkBorder.withOpacity(0.2),
                            offset: const Offset(3, 4),
                            blurRadius: 0,
                          ),
                        ],
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.check_circle_rounded, size: 20, color: Colors.white),
                          SizedBox(width: 10),
                          Text(
                            'SAVE PROFILE CHANGES',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.8,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
    );
  }

  Widget _buildRetroFormField({
    required String label,
    required TextEditingController controller,
    required IconData icon,
    required Color iconBg,
    required bool isDark,
    required String hintText,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: isDark ? Colors.white70 : const Color(0xFF374151),
            fontSize: 10,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF262C38) : Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isDark ? const Color(0xFF3E4556) : AppColors.retroDarkBorder,
              width: 1.6,
            ),
            boxShadow: [
              BoxShadow(
                color: isDark ? Colors.black26 : AppColors.retroDarkBorder.withOpacity(0.06),
                offset: const Offset(2, 2),
                blurRadius: 0,
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                margin: const EdgeInsets.only(left: 10),
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: iconBg,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.retroDarkBorder, width: 1.2),
                ),
                child: Icon(icon, size: 16, color: AppColors.retroDarkBorder),
              ),
              Expanded(
                child: TextField(
                  controller: controller,
                  keyboardType: keyboardType,
                  style: TextStyle(
                    color: isDark ? Colors.white : AppColors.retroDarkBorder,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                  decoration: InputDecoration(
                    hintText: hintText,
                    hintStyle: TextStyle(
                      color: isDark ? Colors.white30 : const Color(0xFF9CA3AF),
                      fontSize: 13,
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
