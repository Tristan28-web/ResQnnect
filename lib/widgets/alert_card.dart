import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/alert_model.dart';
import '../core/constants.dart';

class AlertCard extends StatelessWidget {
  final AlertModel alert;
  final bool isUnread;

  const AlertCard({super.key, required this.alert, this.isUnread = false});

  Color _getSeverityColor() {
    final type = alert.disasterType.toLowerCase();
    if (type.contains('critical') || type.contains('severe') || type.contains('danger')) {
      return AppConstants.primaryRed;
    } else if (type.contains('warning') || type.contains('advisory')) {
      return Colors.orangeAccent;
    } else if (type.contains('info') || type.contains('update')) {
      return Colors.blueAccent;
    }
    return Colors.blueGrey;
  }

  IconData _getSeverityIcon() {
    final type = alert.disasterType.toLowerCase();
    if (type.contains('critical')) return Icons.gpp_maybe_rounded;
    if (type.contains('warning')) return Icons.warning_amber_rounded;
    return Icons.info_outline_rounded;
  }

  @override
  Widget build(BuildContext context) {
    final severityColor = _getSeverityColor();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        gradient: isDark ? const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1E2841), Color(0xFF161E31)],
        ) : null,
        color: isDark ? null : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isUnread ? severityColor.withOpacity(0.4) : (isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.05)),
          width: isUnread ? 2 : 1,
        ),
        boxShadow: [
          if (isUnread)
            BoxShadow(
              color: severityColor.withOpacity(0.1),
              blurRadius: 15,
              spreadRadius: 2,
            ),
          if (isDark)
            const BoxShadow(color: Colors.black45, blurRadius: 10, offset: Offset(0, 4)),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              color: severityColor.withOpacity(0.1),
              child: Row(
                children: [
                  Icon(_getSeverityIcon(), color: severityColor, size: 18),
                  const SizedBox(width: 8),
                  Text(
                    alert.disasterType.toUpperCase(),
                    style: TextStyle(
                      color: severityColor,
                      fontWeight: FontWeight.w900,
                      fontSize: 11,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const Spacer(),
                  if (isUnread)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: severityColor,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Text(
                        'NEW',
                        style: TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold),
                      ),
                    ),
                  const SizedBox(width: 8),
                  Text(
                    DateFormat('hh:mm a').format(alert.createdAt),
                    style: TextStyle(color: isDark ? Colors.white38 : Colors.black54, fontSize: 10, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
            
            // Body
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    alert.title,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : Colors.black87,
                      letterSpacing: 0.2,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    alert.description,
                    style: TextStyle(
                      color: isDark ? Colors.white70 : Colors.black54,
                      height: 1.5,
                      fontSize: 14,
                    ),
                  ),
                  
                  // Action Buttons
                  if (alert.description.toLowerCase().contains('evacuat') || 
                      alert.description.toLowerCase().contains('safe zone') ||
                      alert.description.toLowerCase().contains('center'))
                    Padding(
                      padding: const EdgeInsets.only(top: 20),
                      child: ElevatedButton.icon(
                        onPressed: () {
                          // In DashboardState or via Navigator, go to SafeZones
                          // For now, simple navigation to the screen directly
                          Navigator.pushNamed(context, '/safe_zones');
                        },
                        icon: const Icon(Icons.map_outlined, size: 16),
                        label: const Text('GO TO SAFE ZONE MAP'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: severityColor.withOpacity(0.2),
                          foregroundColor: severityColor,
                          elevation: 0,
                          minimumSize: const Size(double.infinity, 44),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          side: BorderSide(color: severityColor.withOpacity(0.3)),
                        ),
                      ),
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
