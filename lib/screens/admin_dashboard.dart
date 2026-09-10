import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/constants.dart';
import '../services/firestore_service.dart';
import '../models/incident_model.dart';
import '../models/hazard_model.dart';
import '../models/map_location_model.dart';
import 'package:intl/intl.dart';
import 'admin_verification_screen.dart';
import 'alerts_screen.dart';
import '../models/alert_model.dart';
import 'incident_mapping_screen.dart';
import 'incident_monitoring_screen.dart';
import 'hotspot_identification_screen.dart';
import 'predictive_analysis_screen.dart';
import 'report_generation_screen.dart';
import 'safe_zone_map_screen.dart';
import 'report_screen.dart';
import 'incident_pinning_screen.dart';
import 'lgu_user_management_screen.dart';
import '../services/location_service.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  String _selectedCategory = 'All';

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 16),
          _buildSystemStatusCard(context),
          const SizedBox(height: 20),
          _buildIncidentKpiSummary(context),
          const SizedBox(height: 24),
          _buildBroadcastBanner(context),
          const SizedBox(height: 28),
          _buildActionGrid(context),
          const SizedBox(height: 28),
          _buildRetroCategoryDiscs(context),
          const SizedBox(height: 16),
          _buildRecentActivity(context),
          const SizedBox(height: 110),
        ],
      ),
    );
  }

  // --- RETRO PEACH COMMAND CENTER CARD ---
  Widget _buildSystemStatusCard(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final firestore = Provider.of<FirestoreService>(context);
    final locationService = Provider.of<LocationService>(context);
    final rawLoc = locationService.currentLocationName;
    final currentArea = (rawLoc.isNotEmpty && !rawLoc.toLowerCase().contains('disabled') && !rawLoc.toLowerCase().contains('standby') && !rawLoc.toLowerCase().contains('locating'))
        ? rawLoc.split(',')[0].trim().toUpperCase()
        : 'LOCAL';

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
                        'LGU COMMAND CENTER',
                        style: TextStyle(
                          color: isDark ? Colors.white70 : AppColors.retroDarkBorder,
                          fontSize: 9,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'GIS Operational',
                      style: TextStyle(
                        color: isDark ? Colors.white : AppColors.retroDarkBorder,
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Container(
                          width: 7,
                          height: 7,
                          decoration: const BoxDecoration(
                            color: Color(0xFF22C55E),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '$currentArea REAL-TIME LOGIC',
                          style: TextStyle(
                            color: isDark ? const Color(0xFF86EFAC) : const Color(0xFF15803D),
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.retroDarkCard : Colors.white,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isDark ? const Color(0xFF3E4556) : AppColors.retroDarkBorder,
                      width: 1.8,
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
                    child: Icon(
                      Icons.hub_rounded,
                      color: isDark ? Colors.white : AppColors.retroMintDark,
                      size: 28,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Divider(
              color: isDark ? Colors.white24 : AppColors.retroDarkBorder.withOpacity(0.2),
              height: 1,
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildStatItemStream(context, 'CITIZENS', firestore.getVerifiedCitizenCount(), Icons.people_alt_rounded),
                _buildStatItemStream(context, 'VERIFY QUEUE', firestore.getUnverifiedCitizenCount(), Icons.verified_user_rounded, isAlert: true),
                _buildStatItemStream(context, 'LGU ALERTS', firestore.getAlertCount(), Icons.campaign_rounded),
                _buildStatItemStream(context, 'HOTSPOTS', firestore.getMapLocationCount(), Icons.whatshot_rounded),
              ],
            ),
          ],
        ),
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
            ? const Color(0xFFEA580C)
            : (isDark ? Colors.white : AppColors.retroDarkBorder);

        return Column(
          children: [
            Stack(
              clipBehavior: Clip.none,
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
                    child: Icon(icon, color: color, size: 18),
                  ),
                ),
                if (isAlert && val > 0)
                  Positioned(
                    top: -2,
                    right: -2,
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: Color(0xFFEA580C),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              val.toString(),
              style: TextStyle(color: color, fontSize: 16, fontWeight: FontWeight.w900),
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
      },
    );
  }

  // --- RETRO BROADCAST BANNER ---
  Widget _buildBroadcastBanner(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: () => _showBroadcastDialog(context),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF351F22) : const Color(0xFFFEE2E2),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: isDark ? const Color(0xFF7F1D1D) : AppColors.retroDarkBorder,
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
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: const Color(0xFFEF4444),
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.retroDarkBorder, width: 1.6),
              ),
              child: const Center(
                child: Icon(Icons.campaign_rounded, color: Colors.white, size: 22),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'BROADCAST LGU ADVISORY',
                    style: TextStyle(
                      color: isDark ? Colors.white : AppColors.retroDarkBorder,
                      fontSize: 13,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.8,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Issue island-wide warning or emergency alert to citizens',
                    style: TextStyle(
                      color: isDark ? Colors.white60 : const Color(0xFF555B66),
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: isDark ? AppColors.retroDarkCard : Colors.white,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.retroDarkBorder, width: 1.4),
              ),
              child: Icon(
                Icons.arrow_forward_rounded,
                color: isDark ? Colors.white : AppColors.retroDarkBorder,
                size: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- RETRO INCIDENT KPI SUMMARY ---
  Widget _buildIncidentKpiSummary(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final firestore = Provider.of<FirestoreService>(context, listen: false);

    return StreamBuilder<List<IncidentModel>>(
      stream: firestore.getIncidents(),
      builder: (context, incSnap) {
        final incidents = incSnap.data ?? [];
        final totalIncidents = incidents.length;

        // Calculate distribution by type (Module 7: Incidents by Type)
        final typeCounts = <String, int>{
          'Fire': 0,
          'Flood': 0,
          'Crime': 0,
          'Accident': 0,
          'Other': 0,
        };

        for (var inc in incidents) {
          final desc = '${inc.description} ${inc.incidentType}'.toLowerCase();
          if (desc.contains('fire') || desc.contains('blaze') || desc.contains('burning')) {
            typeCounts['Fire'] = (typeCounts['Fire'] ?? 0) + 1;
          } else if (desc.contains('flood') || desc.contains('typhoon') || desc.contains('rain') || desc.contains('water')) {
            typeCounts['Flood'] = (typeCounts['Flood'] ?? 0) + 1;
          } else if (desc.contains('crime') || desc.contains('theft') || desc.contains('robbery') || desc.contains('assault')) {
            typeCounts['Crime'] = (typeCounts['Crime'] ?? 0) + 1;
          } else if (desc.contains('accident') || desc.contains('crash') || desc.contains('vehicular') || desc.contains('collision')) {
            typeCounts['Accident'] = (typeCounts['Accident'] ?? 0) + 1;
          } else {
            typeCounts['Other'] = (typeCounts['Other'] ?? 0) + 1;
          }
        }

        return StreamBuilder<List<HazardModel>>(
          stream: firestore.getHazards(),
          builder: (context, hazSnap) {
            final hazardCount = hazSnap.data?.length ?? 0;

            return StreamBuilder<List<MapLocationModel>>(
              stream: firestore.getMapLocations(),
              builder: (context, locSnap) {
                final locations = locSnap.data ?? [];
                final safeZoneCount = locations.where((l) => l.type == MapLocationType.safeZone || l.type == MapLocationType.medical).length;

                return StreamBuilder<List<AlertModel>>(
                  stream: firestore.getAlerts(),
                  builder: (context, alertSnap) {
                    final alertCount = alertSnap.data?.length ?? 0;

                    return Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.retroDarkCard : Colors.white,
                        borderRadius: BorderRadius.circular(24),
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
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(6),
                                    decoration: BoxDecoration(
                                      color: AppColors.retroLilac,
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(color: AppColors.retroDarkBorder, width: 1.2),
                                    ),
                                    child: const Icon(Icons.dashboard_rounded, color: AppColors.retroDarkBorder, size: 16),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    '07. DASHBOARD KPI SUMMARY',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: 1.1,
                                      color: isDark ? Colors.white : AppColors.retroDarkBorder,
                                    ),
                                  ),
                                ],
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFDCFCE7),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: AppColors.retroDarkBorder, width: 1.2),
                                ),
                                child: const Text(
                                  'GIS ACTIVE',
                                  style: TextStyle(
                                    color: Color(0xFF16A34A),
                                    fontSize: 9,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 18),

                          // GIS KPI Boxes: Incidents, Hazards, Safe Zones, Alerts
                          Row(
                            children: [
                              Expanded(
                                child: _buildRetroKpiBox(
                                  'INCIDENTS',
                                  '$totalIncidents',
                                  AppColors.retroLilac,
                                  isDark ? Colors.white : AppColors.retroDarkBorder,
                                  isDark,
                                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const IncidentMonitoringScreen())),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: _buildRetroKpiBox(
                                  'HAZARDS',
                                  '$hazardCount',
                                  AppColors.retroPeach,
                                  const Color(0xFFEA580C),
                                  isDark,
                                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const IncidentMappingScreen())),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: _buildRetroKpiBox(
                                  'SAFE ZONES',
                                  '$safeZoneCount',
                                  const Color(0xFFCCFBF1),
                                  const Color(0xFF0D9488),
                                  isDark,
                                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SafeZoneMapScreen())),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: _buildRetroKpiBox(
                                  'ALERTS',
                                  '$alertCount',
                                  const Color(0xFFFEE2E2),
                                  const Color(0xFFDC2626),
                                  isDark,
                                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AlertsScreen())),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          Divider(color: isDark ? Colors.white12 : AppColors.retroDarkBorder.withOpacity(0.15), height: 1),
                          const SizedBox(height: 16),

                          // Incidents by Type (Module 7)
                          Text(
                            'INCIDENTS BY TYPE',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1.2,
                              color: isDark ? Colors.white38 : const Color(0xFF6B7280),
                            ),
                          ),
                          const SizedBox(height: 12),
                          ...typeCounts.entries.map((entry) {
                            final count = entry.value;
                            final percentage = totalIncidents > 0 ? (count / totalIncidents) : 0.0;
                            final barColor = _getTypeColor(entry.key);

                            return Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: Column(
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        entry.key,
                                        style: TextStyle(
                                          color: isDark ? Colors.white70 : AppColors.retroDarkBorder,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                      Text(
                                        '$count (${(percentage * 100).toStringAsFixed(0)}%)',
                                        style: TextStyle(
                                          color: barColor,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w900,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(4),
                                    child: Stack(
                                      children: [
                                        Container(
                                          height: 6,
                                          width: double.infinity,
                                          color: isDark ? Colors.white10 : AppColors.retroDarkBorder.withOpacity(0.08),
                                        ),
                                        FractionallySizedBox(
                                          widthFactor: percentage,
                                          child: Container(
                                            height: 6,
                                            decoration: BoxDecoration(
                                              color: barColor,
                                              borderRadius: BorderRadius.circular(3),
                                            ),
                                          ),
                                        ),
                                      ],
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
              },
            );
          },
        );
      },
    );
  }

  Color _getTypeColor(String type) {
    switch (type) {
      case 'Fire':
        return const Color(0xFFEF4444);
      case 'Flood':
        return const Color(0xFF3B82F6);
      case 'Crime':
        return const Color(0xFF8B5CF6);
      case 'Accident':
        return const Color(0xFFF59E0B);
      default: // Other
        return const Color(0xFF10B981);
    }
  }

  Widget _buildRetroKpiBox(String label, String val, Color fill, Color textColor, bool isDark, {VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF262C38) : fill,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isDark ? const Color(0xFF3E4556) : AppColors.retroDarkBorder,
            width: 1.4,
          ),
        ),
        child: Column(
          children: [
            Text(
              val,
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: textColor),
            ),
            const SizedBox(height: 2),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 8,
                  fontWeight: FontWeight.w900,
                  color: isDark ? Colors.white54 : AppColors.retroDarkBorder,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- RETRO 10-MODULE ACTION GRID ---
  Widget _buildActionGrid(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
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
            _buildRetroActionCard(context, '01. Reporting', 'Incident submission', Icons.add_location_alt_rounded, AppColors.retroPeach, const Color(0xFFE11D48), const ReportScreen()),
            _buildRetroActionCard(context, '02. Mapping', 'Interactive GIS pins', Icons.map_rounded, AppColors.retroLilac, const Color(0xFF2563EB), const IncidentMappingScreen()),
            _buildRetroActionCard(context, '03. Pinning', 'Coordinate picker', Icons.pin_drop_rounded, AppColors.retroPeach, const Color(0xFF0891B2), const IncidentPinningScreen()),
            _buildRetroActionCard(context, '04. Monitoring', 'Live incident tracker', Icons.dvr_rounded, AppColors.retroLilac, const Color(0xFF4F46E5), const IncidentMonitoringScreen()),
            _buildRetroActionCard(context, '05. Hotspots', 'High-risk clusters', Icons.whatshot_rounded, AppColors.retroPeach, const Color(0xFFEA580C), const HotspotIdentificationScreen()),
            _buildRetroActionCard(context, '06. Predictive AI', '7-day logic & risk', Icons.auto_awesome_rounded, AppColors.retroLilac, const Color(0xFF7C3AED), const PredictiveAnalysisScreen()),
            _buildRetroActionCard(context, '08. Alerts', 'Broadcast advisory', Icons.notifications_active_rounded, AppColors.retroPeach, const Color(0xFFDB2777), const AlertsScreen()),
            _buildRetroActionCard(context, '09. Report Gen', 'Audit & KPI export', Icons.assessment_rounded, AppColors.retroLilac, const Color(0xFF059669), const ReportGenerationScreen()),
            _buildRetroActionCard(context, '10. User Mgmt', 'Citizens & Admin access', Icons.manage_accounts_rounded, AppColors.retroPeach, const Color(0xFF6D28D9), const LGUUserManagementScreen()),
            _buildRetroVerifyCard(context),
          ],
        ),
      ],
    );
  }

  Widget _buildRetroVerifyCard(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return StreamBuilder<int>(
      stream: Provider.of<FirestoreService>(context).getUnverifiedCitizenCount(),
      builder: (context, snapshot) {
        final pendingCount = snapshot.data ?? 0;
        return GestureDetector(
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminVerificationScreen())),
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
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.retroPeach,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppColors.retroDarkBorder, width: 1.4),
                      ),
                      child: const Icon(Icons.verified_user_rounded, color: Color(0xFFEA580C), size: 22),
                    ),
                    if (pendingCount > 0)
                      Positioned(
                        top: -4,
                        right: -4,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEA580C),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: AppColors.retroDarkBorder, width: 1.2),
                          ),
                          child: Text(
                            '$pendingCount',
                            style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w900),
                          ),
                        ),
                      ),
                  ],
                ),
                Flexible(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Verify Citizens',
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
                        pendingCount > 0 ? '$pendingCount pending' : 'All accounts verified',
                        style: TextStyle(
                          color: pendingCount > 0 ? const Color(0xFFEA580C) : (isDark ? Colors.white54 : const Color(0xFF6B7280)),
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
      },
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

  // --- RETRO CIRCULAR CATEGORY BADGES ---
  Widget _buildRetroCategoryDiscs(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final categories = [
      {'name': 'All', 'icon': Icons.apps_rounded, 'color': AppColors.retroMint},
      {'name': 'Fire', 'icon': Icons.local_fire_department_rounded, 'color': const Color(0xFFEF4444)},
      {'name': 'Flood', 'icon': Icons.water_drop_rounded, 'color': const Color(0xFF3B82F6)},
      {'name': 'Crime', 'icon': Icons.shield_rounded, 'color': const Color(0xFF8B5CF6)},
      {'name': 'Accident', 'icon': Icons.car_crash_rounded, 'color': const Color(0xFFF97316)},
      {'name': 'Hotspot', 'icon': Icons.whatshot_rounded, 'color': AppColors.retroMintDark},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'INCIDENT CATEGORIES',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.3,
                color: isDark ? Colors.white60 : const Color(0xFF6B7280),
              ),
            ),
            if (_selectedCategory != 'All')
              GestureDetector(
                onTap: () => setState(() => _selectedCategory = 'All'),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.retroPeach,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.retroDarkBorder, width: 1.2),
                  ),
                  child: const Text(
                    'Clear filter',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: AppColors.retroDarkBorder,
                    ),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 82,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: categories.length,
            separatorBuilder: (_, index) => const SizedBox(width: 14),
            itemBuilder: (context, index) {
              final cat = categories[index];
              final name = cat['name'] as String;
              final icon = cat['icon'] as IconData;
              final iconColor = cat['color'] as Color;
              final isSelected = _selectedCategory == name;

              return GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedCategory = name;
                  });
                  if (name == 'Hotspot') {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const HotspotIdentificationScreen()),
                    );
                  }
                },
                child: Column(
                  children: [
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppColors.retroMint
                            : (isDark ? AppColors.retroDarkCard : Colors.white),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isSelected
                              ? AppColors.retroDarkBorder
                              : (isDark ? const Color(0xFF3E4556) : AppColors.retroDarkBorder),
                          width: 1.8,
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
                        child: Icon(
                          icon,
                          color: isSelected
                              ? Colors.white
                              : (isDark ? Colors.white : iconColor),
                          size: 24,
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      name,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: isSelected ? FontWeight.w900 : FontWeight.w700,
                        color: isSelected
                            ? AppColors.retroMint
                            : (isDark ? Colors.white70 : AppColors.retroDarkBorder),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  // --- RETRO RECENT ACTIVITY ---
  Widget _buildRecentActivity(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              _selectedCategory == 'All' ? 'Recent Incidents' : '$_selectedCategory Incidents',
              style: TextStyle(
                color: isDark ? Colors.white : AppColors.retroDarkBorder,
                fontSize: 18,
                fontWeight: FontWeight.w900,
              ),
            ),
            TextButton(
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const IncidentMonitoringScreen())),
              child: Text(
                'Live Feed',
                style: TextStyle(
                  color: AppColors.retroMint,
                  fontWeight: FontWeight.w900,
                  fontSize: 13,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        StreamBuilder<List<IncidentModel>>(
          stream: Provider.of<FirestoreService>(context).getIncidents(),
          builder: (context, snapshot) {
            if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Text(
                    'No recent incidents recorded',
                    style: TextStyle(color: isDark ? Colors.white24 : Colors.black38, fontSize: 13),
                  ),
                ),
              );
            }
            final incidents = snapshot.data!
                .where((i) => i.status != 'resolved')
                .where((i) => _selectedCategory == 'All' || i.incidentType.toLowerCase() == _selectedCategory.toLowerCase())
                .take(5)
                .toList();

            if (incidents.isEmpty) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Text(
                    'No $_selectedCategory incidents recorded',
                    style: TextStyle(color: isDark ? Colors.white24 : Colors.black38, fontSize: 13),
                  ),
                ),
              );
            }

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
    final isDispatched = incident.status == 'dispatched';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.retroDarkCard : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? const Color(0xFF3E4556) : AppColors.retroDarkBorder,
          width: 1.6,
        ),
        boxShadow: [
          BoxShadow(
            color: isDark ? Colors.black38 : AppColors.retroDarkBorder.withOpacity(0.08),
            offset: const Offset(2, 2),
            blurRadius: 0,
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: isDispatched ? AppColors.retroLilac : AppColors.retroPeach,
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.retroDarkBorder, width: 1.4),
            ),
            child: Icon(
              isDispatched ? Icons.local_shipping_rounded : Icons.report_problem_rounded,
              color: isDispatched ? const Color(0xFF2563EB) : const Color(0xFFE11D48),
              size: 20,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  incident.description,
                  style: TextStyle(
                    color: isDark ? Colors.white : AppColors.retroDarkBorder,
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 3),
                Row(
                  children: [
                    Icon(Icons.location_on_rounded, color: isDark ? Colors.white38 : Colors.black45, size: 12),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        incident.location,
                        style: TextStyle(
                          color: isDark ? Colors.white38 : const Color(0xFF6B7280),
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                DateFormat('hh:mm a').format(incident.timestamp),
                style: TextStyle(
                  color: isDark ? Colors.white38 : const Color(0xFF888E99),
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: isDispatched ? AppColors.retroLilac : AppColors.retroPeach,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.retroDarkBorder, width: 1.2),
                ),
                child: Text(
                  isDispatched ? 'DISPATCHED' : 'PENDING',
                  style: TextStyle(
                    color: isDispatched ? const Color(0xFF2563EB) : const Color(0xFFD97706),
                    fontSize: 8,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.5,
                  ),
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
          backgroundColor: isDark ? AppColors.retroDarkCard : Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
            side: const BorderSide(color: AppColors.retroDarkBorder, width: 2),
          ),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.retroPeach,
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.retroDarkBorder, width: 1.4),
                      ),
                      child: const Icon(Icons.campaign_rounded, color: Color(0xFFEF4444), size: 22),
                    ),
                    const SizedBox(width: 14),
                    Text(
                      'LGU BROADCAST ALERT',
                      style: TextStyle(
                        color: isDark ? Colors.white : AppColors.retroDarkBorder,
                        fontWeight: FontWeight.w900,
                        fontSize: 17,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                _buildFieldLabel(context, 'ALERT TITLE'),
                _buildRetroDialogField(context, titleController, 'e.g. Typhoon Alert - Signal No. 2'),
                const SizedBox(height: 18),
                _buildFieldLabel(context, 'DETAILED INSTRUCTIONS'),
                _buildRetroDialogField(context, descriptionController, 'What should citizens do?', maxLines: 3),
                const SizedBox(height: 18),
                _buildFieldLabel(context, 'TYPE OF EMERGENCY'),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white.withOpacity(0.04) : const Color(0xFFF9FAFB),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isDark ? const Color(0xFF3E4556) : AppColors.retroDarkBorder,
                      width: 1.4,
                    ),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: selectedDisaster,
                      dropdownColor: isDark ? AppColors.retroDarkCard : Colors.white,
                      isExpanded: true,
                      style: TextStyle(
                        color: isDark ? Colors.white : AppColors.retroDarkBorder,
                        fontWeight: FontWeight.w700,
                      ),
                      items: ['General', 'Flood', 'Fire', 'Typhoon', 'Earthquake', 'Critical Advisory']
                          .map((e) => DropdownMenuItem(value: e, child: Text(e, style: TextStyle(color: isDark ? Colors.white : AppColors.retroDarkBorder))))
                          .toList(),
                      onChanged: (val) => setModalState(() => selectedDisaster = val!),
                    ),
                  ),
                ),
                const SizedBox(height: 28),
                GestureDetector(
                  onTap: () async {
                    if (titleController.text.isEmpty) return;
                    final alert = AlertModel(
                      alertId: DateTime.now().millisecondsSinceEpoch.toString(),
                      title: titleController.text,
                      description: descriptionController.text,
                      disasterType: selectedDisaster,
                      createdAt: DateTime.now(),
                    );
                    await Provider.of<FirestoreService>(context, listen: false).sendAlert(alert);
                    if (context.mounted) Navigator.pop(context);
                  },
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    decoration: BoxDecoration(
                      color: AppColors.retroMint,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.retroDarkBorder, width: 1.8),
                      boxShadow: const [
                        BoxShadow(
                          color: AppColors.retroDarkBorder,
                          offset: Offset(3, 3),
                          blurRadius: 0,
                        ),
                      ],
                    ),
                    child: const Center(
                      child: Text(
                        'INITIATE BROADCAST',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.2,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Center(
                  child: TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(
                      'CANCEL',
                      style: TextStyle(
                        color: isDark ? Colors.white54 : const Color(0xFF6B7280),
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
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
      padding: const EdgeInsets.only(left: 4, bottom: 6),
      child: Text(
        label,
        style: TextStyle(
          color: isDark ? Colors.white60 : const Color(0xFF4B5563),
          fontSize: 10,
          fontWeight: FontWeight.w900,
          letterSpacing: 1.1,
        ),
      ),
    );
  }

  Widget _buildRetroDialogField(BuildContext context, TextEditingController ctrl, String hint, {int maxLines = 1}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return TextField(
      controller: ctrl,
      maxLines: maxLines,
      style: TextStyle(color: isDark ? Colors.white : AppColors.retroDarkBorder, fontWeight: FontWeight.w700),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: isDark ? Colors.white24 : Colors.black26, fontSize: 13),
        filled: true,
        fillColor: isDark ? Colors.white.withOpacity(0.04) : const Color(0xFFF9FAFB),
        contentPadding: const EdgeInsets.all(16),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(
            color: isDark ? const Color(0xFF3E4556) : AppColors.retroDarkBorder,
            width: 1.4,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.retroMint, width: 2.0),
        ),
      ),
    );
  }
}
