import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../services/firestore_service.dart';
import '../models/incident_model.dart';
import '../core/constants.dart';

class IncidentMappingScreen extends StatefulWidget {
  const IncidentMappingScreen({super.key});

  @override
  State<IncidentMappingScreen> createState() => _IncidentMappingScreenState();
}

class _IncidentMappingScreenState extends State<IncidentMappingScreen> {
  GoogleMapController? _mapController;
  String _selectedFilter = 'All';
  IncidentModel? _selectedIncident;

  static const LatLng _catanduanesCenter = LatLng(13.5840, 124.2330);

  double _getMarkerHue(String type) {
    switch (type.toLowerCase()) {
      case 'fire':
        return BitmapDescriptor.hueRed;
      case 'flood':
        return BitmapDescriptor.hueAzure;
      case 'crime':
        return BitmapDescriptor.hueViolet;
      case 'accident':
        return BitmapDescriptor.hueOrange;
      default:
        return BitmapDescriptor.hueYellow;
    }
  }

  Color _getTypeColor(String type) {
    switch (type.toLowerCase()) {
      case 'fire':
        return AppConstants.primaryRed;
      case 'flood':
        return Colors.blue;
      case 'crime':
        return Colors.purpleAccent;
      case 'accident':
        return Colors.orange;
      default:
        return Colors.amber;
    }
  }

