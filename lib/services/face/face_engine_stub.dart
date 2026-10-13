import 'face_engine.dart';

/// Web build: browsers can't run ML Kit / TFLite through these plugins, so the
/// engine reports "unavailable" and the admin verifies the photos by eye.
class _StubFaceEngine implements FaceEngine {
  @override
  bool get canDetect => false;

  @override
  bool get canMatch => false;

  @override
  Future<void> init() async {}

  @override
  Future<FaceAnalysis> analyze(String imagePath) async => FaceAnalysis.none;

  @override
  Future<double?> matchScore({
    required String idPath,
    required FaceAnalysis idFace,
    required String selfiePath,
    required FaceAnalysis selfieFace,
  }) async =>
      null;

  @override
  Future<void> dispose() async {}
}

FaceEngine createFaceEngine() => _StubFaceEngine();
