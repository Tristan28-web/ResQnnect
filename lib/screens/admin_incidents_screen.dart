import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/firestore_service.dart';
import '../models/incident_model.dart';
import '../models/user_model.dart';
import '../core/constants.dart';
import 'package:intl/intl.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'global_map_screen.dart';
import '../widgets/profile_image.dart';
import 'dart:convert';

class AdminIncidentsScreen extends StatelessWidget {
  const AdminIncidentsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final firestoreService = Provider.of<FirestoreService>(context, listen: false);

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        appBar: AppBar(
          title: const Text('INCIDENT CENTER', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
          centerTitle: true,
          bottom: TabBar(
            tabs: const [
              Tab(text: 'CITIZEN REPORTS'),
              Tab(text: 'RESPONDER LOGS'),
            ],
            indicatorColor: AppConstants.primaryRed,
            labelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
            labelColor: AppConstants.primaryRed,
            unselectedLabelColor: Theme.of(context).brightness == Brightness.dark ? Colors.white54 : Colors.black54,
          ),
        ),
        body: StreamBuilder<List<IncidentModel>>(
          stream: firestoreService.getIncidents(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator(color: AppConstants.primaryRed));
            }

            final allIncidents = snapshot.data ?? [];
            return TabBarView(
              children: [
                _buildIncidentList(context, allIncidents.where((i) => i.assignedTo == null).toList(), "No new reports from citizens."),
                _buildIncidentList(context, allIncidents.where((i) => i.assignedTo != null).toList(), "No active responder logs."),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildIncidentList(BuildContext context, List<IncidentModel> incidents, String emptyMessage) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    if (incidents.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.assignment_turned_in_outlined, size: 64, color: (isDark ? Colors.white : Colors.black).withOpacity(0.1)),
            const SizedBox(height: 16),
            Text(emptyMessage, style: TextStyle(color: isDark ? Colors.white38 : Colors.black45)),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: incidents.length,
      itemBuilder: (context, index) {
        final incident = incidents[index];
        return _buildIncidentCard(context, incident);
      },
    );
  }

  Widget _buildIncidentCard(BuildContext context, IncidentModel incident) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        gradient: isDark ? const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1E2841), Color(0xFF161E31)],
        ) : null,
        color: isDark ? null : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: (isDark ? Colors.white : Colors.black).withOpacity(0.05)),
        boxShadow: isDark
            ? [const BoxShadow(color: Colors.black26, blurRadius: 10, offset: Offset(0, 4))]
            : [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppConstants.primaryRed.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.warning_amber_rounded, color: AppConstants.primaryRed, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        incident.description,
                        style: TextStyle(color: isDark ? Colors.white : Colors.black87, fontWeight: FontWeight.bold, fontSize: 16),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        DateFormat('MMM dd, hh:mm a').format(incident.timestamp),
                        style: TextStyle(color: isDark ? Colors.white54 : Colors.black54, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    incident.status.toUpperCase(),
                    style: const TextStyle(color: Colors.orange, fontSize: 10, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
          if (incident.imageBase64 != null && incident.imageBase64!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Builder(
                  builder: (context) {
                    try {
                      return Image.memory(
                        base64Decode(incident.imageBase64!),
                        height: 150,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => const SizedBox.shrink(),
                      );
                    } catch (e) {
                      return const SizedBox.shrink();
                    }
                  }
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                InkWell(
                  onTap: () {
                    final latLng = _parseLocation(incident.location);
                    if (latLng != null) {
                      Navigator.push(context, MaterialPageRoute(builder: (_) => GlobalMapScreen(initialLocation: latLng)));
                    }
                  },
                  child: Row(
                    children: [
                      const Icon(Icons.location_on_outlined, size: 14, color: Colors.blueAccent),
                      const SizedBox(width: 4),
                      Text(
                        incident.location,
                        style: const TextStyle(color: Colors.blueAccent, fontSize: 12, fontWeight: FontWeight.w600, decoration: TextDecoration.underline),
                      ),
                    ],
                  ),
                ),
                if (incident.assignedTo == null)
                  ElevatedButton.icon(
                    onPressed: () => _showAssignResponderDialog(context, incident),
                    icon: const Icon(Icons.person_add, size: 14),
                    label: const Text('ASSIGN', style: TextStyle(fontSize: 10)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppConstants.primaryRed,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
                      minimumSize: const Size(0, 32),
                    ),
                  )
                else
                  const Row(
                    children: [
                      Icon(Icons.check_circle, size: 14, color: Colors.green),
                      SizedBox(width: 4),
                      Text('ASSIGNED', style: TextStyle(color: Colors.green, fontSize: 10, fontWeight: FontWeight.bold)),
                    ],
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showAssignResponderDialog(BuildContext context, IncidentModel incident) {
    final firestoreService = Provider.of<FirestoreService>(context, listen: false);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1E2841),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(32))),
      elevation: 24,
      builder: (context) => SafeArea(
        child: Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Assign Responder', style: TextStyle(color: isDark ? Colors.white : Colors.black87, fontWeight: FontWeight.bold, fontSize: 18)),
              const SizedBox(height: 16),
              Text('Select an active responder to dispatch to this incident:', style: TextStyle(color: isDark ? Colors.white54 : Colors.black54, fontSize: 13)),
              const SizedBox(height: 20),
              Expanded(
                child: StreamBuilder<List<UserModel>>(
                  stream: firestoreService.getResponders(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                    final activeResponders = snapshot.data!.where((r) => r.isActive).toList();
                    
                    if (activeResponders.isEmpty) {
                      return const Center(child: Text('No active responders available', style: TextStyle(color: Colors.white38)));
                    }
  
                    return ListView.builder(
                      itemCount: activeResponders.length,
                      itemBuilder: (context, index) {
                        final responder = activeResponders[index];
                        return ListTile(
                          leading: ProfileImage(source: responder.profileImage, radius: 20),
                          title: Text(responder.name, style: const TextStyle(color: Colors.white)),
                          subtitle: Text(responder.role.toUpperCase(), style: const TextStyle(color: AppConstants.primaryRed, fontSize: 10, fontWeight: FontWeight.bold)),
                          trailing: const Icon(Icons.chevron_right, color: Colors.white24),
                          onTap: () async {
                            await firestoreService.assignIncident(incident.incidentId, responder.userId);
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Dispatched ${responder.name} to incident.'))
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
