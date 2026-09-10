import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import '../services/firestore_service.dart';
import '../services/location_service.dart';
import '../models/incident_model.dart';
import '../core/constants.dart';

class HotspotCluster {
  final String barangay;
  final LatLng center;
  final int count;
  final String dominantHazard;
  final double densityScore; // 0.0 to 1.0

  HotspotCluster({
    required this.barangay,
    required this.center,
    required this.count,
    required this.dominantHazard,
    required this.densityScore,
  });
}

class HotspotIdentificationScreen extends StatefulWidget {
  const HotspotIdentificationScreen({super.key});

  @override
  State<HotspotIdentificationScreen> createState() => _HotspotIdentificationScreenState();
}

class _HotspotIdentificationScreenState extends State<HotspotIdentificationScreen> {
  GoogleMapController? _mapController;
  String _selectedHazardFilter = 'All';

  // Group incidents into geographical clusters per barangay
  List<HotspotCluster> _computeClusters(List<IncidentModel> incidents, LatLng fallbackCenter) {
    final filtered = _selectedHazardFilter == 'All'
        ? incidents
        : incidents.where((i) => i.incidentType.toLowerCase() == _selectedHazardFilter.toLowerCase()).toList();

    final Map<String, List<IncidentModel>> bgyMap = {};
    for (var inc in filtered) {
      final bgy = inc.barangay.isNotEmpty
          ? inc.barangay
          : (inc.location.split(',')[0].trim().isNotEmpty
              ? inc.location.split(',')[0].trim()
              : 'Active Zone');
      bgyMap.putIfAbsent(bgy, () => []).add(inc);
    }

    if (bgyMap.isEmpty) {
      return [];
    }

    int maxCount = 1;
    for (var list in bgyMap.values) {
      if (list.length > maxCount) maxCount = list.length;
    }

    List<HotspotCluster> clusters = [];
    bgyMap.forEach((bgy, list) {
      double sumLat = 0;
      double sumLng = 0;
      int validCoords = 0;
      final Map<String, int> typeTally = {};

      for (var inc in list) {
        typeTally[inc.incidentType] = (typeTally[inc.incidentType] ?? 0) + 1;
        if (inc.latitude != null && inc.longitude != null) {
          sumLat += inc.latitude!;
          sumLng += inc.longitude!;
          validCoords++;
        }
      }

      LatLng center = fallbackCenter;
      if (validCoords > 0) {
        center = LatLng(sumLat / validCoords, sumLng / validCoords);
      }

      String dominant = 'General';
      int topCount = 0;
      typeTally.forEach((t, c) {
        if (c > topCount) {
          topCount = c;
          dominant = t;
        }
      });

      final density = (list.length / maxCount).clamp(0.2, 1.0);
      clusters.add(HotspotCluster(
        barangay: bgy,
        center: center,
        count: list.length,
        dominantHazard: dominant,
        densityScore: density,
      ));
    });

    clusters.sort((a, b) => b.count.compareTo(a.count));
    return clusters;
  }

  Color _getDensityColor(double density) {
    if (density >= 0.8) return Colors.redAccent.withOpacity(0.45);
    if (density >= 0.55) return Colors.orangeAccent.withOpacity(0.40);
    if (density >= 0.35) return Colors.amberAccent.withOpacity(0.35);
    return Colors.greenAccent.withOpacity(0.30);
  }

  Color _getStrokeColor(double density) {
    if (density >= 0.8) return Colors.red;
    if (density >= 0.55) return Colors.orange;
    if (density >= 0.35) return Colors.amber;
    return Colors.green;
  }

