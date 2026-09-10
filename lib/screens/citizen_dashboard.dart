import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../core/constants.dart';
import 'report_screen.dart';
import '../models/incident_model.dart';
import 'alerts_screen.dart';
import 'incident_mapping_screen.dart';
import 'hotspot_identification_screen.dart';
import '../models/alert_model.dart';
import '../services/firestore_service.dart';
import 'package:intl/intl.dart';
import '../services/alert_notification_service.dart';
import '../services/location_service.dart';

class CitizenDashboard extends StatefulWidget {
  const CitizenDashboard({super.key});

  @override
  State<CitizenDashboard> createState() => _CitizenDashboardState();
}

class _CitizenDashboardState extends State<CitizenDashboard> {
  int _lastAlertCount = 0;
  final Set<String> _notifiedIncidentIds = {};
  String _searchQuery = '';
  String _selectedCategory = 'All';
  String _selectedLgu = 'All';
  String _selectedSeverity = 'All';
  String _selectedStatus = 'All';

  bool get _hasActiveFilters =>
      _selectedCategory != 'All' ||
      _selectedLgu != 'All' ||
      _selectedSeverity != 'All' ||
      _selectedStatus != 'All';

  void _resetFilters() {
    setState(() {
      _selectedCategory = 'All';
      _selectedLgu = 'All';
      _selectedSeverity = 'All';
      _selectedStatus = 'All';
    });
  }

  @override
  void initState() {
    super.initState();
    final firestore = Provider.of<FirestoreService>(context, listen: false);
    firestore.getAlertCount().first.then((count) {
      if (mounted) _lastAlertCount = count;
    });
  }

  void _triggerEmergencyFlash() {
    AlertNotificationService.instance.flashAlert();
  }

