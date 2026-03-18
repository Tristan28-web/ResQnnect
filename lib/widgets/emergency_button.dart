import 'package:flutter/material.dart';
import '../core/constants.dart';

import 'dart:async';

class EmergencyButton extends StatefulWidget {
  final VoidCallback onTrigger;
  final String label;

  const EmergencyButton({
    super.key,
    required this.onTrigger,
    this.label = 'SOS',
  });

  @override
  State<EmergencyButton> createState() => _EmergencyButtonState();
}

class _EmergencyButtonState extends State<EmergencyButton> with SingleTickerProviderStateMixin {
  Timer? _timer;
  double _progress = 0.0;
  bool _isHolding = false;

  void _startTimer() {
    setState(() {
      _isHolding = true;
      _progress = 0.0;
    });
    
    _timer = Timer.periodic(const Duration(milliseconds: 30), (timer) {
      setState(() {
        _progress += 0.01; // Approx 3 seconds (30ms * 100 = 3000ms)
        if (_progress >= 1.0) {
          _progress = 1.0;
          _timer?.cancel();
          _isHolding = false;
          widget.onTrigger();
        }
      });
    });
  }

  void _cancelTimer() {
    _timer?.cancel();
    setState(() {
      _isHolding = false;
      _progress = 0.0;
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _startTimer(),
      onTapUp: (_) => _cancelTimer(),
      onTapCancel: () => _cancelTimer(),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Outer Progress Ring
          SizedBox(
            width: 220,
            height: 220,
            child: CircularProgressIndicator(
              value: _progress,
              strokeWidth: 8,
              backgroundColor: Colors.white10,
              valueColor: const AlwaysStoppedAnimation<Color>(AppConstants.primaryRed),
            ),
          ),
          // Inner Button
          AnimatedScale(
            scale: _isHolding ? 0.95 : 1.0,
            duration: const Duration(milliseconds: 100),
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppConstants.primaryRed,
                    AppConstants.primaryRed.withOpacity(0.8),
                  ],
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppConstants.primaryRed.withOpacity(_isHolding ? 0.6 : 0.4),
                    spreadRadius: _isHolding ? 12 : 8,
                    blurRadius: 20,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      _isHolding ? Icons.timer : Icons.warning_amber_rounded,
                      color: Colors.white,
                      size: 60,
                    ),
                    const SizedBox(height: 10),
                    Text(
                      _isHolding ? '${(3 - (_progress * 3)).toStringAsFixed(1)}s' : widget.label,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 2,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
