import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../services/firestore_service.dart';
import '../models/incident_model.dart';
import '../models/user_model.dart';
import '../core/constants.dart';

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
      case 'pending':
      case 'reported':
        return Colors.orangeAccent;
      case 'dispatched':
      case 'responding':
        return Colors.lightBlueAccent;
      case 'resolved':
        return Colors.greenAccent;
      case 'closed':
        return Colors.grey;
      default:
        return Colors.amber;
    }
  }

  Color _getTypeColor(String type) {
    switch (type.toLowerCase()) {
      case 'fire':
        return AppConstants.primaryRed;
      case 'flood':
        return Colors.blue;
      case 'crime':
        return Colors.purpleAccent;
      case 'accident':
        return Colors.orange;
      default:
        return Colors.amber;
    }
  }

  @override
  Widget build(BuildContext context) {
    final firestore = Provider.of<FirestoreService>(context, listen: false);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text(
          'INCIDENT MONITORING',
          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w900, letterSpacing: 1.5),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Column(
        children: [
          // Search & Filters Header
          Container(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: Column(
              children: [
                // Search Input
                TextField(
                  controller: _searchController,
                  onChanged: (val) => setState(() => _searchQuery = val.toLowerCase()),
                  style: TextStyle(color: isDark ? Colors.white : Colors.black87, fontSize: 13),
                  decoration: InputDecoration(
                    hintText: 'Search by Ref ID, Barangay, or Type...',
                    hintStyle: TextStyle(color: isDark ? Colors.white30 : Colors.black38, fontSize: 12),
                    prefixIcon: Icon(Icons.search_rounded, size: 18, color: isDark ? Colors.white54 : Colors.black54),
                    filled: true,
                    fillColor: isDark ? const Color(0xFF1E2841) : Colors.black.withOpacity(0.04),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                  ),
                ),
                const SizedBox(height: 12),

                // Status Filter Chips
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  child: Row(
                    children: [
                      _buildStatusFilterChip('All'),
                      const SizedBox(width: 8),
                      _buildStatusFilterChip('Reported'),
                      const SizedBox(width: 8),
                      _buildStatusFilterChip('Dispatched'),
                      const SizedBox(width: 8),
                      _buildStatusFilterChip('Resolved'),
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
                  // Status filter
                  if (_selectedStatus == 'Reported') {
                    if (inc.status != 'pending' && inc.status != 'reported') return false;
                  } else if (_selectedStatus == 'Dispatched') {
                    if (inc.status != 'dispatched' && inc.status != 'responding') return false;
                  } else if (_selectedStatus == 'Resolved') {
                    if (inc.status != 'resolved' && inc.status != 'closed') return false;
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
                        Icon(Icons.assignment_turned_in_outlined, size: 54, color: (isDark ? Colors.white : Colors.black).withOpacity(0.15)),
                        const SizedBox(height: 12),
                        Text(
                          'No incidents matching monitoring filters',
                          style: TextStyle(color: isDark ? Colors.white38 : Colors.black45, fontSize: 13),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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

  Widget _buildStatusFilterChip(String status) {
    final isSelected = _selectedStatus == status;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ChoiceChip(
      label: Text(status.toUpperCase(), style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: isSelected ? Colors.white : (isDark ? Colors.white60 : Colors.black54))),
      selected: isSelected,
      selectedColor: AppConstants.primaryRed,
      backgroundColor: isDark ? const Color(0xFF1E2841) : Colors.black.withOpacity(0.04),
      onSelected: (val) => setState(() => _selectedStatus = status),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      side: BorderSide.none,
    );
  }

  Widget _buildMonitoringCard(BuildContext context, IncidentModel item, FirestoreService firestore) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final typeColor = _getTypeColor(item.incidentType);
    final statusColor = _getStatusColor(item.status);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E2841) : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: isDark ? Colors.white10 : Colors.black.withOpacity(0.05)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.2 : 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
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
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      item.incidentType.toUpperCase(),
                      style: TextStyle(color: typeColor, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 0.8),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    item.referenceId,
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 13,
                      color: isDark ? Colors.white : Colors.black87,
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
                ),
                child: Row(
                  children: [
                    Container(width: 6, height: 6, decoration: BoxDecoration(color: statusColor, shape: BoxShape.circle)),
                    const SizedBox(width: 6),
                    Text(
                      item.status.toUpperCase(),
                      style: TextStyle(color: statusColor, fontSize: 10, fontWeight: FontWeight.w900),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Location & Barangay
          Row(
            children: [
              const Icon(Icons.location_on_rounded, size: 16, color: AppConstants.primaryRed),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  '${item.barangay} • ${item.location}',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: isDark ? Colors.white : Colors.black87,
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
            style: TextStyle(color: isDark ? Colors.white70 : Colors.black54, fontSize: 12),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 12),

          Divider(height: 1, color: isDark ? Colors.white10 : Colors.black12),
          const SizedBox(height: 10),

          // Bottom Bar: Timestamp, Responder info & Actions
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Icons.access_time_rounded, size: 14, color: isDark ? Colors.white38 : Colors.black38),
                  const SizedBox(width: 4),
                  Text(
                    DateFormat('MMM dd • hh:mm a').format(item.timestamp),
                    style: TextStyle(color: isDark ? Colors.white38 : Colors.black38, fontSize: 11),
                  ),
                ],
              ),
              Row(
                children: [
                  // Action button to update status
                  TextButton.icon(
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      visualDensity: VisualDensity.compact,
                    ),
                    icon: const Icon(Icons.edit_note_rounded, size: 16, color: AppConstants.primaryRed),
                    label: const Text('STATUS', style: TextStyle(color: AppConstants.primaryRed, fontSize: 11, fontWeight: FontWeight.bold)),
                    onPressed: () => _showStatusUpdateDialog(context, item, firestore),
                  ),
                  const SizedBox(width: 4),
                  // Dispatch / assign responder
                  TextButton.icon(
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      visualDensity: VisualDensity.compact,
                    ),
                    icon: const Icon(Icons.person_add_alt_rounded, size: 16, color: Colors.blueAccent),
                    label: const Text('DISPATCH', style: TextStyle(color: Colors.blueAccent, fontSize: 11, fontWeight: FontWeight.bold)),
                    onPressed: () => _showAssignResponderDialog(context, item, firestore),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showStatusUpdateDialog(BuildContext context, IncidentModel incident, FirestoreService firestore) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    String newStatus = incident.status;
    final notesController = TextEditingController(text: incident.resolutionNotes ?? '');

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: isDark ? const Color(0xFF1E2841) : Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text('UPDATE INCIDENT STATUS (${incident.referenceId})', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w900)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              DropdownButtonFormField<String>(
                value: ['pending', 'dispatched', 'responding', 'resolved', 'closed'].contains(newStatus.toLowerCase())
                    ? newStatus.toLowerCase()
                    : 'pending',
                dropdownColor: isDark ? const Color(0xFF161E31) : Colors.white,
                decoration: const InputDecoration(labelText: 'Status Workflow'),
                items: const [
                  DropdownMenuItem(value: 'pending', child: Text('Reported / Pending')),
                  DropdownMenuItem(value: 'dispatched', child: Text('Dispatched')),
                  DropdownMenuItem(value: 'responding', child: Text('Responding On-Scene')),
                  DropdownMenuItem(value: 'resolved', child: Text('Resolved')),
                  DropdownMenuItem(value: 'closed', child: Text('Closed')),
                ],
                onChanged: (val) {
                  if (val != null) setDialogState(() => newStatus = val);
                },
              ),
              const SizedBox(height: 12),
              TextField(
                controller: notesController,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'Resolution / Dispatcher Notes',
                  hintText: 'e.g. Unit deployed, flood receded, fire contained...',
                ),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('CANCEL')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppConstants.primaryRed),
              onPressed: () async {
                await firestore.updateIncidentStatusWithNotes(
                  incident.incidentId,
                  newStatus,
                  notes: notesController.text.trim(),
                );
                if (context.mounted) Navigator.pop(ctx);
              },
              child: const Text('UPDATE', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  void _showAssignResponderDialog(BuildContext context, IncidentModel incident, FirestoreService firestore) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF1E2841) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('DISPATCH RESPONDER (${incident.referenceId})', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w900)),
        content: SizedBox(
          width: double.maxFinite,
          child: StreamBuilder<List<UserModel>>(
            stream: firestore.getResponders(),
            builder: (context, snapshot) {
              final responders = snapshot.data ?? [];
              if (responders.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.all(16),
                  child: Text('No active responders available to dispatch.'),
                );
              }

              return ListView.builder(
                shrinkWrap: true,
                itemCount: responders.length,
                itemBuilder: (context, i) {
                  final responder = responders[i];
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor: AppConstants.primaryRed.withOpacity(0.15),
                      child: const Icon(Icons.person_rounded, color: AppConstants.primaryRed),
                    ),
                    title: Text(responder.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    subtitle: Text(responder.phone.isNotEmpty ? responder.phone : 'Field Unit', style: const TextStyle(fontSize: 11)),
                    trailing: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppConstants.primaryRed,
                        visualDensity: VisualDensity.compact,
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                      ),
                      onPressed: () async {
                        await firestore.assignIncident(incident.incidentId, responder.userId);
                        if (context.mounted) {
                          Navigator.pop(ctx);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Dispatched to ${responder.name}')),
                          );
                        }
                      },
                      child: const Text('ASSIGN', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                    ),
                  );
                },
              );
            },
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('CANCEL')),
        ],
      ),
    );
  }
}
