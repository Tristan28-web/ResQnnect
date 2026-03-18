import 'package:flutter/material.dart';
import '../services/offline_vault_service.dart';
import '../models/map_location_model.dart';
import '../core/constants.dart';

class OfflineVaultScreen extends StatefulWidget {
  const OfflineVaultScreen({super.key});

  @override
  State<OfflineVaultScreen> createState() => _OfflineVaultScreenState();
}

class _OfflineVaultScreenState extends State<OfflineVaultScreen> {
  final OfflineVaultService _vaultService = OfflineVaultService();
  List<MapLocationModel> _cachedZones = [];
  List<Map<String, String>> _guides = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadOfflineData();
  }

  Future<void> _loadOfflineData() async {
    final zones = await _vaultService.getCachedSafeZones();
    final guides = await _vaultService.getCachedGuides();
    setState(() {
      _cachedZones = zones;
      _guides = guides;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('RESCUE VAULT', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1.5, fontSize: 16)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(color: Colors.orange.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
            child: const Row(
              children: [
                Icon(Icons.wifi_off_rounded, color: Colors.orangeAccent, size: 14),
                SizedBox(width: 6),
                Text('OFFLINE MODE', style: TextStyle(color: Colors.orangeAccent, fontSize: 10, fontWeight: FontWeight.bold)),
              ],
            ),
          )
        ],
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator(color: AppConstants.primaryRed))
        : SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSectionHeader(context, 'CRITICAL EMERGENCY GUIDES', Icons.medical_services_rounded),
                const SizedBox(height: 16),
                ..._guides.map((g) => _buildGuideTile(context, g)),
                const SizedBox(height: 32),
                _buildSectionHeader(context, 'CACHED SAFE ZONES', Icons.map_rounded),
                const SizedBox(height: 16),
                if (_cachedZones.isEmpty)
                  Text('No safe zones cached. Sync when online.', style: TextStyle(color: isDark ? Colors.white24 : Colors.black26, fontSize: 12))
                else
                  ..._cachedZones.map((z) => _buildSafeZoneTile(context, z)),
              ],
            ),
          ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title, IconData icon) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Row(
      children: [
        Icon(icon, color: AppConstants.primaryRed, size: 18),
        const SizedBox(width: 10),
        Text(title, style: TextStyle(color: isDark ? Colors.white38 : Colors.black45, fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 1)),
      ],
    );
  }

  Widget _buildGuideTile(BuildContext context, Map<String, String> guide) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: isDark ? const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1E2841), Color(0xFF161E31)],
        ) : null,
        color: isDark ? null : AppConstants.surfaceLight,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.05)),
        boxShadow: isDark ? [const BoxShadow(color: Colors.black26, blurRadius: 10, offset: Offset(0, 4))] : [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(guide['title'] ?? '', style: TextStyle(color: isDark ? Colors.white : Colors.black87, fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 8),
          Text(guide['instruction'] ?? '', style: TextStyle(color: isDark ? Colors.white60 : Colors.black54, fontSize: 13, height: 1.5)),
        ],
      ),
    );
  }

  Widget _buildSafeZoneTile(BuildContext context, MapLocationModel zone) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: isDark ? const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1E2841), Color(0xFF161E31)],
        ) : null,
        color: isDark ? null : AppConstants.surfaceLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.05)),
        boxShadow: isDark ? [const BoxShadow(color: Colors.black26, blurRadius: 10, offset: Offset(0, 4))] : [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Row(
        children: [
          const Icon(Icons.location_on, color: Colors.greenAccent, size: 20),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(zone.label, style: TextStyle(color: isDark ? Colors.white : Colors.black87, fontWeight: FontWeight.bold)),
                Text('${zone.latitude.toStringAsFixed(4)}, ${zone.longitude.toStringAsFixed(4)}', style: TextStyle(color: isDark ? Colors.white24 : Colors.black26, fontSize: 10)),
              ],
            ),
          ),
          Icon(Icons.save_rounded, color: isDark ? Colors.white10 : Colors.black12, size: 16),
        ],
      ),
    );
  }
}
