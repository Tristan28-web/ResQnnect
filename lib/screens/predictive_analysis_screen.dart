import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../services/firestore_service.dart';
import '../services/weather_service.dart';
import '../services/location_service.dart';
import '../services/gemini_ai_service.dart';
import '../models/incident_model.dart';
import '../models/alert_model.dart';
import '../models/weather_model.dart';
import '../core/constants.dart';

class PredictiveAnalysisScreen extends StatefulWidget {
  const PredictiveAnalysisScreen({super.key});

  @override
  State<PredictiveAnalysisScreen> createState() => _PredictiveAnalysisScreenState();
}

class _PredictiveAnalysisScreenState extends State<PredictiveAnalysisScreen> {
  final GeminiAIService _aiService = GeminiAIService();
  GeminiDisasterAnalysis? _analysis;
  bool _isAnalyzing = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _runGeminiAnalysis(forceRefresh: false);
    });
  }

  Future<void> _runGeminiAnalysis({bool forceRefresh = false}) async {
    if (_isAnalyzing) return;
    setState(() {
      _isAnalyzing = true;
      _errorMessage = null;
    });

    try {
      final firestore = Provider.of<FirestoreService>(context, listen: false);
      final weatherService = Provider.of<WeatherService>(context, listen: false);
      final locationService = Provider.of<LocationService>(context, listen: false);

      // Ingest live ground data in parallel
      final incidentsFuture = firestore.getIncidents().first.catchError((_) => <IncidentModel>[]);
      final alertsFuture = firestore.getAlerts().first.catchError((_) => <AlertModel>[]);
      final userPos = locationService.currentPosition ?? await locationService.getCurrentLocation();
      final weatherFuture = (userPos != null
              ? weatherService.getWeatherData(latitude: userPos.latitude, longitude: userPos.longitude)
              : Future<WeatherModel>.error('Current location unavailable'))
          .catchError((_) => WeatherModel(
        temperature: 28.0,
        humidity: 80.0,
        description: 'Mainly Clear',
        isDay: true,
        weatherCode: 2,
        windSpeed: 15.0,
      ));

      final results = await Future.wait([incidentsFuture, alertsFuture, weatherFuture]);
      final incidents = results[0] as List<IncidentModel>;
      final alerts = results[1] as List<AlertModel>;
      final weather = results[2] as WeatherModel?;

      final analysis = await _aiService.analyzeDisasterRisks(
        incidents: incidents,
        alerts: alerts,
        weather: weather,
        currentLocation: locationService.currentLocationName,
        forceRefresh: forceRefresh,
      );

      if (mounted) {
        setState(() {
          _analysis = analysis;
          _isAnalyzing = false;
        });
      }
    } catch (e) {
      debugPrint('Analysis trigger error: $e');
      if (mounted) {
        setState(() {
          _isAnalyzing = false;
          _errorMessage = 'Could not contact Gemini AI: $e';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundBlack : AppColors.retroCream,
      appBar: AppBar(
        title: Text(
          'PREDICTIVE ANALYSIS (AI)',
          style: TextStyle(
            color: isDark ? Colors.white : AppColors.retroDarkBorder,
            fontSize: 14,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.2,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: isDark ? Colors.white : AppColors.retroDarkBorder),
        actions: [
          IconButton(
            icon: Icon(
              Icons.refresh_rounded,
              color: isDark ? Colors.white70 : AppColors.retroDarkBorder,
            ),
            tooltip: 'Re-Analyze with Gemini AI',
            onPressed: () => _runGeminiAnalysis(forceRefresh: true),
          ),
        ],
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Top Hero AI Intelligence Banner
            _buildHeroGeminiBanner(isDark),
            const SizedBox(height: 20),

            // Re-analyze Action Button
            _buildReanalyzeButton(isDark),
            const SizedBox(height: 24),

            // Section 1: High Risk Area Predictions
            _buildSectionHeader(
              title: 'HIGH-RISK AREA PREDICTIONS',
              subtitle: 'AI-evaluated vulnerability by municipal sector',
              icon: Icons.radar_rounded,
              isDark: isDark,
            ),
            const SizedBox(height: 12),
            _buildRiskZonesList(isDark),
            const SizedBox(height: 24),

            // Section 2: 7-Day Forecast Trajectory
            _buildSectionHeader(
              title: 'PREDICTIVE HAZARD TRAJECTORY',
              subtitle: 'Gemini 7-day incident volume projection',
              icon: Icons.auto_graph_rounded,
              isDark: isDark,
            ),
            const SizedBox(height: 12),
            _buildForecastList(isDark),
            const SizedBox(height: 24),

            // Section 3: Actionable Directives
            _buildSectionHeader(
              title: 'ACTIONABLE PDRRMO DIRECTIVES',
              subtitle: 'Tailored guidelines for command and citizens',
              icon: Icons.fact_check_rounded,
              isDark: isDark,
            ),
            const SizedBox(height: 12),
            _buildActionDirectives(isDark),
            const SizedBox(height: 100),
          ],
        ),
      ),
    );
  }

  // --- RETRO HERO GEMINI BANNER ---
  Widget _buildHeroGeminiBanner(bool isDark) {
    final threat = _analysis?.overallThreatLevel ?? 'MODERATE';
    final locationService = Provider.of<LocationService>(context, listen: false);
    final rawLoc = locationService.currentLocationName;
    final areaName = (rawLoc.isNotEmpty && !rawLoc.toLowerCase().contains('disabled') && !rawLoc.toLowerCase().contains('standby') && !rawLoc.toLowerCase().contains('locating'))
        ? rawLoc.split(',')[0].trim()
        : 'Local Operations';
    Color threatBg = const Color(0xFFDCFCE7);
    Color threatText = const Color(0xFF16A34A);

    if (threat == 'HIGH') {
      threatBg = const Color(0xFFFEE2E2);
      threatText = const Color(0xFFDC2626);
    } else if (threat == 'MODERATE') {
      threatBg = AppColors.retroYellow;
      threatText = const Color(0xFFD97706);
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2B2421) : AppColors.retroPeach,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(
          color: isDark ? const Color(0xFF4A3C38) : AppColors.retroDarkBorder,
          width: 2.0,
        ),
        boxShadow: [
          BoxShadow(
            color: isDark ? Colors.black54 : AppColors.retroMintDark,
            offset: const Offset(4, 4),
            blurRadius: 0,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row with Sparkle AI and model badge
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: AppColors.retroMint,
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.retroDarkBorder, width: 1.5),
                    ),
                    child: const Center(
                      child: Icon(Icons.auto_awesome_rounded, size: 18, color: Colors.white),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'DISASTER AI INTEL',
                        style: TextStyle(
                          color: isDark ? Colors.white : AppColors.retroDarkBorder,
                          fontSize: 13,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.5,
                        ),
                      ),
                      Text(
                        '$areaName Operations',
                        style: TextStyle(
                          color: isDark ? Colors.white60 : const Color(0xFF6B7280),
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              // Threat Level Badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: threatBg,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.retroDarkBorder, width: 1.4),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 7,
                      height: 7,
                      decoration: BoxDecoration(
                        color: threatText,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '$threat RISK',
                      style: TextStyle(
                        color: threatText,
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Real AI Executive Summary
          Text(
            _isAnalyzing
                ? 'Synthesizing ground data, live rainfall telemetry, and incident history using Google Gemini Flash Lite...'
                : (_analysis?.executiveSummary ??
                    'Continuous telemetry analysis active across $areaName and surrounding operational zones.'),
            style: TextStyle(
              color: isDark ? Colors.white : AppColors.retroDarkBorder,
              fontSize: 13,
              fontWeight: FontWeight.w700,
              height: 1.45,
            ),
          ),

          const SizedBox(height: 14),

          // Footer tag
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.retroMintLight,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.retroDarkBorder, width: 1.2),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.bolt_rounded, size: 12, color: AppColors.retroMintDark),
                    const SizedBox(width: 4),
                    Text(
                      _analysis?.modelName ?? 'Google Gemini 3.5 Flash Lite',
                      style: const TextStyle(
                        color: AppColors.retroDarkBorder,
                        fontSize: 9,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
              if (_analysis != null)
                Text(
                  'Updated ${DateFormat('h:mm a').format(_analysis!.analyzedAt)}',
                  style: TextStyle(
                    color: isDark ? Colors.white38 : const Color(0xFF9CA3AF),
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  // --- RE-ANALYZE RETRO BUTTON ---
  Widget _buildReanalyzeButton(bool isDark) {
    return GestureDetector(
      onTap: () => _runGeminiAnalysis(forceRefresh: true),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: _isAnalyzing
              ? (isDark ? const Color(0xFF262C38) : const Color(0xFFE5E7EB))
              : AppColors.retroMint,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.retroDarkBorder, width: 1.8),
          boxShadow: [
            if (!_isAnalyzing)
              BoxShadow(
                color: isDark ? Colors.black45 : AppColors.retroDarkBorder.withOpacity(0.15),
                offset: const Offset(3, 3),
                blurRadius: 0,
              ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (_isAnalyzing) ...[
              const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2.2,
                  color: AppColors.retroDarkBorder,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                'GEMINI AI COMPUTING PREDICTIONS...',
                style: TextStyle(
                  color: isDark ? Colors.white70 : AppColors.retroDarkBorder,
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.6,
                ),
              ),
            ] else ...[
              const Icon(Icons.flash_on_rounded, size: 18, color: Colors.white),
              const SizedBox(width: 8),
              const Text(
                'GENERATE REAL-TIME AI RISK REPORT',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.6,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // --- SECTION HEADER ---
  Widget _buildSectionHeader({
    required String title,
    required String subtitle,
    required IconData icon,
    required bool isDark,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF262C38) : AppColors.retroLilac,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.retroDarkBorder, width: 1.2),
              ),
              child: Icon(icon, size: 14, color: isDark ? Colors.white : AppColors.retroDarkBorder),
            ),
            const SizedBox(width: 8),
            Text(
              title,
              style: TextStyle(
                color: isDark ? Colors.white : AppColors.retroDarkBorder,
                fontSize: 13,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Padding(
          padding: const EdgeInsets.only(left: 28),
          child: Text(
            subtitle,
            style: TextStyle(
              color: isDark ? Colors.white60 : const Color(0xFF6B7280),
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  // --- RISK ZONES LIST ---
  Widget _buildRiskZonesList(bool isDark) {
    final zones = _analysis?.highRiskZones ?? [];
    if (zones.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? AppColors.retroDarkCard : Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.retroDarkBorder, width: 1.5),
        ),
        child: const Center(
          child: Text(
            'No elevated risk zones identified at this time.',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
          ),
        ),
      );
    }

    return Column(
      children: zones.map((zone) {
        final pct = zone.riskScorePercentage.clamp(0.0, 100.0);
        Color barColor = AppColors.retroMint;
        if (pct >= 70) {
          barColor = const Color(0xFFEF4444);
        } else if (pct >= 40) {
          barColor = const Color(0xFFF59E0B);
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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Hazard chip
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.retroPeach,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.retroDarkBorder, width: 1.2),
                    ),
                    child: Text(
                      zone.hazardType.toUpperCase(),
                      style: const TextStyle(
                        color: AppColors.retroDarkBorder,
                        fontSize: 9,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Zone name + RISK label stacked
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          zone.name,
                          style: TextStyle(
                            color: isDark ? Colors.white : AppColors.retroDarkBorder,
                            fontSize: 13,
                            fontWeight: FontWeight.w900,
                          ),
                          softWrap: true,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${pct.toStringAsFixed(0)}% RISK',
                          style: TextStyle(
                            color: barColor,
                            fontSize: 11,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              // Progress Bar
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: Container(
                  height: 8,
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF2E3544) : const Color(0xFFF3F4F6),
                    border: Border.all(
                      color: isDark ? Colors.white12 : AppColors.retroDarkBorder.withOpacity(0.2),
                      width: 0.8,
                    ),
                  ),
                  child: FractionallySizedBox(
                    alignment: Alignment.centerLeft,
                    widthFactor: pct / 100.0,
                    child: Container(color: barColor),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                zone.recommendedAction,
                style: TextStyle(
                  color: isDark ? Colors.white70 : const Color(0xFF4B5563),
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  height: 1.35,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  // --- 7-DAY FORECAST LIST ---
  Widget _buildForecastList(bool isDark) {
    final forecast = _analysis?.forecastTrend ?? [];
    if (forecast.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: -20),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        clipBehavior: Clip.none,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Row(
          children: forecast.map((f) {
            return Container(
              width: 140,
              margin: const EdgeInsets.only(right: 12, bottom: 4),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: isDark ? AppColors.retroDarkCard : Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: isDark ? const Color(0xFF3E4556) : AppColors.retroDarkBorder,
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: isDark ? Colors.black38 : AppColors.retroDarkBorder.withOpacity(0.08),
                    offset: const Offset(2, 2),
                    blurRadius: 0,
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.retroLilac,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.retroDarkBorder, width: 1.0),
                    ),
                    child: Text(
                      f.day.toUpperCase(),
                      style: const TextStyle(
                        color: AppColors.retroDarkBorder,
                        fontSize: 9,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    '${f.projectedIncidents} Incidents',
                    style: TextStyle(
                      color: isDark ? Colors.white : AppColors.retroDarkBorder,
                      fontSize: 15,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    f.mainThreat,
                    style: TextStyle(
                      color: isDark ? Colors.white60 : const Color(0xFF6B7280),
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  // --- ACTION DIRECTIVES ---
  Widget _buildActionDirectives(bool isDark) {
    final recs = _analysis?.actionableRecommendations ?? [];
    if (recs.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      children: recs.map((r) {
        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: isDark ? AppColors.retroDarkCard : AppColors.retroMintLight,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: isDark ? const Color(0xFF3E4556) : AppColors.retroDarkBorder,
              width: 1.5,
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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                margin: const EdgeInsets.only(top: 2),
                width: 18,
                height: 18,
                decoration: BoxDecoration(
                  color: AppColors.retroMint,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.retroDarkBorder, width: 1.2),
                ),
                child: const Center(
                  child: Icon(Icons.check_rounded, size: 12, color: Colors.white),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  r,
                  style: TextStyle(
                    color: isDark ? Colors.white : AppColors.retroDarkBorder,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}
