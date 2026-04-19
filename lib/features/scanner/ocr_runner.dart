import 'dart:io';
import 'dart:typed_data';
import 'package:image/image.dart' as img;
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

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
  MlKitOcrRunner({OcrRecognizer? recognizer}) {
    _recognize = recognizer ?? _mlKitRecognize;
  }

  late final OcrRecognizer _recognize;
  final TextRecognizer _mlKit =
      TextRecognizer(script: TextRecognitionScript.latin);
  late final File _scratch =
      File('${Directory.systemTemp.path}/mtg_scanner_ocr.png');

  @override
  Future<List<OcrBlock>> recognizeBlocks(Uint8List imageBytes) async {
    final decoded = img.decodeImage(imageBytes);
    if (decoded == null) return const [];

    final results = <List<OcrBlock>>[];

    // Pass 1: whole card, raw.
    final pass1 =
        await _recognize(imageBytes, decoded.width, decoded.height);
    results.add(pass1);

    // Early-exit: if pass 1 found both a plausible name block AND a plausible
    // set/cn block, later passes are redundant.
    if (_hasConfidentNameAndCn(pass1)) {
      return _mergeBlocks(results);
    }

    // Passes 2 + 3: focused crops with OTSU preprocess only. OTSU adapts to
    // whatever contrast the crop has and usually dominates the fixed-contrast
    // variant we used to also run.
    results.add(await _focusedPass(decoded, _nameCrop));
    results.add(await _focusedPass(decoded, _setCrop));

    // Pass 4 (conditional): whole-card grayscale + contrast, ONLY when pass 1
    // returned nothing at all. This is the rescue path for extremely low-
    // contrast captures where even raw ML Kit fails.
    if (pass1.isEmpty) {
      final pp = img.contrast(img.grayscale(decoded), contrast: 125);
      results.add(await _recognize(Uint8List.fromList(img.encodePng(pp)),
          decoded.width, decoded.height));
    }

    return _mergeBlocks(results);
  }

  static final _confidentLetter = RegExp(r'[A-Za-z]');
  static final _confidentDigit = RegExp(r'\d');

  /// A "confident" pass-1 result has at least one top-band block with
  /// letters (probable name) AND at least one bottom-left block with
  /// digits (probable collector number). Thresholds match
  /// ScanPipeline._pickName / _pickSetCollector so the early-exit gate
  /// doesn't disagree with the pipeline's picker.
  static bool _hasConfidentNameAndCn(List<OcrBlock> blocks) {
    final hasName = blocks.any((b) =>
        b.top < 0.20 &&
        _confidentLetter.hasMatch(b.text) &&
        b.text.trim().length >= 3);
    final hasCn = blocks.any((b) =>
        b.top >= 0.70 && b.left < 0.75 && _confidentDigit.hasMatch(b.text));
    return hasName && hasCn;
  }

  Future<List<OcrBlock>> _focusedPass(
      img.Image src, _FocusCrop crop) async {
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
    final blocks = await _recognize(
        Uint8List.fromList(img.encodePng(region)),
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
    await _scratch.writeAsBytes(pngBytes, flush: true);
    final input = InputImage.fromFilePath(_scratch.path);
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
    try {
      if (await _scratch.exists()) await _scratch.delete();
    } catch (_) {
      // Best-effort cleanup — ignored.
    }
  }
}
