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
  final TextRecognizer _recognizer =
      TextRecognizer(script: TextRecognitionScript.latin);
  // A single reusable scratch file instead of a new file-per-pass with a
  // microsecondsSinceEpoch + identityHashCode filename. OCR passes run
  // sequentially within a single captureFromWarpedCrop call, so there's no
  // concurrent-access concern and we skip the create + delete cycle.
  late final File _scratch =
      File('${Directory.systemTemp.path}/mtg_scanner_ocr.png');

  @override
  Future<List<OcrBlock>> recognizeBlocks(Uint8List imageBytes) async {
    final decoded = img.decodeImage(imageBytes);
    if (decoded == null) return const [];

    final results = <List<OcrBlock>>[];

    // Pass 1: whole card, raw — ML Kit handles standard frames best without
    // preprocessing that can blow out translucent banners.
    results.add(await _run(imageBytes, decoded.width, decoded.height));

    // Early-exit: if pass 1 already found both a plausible name block and a
    // plausible set/cn block, the later three passes are redundant work.
    // Standard-frame cards hit this and skip ~1-1.5s of extra OCR.
    if (_hasConfidentNameAndCn(results.first)) {
      return _mergeBlocks(results);
    }

    // Pass 2: whole card, gentle grayscale + contrast — rescues low-contrast
    // frames (full-art, showcase, textured retro).
    final pp = img.contrast(img.grayscale(decoded), contrast: 125);
    results.add(await _run(Uint8List.fromList(img.encodePng(pp)),
        decoded.width, decoded.height));

    // Passes 3 & 4: focused crops for the two regions that carry the match
    // signal. Running these as zoom-ins gives us full-resolution text in the
    // exact bands we care about.
    results.add(await _focusedPass(decoded, _nameCrop));
    results.add(await _focusedPass(decoded, _setCrop));

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
        b.top < 0.30 &&
        _confidentLetter.hasMatch(b.text) &&
        b.text.trim().length >= 3);
    final hasCn = blocks.any((b) =>
        b.top >= 0.78 && b.left < 0.75 && _confidentDigit.hasMatch(b.text));
    return hasName && hasCn;
  }

  Future<List<OcrBlock>> _focusedPass(
      img.Image src, _FocusCrop crop) async {
    final x = (crop.left * src.width).round();
    final y = (crop.top * src.height).round();
    final w = (crop.width * src.width).round();
    final h = (crop.height * src.height).round();
    if (w <= 0 || h <= 0) return const [];
    var region = img.copyCrop(src, x: x, y: y, width: w, height: h);
    region = img.contrast(img.grayscale(region), contrast: 135);
    // Upscale small crops so tiny collector-number glyphs cross ML Kit's
    // minimum-glyph-size threshold.
    if (region.width < 400) {
      final scale = 400 / region.width;
      region = img.copyResize(region,
          width: 400,
          height: (region.height * scale).round(),
          interpolation: img.Interpolation.cubic);
    }
    final blocks = await _run(
        Uint8List.fromList(img.encodePng(region)),
        region.width,
        region.height);
    // Map bounding boxes from the crop back to card-normalized coordinates.
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

  Future<List<OcrBlock>> _run(
      Uint8List pngBytes, int imgW, int imgH) async {
    await _scratch.writeAsBytes(pngBytes, flush: true);
    final input = InputImage.fromFilePath(_scratch.path);
    final result = await _recognizer.processImage(input);
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
    await _recognizer.close();
    try {
      if (await _scratch.exists()) await _scratch.delete();
    } catch (_) {
      // Best-effort cleanup — ignored.
    }
  }
}
