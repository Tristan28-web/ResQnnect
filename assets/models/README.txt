mobilefacenet.tflite
  Face-embedding model (MobileFaceNets, arXiv 1804.07573): 112x112 RGB input
  scaled to [-1, 1], 192-dim output. Expects an eye-aligned face crop.
  Source: pub.dev package face_detection_tflite 6.10.1 (Apache License 2.0),
          assets/models/mobilefacenet.tflite
  Size: 5,233,552 bytes
  SHA-256: be4bc7cfc53f7bc336d0f28b1ab92535f618c913a422b683210750f6b5354854

Used by lib/services/face/face_engine_mobile.dart. If the file is missing the
app still works: capture and liveness run, and the LGU admin compares the faces
by eye.
