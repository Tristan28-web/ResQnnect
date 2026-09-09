import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../core/constants.dart';

class IncidentPinPickerDialog extends StatefulWidget {
  final LatLng initialPosition;
  final String? initialBarangay;

  const IncidentPinPickerDialog({
    super.key,
    this.initialPosition = const LatLng(10.9574, 123.2978), // Cadiz City Center
    this.initialBarangay,
  });

  @override
  State<IncidentPinPickerDialog> createState() => _IncidentPinPickerDialogState();
}

class _IncidentPinPickerDialogState extends State<IncidentPinPickerDialog> {
  late LatLng _selectedPin;
  late String _selectedBarangay;
  GoogleMapController? _mapController;

  @override
  void initState() {
    super.initState();
    _selectedPin = widget.initialPosition;
    _selectedBarangay = widget.initialBarangay ?? AppConstants.lguBarangays.first;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      backgroundColor: isDark ? const Color(0xFF1E2841) : Colors.white,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: SizedBox(
          width: double.maxFinite,
          height: MediaQuery.of(context).size.height * 0.75,
          child: Column(
            children: [
              // Header
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                color: isDark ? const Color(0xFF161E31) : const Color(0xFFF0F4FF),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppConstants.primaryRed.withOpacity(0.15),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.pin_drop_rounded, color: AppConstants.primaryRed, size: 22),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'INCIDENT PINNING',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1.2,
                              color: isDark ? Colors.white : Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Tap or drag to mark exact GIS location',
                            style: TextStyle(
                              fontSize: 11,
                              color: isDark ? Colors.white60 : Colors.black54,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded),
                      onPressed: () => Navigator.of(context).pop(),
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
                      },
                      markers: {
                        Marker(
                          markerId: const MarkerId('picked_incident_pin'),
                          position: _selectedPin,
                          draggable: true,
                          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
                          onDragEnd: (newPos) {
                            setState(() => _selectedPin = newPos);
                          },
                        ),
                      },
                    ),
                    // Coordinate banner overlay
                    Positioned(
                      top: 12,
                      left: 16,
                      right: 16,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.75),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.gps_fixed_rounded, color: Colors.greenAccent, size: 14),
                            const SizedBox(width: 8),
                            Text(
                              'Lat: ${_selectedPin.latitude.toStringAsFixed(5)}, Lng: ${_selectedPin.longitude.toStringAsFixed(5)}',
                              style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Bottom Barangay Selector & Confirm
              Container(
                padding: const EdgeInsets.all(18),
                color: isDark ? const Color(0xFF161E31) : Colors.white,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'DESIGNATED BARANGAY',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.0,
                        color: isDark ? Colors.white38 : Colors.black45,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF1E2841) : const Color(0xFFF5F7FB),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: isDark ? Colors.white12 : Colors.black12),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _selectedBarangay,
                          isExpanded: true,
                          dropdownColor: isDark ? const Color(0xFF1E2841) : Colors.white,
                          style: TextStyle(
                            color: isDark ? Colors.white : Colors.black87,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                          items: AppConstants.lguBarangays.map((bgy) {
                            return DropdownMenuItem<String>(
                              value: bgy,
                              child: Text(bgy),
                            );
                          }).toList(),
                          onChanged: (val) {
                            if (val != null) {
                              setState(() => _selectedBarangay = val);
                            }
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppConstants.primaryRed,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        elevation: 0,
                      ),
                      icon: const Icon(Icons.check_circle_rounded, size: 18),
                      label: const Text(
                        'CONFIRM PIN LOCATION',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, letterSpacing: 0.8),
                      ),
                      onPressed: () {
                        Navigator.of(context).pop({
                          'position': _selectedPin,
                          'barangay': _selectedBarangay,
                        });
                      },
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
