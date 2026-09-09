class IncidentTrendPoint {
  final String month; // e.g. "Jan", "Feb", "Mar"
  final int historicalCount;
  final int projectedCount;
  final bool isProjected;

  IncidentTrendPoint({
    required this.month,
    required this.historicalCount,
    required this.projectedCount,
    this.isProjected = false,
  });

  Map<String, dynamic> toMap() => {
    'month': month,
    'historical_count': historicalCount,
    'projected_count': projectedCount,
    'is_projected': isProjected,
  };
}

class HighRiskAreaPrediction {
  final int rank; // 1, 2, 3...
  final String barangay;
  final double riskScore; // 0.0 - 100.0
  final String riskLevel; // 'HIGH', 'MODERATE', 'LOW'
  final String primaryHazard; // 'Flood', 'Fire', 'Crime', 'Accident'
  final int incidentCount;
  final double probabilityPercentage; // 0 - 100%
  final String recommendation;

  HighRiskAreaPrediction({
    required this.rank,
    required this.barangay,
    required this.riskScore,
    required this.riskLevel,
    required this.primaryHazard,
    required this.incidentCount,
    required this.probabilityPercentage,
    required this.recommendation,
  });

  Map<String, dynamic> toMap() => {
    'rank': rank,
    'barangay': barangay,
    'risk_score': riskScore,
    'risk_level': riskLevel,
    'primary_hazard': primaryHazard,
    'incident_count': incidentCount,
    'probability_percentage': probabilityPercentage,
    'recommendation': recommendation,
  };
}

class PredictiveAnalysisResult {
  final String overallRiskLevel; // 'HIGH', 'MODERATE', 'LOW'
  final double averageRiskScore;
  final List<IncidentTrendPoint> trendPoints;
  final List<HighRiskAreaPrediction> highRiskAreas;
  final Map<String, int> incidentsByType;
  final String aiSummary;
  final DateTime generatedAt;

  PredictiveAnalysisResult({
    required this.overallRiskLevel,
    required this.averageRiskScore,
    required this.trendPoints,
    required this.highRiskAreas,
    required this.incidentsByType,
    required this.aiSummary,
    required this.generatedAt,
  });
}
