import 'dart:math';
import 'package:intl/intl.dart';
import '../models/incident_model.dart';
import '../models/predictive_ai_model.dart';
import '../core/constants.dart';

class PredictiveAIService {
  static final PredictiveAIService _instance = PredictiveAIService._internal();
  factory PredictiveAIService() => _instance;
  PredictiveAIService._internal();

  /// Run comprehensive predictive analysis on raw incident records
  PredictiveAnalysisResult analyzeIncidents(List<IncidentModel> incidents) {
    if (incidents.isEmpty) {
      return _generateBaselineResult();
    }

    final trendPoints = _calculateMonthlyTrends(incidents);
    final highRiskAreas = _computeHighRiskAreas(incidents);
    final typeDistribution = _computeTypeDistribution(incidents);

    double totalRisk = 0;
    for (var area in highRiskAreas) {
      totalRisk += area.riskScore;
    }
    final avgRisk = highRiskAreas.isNotEmpty ? (totalRisk / highRiskAreas.length) : 35.0;

    String overallLevel = 'LOW';
    if (avgRisk >= 65) {
      overallLevel = 'HIGH';
    } else if (avgRisk >= 40) {
      overallLevel = 'MODERATE';
    }

    final aiSummary = _generateAISummary(highRiskAreas, overallLevel);

    return PredictiveAnalysisResult(
      overallRiskLevel: overallLevel,
      averageRiskScore: avgRisk,
      trendPoints: trendPoints,
      highRiskAreas: highRiskAreas,
      incidentsByType: typeDistribution,
      aiSummary: aiSummary,
      generatedAt: DateTime.now(),
    );
  }

  /// 1. Time-Series Trend Analysis using Holt's Linear Exponential Smoothing
  List<IncidentTrendPoint> _calculateMonthlyTrends(List<IncidentModel> incidents) {
    final now = DateTime.now();
    final DateFormat monthFormat = DateFormat('MMM');

    // Aggregate incidents by last 6 months
    final Map<int, int> monthlyCounts = {};
    for (int i = 5; i >= 0; i--) {
      monthlyCounts[i] = 0;
    }

    for (var incident in incidents) {
      final diffMonths = (now.year - incident.timestamp.year) * 12 + (now.month - incident.timestamp.month);
      if (diffMonths >= 0 && diffMonths < 6) {
        monthlyCounts[5 - diffMonths] = (monthlyCounts[5 - diffMonths] ?? 0) + 1;
      }
    }

    // Historical counts array (ordered from 5 months ago to current month)
    List<double> series = [];
    List<String> monthLabels = [];

    for (int i = 0; i < 6; i++) {
      final targetDate = DateTime(now.year, now.month - (5 - i), 1);
      monthLabels.add(monthFormat.format(targetDate));
      series.add((monthlyCounts[i] ?? 0).toDouble());
    }

    // Holt's Exponential Smoothing parameters
    const double alpha = 0.4;
    const double beta = 0.3;

    double level = series.first;
    double trend = series.length > 1 ? (series[1] - series[0]) : 1.0;

    for (int t = 1; t < series.length; t++) {
      final prevLevel = level;
      level = alpha * series[t] + (1 - alpha) * (prevLevel + trend);
      trend = beta * (level - prevLevel) + (1 - beta) * trend;
    }

    // Build historical points
    List<IncidentTrendPoint> points = [];
    for (int i = 0; i < 6; i++) {
      points.add(IncidentTrendPoint(
        month: monthLabels[i],
        historicalCount: series[i].toInt(),
        projectedCount: series[i].toInt(),
        isProjected: false,
      ));
    }

    // Generate 2 future projected months
    for (int h = 1; h <= 2; h++) {
      final nextMonthDate = DateTime(now.year, now.month + h, 1);
      final forecast = max(0.0, level + h * trend);
      points.add(IncidentTrendPoint(
        month: monthFormat.format(nextMonthDate),
        historicalCount: 0,
        projectedCount: forecast.round(),
        isProjected: true,
      ));
    }

    return points;
  }

