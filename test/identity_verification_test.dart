import 'dart:convert';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:resqnnect/core/image_utils.dart';
import 'package:resqnnect/models/identity_verification_model.dart';
import 'package:resqnnect/models/user_model.dart';
import 'package:resqnnect/services/auth_service.dart';
import 'package:resqnnect/services/face/face_engine.dart';

void main() {
  googleErrorTests();

  group('Accepted Philippine IDs', () {
    test('has no duplicates and primary IDs come first', () {
      expect(kAcceptedIdTypes.toSet().length, kAcceptedIdTypes.length);
      expect(kAcceptedIdTypes.first, 'Philippine National ID (PhilSys)');
      expect(kAcceptedIdTypes.take(kPrimaryIdTypes.length), kPrimaryIdTypes);
    });

    test('contains no private (non-government) IDs', () {
      final joined = kAcceptedIdTypes.join('|').toLowerCase();
      expect(joined.contains('school'), isFalse);
      expect(joined.contains('company'), isFalse);
      expect(joined.contains('student'), isFalse);
    });
  });

  group('Face match thresholds', () {
    test('classifies scores', () {
      expect(FaceMatchThresholds.levelOf(null), FaceMatchLevel.unavailable);
      expect(FaceMatchThresholds.levelOf(0.80), FaceMatchLevel.strong);
      expect(FaceMatchThresholds.levelOf(0.60), FaceMatchLevel.strong);
      expect(FaceMatchThresholds.levelOf(0.50), FaceMatchLevel.review);
      expect(FaceMatchThresholds.levelOf(0.45), FaceMatchLevel.review);
      expect(FaceMatchThresholds.levelOf(0.10), FaceMatchLevel.mismatch);
      expect(FaceMatchThresholds.levelOf(-0.2), FaceMatchLevel.mismatch);
    });

    test('web stub engine degrades to manual review', () async {
      final engine = createFaceEngine();
      await engine.init();
      // Under `flutter test` (dart:io present) this is the mobile engine, which
      // refuses to run on a desktop host, so both capabilities are off.
      expect(engine.canMatch, isFalse);
      final r = await engine.analyze('nonexistent.jpg');
      expect(r.hasFace, isFalse);
      await engine.dispose();
    });
  });

  group('UserModel verification status', () {
    Map<String, dynamic> base() => {
          'user_id': 'u1',
          'name': 'Juan',
          'email': 'juan@example.com',
          'created_at': Timestamp.fromDate(DateTime(2026, 1, 1)),
        };

    test('new citizen without field is unsubmitted', () {
      final u = UserModel.fromMap(base());
      expect(u.isVerified, isFalse);
      expect(u.verificationStatus, 'unsubmitted');
    });

    test('legacy verified account (no status field) is treated as approved', () {
      final u = UserModel.fromMap({...base(), 'is_verified': true});
      expect(u.verificationStatus, 'approved');
    });

    test('pending and rejected round-trip through toMap/fromMap', () {
      final u = UserModel.fromMap({
        ...base(),
        'verification_status': 'rejected',
        'rejection_reason': 'ID is blurry',
      });
      expect(u.verificationStatus, 'rejected');
      final again = UserModel.fromMap(u.toMap());
      expect(again.verificationStatus, 'rejected');
      expect(again.rejectionReason, 'ID is blurry');
    });
  });

  group('IdentityVerificationModel', () {
    test('round-trips including a null score', () {
      final m = IdentityVerificationModel(
        userId: 'u1',
        idType: "Driver's License (LTO)",
        idImageBase64: 'aaa',
        selfieBase64: 'bbb',
        faceMatchScore: null,
        livenessPassed: true,
        faceFoundOnId: true,
        matchEngine: 'manual-review',
        submittedAt: DateTime(2026, 10, 12),
      );
      final back = IdentityVerificationModel.fromMap(m.toMap());
      expect(back.faceMatchScore, isNull);
      expect(back.livenessPassed, isTrue);
      expect(back.idType, "Driver's License (LTO)");
    });

    test('keeps a numeric score', () {
      final back = IdentityVerificationModel.fromMap({
        'user_id': 'u1',
        'face_match_score': 0.73,
        'submitted_at': Timestamp.fromDate(DateTime(2026, 10, 12)),
      });
      expect(back.faceMatchScore, closeTo(0.73, 1e-9));
    });
  });

  group('ImageUtils.processIdentityPhoto', () {
    test('big photo becomes a small decodable JPEG under the Firestore limit', () async {
      // 3000x2000 noisy image, like a phone camera shot.
      final image = img.Image(width: 3000, height: 2000);
      for (var y = 0; y < image.height; y++) {
        for (var x = 0; x < image.width; x++) {
          image.setPixelRgb(x, y, (x * 7 + y) % 256, (x + y * 3) % 256, (x ^ y) % 256);
        }
      }
      final raw = Uint8List.fromList(img.encodeJpg(image, quality: 95));

      final b64 = await ImageUtils.processIdentityPhoto(raw);
      expect(b64.length, lessThan(950000));

      final decoded = img.decodeImage(base64Decode(b64))!;
      expect(decoded.width <= 1000 && decoded.height <= 1000, isTrue);
      expect(decoded.width, greaterThan(500)); // still legible for an ID card
    });
  });
}

// Google sign-in error messages (shown instead of a generic "cancelled or failed").
void googleErrorTests() {
  group('AuthService.describeGoogleError', () {
    test('Android code 10 points to the missing SHA-1', () {
      final msg = AuthService.describeGoogleError(
        PlatformException(code: 'sign_in_failed', message: 'com.google.android.gms.common.api.ApiException: 10: '),
      );
      expect(msg, contains('SHA-1'));
    });

    test('network error is reported as no internet', () {
      final msg = AuthService.describeGoogleError(
        PlatformException(code: 'network_error', message: 'ApiException: 7'),
      );
      expect(msg.toLowerCase(), contains('internet'));
    });

    test('unknown errors still show the cause', () {
      expect(AuthService.describeGoogleError(Exception('boom')), contains('boom'));
    });
  });
}
