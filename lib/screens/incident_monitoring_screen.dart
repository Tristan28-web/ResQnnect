import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../services/firestore_service.dart';
import '../models/incident_model.dart';
import '../core/constants.dart';
import '../core/navigation_utils.dart';
import '../widgets/incident_detail_sheet.dart';

class IncidentMonitoringScreen extends StatefulWidget {
  const IncidentMonitoringScreen({super.key});

  @override
  State<IncidentMonitoringScreen> createState() => _IncidentMonitoringScreenState();
}

class _IncidentMonitoringScreenState extends State<IncidentMonitoringScreen> {
  String _selectedStatus = 'All';
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'closed':
        return const Color(0xFF64748B);
      case 'active':
      default:
        return const Color(0xFF10B981);
    }
  }

  Color _getTypeColor(String type) {
    switch (type.toLowerCase()) {
      case 'fire':
        return const Color(0xFFEF4444);
      case 'flood':
        return const Color(0xFF3B82F6);
      case 'crime':
        return const Color(0xFF8B5CF6);
      case 'accident':
        return const Color(0xFFEA580C);
      default: // Other
        return const Color(0xFF10B981);
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final firestore = Provider.of<FirestoreService>(context, listen: false);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: isDark ? AppColors.retroDarkCard : Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: isDark ? const Color(0xFF3E4556) : AppColors.retroDarkBorder, width: 1.5),
            ),
            child: Icon(Icons.arrow_back_ios_new_rounded, size: 14, color: isDark ? Colors.white : AppColors.retroDarkBorder),
          ),
          onPressed: () => AppNavigation.popOrHome(context),
        ),
        title: Text(
          'INCIDENT MONITORING',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.3,
            color: isDark ? Colors.white : AppColors.retroDarkBorder,
          ),
        ),
      ),
      body: Column(
        children: [
          // Search & Filters Header
          Container(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
            child: Column(
              children: [
                // Retro Search Field
                Container(
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.retroDarkCard : Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isDark ? const Color(0xFF3E4556) : AppColors.retroDarkBorder,
                      width: 1.8,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: isDark ? Colors.black38 : AppColors.retroDarkBorder.withOpacity(0.1),
                        offset: const Offset(2.5, 2.5),
                        blurRadius: 0,
                      ),
                    ],
                  ),
                  child: TextField(
                    controller: _searchController,
                    onChanged: (val) => setState(() => _searchQuery = val.toLowerCase()),
                    style: TextStyle(color: isDark ? Colors.white : AppColors.retroDarkBorder, fontSize: 13, fontWeight: FontWeight.w600),
                    decoration: InputDecoration(
                      hintText: 'Search Ref ID, Barangay, or Type...',
                      hintStyle: TextStyle(color: isDark ? Colors.white30 : const Color(0xFF9CA3AF), fontSize: 12),
                      prefixIcon: Icon(Icons.search_rounded, size: 18, color: isDark ? Colors.white54 : AppColors.retroDarkBorder),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(height: 14),

                // Retro Status Filter Pills
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  child: Row(
                    children: [
                      _buildRetroFilterPill('All', isDark),
                      const SizedBox(width: 8),
                      _buildRetroFilterPill('Active', isDark),
                      const SizedBox(width: 8),
                      _buildRetroFilterPill('Closed', isDark),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Incidents Stream Table / List
          Expanded(
            child: StreamBuilder<List<IncidentModel>>(
              stream: firestore.getIncidents(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator(color: AppConstants.primaryRed));
                }

                final incidents = snapshot.data ?? [];
                final filtered = incidents.where((inc) {
                  // Status filter (Active vs 15-day Closed)
                  if (_selectedStatus == 'Active') {
                    if (inc.isAutoClosed) return false;
                  } else if (_selectedStatus == 'Closed') {
                    if (!inc.isAutoClosed) return false;
                  }

                  // Search query
                  if (_searchQuery.isNotEmpty) {
                    final query = _searchQuery.toLowerCase();
                    final matchRef = inc.referenceId.toLowerCase().contains(query);
                    final matchBgy = inc.barangay.toLowerCase().contains(query);
                    final matchType = inc.incidentType.toLowerCase().contains(query);
                    final matchDesc = inc.description.toLowerCase().contains(query);
                    if (!matchRef && !matchBgy && !matchType && !matchDesc) return false;
                  }

                  return true;
                }).toList();

                if (filtered.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: isDark ? AppColors.retroDarkCard : AppColors.retroCream,
                            shape: BoxShape.circle,
                            border: Border.all(color: isDark ? const Color(0xFF3E4556) : AppColors.retroDarkBorder, width: 1.8),
                          ),
                          child: Icon(Icons.assignment_turned_in_outlined, size: 40, color: isDark ? Colors.white38 : AppColors.retroDarkBorder),
                        ),
                        const SizedBox(height: 14),
                        Text(
                          'No incidents matching monitoring filters',
                          style: TextStyle(
                            color: isDark ? Colors.white60 : AppColors.retroDarkBorder,
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    final item = filtered[index];
                    return _buildMonitoringCard(context, item, firestore);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRetroFilterPill(String status, bool isDark) {
    final isSelected = _selectedStatus == status;
    Color activeBg = AppColors.retroLilac;
    if (status == 'Active') activeBg = const Color(0xFFDCFCE7);
    if (status == 'Closed') activeBg = const Color(0xFFE2E8F0);

    return GestureDetector(
      onTap: () => setState(() => _selectedStatus = status),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected ? activeBg : (isDark ? AppColors.retroDarkCard : Colors.white),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? AppColors.retroDarkBorder
                : (isDark ? const Color(0xFF3E4556) : AppColors.retroDarkBorder.withOpacity(0.4)),
            width: isSelected ? 1.8 : 1.2,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: isDark ? Colors.black54 : AppColors.retroDarkBorder,
                    offset: const Offset(2, 2),
                    blurRadius: 0,
                  ),
                ]
              : null,
        ),
        child: Text(
          status.toUpperCase(),
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w900,
            letterSpacing: 0.6,
            color: isDark ? (isSelected ? AppColors.retroDarkBorder : Colors.white70) : AppColors.retroDarkBorder,
          ),
        ),
      ),
    );
  }

  Widget _buildMonitoringCard(BuildContext context, IncidentModel item, FirestoreService firestore) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final typeColor = _getTypeColor(item.incidentType);
    final statusColor = _getStatusColor(item.status);

    return GestureDetector(
      onTap: () => IncidentDetailSheet.show(context, incident: item, isAdmin: true),
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.retroDarkCard : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? const Color(0xFF3E4556) : AppColors.retroDarkBorder,
          width: 1.8,
        ),
        boxShadow: [
          BoxShadow(
            color: isDark ? Colors.black45 : AppColors.retroDarkBorder.withOpacity(0.12),
            offset: const Offset(3.5, 3.5),
            blurRadius: 0,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Ref ID, Type, Status Badge
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: typeColor.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: typeColor.withOpacity(0.5), width: 1.2),
                    ),
                    child: Text(
                      item.incidentType.toUpperCase(),
                      style: TextStyle(color: typeColor, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 0.6),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    item.referenceId,
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 13,
                      color: isDark ? Colors.white : AppColors.retroDarkBorder,
                      letterSpacing: 0.8,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: statusColor.withOpacity(0.6), width: 1.2),
                ),
                child: Row(
                  children: [
                    Container(width: 6, height: 6, decoration: BoxDecoration(color: statusColor, shape: BoxShape.circle)),
                    const SizedBox(width: 6),
                    Text(
                      item.isAutoClosed ? 'CLOSED' : 'ACTIVE (${item.daysUntilAutoClose}D LEFT)',
                      style: TextStyle(color: statusColor, fontSize: 10, fontWeight: FontWeight.w900),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Location & Barangay
          Row(
            children: [
              const Icon(Icons.location_on_rounded, size: 16, color: AppConstants.primaryRed),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  '${item.barangay} • ${item.location}',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                    color: isDark ? Colors.white : AppColors.retroDarkBorder,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),

          // Description
          Text(
            item.description,
            style: TextStyle(color: isDark ? Colors.white70 : const Color(0xFF4B5563), fontSize: 12, height: 1.3),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 12),

          Divider(height: 1, color: isDark ? Colors.white12 : AppColors.retroDarkBorder.withOpacity(0.1)),
          const SizedBox(height: 10),

          // Bottom Bar: Timestamp & Actions
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Icons.access_time_rounded, size: 14, color: isDark ? Colors.white38 : const Color(0xFF6B7280)),
                  const SizedBox(width: 4),
                  Text(
                    DateFormat('MMM dd • hh:mm a').format(item.timestamp),
                    style: TextStyle(color: isDark ? Colors.white38 : const Color(0xFF6B7280), fontSize: 11, fontWeight: FontWeight.w700),
                  ),
                ],
              ),
              Row(
                children: [
                  // 15-Day Auto-Close Lifecycle Indicator
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: item.isAutoClosed
                          ? (isDark ? const Color(0xFF262C38) : const Color(0xFFF1F5F9))
                          : (isDark ? const Color(0xFF1E2B24) : const Color(0xFFDCFCE7)),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: item.isAutoClosed
                            ? (isDark ? const Color(0xFF475569) : const Color(0xFF94A3B8))
                            : const Color(0xFF16A34A),
                        width: 1.2,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          item.isAutoClosed ? Icons.lock_clock_rounded : Icons.timer_outlined,
                          size: 11,
                          color: item.isAutoClosed
                              ? (isDark ? Colors.white60 : const Color(0xFF64748B))
                              : const Color(0xFF16A34A),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          item.isAutoClosed
                              ? '15D CLOSED'
                              : 'CLOSES IN ${item.daysUntilAutoClose}D',
                          style: TextStyle(
                            color: item.isAutoClosed
                                ? (isDark ? Colors.white60 : const Color(0xFF64748B))
                                : const Color(0xFF16A34A),
                            fontSize: 9,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Details Button
                  GestureDetector(
                    onTap: () => IncidentDetailSheet.show(context, incident: item, isAdmin: true),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: AppColors.retroPeach,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppColors.retroDarkBorder, width: 1.4),
                        boxShadow: [
                          BoxShadow(
                            color: isDark ? Colors.black54 : AppColors.retroDarkBorder,
                            offset: const Offset(2, 2),
                            blurRadius: 0,
                          ),
                        ],
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.visibility_rounded, size: 13, color: AppColors.retroDarkBorder),
                          SizedBox(width: 4),
                          Text(
                            'DETAILS',
                            style: TextStyle(
                              color: AppColors.retroDarkBorder,
                              fontSize: 10,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.6,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    ),
    );
  }
}
