import 'package:torch_light/torch_light.dart';
import 'dart:async';
import 'package:flutter/foundation.dart';

class AlertNotificationService {
  static final AlertNotificationService _instance = AlertNotificationService._internal();
  factory AlertNotificationService() => _instance;
  AlertNotificationService._internal();

  static AlertNotificationService get instance => _instance;

  bool _isFlashing = false;

  /// Trigger a SOS/Alert flash sequence (Flashlight + Screen Flash if UI calls it)
  Future<void> flashAlert() async {
    if (_isFlashing) return;
    _isFlashing = true;

    // Flashlight sequence (3 fast pulses)
    if (!kIsWeb && (defaultTargetPlatform == TargetPlatform.android || defaultTargetPlatform == TargetPlatform.iOS)) {
      try {
        final isTorchAvailable = await TorchLight.isTorchAvailable();
        if (isTorchAvailable) {
          for (int i = 0; i < 5; i++) {
            await TorchLight.enableTorch();
            await Future.delayed(const Duration(milliseconds: 150));
            await TorchLight.disableTorch();
            await Future.delayed(const Duration(milliseconds: 150));
          }
        }
      } catch (e) {
        debugPrint('Flashlight error: $e');
      }
    }

    _isFlashing = false;
  }
}
