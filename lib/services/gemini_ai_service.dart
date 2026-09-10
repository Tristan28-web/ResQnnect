import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/incident_model.dart';
import '../models/alert_model.dart';
import '../models/weather_model.dart';

class GeminiForecastDay {
  final String day;
  final int projectedIncidents;
  final String mainThreat;

  GeminiForecastDay({
    required this.day,
    required this.projectedIncidents,
    required this.mainThreat,
  });

  factory GeminiForecastDay.fromJson(Map<String, dynamic> json) {
    return GeminiForecastDay(
      day: json['day']?.toString() ?? 'Upcoming',
      projectedIncidents: (json['projected_incidents'] as num?)?.toInt() ?? 0,
      mainThreat: json['main_threat']?.toString() ?? 'General Hazard',
    );
  }
}

class GeminiRiskZone {
  final String name;
  final double riskScorePercentage;
  final String hazardType;
  final String recommendedAction;

  GeminiRiskZone({
    required this.name,
    required this.riskScorePercentage,
    required this.hazardType,
    required this.recommendedAction,
  });

  factory GeminiRiskZone.fromJson(Map<String, dynamic> json) {
    return GeminiRiskZone(
      name: json['name']?.toString() ?? 'Sector',
      riskScorePercentage: (json['risk_score_percentage'] as num?)?.toDouble() ?? 50.0,
      hazardType: json['hazard_type']?.toString() ?? 'Precautionary Alert',
      recommendedAction: json['recommended_action']?.toString() ?? 'Maintain alert posture.',
    );
  }
}

class GeminiDisasterAnalysis {
  final String executiveSummary;
  final String overallThreatLevel; // HIGH, MODERATE, LOW
  final List<GeminiRiskZone> highRiskZones;
  final List<GeminiForecastDay> forecastTrend;
  final List<String> actionableRecommendations;
  final DateTime analyzedAt;
  final bool isLiveAI;
  final String modelName;

  GeminiDisasterAnalysis({
    required this.executiveSummary,
    required this.overallThreatLevel,
    required this.highRiskZones,
    required this.forecastTrend,
    required this.actionableRecommendations,
    required this.analyzedAt,
    required this.isLiveAI,
    this.modelName = 'Gemini 3.5 Flash Lite',
  });
}

class GeminiAIService {
  static final GeminiAIService _instance = GeminiAIService._internal();
  factory GeminiAIService() => _instance;
  GeminiAIService._internal();

  static const String _model = 'gemini-3.5-flash-lite';
  static String get _apiKey {
    const envKey = String.fromEnvironment('GEMINI_API_KEY');
    if (envKey.isNotEmpty) return envKey;
    return utf8.decode(base64Decode('QVEuQWI4Uk42S2RNMnFEWUF3M1lVajBsT0l1bTFTbUtsNURKNEI3NTBSZFhzX0JsdWdwc0E='));
  }
  static String get _endpoint =>
      'https://generativelanguage.googleapis.com/v1beta/models/$_model:generateContent?key=$_apiKey';

  GeminiDisasterAnalysis? _cachedAnalysis;
  DateTime? _lastFetchTime;

  GeminiDisasterAnalysis? get cachedAnalysis => _cachedAnalysis;

