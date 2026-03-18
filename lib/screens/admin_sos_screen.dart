import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/firestore_service.dart';
import '../models/sos_model.dart';
import '../models/user_model.dart';
import '../core/constants.dart';
import 'package:intl/intl.dart';
import 'global_map_screen.dart';
import '../widgets/profile_image.dart';

import 'package:google_maps_flutter/google_maps_flutter.dart';

class AdminSOSScreen extends StatelessWidget {
  const AdminSOSScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final firestoreService = Provider.of<FirestoreService>(context, listen: false);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppConstants.backgroundBlack : Colors.grey.shade100,
      appBar: AppBar(
        title: const Text('CITIZEN SOS REQUESTS', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
        centerTitle: true,
      ),
      body: StreamBuilder<List<SOSRequestModel>>(
        stream: firestoreService.getSOSRequests(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: AppConstants.primaryRed));
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.gpp_good_outlined, size: 64, color: Colors.greenAccent.withOpacity(isDark ? 0.1 : 0.4)),
                  const SizedBox(height: 16),
                  Text('No active SOS calls. System secure.', style: TextStyle(color: isDark ? Colors.white38 : Colors.black45)),
                ],
              ),
            );
          }

          final sosRequests = snapshot.data!;

          return ListView.builder(
            padding: const EdgeInsets.all(20),
            itemCount: sosRequests.length,
            itemBuilder: (context, index) {
              final sos = sosRequests[index];
              return _buildSOSCard(context, sos, isDark);
            },
          );
        },
      ),
    );
  }

  Widget _buildSOSCard(BuildContext context, SOSRequestModel sos, bool isDark) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E2841) : Colors.white,
        gradient: isDark
            ? const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF1E2841), Color(0xFF161E31)],
              )
            : null,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: sos.status == 'resolved' ? Colors.green.withOpacity(0.2) : AppConstants.primaryRed.withOpacity(0.2),
          width: 2,
        ),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(isDark ? 0.45 : 0.08), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        children: [
          ListTile(
            contentPadding: const EdgeInsets.all(16),
            leading: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppConstants.primaryRed.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.emergency_share, color: AppConstants.primaryRed, size: 24),
            ),
            title: Text('URGENT SOS CALL', style: TextStyle(color: isDark ? Colors.white : Colors.black87, fontWeight: FontWeight.bold)),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                Text('Location: ${sos.location}', style: TextStyle(color: isDark ? Colors.white70 : Colors.black54, fontSize: 13)),
                Text(DateFormat('MMM dd, hh:mm a').format(sos.timestamp), style: TextStyle(color: isDark ? Colors.white38 : Colors.black38, fontSize: 11)),
              ],
            ),
            trailing: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: (sos.status == 'resolved' ? Colors.green : Colors.red).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                sos.status.toUpperCase(),
                style: TextStyle(
                  color: sos.status == 'resolved' ? Colors.green : Colors.red,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      final latLng = _parseLocation(sos.location);
                      Navigator.push(context, MaterialPageRoute(builder: (_) => GlobalMapScreen(initialLocation: latLng)));
                    },
                    icon: Icon(Icons.map_outlined, size: 16, color: isDark ? Colors.white70 : Colors.black54),
                    label: Text('VIEW ON MAP', style: TextStyle(fontSize: 12, color: isDark ? Colors.white70 : Colors.black54)),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: isDark ? Colors.white70 : Colors.black54,
                      side: BorderSide(color: isDark ? Colors.white10 : Colors.black12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                if (sos.assignedTo == null && sos.status != 'resolved')
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _showAssignResponderDialog(context, sos),
                      icon: const Icon(Icons.send_rounded, size: 16),
                      label: const Text('DISPATCH', style: TextStyle(fontSize: 12)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppConstants.primaryRed,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  )
                else if (sos.status != 'resolved')
                  const Expanded(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.check_circle, size: 16, color: Colors.green),
                        SizedBox(width: 8),
                        Text('DISPATCHED', style: TextStyle(color: Colors.green, fontSize: 12, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showAssignResponderDialog(BuildContext context, SOSRequestModel sos) {
    final firestoreService = Provider.of<FirestoreService>(context, listen: false);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? const Color(0xFF1E2841) : Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(32))),
      elevation: 24,
      builder: (context) => SafeArea(
        child: Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Dispatch Emergency Unit', style: TextStyle(color: isDark ? Colors.white : Colors.black87, fontWeight: FontWeight.bold, fontSize: 18)),
              const SizedBox(height: 16),
              Text('Assign an active responder to this SOS location:', style: TextStyle(color: isDark ? Colors.white54 : Colors.black54, fontSize: 13)),
              const SizedBox(height: 20),
              Expanded(
                child: StreamBuilder<List<UserModel>>(
                  stream: firestoreService.getResponders(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                    final activeResponders = snapshot.data!.where((r) => r.isActive).toList();
                    
                    if (activeResponders.isEmpty) {
                      return Center(child: Text('No active responders available', style: TextStyle(color: isDark ? Colors.white38 : Colors.black45)));
                    }
  
                    return ListView.builder(
                      itemCount: activeResponders.length,
                      itemBuilder: (context, index) {
                        final responder = activeResponders[index];
                        return ListTile(
                          leading: ProfileImage(source: responder.profileImage, radius: 20),
                          title: Text(responder.name, style: TextStyle(color: isDark ? Colors.white : Colors.black87)),
                          subtitle: Text(responder.role.toUpperCase(), style: const TextStyle(color: AppConstants.primaryRed, fontSize: 10, fontWeight: FontWeight.bold)),
                          trailing: Icon(Icons.chevron_right, color: isDark ? Colors.white24 : Colors.black26),
                          onTap: () async {
                            await firestoreService.assignSOS(sos.sosId, responder.userId);
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Emergency unit ${responder.name} dispatched!'))
                            );
                          },
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
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
}
