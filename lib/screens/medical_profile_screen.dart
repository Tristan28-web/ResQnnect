import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/user_model.dart';
import '../services/firestore_service.dart';
import '../core/constants.dart';

class MedicalProfileScreen extends StatefulWidget {
  final UserModel user;

  const MedicalProfileScreen({super.key, required this.user});

  @override
  State<MedicalProfileScreen> createState() => _MedicalProfileScreenState();
}

class _MedicalProfileScreenState extends State<MedicalProfileScreen> {
  late TextEditingController _bloodTypeController;
  late TextEditingController _weightController;
  late TextEditingController _allergiesController;
  late TextEditingController _medicationsController;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _bloodTypeController = TextEditingController(text: widget.user.bloodType);
    _weightController = TextEditingController(text: widget.user.weight);
    _allergiesController = TextEditingController(text: widget.user.allergies);
    _medicationsController = TextEditingController(text: widget.user.medications);
  }

  @override
  void dispose() {
    _bloodTypeController.dispose();
    _weightController.dispose();
    _allergiesController.dispose();
    _medicationsController.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    setState(() => _isSaving = true);
    
    final updatedUser = UserModel(
      userId: widget.user.userId,
      name: widget.user.name,
      email: widget.user.email,
      phone: widget.user.phone,
      profileImage: widget.user.profileImage,
      role: widget.user.role,
      isActive: widget.user.isActive,
      isVerified: widget.user.isVerified,
      createdAt: widget.user.createdAt,
      lastClockIn: widget.user.lastClockIn,
      bloodType: _bloodTypeController.text,
      weight: _weightController.text,
      allergies: _allergiesController.text,
      medications: _medicationsController.text,
      emergencyContacts: widget.user.emergencyContacts,
    );

    try {
      await Provider.of<FirestoreService>(context, listen: false).updateUserData(updatedUser);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Medical profile updated!'), backgroundColor: Colors.green),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: AppConstants.primaryRed),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: isDark ? AppConstants.backgroundBlack : Colors.grey.shade100,
      appBar: AppBar(
        title: Text('MEDICAL PROFILE', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: isDark ? Colors.white : Colors.black87)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: isDark ? Colors.white : Colors.black87),
        actions: [
          if (_isSaving)
            const Center(child: Padding(padding: EdgeInsets.only(right: 16), child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: AppConstants.primaryRed))))
          else
            TextButton(
              onPressed: _saveProfile,
              child: const Text('SAVE', style: TextStyle(color: AppConstants.primaryRed, fontWeight: FontWeight.bold)),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildInfoBox(isDark),
            const SizedBox(height: 32),
            _buildField('Blood Type', _bloodTypeController, Icons.bloodtype, 'e.g. O+', isDark),
            _buildField('Weight (kg)', _weightController, Icons.monitor_weight_outlined, 'e.g. 70kg', isDark),
            _buildField('Allergies', _allergiesController, Icons.warning_amber_rounded, 'e.g. Peanuts, Penicillin', isDark, maxLines: 2),
            _buildField('Medications', _medicationsController, Icons.medication_rounded, 'e.g. Maintenance drugs', isDark, maxLines: 2),
            const SizedBox(height: 40),
            Text(
              'Emergency Contacts',
              style: TextStyle(color: isDark ? Colors.white : Colors.black87, fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Contacts are managed in the main Contacts screen.',
              style: TextStyle(color: isDark ? Colors.white38 : Colors.black38, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoBox(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppConstants.primaryRed.withOpacity(0.15),
            AppConstants.primaryRed.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppConstants.primaryRed.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline, color: AppConstants.primaryRed),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              'This information will only be visible to emergency personnel during an SOS dispatch.',
              style: TextStyle(color: isDark ? Colors.white70 : Colors.black87, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildField(String label, TextEditingController controller, IconData icon, String hint, bool isDark, {int maxLines = 1}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(color: isDark ? Colors.white54 : Colors.black54, fontSize: 14)),
          const SizedBox(height: 12),
          TextField(
            controller: controller,
            maxLines: maxLines,
            style: TextStyle(color: isDark ? Colors.white : Colors.black87),
            decoration: InputDecoration(
              prefixIcon: Icon(icon, color: AppConstants.primaryRed, size: 20),
              hintText: hint,
              hintStyle: TextStyle(color: isDark ? Colors.white12 : Colors.black12),
              filled: true,
              fillColor: isDark ? const Color(0xFF1E2841) : Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16), 
                borderSide: isDark ? BorderSide.none : BorderSide(color: Colors.black.withOpacity(0.05)),
              ),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: AppConstants.primaryRed)),
              enabledBorder: isDark ? null : OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: Colors.black.withOpacity(0.05))),
            ),
          ),
        ],
      ),
    );
  }
}
