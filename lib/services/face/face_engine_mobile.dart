import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:image/image.dart' as img;
import 'package:tflite_flutter/tflite_flutter.dart';

import 'face_engine.dart';

const String kFaceModelAsset = 'assets/models/mobilefacenet.tflite';
const int _kInputSize = 112;

/// Builds the 112x112 RGB model input (scaled to [-1, 1]) from a full photo.
/// Runs in a background isolate because decoding a 12 MP photo is slow.
///
/// MobileFaceNet expects an *aligned* face: a square of 2.5x the eye distance,
/// rotated so the eyes are level, centred slightly below the eyes. When eye
/// landmarks are available we sample exactly that; otherwise we fall back to a
/// plain bounding-box crop (less accurate).
///
/// args: [bytes, box(l,t,w,h), eyes(ax,ay,bx,by) or null]
Float32List _cropFacePixels(List<Object?> args) {
  final bytes = args[0] as Uint8List;
  final box = args[1] as List<double>;
  final eyes = args[2] as List<double>?;
  final image = img.bakeOrientation(img.decodeImage(bytes)!);

  final out = Float32List(_kInputSize * _kInputSize * 3);

  num sample(double sx, double sy, int channel) {
    // Bilinear sample with edge clamping.
    final x0 = sx.floor().clamp(0, image.width - 1);
    final y0 = sy.floor().clamp(0, image.height - 1);
    final x1 = (x0 + 1).clamp(0, image.width - 1);
    final y1 = (y0 + 1).clamp(0, image.height - 1);
    final fx = (sx - sx.floor()).clamp(0.0, 1.0);
    final fy = (sy - sy.floor()).clamp(0.0, 1.0);
    num px(int x, int y) {
      final p = image.getPixel(x, y);
      return channel == 0 ? p.r : (channel == 1 ? p.g : p.b);
    }

    final top = px(x0, y0) * (1 - fx) + px(x1, y0) * fx;
    final bottom = px(x0, y1) * (1 - fx) + px(x1, y1) * fx;
    return top * (1 - fy) + bottom * fy;
  }

  double cx, cy, size, theta;
  if (eyes != null) {
    // Order eyes left→right in the image so the rotation is well defined.
    var ax = eyes[0], ay = eyes[1], bx = eyes[2], by = eyes[3];
    if (ax > bx) {
      final tx = ax, ty = ay;
      ax = bx;
      ay = by;
      bx = tx;
      by = ty;
    }
    final dx = bx - ax, dy = by - ay;
    theta = math.atan2(dy, dx);
    size = math.sqrt(dx * dx + dy * dy) * 2.5;
    final offsetY = size * 0.15;
    cx = (ax + bx) / 2 - offsetY * math.sin(theta);
    cy = (ay + by) / 2 + offsetY * math.cos(theta);
  } else {
    cx = box[0] + box[2] / 2;
    cy = box[1] + box[3] / 2;
    size = math.max(box[2], box[3]) * 1.25;
    theta = 0;
  }

  final ct = math.cos(theta), st = math.sin(theta);
  var i = 0;
  for (var v = 0; v < _kInputSize; v++) {
    for (var u = 0; u < _kInputSize; u++) {
      final xo = ((u + 0.5) / _kInputSize - 0.5) * size;
      final yo = ((v + 0.5) / _kInputSize - 0.5) * size;
      final sx = cx + xo * ct - yo * st;
      final sy = cy + xo * st + yo * ct;
      for (var c = 0; c < 3; c++) {
        out[i++] = sample(sx, sy, c) / 127.5 - 1.0;
      }
    }
  }
  return out;
}

class _MobileFaceEngine implements FaceEngine {
  FaceDetector? _detector;
  Interpreter? _interpreter;
  int _embeddingSize = 0;

  bool get _platformOk => Platform.isAndroid || Platform.isIOS;

  @override
  bool get canDetect => _detector != null;

  @override
  bool get canMatch => _interpreter != null;

