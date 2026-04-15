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

class MlKitOcrRunner implements OcrRunner {
  final TextRecognizer _recognizer =
      TextRecognizer(script: TextRecognitionScript.latin);

  @override
  Future<List<OcrBlock>> recognizeBlocks(Uint8List imageBytes) async {
    final decoded = img.decodeImage(imageBytes);
    if (decoded == null) return const [];

    // Pass 1: raw. ML Kit handles standard-frame cards best without help —
    // aggressive preprocessing was washing out translucent name banners on
    // borderless cards.
    final raw = await _run(imageBytes, decoded.width, decoded.height);

    // Pass 2: grayscale + contrast boost. This rescues low-contrast frames
    // (full-art, showcase, textured retro) where the raw pass misses text.
    // We merge both result sets so neither frame style loses out.
    var pp = img.grayscale(decoded);
    pp = img.contrast(pp, contrast: 125);
    final preprocessed = await _run(
        Uint8List.fromList(img.encodePng(pp)), decoded.width, decoded.height);

    return _mergeBlocks(raw, preprocessed);
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

  // Union blocks from both passes, dropping near-duplicates (same text in a
  // very similar box) so the merged list doesn't double-count passes that
  // agree.
  static List<OcrBlock> _mergeBlocks(
      List<OcrBlock> a, List<OcrBlock> b) {
    final out = [...a];
    for (final cand in b) {
      final dupe = out.any((existing) =>
          existing.text.trim() == cand.text.trim() &&
          (existing.left - cand.left).abs() < 0.03 &&
          (existing.top - cand.top).abs() < 0.03);
      if (!dupe) out.add(cand);
    }
    return out;
  }

  @override
  Future<void> dispose() => _recognizer.close();
}
