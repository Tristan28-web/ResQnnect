import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class SMSService {
  static const MethodChannel _smsChannel = MethodChannel('com.yummyjoy.resqnnect/sms');

  // Emergency contact model
  static Future<List<Map<String, String>>> getEmergencyContacts() async {
    final prefs = await SharedPreferences.getInstance();
    final String? contactsJson = prefs.getString('personal_emergency_contacts');
    if (contactsJson == null) return [];
    
    final List<dynamic> decoded = jsonDecode(contactsJson);
    return decoded.map((c) => Map<String, String>.from(c)).toList();
  }

  static Future<void> saveEmergencyContacts(List<Map<String, String>> contacts) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('personal_emergency_contacts', jsonEncode(contacts));
  }

  static Future<bool> sendEmergencyAlert(double lat, double lng, String description) async {
    // 1. Check/Request SMS Permissions
    var status = await Permission.sms.status;
    if (status.isDenied) {
      status = await Permission.sms.request();
    }
    
    if (!status.isGranted) return false;

    // 2. Get contacts
    final contacts = await getEmergencyContacts();
    if (contacts.isEmpty) return false;

    // 3. Prepare message
    // Google Maps Link for instant navigation
    final String locationLink = 'https://www.google.com/maps/search/?api=1&query=$lat,$lng';
    final String message = "🚨 GIS SOS: I am in danger! \n"
        "📍 My Location: $locationLink \n"
        "🆘 Details: $description";

    bool allSent = true;
    for (var contact in contacts) {
      String? phone = contact['number']?.trim();
      if (phone != null && phone.isNotEmpty) {
        // Normalize number for Philippines (+63)
        if (phone.startsWith('0')) {
          phone = '+63${phone.substring(1)}';
        } else if (phone.length == 10 && !phone.startsWith('+')) {
          phone = '+63$phone';
        }

        try {
          await _smsChannel.invokeMethod('sendSMS', {
            'phoneNumber': phone,
            'message': message,
          });
        } catch (e) {
          print('Native SMS Error for $phone: $e');
          allSent = false;
        }
      }
    }
    
    return allSent;
  }
}
