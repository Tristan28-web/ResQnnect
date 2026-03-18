import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../core/constants.dart';

class ContactsScreen extends StatelessWidget {
  const ContactsScreen({super.key});

  Future<void> _makePhoneCall(String phoneNumber) async {
    final Uri launchUri = Uri(
      scheme: 'tel',
      path: phoneNumber,
    );
    await launchUrl(launchUri);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text('EMERGENCY CONTACTS', style: TextStyle(color: isDark ? Colors.white : Colors.black87, fontSize: 13, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
        children: [
          _buildInfoNote(context),
          const SizedBox(height: 24),
          _buildContactCategory(context, 'City Contacts'),
          _buildContactTile(context, 'Cadiz City Disaster Office', '911', Icons.emergency_rounded),
          _buildContactTile(context, 'BFP Cadiz City', '034-493-0111', Icons.fire_truck_rounded),
          _buildContactTile(context, 'Cadiz City Police Station', '0998-598-6325', Icons.local_police_rounded),
          const SizedBox(height: 32),
          _buildContactCategory(context, 'Medical Facilities'),
          _buildContactTile(context, 'Cadiz District Hospital', '034-493-0101', Icons.local_hospital_rounded),
          _buildContactTile(context, 'Red Cross Cadiz', '034-712-1234', Icons.medical_services_rounded),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildInfoNote(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppConstants.primaryRed.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppConstants.primaryRed.withOpacity(0.1)),
      ),
      child: const Row(
        children: [
          Icon(Icons.info_outline, color: AppConstants.primaryRed, size: 20),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              'All calls made through this screen are high-priority emergency requests.',
              style: TextStyle(color: AppConstants.primaryRed, fontSize: 12, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactCategory(BuildContext context, String title) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0, left: 4),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w900,
          color: isDark ? Colors.white38 : Colors.black38,
          letterSpacing: 1.5,
        ),
      ),
    );
  }

  Widget _buildContactTile(BuildContext context, String name, String number, IconData icon) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        gradient: isDark ? const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1E2841), Color(0xFF161E31)],
        ) : null,
        color: isDark ? null : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: (isDark ? Colors.white : Colors.black).withOpacity(0.05)),
        boxShadow: isDark 
            ? [const BoxShadow(color: Colors.black45, blurRadius: 10, offset: Offset(0, 4))] 
            : [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AppConstants.primaryRed.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: AppConstants.primaryRed, size: 20),
        ),
        title: Text(name, style: TextStyle(color: isDark ? Colors.white : Colors.black87, fontWeight: FontWeight.bold, fontSize: 16)),
        subtitle: Text(number, style: TextStyle(color: isDark ? Colors.white38 : Colors.black54, fontSize: 14)),
        trailing: Container(
          decoration: BoxDecoration(
            color: Colors.green.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: IconButton(
            icon: const Icon(Icons.call, color: Colors.green, size: 20),
            onPressed: () => _makePhoneCall(number),
          ),
        ),
      ),
    );
  }
}
