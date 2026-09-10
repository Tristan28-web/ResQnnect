import 'package:flutter/material.dart';

class AppConstants {
  static const String appName = 'GIS';
  static const String logoAsset = 'assets/images/logo.png';
  
  // Colors
  static const Color primaryRed = Color(0xFFFF3B41); // Vibrant Red from image
  static const Color darkRed = Color(0xFF8B0000);   // Keep for dark accents
  static const Color emergencyRed = Color(0xFFD32F2F);
  static const Color backgroundBlack = Color(0xFF121212);
  static const Color surfaceDark = Color(0xFF1E2333); // Premium Dark Blue-Grey
  static const Color backgroundWhite = Color(0xFFF8F9FA);
  static const Color surfaceLight = Colors.white;
  static const Color accentBlue = Color(0xFF2196F3);
  static const Color warningAmber = Color(0xFFFFC107);
  
  // API Keys (Placeholders)
  static const String weatherApiKey = 'YOUR_WEATHER_API_KEY';
  static const String googleMapsApiKey = 'AIzaSyDScomUWZR0uMzReCG_t75caWDj4NgUdD4';
  
  // Collections
  static const String usersCollection = 'users';
  static const String alertsCollection = 'alerts';
  static const String incidentsCollection = 'incidents';
  static const String sosCollection = 'sos_requests';

  // Roles
  static const String roleAdmin = 'admin';
  static const String roleResponder = 'responder';
  static const String roleCitizen = 'citizen';
  static const String rolePNP = 'pnp'; // Philippine National Police (Crimes & Accidents)
  static const String roleBFP = 'bfp'; // Bureau of Fire Protection (Fire)
  static const String roleRescue = 'rescue'; // CDRRMO / Emergency Rescue (Floods, Disasters)

  // Blueprint Incident Types
  static const String incidentTypeFire = 'Fire';
  static const String incidentTypeFlood = 'Flood';
  static const String incidentTypeCrime = 'Crime';
  static const String incidentTypeAccident = 'Accident';
  static const String incidentTypeOther = 'Other';

  static const List<String> incidentTypes = [
    incidentTypeFire,
    incidentTypeFlood,
    incidentTypeCrime,
    incidentTypeAccident,
    incidentTypeOther,
  ];

  // Standard LGU Barangays (Cadiz City / LGU jurisdiction)
  static const List<String> lguBarangays = [
    'Brgy. Zone 1 (Poblacion)',
    'Brgy. Zone 2 (Poblacion)',
    'Brgy. Zone 3 (Poblacion)',
    'Brgy. Zone 4 (Poblacion)',
    'Brgy. Zone 5 (Poblacion)',
    'Brgy. Zone 6 (Poblacion)',
    'Brgy. Daga',
    'Brgy. Luna',
    'Brgy. Mabini',
    'Brgy. San Juan',
    'Brgy. Tinampaan',
    'Brgy. Sicaba',
    'Brgy. Burgos',
    'Brgy. Cabahug',
    'Brgy. Cadiz Viejo',
    'Brgy. Caduha-an',
    'Brgy. Celestino Villacin',
    'Brgy. Jerusalem',
    'Brgy. VF Gustilo',
    'Brgy. Magsaysay',
    'Brgy. Tiglawigan',
    'Brgy. Andres Bonifacio',
  ];
}
