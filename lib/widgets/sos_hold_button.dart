import 'package:flutter/material.dart';
import 'dart:async';
import '../core/constants.dart';

class SOSHoldButton extends StatefulWidget {
  final VoidCallback onTrigger;
  const SOSHoldButton({super.key, required this.onTrigger});

  @override
  State<SOSHoldButton> createState() => _SOSHoldButtonState();
}

class _SOSHoldButtonState extends State<SOSHoldButton> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  bool _isHolding = false;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    _timer?.cancel();
    super.dispose();
  }

  void _startHold() {
    setState(() => _isHolding = true);
    _controller.forward();
    _timer = Timer(const Duration(seconds: 3), () {
      if (_isHolding) {
        widget.onTrigger();
        _reset();
      }
    });
  }

  void _cancelHold() {
    _reset();
  }

  void _reset() {
    _timer?.cancel();
    _controller.reset();
    if (mounted) {
      setState(() => _isHolding = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onLongPressStart: (_) => _startHold(),
      onLongPressEnd: (_) => _cancelHold(),
      onTapDown: (_) => null, // Prevents accidental tap interference
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Background Glow
          Container(
            width: 180,
            height: 180,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppConstants.primaryRed.withOpacity(0.1),
            ),
          ),
          
          // Outer Progress Ring
          SizedBox(
            width: 150,
            height: 150,
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                return CircularProgressIndicator(
                  value: _controller.value,
                  strokeWidth: 6,
                  backgroundColor: Colors.white10,
                  valueColor: const AlwaysStoppedAnimation<Color>(AppConstants.primaryRed),
                );
              },
            ),
          ),
          
          // Inner Button
          Container(
            width: 130,
            height: 130,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  _isHolding ? AppConstants.primaryRed : const Color(0xFFB71C1C),
                  const Color(0xFF8B0000),
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: AppConstants.primaryRed.withOpacity(_isHolding ? 0.6 : 0.4),
                  blurRadius: _isHolding ? 40 : 30,
                  spreadRadius: _isHolding ? 15 : 10,
                ),
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  _isHolding ? Icons.emergency : Icons.star,
                  color: Colors.white,
                  size: 40,
                ),
                const Text(
                  'SOS',
                  style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                ),
                Text(
                  _isHolding ? 'RELEASING...' : 'HOLD FOR 3S',
                  style: const TextStyle(color: Colors.white60, fontSize: 10),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
