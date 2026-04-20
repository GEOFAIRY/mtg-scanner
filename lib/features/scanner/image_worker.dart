import 'dart:async';
import 'dart:typed_data';

enum PreprocessMode { none, otsu, contrast }

class Crop {
  const Crop(this.left, this.top, this.width, this.height);
  final double left, top, width, height;
}

sealed class ImageWorkerRequest {
  const ImageWorkerRequest();
}

class PrepareOcrRequest extends ImageWorkerRequest {
  const PrepareOcrRequest({
    required this.bytes,
    required this.crop,
    required this.preprocess,
    required this.minWidth,
  });
  final Uint8List bytes;
  final Crop? crop;
  final PreprocessMode preprocess;
  final int minWidth;
}

class RotateRequest extends ImageWorkerRequest {
  const RotateRequest({required this.bytes, required this.angle});
  final Uint8List bytes;
  final int angle; // 90 | 180 | 270
}

class ImageWorkerResult {
  const ImageWorkerResult({
    required this.pngBytes,
    required this.width,
    required this.height,
  });
  final Uint8List pngBytes;
  final int width;
  final int height;
}

/// Client handle to a long-lived image-processing worker isolate. Synchronous
/// Dart `image` package ops happen in the worker so they don't block the
/// main isolate. opencv_dart / ML Kit stay on main (native handles don't
/// cross isolates cleanly).
class ImageWorker {
  ImageWorker.forTesting(this._handler)
      : _timeout = const Duration(seconds: 5);

  ImageWorker.forTestingWithTimeout(
    this._handler, {
    required Duration timeout,
  }) : _timeout = timeout;

  final Future<ImageWorkerResult> Function(ImageWorkerRequest) _handler;
  final Duration _timeout;
  bool _closed = false;

  Future<ImageWorkerResult> prepareOcr(
    Uint8List bytes, {
    required Crop? crop,
    required PreprocessMode preprocess,
    required int minWidth,
  }) {
    return _dispatch(PrepareOcrRequest(
      bytes: bytes,
      crop: crop,
      preprocess: preprocess,
      minWidth: minWidth,
    ));
  }

  Future<ImageWorkerResult> rotate(Uint8List bytes, int angle) {
    return _dispatch(RotateRequest(bytes: bytes, angle: angle));
  }

  Future<ImageWorkerResult> _dispatch(ImageWorkerRequest req) async {
    if (_closed) {
      throw StateError('ImageWorker is closed');
    }
    return _handler(req).timeout(_timeout);
  }

  Future<void> close() async {
    _closed = true;
  }
}
