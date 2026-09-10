import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/constants.dart';
import '../services/firestore_service.dart';
import '../models/incident_model.dart';
import 'package:intl/intl.dart';
import 'admin_verification_screen.dart';
import 'alerts_screen.dart';
import '../models/alert_model.dart';
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 20),
          _buildSystemStatusCard(context),
          const SizedBox(height: 24),
          _buildIncidentKpiSummary(context),
          const SizedBox(height: 28),
          _buildBroadcastBanner(context),
          const SizedBox(height: 32),
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
    final firestore = Provider.of<FirestoreService>(context);

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [const Color(0xFF1E2841), const Color(0xFF161E31)]
              : [const Color(0xFFE8F0FE), const Color(0xFFF0F4FF)],
        ),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: isDark ? Colors.white10 : Colors.black.withOpacity(0.06)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.3 : 0.06),
            blurRadius: 20,
            offset: const Offset(0, 8),
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
                  Text(
                    'LGU COMMAND CENTER',
                    style: TextStyle(
                      color: isDark ? Colors.white38 : Colors.black54,
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.5,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'GIS Operational',
                    style: TextStyle(
                      color: isDark ? Colors.white : Colors.black87,
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.greenAccent.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 6, height: 6,
                          decoration: const BoxDecoration(color: Colors.greenAccent, shape: BoxShape.circle),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'CATANDUANES REAL-TIME LOGIC',
                          style: TextStyle(
                            color: isDark ? Colors.greenAccent : Colors.green[700],
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: (isDark ? Colors.white : Colors.black).withOpacity(0.04),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.hub_rounded, color: isDark ? Colors.white70 : Colors.black54, size: 36),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Divider(color: isDark ? Colors.white12 : Colors.black12, height: 1),
          const SizedBox(height: 18),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildStatItemStream(context, 'RESPONDERS', firestore.getResponderCount(), Icons.shield_rounded),
              _buildStatItemStream(context, 'VERIFY QUEUE', firestore.getUnverifiedCitizenCount(), Icons.verified_user_rounded, isAlert: true),
              _buildStatItemStream(context, 'LGU ALERTS', firestore.getAlertCount(), Icons.campaign_rounded),
              _buildStatItemStream(context, 'HOTSPOTS', firestore.getMapLocationCount(), Icons.whatshot_rounded),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItemStream(BuildContext context, String label, Stream<int> stream, IconData icon, {bool isAlert = false}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return StreamBuilder<int>(
      stream: stream,
      builder: (context, snapshot) {
        final val = snapshot.data ?? 0;
        final color = (isAlert && val > 0)
            ? Colors.orangeAccent
            : (isDark ? Colors.white : Colors.black87);
        
        return Column(
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Icon(icon, color: color.withOpacity(0.55), size: 18),
                if (isAlert && val > 0)
                  Positioned(
                    top: -2, right: -2,
                    child: Container(width: 6, height: 6, decoration: const BoxDecoration(color: Colors.orangeAccent, shape: BoxShape.circle)),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              val.toString(),
              style: TextStyle(color: color, fontSize: 18, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(color: isDark ? Colors.white24 : Colors.black45, fontSize: 8, fontWeight: FontWeight.bold, letterSpacing: 0.5),
            ),
          ],
        );
      },
    );
  }

  Widget _buildBroadcastBanner(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return InkWell(
      onTap: () => _showBroadcastDialog(context),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFB71C1C), Color(0xFFD32F2F)],
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: AppConstants.primaryRed.withOpacity(0.35),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.campaign_rounded, color: Colors.white, size: 24),
            ),
            const SizedBox(width: 16),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'BROADCAST LGU ADVISORY',
                    style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w900, letterSpacing: 1),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'Issue city-wide warning or emergency alert to citizens',
                    style: TextStyle(color: Colors.white70, fontSize: 11),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white70, size: 16),
          ],
        ),
      ),
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

        // Calculate distribution by type (Module 7: Incidents by Type)
        final typeCounts = <String, int>{
          'Flood': 0,
          'Fire': 0,
          'Crime': 0,
          'Accident': 0,
          'Other': 0,
        };

        for (var inc in incidents) {
          final desc = '${inc.description} ${inc.incidentType}'.toLowerCase();
          if (desc.contains('flood') || desc.contains('typhoon') || desc.contains('rain')) {
            typeCounts['Flood'] = (typeCounts['Flood'] ?? 0) + 1;
          } else if (desc.contains('fire')) {
            typeCounts['Fire'] = (typeCounts['Fire'] ?? 0) + 1;
          } else if (desc.contains('crime') || desc.contains('theft') || desc.contains('robbery') || desc.contains('assault')) {
            typeCounts['Crime'] = (typeCounts['Crime'] ?? 0) + 1;
          } else if (desc.contains('accident') || desc.contains('crash') || desc.contains('vehicular') || desc.contains('collision')) {
            typeCounts['Accident'] = (typeCounts['Accident'] ?? 0) + 1;
          } else {
            typeCounts['Other'] = (typeCounts['Other'] ?? 0) + 1;
          }
        }

        return Container(
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E2841) : Colors.white,
            borderRadius: BorderRadius.circular(26),
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
                        '07. DASHBOARD KPI & INCIDENT SUMMARY',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.1,
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

              // KPI Boxes: Total, Ongoing, Resolved, Closed
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
              const SizedBox(height: 20),
              Divider(color: isDark ? Colors.white10 : Colors.black12, height: 1),
              const SizedBox(height: 16),

              // Incidents by Type (Visual representation matching blueprint Module 7)
              Text(
                'INCIDENTS BY TYPE',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1,
                  color: isDark ? Colors.white38 : Colors.black45,
                ),
              ),
              const SizedBox(height: 12),
              ...typeCounts.entries.map((entry) {
                final count = entry.value;
                final percentage = total > 0 ? (count / total) : 0.0;
                final barColor = _getTypeColor(entry.key);

                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(entry.key, style: TextStyle(color: isDark ? Colors.white70 : Colors.black87, fontSize: 11, fontWeight: FontWeight.bold)),
                          Text('$count (${(percentage * 100).toStringAsFixed(0)}%)', style: TextStyle(color: barColor, fontSize: 11, fontWeight: FontWeight.w900)),
                        ],
                      ),
                      const SizedBox(height: 4),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: percentage,
                          minHeight: 6,
                          backgroundColor: isDark ? Colors.white.withOpacity(0.06) : Colors.black.withOpacity(0.06),
                          valueColor: AlwaysStoppedAnimation<Color>(barColor),
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ],
          ),
        );
      },
    );
  }

  Color _getTypeColor(String type) {
    switch (type) {
      case 'Flood':
        return Colors.blueAccent;
      case 'Fire':
        return Colors.deepOrangeAccent;
      case 'Crime':
        return Colors.purpleAccent;
      case 'Accident':
        return Colors.amber;
      default:
        return Colors.tealAccent;
    }
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
            _buildActionCard(context, '01. Reporting', 'Evidence submission', Icons.add_location_alt_rounded, AppConstants.primaryRed, const ReportScreen()),
            _buildActionCard(context, '02. Mapping', 'Interactive GIS pins', Icons.map_rounded, const Color(0xFF1E88E5), const IncidentMappingScreen()),
            _buildActionCard(context, '03. Pinning', 'Coordinate picker', Icons.pin_drop_rounded, const Color(0xFF00ACC1), const ReportScreen()),
            _buildActionCard(context, '04. Monitoring', 'Live incident tracker', Icons.dvr_rounded, const Color(0xFF3949AB), const IncidentMonitoringScreen()),
            _buildActionCard(context, '05. Hotspots', 'High-risk clusters', Icons.whatshot_rounded, const Color(0xFFE65100), const HotspotIdentificationScreen()),
            _buildActionCard(context, '06. Predictive AI', '7-day logic & risk', Icons.auto_awesome_rounded, const Color(0xFF7B1FA2), const PredictiveAnalysisScreen()),
            _buildActionCard(context, '08. Alerts', 'Broadcast advisory', Icons.notifications_active_rounded, const Color(0xFFD81B60), const AlertsScreen()),
            _buildActionCard(context, '09. Report Gen', 'Audit & KPI export', Icons.assessment_rounded, const Color(0xFF00897B), const ReportGenerationScreen()),
            _buildActionCard(context, '10. Users', 'LGU roles & access', Icons.admin_panel_settings_rounded, const Color(0xFF5E35B1), const LGUUserManagementScreen()),
            _buildVerifyCard(context),
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
              border: Border.all(color: pendingCount > 0 ? Colors.orangeAccent.withOpacity(0.4) : (isDark ? Colors.white.withOpacity(0.06) : Colors.black.withOpacity(0.06))),
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
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.orangeAccent.withOpacity(0.18),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Icon(Icons.verified_user_rounded, color: Colors.orangeAccent, size: 24),
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
                    Text('Verify Citizens', style: TextStyle(color: isDark ? Colors.white : Colors.black87, fontSize: 15, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 2),
                    Text(
                      pendingCount > 0 ? '$pendingCount pending verification' : 'All accounts verified',
                      style: TextStyle(color: pendingCount > 0 ? Colors.orangeAccent : (isDark ? Colors.white54 : Colors.black54), fontSize: 11),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
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

  Widget _buildRecentActivity(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Recent Incidents', style: TextStyle(color: isDark ? Colors.white : Colors.black87, fontSize: 18, fontWeight: FontWeight.bold)),
            TextButton(
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const IncidentMonitoringScreen())), 
              child: const Text('Live Feed', style: TextStyle(color: AppConstants.primaryRed, fontWeight: FontWeight.bold))
            ),
          ],
        ),
        const SizedBox(height: 12),
        StreamBuilder<List<IncidentModel>>(
          stream: Provider.of<FirestoreService>(context).getIncidents(),
          builder: (context, snapshot) {
            if (!snapshot.hasData || snapshot.data!.isEmpty) {
               return Center(child: Text('No recent incidents recorded', style: TextStyle(color: isDark ? Colors.white24 : Colors.black38, fontSize: 12)));
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
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: isDark ? const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1E2841), Color(0xFF161E31)],
        ) : null,
        color: isDark ? null : Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: isDark ? Colors.white.withOpacity(0.04) : Colors.black.withOpacity(0.05)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.25 : 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppConstants.primaryRed.withOpacity(0.12),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(Icons.report_problem_rounded, color: AppConstants.primaryRed, size: 22),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  incident.description,
                  style: TextStyle(color: isDark ? Colors.white : Colors.black87, fontSize: 14, fontWeight: FontWeight.bold),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.location_on, color: isDark ? Colors.white24 : Colors.black38, size: 12),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        incident.location,
                        style: TextStyle(color: isDark ? Colors.white38 : Colors.black54, fontSize: 11),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
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
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                decoration: BoxDecoration(
                  color: (incident.status == 'dispatched' ? Colors.blue : Colors.orange).withOpacity(0.12), 
                  borderRadius: BorderRadius.circular(6)
                ),
                child: Text(
                  incident.status == 'dispatched' ? 'DISPATCHED' : 'PENDING', 
                  style: TextStyle(
                    color: incident.status == 'dispatched' ? Colors.blueAccent : Colors.orangeAccent, 
                    fontSize: 8, 
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.5,
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
                      child: const Icon(Icons.campaign_rounded, color: AppConstants.primaryRed, size: 24),
                    ),
                    const SizedBox(width: 16),
                    Text(
                      'LGU BROADCAST ALERT',
                      style: TextStyle(color: isDark ? Colors.white : Colors.black87, fontWeight: FontWeight.w900, fontSize: 18, letterSpacing: -0.5),
                    ),
                  ],
                ),
                const SizedBox(height: 28),
                _buildFieldLabel(context, 'ALERT TITLE'),
                _buildGlassDialogField(context, titleController, 'e.g. Typhoon Alert - Signal No. 2'),
                const SizedBox(height: 20),
                _buildFieldLabel(context, 'DETAILED INSTRUCTIONS'),
                _buildGlassDialogField(context, descriptionController, 'What should citizens do?', maxLines: 3),
                const SizedBox(height: 20),
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
                const SizedBox(height: 36),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppConstants.primaryRed,
                    minimumSize: const Size(double.infinity, 54),
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
                  child: const Text('INITIATE BROADCAST', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1.2)),
                ),
                const SizedBox(height: 12),
                Center(
                  child: TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text('CANCEL', style: TextStyle(color: isDark ? Colors.white38 : Colors.black38, fontSize: 11, fontWeight: FontWeight.bold)),
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
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(label, style: TextStyle(color: isDark ? Colors.white38 : Colors.black38, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1.2)),
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
        hintStyle: TextStyle(color: isDark ? Colors.white24 : Colors.black26, fontSize: 13),
        filled: true,
        fillColor: isDark ? Colors.white.withOpacity(0.03) : Colors.black.withOpacity(0.03),
        contentPadding: const EdgeInsets.all(18),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.05))),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: AppConstants.primaryRed)),
      ),
    );
  }
}
