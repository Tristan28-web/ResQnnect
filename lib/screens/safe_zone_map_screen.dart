import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import 'package:geolocator/geolocator.dart';
import '../core/constants.dart';
import '../models/map_location_model.dart';
import '../services/firestore_service.dart';
import '../services/location_service.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class SafeZoneMapScreen extends StatefulWidget {
  const SafeZoneMapScreen({super.key});

  @override
  State<SafeZoneMapScreen> createState() => _SafeZoneMapScreenState();
}

class _SafeZoneMapScreenState extends State<SafeZoneMapScreen> {
  GoogleMapController? _mapController;
  LatLng? _currentPosition;
  bool _isLoadingLocation = true;
  MapLocationModel? _nearestSafeZone;
  double? _distanceToNearest;
  Stream<List<MapLocationModel>>? _locationsStream;
  Set<Polyline> _polylines = {};
  LatLng? _activeRouteDestination;
  bool _isFetchingRoute = false;

  static const LatLng _catanduanesCenter = LatLng(13.5840, 124.2330);

  @override
  void initState() {
    super.initState();
    final firestore = Provider.of<FirestoreService>(context, listen: false);
    _locationsStream = firestore.getMapLocations();
    _initLocation();
  }

  Future<void> _initLocation() async {
    final locationService = Provider.of<LocationService>(context, listen: false);
    final position = await locationService.getCurrentLocation();
    if (mounted) {
      setState(() {
        if (position != null) {
          _currentPosition = LatLng(position.latitude, position.longitude);
        }
        _isLoadingLocation = false;
      });
    }
  }

