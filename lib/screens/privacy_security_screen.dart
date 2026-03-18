import 'package:flutter/material.dart';
import '../core/constants.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PrivacySecurityScreen extends StatefulWidget {
  const PrivacySecurityScreen({super.key});

  @override
  State<PrivacySecurityScreen> createState() => _PrivacySecurityScreenState();
}

class _PrivacySecurityScreenState extends State<PrivacySecurityScreen> {
  bool _shareLocation = true;
  bool _twoFactorAuth = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _shareLocation = prefs.getBool('privacy_share_loc') ?? true;
      _twoFactorAuth = prefs.getBool('security_2fa') ?? false;
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
        title: const Text('PRIVACY & SECURITY', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          _buildSectionHeader('Privacy'),
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
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Column(
              children: [
                _buildSwitchTile(
                  title: 'Location Sharing',
                  subtitle: 'Allow system to track your active location',
                  value: _shareLocation,
                  onChanged: (val) {
                    setState(() => _shareLocation = val);
                    _saveBool('privacy_share_loc', val);
                  },
                ),
                const Divider(color: Colors.white10),
                ListTile(
                  title: Text('Data Usage & Tracking', style: TextStyle(color: isDark ? Colors.white : Colors.black87, fontSize: 14, fontWeight: FontWeight.w600)),
                  subtitle: Text('Manage your data sharing preferences', style: TextStyle(color: isDark ? Colors.white54 : Colors.black54, fontSize: 12)),
                  trailing: Icon(Icons.chevron_right, color: isDark ? Colors.white54 : Colors.black38),
                  contentPadding: EdgeInsets.zero,
                  onTap: () {
                     ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Tracking preferences updated.')));
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          _buildSectionHeader('Security'),
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
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Column(
              children: [
                _buildSwitchTile(
                  title: 'Two-Factor Authentication',
                  subtitle: 'Add an extra layer of system security',
                  value: _twoFactorAuth,
                  onChanged: (val) {
                    setState(() => _twoFactorAuth = val);
                    _saveBool('security_2fa', val);
                  },
                ),
                Divider(color: isDark ? Colors.white10 : Colors.black12),
                ListTile(
                  title: Text('Change Password', style: TextStyle(color: isDark ? Colors.white : Colors.black87, fontSize: 14, fontWeight: FontWeight.w600)),
                  subtitle: Text('Update your account password', style: TextStyle(color: isDark ? Colors.white54 : Colors.black54, fontSize: 12)),
                  trailing: Icon(Icons.chevron_right, color: isDark ? Colors.white54 : Colors.black38),
                  contentPadding: EdgeInsets.zero,
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Password change request sent to email.')));
                  },
                ),
              ],
            ),
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
