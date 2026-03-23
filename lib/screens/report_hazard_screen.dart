import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import '../services/firestore_service.dart';
import '../models/hazard_model.dart';
import '../core/constants.dart';

class ReportHazardScreen extends StatefulWidget {
  const ReportHazardScreen({super.key});

  @override
  State<ReportHazardScreen> createState() => _ReportHazardScreenState();
}

class _ReportHazardScreenState extends State<ReportHazardScreen> {
  final _descriptionController = TextEditingController();
  final _locationController = TextEditingController();
  File? _image;
  bool _isReporting = false;
  bool _isLocationVerified = false;
  HazardType _selectedType = HazardType.other;
  Position? _currentPosition;

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 25, 
    );
    if (pickedFile != null) {
      setState(() => _image = File(pickedFile.path));
    }
  }

  Future<void> _getCurrentLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return;

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return;
    }
    
    if (permission == LocationPermission.deniedForever) return;

    _currentPosition = await Geolocator.getCurrentPosition();
    setState(() {
      _locationController.text = '${_currentPosition!.latitude.toStringAsFixed(4)}, ${_currentPosition!.longitude.toStringAsFixed(4)}';
      _isLocationVerified = true;
    });
  }

  void _submitHazard() async {
    if (_descriptionController.text.isEmpty || _currentPosition == null || _image == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill in all fields (including photo and location)'),
          backgroundColor: AppConstants.primaryRed,
        ),
      );
      return;
    }

    setState(() => _isReporting = true);
    
    final firestoreService = Provider.of<FirestoreService>(context, listen: false);
    final userId = FirebaseAuth.instance.currentUser?.uid ?? 'anonymous';
    
    String? imageBase64;
    final bytes = await _image!.readAsBytes();
    imageBase64 = base64Encode(bytes);
    
    final hazard = HazardModel(
      hazardId: DateTime.now().millisecondsSinceEpoch.toString(),
      type: _selectedType,
      description: _descriptionController.text.trim(),
      imageBase64: imageBase64,
      latitude: _currentPosition!.latitude,
      longitude: _currentPosition!.longitude,
      reportedBy: userId,
      status: 'pending',
      timestamp: DateTime.now(),
    );
    
    await firestoreService.reportHazard(hazard);

    if (mounted) {
      _showSuccessDialog();
    }
    
    setState(() => _isReporting = false);
  }

  void _showSuccessDialog() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E2841),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        elevation: 24,
        shadowColor: Colors.black,
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.shield_outlined, color: Colors.greenAccent, size: 48),
            ),
            const SizedBox(height: 24),
            Text(
              'HAZARD BROADCASTED',
              style: TextStyle(color: isDark ? Colors.white : Colors.black87, fontWeight: FontWeight.bold, fontSize: 18, letterSpacing: 1),
            ),
            const SizedBox(height: 12),
            Text(
              'Your report will help alert other citizens in the area. Thank you for your civil action.',
              textAlign: TextAlign.center,
              style: TextStyle(color: isDark ? Colors.white54 : Colors.black54, fontSize: 13),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppConstants.primaryRed,
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () {
                Navigator.pop(ctx);
                Navigator.pop(context);
              },
              child: const Text('BACK TO HAZARDS', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('REPORT A HAZARD', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
             _buildSectionTitle(context, 'Hazard Type', Icons.category_outlined),
            const SizedBox(height: 16),
            _buildTypeDropdown(context),
            const SizedBox(height: 32),
            _buildSectionTitle(context, 'Hazard Details', Icons.description_outlined),
            const SizedBox(height: 16),
            _buildGlassField(
              context,
              controller: _descriptionController,
              hint: 'Describe what you see (e.g., Fallen tree on road, Severe flood area)...',
              maxLines: 4,
            ),
            const SizedBox(height: 32),
            _buildSectionTitle(context, 'Location', Icons.location_on_outlined),
            const SizedBox(height: 16),
            _buildLocationField(context),
            const SizedBox(height: 32),
            _buildSectionTitle(context, 'Hazard Photo', Icons.camera_alt_outlined),
            const SizedBox(height: 16),
            _buildImagePicker(context),
            const SizedBox(height: 48),
            _buildSubmitButton(),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildTypeDropdown(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E2841) : Colors.black.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: (isDark ? Colors.white : Colors.black).withOpacity(0.05)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<HazardType>(
          value: _selectedType,
          dropdownColor: isDark ? const Color(0xFF161E31) : Colors.white,
          style: TextStyle(color: isDark ? Colors.white : Colors.black87),
          items: HazardType.values.map((type) {
            return DropdownMenuItem(
              value: type,
              child: Text(_formatType(type)),
            );
          }).toList(),
          onChanged: (val) => setState(() => _selectedType = val!),
        ),
      ),
    );
  }

  String _formatType(HazardType type) {
    switch (type) {
      case HazardType.roadHazard: return 'Road Hazard';
      case HazardType.naturalDisaster: return 'Natural Disaster';
      case HazardType.other: return 'General Hazard';
    }
  }

  Widget _buildSectionTitle(BuildContext context, String title, IconData icon) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Row(
      children: [
        Icon(icon, color: AppConstants.primaryRed, size: 18),
        const SizedBox(width: 10),
        Text(
          title.toUpperCase(),
          style: TextStyle(color: isDark ? Colors.white70 : Colors.black87.withOpacity(0.6), fontSize: 12, fontWeight: FontWeight.w900, letterSpacing: 1.5),
        ),
      ],
    );
  }

  Widget _buildGlassField(BuildContext context, {required TextEditingController controller, required String hint, int maxLines = 1}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return TextField(
      controller: controller,
      maxLines: maxLines,
      style: TextStyle(color: isDark ? Colors.white : Colors.black87, fontSize: 15),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: isDark ? Colors.white24 : Colors.black26),
        filled: true,
        fillColor: isDark ? const Color(0xFF1E2841) : Colors.black.withOpacity(0.05),
        contentPadding: const EdgeInsets.all(20),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.05)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppConstants.primaryRed),
        ),
      ),
    );
  }

  Widget _buildLocationField(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E2841) : Colors.black.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _isLocationVerified ? Colors.greenAccent.withOpacity(0.3) : (isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.05))),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _locationController,
              readOnly: true,
              style: TextStyle(color: isDark ? Colors.white : Colors.black87, fontSize: 15),
              decoration: InputDecoration(
                hintText: 'Tap GPS icon to verify location...',
                hintStyle: TextStyle(color: isDark ? Colors.white24 : Colors.black26),
                contentPadding: const EdgeInsets.all(20),
                border: InputBorder.none,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: IconButton(
              icon: Icon(
                _isLocationVerified ? Icons.gps_fixed : Icons.my_location,
                color: _isLocationVerified ? Colors.greenAccent : AppConstants.primaryRed,
              ),
              onPressed: _getCurrentLocation,
              tooltip: 'Verify my GPS location',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImagePicker(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: _pickImage,
      child: Container(
        height: 200,
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E2841) : Colors.black.withOpacity(0.05),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: (isDark ? Colors.white : Colors.black).withOpacity(0.05)),
        ),
        child: _image == null
            ? Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: (isDark ? Colors.white : Colors.black).withOpacity(0.03),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.add_a_photo_outlined, size: 40, color: isDark ? Colors.white30 : Colors.black26),
                  ),
                  const SizedBox(height: 12),
                  Text('CAPTURE PHOTO EVIDENCE', style: TextStyle(color: isDark ? Colors.white24 : Colors.black38, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1)),
                ],
              )
            : Stack(
                fit: StackFit.expand,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: Image.file(_image!, fit: BoxFit.cover),
                  ),
                  Positioned(
                    top: 10, right: 10,
                    child: IconButton(
                      icon: const Icon(Icons.cancel, color: Colors.white70),
                      onPressed: () => setState(() => _image = null),
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildSubmitButton() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      child: ElevatedButton(
        onPressed: _isReporting ? null : _submitHazard,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppConstants.primaryRed,
          minimumSize: const Size(double.infinity, 60),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          elevation: 8,
          shadowColor: AppConstants.primaryRed.withOpacity(0.4),
        ),
        child: _isReporting 
            ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3)) 
            : const Text(
                'BROADCAST HAZARD ALERT',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, letterSpacing: 1.5),
              ),
      ),
    );
  }
}
