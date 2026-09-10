import 'package:flutter/material.dart';
import '../core/constants.dart';
import 'report_screen.dart';
import 'alerts_screen.dart';
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
                  const SizedBox(height: 16),
                  _buildMissionStatusCard(context, mission, shiftTime),
                  const SizedBox(height: 28),
                  _buildStatusControl(context, firestoreService, userId, isActive, mission),
                  const SizedBox(height: 28),
                  _buildActionGrid(context),
                  const SizedBox(height: 110),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // --- RETRO PEACH MISSION CARD ---
  Widget _buildMissionStatusCard(BuildContext context, Map<String, dynamic>? mission, String shiftTime) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final hasMission = mission != null;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2B2421) : AppColors.retroPeach,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(
          color: isDark ? const Color(0xFF4A3C38) : AppColors.retroDarkBorder,
          width: 2.0,
        ),
        boxShadow: [
          BoxShadow(
            color: isDark ? Colors.black45 : AppColors.retroMintDark,
            offset: const Offset(4, 4),
            blurRadius: 0,
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: isDark ? Colors.black38 : Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: isDark ? Colors.white24 : AppColors.retroDarkBorder,
                          width: 1.4,
                        ),
                      ),
                      child: Text(
                        'DISPATCH MISSION',
                        style: TextStyle(
                          color: isDark ? Colors.white70 : AppColors.retroDarkBorder,
                          fontSize: 9,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: hasMission ? const Color(0xFFEF4444) : const Color(0xFF22C55E),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          hasMission ? 'ACTIVE DISPATCH' : 'STANDING BY',
                          style: TextStyle(
                            color: hasMission ? const Color(0xFFDC2626) : const Color(0xFF16A34A),
                            fontSize: 12,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.8,
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
                      color: AppColors.retroLilac,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.retroDarkBorder, width: 1.4),
                    ),
                    child: Text(
                      mission['mission_type'] ?? 'TASK',
                      style: const TextStyle(
                        color: AppColors.retroDarkBorder,
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 18),
            if (hasMission && mission['image_base64'] != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(18),
                  child: Builder(
                    builder: (context) {
                      try {
                        final imgBase64 = mission['image_base64'];
                        if (imgBase64 == null || imgBase64.isEmpty) {
                          return const SizedBox.shrink();
                        }
                        return Image.memory(
                          base64Decode(imgBase64),
                          height: 160,
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
                padding: const EdgeInsets.only(bottom: 20),
                child: Center(child: _buildPulseRadar()),
              ),
            Text(
              hasMission ? (mission['description'] ?? 'Mission') : 'No Active Emergency Dispatch',
              style: TextStyle(
                color: isDark ? Colors.white : AppColors.retroDarkBorder,
                fontSize: 20,
                fontWeight: FontWeight.w900,
                letterSpacing: -0.4,
              ),
            ),
            if (!hasMission)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Row(
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(color: Color(0xFF22C55E), shape: BoxShape.circle),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'GIS location connected with LGU Command Center',
                      style: TextStyle(
                        color: isDark ? const Color(0xFF86EFAC) : const Color(0xFF15803D),
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            if (hasMission) ...[
              const SizedBox(height: 10),
              Row(
                children: [
                  const Icon(Icons.location_on_rounded, color: Color(0xFFEF4444), size: 16),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      mission['location'] ?? 'Assigned Location',
                      style: TextStyle(
                        color: isDark ? Colors.white70 : const Color(0xFF4B5563),
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const IncidentMappingScreen()),
                        );
                      },
                      icon: const Icon(Icons.map_rounded, size: 16),
                      label: const Text('VIEW ON GIS MAP', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 12)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.retroMint,
                        foregroundColor: Colors.white,
                        minimumSize: const Size(double.infinity, 48),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                          side: const BorderSide(color: AppColors.retroDarkBorder, width: 1.6),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Container(
                    height: 48,
                    width: 48,
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.retroDarkCard : Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.retroDarkBorder, width: 1.6),
                    ),
                    child: IconButton(
                      onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ResponderTasksScreen())),
                      icon: Icon(Icons.checklist_rounded, color: isDark ? Colors.white : AppColors.retroDarkBorder),
                      tooltip: 'Update Status',
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 20),
            Divider(color: isDark ? Colors.white12 : AppColors.retroDarkBorder.withOpacity(0.2), height: 1),
            const SizedBox(height: 16),
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
              width: 90 * (1 + _pulseController.value * 0.3),
              height: 90 * (1 + _pulseController.value * 0.3),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF22C55E).withOpacity((1 - _pulseController.value) * 0.2),
              ),
            ),
            Container(
              width: 68,
              height: 68,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white,
                border: Border.all(color: AppColors.retroDarkBorder, width: 1.8),
              ),
              child: const Icon(Icons.radar_rounded, color: Color(0xFF16A34A), size: 32),
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
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: isDark ? AppColors.retroDarkCard : Colors.white,
            shape: BoxShape.circle,
            border: Border.all(
              color: isDark ? const Color(0xFF3E4556) : AppColors.retroDarkBorder,
              width: 1.4,
            ),
          ),
          child: Center(
            child: Icon(
              icon,
              color: isAlert ? const Color(0xFFEF4444) : (isDark ? Colors.white70 : AppColors.retroDarkBorder),
              size: 18,
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          value,
          style: TextStyle(
            color: isDark ? Colors.white : AppColors.retroDarkBorder,
            fontSize: 16,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            color: isDark ? Colors.white38 : const Color(0xFF6B7280),
            fontSize: 8,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }

  // --- RETRO STATUS CONTROL ---
  Widget _buildStatusControl(BuildContext context, FirestoreService firestoreService, String userId, bool isActive, Map<String, dynamic>? activeMission) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Center(
      child: Column(
        children: [
          GestureDetector(
            onTap: () async {
              if (isActive && activeMission != null) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Cannot go offline while you have an active mission! Please resolve it first.'),
                      backgroundColor: Color(0xFFEF4444),
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
            child: Container(
              width: 150,
              height: 150,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isActive ? const Color(0xFFDCFCE7) : const Color(0xFFF1F5F9),
                border: Border.all(
                  color: AppColors.retroDarkBorder,
                  width: 2.2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: isDark ? Colors.black45 : AppColors.retroDarkBorder.withOpacity(0.15),
                    offset: const Offset(4, 4),
                    blurRadius: 0,
                  ),
                ],
              ),
              child: Center(
                child: Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isActive ? AppColors.retroMint : const Color(0xFF64748B),
                    border: Border.all(color: AppColors.retroDarkBorder, width: 1.8),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        isActive ? Icons.verified_user_rounded : Icons.power_settings_new_rounded,
                        color: Colors.white,
                        size: 34,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        isActive ? 'ON-DUTY' : 'OFF-DUTY',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            decoration: BoxDecoration(
              color: isActive ? const Color(0xFFDCFCE7) : (isDark ? AppColors.retroDarkCard : Colors.white),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.retroDarkBorder, width: 1.4),
            ),
            child: Text(
              isActive ? 'RESPONDER ACTIVE & AVAILABLE' : 'RESPONDER CURRENTLY OFF-DUTY',
              style: TextStyle(
                color: isActive ? const Color(0xFF16A34A) : (isDark ? Colors.white60 : const Color(0xFF6B7280)),
                fontSize: 10,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.8,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- RETRO ACTION GRID ---
  Widget _buildActionGrid(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
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
              letterSpacing: 1.3,
              color: isDark ? Colors.white60 : const Color(0xFF6B7280),
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
            _buildRetroActionCard(context, 'GIS Mapping', 'Interactive pins & paths', Icons.map_rounded, AppColors.retroLilac, const Color(0xFF2563EB), const IncidentMappingScreen()),
            _buildRetroActionCard(context, 'Incident Monitor', 'Dispatches & queue', Icons.dvr_rounded, AppColors.retroPeach, const Color(0xFF4F46E5), const IncidentMonitoringScreen()),
            _buildRetroActionCard(context, 'Report Incident', 'Field log & pinning', Icons.add_location_alt_rounded, AppColors.retroLilac, const Color(0xFFE11D48), const ReportScreen()),
            _buildRetroActionCard(context, 'Hotspot Heatmap', 'High-risk clusters', Icons.whatshot_rounded, AppColors.retroPeach, const Color(0xFFEA580C), const HotspotIdentificationScreen()),
            _buildRetroActionCard(context, 'LGU Alerts', 'Priority advisories', Icons.notifications_active_rounded, AppColors.retroLilac, const Color(0xFFDB2777), const AlertsScreen()),
            _buildRetroActionCard(context, 'Task Status', 'Update checklist', Icons.checklist_rounded, AppColors.retroPeach, const Color(0xFF0D9488), const ResponderTasksScreen()),
          ],
        ),
      ],
    );
  }

  Widget _buildRetroActionCard(BuildContext context, String title, String subtitle, IconData icon, Color accentColor, Color iconColor, Widget screen) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => screen)),
      child: Container(
        padding: const EdgeInsets.all(16),
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
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF2C3240) : accentColor,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isDark ? Colors.white12 : AppColors.retroDarkBorder,
                  width: 1.4,
                ),
              ),
              child: Icon(icon, color: isDark ? Colors.white : iconColor, size: 22),
            ),
            const SizedBox(height: 8),
            Flexible(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: isDark ? Colors.white : AppColors.retroDarkBorder,
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: isDark ? Colors.white54 : const Color(0xFF6B7280),
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
