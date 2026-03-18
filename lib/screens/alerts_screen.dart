import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/firestore_service.dart';
import '../models/alert_model.dart';
import '../widgets/alert_card.dart';
import '../core/constants.dart';


class AlertsScreen extends StatefulWidget {
  const AlertsScreen({super.key});

  @override
  State<AlertsScreen> createState() => _AlertsScreenState();
}

class _AlertsScreenState extends State<AlertsScreen> {
  Set<String> _seenAlertIds = {};

  @override
  void initState() {
    super.initState();
    _loadSeenAlerts();
  }

  Future<void> _loadSeenAlerts() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _seenAlertIds = (prefs.getStringList('seen_alerts') ?? []).toSet();
    });
  }

  Future<void> _markAsSeen(List<AlertModel> alerts) async {
    final prefs = await SharedPreferences.getInstance();
    final allIds = alerts.map((a) => a.alertId).toList();
    await prefs.setStringList('seen_alerts', allIds);
  }

  String _getTimeGroup(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final itemDate = DateTime(date.year, date.month, date.day);

    if (itemDate == today) return 'TODAY';
    if (itemDate == yesterday) return 'YESTERDAY';
    return 'EARLIER THIS WEEK';
  }

  @override
  Widget build(BuildContext context) {
    final firestoreService = Provider.of<FirestoreService>(context, listen: false);

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text('DISASTER BROADCASTS', style: TextStyle(color: isDark ? Colors.white : Colors.black87, fontSize: 13, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
        centerTitle: true,
        iconTheme: IconThemeData(color: isDark ? Colors.white : Colors.black87),
      ),
      body: FutureBuilder<SharedPreferences>(
        future: SharedPreferences.getInstance(),
        builder: (context, prefSnapshot) {
          if (prefSnapshot.connectionState == ConnectionState.waiting) {
             return const Center(child: CircularProgressIndicator(color: AppConstants.primaryRed));
          }
          final isNotifsEnabled = prefSnapshot.data?.getBool('config_push_notif') ?? true;

          return StreamBuilder<List<AlertModel>>(
            stream: firestoreService.getAlerts(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
    
              final alerts = snapshot.data ?? [];
              if (alerts.isEmpty) {
                return _buildEmptyState(context);
              }

              // Grouping logic
              Map<String, List<AlertModel>> grouped = {};
              for (var alert in alerts) {
                final group = _getTimeGroup(alert.createdAt);
                grouped.putIfAbsent(group, () => []).add(alert);
              }

              // Track seen alerts after build
              WidgetsBinding.instance.addPostFrameCallback((_) => _markAsSeen(alerts));

              return Column(
                children: [
                  if (!isNotifsEnabled) _buildNotifWarning(),
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                      children: grouped.entries.map((entry) {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(left: 8, bottom: 16, top: 10),
                              child: Text(
                                entry.key,
                                style: TextStyle(
                                  color: isDark ? Colors.white24 : Colors.black38,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 2,
                                ),
                              ),
                            ),
                            ...entry.value.map((alert) => AlertCard(
                              alert: alert,
                              isUnread: !_seenAlertIds.contains(alert.alertId),
                            )),
                          ],
                        );
                      }).toList(),
                    ),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.notifications_off_outlined, size: 80, color: (isDark ? Colors.white : Colors.black).withOpacity(0.05)),
          const SizedBox(height: 24),
          Text('No Broadcasts Found', style: TextStyle(color: isDark ? Colors.white54 : Colors.black54, fontWeight: FontWeight.bold)),
          Text('Stay tuned for official updates', style: TextStyle(color: isDark ? Colors.white24 : Colors.black38, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildNotifWarning() {
    return Container(
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E2841),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.orange.withOpacity(0.2)),
        boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 10, offset: Offset(0, 4))],
      ),
      child: Row(
        children: [
          const Icon(Icons.notifications_off_rounded, color: Colors.orangeAccent, size: 20),
          const SizedBox(width: 16),
          const Expanded(
            child: Text(
              'Notifications are currently disabled in settings. You might miss critical updates.',
              style: TextStyle(color: Colors.orangeAccent, fontSize: 11, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}