  IconData _getTypeIcon(String type) {
    switch (type.toLowerCase()) {
      case 'fire':
        return Icons.local_fire_department_rounded;
      case 'flood':
        return Icons.waves_rounded;
      case 'crime':
        return Icons.shield_rounded;
      case 'accident':
        return Icons.car_crash_rounded;
      default:
        return Icons.warning_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final firestore = Provider.of<FirestoreService>(context, listen: false);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text(
          'GIS INCIDENT MAPPING',
          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w900, letterSpacing: 1.5),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: StreamBuilder<List<IncidentModel>>(
        stream: firestore.getIncidents(),
        builder: (context, snapshot) {
          final allIncidents = snapshot.data ?? [];
          final filteredIncidents = _selectedFilter == 'All'
              ? allIncidents
              : allIncidents.where((i) => i.incidentType.toLowerCase() == _selectedFilter.toLowerCase()).toList();

          final Set<Marker> markers = {};
          for (var inc in filteredIncidents) {
            final lat = inc.latitude ?? 10.9574;
            final lng = inc.longitude ?? 123.2978;

            markers.add(
              Marker(
                markerId: MarkerId(inc.incidentId),
                position: LatLng(lat, lng),
                icon: BitmapDescriptor.defaultMarkerWithHue(_getMarkerHue(inc.incidentType)),
                infoWindow: InfoWindow(
                  title: '${inc.referenceId} • ${inc.incidentType}',
                  snippet: inc.barangay,
                ),
                onTap: () {
                  setState(() => _selectedIncident = inc);
                  _showIncidentDetailsSheet(inc);
                },
              ),
            );
          }

          return Stack(
            children: [
              GoogleMap(
                initialCameraPosition: const CameraPosition(
                  target: _catanduanesCenter,
                  zoom: 12.5,
                ),
                onMapCreated: (controller) => _mapController = controller,
                markers: markers,
                myLocationEnabled: false,
                zoomControlsEnabled: false,
              ),

              // Filter Chips on Top
              Positioned(
                top: 16,
                left: 12,
                right: 12,
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  child: Row(
                    children: [
                      _buildFilterChip('All', Icons.apps_rounded, Colors.white),
                      const SizedBox(width: 8),
                      _buildFilterChip('Fire', Icons.local_fire_department_rounded, AppConstants.primaryRed),
                      const SizedBox(width: 8),
                      _buildFilterChip('Flood', Icons.waves_rounded, Colors.blue),
                      const SizedBox(width: 8),
                      _buildFilterChip('Crime', Icons.shield_rounded, Colors.purpleAccent),
                      const SizedBox(width: 8),
                      _buildFilterChip('Accident', Icons.car_crash_rounded, Colors.orange),
                    ],
                  ),
                ),
              ),

              // Bottom Incident Count Badge
              Positioned(
                bottom: 24,
                left: 20,
                right: 20,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF262C38) : AppColors.retroPeach,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isDark ? const Color(0xFF3E4556) : AppColors.retroDarkBorder,
                      width: 1.8,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: isDark ? Colors.black54 : AppColors.retroMintDark,
                        offset: const Offset(3, 3),
                        blurRadius: 0,
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 10,
                            height: 10,
                            decoration: BoxDecoration(
                              color: const Color(0xFF22C55E),
                              shape: BoxShape.circle,
                              border: Border.all(color: AppColors.retroDarkBorder, width: 1.2),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            'Active GIS Incidents: ${filteredIncidents.length}',
                            style: TextStyle(
                              color: isDark ? Colors.white : AppColors.retroDarkBorder,
                              fontWeight: FontWeight.w900,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF1E222D) : AppColors.retroLilac,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: isDark ? const Color(0xFF4A3C38) : AppColors.retroDarkBorder,
                            width: 1.2,
                          ),
                        ),
                        child: Text(
                          _selectedFilter.toUpperCase(),
                          style: TextStyle(
                            color: isDark ? Colors.white : AppColors.retroDarkBorder,
                            fontWeight: FontWeight.w900,
                            fontSize: 10,
                            letterSpacing: 0.8,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildFilterChip(String label, IconData icon, Color color) {
    final isSelected = _selectedFilter.toLowerCase() == label.toLowerCase();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    Color activeFill = AppColors.retroMint;
    if (label == 'Fire') activeFill = const Color(0xFFFEE2E2);
    if (label == 'Flood') activeFill = const Color(0xFFDBEAFE);
    if (label == 'Crime') activeFill = AppColors.retroLilac;
    if (label == 'Accident') activeFill = AppColors.retroPeach;

    Color activeTextColor = AppColors.retroDarkBorder;
    if (label == 'All') {
      activeFill = AppColors.retroMint;
      activeTextColor = Colors.white;
    }

    return GestureDetector(
      onTap: () => setState(() => _selectedFilter = label),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? activeFill
              : (isDark ? AppColors.retroDarkCard : Colors.white),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark ? const Color(0xFF3E4556) : AppColors.retroDarkBorder,
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: isDark ? Colors.black38 : AppColors.retroDarkBorder.withOpacity(0.12),
              offset: const Offset(2, 2),
              blurRadius: 0,
            ),
          ],
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 15,
              color: isSelected ? activeTextColor : (isDark ? Colors.white70 : color),
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? activeTextColor : (isDark ? Colors.white70 : AppColors.retroDarkBorder),
                fontSize: 11,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.3,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showIncidentDetailsSheet(IncidentModel incident) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final color = _getTypeColor(incident.incidentType);

    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? AppColors.retroDarkCard : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        side: BorderSide(color: AppColors.retroDarkBorder, width: 2),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white24 : AppColors.retroDarkBorder.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: AppColors.retroPeach,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.retroDarkBorder, width: 1.4),
                    ),
                    child: Row(
                      children: [
                        Icon(_getTypeIcon(incident.incidentType), color: AppColors.retroDarkBorder, size: 14),
                        const SizedBox(width: 6),
                        Text(
                          incident.incidentType.toUpperCase(),
                          style: const TextStyle(
                            color: AppColors.retroDarkBorder,
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.retroLilac,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.retroDarkBorder, width: 1.2),
                    ),
                    child: Text(
                      incident.referenceId,
                      style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.8,
                        fontSize: 11,
                        color: AppColors.retroDarkBorder,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                incident.barangay,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: isDark ? Colors.white : AppColors.retroDarkBorder,
                ),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(Icons.location_on_rounded, size: 14, color: AppColors.retroMint),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      incident.location,
                      style: TextStyle(
                        color: isDark ? Colors.white70 : const Color(0xFF4B5563),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Text(
                incident.description,
                style: TextStyle(
                  color: isDark ? Colors.white : AppColors.retroDarkBorder,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Icon(Icons.access_time_rounded, size: 14, color: isDark ? Colors.white38 : const Color(0xFF9CA3AF)),
                  const SizedBox(width: 6),
                  Text(
                    DateFormat('yyyy-MM-dd • hh:mm a').format(incident.timestamp),
                    style: TextStyle(
                      color: isDark ? Colors.white38 : const Color(0xFF9CA3AF),
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: incident.status == 'resolved' ? const Color(0xFFDCFCE7) : AppColors.retroYellow,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.retroDarkBorder, width: 1.2),
                    ),
                    child: Text(
                      incident.status.toUpperCase(),
                      style: TextStyle(
                        color: incident.status == 'resolved' ? const Color(0xFF16A34A) : const Color(0xFFD97706),
                        fontSize: 9,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }
}
