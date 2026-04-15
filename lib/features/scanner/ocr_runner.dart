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

  @override
  Future<List<OcrBlock>> recognizeBlocks(Uint8List imageBytes) async {
    final decoded = img.decodeImage(imageBytes);
    if (decoded == null) return const [];

    final results = <List<OcrBlock>>[];

    // Pass 1: whole card, raw — ML Kit handles standard frames best without
    // preprocessing that can blow out translucent banners.
    results.add(await _run(imageBytes, decoded.width, decoded.height));

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
    final temp = File(
        '${Directory.systemTemp.path}/ocr_${DateTime.now().microsecondsSinceEpoch}_${identityHashCode(pngBytes)}.png');
    await temp.writeAsBytes(pngBytes);
    try {
      final input = InputImage.fromFilePath(temp.path);
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
    } finally {
      if (await temp.exists()) await temp.delete();
    }
  }

  static List<OcrBlock> _mergeBlocks(List<List<OcrBlock>> passes) {
    final out = <OcrBlock>[];
    for (final pass in passes) {
      for (final cand in pass) {
        final dupe = out.any((existing) =>
            existing.text.trim() == cand.text.trim() &&
            (existing.left - cand.left).abs() < 0.03 &&
            (existing.top - cand.top).abs() < 0.03);
        if (!dupe) out.add(cand);
      }
    }
    return out;
  }

  @override
  Future<void> dispose() => _recognizer.close();
}
