import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:convert';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../core/constants.dart';
import '../models/map_location_model.dart';
import '../models/hazard_model.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/location_service.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:async';
import '../models/user_model.dart';
import '../services/firestore_service.dart';
import '../services/auth_service.dart';
import '../core/localization.dart';
import '../models/incident_model.dart';
import '../models/sos_model.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../widgets/profile_image.dart';
import 'package:http/http.dart' as http;

class GlobalMapScreen extends StatefulWidget {
  final LatLng? initialLocation;
  const GlobalMapScreen({super.key, this.initialLocation});

  @override
  State<GlobalMapScreen> createState() => _GlobalMapScreenState();
}

class _GlobalMapScreenState extends State<GlobalMapScreen> {
  GoogleMapController? _mapController;

  static const LatLng _catanduanesCenter = LatLng(13.5840, 124.2330);

  MapType _selectedMapType = MapType.normal;
  bool _isAddingPin = false; // admin pin placement mode
  LatLng? _pendingPinLatLng;   // tap position waiting for confirmation
  MapLocationModel? _selectedLocation;
  IncidentModel? _selectedIncident;
  HazardModel? _selectedHazard;
  Stream<List<MapLocationModel>>? _locationsStream;
  Stream<List<IncidentModel>>? _incidentsStream;
  Stream<List<HazardModel>>? _hazardsStream;
  Stream<List<SOSRequestModel>>? _sosStream;
  StreamSubscription<Position>? _positionSubscription;
  Position? _currentPos;
  Map<String, dynamic>? _activeRouteInfo;
  List<dynamic> _routeSteps = [];
  int _currentStepIndex = 0;
  HazardModel? _proximityHazard;
  final Set<String> _notifiedHazards = {};
  Set<Polyline> _polylines = {};
  LatLng? _activeRouteDestination;
  bool _isFetchingRoute = false;

  @override
  void initState() {
    super.initState();
    final firestore = Provider.of<FirestoreService>(context, listen: false);
    _locationsStream = firestore.getMapLocations();
    _incidentsStream = firestore.getIncidents();
    _hazardsStream = firestore.getHazards();
    _sosStream = firestore.getSOSRequests(); // Moved to initState for stability
    _startProximityListener();
  }

