import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../models/incident_model.dart';
import '../core/constants.dart';
import '../screens/global_map_screen.dart';

class IncidentDetailSheet extends StatelessWidget {
  final IncidentModel incident;
  final bool isAdmin;
  final VoidCallback? onStatusChanged;

  const IncidentDetailSheet({
    super.key,
    required this.incident,
    this.isAdmin = false,
    this.onStatusChanged,
  });

  static Future<void> show(
    BuildContext context, {
    required IncidentModel incident,
    bool isAdmin = false,
    VoidCallback? onStatusChanged,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.85,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) => Container(
          decoration: BoxDecoration(
            color: isDark ? AppColors.retroDarkCard : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            border: Border.all(
              color: isDark ? const Color(0xFF3E4556) : AppColors.retroDarkBorder,
              width: 2.0,
            ),
          ),
          child: IncidentDetailSheet(
            incident: incident,
            isAdmin: isAdmin,
            onStatusChanged: onStatusChanged,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final typeColor = _getTypeColor(incident.incidentType);
    final statusColor = _getStatusColor(incident.status);
    final statusBg = _getStatusBg(incident.status, isDark);

    return Column(
      children: [
        // Top Drag Handle & Title Bar
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 16, 8),
          child: Column(
            children: [
              Center(
                child: Container(
                  width: 44,
                  height: 4,
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white24 : AppColors.retroDarkBorder.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: typeColor.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: typeColor, width: 1.4),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(_getTypeIcon(incident.incidentType), size: 14, color: typeColor),
                            const SizedBox(width: 5),
                            Text(
                              incident.incidentType.toUpperCase(),
                              style: TextStyle(
                                color: typeColor,
                                fontSize: 11,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 0.6,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        incident.referenceId,
                        style: TextStyle(
                          color: isDark ? Colors.white70 : AppColors.retroDarkBorder,
                          fontSize: 13,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ],
                  ),
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF262C38) : const Color(0xFFF3F4F6),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isDark ? const Color(0xFF3E4556) : AppColors.retroDarkBorder,
                          width: 1.4,
                        ),
                      ),
                      child: Icon(
                        Icons.close_rounded,
                        size: 16,
                        color: isDark ? Colors.white : AppColors.retroDarkBorder,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        const Divider(height: 1, thickness: 1.2),

        // Scrollable Body
        Expanded(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Photo / Picture Preview Section
                _buildPhotoSection(context, isDark),
                const SizedBox(height: 16),

                // 2. Main Title / Description Headline
                Text(
                  incident.description,
                  style: TextStyle(
                    color: isDark ? Colors.white : AppColors.retroDarkBorder,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.3,
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 12),

                // 3. Status & Severity Badges
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: statusBg,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: statusColor, width: 1.4),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 7,
                            height: 7,
                            decoration: BoxDecoration(
                              color: statusColor,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            incident.isAutoClosed ? 'CLOSED' : 'ACTIVE',
                            style: TextStyle(
                              color: statusColor,
                              fontSize: 10,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.6,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    _buildSeverityBadge(incident.severity, isDark),
                  ],
                ),
                const SizedBox(height: 18),

                // 4. Details Information Box
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1E222D) : const Color(0xFFF9FAFB),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: isDark ? const Color(0xFF3E4556) : AppColors.retroDarkBorder.withOpacity(0.2),
                      width: 1.4,
                    ),
                  ),
                  child: Column(
                    children: [
                      _buildDetailRow(
                        icon: Icons.location_city_rounded,
                        iconColor: AppColors.retroLilac,
                        label: 'Barangay',
                        value: incident.barangay.isNotEmpty ? incident.barangay : 'Catanduanes Sector',
                        isDark: isDark,
                      ),
                      const SizedBox(height: 12),
                      _buildDetailRow(
                        icon: Icons.pin_drop_rounded,
                        iconColor: AppColors.retroMint,
                        label: 'Location / Landmark',
                        value: incident.location,
                        isDark: isDark,
                      ),
                      if (incident.latitude != null && incident.longitude != null) ...[
                        const SizedBox(height: 12),
                        _buildDetailRow(
                          icon: Icons.my_location_rounded,
                          iconColor: const Color(0xFF3B82F6),
                          label: 'Coordinates',
                          value: '${incident.latitude!.toStringAsFixed(5)}, ${incident.longitude!.toStringAsFixed(5)}',
                          isDark: isDark,
                        ),
                      ],
                      const SizedBox(height: 12),
                      _buildDetailRow(
                        icon: Icons.schedule_rounded,
                        iconColor: const Color(0xFFF59E0B),
                        label: 'Reported Timestamp',
                        value: DateFormat('MMMM dd, yyyy • hh:mm a').format(incident.timestamp),
                        isDark: isDark,
                      ),
                      if (incident.userId.isNotEmpty && incident.userId != 'anonymous') ...[
                        const SizedBox(height: 12),
                        _buildDetailRow(
                          icon: Icons.person_rounded,
                          iconColor: const Color(0xFF8B5CF6),
                          label: 'Reporter ID',
                          value: incident.userId,
                          isDark: isDark,
                        ),
                      ],
                      if (incident.resolutionNotes != null && incident.resolutionNotes!.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        _buildDetailRow(
                          icon: Icons.assignment_turned_in_rounded,
                          iconColor: const Color(0xFF16A34A),
                          label: 'Resolution Notes',
                          value: incident.resolutionNotes!,
                          isDark: isDark,
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // 5. Action Buttons (View on Map & Admin Status Update)
                if (incident.latitude != null && incident.longitude != null) ...[
                  GestureDetector(
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => GlobalMapScreen(
                            initialLocation: LatLng(incident.latitude!, incident.longitude!),
                          ),
                        ),
                      );
                    },
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF262C38) : Colors.white,
                        borderRadius: BorderRadius.circular(16),
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
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.map_rounded, size: 18, color: AppColors.retroMint),
                          const SizedBox(width: 8),
                          Text(
                            'VIEW ON GIS MAP',
                            style: TextStyle(
                              color: isDark ? Colors.white : AppColors.retroDarkBorder,
                              fontSize: 12,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.6,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],

                // 15-Day Automatic Closure Policy Card
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: incident.isAutoClosed
                        ? (isDark ? const Color(0xFF262C38) : const Color(0xFFF1F5F9))
                        : (isDark ? const Color(0xFF1E2B24) : const Color(0xFFECFDF5)),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: incident.isAutoClosed
                          ? (isDark ? const Color(0xFF475569) : const Color(0xFF94A3B8))
                          : const Color(0xFF10B981),
                      width: 1.8,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: isDark ? Colors.black45 : AppColors.retroDarkBorder.withOpacity(0.1),
                        offset: const Offset(3, 3),
                        blurRadius: 0,
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: incident.isAutoClosed
                                  ? (isDark ? Colors.white12 : const Color(0xFFCBD5E1))
                                  : const Color(0xFF10B981).withOpacity(0.2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              incident.isAutoClosed ? Icons.lock_clock_rounded : Icons.auto_mode_rounded,
                              size: 16,
                              color: incident.isAutoClosed
                                  ? (isDark ? Colors.white70 : const Color(0xFF475569))
                                  : const Color(0xFF059669),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              incident.isAutoClosed
                                  ? 'AUTOMATICALLY CLOSED (15-DAY LIMIT)'
                                  : '15-DAY AUTOMATIC CLOSURE POLICY',
                              style: TextStyle(
                                color: incident.isAutoClosed
                                    ? (isDark ? Colors.white70 : const Color(0xFF334155))
                                    : const Color(0xFF047857),
                                fontSize: 11,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        incident.isAutoClosed
                            ? 'This report reached the 15-day system lifecycle limit and was automatically closed and archived.'
                            : 'This report will automatically close in ${incident.daysUntilAutoClose} day(s) (Day ${incident.ageInDays} of 15). Manual status updates have been disabled per system policy.',
                        style: TextStyle(
                          color: isDark ? Colors.white60 : const Color(0xFF64748B),
                          fontSize: 11,
                          height: 1.35,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (!incident.isAutoClosed) ...[
                        const SizedBox(height: 10),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: (incident.ageInDays / 15.0).clamp(0.0, 1.0),
                            backgroundColor: isDark ? Colors.white12 : const Color(0xFFD1FAE5),
                            valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF10B981)),
                            minHeight: 6,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // --- PHOTO PREVIEW SECTION ---
  Widget _buildPhotoSection(BuildContext context, bool isDark) {
    Uint8List? memoryBytes;
    String? networkUrl;

    if (incident.imageBase64 != null && incident.imageBase64!.isNotEmpty) {
      try {
        String raw = incident.imageBase64!.trim();
        if (raw.contains(',')) {
          raw = raw.split(',').last;
        }
        raw = raw.replaceAll(RegExp(r'\s+'), '');
        memoryBytes = base64Decode(raw);
      } catch (e) {
        debugPrint('Incident image decode error: $e');
      }
    } else if (incident.imageUrl != null &&
        (incident.imageUrl!.startsWith('http://') || incident.imageUrl!.startsWith('https://'))) {
      networkUrl = incident.imageUrl;
    }

    if (memoryBytes != null || networkUrl != null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: () => _showFullScreenImage(context, memoryBytes, networkUrl),
            child: Stack(
              children: [
                Container(
                  width: double.infinity,
                  height: 220,
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1E222D) : const Color(0xFFF3F4F6),
                    borderRadius: BorderRadius.circular(20),
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
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(18),
                    child: memoryBytes != null
                        ? Image.memory(
                            memoryBytes,
                            width: double.infinity,
                            height: 220,
                            fit: BoxFit.cover,
                            errorBuilder: (ctx, err, stack) => _buildPhotoFallback(isDark),
                          )
                        : Image.network(
                            networkUrl!,
                            width: double.infinity,
                            height: 220,
                            fit: BoxFit.cover,
                            errorBuilder: (ctx, err, stack) => _buildPhotoFallback(isDark),
                          ),
                  ),
                ),
                // Photo Tag Badge
                Positioned(
                  top: 10,
                  left: 10,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.75),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.white24, width: 1),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.camera_alt_rounded, size: 12, color: Colors.white),
                        SizedBox(width: 5),
                        Text(
                          'FIELD PHOTO',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.6,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                // Tap to zoom hint
                Positioned(
                  bottom: 10,
                  right: 10,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.75),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.white24, width: 1),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.zoom_in_rounded, size: 12, color: Colors.white),
                        SizedBox(width: 4),
                        Text(
                          'Tap to zoom',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      );
    }

    // No photo fallback container
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E222D) : const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? const Color(0xFF3E4556) : AppColors.retroDarkBorder.withOpacity(0.25),
          width: 1.4,
        ),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF262C38) : const Color(0xFFE5E7EB),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.no_photography_rounded,
              size: 26,
              color: isDark ? Colors.white38 : const Color(0xFF9CA3AF),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'NO FIELD PHOTO ATTACHED',
            style: TextStyle(
              color: isDark ? Colors.white60 : const Color(0xFF6B7280),
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.6,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            'The reporter did not upload camera evidence for this incident.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isDark ? Colors.white30 : const Color(0xFF9CA3AF),
              fontSize: 10,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPhotoFallback(bool isDark) {
    return Center(
      child: Icon(
        Icons.broken_image_rounded,
        size: 32,
        color: isDark ? Colors.white38 : const Color(0xFF9CA3AF),
      ),
    );
  }

  // Full Screen Zoomable Image Modal
  void _showFullScreenImage(BuildContext context, Uint8List? bytes, String? url) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.black,
        insetPadding: EdgeInsets.zero,
        child: Stack(
          children: [
            Center(
              child: InteractiveViewer(
                minScale: 0.8,
                maxScale: 4.0,
                child: bytes != null
                    ? Image.memory(bytes, fit: BoxFit.contain)
                    : Image.network(url!, fit: BoxFit.contain),
              ),
            ),
            Positioned(
              top: 40,
              right: 20,
              child: GestureDetector(
                onTap: () => Navigator.pop(ctx),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: const BoxDecoration(
                    color: Colors.white24,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.close_rounded, color: Colors.white, size: 24),
                ),
              ),
            ),
            Positioned(
              bottom: 30,
              left: 20,
              right: 20,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.black87,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white24, width: 1),
                ),
                child: Text(
                  '${incident.referenceId} • ${incident.incidentType.toUpperCase()} Evidence',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow({
    required IconData icon,
    required Color iconColor,
    required String label,
    required String value,
    required bool isDark,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: iconColor.withOpacity(0.15),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 14, color: iconColor),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: isDark ? Colors.white38 : const Color(0xFF9CA3AF),
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.4,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: TextStyle(
                  color: isDark ? Colors.white : AppColors.retroDarkBorder,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSeverityBadge(String severity, bool isDark) {
    Color color = const Color(0xFF10B981);
    String label = 'LOW';
    switch (severity.toLowerCase()) {
      case 'critical':
      case 'high':
        color = const Color(0xFFEF4444);
        label = severity.toUpperCase();
        break;
      case 'medium':
        color = const Color(0xFFF59E0B);
        label = 'MEDIUM';
        break;
      default:
        color = const Color(0xFF10B981);
        label = 'LOW';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color, width: 1.2),
      ),
      child: Text(
        'SEVERITY: $label',
        style: TextStyle(
          color: color,
          fontSize: 9,
          fontWeight: FontWeight.w900,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Color _getTypeColor(String type) {
    switch (type.toLowerCase()) {
      case 'fire':
        return const Color(0xFFEF4444);
      case 'flood':
        return const Color(0xFF3B82F6);
      case 'crime':
        return const Color(0xFF8B5CF6);
      case 'accident':
        return const Color(0xFFEA580C);
      default:
        return const Color(0xFF10B981);
    }
  }

  IconData _getTypeIcon(String type) {
    switch (type.toLowerCase()) {
      case 'fire':
        return Icons.local_fire_department_rounded;
      case 'flood':
        return Icons.water_drop_rounded;
      case 'crime':
        return Icons.security_rounded;
      case 'accident':
        return Icons.car_crash_rounded;
      default:
        return Icons.report_problem_rounded;
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'closed':
        return const Color(0xFF64748B);
      case 'active':
      default:
        return const Color(0xFF10B981);
    }
  }

  Color _getStatusBg(String status, bool isDark) {
    switch (status.toLowerCase()) {
      case 'closed':
        return isDark ? const Color(0xFF21252D) : const Color(0xFFF1F5F9);
      case 'active':
      default:
        return isDark ? const Color(0xFF142E1F) : const Color(0xFFDCFCE7);
    }
  }
}
