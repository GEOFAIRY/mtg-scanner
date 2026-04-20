import 'dart:async';
import 'dart:isolate';
import 'dart:typed_data';

import 'package:image/image.dart' as img;

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
  ImageWorker._real(
    SendPort sendPort,
    ReceivePort receivePort,
    Isolate isolate,
  )   : _sendPort = sendPort,
        _receivePort = receivePort,
        _isolate = isolate,
        _handler = null,
        _timeout = const Duration(seconds: 5);

  ImageWorker.forTesting(this._handler)
      : _sendPort = null,
        _receivePort = null,
        _isolate = null,
        _timeout = const Duration(seconds: 5);

  ImageWorker.forTestingWithTimeout(
    this._handler, {
    required Duration timeout,
  })  : _sendPort = null,
        _receivePort = null,
        _isolate = null,
        _timeout = timeout;

  final Future<ImageWorkerResult> Function(ImageWorkerRequest)? _handler;
  final SendPort? _sendPort;
  final ReceivePort? _receivePort;
  final Isolate? _isolate;
  final Duration _timeout;

  final Map<int, Completer<ImageWorkerResult>> _pending = {};
  int _nextId = 1;
  bool _closed = false;

  static Future<ImageWorker> spawn() async {
    final receivePort = ReceivePort();
    final readyCompleter = Completer<SendPort>();
    final isolate = await Isolate.spawn(_workerEntry, receivePort.sendPort);
    // Single listener handles both the initial SendPort handshake and all
    // subsequent worker responses. ReceivePort is single-subscription, so we
    // can't listen twice.
    late final ImageWorker worker;
    receivePort.listen((m) {
      if (!readyCompleter.isCompleted && m is SendPort) {
        readyCompleter.complete(m);
        return;
      }
      worker._onWorkerMessage(m);
    });
    final sendPort = await readyCompleter.future;
    worker = ImageWorker._real(sendPort, receivePort, isolate);
    return worker;
  }

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
    final handler = _handler;
    if (handler != null) {
      // Test path.
      return handler(req).timeout(_timeout);
    }
    // Real isolate path.
    final id = _nextId++;
    final completer = Completer<ImageWorkerResult>();
    _pending[id] = completer;
    _sendPort!.send(_encodeRequest(id, req));
    try {
      return await completer.future.timeout(_timeout);
    } on TimeoutException {
      _pending.remove(id);
      rethrow;
    }
  }

  void _onWorkerMessage(dynamic msg) {
    if (msg is! Map) return;
    final id = msg['id'] as int?;
    if (id == null) return;
    final completer = _pending.remove(id);
    if (completer == null) return;
    final err = msg['error'] as String?;
    if (err != null) {
      completer.completeError(StateError(err));
      return;
    }
    completer.complete(ImageWorkerResult(
      pngBytes: msg['pngBytes'] as Uint8List,
      width: msg['width'] as int,
      height: msg['height'] as int,
    ));
  }

  Future<void> close() async {
    if (_closed) return;
    _closed = true;
    final sendPort = _sendPort;
    if (sendPort != null) {
      sendPort.send({'op': 'close'});
    }
    _isolate?.kill(priority: Isolate.immediate);
    _receivePort?.close();
    for (final c in _pending.values) {
      if (!c.isCompleted) {
        c.completeError(StateError('ImageWorker closed'));
      }
    }
    _pending.clear();
  }
}

Map<String, Object?> _encodeRequest(int id, ImageWorkerRequest req) {
  if (req is PrepareOcrRequest) {
    return {
      'id': id,
      'op': 'prepareOcr',
      'bytes': req.bytes,
      'crop': req.crop == null
          ? null
          : {
              'l': req.crop!.left,
              't': req.crop!.top,
              'w': req.crop!.width,
              'h': req.crop!.height,
            },
      'preprocess': req.preprocess.name,
      'minWidth': req.minWidth,
    };
  }
  if (req is RotateRequest) {
    return {
      'id': id,
      'op': 'rotate',
      'bytes': req.bytes,
      'angle': req.angle,
    };
  }
  throw StateError('unknown request type: ${req.runtimeType}');
}

