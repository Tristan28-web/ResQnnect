import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../services/firestore_service.dart';
import '../models/incident_model.dart';
import '../core/constants.dart';

class ReportGenerationScreen extends StatefulWidget {
  const ReportGenerationScreen({super.key});

  @override
  State<ReportGenerationScreen> createState() => _ReportGenerationScreenState();
}

class _ReportGenerationScreenState extends State<ReportGenerationScreen> {
  DateTime _startDate = DateTime.now().subtract(const Duration(days: 30));
  DateTime _endDate = DateTime.now();
  String _selectedType = 'All';
  String _selectedBarangay = 'All Barangays';
  bool _hasGenerated = false;

  Future<void> _selectStartDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _startDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null) setState(() => _startDate = picked);
  }

  Future<void> _selectEndDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _endDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 1)),
    );
    if (picked != null) setState(() => _endDate = picked);
  }

  @override
  Widget build(BuildContext context) {
    final firestore = Provider.of<FirestoreService>(context, listen: false);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text(
          'REPORT GENERATION',
          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w900, letterSpacing: 1.5),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: StreamBuilder<List<IncidentModel>>(
        stream: firestore.getIncidents(),
        builder: (context, snapshot) {
          final allIncidents = snapshot.data ?? [];

          // Filter according to selected criteria
          final filtered = allIncidents.where((i) {
            final inDate = i.timestamp.isAfter(_startDate.subtract(const Duration(days: 1))) &&
                i.timestamp.isBefore(_endDate.add(const Duration(days: 1)));
            if (!inDate) return false;

            if (_selectedType != 'All' && i.incidentType.toLowerCase() != _selectedType.toLowerCase()) {
              return false;
            }

            if (_selectedBarangay != 'All Barangays' && i.barangay != _selectedBarangay) {
              return false;
            }

            return true;
          }).toList();

          return SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Filter Panel (Date From, Date To, Incident Type, Barangay)
                _buildFilterCard(context, allIncidents),
                const SizedBox(height: 24),

                // Generate Report Button
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppConstants.primaryRed,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    elevation: 4,
                  ),
                  icon: const Icon(Icons.analytics_rounded, color: Colors.white, size: 20),
                  label: const Text(
                    'GENERATE REPORT',
                    style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w900, letterSpacing: 1.2),
                  ),
                  onPressed: () {
                    setState(() => _hasGenerated = true);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Report generated: ${filtered.length} records matching criteria.'),
                        backgroundColor: AppConstants.primaryRed,
                        duration: const Duration(seconds: 2),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 28),

                // Generated Report Section
                if (_hasGenerated) ...[
                  _buildReportHeaderCard(context, filtered.length),
                  const SizedBox(height: 20),
                  _buildKpiMetrics(context, filtered),
                  const SizedBox(height: 24),
                  _buildTypeDistributionCard(context, filtered),
                  const SizedBox(height: 24),
                  _buildIncidentDataTable(context, filtered),
                  const SizedBox(height: 40),
                ] else ...[
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 40),
                      child: Column(
                        children: [
                          Icon(Icons.assessment_outlined, size: 64, color: (isDark ? Colors.white : Colors.black).withOpacity(0.15)),
                          const SizedBox(height: 12),
                          Text(
                            'Select filters above and tap "Generate Report"',
                            style: TextStyle(color: isDark ? Colors.white38 : Colors.black45, fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildFilterCard(BuildContext context, List<IncidentModel> allIncidents) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final detectedBarangays = allIncidents
        .map((i) => i.barangay.trim())
        .where((b) => b.isNotEmpty)
        .toSet()
        .toList()
      ..sort();
    final barangayOptions = ['All Barangays', ...detectedBarangays];
    final currentBarangay = barangayOptions.contains(_selectedBarangay) ? _selectedBarangay : 'All Barangays';

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E2841) : Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: isDark ? Colors.white10 : Colors.black.withOpacity(0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.filter_list_rounded, color: AppConstants.primaryRed, size: 20),
              const SizedBox(width: 8),
              Text(
                'REPORT FILTERS',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.2,
                  color: isDark ? Colors.white70 : Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Date Pickers Row
          Row(
            children: [
              Expanded(
                child: _buildDateButton('Date From', _startDate, _selectStartDate),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildDateButton('Date To', _endDate, _selectEndDate),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Incident Type Dropdown
          Text(
            'INCIDENT TYPE',
            style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1.0, color: isDark ? Colors.white38 : Colors.black45),
          ),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF161E31) : Colors.black.withOpacity(0.04),
              borderRadius: BorderRadius.circular(14),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _selectedType,
                isExpanded: true,
                dropdownColor: isDark ? const Color(0xFF1E2841) : Colors.white,
                items: ['All', ...AppConstants.incidentTypes].map((t) {
                  return DropdownMenuItem<String>(value: t, child: Text(t, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)));
                }).toList(),
                onChanged: (val) {
                  if (val != null) setState(() => _selectedType = val);
                },
              ),
            ),
          ),
          const SizedBox(height: 14),

          // Barangay Dropdown
          Text(
            'AREA / BARANGAY',
            style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1.0, color: isDark ? Colors.white38 : Colors.black45),
          ),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF161E31) : Colors.black.withOpacity(0.04),
              borderRadius: BorderRadius.circular(14),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: currentBarangay,
                isExpanded: true,
                dropdownColor: isDark ? const Color(0xFF1E2841) : Colors.white,
                items: barangayOptions.map((b) {
                  return DropdownMenuItem<String>(value: b, child: Text(b, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)));
                }).toList(),
                onChanged: (val) {
                  if (val != null) setState(() => _selectedBarangay = val);
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDateButton(String label, DateTime date, VoidCallback onTap) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF161E31) : Colors.black.withOpacity(0.04),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: isDark ? Colors.white38 : Colors.black45)),
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.calendar_month_rounded, size: 14, color: AppConstants.primaryRed),
                const SizedBox(width: 6),
                Text(
                  DateFormat('yyyy-MM-dd').format(date),
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black87),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReportHeaderCard(BuildContext context, int count) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E2841) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isDark ? Colors.white10 : Colors.black.withOpacity(0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'LGU INCIDENT SUMMARY REPORT',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w900, letterSpacing: 1.1, color: isDark ? Colors.white : Colors.black87),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(color: Colors.green.withOpacity(0.15), borderRadius: BorderRadius.circular(8)),
                child: const Text('OFFICIAL', style: TextStyle(color: Colors.greenAccent, fontSize: 10, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Generated: ${DateFormat('yyyy-MM-dd hh:mm a').format(DateTime.now())} • GIS Command Center',
            style: TextStyle(fontSize: 11, color: isDark ? Colors.white38 : Colors.black45),
          ),
          const SizedBox(height: 12),
          Text(
            'Scope: $_selectedType Incidents in $_selectedBarangay (${DateFormat('MMM d').format(_startDate)} - ${DateFormat('MMM d, yyyy').format(_endDate)})',
            style: TextStyle(fontSize: 12, color: isDark ? Colors.white70 : Colors.black87),
          ),
        ],
      ),
    );
  }

  Widget _buildKpiMetrics(BuildContext context, List<IncidentModel> list) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final total = list.length;
    final resolved = list.where((i) => i.status == 'resolved' || i.status == 'closed').length;
    final rate = total > 0 ? ((resolved / total) * 100).round() : 100;

    return Row(
      children: [
        Expanded(child: _buildMetricTile('TOTAL INCIDENTS', '$total', Colors.blueAccent, isDark)),
        const SizedBox(width: 10),
        Expanded(child: _buildMetricTile('RESOLVED', '$resolved', Colors.greenAccent, isDark)),
        const SizedBox(width: 10),
        Expanded(child: _buildMetricTile('RESOLUTION RATE', '$rate%', AppConstants.primaryRed, isDark)),
      ],
    );
  }

  Widget _buildMetricTile(String title, String val, Color color, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E2841) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: isDark ? Colors.white38 : Colors.black45)),
          const SizedBox(height: 6),
          Text(val, style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: color)),
        ],
      ),
    );
  }

  Widget _buildTypeDistributionCard(BuildContext context, List<IncidentModel> list) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final Map<String, int> typeMap = {};
    for (var i in list) {
      typeMap[i.incidentType] = (typeMap[i.incidentType] ?? 0) + 1;
    }

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E2841) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isDark ? Colors.white10 : Colors.black.withOpacity(0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'INCIDENTS BY TYPE DISTRIBUTION',
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 1.0, color: isDark ? Colors.white70 : Colors.black87),
          ),
          const SizedBox(height: 14),
          if (typeMap.isEmpty)
            Text('No incidents recorded in this filter window.', style: TextStyle(color: isDark ? Colors.white38 : Colors.black38, fontSize: 12))
          else
            Column(
              children: typeMap.entries.map((entry) {
                final double percent = list.isNotEmpty ? (entry.value / list.length) : 0;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 70,
                        child: Text(entry.key, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                      ),
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: LinearProgressIndicator(
                            value: percent,
                            minHeight: 10,
                            backgroundColor: isDark ? Colors.white10 : Colors.black.withOpacity(0.05),
                            valueColor: AlwaysStoppedAnimation(AppConstants.primaryRed),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text('${entry.value} (${(percent * 100).toInt()}%)', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                    ],
                  ),
                );
              }).toList(),
            ),
        ],
      ),
    );
  }

  Widget _buildIncidentDataTable(BuildContext context, List<IncidentModel> list) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E2841) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isDark ? Colors.white10 : Colors.black.withOpacity(0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'ITEMIZED INCIDENT LOGS',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 1.0, color: isDark ? Colors.white70 : Colors.black87),
              ),
              Text('${list.length} Records', style: TextStyle(fontSize: 11, color: isDark ? Colors.white38 : Colors.black38)),
            ],
          ),
          const SizedBox(height: 12),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: list.length,
            separatorBuilder: (_, __) => Divider(height: 16, color: isDark ? Colors.white10 : Colors.black12),
            itemBuilder: (ctx, i) {
              final inc = list[i];
              return Row(
                children: [
                  Text(inc.referenceId, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                  const SizedBox(width: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(color: AppConstants.primaryRed.withOpacity(0.12), borderRadius: BorderRadius.circular(4)),
                    child: Text(inc.incidentType, style: const TextStyle(color: AppConstants.primaryRed, fontSize: 10, fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      inc.barangay,
                      style: TextStyle(fontSize: 12, color: isDark ? Colors.white70 : Colors.black87),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Text(
                    DateFormat('MM/dd').format(inc.timestamp),
                    style: TextStyle(fontSize: 11, color: isDark ? Colors.white38 : Colors.black38),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}
