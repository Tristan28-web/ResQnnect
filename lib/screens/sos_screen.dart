import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../widgets/emergency_button.dart';
import '../services/firestore_service.dart';
import '../services/location_service.dart';
import '../models/sos_model.dart';
import '../core/constants.dart';
import '../services/sms_service.dart';

class SOSScreen extends StatefulWidget {
  const SOSScreen({super.key});

  @override
  State<SOSScreen> createState() => _SOSScreenState();
}

class _SOSScreenState extends State<SOSScreen> {
  bool _isSending = false;

  final TextEditingController _detailsController = TextEditingController();

  void _triggerSOS() async {
    final prefs = await SharedPreferences.getInstance();
    final sosVerification = prefs.getString('config_sos_verification') ?? 'Strict';

    // 1. First confirmation if needed
    if (sosVerification != 'Fast') {
      if (!mounted) return;
      final confirm = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E2841),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        elevation: 24,
        shadowColor: Colors.black,
          title: Text(
            sosVerification == 'Strict' ? 'CRITICAL CONFIRMATION' : 'Confirm SOS',
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          content: Text(
            sosVerification == 'Strict'
                ? 'Are you absolutely sure you want to broadcast a system-wide SOS? This will alert emergency authorities and LGU command immediately.'
                : 'Send SOS alert now? Help will be dispatched to your location.',
            style: const TextStyle(color: Colors.white70),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('CANCEL', style: TextStyle(color: Colors.white54)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppConstants.primaryRed,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () => Navigator.pop(context, true),
              child: const Text('CONFIRM', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
            ),
          ],
        ),
      );
      if (confirm != true) return;
    }

    // 2. Ask for details (Incident etc.)
    if (!mounted) return;
    final String? description = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E2841),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        elevation: 24,
        shadowColor: Colors.black,
        title: const Row(
          children: [
            Icon(Icons.description_outlined, color: AppConstants.primaryRed),
            SizedBox(width: 12),
            Text('Incident Details', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Briefly describe your emergency (optional):', style: TextStyle(color: Colors.white70, fontSize: 13)),
            const SizedBox(height: 16),
            TextField(
              controller: _detailsController,
              maxLines: 3,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'e.g., Medical emergency, House fire, Road accident...',
                hintStyle: TextStyle(color: Colors.white.withOpacity(0.3), fontSize: 14),
                filled: true,
                fillColor: Colors.white.withOpacity(0.05),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: AppConstants.primaryRed, width: 1)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              _detailsController.clear();
              Navigator.pop(context, "");
            },
            child: const Text('SKIP', style: TextStyle(color: Colors.white54, fontWeight: FontWeight.bold)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppConstants.primaryRed,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            onPressed: () => Navigator.pop(context, _detailsController.text),
            child: const Text('SEND SOS', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
          ),
        ],
      ),
    );

    if (description == null) return;

    setState(() => _isSending = true);
    
    final locationService = LocationService();
    final position = await locationService.getCurrentLocation();
    
    if (position != null) {
      final firestoreService = Provider.of<FirestoreService>(context, listen: false);
      final userId = FirebaseAuth.instance.currentUser?.uid ?? 'anonymous';
      
      final sos = SOSRequestModel(
        sosId: DateTime.now().millisecondsSinceEpoch.toString(),
        userId: userId,
        location: '${position.latitude}, ${position.longitude}',
        timestamp: DateTime.now(),
        status: 'active',
        description: description.isEmpty ? 'No details provided' : description,
      );
      
      await firestoreService.sendSOS(sos);
      
      // AUTO-SEND SMS TO PERSONAL CONTACTS 🌩️🚨✅
      final smsSent = await SMSService.sendEmergencyAlert(
        position.latitude, 
        position.longitude, 
        description.isEmpty ? 'SOS EMERGENCY SIGNALED' : description
      );

      _detailsController.clear();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(smsSent 
                ? 'SOS Alert Sent! LGU command and emergency contacts notified.' 
                : 'SOS Sent to Emergency Command. (Check SMS Permissions for contacts)'),
            backgroundColor: smsSent ? Colors.green : Colors.orange,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not get location. Check permissions.')),
      );
    }
    
    setState(() => _isSending = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Emergency SOS')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'IN CASE OF EMERGENCY',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            const Text(
              'Press the button below to send your\nlive location to emergency command.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 60),
            _isSending 
                ? const CircularProgressIndicator(color: AppConstants.primaryRed)
                : EmergencyButton(onTrigger: _triggerSOS),
            const SizedBox(height: 60),
            Card(
              margin: const EdgeInsets.symmetric(horizontal: 32),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              clipBehavior: Clip.antiAlias,
              child: Container(
                padding: const EdgeInsets.all(16.0),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF1E2841), Color(0xFF161E31)],
                  ),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.info_outline, color: AppConstants.primaryRed),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Your name, phone number, and location will be shared immediately.',
                        style: TextStyle(fontSize: 12, color: Colors.white70),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
