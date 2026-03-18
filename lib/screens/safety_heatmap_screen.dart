import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import '../services/firestore_service.dart';
import '../models/safety_check_model.dart';
import '../core/constants.dart';

class SafetyHeatmapScreen extends StatefulWidget {
  const SafetyHeatmapScreen({super.key});

  @override
  State<SafetyHeatmapScreen> createState() => _SafetyHeatmapScreenState();
}

class _SafetyHeatmapScreenState extends State<SafetyHeatmapScreen> {
  GoogleMapController? _mapController;

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final firestoreService = Provider.of<FirestoreService>(context, listen: false);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('SAFETY CHECK-IN HEATMAP', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, letterSpacing: 1.5)),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: StreamBuilder<SafetyCheckEvent?>(
        stream: firestoreService.getActiveSafetyCheck(),
        builder: (context, eventSnapshot) {
          if (!eventSnapshot.hasData || eventSnapshot.data == null) {
            return Center(
              child: Text(
                'NO ACTIVE SAFETY CHECK-IN\nTRIGGER ONE FROM DASHBOARD',
                textAlign: TextAlign.center,
                style: TextStyle(color: isDark ? Colors.white24 : Colors.black26, fontWeight: FontWeight.bold),
              ),
            );
          }

          final event = eventSnapshot.data!;

          return Column(
            children: [
              _buildEventStatsHeader(context, firestoreService, event),
              Expanded(
                child: StreamBuilder<List<SafetyResponse>>(
                  stream: firestoreService.getSafetyResponses(event.eventId),
                  builder: (context, responseSnapshot) {
                    final responses = responseSnapshot.data ?? [];
                    
                    return GoogleMap(
                      initialCameraPosition: const CameraPosition(
                        target: LatLng(10.9575, 123.3217),
                        zoom: 13.0,
                      ),
                      onMapCreated: (controller) {
                        if (mounted) {
                          setState(() => _mapController = controller);
                        }
                      },
                      myLocationEnabled: false,
                      zoomControlsEnabled: false,
                      circles: responses.map((r) {
                        final isSafe = r.status == 'safe';
                        return Circle(
                          circleId: CircleId('circle_${r.responseId ?? r.userId}'),
                          center: LatLng(r.latitude, r.longitude),
                          radius: isSafe ? 200 : 400,
                          fillColor: (isSafe 
                            ? Colors.greenAccent 
                            : AppConstants.primaryRed).withOpacity(0.35),
                          strokeColor: isSafe ? Colors.greenAccent : AppConstants.primaryRed,
                          strokeWidth: 2,
                        );
                      }).toSet(),
                      markers: responses.where((r) => r.status != 'safe').map((r) {
                        return Marker(
                          markerId: MarkerId('marker_${r.responseId ?? r.userId}'),
                          position: LatLng(r.latitude, r.longitude),
                          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
                          infoWindow: const InfoWindow(title: 'CITIZEN IN DANGER'),
                        );
                      }).toSet(),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildEventStatsHeader(BuildContext context, FirestoreService fs, SafetyCheckEvent event) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(20),
      margin: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: isDark ? const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1E2841), Color(0xFF161E31)],
        ) : null,
        color: isDark ? null : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: (isDark ? Colors.white : Colors.black).withOpacity(0.05)),
        boxShadow: isDark 
            ? [const BoxShadow(color: Colors.black45, blurRadius: 10, offset: Offset(0, 4))] 
            : [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(event.title, style: TextStyle(color: isDark ? Colors.white : Colors.black87, fontWeight: FontWeight.bold, fontSize: 16)),
                    const Text('ACTIVE ENFORCEMENT', style: TextStyle(color: Colors.greenAccent, fontSize: 10, fontWeight: FontWeight.w900)),
                  ],
                ),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: AppConstants.primaryRed, minimumSize: const Size(80, 36)),
                onPressed: () => fs.deactivateSafetyCheck(event.eventId),
                child: const Text('STOP', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: 20),
          StreamBuilder<List<SafetyResponse>>(
            stream: fs.getSafetyResponses(event.eventId),
            builder: (context, snapshot) {
              final responses = snapshot.data ?? [];
              final safeCount = responses.where((r) => r.status == 'safe').length;
              final helpCount = responses.where((r) => r.status != 'safe').length;

              return Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildStat(context, safeCount.toString(), 'SAFE CITIZENS', Colors.greenAccent),
                  _buildStat(context, helpCount.toString(), 'DANGER SIGNALS', AppConstants.primaryRed),
                  _buildStat(context, responses.length.toString(), 'TOTAL RESPONSES', isDark ? Colors.white : Colors.black87),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildStat(BuildContext context, String val, String label, Color color) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      children: [
        Text(val, style: TextStyle(color: color, fontSize: 20, fontWeight: FontWeight.w900)),
        Text(label, style: TextStyle(color: isDark ? Colors.white24 : Colors.black38, fontSize: 8, fontWeight: FontWeight.bold)),
      ],
    );
  }
}
