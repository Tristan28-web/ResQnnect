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
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                  decoration: BoxDecoration(
                    color: (isDark ? const Color(0xFF1E2841) : Colors.white).withOpacity(0.95),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.15),
                        blurRadius: 15,
                        offset: const Offset(0, 5),
                      ),
                    ],
                    border: Border.all(color: isDark ? Colors.white12 : Colors.black12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 10,
                            height: 10,
                            decoration: const BoxDecoration(
                              color: Colors.greenAccent,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            'Active GIS Incidents: ${filteredIncidents.length}',
                            style: TextStyle(
                              color: isDark ? Colors.white : Colors.black87,
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                      Text(
                        _selectedFilter.toUpperCase(),
                        style: TextStyle(
                          color: _getTypeColor(_selectedFilter),
                          fontWeight: FontWeight.w900,
                          fontSize: 11,
                          letterSpacing: 1.0,
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

    return GestureDetector(
      onTap: () => setState(() => _selectedFilter = label),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? (color == Colors.white ? AppConstants.primaryRed : color)
              : (isDark ? const Color(0xFF1E2841) : Colors.white).withOpacity(0.9),
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            Icon(icon, size: 16, color: isSelected ? Colors.white : color),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : (isDark ? Colors.white70 : Colors.black87),
                fontSize: 12,
                fontWeight: FontWeight.bold,
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
      backgroundColor: isDark ? const Color(0xFF1E2841) : Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.all(22),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(_getTypeIcon(incident.incidentType), color: color, size: 14),
                        const SizedBox(width: 6),
                        Text(
                          incident.incidentType.toUpperCase(),
                          style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w900),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    incident.referenceId,
                    style: const TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1.0, fontSize: 13),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Text(
                incident.barangay,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                incident.location,
                style: TextStyle(color: isDark ? Colors.white60 : Colors.black54, fontSize: 13),
              ),
              const SizedBox(height: 12),
              Text(
                incident.description,
                style: TextStyle(color: isDark ? Colors.white : Colors.black87, fontSize: 14),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Icon(Icons.access_time_rounded, size: 14, color: isDark ? Colors.white38 : Colors.black38),
                  const SizedBox(width: 6),
                  Text(
                    DateFormat('yyyy-MM-dd • hh:mm a').format(incident.timestamp),
                    style: TextStyle(color: isDark ? Colors.white38 : Colors.black38, fontSize: 12),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: (incident.status == 'resolved' ? Colors.green : Colors.orange).withOpacity(0.15),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      incident.status.toUpperCase(),
                      style: TextStyle(
                        color: incident.status == 'resolved' ? Colors.greenAccent : Colors.orange,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
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
