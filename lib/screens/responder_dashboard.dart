import 'package:flutter/material.dart';
import '../core/constants.dart';
import 'report_screen.dart';
import 'alerts_screen.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/firestore_service.dart';
import '../models/user_model.dart';
import 'incident_mapping_screen.dart';
import 'incident_monitoring_screen.dart';
import 'hotspot_identification_screen.dart';
import 'responder_tasks_screen.dart';
import 'dart:async';
import 'dart:convert';

class ResponderDashboard extends StatefulWidget {
  const ResponderDashboard({super.key});

  @override
  State<ResponderDashboard> createState() => _ResponderDashboardState();
}

class _ResponderDashboardState extends State<ResponderDashboard> with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  Timer? _shiftTimer;
  
  Stream<UserModel?>? _userStream;
  Stream<Map<String, dynamic>?>? _missionStream;
  Stream<int>? _incidentCountStream;
  Stream<int>? _alertCountStream;

  @override
  void initState() {
    super.initState();
    final userId = FirebaseAuth.instance.currentUser?.uid ?? '';
    final firestore = Provider.of<FirestoreService>(context, listen: false);
    
    _userStream = firestore.getUserStream(userId);
    _missionStream = firestore.getAssignedMission(userId);
    _incidentCountStream = firestore.getIncidentCountByUser(userId);
    _alertCountStream = firestore.getAlertCount();
    
    _startShiftTimer();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
  }

  @override
  void dispose() {
    _shiftTimer?.cancel();
    _pulseController.dispose();
    super.dispose();
  }

  void _startShiftTimer() {
    _shiftTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      if (mounted) setState(() {});
    });
  }

  String _calculateShift(DateTime? clockIn) {
    if (clockIn == null) return '0m';
    final diff = DateTime.now().difference(clockIn);
    if (diff.inHours > 0) {
      return '${diff.inHours}h ${diff.inMinutes % 60}m';
    }
    return '${diff.inMinutes}m';
  }

  LatLng? _parseLocation(String locStr) {
    try {
      final parts = locStr.split(',');
      if (parts.length >= 2) {
        final lat = double.parse(parts[0].trim());
        final lng = double.parse(parts[1].trim());
        return LatLng(lat, lng);
      }
    } catch (_) {}
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final firestoreService = Provider.of<FirestoreService>(context, listen: false);
    final userId = FirebaseAuth.instance.currentUser?.uid ?? '';

    return StreamBuilder<UserModel?>(
      stream: _userStream,
      builder: (context, userSnapshot) {
        final user = userSnapshot.data;
        final isActive = user?.isActive ?? false;
        final shiftTime = _calculateShift(user?.lastClockIn);

        return StreamBuilder<Map<String, dynamic>?>(
          stream: _missionStream,
          builder: (context, missionSnapshot) {
            final mission = missionSnapshot.data;

            return SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: [
                  const SizedBox(height: 20),
                  _buildMissionStatusCard(context, mission, shiftTime),
                  const SizedBox(height: 36),
                  _buildStatusControl(context, firestoreService, userId, isActive, mission),
                  const SizedBox(height: 36),
                  _buildActionGrid(context),
                  const SizedBox(height: 100),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildMissionStatusCard(BuildContext context, Map<String, dynamic>? mission, String shiftTime) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final hasMission = mission != null;

    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [const Color(0xFF1E2841), const Color(0xFF161E31)]
              : [const Color(0xFFE8F0FE), const Color(0xFFF0F4FF)],
        ),
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: isDark ? Colors.black.withOpacity(0.3) : Colors.black.withOpacity(0.07),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('DISPATCH MISSION', style: TextStyle(color: isDark ? Colors.white60 : Colors.black54, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1.5)),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Container(
                        width: 8, height: 8,
                        decoration: BoxDecoration(
                          color: hasMission ? AppConstants.primaryRed : Colors.greenAccent,
                          shape: BoxShape.circle,
                          boxShadow: [
                            if (hasMission) BoxShadow(color: AppConstants.primaryRed.withOpacity(0.5), blurRadius: 10, spreadRadius: 2)
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        hasMission ? 'ACTIVE DISPATCH' : 'STANDING BY',
                        style: TextStyle(
                          color: hasMission ? AppConstants.primaryRed : Colors.greenAccent,
                          fontSize: 12,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              if (hasMission)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: isDark ? Colors.white10 : Colors.black12),
                  ),
                  child: Text(
                    mission['mission_type'] ?? 'TASK',
                    style: TextStyle(color: isDark ? Colors.white70 : Colors.black87, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 24),
          if (hasMission && mission['image_base64'] != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 20),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Builder(
                  builder: (context) {
                    try {
                      final imgBase64 = mission['image_base64'];
                      if (imgBase64 == null || imgBase64.isEmpty) {
                        return const SizedBox.shrink();
                      }
                      return Image.memory(
                        base64Decode(imgBase64),
                        height: 180,
                        width: double.infinity,
                        fit: BoxFit.cover,
                      );
                    } catch (_) {
                      return const SizedBox.shrink();
                    }
                  },
                ),
              ),
            ),
          if (!hasMission)
            Padding(
              padding: const EdgeInsets.only(bottom: 24),
              child: Center(child: _buildPulseRadar()),
            ),
          Text(
            hasMission ? mission['description'] ?? 'Mission' : 'No Active Emergency Dispatch',
            style: TextStyle(color: isDark ? Colors.white : Colors.black87, fontSize: 22, fontWeight: FontWeight.bold, letterSpacing: -0.5),
          ),
          if (!hasMission)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Row(
                children: [
                  Container(
                    width: 6, height: 6,
                    decoration: const BoxDecoration(color: Colors.greenAccent, shape: BoxShape.circle),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'GIS responder location active with LGU Command Center',
                    style: TextStyle(color: Colors.greenAccent, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 12),
          if (hasMission)
            Row(
              children: [
                const Icon(Icons.location_on, color: AppConstants.primaryRed, size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    mission['location'] ?? 'Assigned Location',
                    style: TextStyle(color: isDark ? Colors.white60 : Colors.black54, fontSize: 14, fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
          if (hasMission)
            Padding(
              padding: const EdgeInsets.only(top: 24),
              child: Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const IncidentMappingScreen(),
                          ),
                        );
                      },
                      icon: const Icon(Icons.map_rounded, size: 18),
                      label: const Text('VIEW ON GIS MAP', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppConstants.primaryRed,
                        foregroundColor: Colors.white,
                        minimumSize: const Size(double.infinity, 56),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        elevation: 8,
                        shadowColor: AppConstants.primaryRed.withOpacity(0.4),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    height: 56,
                    width: 56,
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: IconButton(
                      onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ResponderTasksScreen())),
                      icon: Icon(Icons.checklist_rounded, color: isDark ? Colors.white70 : Colors.black87),
                      tooltip: 'Update Status',
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 32),
          Divider(color: isDark ? Colors.white12 : Colors.black12, height: 1),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              StreamBuilder<int>(
                stream: _incidentCountStream,
                builder: (context, snapshot) => _buildStatItem(context, 'RESOLVED', snapshot.data?.toString() ?? '0', Icons.assignment_turned_in_rounded),
              ),
              StreamBuilder<int>(
                stream: _alertCountStream,
                builder: (context, snapshot) => _buildStatItem(context, 'ALERTS', snapshot.data?.toString() ?? '0', Icons.notifications_active_rounded, isAlert: true),
              ),
              _buildStatItem(context, 'SHIFT', shiftTime, Icons.timer_rounded),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPulseRadar() {
    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, child) {
        return Stack(
          alignment: Alignment.center,
          children: [
            Container(
              width: 100 * (1 + _pulseController.value * 0.4),
              height: 100 * (1 + _pulseController.value * 0.4),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.greenAccent.withOpacity((1 - _pulseController.value) * 0.15),
              ),
            ),
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.greenAccent.withOpacity(0.1),
              ),
              child: const Icon(Icons.radar_rounded, color: Colors.greenAccent, size: 36),
            ),
          ],
        );
      },
    );
  }

  Widget _buildStatItem(BuildContext context, String label, String value, IconData icon, {bool isAlert = false}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      children: [
        Icon(icon, color: isAlert ? AppConstants.primaryRed.withOpacity(0.5) : (isDark ? Colors.white24 : Colors.black26), size: 18),
        const SizedBox(height: 10),
        Text(value, style: TextStyle(color: isDark ? Colors.white : Colors.black87, fontSize: 18, fontWeight: FontWeight.w900)),
        const SizedBox(height: 2),
        Text(label, style: TextStyle(color: isDark ? Colors.white24 : Colors.black38, fontSize: 8, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
      ],
    );
  }

  Widget _buildStatusControl(BuildContext context, FirestoreService firestoreService, String userId, bool isActive, Map<String, dynamic>? activeMission) {
    return Center(
      child: Column(
        children: [
          InkWell(
            onTap: () async {
              if (isActive && activeMission != null) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Cannot go offline while you have an active mission! Please resolve it first.'),
                      backgroundColor: AppConstants.primaryRed,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
                return;
              }

              try {
                await firestoreService.toggleResponderActive(userId, isActive);
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Failed to update status: $e'), backgroundColor: Colors.red),
                  );
                }
              }
            },
            borderRadius: BorderRadius.circular(100),
            child: Container(
              width: 170,
              height: 170,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: (isActive ? Colors.green : Colors.grey).withOpacity(0.05),
              ),
              child: Center(
                child: Container(
                  width: 130,
                  height: 130,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: isActive 
                        ? [const Color(0xFF43A047), const Color(0xFF1B5E20)]
                        : [const Color(0xFF424242), const Color(0xFF212121)],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: (isActive ? Colors.green : Colors.black).withOpacity(0.3), 
                        blurRadius: 36, 
                        spreadRadius: 4
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        isActive ? Icons.verified_user_rounded : Icons.power_settings_new_rounded, 
                        color: Colors.white, 
                        size: 38
                      ),
                      const SizedBox(height: 6),
                      Text(
                        isActive ? 'ON-DUTY' : 'OFF-DUTY', 
                        style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900, letterSpacing: 1)
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            decoration: BoxDecoration(
              color: isActive ? Colors.green.withOpacity(0.1) : (Theme.of(context).brightness == Brightness.dark ? Colors.white.withOpacity(0.03) : Colors.black.withOpacity(0.05)),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              isActive ? 'RESPONDER ACTIVE & AVAILABLE' : 'RESPONDER CURRENTLY OFF-DUTY',
              style: TextStyle(
                color: isActive ? Colors.green : (Theme.of(context).brightness == Brightness.dark ? Colors.white24 : Colors.black38),
                fontSize: 10,
                fontWeight: FontWeight.w900,
                letterSpacing: 1,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionGrid(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 14),
          child: Text(
            'LGU FIELD OPERATIONS',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.2,
              color: Theme.of(context).brightness == Brightness.dark ? Colors.white54 : Colors.black54,
            ),
          ),
        ),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          crossAxisSpacing: 14,
          mainAxisSpacing: 14,
          childAspectRatio: 1.15,
          children: [
            _buildActionCard(context, 'GIS Mapping', 'Interactive pins & paths', Icons.map_rounded, const Color(0xFF1E88E5), const IncidentMappingScreen()),
            _buildActionCard(context, 'Incident Monitor', 'Dispatches & queue', Icons.dvr_rounded, const Color(0xFF3949AB), const IncidentMonitoringScreen()),
            _buildActionCard(context, 'Report Incident', 'Field log & pinning', Icons.add_location_alt_rounded, AppConstants.primaryRed, const ReportScreen()),
            _buildActionCard(context, 'Hotspot Heatmap', 'High-risk clusters', Icons.whatshot_rounded, const Color(0xFFE65100), const HotspotIdentificationScreen()),
            _buildActionCard(context, 'LGU Alerts', 'Priority advisories', Icons.notifications_active_rounded, const Color(0xFFD81B60), const AlertsScreen()),
            _buildActionCard(context, 'Task Status', 'Update mission checklist', Icons.checklist_rounded, Colors.blueGrey, const ResponderTasksScreen()),
          ],
        ),
      ],
    );
  }

  Widget _buildActionCard(BuildContext context, String title, String subtitle, IconData icon, Color iconColor, Widget screen) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return InkWell(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => screen)),
      borderRadius: BorderRadius.circular(24),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          gradient: isDark ? const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF1E2841), Color(0xFF161E31)],
          ) : null,
          color: isDark ? null : Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: isDark ? Colors.white.withOpacity(0.06) : Colors.black.withOpacity(0.06)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isDark ? 0.25 : 0.04),
              blurRadius: 10,
              offset: const Offset(0, 4),
            )
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.18),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(icon, color: iconColor, size: 24),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(color: isDark ? Colors.white : Colors.black87, fontSize: 15, fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 2),
                Text(subtitle, style: TextStyle(color: isDark ? Colors.white54 : Colors.black54, fontSize: 11), maxLines: 1, overflow: TextOverflow.ellipsis),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
