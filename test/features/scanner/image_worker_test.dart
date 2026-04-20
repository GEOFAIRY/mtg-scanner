import 'dart:async';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
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
}