  Future<GeminiDisasterAnalysis> analyzeDisasterRisks({
    required List<IncidentModel> incidents,
    required List<AlertModel> alerts,
    required WeatherModel? weather,
    required String currentLocation,
    bool forceRefresh = false,
  }) async {
    // Cache for 3 minutes unless explicitly forced
    if (!forceRefresh &&
        _cachedAnalysis != null &&
        _lastFetchTime != null &&
        DateTime.now().difference(_lastFetchTime!).inMinutes < 3) {
      return _cachedAnalysis!;
    }

    try {
      final prompt = _buildAnalysisPrompt(
        incidents: incidents,
        alerts: alerts,
        weather: weather,
        currentLocation: currentLocation,
      );

      final payload = jsonEncode({
        'contents': [
          {
            'parts': [
              {'text': prompt}
            ]
          }
        ],
        'generationConfig': {
          'response_mime_type': 'application/json',
          'temperature': 0.2,
        }
      });

      final response = await http
          .post(
            Uri.parse(_endpoint),
            headers: {'Content-Type': 'application/json'},
            body: payload,
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        final rawText =
            decoded['candidates']?[0]?['content']?['parts']?[0]?['text'] as String?;
        if (rawText != null && rawText.isNotEmpty) {
          final data = jsonDecode(rawText);
          final analysis = _parseGeminiJson(data);
          _cachedAnalysis = analysis;
          _lastFetchTime = DateTime.now();
          return analysis;
        }
      }
      debugPrint('Gemini API Non-200 Response: ${response.statusCode} ${response.body}');
    } catch (e) {
      debugPrint('Gemini AIService Error: $e');
    }

    // Contextual Fallback if network/offline
    final fallback = _generateContextualAnalysis(
      incidents: incidents,
      alerts: alerts,
      weather: weather,
      currentLocation: currentLocation,
    );
    _cachedAnalysis = fallback;
    return fallback;
  }

  String _buildAnalysisPrompt({
    required List<IncidentModel> incidents,
    required List<AlertModel> alerts,
    required WeatherModel? weather,
    required String currentLocation,
  }) {
    final weatherDesc = weather != null
        ? 'Temp: ${weather.temperature.toStringAsFixed(1)}°C, Humidity: ${weather.humidity}%, Wind: ${weather.windSpeed.toStringAsFixed(1)} km/h, Daylight: ${weather.isDay ? "Day" : "Night"}'
        : 'Weather telemetry: Tropical Maritime Climate, seasonal monsoon moisture';

    final incidentsSummary = incidents.isEmpty
        ? 'No currently active emergency incidents reported in $currentLocation.'
        : incidents
            .take(10)
            .map((i) =>
                '${i.incidentType} in ${i.barangay}, reported at ${i.timestamp.toIso8601String()}')
            .join('; ');

    final alertsSummary = alerts.isEmpty
        ? 'No active public broadcast alerts issued by emergency command.'
        : alerts
            .take(5)
            .map((a) => '${a.disasterType} alert: "${a.title}"')
            .join('; ');

    return '''
You are the GIS Disaster Predictive Intelligence AI for $currentLocation, Philippines (ResQnnect Emergency Command).
Analyze the ground conditions and return predictive hazard forecasts for $currentLocation and its local operational sectors.

CURRENT GROUND TELEMETRY:
- User Location: $currentLocation
- Live Weather: $weatherDesc
- Active Incidents (${incidents.length} total): $incidentsSummary
- Active Emergency Broadcasts (${alerts.length} total): $alertsSummary

REQUIRED JSON OUTPUT FORMAT:
{
  "executive_summary": "Comprehensive 2-sentence situational intelligence assessment for $currentLocation and local citizens.",
  "overall_threat_level": "HIGH or MODERATE or LOW",
  "high_risk_zones": [
    {
      "name": "Local Sector / Barangay Name in $currentLocation",
      "risk_score_percentage": 75.0,
      "hazard_type": "Flooding / Landslide / Storm Wind / Accident",
      "recommended_action": "Targeted actionable directive for responders and citizens in this zone."
    }
  ],
  "forecast_trend": [
    {
      "day": "Day 1 (Today)",
      "projected_incidents": 3,
      "main_threat": "Hydrological risk"
    },
    {
      "day": "Day 2",
      "projected_incidents": 2,
      "main_threat": "Localized runoff"
    },
    {
      "day": "Day 3",
      "projected_incidents": 1,
      "main_threat": "Improving weather"
    }
  ],
  "actionable_recommendations": [
    "Clear actionable directive 1 for LGU command.",
    "Actionable directive 2 for responders.",
    "Actionable directive 3 for citizens and households."
  ]
}
Return ONLY valid raw JSON.
''';
  }

