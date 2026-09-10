import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import '../services/location_service.dart';
import '../core/constants.dart';
import 'report_screen.dart';

class IncidentPinningScreen extends StatefulWidget {
  const IncidentPinningScreen({super.key});

  @override
  State<IncidentPinningScreen> createState() => _IncidentPinningScreenState();
}

class _IncidentPinningScreenState extends State<IncidentPinningScreen> {
  GoogleMapController? _mapController;
  LatLng _pinnedLocation = const LatLng(AppConstants.defaultLat, AppConstants.defaultLng);
  String _pinnedBarangay = 'Detecting address...';
  bool _isGeocoding = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final loc = Provider.of<LocationService>(context, listen: false);
      if (loc.currentPosition != null) {
        final pos = loc.currentPosition!;
        setState(() {
          _pinnedLocation = LatLng(pos.latitude, pos.longitude);
        });
        _updateReverseGeocode(_pinnedLocation);
      }
    });
  }

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }

  Future<void> _updateReverseGeocode(LatLng target) async {
    setState(() => _isGeocoding = true);
    final locService = Provider.of<LocationService>(context, listen: false);
    final name = await locService.reverseGeocode(target.latitude, target.longitude);
    if (mounted) {
      setState(() {
        _pinnedBarangay = name.isNotEmpty ? name : 'Selected Location';
        _isGeocoding = false;
      });
    }
  }

  void _onCameraMove(CameraPosition position) {
    _pinnedLocation = position.target;
  }

  void _onCameraIdle() {
    _updateReverseGeocode(_pinnedLocation);
  }

  void _snapToGPS() async {
    final locService = Provider.of<LocationService>(context, listen: false);
    final pos = locService.currentPosition;
    if (pos != null) {
      final target = LatLng(pos.latitude, pos.longitude);
      _mapController?.animateCamera(CameraUpdate.newLatLngZoom(target, 16.5));
      setState(() => _pinnedLocation = target);
      _updateReverseGeocode(target);
    }
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
          '03. INCIDENT PINNING',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.3,
            color: isDark ? Colors.white : AppColors.retroDarkBorder,
          ),
        ),
      ),
      body: Stack(
        children: [
          // Full-Screen Google Map
          GoogleMap(
            initialCameraPosition: CameraPosition(target: _pinnedLocation, zoom: 16.0),
            onMapCreated: (ctrl) => _mapController = ctrl,
            onCameraMove: _onCameraMove,
            onCameraIdle: _onCameraIdle,
            myLocationEnabled: true,
            zoomControlsEnabled: false,
            compassEnabled: false,
          ),

          // Central Pinning Reticle
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.retroDarkBorder,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: const [
                      BoxShadow(color: Colors.black38, offset: Offset(2, 2), blurRadius: 4),
                    ],
                  ),
                  child: const Text(
                    'MOVE MAP TO PIN',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 9,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.8,
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                const Icon(
                  Icons.location_on_rounded,
                  size: 46,
                  color: AppColors.retroMint,
                ),
                const SizedBox(height: 38), // Center offset for pin tip
              ],
            ),
          ),

          // GPS Snap Button — Mint FAB (matches mapping screen reference)
          Positioned(
            right: 16,
            bottom: 220,
            child: GestureDetector(
              onTap: _snapToGPS,
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: const BoxDecoration(
                  color: AppColors.retroMint,
                  shape: BoxShape.circle,
                  border: Border.fromBorderSide(
                    BorderSide(color: AppColors.retroDarkBorder, width: 1.8),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.retroDarkBorder,
                      offset: Offset(3, 3),
                      blurRadius: 0,
                    ),
                  ],
                ),
                child: const Icon(Icons.my_location_rounded, color: Colors.white, size: 22),
              ),
            ),
          ),

          // Bottom Coordinate & Pin Action Card
          Positioned(
            bottom: 20,
            left: 16,
            right: 16,
            child: Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: isDark ? AppColors.retroDarkCard : Colors.white,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(
                  color: isDark ? const Color(0xFF3E4556) : AppColors.retroDarkBorder,
                  width: 2.0,
                ),
                boxShadow: [
                  BoxShadow(
                    color: isDark ? Colors.black54 : AppColors.retroDarkBorder,
                    offset: const Offset(4, 4),
                    blurRadius: 0,
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: AppColors.retroLilac,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: AppColors.retroDarkBorder, width: 1.2),
                            ),
                            child: const Icon(Icons.pin_drop_rounded, color: Color(0xFF2563EB), size: 16),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'GIS COORDINATE PIN',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1.1,
                              color: isDark ? Colors.white : AppColors.retroDarkBorder,
                            ),
                          ),
                        ],
                      ),
                      GestureDetector(
                        onTap: () {
                          final coords = '${_pinnedLocation.latitude.toStringAsFixed(6)}, ${_pinnedLocation.longitude.toStringAsFixed(6)}';
                          Clipboard.setData(ClipboardData(text: coords));
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Coordinates copied to clipboard!'), backgroundColor: Color(0xFF2563EB)),
                          );
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppColors.retroPeach,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: AppColors.retroDarkBorder, width: 1.0),
                          ),
                          child: const Row(
                            children: [
                              Icon(Icons.copy_rounded, size: 10, color: AppColors.retroDarkBorder),
                              SizedBox(width: 4),
                              Text('COPY', style: TextStyle(fontSize: 8, fontWeight: FontWeight.w900, color: AppColors.retroDarkBorder)),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Barangay / Address Name
                  Row(
                    children: [
                      const Icon(Icons.place_rounded, size: 18, color: AppColors.retroMint),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          _isGeocoding ? 'Detecting address...' : _pinnedBarangay,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            color: isDark ? Colors.white : AppColors.retroDarkBorder,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),

                  // Coordinates Text
                  Text(
                    'Lat: ${_pinnedLocation.latitude.toStringAsFixed(5)} • Lng: ${_pinnedLocation.longitude.toStringAsFixed(5)}',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: isDark ? Colors.white54 : const Color(0xFF6B7280),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Action Button: Report Incident at this Pin — MINT
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const ReportScreen(),
                        ),
                      );
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
                            offset: Offset(3, 3),
                            blurRadius: 0,
                          ),
                        ],
                      ),
                      child: const Center(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.add_location_alt_rounded, color: Colors.white, size: 18),
                            SizedBox(width: 8),
                            Text(
                              'REPORT INCIDENT AT THIS PIN',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 1.0,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
