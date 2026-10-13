import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;

Uint8List _resizeToJpeg(List<Object> args) {
  final decoded = img.decodeImage(args[0] as Uint8List);
  if (decoded == null) return args[0] as Uint8List;
  var image = img.bakeOrientation(decoded);
  final maxDim = args[1] as int;
  if (image.width > maxDim || image.height > maxDim) {
    image = image.width >= image.height
        ? img.copyResize(image, width: maxDim)
        : img.copyResize(image, height: maxDim);
  }
  return Uint8List.fromList(img.encodeJpg(image, quality: args[2] as int));
}

class ImageUtils {
  /// Downscales a camera photo to a legible-but-small JPEG (ID cards need more
  /// pixels than a profile picture to stay readable), then runs it through the
  /// standard Firestore guard. Works on web and mobile (pure Dart).
  static Future<String> processIdentityPhoto(Uint8List bytes, {int maxDim = 1000, int quality = 80}) async {
    final jpeg = await compute(_resizeToJpeg, <Object>[bytes, maxDim, quality]);
    return processImageForFirestore(jpeg);
  }

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
