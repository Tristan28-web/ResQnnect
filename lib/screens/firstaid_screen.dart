import 'package:flutter/material.dart';
import '../core/constants.dart';

class FirstAidScreen extends StatelessWidget {
  const FirstAidScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('First Aid & Safety')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildGuideCard(
            context,
            'CPR (Cardiopulmonary Resuscitation)',
            'Call emergency services immediately. Push hard and fast in the center of the chest...',
            Icons.favorite,
          ),
          _buildGuideCard(
            context,
            'Fire Safety',
            'Stop, Drop, and Roll. Crawl low under smoke. Have a fire escape plan...',
            Icons.local_fire_department,
          ),
          _buildGuideCard(
            context,
            'Earthquake Drill',
            'Drop, Cover, and Hold On. Stay away from windows and heavy furniture...',
            Icons.vibration,
          ),
          _buildGuideCard(
            context,
            'Flood Safety',
            'Avoid walking or driving through flood waters. Move to higher ground...',
            Icons.flood,
          ),
          _buildGuideCard(
            context,
            'First Aid Kit Essentials',
            'Bandages, antiseptic, scissors, gloves, fever medication...',
            Icons.medical_services,
          ),
        ],
      ),
    );
  }

  Widget _buildGuideCard(BuildContext context, String title, String description, IconData icon) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ExpansionTile(
        leading: Icon(icon, color: AppConstants.primaryRed, size: 32),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(description),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: () {},
                  child: const Text('Read Full Guide'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