  @override
  Future<void> init() async {
    if (!_platformOk) return;

    _detector = FaceDetector(
      options: FaceDetectorOptions(
        enableClassification: true, // eye-open probabilities for the blink check
        enableLandmarks: true, // eye centres, to align the face for matching
        performanceMode: FaceDetectorMode.accurate,
        minFaceSize: 0.05, // the portrait on an ID card is small in the frame
      ),
    );

    try {
      _interpreter = await Interpreter.fromAsset(kFaceModelAsset);
      _embeddingSize = _interpreter!.getOutputTensor(0).shape.last;
    } catch (e) {
      // Model file not bundled → detection + liveness still work, the admin
      // does the face comparison by eye.
      debugPrint('Face embedding model unavailable ($kFaceModelAsset): $e');
      _interpreter = null;
    }
  }

  @override
  Future<FaceAnalysis> analyze(String imagePath) async {
    final detector = _detector;
    if (detector == null) return FaceAnalysis.none;

    final faces = await detector.processImage(InputImage.fromFilePath(imagePath));
    if (faces.isEmpty) return FaceAnalysis.none;

    // The subject is the largest face in the frame.
    faces.sort((a, b) => (b.boundingBox.width * b.boundingBox.height)
        .compareTo(a.boundingBox.width * a.boundingBox.height));
    final f = faces.first;
    final r = f.boundingBox;
    final le = f.landmarks[FaceLandmarkType.leftEye]?.position;
    final re = f.landmarks[FaceLandmarkType.rightEye]?.position;
    return FaceAnalysis(
      faceCount: faces.length,
      headYaw: f.headEulerAngleY,
      leftEyeOpen: f.leftEyeOpenProbability,
      rightEyeOpen: f.rightEyeOpenProbability,
      box: FaceBox(r.left, r.top, r.width, r.height),
      eyeA: le == null ? null : FacePoint(le.x.toDouble(), le.y.toDouble()),
      eyeB: re == null ? null : FacePoint(re.x.toDouble(), re.y.toDouble()),
    );
  }

  Future<List<double>?> _embed(String path, FaceAnalysis face) async {
    final interpreter = _interpreter;
    final box = face.box;
    if (interpreter == null || box == null) return null;

    final eyes = (face.eyeA != null && face.eyeB != null)
        ? <double>[face.eyeA!.x, face.eyeA!.y, face.eyeB!.x, face.eyeB!.y]
        : null;

    final bytes = await File(path).readAsBytes();
    final pixels = await compute(
      _cropFacePixels,
      <Object?>[bytes, <double>[box.left, box.top, box.width, box.height], eyes],
    );

    final input = [
      List.generate(
        _kInputSize,
        (y) => List.generate(
          _kInputSize,
          (x) {
            final o = (y * _kInputSize + x) * 3;
            return [pixels[o], pixels[o + 1], pixels[o + 2]];
          },
        ),
      ),
    ];
    final output = [List<double>.filled(_embeddingSize, 0.0)];
    interpreter.run(input, output);

    // L2-normalise so a dot product is the cosine similarity.
    final v = output[0];
    final norm = math.sqrt(v.fold<double>(0, (s, e) => s + e * e));
    if (norm == 0) return null;
    return v.map((e) => e / norm).toList();
  }

  @override
  Future<double?> matchScore({
    required String idPath,
    required FaceAnalysis idFace,
    required String selfiePath,
    required FaceAnalysis selfieFace,
  }) async {
    if (!canMatch || !idFace.hasFace || !selfieFace.hasFace) return null;
    try {
      final a = await _embed(idPath, idFace);
      final b = await _embed(selfiePath, selfieFace);
      if (a == null || b == null) return null;
      var dot = 0.0;
      for (var i = 0; i < a.length; i++) {
        dot += a[i] * b[i];
      }
      return dot;
    } catch (e) {
      debugPrint('Face match failed: $e');
      return null;
    }
  }

  @override
  Future<void> dispose() async {
    await _detector?.close();
    _interpreter?.close();
    _detector = null;
    _interpreter = null;
  }
}

FaceEngine createFaceEngine() => _MobileFaceEngine();
