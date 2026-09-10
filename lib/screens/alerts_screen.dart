import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/firestore_service.dart';
import '../services/location_service.dart';
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
      backgroundColor: isDark ? AppColors.backgroundBlack : AppColors.retroCream,
      appBar: AppBar(
        title: Text(
          'DISASTER BROADCASTS',
          style: TextStyle(
            color: isDark ? Colors.white : AppColors.retroDarkBorder,
            fontSize: 14,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.2,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: isDark ? Colors.white : AppColors.retroDarkBorder),
      ),
      body: FutureBuilder<SharedPreferences>(
        future: SharedPreferences.getInstance(),
        builder: (context, prefSnapshot) {
          if (prefSnapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: AppColors.retroMint));
          }
          final isNotifsEnabled = prefSnapshot.data?.getBool('config_push_notif') ?? true;

          return StreamBuilder<List<AlertModel>>(
            stream: firestoreService.getAlerts(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator(color: AppColors.retroMint));
              }

              final alerts = snapshot.data ?? [];

              // Grouping logic
              Map<String, List<AlertModel>> grouped = {};
              for (var alert in alerts) {
                final group = _getTimeGroup(alert.createdAt);
                grouped.putIfAbsent(group, () => []).add(alert);
              }

              if (alerts.isNotEmpty) {
                WidgetsBinding.instance.addPostFrameCallback((_) => _markAsSeen(alerts));
              }

              return SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Retro Broadcast Hero Card
                    _buildHeroBroadcastCard(isDark, alerts.length),
                    const SizedBox(height: 16),

                    if (!isNotifsEnabled) ...[
                      _buildNotifWarning(isDark),
                      const SizedBox(height: 16),
                    ],

                    if (alerts.isEmpty)
                      _buildEmptyState(context, isDark)
                    else
                      ...grouped.entries.map((entry) {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(left: 4, bottom: 12, top: 8),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: isDark ? const Color(0xFF262C38) : AppColors.retroLilac,
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: isDark ? const Color(0xFF3E4556) : AppColors.retroDarkBorder,
                                    width: 1.2,
                                  ),
                                ),
                                child: Text(
                                  entry.key,
                                  style: TextStyle(
                                    color: isDark ? Colors.white70 : AppColors.retroDarkBorder,
                                    fontSize: 9,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 1.0,
                                  ),
                                ),
                              ),
                            ),
                            ...entry.value.map((alert) => AlertCard(
                                  alert: alert,
                                  isUnread: !_seenAlertIds.contains(alert.alertId),
                                )),
                          ],
                        );
                      }),
                    const SizedBox(height: 100),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  // --- RETRO BROADCAST HERO CARD ---
  Widget _buildHeroBroadcastCard(bool isDark, int alertCount) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2B2421) : AppColors.retroPeach,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDark ? const Color(0xFF4A3C38) : AppColors.retroDarkBorder,
          width: 2.0,
        ),
        boxShadow: [
          BoxShadow(
            color: isDark ? Colors.black54 : AppColors.retroMintDark,
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
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: AppColors.retroMint,
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.retroDarkBorder, width: 1.5),
                    ),
                    child: const Center(
                      child: Icon(Icons.campaign_rounded, size: 20, color: Colors.white),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'PDRRMO BROADCAST',
                        style: TextStyle(
                          color: isDark ? Colors.white : AppColors.retroDarkBorder,
                          fontSize: 13,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      Text(
                        'Official Public Warning System',
                        style: TextStyle(
                          color: isDark ? Colors.white60 : const Color(0xFF6B7280),
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: alertCount > 0 ? const Color(0xFFFEE2E2) : const Color(0xFFDCFCE7),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.retroDarkBorder, width: 1.2),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: alertCount > 0 ? const Color(0xFFDC2626) : const Color(0xFF16A34A),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      alertCount > 0 ? '$alertCount ACTIVE' : 'LIVE 24/7',
                      style: TextStyle(
                        color: alertCount > 0 ? const Color(0xFFDC2626) : const Color(0xFF16A34A),
                        fontSize: 9,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Emergency bulletins, typhoon tracks, and municipal evacuation orders transmitted in real time by the Provincial Disaster Command.',
            style: TextStyle(
              color: isDark ? Colors.white70 : const Color(0xFF4B5563),
              fontSize: 12,
              fontWeight: FontWeight.w600,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  // --- RETRO EMPTY STATE ---
  Widget _buildEmptyState(BuildContext context, bool isDark) {
    final locationService = Provider.of<LocationService>(context);
    final rawLoc = locationService.currentLocationName;
    final currentArea = (rawLoc.isNotEmpty && !rawLoc.startsWith('GPS') && !rawLoc.startsWith('Locating'))
        ? rawLoc.split(',')[0].trim().toUpperCase()
        : 'CURRENT AREA';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 24),
      decoration: BoxDecoration(
        color: isDark ? AppColors.retroDarkCard : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDark ? const Color(0xFF3E4556) : AppColors.retroDarkBorder,
          width: 1.8,
        ),
        boxShadow: [
          BoxShadow(
            color: isDark ? Colors.black45 : AppColors.retroDarkBorder.withOpacity(0.08),
            offset: const Offset(3, 3),
            blurRadius: 0,
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF262C38) : AppColors.retroMintLight,
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.retroDarkBorder, width: 1.8),
            ),
            child: const Center(
              child: Icon(Icons.notifications_active_rounded, size: 34, color: AppColors.retroMintDark),
            ),
          ),
          const SizedBox(height: 18),
          Text(
            'ALL CLEAR IN $currentArea',
            style: TextStyle(
              color: isDark ? Colors.white : AppColors.retroDarkBorder,
              fontWeight: FontWeight.w900,
              fontSize: 15,
              letterSpacing: 0.4,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'No emergency bulletins or disaster alerts currently issued. Emergency command units are continuously monitoring area telemetry.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isDark ? Colors.white60 : const Color(0xFF6B7280),
              fontSize: 12,
              height: 1.45,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 18),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFFDCFCE7),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.retroDarkBorder, width: 1.2),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.shield_rounded, size: 14, color: Color(0xFF16A34A)),
                SizedBox(width: 6),
                Text(
                  'CIVIL DEFENSE READY',
                  style: TextStyle(
                    color: Color(0xFF16A34A),
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- RETRO NOTIF WARNING ---
  Widget _buildNotifWarning(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF3B2E1E) : AppColors.retroYellow,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.retroDarkBorder, width: 1.6),
        boxShadow: [
          BoxShadow(
            color: isDark ? Colors.black38 : AppColors.retroDarkBorder.withOpacity(0.1),
            offset: const Offset(2, 2),
            blurRadius: 0,
          ),
        ],
      ),
      child: const Row(
        children: [
          Icon(Icons.notifications_off_rounded, color: Color(0xFFD97706), size: 20),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              'Push notifications are currently disabled. Enable them in settings to receive high-priority provincial warnings.',
              style: TextStyle(
                color: Color(0xFF92400E),
                fontSize: 11,
                fontWeight: FontWeight.w800,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
