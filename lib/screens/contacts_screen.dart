import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../core/constants.dart';
import '../services/sms_service.dart';

class ContactsScreen extends StatefulWidget {
  const ContactsScreen({super.key});

  @override
  State<ContactsScreen> createState() => _ContactsScreenState();
}

class _ContactsScreenState extends State<ContactsScreen> {
  List<Map<String, String>> _personalContacts = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadContacts();
  }

  Future<void> _loadContacts() async {
    final contacts = await SMSService.getEmergencyContacts();
    setState(() {
      _personalContacts = contacts;
      _isLoading = false;
    });
  }

  Future<void> _saveContacts() async {
    await SMSService.saveEmergencyContacts(_personalContacts);
  }

  Future<void> _makePhoneCall(String phoneNumber) async {
    final Uri launchUri = Uri(
      scheme: 'tel',
      path: phoneNumber,
    );
    await launchUrl(launchUri);
  }

  void _addContact() {
    final nameController = TextEditingController();
    final phoneController = TextEditingController();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? AppConstants.surfaceDark : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text('Add Emergency Contact', style: TextStyle(fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: 'Name', hintText: 'e.g. Mom, Brother...'),
              textCapitalization: TextCapitalization.words,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: phoneController,
              decoration: const InputDecoration(labelText: 'Phone Number', hintText: '09XX XXX XXXX'),
              keyboardType: TextInputType.phone,
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('CANCEL')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppConstants.primaryRed, foregroundColor: Colors.white),
            onPressed: () {
              if (nameController.text.isNotEmpty && phoneController.text.isNotEmpty) {
                setState(() {
                  _personalContacts.add({
                    'name': nameController.text,
                    'number': phoneController.text,
                  });
                });
                _saveContacts();
                Navigator.pop(context);
              }
            },
            child: const Text('ADD CONTACT'),
          ),
        ],
      ),
    );
  }

  void _deleteContact(int index) {
     setState(() {
      _personalContacts.removeAt(index);
    });
    _saveContacts();
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
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : ListView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
            children: [
              _buildInfoNote(context),
              const SizedBox(height: 32),
              
              // PERSONAL CONTACTS Section
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                   _buildContactCategory(context, 'Primary Inner Circle'),
                   TextButton.icon(
                     onPressed: _addContact, 
                     icon: const Icon(Icons.add, size: 16, color: AppConstants.primaryRed),
                     label: const Text('ADD NEW', style: TextStyle(color: AppConstants.primaryRed, fontSize: 11, fontWeight: FontWeight.bold))
                   ),
                ],
              ),
              const SizedBox(height: 8),
              if (_personalContacts.isEmpty)
                _buildEmptyState(isDark)
              else
                ...List.generate(_personalContacts.length, (index) {
                   final contact = _personalContacts[index];
                   return _buildContactTile(
                     context, 
                     contact['name'] ?? 'Contact', 
                     contact['number'] ?? '', 
                     Icons.person_pin_rounded,
                     canDelete: true,
                     onDelete: () => _deleteContact(index),
                   );
                }),

              const SizedBox(height: 32),
              _buildContactCategory(context, 'City Responders (Direct Line)'),
              _buildContactTile(context, 'Cadiz City Disaster Office', '911', Icons.emergency_rounded),
              _buildContactTile(context, 'BFP Cadiz City', '034-493-0111', Icons.fire_truck_rounded),
              _buildContactTile(context, 'Cadiz City Police Station', '0998-598-6325', Icons.local_police_rounded),
              const SizedBox(height: 32),
              _buildContactCategory(context, 'Public Hospitals'),
              _buildContactTile(context, 'Cadiz District Hospital', '034-493-0101', Icons.local_hospital_rounded),
              _buildContactTile(context, 'Red Cross Cadiz', '034-712-1234', Icons.medical_services_rounded),
              const SizedBox(height: 40),
            ],
          ),
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.01) : Colors.black.withOpacity(0.01),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: (isDark ? Colors.white : Colors.black).withOpacity(0.05)),
      ),
      child: Column(
        children: [
          Icon(Icons.people_outline_rounded, color: isDark ? Colors.white12 : Colors.black12, size: 40),
          const SizedBox(height: 12),
          Text(
            'Keep your family close. Add contacts to your inner circle to auto-notify them during SOS.',
            textAlign: TextAlign.center,
            style: TextStyle(color: isDark ? Colors.white38 : Colors.black38, fontSize: 12),
          ),
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
          Icon(Icons.verified_user_rounded, color: AppConstants.primaryRed, size: 20),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              'Your inner circle will receive a direct location-link via SMS if you pull the SOS trigger.',
              style: TextStyle(color: AppConstants.primaryRed, fontSize: 11, fontWeight: FontWeight.bold),
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
          fontSize: 10,
          fontWeight: FontWeight.w900,
          color: isDark ? Colors.white38 : Colors.black38,
          letterSpacing: 1.5,
        ),
      ),
    );
  }

  Widget _buildContactTile(BuildContext context, String name, String number, IconData icon, {bool canDelete = false, VoidCallback? onDelete}) {
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
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (canDelete)
              IconButton(onPressed: onDelete, icon: Icon(Icons.delete_outline_rounded, color: Colors.grey.withOpacity(0.5))),
            Container(
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: IconButton(
                icon: const Icon(Icons.call, color: Colors.green, size: 20),
                onPressed: () => _makePhoneCall(number),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
