import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../core/constants.dart';
import 'report_screen.dart';
import '../models/incident_model.dart';
import 'alerts_screen.dart';
import 'incident_mapping_screen.dart';
import 'hotspot_identification_screen.dart';
import '../models/alert_model.dart';
import '../services/firestore_service.dart';
import 'package:intl/intl.dart';
import '../services/alert_notification_service.dart';

class CitizenDashboard extends StatefulWidget {
  const CitizenDashboard({super.key});

  @override
  State<CitizenDashboard> createState() => _CitizenDashboardState();
}

class _CitizenDashboardState extends State<CitizenDashboard> {
  int _lastAlertCount = 0;
  final Set<String> _notifiedIncidentIds = {};

  @override
  void initState() {
    super.initState();
    final firestore = Provider.of<FirestoreService>(context, listen: false);
    firestore.getAlertCount().first.then((count) {
      if (mounted) _lastAlertCount = count;
    });
  }

  void _triggerEmergencyFlash() {
    AlertNotificationService.instance.flashAlert();
  }

  @override
  Widget build(BuildContext context) {
    final firestoreService = Provider.of<FirestoreService>(context, listen: false);
    final userId = FirebaseAuth.instance.currentUser?.uid ?? '';

    return StreamProvider<int>(
      create: (_) => firestoreService.getAlertCount(),
      initialData: 0,
      builder: (context, child) {
        final alertCount = Provider.of<int>(context);

        // Flash screen if new alerts are published
        if (alertCount > _lastAlertCount) {
          _lastAlertCount = alertCount;
          WidgetsBinding.instance.addPostFrameCallback((_) => _triggerEmergencyFlash());
        }

        // Check for report status updates (e.g. dispatched)
        _checkForAcceptedReports(context, firestoreService, userId);

        return SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),
              _buildLguHeroCard(context),
              const SizedBox(height: 28),
              _buildActionGrid(context),
              const SizedBox(height: 32),
              _buildMyReports(context),
              const SizedBox(height: 32),
              _buildLiveUpdates(context),
              const SizedBox(height: 100),
            ],
          ),
        );
      },
    );
  }

  void _checkForAcceptedReports(BuildContext context, FirestoreService firestore, String userId) {
    firestore.getIncidents().listen((incidents) {
      if (!mounted) return;
      for (var inc in incidents) {
        if (inc.userId == userId && inc.status == 'dispatched' && !_notifiedIncidentIds.contains(inc.incidentId)) {
          _notifiedIncidentIds.add(inc.incidentId);
          _showReportAcceptedDialog(context, inc);
        }
      }
    });
  }

  void _showReportAcceptedDialog(BuildContext context, IncidentModel inc) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? AppConstants.surfaceDark : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        title: const Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green, size: 28),
            SizedBox(width: 12),
            Text('Report Accepted', style: TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Your incident report has been verified by LGU Catanduanes and emergency responders are dispatched to your pinned location.', 
              style: TextStyle(color: isDark ? Colors.white70 : Colors.black87)),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Row(
                children: [
                  Icon(Icons.timer_outlined, color: Colors.green),
                  SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('EST. RESPONSE TIME', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.green)),
                      Text('5 - 12 Minutes', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Colors.green)),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('UNDERSTOOD'),
          ),
        ],
      ),
    );
  }

  Widget _buildLguHeroCard(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final firestore = Provider.of<FirestoreService>(context, listen: false);

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [const Color(0xFF1E2841), const Color(0xFF161E31)]
              : [const Color(0xFFF0F4FF), const Color(0xFFE5EDFF)],
        ),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: isDark ? Colors.white10 : Colors.black.withOpacity(0.06)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.3 : 0.06),
            blurRadius: 20,
            offset: const Offset(0, 8),
          )
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
                  color: AppConstants.primaryRed.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'LGU CATANDUANES',
                  style: TextStyle(color: AppConstants.primaryRed, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1.2),
                ),
              ),
              Row(
                children: [
                  Container(
                    width: 7, height: 7,
                    decoration: const BoxDecoration(color: Colors.greenAccent, shape: BoxShape.circle),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'GIS LIVE',
                    style: TextStyle(color: isDark ? Colors.greenAccent : Colors.green[700], fontSize: 10, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            'Incident Mapping & Predictive Logic',
            style: TextStyle(
              color: isDark ? Colors.white : Colors.black87,
              fontSize: 22,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Centralized portal for incident reporting, geolocation pinning, and community risk monitoring.',
            style: TextStyle(
              color: isDark ? Colors.white60 : Colors.black54,
              fontSize: 12,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 20),
          Divider(color: isDark ? Colors.white10 : Colors.black12, height: 1),
          const SizedBox(height: 16),
          StreamBuilder<List<IncidentModel>>(
            stream: firestore.getIncidents(),
            builder: (context, snapshot) {
              final incidents = snapshot.data ?? [];
              final ongoing = incidents.where((i) => i.status != 'resolved' && i.status != 'closed').length;
              final resolved = incidents.where((i) => i.status == 'resolved').length;

              return Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildHeroStat('ACTIVE INCIDENTS', '$ongoing', Colors.orangeAccent, isDark),
                  Container(width: 1, height: 24, color: isDark ? Colors.white10 : Colors.black12),
                  _buildHeroStat('RESOLVED', '$resolved', Colors.greenAccent, isDark),
                  Container(width: 1, height: 24, color: isDark ? Colors.white10 : Colors.black12),
                  _buildHeroStat('COVERAGE', '11 LGUs', Colors.lightBlueAccent, isDark),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildHeroStat(String label, String value, Color color, bool isDark) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(color: color, fontSize: 18, fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(color: isDark ? Colors.white38 : Colors.black45, fontSize: 8, fontWeight: FontWeight.bold, letterSpacing: 0.6),
        ),
      ],
    );
  }

  Widget _buildActionGrid(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'GIS ACTION SERVICES',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.2,
            color: isDark ? Colors.white54 : Colors.black54,
          ),
        ),
        const SizedBox(height: 14),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          crossAxisSpacing: 14,
          mainAxisSpacing: 14,
          childAspectRatio: 1.15,
          children: [
            _buildActionCard(
              context,
              'Report Incident',
              'Pin & submit evidence',
              Icons.add_location_alt_rounded,
              AppConstants.primaryRed,
              const ReportScreen(),
            ),
            _buildActionCard(
              context,
              'Incident Map',
              'Live interactive GIS pins',
              Icons.map_rounded,
              const Color(0xFF1E88E5),
              const IncidentMappingScreen(),
            ),
            _buildActionCard(
              context,
              'Hotspot Heatmap',
              'High-risk hazard zones',
              Icons.whatshot_rounded,
              const Color(0xFFE65100),
              const HotspotIdentificationScreen(),
            ),
            _buildActionCard(
              context,
              'LGU Alerts',
              'Public emergency advisories',
              Icons.notifications_active_rounded,
              const Color(0xFF7B1FA2),
              const AlertsScreen(),
            ),
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
            const SizedBox(height: 8),
            Flexible(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title, 
                    style: TextStyle(color: isDark ? Colors.white : Colors.black87, fontSize: 15, fontWeight: FontWeight.bold),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle, 
                    style: TextStyle(color: isDark ? Colors.white54 : Colors.black54, fontSize: 11),
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

  Widget _buildMyReports(BuildContext context) {
    final firestoreService = Provider.of<FirestoreService>(context, listen: false);
    final userId = FirebaseAuth.instance.currentUser?.uid ?? '';
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'My Incident Reports',
              style: TextStyle(
                color: isDark ? Colors.white : Colors.black87,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            TextButton.icon(
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ReportScreen())),
              icon: const Icon(Icons.add, size: 16, color: AppConstants.primaryRed),
              label: const Text('New Report', style: TextStyle(color: AppConstants.primaryRed, fontSize: 12, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
        const SizedBox(height: 12),
        StreamBuilder<List<IncidentModel>>(
          stream: firestoreService.getIncidents(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) return const SizedBox.shrink();
            
            final myReports = snapshot.data!
                .where((i) => i.userId == userId)
                .toList();

            if (myReports.isEmpty) {
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
                  border: Border.all(color: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.05)),
                ),
                child: Column(
                  children: [
                    Icon(Icons.assignment_turned_in_outlined, color: isDark ? Colors.white24 : Colors.black26, size: 36),
                    const SizedBox(height: 8),
                    Text(
                      'No incident reports submitted yet.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: isDark ? Colors.white54 : Colors.black54, fontSize: 13),
                    ),
                  ],
                ),
              );
            }

            return Column(
              children: myReports.take(3).map((incident) => _buildMyReportItem(context, incident)).toList(),
            );
          },
        ),
      ],
    );
  }

  Widget _buildMyReportItem(BuildContext context, IncidentModel incident) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    Color statusColor = Colors.orange;
    String statusText = 'PENDING LGU REVIEW';

    if (incident.status == 'dispatched') {
      statusColor = Colors.blueAccent;
      statusText = 'RESPONDERS DISPATCHED';
    } else if (incident.status == 'resolved') {
      statusColor = Colors.greenAccent;
      statusText = 'RESOLVED & VERIFIED';
    }

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
        border: Border.all(color: statusColor.withOpacity(0.3)),
        boxShadow: isDark ? [const BoxShadow(color: Colors.black45, blurRadius: 10, offset: Offset(0, 4))] : [],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(
              incident.status == 'dispatched'
                  ? Icons.local_shipping_rounded
                  : (incident.status == 'resolved' ? Icons.check_circle_rounded : Icons.pending_actions_rounded),
              color: statusColor,
              size: 20,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  incident.description,
                  style: TextStyle(color: isDark ? Colors.white : Colors.black87, fontWeight: FontWeight.bold, fontSize: 14),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.pin_drop, size: 11, color: isDark ? Colors.white38 : Colors.black38),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        incident.location,
                        style: TextStyle(color: isDark ? Colors.white38 : Colors.black45, fontSize: 11),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  statusText,
                  style: TextStyle(color: statusColor, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 0.5),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Icon(Icons.chevron_right, color: isDark ? Colors.white24 : Colors.black26),
        ],
      ),
    );
  }

  Widget _buildLiveUpdates(BuildContext context) {
    final firestoreService = Provider.of<FirestoreService>(context, listen: false);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('LGU Advisories & Alerts', style: TextStyle(color: isDark ? Colors.white : Colors.black87, fontSize: 18, fontWeight: FontWeight.bold)),
            TextButton(
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AlertsScreen())), 
              child: const Text('View all', style: TextStyle(color: AppConstants.primaryRed, fontWeight: FontWeight.bold))
            ),
          ],
        ),
        const SizedBox(height: 12),
        StreamBuilder<List<AlertModel>>(
          stream: firestoreService.getAlerts(),
          builder: (context, snapshot) {
            if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  child: Text('No active advisories at this time.', style: TextStyle(color: isDark ? Colors.white38 : Colors.black38, fontSize: 14)),
                ),
              );
            }

            final alerts = snapshot.data!.take(3).toList();
            return Column(
              children: alerts.map((alert) => _buildAlertItem(context, alert)).toList(),
            );
          },
        ),
      ],
    );
  }

  Widget _buildAlertItem(BuildContext context, AlertModel alert) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
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
        border: Border.all(color: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.05)),
        boxShadow: isDark 
            ? [const BoxShadow(color: Colors.black26, blurRadius: 10, offset: Offset(0, 4))] 
            : [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: (alert.disasterType == 'Critical' ? AppConstants.primaryRed : Colors.orange).withOpacity(0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(
              alert.disasterType == 'Critical' ? Icons.warning_rounded : Icons.campaign_rounded,
              color: alert.disasterType == 'Critical' ? AppConstants.primaryRed : Colors.orange,
              size: 20,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(alert.title, style: TextStyle(color: isDark ? Colors.white : Colors.black87, fontWeight: FontWeight.bold, fontSize: 14)),
                const SizedBox(height: 2),
                Text(
                  alert.description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: isDark ? Colors.white60 : Colors.black54, fontSize: 12),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            DateFormat('h:mm a').format(alert.createdAt),
            style: TextStyle(color: isDark ? Colors.white30 : Colors.black38, fontSize: 10),
          ),
        ],
      ),
    );
  }
}
