import 'dart:io';
import 'dart:typed_data';
import 'package:image/image.dart' as img;
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

import 'image_worker.dart';

/// A single recognized text block with its bounding box in normalized card
/// coordinates (0..1 of the input image width/height).
class OcrBlock {
  const OcrBlock({
    required this.text,
    required this.left,
    required this.top,
    required this.width,
    required this.height,
  });
  final String text;
  final double left, top, width, height;

  double get right => left + width;
  double get bottom => top + height;
  double get area => width * height;
}

abstract class OcrRunner {
  /// Recognize every text block in [imageBytes] (an upright card PNG).
  /// Returns blocks with bounding boxes normalized to the image dimensions.
  Future<List<OcrBlock>> recognizeBlocks(Uint8List imageBytes);
  Future<void> dispose();
}

/// Recognize blocks from a PNG byte buffer. Injected into [MlKitOcrRunner] so
/// unit tests can substitute a fake implementation and ML Kit stays out of
/// the test graph.
typedef OcrRecognizer = Future<List<OcrBlock>> Function(
    Uint8List pngBytes, int imgWidth, int imgHeight);

/// Normalized regions of the card we OCR as focused zoom-ins. Whole-card
/// OCR misses pixel-tiny text (retro-frame collector numbers, translucent
/// borderless name banners) because the text is too small relative to the
/// whole frame; cropping first forces ML Kit to operate at a scale where
/// those glyphs register.
class _FocusCrop {
  const _FocusCrop(this.left, this.top, this.width, this.height);
  final double left, top, width, height;
}

const _nameCrop = _FocusCrop(0.02, 0.02, 0.96, 0.18);
const _setCrop = _FocusCrop(0.02, 0.84, 0.70, 0.14);

class MlKitOcrRunner implements OcrRunner {
  MlKitOcrRunner({OcrRecognizer? recognizer, ImageWorker? imageWorker})
      : _imageWorker = imageWorker {
    _recognize = recognizer ?? _mlKitRecognize;
  }

  late final OcrRecognizer _recognize;
  final ImageWorker? _imageWorker;
  final TextRecognizer _mlKit =
      TextRecognizer(script: TextRecognitionScript.latin);
  late final File _pass1Scratch =
      File('${Directory.systemTemp.path}/mtg_scanner_ocr_pass1.png');
  late final File _pass2Scratch =
      File('${Directory.systemTemp.path}/mtg_scanner_ocr_pass2.png');
  late final File _pass3Scratch =
      File('${Directory.systemTemp.path}/mtg_scanner_ocr_pass3.png');
  late final File _pass4Scratch =
      File('${Directory.systemTemp.path}/mtg_scanner_ocr_pass4.png');

  @override
  Future<List<OcrBlock>> recognizeBlocks(Uint8List imageBytes) async {
    final probe = img.decodeImage(imageBytes);
    if (probe == null) return const [];
    final probeW = probe.width;
    final probeH = probe.height;

    // Passes 1, 2, 3 are independent — run them concurrently and collect.
    // The pass-1 early-exit is removed: any work the extra passes do runs
    // while pass 1 is still in flight, so there's no wall-clock penalty.
    final pass1F =
        _recognizeWithScratch(imageBytes, _pass1Scratch, probeW, probeH);
    final pass2F = _focusedPass(imageBytes, _nameCrop, _pass2Scratch);
    final pass3F = _focusedPass(imageBytes, _setCrop, _pass3Scratch);

    final results = <List<OcrBlock>>[];
    final triple = await Future.wait([pass1F, pass2F, pass3F]);
    results.addAll(triple);

    // Pass 4 (conditional): whole-card grayscale + contrast, ONLY when pass 1
    // returned nothing. Rare rescue path; stays sequential because it's only
    // scheduled after pass 1's result is known.
    if (triple[0].isEmpty) {
      final pp = img.contrast(img.grayscale(probe), contrast: 125);
      results.add(await _recognizeWithScratch(
          Uint8List.fromList(img.encodePng(pp)),
          _pass4Scratch,
          probeW,
          probeH));
    }

    return _mergeBlocks(results);
  }

  Future<List<OcrBlock>> _recognizeWithScratch(
      Uint8List pngBytes, File scratch, int imgW, int imgH) {
    // If the default ML Kit recognizer is active, route through the scratch
    // variant. Otherwise the injected test recognizer doesn't care about the
    // scratch path.
    if (identical(_recognize, _mlKitRecognize)) {
      return _mlKitRecognizeWithScratch(pngBytes, scratch, imgW, imgH);
    }
    return _recognize(pngBytes, imgW, imgH);
  }

