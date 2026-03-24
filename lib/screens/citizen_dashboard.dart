import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/sos_model.dart';
import '../core/constants.dart';
import 'sos_screen.dart';
import 'report_screen.dart';
import '../models/incident_model.dart';
import 'alerts_screen.dart';
import 'weather_screen.dart';
import 'firstaid_screen.dart';
import 'contacts_screen.dart';
import 'global_map_screen.dart';
import '../models/alert_model.dart';
import '../services/firestore_service.dart';
import '../services/weather_service.dart';
import '../models/weather_model.dart';
import '../services/location_service.dart';
import 'package:intl/intl.dart';
import 'dart:convert';
import '../widgets/sos_hold_button.dart';
import '../models/safety_check_model.dart';
import '../models/hazard_model.dart';
import 'offline_vault_screen.dart';
import 'hazard_gallery_screen.dart';
import 'report_hazard_screen.dart';
import '../services/alert_notification_service.dart';

class CitizenDashboard extends StatefulWidget {
  const CitizenDashboard({super.key});

  @override
  State<CitizenDashboard> createState() => _CitizenDashboardState();
}

class _CitizenDashboardState extends State<CitizenDashboard> {
  String? _lastSafetyEventId;
  int _lastSOSCount = 0;
  int _lastAlertCount = 0;
  final Set<String> _notifiedIncidentIds = {};

  @override
  void initState() {
    super.initState();
    // Initialize counts
    final firestore = Provider.of<FirestoreService>(context, listen: false);
    
    firestore.getAlertCount().first.then((count) {
      if (mounted) _lastAlertCount = count;
    });

    firestore.getSOSRequests().first.then((sos) {
      if (mounted) _lastSOSCount = sos.length;
    });
  }

  void _triggerEmergencyFlash() {
    AlertNotificationService.instance.flashAlert();
  }

