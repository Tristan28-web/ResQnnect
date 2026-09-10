import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/alert_model.dart';
import '../core/constants.dart';

class AlertCard extends StatelessWidget {
  final AlertModel alert;
  final bool isUnread;

  const AlertCard({super.key, required this.alert, this.isUnread = false});

  Color _getBadgeBg() {
    final type = alert.disasterType.toLowerCase();
    if (type.contains('critical') || type.contains('severe') || type.contains('danger') || type.contains('typhoon')) {
      return const Color(0xFFFEE2E2);
    } else if (type.contains('warning') || type.contains('advisory') || type.contains('flood')) {
      return AppColors.retroPeach;
    }
    return AppColors.retroMintLight;
  }

  Color _getBadgeTextColor() {
    final type = alert.disasterType.toLowerCase();
    if (type.contains('critical') || type.contains('severe') || type.contains('danger') || type.contains('typhoon')) {
      return const Color(0xFFDC2626);
    } else if (type.contains('warning') || type.contains('advisory') || type.contains('flood')) {
      return const Color(0xFFD97706);
    }
    return AppColors.retroMintDark;
  }

  IconData _getSeverityIcon() {
    final type = alert.disasterType.toLowerCase();
    if (type.contains('critical') || type.contains('danger')) return Icons.gpp_maybe_rounded;
    if (type.contains('warning') || type.contains('flood')) return Icons.warning_amber_rounded;
    if (type.contains('typhoon')) return Icons.cyclone_rounded;
    return Icons.info_outline_rounded;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final badgeBg = _getBadgeBg();
    final badgeText = _getBadgeTextColor();

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
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
        children: [
          // Retro Header Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF262C38) : const Color(0xFFF9FAFB),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              border: Border(
                bottom: BorderSide(
                  color: isDark ? const Color(0xFF3E4556) : AppColors.retroDarkBorder,
                  width: 1.4,
                ),
              ),
            ),
            child: Row(
              children: [
                // Severity Tag Pill
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: badgeBg,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.retroDarkBorder, width: 1.2),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(_getSeverityIcon(), color: badgeText, size: 14),
                      const SizedBox(width: 5),
                      Text(
                        alert.disasterType.toUpperCase(),
                        style: TextStyle(
                          color: badgeText,
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                if (isUnread)
                  Container(
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.retroMint,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.retroDarkBorder, width: 1.0),
                    ),
                    child: const Text(
                      'NEW',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 9,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                Text(
                  DateFormat('hh:mm a').format(alert.createdAt),
                  style: TextStyle(
                    color: isDark ? Colors.white60 : const Color(0xFF6B7280),
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),

          // Body
          Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  alert.title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    color: isDark ? Colors.white : AppColors.retroDarkBorder,
                    letterSpacing: -0.2,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  alert.description,
                  style: TextStyle(
                    color: isDark ? Colors.white70 : const Color(0xFF4B5563),
                    height: 1.45,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
