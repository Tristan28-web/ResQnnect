import 'package:flutter/material.dart';
import '../core/constants.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NotificationsSettingsScreen extends StatefulWidget {
  const NotificationsSettingsScreen({super.key});

  @override
  State<NotificationsSettingsScreen> createState() => _NotificationsSettingsScreenState();
}

class _NotificationsSettingsScreenState extends State<NotificationsSettingsScreen> {
  bool _pushNotifs = true;
  bool _emailNotifs = true;
  bool _smsNotifs = false;
  bool _soundEnabled = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _pushNotifs = prefs.getBool('config_push_notif') ?? true;
      _emailNotifs = prefs.getBool('notif_email') ?? true;
      _smsNotifs = prefs.getBool('notif_sms') ?? false;
      _soundEnabled = prefs.getBool('notif_sound') ?? true;
    });
  }

  Future<void> _saveBool(String key, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, value);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('NOTIFICATIONS', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          _buildSectionHeader('Alert Channels'),
          _buildSwitchTile(
            title: 'Push Notifications',
            subtitle: 'Receive real-time alerts on your device',
            value: _pushNotifs,
            onChanged: (val) {
              setState(() => _pushNotifs = val);
              _saveBool('config_push_notif', val);
            },
          ),
          const Divider(color: Colors.white10),
          _buildSwitchTile(
            title: 'Email Notifications',
            subtitle: 'Receive daily summaries & updates',
            value: _emailNotifs,
            onChanged: (val) {
              setState(() => _emailNotifs = val);
              _saveBool('notif_email', val);
            },
          ),
          const Divider(color: Colors.white10),
          _buildSwitchTile(
            title: 'SMS Alerts',
            subtitle: 'Receive vital alerts via text message',
            value: _smsNotifs,
            onChanged: (val) {
              setState(() => _smsNotifs = val);
              _saveBool('notif_sms', val);
            },
          ),
          const SizedBox(height: 32),
          _buildSectionHeader('Alert Preferences'),
          _buildSwitchTile(
            title: 'Sound',
            subtitle: 'Play sound for notifications',
            value: _soundEnabled,
            onChanged: (val) {
              setState(() => _soundEnabled = val);
              _saveBool('notif_sound', val);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Text(
        title.toUpperCase(),
        style: const TextStyle(color: AppConstants.primaryRed, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.2),
      ),
    );
  }

  Widget _buildSwitchTile({required String title, required String subtitle, required bool value, required ValueChanged<bool> onChanged}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return SwitchListTile(
      title: Text(title, style: TextStyle(color: isDark ? Colors.white : Colors.black87, fontSize: 14, fontWeight: FontWeight.w600)),
      subtitle: Text(subtitle, style: TextStyle(color: isDark ? Colors.white54 : Colors.black54, fontSize: 12)),
      value: value,
      onChanged: onChanged,
      activeColor: AppConstants.primaryRed,
      contentPadding: EdgeInsets.zero,
    );
  }
}