  @override
  Widget build(BuildContext context) {
    final firestoreService = Provider.of<FirestoreService>(context, listen: false);
    final userId = FirebaseAuth.instance.currentUser?.uid ?? '';

    return MultiProvider(
      providers: [
        StreamProvider<SafetyCheckEvent?>(
          create: (_) => firestoreService.getActiveSafetyCheck(),
          initialData: null,
          catchError: (_, __) => null,
        ),
        StreamProvider<List<SOSRequestModel>>(
          create: (_) => firestoreService.getSOSRequests(),
          initialData: const [],
        ),
        StreamProvider<int>(
          create: (_) => firestoreService.getAlertCount(),
          initialData: 0,
        ),
      ],
      builder: (context, child) {
        final currentEvent = Provider.of<SafetyCheckEvent?>(context);
        final sosList = Provider.of<List<SOSRequestModel>>(context);
        final alertCount = Provider.of<int>(context);

        // CHECK FOR NEW SAFETY CHECK
        if (currentEvent != null) {
          if (_lastSafetyEventId == null) {
            _lastSafetyEventId = currentEvent.eventId;
            // First load: only flash if the event was triggered in the last 60 seconds
            if (DateTime.now().difference(currentEvent.createdAt).inSeconds < 60) {
              WidgetsBinding.instance.addPostFrameCallback((_) => _triggerEmergencyFlash());
            }
          } else if (currentEvent.eventId != _lastSafetyEventId) {
            // App is active and a new event came in
            _lastSafetyEventId = currentEvent.eventId;
            WidgetsBinding.instance.addPostFrameCallback((_) => _triggerEmergencyFlash());
          }
        } else {
          // No active event
          if (_lastSafetyEventId != null && _lastSafetyEventId != 'startup') {
             _lastSafetyEventId = null;
          }
        }

        // CHECK FOR NEW SOS
        if (sosList.length > _lastSOSCount) {
          _lastSOSCount = sosList.length;
           WidgetsBinding.instance.addPostFrameCallback((_) => _triggerEmergencyFlash());
        }

        // CHECK FOR NEW ALERTS
        if (alertCount > _lastAlertCount) {
          _lastAlertCount = alertCount;
           WidgetsBinding.instance.addPostFrameCallback((_) => _triggerEmergencyFlash());
        }

        // CHECK FOR ACCEPTED REPORTS
        _checkForAcceptedReports(context, firestoreService, userId);

        // Sync Offline Vault in background
        WidgetsBinding.instance.addPostFrameCallback((_) {
          firestoreService.syncOfflineVault();
        });

        return GestureDetector(
          onDoubleTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SOSScreen())),
          child: Stack(
            children: [
             // Listen for active safety check-ins (DIALOG RENDERER)
             if (currentEvent != null) ...[
               StreamBuilder<bool>(
                stream: firestoreService.hasUserResponded(currentEvent.eventId, userId),
                builder: (context, responseSnapshot) {
                  final hasResponded = responseSnapshot.data ?? true;
                  if (!hasResponded) {
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      _showSafetyCheckInDialog(context, currentEvent, firestoreService, userId);
                    });
                  }
                  return const SizedBox.shrink();
                },
              ),
             ],
        
            SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 20),
                  _buildWeatherCard(context),
                  const SizedBox(height: 20),
                  _buildActiveSOSStatus(context),
                  const SizedBox(height: 40),
                  _buildSOSSection(context),
                  const SizedBox(height: 40),
                  _buildActionGrid(context),
                  const SizedBox(height: 32),
                  _buildMyReports(context),
                  const SizedBox(height: 32),
                  _buildHazardFeed(context),
                  const SizedBox(height: 32),
                  _buildLiveUpdates(context),
                  const SizedBox(height: 100),
                ],
              ),
            ),
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
            Text('Your emergency report has been accepted and help is being dispatched to your location.', 
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

  void _showSafetyCheckInDialog(BuildContext context, SafetyCheckEvent event, FirestoreService firestoreService, String userId) {
    // Prevent multiple dialogs
    if (ModalRoute.of(context)?.isCurrent == false) return;

    final isDark = Theme.of(context).brightness == Brightness.dark;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF1E2841) : Colors.white,
        elevation: isDark ? 24 : 8,
        shadowColor: isDark ? Colors.black87 : Colors.black26,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: Colors.blue.withOpacity(0.1), shape: BoxShape.circle),
              child: const Icon(Icons.gpp_maybe_rounded, color: Colors.blueAccent, size: 40),
            ),
            const SizedBox(height: 24),
            Text(
              event.title.toUpperCase(),
              textAlign: TextAlign.center,
              style: TextStyle(color: isDark ? Colors.white : Colors.black87, fontWeight: FontWeight.w900, fontSize: 18),
            ),
            const SizedBox(height: 12),
            Text(
              'The Command Center is requesting a status update from all citizens in Cadiz City.',
              textAlign: TextAlign.center,
              style: TextStyle(color: isDark ? Colors.white54 : Colors.black54, fontSize: 13),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.greenAccent[700],
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () async {
                final pos = await Provider.of<LocationService>(context, listen: false).getCurrentLocation();
                final response = SafetyResponse(
                  responseId: '',
                  eventId: event.eventId,
                  userId: userId,
                  userName: FirebaseAuth.instance.currentUser?.displayName ?? 'Citizen',
                  status: 'safe',
                  latitude: pos?.latitude ?? 10.9575,
                  longitude: pos?.longitude ?? 123.3217,
                  timestamp: DateTime.now(),
                );
                await firestoreService.submitSafetyResponse(response);
                if (ctx.mounted) Navigator.pop(ctx);
              },
              child: const Text('I AM SAFE', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
            ),
            const SizedBox(height: 12),
            OutlinedButton(
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppConstants.primaryRed),
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () async {
                final pos = await Provider.of<LocationService>(context, listen: false).getCurrentLocation();
                final response = SafetyResponse(
                  responseId: '',
                  eventId: event.eventId,
                  userId: userId,
                  userName: FirebaseAuth.instance.currentUser?.displayName ?? 'Citizen',
                  status: 'needs_help',
                  latitude: pos?.latitude ?? 10.9575,
                  longitude: pos?.longitude ?? 123.3217,
                  timestamp: DateTime.now(),
                );
                await firestoreService.submitSafetyResponse(response);
                if (ctx.mounted) {
                  Navigator.pop(ctx);
                  // Optionally push to SOS screen
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const SOSScreen()));
                }
              },
              child: const Text('I NEED HELP', style: TextStyle(color: AppConstants.primaryRed, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWeatherCard(BuildContext context) {
    final weatherService = Provider.of<WeatherService>(context, listen: false);
    final locationService = Provider.of<LocationService>(context, listen: false);

    return FutureBuilder(
      future: locationService.getCurrentLocation().then((position) {
        return weatherService.getWeatherData(
          latitude: position?.latitude,
          longitude: position?.longitude,
        ).then((weather) => {'weather': weather, 'hasLoc': position != null});
      }),
      builder: (context, AsyncSnapshot<Map<String, dynamic>> snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildWeatherSkeleton();
        }

        if (snapshot.hasError || !snapshot.hasData) {
          return _buildWeatherError();
        }

        final weather = snapshot.data!['weather'] as WeatherModel;
        final hasLoc = snapshot.data!['hasLoc'] as bool;
        final isSevere = weather.weatherCode >= 80;

        final isDark = Theme.of(context).brightness == Brightness.dark;

        return Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: isDark
                  ? (isSevere
                      ? [const Color(0xFF4A0E0E), const Color(0xFF1E2841)]
                      : [const Color(0xFF1E2841), const Color(0xFF161E31)])
                  : (isSevere
                      ? [const Color(0xFFFFECEC), const Color(0xFFFFF3E0)]
                      : [const Color(0xFFE8F4FD), const Color(0xFFF0F4FF)]),
            ),
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color: isSevere
                    ? Colors.red.withOpacity(0.1)
                    : (isDark ? Colors.black26 : Colors.black.withOpacity(0.07)),
                blurRadius: 20,
                offset: const Offset(0, 10),
              )
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
                        hasLoc ? 'Current Location' : 'Cadiz City (Fixed)',
                        style: TextStyle(color: isDark ? Colors.white70 : Colors.black54, fontSize: 16, fontWeight: FontWeight.w500),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${weather.temperature.round()}°C',
                        style: TextStyle(color: isDark ? Colors.white : Colors.black87, fontSize: 36, fontWeight: FontWeight.w900, letterSpacing: -1),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            isSevere ? Icons.warning_amber_rounded : Icons.check_circle_rounded,
                            color: isSevere ? Colors.orangeAccent : Colors.greenAccent[400],
                            size: 16,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            isSevere ? 'Severe Weather Warning' : 'Safe Conditions',
                            style: TextStyle(
                              color: isSevere ? Colors.orangeAccent : Colors.greenAccent[400],
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  _getWeatherIcon(weather.weatherCode, size: 64),
                ],
              ),
              const SizedBox(height: 24),
              Divider(color: isDark ? Colors.white10 : Colors.black12),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildWeatherDetail('Humidity', '${weather.humidity.round()}%', Icons.water_drop_outlined),
                  _buildWeatherDetail('Wind', '${weather.windSpeed.round()} km/h', Icons.air_rounded),
                  _buildWeatherDetail('Status', weather.description, Icons.info_outline_rounded),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildWeatherDetail(String label, String value, IconData icon) {
    // isDark is passed via closure from parent build context
    // Use a Builder to get context here
    return Builder(builder: (context) {
      final isDark = Theme.of(context).brightness == Brightness.dark;
      return Column(
        children: [
          Icon(icon, color: isDark ? Colors.white54 : Colors.black45, size: 18),
          const SizedBox(height: 8),
          Text(value, style: TextStyle(color: isDark ? Colors.white : Colors.black87, fontSize: 13, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(label, style: TextStyle(color: isDark ? Colors.white30 : Colors.black38, fontSize: 10)),
        ],
      );
    });
  }

  Widget _getWeatherIcon(int code, {double size = 24}) {
    IconData icon;
    Color color = Colors.white;

    if (code == 0) {
      icon = Icons.wb_sunny_rounded;
      color = Colors.orangeAccent;
    } else if (code <= 3) {
      icon = Icons.wb_cloudy_rounded;
      color = Colors.white70;
    } else if (code <= 48) {
      icon = Icons.cloud_queue_rounded;
    } else if (code <= 65) {
      icon = Icons.umbrella_rounded;
      color = Colors.blueAccent;
    } else if (code <= 82) {
      icon = Icons.beach_access_rounded;
      color = Colors.blue;
    } else {
      icon = Icons.thunderstorm_rounded;
      color = Colors.deepPurpleAccent;
    }

    return Icon(icon, color: color, size: size);
  }

  Widget _buildWeatherSkeleton() {
    return Builder(builder: (context) {
      final isDark = Theme.of(context).brightness == Brightness.dark;
      return Container(
        height: 200,
        width: double.infinity,
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E2841) : const Color(0xFFE8F4FD),
          borderRadius: BorderRadius.circular(28),
        ),
        child: const Center(child: CircularProgressIndicator(color: AppConstants.primaryRed)),
      );
    });
  }

  Widget _buildWeatherError() {
    return Builder(builder: (context) {
      final isDark = Theme.of(context).brightness == Brightness.dark;
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E2841) : const Color(0xFFE8F4FD),
          borderRadius: BorderRadius.circular(28),
        ),
        child: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.redAccent),
            const SizedBox(width: 16),
            Text('Weather data unavailable', style: TextStyle(color: isDark ? Colors.white54 : Colors.black54)),
          ],
        ),
      );
    },
  );
}
  Widget _buildSOSSection(BuildContext context) {
    return Center(
      child: Column(
        children: [
          SOSHoldButton(
            onTrigger: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SOSScreen())),
          ),
          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              'In case of emergency, hold the button to notify authorities and emergency contacts.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Theme.of(context).brightness == Brightness.dark ? Colors.white54 : Colors.black54, fontSize: 14),
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
        _buildActionCard(context, 'MAP', 'Real-time locations', Icons.map_rounded, const Color(0xFF6366F1), const GlobalMapScreen()),
        _buildActionCard(context, 'REPORT', 'Incident evidence', Icons.add_a_photo_rounded, const Color(0xFFEC4899), const ReportScreen()),
        _buildActionCard(context, 'HAZARDS', 'Recent danger pics', Icons.warning_amber_rounded, Colors.orange, const HazardGalleryScreen()),
        _buildActionCard(context, 'OFFLINE VAULT', 'First Aid & Safety', Icons.book_rounded, const Color(0xFFF59E0B), const OfflineVaultScreen()),
        _buildActionCard(context, 'CONTACTS', 'Emergency services', Icons.contact_phone_rounded, const Color(0xFF10B981), const ContactsScreen()),
        _buildActionCard(context, 'WEATHER', 'Cadiz City Forecast', Icons.cloud_queue_rounded, Colors.lightBlue, const WeatherScreen()),
      ],
    );
  }

  Widget _buildHazardFeed(BuildContext context) {
    final firestoreService = Provider.of<FirestoreService>(context, listen: false);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Community Hazards Feed',
              style: TextStyle(
                color: isDark ? Colors.white : Colors.black87,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            TextButton(
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const HazardGalleryScreen())),
              child: const Text('View All', style: TextStyle(color: AppConstants.primaryRed)),
            ),
          ],
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 180,
          child: StreamBuilder<List<HazardModel>>(
            stream: firestoreService.getHazards(),
            builder: (context, snapshot) {
              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1E2841) : Colors.black.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Center(
                    child: Text('No hazard reports yet.', style: TextStyle(color: isDark ? Colors.white24 : Colors.black26)),
                  ),
                );
              }

              final hazards = snapshot.data!.take(5).toList();
              return ListView.builder(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                itemCount: hazards.length,
                itemBuilder: (context, index) {
                  final hazard = hazards[index];
                  return Container(
                    width: 150,
                    margin: const EdgeInsets.only(right: 16),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1E2841) : Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10)],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: ClipRRect(
                            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                            child: hazard.imageBase64 != null
                                ? Image.memory(base64Decode(hazard.imageBase64!), fit: BoxFit.cover, width: double.infinity)
                                : Container(color: Colors.grey, child: const Icon(Icons.broken_image)),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(10),
                          child: Text(
                            hazard.description,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(color: isDark ? Colors.white : Colors.black87, fontSize: 12, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          ),
        ),
        const SizedBox(height: 16),
        Center(
          child: OutlinedButton.icon(
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ReportHazardScreen())),
            icon: const Icon(Icons.add_a_photo_rounded, color: AppConstants.primaryRed),
            label: const Text('REPORT NEW HAZARD', style: TextStyle(color: AppConstants.primaryRed, fontWeight: FontWeight.bold, letterSpacing: 1.1)),
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: AppConstants.primaryRed.withOpacity(0.5)),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
          ),
        ),
      ],
    );
  }


  Widget _buildMyReports(BuildContext context) {
    final firestoreService = Provider.of<FirestoreService>(context, listen: false);
    final userId = FirebaseAuth.instance.currentUser?.uid ?? '';
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'My Active Reports',
          style: TextStyle(
            color: isDark ? Colors.white : Colors.black87,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        StreamBuilder<List<IncidentModel>>(
          stream: firestoreService.getIncidents(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) return const SizedBox.shrink();
            
            final myActiveReports = snapshot.data!
                .where((i) => i.userId == userId && i.status != 'resolved')
                .toList();

            if (myActiveReports.isEmpty) {
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
                child: Text(
                  'You have no active incident reports.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: isDark ? Colors.white30 : Colors.black38, fontSize: 13),
                ),
              );
            }

            return Column(
              children: myActiveReports.map((incident) => _buildMyReportItem(context, incident)).toList(),
            );
          },
        ),
      ],
    );
  }

  Widget _buildMyReportItem(BuildContext context, IncidentModel incident) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    Color statusColor = Colors.orange;
    String statusText = 'WAITING FOR REVIEW';

    if (incident.status == 'dispatched') {
      statusColor = Colors.blueAccent;
      statusText = 'HELP IS ON THE WAY';
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
              color: statusColor.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              incident.status == 'dispatched' ? Icons.local_shipping : Icons.pending_actions,
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
                Text(
                  statusText,
                  style: TextStyle(color: statusColor, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 0.5),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Icon(Icons.chevron_right, color: isDark ? Colors.white12 : Colors.black12),
        ],
      ),
    );
  }

  Widget _buildActionCard(BuildContext context, String title, String subtitle, IconData icon, Color iconColor, Widget screen) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return InkWell(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => screen)),
      child: Container(
        padding: const EdgeInsets.all(16), // Slightly reduced padding
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
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.2),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(icon, color: iconColor, size: 24), // Slightly smaller icon
            ),
            const SizedBox(height: 8),
            Flexible(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title, 
                    style: TextStyle(color: isDark ? Colors.white : Colors.black87, fontSize: 16, fontWeight: FontWeight.bold),
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

  Widget _buildLiveUpdates(BuildContext context) {
    final firestoreService = Provider.of<FirestoreService>(context, listen: false);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Live Updates', style: TextStyle(color: isDark ? Colors.white : Colors.black87, fontSize: 20, fontWeight: FontWeight.bold)),
            TextButton(
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AlertsScreen())), 
              child: const Text('View all', style: TextStyle(color: AppConstants.primaryRed))
            ),
          ],
        ),
        const SizedBox(height: 16),
        StreamBuilder<List<AlertModel>>(
          stream: firestoreService.getAlerts(),
          builder: (context, snapshot) {
            if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  child: Text('No active updates at this time', style: TextStyle(color: isDark ? Colors.white38 : Colors.black38, fontSize: 14)),
                ),
              );
            }

            final alerts = snapshot.data!.take(2).toList();
            return Column(
              children: alerts.map((alert) => _buildAlertItem(context, alert)).toList(),
            );
          },
        ),
      ],
    );
  }

  Widget _buildActiveSOSStatus(BuildContext context) {
    final userId = FirebaseAuth.instance.currentUser?.uid ?? '';
    final firestoreService = Provider.of<FirestoreService>(context, listen: false);

    return StreamBuilder<List<SOSRequestModel>>(
      stream: firestoreService.getSOSRequests(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox.shrink();
        
        final userSOS = snapshot.data!.where((s) => s.userId == userId && s.status != 'resolved').toList();
        if (userSOS.isEmpty) return const SizedBox.shrink();

        final activeSOS = userSOS.first;
        final isDispatched = activeSOS.status == 'dispatched';

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: isDispatched ? const Color(0xFF1B5E20).withOpacity(0.9) : AppConstants.primaryRed.withOpacity(0.9),
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: (isDispatched ? Colors.green : Colors.red).withOpacity(0.2),
                blurRadius: 20,
                spreadRadius: 2,
              )
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  isDispatched ? Icons.local_shipping : Icons.emergency,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isDispatched ? 'HELP DISPATCHED' : 'SOS SIGNAL ACTIVE',
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    Text(
                      isDispatched ? 'A responder is on their way to you.' : 'Waiting for dispatch confirmation...',
                      style: const TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                  ],
                ),
              ),
              if (isDispatched)
                const Icon(Icons.check_circle, color: Colors.white, size: 24),
            ],
          ),
        );
      },
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
              color: (alert.disasterType == 'Critical' ? AppConstants.primaryRed : Colors.orange).withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              alert.disasterType == 'Critical' ? Icons.warning_rounded : Icons.info_rounded,
              color: alert.disasterType == 'Critical' ? AppConstants.primaryRed : Colors.orange,
              size: 20,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(alert.title, style: TextStyle(color: isDark ? Colors.white : Colors.black87, fontWeight: FontWeight.bold)),
                const SizedBox(height: 2),
                Text(
                  alert.description,
                  maxLines: 1,
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
