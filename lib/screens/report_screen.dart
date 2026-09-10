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
import '../services/location_service.dart';
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
  final _barangayController = TextEditingController();

  String _selectedIncidentType = AppConstants.incidentTypeFire;
  DateTime _incidentDateTime = DateTime.now();
  LatLng? _pinnedLocation;
  File? _image;
  bool _isReporting = false;
  bool _isLocationVerified = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final locService = Provider.of<LocationService>(context, listen: false);
      if (locService.currentPosition != null) {
        final pos = locService.currentPosition!;
        setState(() {
          _pinnedLocation = LatLng(pos.latitude, pos.longitude);
          _locationController.text = '${pos.latitude.toStringAsFixed(5)}, ${pos.longitude.toStringAsFixed(5)}';
          if (locService.currentLocationName != 'Detecting Location...') {
            _barangayController.text = locService.currentLocationName;
          }
          _isLocationVerified = true;
        });
      } else {
        _getCurrentLocation();
      }
    });
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _locationController.dispose();
    _barangayController.dispose();
    super.dispose();
  }

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
    if (!mounted) return;
    final locService = Provider.of<LocationService>(context, listen: false);
    String detectedName = locService.currentLocationName;
    if (detectedName.isEmpty || detectedName == 'Detecting Location...') {
      detectedName = await locService.reverseGeocode(position.latitude, position.longitude);
    }
    setState(() {
      _pinnedLocation = LatLng(position.latitude, position.longitude);
      _locationController.text = '${position.latitude.toStringAsFixed(5)}, ${position.longitude.toStringAsFixed(5)}';
      if (detectedName.isNotEmpty) {
        _barangayController.text = detectedName;
      }
      _isLocationVerified = true;
    });
  }

  void _openPinPicker() async {
    final defaultTarget = _pinnedLocation ??
        LatLng(
          Provider.of<LocationService>(context, listen: false).currentPosition?.latitude ?? AppConstants.defaultLat,
          Provider.of<LocationService>(context, listen: false).currentPosition?.longitude ?? AppConstants.defaultLng,
        );

    final selectedLatLng = await showDialog<LatLng>(
      context: context,
      builder: (ctx) => IncidentPinPickerDialog(initialPosition: defaultTarget),
    );

    if (selectedLatLng != null && mounted) {
      final locService = Provider.of<LocationService>(context, listen: false);
      final resolvedName = await locService.reverseGeocode(selectedLatLng.latitude, selectedLatLng.longitude);

      setState(() {
        _pinnedLocation = selectedLatLng;
        _locationController.text = '${selectedLatLng.latitude.toStringAsFixed(5)}, ${selectedLatLng.longitude.toStringAsFixed(5)}';
        if (resolvedName.isNotEmpty) {
          _barangayController.text = resolvedName;
        }
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

    if (pickedDate == null || !mounted) return;

    final pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_incidentDateTime),
    );

    if (pickedTime == null || !mounted) return;

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
          backgroundColor: AppColors.retroMint,
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

      final locText = _locationController.text.trim();
      final bgyText = _barangayController.text.trim();
      final resolvedBarangay = bgyText.isNotEmpty
          ? bgyText
          : (locText.isNotEmpty ? locText.split(',')[0].trim() : 'Local Area');

      final incident = IncidentModel(
        incidentId: nowMillis,
        referenceId: generatedRefId,
        userId: userId,
        incidentType: _selectedIncidentType,
        barangay: resolvedBarangay,
        description: _descriptionController.text.trim(),
        imageBase64: imageBase64,
        location: locText.isNotEmpty ? locText : resolvedBarangay,
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
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to submit report: $e'), backgroundColor: Colors.red),
        );
      }
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
        backgroundColor: isDark ? AppColors.retroDarkCard : Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: BorderSide(
            color: isDark ? const Color(0xFF3E4556) : AppColors.retroDarkBorder,
            width: 2.0,
          ),
        ),
        elevation: 0,
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFDCFCE7),
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.retroDarkBorder, width: 2.0),
              ),
              child: const Icon(Icons.check_circle_rounded, color: Color(0xFF16A34A), size: 40),
            ),
            const SizedBox(height: 16),
            Text(
              'REPORT SUBMITTED',
              style: TextStyle(
                color: isDark ? Colors.white : AppColors.retroDarkBorder,
                fontWeight: FontWeight.w900,
                fontSize: 17,
                letterSpacing: 0.8,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Reference ID: $refId',
              style: const TextStyle(
                color: Color(0xFF2563EB),
                fontWeight: FontWeight.w900,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'LGU Emergency Command has logged this GIS incident.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: isDark ? Colors.white60 : const Color(0xFF6B7280),
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 24),
            GestureDetector(
              onTap: () {
                Navigator.pop(ctx);
                Navigator.pop(context);
              },
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 13),
                decoration: BoxDecoration(
                  color: AppColors.retroPeach,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isDark ? const Color(0xFF4A3C38) : AppColors.retroDarkBorder,
                    width: 2.0,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: isDark ? Colors.black54 : AppColors.retroDarkBorder,
                      offset: const Offset(3, 3),
                      blurRadius: 0,
                    ),
                  ],
                ),
                child: const Center(
                  child: Text(
                    'BACK TO DASHBOARD',
                    style: TextStyle(
                      color: AppColors.retroDarkBorder,
                      fontWeight: FontWeight.w900,
                      fontSize: 12,
                      letterSpacing: 1.0,
                    ),
                  ),
                ),
              ),
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
          'INCIDENT GEO-REPORTING',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.3,
            color: isDark ? Colors.white : AppColors.retroDarkBorder,
          ),
        ),
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildRetroProtocolCard(isDark),
            const SizedBox(height: 20),

            // 1. Incident Type
            _buildSectionHeader('01. Incident Category', Icons.category_rounded, isDark),
            const SizedBox(height: 10),
            _buildIncidentTypeSelector(isDark),
            const SizedBox(height: 20),

            // 2. Location & GIS Pinning
            _buildSectionHeader('02. Location & Coordinate Pin', Icons.location_on_rounded, isDark),
            const SizedBox(height: 10),
            _buildLocationSection(isDark),
            const SizedBox(height: 20),

            // 3. Incident Description
            _buildSectionHeader('03. Incident Details', Icons.description_rounded, isDark),
            const SizedBox(height: 10),
            _buildRetroField(
              controller: _descriptionController,
              hint: 'Describe what happened (water depth, fire spread, casualties, trapped residents)...',
              maxLines: 4,
              isDark: isDark,
            ),
            const SizedBox(height: 20),

            // 4. Date & Time
            _buildSectionHeader('04. Date & Time of Occurrence', Icons.access_time_rounded, isDark),
            const SizedBox(height: 10),
            _buildDateTimeTile(isDark),
            const SizedBox(height: 20),

            // 5. Evidence Photo
            _buildSectionHeader('05. Camera Evidence / Photo', Icons.camera_alt_rounded, isDark),
            const SizedBox(height: 10),
            _buildImagePicker(isDark),
            const SizedBox(height: 30),

            // Submit Button
            _buildRetroSubmitButton(isDark),
            const SizedBox(height: 35),
          ],
        ),
      ),
    );
  }

  Widget _buildRetroProtocolCard(bool isDark) {
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
            child: const Icon(Icons.add_location_alt_rounded, color: Color(0xFFE11D48), size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'LGU GIS REPORTING PROTOCOL',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.0,
                    color: isDark ? Colors.white70 : AppColors.retroDarkBorder,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  'Geotagged reports feed directly into live disaster maps and risk clustering.',
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

  Widget _buildSectionHeader(String title, IconData icon, bool isDark) {
    return Row(
      children: [
        Icon(icon, color: AppColors.retroMint, size: 16),
        const SizedBox(width: 8),
        Text(
          title.toUpperCase(),
          style: TextStyle(
            color: isDark ? Colors.white70 : AppColors.retroDarkBorder,
            fontSize: 11,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.1,
          ),
        ),
      ],
    );
  }

  Widget _buildIncidentTypeSelector(bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: isDark ? AppColors.retroDarkCard : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? const Color(0xFF3E4556) : AppColors.retroDarkBorder,
          width: 1.8,
        ),
        boxShadow: [
          BoxShadow(
            color: isDark ? Colors.black38 : AppColors.retroDarkBorder.withOpacity(0.1),
            offset: const Offset(2.5, 2.5),
            blurRadius: 0,
          ),
        ],
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedIncidentType,
          isExpanded: true,
          dropdownColor: isDark ? AppColors.retroDarkCard : Colors.white,
          items: AppConstants.incidentTypes.map((type) {
            IconData icon = Icons.shield_rounded;
            Color iconColor = const Color(0xFF8B5CF6);
            if (type == AppConstants.incidentTypeFire) {
              icon = Icons.local_fire_department_rounded;
              iconColor = const Color(0xFFEF4444);
            } else if (type == AppConstants.incidentTypeFlood) {
              icon = Icons.water_drop_rounded;
              iconColor = const Color(0xFF3B82F6);
            } else if (type == AppConstants.incidentTypeMedical) {
              icon = Icons.medical_services_rounded;
              iconColor = const Color(0xFF10B981);
            } else if (type == AppConstants.incidentTypeAccident) {
              icon = Icons.car_crash_rounded;
              iconColor = const Color(0xFFEA580C);
            }

            return DropdownMenuItem<String>(
              value: type,
              child: Row(
                children: [
                  Icon(icon, color: iconColor, size: 18),
                  const SizedBox(width: 10),
                  Text(
                    type,
                    style: TextStyle(
                      color: isDark ? Colors.white : AppColors.retroDarkBorder,
                      fontWeight: FontWeight.w800,
                      fontSize: 13,
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

  Widget _buildLocationSection(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildRetroField(
          controller: _barangayController,
          hint: 'Barangay / District / Area...',
          isDark: isDark,
        ),
        const SizedBox(height: 10),
        _buildRetroField(
          controller: _locationController,
          hint: 'Street, landmark, or GPS coordinates...',
          isDark: isDark,
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: GestureDetector(
                onTap: _openPinPicker,
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF2A2338) : AppColors.retroLilac,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: isDark ? const Color(0xFF4A3C58) : AppColors.retroDarkBorder,
                      width: 1.8,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: isDark ? Colors.black38 : AppColors.retroDarkBorder.withOpacity(0.12),
                        offset: const Offset(2.5, 2.5),
                        blurRadius: 0,
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.pin_drop_rounded, size: 18, color: isDark ? Colors.white : AppColors.retroDarkBorder),
                      const SizedBox(width: 8),
                      Text(
                        'PIN ON GIS MAP',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.8,
                          color: isDark ? Colors.white : AppColors.retroDarkBorder,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            GestureDetector(
              onTap: _getCurrentLocation,
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _isLocationVerified ? const Color(0xFFDCFCE7) : (isDark ? AppColors.retroDarkCard : Colors.white),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isDark ? const Color(0xFF3E4556) : AppColors.retroDarkBorder,
                    width: 1.8,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: isDark ? Colors.black38 : AppColors.retroDarkBorder.withOpacity(0.12),
                      offset: const Offset(2.5, 2.5),
                      blurRadius: 0,
                    ),
                  ],
                ),
                child: Icon(
                  Icons.my_location_rounded,
                  color: _isLocationVerified ? const Color(0xFF16A34A) : AppColors.retroMint,
                  size: 20,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildRetroField({
    required TextEditingController controller,
    required String hint,
    int maxLines = 1,
    required bool isDark,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.retroDarkCard : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? const Color(0xFF3E4556) : AppColors.retroDarkBorder,
          width: 1.8,
        ),
        boxShadow: [
          BoxShadow(
            color: isDark ? Colors.black38 : AppColors.retroDarkBorder.withOpacity(0.1),
            offset: const Offset(2.5, 2.5),
            blurRadius: 0,
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        style: TextStyle(
          color: isDark ? Colors.white : AppColors.retroDarkBorder,
          fontSize: 13,
          fontWeight: FontWeight.w600,
        ),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(
            color: isDark ? Colors.white30 : const Color(0xFF9CA3AF),
            fontSize: 12,
            fontWeight: FontWeight.normal,
          ),
          filled: false,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          border: InputBorder.none,
        ),
      ),
    );
  }

  Widget _buildDateTimeTile(bool isDark) {
    final formatted = DateFormat('yyyy-MM-dd • hh:mm a').format(_incidentDateTime);

    return InkWell(
      onTap: _pickDateTime,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: isDark ? AppColors.retroDarkCard : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark ? const Color(0xFF3E4556) : AppColors.retroDarkBorder,
            width: 1.8,
          ),
          boxShadow: [
            BoxShadow(
              color: isDark ? Colors.black38 : AppColors.retroDarkBorder.withOpacity(0.1),
              offset: const Offset(2.5, 2.5),
              blurRadius: 0,
            ),
          ],
        ),
        child: Row(
          children: [
            const Icon(Icons.calendar_today_rounded, color: AppColors.retroMint, size: 18),
            const SizedBox(width: 12),
            Text(
              formatted,
              style: TextStyle(
                color: isDark ? Colors.white : AppColors.retroDarkBorder,
                fontSize: 13,
                fontWeight: FontWeight.w800,
              ),
            ),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: isDark ? Colors.white12 : const Color(0xFFF3F4F6),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isDark ? Colors.white24 : AppColors.retroDarkBorder,
                  width: 1.2,
                ),
              ),
              child: Text(
                'CHANGE',
                style: TextStyle(
                  color: isDark ? Colors.white70 : AppColors.retroDarkBorder,
                  fontSize: 9,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImagePicker(bool isDark) {
    return GestureDetector(
      onTap: _pickImage,
      child: Container(
        height: 130,
        decoration: BoxDecoration(
          color: isDark ? AppColors.retroDarkCard : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark ? const Color(0xFF3E4556) : AppColors.retroDarkBorder,
            width: 1.8,
          ),
          boxShadow: [
            BoxShadow(
              color: isDark ? Colors.black38 : AppColors.retroDarkBorder.withOpacity(0.1),
              offset: const Offset(2.5, 2.5),
              blurRadius: 0,
            ),
          ],
        ),
        child: _image != null
            ? ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: Image.file(_image!, width: double.infinity, fit: BoxFit.cover),
              )
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.retroPeach,
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.retroDarkBorder, width: 1.4),
                    ),
                    child: const Icon(Icons.camera_alt_rounded, size: 24, color: AppColors.retroDarkBorder),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Attach Camera Photo Evidence',
                    style: TextStyle(
                      color: isDark ? Colors.white60 : AppColors.retroDarkBorder,
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildRetroSubmitButton(bool isDark) {
    return GestureDetector(
      onTap: _isReporting ? null : _submitReport,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: _isReporting ? Colors.grey.shade400 : AppColors.retroMint,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.retroDarkBorder, width: 2.0),
          boxShadow: [
            BoxShadow(
              color: isDark ? Colors.black54 : AppColors.retroDarkBorder,
              offset: const Offset(4, 4),
              blurRadius: 0,
            ),
          ],
        ),
        child: Center(
          child: _isReporting
              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
              : const Text(
                  'SUBMIT INCIDENT REPORT',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.2,
                  ),
                ),
        ),
      ),
    );
  }
}
