import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/firestore_service.dart';
import '../models/incident_model.dart';
import '../models/sos_model.dart';
import '../core/constants.dart';
import 'package:intl/intl.dart';

class ResponderTasksScreen extends StatefulWidget {
  const ResponderTasksScreen({super.key});

  @override
  State<ResponderTasksScreen> createState() => _ResponderTasksScreenState();
}

class _ResponderTasksScreenState extends State<ResponderTasksScreen> {
  String _selectedCategory = 'All';

  @override
  Widget build(BuildContext context) {
    final firestoreService = Provider.of<FirestoreService>(context, listen: false);
    final userId = FirebaseAuth.instance.currentUser?.uid ?? '';
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        appBar: AppBar(
          title: Text(
            'MY TASKS & DISPATCHES',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.3,
              color: isDark ? Colors.white : AppColors.retroDarkBorder,
            ),
          ),
          centerTitle: true,
          backgroundColor: Colors.transparent,
          elevation: 0,
          iconTheme: IconThemeData(color: isDark ? Colors.white : AppColors.retroDarkBorder),
          bottom: TabBar(
            tabs: const [
              Tab(text: 'INCIDENTS'),
              Tab(text: 'SOS REQUESTS'),
            ],
            indicatorColor: AppColors.retroMint,
            indicatorWeight: 3,
            labelColor: isDark ? Colors.white : AppColors.retroDarkBorder,
            unselectedLabelColor: isDark ? Colors.white38 : const Color(0xFF9CA3AF),
            labelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w900, letterSpacing: 0.8),
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
    return Column(
      children: [
        _buildCategoryFilterBar(isDark),
        Expanded(
          child: StreamBuilder<List<IncidentModel>>(
            stream: firestoreService.getIncidents(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator(color: AppColors.retroMint));
              }

              final allIncidents = snapshot.data ?? [];
              final myIncidents = allIncidents
                  .where((i) => i.assignedTo == userId)
                  .where((i) => _selectedCategory == 'All' || i.incidentType.toLowerCase() == _selectedCategory.toLowerCase())
                  .toList();

              if (myIncidents.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 68,
                        height: 68,
                        decoration: BoxDecoration(
                          color: AppColors.retroPeach,
                          shape: BoxShape.circle,
                          border: Border.all(color: AppColors.retroDarkBorder, width: 1.8),
                        ),
                        child: const Icon(Icons.checklist_rounded, size: 32, color: AppColors.retroDarkBorder),
                      ),
                      const SizedBox(height: 14),
                      Text(
                        _selectedCategory == 'All'
                            ? 'No assigned incidents'
                            : 'No $_selectedCategory incidents assigned',
                        style: TextStyle(
                          color: isDark ? Colors.white70 : AppColors.retroDarkBorder,
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                );
              }

              return ListView.builder(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.all(20),
                itemCount: myIncidents.length,
                itemBuilder: (context, index) {
                  final incident = myIncidents[index];
                  return _buildRetroTaskTile(
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
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryFilterBar(bool isDark) {
    final categories = ['All', 'Fire', 'Flood', 'Medical', 'Accident', 'Hotspot'];
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      height: 52,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: categories.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final cat = categories[index];
          final isSelected = _selectedCategory == cat;
          return GestureDetector(
            onTap: () => setState(() => _selectedCategory = cat),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.retroMint
                    : (isDark ? AppColors.retroDarkCard : Colors.white),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isSelected ? AppColors.retroDarkBorder : (isDark ? const Color(0xFF3E4556) : AppColors.retroDarkBorder),
                  width: 1.4,
                ),
                boxShadow: [
                  BoxShadow(
                    color: isDark ? Colors.black38 : AppColors.retroDarkBorder.withOpacity(0.12),
                    offset: const Offset(2, 2),
                    blurRadius: 0,
                  ),
                ],
              ),
              child: Center(
                child: Text(
                  cat,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                    color: isSelected ? Colors.white : (isDark ? Colors.white70 : AppColors.retroDarkBorder),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSOSTab(FirestoreService firestoreService, String userId, bool isDark) {
    return StreamBuilder<List<SOSRequestModel>>(
      stream: firestoreService.getSOSRequests(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: AppColors.retroMint));
        }

        final allSOS = snapshot.data ?? [];
        final mySOS = allSOS.where((s) => s.assignedTo == userId).toList();

        if (mySOS.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 68,
                  height: 68,
                  decoration: BoxDecoration(
                    color: AppColors.retroLilac,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.retroDarkBorder, width: 1.8),
                  ),
                  child: const Icon(Icons.emergency_rounded, size: 32, color: AppColors.retroDarkBorder),
                ),
                const SizedBox(height: 14),
                Text(
                  'No assigned SOS requests',
                  style: TextStyle(
                    color: isDark ? Colors.white70 : AppColors.retroDarkBorder,
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.all(20),
          itemCount: mySOS.length,
          itemBuilder: (context, index) {
            final sos = mySOS[index];
            return _buildRetroTaskTile(
              context,
              title: 'SOS EMERGENCY DISPATCH',
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

  Widget _buildRetroTaskTile(
    BuildContext context, {
    required String title,
    required String location,
    required String status,
    required DateTime timestamp,
    required Function(String) onStatusChange,
    required String type,
    required bool isDark,
  }) {
    Color statusBg = AppColors.retroPeach;
    Color statusTextColor = const Color(0xFFD97706);

    if (status.toLowerCase() == 'resolved') {
      statusBg = const Color(0xFFDCFCE7);
      statusTextColor = const Color(0xFF16A34A);
    } else if (status.toLowerCase() == 'in_progress' || status.toLowerCase() == 'dispatched') {
      statusBg = AppColors.retroLilac;
      statusTextColor = const Color(0xFF2563EB);
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark ? AppColors.retroDarkCard : Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: isDark ? const Color(0xFF3E4556) : AppColors.retroDarkBorder,
          width: 1.8,
        ),
        boxShadow: [
          BoxShadow(
            color: isDark ? Colors.black45 : AppColors.retroDarkBorder.withOpacity(0.12),
            offset: const Offset(3, 3),
            blurRadius: 0,
          ),
        ],
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
                  color: type == 'SOS' ? const Color(0xFFFEE2E2) : AppColors.retroLilac,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.retroDarkBorder, width: 1.2),
                ),
                child: Text(
                  type,
                  style: TextStyle(
                    color: type == 'SOS' ? const Color(0xFFDC2626) : const Color(0xFF4F46E5),
                    fontSize: 9,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.8,
                  ),
                ),
              ),
              Text(
                DateFormat('hh:mm a').format(timestamp),
                style: TextStyle(
                  color: isDark ? Colors.white38 : const Color(0xFF888E99),
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: TextStyle(
              color: isDark ? Colors.white : AppColors.retroDarkBorder,
              fontWeight: FontWeight.w900,
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              const Icon(Icons.location_on_rounded, size: 14, color: Color(0xFFEF4444)),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  location,
                  style: TextStyle(
                    color: isDark ? Colors.white60 : const Color(0xFF6B7280),
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
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
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: statusBg,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.retroDarkBorder, width: 1.2),
                ),
                child: Text(
                  status.toUpperCase(),
                  style: TextStyle(
                    color: statusTextColor,
                    fontSize: 9,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              PopupMenuButton<String>(
                onSelected: onStatusChange,
                color: isDark ? AppColors.retroDarkCard : Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: const BorderSide(color: AppColors.retroDarkBorder, width: 1.4),
                ),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.retroMint,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.retroDarkBorder, width: 1.4),
                  ),
                  child: const Row(
                    children: [
                      Text(
                        'UPDATE STATUS',
                        style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w900),
                      ),
                      SizedBox(width: 4),
                      Icon(Icons.arrow_drop_down_rounded, color: Colors.white, size: 16),
                    ],
                  ),
                ),
                itemBuilder: (context) => [
                  PopupMenuItem(
                    value: 'pending',
                    child: Text('Pending', style: TextStyle(color: isDark ? Colors.white : AppColors.retroDarkBorder, fontWeight: FontWeight.bold)),
                  ),
                  PopupMenuItem(
                    value: 'in_progress',
                    child: Text('In Progress', style: TextStyle(color: isDark ? Colors.white : AppColors.retroDarkBorder, fontWeight: FontWeight.bold)),
                  ),
                  PopupMenuItem(
                    value: 'resolved',
                    child: Text('Resolved', style: TextStyle(color: isDark ? Colors.white : AppColors.retroDarkBorder, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