  void _startProximityListener() {
    _positionSubscription = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(accuracy: LocationAccuracy.high, distanceFilter: 10),
    ).listen((position) {
      if (!mounted) return;
      setState(() => _currentPos = position);
      _checkHazardProximity(position);
    });
  }

  void _checkHazardProximity(Position position) async {
    final firestore = Provider.of<FirestoreService>(context, listen: false);
    final hazards = await firestore.getHazards().first;
    
    HazardModel? nearest;
    double minDistance = 500; // 500 meters threshold

    for (var hazard in hazards) {
      if (hazard.status == 'resolved') continue;
      
      double distance = Geolocator.distanceBetween(
        position.latitude, position.longitude,
        hazard.latitude, hazard.longitude,
      );

      if (distance < minDistance) {
        nearest = hazard;
        minDistance = distance;
      }
    }

    if (nearest != null && !_notifiedHazards.contains(nearest.hazardId)) {
      setState(() => _proximityHazard = nearest);
      // Auto-clear after 10 seconds or when moving away
    } else if (nearest == null) {
      setState(() => _proximityHazard = null);
    }
  }

  @override
  void dispose() {
    _positionSubscription?.cancel();
    _mapController?.dispose();
    super.dispose();
  }

  // ═══════════════════════════════════ NAVIGATION ════════════════════════════════════

  List<LatLng> _decodePolyline(String encoded) {
    List<LatLng> points = [];
    int index = 0, len = encoded.length;
    int lat = 0, lng = 0;

    while (index < len) {
      int b, shift = 0, result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlat = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lat += dlat;

      shift = 0;
      result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlng = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lng += dlng;

      points.add(LatLng(lat / 1E5, lng / 1E5));
    }
    return points;
  }

  Future<void> _fetchDirections(LatLng destination) async {
    LatLng? originPos;
    
    if (_currentPos != null) {
      originPos = LatLng(_currentPos!.latitude, _currentPos!.longitude);
    } else {
      final locService = Provider.of<LocationService>(context, listen: false);
      final pos = await locService.getCurrentLocation();
      if (pos != null) {
        originPos = LatLng(pos.latitude, pos.longitude);
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
          final routes = data['routes'] as List;
          if (routes.isNotEmpty) {
            final route = routes[0];
            final overviewPolyline = route['overview_polyline']['points'];
            final decodedPoints = _decodePolyline(overviewPolyline);
            
            setState(() {
              _polylines = {
                Polyline(
                  polylineId: const PolylineId('active_route'),
                  points: decodedPoints,
                  color: AppConstants.primaryRed,
                  width: 6,
                  jointType: JointType.round,
                  startCap: Cap.roundCap,
                  endCap: Cap.roundCap,
                ),
              };
              _activeRouteDestination = destination;
              _activeRouteInfo = route['legs'][0];
              _routeSteps = _activeRouteInfo!['steps'];
              _currentStepIndex = 0;
              _selectedLocation = null;
              _selectedIncident = null;
              _selectedHazard = null;
            });

            _fitRoute(decodedPoints);
          }
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

  bool _isAdmin(BuildContext context) {
    final user = Provider.of<UserModel?>(context, listen: false);
    final auth = Provider.of<AuthService>(context, listen: false);
    return user?.role == 'admin' || 
           auth.currentUserEmail == 'admin@catanduanes.gov.ph' || 
           auth.currentUserEmail == 'admin@cadiz.gov.ph' ||
           auth.currentUserEmail?.contains('admin') == true;
  }

  bool _isResponder(BuildContext context) {
    final user = Provider.of<UserModel?>(context, listen: false);
    return user?.role == 'responder' || user?.role == 'admin'; // Admin also acts as responder
  }

  @override
  Widget build(BuildContext context) {
    final isAdmin = _isAdmin(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          'CATANDUANES GIS TRACKING MAP'.tr(context),
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, letterSpacing: 1.5),
        ),
        centerTitle: true,
        actions: [
          // Admin: toggle pin placement mode
          if (isAdmin)
            Tooltip(
              message: _isAddingPin ? 'Cancel pin placement' : 'Add new pin',
              child: IconButton(
                icon: Icon(
                  _isAddingPin ? Icons.close : Icons.add_location_alt_rounded,
                  color: _isAddingPin ? AppConstants.primaryRed : Colors.white70,
                ),
                onPressed: () => setState(() {
                  _isAddingPin = !_isAddingPin;
                  _pendingPinLatLng = null;
                }),
              ),
            ),
          // Layer switcher
          PopupMenuButton<MapType>(
            color: isDark ? AppConstants.surfaceDark : Colors.white,
            icon: Icon(Icons.layers_rounded, color: isDark ? Colors.white70 : Colors.black87),
            onSelected: (val) => setState(() => _selectedMapType = val),
            itemBuilder: (_) => [
              _layerMenuItem(MapType.normal, Icons.map, 'Street Map'),
              _layerMenuItem(MapType.satellite, Icons.satellite_alt, 'Satellite'),
              _layerMenuItem(MapType.hybrid, Icons.map_outlined, 'Hybrid'),
              _layerMenuItem(MapType.terrain, Icons.terrain, 'Terrain'),
            ],
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: StreamBuilder<List<MapLocationModel>>(
        stream: _locationsStream,
        builder: (context, mapLocSnapshot) {
          final locations = mapLocSnapshot.data ?? [];

              return StreamBuilder<List<IncidentModel>>(
                stream: _incidentsStream,
                builder: (context, incidentSnapshot) {
                  final incidents = (incidentSnapshot.data ?? [])
                      .where((i) => i.status.trim().toLowerCase() != 'resolved')
                      .toList();
    
                  return StreamBuilder<List<SOSRequestModel>>(
                    stream: _sosStream,
                    builder: (context, sosSnapshot) {
                      final authorized = _isResponder(context);
                      final sosCalls = (sosSnapshot.data ?? [])
                          .where((s) => s.status.trim().toLowerCase() != 'resolved')
                          .toList();
                      
                      // Filtered SOS calls for the legend
                      final visibleSOSCount = authorized ? sosCalls.length : 0;

                      return StreamBuilder<List<HazardModel>>(
                        stream: _hazardsStream,
                        builder: (context, hazardSnapshot) {
                          final hazards = (hazardSnapshot.data ?? [])
                              .where((h) => h.status.trim().toLowerCase() != 'resolved')
                              .toList();

                      return Stack(
                        children: [
                          // ═══════════════════════════════════ GOOGLE MAP ════════════════════════════════════
                          GoogleMap(
                            initialCameraPosition: CameraPosition(
                              target: widget.initialLocation ?? _catanduanesCenter,
                              zoom: widget.initialLocation != null ? 15.0 : 13.0,
                            ),
                            mapType: _selectedMapType,
                            onMapCreated: (controller) => _mapController = controller,
                            zoomControlsEnabled: false,
                            compassEnabled: false,
                            mapToolbarEnabled: false,
                            myLocationEnabled: true,
                            myLocationButtonEnabled: false,
                            markers: _buildMarkers(locations, incidents, sosCalls, hazards),
                            polylines: _polylines,
                            onTap: (latLng) {
                              if (_isAddingPin) {
                                setState(() => _pendingPinLatLng = latLng);
                              } else {
                                setState(() {
                                  _selectedLocation = null;
                                  _selectedIncident = null;
                                  _selectedHazard = null;
                                });
                              }
                            },
                          ),

                          // ═══════════════════════ REAL-TIME NAVIGATION GUIDE ═════════════════════════
                          if (_polylines.isNotEmpty && _activeRouteInfo != null) ...[
                            _buildTopNavigationBanner(context),
                            _buildBottomNavigationSummary(context),
                          ],

                        // ⚠️ PROXIMITY WARNING BANNER ⚠️
                        if (_proximityHazard != null && _polylines.isEmpty) // Hide when navigating for clarity
                          Positioned(
                            top: _isAddingPin ? 60 : 20,
                            left: 20,
                            right: 20,
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 500),
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              decoration: BoxDecoration(
                                color: _hazardColor(_proximityHazard!.type).withOpacity(0.95),
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.5),
                                    blurRadius: 20,
                                    spreadRadius: 5,
                                  ),
                                ],
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.warning_amber_rounded, color: Colors.black, size: 28),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          'HAZARD AHEAD: ${_hazardName(_proximityHazard!.type).toUpperCase()}',
                                          style: const TextStyle(color: Colors.black, fontWeight: FontWeight.w900, fontSize: 13),
                                        ),
                                        Text(
                                          'Reported ${DateFormat('h:mm a').format(_proximityHazard!.timestamp)}',
                                          style: const TextStyle(color: Colors.black54, fontSize: 10, fontWeight: FontWeight.bold),
                                        ),
                                      ],
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.close, color: Colors.black54, size: 20),
                                    onPressed: () {
                                      _notifiedHazards.add(_proximityHazard!.hazardId);
                                      setState(() => _proximityHazard = null);
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ),

                        // ═══════════════════════ ADMIN: PIN PLACEMENT BANNER ═════════════════════
                          if (_isAddingPin)
                            Positioned(
                              top: 0,
                              left: 0,
                              right: 0,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                color: AppConstants.primaryRed.withOpacity(0.92),
                                child: Row(
                                  children: [
                                    const Icon(Icons.touch_app, color: Colors.white, size: 18),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Text(
                                      _pendingPinLatLng == null
                                          ? 'Tap anywhere on the map to place a pin'
                                          : 'Pin placed — tap "Confirm" to save details',
                                      style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                                    ),
                                    ),
                                    if (_pendingPinLatLng != null)
                                      TextButton(
                                        onPressed: () => _showAddPinDialog(context, _pendingPinLatLng!),
                                        child: const Text('CONFIRM', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 1)),
                                      ),
                                  ],
                                ),
                              ),
                            ),

                          // ═══════════════════════ SELECTED LOCATION CARD ═════════════════════════
                          if (_selectedLocation != null)
                            Positioned(
                              top: _isAddingPin ? 52 : 12,
                              left: 12,
                              right: 68, // Leaves 56px for the right-side control column
                              child: _buildInfoCard(_selectedLocation!, isAdmin, context),
                            ),

                          if (_selectedIncident != null)
                            Positioned(
                              top: _isAddingPin ? 52 : 12,
                              left: 12,
                              right: 68,
                              child: _buildIncidentCard(_selectedIncident!, context),
                            ),

                          if (_selectedHazard != null)
                            Positioned(
                              top: _isAddingPin ? 52 : 12,
                              left: 12,
                              right: 68,
                              child: _buildHazardCard(_selectedHazard!, context),
                            ),

                          // ═══════════════════════ ACTION BUTTONS (Right Side) ═══════════════════
                          AnimatedPositioned(
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeInOut,
                            bottom: (_polylines.isNotEmpty && _activeRouteInfo != null) 
                                ? 160 + MediaQuery.of(context).padding.bottom 
                                : 24 + MediaQuery.of(context).padding.bottom,
                            right: 12,
                            child: Column(
                              children: [
                                // MAP HELP BUTTON
                                _buildMapHelpButton(context, visibleSOSCount, hazards.length, locations.length, incidents.length),
                                const SizedBox(height: 12),
                                // ZOOM IN
                                _mapFab(Icons.add, () => _mapController?.animateCamera(CameraUpdate.zoomIn())),
                                const SizedBox(height: 12),
                                // ZOOM OUT
                                _mapFab(Icons.remove, () => _mapController?.animateCamera(CameraUpdate.zoomOut())),
                                const SizedBox(height: 12),
                                // RECENTER ON CATANDUANES
                                Tooltip(
                                  message: 'Recenter to Catanduanes',
                                  child: _mapFab(Icons.home_outlined, () => _mapController?.animateCamera(
                                    CameraUpdate.newLatLngZoom(_catanduanesCenter, 13.0))),
                                ),
                                const SizedBox(height: 24),
                                // REPORT HAZARD
                                FloatingActionButton(
                                  heroTag: 'hazard',
                                  backgroundColor: isDark ? Colors.orange : Colors.orange.shade700,
                                  onPressed: () => _showReportHazardDialog(context),
                                  child: const Icon(Icons.warning_amber_rounded, color: Colors.white),
                                ),
                                const SizedBox(height: 12),
                                // GO TO MY ACTUAL DEVICE LOCATION
                                FloatingActionButton(
                                  heroTag: 'myloc',
                                  backgroundColor: Colors.blueAccent,
                                  onPressed: () => _getCurrentLocation(),
                                  child: const Icon(Icons.my_location, color: Colors.white),
                                ),
                              ],
                            ),
                          ),
                        ],
                      );
                    },
                  );
                },
              );
            },
          );
        },
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────
  // ADD PIN DIALOG (Admin only)
  // ─────────────────────────────────────────────────────────────────
  void _showAddPinDialog(BuildContext context, LatLng position) {
    final labelController = TextEditingController();
    final descController = TextEditingController();
    MapLocationType selectedType = MapLocationType.safeZone;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => Dialog(
          backgroundColor: isDark ? const Color(0xFF1A1A1A) : Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Add Map Pin', style: TextStyle(color: isDark ? Colors.white : Colors.black87, fontWeight: FontWeight.bold, fontSize: 18)),
                const SizedBox(height: 4),
                Text(
                  '${position.latitude.toStringAsFixed(5)}, ${position.longitude.toStringAsFixed(5)}',
                  style: TextStyle(color: isDark ? Colors.white38 : Colors.black54, fontSize: 11),
                ),
                const SizedBox(height: 20),
                _dialogField(isDark, labelController, 'Location name', Icons.label_outline),
                const SizedBox(height: 14),
                _dialogField(isDark, descController, 'Description (optional)', Icons.notes),
                const SizedBox(height: 14),
                DropdownButtonFormField<MapLocationType>(
                  value: selectedType,
                  dropdownColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                  style: TextStyle(color: isDark ? Colors.white : Colors.black87),
                  decoration: InputDecoration(
                    labelText: 'Location type',
                    labelStyle: TextStyle(color: isDark ? Colors.white54 : Colors.black54),
                    prefixIcon: Icon(Icons.category_outlined, color: isDark ? Colors.white38 : Colors.black38),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: isDark ? Colors.white10 : Colors.black12),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppConstants.primaryRed),
                    ),
                    filled: !isDark,
                    fillColor: isDark ? Colors.transparent : Colors.black.withOpacity(0.02),
                  ),
                  items: MapLocationType.values.map((t) => DropdownMenuItem(
                    value: t,
                    child: Row(children: [
                      Icon(_typeIcon(t), color: _typeColor(t), size: 16),
                      const SizedBox(width: 8),
                      Text(_typeName(t), style: TextStyle(color: isDark ? Colors.white : Colors.black87)),
                    ]),
                  )).toList(),
                  onChanged: (val) => setLocal(() => selectedType = val!),
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: Text('CANCEL', style: TextStyle(color: isDark ? Colors.white38 : Colors.black38, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1)),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppConstants.primaryRed,
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 0,
                        minimumSize: const Size(80, 44),
                      ),
                      onPressed: () async {
                        if (labelController.text.trim().isEmpty) return;
                        final loc = MapLocationModel(
                          locationId: DateTime.now().millisecondsSinceEpoch.toString(),
                          label: labelController.text.trim(),
                          description: descController.text.trim(),
                          latitude: position.latitude,
                          longitude: position.longitude,
                          type: selectedType,
                          addedBy: 'admin',
                          createdAt: DateTime.now(),
                        );
                        await Provider.of<FirestoreService>(ctx, listen: false).addMapLocation(loc);
                        Navigator.pop(ctx);
                        setState(() {
                          _isAddingPin = false;
                          _pendingPinLatLng = null;
                        });
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('📍 Pin saved successfully!'), backgroundColor: AppConstants.primaryRed),
                          );
                        }
                      },
                      child: const Text('SAVE PIN', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────
  // REPORT HAZARD DIALOG
  // ─────────────────────────────────────────────────────────────────
  void _showReportHazardDialog(BuildContext context) {
    final descriptionController = TextEditingController();
    HazardType selectedType = HazardType.roadHazard;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    String? base64Image;
    final ImagePicker picker = ImagePicker();

    // Show the dialog IMMEDIATELY so the user gets instant feedback
    showDialog(
      context: context,
      barrierDismissible: false, // Prevent dismissing while loading location
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) {
          return FutureBuilder<Position?>(
            future: _currentPos != null 
                ? Future.value(_currentPos) 
                : LocationService().getCurrentLocation(),
            builder: (context, snapshot) {
              final loc = snapshot.data;
              final isLoading = snapshot.connectionState == ConnectionState.waiting;

              return Dialog(
                backgroundColor: isDark ? const Color(0xFF1A1A1A) : Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (isLoading) ...[
                        const SizedBox(height: 20),
                        const CircularProgressIndicator(color: AppConstants.primaryRed),
                        const SizedBox(height: 20),
                        Text('Getting location...', style: TextStyle(color: isDark ? Colors.white70 : Colors.black54)),
                        const SizedBox(height: 20),
                        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('CANCEL')),
                      ] else if (snapshot.hasError || loc == null) ...[
                        const Icon(Icons.location_off, size: 48, color: AppConstants.primaryRed),
                        const SizedBox(height: 16),
                        const Text('Location Error', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                        const SizedBox(height: 8),
                        const Text('Could not determine your current location.', textAlign: TextAlign.center),
                        const SizedBox(height: 24),
                        ElevatedButton(onPressed: () => Navigator.pop(ctx), child: const Text('CLOSE')),
                      ] else ...[
                        // ACTUAL FORM CONTENT
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Text('Report Hazard', style: TextStyle(color: isDark ? Colors.white : Colors.black87, fontWeight: FontWeight.bold, fontSize: 18)),
                        ),
                        const SizedBox(height: 4),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            '${loc.latitude.toStringAsFixed(5)}, ${loc.longitude.toStringAsFixed(5)}',
                            style: TextStyle(color: isDark ? Colors.white38 : Colors.black54, fontSize: 11),
                          ),
                        ),
                        const SizedBox(height: 20),
                        _dialogField(isDark, descriptionController, 'Description (e.g., fallen tree)', Icons.description),
                        const SizedBox(height: 14),
                        DropdownButtonFormField<HazardType>(
                          value: selectedType,
                          dropdownColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                          style: TextStyle(color: isDark ? Colors.white : Colors.black87),
                          decoration: InputDecoration(
                            labelText: 'Hazard Type',
                            labelStyle: TextStyle(color: isDark ? Colors.white54 : Colors.black54),
                            prefixIcon: Icon(Icons.category_outlined, color: isDark ? Colors.white38 : Colors.black38),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: isDark ? Colors.white10 : Colors.black12),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: AppConstants.primaryRed),
                            ),
                            filled: !isDark,
                            fillColor: isDark ? Colors.transparent : Colors.black.withOpacity(0.02),
                          ),
                          items: HazardType.values.map((t) => DropdownMenuItem(
                            value: t,
                            child: Row(children: [
                              Icon(_hazardIcon(t), color: _hazardColor(t), size: 16),
                              const SizedBox(width: 8),
                              Text(_hazardName(t), style: TextStyle(color: isDark ? Colors.white : Colors.black87)),
                            ]),
                          )).toList(),
                          onChanged: (val) => setLocal(() => selectedType = val!),
                        ),
                        const SizedBox(height: 16),
                        // Photo Picker Section
                        InkWell(
                          onTap: () async {
                            final image = await picker.pickImage(
                              source: ImageSource.camera,
                              imageQuality: 50,
                            );
                            if (image != null) {
                              final bytes = await image.readAsBytes();
                              setLocal(() {
                                base64Image = base64Encode(bytes);
                              });
                            }
                          },
                          child: Container(
                            height: 100,
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.02),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: isDark ? Colors.white10 : Colors.black12),
                            ),
                            child: base64Image != null
                                ? ClipRRect(
                                    borderRadius: BorderRadius.circular(15),
                                    child: Image.memory(base64Decode(base64Image!), fit: BoxFit.cover),
                                  )
                                : Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.add_a_photo_outlined, color: AppConstants.primaryRed.withOpacity(0.7), size: 28),
                                      const SizedBox(height: 8),
                                      Text('Add Hazard Photo', style: TextStyle(color: isDark ? Colors.white38 : Colors.black38, fontSize: 11)),
                                    ],
                                  ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            TextButton(
                              onPressed: () => Navigator.pop(ctx),
                              child: Text('CANCEL', style: TextStyle(color: isDark ? Colors.white38 : Colors.black38, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1)),
                            ),
                            const SizedBox(width: 12),
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppConstants.primaryRed,
                                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                elevation: 0,
                                minimumSize: const Size(80, 44),
                              ),
                              onPressed: () async {
                                final user = FirebaseAuth.instance.currentUser;
                                if (user == null) {
                                  if (mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('Please log in to report a hazard.'), backgroundColor: AppConstants.primaryRed),
                                    );
                                  }
                                  Navigator.pop(ctx);
                                  return;
                                }

                                final hazard = HazardModel(
                                  hazardId: DateTime.now().millisecondsSinceEpoch.toString(),
                                  type: selectedType,
                                  description: descriptionController.text.trim(),
                                  imageBase64: base64Image,
                                  latitude: loc.latitude,
                                  longitude: loc.longitude,
                                  reportedBy: user.uid,
                                  status: 'pending',
                                  timestamp: DateTime.now(),
                                );
                                await Provider.of<FirestoreService>(ctx, listen: false).addHazard(hazard);
                                Navigator.pop(ctx);
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('⚠️ Hazard reported successfully!'), backgroundColor: AppConstants.primaryRed),
                                  );
                                }
                              },
                              child: const Text('REPORT', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1)),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────
  // DELETE CONFIRMATION
  // ─────────────────────────────────────────────────────────────────
  void _confirmDelete(BuildContext context, MapLocationModel loc) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: isDark ? const Color(0xFF1A1A1A) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppConstants.primaryRed.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.delete_outline, color: AppConstants.primaryRed, size: 32),
              ),
              const SizedBox(height: 16),
              Text('Remove Pin?', style: TextStyle(color: isDark ? Colors.white : Colors.black87, fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 8),
              Text(
                '"${loc.label}" will be permanently removed from the map.',
                textAlign: TextAlign.center,
                style: TextStyle(color: isDark ? Colors.white54 : Colors.black54, fontSize: 13),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: Text('CANCEL', style: TextStyle(color: isDark ? Colors.white38 : Colors.black38, fontSize: 12, fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppConstants.primaryRed,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 0,
                      minimumSize: const Size(80, 40),
                    ),
                    onPressed: () async {
                      await Provider.of<FirestoreService>(ctx, listen: false).deleteMapLocation(loc.locationId);
                      Navigator.pop(ctx);
                      setState(() => _selectedLocation = null);
                    },
                    child: const Text('REMOVE', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────
  // WIDGETS
  // ─────────────────────────────────────────────────────────────────
  Set<Marker> _buildMarkers(
    List<MapLocationModel> locations,
    List<IncidentModel> incidents,
    List<SOSRequestModel> sosCalls,
    List<HazardModel> hazards,
  ) {
    Set<Marker> markers = {};
    
    // 🏠 Your Current Location Marker 🏠
    if (_currentPos != null) {
      markers.add(Marker(
        markerId: const MarkerId('current_user_loc'),
        position: LatLng(_currentPos!.latitude, _currentPos!.longitude),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
        infoWindow: const InfoWindow(title: 'YOUR LOCATION', snippet: 'Your current GPS position'),
      ));
    }

    // 📍 Locations / Pins from Firestore
    for (var loc in locations) {
      markers.add(Marker(
        markerId: MarkerId(loc.locationId),
        position: LatLng(loc.latitude, loc.longitude),
        icon: BitmapDescriptor.defaultMarkerWithHue(_typeHue(loc.type)),
        onTap: () {
          if (!_isAddingPin) {
            setState(() => _selectedLocation = loc);
          }
        },
      ));
    }

    // 🚨 Emergency: Incidents 🚨
    for (var inc in incidents) {
      final latLng = _parseLocation(inc.location);
      if (latLng != null) {
        markers.add(Marker(
          markerId: MarkerId('inc_${inc.incidentId}'),
          position: latLng,
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
          onTap: () => setState(() {
            _selectedIncident = inc;
            _selectedLocation = null;
            _selectedHazard = null;
          }),
        ));
      }
    }

    // 🚨 Emergency: SOS Calls 🚨
    if (_isResponder(context)) {
      for (var sos in sosCalls) {
        final latLng = _parseLocation(sos.location);
        if (latLng != null) {
          markers.add(Marker(
            markerId: MarkerId('sos_${sos.sosId}'),
            position: latLng,
            icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
            onTap: () => _showSOSDetails(sos),
          ));
        }
      }
    }

    // ⚠️ Hazards ⚠️
    for (var hazard in hazards) {
      markers.add(Marker(
        markerId: MarkerId('haz_${hazard.hazardId}'),
        position: LatLng(hazard.latitude, hazard.longitude),
        icon: BitmapDescriptor.defaultMarkerWithHue(_hazardHue(hazard.type)),
        onTap: () => setState(() {
          _selectedHazard = hazard;
          _selectedLocation = null;
          _selectedIncident = null;
        }),
      ));
    }

    // 🔘 Ghost pin: admin tap preview
    if (_pendingPinLatLng != null) {
      markers.add(Marker(
        markerId: const MarkerId('pending'),
        position: _pendingPinLatLng!,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
      ));
    }

    return markers;
  }

  double _typeHue(MapLocationType type) {
    switch (type) {
      case MapLocationType.command: return BitmapDescriptor.hueRed;
      case MapLocationType.medical: return BitmapDescriptor.hueGreen;
      case MapLocationType.responder: return BitmapDescriptor.hueAzure;
      case MapLocationType.safeZone: return BitmapDescriptor.hueOrange;
    }
  }

  double _hazardHue(HazardType type) {
    switch (type) {
      case HazardType.roadHazard: return BitmapDescriptor.hueYellow;
      case HazardType.naturalDisaster: return BitmapDescriptor.hueRed; // Close enough to deep orange
      case HazardType.other: return BitmapDescriptor.hueViolet;
    }
  }

  void _showSOSDetails(SOSRequestModel sos) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final firestore = Provider.of<FirestoreService>(context, listen: false);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => SafeArea(
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: isDark ? AppConstants.surfaceDark : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
          ),
          child: StreamBuilder<UserModel?>(
            stream: firestore.getUserStream(sos.userId),
            builder: (context, snapshot) {
              final user = snapshot.data;
              return Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppConstants.primaryRed.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          'CRITICAL SOS ALERT',
                          style: TextStyle(color: AppConstants.primaryRed, fontSize: 10, fontWeight: FontWeight.bold),
                        ),
                      ),
                      IconButton(onPressed: () => Navigator.pop(context), icon: Icon(Icons.close, color: isDark ? Colors.white30 : Colors.black38)),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      ProfileImage(source: user?.profileImage, radius: 30),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(user?.name ?? 'Loading name...', style: TextStyle(color: isDark ? Colors.white : Colors.black87, fontSize: 24, fontWeight: FontWeight.bold)),
                            Text('Broadcasting live location', style: TextStyle(color: isDark ? Colors.white38 : Colors.black54, fontSize: 14)),
                          ],
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 24),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppConstants.primaryRed.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppConstants.primaryRed.withOpacity(0.2)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.description_outlined, color: AppConstants.primaryRed, size: 18),
                            SizedBox(width: 8),
                            Text('INCIDENT DESCRIPTION', style: TextStyle(color: AppConstants.primaryRed, fontSize: 11, fontWeight: FontWeight.bold)),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          sos.description ?? 'No details provided by the citizen.',
                          style: TextStyle(color: isDark ? Colors.white : Colors.black87, fontSize: 15, fontStyle: (sos.description == null) ? FontStyle.italic : FontStyle.normal),
                        ),
                      ],
                    ),
                  ),
  
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: _buildDetailItem(
                          context, 
                          Icons.phone_in_talk_rounded, 
                          'Contact Number', 
                          user?.phone == null || user!.phone.isEmpty ? 'No number provided' : user.phone,
                          isPrimary: true
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 32),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {
                            final latLng = _parseLocation(sos.location);
                            if (latLng != null) {
                              Navigator.pop(context); // Close the sheet
                              _fetchDirections(latLng);
                            }
                          },
                          icon: _isFetchingRoute 
                            ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: AppConstants.primaryRed))
                            : const Icon(Icons.directions_rounded),
                          label: const Text('DIRECTIONS'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: isDark ? Colors.white : Colors.black87,
                            side: BorderSide(color: isDark ? Colors.white10 : Colors.black12),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            firestore.updateSOSStatus(sos.sosId, 'dispatched');
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('SOS marked as Dispatched')));
                          },
                          icon: const Icon(Icons.local_shipping_outlined),
                          label: const Text('DISPATCH HELP'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.orange,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton(
                     onPressed: () {
                      firestore.updateSOSStatus(sos.sosId, 'resolved');
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('SOS marked as Resolved')));
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 56),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    child: const Text('MARK AS RESOLVED', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(height: 10),
                ],
              );
            },
          ),
        ),
      ),
    );
  }


  Widget _buildInfoCard(MapLocationModel loc, bool isAdmin, BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppConstants.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: _typeColor(loc.type).withOpacity(0.35)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 20)],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: _typeColor(loc.type).withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(_typeIcon(loc.type), color: _typeColor(loc.type), size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(loc.label, style: TextStyle(color: isDark ? Colors.white : Colors.black87, fontWeight: FontWeight.bold, fontSize: 14)),
                    const SizedBox(height: 2),
                    Text(_typeName(loc.type).toUpperCase(),
                        style: TextStyle(color: _typeColor(loc.type), fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 0.8)),
                  ],
                ),
              ),
              if (isAdmin)
                IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 20),
                  tooltip: 'Remove pin',
                  onPressed: () => _confirmDelete(context, loc),
                ),
              IconButton(
                icon: Icon(Icons.close, color: isDark ? Colors.white38 : Colors.black38, size: 18),
                onPressed: () => setState(() => _selectedLocation = null),
              ),
            ],
          ),
          if (loc.description.isNotEmpty) ...[
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                loc.description,
                style: TextStyle(color: isDark ? Colors.white54 : Colors.black54, fontSize: 13),
              ),
            ),
          ],
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _fetchDirections(LatLng(loc.latitude, loc.longitude)),
                  icon: _isFetchingRoute 
                      ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white70))
                      : const Icon(Icons.directions_outlined, size: 18),
                  label: const Text('NAVIGATE', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1, fontSize: 12)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _typeColor(loc.type),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    elevation: 0,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }


  Widget _buildMapHelpButton(BuildContext context, int sosCount, int hazardCount, int pinCount, int incidentCount) {
    return GestureDetector(
      onTap: () => _showLegendDialog(context, sosCount, hazardCount, pinCount, incidentCount),
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

  void _showLegendDialog(BuildContext context, int sosCount, int hazardCount, int pinCount, int incidentCount) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? AppConstants.surfaceDark : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        title: Row(
          children: [
            Icon(Icons.map_outlined, color: isDark ? Colors.white70 : Colors.black54),
            const SizedBox(width: 12),
            const Text('Map Guide', style: TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Identification markers for this map:',
              style: TextStyle(color: isDark ? Colors.white38 : Colors.black38, fontSize: 13),
            ),
            const SizedBox(height: 20),
            _legendItem(Icons.shield_rounded, AppConstants.primaryRed, 'Command Center', isDark),
            const SizedBox(height: 12),
            _legendItem(Icons.local_hospital, Colors.greenAccent, 'Medical Facility', isDark),
            const SizedBox(height: 12),
            _legendItem(Icons.emergency_share, Colors.blueAccent, 'Responder Unit', isDark),
            const SizedBox(height: 12),
            _legendItem(Icons.home_work, Colors.orangeAccent, 'Evacuation Center', isDark),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 16),
             _legendItem(Icons.warning_amber_rounded, Colors.yellow, 'Road Hazard', isDark),
            const SizedBox(height: 12),
            _legendItem(Icons.cyclone_rounded, Colors.deepOrangeAccent, 'Natural Disaster', isDark),
            const SizedBox(height: 12),
            _legendItem(Icons.report_problem_rounded, Colors.purpleAccent, 'Other Hazard', isDark),
             const SizedBox(height: 24),
              Text(
                'LIVE STATUS',
                style: TextStyle(color: isDark ? Colors.white38 : Colors.black38, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.5),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8, runSpacing: 8,
                children: [
                  _statusBadge(Icons.push_pin, AppConstants.primaryRed, '$pinCount pinned', isDark),
                   if (incidentCount > 0)
                     _statusBadge(Icons.emergency, AppConstants.primaryRed, '$incidentCount incidents', isDark),
                   if (sosCount > 0)
                     _statusBadge(Icons.warning, AppConstants.primaryRed, '$sosCount emergencies', isDark),
                   if (hazardCount > 0)
                     _statusBadge(Icons.warning_amber_rounded, Colors.orange, '$hazardCount hazards', isDark),
                ],
              ),
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

  Widget _statusBadge(IconData icon, Color color, String label, bool isDark) {
     return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 12),
          const SizedBox(width: 6),
          Text(label, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold)),
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

  Widget _buildIncidentCard(IncidentModel inc, BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final latLng = _parseLocation(inc.location);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppConstants.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppConstants.primaryRed.withOpacity(0.35)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 20)],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppConstants.primaryRed.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.emergency_rounded, color: AppConstants.primaryRed, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('INCIDENT REPORT', style: TextStyle(color: isDark ? Colors.white : Colors.black87, fontWeight: FontWeight.bold, fontSize: 14)),
                    const SizedBox(height: 2),
                    Text(inc.status.toUpperCase(),
                        style: const TextStyle(color: AppConstants.primaryRed, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 0.8)),
                  ],
                ),
              ),
              IconButton(
                icon: Icon(Icons.close, color: isDark ? Colors.white38 : Colors.black38, size: 18),
                onPressed: () => setState(() => _selectedIncident = null),
              ),
            ],
          ),
          if (inc.imageBase64 != null) ...[
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.memory(base64Decode(inc.imageBase64!), height: 120, width: double.infinity, fit: BoxFit.cover),
            ),
          ],
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              inc.description,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: isDark ? Colors.white : Colors.black87, fontSize: 13),
            ),
          ),
          const SizedBox(height: 16),
          if (latLng != null)
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _fetchDirections(latLng),
                    icon: _isFetchingRoute 
                        ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white70))
                        : const Icon(Icons.directions_outlined, size: 18),
                    label: const Text('NAVIGATE', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1, fontSize: 12)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppConstants.primaryRed,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  void _confirmResolveHazard(BuildContext context, HazardModel hazard) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Remove Hazard?', style: TextStyle(fontWeight: FontWeight.bold)),
        content: const Text('This hazard report will be permanently deleted from the system. This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('CANCEL', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppConstants.primaryRed),
            onPressed: () async {
              Navigator.pop(ctx);
              await Provider.of<FirestoreService>(context, listen: false).deleteHazard(hazard.hazardId);
              setState(() => _selectedHazard = null);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Hazard removed successfully!'), backgroundColor: Colors.green),
                );
              }
            },
            child: const Text('REMOVE', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildHazardCard(HazardModel hazard, BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final color = _hazardColor(hazard.type);
    final isResponder = _isResponder(context);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppConstants.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: color.withOpacity(0.35)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 20)],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(_hazardIcon(hazard.type), color: color, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(_hazardName(hazard.type).toUpperCase(), style: TextStyle(color: isDark ? Colors.white : Colors.black87, fontWeight: FontWeight.bold, fontSize: 14)),
                    const SizedBox(height: 2),
                    Text('REPORTED HAZARD',
                        style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 0.8)),
                  ],
                ),
              ),
              IconButton(
                icon: Icon(Icons.close, color: isDark ? Colors.white38 : Colors.black38, size: 18),
                onPressed: () => setState(() => _selectedHazard = null),
              ),
            ],
          ),
          if (hazard.imageBase64 != null) ...[
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.memory(base64Decode(hazard.imageBase64!), height: 120, width: double.infinity, fit: BoxFit.cover),
            ),
          ],
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              hazard.description,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: isDark ? Colors.white : Colors.black87, fontSize: 13),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _fetchDirections(LatLng(hazard.latitude, hazard.longitude)),
                  icon: _isFetchingRoute 
                      ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white70))
                      : const Icon(Icons.directions_outlined, size: 18),
                  label: const Text('NAVIGATE', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1, fontSize: 12)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: color,
                    foregroundColor: Colors.black, // Dark text for yellow/orange
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
              if (isResponder) ...[
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _confirmResolveHazard(context, hazard),
                    icon: const Icon(Icons.delete_outline_rounded, size: 18),
                    label: const Text('REMOVE', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1, fontSize: 12)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppConstants.primaryRed,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTopNavigationBanner(BuildContext context) {
    if (_routeSteps.isEmpty) return const SizedBox.shrink();
    final step = _routeSteps[_currentStepIndex];
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    // Simple HTML cleaning for instructions
    String instruction = (step['html_instructions'] as String)
        .replaceAll(RegExp(r'<[^>]*>|&[^;]+;'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();

    return Positioned(
      top: 0, left: 0, right: 0,
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
        decoration: BoxDecoration(
          color: const Color(0xFF006B3F), // Dark green navigation style
          borderRadius: const BorderRadius.vertical(bottom: Radius.circular(32)),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 20)],
        ),
        child: Row(
          children: [
            const Icon(Icons.navigation_rounded, color: Colors.white, size: 36),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                   Text(
                    instruction,
                    style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900, letterSpacing: -0.5),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Text('Dist:', style: TextStyle(color: Colors.white60, fontSize: 12)),
                      const SizedBox(width: 4),
                      Text(step['distance']['text'], style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.close_rounded, color: Colors.white, size: 26),
              onPressed: () => setState(() {
                _polylines.clear();
                _activeRouteInfo = null;
                _routeSteps = [];
              }),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomNavigationSummary(BuildContext context) {
    if (_activeRouteInfo == null) return const SizedBox.shrink();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Positioned(
      bottom: 0, left: 0, right: 0,
      child: Container(
        padding: EdgeInsets.fromLTRB(24, 20, 24, 16 + MediaQuery.of(context).padding.bottom),
        decoration: BoxDecoration(
          color: isDark ? AppConstants.surfaceDark : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(36)),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 40, offset: const Offset(0, -10))],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _activeRouteInfo!['duration']['text'],
                      style: const TextStyle(color: Colors.green, fontSize: 32, fontWeight: FontWeight.w900),
                    ),
                    Row(
                      children: [
                        Text(_activeRouteInfo!['distance']['text'], style: TextStyle(color: isDark ? Colors.white70 : Colors.black54, fontSize: 13, fontWeight: FontWeight.bold)),
                        const SizedBox(width: 8),
                        Text('• ETA: ${DateFormat('h:mm a').format(DateTime.now().add(Duration(seconds: _activeRouteInfo!['duration']['value'])))}', 
                             style: TextStyle(color: isDark ? Colors.white38 : Colors.black38, fontSize: 13)),
                      ],
                    ),
                  ],
                ),
                Container(
                  height: 60, width: 60,
                  decoration: BoxDecoration(
                    color: AppConstants.primaryRed.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: IconButton(
                      icon: const Icon(Icons.close_rounded, color: AppConstants.primaryRed, size: 30),
                      onPressed: () => setState(() {
                        _polylines.clear();
                        _activeRouteInfo = null;
                        _activeRouteDestination = null;
                      }),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Step simulator if we had movement, but for now just show we are on step X
            if (_routeSteps.length > 1)
              LinearProgressIndicator(
                value: (_currentStepIndex + 1) / _routeSteps.length,
                backgroundColor: isDark ? Colors.white10 : Colors.black.withOpacity(0.05),
                valueColor: const AlwaysStoppedAnimation<Color>(Colors.green),
                borderRadius: BorderRadius.circular(10),
                minHeight: 4,
              ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _mapFab(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44, height: 44,
        decoration: BoxDecoration(
          color: AppConstants.surfaceDark,
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white.withOpacity(0.1)),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 10)],
        ),
        child: Icon(icon, color: Colors.white, size: 24),
      ),
    );
  }

  Widget _dialogField(bool isDark, TextEditingController ctrl, String label, IconData icon) {
    return TextField(
      controller: ctrl,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white54),
        prefixIcon: Icon(icon, color: Colors.white38),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.white10),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppConstants.primaryRed),
        ),
      ),
    );
  }

  PopupMenuItem<MapType> _layerMenuItem(MapType value, IconData icon, String label) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return PopupMenuItem(
      value: value,
      child: Row(children: [
        Icon(icon, color: _selectedMapType == value ? AppConstants.primaryRed : (isDark ? Colors.white54 : Colors.black54), size: 18),
        const SizedBox(width: 12),
        Text(label, style: TextStyle(color: isDark ? Colors.white : Colors.black87, fontSize: 13, fontWeight: FontWeight.bold)),
      ]),
    );
  }

  // ─────────────────────────────────────────────────────────────────
  // HELPERS
  // ─────────────────────────────────────────────────────────────────
  Color _typeColor(MapLocationType type) {
    switch (type) {
      case MapLocationType.command: return AppConstants.primaryRed;
      case MapLocationType.medical: return Colors.greenAccent;
      case MapLocationType.responder: return Colors.blueAccent;
      case MapLocationType.safeZone: return Colors.orangeAccent;
    }
  }

  IconData _typeIcon(MapLocationType type) {
    switch (type) {
      case MapLocationType.command: return Icons.shield_rounded;
      case MapLocationType.medical: return Icons.local_hospital;
      case MapLocationType.responder: return Icons.emergency_share;
      case MapLocationType.safeZone: return Icons.home_work;
    }
  }

  String _typeName(MapLocationType type) {
    switch (type) {
      case MapLocationType.command: return 'Command Center';
      case MapLocationType.medical: return 'Medical Facility';
      case MapLocationType.responder: return 'Responder Unit';
      case MapLocationType.safeZone: return 'Evacuation Center';
    }
  }

  Color _hazardColor(HazardType type) {
    switch (type) {
      case HazardType.roadHazard: return Colors.yellow;
      case HazardType.naturalDisaster: return Colors.deepOrange;
      case HazardType.other: return Colors.purple;
    }
  }

  IconData _hazardIcon(HazardType type) {
    switch (type) {
      case HazardType.roadHazard: return Icons.traffic;
      case HazardType.naturalDisaster: return Icons.storm;
      case HazardType.other: return Icons.warning;
    }
  }

  String _hazardName(HazardType type) {
    switch (type) {
      case HazardType.roadHazard: return 'Road Hazard';
      case HazardType.naturalDisaster: return 'Natural Disaster';
      case HazardType.other: return 'Other Hazard';
    }
  }


  LatLng? _parseLocation(String location) {
    try {
      if (location.contains(',')) {
        final parts = location.split(',');
        final lat = double.tryParse(parts[0].trim());
        final lng = double.tryParse(parts[1].trim());
        if (lat != null && lng != null) {
          return LatLng(lat, lng);
        }
      }
    } catch (_) {}
    return null;
  }

  void _getCurrentLocation() async {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('⏳ Locating your device...'),
          duration: Duration(seconds: 2),
        ),
      );
    }
    
    try {
      // Use a timeout to prevent waiting forever if GPS is weak
      final pos = await LocationService().getCurrentLocation().timeout(
        const Duration(seconds: 5),
        onTimeout: () => throw 'Request timed out. Please ensure GPS is enabled.',
      );

      if (pos != null) {
        _mapController?.animateCamera(
          CameraUpdate.newLatLngZoom(LatLng(pos.latitude, pos.longitude), 15.0)
        );
      } else {
        throw 'Permission denied or GPS disabled.';
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('GPS Error: $e'),
            backgroundColor: AppConstants.primaryRed,
            action: SnackBarAction(
              label: 'RETRY',
              textColor: Colors.white,
              onPressed: _getCurrentLocation,
            ),
          ),
        );
      }
    }
  }

  Widget _buildDetailItem(BuildContext context, IconData icon, String label, String value, {bool isPrimary = false}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = isPrimary ? AppConstants.primaryRed : (isDark ? Colors.white24 : Colors.black26);
    
    return Row(
      children: [
        Icon(icon, color: primaryColor, size: isPrimary ? 24 : 20),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: TextStyle(color: isDark ? Colors.white38 : Colors.black54, fontSize: 11)),
            Text(value, style: TextStyle(
              color: isPrimary ? (isDark ? Colors.white : Colors.black87) : (isDark ? Colors.white70 : Colors.black87), 
              fontSize: isPrimary ? 16 : 13, 
              fontWeight: FontWeight.bold
            )),
          ],
        ),
      ],
    );
  }
}
