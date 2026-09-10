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

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }

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
    if (density >= 0.8) return Colors.redAccent.withValues(alpha: 0.45);
    if (density >= 0.55) return Colors.orangeAccent.withValues(alpha: 0.40);
    if (density >= 0.35) return Colors.amberAccent.withValues(alpha: 0.35);
    return Colors.greenAccent.withValues(alpha: 0.30);
  }

  Color _getStrokeColor(double density) {
    if (density >= 0.8) return const Color(0xFFDC2626);
    if (density >= 0.55) return const Color(0xFFEA580C);
    if (density >= 0.35) return const Color(0xFFD97706);
    return const Color(0xFF16A34A);
  }

  @override
  Widget build(BuildContext context) {
    final firestore = Provider.of<FirestoreService>(context, listen: false);
    final locationService = Provider.of<LocationService>(context);
    final userPos = locationService.currentPosition;
    final LatLng initialTarget = userPos != null
        ? LatLng(userPos.latitude, userPos.longitude)
        : const LatLng(AppConstants.defaultLat, AppConstants.defaultLng);
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
          'HOTSPOT IDENTIFICATION',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.3,
            color: isDark ? Colors.white : AppColors.retroDarkBorder,
          ),
        ),
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
            // Density heatmap circles
            heatmapCircles.add(
              Circle(
                circleId: CircleId('outer_${c.barangay}_$i'),
                center: c.center,
                radius: 350 + (c.densityScore * 300),
                fillColor: _getDensityColor(c.densityScore),
                strokeColor: _getStrokeColor(c.densityScore).withValues(alpha: 0.6),
                strokeWidth: 2,
              ),
            );

            heatmapCircles.add(
              Circle(
                circleId: CircleId('core_${c.barangay}_$i'),
                center: c.center,
                radius: 120 + (c.densityScore * 100),
                fillColor: _getStrokeColor(c.densityScore).withValues(alpha: 0.55),
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
                myLocationButtonEnabled: false,
                zoomControlsEnabled: false,
              ),

              // Top Hazard Filter (Retro Horizontal Chips)
              Positioned(
                top: 14,
                left: 16,
                right: 16,
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  child: Row(
                    children: [
                      _buildRetroHazardChip('All', Icons.apps_rounded, AppColors.retroMint, isDark),
                      const SizedBox(width: 8),
                      _buildRetroHazardChip('Fire', Icons.local_fire_department_rounded, const Color(0xFFEF4444), isDark),
                      const SizedBox(width: 8),
                      _buildRetroHazardChip('Flood', Icons.water_drop_rounded, const Color(0xFF3B82F6), isDark),
                      const SizedBox(width: 8),
                      _buildRetroHazardChip('Crime', Icons.shield_rounded, const Color(0xFF8B5CF6), isDark),
                      const SizedBox(width: 8),
                      _buildRetroHazardChip('Accident', Icons.car_crash_rounded, const Color(0xFFF97316), isDark),
                    ],
                  ),
                ),
              ),

              // Retro Mint GPS FAB (matches GIS Mapping screen reference)
              Positioned(
                bottom: 200,
                right: 20,
                child: GestureDetector(
                  onTap: () async {
                    final pos = Provider.of<LocationService>(context, listen: false).currentPosition;
                    if (pos != null && _mapController != null) {
                      _mapController?.animateCamera(
                        CameraUpdate.newCameraPosition(
                          CameraPosition(target: LatLng(pos.latitude, pos.longitude), zoom: 15.0),
                        ),
                      );
                    }
                  },
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
                    child: const Icon(Icons.my_location_rounded, color: Colors.white, size: 20),
                  ),
                ),
              ),

              // Bottom Hotspot Ranking Card (Neo-Brutalist Retro)
              Positioned(
                bottom: 24,
                left: 16,
                right: 16,
                child: Container(
                  padding: const EdgeInsets.all(16),
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
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: AppColors.retroPeach,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: AppColors.retroDarkBorder, width: 1.2),
                                ),
                                child: const Icon(Icons.whatshot_rounded, color: Color(0xFFEA580C), size: 16),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'IDENTIFIED HOTSPOTS',
                                style: TextStyle(
                                  fontWeight: FontWeight.w900,
                                  fontSize: 11,
                                  letterSpacing: 1.1,
                                  color: isDark ? Colors.white : AppColors.retroDarkBorder,
                                ),
                              ),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFEE2E2),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: AppColors.retroDarkBorder, width: 1.2),
                            ),
                            child: Text(
                              '${clusters.length} CLUSTERS',
                              style: const TextStyle(
                                color: Color(0xFFDC2626),
                                fontSize: 9,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      if (clusters.isEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          child: Center(
                            child: Text(
                              'No density clusters found for selected filter.',
                              style: TextStyle(
                                color: isDark ? Colors.white54 : const Color(0xFF6B7280),
                                fontSize: 11,
                              ),
                            ),
                          ),
                        )
                      else
                        SizedBox(
                          height: 80,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            physics: const BouncingScrollPhysics(),
                            itemCount: clusters.length,
                            itemBuilder: (ctx, idx) {
                              final cluster = clusters[idx];
                              final strokeColor = _getStrokeColor(cluster.densityScore);

                              return GestureDetector(
                                onTap: () {
                                  _mapController?.animateCamera(
                                    CameraUpdate.newLatLngZoom(cluster.center, 15.0),
                                  );
                                },
                                child: Container(
                                  width: 170,
                                  margin: const EdgeInsets.only(right: 10),
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: isDark ? const Color(0xFF262C38) : AppColors.retroPeach,
                                    borderRadius: BorderRadius.circular(14),
                                    border: Border.all(
                                      color: isDark ? const Color(0xFF3E4556) : AppColors.retroDarkBorder,
                                      width: 1.4,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: isDark ? Colors.black38 : AppColors.retroDarkBorder.withValues(alpha: 0.1),
                                        offset: const Offset(2, 2),
                                        blurRadius: 0,
                                      ),
                                    ],
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        cluster.barangay,
                                        style: TextStyle(
                                          fontWeight: FontWeight.w900,
                                          fontSize: 12,
                                          color: isDark ? Colors.white : AppColors.retroDarkBorder,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 4),
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            '${cluster.count} Reports',
                                            style: TextStyle(
                                              color: isDark ? Colors.white60 : const Color(0xFF6B7280),
                                              fontSize: 10,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: Colors.white,
                                              borderRadius: BorderRadius.circular(6),
                                              border: Border.all(color: strokeColor, width: 1.0),
                                            ),
                                            child: Text(
                                              cluster.dominantHazard.toUpperCase(),
                                              style: TextStyle(
                                                color: strokeColor,
                                                fontSize: 8,
                                                fontWeight: FontWeight.w900,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
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

  Widget _buildRetroHazardChip(String hazard, IconData icon, Color typeColor, bool isDark) {
    final isSelected = _selectedHazardFilter.toLowerCase() == hazard.toLowerCase();

    Color activeFill = AppColors.retroMint;
    Color activeTextColor = Colors.white;
    if (hazard == 'Fire') activeFill = const Color(0xFFFEE2E2);
    if (hazard == 'Flood') activeFill = const Color(0xFFDBEAFE);
    if (hazard == 'Crime') activeFill = AppColors.retroLilac;
    if (hazard == 'Accident') activeFill = AppColors.retroPeach;
    if (hazard != 'All') activeTextColor = AppColors.retroDarkBorder;

    return GestureDetector(
      onTap: () => setState(() => _selectedHazardFilter = hazard),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected
              ? activeFill
              : (isDark ? AppColors.retroDarkCard : Colors.white),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isDark ? const Color(0xFF3E4556) : AppColors.retroDarkBorder,
            width: isSelected ? 1.8 : 1.4,
          ),
          boxShadow: [
            BoxShadow(
              color: isDark ? Colors.black45 : AppColors.retroDarkBorder,
              offset: isSelected ? const Offset(2.5, 2.5) : const Offset(1.5, 1.5),
              blurRadius: 0,
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 14,
              color: isSelected ? activeTextColor : (isDark ? Colors.white70 : typeColor),
            ),
            const SizedBox(width: 5),
            Text(
              hazard.toUpperCase(),
              style: TextStyle(
                color: isSelected
                    ? activeTextColor
                    : (isDark ? Colors.white70 : AppColors.retroDarkBorder),
                fontSize: 10,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
