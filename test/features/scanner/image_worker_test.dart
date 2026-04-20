import 'dart:async';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:mtg_card_scanner/features/scanner/image_worker.dart';

void main() {
  test('prepareOcr returns the handler result bytes', () async {
    final w = ImageWorker.forTesting((req) async {
      expect(req, isA<PrepareOcrRequest>());
      final p = req as PrepareOcrRequest;
      expect(p.bytes, equals(Uint8List.fromList([1, 2, 3])));
      expect(p.preprocess, PreprocessMode.otsu);
      return ImageWorkerResult(
        pngBytes: Uint8List.fromList([9, 9, 9]),
        width: 600,
        height: 900,
      );
    });

    final r = await w.prepareOcr(
      Uint8List.fromList([1, 2, 3]),
      crop: null,
      preprocess: PreprocessMode.otsu,
      minWidth: 600,
    );

    expect(r.pngBytes, equals(Uint8List.fromList([9, 9, 9])));
    expect(r.width, 600);
    expect(r.height, 900);
    await w.close();
  });

  test('handler errors are rethrown by prepareOcr', () async {
    final w = ImageWorker.forTesting(
        (req) async => throw StateError('simulated worker failure'));

    await expectLater(
      w.prepareOcr(
        Uint8List(1),
        crop: null,
        preprocess: PreprocessMode.none,
        minWidth: 600,
      ),
      throwsA(isA<StateError>().having(
          (e) => e.message, 'message', contains('simulated worker failure'))),
    );
    await w.close();
  });

  test('prepareOcr times out when the handler never responds', () async {
    final never = Completer<ImageWorkerResult>();
    final w = ImageWorker.forTestingWithTimeout(
      (req) => never.future,
      timeout: const Duration(milliseconds: 50),
    );

    await expectLater(
      w.prepareOcr(
        Uint8List(1),
        crop: null,
        preprocess: PreprocessMode.none,
        minWidth: 600,
      ),
      throwsA(isA<TimeoutException>()),
    );
    await w.close();
  });

  test('spawned worker prepares a real image (otsu, minWidth upscale)',
      () async {
    final inPng = Uint8List.fromList(img.encodePng(img.Image(width: 100, height: 200)));
    final w = await ImageWorker.spawn();
    try {
      final r = await w.prepareOcr(
        inPng,
        crop: null,
        preprocess: PreprocessMode.otsu,
        minWidth: 600,
      );
      // minWidth=600 upscales the input from 100px → 600px wide.
      expect(r.width, 600);
      expect(r.height, 1200);
      expect(r.pngBytes.isNotEmpty, isTrue);
    } finally {
      await w.close();
    }
  });

  test('spawned worker rotates a real image', () async {
    final inPng = Uint8List.fromList(img.encodePng(img.Image(width: 100, height: 200)));
    final w = await ImageWorker.spawn();
    try {
      final r = await w.rotate(inPng, 90);
      // 90° rotation swaps dims.
      expect(r.width, 200);
      expect(r.height, 100);
    } finally {
      await w.close();
    }
  });
}
