import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/constants.dart';

class SOSGestureSettingsScreen extends StatefulWidget {
  const SOSGestureSettingsScreen({super.key});

  @override
  State<SOSGestureSettingsScreen> createState() => _SOSGestureSettingsScreenState();
}

class _SOSGestureSettingsScreenState extends State<SOSGestureSettingsScreen> {
  String _selectedGesture = 'none';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPreference();
  }

  Future<void> _loadPreference() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _selectedGesture = prefs.getString('sos_gesture') ?? 'none';
      _isLoading = false;
    });
  }

  Future<void> _savePreference(String gesture) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('sos_gesture', gesture);
    setState(() {
      _selectedGesture = gesture;
    });
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('SOS Gesture updated to: ${gesture.replaceAll('_', ' ').toUpperCase()}'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppConstants.backgroundBlack : AppConstants.backgroundWhite,
      appBar: AppBar(
        title: const Text('SOS Gesture Settings', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : ListView(
            padding: const EdgeInsets.all(24),
            children: [
              _buildHeader(isDark),
              const SizedBox(height: 32),
              _buildGestureOption(
                id: 'triple_volume_up',
                title: 'Triple Click Volume Up',
                description: 'Press the Volume Up button 3 times in quick succession to trigger an SOS.',
                icon: Icons.volume_up,
                isDark: isDark,
              ),
              const SizedBox(height: 16),
              _buildGestureOption(
                id: 'long_press_volume_down',
                title: 'Long Press Volume Down',
                description: 'Hold the Volume Down button for 3 seconds to trigger an SOS.',
                icon: Icons.volume_down,
                isDark: isDark,
              ),
              const SizedBox(height: 16),
              _buildGestureOption(
                id: 'double_tap_screen',
                title: 'Double Tap Screen',
                description: 'Rapidly tap twice anywhere on the main app dashboard to trigger an SOS.',
                icon: Icons.touch_app_rounded,
                isDark: isDark,
              ),
              const SizedBox(height: 16),
              _buildGestureOption(
                id: 'none',
                title: 'No Gesture (Button Only)',
                description: 'Disable gesture triggers. SOS will only be sent via the in-app button.',
                icon: Icons.do_not_disturb_on_rounded,
                isDark: isDark,
              ),
              const SizedBox(height: 40),
              _buildIntegrityNote(isDark),
            ],
          ),
    );
  }

  Widget _buildHeader(bool isDark) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppConstants.primaryRed.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.gesture_rounded, color: AppConstants.primaryRed, size: 40),
        ),
        const SizedBox(height: 20),
        const Text(
          'Choose Your SOS Trigger',
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 12),
        Text(
          'These gestures work even when the screen is locked, using the accessibility services you authorized.',
          style: TextStyle(color: isDark ? Colors.white38 : Colors.black38, fontSize: 13),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildGestureOption({
    required String id,
    required String title,
    required String description,
    required IconData icon,
    required bool isDark,
  }) {
    final isSelected = _selectedGesture == id;
    final borderColor = isSelected ? AppConstants.primaryRed : (isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.05));

    return InkWell(
      onTap: () => _savePreference(id),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isDark ? (isSelected ? AppConstants.primaryRed.withOpacity(0.05) : const Color(0xFF1E2841)) : (isSelected ? AppConstants.primaryRed.withOpacity(0.02) : Colors.white),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: borderColor, width: isSelected ? 2 : 1),
          boxShadow: [
            if (isSelected) BoxShadow(color: AppConstants.primaryRed.withOpacity(0.1), blurRadius: 10)
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isSelected ? AppConstants.primaryRed : (isDark ? Colors.black26 : Colors.grey[100]),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: isSelected ? Colors.white : (isDark ? Colors.white70 : Colors.black54)),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: isDark ? Colors.white : Colors.black87,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: TextStyle(
                      color: isDark ? Colors.white38 : Colors.black38,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              const Icon(Icons.check_circle, color: AppConstants.primaryRed),
          ],
        ),
      ),
    );
  }

  Widget _buildIntegrityNote(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.02),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline, color: isDark ? Colors.white38 : Colors.black38),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              'To change these permissions, visit Device Settings > Accessibility > GIS Accessibility Service.',
              style: TextStyle(
                color: isDark ? Colors.white38 : Colors.black38,
                fontSize: 11,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