  void _calculateNearest(List<MapLocationModel> locations) {
    if (_currentPosition == null || locations.isEmpty) return;

    MapLocationModel? nearest;
    double minDistance = double.infinity;

    for (var loc in locations) {
      if (loc.type == MapLocationType.safeZone || loc.type == MapLocationType.medical) {
        final distance = Geolocator.distanceBetween(
          _currentPosition!.latitude,
          _currentPosition!.longitude,
          loc.latitude,
          loc.longitude,
        );

        if (distance < minDistance) {
          minDistance = distance;
          nearest = loc;
        }
      }
    }

    if (nearest != null && nearest != _nearestSafeZone) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          setState(() {
            _nearestSafeZone = nearest;
            _distanceToNearest = minDistance;
          });
        }
      });
    }
  }

  // ═══════════════════════════════════ NAVIGATION ════════════════════════════════════

  Future<void> _fetchDirections(LatLng destination) async {
    LatLng? originPos = _currentPosition;

    if (originPos == null) {
      final locService = Provider.of<LocationService>(context, listen: false);
      final pos = await locService.getCurrentLocation();
      if (pos != null) {
        originPos = LatLng(pos.latitude, pos.longitude);
        setState(() => _currentPosition = originPos);
      }
    }

    if (originPos == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Waiting for GPS location to start navigation...'), backgroundColor: AppConstants.primaryRed),
        );
      }
      return;
    }

    setState(() => _isFetchingRoute = true);

    final origin = '${originPos.latitude},${originPos.longitude}';
    final dest = '${destination.latitude},${destination.longitude}';
    final apiKey = AppConstants.googleMapsApiKey;
    
    // On Web, use a CORS proxy. On Android/iOS, call the API directly.
    final directUrl = 'https://maps.googleapis.com/maps/api/directions/json?origin=$origin&destination=$dest&key=$apiKey';
    final url = kIsWeb
        ? 'https://proxy.corsfix.com/?$directUrl'
        : directUrl;

    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'OK') {
          List<LatLng> decodedPoints = [];
          final steps = data['routes'][0]['legs'][0]['steps'];
          for (var step in steps) {
            decodedPoints.add(LatLng(step['start_location']['lat'], step['start_location']['lng']));
            decodedPoints.add(LatLng(step['end_location']['lat'], step['end_location']['lng']));
          }
          
          setState(() {
            _polylines = {
              Polyline(
                polylineId: const PolylineId('active_route'),
                points: decodedPoints,
                color: Colors.greenAccent,
                width: 5,
              ),
            };
            _activeRouteDestination = destination;
          });

          _fitRoute(decodedPoints);
        } else {
          throw 'Directions API error: ${data['status']} - ${data['error_message'] ?? 'No detail'}';
        }
      } else {
        throw 'Failed to connect to directions service';
      }
    } catch (e) {
       if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to fetch directions: $e'), backgroundColor: AppConstants.primaryRed),
        );
      }
    } finally {
      if (mounted) setState(() => _isFetchingRoute = false);
    }
  }

  void _fitRoute(List<LatLng> points) {
    if (points.isEmpty) return;
    
    double minLat = points.first.latitude;
    double maxLat = points.first.latitude;
    double minLng = points.first.longitude;
    double maxLng = points.first.longitude;

    for (var p in points) {
      if (p.latitude < minLat) minLat = p.latitude;
      if (p.latitude > maxLat) maxLat = p.latitude;
      if (p.longitude < minLng) minLng = p.longitude;
      if (p.longitude > maxLng) maxLng = p.longitude;
    }

    _mapController?.animateCamera(
      CameraUpdate.newLatLngBounds(
        LatLngBounds(
          southwest: LatLng(minLat, minLng),
          northeast: LatLng(maxLat, maxLng),
        ),
        80, // padding
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final firestoreService = Provider.of<FirestoreService>(context, listen: false);

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text('NEAREST SAFE ZONES', style: TextStyle(color: isDark ? Colors.white : Colors.black87, fontSize: 13, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(Icons.my_location, color: isDark ? Colors.white70 : Colors.black54),
            onPressed: () {
              if (_currentPosition != null) {
                _mapController?.animateCamera(CameraUpdate.newLatLngZoom(_currentPosition!, 15.0));
              } else {
                _mapController?.animateCamera(CameraUpdate.newLatLngZoom(_catanduanesCenter, 13.0));
              }
            },
          ),
        ],
        iconTheme: IconThemeData(color: isDark ? Colors.white : Colors.black87),
      ),
      body: StreamBuilder<List<MapLocationModel>>(
        stream: _locationsStream,
        builder: (context, snapshot) {
          final allLocations = snapshot.data ?? [];
          final safeZones = allLocations.where((l) => 
            l.type == MapLocationType.safeZone || l.type == MapLocationType.medical
          ).toList();

          if (snapshot.connectionState == ConnectionState.active) {
            _calculateNearest(safeZones);
          }

          return Stack(
            children: [
              GoogleMap(
                initialCameraPosition: CameraPosition(
                  target: _currentPosition ?? _catanduanesCenter,
                  zoom: 13.0,
                ),
                mapType: MapType.normal,
                onMapCreated: (controller) => _mapController = controller,
                myLocationEnabled: true,
                myLocationButtonEnabled: false,
                zoomControlsEnabled: false,
                markers: _buildSafeZoneMarkers(safeZones),
                polylines: _polylines,
              ),
              
              // Clear Route Button
              if (_polylines.isNotEmpty)
                Positioned(
                  top: 20,
                  right: 20,
                  child: FloatingActionButton.small(
                    heroTag: 'clear_route_safe',
                    backgroundColor: Colors.greenAccent,
                    onPressed: () {
                      setState(() {
                        _polylines.clear();
                        _activeRouteDestination = null;
                      });
                    },
                    child: const Icon(Icons.close, color: Colors.white),
                  ),
                ),

              // Map Help Button
              Positioned(
                top: 20,
                right: _polylines.isNotEmpty ? 70 : 20,
                child: _buildMapHelpButton(context),
              ),

              // Bottom Sheet for Nearest Safe Zone
              if (safeZones.isNotEmpty)
                Positioned(
                  bottom: 20,
                  left: 20,
                  right: 20,
                  child: _buildNearestInfoCard(context),
                )
              else if (!snapshot.hasData && snapshot.connectionState == ConnectionState.waiting)
                const Center(child: CircularProgressIndicator(color: AppConstants.primaryRed))
              else
                _buildEmptyState(context),
            ],
          );
        },
      ),
    );
  }


  Widget _buildNearestInfoCard(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (_nearestSafeZone == null) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: isDark ? const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF1E2841), Color(0xFF161E31)],
          ) : null,
          color: isDark ? null : Colors.white.withOpacity(0.95),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: isDark ? Colors.white10 : Colors.black12),
        ),
        child: Row(
          children: [
            const SizedBox(
              height: 20,
              width: 20,
              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.blueAccent),
            ),
            const SizedBox(width: 16),
            Text('Finding nearest evacuation center...', style: TextStyle(color: isDark ? Colors.white70 : Colors.black87)),
          ],
        ),
      );
    }

    final distanceKm = (_distanceToNearest! / 1000).toStringAsFixed(1);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: isDark ? const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1E2841), Color(0xFF161E31)],
        ) : null,
        color: isDark ? null : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppConstants.primaryRed.withOpacity(isDark ? 0.5 : 0.3)),
        boxShadow: isDark
            ? [const BoxShadow(color: Colors.black45, blurRadius: 20)]
            : [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 20, offset: const Offset(0, 10))],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppConstants.primaryRed.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.navigation_rounded, color: AppConstants.primaryRed, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('NEAREST EVACUATION', style: TextStyle(color: AppConstants.primaryRed, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1)),
                    Text(_nearestSafeZone!.label, style: TextStyle(color: isDark ? Colors.white : Colors.black87, fontSize: 18, fontWeight: FontWeight.bold)),
                    Text('$distanceKm km away from your location', style: TextStyle(color: isDark ? Colors.white.withOpacity(0.5) : Colors.black54, fontSize: 12)),
                  ],
                ),
              ),
              IconButton(
                onPressed: () => _mapController?.animateCamera(
                  CameraUpdate.newLatLngZoom(LatLng(_nearestSafeZone!.latitude, _nearestSafeZone!.longitude), 16.0)),
                icon: Icon(Icons.center_focus_strong, color: isDark ? Colors.white54 : Colors.black45),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => _showLocationDetails(_nearestSafeZone!),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppConstants.primaryRed,
              minimumSize: const Size(double.infinity, 50),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            child: const Text('VIEW DETAILS & DIRECTIONS', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _showLocationDetails(MapLocationModel loc) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => SafeArea(
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: isDark ? const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF1E2841), Color(0xFF161E31)],
            ) : null,
            color: isDark ? null : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: (loc.type == MapLocationType.medical ? Colors.greenAccent : Colors.orangeAccent).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      loc.type == MapLocationType.medical ? 'MEDICAL FACILITY' : 'EVACUATION CENTER',
                      style: TextStyle(
                        color: loc.type == MapLocationType.medical ? Colors.greenAccent : Colors.orangeAccent,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(onPressed: () => Navigator.pop(context), icon: Icon(Icons.close, color: isDark ? Colors.white30 : Colors.black38)),
                ],
              ),
              const SizedBox(height: 12),
              Text(loc.label, style: TextStyle(color: isDark ? Colors.white : Colors.black87, fontSize: 24, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text(loc.description, style: TextStyle(color: isDark ? Colors.white60 : Colors.black54, fontSize: 16)),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: _buildDetailItem(context, Icons.map_outlined, 'Coordinates', '${loc.latitude.toStringAsFixed(4)}, ${loc.longitude.toStringAsFixed(4)}'),
                  ),
                  Expanded(
                    child: _buildDetailItem(context, Icons.verified_user_outlined, 'Verified by', 'GIS Admin'),
                  ),
                ],
              ),
              const SizedBox(height: 32),
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(context); // Close sheet
                  _fetchDirections(LatLng(loc.latitude, loc.longitude));
                },
                icon: _isFetchingRoute 
                  ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.directions_rounded),
                label: const Text('GET DIRECTIONS'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppConstants.primaryRed,
                  minimumSize: const Size(double.infinity, 56),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailItem(BuildContext context, IconData icon, String label, String value) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Row(
      children: [
        Icon(icon, color: isDark ? Colors.white24 : Colors.black26, size: 20),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: TextStyle(color: isDark ? Colors.white38 : Colors.black54, fontSize: 11)),
            Text(value, style: TextStyle(color: isDark ? Colors.white70 : Colors.black87, fontSize: 13, fontWeight: FontWeight.bold)),
          ],
        ),
      ],
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.map_outlined, size: 80, color: (isDark ? Colors.white : Colors.black).withOpacity(0.05)),
          const SizedBox(height: 24),
          Text('No Safe Zones Pinned Yet', style: TextStyle(color: isDark ? Colors.white : Colors.black87, fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              'Admin has not yet pinned any evacuation centers or medical facilities for Catanduanes.',
              textAlign: TextAlign.center,
              style: TextStyle(color: isDark ? Colors.white38 : Colors.black54, fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  Set<Marker> _buildSafeZoneMarkers(List<MapLocationModel> locations) {
    final markers = locations.map((loc) => Marker(
      markerId: MarkerId(loc.locationId),
      position: LatLng(loc.latitude, loc.longitude),
      icon: BitmapDescriptor.defaultMarkerWithHue(
        loc.type == MapLocationType.medical ? BitmapDescriptor.hueGreen : BitmapDescriptor.hueOrange
      ),
      onTap: () => _showLocationDetails(loc),
      infoWindow: InfoWindow(
        title: loc.label,
        snippet: loc.type == MapLocationType.medical ? 'Medical Facility' : 'Evacuation Center',
      ),
    )).toSet();

    // 🙋 Your Current Location Marker
    if (_currentPosition != null) {
      markers.add(Marker(
        markerId: const MarkerId('current_user_pos_safe'),
        position: _currentPosition!,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
        infoWindow: const InfoWindow(title: 'YOUR LOCATION', snippet: 'You are here'),
      ));
    }

    return markers;
  }

  Widget _buildMapHelpButton(BuildContext context) {
    return GestureDetector(
      onTap: () => _showLegendDialog(context),
      child: Container(
        width: 44, height: 44,
        decoration: BoxDecoration(
          color: AppConstants.surfaceDark.withOpacity(0.9),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white.withOpacity(0.1)),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 10)],
        ),
        child: const Icon(Icons.info_outline_rounded, color: Colors.white, size: 24),
      ),
    );
  }

  void _showLegendDialog(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? AppConstants.surfaceDark : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        title: const Row(
          children: [
            Icon(Icons.shield_outlined, color: Colors.greenAccent),
            SizedBox(width: 12),
            Text('Safety Guide', style: TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Identification markers for safe zones:',
              style: TextStyle(color: isDark ? Colors.white38 : Colors.black38, fontSize: 13),
            ),
            const SizedBox(height: 20),
            _legendItem(Icons.local_hospital, Colors.greenAccent, 'Medical Facility', isDark),
            const SizedBox(height: 12),
            _legendItem(Icons.home_work, Colors.orangeAccent, 'Evacuation Center', isDark),
            const SizedBox(height: 12),
            _legendItem(Icons.person_pin_circle, Colors.blueAccent, 'Your Location', isDark),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('DISMISS'),
          ),
        ],
      ),
    );
  }

  Widget _legendItem(IconData icon, Color color, String label, bool isDark) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 18),
        ),
        const SizedBox(width: 12),
        Text(label, style: TextStyle(color: isDark ? Colors.white : Colors.black87, fontSize: 14)),
      ],
    );
  }

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }
}
