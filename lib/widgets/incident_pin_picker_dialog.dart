import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../core/constants.dart';
import '../services/location_service.dart';

class IncidentPinPickerDialog extends StatefulWidget {
  final LatLng initialPosition;
  final String? initialBarangay;

  const IncidentPinPickerDialog({
    super.key,
    required this.initialPosition,
    this.initialBarangay,
  });

  @override
  State<IncidentPinPickerDialog> createState() => _IncidentPinPickerDialogState();
}

class _IncidentPinPickerDialogState extends State<IncidentPinPickerDialog> {
  late LatLng _selectedPin;
  late TextEditingController _barangayController;
  GoogleMapController? _mapController;

  @override
  void initState() {
    super.initState();
    _selectedPin = widget.initialPosition;
    _barangayController = TextEditingController(text: widget.initialBarangay ?? '');
    if (_barangayController.text.isEmpty) {
      _resolveLocationName(_selectedPin);
    }
  }

  @override
  void dispose() {
    _barangayController.dispose();
    super.dispose();
  }

  Future<void> _resolveLocationName(LatLng point) async {
    try {
      final name = await LocationService().reverseGeocode(point.latitude, point.longitude);
      if (mounted && name.isNotEmpty && name != 'Unknown Area') {
        setState(() => _barangayController.text = name);
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(22),
        side: const BorderSide(color: AppColors.retroDarkBorder, width: 2.0),
      ),
      backgroundColor: isDark ? AppColors.retroDarkCard : Colors.white,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: SizedBox(
          width: double.maxFinite,
          height: MediaQuery.of(context).size.height * 0.75,
          child: Column(
            children: [
              // ── Retro Header ──
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.retroDarkBorder : AppColors.retroMintLight,
                  border: Border(
                    bottom: BorderSide(
                      color: isDark ? const Color(0xFF3E4556) : AppColors.retroDarkBorder,
                      width: 1.8,
                    ),
                  ),
                ),
                child: Row(
                  children: [
                    // Retro Mint Icon Badge
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.retroMint,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppColors.retroDarkBorder, width: 1.4),
                        boxShadow: const [
                          BoxShadow(
                            color: AppColors.retroDarkBorder,
                            offset: Offset(2, 2),
                            blurRadius: 0,
                          ),
                        ],
                      ),
                      child: const Icon(Icons.pin_drop_rounded, color: Colors.white, size: 18),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'GIS INCIDENT PINNING',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1.2,
                              color: isDark ? Colors.white : AppColors.retroDarkBorder,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Tap or drag to mark exact GIS location',
                            style: TextStyle(
                              fontSize: 10,
                              color: isDark ? Colors.white60 : const Color(0xFF6B7280),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    GestureDetector(
                      onTap: () => Navigator.of(context).pop(),
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF2A2F3E) : const Color(0xFFF3F4F6),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: isDark ? const Color(0xFF3E4556) : AppColors.retroDarkBorder,
                            width: 1.2,
                          ),
                        ),
                        child: Icon(Icons.close_rounded, size: 16,
                            color: isDark ? Colors.white70 : AppColors.retroDarkBorder),
                      ),
                    ),
                  ],
                ),
              ),

              // Interactive Google Map
              Expanded(
                child: Stack(
                  children: [
                    GoogleMap(
                      initialCameraPosition: CameraPosition(
                        target: _selectedPin,
                        zoom: 15,
                      ),
                      onMapCreated: (controller) => _mapController = controller,
                      onTap: (point) {
                        setState(() => _selectedPin = point);
                        _mapController?.animateCamera(CameraUpdate.newLatLng(point));
                        _resolveLocationName(point);
                      },
                      markers: {
                        Marker(
                          markerId: const MarkerId('picked_incident_pin'),
                          position: _selectedPin,
                          draggable: true,
                          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
                          onDragEnd: (newPos) {
                            setState(() => _selectedPin = newPos);
                            _resolveLocationName(newPos);
                          },
                        ),
                      },
                    ),
                    // Retro Coordinate Banner Overlay
                    Positioned(
                      top: 12,
                      left: 14,
                      right: 14,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                        decoration: BoxDecoration(
                          color: AppColors.retroDarkBorder,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: const [
                            BoxShadow(color: Colors.black38, offset: Offset(2, 2), blurRadius: 0),
                          ],
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.gps_fixed_rounded, color: AppColors.retroMint, size: 13),
                            const SizedBox(width: 7),
                            Text(
                              'Lat: ${_selectedPin.latitude.toStringAsFixed(5)}, Lng: ${_selectedPin.longitude.toStringAsFixed(5)}',
                              style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w800),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // ── Retro Bottom: Barangay + Confirm ──
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.retroDarkCard : Colors.white,
                  border: Border(
                    top: BorderSide(
                      color: isDark ? const Color(0xFF3E4556) : AppColors.retroDarkBorder,
                      width: 1.8,
                    ),
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'DESIGNATED AREA / BARANGAY',
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.1,
                        color: isDark ? Colors.white38 : const Color(0xFF6B7280),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF1E2841) : Colors.white,
                        borderRadius: BorderRadius.circular(14),
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
                        controller: _barangayController,
                        style: TextStyle(
                          color: isDark ? Colors.white : AppColors.retroDarkBorder,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                        decoration: InputDecoration(
                          hintText: 'Enter area or barangay name...',
                          hintStyle: TextStyle(
                            color: isDark ? Colors.white30 : const Color(0xFF9CA3AF),
                            fontSize: 12,
                          ),
                          border: InputBorder.none,
                          isDense: true,
                          prefixIcon: const Icon(Icons.location_city_rounded, size: 18, color: AppColors.retroMint),
                          prefixIconConstraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Retro CONFIRM PIN LOCATION Button
                    GestureDetector(
                      onTap: () {
                        Navigator.of(context).pop({
                          'position': _selectedPin,
                          'barangay': _barangayController.text.trim().isNotEmpty
                              ? _barangayController.text.trim()
                              : 'Pin Area',
                        });
                      },
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        decoration: BoxDecoration(
                          color: AppColors.retroMint,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppColors.retroDarkBorder, width: 2.0),
                          boxShadow: const [
                            BoxShadow(
                              color: AppColors.retroDarkBorder,
                              offset: Offset(4, 4),
                              blurRadius: 0,
                            ),
                          ],
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.check_circle_rounded, color: Colors.white, size: 18),
                            SizedBox(width: 8),
                            Text(
                              'CONFIRM PIN LOCATION',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 0.9,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
