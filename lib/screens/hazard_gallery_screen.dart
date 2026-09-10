import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/hazard_model.dart';
import '../services/firestore_service.dart';
import '../core/constants.dart';
import 'report_hazard_screen.dart';
import '../models/user_model.dart';

class HazardGalleryScreen extends StatelessWidget {
  const HazardGalleryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final firestoreService = Provider.of<FirestoreService>(context, listen: false);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('COMMUNITY HAZARDS', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ReportHazardScreen())),
        backgroundColor: AppConstants.primaryRed,
        icon: const Icon(Icons.add_a_photo, color: Colors.white),
        label: const Text('REPORT HAZARD', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      body: StreamBuilder<List<HazardModel>>(
        stream: firestoreService.getHazards(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: AppConstants.primaryRed));
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}', style: TextStyle(color: isDark ? Colors.white54 : Colors.black54)));
          }

          final hazards = snapshot.data ?? [];
          if (hazards.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.photo_library_outlined, size: 80, color: isDark ? Colors.white12 : Colors.black12),
                  const SizedBox(height: 16),
                  Text(
                    'No hazard pictures reported yet.',
                    style: TextStyle(color: isDark ? Colors.white24 : Colors.black26, fontSize: 16),
                  ),
                ],
              ),
            );
          }

          return GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 0.8,
            ),
            itemCount: hazards.length,
            itemBuilder: (context, index) {
              return _buildHazardCard(context, hazards[index]);
            },
          );
        },
      ),
    );
  }

  Widget _buildHazardCard(BuildContext context, HazardModel hazard) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return GestureDetector(
      onTap: () => _showHazardDetail(context, hazard),
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E2841) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isDark ? 0.3 : 0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                child: hazard.imageBase64 != null
                    ? Image.memory(
                        base64Decode(hazard.imageBase64!),
                        fit: BoxFit.cover,
                      )
                    : Container(
                        color: AppConstants.primaryRed.withOpacity(0.1),
                        child: const Icon(Icons.image_not_supported, color: AppConstants.primaryRed),
                      ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _formatType(hazard.type),
                    style: const TextStyle(color: AppConstants.primaryRed, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    hazard.description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: isDark ? Colors.white : Colors.black87, fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.access_time, size: 10, color: isDark ? Colors.white30 : Colors.black38),
                      const SizedBox(width: 4),
                      Text(
                        DateFormat('MMM d, h:mm a').format(hazard.timestamp),
                        style: TextStyle(color: isDark ? Colors.white30 : Colors.black38, fontSize: 9),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showHazardDetail(BuildContext context, HazardModel hazard) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final user = Provider.of<UserModel?>(context, listen: false);
    final isAdmin = user?.role == 'admin';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.8,
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF161E31) : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
                  child: hazard.imageBase64 != null
                      ? Image.memory(
                          base64Decode(hazard.imageBase64!),
                          height: 300,
                          width: double.infinity,
                          fit: BoxFit.cover,
                        )
                      : Container(height: 300, color: Colors.grey[800]),
                ),
                Positioned(
                  top: 20, right: 20,
                  child: CircleAvatar(
                    backgroundColor: Colors.black54,
                    child: IconButton(
                      icon: const Icon(Icons.close, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),
                ),
              ],
            ),
            Expanded(
              child: Padding(
                padding: EdgeInsets.fromLTRB(24, 24, 24, 24 + MediaQuery.of(context).padding.bottom),
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppConstants.primaryRed.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          _formatType(hazard.type).toUpperCase(),
                          style: const TextStyle(color: AppConstants.primaryRed, fontWeight: FontWeight.bold, fontSize: 11),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        hazard.description,
                        style: TextStyle(color: isDark ? Colors.white : Colors.black87, fontSize: 18, fontWeight: FontWeight.bold, height: 1.4),
                      ),
                      const SizedBox(height: 24),
                      _buildDetailRow(Icons.location_on_outlined, 'Location', '${hazard.latitude.toStringAsFixed(4)}, ${hazard.longitude.toStringAsFixed(4)}', isDark),
                      _buildDetailRow(Icons.calendar_today_outlined, 'Reported At', DateFormat('MMMM d, yyyy - h:mm a').format(hazard.timestamp), isDark),
                      if (isAdmin) ...[
                        const SizedBox(height: 32),
                        ElevatedButton.icon(
                          onPressed: () => _confirmDeleteHazard(context, hazard),
                          icon: const Icon(Icons.delete_outline_rounded),
                          label: const Text('REMOVE HAZARD', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppConstants.primaryRed,
                            foregroundColor: Colors.white,
                            minimumSize: const Size(double.infinity, 54),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value, bool isDark, {Color? color}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppConstants.primaryRed, size: 20),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: TextStyle(color: isDark ? Colors.white30 : Colors.black38, fontSize: 12)),
              const SizedBox(height: 4),
              Text(value, style: TextStyle(color: color ?? (isDark ? Colors.white70 : Colors.black87), fontSize: 14, fontWeight: FontWeight.w500)),
            ],
          ),
        ],
      ),
    );
  }

  void _confirmDeleteHazard(BuildContext context, HazardModel hazard) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Remove Hazard?', style: TextStyle(fontWeight: FontWeight.bold)),
        content: const Text('This hazard report will be permanently deleted from the system. This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('CANCEL', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppConstants.primaryRed),
            onPressed: () async {
              Navigator.pop(ctx);
              Navigator.pop(context); // Close the bottom sheet
              await Provider.of<FirestoreService>(context, listen: false).deleteHazard(hazard.hazardId);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Hazard removed successfully!'), backgroundColor: Colors.green),
                );
              }
            },
            child: const Text('REMOVE', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  String _formatType(HazardType type) {
    switch (type) {
      case HazardType.roadHazard: return 'Road Hazard';
      case HazardType.naturalDisaster: return 'Natural Disaster';
      case HazardType.other: return 'General Hazard';
    }
  }
}
