import 'face_engine_stub.dart' if (dart.library.io) 'face_engine_mobile.dart' as impl;

/// Result of running face detection on one photo.
class FaceAnalysis {
  final int faceCount;
  final double? headYaw; // degrees, ~0 when looking straight at the camera
  final double? leftEyeOpen; // 0..1
  final double? rightEyeOpen; // 0..1
  final FaceBox? box;

  /// Eye centres (pixels, upright image). Used to align the face before
  /// matching. Order is not significant. Null if the detector found no landmarks.
  final FacePoint? eyeA;
  final FacePoint? eyeB;

  const FaceAnalysis({
    required this.faceCount,
    this.headYaw,
    this.leftEyeOpen,
    this.rightEyeOpen,
    this.box,
    this.eyeA,
    this.eyeB,
  });

  bool get hasFace => faceCount > 0 && box != null;
  bool get singleFace => faceCount == 1;

  static const none = FaceAnalysis(faceCount: 0);
}

class FaceBox {
  final double left, top, width, height;
  const FaceBox(this.left, this.top, this.width, this.height);
}

class FacePoint {
  final double x, y;
  const FacePoint(this.x, this.y);
}

/// How confident the on-device matcher is that ID portrait == selfie.
/// Cosine-similarity cut-offs for MobileFaceNet-style embeddings. These are
/// starting values: calibrate them with real ID/selfie pairs before the defense.
enum FaceMatchLevel { strong, review, mismatch, unavailable }

class FaceMatchThresholds {
  static const double strong = 0.60;
  static const double review = 0.45;

  static FaceMatchLevel levelOf(double? score) {
    if (score == null) return FaceMatchLevel.unavailable;
    if (score >= strong) return FaceMatchLevel.strong;
    if (score >= review) return FaceMatchLevel.review;
    return FaceMatchLevel.mismatch;
  }
}

/// Platform-neutral face detection + matching.
/// Android/iOS: Google ML Kit (detection, eyes, head pose) + a TFLite
/// MobileFaceNet embedding model (matching). Web: unsupported, every call
/// degrades gracefully so the admin reviews the photos manually.
abstract class FaceEngine {
  /// Prepares detector and (if the model asset exists) the embedding network.
  Future<void> init();

  /// True when ML Kit detection (liveness checks) can run on this platform.
  bool get canDetect;

  /// True when the embedding model loaded, so [matchScore] returns a number.
  bool get canMatch;

  Future<FaceAnalysis> analyze(String imagePath);

  /// Cosine similarity in [-1, 1] between the two faces, or null if unavailable.
  Future<double?> matchScore({
    required String idPath,
    required FaceAnalysis idFace,
    required String selfiePath,
    required FaceAnalysis selfieFace,
  });

  Future<void> dispose();
}

FaceEngine createFaceEngine() => impl.createFaceEngine();