  /// 2. Composite Risk Index (CRI) calculation and Ranking of High-Risk Areas
  List<HighRiskAreaPrediction> _computeHighRiskAreas(List<IncidentModel> incidents) {
    // Group incidents by barangay
    final Map<String, List<IncidentModel>> barangayMap = {};

    for (var incident in incidents) {
      final bgy = incident.barangay.isNotEmpty ? incident.barangay : 'Virac (Capital)';
      barangayMap.putIfAbsent(bgy, () => []).add(incident);
    }

    // Ensure standard major barangays are present
    for (var bgy in AppConstants.lguBarangays.take(6)) {
      barangayMap.putIfAbsent(bgy, () => []);
    }

    // Find max frequency for normalization
    int maxIncidents = 1;
    for (var list in barangayMap.values) {
      if (list.length > maxIncidents) maxIncidents = list.length;
    }

    final now = DateTime.now();
    List<HighRiskAreaPrediction> predictions = [];

    barangayMap.forEach((barangay, items) {
      // 1. Normalized Frequency (w_f = 0.35)
      final double fScore = (items.length / maxIncidents).clamp(0.0, 1.0);

      // 2. Average Severity Weight (w_s = 0.30)
      double totalSeverity = 0;
      final Map<String, int> typeTally = {};

      for (var item in items) {
        typeTally[item.incidentType] = (typeTally[item.incidentType] ?? 0) + 1;
        switch (item.incidentType.toLowerCase()) {
          case 'fire':
            totalSeverity += 1.0;
            break;
          case 'flood':
            totalSeverity += 0.9;
            break;
          case 'crime':
            totalSeverity += 0.8;
            break;
          case 'accident':
            totalSeverity += 0.7;
            break;
          default:
            totalSeverity += 0.5;
        }
      }
      final double sScore = items.isNotEmpty ? (totalSeverity / items.length) : 0.4;

      // Primary hazard
      String primaryHazard = 'Accident';
      int maxTypeCount = 0;
      typeTally.forEach((type, count) {
        if (count > maxTypeCount) {
          maxTypeCount = count;
          primaryHazard = type;
        }
      });

      // 3. Recency Decay (w_r = 0.20)
      // e^(-0.05 * deltaDays)
      double recencySum = 0;
      for (var item in items) {
        final days = max(0, now.difference(item.timestamp).inDays);
        recencySum += exp(-0.05 * days);
      }
      final double rScore = items.isNotEmpty ? (recencySum / items.length).clamp(0.0, 1.0) : 0.2;

      // 4. Environmental / Seasonal Modifier (w_e = 0.15)
      // June to November is typhoon/flood season in Philippines; March to May is dry/fire season.
      double eScore = 0.3;
      final currentMonth = now.month;
      if (primaryHazard == 'Flood' && (currentMonth >= 6 && currentMonth <= 11)) {
        eScore = 0.9;
      } else if (primaryHazard == 'Fire' && (currentMonth >= 3 && currentMonth <= 5)) {
        eScore = 0.85;
      }

      // Compute Weighted CRI (0.0 to 100.0)
      final rawCRI = (0.35 * fScore + 0.30 * sScore + 0.20 * rScore + 0.15 * eScore) * 100.0;
      final riskScore = double.parse(rawCRI.clamp(10.0, 98.0).toStringAsFixed(1));

      // Poisson probability of >= 1 incident in next 7 days
      // arrival rate lambda based on recent month
      final double lambda = max(0.1, items.length / 4.0);
      final double probPercent = double.parse(((1.0 - exp(-lambda)) * 100.0).clamp(5.0, 99.0).toStringAsFixed(1));

      String riskLevel = 'LOW';
      if (riskScore >= 70) {
        riskLevel = 'HIGH';
      } else if (riskScore >= 40) {
        riskLevel = 'MODERATE';
      }

      // Actionable LGU recommendation
      String recommendation = _buildRecommendation(barangay, primaryHazard, riskLevel);

      predictions.add(HighRiskAreaPrediction(
        rank: 0, // Assigned after sorting
        barangay: barangay,
        riskScore: riskScore,
        riskLevel: riskLevel,
        primaryHazard: primaryHazard,
        incidentCount: items.length,
        probabilityPercentage: probPercent,
        recommendation: recommendation,
      ));
    });

    // Sort descending by risk score
    predictions.sort((a, b) => b.riskScore.compareTo(a.riskScore));

    // Assign 1-indexed ranks
    List<HighRiskAreaPrediction> ranked = [];
    for (int i = 0; i < predictions.length; i++) {
      final p = predictions[i];
      ranked.add(HighRiskAreaPrediction(
        rank: i + 1,
        barangay: p.barangay,
        riskScore: p.riskScore,
        riskLevel: p.riskLevel,
        primaryHazard: p.primaryHazard,
        incidentCount: p.incidentCount,
        probabilityPercentage: p.probabilityPercentage,
        recommendation: p.recommendation,
      ));
    }

    return ranked;
  }