  Future<List<OcrBlock>> _focusedPass(
      Uint8List imageBytes, _FocusCrop crop, File scratch) async {
    final worker = _imageWorker;
    if (worker == null) {
      // No worker wired; fall back to running inline (legacy path — kept for
      // tests that don't inject a worker).
      return _focusedPassInline(imageBytes, crop, scratch);
    }
    final prepared = await worker.prepareOcr(
      imageBytes,
      crop: Crop(crop.left, crop.top, crop.width, crop.height),
      preprocess: PreprocessMode.otsu,
      minWidth: 600,
    );
    final blocks = await _recognizeWithScratch(
        prepared.pngBytes, scratch, prepared.width, prepared.height);
    return [
      for (final b in blocks)
        OcrBlock(
          text: b.text,
          left: crop.left + b.left * crop.width,
          top: crop.top + b.top * crop.height,
          width: b.width * crop.width,
          height: b.height * crop.height,
        ),
    ];
  }

  Future<List<OcrBlock>> _focusedPassInline(
      Uint8List imageBytes, _FocusCrop crop, File scratch) async {
    final src = img.decodeImage(imageBytes);
    if (src == null) return const [];
    final x = (crop.left * src.width).round();
    final y = (crop.top * src.height).round();
    final w = (crop.width * src.width).round();
    final h = (crop.height * src.height).round();
    if (w <= 0 || h <= 0) return const [];
    final rawCrop = img.copyCrop(src, x: x, y: y, width: w, height: h);
    var region = _otsuPreprocess(rawCrop);
    if (region.width < 600) {
      final scale = 600 / region.width;
      region = img.copyResize(region,
          width: 600,
          height: (region.height * scale).round(),
          interpolation: img.Interpolation.cubic);
    }
    final blocks = await _recognizeWithScratch(
        Uint8List.fromList(img.encodePng(region)),
        scratch,
        region.width,
        region.height);
    return [
      for (final b in blocks)
        OcrBlock(
          text: b.text,
          left: crop.left + b.left * crop.width,
          top: crop.top + b.top * crop.height,
          width: b.width * crop.width,
          height: b.height * crop.height,
        ),
    ];
  }

  static img.Image _otsuPreprocess(img.Image src) {
    final gray = img.grayscale(img.Image.from(src));
    // Manual OTSU threshold: compute histogram, find the threshold that
    // minimizes intra-class variance, then binarize.
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

  Future<List<OcrBlock>> _mlKitRecognize(
      Uint8List pngBytes, int imgW, int imgH) async {
    return _mlKitRecognizeWithScratch(pngBytes, _pass1Scratch, imgW, imgH);
  }

  Future<List<OcrBlock>> _mlKitRecognizeWithScratch(
      Uint8List pngBytes, File scratch, int imgW, int imgH) async {
    await scratch.writeAsBytes(pngBytes, flush: true);
    final input = InputImage.fromFilePath(scratch.path);
    final result = await _mlKit.processImage(input);
    final w = imgW.toDouble();
    final h = imgH.toDouble();
    if (w <= 0 || h <= 0) return const [];
    return [
      for (final b in result.blocks)
        OcrBlock(
          text: b.text,
          left: b.boundingBox.left / w,
          top: b.boundingBox.top / h,
          width: b.boundingBox.width / w,
          height: b.boundingBox.height / h,
        ),
    ];
  }

  static List<OcrBlock> _mergeBlocks(List<List<OcrBlock>> passes) {
    // Dedupe by (text, bucketed position). 0.03 worked as the "near enough"
    // threshold in the O(n²) version, so bucket at 0.03 ≈ 1/33 to preserve
    // that behavior.
    final seen = <String>{};
    final out = <OcrBlock>[];
    for (final pass in passes) {
      for (final cand in pass) {
        final key =
            '${cand.text.trim()}|${(cand.left * 33).round()}|${(cand.top * 33).round()}';
        if (seen.add(key)) out.add(cand);
      }
    }
    return out;
  }

  @override
  Future<void> dispose() async {
    await _mlKit.close();
    for (final f in [_pass1Scratch, _pass2Scratch, _pass3Scratch, _pass4Scratch]) {
      try {
        if (await f.exists()) await f.delete();
      } catch (_) {
        // Best-effort cleanup.
      }
    }
  }
}
