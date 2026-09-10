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
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'REPORT GENERATION',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.3,
            color: isDark ? Colors.white : AppColors.retroDarkBorder,
          ),
        ),
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
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Filter Panel (Date From, Date To, Incident Type, Barangay)
                _buildFilterCard(context, allIncidents, isDark),
                const SizedBox(height: 18),

                // Generate Report Button
                GestureDetector(
                  onTap: () {
                    setState(() => _hasGenerated = true);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Report compiled: ${filtered.length} records matching criteria.'),
                        backgroundColor: AppColors.retroMintDark,
                        duration: const Duration(seconds: 2),
                      ),
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    decoration: BoxDecoration(
                      color: AppColors.retroMint,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: AppColors.retroDarkBorder, width: 2.0),
                      boxShadow: [
                        BoxShadow(
                          color: isDark ? Colors.black54 : AppColors.retroDarkBorder,
                          offset: const Offset(4, 4),
                          blurRadius: 0,
                        ),
                      ],
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.analytics_rounded, color: Colors.white, size: 20),
                        SizedBox(width: 8),
                        Text(
                          'GENERATE OFFICIAL AUDIT REPORT',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.1,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Generated Report Section
                if (_hasGenerated) ...[
                  _buildReportHeaderCard(context, filtered.length, isDark),
                  const SizedBox(height: 16),
                  _buildKpiMetrics(context, filtered, isDark),
                  const SizedBox(height: 20),
                  _buildTypeDistributionCard(context, filtered, isDark),
                  const SizedBox(height: 20),
                  _buildIncidentDataTable(context, filtered, isDark),
                  const SizedBox(height: 40),
                ] else ...[
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 36),
                      child: Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: isDark ? AppColors.retroDarkCard : AppColors.retroPeach,
                              shape: BoxShape.circle,
                              border: Border.all(color: isDark ? const Color(0xFF3E4556) : AppColors.retroDarkBorder, width: 1.8),
                            ),
                            child: Icon(Icons.assessment_outlined, size: 44, color: isDark ? Colors.white38 : AppColors.retroDarkBorder),
                          ),
                          const SizedBox(height: 14),
                          Text(
                            'Select filter criteria above and tap "Generate Official Audit Report"',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: isDark ? Colors.white54 : const Color(0xFF6B7280),
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
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

  Widget _buildFilterCard(BuildContext context, List<IncidentModel> allIncidents, bool isDark) {
    final detectedBarangays = allIncidents
        .map((i) => i.barangay.trim())
        .where((b) => b.isNotEmpty)
        .toSet()
        .toList()
      ..sort();
    final barangayOptions = ['All Barangays', ...detectedBarangays];
    final currentBarangay = barangayOptions.contains(_selectedBarangay) ? _selectedBarangay : 'All Barangays';

    return Container(
      padding: const EdgeInsets.all(18),
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
            offset: const Offset(3.5, 3.5),
            blurRadius: 0,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppColors.retroPeach,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.retroDarkBorder, width: 1.2),
                ),
                child: const Icon(Icons.filter_list_rounded, color: AppColors.retroDarkBorder, size: 16),
              ),
              const SizedBox(width: 8),
              Text(
                'REPORT FILTERS',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.1,
                  color: isDark ? Colors.white : AppColors.retroDarkBorder,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Date Pickers Row
          Row(
            children: [
              Expanded(
                child: _buildDateButton('DATE FROM', _startDate, _selectStartDate, isDark),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildDateButton('DATE TO', _endDate, _selectEndDate, isDark),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Incident Type Dropdown
          Text(
            'INCIDENT TYPE',
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.0,
              color: isDark ? Colors.white54 : const Color(0xFF6B7280),
            ),
          ),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF262C38) : const Color(0xFFF9FAFB),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isDark ? const Color(0xFF3E4556) : AppColors.retroDarkBorder,
                width: 1.4,
              ),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _selectedType,
                isExpanded: true,
                dropdownColor: isDark ? AppColors.retroDarkCard : Colors.white,
                items: ['All', ...AppConstants.incidentTypes].map((t) {
                  return DropdownMenuItem<String>(
                    value: t,
                    child: Text(
                      t,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: isDark ? Colors.white : AppColors.retroDarkBorder,
                      ),
                    ),
                  );
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
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.0,
              color: isDark ? Colors.white54 : const Color(0xFF6B7280),
            ),
          ),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF262C38) : const Color(0xFFF9FAFB),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isDark ? const Color(0xFF3E4556) : AppColors.retroDarkBorder,
                width: 1.4,
              ),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: currentBarangay,
                isExpanded: true,
                dropdownColor: isDark ? AppColors.retroDarkCard : Colors.white,
                items: barangayOptions.map((b) {
                  return DropdownMenuItem<String>(
                    value: b,
                    child: Text(
                      b,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: isDark ? Colors.white : AppColors.retroDarkBorder,
                      ),
                    ),
                  );
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

  Widget _buildDateButton(String label, DateTime date, VoidCallback onTap, bool isDark) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF262C38) : AppColors.retroCream,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isDark ? const Color(0xFF3E4556) : AppColors.retroDarkBorder,
            width: 1.4,
          ),
          boxShadow: [
            BoxShadow(
              color: isDark ? Colors.black38 : AppColors.retroDarkBorder.withOpacity(0.1),
              offset: const Offset(2, 2),
              blurRadius: 0,
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 8,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.6,
                color: isDark ? Colors.white54 : const Color(0xFF6B7280),
              ),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.calendar_today_rounded, size: 13, color: AppColors.retroMint),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    DateFormat('MMM dd, yyyy').format(date),
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                      color: isDark ? Colors.white : AppColors.retroDarkBorder,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReportHeaderCard(BuildContext context, int count, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2B2421) : AppColors.retroPeach,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? const Color(0xFF4A3C38) : AppColors.retroDarkBorder,
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
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'LGU INCIDENT SUMMARY REPORT',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.0,
                  color: isDark ? Colors.white : AppColors.retroDarkBorder,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFDCFCE7),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.retroDarkBorder, width: 1.2),
                ),
                child: const Text(
                  'OFFICIAL',
                  style: TextStyle(color: Color(0xFF16A34A), fontSize: 9, fontWeight: FontWeight.w900),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Generated: ${DateFormat('yyyy-MM-dd hh:mm a').format(DateTime.now())} • GIS Command Center',
            style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: isDark ? Colors.white54 : const Color(0xFF6B7280)),
          ),
          const SizedBox(height: 8),
          Text(
            'Scope: $_selectedType Incidents in $_selectedBarangay (${DateFormat('MMM d').format(_startDate)} - ${DateFormat('MMM d, yyyy').format(_endDate)})',
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: isDark ? Colors.white70 : AppColors.retroDarkBorder),
          ),
        ],
      ),
    );
  }

  Widget _buildKpiMetrics(BuildContext context, List<IncidentModel> list, bool isDark) {
    final total = list.length;
    final resolved = list.where((i) => i.status == 'resolved' || i.status == 'closed').length;
    final rate = total > 0 ? ((resolved / total) * 100).round() : 100;

    return Row(
      children: [
        Expanded(
          child: _buildRetroMetricBox('TOTAL', '$total', AppColors.retroLilac, isDark ? Colors.white : AppColors.retroDarkBorder, isDark),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildRetroMetricBox('RESOLVED', '$resolved', const Color(0xFFDCFCE7), const Color(0xFF16A34A), isDark),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildRetroMetricBox('RATE', '$rate%', const Color(0xFFFEF08A), const Color(0xFFB45309), isDark),
        ),
      ],
    );
  }

  Widget _buildRetroMetricBox(String label, String val, Color fill, Color textColor, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF262C38) : fill,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? const Color(0xFF3E4556) : AppColors.retroDarkBorder,
          width: 1.4,
        ),
        boxShadow: [
          BoxShadow(
            color: isDark ? Colors.black38 : AppColors.retroDarkBorder.withOpacity(0.1),
            offset: const Offset(2, 2),
            blurRadius: 0,
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            val,
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: textColor),
          ),
          const SizedBox(height: 2),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 8,
                fontWeight: FontWeight.w900,
                color: isDark ? Colors.white54 : AppColors.retroDarkBorder,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTypeDistributionCard(BuildContext context, List<IncidentModel> list, bool isDark) {
    final Map<String, int> typeMap = {};
    for (var i in list) {
      typeMap[i.incidentType] = (typeMap[i.incidentType] ?? 0) + 1;
    }

    return Container(
      padding: const EdgeInsets.all(18),
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
          Text(
            'INCIDENTS BY TYPE DISTRIBUTION',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.0,
              color: isDark ? Colors.white : AppColors.retroDarkBorder,
            ),
          ),
          const SizedBox(height: 14),
          if (typeMap.isEmpty)
            Text(
              'No incidents recorded in this filter window.',
              style: TextStyle(color: isDark ? Colors.white38 : const Color(0xFF6B7280), fontSize: 11),
            )
          else
            Column(
              children: typeMap.entries.map((entry) {
                final double percent = list.isNotEmpty ? (entry.value / list.length) : 0;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 75,
                        child: Text(
                          entry.key,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            color: isDark ? Colors.white70 : AppColors.retroDarkBorder,
                          ),
                        ),
                      ),
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: percent,
                            minHeight: 8,
                            backgroundColor: isDark ? Colors.white10 : AppColors.retroDarkBorder.withOpacity(0.08),
                            valueColor: const AlwaysStoppedAnimation(Color(0xFFE11D48)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        '${entry.value} (${(percent * 100).toInt()}%)',
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: Color(0xFFE11D48)),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
        ],
      ),
    );
  }

  Widget _buildIncidentDataTable(BuildContext context, List<IncidentModel> list, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(18),
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'ITEMIZED INCIDENT LOGS',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.0,
                  color: isDark ? Colors.white : AppColors.retroDarkBorder,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.retroLilac,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: AppColors.retroDarkBorder, width: 1.0),
                ),
                child: Text(
                  '${list.length} RECORDS',
                  style: const TextStyle(
                    color: AppColors.retroDarkBorder,
                    fontSize: 9,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: list.length,
            separatorBuilder: (_, __) => Divider(
              height: 16,
              color: isDark ? Colors.white10 : AppColors.retroDarkBorder.withOpacity(0.1),
            ),
            itemBuilder: (ctx, i) {
              final inc = list[i];
              return Row(
                children: [
                  Text(
                    inc.referenceId,
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 12,
                      color: isDark ? Colors.white : AppColors.retroDarkBorder,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEE2E2),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: const Color(0xFFDC2626), width: 0.8),
                    ),
                    child: Text(
                      inc.incidentType.toUpperCase(),
                      style: const TextStyle(color: Color(0xFFDC2626), fontSize: 8, fontWeight: FontWeight.w900),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      inc.barangay,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white70 : const Color(0xFF374151),
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Text(
                    DateFormat('MM/dd').format(inc.timestamp),
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: isDark ? Colors.white38 : const Color(0xFF6B7280)),
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
