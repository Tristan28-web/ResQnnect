import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:intl/intl.dart';
import '../services/firestore_service.dart';
import '../models/incident_model.dart';
import '../core/constants.dart';
import '../widgets/incident_pin_picker_dialog.dart';

class ReportScreen extends StatefulWidget {
  const ReportScreen({super.key});

  @override
  State<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen> {
  final _descriptionController = TextEditingController();
  final _locationController = TextEditingController();

  String _selectedIncidentType = AppConstants.incidentTypeFire;
  String _selectedBarangay = AppConstants.lguBarangays.first;
  DateTime _incidentDateTime = DateTime.now();
  LatLng? _pinnedLocation;
  File? _image;
  bool _isReporting = false;
  bool _isLocationVerified = false;

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 35,
    );
    if (pickedFile != null) {
      setState(() => _image = File(pickedFile.path));
    }
  }

  Future<void> _getCurrentLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return;

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return;
    }
    if (permission == LocationPermission.deniedForever) return;

    final position = await Geolocator.getCurrentPosition();
    setState(() {
      _pinnedLocation = LatLng(position.latitude, position.longitude);
      _locationController.text = '${position.latitude.toStringAsFixed(5)}, ${position.longitude.toStringAsFixed(5)}';
      _isLocationVerified = true;
    });
  }

  Future<void> _openPinPicker() async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (ctx) => IncidentPinPickerDialog(
        initialPosition: _pinnedLocation ?? const LatLng(10.9574, 123.2978),
        initialBarangay: _selectedBarangay,
      ),
    );

    if (result != null) {
      final LatLng pos = result['position'];
      final String bgy = result['barangay'];
      setState(() {
        _pinnedLocation = pos;
        _selectedBarangay = bgy;
        _locationController.text = '$bgy (${pos.latitude.toStringAsFixed(4)}, ${pos.longitude.toStringAsFixed(4)})';
        _isLocationVerified = true;
      });
    }
  }

  Future<void> _pickDateTime() async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _incidentDateTime,
      firstDate: DateTime.now().subtract(const Duration(days: 30)),
      lastDate: DateTime.now().add(const Duration(days: 1)),
    );
    if (pickedDate == null) return;

    final pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_incidentDateTime),
    );
    if (pickedTime == null) return;

    setState(() {
      _incidentDateTime = DateTime(
        pickedDate.year,
        pickedDate.month,
        pickedDate.day,
        pickedTime.hour,
        pickedTime.minute,
      );
    });
  }

  void _submitReport() async {
    if (_descriptionController.text.trim().isEmpty || _locationController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please provide incident description and location'),
          backgroundColor: AppConstants.primaryRed,
        ),
      );
      return;
    }

    setState(() => _isReporting = true);

    try {
      final firestoreService = Provider.of<FirestoreService>(context, listen: false);
      final userId = FirebaseAuth.instance.currentUser?.uid ?? 'anonymous';

      String? imageBase64;
      if (_image != null) {
        final bytes = await _image!.readAsBytes();
        imageBase64 = base64Encode(bytes);
      }

      final nowMillis = DateTime.now().millisecondsSinceEpoch.toString();
      final suffix = nowMillis.length > 4 ? nowMillis.substring(nowMillis.length - 4) : '001';
      final generatedRefId = 'INC-$suffix';

      final incident = IncidentModel(
        incidentId: nowMillis,
        referenceId: generatedRefId,
        userId: userId,
        incidentType: _selectedIncidentType,
        barangay: _selectedBarangay,
        description: _descriptionController.text.trim(),
        imageBase64: imageBase64,
        location: _locationController.text.trim(),
        latitude: _pinnedLocation?.latitude,
        longitude: _pinnedLocation?.longitude,
        severity: _selectedIncidentType == AppConstants.incidentTypeFire || _selectedIncidentType == AppConstants.incidentTypeFlood
            ? 'high'
            : 'medium',
        status: 'pending',
        timestamp: _incidentDateTime,
      );

      await firestoreService.reportIncident(incident);

      if (mounted) {
        _showSuccessDialog(generatedRefId);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to submit report: $e'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _isReporting = false);
    }
  }

  void _showSuccessDialog(String refId) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF1E2841) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        elevation: 24,
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
              child: const Icon(Icons.check_circle_rounded, color: Colors.greenAccent, size: 48),
            ),
            const SizedBox(height: 20),
            Text(
              'REPORT SUBMITTED',
              style: TextStyle(
                color: isDark ? Colors.white : Colors.black87,
                fontWeight: FontWeight.bold,
                fontSize: 18,
                letterSpacing: 1,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: AppConstants.primaryRed.withOpacity(0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                'Tracking ID: $refId',
                style: const TextStyle(
                  color: AppConstants.primaryRed,
                  fontWeight: FontWeight.w900,
                  fontSize: 14,
                  letterSpacing: 1.1,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'LGU dispatch and responders have received this incident. Please keep safe.',
              textAlign: TextAlign.center,
              style: TextStyle(color: isDark ? Colors.white60 : Colors.black54, fontSize: 13),
            ),
            const SizedBox(height: 28),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppConstants.primaryRed,
                minimumSize: const Size(double.infinity, 48),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              onPressed: () {
                Navigator.pop(ctx);
                Navigator.pop(context);
              },
              child: const Text('BACK TO DASHBOARD', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text(
          'INCIDENT REPORTING',
          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w900, letterSpacing: 1.5),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildInfoCard(),
            const SizedBox(height: 24),

            // 1. Incident Type (Dropdown from blueprint)
            _buildSectionTitle('1. Incident Type', Icons.category_rounded),
            const SizedBox(height: 10),
            _buildIncidentTypeSelector(),
            const SizedBox(height: 24),

            // 2. Location & GIS Pinning
            _buildSectionTitle('2. Location & GIS Pin', Icons.location_on_rounded),
            const SizedBox(height: 10),
            _buildLocationSection(),
            const SizedBox(height: 24),

            // 3. Description
            _buildSectionTitle('3. Incident Description', Icons.description_rounded),
            const SizedBox(height: 10),
            _buildGlassField(
              controller: _descriptionController,
              hint: 'Provide clear details of the incident (e.g. water rising, electrical fire, injured persons)...',
              maxLines: 4,
            ),
            const SizedBox(height: 24),

            // 4. Date & Time
            _buildSectionTitle('4. Date & Time', Icons.access_time_rounded),
            const SizedBox(height: 10),
            _buildDateTimeTile(),
            const SizedBox(height: 24),

            // 5. Photo Attachment
            _buildSectionTitle('5. Attachment / Evidence', Icons.camera_alt_rounded),
            const SizedBox(height: 10),
            _buildImagePicker(),
            const SizedBox(height: 36),

            // Submit Button
            _buildSubmitButton(),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title, IconData icon) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Row(
      children: [
        Icon(icon, color: AppConstants.primaryRed, size: 18),
        const SizedBox(width: 8),
        Text(
          title.toUpperCase(),
          style: TextStyle(
            color: isDark ? Colors.white70 : Colors.black87.withOpacity(0.7),
            fontSize: 11,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.2,
          ),
        ),
      ],
    );
  }

  Widget _buildIncidentTypeSelector() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E2841) : Colors.black.withOpacity(0.04),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? Colors.white12 : Colors.black12),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedIncidentType,
          isExpanded: true,
          dropdownColor: isDark ? const Color(0xFF1E2841) : Colors.white,
          items: AppConstants.incidentTypes.map((type) {
            IconData icon = Icons.warning_rounded;
            Color iconColor = Colors.amber;
            if (type == AppConstants.incidentTypeFire) {
              icon = Icons.local_fire_department_rounded;
              iconColor = AppConstants.primaryRed;
            } else if (type == AppConstants.incidentTypeFlood) {
              icon = Icons.waves_rounded;
              iconColor = Colors.blue;
            } else if (type == AppConstants.incidentTypeCrime) {
              icon = Icons.shield_rounded;
              iconColor = Colors.purpleAccent;
            } else if (type == AppConstants.incidentTypeAccident) {
              icon = Icons.car_crash_rounded;
              iconColor = Colors.orange;
            }

            return DropdownMenuItem<String>(
              value: type,
              child: Row(
                children: [
                  Icon(icon, color: iconColor, size: 20),
                  const SizedBox(width: 12),
                  Text(
                    type,
                    style: TextStyle(
                      color: isDark ? Colors.white : Colors.black87,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
          onChanged: (val) {
            if (val != null) setState(() => _selectedIncidentType = val);
          },
        ),
      ),
    );
  }

  Widget _buildLocationSection() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Barangay dropdown
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E2841) : Colors.black.withOpacity(0.04),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: isDark ? Colors.white12 : Colors.black12),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _selectedBarangay,
              isExpanded: true,
              dropdownColor: isDark ? const Color(0xFF1E2841) : Colors.white,
              items: AppConstants.lguBarangays.map((bgy) {
                return DropdownMenuItem<String>(
                  value: bgy,
                  child: Text(
                    bgy,
                    style: TextStyle(
                      color: isDark ? Colors.white : Colors.black87,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                );
              }).toList(),
              onChanged: (val) {
                if (val != null) setState(() => _selectedBarangay = val);
              },
            ),
          ),
        ),
        const SizedBox(height: 10),

        // Text input for specific street/landmark
        _buildGlassField(
          controller: _locationController,
          hint: 'Enter street, landmark, or GPS coordinates...',
        ),
        const SizedBox(height: 10),

        // Pin on GIS Map & GPS buttons
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppConstants.primaryRed,
                  side: const BorderSide(color: AppConstants.primaryRed),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                icon: const Icon(Icons.pin_drop_rounded, size: 18),
                label: const Text('PIN ON GIS MAP', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900)),
                onPressed: _openPinPicker,
              ),
            ),
            const SizedBox(width: 10),
            IconButton(
              icon: Icon(Icons.my_location_rounded, color: _isLocationVerified ? Colors.greenAccent : AppConstants.primaryRed),
              style: IconButton.styleFrom(
                backgroundColor: isDark ? const Color(0xFF1E2841) : Colors.black.withOpacity(0.05),
                padding: const EdgeInsets.all(12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              onPressed: _getCurrentLocation,
              tooltip: 'Use GPS Location',
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDateTimeTile() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final formatted = DateFormat('yyyy-MM-dd • hh:mm a').format(_incidentDateTime);

    return InkWell(
      onTap: _pickDateTime,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E2841) : Colors.black.withOpacity(0.04),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: isDark ? Colors.white12 : Colors.black12),
        ),
        child: Row(
          children: [
            const Icon(Icons.calendar_today_rounded, color: AppConstants.primaryRed, size: 18),
            const SizedBox(width: 12),
            Text(
              formatted,
              style: TextStyle(
                color: isDark ? Colors.white : Colors.black87,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
            const Spacer(),
            Text(
              'CHANGE',
              style: TextStyle(
                color: isDark ? Colors.white38 : Colors.black45,
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppConstants.primaryRed.withOpacity(isDark ? 0.12 : 0.08),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppConstants.primaryRed.withOpacity(0.25)),
      ),
      child: const Row(
        children: [
          Icon(Icons.shield_rounded, color: AppConstants.primaryRed, size: 22),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              'LGU Incident Dispatch System. False reports are subject to penalty under RA 10121.',
              style: TextStyle(color: AppConstants.primaryRed, fontSize: 12, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGlassField({required TextEditingController controller, required String hint, int maxLines = 1}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return TextField(
      controller: controller,
      maxLines: maxLines,
      style: TextStyle(color: isDark ? Colors.white : Colors.black87, fontSize: 14),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: isDark ? Colors.white24 : Colors.black26, fontSize: 13),
        filled: true,
        fillColor: isDark ? const Color(0xFF1E2841) : Colors.black.withOpacity(0.04),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  Widget _buildImagePicker() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: _pickImage,
      child: Container(
        height: 130,
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E2841) : Colors.black.withOpacity(0.04),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: isDark ? Colors.white12 : Colors.black12, style: BorderStyle.solid),
        ),
        child: _image != null
            ? ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.file(_image!, width: double.infinity, fit: BoxFit.cover),
              )
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.add_a_photo_rounded, size: 32, color: (isDark ? Colors.white : Colors.black).withOpacity(0.3)),
                  const SizedBox(height: 8),
                  Text(
                    'Attach Camera Photo Evidence',
                    style: TextStyle(color: (isDark ? Colors.white : Colors.black).withOpacity(0.4), fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildSubmitButton() {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppConstants.primaryRed,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: 4,
      ),
      onPressed: _isReporting ? null : _submitReport,
      child: _isReporting
          ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
          : const Text(
              'SUBMIT INCIDENT REPORT',
              style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w900, letterSpacing: 1.2),
            ),
    );
  }
}
