import 'package:flutter/material.dart';
import '../core/constants.dart';
import 'report_screen.dart';
import 'alerts_screen.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/firestore_service.dart';
import '../models/user_model.dart';
import 'contacts_screen.dart';
import 'global_map_screen.dart';
import '../models/incident_model.dart';
import '../models/sos_model.dart';
import 'package:url_launcher/url_launcher.dart';
import 'hazard_gallery_screen.dart';

import 'package:intl/intl.dart';
import 'responder_tasks_screen.dart';
import 'dart:async';
import 'dart:convert';
import '../services/alert_notification_service.dart';
import '../models/sos_model.dart';

class ResponderDashboard extends StatefulWidget {
  const ResponderDashboard({super.key});

  @override
  State<ResponderDashboard> createState() => _ResponderDashboardState();
}

class _ResponderDashboardState extends State<ResponderDashboard> with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  Timer? _shiftTimer;
  String _shiftDuration = '0m';
  
  Stream<UserModel?>? _userStream;
  Stream<Map<String, dynamic>?>? _missionStream;
  Stream<int>? _incidentCountStream;
  Stream<int>? _alertCountStream;

  int _lastIncidentCount = -1;
  int _lastAlertCount = -1;
  int _lastSOSCount = -1;
  String? _lastMissionId;
  final Set<String> _notifiedSOSIds = {};

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

  void _showSOSAlertPopup(BuildContext context, SOSRequestModel sos) {
    if (!mounted) return;
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: AppConstants.primaryRed,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        contentPadding: EdgeInsets.zero,
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  const Icon(Icons.warning_rounded, color: Colors.white, size: 64),
                  const SizedBox(height: 16),
                  const Text(
                    'INCOMING SOS!',
                    style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900, letterSpacing: 2),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'A citizen requires immediate assistance.',
                    style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 14),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      children: [
                        const Icon(Icons.location_on, color: Colors.white70, size: 16),
                        const SizedBox(height: 4),
                        Text(
                          sos.location,
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            InkWell(
              onTap: () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(builder: (_) => const GlobalMapScreen()));
              },
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: const BorderRadius.vertical(bottom: Radius.circular(28)),
                ),
                child: const Center(
                  child: Text(
                    'OPEN MAP & RESPOND',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 1),
                  ),
                ),
              ),
            ),
          ],
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

  @override
  Widget build(BuildContext context) {
    final firestoreService = Provider.of<FirestoreService>(context, listen: false);
    final userId = FirebaseAuth.instance.currentUser?.uid ?? '';

    return MultiProvider(
      providers: [
        StreamProvider<UserModel?>(create: (_) => _userStream!, initialData: null),
        StreamProvider<Map<String, dynamic>?>(create: (_) => _missionStream!, initialData: null),
        StreamProvider<int>(create: (_) => _incidentCountStream!, initialData: 0),
        StreamProvider<int>(create: (_) => _alertCountStream!, initialData: 0),
        StreamProvider<List<SOSRequestModel>>(create: (_) => firestoreService.getSOSRequests(), initialData: const []),
      ],
      builder: (context, child) {
        final user = Provider.of<UserModel?>(context);
        final mission = Provider.of<Map<String, dynamic>?>(context);
        final incidentCount = Provider.of<int>(context);
        final alertCount = Provider.of<int>(context);
        final sosList = Provider.of<List<SOSRequestModel>>(context);

        // INITIALIZE ON FIRST LOAD (to avoid flashing when app opens)
        if (_lastAlertCount == -1) {
          _lastAlertCount = alertCount;
          _lastIncidentCount = incidentCount;
          _lastSOSCount = sosList.length;
          _lastMissionId = mission?['missionId'];
        }

        // CHECK FOR NEW MISSION
        if (mission != null && mission['missionId'] != _lastMissionId) {
          _lastMissionId = mission['missionId'];
          WidgetsBinding.instance.addPostFrameCallback((_) => AlertNotificationService.instance.flashAlert());
        }

        // CHECK FOR NEW INCIDENTS
        if (incidentCount > _lastIncidentCount) {
          _lastIncidentCount = incidentCount;
          WidgetsBinding.instance.addPostFrameCallback((_) => AlertNotificationService.instance.flashAlert());
        }

        // CHECK FOR NEW SOS (Responder should be VERY alert)
        if (sosList.length > _lastSOSCount) {
          final newSOS = sosList.firstWhere((s) => !_notifiedSOSIds.contains(s.sosId), orElse: () => sosList.first);
          _lastSOSCount = sosList.length;
          _notifiedSOSIds.add(newSOS.sosId);
          WidgetsBinding.instance.addPostFrameCallback((_) {
            AlertNotificationService.instance.flashAlert();
            _showSOSAlertPopup(context, newSOS);
          });
        }

        // CHECK FOR NEW COMMUNITY ALERTS
        if (alertCount > _lastAlertCount) {
          _lastAlertCount = alertCount;
          WidgetsBinding.instance.addPostFrameCallback((_) => AlertNotificationService.instance.flashAlert());
        }

        if (user == null) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }

        final isActive = user.isActive;
        _shiftDuration = _calculateShift(user.lastClockIn);

        return SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),
              _buildMissionCard(context, firestoreService, userId, _shiftDuration, mission),
              const SizedBox(height: 40),
              _buildStatusControl(context, firestoreService, userId, isActive, mission),
              const SizedBox(height: 40),
              _buildActionGrid(context),
              const SizedBox(height: 32),
              _buildActiveDispatches(context),
              const SizedBox(height: 32),
              _buildMissionLog(context),
              const SizedBox(height: 100),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMissionCard(BuildContext context, FirestoreService firestoreService, String userId, String shiftTime, Map<String, dynamic>? mission) {
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
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('MISSION STATUS', style: TextStyle(color: isDark ? Colors.white60 : Colors.black54, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1.5)),
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
                            return Container(
                              height: 180,
                              width: double.infinity,
                              color: isDark ? Colors.white10 : Colors.black12,
                              child: const Icon(Icons.image_not_supported, color: Colors.white24),
                            );
                          }
                          return Image.memory(
                            base64Decode(imgBase64),
                            height: 180,
                            width: double.infinity,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) => Container(
                              height: 180,
                              width: double.infinity,
                              color: isDark ? Colors.white10 : Colors.black12,
                              child: const Icon(Icons.broken_image, color: Colors.white24),
                            ),
                          );
                        } catch (e) {
                          return Container(
                            height: 180,
                            width: double.infinity,
                            color: isDark ? Colors.white10 : Colors.black12,
                            child: const Icon(Icons.broken_image, color: Colors.white24),
                          );
                        }
                      }
                    ),
                  ),
                ),
              if (!hasMission)
                Padding(
                  padding: const EdgeInsets.only(bottom: 24),
                  child: Center(child: _buildPulseRadar()),
                ),
              Text(
                hasMission ? mission['description'] ?? 'Mission' : 'Currently No Active Task',
                style: TextStyle(color: isDark ? Colors.white : Colors.black87, fontSize: 24, fontWeight: FontWeight.bold, letterSpacing: -0.5),
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
                        'Location sharing active with Command Center',
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
                            final latLng = _parseLocation(mission['location'] ?? '');
                            if (latLng != null) {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => GlobalMapScreen(initialLocation: latLng),
                                ),
                              );
                            }
                          },
                          icon: const Icon(Icons.navigation_rounded, size: 18),
                          label: const Text('NAVIGATE', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1)),
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
            ],
          ),
          const SizedBox(height: 32),
          Divider(color: isDark ? Colors.white12 : Colors.black12, height: 1),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              StreamBuilder<int>(
                stream: _incidentCountStream,
                builder: (context, snapshot) => _buildStatItem(context, 'REPORTS', snapshot.data?.toString() ?? '0', Icons.assignment_rounded),
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
              width: 180,
              height: 180,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: (isActive ? Colors.green : Colors.grey).withOpacity(0.05),
              ),
              child: Center(
                child: Container(
                  width: 140,
                  height: 140,
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
                        blurRadius: 40, 
                        spreadRadius: 5
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        isActive ? Icons.verified_user_rounded : Icons.power_settings_new_rounded, 
                        color: Colors.white, 
                        size: 40
                      ),
                      const SizedBox(height: 8),
                      Text(
                        isActive ? 'READY' : 'OFFLINE', 
                        style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w900, letterSpacing: 1)
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            decoration: BoxDecoration(
              color: isActive ? Colors.green.withOpacity(0.1) : (Theme.of(context).brightness == Brightness.dark ? Colors.white.withOpacity(0.03) : Colors.black.withOpacity(0.05)),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              isActive ? 'YOU ARE CURRENTLY ON-DUTY' : 'YOU ARE CURRENTLY OFF-DUTY',
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
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      childAspectRatio: 1.1,
      children: [
        _buildActionCard(context, 'Alerts', 'Priority dispatches', Icons.notifications_active, AppConstants.primaryRed, const AlertsScreen()),
        _buildActionCard(context, 'Report', 'Incident log', Icons.add_task, const Color(0xFF3949AB), const ReportScreen()),
        _buildActionCard(context, 'Hazards', 'Community dangers', Icons.warning_amber_rounded, Colors.orange, const HazardGalleryScreen()),
        _buildActionCard(context, 'Map', 'Navigation & zones', Icons.navigation, const Color(0xFF43A047), const GlobalMapScreen()),
        _buildActionCard(context, 'Contacts', 'Emergency ops', Icons.contact_phone, const Color(0xFF8E24AA), const ContactsScreen()),
        _buildActionCard(context, 'Status', 'Update task state', Icons.checklist_rounded, Colors.blueGrey, const ResponderTasksScreen()),
      ],
    );
  }


  Widget _buildActionCard(BuildContext context, String title, String subtitle, IconData icon, Color iconColor, Widget screen) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return InkWell(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => screen)),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: isDark ? const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF1E2841), Color(0xFF161E31)],
          ) : null,
          color: isDark ? null : Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.05)),
          boxShadow: isDark
              ? [const BoxShadow(color: Colors.black45, blurRadius: 10, offset: Offset(0, 4))]
              : [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.2),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(icon, color: iconColor, size: 28),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(color: isDark ? Colors.white : Colors.black87, fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text(subtitle, style: TextStyle(color: isDark ? Colors.white54 : Colors.black54, fontSize: 12)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActiveDispatches(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Active Dispatches', style: TextStyle(color: isDark ? Colors.white : Colors.black87, fontSize: 20, fontWeight: FontWeight.bold)),
            TextButton(
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ResponderTasksScreen())), 
              child: const Text('View all', style: TextStyle(color: AppConstants.primaryRed))
            ),
          ],
        ),
        const SizedBox(height: 16),
        InkWell(
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ResponderTasksScreen())),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: isDark ? const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF1E2841), Color(0xFF161E31)],
              ) : null,
              color: isDark ? null : Colors.white,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.05)),
              boxShadow: isDark
                  ? [const BoxShadow(color: Colors.black45, blurRadius: 10, offset: Offset(0, 4))]
                  : [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4))],
            ),
            child: Column(
              children: [
                const Icon(Icons.assignment_ind_outlined, color: AppConstants.primaryRed, size: 32),
                const SizedBox(height: 12),
                Text('Manage Tasks & SOS', style: TextStyle(color: isDark ? Colors.white : Colors.black87, fontWeight: FontWeight.bold)),
                Text('Tap to update resolved/pending status', style: TextStyle(color: isDark ? Colors.white30 : Colors.black38, fontSize: 12)),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPulseRadar() {
    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, child) {
        return SizedBox(
          width: 100,
          height: 100,
          child: Stack(
            alignment: Alignment.center,
            children: [
              ...List.generate(3, (index) {
                final val = (_pulseController.value + (index * 0.33)) % 1.0;
                return Container(
                  width: 100 * val,
                  height: 100 * val,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.greenAccent.withOpacity(1 - val), width: 2),
                  ),
                );
              }),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: const BoxDecoration(color: Colors.greenAccent, shape: BoxShape.circle),
                child: const Icon(Icons.radar_rounded, color: Colors.black, size: 24),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMissionLog(BuildContext context) {
    final firestoreService = Provider.of<FirestoreService>(context, listen: false);
    final userId = FirebaseAuth.instance.currentUser?.uid ?? '';
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Recently Resolved',
          style: TextStyle(
            color: isDark ? Colors.white : Colors.black87,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        StreamBuilder<List<IncidentModel>>(
          stream: firestoreService.getIncidents(),
          builder: (context, incidentSnapshot) {
            return StreamBuilder<List<SOSRequestModel>>(
              stream: firestoreService.getSOSRequests(),
              builder: (context, sosSnapshot) {
                if (!incidentSnapshot.hasData && !sosSnapshot.hasData) {
                  return const SizedBox(height: 100, child: Center(child: CircularProgressIndicator()));
                }

                final resolvedIncidents = (incidentSnapshot.data ?? [])
                    .where((i) => i.assignedTo == userId && i.status == 'resolved')
                    .map((i) => {
                          'title': i.description,
                          'time': i.timestamp,
                          'type': 'INCIDENT',
                        })
                    .toList();

                final resolvedSOS = (sosSnapshot.data ?? [])
                    .where((s) => s.assignedTo == userId && s.status == 'resolved')
                    .map((s) => {
                          'title': 'SOS EMERGENCY',
                          'time': s.timestamp,
                          'type': 'SOS',
                        })
                    .toList();

                final allResolved = [...resolvedIncidents, ...resolvedSOS]
                  ..sort((a, b) => (b['time'] as DateTime).compareTo(a['time'] as DateTime));

                final recentTasks = allResolved.take(5).toList();

                if (recentTasks.isEmpty) {
                  return Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      gradient: isDark ? const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Color(0xFF1E2841), Color(0xFF161E31)],
                      ) : null,
                      color: isDark ? null : Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                          color: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.05)),
                      boxShadow: isDark ? [const BoxShadow(color: Colors.black26, blurRadius: 10, offset: Offset(0, 4))] : [],
                    ),
                    child: Text(
                      'No resolved missions yet.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: isDark ? Colors.white30 : Colors.black38, fontSize: 13),
                    ),
                  );
                }

                return Column(
                  children: recentTasks.map((task) {
                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: isDark ? const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [Color(0xFF1E2841), Color(0xFF161E31)],
                        ) : null,
                        color: isDark ? null : Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                            color: isDark ? Colors.white.withOpacity(0.03) : Colors.black.withOpacity(0.05)),
                        boxShadow: isDark
                            ? [const BoxShadow(color: Colors.black26, blurRadius: 10, offset: Offset(0, 4))]
                            : [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4))],
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.green.withOpacity(0.1),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.check_circle_outline, color: Colors.green, size: 18),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  task['title'] as String,
                                  style: TextStyle(
                                    color: isDark ? Colors.white : Colors.black87,
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Text(
                                  DateFormat('MMM dd, hh:mm a').format(task['time'] as DateTime),
                                  style: TextStyle(
                                    color: isDark ? Colors.white38 : Colors.black38,
                                    fontSize: 10,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: (task['type'] == 'SOS' ? Colors.red : Colors.blue).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              task['type'] as String,
                              style: TextStyle(
                                color: task['type'] == 'SOS' ? Colors.red : Colors.blue,
                                fontSize: 8,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                );
              },
            );
          },
        ),
      ],
    );
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _StatItem(this.label, this.value, this.icon);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: Colors.white60, size: 18),
        const SizedBox(height: 8),
        Text(value, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
        Text(label, style: const TextStyle(color: Colors.white30, fontSize: 10)),
      ],
    );
  }
}