  @override
  Widget build(BuildContext context) {
    final firestoreService = Provider.of<FirestoreService>(context, listen: false);
    final userId = FirebaseAuth.instance.currentUser?.uid ?? '';

    return StreamProvider<int>(
      create: (_) => firestoreService.getAlertCount(),
      initialData: 0,
      builder: (context, child) {
        final alertCount = Provider.of<int>(context);

        // Flash screen if new alerts are published
        if (alertCount > _lastAlertCount) {
          _lastAlertCount = alertCount;
          WidgetsBinding.instance.addPostFrameCallback((_) => _triggerEmergencyFlash());
        }

        // Check for report status updates (e.g. dispatched)
        _checkForAcceptedReports(context, firestoreService, userId);

        return SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),
              _buildRetroSearchBar(context),
              const SizedBox(height: 20),
              _buildLguHeroCard(context),
              const SizedBox(height: 24),
              _buildActionGrid(context),
              const SizedBox(height: 28),
              _buildRetroCategoryDiscs(context),
              const SizedBox(height: 16),
              _buildMyReports(context),
              const SizedBox(height: 32),
              _buildLiveUpdates(context),
              const SizedBox(height: 110),
            ],
          ),
        );
      },
    );
  }

  // --- RETRO PILL SEARCH & FILTER BAR ---
  Widget _buildRetroSearchBar(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      height: 52,
      padding: const EdgeInsets.only(left: 16, right: 6),
      decoration: BoxDecoration(
        color: isDark ? AppColors.retroDarkCard : Colors.white,
        borderRadius: BorderRadius.circular(30),
        border: Border.all(
          color: isDark ? const Color(0xFF3E4556) : AppColors.retroDarkBorder,
          width: 1.8,
        ),
        boxShadow: [
          BoxShadow(
            color: isDark ? Colors.black38 : AppColors.retroDarkBorder.withOpacity(0.12),
            offset: const Offset(2, 2),
            blurRadius: 0,
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(
            Icons.search_rounded,
            color: isDark ? Colors.white60 : AppColors.retroDarkBorder,
            size: 22,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              onChanged: (val) {
                setState(() {
                  _searchQuery = val.trim().toLowerCase();
                });
              },
              style: TextStyle(
                color: isDark ? Colors.white : AppColors.retroDarkBorder,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
              decoration: InputDecoration(
                hintText: 'Search incidents, hazards, alerts...',
                hintStyle: TextStyle(
                  color: isDark ? Colors.white38 : Colors.black38,
                  fontSize: 13,
                  fontWeight: FontWeight.normal,
                ),
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ),
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: _hasActiveFilters ? AppColors.retroMintDark : AppColors.retroMint,
              shape: BoxShape.circle,
              border: Border.all(
                color: AppColors.retroDarkBorder,
                width: 1.6,
              ),
              boxShadow: const [
                BoxShadow(
                  color: AppColors.retroDarkBorder,
                  offset: Offset(2, 2),
                  blurRadius: 0,
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(20),
                onTap: () => _showFilterBottomSheet(context),
                child: const Icon(
                  Icons.tune_rounded,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- RETRO PEACH HERO BANNER WITH OFFSET SHADOW ---
  Widget _buildLguHeroCard(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final firestore = Provider.of<FirestoreService>(context, listen: false);
    final locationService = Provider.of<LocationService>(context);
    final locName = locationService.currentLocationName;
    final currentArea = locName.contains(',') ? locName.split(',')[0].trim() : locName;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2B2421) : AppColors.retroPeach,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(
          color: isDark ? const Color(0xFF4A3C38) : AppColors.retroDarkBorder,
          width: 2.0,
        ),
        boxShadow: [
          BoxShadow(
            color: isDark ? Colors.black45 : AppColors.retroMintDark,
            offset: const Offset(4, 4),
            blurRadius: 0,
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.black38 : Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isDark ? Colors.white24 : AppColors.retroDarkBorder,
                      width: 1.5,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 7,
                        height: 7,
                        decoration: const BoxDecoration(
                          color: Color(0xFF22C55E),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        currentArea.isNotEmpty ? '${currentArea.toUpperCase()} GIS LIVE' : 'GIS LIVE',
                        style: TextStyle(
                          color: isDark ? Colors.white : AppColors.retroDarkBorder,
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.0,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.retroLilac,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: AppColors.retroDarkBorder,
                      width: 1.4,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.place_rounded, size: 11, color: AppColors.retroDarkBorder),
                      const SizedBox(width: 4),
                      Text(
                        currentArea.isNotEmpty ? currentArea : 'Detected',
                        style: const TextStyle(
                          color: AppColors.retroDarkBorder,
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              'Incident Mapping &\nPredictive Logic',
              style: TextStyle(
                color: isDark ? Colors.white : AppColors.retroDarkBorder,
                fontSize: 23,
                fontWeight: FontWeight.w900,
                height: 1.15,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Real-time geo-pinned incident reporting, hazard alerts, and emergency response in $currentArea.',
              style: TextStyle(
                color: isDark ? Colors.white70 : const Color(0xFF555B66),
                fontSize: 12,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const IncidentMappingScreen()),
                    );
                  },
                  icon: const Icon(Icons.explore_rounded, size: 16),
                  label: const Text(
                    'Explore Live Map',
                    style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.retroLilac,
                    foregroundColor: AppColors.retroDarkBorder,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                      side: const BorderSide(color: AppColors.retroDarkBorder, width: 1.6),
                    ),
                  ),
                ),
                const Spacer(),
                StreamBuilder<List<IncidentModel>>(
                  stream: firestore.getIncidents(),
                  builder: (context, snapshot) {
                    final incidents = snapshot.data ?? [];
                    final ongoing = incidents.where((i) => i.status != 'resolved' && i.status != 'closed').length;
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: isDark ? Colors.black38 : Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isDark ? Colors.white24 : AppColors.retroDarkBorder,
                          width: 1.4,
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.flash_on_rounded, color: Color(0xFFF59E0B), size: 16),
                          const SizedBox(width: 4),
                          Text(
                            '$ongoing Active',
                            style: TextStyle(
                              color: isDark ? Colors.white : AppColors.retroDarkBorder,
                              fontWeight: FontWeight.w900,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // --- RETRO CIRCULAR CATEGORY BADGES ---
  Widget _buildRetroCategoryDiscs(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final categories = [
      {'name': 'All', 'icon': Icons.apps_rounded, 'color': AppColors.retroMint},
      {'name': 'Fire', 'icon': Icons.local_fire_department_rounded, 'color': const Color(0xFFEF4444)},
      {'name': 'Flood', 'icon': Icons.water_drop_rounded, 'color': const Color(0xFF3B82F6)},
      {'name': 'Medical', 'icon': Icons.medical_services_rounded, 'color': const Color(0xFF10B981)},
      {'name': 'Accident', 'icon': Icons.car_crash_rounded, 'color': const Color(0xFFF97316)},
      {'name': 'Hotspot', 'icon': Icons.whatshot_rounded, 'color': const Color(0xFF8B5CF6)},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'INCIDENT CATEGORIES',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.3,
                color: isDark ? Colors.white60 : const Color(0xFF6B7280),
              ),
            ),
            GestureDetector(
              onTap: () => _showFilterBottomSheet(context),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: _hasActiveFilters ? AppColors.retroMint : AppColors.retroMintLight,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.retroDarkBorder, width: 1.4),
                  boxShadow: const [
                    BoxShadow(
                      color: AppColors.retroDarkBorder,
                      offset: Offset(1.5, 1.5),
                      blurRadius: 0,
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.tune_rounded,
                      size: 12,
                      color: _hasActiveFilters ? Colors.white : AppColors.retroDarkBorder,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Filter view',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                        color: _hasActiveFilters ? Colors.white : AppColors.retroDarkBorder,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 82,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: categories.length,
            separatorBuilder: (_, index) => const SizedBox(width: 14),
            itemBuilder: (context, index) {
              final cat = categories[index];
              final name = cat['name'] as String;
              final icon = cat['icon'] as IconData;
              final iconColor = cat['color'] as Color;
              final isSelected = _selectedCategory == name;

              return GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedCategory = name;
                  });
                  if (name == 'Hotspot') {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const HotspotIdentificationScreen()),
                    );
                  }
                },
                child: Column(
                  children: [
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppColors.retroMint
                            : (isDark ? AppColors.retroDarkCard : Colors.white),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isSelected
                              ? AppColors.retroDarkBorder
                              : (isDark ? const Color(0xFF3E4556) : AppColors.retroDarkBorder),
                          width: 1.8,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: isDark ? Colors.black38 : AppColors.retroDarkBorder.withOpacity(0.12),
                            offset: const Offset(2, 2),
                            blurRadius: 0,
                          ),
                        ],
                      ),
                      child: Center(
                        child: Icon(
                          icon,
                          color: isSelected
                              ? Colors.white
                              : (isDark ? Colors.white : iconColor),
                          size: 24,
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      name,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: isSelected ? FontWeight.w900 : FontWeight.w700,
                        color: isSelected
                            ? AppColors.retroMint
                            : (isDark ? Colors.white70 : AppColors.retroDarkBorder),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
        if (_hasActiveFilters) ...[
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF2B2421) : AppColors.retroPeach,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isDark ? const Color(0xFF4A3C38) : AppColors.retroDarkBorder,
                width: 1.4,
              ),
            ),
            child: Row(
              children: [
                const Icon(Icons.filter_list_rounded, size: 15, color: AppColors.retroMintDark),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Active: '
                    '${_selectedCategory != 'All' ? 'Cat: $_selectedCategory • ' : ''}'
                    '${_selectedLgu != 'All' ? 'LGU: $_selectedLgu • ' : ''}'
                    '${_selectedSeverity != 'All' ? 'Sev: $_selectedSeverity • ' : ''}'
                    '${_selectedStatus != 'All' ? 'Status: $_selectedStatus' : ''}',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: isDark ? Colors.white70 : AppColors.retroDarkBorder,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                GestureDetector(
                  onTap: _resetFilters,
                  child: Container(
                    padding: const EdgeInsets.all(3),
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white12 : Colors.white,
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.retroDarkBorder, width: 1.2),
                    ),
                    child: const Icon(Icons.close_rounded, size: 12, color: AppColors.retroDarkBorder),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  // --- RETRO ACTION SERVICES GRID ---
  Widget _buildActionGrid(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'GIS ACTION SERVICES',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.3,
            color: isDark ? Colors.white60 : const Color(0xFF6B7280),
          ),
        ),
        const SizedBox(height: 14),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          crossAxisSpacing: 14,
          mainAxisSpacing: 14,
          childAspectRatio: 1.15,
          children: [
            _buildRetroActionCard(
              context: context,
              title: 'Report Incident',
              subtitle: 'Pin & submit evidence',
              icon: Icons.add_location_alt_rounded,
              accentColor: AppColors.retroPeach,
              iconColor: const Color(0xFFE11D48),
              screen: const ReportScreen(),
            ),
            _buildRetroActionCard(
              context: context,
              title: 'Incident Map',
              subtitle: 'Live interactive pins',
              icon: Icons.map_rounded,
              accentColor: AppColors.retroLilac,
              iconColor: const Color(0xFF2563EB),
              screen: const IncidentMappingScreen(),
            ),
            _buildRetroActionCard(
              context: context,
              title: 'Hotspot Heatmap',
              subtitle: 'High-risk hazard zones',
              icon: Icons.whatshot_rounded,
              accentColor: AppColors.retroPeach,
              iconColor: const Color(0xFFEA580C),
              screen: const HotspotIdentificationScreen(),
            ),
            _buildRetroActionCard(
              context: context,
              title: 'LGU Alerts',
              subtitle: 'Public emergency feeds',
              icon: Icons.notifications_active_rounded,
              accentColor: AppColors.retroLilac,
              iconColor: const Color(0xFF7C3AED),
              screen: const AlertsScreen(),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildRetroActionCard({
    required BuildContext context,
    required String title,
    required String subtitle,
    required IconData icon,
    required Color accentColor,
    required Color iconColor,
    required Widget screen,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => screen)),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? AppColors.retroDarkCard : Colors.white,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: isDark ? const Color(0xFF3E4556) : AppColors.retroDarkBorder,
            width: 1.8,
          ),
          boxShadow: [
            BoxShadow(
              color: isDark ? Colors.black45 : AppColors.retroDarkBorder.withOpacity(0.12),
              offset: const Offset(3, 3),
              blurRadius: 0,
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF2C3240) : accentColor,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isDark ? Colors.white12 : AppColors.retroDarkBorder,
                  width: 1.4,
                ),
              ),
              child: Icon(icon, color: isDark ? Colors.white : iconColor, size: 22),
            ),
            const SizedBox(height: 8),
            Flexible(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: isDark ? Colors.white : AppColors.retroDarkBorder,
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: isDark ? Colors.white54 : const Color(0xFF6B7280),
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- RETRO MY REPORTS ---
  Widget _buildMyReports(BuildContext context) {
    final firestoreService = Provider.of<FirestoreService>(context, listen: false);
    final userId = FirebaseAuth.instance.currentUser?.uid ?? '';
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'My Incident Reports',
              style: TextStyle(
                color: isDark ? Colors.white : AppColors.retroDarkBorder,
                fontSize: 18,
                fontWeight: FontWeight.w900,
              ),
            ),
            ElevatedButton.icon(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ReportScreen()),
              ),
              icon: const Icon(Icons.add_rounded, size: 14),
              label: const Text('New Report', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800)),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.retroMint,
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: const BorderSide(color: AppColors.retroDarkBorder, width: 1.4),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        StreamBuilder<List<IncidentModel>>(
          stream: firestoreService.getIncidents(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) return const SizedBox.shrink();

            var myReports = snapshot.data!
                .where((i) => i.userId == userId)
                .toList();

            if (_selectedCategory != 'All' && _selectedCategory != 'Hotspot') {
              myReports = myReports
                  .where((i) => i.incidentType.toLowerCase().contains(_selectedCategory.toLowerCase()))
                  .toList();
            }

            if (_selectedLgu != 'All') {
              myReports = myReports
                  .where((i) =>
                      i.barangay.toLowerCase().contains(_selectedLgu.toLowerCase()) ||
                      i.location.toLowerCase().contains(_selectedLgu.toLowerCase()))
                  .toList();
            }

            if (_selectedSeverity != 'All') {
              myReports = myReports
                  .where((i) => i.severity.toLowerCase() == _selectedSeverity.toLowerCase())
                  .toList();
            }

            if (_selectedStatus != 'All') {
              myReports = myReports
                  .where((i) => i.status.toLowerCase() == _selectedStatus.toLowerCase())
                  .toList();
            }

            if (_searchQuery.isNotEmpty) {
              myReports = myReports
                  .where((i) =>
                      i.description.toLowerCase().contains(_searchQuery) ||
                      i.location.toLowerCase().contains(_searchQuery) ||
                      i.incidentType.toLowerCase().contains(_searchQuery))
                  .toList();
            }

            if (myReports.isEmpty) {
              return Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.retroDarkCard : Colors.white,
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(
                    color: isDark ? const Color(0xFF3E4556) : AppColors.retroDarkBorder,
                    width: 1.6,
                  ),
                ),
                child: Column(
                  children: [
                    Icon(
                      Icons.assignment_turned_in_outlined,
                      color: isDark ? Colors.white24 : Colors.black26,
                      size: 36,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'No incident reports match your filter.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: isDark ? Colors.white54 : Colors.black54,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              );
            }

            return Column(
              children: myReports.take(3).map((incident) => _buildMyReportItem(context, incident)).toList(),
            );
          },
        ),
      ],
    );
  }

  Widget _buildMyReportItem(BuildContext context, IncidentModel incident) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    Color statusBg = AppColors.retroPeach;
    Color statusText = const Color(0xFFD97706);
    String statusLabel = 'PENDING';

    if (incident.status == 'dispatched') {
      statusBg = AppColors.retroLilac;
      statusText = const Color(0xFF2563EB);
      statusLabel = 'DISPATCHED';
    } else if (incident.status == 'resolved') {
      statusBg = const Color(0xFFDCFCE7);
      statusText = const Color(0xFF16A34A);
      statusLabel = 'RESOLVED';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.retroDarkCard : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? const Color(0xFF3E4556) : AppColors.retroDarkBorder,
          width: 1.6,
        ),
        boxShadow: [
          BoxShadow(
            color: isDark ? Colors.black38 : AppColors.retroDarkBorder.withOpacity(0.08),
            offset: const Offset(2, 2),
            blurRadius: 0,
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: statusBg,
              shape: BoxShape.circle,
              border: Border.all(
                color: AppColors.retroDarkBorder,
                width: 1.4,
              ),
            ),
            child: Icon(
              incident.status == 'dispatched'
                  ? Icons.local_shipping_rounded
                  : (incident.status == 'resolved' ? Icons.check_circle_rounded : Icons.pending_actions_rounded),
              color: statusText,
              size: 20,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  incident.description,
                  style: TextStyle(
                    color: isDark ? Colors.white : AppColors.retroDarkBorder,
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 3),
                Row(
                  children: [
                    Icon(Icons.pin_drop_rounded, size: 12, color: isDark ? Colors.white38 : Colors.black45),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        incident.location,
                        style: TextStyle(
                          color: isDark ? Colors.white38 : const Color(0xFF6B7280),
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: statusBg,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: AppColors.retroDarkBorder,
                      width: 1.2,
                    ),
                  ),
                  child: Text(
                    statusLabel,
                    style: TextStyle(
                      color: statusText,
                      fontSize: 9,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Icon(Icons.chevron_right_rounded, color: isDark ? Colors.white30 : AppColors.retroDarkBorder),
        ],
      ),
    );
  }

  // --- RETRO LGU ADVISORIES & ALERTS ---
  Widget _buildLiveUpdates(BuildContext context) {
    final firestoreService = Provider.of<FirestoreService>(context, listen: false);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'LGU Advisories & Alerts',
              style: TextStyle(
                color: isDark ? Colors.white : AppColors.retroDarkBorder,
                fontSize: 18,
                fontWeight: FontWeight.w900,
              ),
            ),
            TextButton(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AlertsScreen()),
              ),
              child: Text(
                'View all',
                style: TextStyle(
                  color: AppColors.retroMint,
                  fontWeight: FontWeight.w900,
                  fontSize: 13,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        StreamBuilder<List<AlertModel>>(
          stream: firestoreService.getAlerts(),
          builder: (context, snapshot) {
            if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  child: Text(
                    'No active advisories at this time.',
                    style: TextStyle(
                      color: isDark ? Colors.white38 : Colors.black38,
                      fontSize: 13,
                    ),
                  ),
                ),
              );
            }

            final alerts = snapshot.data!.take(3).toList();
            return Column(
              children: alerts.map((alert) => _buildRetroAlertItem(context, alert)).toList(),
            );
          },
        ),
      ],
    );
  }

  Widget _buildRetroAlertItem(BuildContext context, AlertModel alert) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isCritical = alert.disasterType == 'Critical';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.retroDarkCard : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? const Color(0xFF3E4556) : AppColors.retroDarkBorder,
          width: 1.6,
        ),
        boxShadow: [
          BoxShadow(
            color: isDark ? Colors.black38 : AppColors.retroDarkBorder.withOpacity(0.08),
            offset: const Offset(2, 2),
            blurRadius: 0,
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: isCritical ? AppColors.retroPeach : AppColors.retroLilac,
              shape: BoxShape.circle,
              border: Border.all(
                color: AppColors.retroDarkBorder,
                width: 1.4,
              ),
            ),
            child: Icon(
              isCritical ? Icons.warning_rounded : Icons.campaign_rounded,
              color: isCritical ? const Color(0xFFEF4444) : const Color(0xFF7C3AED),
              size: 20,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  alert.title,
                  style: TextStyle(
                    color: isDark ? Colors.white : AppColors.retroDarkBorder,
                    fontWeight: FontWeight.w900,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  alert.description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: isDark ? Colors.white60 : const Color(0xFF555B66),
                    fontSize: 11,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            DateFormat('h:mm a').format(alert.createdAt),
            style: TextStyle(
              color: isDark ? Colors.white30 : const Color(0xFF888E99),
              fontSize: 10,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  void _checkForAcceptedReports(BuildContext context, FirestoreService firestore, String userId) {
    firestore.getIncidents().listen((incidents) {
      if (!mounted) return;
      for (var inc in incidents) {
        if (inc.userId == userId && inc.status == 'dispatched' && !_notifiedIncidentIds.contains(inc.incidentId)) {
          _notifiedIncidentIds.add(inc.incidentId);
          _showReportAcceptedDialog(context, inc);
        }
      }
    });
  }

  void _showReportAcceptedDialog(BuildContext context, IncidentModel inc) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? AppColors.retroDarkCard : Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: const BorderSide(color: AppColors.retroDarkBorder, width: 2),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: const BoxDecoration(
                color: Color(0xFFDCFCE7),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check_circle, color: Color(0xFF16A34A), size: 24),
            ),
            const SizedBox(width: 12),
            const Text(
              'Report Accepted',
              style: TextStyle(fontWeight: FontWeight.w900, color: AppColors.retroDarkBorder),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Your incident report has been verified by LGU Catanduanes and emergency responders are dispatched to your pinned location.',
              style: TextStyle(color: isDark ? Colors.white70 : Colors.black87, fontSize: 13, height: 1.4),
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.retroPeach,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.retroDarkBorder, width: 1.4),
              ),
              child: const Row(
                children: [
                  Icon(Icons.timer_outlined, color: AppColors.retroDarkBorder),
                  SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'EST. RESPONSE TIME',
                        style: TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: AppColors.retroDarkBorder),
                      ),
                      Text(
                        '5 - 12 Minutes',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: AppColors.retroDarkBorder),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.retroMint,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
                side: const BorderSide(color: AppColors.retroDarkBorder, width: 1.6),
              ),
            ),
            child: const Text('UNDERSTOOD', style: TextStyle(fontWeight: FontWeight.w900)),
          ),
        ],
      ),
    );
  }

  void _showFilterBottomSheet(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final locationService = Provider.of<LocationService>(context, listen: false);
    final userLocation = locationService.currentLocationName;

    final Set<String> lguOptions = {'All'};
    if (userLocation.contains(',')) {
      final localCity = userLocation.split(',')[0].trim();
      if (localCity.isNotEmpty && !localCity.startsWith('GPS') && !localCity.startsWith('Locating')) {
        lguOptions.add(localCity);
      }
    }
    lguOptions.addAll([
      'Virac',
      'San Andres',
      'Bato',
      'Baras',
      'Gigmoto',
      'Pandan',
      'Caramoran',
      'Bagamanoc',
      'Panganiban',
      'Viga',
      'San Miguel',
    ]);

    final categories = ['All', 'Fire', 'Flood', 'Medical', 'Accident', 'Crime'];
    final severities = ['All', 'Critical', 'High', 'Moderate', 'Low'];
    final statuses = ['All', 'Pending', 'Dispatched', 'Resolved'];

    String tempCategory = _selectedCategory;
    String tempLgu = _selectedLgu;
    String tempSeverity = _selectedSeverity;
    String tempStatus = _selectedStatus;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (modalContext, setModalState) {
            return Container(
              height: MediaQuery.of(context).size.height * 0.78,
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E222D) : AppColors.retroCream,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
                border: Border.all(
                  color: isDark ? const Color(0xFF3E4556) : AppColors.retroDarkBorder,
                  width: 2.0,
                ),
                boxShadow: const [
                  BoxShadow(
                    color: AppColors.retroDarkBorder,
                    offset: Offset(0, -3),
                    blurRadius: 0,
                  ),
                ],
              ),
              child: Column(
                children: [
                  const SizedBox(height: 12),
                  Container(
                    width: 44,
                    height: 5,
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white30 : AppColors.retroDarkBorder,
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: AppColors.retroPeach,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: AppColors.retroDarkBorder, width: 1.5),
                              ),
                              child: const Icon(Icons.tune_rounded, size: 18, color: AppColors.retroDarkBorder),
                            ),
                            const SizedBox(width: 12),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'INCIDENT & GIS FILTERS',
                                  style: TextStyle(
                                    color: isDark ? Colors.white : AppColors.retroDarkBorder,
                                    fontSize: 15,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 0.8,
                                  ),
                                ),
                                Text(
                                  'Filter by LGU, category & severity',
                                  style: TextStyle(
                                    color: isDark ? Colors.white54 : const Color(0xFF6B7280),
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        GestureDetector(
                          onTap: () => Navigator.pop(ctx),
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: isDark ? Colors.white12 : Colors.white,
                              shape: BoxShape.circle,
                              border: Border.all(color: AppColors.retroDarkBorder, width: 1.4),
                            ),
                            child: Icon(Icons.close_rounded, size: 16, color: isDark ? Colors.white : AppColors.retroDarkBorder),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1, thickness: 1.4, color: AppColors.retroDarkBorder),
                  Expanded(
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildFilterSectionTitle('1. MUNICIPALITY / LGU AREA', isDark),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: lguOptions.map((lgu) {
                              final isSelected = tempLgu.toLowerCase() == lgu.toLowerCase();
                              return _buildRetroFilterPill(
                                label: lgu,
                                isSelected: isSelected,
                                activeColor: AppColors.retroMintLight,
                                isDark: isDark,
                                onTap: () => setModalState(() => tempLgu = lgu),
                              );
                            }).toList(),
                          ),
                          const SizedBox(height: 20),
                          _buildFilterSectionTitle('2. HAZARD / INCIDENT CATEGORY', isDark),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: categories.map((cat) {
                              final isSelected = tempCategory.toLowerCase() == cat.toLowerCase();
                              return _buildRetroFilterPill(
                                label: cat,
                                isSelected: isSelected,
                                activeColor: AppColors.retroPeach,
                                isDark: isDark,
                                onTap: () => setModalState(() => tempCategory = cat),
                              );
                            }).toList(),
                          ),
                          const SizedBox(height: 20),
                          _buildFilterSectionTitle('3. SEVERITY / THREAT LEVEL', isDark),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: severities.map((sev) {
                              final isSelected = tempSeverity.toLowerCase() == sev.toLowerCase();
                              return _buildRetroFilterPill(
                                label: sev,
                                isSelected: isSelected,
                                activeColor: AppColors.retroLilac,
                                isDark: isDark,
                                onTap: () => setModalState(() => tempSeverity = sev),
                              );
                            }).toList(),
                          ),
                          const SizedBox(height: 20),
                          _buildFilterSectionTitle('4. DISPATCH STATUS', isDark),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: statuses.map((st) {
                              final isSelected = tempStatus.toLowerCase() == st.toLowerCase();
                              return _buildRetroFilterPill(
                                label: st,
                                isSelected: isSelected,
                                activeColor: const Color(0xFFDCFCE7),
                                isDark: isDark,
                                onTap: () => setModalState(() => tempStatus = st),
                              );
                            }).toList(),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF191D26) : Colors.white,
                      border: const Border(top: BorderSide(color: AppColors.retroDarkBorder, width: 1.6)),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              flex: 2,
                              child: OutlinedButton(
                                onPressed: () {
                                  setModalState(() {
                                    tempCategory = 'All';
                                    tempLgu = 'All';
                                    tempSeverity = 'All';
                                    tempStatus = 'All';
                                  });
                                },
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: isDark ? Colors.white70 : AppColors.retroDarkBorder,
                                  side: const BorderSide(color: AppColors.retroDarkBorder, width: 1.6),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                ),
                                child: const Text('RESET', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 12)),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              flex: 3,
                              child: Container(
                                decoration: const BoxDecoration(
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppColors.retroDarkBorder,
                                      offset: Offset(2.5, 2.5),
                                      blurRadius: 0,
                                    ),
                                  ],
                                ),
                                child: ElevatedButton(
                                  onPressed: () {
                                    setState(() {
                                      _selectedCategory = tempCategory;
                                      _selectedLgu = tempLgu;
                                      _selectedSeverity = tempSeverity;
                                      _selectedStatus = tempStatus;
                                    });
                                    Navigator.pop(ctx);
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.retroMint,
                                    foregroundColor: Colors.white,
                                    elevation: 0,
                                    side: const BorderSide(color: AppColors.retroDarkBorder, width: 1.8),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                    padding: const EdgeInsets.symmetric(vertical: 14),
                                  ),
                                  child: const Text('APPLY FILTERS', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13, letterSpacing: 0.5)),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        SizedBox(
                          width: double.infinity,
                          child: GestureDetector(
                            onTap: () {
                              Navigator.pop(ctx);
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => IncidentMappingScreen(
                                    initialCategory: tempCategory == 'All' ? null : tempCategory,
                                    initialLgu: tempLgu == 'All' ? null : tempLgu,
                                  ),
                                ),
                              );
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              decoration: BoxDecoration(
                                color: AppColors.retroLilac,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(color: AppColors.retroDarkBorder, width: 1.5),
                                boxShadow: const [
                                  BoxShadow(
                                    color: AppColors.retroDarkBorder,
                                    offset: Offset(2, 2),
                                    blurRadius: 0,
                                  ),
                                ],
                              ),
                              child: const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.map_rounded, size: 16, color: AppColors.retroDarkBorder),
                                  SizedBox(width: 8),
                                  Text(
                                    'VIEW ON GIS INCIDENT MAP',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: 0.5,
                                      color: AppColors.retroDarkBorder,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildFilterSectionTitle(String title, bool isDark) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 10,
        fontWeight: FontWeight.w900,
        letterSpacing: 1.0,
        color: isDark ? Colors.white54 : const Color(0xFF6B7280),
      ),
    );
  }

  Widget _buildRetroFilterPill({
    required String label,
    required bool isSelected,
    required Color activeColor,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected ? activeColor : (isDark ? const Color(0xFF262C38) : Colors.white),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppColors.retroDarkBorder : (isDark ? const Color(0xFF3E4556) : AppColors.retroDarkBorder),
            width: isSelected ? 1.8 : 1.2,
          ),
          boxShadow: isSelected
              ? const [
                  BoxShadow(
                    color: AppColors.retroDarkBorder,
                    offset: Offset(1.8, 1.8),
                    blurRadius: 0,
                  ),
                ]
              : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.w900 : FontWeight.w700,
            color: isSelected
                ? AppColors.retroDarkBorder
                : (isDark ? Colors.white70 : const Color(0xFF4B5563)),
          ),
        ),
      ),
    );
  }
}
