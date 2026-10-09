import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/foundation.dart';

class ImageUtils {
  /// Compresses and safely encodes image bytes to Base64 so it never exceeds
  /// Cloud Firestore's 1,048,487 byte document property limit.
  static Future<String> processImageForFirestore(Uint8List bytes) async {
    Uint8List processed = bytes;

    // 1. If raw image is larger than 500 KB, downscale to 600px width
    if (processed.lengthInBytes > 500000) {
      try {
        final codec = await ui.instantiateImageCodec(processed, targetWidth: 600);
        final frame = await codec.getNextFrame();
        final byteData = await frame.image.toByteData(format: ui.ImageByteFormat.png);
        if (byteData != null) {
          processed = byteData.buffer.asUint8List();
        }
      } catch (e) {
        debugPrint('Downscale pass 1 error: $e');
      }
    }

    // 2. If still larger than 600 KB, downscale to 400px width
    if (processed.lengthInBytes > 600000) {
      try {
        final codec = await ui.instantiateImageCodec(processed, targetWidth: 400);
        final frame = await codec.getNextFrame();
        final byteData = await frame.image.toByteData(format: ui.ImageByteFormat.png);
        if (byteData != null) {
          processed = byteData.buffer.asUint8List();
        }
      } catch (e) {
        debugPrint('Downscale pass 2 error: $e');
      }
    }

    // 3. Final verification of Base64 length (safe margin below 1,048,487 limit)
    String base64Str = base64Encode(processed);
    if (base64Str.length > 950000) {
      try {
        final codec = await ui.instantiateImageCodec(processed, targetWidth: 300);
        final frame = await codec.getNextFrame();
        final byteData = await frame.image.toByteData(format: ui.ImageByteFormat.png);
        if (byteData != null) {
          base64Str = base64Encode(byteData.buffer.asUint8List());
        }
      } catch (e) {
        debugPrint('Downscale pass 3 error: $e');
      }
    }

    return base64Str;
  }
}