  @override
  Widget build(BuildContext context) {
    final firestore = Provider.of<FirestoreService>(context, listen: false);
    final locationService = Provider.of<LocationService>(context);
    final userPos = locationService.currentPosition;
    final LatLng initialTarget = userPos != null
        ? LatLng(userPos.latitude, userPos.longitude)
        : const LatLng(14.5995, 120.9842);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text(
          'HOTSPOT IDENTIFICATION',
          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w900, letterSpacing: 1.5),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: StreamBuilder<List<IncidentModel>>(
        stream: firestore.getIncidents(),
        builder: (context, snapshot) {
          final incidents = snapshot.data ?? [];
          final clusters = _computeClusters(incidents, initialTarget);

          final Set<Circle> heatmapCircles = {};
          final Set<Marker> hotspotMarkers = {};

          for (int i = 0; i < clusters.length; i++) {
            final c = clusters[i];
            // Density heatmap circles (inner intense core + outer gradient halo)
            heatmapCircles.add(
              Circle(
                circleId: CircleId('outer_${c.barangay}_$i'),
                center: c.center,
                radius: 350 + (c.densityScore * 300),
                fillColor: _getDensityColor(c.densityScore),
                strokeColor: _getStrokeColor(c.densityScore).withOpacity(0.6),
                strokeWidth: 2,
              ),
            );

            heatmapCircles.add(
              Circle(
                circleId: CircleId('core_${c.barangay}_$i'),
                center: c.center,
                radius: 120 + (c.densityScore * 100),
                fillColor: _getStrokeColor(c.densityScore).withOpacity(0.55),
                strokeColor: _getStrokeColor(c.densityScore),
                strokeWidth: 2,
              ),
            );

            hotspotMarkers.add(
              Marker(
                markerId: MarkerId('hotspot_pin_${c.barangay}_$i'),
                position: c.center,
                icon: BitmapDescriptor.defaultMarkerWithHue(
                  c.densityScore >= 0.7 ? BitmapDescriptor.hueRed : BitmapDescriptor.hueOrange,
                ),
                infoWindow: InfoWindow(
                  title: 'HOTSPOT: ${c.barangay}',
                  snippet: '${c.count} Incidents • Dominant: ${c.dominantHazard}',
                ),
              ),
            );
          }

          return Stack(
            children: [
              GoogleMap(
                initialCameraPosition: CameraPosition(target: initialTarget, zoom: 13.5),
                onMapCreated: (ctrl) => _mapController = ctrl,
                circles: heatmapCircles,
                markers: hotspotMarkers,
                myLocationEnabled: true,
                zoomControlsEnabled: false,
              ),

              // Top Hazard Filter
              Positioned(
                top: 14,
                left: 14,
                right: 14,
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  child: Row(
                    children: [
                      _buildHazardChip('All'),
                      const SizedBox(width: 8),
                      _buildHazardChip('Fire'),
                      const SizedBox(width: 8),
                      _buildHazardChip('Flood'),
                      const SizedBox(width: 8),
                      _buildHazardChip('Crime'),
                      const SizedBox(width: 8),
                      _buildHazardChip('Accident'),
                    ],
                  ),
                ),
              ),

              // Bottom Hotspot Ranking Card
              Positioned(
                bottom: 20,
                left: 16,
                right: 16,
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: (isDark ? const Color(0xFF1E2841) : Colors.white).withOpacity(0.95),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withOpacity(0.18), blurRadius: 16, offset: const Offset(0, 6)),
                    ],
                    border: Border.all(color: isDark ? Colors.white12 : Colors.black12),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.whatshot_rounded, color: AppConstants.primaryRed, size: 18),
                              const SizedBox(width: 8),
                              Text(
                                'IDENTIFIED HOTSPOTS',
                                style: TextStyle(
                                  fontWeight: FontWeight.w900,
                                  fontSize: 12,
                                  letterSpacing: 1.1,
                                  color: isDark ? Colors.white : Colors.black87,
                                ),
                              ),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppConstants.primaryRed.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              '${clusters.length} CLUSTERS',
                              style: const TextStyle(color: AppConstants.primaryRed, fontSize: 10, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        height: 75,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: clusters.length,
                          itemBuilder: (ctx, idx) {
                            final cluster = clusters[idx];
                            final color = _getStrokeColor(cluster.densityScore);

                            return Container(
                              width: 175,
                              margin: const EdgeInsets.only(right: 10),
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: (isDark ? const Color(0xFF161E31) : const Color(0xFFF5F7FB)),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(color: color.withOpacity(0.4)),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    cluster.barangay,
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 11,
                                      color: isDark ? Colors.white : Colors.black87,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        '${cluster.count} Incidents',
                                        style: TextStyle(color: isDark ? Colors.white60 : Colors.black54, fontSize: 10),
                                      ),
                                      Text(
                                        cluster.dominantHazard.toUpperCase(),
                                        style: TextStyle(color: color, fontSize: 9, fontWeight: FontWeight.w900),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            );
                          },
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

  Widget _buildHazardChip(String hazard) {
    final isSelected = _selectedHazardFilter.toLowerCase() == hazard.toLowerCase();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: () => setState(() => _selectedHazardFilter = hazard),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected ? AppConstants.primaryRed : (isDark ? const Color(0xFF1E2841) : Colors.white).withOpacity(0.9),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 6, offset: const Offset(0, 2)),
          ],
        ),
        child: Text(
          hazard,
          style: TextStyle(
            color: isSelected ? Colors.white : (isDark ? Colors.white70 : Colors.black87),
            fontSize: 11,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