  Map<String, int> _computeTypeDistribution(List<IncidentModel> incidents) {
    final Map<String, int> distribution = {
      'Fire': 0,
      'Flood': 0,
      'Crime': 0,
      'Accident': 0,
      'Other': 0,
    };

    for (var incident in incidents) {
      final type = incident.incidentType;
      if (distribution.containsKey(type)) {
        distribution[type] = distribution[type]! + 1;
      } else {
        distribution['Other'] = distribution['Other']! + 1;
      }
    }

    return distribution;
  }

  String _buildRecommendation(String barangay, String hazard, String level) {
    if (level == 'HIGH') {
      switch (hazard.toLowerCase()) {
        case 'flood':
          return 'Preposition rescue boats and activate CDRRMO evacuation staging in $barangay.';
        case 'fire':
          return 'Deploy BFP patrol and inspect hydrants; enforce firebreak vigilance in $barangay.';
        case 'crime':
          return 'Increase PNP mobile visibility and establish checkpoint security in $barangay.';
        default:
          return 'Deploy traffic marshals and emergency response units on major corridors in $barangay.';
      }
    } else if (level == 'MODERATE') {
      return 'Maintain heightened monitoring and broadcast safety advisories to residents of $barangay.';
    }
    return 'Routine surveillance and community disaster preparedness logging active in $barangay.';
  }

  String _generateAISummary(List<HighRiskAreaPrediction> ranked, String overallLevel) {
    if (ranked.isEmpty) return 'No incident trends detected. System is in baseline standby.';
    final topArea = ranked.first;
    return 'Predictive AI identifies ${topArea.barangay} as the highest priority sector '
        '(Risk Score: ${topArea.riskScore}%, Hazard: ${topArea.primaryHazard}). '
        'Overall city risk level is $overallLevel. Immediate LGU mitigation recommended.';
  }

  PredictiveAnalysisResult _generateBaselineResult() {
    final now = DateTime.now();
    final DateFormat monthFormat = DateFormat('MMM');

    List<IncidentTrendPoint> baselinePoints = [];
    for (int i = 5; i >= 0; i--) {
      baselinePoints.add(IncidentTrendPoint(
        month: monthFormat.format(DateTime(now.year, now.month - i, 1)),
        historicalCount: 2 + i * 3,
        projectedCount: 2 + i * 3,
        isProjected: false,
      ));
    }
    for (int h = 1; h <= 2; h++) {
      baselinePoints.add(IncidentTrendPoint(
        month: monthFormat.format(DateTime(now.year, now.month + h, 1)),
        historicalCount: 0,
        projectedCount: 18 + h * 4,
        isProjected: true,
      ));
    }

    final baselineAreas = [
      HighRiskAreaPrediction(
        rank: 1,
        barangay: 'Virac (Capital)',
        riskScore: 84.5,
        riskLevel: 'HIGH',
        primaryHazard: 'Flood',
        incidentCount: 16,
        probabilityPercentage: 88.0,
        recommendation: 'Preposition CDRRMO rescue boats along coastal lowlands.',
      ),
      HighRiskAreaPrediction(
        rank: 2,
        barangay: 'San Andres (Calolbon)',
        riskScore: 78.2,
        riskLevel: 'HIGH',
        primaryHazard: 'Typhoon/Flood',
        incidentCount: 14,
        probabilityPercentage: 82.5,
        recommendation: 'Alert coastal barangay response teams and inspect seawalls.',
      ),
      HighRiskAreaPrediction(
        rank: 3,
        barangay: 'Bato',
        riskScore: 61.0,
        riskLevel: 'MODERATE',
        primaryHazard: 'Accident',
        incidentCount: 9,
        probabilityPercentage: 64.0,
        recommendation: 'Deploy highway marshals along Bato-Virac national road.',
      ),
    ];

    return PredictiveAnalysisResult(
      overallRiskLevel: 'HIGH',
      averageRiskScore: 74.5,
      trendPoints: baselinePoints,
      highRiskAreas: baselineAreas,
      incidentsByType: {'Fire': 6, 'Flood': 14, 'Crime': 3, 'Accident': 8, 'Other': 2},
      aiSummary: 'Predictive simulation active. Virac (Capital) and San Andres identified as high-priority sectors.',
      generatedAt: now,
    );
  }
}
