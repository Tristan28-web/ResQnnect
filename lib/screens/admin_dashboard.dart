import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/constants.dart';
import '../services/firestore_service.dart';
import '../models/user_model.dart';
import '../models/incident_model.dart';
import 'package:intl/intl.dart';
import 'admin_verification_screen.dart';
import 'manage_responders_screen.dart';
import 'alerts_screen.dart';
import 'global_map_screen.dart';
import 'config_screen.dart';
import '../models/alert_model.dart';
import 'admin_incidents_screen.dart';
import 'admin_sos_screen.dart';
import 'safety_heatmap_screen.dart';
import '../models/safety_check_model.dart';
import 'incident_mapping_screen.dart';
import 'incident_monitoring_screen.dart';
import 'hotspot_identification_screen.dart';
import 'predictive_analysis_screen.dart';
import 'report_generation_screen.dart';
import 'lgu_user_management_screen.dart';
import 'report_screen.dart';

class AdminDashboard extends StatelessWidget {
  const AdminDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          const SizedBox(height: 20),
          _buildSystemStatusCard(context),
          const SizedBox(height: 24),
          _buildIncidentKpiSummary(context),
          const SizedBox(height: 36),
          _buildEmergencyControl(context),
          const SizedBox(height: 36),
          _buildActionGrid(context),
          const SizedBox(height: 32),
          _buildRecentActivity(context),
          const SizedBox(height: 100),
        ],
      ),
    );
  }

  Widget _buildSystemStatusCard(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
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
                  Text('COMMAND CENTER', style: TextStyle(color: isDark ? Colors.white38 : Colors.black54, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1.5)),
                  const SizedBox(height: 8),
                  Text('Operational', style: TextStyle(color: isDark ? Colors.white : Colors.black87, fontSize: 32, fontWeight: FontWeight.bold, letterSpacing: -1)),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.greenAccent.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 6, height: 6,
                          decoration: const BoxDecoration(color: Colors.greenAccent, shape: BoxShape.circle),
                        ),
                        const SizedBox(width: 8),
                        Text('LIVE MONITORING', style: TextStyle(color: isDark ? Colors.greenAccent : Colors.green[700], fontSize: 10, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: (isDark ? Colors.white : Colors.black).withOpacity(0.03),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.security_rounded, color: isDark ? Colors.white70 : Colors.black54, size: 40),
              ),
            ],
          ),
          const SizedBox(height: 32),
          Divider(color: isDark ? Colors.white12 : Colors.black12, height: 1),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildStatItemStream(context, 'RESPONDERS', Provider.of<FirestoreService>(context).getResponderCount(), Icons.people_rounded),
              _buildStatItemStream(context, 'PENDING', Provider.of<FirestoreService>(context).getUnverifiedCitizenCount(), Icons.verified_user_rounded, isAlert: true),
              _buildStatItemStream(context, 'ZONES', Provider.of<FirestoreService>(context).getMapLocationCount(), Icons.map_rounded),
              _buildStatItemStream(context, 'ACTIVE SOS', Provider.of<FirestoreService>(context).getSOSRequests().map((l) => l.length), Icons.emergency_rounded, isEmergency: true),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItemStream(BuildContext context, String label, Stream<int> stream, IconData icon, {bool isAlert = false, bool isEmergency = false}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return StreamBuilder<int>(
      stream: stream,
      builder: (context, snapshot) {
        final val = snapshot.data ?? 0;
        final color = isEmergency
            ? AppConstants.primaryRed
            : (isAlert && val > 0
                ? Colors.orangeAccent
                : (isDark ? Colors.white : Colors.black87));
        
        return Column(
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Icon(icon, color: color.withOpacity(0.5), size: 18),
                if (isAlert && val > 0)
                  Positioned(
                    top: -2, right: -2,
                    child: Container(width: 6, height: 6, decoration: const BoxDecoration(color: Colors.orangeAccent, shape: BoxShape.circle)),
                  ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              val.toString(),
              style: TextStyle(color: color, fontSize: 18, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 2),
            Text(label, style: TextStyle(color: isDark ? Colors.white24 : Colors.black54, fontSize: 8, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
          ],
        );
      },
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Text(label, style: const TextStyle(color: Colors.white30, fontSize: 10)),
        const SizedBox(height: 8),
        Icon(icon, color: Colors.white, size: 22),
        const SizedBox(height: 8),
        Text(value, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildEmergencyControl(BuildContext context) {
    return Column(
      children: [
        Center(
          child: InkWell(
            onTap: () => _showBroadcastDialog(context),
            borderRadius: BorderRadius.circular(100),
            child: Container(
              width: 180,
              height: 180,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppConstants.primaryRed.withOpacity(0.05),
              ),
              child: Center(
                child: InkWell(
                  onLongPress: () => _showTriggerCheckInDialog(context),
                  onTap: () => _showBroadcastDialog(context),
                  borderRadius: BorderRadius.circular(100),
                  child: Container(
                    width: 140,
                    height: 140,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const LinearGradient(
                        colors: [Color(0xFFD32F2F), Color(0xFFB71C1C)],
                      ),
                      boxShadow: [
                        BoxShadow(color: AppConstants.primaryRed.withOpacity(0.4), blurRadius: 40, spreadRadius: 5),
                      ],
                    ),
                    child: const Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.radar_rounded, color: Colors.white, size: 44),
                        Text('ALERT', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold, letterSpacing: 2)),
                        Text('TAP TO BROADCAST', style: TextStyle(color: Colors.white60, fontSize: 8, fontWeight: FontWeight.w900)),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 20),
        Text(
          'TAP TO BROADCAST | LONG PRESS TO TRIGGER CHECK-IN',
          textAlign: TextAlign.center,
          style: TextStyle(color: Theme.of(context).brightness == Brightness.dark ? Colors.white24 : Colors.black54, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1),
        ),
      ],
    );
  }

  Widget _buildIncidentKpiSummary(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final firestore = Provider.of<FirestoreService>(context, listen: false);

    return StreamBuilder<List<IncidentModel>>(
      stream: firestore.getIncidents(),
      builder: (context, snapshot) {
        final incidents = snapshot.data ?? [];
        final total = incidents.length;
        final ongoing = incidents.where((i) => i.status != 'resolved' && i.status != 'closed').length;
        final resolved = incidents.where((i) => i.status == 'resolved').length;
        final closed = incidents.where((i) => i.status == 'closed').length;

        return Container(
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E2841) : Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: isDark ? Colors.white10 : Colors.black.withOpacity(0.06)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(isDark ? 0.25 : 0.05),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.dashboard_rounded, color: AppConstants.primaryRed, size: 18),
                      const SizedBox(width: 8),
                      Text(
                        'LGU INCIDENT SUMMARY',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.2,
                          color: isDark ? Colors.white70 : Colors.black87,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.greenAccent.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Text('GIS ACTIVE', style: TextStyle(color: Colors.greenAccent, fontSize: 9, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
              const SizedBox(height: 18),

              // KPI Counters (Total, Ongoing, Resolved, Closed from Blueprint Module 7)
              Row(
                children: [
                  Expanded(child: _buildKpiBox('TOTAL', '$total', isDark ? Colors.white : Colors.black87, isDark)),
                  const SizedBox(width: 8),
                  Expanded(child: _buildKpiBox('ONGOING', '$ongoing', Colors.orangeAccent, isDark)),
                  const SizedBox(width: 8),
                  Expanded(child: _buildKpiBox('RESOLVED', '$resolved', Colors.greenAccent, isDark)),
                  const SizedBox(width: 8),
                  Expanded(child: _buildKpiBox('CLOSED', '$closed', Colors.blueGrey, isDark)),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildKpiBox(String label, String val, Color color, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
      decoration: BoxDecoration(
        color: (isDark ? const Color(0xFF161E31) : const Color(0xFFF5F7FB)),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          Text(
            val,
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: color),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(fontSize: 8, fontWeight: FontWeight.w900, color: isDark ? Colors.white38 : Colors.black45, letterSpacing: 0.5),
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
            'LGU GIS & PREDICTIVE LOGIC MODULES',
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
            _buildActionCard(context, 'Report Incident', 'GIS Pinning (1 & 3)', Icons.add_location_alt_rounded, AppConstants.primaryRed, const ReportScreen()),
            _buildActionCard(context, 'Incident Mapping', 'GIS Pins (2)', Icons.map_rounded, const Color(0xFF1E88E5), const IncidentMappingScreen()),
            _buildActionCard(context, 'Incident Monitor', 'LGU Feed (4)', Icons.dvr_rounded, const Color(0xFF3949AB), const IncidentMonitoringScreen()),
            _buildActionCard(context, 'Hotspot Heatmap', 'GIS Density (5)', Icons.whatshot_rounded, const Color(0xFFE65100), const HotspotIdentificationScreen()),
            _buildActionCard(context, 'Predictive AI', 'Trends & Risk (6)', Icons.auto_awesome_rounded, const Color(0xFF7B1FA2), const PredictiveAnalysisScreen()),
            _buildActionCard(context, 'Report Gen', 'Audit & KPIs (9)', Icons.assessment_rounded, const Color(0xFF00897B), const ReportGenerationScreen()),
            _buildActionCard(context, 'User Accounts', 'LGU RBAC (10)', Icons.admin_panel_settings_rounded, const Color(0xFF5E35B1), const LGUUserManagementScreen()),
            _buildActionCard(context, 'SOS Requests', 'Citizen SOS', Icons.emergency_share_rounded, AppConstants.primaryRed, const AdminSOSScreen()),
            _buildActionCard(context, 'Responders', 'Manage fleet', Icons.people_alt_rounded, const Color(0xFF43A047), const ManageRespondersScreen()),
            _buildVerifyCard(context),
            _buildActionCard(context, 'Safety Map', 'Check-in Heatmap', Icons.query_stats_rounded, Colors.greenAccent, const SafetyHeatmapScreen()),
            _buildActionCard(context, 'Config', 'System settings', Icons.settings_suggest_rounded, const Color(0xFF8E24AA), const ConfigScreen()),
          ],
        ),
      ],
    );
  }

  Widget _buildVerifyCard(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return StreamBuilder<int>(
      stream: Provider.of<FirestoreService>(context).getUnverifiedCitizenCount(),
      builder: (context, snapshot) {
        final pendingCount = snapshot.data ?? 0;
        return InkWell(
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminVerificationScreen())),
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
              border: Border.all(color: pendingCount > 0 ? Colors.orangeAccent.withOpacity(0.4) : (isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.05))),
              boxShadow: isDark
                  ? [const BoxShadow(color: Colors.black45, blurRadius: 10, offset: Offset(0, 4))]
                  : [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4))],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.orangeAccent.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Icon(Icons.verified_user_rounded, color: Colors.orangeAccent, size: 28),
                    ),
                    if (pendingCount > 0)
                      Positioned(
                        top: -4, right: -4,
                        child: Container(
                          padding: const EdgeInsets.all(5),
                          decoration: const BoxDecoration(color: Colors.orangeAccent, shape: BoxShape.circle),
                          child: Text('$pendingCount', style: const TextStyle(color: Colors.black, fontSize: 9, fontWeight: FontWeight.bold)),
                        ),
                      ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Verify Citizens', style: TextStyle(color: isDark ? Colors.white : Colors.black87, fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text(
                      pendingCount > 0 ? '$pendingCount pending' : 'All verified',
                      style: TextStyle(color: pendingCount > 0 ? Colors.orangeAccent : (isDark ? Colors.white54 : Colors.black54), fontSize: 12),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
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

  Widget _buildRecentActivity(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Recent Activity', style: TextStyle(color: isDark ? Colors.white : Colors.black87, fontSize: 20, fontWeight: FontWeight.bold)),
            TextButton(
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminIncidentsScreen())), 
              child: const Text('View all', style: TextStyle(color: AppConstants.primaryRed, fontWeight: FontWeight.bold))
            ),
          ],
        ),
        const SizedBox(height: 16),
        StreamBuilder<List<IncidentModel>>(
          stream: Provider.of<FirestoreService>(context).getIncidents(),
          builder: (context, snapshot) {
            if (!snapshot.hasData || snapshot.data!.isEmpty) {
               return Center(child: Text('No recent incidents', style: TextStyle(color: isDark ? Colors.white24 : Colors.black38, fontSize: 12)));
            }
            final incidents = snapshot.data!
              .where((i) => i.status != 'resolved')
              .take(3)
              .toList();
            return Column(
              children: incidents.map((i) => _buildIncidentActivityTile(context, i)).toList(),
            );
          },
        ),
      ],
    );
  }

  Widget _buildIncidentActivityTile(BuildContext context, IncidentModel incident) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: isDark ? const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1E2841), Color(0xFF161E31)],
        ) : null,
        color: isDark ? null : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: isDark ? Colors.white.withOpacity(0.03) : Colors.black.withOpacity(0.05)),
        boxShadow: isDark
            ? [const BoxShadow(color: Colors.black45, blurRadius: 8, offset: Offset(0, 3))]
            : [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppConstants.primaryRed.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(Icons.emergency_rounded, color: AppConstants.primaryRed, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(incident.description, style: TextStyle(color: isDark ? Colors.white : Colors.black87, fontSize: 15, fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.location_on, color: isDark ? Colors.white24 : Colors.black38, size: 12),
                    const SizedBox(width: 4),
                    Text(incident.location, style: TextStyle(color: isDark ? Colors.white38 : Colors.black54, fontSize: 11)),
                  ],
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                DateFormat('hh:mm a').format(incident.timestamp),
                style: TextStyle(color: isDark ? Colors.white38 : Colors.black54, fontSize: 10, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: (incident.status == 'dispatched' ? Colors.blue : Colors.orange).withOpacity(0.1), 
                  borderRadius: BorderRadius.circular(4)
                ),
                child: Text(
                  incident.status == 'dispatched' ? 'DISPATCHED' : 'PENDING', 
                  style: TextStyle(
                    color: incident.status == 'dispatched' ? Colors.blueAccent : Colors.orangeAccent, 
                    fontSize: 8, 
                    fontWeight: FontWeight.bold
                  )
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showBroadcastDialog(BuildContext context) {
    final titleController = TextEditingController();
    final descriptionController = TextEditingController();
    String selectedDisaster = 'General';
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Dialog(
          backgroundColor: isDark ? const Color(0xFF1E2841) : Colors.white,
          elevation: isDark ? 24 : 8,
          shadowColor: isDark ? Colors.black : Colors.black26,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(color: AppConstants.primaryRed.withOpacity(0.1), shape: BoxShape.circle),
                      child: const Icon(Icons.flash_on_rounded, color: AppConstants.primaryRed, size: 24),
                    ),
                    const SizedBox(width: 16),
                    Text('LEVEL 1 BROADCAST', style: TextStyle(color: isDark ? Colors.white : Colors.black87, fontWeight: FontWeight.w900, fontSize: 20, letterSpacing: -0.5)),
                  ],
                ),
                const SizedBox(height: 32),
                _buildFieldLabel(context, 'ALERT TITLE'),
                _buildGlassDialogField(context, titleController, 'e.g. Flood Warning - Brgy 1'),
                const SizedBox(height: 24),
                _buildFieldLabel(context, 'DETAILED INSTRUCTIONS'),
                _buildGlassDialogField(context, descriptionController, 'What should citizens do?', maxLines: 3),
                const SizedBox(height: 24),
                _buildFieldLabel(context, 'TYPE OF EMERGENCY'),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white.withOpacity(0.03) : Colors.black.withOpacity(0.03),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.05)),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: selectedDisaster,
                      dropdownColor: isDark ? AppConstants.surfaceDark : Colors.white,
                      isExpanded: true,
                      style: TextStyle(color: isDark ? Colors.white : Colors.black87, fontWeight: FontWeight.bold),
                      items: ['General', 'Flood', 'Fire', 'Typhoon', 'Earthquake', 'Critical Advisory']
                          .map((e) => DropdownMenuItem(value: e, child: Text(e, style: TextStyle(color: isDark ? Colors.white : Colors.black87))))
                          .toList(),
                      onChanged: (val) => setModalState(() => selectedDisaster = val!),
                    ),
                  ),
                ),
                const SizedBox(height: 48),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppConstants.primaryRed,
                    minimumSize: const Size(double.infinity, 56),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    elevation: 10,
                    shadowColor: AppConstants.primaryRed.withOpacity(0.4),
                  ),
                  onPressed: () async {
                    if (titleController.text.isEmpty) return;
                    final alert = AlertModel(
                      alertId: DateTime.now().millisecondsSinceEpoch.toString(),
                      title: titleController.text,
                      description: descriptionController.text,
                      disasterType: selectedDisaster,
                      createdAt: DateTime.now(),
                    );
                    await Provider.of<FirestoreService>(context, listen: false).sendAlert(alert);
                    Navigator.pop(context);
                  },
                  child: const Text('INITIATE BROADCAST', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1.5)),
                ),
                const SizedBox(height: 12),
                Center(
                  child: TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('CLOSE COMMAND', style: TextStyle(color: Colors.white24, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFieldLabel(BuildContext context, String label) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 10),
      child: Text(label, style: TextStyle(color: isDark ? Colors.white38 : Colors.black38, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1.5)),
    );
  }

  Widget _buildGlassDialogField(BuildContext context, TextEditingController ctrl, String hint, {int maxLines = 1}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return TextField(
      controller: ctrl,
      maxLines: maxLines,
      style: TextStyle(color: isDark ? Colors.white : Colors.black87, fontWeight: FontWeight.bold),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: isDark ? Colors.white12 : Colors.black12, fontSize: 14),
        filled: true,
        fillColor: isDark ? Colors.white.withOpacity(0.03) : Colors.black.withOpacity(0.03),
        contentPadding: const EdgeInsets.all(20),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.05))),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: AppConstants.primaryRed)),
      ),
    );
  }

  void _showTriggerCheckInDialog(BuildContext context) {
    final controller = TextEditingController(text: 'CITY-WIDE SAFETY CHECK-IN');
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF1E2841) : Colors.white,
        elevation: isDark ? 24 : 8,
        shadowColor: isDark ? Colors.black : Colors.black26,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text('Initiate Check-in', style: TextStyle(color: isDark ? Colors.white : Colors.black87, fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'This will send a high-priority popup to all citizens requesting their status.',
              style: TextStyle(color: isDark ? Colors.white54 : Colors.black54, fontSize: 13),
            ),
            const SizedBox(height: 16),
            _buildGlassDialogField(context, controller, 'Event Title'),
          ],
        ),
        actionsAlignment: MainAxisAlignment.end,
        actionsPadding: const EdgeInsets.only(right: 24, bottom: 20, left: 24),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx), 
            child: Text('CANCEL', style: TextStyle(color: isDark ? Colors.white54 : Colors.black54, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(width: 8),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              elevation: 0,
            ),
            onPressed: () async {
              await Provider.of<FirestoreService>(context, listen: false).triggerSafetyCheck(controller.text.trim());
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: const Text('LAUNCH PROTOCOL', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, letterSpacing: 0.5)),
          ),
        ],
      ),
    );
  }
}
