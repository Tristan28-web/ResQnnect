import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/constants.dart';
import '../core/localization.dart';

class ConfigScreen extends StatefulWidget {
  const ConfigScreen({super.key});

  @override
  State<ConfigScreen> createState() => _ConfigScreenState();
}

class _ConfigScreenState extends State<ConfigScreen> {
  // General
  bool _pushNotifications = true;
  bool _highAccuracyLocation = true;

  // Security & Broadcast
  String _sosVerification = 'Strict';
  String _broadcastRadius = 'Global';
  bool _autoLogSessions = true;

  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _pushNotifications = prefs.getBool('config_push_notif') ?? true;
      _highAccuracyLocation = prefs.getBool('config_high_acc_loc') ?? true;
      
      _sosVerification = prefs.getString('config_sos_verification') ?? 'Strict';
      _broadcastRadius = prefs.getString('config_broadcast_radius') ?? 'Global';
      _autoLogSessions = prefs.getBool('config_auto_log') ?? true;
      _isLoading = false;
    });
  }

  Future<void> _saveBool(String key, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, value);
  }

  Future<void> _saveString(String key, String value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(key, value);
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: const Center(child: CircularProgressIndicator(color: AppConstants.primaryRed)),
      );
    }
    
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text('SYSTEM CONFIGURATION'.tr(context), style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          _buildConfigSection(context, 'General Settings'.tr(context), [
            _buildSwitchTile(
              context,
              icon: Icons.notifications_active,
              title: 'Push Notifications'.tr(context),
              subtitle: 'Allow real-time critical alerts'.tr(context),
              value: _pushNotifications,
              onChanged: (val) {
                setState(() => _pushNotifications = val);
                _saveBool('config_push_notif', val);
              },
            ),
            _buildDivider(context),
            _buildSwitchTile(
              context,
              icon: Icons.location_on,
              title: 'High Accuracy Tracking'.tr(context),
              subtitle: 'Use GPS, Wi-Fi, and mobile networks'.tr(context),
              value: _highAccuracyLocation,
              onChanged: (val) {
                setState(() => _highAccuracyLocation = val);
                _saveBool('config_high_acc_loc', val);
              },
            ),
          ]),
          const SizedBox(height: 32),
          _buildConfigSection(context, 'Security & Broadcast'.tr(context), [
            _buildDropdownTile(
              context: context,
              icon: Icons.security,
              title: 'SOS Verification'.tr(context),
              value: _sosVerification,
              items: const ['Fast', 'Moderate', 'Strict'],
              onChanged: (val) {
                if (val != null) {
                  setState(() => _sosVerification = val);
                  _saveString('config_sos_verification', val);
                }
              },
            ),
            _buildDivider(context),
            _buildDropdownTile(
              context: context,
              icon: Icons.broadcast_on_personal,
              title: 'Broadcast Radius'.tr(context),
              value: _broadcastRadius,
              items: const ['5 km', '10 km', '20 km', 'Global'],
              onChanged: (val) {
                if (val != null) {
                  setState(() => _broadcastRadius = val);
                  _saveString('config_broadcast_radius', val);
                }
              },
            ),
            _buildDivider(context),
            _buildSwitchTile(
              context,
              icon: Icons.history_rounded,
              title: 'Auto-Log Sessions'.tr(context),
              subtitle: 'Automatically log system activities'.tr(context),
              value: _autoLogSessions,
              onChanged: (val) {
                setState(() => _autoLogSessions = val);
                _saveBool('config_auto_log', val);
              },
            ),
          ]),
          const SizedBox(height: 32),
          _buildConfigSection(context, 'System Metadata'.tr(context), [
            _buildInfoTile(context, Icons.info_outline, 'System Version'.tr(context), 'v2.4.0-premium'),
            _buildDivider(context),
            _buildInfoTile(context, Icons.update, 'Last Update'.tr(context), 'Mar 15, 2026'),
            _buildDivider(context),
            _buildInfoTile(context, Icons.dns, 'Server Status'.tr(context), 'Operational'.tr(context), valueColor: Colors.greenAccent),
          ]),
          const SizedBox(height: 60),
          // Clear Preferences Button
          Center(
            child: TextButton.icon(
              onPressed: () async {
                final prefs = await SharedPreferences.getInstance();
                await prefs.clear();
                _loadSettings();
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('All system configurations reset to default.'.tr(context)),
                      backgroundColor: AppConstants.primaryRed,
                    ),
                  );
                }
              },
              icon: const Icon(Icons.restore, color: Colors.white38, size: 18),
              label: Text('Reset to Defaults'.tr(context), style: const TextStyle(color: Colors.white38)),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildConfigSection(BuildContext context, String title, List<Widget> children) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 16, bottom: 12),
          child: Text(
            title.toUpperCase(),
            style: TextStyle(color: isDark ? Colors.white38 : Colors.black38, fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 1.5),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            gradient: isDark ? const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF1E2841), Color(0xFF161E31)],
            ) : null,
            color: isDark ? null : Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.05)),
            boxShadow: isDark 
                ? [const BoxShadow(color: Colors.black45, blurRadius: 10, offset: Offset(0, 4))] 
                : [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4))],
          ),
          child: Column(children: children),
        ),
      ],
    );
  }

  Widget _buildDivider(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Divider(color: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.05), height: 1, indent: 64, endIndent: 20);
  }

  Widget _buildSwitchTile(BuildContext context, {required IconData icon, required String title, required String subtitle, required bool value, required Function(bool) onChanged}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return SwitchListTile(
      value: value,
      onChanged: onChanged,
      activeColor: AppConstants.primaryRed,
      secondary: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(color: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.05), borderRadius: BorderRadius.circular(10)),
        child: Icon(icon, color: isDark ? Colors.white70 : Colors.black54, size: 20),
      ),
      title: Text(title, style: TextStyle(color: isDark ? Colors.white : Colors.black87, fontWeight: FontWeight.bold, fontSize: 15)),
      subtitle: Text(subtitle, style: TextStyle(color: isDark ? Colors.white54 : Colors.black54, fontSize: 12)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
    );
  }

  Widget _buildDropdownTile({required BuildContext context, required IconData icon, required String title, required String value, required List<String> items, required Function(String?) onChanged}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.05), borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, color: isDark ? Colors.white70 : Colors.black54, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(title, style: TextStyle(color: isDark ? Colors.white : Colors.black87, fontWeight: FontWeight.bold, fontSize: 15)),
          ),
          DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: value,
              dropdownColor: isDark ? AppConstants.surfaceDark : Colors.white,
              icon: Icon(Icons.arrow_drop_down, color: isDark ? Colors.white38 : Colors.black38),
              style: TextStyle(color: isDark ? Colors.white70 : Colors.black87, fontSize: 14, fontWeight: FontWeight.w600),
              items: items.map((i) => DropdownMenuItem(value: i, child: Text(i.tr(context)))).toList(),
              onChanged: onChanged,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoTile(BuildContext context, IconData icon, String title, String value, {Color? valueColor}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(color: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.05), shape: BoxShape.circle),
        child: Icon(icon, color: isDark ? Colors.white70 : Colors.black54, size: 20),
      ),
      title: Text(title, style: TextStyle(color: isDark ? Colors.white : Colors.black87, fontSize: 13, fontWeight: FontWeight.bold)),
      trailing: Text(value, style: TextStyle(color: valueColor ?? (isDark ? Colors.white70 : Colors.black87), fontSize: 13, fontWeight: FontWeight.bold)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
    );
  }
}
