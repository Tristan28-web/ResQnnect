import 'package:flutter/material.dart';
import '../core/constants.dart';
import 'package:intl/intl.dart';

class AdminLogsScreen extends StatefulWidget {
  const AdminLogsScreen({super.key});

  @override
  State<AdminLogsScreen> createState() => _AdminLogsScreenState();
}

class _AdminLogsScreenState extends State<AdminLogsScreen> {
  // Mock data for the administrative logs UI since a unified logging collection doesn't exist yet
  final List<Map<String, dynamic>> _mockLogs = [
    {
      'action': 'System Configuration Updated',
      'user': 'Admin',
      'timestamp': DateTime.now().subtract(const Duration(minutes: 5)),
      'type': 'config',
    },
    {
      'action': 'New Map Pin Added: Eastern Bicol Medical Center',
      'user': 'Admin',
      'timestamp': DateTime.now().subtract(const Duration(minutes: 12)),
      'type': 'map',
    },
    {
      'action': 'Broadcast Alert: Heavy Rain Warning',
      'user': 'Admin',
      'timestamp': DateTime.now().subtract(const Duration(hours: 1)),
      'type': 'alert',
    },
    {
      'action': 'Citizen Account Verified: Juan Dela Cruz',
      'user': 'Admin',
      'timestamp': DateTime.now().subtract(const Duration(hours: 2)),
      'type': 'user',
    },
    {
      'action': 'System Boot up Sequence Completed',
      'user': 'System',
      'timestamp': DateTime.now().subtract(const Duration(hours: 5)),
      'type': 'system',
    },
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: isDark ? AppColors.retroDarkCard : Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: isDark ? const Color(0xFF3E4556) : AppColors.retroDarkBorder,
                width: 1.5,
              ),
            ),
            child: Icon(Icons.arrow_back_ios_new_rounded, size: 14,
                color: isDark ? Colors.white : AppColors.retroDarkBorder),
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'ADMINISTRATIVE LOGS',
          style: TextStyle(
            color: isDark ? Colors.white : AppColors.retroDarkBorder,
            fontSize: 13,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.2,
          ),
        ),
      ),
      body: Center(
        child: Text(
          'No administrative logs recorded.',
          style: TextStyle(color: isDark ? Colors.white30 : Colors.black38, fontSize: 14),
        ),
      ),
    );
  }

  Widget _buildLogTile(Map<String, dynamic> log) {
    final type = log['type'] as String;
    
    IconData icon;
    Color iconColor;

    switch (type) {
      case 'config':
        icon = Icons.settings;
        iconColor = Colors.orangeAccent;
        break;
      case 'map':
        icon = Icons.map;
        iconColor = Colors.blueAccent;
        break;
      case 'alert':
        icon = Icons.campaign;
        iconColor = AppConstants.primaryRed;
        break;
      case 'user':
        icon = Icons.person_add;
        iconColor = Colors.greenAccent;
        break;
      default:
        icon = Icons.terminal;
        iconColor = Colors.white54;
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(color: iconColor.withOpacity(0.15), shape: BoxShape.circle),
          child: Icon(icon, color: iconColor, size: 20),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(log['action'], style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600)),
              const SizedBox(height: 4),
              Row(
                children: [
                  Text('By: ${log['user']}', style: const TextStyle(color: AppConstants.primaryRed, fontSize: 11, fontWeight: FontWeight.bold)),
                  const SizedBox(width: 12),
                  const Icon(Icons.circle, size: 4, color: Colors.white38),
                  const SizedBox(width: 12),
                  Text(DateFormat('MMM dd, hh:mm a').format(log['timestamp']), style: const TextStyle(color: Colors.white54, fontSize: 11)),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}