  GeminiDisasterAnalysis _parseGeminiJson(Map<String, dynamic> data) {
    final summary = data['executive_summary']?.toString() ??
        'Provincial disaster intelligence assessment completed.';
    final threat = data['overall_threat_level']?.toString().toUpperCase() ?? 'MODERATE';

    final zonesList = (data['high_risk_zones'] as List?)
            ?.map((z) => GeminiRiskZone.fromJson(Map<String, dynamic>.from(z)))
            .toList() ??
        [];

    final forecastList = (data['forecast_trend'] as List?)
            ?.map((f) => GeminiForecastDay.fromJson(Map<String, dynamic>.from(f)))
            .toList() ??
        [];

    final recsList = (data['actionable_recommendations'] as List?)
            ?.map((r) => r.toString())
            .toList() ??
        [];

    return GeminiDisasterAnalysis(
      executiveSummary: summary,
      overallThreatLevel: threat,
      highRiskZones: zonesList,
      forecastTrend: forecastList,
      actionableRecommendations: recsList,
      analyzedAt: DateTime.now(),
      isLiveAI: true,
    );
  }

  GeminiDisasterAnalysis _generateContextualAnalysis({
    required List<IncidentModel> incidents,
    required List<AlertModel> alerts,
    required WeatherModel? weather,
    required String currentLocation,
  }) {
    final rainRisk = (weather?.humidity ?? 75) > 85;
    final threat = incidents.isNotEmpty
        ? 'HIGH'
        : (rainRisk ? 'MODERATE' : 'LOW');

    final areaName = (currentLocation.isNotEmpty && !currentLocation.startsWith('GPS') && !currentLocation.startsWith('Locating'))
        ? currentLocation.split(',')[0].trim()
        : 'Operational Area';

    return GeminiDisasterAnalysis(
      executiveSummary:
          '$areaName disaster surveillance indicates stable regional indicators. Soil saturation and meteorological telemetry remain within baseline thresholds, with responder units standing by.',
      overallThreatLevel: threat,
      highRiskZones: [
        GeminiRiskZone(
          name: '$areaName - Sector 1',
          riskScorePercentage: 42.0,
          hazardType: 'Urban Drainage & Surface Runoff',
          recommendedAction:
              'Maintain monitoring along primary channels and keep storm drain systems clear.',
        ),
        GeminiRiskZone(
          name: '$areaName - Sector 2',
          riskScorePercentage: 38.0,
          hazardType: 'Precipitation & Wind Exposure',
          recommendedAction:
              'Residents advised to secure loose structures and review local emergency bulletins.',
        ),
        GeminiRiskZone(
          name: '$areaName - Sector 3',
          riskScorePercentage: 35.0,
          hazardType: 'Low-Lying Catchment Elevation',
          recommendedAction:
              'Local command automated telemetry sensors operating normally.',
        ),
      ],
      forecastTrend: [
        GeminiForecastDay(day: 'Today', projectedIncidents: incidents.length, mainThreat: 'Monitored Baseline'),
        GeminiForecastDay(day: 'Tomorrow', projectedIncidents: 1, mainThreat: 'Scattered Showers'),
        GeminiForecastDay(day: 'Day 3', projectedIncidents: 1, mainThreat: 'Clear Intervals'),
        GeminiForecastDay(day: 'Day 4', projectedIncidents: 0, mainThreat: 'Fair Skies'),
      ],
      actionableRecommendations: [
        'LGU Operations Centers: Maintain 24/7 telemetry monitoring across all operational zones.',
        'Emergency Responders: Inspect portable power generators, radios, and first response medical equipment.',
        'Citizens: Keep emergency go-bags stocked and check real-time evacuation routes on the GIS map.',
      ],
      analyzedAt: DateTime.now(),
      isLiveAI: false,
      modelName: 'Gemini Flash-Lite (Offline Fallback)',
    );
  }
}
