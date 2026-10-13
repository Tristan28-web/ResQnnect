import 'dart:async';
import 'dart:typed_data';

import 'package:app_settings/app_settings.dart';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

import '../core/constants.dart';
import '../services/face/face_engine.dart';

enum IdentityCaptureMode { idCard, selfieLiveness }

/// What the capture screen hands back to the verification form.
class IdentityCaptureResult {
  final XFile file;
  final Uint8List bytes;
  final FaceAnalysis face;

  /// Selfie only: every challenge (look straight / turn head / close eyes) was
  /// passed. False when the platform can't run face detection (web).
  final bool livenessPassed;

  const IdentityCaptureResult({
    required this.file,
    required this.bytes,
    required this.face,
    this.livenessPassed = false,
  });
}

enum _Challenge { straight, turnHead, closeEyes }

/// Live-camera-only capture (no gallery picker, so photos can't be uploaded
/// from elsewhere). ID mode checks a portrait is visible on the card; selfie
/// mode walks the user through look-straight → turn-head → close-eyes prompts
/// that a still photo can't answer.
class IdentityCameraScreen extends StatefulWidget {
  final IdentityCaptureMode mode;
  final FaceEngine engine;

  const IdentityCameraScreen({super.key, required this.mode, required this.engine});

  @override
  State<IdentityCameraScreen> createState() => _IdentityCameraScreenState();
}

class _IdentityCameraScreenState extends State<IdentityCameraScreen> {
  CameraController? _controller;
  String? _error;
  bool _permissionIssue = false;
  bool _busy = false;
  String? _feedback;
  int _countdown = 0;

  final List<_Challenge> _challenges = const [_Challenge.straight, _Challenge.turnHead, _Challenge.closeEyes];
  int _challengeIndex = 0;
  XFile? _straightShot;
  FaceAnalysis _straightFace = FaceAnalysis.none;

  bool get _isSelfie => widget.mode == IdentityCaptureMode.selfieLiveness;

