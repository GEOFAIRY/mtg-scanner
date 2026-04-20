import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:mtg_card_scanner/features/scanner/image_worker.dart';
import 'package:mtg_card_scanner/features/scanner/ocr_runner.dart';

void main() {
  test('focused pass delegates image prep to the injected worker', () async {
    final workerCalls = <PrepareOcrRequest>[];
    final worker = ImageWorker.forTesting((req) async {
      workerCalls.add(req as PrepareOcrRequest);
      return ImageWorkerResult(
        pngBytes: Uint8List.fromList([0xff]),
        width: 600,
        height: 900,
      );
    });

    final recognizerCalls = <(int, int)>[];
    final runner = MlKitOcrRunner(
      imageWorker: worker,
      recognizer: (bytes, w, h) async {
        recognizerCalls.add((w, h));
        return const <OcrBlock>[];
      },
    );

    final tinyPng = Uint8List.fromList(
        img.encodePng(img.Image(width: 750, height: 1050)));
    await runner.recognizeBlocks(tinyPng);

    // Pass 1 (whole card) uses the original bytes — not a worker call.
    // Focused name + focused set each submit one worker call.
    expect(workerCalls.length, 2);
    expect(workerCalls.every((c) => c.preprocess == PreprocessMode.otsu), isTrue);
    expect(workerCalls[0].crop, isNotNull);
    expect(workerCalls[1].crop, isNotNull);
    await worker.close();
  });

  // Helper: craft a fake recognizer whose per-call outputs are scripted.
  // Each call records the (width, height) it was invoked with so the test
  // can assert which passes ran.
  ({MlKitOcrRunner runner, List<(int, int)> calls}) build(
      List<List<OcrBlock>> scripted) {
    final calls = <(int, int)>[];
    final runner = MlKitOcrRunner(recognizer: (bytes, w, h) async {
      final idx = calls.length;
      calls.add((w, h));
      return idx < scripted.length ? scripted[idx] : const [];
    });
    return (runner: runner, calls: calls);
  }

  // Programmatic PNG so decodeImage + copyCrop roundtrip cleanly regardless
  // of platform. 750x1050 matches the pipeline's target warp dimensions.
  final tinyPng = Uint8List.fromList(
      img.encodePng(img.Image(width: 750, height: 1050)));

  test('pass 1 only when it already produces confident name + cn', () async {
    final b = build([
      [
        OcrBlock(text: 'Lightning Bolt',
            left: 0.05, top: 0.05, width: 0.60, height: 0.06),
        OcrBlock(text: '2xm 137',
            left: 0.05, top: 0.90, width: 0.40, height: 0.04),
      ],
    ]);

    await b.runner.recognizeBlocks(tinyPng);

    expect(b.calls.length, 1, reason: 'early-exit should prevent further passes');
  });

  test('runs pass 1 + focused name + focused set when pass 1 is not confident',
      () async {
    // Pass 1 returns only blocks outside the confident-name-or-cn bands
    // (mid-card only), so the runner falls through to focused crops.
    final b = build([
      [
        OcrBlock(text: 'middle text',
            left: 0.10, top: 0.45, width: 0.60, height: 0.04),
      ],
      // Focused name crop — OTSU preprocess — returns nothing dramatic.
      [],
      // Focused set crop — OTSU preprocess — returns nothing dramatic.
      [],
    ]);

    await b.runner.recognizeBlocks(tinyPng);

    expect(b.calls.length, 3,
        reason: 'pass 1 + focused name (OTSU) + focused set (OTSU) = 3 passes');
  });

  test('runs a whole-card contrast fallback only when pass 1 is empty',
      () async {
    final b = build([
      [], // pass 1 raw — empty.
      [], // focused name OTSU — empty.
      [], // focused set OTSU — empty.
      [], // whole-card contrast fallback.
    ]);

    await b.runner.recognizeBlocks(tinyPng);

    expect(b.calls.length, 4,
        reason: 'empty pass 1 triggers the whole-card contrast fallback');
  });

  test('skips whole-card contrast fallback when pass 1 had any blocks',
      () async {
    final b = build([
      [
        OcrBlock(text: 'noise',
            left: 0.40, top: 0.40, width: 0.10, height: 0.02),
      ],
      [], // focused name OTSU.
      [], // focused set OTSU.
    ]);

    await b.runner.recognizeBlocks(tinyPng);

    expect(b.calls.length, 3,
        reason: 'any pass-1 blocks prevents the contrast fallback');
  });
}
