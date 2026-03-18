import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/firestore_service.dart';
import '../models/incident_model.dart';
import '../models/sos_model.dart';
import '../core/constants.dart';
import 'package:intl/intl.dart';

class ResponderTasksScreen extends StatelessWidget {
  const ResponderTasksScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final firestoreService = Provider.of<FirestoreService>(context, listen: false);
    final userId = FirebaseAuth.instance.currentUser?.uid ?? '';
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: isDark ? AppConstants.backgroundBlack : Colors.grey.shade100,
        appBar: AppBar(
          title: const Text('MY TASKS & DISPATCHES', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
          centerTitle: true,
          bottom: const TabBar(
            tabs: [
              Tab(text: 'INCIDENTS'),
              Tab(text: 'SOS REQUESTS'),
            ],
            indicatorColor: AppConstants.primaryRed,
            labelStyle: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
          ),
        ),
        body: TabBarView(
          children: [
            _buildIncidentsTab(firestoreService, userId, isDark),
            _buildSOSTab(firestoreService, userId, isDark),
          ],
        ),
      ),
    );
  }

  Widget _buildIncidentsTab(FirestoreService firestoreService, String userId, bool isDark) {
    return StreamBuilder<List<IncidentModel>>(
      stream: firestoreService.getIncidents(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: AppConstants.primaryRed));
        }
        
        final allIncidents = snapshot.data ?? [];
        final myIncidents = allIncidents.where((i) => i.assignedTo == userId).toList();

        if (myIncidents.isEmpty) {
          return Center(
            child: Text('No assigned incidents.', style: TextStyle(color: isDark ? Colors.white38 : Colors.black45)),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(20),
          itemCount: myIncidents.length,
          itemBuilder: (context, index) {
            final incident = myIncidents[index];
            return _buildTaskTile(
              context,
              title: incident.description,
              location: incident.location,
              status: incident.status,
              timestamp: incident.timestamp,
              onStatusChange: (newStatus) => firestoreService.updateIncidentStatus(incident.incidentId, newStatus),
              type: 'INCIDENT',
              isDark: isDark,
            );
          },
        );
      },
    );
  }

  Widget _buildSOSTab(FirestoreService firestoreService, String userId, bool isDark) {
    return StreamBuilder<List<SOSRequestModel>>(
      stream: firestoreService.getSOSRequests(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: AppConstants.primaryRed));
        }
        
        final allSOS = snapshot.data ?? [];
        final mySOS = allSOS.where((s) => s.assignedTo == userId).toList();

        if (mySOS.isEmpty) {
          return Center(
            child: Text('No assigned SOS requests.', style: TextStyle(color: isDark ? Colors.white38 : Colors.black45)),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(20),
          itemCount: mySOS.length,
          itemBuilder: (context, index) {
            final sos = mySOS[index];
            return _buildTaskTile(
              context,
              title: 'SOS EMERGENCY',
              location: sos.location,
              status: sos.status,
              timestamp: sos.timestamp,
              onStatusChange: (newStatus) => firestoreService.updateSOSStatus(sos.sosId, newStatus),
              type: 'SOS',
              isDark: isDark,
            );
          },
        );
      },
    );
  }

  Widget _buildTaskTile(
    BuildContext context, {
    required String title,
    required String location,
    required String status,
    required DateTime timestamp,
    required Function(String) onStatusChange,
    required String type,
    required bool isDark,
  }) {
    Color statusColor = Colors.orange;
    if (status == 'resolved') statusColor = Colors.green;
    if (status == 'pending') statusColor = Colors.orange;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? null : Colors.white,
        gradient: isDark
            ? const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF1E2841), Color(0xFF161E31)],
              )
            : null,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.06)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(isDark ? 0.45 : 0.06), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: (type == 'SOS' ? Colors.red : Colors.blue).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  type,
                  style: TextStyle(
                    color: type == 'SOS' ? Colors.red : Colors.blue,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Text(
                DateFormat('hh:mm a').format(timestamp),
                style: TextStyle(color: isDark ? Colors.white38 : Colors.black38, fontSize: 11),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: TextStyle(color: isDark ? Colors.white : Colors.black87, fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              const Icon(Icons.location_on, size: 14, color: AppConstants.primaryRed),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  location,
                  style: TextStyle(color: isDark ? Colors.white54 : Colors.black54, fontSize: 12),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Text('Status: ', style: TextStyle(color: isDark ? Colors.white38 : Colors.black45, fontSize: 13)),
                  Text(
                    status.toUpperCase(),
                    style: TextStyle(color: statusColor, fontSize: 13, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              PopupMenuButton<String>(
                onSelected: onStatusChange,
                color: isDark ? AppConstants.surfaceDark : Colors.white,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    border: Border.all(color: AppConstants.primaryRed),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Row(
                    children: [
                      Text('UPDATE', style: TextStyle(color: AppConstants.primaryRed, fontSize: 11, fontWeight: FontWeight.bold)),
                      Icon(Icons.arrow_drop_down, color: AppConstants.primaryRed, size: 16),
                    ],
                  ),
                ),
                itemBuilder: (context) => [
                  PopupMenuItem(value: 'pending', child: Text('Pending', style: TextStyle(color: isDark ? Colors.white : Colors.black87))),
                  PopupMenuItem(value: 'in_progress', child: Text('In Progress', style: TextStyle(color: isDark ? Colors.white : Colors.black87))),
                  PopupMenuItem(value: 'resolved', child: Text('Resolved', style: TextStyle(color: isDark ? Colors.white : Colors.black87))),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