  @override
  void initState() {
    super.initState();
    _initCamera();
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  Future<void> _initCamera() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        setState(() => _error = 'No camera found on this device.');
        return;
      }
      final wanted = _isSelfie ? CameraLensDirection.front : CameraLensDirection.back;
      final camera = cameras.firstWhere(
        (c) => c.lensDirection == wanted,
        orElse: () => cameras.first,
      );
      final controller = CameraController(camera, ResolutionPreset.high, enableAudio: false);
      await controller.initialize();
      if (!mounted) {
        await controller.dispose();
        return;
      }
      setState(() => _controller = controller);
    } on CameraException catch (e) {
      if (!mounted) return;
      final denied = e.code.toLowerCase().contains('permission') || e.code.toLowerCase().contains('denied');
      setState(() {
        _permissionIssue = denied;
        _error = denied
            ? 'Camera permission is required to verify your identity.'
            : 'Could not start the camera (${e.code}).';
      });
    } catch (e) {
      if (mounted) setState(() => _error = 'Could not start the camera: $e');
    }
  }

  // ---------------------------------------------------------------- capture

  Future<void> _captureId() async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _feedback = null;
    });
    try {
      final shot = await _controller!.takePicture();
      final face = await widget.engine.analyze(shot.path);

      if (widget.engine.canDetect && !face.hasFace) {
        _fail('No portrait found on the ID. Place the whole ID inside the frame, avoid glare, and retake.');
        return;
      }
      final bytes = await shot.readAsBytes();
      if (!mounted) return;
      Navigator.pop(context, IdentityCaptureResult(file: shot, bytes: bytes, face: face));
    } catch (e) {
      _fail('Capture failed: $e');
    }
  }

  Future<void> _runChallenge() async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _feedback = null;
    });

    for (var i = 3; i >= 1; i--) {
      if (!mounted) return;
      setState(() => _countdown = i);
      await Future.delayed(const Duration(seconds: 1));
    }
    if (!mounted) return;
    setState(() => _countdown = 0);

    try {
      final challenge = _challenges[_challengeIndex];
      final shot = await _controller!.takePicture();

      if (!widget.engine.canDetect) {
        // Web / unsupported: no automatic liveness, take one frontal photo and
        // let the admin judge it.
        final bytes = await shot.readAsBytes();
        if (!mounted) return;
        Navigator.pop(
          context,
          IdentityCaptureResult(file: shot, bytes: bytes, face: FaceAnalysis.none, livenessPassed: false),
        );
        return;
      }

      final face = await widget.engine.analyze(shot.path);
      final problem = _checkChallenge(challenge, face);
      if (problem != null) {
        _fail(problem);
        return;
      }

      if (challenge == _Challenge.straight) {
        _straightShot = shot;
        _straightFace = face;
      }

      if (_challengeIndex == _challenges.length - 1) {
        final bytes = await _straightShot!.readAsBytes();
        if (!mounted) return;
        Navigator.pop(
          context,
          IdentityCaptureResult(
            file: _straightShot!,
            bytes: bytes,
            face: _straightFace,
            livenessPassed: true,
          ),
        );
      } else {
        setState(() {
          _challengeIndex++;
          _busy = false;
          _feedback = 'Nice! Next step.';
        });
      }
    } catch (e) {
      _fail('Capture failed: $e');
    }
  }

  /// Returns a user-facing reason if the photo doesn't satisfy [c], else null.
  String? _checkChallenge(_Challenge c, FaceAnalysis f) {
    if (!f.hasFace) return 'No face detected. Move closer, face the camera and make sure the light is on your face.';
    if (!f.singleFace) return 'More than one face detected. Only you should be in the frame.';

    final yaw = (f.headYaw ?? 0).abs();
    final left = f.leftEyeOpen;
    final right = f.rightEyeOpen;

    switch (c) {
      case _Challenge.straight:
        if (yaw > 15) return 'Look straight at the camera.';
        if ((left != null && left < 0.5) || (right != null && right < 0.5)) {
          return 'Keep your eyes open and look at the camera.';
        }
        return null;
      case _Challenge.turnHead:
        return yaw >= 20 ? null : 'Turn your head clearly to one side, then try again.';
      case _Challenge.closeEyes:
        final closed = (left != null && left < 0.4) && (right != null && right < 0.4);
        return closed ? null : 'Eyes should be closed when the countdown ends. Try again.';
    }
  }

  void _fail(String message) {
    if (!mounted) return;
    setState(() {
      _busy = false;
      _feedback = message;
    });
  }

  String get _instruction {
    if (!_isSelfie) return 'Fit the front of your ID inside the frame, then capture.';
    if (!widget.engine.canDetect) return 'Center your face in the oval and capture.';
    switch (_challenges[_challengeIndex]) {
      case _Challenge.straight:
        return 'Step 1 of 3: Look straight at the camera.';
      case _Challenge.turnHead:
        return 'Step 2 of 3: Turn your head to either side when the countdown ends.';
      case _Challenge.closeEyes:
        return 'Step 3 of 3: Close your eyes when the countdown ends.';
    }
  }

  // --------------------------------------------------------------------- UI

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        elevation: 0,
        title: Text(
          _isSelfie ? 'LIVE SELFIE' : 'SCAN YOUR ID',
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w900, letterSpacing: 1.3),
        ),
      ),
      body: SafeArea(child: _buildBody()),
    );
  }

  Widget _buildBody() {
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.no_photography_rounded, color: Colors.white70, size: 56),
              const SizedBox(height: 16),
              Text(_error!, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white, fontSize: 14)),
              const SizedBox(height: 20),
              if (_permissionIssue)
                ElevatedButton(
                  onPressed: () => AppSettings.openAppSettings(),
                  child: const Text('OPEN SETTINGS'),
                ),
            ],
          ),
        ),
      );
    }

    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) {
      return const Center(child: CircularProgressIndicator(color: AppColors.retroMint));
    }

    final portrait = MediaQuery.of(context).orientation == Orientation.portrait;
    final ratio = controller.value.aspectRatio;
    final previewRatio = portrait ? 1 / ratio : ratio;

    return Column(
      children: [
        Expanded(
          child: Center(
            child: AspectRatio(
              aspectRatio: previewRatio,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  CameraPreview(controller),
                  CustomPaint(painter: _FrameOverlayPainter(oval: _isSelfie)),
                  if (_countdown > 0)
                    Center(
                      child: Text(
                        '$_countdown',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 96,
                          fontWeight: FontWeight.w900,
                          shadows: [Shadow(blurRadius: 12, color: Colors.black87)],
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
        Container(
          width: double.infinity,
          color: Colors.black,
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _instruction,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w700),
              ),
              if (_feedback != null) ...[
                const SizedBox(height: 8),
                Text(
                  _feedback!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Color(0xFFFCA5A5), fontSize: 12, fontWeight: FontWeight.w600),
                ),
              ],
              const SizedBox(height: 14),
              GestureDetector(
                onTap: _busy ? null : (_isSelfie ? _runChallenge : _captureId),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  decoration: BoxDecoration(
                    color: _busy ? Colors.grey : AppColors.retroMint,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white, width: 1.6),
                  ),
                  child: Center(
                    child: _busy
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                          )
                        : Text(
                            _isSelfie && widget.engine.canDetect ? 'START' : 'CAPTURE',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1.2,
                            ),
                          ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Dims everything except a card-shaped (ID) or oval (face) window.
class _FrameOverlayPainter extends CustomPainter {
  final bool oval;
  _FrameOverlayPainter({required this.oval});

  @override
  void paint(Canvas canvas, Size size) {
    final Rect window;
    if (oval) {
      final w = size.width * 0.72;
      window = Rect.fromCenter(center: size.center(Offset.zero), width: w, height: w * 1.3);
    } else {
      final w = size.width * 0.9;
      window = Rect.fromCenter(center: size.center(Offset.zero), width: w, height: w / 1.586);
    }

    final shape = oval ? (Path()..addOval(window)) : (Path()..addRRect(RRect.fromRectXY(window, 14, 14)));
    final dim = Path.combine(PathOperation.difference, Path()..addRect(Offset.zero & size), shape);

    canvas.drawPath(dim, Paint()..color = Colors.black.withOpacity(0.55));
    canvas.drawPath(
      shape,
      Paint()
        ..color = AppColors.retroMint
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3,
    );
  }

  @override
  bool shouldRepaint(covariant _FrameOverlayPainter old) => old.oval != oval;
}