void _workerEntry(SendPort hostSendPort) {
  final port = ReceivePort();
  hostSendPort.send(port.sendPort);
  port.listen((msg) {
    if (msg is! Map) return;
    final op = msg['op'] as String?;
    if (op == 'close') {
      port.close();
      return;
    }
    final id = msg['id'] as int?;
    if (id == null) return;
    try {
      final result = _handleInWorker(msg);
      hostSendPort.send({
        'id': id,
        'pngBytes': result.pngBytes,
        'width': result.width,
        'height': result.height,
      });
    } catch (e, s) {
      hostSendPort.send({'id': id, 'error': '$e\n$s'});
    }
  });
}

ImageWorkerResult _handleInWorker(Map<dynamic, dynamic> msg) {
  final op = msg['op'] as String;
  final bytes = msg['bytes'] as Uint8List;
  final decoded = img.decodeImage(bytes);
  if (decoded == null) {
    throw StateError('decodeImage returned null');
  }
  switch (op) {
    case 'prepareOcr':
      return _prepareOcr(decoded, msg);
    case 'rotate':
      final angle = msg['angle'] as int;
      final rotated = img.copyRotate(decoded, angle: angle);
      final out = Uint8List.fromList(img.encodePng(rotated));
      return ImageWorkerResult(
          pngBytes: out, width: rotated.width, height: rotated.height);
    default:
      throw StateError('unknown op: $op');
  }
}

ImageWorkerResult _prepareOcr(img.Image decoded, Map<dynamic, dynamic> msg) {
  img.Image src = decoded;
  final cropMap = msg['crop'] as Map?;
  if (cropMap != null) {
    final l = (cropMap['l'] as num).toDouble();
    final t = (cropMap['t'] as num).toDouble();
    final w = (cropMap['w'] as num).toDouble();
    final h = (cropMap['h'] as num).toDouble();
    final x = (l * src.width).round();
    final y = (t * src.height).round();
    final cw = (w * src.width).round();
    final ch = (h * src.height).round();
    if (cw <= 0 || ch <= 0) {
      throw StateError('invalid crop: $cw x $ch');
    }
    src = img.copyCrop(src, x: x, y: y, width: cw, height: ch);
  }
  final preprocess = msg['preprocess'] as String;
  img.Image region;
  switch (preprocess) {
    case 'none':
      region = src;
      break;
    case 'otsu':
      region = _otsuPreprocess(src);
      break;
    case 'contrast':
      region = img.contrast(img.grayscale(img.Image.from(src)), contrast: 125);
      break;
    default:
      throw StateError('unknown preprocess: $preprocess');
  }
  final minWidth = msg['minWidth'] as int;
  if (region.width < minWidth) {
    final scale = minWidth / region.width;
    region = img.copyResize(region,
        width: minWidth,
        height: (region.height * scale).round(),
        interpolation: img.Interpolation.cubic);
  }
  final png = Uint8List.fromList(img.encodePng(region));
  return ImageWorkerResult(
      pngBytes: png, width: region.width, height: region.height);
}

img.Image _otsuPreprocess(img.Image src) {
  final gray = img.grayscale(img.Image.from(src));
  final hist = List.filled(256, 0);
  for (final pixel in gray) {
    hist[pixel.r.toInt()]++;
  }
  final total = gray.width * gray.height;
  var sumAll = 0.0;
  for (var i = 0; i < 256; i++) {
    sumAll += i * hist[i];
  }
  var sumBg = 0.0;
  var wBg = 0;
  var bestThresh = 0;
  var bestVar = 0.0;
  for (var t = 0; t < 256; t++) {
    wBg += hist[t];
    if (wBg == 0) continue;
    final wFg = total - wBg;
    if (wFg == 0) break;
    sumBg += t * hist[t];
    final meanBg = sumBg / wBg;
    final meanFg = (sumAll - sumBg) / wFg;
    final varBetween = wBg * wFg * (meanBg - meanFg) * (meanBg - meanFg);
    if (varBetween > bestVar) {
      bestVar = varBetween;
      bestThresh = t;
    }
  }
  for (final pixel in gray) {
    final v = pixel.r.toInt() >= bestThresh ? 255 : 0;
    pixel
      ..r = v
      ..g = v
      ..b = v;
  }
  return gray;
}
