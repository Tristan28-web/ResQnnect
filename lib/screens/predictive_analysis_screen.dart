import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/firestore_service.dart';
import '../services/predictive_ai_service.dart';
import '../models/incident_model.dart';
import '../models/predictive_ai_model.dart';
import '../core/constants.dart';

class PredictiveAnalysisScreen extends StatelessWidget {
  const PredictiveAnalysisScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final firestore = Provider.of<FirestoreService>(context, listen: false);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text(
          'PREDICTIVE ANALYSIS (AI)',
          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w900, letterSpacing: 1.5),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: StreamBuilder<List<IncidentModel>>(
        stream: firestore.getIncidents(),
        builder: (context, snapshot) {
          final incidents = snapshot.data ?? [];
          final aiService = PredictiveAIService();
          final analysis = aiService.analyzeIncidents(incidents);

          return SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Top AI Banner
                _buildAISummaryCard(context, analysis),
                const SizedBox(height: 24),

                // 1. Incident Trend (Monthly) - Matching Blueprint Component 6
                _buildSectionTitle(context, 'Incident Trend (Monthly)', Icons.trending_up_rounded),
                const SizedBox(height: 12),
                _buildMonthlyTrendChart(context, analysis.trendPoints),
                const SizedBox(height: 28),

                // 2. High-Risk Area Prediction - Matching Blueprint Component 6
                _buildSectionTitle(context, 'High Risk Area Prediction', Icons.radar_rounded),
                const SizedBox(height: 12),
                _buildHighRiskAreaList(context, analysis.highRiskAreas),
                const SizedBox(height: 28),

                // 3. Recommended LGU Resource Deployment
                _buildSectionTitle(context, 'Predictive LGU Action Plan', Icons.military_tech_rounded),
                const SizedBox(height: 12),
                _buildActionPlanCards(context, analysis.highRiskAreas.take(3).toList()),
                const SizedBox(height: 40),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title, IconData icon) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Row(
      children: [
        Icon(icon, color: AppConstants.primaryRed, size: 20),
        const SizedBox(width: 8),
        Text(
          title.toUpperCase(),
          style: TextStyle(
            color: isDark ? Colors.white70 : Colors.black87.withOpacity(0.7),
            fontSize: 12,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.2,
          ),
        ),
      ],
    );
  }

  Widget _buildAISummaryCard(BuildContext context, PredictiveAnalysisResult analysis) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    Color levelColor = Colors.greenAccent;
    if (analysis.overallRiskLevel == 'HIGH') {
      levelColor = AppConstants.primaryRed;
    } else if (analysis.overallRiskLevel == 'MODERATE') {
      levelColor = Colors.orangeAccent;
    }

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [const Color(0xFF1E2841), const Color(0xFF161E31)]
              : [const Color(0xFFF0F4FF), Colors.white],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: levelColor.withOpacity(0.35)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.25 : 0.05),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(color: levelColor.withOpacity(0.15), shape: BoxShape.circle),
                    child: Icon(Icons.auto_awesome_rounded, color: levelColor, size: 20),
                  ),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'PREDICTIVE ENGINE',
                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1.2, color: isDark ? Colors.white38 : Colors.black45),
                      ),
                      const Text(
                        'Spatiotemporal AI',
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ],
              ),
              // Risk Level Badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: levelColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: levelColor.withOpacity(0.5)),
                ),
                child: Row(
                  children: [
                    Container(width: 8, height: 8, decoration: BoxDecoration(color: levelColor, shape: BoxShape.circle)),
                    const SizedBox(width: 6),
                    Text(
                      '${analysis.overallRiskLevel} RISK',
                      style: TextStyle(color: levelColor, fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 0.8),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            analysis.aiSummary,
            style: TextStyle(
              fontSize: 13,
              height: 1.4,
              color: isDark ? Colors.white70 : Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMonthlyTrendChart(BuildContext context, List<IncidentTrendPoint> points) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    int maxVal = 1;
    for (var p in points) {
      final v = max(p.historicalCount, p.projectedCount);
      if (v > maxVal) maxVal = v;
    }

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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Historical vs. AI Forecasted Incidents',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: isDark ? Colors.white60 : Colors.black54),
              ),
              Row(
                children: [
                  _buildLegendIndicator('Historical', AppConstants.primaryRed),
                  const SizedBox(width: 12),
                  _buildLegendIndicator('AI Projected', Colors.blueAccent),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),
          // Bar / Line visualization
          SizedBox(
            height: 130,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: points.map((p) {
                final double ratio = (p.isProjected ? p.projectedCount : p.historicalCount) / (maxVal * 1.15);
                final barHeight = max(18.0, 100.0 * ratio);

                return Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(
                      p.isProjected ? '${p.projectedCount}' : '${p.historicalCount}',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: p.isProjected ? Colors.blueAccent : (isDark ? Colors.white70 : Colors.black87),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      width: 22,
                      height: barHeight,
                      decoration: BoxDecoration(
                        color: p.isProjected
                            ? Colors.blueAccent.withOpacity(0.85)
                            : AppConstants.primaryRed.withOpacity(0.85),
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      p.month,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: p.isProjected ? FontWeight.w900 : FontWeight.w500,
                        color: p.isProjected ? Colors.blueAccent : (isDark ? Colors.white38 : Colors.black45),
                      ),
                    ),
                  ],
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegendIndicator(String label, Color color) {
    return Row(
      children: [
        Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 4),
        Text(label, style: TextStyle(fontSize: 10, color: color, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildHighRiskAreaList(BuildContext context, List<HighRiskAreaPrediction> areas) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      children: areas.take(5).map((area) {
        Color badgeColor = Colors.greenAccent;
        if (area.riskLevel == 'HIGH') {
          badgeColor = AppConstants.primaryRed;
        } else if (area.riskLevel == 'MODERATE') {
          badgeColor = Colors.orangeAccent;
        }

        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E2841) : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: isDark ? Colors.white10 : Colors.black.withOpacity(0.06)),
          ),
          child: Row(
            children: [
              // Rank Badge
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: area.rank == 1 ? AppConstants.primaryRed : (isDark ? const Color(0xFF161E31) : const Color(0xFFE8F0FE)),
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Text(
                  '#${area.rank}',
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 12,
                    color: area.rank == 1 ? Colors.white : (isDark ? Colors.white70 : Colors.black87),
                  ),
                ),
              ),
              const SizedBox(width: 14),

              // Barangay & Primary Hazard
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      area.barangay,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Text(
                          'Hazard: ${area.primaryHazard}',
                          style: TextStyle(color: badgeColor, fontSize: 11, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '• ${area.incidentCount} incidents',
                          style: TextStyle(color: isDark ? Colors.white38 : Colors.black38, fontSize: 11),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Risk Score Progress / Value
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${area.riskScore}%',
                    style: TextStyle(color: badgeColor, fontSize: 15, fontWeight: FontWeight.w900),
                  ),
                  Text(
                    '${area.riskLevel} RISK',
                    style: TextStyle(color: badgeColor, fontSize: 9, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildActionPlanCards(BuildContext context, List<HighRiskAreaPrediction> topAreas) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      children: topAreas.map((area) {
        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: (isDark ? const Color(0xFF161E31) : const Color(0xFFF5F7FB)),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppConstants.primaryRed.withOpacity(0.2)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.flash_on_rounded, color: AppConstants.primaryRed, size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      area.barangay,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      area.recommendation,
                      style: TextStyle(fontSize: 12, height: 1.3, color: isDark ? Colors.white70 : Colors.black87),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}
