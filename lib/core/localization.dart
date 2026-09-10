import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LanguageProvider extends ChangeNotifier {
  String _currentLanguage = 'English (US)';

  String get currentLanguage => _currentLanguage;

  LanguageProvider() {
    _loadLang();
  }

  Future<void> _loadLang() async {
    final prefs = await SharedPreferences.getInstance();
    String loaded = prefs.getString('config_language') ?? 'English (US)';
    if (!['English (US)', 'Filipino', 'Hiligaynon', 'Cebuano'].contains(loaded)) {
      loaded = 'English (US)';
    }
    _currentLanguage = loaded;
    notifyListeners();
  }

  Future<void> setLanguage(String lang) async {
    if (_currentLanguage == lang) return;
    _currentLanguage = lang;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('config_language', lang);
    notifyListeners();
  }
}

extension StringTranslateExtension on String {
  String tr(BuildContext context) {
    try {
      final lang = Provider.of<LanguageProvider>(context, listen: true).currentLanguage;
      return AppTranslations.translate(this, lang);
    } catch (e) {
      return this;
    }
  }
}

class AppTranslations {
  static String translate(String text, String lang) {
    if (lang == 'English (US)') return text;
    
    final map = _dictionary[text];
    if (map == null) return text; 
    
    return map[lang] ?? text;
  }

  static const Map<String, Map<String, String>> _dictionary = {
    // Config Screen
    'SYSTEM CONFIGURATION': {
      'Filipino': 'PAG-AAYOS NG SISTEMA',
      'Hiligaynon': 'PAG-AREGLO SANG SISTEMA',
      'Cebuano': 'PAG-AYO SA SISTEMA',
    },
    'General Settings': {
       'Filipino': 'Pangkalahatang Setting',
       'Hiligaynon': 'Kabilugan nga Setting',
       'Cebuano': 'Kinatibuk-ang Setting',
    },
    'Regional Language': {
       'Filipino': 'Wika',
       'Hiligaynon': 'Lenggwahe',
       'Cebuano': 'Pinulongan',
    },
    'Push Notifications': {
       'Filipino': 'Mga Abiso',
       'Hiligaynon': 'Mga Pahibalo',
       'Cebuano': 'Mga Pahibalo',
    },
    'Allow real-time critical alerts': {
       'Filipino': 'Payagan ang mga agarang alerto',
       'Hiligaynon': 'Tugutan ang madasig nga alerto',
       'Cebuano': 'Tugoti ang dinalian nga alerto',
    },
    'High Accuracy Tracking': {
       'Filipino': 'Mataas na Katumpakan',
       'Hiligaynon': 'Sibu nga Pagpadala',
       'Cebuano': 'Tukmang Pagsubay',
    },
    'Use GPS, Wi-Fi, and mobile networks': {
       'Filipino': 'Gumamit ng GPS, Wi-Fi, cellular',
       'Hiligaynon': 'Gamit ang GPS, Wi-Fi, cellular',
       'Cebuano': 'Paggamit sa GPS, Wi-Fi, cellular',
    },
    'Security & Broadcast': {
       'Filipino': 'Seguridad at Pag-broadcast',
       'Hiligaynon': 'Seguridad kag Pag-broadcast',
       'Cebuano': 'Seguridad ug Pag-sibya',
    },
    'SOS Verification': {
       'Filipino': 'Pagpapatunay ng SOS',
       'Hiligaynon': 'Pag-beripika sang SOS',
       'Cebuano': 'Pagpamatuod sa SOS',
    },
    'Fast': {'Filipino': 'Mabilis', 'Hiligaynon': 'Madasig', 'Cebuano': 'Paspas'},
    'Moderate': {'Filipino': 'Katamtaman', 'Hiligaynon': 'Husto-husto', 'Cebuano': 'Kasagaran'},
    'Strict': {'Filipino': 'Mahigpit', 'Hiligaynon': 'Strikto', 'Cebuano': 'Estrikto'},
    'Broadcast Radius': {
       'Filipino': 'Saklaw ng Broadcast',
       'Hiligaynon': 'Sakup sang Broadcast',
       'Cebuano': 'Hataas nga Sibya',
    },
    'Global': {'Filipino': 'Pandaigdigan', 'Hiligaynon': 'Globo', 'Cebuano': 'Kalibutanon'},
    'Auto-Log Sessions': {
       'Filipino': 'Awtomatikong Mag-log',
       'Hiligaynon': 'Kusa nga Pag-log',
       'Cebuano': 'Awtomatikong Pag-log',
    },
    'Automatically log system activities': {
       'Filipino': 'Awtomatikong i-record ang aksyon',
       'Hiligaynon': 'Kusa i-rekord ang aktibidad',
       'Cebuano': 'I-rekord ang mga kalihokan',
    },
    'System Metadata': {
       'Filipino': 'Impormasyon ng Sistema',
       'Hiligaynon': 'Impormasyon sang Sistema',
       'Cebuano': 'Impormasyon sa Sistema',
    },
    'System Version': {
       'Filipino': 'Bersyon ng Sistema',
       'Hiligaynon': 'Bersyon sang Sistema',
       'Cebuano': 'Bersyon sa Sistema',
    },
    'Last Update': {
       'Filipino': 'Huling Update',
       'Hiligaynon': 'Katapusan nga Update',
       'Cebuano': 'Katapusang Update',
    },
    'Server Status': {
       'Filipino': 'Status ng Server',
       'Hiligaynon': 'Istatus sang Server',
       'Cebuano': 'Estadu sa Server',
    },
    'Operational': {
       'Filipino': 'Gumagana',
       'Hiligaynon': 'Aktibo',
       'Cebuano': 'Nagapadagan',
    },
    'Reset to Defaults': {
       'Filipino': 'I-reset sa Default',
       'Hiligaynon': 'Ibalik sa Daan',
       'Cebuano': 'Ibalik sa Orihinal',
    },
    'All system configurations reset to default.': {
       'Filipino': 'Lahat ng config ay na-reset.',
       'Hiligaynon': 'Nabalik na ang tanan nga config.',
       'Cebuano': 'Na-reset nang tanan nga config.',
    },
    
    // Bottom Nav
    'Home': {'Filipino': 'Home', 'Hiligaynon': 'Panimalay', 'Cebuano': 'Balay'},
    'Safe Zone': {'Filipino': 'Ligtas na Lugar', 'Hiligaynon': 'Luwas nga Lugar', 'Cebuano': 'Luwas nga Lugar'},
    'Broadcast': {'Filipino': 'I-broadcast', 'Hiligaynon': 'Ipahibalo', 'Cebuano': 'I-sibya'},
    'Profile': {'Filipino': 'Profile', 'Hiligaynon': 'Profile', 'Cebuano': 'Profile'},
    'Dashboard': {'Filipino': 'Dashboard', 'Hiligaynon': 'Dashboard', 'Cebuano': 'Dashboard'},
    'Global Map': {'Filipino': 'Mapa', 'Hiligaynon': 'Mapa', 'Cebuano': 'Mapa'},
    'Config': {'Filipino': 'Mga Setting', 'Hiligaynon': 'Setting', 'Cebuano': 'Mga Setting'},
  };
}
